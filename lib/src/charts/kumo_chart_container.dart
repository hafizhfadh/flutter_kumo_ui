import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';

/// The space a chart layer paints into.
///
/// [plot] is the data area after [KumoChartContainer.insets] are applied; [size]
/// is the full canvas. Both are resolved once per layout and handed to every
/// layer, so a painter never measures or insets anything itself.
@immutable
class KumoChartGeometry {
  /// Creates a geometry for one layout pass.
  const KumoChartGeometry({required this.size, required this.plot});

  /// Full canvas, including the room reserved for axes.
  final Size size;

  /// The data area: where series, ribbons and map paths belong.
  final Rect plot;

  @override
  bool operator ==(Object other) =>
      other is KumoChartGeometry && other.size == size && other.plot == plot;

  @override
  int get hashCode => Object.hash(size, plot);
}

/// Everything a chart layer needs, resolved once per layout.
///
/// Carrying the tokens in here is what keeps a `paint` body free of
/// `KumoTheme.of(context)` lookups and of freshly built `Paint` objects.
///
/// [repaint] is non-null only for the dynamic layer. A background layer is given
/// a context without it, so a static grid cannot accidentally become a
/// per-tick repaint.
@immutable
class KumoChartContext {
  /// Creates a layer context.
  const KumoChartContext({
    required this.geometry,
    required this.colors,
    required this.styles,
    this.repaint,
  });

  /// The layout this layer paints into.
  final KumoChartGeometry geometry;

  /// Semantic tokens for the active scheme.
  final KumoColors colors;

  /// Type tokens for the active scheme.
  final KumoTextStyles styles;

  /// The listenable this layer repaints on, or null for a static layer.
  final Listenable? repaint;

  /// The same context, with [repaint] attached. Used for the dynamic layer.
  KumoChartContext withRepaint(Listenable? listenable) => KumoChartContext(
    geometry: geometry,
    colors: colors,
    styles: styles,
    repaint: listenable,
  );

  @override
  bool operator ==(Object other) =>
      other is KumoChartContext &&
      other.geometry == geometry &&
      other.colors == colors &&
      other.repaint == repaint;

  @override
  int get hashCode => Object.hash(geometry, colors, repaint);
}

/// Builds one layer of a chart.
typedef KumoChartLayerBuilder = KumoChartLayer Function(KumoChartContext context);

/// Base class for a chart layer.
///
/// Subclasses must not build `Paint`, `Path` or `TextPainter` inside [paint]:
/// declare them as fields, size them against [KumoChartContext.geometry] in
/// [prepare] (called once per layout, outside the paint pass), and only mutate
/// them in [paint]. That is what keeps a streaming chart from allocating on
/// every frame.
abstract class KumoChartLayer extends CustomPainter {
  /// Creates a layer bound to [context].
  KumoChartLayer({required this.context}) : super(repaint: context.repaint);

  /// Geometry, tokens and the repaint listenable for this layer.
  final KumoChartContext context;

  /// Reusable helpers this layer may allocate (`Paint`, `Path`, `TextPainter`).
  ///
  /// Called once per layout, before the paint pass. The default does nothing.
  void prepare() {}

  @override
  bool shouldRepaint(covariant KumoChartLayer oldDelegate) =>
      oldDelegate.context.geometry != context.geometry ||
      oldDelegate.context.colors != context.colors;
}

/// The chart surface: a static layer, a dynamic layer, and an optional overlay.
///
/// The container exists to make one guarantee, which is the difference between a
/// chart that keeps up with a stream and one that does not: **a data tick
/// repaints only the dynamic layer.** The background sits behind its own
/// [RepaintBoundary] and is never handed a repaint listenable, so a grid, its
/// axis lines and its tick labels are rasterised once per layout rather than
/// once per frame. The widget tree is not rebuilt at all, because the dynamic
/// layer repaints through `CustomPainter.repaint` rather than through
/// `setState`.
///
/// ```dart
/// KumoChartContainer(
///   repaint: controller,
///   background: (KumoChartContext context) => KumoGridLayer(context: context),
///   foreground: (KumoChartContext context) =>
///       KumoLineLayer(context: context, series: series),
/// )
/// ```
class KumoChartContainer extends StatelessWidget {
  /// Creates a chart surface.
  const KumoChartContainer({
    super.key,
    required this.foreground,
    this.background,
    this.overlay,
    this.repaint,
    this.height = 220,
    this.insets = const EdgeInsets.fromLTRB(12, 12, 12, 28),
    this.showSurface = true,
  });

  /// The dynamic layer. Receives a context whose [KumoChartContext.repaint] is
  /// [repaint], so it repaints on every data tick.
  final KumoChartLayerBuilder foreground;

  /// The static layer: grid, axes, tick labels. Receives a context with no
  /// repaint listenable, and sits behind its own [RepaintBoundary].
  final KumoChartLayerBuilder? background;

  /// Interaction chrome drawn above the layers, such as a readout or a
  /// crosshair label. Not repainted by data ticks.
  final Widget? overlay;

  /// The listenable a data tick notifies, normally a `KumoChartController`.
  final Listenable? repaint;

  /// Height of the surface. Width comes from the parent.
  final double height;

  /// Room reserved inside the surface for axes, before [KumoChartGeometry.plot]
  /// is derived.
  final EdgeInsets insets;

  /// Whether to paint the token surface fill, outline and radius. Turn off to
  /// drop the chart into a card that already provides them.
  final bool showSurface;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final KumoChartGeometry geometry = KumoChartGeometry(
            size: Size(constraints.maxWidth, height),
            plot: Rect.fromLTRB(
              insets.left,
              insets.top,
              constraints.maxWidth - insets.right,
              height - insets.bottom,
            ),
          );
          final KumoChartContext base = KumoChartContext(
            geometry: geometry,
            colors: colors,
            styles: styles,
          );
          final KumoChartLayerBuilder? backgroundBuilder = background;

          return DecoratedBox(
            decoration: showSurface
                ? BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(8),
                  )
                : const BoxDecoration(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(showSurface ? 8 : 0),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (backgroundBuilder != null)
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: backgroundBuilder(base),
                        size: geometry.size,
                      ),
                    ),
                  // The dynamic layer is its own boundary too, so a tick cannot
                  // dirty an ancestor layer either.
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: foreground(base.withRepaint(repaint)),
                      size: geometry.size,
                    ),
                  ),
                  ?overlay,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
