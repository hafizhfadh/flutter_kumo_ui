import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../kumo_chart_colors.dart';
import '../kumo_chart_container.dart';
import 'kumo_sankey_solver.dart';

/// Sets the label a node carries on the canvas.
String _labelOf(KumoSankeyNode node) => node.label ?? node.id;

/// The palette slot a node takes when it has no colour of its own.
Color _slotColor(KumoSankeyNode node, int index) =>
    node.color ??
    KumoChartColors.categorical[index % KumoChartColors.categorical.length];

/// Draws the nodes and their labels.
///
/// Static: node boxes only move when the layout does, so this layer is handed a
/// context with no repaint listenable. That matters more here than on a
/// timeseries chart, because it lets the label pass cache each `TextPainter`
/// already laid out in [prepare], leaving the paint body with nothing to build.
///
/// The labels are positioned beside the node, on the far side of the last
/// column, so a terminal node's text does not run off the plot.
class KumoSankeyBackgroundLayer extends KumoChartLayer {
  /// Creates the node layer.
  KumoSankeyBackgroundLayer({
    required super.context,
    required this.graph,
    required this.nodeLayouts,
    required this.linkLayouts,
    this.nodeWidth = 12,
    this.nodePadding = 10,
    this.nodeRadius = 4,
    this.selectedNodeId,
  });

  /// The graph being drawn.
  final KumoSankeyGraph graph;

  /// Node geometry, written by the solver in [prepare].
  final List<KumoSankeyNodeLayout> nodeLayouts;

  /// Link geometry, written by the solver in [prepare].
  final List<KumoSankeyLinkLayout> linkLayouts;

  /// Node thickness. Mirrors the solver's own setting.
  final double nodeWidth;

  /// Minimum vertical gap between nodes in a column.
  final double nodePadding;

  /// Corner radius of a node block.
  final double nodeRadius;

  /// The node whose label is emphasised, if any.
  final String? selectedNodeId;

  final Paint _fill = Paint();
  final Paint _border = Paint();
  late final KumoSankeySolver _solver = KumoSankeySolver(
    graph: graph,
    nodeWidth: nodeWidth,
    nodePadding: nodePadding,
  );

  late List<RRect> _rects;
  late List<TextPainter> _labels;
  late List<Offset> _labelOffsets;
  late Rect _plot;
  late Rect _clip;
  late Color _labelColor;
  late Color _selectedLabelColor;

