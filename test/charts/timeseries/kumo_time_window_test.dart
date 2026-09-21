import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

/// A series at `x = 0..length-1`, `y = x * 10`.
KumoSeriesBuffer _series(int length) {
  final KumoSeriesBuffer series = KumoSeriesBuffer(capacity: length);
  for (int i = 0; i < length; i++) {
    series.add(i.toDouble(), (i * 10).toDouble());
  }
  return series;
}

const Rect _plot = Rect.fromLTRB(10, 20, 210, 120);

void main() {
  group('timestamp to x', () {
    test('maps the window edges to the plot edges', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 100,
        maxTimestamp: 200,
      );

      expect(window.normalizedX(100), 0);
      expect(window.normalizedX(200), 1);
      expect(window.normalizedX(150), 0.5);

      final Vector3 left = window.projectPoint(100, 0, _plot);
      final Vector3 right = window.projectPoint(200, 0, _plot);
      expect(left.x, _plot.left);
      expect(right.x, _plot.right);
    });

    test('maps a midpoint halfway across the plot', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 1000,
      );

      expect(window.projectPoint(250, 0, _plot).x, _plot.left + 0.25 * _plot.width);
    });
  });

  group('value to y', () {
    test('inverts the canvas axis so the maximum sits on top', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 10,
        minY: 0,
        maxY: 100,
      );

      expect(window.normalizedY(0), 0);
      expect(window.normalizedY(100), 1);
      expect(window.normalizedY(50), 0.5);

      expect(window.projectPoint(0, 100, _plot).y, _plot.top);
      expect(window.projectPoint(0, 0, _plot).y, _plot.bottom);
      expect(window.projectPoint(0, 50, _plot).y, _plot.center.dy);
    });
  });

  group('sliding viewport', () {
    test('slideBy shifts the output linearly', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 100,
      );
      final double before = window.projectPoint(50, 0, _plot).x;

      window.slideBy(10);
      expect(window.minTimestamp, 10);
      expect(window.maxTimestamp, 110);
      expect(window.timeSpan, 100, reason: 'sliding must not rescale');

      // A point 10 later lands exactly where the original did.
      expect(window.projectPoint(60, 0, _plot).x, before);
      expect(window.projectPoint(50, 0, _plot).x, lessThan(before));
    });

    test('slideTo keeps the duration', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 100,
      );

      window.slideTo(500);
      expect(window.minTimestamp, 400);
      expect(window.maxTimestamp, 500);
      expect(window.normalizedX(450), 0.5);
    });

    test('updateTranslation matches a full recompute after a slide', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 100,
        minY: 0,
        maxY: 100,
      );
      final Matrix4 matrix = window.computeDomainTransform(_plot);

      window.slideBy(25);
      window.updateTranslation(matrix, _plot);

      final Matrix4 rebuilt = window.computeDomainTransform(_plot);
      final Vector3 fromUpdate = matrix.transform3(Vector3(75, 25, 0));
      final Vector3 fromRebuild = rebuilt.transform3(Vector3(75, 25, 0));

      expect(fromUpdate.x, closeTo(fromRebuild.x, 1e-9));
      expect(fromUpdate.y, closeTo(fromRebuild.y, 1e-9));
      expect(matrix.entry(0, 0), rebuilt.entry(0, 0), reason: 'scale untouched');
    });
  });

  group('Matrix4 transform', () {
    test('the normalized transform matches direct projection', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 10,
        minY: 0,
        maxY: 10,
      );
      final Matrix4 matrix = window.computeTransform(_plot);

      for (final double t in <double>[0, 2.5, 7.5, 10]) {
        for (final double v in <double>[0, 4, 10]) {
          final Vector3 throughMatrix = matrix.transform3(
            Vector3(window.normalizedX(t), window.normalizedY(v), 0),
          );
          final Vector3 direct = window.projectPoint(t, v, _plot);
          expect(throughMatrix.x, closeTo(direct.x, 1e-9));
          expect(throughMatrix.y, closeTo(direct.y, 1e-9));
        }
      }
    });

    test('the domain transform matches the batch projection pass', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 9,
        minY: 0,
        maxY: 90,
      );
      final KumoSeriesBuffer series = _series(10);
      final Float64List outX = Float64List(10);
      final Float64List outY = Float64List(10);
      final int count = window.projectSeries(series, outX, outY, _plot);
      final Matrix4 matrix = window.computeDomainTransform(_plot);

      expect(count, 10);
      for (int i = 0; i < 10; i++) {
        final Vector3 throughMatrix = matrix.transform3(
          Vector3(series.xAt(i), series.yAt(i), 0),
        );
        expect(outX[i], closeTo(throughMatrix.x, 1e-9));
        expect(outY[i], closeTo(throughMatrix.y, 1e-9));
      }
    });
  });

  group('zero-allocation projection', () {
    test('writes into the caller-owned buffers and returns a count', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 9,
        minY: 0,
        maxY: 90,
      );
      final KumoSeriesBuffer series = _series(10);
      final Float64List outX = Float64List(10)..fillRange(0, 10, -1);
      final Float64List outY = Float64List(10)..fillRange(0, 10, -1);

      final int count = window.projectSeries(series, outX, outY, _plot);

      expect(count, 10);
      // Mutated in place: the identities are unchanged and the sentinels are
      // gone. The API returns a count rather than a list, so no projection pass
      // can allocate one.
      expect(outX[0], _plot.left);
      expect(outX[9], _plot.right);
      expect(outY[0], _plot.bottom);
      expect(outY[9], _plot.top);
      expect(outX.every((double value) => value != -1), isTrue);
    });

    test('honours a sub-range without touching the rest of the buffer', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 9,
        minY: 0,
        maxY: 90,
      );
      final KumoSeriesBuffer series = _series(10);
      final Float64List outX = Float64List(10)..fillRange(0, 10, -1);
      final Float64List outY = Float64List(10)..fillRange(0, 10, -1);

      final int count = window.projectSeries(
        series,
        outX,
        outY,
        _plot,
        start: 2,
        end: 5,
      );

      expect(count, 3);
      expect(outX[0], _plot.left + (2 / 9) * _plot.width);
      expect(outX[3], -1, reason: 'slots past the range are left alone');
    });
  });

  group('edge cases', () {
    test('a zero-width window collapses to the centre', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 42,
        maxTimestamp: 42,
      );

      expect(window.hasTimeSpan, isFalse);
      expect(window.normalizedX(42), 0.5);
      expect(window.projectPoint(42, 0, _plot).x, _plot.center.dx);
      expect(window.projectPoint(9999, 0, _plot).x, _plot.center.dx);
    });

    test('a flat series sits on the centre line', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 10,
        minY: 5,
        maxY: 5,
      );

      expect(window.hasValueSpan, isFalse);
      expect(window.normalizedY(5), 0.5);
      expect(window.normalizedY(-100), 0.5);
      expect(window.projectPoint(0, 5, _plot).y, _plot.center.dy);
    });

    test('an empty series projects nothing', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 10,
      );
      final KumoSeriesBuffer empty = KumoSeriesBuffer(capacity: 4);
      final Float64List outX = Float64List(0);
      final Float64List outY = Float64List(0);

      expect(window.projectSeries(empty, outX, outY, _plot), 0);
    });

    test('points outside the window are projected, not clamped', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 10,
        maxTimestamp: 20,
      );

      // Clamping in the maths would flatten a line against the border; the
      // painter clips instead.
      expect(window.normalizedX(5), -0.5);
      expect(window.normalizedX(25), 1.5);
      expect(window.containsTimestamp(5), isFalse);
      expect(window.containsTimestamp(15), isTrue);
    });

    test('containsValue respects the domain', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 1,
        minY: 0,
        maxY: 10,
      );

      expect(window.containsValue(0), isTrue);
      expect(window.containsValue(10), isTrue);
      expect(window.containsValue(10.1), isFalse);
    });
  });

  group('fitY', () {
    test('adds headroom on both ends', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 9,
        yPadding: 0.05,
      );

      window.fitY(_series(10));

      // Data spans 0..90, so 5% headroom is 4.5 either side.
      expect(window.minY, closeTo(-4.5, 1e-9));
      expect(window.maxY, closeTo(94.5, 1e-9));
    });

    test('can widen the domain to include zero', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 100,
        maxTimestamp: 110,
        includeZero: true,
        yPadding: 0,
      );

      window.fitY(_series(10));

      expect(window.minY, 0);
      expect(window.maxY, 90);
    });

    test('fits only the requested timestamp range', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 9,
        yPadding: 0,
      );

      // A spike at the end must not stretch the axis once it has scrolled off.
      window.fitY(_series(10), fromTimestamp: 0, toTimestamp: 4);

      expect(window.minY, 0);
      expect(window.maxY, 40);
    });

    test('leaves the domain alone for an empty series', () {
      final KumoTimeWindow window = KumoTimeWindow(
        minTimestamp: 0,
        maxTimestamp: 10,
        minY: 3,
        maxY: 7,
      );

      window.fitY(KumoSeriesBuffer(capacity: 4));

      expect(window.minY, 3);
      expect(window.maxY, 7);
    });
  });

  group('KumoTimeWindow.last', () {
    test('spans exactly the requested duration', () {
      final KumoTimeWindow window = KumoTimeWindow.last(
        const Duration(minutes: 5),
        endTimestamp: 1000,
      );

      expect(window.maxTimestamp, 1000);
      expect(window.minTimestamp, 700);
      expect(window.timeSpan, 300);
    });
  });
}
