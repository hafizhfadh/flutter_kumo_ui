import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/widgets.dart';

import 'kumo_chart_container.dart';

/// Draws custom content into a [KumoCanvas].
///
/// The callback is handed everything it needs and nothing it has to work out:
/// the raw [Canvas], the full [Size] of the surface, and a
/// [KumoChartContext] carrying the resolved tokens, the type styles and
/// [KumoChartGeometry.plot] — the data area after the axes' room is taken out.
/// A custom visualiser therefore never calls `KumoTheme.of(context)` and never
/// does layout maths to find out where its data belongs.
typedef KumoCanvasPainter = void Function(
  Canvas canvas,
  Size size,
  KumoChartContext context,
);

/// The managed background layer [KumoCanvas] places behind a custom painter.
///
/// Draws the division gridlines in the hairline border token, plus a short tick
/// at each division on the left and bottom edges. Static by construction: it is
/// built from a [KumoChartContext] that carries no repaint listenable, so a data
/// tick can never rasterise it again — only a layout pass can.
///
/// Lines go out through `Canvas.drawRawPoints` against a pre-allocated
/// [Float32List], because `drawLine` takes [Offset] objects and would allocate
/// two per line per paint.
class KumoCanvasGridLayer extends KumoChartLayer {
  /// Creates the grid layer.
  KumoCanvasGridLayer({
    required super.context,
    this.divisions = 4,
    this.tickLength = 4,
  }) : assert(divisions > 0, 'divisions must be positive');

  /// Divisions per axis. A value of four draws five lines each way.
  final int divisions;

  /// Length of the axis tick marks, in device pixels.
  final double tickLength;

  final Paint _stroke = Paint();
  late Float32List _points;

  @override
  void prepare() {
    _stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = context.colors.border;
    // Four floats per segment: an x and a y at each end.
    _points = Float32List((divisions + 1) * 2 * 4);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect plot = context.geometry.plot;
    if (plot.isEmpty) {
      return;
    }

    int slot = 0;
    for (int i = 0; i <= divisions; i++) {
      final double t = i / divisions;

      final double y = plot.bottom - t * plot.height;
      _points[slot++] = plot.left;
      _points[slot++] = y;
      _points[slot++] = plot.right;
      _points[slot++] = y;

      final double x = plot.left + t * plot.width;
      _points[slot++] = x;
      _points[slot++] = plot.top;
      _points[slot++] = x;
      _points[slot++] = plot.bottom;
    }

    canvas.drawRawPoints(
      PointMode.lines,
      Float32List.sublistView(_points, 0, slot),
      _stroke,
    );

    // Ticks sit just outside the plot, so they read as an axis rather than as
    // two more gridlines.
    slot = 0;
    for (int i = 0; i <= divisions; i++) {
      final double t = i / divisions;

      final double x = plot.left + t * plot.width;
      _points[slot++] = x;
      _points[slot++] = plot.bottom;
      _points[slot++] = x;
      _points[slot++] = plot.bottom + tickLength;

      final double y = plot.bottom - t * plot.height;
      _points[slot++] = plot.left - tickLength;
      _points[slot++] = y;
      _points[slot++] = plot.left;
      _points[slot++] = y;
    }

    canvas.drawRawPoints(
      PointMode.lines,
      Float32List.sublistView(_points, 0, slot),
      _stroke,
    );
  }

  @override
  bool shouldRepaint(covariant KumoCanvasGridLayer oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      oldDelegate.divisions != divisions ||
      oldDelegate.tickLength != tickLength;
}

/// Bridges a [KumoCanvasPainter] callback to the layer contract.
class _KumoCanvasLayer extends KumoChartLayer {
  _KumoCanvasLayer({required super.context, required this.painter});

  final KumoCanvasPainter painter;

  @override
  void paint(Canvas canvas, Size size) => painter(canvas, size, context);

  @override
  bool shouldRepaint(covariant _KumoCanvasLayer oldDelegate) =>
      super.shouldRepaint(oldDelegate) || oldDelegate.painter != painter;
}

/// The escape hatch: a chart surface that hands you the raw [Canvas].
///
/// Every other component in this package decides what to draw. [KumoCanvas]
/// decides only the scaffolding around what you draw: it paints the surface fill
/// and outline, carves out the plot rect for the axes, lays down the gridlines
/// and axis ticks, resolves the active scheme's tokens, and splits the repaint —
/// and then gets out of the way.
///
/// ```dart
/// // `marker` is a field, allocated once — see the contract below.
/// KumoCanvas(
///   repaint: controller,
///   painter: (Canvas canvas, Size size, KumoChartContext context) {
///     final Rect plot = context.geometry.plot;
///     marker.color = context.colors.primary;
///     canvas.drawCircle(plot.center, 8, marker);
///   },
/// )
/// ```
///
/// ## The contract the handle comes with
///
/// The callback runs inside a paint pass, so it inherits the package's paint
/// discipline: declare `Paint`, `Path` and `TextPainter` outside the callback —
/// as fields on a widget's `State`, or above the `build` that returns this
/// widget — and only mutate them inside. A `Paint` constructed in the callback
/// is a `Paint` constructed every frame, which is exactly the cost the rest of
/// the subsystem exists to avoid. Build them from [KumoChartContext.colors] and
/// [KumoChartContext.styles] so they follow the scheme, and size anything
/// geometric against [KumoChartGeometry.plot].
///
/// ## Repainting without rebuilding
///
/// Pass [repaint] — normally a `KumoChartController` — and the callback is
/// re-run on every notification while the widget tree is left alone. The grid
/// sits behind its own `RepaintBoundary` on a context with no listenable, so a
/// tick repaints your drawing and nothing else.
class KumoCanvas extends StatelessWidget {
  /// Creates a custom-drawing chart surface.
  const KumoCanvas({
    super.key,
    required this.painter,
    this.repaint,
    this.height = 220,
    this.insets = const EdgeInsets.fromLTRB(12, 12, 12, 28),
    this.showSurface = true,
    this.showGrid = true,
    this.gridDivisions = 4,
    this.overlay,
  }) : assert(gridDivisions > 0, 'gridDivisions must be positive');

  /// Draws the content. Called once per layout, and again on every [repaint].
  final KumoCanvasPainter painter;

  /// Notified on a data change. The callback re-runs; the widget does not
  /// rebuild.
  final Listenable? repaint;

  /// Height of the surface. Width comes from the parent.
  final double height;

  /// Room reserved inside the surface for axes, before the plot rect is
  /// derived.
  final EdgeInsets insets;

  /// Whether to paint the token surface fill, outline and radius.
  final bool showSurface;

  /// Whether to lay down the managed gridlines and axis ticks.
  final bool showGrid;

  /// Divisions per grid axis.
  final int gridDivisions;

  /// Interaction chrome drawn above the drawing, such as a legend or a readout.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return KumoChartContainer(
      height: height,
      insets: insets,
      repaint: repaint,
      showSurface: showSurface,
      overlay: overlay,
      background: showGrid
          ? (KumoChartContext chartContext) => KumoCanvasGridLayer(
              context: chartContext,
              divisions: gridDivisions,
            )
          : null,
      foreground: (KumoChartContext chartContext) =>
          _KumoCanvasLayer(context: chartContext, painter: painter),
    );
  }
}