  @override
  void prepare() {
    _plot = context.geometry.plot;
    _clip = Rect.fromLTWH(0, 0, _plot.width, _plot.height);
    _solver.layout(
      width: _plot.width,
      height: _plot.height,
      nodeLayouts: nodeLayouts,
      linkLayouts: linkLayouts,
    );

    _fill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    _border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = context.colors.border
      ..isAntiAlias = true;

    _labelColor = context.colors.textMuted;
    _selectedLabelColor = context.colors.textPrimary;

    final TextStyle style = context.styles.caption;
    final Radius radius = Radius.circular(nodeRadius);
    final int nodeCount = graph.nodes.length;
    final int lastColumn = _solver.columnCount - 1;

    _rects = List<RRect>.generate(nodeCount, (int i) {
      final KumoSankeyNodeLayout layout = nodeLayouts[i];
      return RRect.fromRectAndRadius(
        Rect.fromLTWH(layout.x, layout.y, layout.width, layout.height),
        radius,
      );
    });
    _labels = List<TextPainter>.generate(nodeCount, (int i) {
      return TextPainter(
        text: TextSpan(
          text: _labelOf(graph.nodes[i]),
          style: style.copyWith(
            color: graph.nodes[i].id == selectedNodeId
                ? _selectedLabelColor
                : _labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
    });
    // Positions are resolved here, not in paint, so the label pass allocates
    // nothing at all.
    _labelOffsets = List<Offset>.generate(nodeCount, (int i) {
      final KumoSankeyNodeLayout layout = nodeLayouts[i];
      final TextPainter label = _labels[i];
      final bool terminal = layout.depth == lastColumn;
      final double dx = terminal
          ? layout.x - label.width - 6
          : layout.x + layout.width + 6;
      return Offset(dx, layout.y + layout.height / 2 - label.height / 2);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final int nodeCount = graph.nodes.length;
    canvas
      ..save()
      ..translate(_plot.left, _plot.top)
      ..clipRect(_clip);

    for (int i = 0; i < nodeCount; i++) {
      _fill.color = _slotColor(graph.nodes[i], i);
      canvas
        ..drawRRect(_rects[i], _fill)
        ..drawRRect(_rects[i], _border);
    }
    for (int i = 0; i < nodeCount; i++) {
      _labels[i].paint(canvas, _labelOffsets[i]);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant KumoSankeyBackgroundLayer oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      !identical(oldDelegate.graph, graph) ||
      oldDelegate.selectedNodeId != selectedNodeId ||
      oldDelegate.nodeWidth != nodeWidth ||
      oldDelegate.nodePadding != nodePadding ||
      oldDelegate.nodeRadius != nodeRadius;
}

/// Draws the flows as ribbons.
///
/// A ribbon is a closed path: two horizontal cubic segments joined by straight
/// end caps. Both ends are as thick as the flow, because both scale the same
/// value by the same factor, so the shape carries the magnitude. A stroke could
/// not — a stroke has one width along its whole length — which is why the
/// ribbons are filled rather than stroked.
///
/// The horizontal control points sit at the midpoint of the run, giving the
/// curve its characteristic S. Every `Paint`, its gradient shader and the one
/// reusable `Path` are built in [prepare]; the paint body resets that path and
/// refills it, and constructs no `Offset` or `Rect` at all.
class KumoSankeyForegroundLayer extends KumoChartLayer {
  /// Creates the ribbon layer.
  KumoSankeyForegroundLayer({
    required super.context,
    required this.graph,
    required this.nodeLayouts,
    required this.linkLayouts,
    this.nodeWidth = 12,
    this.nodePadding = 10,
    this.chartColors = const KumoChartColors(),
    this.ribbonOpacity = 0.45,
  });

  /// The graph being drawn.
  final KumoSankeyGraph graph;

  /// Node geometry, written by the solver in [prepare].
  final List<KumoSankeyNodeLayout> nodeLayouts;

  /// Link geometry, written by the solver in [prepare].
  final List<KumoSankeyLinkLayout> linkLayouts;

  /// Node thickness. Mirrors the solver's own setting.
  final double nodeWidth;

  /// Minimum vertical gap between nodes in a column.
  final double nodePadding;

  /// The chart palette.
  final KumoChartColors chartColors;

  /// Ribbon alpha. Ribbons cross, so they have to be able to overlap legibly.
  final double ribbonOpacity;

  final Path _ribbon = Path();
  late final KumoSankeySolver _solver = KumoSankeySolver(
    graph: graph,
    nodeWidth: nodeWidth,
    nodePadding: nodePadding,
  );

  late List<Paint> _ribbonPaints;
  late Rect _plot;
  late Rect _clip;

  @override
  void prepare() {
    _plot = context.geometry.plot;
    _clip = Rect.fromLTWH(0, 0, _plot.width, _plot.height);
    _solver.layout(
      width: _plot.width,
      height: _plot.height,
      nodeLayouts: nodeLayouts,
      linkLayouts: linkLayouts,
    );

    _ribbonPaints = List<Paint>.generate(graph.links.length, (int l) {
      final Paint paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      final KumoSankeyLinkLayout layout = linkLayouts[l];
      if (!layout.isPlaced) {
        return paint;
      }

      final KumoSankeyNodeLayout source = nodeLayouts[layout.sourceIndex];
      final KumoSankeyNodeLayout target = nodeLayouts[layout.targetIndex];
      final double left = source.x + source.width;
      final double right = target.x;
      final double top = math.min(layout.sourceTop, layout.targetTop);
      final double bottom = math.max(layout.sourceBottom, layout.targetBottom);

      // A ribbon that does not travel left to right — a cycle, or a link within
      // one column — has no gradient axis to span, so it takes the source
      // colour flat rather than a shader over a degenerate rect.
      if (right <= left || bottom <= top) {
        paint.color = _slotColor(
          graph.nodes[layout.sourceIndex],
          layout.sourceIndex,
        ).withValues(alpha: ribbonOpacity);
        return paint;
      }

      paint.shader = LinearGradient(
        colors: <Color>[
          _slotColor(
            graph.nodes[layout.sourceIndex],
            layout.sourceIndex,
          ).withValues(alpha: ribbonOpacity),
          _slotColor(
            graph.nodes[layout.targetIndex],
            layout.targetIndex,
          ).withValues(alpha: ribbonOpacity),
        ],
      ).createShader(Rect.fromLTRB(left, top, right, bottom));
      return paint;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final int linkCount = graph.links.length;
    canvas
      ..save()
      ..translate(_plot.left, _plot.top)
      ..clipRect(_clip);

    for (int l = 0; l < linkCount; l++) {
      final KumoSankeyLinkLayout layout = linkLayouts[l];
      if (!layout.isPlaced) {
        continue;
      }
      final KumoSankeyNodeLayout source = nodeLayouts[layout.sourceIndex];
      final KumoSankeyNodeLayout target = nodeLayouts[layout.targetIndex];
      final double startX = source.x + source.width;
      final double endX = target.x;
      final double control = (endX - startX) / 2;

      _ribbon.reset();
      _ribbon.moveTo(startX, layout.sourceTop);
      _ribbon.cubicTo(
        startX + control,
        layout.sourceTop,
        endX - control,
        layout.targetTop,
        endX,
        layout.targetTop,
      );
      _ribbon.lineTo(endX, layout.targetBottom);
      _ribbon.cubicTo(
        endX - control,
        layout.targetBottom,
        startX + control,
        layout.sourceBottom,
        startX,
        layout.sourceBottom,
      );
      _ribbon.close();
      canvas.drawPath(_ribbon, _ribbonPaints[l]);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant KumoSankeyForegroundLayer oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      !identical(oldDelegate.graph, graph) ||
      oldDelegate.nodeWidth != nodeWidth ||
      oldDelegate.nodePadding != nodePadding ||
      oldDelegate.ribbonOpacity != ribbonOpacity;
}
