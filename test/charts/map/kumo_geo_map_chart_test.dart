import 'dart:ui' show PictureRecorder, Size;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

class _CountingMap extends KumoGeoMapLayer {
  _CountingMap({
    required super.context,
    required super.data,
    super.zoom,
    super.focus,
    super.selectedFeatureId,
  });

  int prepares = 0;

  @override
  void prepare() {
    prepares++;
    super.prepare();
  }
}

const double _width = 320;
const double _height = 240;

List<List<double>> _ring(
  double west,
  double south,
  double east,
  double north,
) => <List<double>>[
  <double>[west, south],
  <double>[east, south],
  <double>[east, north],
  <double>[west, north],
  <double>[west, south],
];

Map<String, Object?> _feature(
  String id,
  Object? value,
  double west,
  double south,
  double east,
  double north,
) => <String, Object?>{
  'type': 'Feature',
  'id': id,
  'properties': <String, Object?>{'name': id, 'value': value},
  'geometry': <String, Object?>{
    'type': 'Polygon',
    'coordinates': <Object?>[_ring(west, south, east, north)],
  },
};

KumoGeoMapData _data() => const KumoGeoJsonParser().parse(
  <String, Object?>{
    'type': 'FeatureCollection',
    'features': <Map<String, Object?>>[
      _feature('north', 10, 0, 10, 20, 20),
      _feature('south', 90, 0, 0, 20, 10),
    ],
  },
);

KumoChartContext _context({double width = _width, double height = _height}) =>
    KumoChartContext(
      geometry: KumoChartGeometry(
        size: Size(width, height),
        plot: Rect.fromLTRB(0, 0, width, height),
      ),
      colors: const KumoColors(),
      styles: KumoTypography.resolve(const KumoColors()),
    );

void _paintTimes(KumoChartLayer layer, int times) {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  for (int i = 0; i < times; i++) {
    layer.paint(canvas, const Size(_width, _height));
  }
  recorder.endRecording().dispose();
}

List<int> _pathIds(KumoGeoMapData data) => data.features
    .map((KumoGeoFeature feature) => identityHashCode(feature.path))
    .toList();

void main() {
  group('cached geometry', () {
    test('a zoom change reuses the compiled paths', () {
      final KumoGeoMapData data = _data();
      final List<int> before = _pathIds(data);
      final KumoGeoBounds boundsBefore = data.bounds;

      final _CountingMap near = _CountingMap(
        context: _context(),
        data: data,
      )..prepare();
      _paintTimes(near, 1);

      final _CountingMap far = _CountingMap(
        context: _context(),
        data: data,
        zoom: 8,
        focus: const Offset(0.5, 0.5),
      )..prepare();
      _paintTimes(far, 1);

      // The whole point of compiling into world space: a viewport change is a
      // matrix. The paths are untouched, and the layer has no parser to call
      // even if it wanted to re-project them.
      expect(_pathIds(data), before);
      expect(data.bounds, boundsBefore);
      expect(near.prepares, 1);
      expect(far.prepares, 1);
      expect(far.shouldRepaint(near), isTrue);
    });

    test('a resize reuses them too', () {
      final KumoGeoMapData data = _data();
      final List<int> before = _pathIds(data);

      final _CountingMap wide = _CountingMap(
        context: _context(),
        data: data,
      )..prepare();
      final _CountingMap narrow = _CountingMap(
        context: _context(width: 120, height: 90),
        data: data,
      )..prepare();
      _paintTimes(narrow, 1);

      expect(_pathIds(data), before);
      expect(wide.prepares, 1);
      expect(narrow.prepares, 1);
    });

    test('a selection changes without touching geometry', () {
      final KumoGeoMapData data = _data();
      final List<int> before = _pathIds(data);

      final _CountingMap plain = _CountingMap(
        context: _context(),
        data: data,
      )..prepare();
      final _CountingMap selected = _CountingMap(
        context: _context(),
        data: data,
        selectedFeatureId: 'north',
      )..prepare();
      _paintTimes(selected, 1);

      expect(_pathIds(data), before);
      expect(selected.shouldRepaint(plain), isTrue);
    });
  });

  group('zero allocation in the paint loop', () {
    test('a prepared layer never re-prepares, however many paints', () {
      final KumoGeoMapData data = _data();
      final _CountingMap layer = _CountingMap(
        context: _context(),
        data: data,
        selectedFeatureId: 'north',
      )..prepare();

      expect(layer.prepares, 1);
      final List<int> before = _pathIds(data);
      final KumoGeoBounds boundsBefore = data.bounds;

      _paintTimes(layer, 200);

      // Dart exposes no allocation counter, so what is asserted is what is
      // observable: 200 paints neither re-prepared nor moved any geometry. The
      // allocation-freedom is structural — the paint body builds no Paint, Path,
      // Rect or Matrix4, and only reads what prepare left behind.
      expect(layer.prepares, 1);
      expect(_pathIds(data), before);
      expect(data.bounds, boundsBefore);
    });

    test('painting empty data is a no-op rather than a crash', () {
      final _CountingMap layer = _CountingMap(
        context: _context(),
        data: const KumoGeoJsonParser().parse(
          <String, Object?>{'type': 'FeatureCollection'},
        ),
      )..prepare();

      _paintTimes(layer, 5);
      expect(layer.prepares, 1);
    });
  });

  group('KumoGeoMapChart', () {
    testWidgets('renders, pans, zooms and survives a resize', (tester) async {
      final KumoGeoMapData data = _data();

      Widget sized(double width, {double zoom = 1, Offset? focus}) => KumoTheme(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: width,
              child: KumoGeoMapChart(data: data, zoom: zoom, focus: focus),
            ),
          ),
        ),
      );

      await tester.pumpWidget(sized(320));
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);

      await tester.pumpWidget(sized(200, zoom: 3));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        sized(200, zoom: 3, focus: const Offset(0.25, 0.75)),
      );
      expect(tester.takeException(), isNull);

      // Same data object throughout: three viewports, one parse.
      expect(data.features, hasLength(2));
    });

    testWidgets('renders without the surface chrome and with an overlay', (
      tester,
    ) async {
      await tester.pumpWidget(
        KumoTheme(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 320,
                child: KumoGeoMapChart(
                  data: _data(),
                  showSurface: false,
                  selectedFeatureId: 'south',
                  overlay: const Text('legend'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('legend'), findsOneWidget);
    });

    testWidgets('an empty map renders as a blank surface', (tester) async {
      await tester.pumpWidget(
        KumoTheme(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 320,
                child: KumoGeoMapChart(
                  data: const KumoGeoJsonParser().parse(
                    <String, Object?>{'type': 'FeatureCollection'},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
