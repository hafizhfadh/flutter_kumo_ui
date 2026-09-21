import 'package:flutter/widgets.dart';

import '../kumo_chart_colors.dart';
import '../kumo_chart_container.dart';
import 'kumo_sankey_painter.dart';
import 'kumo_sankey_solver.dart';

/// A Sankey diagram.
///
/// ```dart
/// KumoSankeyChart(
///   graph: KumoSankeyGraph(
///     nodes: <KumoSankeyNode>[
///       KumoSankeyNode(id: 'edge', label: 'Edge'),
///       KumoSankeyNode(id: 'cache', label: 'Cache'),
///     ],
///     links: <KumoSankeyLink>[
///       KumoSankeyLink(source: 'edge', target: 'cache', value: 62),
///     ],
///   ),
/// )
/// ```
///
/// Stateful because the layout structs have to outlive a frame: the solver
/// mutates them in place, so a resize re-lays out the same objects instead of
/// building a new graph of them. Both layers run the solver in their own
/// `prepare`, which costs a duplicated pass per layout and buys each layer the
/// ability to stand alone.
///
/// The graph is compared by identity. Mutating a graph in place will not
/// relayout it; hand over a new [KumoSankeyGraph].
class KumoSankeyChart extends StatefulWidget {
  /// Creates a Sankey chart.
  const KumoSankeyChart({
    super.key,
    required this.graph,
    this.repaint,
    this.height = 260,
    this.nodeWidth = 12,
    this.nodePadding = 10,
    this.nodeRadius = 4,
    this.selectedNodeId,
    this.chartColors = const KumoChartColors(),
    this.showSurface = true,
    this.insets = const EdgeInsets.fromLTRB(16, 16, 16, 16),
  });

  /// The graph to draw.
  final KumoSankeyGraph graph;

  /// Notified when the graph changes, for a chart fed by a live source.
  final Listenable? repaint;

  /// Height of the surface. Width comes from the parent.
  final double height;

  /// Node thickness along the x axis.
  final double nodeWidth;

  /// Minimum vertical gap between nodes sharing a column.
  final double nodePadding;

  /// Corner radius of a node block.
  final double nodeRadius;

  /// Node whose label is drawn in `textPrimary` rather than `textMuted`.
  final String? selectedNodeId;

  /// The chart palette.
  final KumoChartColors chartColors;

  /// Whether to paint the surface fill and outline. Turn off inside a card.
  final bool showSurface;

  /// Room reserved inside the surface.
  final EdgeInsets insets;

  @override
  State<KumoSankeyChart> createState() => _KumoSankeyChartState();
}

class _KumoSankeyChartState extends State<KumoSankeyChart> {
  late List<KumoSankeyNodeLayout> _nodeLayouts;
  late List<KumoSankeyLinkLayout> _linkLayouts;

  @override
  void initState() {
    super.initState();
    _allocate();
  }

  @override
  void didUpdateWidget(covariant KumoSankeyChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.graph, widget.graph)) {
      _allocate();
    }
  }

  void _allocate() {
    _nodeLayouts = List<KumoSankeyNodeLayout>.generate(
      widget.graph.nodes.length,
      (_) => KumoSankeyNodeLayout(),
      growable: false,
    );
    _linkLayouts = List<KumoSankeyLinkLayout>.generate(
      widget.graph.links.length,
      (_) => KumoSankeyLinkLayout(),
      growable: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return KumoChartContainer(
      height: widget.height,
      insets: widget.insets,
      repaint: widget.repaint,
      showSurface: widget.showSurface,
      background: (KumoChartContext context) => KumoSankeyBackgroundLayer(
        context: context,
        graph: widget.graph,
        nodeLayouts: _nodeLayouts,
        linkLayouts: _linkLayouts,
        nodeWidth: widget.nodeWidth,
        nodePadding: widget.nodePadding,
        nodeRadius: widget.nodeRadius,
        selectedNodeId: widget.selectedNodeId,
      ),
      foreground: (KumoChartContext context) => KumoSankeyForegroundLayer(
        context: context,
        graph: widget.graph,
        nodeLayouts: _nodeLayouts,
        linkLayouts: _linkLayouts,
        nodeWidth: widget.nodeWidth,
        nodePadding: widget.nodePadding,
        chartColors: widget.chartColors,
      ),
    );
  }
}
