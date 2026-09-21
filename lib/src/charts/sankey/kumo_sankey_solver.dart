import 'dart:typed_data';
import 'dart:ui' show Color;

/// One node in a Sankey graph.
class KumoSankeyNode {
  /// Creates a node.
  const KumoSankeyNode({required this.id, this.label, this.color});

  /// Identifies the node within a [KumoSankeyGraph].
  final String id;

  /// Text drawn beside the node. Falls back to [id].
  final String? label;

  /// Overrides the palette slot this node would otherwise take.
  final Color? color;
}

/// One flow between two nodes.
class KumoSankeyLink {
  /// Creates a link.
  const KumoSankeyLink({
    required this.source,
    required this.target,
    required this.value,
  });

  /// Id of the node the flow leaves.
  final String source;

  /// Id of the node the flow enters.
  final String target;

  /// The flow's magnitude. Ribbon thickness and node height are proportional
  /// to it.
  final double value;
}

/// A directed graph of flows.
class KumoSankeyGraph {
  /// Creates a graph.
  const KumoSankeyGraph({required this.nodes, required this.links});

  /// The nodes.
  final List<KumoSankeyNode> nodes;

  /// The links.
  final List<KumoSankeyLink> links;
}

/// Where one node ended up.
///
/// A plain mutable struct rather than a value object: the solver writes into
/// caller-owned instances on every layout pass, so a resize reuses the same
/// objects instead of replacing them.
class KumoSankeyNodeLayout {
  /// Column index, `0` at the leftmost stage.
  int depth = 0;

  /// Left edge, in plot-local pixels.
  double x = 0;

  /// Top edge, in plot-local pixels.
  double y = 0;

  /// Node thickness along the x axis.
  double width = 0;

  /// Node extent along the y axis, proportional to [throughput].
  double height = 0;

  /// Sum of incoming flow.
  double inflow = 0;

  /// Sum of outgoing flow.
  double outflow = 0;

  /// The larger of [inflow] and [outflow].
  ///
  /// A node is as tall as the most it has to carry in either direction, which
  /// is what stops a node from being too short for the flows entering it.
  double get throughput => inflow > outflow ? inflow : outflow;

  /// The node's vertical centre, in plot-local pixels.
  double get centerY => y + height / 2;
}

/// Where one link's ribbon attaches.
///
/// The four bands are plot-local pixel coordinates, so a painter needs no
/// arithmetic beyond the Bézier control points. Thicknesses are equal at both
/// ends because both scale the same value by the same factor.
class KumoSankeyLinkLayout {
  /// Index into the graph's node list, or `-1` when an endpoint did not
  /// resolve and the link was dropped.
  int sourceIndex = -1;

  /// Index into the graph's node list, or `-1`.
  int targetIndex = -1;

  /// Top of the band on the source node.
  double sourceTop = 0;

  /// Bottom of the band on the source node.
  double sourceBottom = 0;

  /// Top of the band on the target node.
  double targetTop = 0;

  /// Bottom of the band on the target node.
  double targetBottom = 0;

  /// Whether this link was placed.
  bool get isPlaced => sourceIndex >= 0 && targetIndex >= 0;

  /// Ribbon thickness at the source.
  double get sourceThickness => sourceBottom - sourceTop;

  /// Ribbon thickness at the target.
  double get targetThickness => targetBottom - targetTop;
}

/// Places a [KumoSankeyGraph] into a rectangle.
///
/// Two responsibilities, and they are separable: columns come from the graph's
/// topology, and vertical positions come from its flows. Nodes are partitioned
/// into columns by longest-path depth, then every node in a column is stacked
/// with [nodePadding] between them under a single shared scale, so no column can
/// overlap.
///
/// Every buffer this needs is allocated in the constructor and reused. [layout]
/// writes only into those buffers and into the caller's layout structs, so a
/// resize costs no allocations.
///
/// ```dart
/// final solver = KumoSankeySolver(graph: graph);
/// final nodes = List.generate(graph.nodes.length, (_) => KumoSankeyNodeLayout());
/// final links = List.generate(graph.links.length, (_) => KumoSankeyLinkLayout());
/// solver.layout(width: 400, height: 260, nodeLayouts: nodes, linkLayouts: links);
/// ```
class KumoSankeySolver {
  /// Creates a solver for [graph].
  ///
  /// [nodeWidth] is the node thickness and [nodePadding] the minimum vertical
  /// gap between two nodes sharing a column.
  KumoSankeySolver({
    required this.graph,
    this.nodeWidth = 12,
    this.nodePadding = 10,
  }) : _linkSource = Int32List(graph.links.length),
       _linkTarget = Int32List(graph.links.length),
       _depth = Int32List(graph.nodes.length),
       _settled = Uint8List(graph.nodes.length),
       _inDegree = Int32List(graph.nodes.length),
       _queue = Int32List(graph.nodes.length),
       _columnWeight = Float64List(graph.nodes.length + 1),
       _columnNodes = Int32List(graph.nodes.length + 1),
       _columnPlaced = Int32List(graph.nodes.length + 1),
       _columnCursor = Float64List(graph.nodes.length + 1),
       _inflow = Float64List(graph.nodes.length),
       _outflow = Float64List(graph.nodes.length),
       _outStart = Int32List(graph.nodes.length + 1),
       _outLinks = Int32List(graph.links.length),
       _outCursor = Int32List(graph.nodes.length),
       _inStart = Int32List(graph.nodes.length + 1),
       _inLinks = Int32List(graph.links.length),
       _inCursor = Int32List(graph.nodes.length);

