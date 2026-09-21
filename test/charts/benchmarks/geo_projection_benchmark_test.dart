import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

/// Coordinates projected per measured pass.
const int _coords = 10000;

/// Warm-up passes so the JIT settles before anything is timed.
const int _warmup = 200;

/// Measured view-matrix builds. Cheap enough that 2000 of them stay fast.
const int _iterations = 2000;

/// Measured whole-buffer projection passes.
const int _projectionIterations = 50;

/// Plot box the projection maps into, as a painter would hand it over.
const double _left = 0;
const double _top = 0;
const double _width = 640;
const double _height = 360;

/// A grid of coordinates around the eastern United States, so the bounds have
/// both axes populated and the fit is not degenerate.
Float64List _longitudes() {
  final Float64List values = Float64List(_coords);
  for (int i = 0; i < _coords; i++) {
    values[i] = -125 + (i % 100) * 0.5;
  }
  return values;
}

Float64List _latitudes() {
  final Float64List values = Float64List(_coords);
  for (int i = 0; i < _coords; i++) {
    values[i] = 25 + (i ~/ 100) * 0.5;
  }
  return values;
}

KumoGeoBounds _bounds(
  KumoGeoProjection projection,
  Float64List longitudes,
  Float64List latitudes,
) {
  KumoGeoBounds bounds = const KumoGeoBounds.empty();
  for (int i = 0; i < _coords; i++) {
    bounds = bounds.expandedWith(projection, longitudes[i], latitudes[i]);
  }
  return bounds;
}

