import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

const KumoGeoProjection _mercator = KumoGeoProjection();
const KumoGeoJsonParser _parser = KumoGeoJsonParser();

/// A closed rectangular ring, as GeoJSON writes one: the first position repeats
/// at the end.
List<List<double>> _ring(
  double west,
  double south,
  double east,
  double north, {
  bool close = true,
  bool reverse = false,
}) {
  final List<List<double>> positions = <List<double>>[
    <double>[west, south],
    <double>[east, south],
    <double>[east, north],
    <double>[west, north],
  ];
  if (reverse) {
    positions.setAll(0, positions.reversed.toList());
  }
  if (close) {
    positions.add(positions.first);
  }
  return positions;
}

Map<String, Object?> _polygon(List<Object?> rings) => <String, Object?>{
  'type': 'Polygon',
  'coordinates': rings,
};

Map<String, Object?> _multiPolygon(List<Object?> polygons) => <String, Object?>{
  'type': 'MultiPolygon',
  'coordinates': polygons,
};

Map<String, Object?> _feature(
  String id,
  Object? value,
  Map<String, Object?> geometry,
) => <String, Object?>{
  'type': 'Feature',
  'id': id,
  'properties': <String, Object?>{'name': id.toUpperCase(), 'value': value},
  'geometry': geometry,
};

Map<String, Object?> _collection(List<Map<String, Object?>> features) =>
    <String, Object?>{'type': 'FeatureCollection', 'features': features};

List<KumoGeoFeature> _features(Map<String, Object?> geoJson) =>
    _parser.parse(geoJson).features;

Offset _world(double longitude, double latitude) =>
    Offset(_mercator.worldX(longitude), _mercator.worldY(latitude));

