import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

const double _width = 400;
const double _height = 300;
const double _nodeWidth = 12;
const double _padding = 10;

KumoSankeyNode _node(String id) => KumoSankeyNode(id: id, label: id);

KumoSankeyLink _link(String source, String target, double value) =>
    KumoSankeyLink(source: source, target: target, value: value);

class _Fixture {
  _Fixture(this.graph)
    : solver = KumoSankeySolver(
        graph: graph,
        nodeWidth: _nodeWidth,
        nodePadding: _padding,
      ),
      nodes = List<KumoSankeyNodeLayout>.generate(
        graph.nodes.length,
        (_) => KumoSankeyNodeLayout(),
      ),
      links = List<KumoSankeyLinkLayout>.generate(
        graph.links.length,
        (_) => KumoSankeyLinkLayout(),
      );

  final KumoSankeyGraph graph;
  final KumoSankeySolver solver;
  final List<KumoSankeyNodeLayout> nodes;
  final List<KumoSankeyLinkLayout> links;

  void layout({double width = _width, double height = _height}) =>
      solver.layout(
        width: width,
        height: height,
        nodeLayouts: nodes,
        linkLayouts: links,
      );

  int indexOf(String id) => graph.nodes.indexWhere(
    (KumoSankeyNode node) => node.id == id,
  );

  KumoSankeyNodeLayout node(String id) => nodes[indexOf(id)];
}