  /// The graph to lay out.
  final KumoSankeyGraph graph;

  /// Node thickness along the x axis.
  final double nodeWidth;

  /// Minimum vertical gap between nodes in the same column.
  final double nodePadding;

  final Int32List _linkSource;
  final Int32List _linkTarget;
  final Int32List _depth;
  final Uint8List _settled;
  final Int32List _inDegree;
  final Int32List _queue;
  final Float64List _columnWeight;
  final Int32List _columnNodes;
  final Int32List _columnPlaced;
  final Float64List _columnCursor;
  final Float64List _inflow;
  final Float64List _outflow;
  final Int32List _outStart;
  final Int32List _outLinks;
  final Int32List _outCursor;
  final Int32List _inStart;
  final Int32List _inLinks;
  final Int32List _inCursor;

  /// Number of columns the last layout produced.
  int get columnCount => _columnCount;
  int _columnCount = 0;

  /// The vertical scale applied per unit of flow on the last layout.
  double get scale => _scale;
  double _scale = 0;

  /// Lays the graph out inside a `width` by `height` box.
  ///
  /// Coordinates are plot-local: the origin is the box's top-left, so a painter
  /// translates to the plot rect rather than the solver knowing about insets.
  ///
  /// [nodeLayouts] and [linkLayouts] must each hold one entry per node and per
  /// link. They are overwritten, never reallocated.
  void layout({
    required double width,
    required double height,
    required List<KumoSankeyNodeLayout> nodeLayouts,
    required List<KumoSankeyLinkLayout> linkLayouts,
  }) {
    assert(nodeLayouts.length >= graph.nodes.length, 'one layout per node');
    assert(linkLayouts.length >= graph.links.length, 'one layout per link');

    final int nodeCount = graph.nodes.length;
    final int linkCount = graph.links.length;
    if (nodeCount == 0) {
      _columnCount = 0;
      _scale = 0;
      return;
    }

    _nodeLayouts = nodeLayouts;
    _linkLayouts = linkLayouts;
    _resolveEndpoints();
    _accumulateFlow(nodeCount, linkCount);
    _computeDepths(nodeCount, linkCount);
    _resolveColumns(nodeCount);
    _resolveScale(nodeCount, height);
    _placeNodes(nodeCount, width, height);
    _placeLinks(nodeCount);

    for (int l = 0; l < linkCount; l++) {
      final KumoSankeyLinkLayout layout = linkLayouts[l];
      if (!layout.isPlaced) {
        layout
          ..sourceTop = 0
          ..sourceBottom = 0
          ..targetTop = 0
          ..targetBottom = 0;
      }
    }
  }

  late List<KumoSankeyNodeLayout> _nodeLayouts;
  late List<KumoSankeyLinkLayout> _linkLayouts;

  void _resolveEndpoints() {
    final int linkCount = graph.links.length;
    for (int l = 0; l < linkCount; l++) {
      final KumoSankeyLink link = graph.links[l];
      _linkSource[l] = _indexOf(link.source);
      _linkTarget[l] = _indexOf(link.target);
    }
  }

  int _indexOf(String id) {
    final int nodeCount = graph.nodes.length;
    for (int i = 0; i < nodeCount; i++) {
      if (graph.nodes[i].id == id) {
        return i;
      }
    }
    // An unknown endpoint drops the link rather than throwing: a chart fed by
    // generated data is better off missing one ribbon than blank.
    return -1;
  }

  void _accumulateFlow(int nodeCount, int linkCount) {
    _inflow.fillRange(0, nodeCount, 0);
    _outflow.fillRange(0, nodeCount, 0);
    for (int l = 0; l < linkCount; l++) {
      final int source = _linkSource[l];
      final int target = _linkTarget[l];
      if (source < 0 || target < 0) {
        continue;
      }
      final double value = graph.links[l].value;
      _outflow[source] += value;
      _inflow[target] += value;
    }
    for (int v = 0; v < nodeCount; v++) {
      _nodeLayouts[v]
        ..inflow = _inflow[v]
        ..outflow = _outflow[v];
    }
  }