void main() {
  group('feature collection parsing', () {
    test('every feature becomes one path with its properties', () {
      final KumoGeoMapData data = _parser.parse(
        _collection(<Map<String, Object?>>[
          _feature('wa', 12, _polygon(<Object?>[_ring(-124, 45, -116, 49)])),
          _feature('mt', 7, _polygon(<Object?>[_ring(-116, 44, -104, 49)])),
        ]),
      );

      expect(data.features, hasLength(2));
      expect(data.features[0].id, 'wa');
      expect(data.features[0].name, 'WA');
      expect(data.features[0].value, 12);
      expect(data.features[1].id, 'mt');
      expect(data.features[1].value, 7);
      expect(data.maxValue, 12);
      expect(data.minValue, 7);
    });

    test('coordinates are read as longitude then latitude', () {
      // Asymmetric on purpose: a swapped read would put minX at longitude 0.
      final KumoGeoBounds bounds = _parser
          .parse(
            _collection(<Map<String, Object?>>[
              _feature('box', 1, _polygon(<Object?>[_ring(20, 0, 40, 10)])),
            ]),
          )
          .bounds;

      expect(bounds.minX, closeTo(_mercator.worldX(20), 1e-12));
      expect(bounds.maxX, closeTo(_mercator.worldX(40), 1e-12));
      // North is the smaller y.
      expect(bounds.minY, closeTo(_mercator.worldY(10), 1e-12));
      expect(bounds.maxY, closeTo(_mercator.worldY(0), 1e-12));
    });

    test('a bare feature and a bare geometry both parse', () {
      expect(
        _features(_feature('solo', 3, _polygon(<Object?>[_ring(0, 0, 1, 1)]))),
        hasLength(1),
      );
      expect(
        _features(_polygon(<Object?>[_ring(0, 0, 1, 1)])),
        hasLength(1),
      );
    });

    test('a feature without an id gets a positional one', () {
      final KumoGeoFeature feature = _features(
        _collection(<Map<String, Object?>>[
          <String, Object?>{
            'type': 'Feature',
            'properties': const <String, Object?>{},
            'geometry': _polygon(<Object?>[_ring(0, 0, 1, 1)]),
          },
        ]),
      ).single;

      expect(feature.id, 'feature-0');
      // With no name property it falls back to the id rather than to null.
      expect(feature.name, 'feature-0');
      expect(feature.value, isNull);
    });

    test('a numeric string is read as a magnitude', () {
      final KumoGeoFeature feature = _features(
        _collection(<Map<String, Object?>>[
          _feature('a', '42.5', _polygon(<Object?>[_ring(0, 0, 1, 1)])),
        ]),
      ).single;

      expect(feature.value, 42.5);
    });

    test('a custom value and name key are honoured', () {
      const KumoGeoJsonParser custom = KumoGeoJsonParser(
        valueKey: 'count',
        nameKey: 'label',
      );
      final KumoGeoFeature feature = custom
          .parse(
            _collection(<Map<String, Object?>>[
              <String, Object?>{
                'type': 'Feature',
                'properties': const <String, Object?>{
                  'count': 9,
                  'label': 'Nine',
                },
                'geometry': _polygon(<Object?>[_ring(0, 0, 1, 1)]),
              },
            ]),
          )
          .features
          .single;

      expect(feature.value, 9);
      expect(feature.name, 'Nine');
    });
  });

  group('path compilation', () {
    test('a polygon with a hole keeps the hole empty', () {
      final KumoGeoFeature holed = _features(
        _collection(<Map<String, Object?>>[
          _feature(
            'ring',
            1,
            _polygon(<Object?>[_ring(0, 0, 10, 10), _ring(3, 3, 7, 7)]),
          ),
        ]),
      ).single;

      expect(holed.path.contains(_world(1, 5)), isTrue);
      expect(holed.path.contains(_world(5, 5)), isFalse);
      expect(holed.path.contains(_world(9, 9)), isTrue);

      // The same outline without the second ring fills solid, which is what
      // makes the assertion above about the hole rather than about the shape.
      final KumoGeoFeature solid = _features(
        _collection(<Map<String, Object?>>[
          _feature('solid', 1, _polygon(<Object?>[_ring(0, 0, 10, 10)])),
        ]),
      ).single;
      expect(solid.path.contains(_world(5, 5)), isTrue);
    });

    test('a hole is a hole whatever way its ring winds', () {
      for (final bool reverse in <bool>[false, true]) {
        final KumoGeoFeature feature = _features(
          _collection(<Map<String, Object?>>[
            _feature(
              'ring',
              1,
              _polygon(<Object?>[
                _ring(0, 0, 10, 10),
                _ring(3, 3, 7, 7, reverse: reverse),
              ]),
            ),
          ]),
        ).single;

        expect(
          feature.path.contains(_world(5, 5)),
          isFalse,
          reason:
              'the spec asks holes to wind the other way, but real files '
              'disagree and even-odd makes it moot (reverse: $reverse)',
        );
      }
    });

    test('a multipolygon is one path covering every part', () {
      final KumoGeoFeature feature = _features(
        _collection(<Map<String, Object?>>[
          _feature(
            'islands',
            5,
            _multiPolygon(<Object?>[
              <Object?>[_ring(0, 0, 10, 10)],
              <Object?>[_ring(20, 0, 30, 10)],
            ]),
          ),
        ]),
      ).single;

      expect(feature.path.contains(_world(5, 5)), isTrue);
      expect(feature.path.contains(_world(25, 5)), isTrue);
      expect(
        feature.path.contains(_world(15, 5)),
        isFalse,
        reason: 'the gap between the two parts is not part of the feature',
      );
    });

    test('a multipolygon part with a hole keeps both', () {
      final KumoGeoFeature feature = _features(
        _collection(<Map<String, Object?>>[
          _feature(
            'atoll',
            5,
            _multiPolygon(<Object?>[
              <Object?>[_ring(0, 0, 10, 10)],
              <Object?>[_ring(20, 0, 30, 10), _ring(22, 2, 28, 8)],
            ]),
          ),
        ]),
      ).single;

      expect(feature.path.contains(_world(5, 5)), isTrue);
      expect(feature.path.contains(_world(21, 5)), isTrue);
      expect(feature.path.contains(_world(25, 5)), isFalse);
    });

    test('an unclosed ring is closed rather than left open', () {
      final KumoGeoFeature feature = _features(
        _collection(<Map<String, Object?>>[
          _feature(
            'open',
            1,
            _polygon(<Object?>[_ring(0, 0, 10, 10, close: false)]),
          ),
        ]),
      ).single;

      expect(feature.path.contains(_world(5, 5)), isTrue);
    });

    test('the per-feature box is its own, not the collection\u2019s', () {
      final KumoGeoMapData data = _parser.parse(
        _collection(<Map<String, Object?>>[
          _feature('a', 1, _polygon(<Object?>[_ring(0, 0, 10, 10)])),
          _feature('b', 1, _polygon(<Object?>[_ring(20, 20, 30, 30)])),
        ]),
      );

      expect(
        data.features[0].bounds.maxX,
        closeTo(_mercator.worldX(10), 1e-12),
      );
      expect(
        data.features[1].bounds.minX,
        closeTo(_mercator.worldX(20), 1e-12),
      );
      expect(data.bounds.minX, closeTo(_mercator.worldX(0), 1e-12));
      expect(data.bounds.maxX, closeTo(_mercator.worldX(30), 1e-12));
    });
  });

  group('malformed input', () {
    test('geometry types that are not areas are skipped, not thrown on', () {
      final KumoGeoMapData data = _parser.parse(
        _collection(<Map<String, Object?>>[
          _feature('pin', 1, <String, Object?>{
            'type': 'Point',
            'coordinates': <double>[1, 2],
          }),
          _feature('road', 1, <String, Object?>{
            'type': 'LineString',
            'coordinates': <Object?>[
              <double>[0, 0],
              <double>[1, 1],
            ],
          }),
          _feature('none', 1, const <String, Object?>{}),
          _feature(
            'degenerate',
            1,
            _polygon(<Object?>[
              <Object?>[
                <double>[0, 0],
                <double>[1, 1],
              ],
            ]),
          ),
        ]),
      );

      expect(data.features, isEmpty);
      expect(data.isEmpty, isTrue);
    });

    test('a non-collection root parses to nothing but still has a box', () {
      for (final Map<String, Object?> root in <Map<String, Object?>>[
        const <String, Object?>{},
        const <String, Object?>{'type': 'GeometryCollection'},
        const <String, Object?>{'type': 'FeatureCollection'},
      ]) {
        final KumoGeoMapData data = _parser.parse(root);
        expect(data.features, isEmpty);
        // A map with nothing to fit still needs a box, or a projector has
        // nothing to scale and would collapse to the plot's top-left corner.
        expect(data.bounds.width, 1);
        expect(data.bounds.height, 1);
      }
    });

    test('a malformed position is skipped without losing the ring', () {
      final KumoGeoFeature feature = _features(
        _collection(<Map<String, Object?>>[
          _feature('mixed', 1, <String, Object?>{
            'type': 'Polygon',
            'coordinates': <Object?>[
              <Object?>[
                <Object?>[0, 0],
                <Object?>['nope', 0],
                <Object?>[10, 0],
                <Object?>[10, 10],
                <Object?>[0, 10],
                <Object?>[0, 0],
              ],
            ],
          }),
        ]),
      ).single;

      // The bad vertex is dropped and the other four still enclose an area.
      expect(feature.path.contains(_world(5, 5)), isTrue);
    });
  });

  group('KumoGeoMapData', () {
    Map<String, Object?> source() => _collection(<Map<String, Object?>>[
      _feature('a', 10, _polygon(<Object?>[_ring(0, 0, 10, 10)])),
      _feature('b', 30, _polygon(<Object?>[_ring(20, 0, 30, 10)])),
      _feature('c', null, _polygon(<Object?>[_ring(40, 0, 50, 10)])),
    ]);

    test('the magnitude domain spans the features that have one', () {
      final KumoGeoMapData data = _parser.parse(source());

      expect(data.features, hasLength(3));
      expect(data.minValue, 10);
      expect(data.maxValue, 30);
      expect(data.features[2].value, isNull);
    });

    test('a collection with no magnitudes has a domain of zero', () {
      final KumoGeoMapData data = _parser.parse(
        _collection(<Map<String, Object?>>[
          _feature('a', null, _polygon(<Object?>[_ring(0, 0, 10, 10)])),
        ]),
      );

      expect(data.minValue, 0);
      expect(data.maxValue, 0);
    });

    test('one parse cannot move a map another parse already returned', () {
      // The parser holds no accumulator between calls, so the first result
      // keeps its own bounds and its own paths.
      final KumoGeoMapData first = _parser.parse(source());
      final KumoGeoBounds before = first.bounds;

      _parser.parse(
        _collection(<Map<String, Object?>>[
          _feature('z', 1, _polygon(<Object?>[_ring(100, 0, 110, 10)])),
        ]),
      );

      expect(first.bounds, before);
      expect(first.features, hasLength(3));
    });
  });

  group('choropleth palette', () {
    test('magnitude picks a step by position on the scale', () {
      expect(KumoChartColors.sequentialIndex(0, 0, 100), 0);
      expect(KumoChartColors.sequentialIndex(100, 0, 100), 4);
      expect(KumoChartColors.sequentialIndex(50, 0, 100), 2);
      expect(KumoChartColors.sequentialIndex(1, 0, 100), 0);
      expect(KumoChartColors.sequentialIndex(99, 0, 100), 4);
    });

    test('values outside the domain clamp to the ends', () {
      expect(KumoChartColors.sequentialIndex(-50, 0, 100), 0);
      expect(KumoChartColors.sequentialIndex(500, 0, 100), 4);
    });

    test('a domain with no span resolves to the top step', () {
      expect(KumoChartColors.sequentialIndex(5, 5, 5), 4);
      expect(KumoChartColors.sequentialIndex(5, 10, 0), 4);
      expect(KumoChartColors.sequentialIndex(double.nan, 0, 100), 4);
    });

    test('dark mode reverses the scale, so prominence still means magnitude', () {
      expect(
        KumoChartColors.sequentialFor(Brightness.light),
        KumoChartColors.sequential,
      );
      expect(
        KumoChartColors.sequentialFor(Brightness.dark),
        KumoChartColors.sequentialDark,
      );
      expect(
        KumoChartColors.sequentialDark.first,
        KumoChartColors.sequential.last,
      );
      // The largest value is last in either scheme: dark mode leads with the
      // darkest step and light mode ends with it.
      expect(
        KumoChartColors.sequentialFor(Brightness.dark).last,
        KumoChartColors.sequential.first,
      );
    });
  });
}
