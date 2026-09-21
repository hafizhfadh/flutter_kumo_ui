import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

const KumoGeoProjection _mercator = KumoGeoProjection();
const KumoGeoProjection _equirectangular = KumoGeoProjection(
  KumoGeoProjectionKind.equirectangular,
);

/// Projects one coordinate and returns it as `[x, y]`.
List<double> _pixel(
  KumoGeoProjector projector,
  Matrix4 view,
  double longitude,
  double latitude,
) {
  final Float64List out = Float64List(2);
  projector.projectPoint(
    longitude: longitude,
    latitude: latitude,
    view: view,
    out: out,
  );
  return <double>[out[0], out[1]];
}

void main() {
  group('projection precision', () {
    test('the equator and the prime meridian meet at the centre', () {
      // Both projections put the origin of the graticule at the middle of the
      // unit square.
      expect(_mercator.worldX(0), 0.5);
      expect(_mercator.worldY(0), 0.5);
      expect(_equirectangular.worldX(0), 0.5);
      expect(_equirectangular.worldY(0), 0.5);
    });

    test('longitude spans the square from edge to edge', () {
      expect(_mercator.worldX(-180), 0);
      expect(_mercator.worldX(180), 1);
      expect(_mercator.worldX(-90), 0.25);
      expect(_mercator.worldX(90), 0.75);
    });

    test('northerly latitude is a smaller y, because canvas y grows down', () {
      expect(_mercator.worldY(60), lessThan(_mercator.worldY(0)));
      expect(_mercator.worldY(-60), greaterThan(_mercator.worldY(0)));
    });

    test('equirectangular is linear in latitude', () {
      expect(_equirectangular.worldY(90), 0);
      expect(_equirectangular.worldY(45), 0.25);
      expect(_equirectangular.worldY(-90), 1);
    });

    test('mercator matches its closed form away from the equator', () {
      // (1 - ln(tan φ + sec φ) / π) / 2 at 45°.
      expect(_mercator.worldY(45), closeTo(0.35972503691520497, 1e-12));
      expect(_mercator.worldY(-45), closeTo(0.640274963084795, 1e-12));
      // The equator is the midpoint of the square, not of the latitude range.
      expect(_mercator.worldY(0), 0.5);
    });

    test('mercator caps latitude where the projection diverges', () {
      expect(_mercator.worldY(90), _mercator.worldY(KumoGeoProjection.maxLatitude));
      expect(_mercator.worldY(KumoGeoProjection.maxLatitude), closeTo(0, 1e-12));
      expect(
        _mercator.worldY(-KumoGeoProjection.maxLatitude),
        closeTo(1, 1e-12),
      );
    });

    test('equirectangular is unaffected by the mercator cap', () {
      expect(_equirectangular.worldY(90), 0);
    });

    test('longitude is clamped rather than wrapped', () {
      // Wrapping would send 180.9° to x = 0.0025 and blow up a bounding box.
      expect(_mercator.worldX(190), 1);
      expect(_mercator.worldX(-190), 0);
    });

    test('latitude and longitude round-trip', () {
      for (final double latitude in <double>[0, 12.5, -37.25, 60]) {
        expect(
          _mercator.worldToLatitude(_mercator.worldY(latitude)),
          closeTo(latitude, 1e-9),
        );
        expect(
          _equirectangular.worldToLatitude(
            _equirectangular.worldY(latitude),
          ),
          closeTo(latitude, 1e-9),
        );
      }
      for (final double longitude in <double>[-179, -90, 0, 45.5, 180]) {
        expect(
          _mercator.worldToLongitude(_mercator.worldX(longitude)),
          closeTo(longitude, 1e-9),
        );
      }
    });
  });

  group('bounding box auto-fit', () {
    test('a world-sized box maps the origin of the graticule to the plot centre',
        () {
      const KumoGeoProjector projector = KumoGeoProjector(
        projection: _mercator,
        bounds: KumoGeoBounds.world(),
      );
      final Matrix4 view = projector.computeViewMatrix(
        left: 0,
        top: 0,
        width: 400,
        height: 200,
      );

      expect(_pixel(projector, view, 0, 0), <double>[200, 100]);
    });

    test('the fit takes the smaller axis, so the aspect ratio is preserved', () {
      const KumoGeoProjector projector = KumoGeoProjector(
        projection: _mercator,
        bounds: KumoGeoBounds.world(),
      );

      // A square world in a 400x200 box can only be 200 across, so the scale is
      // one number for both axes rather than two.
      final Matrix4 wide = projector.computeViewMatrix(
        left: 0,
        top: 0,
        width: 400,
        height: 200,
      );
      expect(KumoGeoProjector.scaleOf(wide), 200);
      expect(wide.storage[0], wide.storage[5]);

      final Matrix4 tall = projector.computeViewMatrix(
        left: 0,
        top: 0,
        width: 200,
        height: 400,
      );
      expect(KumoGeoProjector.scaleOf(tall), 200);

      // The slack lands on the longer axis, split evenly.
      expect(KumoGeoProjector.translationX(wide), 100);
      expect(KumoGeoProjector.translationY(wide), 0);
    });

    test('the fit takes the constraining axis and centres the other', () {
      // 0°..10°E and 0°..10°N. Ten degrees of latitude at the equator projects
      // *taller* than ten degrees of longitude, so this box is not square even
      // though its degrees are: that is mercator, and it is why the height is
      // what constrains the fit rather than the width.
      final KumoGeoBounds bounds = const KumoGeoBounds.empty()
          .expandedWith(_mercator, 0, 10)
          .expandedWith(_mercator, 10, 0);
      expect(bounds.height, greaterThan(bounds.width));

      final KumoGeoProjector projector = KumoGeoProjector(
        projection: _mercator,
        bounds: bounds,
      );
      final Matrix4 view = projector.computeViewMatrix(
        left: 0,
        top: 0,
        width: 100,
        height: 100,
      );

      expect(KumoGeoProjector.scaleOf(view), closeTo(100 / bounds.height, 1e-9));

      // The box fills the plot vertically and leaves equal slack either side.
      final List<double> northWest = _pixel(projector, view, 0, 10);
      final List<double> southEast = _pixel(projector, view, 10, 0);
      expect(northWest[1], closeTo(0, 1e-9));
      expect(southEast[1], closeTo(100, 1e-9));
      expect(northWest[0], greaterThan(0));
      expect(southEast[0], lessThan(100));
      expect(northWest[0], closeTo(100 - southEast[0], 1e-9));
    });

    test('zoom multiplies the scale about the focus', () {
      const KumoGeoProjector projector = KumoGeoProjector(
        projection: _mercator,
        bounds: KumoGeoBounds.world(),
      );
      final Matrix4 one = projector.computeViewMatrix(
        left: 0,
        top: 0,
        width: 400,
        height: 400,
      );
      final Matrix4 four = projector.computeViewMatrix(
        left: 0,
        top: 0,
        width: 400,
        height: 400,
        zoom: 4,
      );

      expect(
        KumoGeoProjector.scaleOf(four),
        closeTo(KumoGeoProjector.scaleOf(one) * 4, 1e-9),
      );
      // The focus is the point that does not move: the centre of the box.
      expect(_pixel(projector, four, 0, 0), <double>[200, 200]);
    });

    test('a focus change pans the view onto that point', () {
      const KumoGeoProjector projector = KumoGeoProjector(
        projection: _mercator,
        bounds: KumoGeoBounds.world(),
      );
      final Matrix4 view = projector.computeViewMatrix(
        left: 0,
        top: 0,
        width: 400,
        height: 400,
        zoom: 2,
        focusX: _mercator.worldX(-74),
        focusY: _mercator.worldY(40.7),
      );

      // New York lands at the centre of the plot.
      expect(_pixel(projector, view, -74, 40.7), <double>[200, 200]);
    });

    test('a plot offset shifts the whole view', () {
      const KumoGeoProjector projector = KumoGeoProjector(
        projection: _mercator,
        bounds: KumoGeoBounds.world(),
      );
      final Matrix4 inset = projector.computeViewMatrix(
        left: 16,
        top: 12,
        width: 400,
        height: 400,
      );

      expect(_pixel(projector, inset, 0, 0), <double>[216, 212]);
    });

    test('projectInto agrees with projectPoint', () {
      const KumoGeoProjector projector = KumoGeoProjector(
        projection: _mercator,
        bounds: KumoGeoBounds.world(),
      );
      final Matrix4 view = projector.computeViewMatrix(
        left: 8,
        top: 4,
        width: 320,
        height: 180,
        zoom: 1.7,
      );
      final Float64List longitudes = Float64List.fromList(<double>[
        -74,
        0,
        139.7,
        180,
      ]);
      final Float64List latitudes = Float64List.fromList(<double>[
        40.7,
        0,
        35.7,
        -33.9,
      ]);
      final Float64List out = Float64List(8);

      projector.projectInto(
        longitudes: longitudes,
        latitudes: latitudes,
        length: 4,
        view: view,
        outPixels: out,
      );

      for (int i = 0; i < 4; i++) {
        final List<double> expected = _pixel(
          projector,
          view,
          longitudes[i],
          latitudes[i],
        );
        expect(out[i * 2], closeTo(expected[0], 1e-12));
        expect(out[i * 2 + 1], closeTo(expected[1], 1e-12));
      }
    });
  });

  group('degenerate bounds and plots', () {
    test('an empty box centres instead of dividing by zero', () {
      const KumoGeoProjector projector = KumoGeoProjector(
        projection: _mercator,
        bounds: KumoGeoBounds.empty(),
      );
      final Matrix4 view = projector.computeViewMatrix(
        left: 0,
        top: 0,
        width: 400,
        height: 200,
      );

      expect(view.storage.every((double value) => value.isFinite), isTrue);
      expect(KumoGeoProjector.translationX(view), 200);
      expect(KumoGeoProjector.translationY(view), 100);
      expect(projector.bounds.isEmpty, isTrue);
      expect(projector.bounds.width, 0);
      expect(projector.bounds.centerX, 0.5);
    });

    test('a zero-size plot stays finite', () {
      const KumoGeoProjector projector = KumoGeoProjector(
        projection: _mercator,
        bounds: KumoGeoBounds.world(),
      );
      final Matrix4 view = projector.computeViewMatrix(
        left: 0,
        top: 0,
        width: 0,
        height: 0,
      );

      expect(view.storage.every((double value) => value.isFinite), isTrue);
    });

    test('a nonsense zoom falls back to 1', () {
      const KumoGeoProjector projector = KumoGeoProjector(
        projection: _mercator,
        bounds: KumoGeoBounds.world(),
      );
      final Matrix4 fallback = projector.computeViewMatrix(
        left: 0,
        top: 0,
        width: 400,
        height: 400,
        zoom: 0,
      );
      final Matrix4 baseline = projector.computeViewMatrix(
        left: 0,
        top: 0,
        width: 400,
        height: 400,
      );

      expect(KumoGeoProjector.scaleOf(fallback), KumoGeoProjector.scaleOf(baseline));
      expect(
        projector
            .computeViewMatrix(
              left: 0,
              top: 0,
              width: 400,
              height: 400,
              zoom: double.nan,
            )
            .storage
            .every((double value) => value.isFinite),
        isTrue,
      );
    });

    test('bounds accumulate across both projections', () {
      final KumoGeoBounds equirectangular = const KumoGeoBounds.empty()
          .expandedWith(_equirectangular, -10, 20)
          .expandedWith(_equirectangular, 10, -20);
      final KumoGeoBounds mercator = const KumoGeoBounds.empty()
          .expandedWith(_mercator, -10, 20)
          .expandedWith(_mercator, 10, -20);

      expect(equirectangular.minX, mercator.minX);
      expect(equirectangular.maxX, mercator.maxX);
      expect(equirectangular.minY, lessThan(equirectangular.maxY));
      expect(mercator.minY, lessThan(mercator.maxY));
    });

    test('mercator stretches the poles and a plate carrée does not', () {
      // Comparing the two normalised heights directly would prove nothing:
      // equirectangular spends the whole square on 180° of latitude while
      // mercator spends it on 170.1°. What defines mercator is the *ratio*
      // between a band at the pole and the same band at the equator.
      double mercatorSpan(double north, double south) =>
          (_mercator.worldY(north) - _mercator.worldY(south)).abs();
      double flatSpan(double north, double south) =>
          (_equirectangular.worldY(north) - _equirectangular.worldY(south))
              .abs();

      expect(mercatorSpan(0, 25), closeTo(0.07175903748000478, 1e-12));
      expect(mercatorSpan(60, 85), closeTo(0.2887617260744545, 1e-12));
      expect(
        mercatorSpan(60, 85) / mercatorSpan(0, 25),
        closeTo(4.024, 1e-3),
        reason: 'the same 25° covers four times the square near the pole',
      );

      // Every degree is the same height in equirectangular, which is exactly
      // the distortion mercator exists to trade away.
      expect(flatSpan(60, 85), closeTo(flatSpan(0, 25), 1e-12));
      expect(flatSpan(0, 25), closeTo(25 / 180, 1e-12));
    });

    test('one distinct point has no span but still has a centre', () {
      final KumoGeoBounds bounds = const KumoGeoBounds.empty()
          .expandedWith(_mercator, 5, 5);

      expect(bounds.isEmpty, isFalse);
      expect(bounds.width, 0);
      expect(bounds.height, 0);
      expect(bounds.centerX, _mercator.worldX(5));
      expect(bounds.centerY, _mercator.worldY(5));
    });
  });
}