void main() {
  group('topological order and depth calculations', () {
    test('a three-stage pipeline gets three columns', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[_node('a'), _node('b'), _node('c')],
          links: <KumoSankeyLink>[
            _link('a', 'b', 60),
            _link('b', 'c', 60),
          ],
        ),
      )..layout();

      expect(fixture.solver.columnCount, 3);
      expect(fixture.node('a').depth, 0);
      expect(fixture.node('b').depth, 1);
      expect(fixture.node('c').depth, 2);
    });

    test('depth is the longest path, not the first one found', () {
      // a -> b -> c -> d and a -> d. The shortcut must not pull d left.
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[
            _node('a'),
            _node('b'),
            _node('c'),
            _node('d'),
          ],
          links: <KumoSankeyLink>[
            _link('a', 'b', 10),
            _link('b', 'c', 10),
            _link('c', 'd', 10),
            _link('a', 'd', 10),
          ],
        ),
      )..layout();

      expect(fixture.solver.columnCount, 4);
      expect(fixture.node('d').depth, 3);
    });

    test('a diamond splits and rejoins', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[
            _node('a'),
            _node('b'),
            _node('c'),
            _node('d'),
          ],
          links: <KumoSankeyLink>[
            _link('a', 'b', 30),
            _link('a', 'c', 30),
            _link('b', 'd', 30),
            _link('c', 'd', 30),
          ],
        ),
      )..layout();

      expect(fixture.solver.columnCount, 3);
      expect(fixture.node('a').depth, 0);
      expect(fixture.node('b').depth, 1);
      expect(fixture.node('c').depth, 1);
      expect(fixture.node('d').depth, 2);
    });

    test('columns span the plot left to right', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[_node('a'), _node('b'), _node('c')],
          links: <KumoSankeyLink>[_link('a', 'b', 1), _link('b', 'c', 1)],
        ),
      )..layout();

      // Column zero starts at the left edge and the last column ends at the
      // right edge, so the diagram uses the full width it was given.
      expect(fixture.node('a').x, 0);
      expect(
        fixture.node('c').x + fixture.node('c').width,
        closeTo(_width, 1e-9),
      );
      expect(fixture.node('a').x, lessThan(fixture.node('b').x));
      expect(fixture.node('b').x, lessThan(fixture.node('c').x));
    });

    test('nodes take their depth from the graph, not from their index', () {
      // Node order deliberately disagrees with link direction.
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[_node('sink'), _node('source')],
          links: <KumoSankeyLink>[_link('source', 'sink', 5)],
        ),
      )..layout();

      expect(fixture.indexOf('source'), 1);
      expect(fixture.node('source').depth, 0);
      expect(fixture.node('sink').depth, 1);
      expect(fixture.node('source').x, lessThan(fixture.node('sink').x));
    });
  });

  group('flow conservation', () {
    _Fixture fan() => _Fixture(
      KumoSankeyGraph(
        nodes: <KumoSankeyNode>[_node('s'), _node('m'), _node('t1'), _node('t2')],
        links: <KumoSankeyLink>[
          _link('s', 'm', 30),
          _link('m', 't1', 20),
          _link('m', 't2', 10),
        ],
      ),
    )..layout();

    test('what enters a node leaves it', () {
      final _Fixture fixture = fan();
      final KumoSankeyNodeLayout middle = fixture.node('m');

      expect(middle.inflow, 30);
      expect(middle.outflow, 30);
      expect(middle.throughput, 30);
      expect(middle.inflow, middle.outflow);
    });

    test('a node is as tall as its throughput', () {
      final _Fixture fixture = fan();
      final KumoSankeyNodeLayout middle = fixture.node('m');

      expect(
        middle.height,
        closeTo(middle.throughput * fixture.solver.scale, 1e-9),
      );
      expect(
        fixture.node('s').height,
        closeTo(30 * fixture.solver.scale, 1e-9),
      );
    });

    test('every link is as thick at both ends', () {
      final _Fixture fixture = fan();

      for (final KumoSankeyLinkLayout link in fixture.links) {
        expect(link.isPlaced, isTrue);
        expect(
          link.sourceThickness,
          closeTo(link.targetThickness, 1e-9),
          reason: 'a ribbon cannot change thickness along its run',
        );
      }
      expect(
        fixture.links[1].sourceThickness,
        closeTo(20 * fixture.solver.scale, 1e-9),
        reason: 'the m -> t1 ribbon is 20 of the 30 units leaving m',
      );
    });

    test('bands pack against the node without gaps or overlaps', () {
      final _Fixture fixture = fan();
      final KumoSankeyLinkLayout first = fixture.links[1]; // m -> t1
      final KumoSankeyLinkLayout second = fixture.links[2]; // m -> t2
      final KumoSankeyNodeLayout middle = fixture.node('m');

      // Outgoing bands start at the node's top and run contiguously, so the
      // node's height is exactly accounted for by its flows.
      expect(first.sourceTop, closeTo(middle.y, 1e-9));
      expect(second.sourceTop, closeTo(first.sourceBottom, 1e-9));
      expect(
        second.sourceBottom - middle.y,
        closeTo(middle.outflow * fixture.solver.scale, 1e-9),
      );

      // Targets are laid out the same way, each starting at its own node top.
      expect(first.targetTop, closeTo(fixture.node('t1').y, 1e-9));
      expect(second.targetTop, closeTo(fixture.node('t2').y, 1e-9));
    });

    test('bands are ordered by the other end, which avoids crossings', () {
      // f1 lands on the higher target and leaves from the higher band.
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[_node('s'), _node('hi'), _node('lo')],
          links: <KumoSankeyLink>[
            _link('s', 'lo', 10),
            _link('s', 'hi', 10),
          ],
        ),
      )..layout();

      final double hiY = fixture.node('hi').y;
      final double loY = fixture.node('lo').y;
      expect(hiY, lessThan(loY), reason: 'hi is stacked first');

      final KumoSankeyLinkLayout toHi = fixture.links[1];
      final KumoSankeyLinkLayout toLo = fixture.links[0];
      expect(toHi.sourceTop, lessThan(toLo.sourceTop));
    });

    test('two nodes in a column never overlap', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[_node('a'), _node('b'), _node('x')],
          links: <KumoSankeyLink>[
            _link('a', 'x', 10),
            _link('b', 'x', 20),
          ],
        ),
      )..layout();

      // Both sources share column zero, and the column still fits the height
      // with its padding intact.
      expect(fixture.node('a').depth, 0);
      expect(fixture.node('b').depth, 0);
      expect(fixture.node('a').y, greaterThanOrEqualTo(0));
      expect(
        fixture.node('b').y - fixture.node('a').y,
        greaterThanOrEqualTo(fixture.node('a').height + _padding - 1e-9),
        reason: 'the gap must be at least nodePadding',
      );
      expect(
        fixture.node('b').y + fixture.node('b').height,
        lessThanOrEqualTo(_height + 1e-9),
      );
    });
  });

  group('cycle guard', () {
    test('a two-node cycle terminates', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[_node('a'), _node('b')],
          links: <KumoSankeyLink>[_link('a', 'b', 10), _link('b', 'a', 10)],
        ),
      );

      // The assertion is that this returns at all: Kahn's queue drains even
      // when no node has in-degree zero and nothing else can.
      fixture.layout();

      for (final KumoSankeyNodeLayout node in fixture.nodes) {
        expect(node.depth, greaterThanOrEqualTo(0));
        expect(node.x.isFinite, isTrue);
        expect(node.y.isFinite, isTrue);
        expect(node.height.isFinite, isTrue);
      }
      for (final KumoSankeyLinkLayout link in fixture.links) {
        expect(link.isPlaced, isTrue);
      }
    });

    test('a self-referential node does not feed its own depth', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[_node('a')],
          links: <KumoSankeyLink>[_link('a', 'a', 10)],
        ),
      )..layout();

      expect(fixture.solver.columnCount, 1);
      expect(fixture.node('a').depth, 0);
      expect(fixture.node('a').outflow, 10);
    });

    test('a three-node cycle with a real source beside it still orders', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[
            _node('src'),
            _node('a'),
            _node('b'),
            _node('c'),
            _node('sink'),
          ],
          links: <KumoSankeyLink>[
            _link('a', 'b', 5),
            _link('b', 'c', 5),
            _link('c', 'a', 5),
            _link('src', 'sink', 5),
          ],
        ),
      )..layout();

      // The acyclic part is still ordered from its own source.
      expect(fixture.node('src').depth, 0);
      expect(fixture.node('sink').depth, 1);
      expect(fixture.solver.columnCount, 2);
      // The cycle members all land in column zero: a cycle with no entry point
      // from the acyclic part has no position to derive.
      expect(fixture.node('a').depth, 0);
      expect(fixture.node('b').depth, 0);
      expect(fixture.node('c').depth, 0);
    });

    test('a cycle hanging off a settled chain is pushed right of it', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[
            _node('src'),
            _node('a'),
            _node('b'),
            _node('c'),
          ],
          links: <KumoSankeyLink>[
            _link('src', 'a', 5),
            _link('a', 'b', 5),
            _link('b', 'a', 5),
            _link('b', 'c', 5),
          ],
        ),
      )..layout();

      expect(fixture.node('src').depth, 0);
      expect(fixture.node('a').depth, 1);
      // b is never dequeued by Kahn, so the sweep reaches it from a and gives
      // it a real depth rather than leaving it in column zero.
      expect(fixture.node('b').depth, 2);
      expect(fixture.node('c').depth, 3);
      expect(fixture.solver.columnCount, 4);
    });
  });

  group('allocation rule', () {
    test('layout mutates the caller\u2019s structs rather than replacing them', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[_node('a'), _node('b'), _node('c')],
          links: <KumoSankeyLink>[_link('a', 'b', 60), _link('b', 'c', 60)],
        ),
      );

      fixture.layout();
      final List<int> nodeIds = fixture.nodes
          .map(identityHashCode)
          .toList();
      final List<int> linkIds = fixture.links
          .map(identityHashCode)
          .toList();
      final double firstX = fixture.node('b').x;

      for (int i = 1; i <= 50; i++) {
        fixture.layout(width: _width + i.toDouble());
      }

      // Same objects, 51 layouts later, with different contents.
      expect(fixture.nodes.map(identityHashCode).toList(), nodeIds);
      expect(fixture.links.map(identityHashCode).toList(), linkIds);
      expect(fixture.node('b').x, isNot(firstX));
    });
  });

  group('degenerate input', () {
    test('an empty graph lays out to nothing', () {
      final _Fixture fixture = _Fixture(
        const KumoSankeyGraph(nodes: <KumoSankeyNode>[], links: <KumoSankeyLink>[]),
      )..layout();

      expect(fixture.solver.columnCount, 0);
      expect(fixture.solver.scale, 0);
    });

    test('an unresolved endpoint drops its link instead of throwing', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[_node('a')],
          links: <KumoSankeyLink>[
            _link('a', 'ghost', 10),
            _link('ghost', 'a', 10),
          ],
        ),
      )..layout();

      expect(fixture.links[0].isPlaced, isFalse);
      expect(fixture.links[1].isPlaced, isFalse);
      expect(fixture.node('a').outflow, 0);
      expect(fixture.node('a').inflow, 0);
    });

    test('zero total flow does not divide by zero', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[_node('a'), _node('b')],
          links: <KumoSankeyLink>[_link('a', 'b', 0)],
        ),
      )..layout();

      expect(fixture.solver.scale, 0);
      expect(fixture.node('a').height, 0);
      expect(fixture.node('a').x.isFinite, isTrue);
    });

    test('a zero-size plot does not produce NaN', () {
      final _Fixture fixture = _Fixture(
        KumoSankeyGraph(
          nodes: <KumoSankeyNode>[_node('a'), _node('b')],
          links: <KumoSankeyLink>[_link('a', 'b', 10)],
        ),
      )..layout(width: 0, height: 0);

      for (final KumoSankeyNodeLayout node in fixture.nodes) {
        expect(node.x.isNaN, isFalse);
        expect(node.y.isNaN, isFalse);
        expect(node.height.isNaN, isFalse);
      }
    });
  });
}
