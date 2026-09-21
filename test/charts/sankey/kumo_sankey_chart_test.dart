import 'dart:ui' show PictureRecorder, Size;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

/// Wraps a real layer so a test can count its paints.
class _CountingLayer extends KumoChartLayer {
  _CountingLayer({
    required super.context,
    required this.delegate,
    required this.onPaint,
  });

  final KumoChartLayer delegate;
  final VoidCallback onPaint;

  @override
  void prepare() => delegate.prepare();

  @override
  void paint(Canvas canvas, Size size) {
    onPaint();
    delegate.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _CountingLayer oldDelegate) => true;
}

class _CountingNodes extends KumoSankeyBackgroundLayer {
  _CountingNodes({
    required super.context,
    required super.graph,
    required super.nodeLayouts,
    required super.linkLayouts,
  });

  int prepares = 0;

  @override
  void prepare() {
    prepares++;
    super.prepare();
  }
}

class _CountingRibbons extends KumoSankeyForegroundLayer {
  _CountingRibbons({
    required super.context,
    required super.graph,
    required super.nodeLayouts,
    required super.linkLayouts,
  });

  int prepares = 0;

  @override
  void prepare() {
    prepares++;
    super.prepare();
  }
}

const double _width = 320;
const double _height = 240;

KumoSankeyGraph _graph() => KumoSankeyGraph(
  nodes: const <KumoSankeyNode>[
    KumoSankeyNode(id: 'edge', label: 'Edge'),
    KumoSankeyNode(id: 'cache', label: 'Cache'),
    KumoSankeyNode(id: 'origin', label: 'Origin'),
  ],
  links: const <KumoSankeyLink>[
    KumoSankeyLink(source: 'edge', target: 'cache', value: 62),
    KumoSankeyLink(source: 'edge', target: 'origin', value: 38),
    KumoSankeyLink(source: 'cache', target: 'origin', value: 62),
  ],
);

KumoChartContext _context({double width = _width, double height = _height}) =>
    KumoChartContext(
      geometry: KumoChartGeometry(
        size: Size(width, height),
        plot: Rect.fromLTRB(16, 16, width - 16, height - 16),
      ),
      colors: const KumoColors(),
      styles: KumoTypography.resolve(const KumoColors()),
    );

void _paintTimes(KumoChartLayer layer, int times) {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  for (int i = 0; i < times; i++) {
    layer.paint(canvas, const Size(_width, _height));
  }
  recorder.endRecording().dispose();
}