void main() {
  const KumoGeoProjection projection = KumoGeoProjection();
  late Float64List longitudes;
  late Float64List latitudes;
  late KumoGeoBounds bounds;
  late KumoGeoProjector projector;
  late Float64List pixels;

  setUp(() {
    longitudes = _longitudes();
    latitudes = _latitudes();
    bounds = _bounds(projection, longitudes, latitudes);
    projector = KumoGeoProjector(projection: projection, bounds: bounds);
    pixels = Float64List(_coords * 2);
  });

  test('building the view matrix is a microsecond-scale pass', () {
    for (int i = 0; i < _warmup; i++) {
      projector.computeViewMatrix(
        left: _left,
        top: _top,
        width: _width,
        height: _height,
        zoom: 2,
      );
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    for (int i = 0; i < _iterations; i++) {
      projector.computeViewMatrix(
        left: _left,
        top: _top,
        width: _width,
        height: _height,
        zoom: 2,
      );
    }
    stopwatch.stop();

    final double microsPerCall = stopwatch.elapsedMicroseconds / _iterations;
    // ignore: avoid_print
    print(
      'KumoGeoProjector.computeViewMatrix: '
      '${microsPerCall.toStringAsFixed(3)}us/call '
      '($_iterations fit+zoom passes over bounds ${bounds.width.toStringAsFixed(3)}'
      'x${bounds.height.toStringAsFixed(3)})',
    );

    expect(
      microsPerCall,
      lessThan(200),
      reason: 'a fit and a zoom are affine entries, not a re-projection',
    );
  });

  test('panning is a focus change, so it costs no geometry work', () {
    final view = projector.computeViewMatrix(
      left: _left,
      top: _top,
      width: _width,
      height: _height,
    );
    final double scale = KumoGeoProjector.scaleOf(view);
    expect(scale, greaterThan(0));

    const double delta = 0.02;
    final panned = projector.computeViewMatrix(
      left: _left,
      top: _top,
      width: _width,
      height: _height,
      focusX: bounds.centerX + delta,
    );

    // Pan moves the point held at the centre, which moves only the translation
    // the fit baked in. The scale is untouched, so no geometry is rebuilt.
    expect(KumoGeoProjector.scaleOf(panned), scale);
    expect(
      KumoGeoProjector.translationX(panned) -
          KumoGeoProjector.translationX(view),
      moreOrLessEquals(-delta * scale, epsilon: 1e-6),
    );

    final Stopwatch stopwatch = Stopwatch()..start();
    double lastY = 0;
    for (int i = 0; i < _iterations; i++) {
      lastY = KumoGeoProjector.translationY(panned) + i * 0.001;
    }
    stopwatch.stop();

    final double nanosPerCall =
        stopwatch.elapsedMicroseconds * 1000 / _iterations;
    // ignore: avoid_print
    print(
      'KumoGeoProjector.translation read: '
      '${nanosPerCall.toStringAsFixed(1)}ns/call (scale $scale)',
    );

    expect(lastY, greaterThan(KumoGeoProjector.translationY(panned)));
    expect(nanosPerCall, lessThan(5000));
  });

  test('projecting 10,000 points writes through the caller buffer', () {
    final view = projector.computeViewMatrix(
      left: _left,
      top: _top,
      width: _width,
      height: _height,
      zoom: 1.5,
    );

    for (int i = 0; i < 5; i++) {
      projector.projectInto(
        longitudes: longitudes,
        latitudes: latitudes,
        length: _coords,
        view: view,
        outPixels: pixels,
      );
    }

    final int pixelsIdentity = identityHashCode(pixels);
    final int pixelsBytes = pixels.buffer.lengthInBytes;
    final double lastPixelBefore = pixels[_coords * 2 - 1];

    final Stopwatch stopwatch = Stopwatch()..start();
    for (int i = 0; i < _projectionIterations; i++) {
      projector.projectInto(
        longitudes: longitudes,
        latitudes: latitudes,
        length: _coords,
        view: view,
        outPixels: pixels,
      );
    }
    stopwatch.stop();

    final double microsPerPass =
        stopwatch.elapsedMicroseconds / _projectionIterations;
    final double nanosPerPoint = microsPerPass * 1000 / _coords;
    // ignore: avoid_print
    print(
      'KumoGeoProjector.projectInto: $_coords points in '
      '${microsPerPass.toStringAsFixed(1)}us/pass '
      '(${nanosPerPoint.toStringAsFixed(1)}ns/point)',
    );

    // Dart exposes no allocation counter, so the observable half of the
    // "allocates nothing" claim is asserted: the same caller-owned buffer, same
    // identity and same byte length, overwritten in place and never grown.
    expect(identityHashCode(pixels), pixelsIdentity);
    expect(pixels.buffer.lengthInBytes, pixelsBytes);
    expect(pixels.length, _coords * 2);
    expect(pixels.last, lastPixelBefore);

    expect(microsPerPass, lessThan(20000));
    expect(
      nanosPerPoint,
      lessThan(5000),
      reason: 'per-point projection is a multiply-add, not a transform3',
    );

    // Zoom above 1 deliberately lets the content overflow the plot, so the
    // invariant to hold is the aspect-correct *centred* fit: the projected box
    // stays centred on the plot and keeps the bounds' aspect ratio.
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (int i = 0; i < _coords; i++) {
      final double x = pixels[i * 2];
      final double y = pixels[i * 2 + 1];
      if (x < minX) {
        minX = x;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (y > maxY) {
        maxY = y;
      }
    }
    expect((minX + maxX) / 2, moreOrLessEquals(_left + _width / 2, epsilon: 1));
    expect((minY + maxY) / 2, moreOrLessEquals(_top + _height / 2, epsilon: 1));
    expect(
      (maxX - minX) / (maxY - minY),
      moreOrLessEquals(bounds.width / bounds.height, epsilon: 0.01),
      reason: 'a map must not stretch with the aspect ratio of its box',
    );

    // At zoom 1 the whole box fits inside the plot.
    final fitted = projector.computeViewMatrix(
      left: _left,
      top: _top,
      width: _width,
      height: _height,
    );
    final Float64List fittedPixels = Float64List(_coords * 2);
    projector.projectInto(
      longitudes: longitudes,
      latitudes: latitudes,
      length: _coords,
      view: fitted,
      outPixels: fittedPixels,
    );
    for (int i = 0; i < _coords; i++) {
      expect(
        fittedPixels[i * 2],
        inInclusiveRange(_left - 0.5, _left + _width + 0.5),
      );
      expect(
        fittedPixels[i * 2 + 1],
        inInclusiveRange(_top - 0.5, _top + _height + 0.5),
      );
    }
  });

  test('growing bounds across the mapped box stays linear', () {
    final Stopwatch stopwatch = Stopwatch()..start();
    KumoGeoBounds accumulator = const KumoGeoBounds.empty();
    for (int i = 0; i < _coords; i++) {
      accumulator = accumulator.expandedWith(
        projection,
        longitudes[i],
        latitudes[i],
      );
    }
    stopwatch.stop();

    final double microsPerPoint = stopwatch.elapsedMicroseconds / _coords;
    // ignore: avoid_print
    print(
      'KumoGeoBounds.expandedWith: ${microsPerPoint.toStringAsFixed(4)}us/point '
      '($_coords points)',
    );

    expect(accumulator, bounds, reason: 'a second pass derives the same box');
    expect(microsPerPoint, lessThan(50));
  });
}
