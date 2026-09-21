import 'dart:ui' show PictureRecorder, Size;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

const double _width = 320;
const double _height = 220;
const EdgeInsets _insets = EdgeInsets.fromLTRB(12, 12, 12, 28);

KumoChartContext _context({Rect? plot}) => KumoChartContext(
  geometry: KumoChartGeometry(
    size: const Size(_width, _height),
    plot: plot ?? const Rect.fromLTRB(12, 12, 308, 192),
  ),
  colors: const KumoColors(),
  styles: KumoTypography.resolve(const KumoColors()),
);

/// Paints [layer] [times] into a throwaway picture.
void _paintTimes(KumoChartLayer layer, int times) {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  for (int i = 0; i < times; i++) {
    layer.paint(canvas, const Size(_width, _height));
  }
  recorder.endRecording().dispose();
}

Widget _host(Widget child) => KumoTheme(
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(width: _width, child: child),
    ),
  ),
);

void main() {
  group('KumoCanvasGridLayer', () {
    test('prepares once and paints a static grid however often', () {
      final KumoCanvasGridLayer layer = KumoCanvasGridLayer(
        context: _context(),
        divisions: 4,
      )..prepare();

      _paintTimes(layer, 25);

      // Dart exposes no allocation counter, so what is asserted is what is
      // observable: 25 paints neither crash nor change the layer's opinion of
      // itself. The allocation-freedom is structural — prepare() owns the only
      // Paint and Float32List, and paint() only writes into them.
      expect(
        layer.shouldRepaint(
          KumoCanvasGridLayer(context: _context(), divisions: 4),
        ),
        isFalse,
      );
      expect(
        layer.shouldRepaint(
          KumoCanvasGridLayer(context: _context(), divisions: 6),
        ),
        isTrue,
      );
    });

    test('an empty plot is a no-op rather than a crash', () {
      final KumoCanvasGridLayer layer = KumoCanvasGridLayer(
        context: _context(plot: Rect.zero),
      )..prepare();

      _paintTimes(layer, 3);
    });
  });

  group('context handed to the painter', () {
    testWidgets('carries the resolved tokens, styles and carved plot rect', (
      tester,
    ) async {
      KumoChartContext? seen;
      Size? seenSize;

      await tester.pumpWidget(
        _host(
          KumoCanvas(
            height: _height,
            insets: _insets,
            painter: (Canvas canvas, Size size, KumoChartContext context) {
              seen = context;
              seenSize = size;
            },
          ),
        ),
      );

      expect(seenSize, const Size(_width, _height));
      expect(seen!.geometry.size, const Size(_width, _height));
      expect(seen!.geometry.plot, const Rect.fromLTRB(12, 12, 308, 192));
      expect(seen!.colors, const KumoColors());
      expect(seen!.styles, KumoTypography.resolve(const KumoColors()));
      // No repaint binding was supplied, so the dynamic layer has none either.
      expect(seen!.repaint, isNull);
    });

    testWidgets('binds the foreground layer to the supplied listenable', (
      tester,
    ) async {
      final ValueNotifier<int> ticks = ValueNotifier<int>(0);
      addTearDown(ticks.dispose);

      final List<Listenable?> seen = <Listenable?>[];

      await tester.pumpWidget(
        _host(
          KumoCanvas(
            repaint: ticks,
            painter: (Canvas canvas, Size size, KumoChartContext context) {
              seen.add(context.repaint);
            },
          ),
        ),
      );

      expect(seen, isNotEmpty);
      expect(seen.first, same(ticks));
    });
  });

  group('repaint isolation', () {
    testWidgets('a tick re-runs the callback without rebuilding the tree', (
      tester,
    ) async {
      final ValueNotifier<int> ticks = ValueNotifier<int>(0);
      addTearDown(ticks.dispose);

      int paints = 0;
      int overlayBuilds = 0;

      await tester.pumpWidget(
        _host(
          KumoCanvas(
            repaint: ticks,
            painter: (Canvas canvas, Size size, KumoChartContext context) {
              paints++;
            },
            overlay: Builder(
              builder: (BuildContext context) {
                overlayBuilds++;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final int afterFirstFrame = paints;
      expect(afterFirstFrame, greaterThanOrEqualTo(1));
      expect(overlayBuilds, 1);

      for (int i = 1; i <= 3; i++) {
        ticks.value = i;
        await tester.pump();
      }

      expect(
        paints,
        afterFirstFrame + 3,
        reason: 'the custom painter is repaint-driven',
      );
      expect(
        overlayBuilds,
        1,
        reason: 'a tick repaints a layer, it does not rebuild the widget',
      );
    });
  });

  group('managed chrome', () {
    testWidgets('the grid is the static background slot', (tester) async {
      await tester.pumpWidget(
        _host(
          KumoCanvas(
            painter: (Canvas canvas, Size size, KumoChartContext context) {},
          ),
        ),
      );
      expect(
        find.byType(CustomPaint),
        findsNWidgets(2),
        reason: 'one managed grid layer behind one custom layer',
      );

      await tester.pumpWidget(
        _host(
          KumoCanvas(
            showGrid: false,
            painter: (Canvas canvas, Size size, KumoChartContext context) {},
          ),
        ),
      );
      expect(
        find.byType(CustomPaint),
        findsOneWidget,
        reason: 'showGrid: false drops the background layer entirely',
      );
    });

    testWidgets('renders without the surface chrome and with an overlay', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          KumoCanvas(
            showSurface: false,
            overlay: const Text('legend'),
            painter: (Canvas canvas, Size size, KumoChartContext context) {
              canvas.drawCircle(Offset.zero, 1, Paint());
            },
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('legend'), findsOneWidget);
    });

    testWidgets('draws through the raw Canvas without throwing', (
      tester,
    ) async {
      bool called = false;

      await tester.pumpWidget(
        _host(
          KumoCanvas(
            painter: (Canvas canvas, Size size, KumoChartContext context) {
              called = true;
              expect(size, const Size(_width, _height));
              expect(context.geometry.plot, isNot(Rect.zero));
              // The whole point of the escape hatch: a plain Canvas draw call.
              canvas.drawRect(context.geometry.plot, Paint());
            },
          ),
        ),
      );

      expect(called, isTrue);
    });
  });
}
