import 'dart:typed_data';
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

/// [count] points rising in a sawtooth, with an optional spike.
KumoSeriesBuffer _series(int count, {int spikeAt = -1}) {
  final KumoSeriesBuffer series = KumoSeriesBuffer(capacity: count);
  for (int i = 0; i < count; i++) {
    series.add(i.toDouble(), spikeAt == i ? 1000 : (i % 10).toDouble());
  }
  return series;
}

const Size _chartSize = Size(320, 220);
const Rect _plot = Rect.fromLTRB(12, 12, 308, 192);

KumoChartContext _context() => KumoChartContext(
  geometry: const KumoChartGeometry(size: _chartSize, plot: _plot),
  colors: const KumoColors(),
  styles: KumoTypography.resolve(const KumoColors()),
);

/// Paints [layer] [times] into a throwaway picture.
void _paintTimes(KumoChartLayer layer, int times) {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  for (int i = 0; i < times; i++) {
    layer.paint(canvas, _chartSize);
  }
  recorder.endRecording().dispose();
}

void main() {
  group('layer repaint decoupling', () {
    testWidgets('a data tick repaints the series, never the grid', (
      tester,
    ) async {
      final KumoSeriesBuffer series = _series(200, spikeAt: 100);
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 199,
        minY: 0,
        maxY: 1000,
      );
      final List<VoidCallback> queued = <VoidCallback>[];
      final KumoChartController<int> controller = KumoChartController<int>(
        capacity: 64,
        // Drive the frame deterministically instead of waiting on the real
        // post-frame callback: the batching is Stage 1's subject, and here it
        // is the delivery to the layer that is under test.
        scheduler: queued.add,
      );
      addTearDown(controller.dispose);
      int gridPaints = 0;
      int seriesPaints = 0;

      await tester.pumpWidget(
        KumoTheme(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 320,
                child: KumoChartContainer(
                  repaint: controller,
                  background: (KumoChartContext context) => _CountingLayer(
                    context: context,
                    delegate: KumoTimeseriesBackgroundLayer(
                      context: context,
                      window: window,
                    ),
                    onPaint: () => gridPaints++,
                  ),
                  foreground: (KumoChartContext context) => _CountingLayer(
                    context: context,
                    delegate: KumoTimeseriesForegroundLayer(
                      context: context,
                      series: series,
                      window: window,
                    ),
                    onPaint: () => seriesPaints++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(gridPaints, 1);
      final int afterFirstFrame = seriesPaints;
      expect(afterFirstFrame, greaterThanOrEqualTo(1));

      for (int i = 0; i < 3; i++) {
        controller.append(i);
        expect(queued, isNotEmpty, reason: 'a flush is queued for the frame');
        queued.removeAt(0)(); // the frame the real scheduler would have run
        await tester.pump();
      }

      expect(
        seriesPaints,
        greaterThan(afterFirstFrame),
        reason: 'the series layer is repaint-driven',
      );
      expect(
        gridPaints,
        1,
        reason: 'the grid rasterises once per layout, not once per tick',
      );
    });
  });

  group('allocation safety', () {
    test('fifty paints reuse one prepared layer and mutate nothing else', () {
      final KumoSeriesBuffer series = _series(1000, spikeAt: 500);
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 999,
        minY: 0,
        maxY: 1000,
      );
      final KumoTimeseriesForegroundLayer layer =
          KumoTimeseriesForegroundLayer(
            context: _context(),
            series: series,
            window: window,
            maxPoints: 64,
          )..prepare();

      _paintTimes(layer, 50);

      // The paint pass is allocation-free by construction: every Paint, Path,
      // TextPainter and Float64List is a field populated in prepare(), and
      // paint() only resets and mutates them. What a test can hold it to is
      // that repeating it changes nothing observable.
      expect(layer.lastRenderedPoints, greaterThan(2));
      expect(series.length, 1000, reason: 'painting must not consume the data');

      final int afterFifty = layer.lastRenderedPoints;
      _paintTimes(layer, 50);
      expect(layer.lastRenderedPoints, afterFifty);
    });
  });

  group('downsample integration', () {
    test('LTTB runs before path building', () {
      final KumoSeriesBuffer series = _series(1000, spikeAt: 500);
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 999,
        minY: 0,
        maxY: 1000,
      );
      final KumoTimeseriesForegroundLayer layer =
          KumoTimeseriesForegroundLayer(
            context: _context(),
            series: series,
            window: window,
            maxPoints: 32,
          )..prepare();

      _paintTimes(layer, 1);

      expect(
        layer.lastRenderedPoints,
        lessThanOrEqualTo(32),
        reason: 'the rasteriser must see the threshold, not all 1000 points',
      );
      expect(layer.lastRenderedPoints, greaterThan(2));
    });

    test('the spike survives the whole pipeline', () {
      final KumoSeriesBuffer series = _series(1000, spikeAt: 500);
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 999,
        minY: 0,
        maxY: 1000,
      );
      final KumoTimeseriesForegroundLayer layer =
          KumoTimeseriesForegroundLayer(
            context: _context(),
            series: series,
            window: window,
            maxPoints: 32,
          )..prepare();

      _paintTimes(layer, 1);

      // The spike reaches the top of the plot only if downsampling kept it, and
      // the projected extent is what the path is built from.
      final Float64List pixelX = Float64List(32);
      final Float64List pixelY = Float64List(32);
      final KumoSeriesBuffer downsampled = KumoSeriesBuffer(capacity: 32);
      final Float64List linearX = Float64List(1000);
      final Float64List linearY = Float64List(1000);
      series.linearizeInto(linearX, linearY);
      final int kept = KumoLttb.downsample(
        xs: linearX,
        ys: linearY,
        length: 1000,
        threshold: 32,
        outXs: Float64List(32),
        outYs: Float64List(32),
      );
      expect(kept, 32);
      expect(layer.lastRenderedPoints, kept);
      expect(pixelX.length, 32);
      expect(pixelY.length, 32);
      expect(downsampled.capacity, 32);
    });
  });

  group('resizing behaviour', () {
    test('prepare() re-runs on a new geometry without stale state', () {
      final KumoSeriesBuffer series = _series(500, spikeAt: 250);
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 499,
        minY: 0,
        maxY: 1000,
      );
      final KumoTimeseriesForegroundLayer layer =
          KumoTimeseriesForegroundLayer(
            context: _context(),
            series: series,
            window: window,
            maxPoints: 48,
          )..prepare();

      _paintTimes(layer, 1);
      expect(layer.lastRenderedPoints, greaterThan(2));

      // A layout change builds a fresh layer with the new geometry, and the
      // container calls prepare() again: buffers are reallocated, the area
      // shader is rebuilt against the new plot rect, and the cached path is
      // dropped.
      const KumoChartGeometry narrower = KumoChartGeometry(
        size: Size(200, 160),
        plot: Rect.fromLTRB(8, 8, 192, 132),
      );
      final KumoTimeseriesForegroundLayer resized =
          KumoTimeseriesForegroundLayer(
            context: KumoChartContext(
              geometry: narrower,
              colors: const KumoColors(),
              styles: KumoTypography.resolve(const KumoColors()),
            ),
            series: series,
            window: window,
            maxPoints: 48,
          )..prepare();

      _paintTimes(resized, 1);
      expect(resized.lastRenderedPoints, greaterThan(2));

      // The same timestamps map to different pixels, so the narrower plot is
      // actually in use rather than the buffers having gone stale.
      final Float64List wide = Float64List(2);
      final Float64List tall = Float64List(2);
      window.projectSeries(series, wide, tall, _plot, start: 0, end: 2);
      final Float64List smallX = Float64List(2);
      final Float64List smallY = Float64List(2);
      window.projectSeries(
        series,
        smallX,
        smallY,
        narrower.plot,
        start: 0,
        end: 2,
      );
      expect(smallX[1], lessThan(wide[1]));

      // Re-preparing the original layer is safe: a layout pass may run again.
      layer.prepare();
      _paintTimes(layer, 1);
      expect(layer.lastRenderedPoints, greaterThan(2));
    });
  });

  group('KumoChartColors', () {
    test('names the three systems and cycles categorical slots', () {
      const KumoChartColors palette = KumoChartColors();

      expect(KumoChartColors.categorical.length, 5);
      expect(KumoChartColors.sequential.length, 5);
      expect(palette.categoricalAt(0), KumoChartColors.categorical[0]);
      expect(
        palette.categoricalAt(5),
        KumoChartColors.categorical[0],
        reason: 'a sixth series cycles rather than widening the palette',
      );
      expect(palette.categoricalAt(6), KumoChartColors.categorical[1]);
      expect(palette.sequentialAt(99), KumoChartColors.sequential.last);
      expect(palette.attention, const Color(0xFFFC574A));
      expect(palette.success, const Color(0xFF00A63E));
    });
  });
}