void main() {
  group('zero allocation in the paint loop', () {
    test('a prepared layer never re-prepares, however many paints', () {
      final KumoSankeyGraph graph = _graph();
      final List<KumoSankeyNodeLayout> nodes = List<KumoSankeyNodeLayout>.generate(
        graph.nodes.length,
        (_) => KumoSankeyNodeLayout(),
      );
      final List<KumoSankeyLinkLayout> links = List<KumoSankeyLinkLayout>.generate(
        graph.links.length,
        (_) => KumoSankeyLinkLayout(),
      );

      final _CountingNodes background = _CountingNodes(
        context: _context(),
        graph: graph,
        nodeLayouts: nodes,
        linkLayouts: links,
      )..prepare();
      final _CountingRibbons foreground = _CountingRibbons(
        context: _context(),
        graph: graph,
        nodeLayouts: nodes,
        linkLayouts: links,
      )..prepare();

      expect(background.prepares, 1);
      expect(foreground.prepares, 1);

      final List<List<double>> before = nodes
          .map(
            (KumoSankeyNodeLayout node) => <double>[
              node.x,
              node.y,
              node.height,
              node.inflow,
              node.outflow,
            ],
          )
          .toList();
      final List<List<double>> linkBefore = links
          .map(
            (KumoSankeyLinkLayout link) => <double>[
              link.sourceTop,
              link.sourceBottom,
              link.targetTop,
              link.targetBottom,
            ],
          )
          .toList();

      _paintTimes(background, 200);
      _paintTimes(foreground, 200);

      // Dart exposes no allocation counter, so what is asserted here is what is
      // observable: 200 paints neither re-prepared nor changed the layout. The
      // allocation-freedom itself is structural — neither paint body constructs
      // a Paint, Path, TextSpan, Offset, RRect or Rect; those are built in
      // prepare and only read here.
      expect(background.prepares, 1);
      expect(foreground.prepares, 1);

      for (int i = 0; i < nodes.length; i++) {
        expect(
          <double>[
            nodes[i].x,
            nodes[i].y,
            nodes[i].height,
            nodes[i].inflow,
            nodes[i].outflow,
          ],
          before[i],
          reason: 'the paint pass reads the layout, it does not write it',
        );
      }
      for (int i = 0; i < links.length; i++) {
        expect(
          <double>[
            links[i].sourceTop,
            links[i].sourceBottom,
            links[i].targetTop,
            links[i].targetBottom,
          ],
          linkBefore[i],
        );
      }
    });

    test('preparing again on a new geometry overwrites the same structs', () {
      final KumoSankeyGraph graph = _graph();
      final List<KumoSankeyNodeLayout> nodes = List<KumoSankeyNodeLayout>.generate(
        graph.nodes.length,
        (_) => KumoSankeyNodeLayout(),
      );
      final List<KumoSankeyLinkLayout> links = List<KumoSankeyLinkLayout>.generate(
        graph.links.length,
        (_) => KumoSankeyLinkLayout(),
      );

      final _CountingRibbons wide = _CountingRibbons(
        context: _context(),
        graph: graph,
        nodeLayouts: nodes,
        linkLayouts: links,
      )..prepare();
      final double wideX = nodes[2].x;
      _paintTimes(wide, 1);

      final _CountingRibbons narrow = _CountingRibbons(
        context: _context(width: 200, height: 160),
        graph: graph,
        nodeLayouts: nodes,
        linkLayouts: links,
      )..prepare();
      _paintTimes(narrow, 1);

      // Same structs, new geometry: the solver wrote over them rather than
      // handing back a fresh set.
      expect(wide.prepares, 1);
      expect(narrow.prepares, 1);
      expect(nodes[2].x, lessThan(wideX));
      expect(nodes[0].x, 0);
    });
  });

  group('layer repaint decoupling', () {
    testWidgets('a tick repaints ribbons, never the nodes', (tester) async {
      final KumoSankeyGraph graph = _graph();
      final List<KumoSankeyNodeLayout> nodes = List<KumoSankeyNodeLayout>.generate(
        graph.nodes.length,
        (_) => KumoSankeyNodeLayout(),
      );
      final List<KumoSankeyLinkLayout> links = List<KumoSankeyLinkLayout>.generate(
        graph.links.length,
        (_) => KumoSankeyLinkLayout(),
      );
      final List<VoidCallback> queued = <VoidCallback>[];
      final KumoChartController<int> controller = KumoChartController<int>(
        capacity: 64,
        scheduler: queued.add,
      );
      addTearDown(controller.dispose);

      int nodePaints = 0;
      int ribbonPaints = 0;

      await tester.pumpWidget(
        KumoTheme(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: _width,
                child: KumoChartContainer(
                  height: _height,
                  repaint: controller,
                  background: (KumoChartContext context) => _CountingLayer(
                    context: context,
                    delegate: KumoSankeyBackgroundLayer(
                      context: context,
                      graph: graph,
                      nodeLayouts: nodes,
                      linkLayouts: links,
                    ),
                    onPaint: () => nodePaints++,
                  ),
                  foreground: (KumoChartContext context) => _CountingLayer(
                    context: context,
                    delegate: KumoSankeyForegroundLayer(
                      context: context,
                      graph: graph,
                      nodeLayouts: nodes,
                      linkLayouts: links,
                    ),
                    onPaint: () => ribbonPaints++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(nodePaints, 1);
      final int afterFirstFrame = ribbonPaints;
      expect(afterFirstFrame, greaterThanOrEqualTo(1));

      for (int i = 0; i < 3; i++) {
        controller.append(i);
        expect(queued, isNotEmpty);
        queued.removeAt(0)();
        await tester.pump();
      }

      expect(ribbonPaints, greaterThan(afterFirstFrame));
      expect(nodePaints, 1, reason: 'node boxes rasterise once per layout');
    });
  });

  group('KumoSankeyChart', () {
    testWidgets('renders and survives a resize', (tester) async {
      final KumoSankeyGraph graph = _graph();

      Widget sized(double width) => KumoTheme(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(width: width, child: KumoSankeyChart(graph: graph)),
          ),
        ),
      );

      await tester.pumpWidget(sized(320));
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);

      // A resize reruns prepare against a new plot rect; nothing may go stale.
      await tester.pumpWidget(sized(200));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(sized(200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without the surface chrome', (tester) async {
      await tester.pumpWidget(
        KumoTheme(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 320,
                child: KumoSankeyChart(
                  graph: _graph(),
                  showSurface: false,
                  selectedNodeId: 'cache',
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('shouldRepaint', () {
    late KumoSankeyGraph graph;
    late List<KumoSankeyNodeLayout> nodes;
    late List<KumoSankeyLinkLayout> links;

    setUp(() {
      graph = _graph();
      nodes = List<KumoSankeyNodeLayout>.generate(
        graph.nodes.length,
        (_) => KumoSankeyNodeLayout(),
      );
      links = List<KumoSankeyLinkLayout>.generate(
        graph.links.length,
        (_) => KumoSankeyLinkLayout(),
      );
    });

    test('a static node layer does not repaint for the same input', () {
      final KumoSankeyBackgroundLayer first = KumoSankeyBackgroundLayer(
        context: _context(),
        graph: graph,
        nodeLayouts: nodes,
        linkLayouts: links,
      );
      final KumoSankeyBackgroundLayer second = KumoSankeyBackgroundLayer(
        context: _context(),
        graph: graph,
        nodeLayouts: nodes,
        linkLayouts: links,
      );

      expect(second.shouldRepaint(first), isFalse);
    });

    test('selecting a node repaints the node layer', () {
      final KumoSankeyBackgroundLayer plain = KumoSankeyBackgroundLayer(
        context: _context(),
        graph: graph,
        nodeLayouts: nodes,
        linkLayouts: links,
      );
      final KumoSankeyBackgroundLayer selected = KumoSankeyBackgroundLayer(
        context: _context(),
        graph: graph,
        nodeLayouts: nodes,
        linkLayouts: links,
        selectedNodeId: 'edge',
      );

      expect(selected.shouldRepaint(plain), isTrue);
    });

    test('a new graph repaints the ribbon layer', () {
      final KumoSankeyForegroundLayer first = KumoSankeyForegroundLayer(
        context: _context(),
        graph: graph,
        nodeLayouts: nodes,
        linkLayouts: links,
      );
      final KumoSankeyForegroundLayer second = KumoSankeyForegroundLayer(
        context: _context(),
        graph: _graph(),
        nodeLayouts: nodes,
        linkLayouts: links,
      );

      expect(second.shouldRepaint(first), isTrue);
    });
  });
}