  /// Longest-path depths via Kahn's algorithm, with a bounded sweep for cycles.
  ///
  /// Kahn is what makes a cycle safe: each node leaves the queue exactly once,
  /// so the loop always terminates. Nodes still unvisited when the queue drains
  /// are the ones inside a cycle, and they cannot be ordered by in-degree.
  ///
  /// They are swept breadth-first instead, from the settled nodes outward: a
  /// cycle member reachable from the acyclic part gets a real depth, and its
  /// successors follow it. Each unsettled node is enqueued at most once, so a
  /// cycle costs a pass rather than a hang. A cycle with no entry point at all
  /// has no left-to-right position to derive, so it stays in the first column.
  void _computeDepths(int nodeCount, int linkCount) {
    _buildAdjacency(nodeCount, linkCount);
    _inDegree.fillRange(0, nodeCount, 0);
    _settled.fillRange(0, nodeCount, 0);
    _depth.fillRange(0, nodeCount, 0);

    for (int l = 0; l < linkCount; l++) {
      final int source = _linkSource[l];
      final int target = _linkTarget[l];
      if (source < 0 || target < 0 || source == target) {
        continue;
      }
      _inDegree[target]++;
    }

    int head = 0;
    int tail = 0;
    for (int v = 0; v < nodeCount; v++) {
      if (_inDegree[v] == 0) {
        _queue[tail++] = v;
      }
    }
    while (head < tail) {
      final int v = _queue[head++];
      _settled[v] = 1;
      for (int k = _outStart[v]; k < _outStart[v + 1]; k++) {
        final int target = _linkTarget[_outLinks[k]];
        if (target == v) {
          continue;
        }
        if (_depth[v] + 1 > _depth[target]) {
          _depth[target] = _depth[v] + 1;
        }
        if (--_inDegree[target] == 0) {
          _queue[tail++] = target;
        }
      }
    }

    // Sweep the cycles from the settled frontier. `_settled` doubles as the
    // visited flag here: 1 means Kahn ordered it, 2 means the sweep did.
    head = 0;
    tail = 0;
    for (int v = 0; v < nodeCount; v++) {
      if (_settled[v] != 0) {
        continue;
      }
      int depth = 0;
      bool anchored = false;
      for (int k = _inStart[v]; k < _inStart[v + 1]; k++) {
        final int source = _linkSource[_inLinks[k]];
        if (source != v && _settled[source] == 1) {
          anchored = true;
          if (_depth[source] + 1 > depth) {
            depth = _depth[source] + 1;
          }
        }
      }
      if (anchored) {
        _depth[v] = depth;
        _settled[v] = 2;
        _queue[tail++] = v;
      }
    }
    while (head < tail) {
      final int v = _queue[head++];
      for (int k = _outStart[v]; k < _outStart[v + 1]; k++) {
        final int target = _linkTarget[_outLinks[k]];
        if (target == v || _settled[target] != 0) {
          continue;
        }
        _depth[target] = _depth[v] + 1;
        _settled[target] = 2;
        _queue[tail++] = target;
      }
    }
  }

  void _buildAdjacency(int nodeCount, int linkCount) {
    _outStart.fillRange(0, nodeCount + 1, 0);
    _inStart.fillRange(0, nodeCount + 1, 0);

    for (int l = 0; l < linkCount; l++) {
      final int source = _linkSource[l];
      final int target = _linkTarget[l];
      if (source < 0 || target < 0) {
        continue;
      }
      _outStart[source + 1]++;
      _inStart[target + 1]++;
    }
    for (int v = 0; v < nodeCount; v++) {
      _outStart[v + 1] += _outStart[v];
      _inStart[v + 1] += _inStart[v];
    }
    _outCursor.fillRange(0, nodeCount, 0);
    _inCursor.fillRange(0, nodeCount, 0);
    for (int l = 0; l < linkCount; l++) {
      final int source = _linkSource[l];
      final int target = _linkTarget[l];
      if (source < 0 || target < 0) {
        continue;
      }
      _outLinks[_outStart[source] + _outCursor[source]++] = l;
      _inLinks[_inStart[target] + _inCursor[target]++] = l;
    }
  }

  void _resolveColumns(int nodeCount) {
    int maxDepth = 0;
    for (int v = 0; v < nodeCount; v++) {
      if (_depth[v] > maxDepth) {
        maxDepth = _depth[v];
      }
    }
    _columnCount = maxDepth + 1;
  }

