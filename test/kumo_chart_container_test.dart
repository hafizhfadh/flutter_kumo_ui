import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

/// A layer that records how many times it painted, and its geometry.
class _CountingLayer extends KumoChartLayer {
  _CountingLayer({required super.context, required this.onPaint});

  final void Function(KumoChartContext context) onPaint;

  @override
  void paint(Canvas canvas, Size size) => onPaint(context);
}

void main() {
  group('KumoChartGeometry', () {
    testWidgets('carves the plot rect out of the insets', (tester) async {
      KumoChartGeometry? seen;
      await tester.pumpWidget(
        KumoTheme(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 320,
                child: KumoChartContainer(
                  height: 200,
                  insets: const EdgeInsets.fromLTRB(10, 20, 30, 40),
                  foreground: (KumoChartContext context) {
                    seen = context.geometry;
                    return _CountingLayer(context: context, onPaint: (_) {});
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(seen!.size, const Size(320, 200));
      expect(seen!.plot, const Rect.fromLTRB(10, 20, 290, 160));
    });
  });

  group('KumoChartContainer layer isolation', () {
    testWidgets('a data tick repaints the dynamic layer only', (tester) async {
      final ValueNotifier<int> ticks = ValueNotifier<int>(0);
      addTearDown(ticks.dispose);

      int backgroundPaints = 0;
      int foregroundPaints = 0;
      int overlayBuilds = 0;

      await tester.pumpWidget(
        KumoTheme(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 320,
                child: KumoChartContainer(
                  repaint: ticks,
                  background: (KumoChartContext context) => _CountingLayer(
                    context: context,
                    onPaint: (_) => backgroundPaints++,
                  ),
                  foreground: (KumoChartContext context) => _CountingLayer(
                    context: context,
                    onPaint: (_) => foregroundPaints++,
                  ),
                  overlay: Builder(
                    builder: (BuildContext context) {
                      overlayBuilds++;
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(backgroundPaints, 1);
      expect(foregroundPaints, 1);
      expect(overlayBuilds, 1);

      // Three data ticks.
      for (int i = 1; i <= 3; i++) {
        ticks.value = i;
        await tester.pump();
      }

      expect(foregroundPaints, 4, reason: 'the dynamic layer paints per tick');
      expect(
        backgroundPaints,
        1,
        reason: 'the static grid is behind a RepaintBoundary and must not '
            're-raster on a tick',
      );
      expect(
        overlayBuilds,
        1,
        reason: 'a tick repaints a layer, it does not rebuild the tree',
      );
    });

    testWidgets('the background layer is given no repaint listenable', (
      tester,
    ) async {
      final ValueNotifier<int> ticks = ValueNotifier<int>(0);
      addTearDown(ticks.dispose);

      Listenable? backgroundRepaint;
      Listenable? foregroundRepaint;

      await tester.pumpWidget(
        KumoTheme(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 320,
                child: KumoChartContainer(
                  repaint: ticks,
                  background: (KumoChartContext context) {
                    backgroundRepaint = context.repaint;
                    return _CountingLayer(context: context, onPaint: (_) {});
                  },
                  foreground: (KumoChartContext context) {
                    foregroundRepaint = context.repaint;
                    return _CountingLayer(context: context, onPaint: (_) {});
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(backgroundRepaint, isNull);
      expect(foregroundRepaint, same(ticks));
    });

    testWidgets('renders without a background layer', (tester) async {
      await tester.pumpWidget(
        KumoTheme(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 320,
                child: KumoChartContainer(
                  foreground: (KumoChartContext context) =>
                      _CountingLayer(context: context, onPaint: (_) {}),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('KumoChartLayer', () {
    test('repaints on a geometry change and not otherwise', () {
      const KumoChartContext a = KumoChartContext(
        geometry: KumoChartGeometry(
          size: Size(100, 50),
          plot: Rect.fromLTRB(0, 0, 100, 50),
        ),
        colors: KumoColors(),
        styles: KumoTextStyles(
          h1: TextStyle(fontSize: 24),
          h2: TextStyle(fontSize: 18),
          body: TextStyle(fontSize: 14),
          bodyMuted: TextStyle(fontSize: 14),
          caption: TextStyle(fontSize: 12),
          code: TextStyle(fontSize: 12),
        ),
      );
      const KumoChartContext same = KumoChartContext(
        geometry: KumoChartGeometry(
          size: Size(100, 50),
          plot: Rect.fromLTRB(0, 0, 100, 50),
        ),
        colors: KumoColors(),
        styles: KumoTextStyles(
          h1: TextStyle(fontSize: 24),
          h2: TextStyle(fontSize: 18),
          body: TextStyle(fontSize: 14),
          bodyMuted: TextStyle(fontSize: 14),
          caption: TextStyle(fontSize: 12),
          code: TextStyle(fontSize: 12),
        ),
      );
      const KumoChartContext resized = KumoChartContext(
        geometry: KumoChartGeometry(
          size: Size(200, 50),
          plot: Rect.fromLTRB(0, 0, 200, 50),
        ),
        colors: KumoColors(),
        styles: KumoTextStyles(
          h1: TextStyle(fontSize: 24),
          h2: TextStyle(fontSize: 18),
          body: TextStyle(fontSize: 14),
          bodyMuted: TextStyle(fontSize: 14),
          caption: TextStyle(fontSize: 12),
          code: TextStyle(fontSize: 12),
        ),
      );

      final _CountingLayer layer = _CountingLayer(
        context: a,
        onPaint: (_) {},
      );

      expect(
        layer.shouldRepaint(_CountingLayer(context: same, onPaint: (_) {})),
        isFalse,
      );
      expect(
        layer.shouldRepaint(_CountingLayer(context: resized, onPaint: (_) {})),
        isTrue,
      );
    });
  });
}