  void _resolveScale(int nodeCount, double height) {
    final int columns = _columnCount;
    _columnWeight.fillRange(0, columns, 0);
    _columnNodes.fillRange(0, columns, 0);

    for (int v = 0; v < nodeCount; v++) {
      _columnWeight[_depth[v]] += _nodeLayouts[v].throughput;
      _columnNodes[_depth[v]]++;
    }

    double maxWeight = 0;
    int maxNodes = 0;
    for (int c = 0; c < columns; c++) {
      if (_columnWeight[c] > maxWeight) {
        maxWeight = _columnWeight[c];
      }
      if (_columnNodes[c] > maxNodes) {
        maxNodes = _columnNodes[c];
      }
    }

    final double padding = (maxNodes <= 1 ? 0 : (maxNodes - 1) * nodePadding);
    final double available = height - padding;
    // One scale for every column, sized so the busiest column fits with its
    // padding. That is what makes overlap impossible rather than merely
    // unlikely, and it costs nothing: a relaxation pass would iterate towards
    // the same answer.
    _scale = (maxWeight <= 0 || available <= 0) ? 0 : available / maxWeight;
  }

  void _placeNodes(int nodeCount, double width, double height) {
    final int columns = _columnCount;
    final double thickness = nodeWidth < 0
        ? 0
        : (nodeWidth > width ? width : nodeWidth);
    final double span = width - thickness;
    final bool singleColumn = columns <= 1;

    for (int c = 0; c < columns; c++) {
      final double total = _columnWeight[c] * _scale;
      final int count = _columnNodes[c];
      // Padding separates nodes, so a column of n has n - 1 gaps. Centring has
      // to account for those gaps as well as the nodes: the busiest column is
      // then exactly as tall as the box, with no half gap left over at either
      // end.
      final double gaps = count <= 1 ? 0 : (count - 1) * nodePadding;
      _columnCursor[c] = (height - (total + gaps)) / 2;
      _columnPlaced[c] = 0;
    }

    for (int v = 0; v < nodeCount; v++) {
      final int column = _depth[v];
      final KumoSankeyNodeLayout layout = _nodeLayouts[v];
      layout
        ..depth = column
        ..x = singleColumn ? (span / 2) : (column / (columns - 1)) * span
        ..width = thickness
        ..y = _columnCursor[column]
        ..height = layout.throughput * _scale;
      _columnPlaced[column]++;
      // Trailing padding after the last node would push the column past the
      // height it was scaled to fit.
      _columnCursor[column] +=
          layout.height +
          (_columnPlaced[column] < _columnNodes[column] ? nodePadding : 0);
    }
  }

  void _placeLinks(int nodeCount) {
    for (int v = 0; v < nodeCount; v++) {
      // Ordering bands by the other endpoint's position is what keeps ribbons
      // from crossing: a flow that lands highest leaves highest.
      _sortBands(_outLinks, _outStart[v], _outStart[v + 1], _linkTarget);
      double cursor = _nodeLayouts[v].y;
      for (int k = _outStart[v]; k < _outStart[v + 1]; k++) {
        final int l = _outLinks[k];
        final KumoSankeyLinkLayout layout = _linkLayouts[l];
        final double thickness = graph.links[l].value * _scale;
        layout
          ..sourceIndex = v
          ..sourceTop = cursor
          ..sourceBottom = cursor + thickness;
        cursor += thickness;
      }

      _sortBands(_inLinks, _inStart[v], _inStart[v + 1], _linkSource);
      cursor = _nodeLayouts[v].y;
      for (int k = _inStart[v]; k < _inStart[v + 1]; k++) {
        final int l = _inLinks[k];
        final KumoSankeyLinkLayout layout = _linkLayouts[l];
        final double thickness = graph.links[l].value * _scale;
        layout
          ..targetIndex = v
          ..targetTop = cursor
          ..targetBottom = cursor + thickness;
        cursor += thickness;
      }
    }
  }

  /// Insertion sort over an [Int32List] slice, keyed by the other endpoint's
  /// vertical position. Link counts per node are small, and an in-place sort
  /// avoids the list a comparator would allocate.
  void _sortBands(Int32List bands, int start, int end, Int32List otherEnd) {
    for (int i = start + 1; i < end; i++) {
      final int band = bands[i];
      final double key = _nodeLayouts[otherEnd[band]].y;
      int j = i - 1;
      while (j >= start && _nodeLayouts[otherEnd[bands[j]]].y > key) {
        bands[j + 1] = bands[j];
        j--;
      }
      bands[j + 1] = band;
    }
  }
}
