import 'dart:ui' show Path, PathFillType;

import 'kumo_geo_projection.dart';

/// One parsed map region: a shape in world coordinates, plus its properties.
///
/// [path] is world-space, not pixel-space. That is what makes a parsed map
/// reusable across a resize and a zoom: the shape is a property of the data, and
/// the viewport is a matrix applied when it is painted.
class KumoGeoFeature {
  /// Creates a feature.
  const KumoGeoFeature({
    required this.id,
    required this.path,
    required this.bounds,
    this.name,
    this.value,
    this.properties = const <String, Object?>{},
  });

  /// The GeoJSON `id`, or a positional fallback.
  final String id;

  /// The shape, in world coordinates.
  final Path path;

  /// This feature's own box, for zooming to it.
  final KumoGeoBounds bounds;

  /// The label source: the [KumoGeoJsonParser.nameKey] property, then the `id`.
  final String? name;

  /// The magnitude that drives a choropleth fill, from the
  /// [KumoGeoJsonParser.valueKey] property.
  final double? value;

  /// The raw GeoJSON properties.
  final Map<String, Object?> properties;
}

/// A parsed map: its shapes, their union box, and its magnitude domain.
///
/// Parsing is the expensive step and it does not depend on the viewport, so its
/// result is worth holding across rebuilds. Keep the object you get back from
/// [KumoGeoJsonParser.parse] where you hold your data — a `State`, a provider, a
/// top-level `final` — and hand the same instance to `KumoGeoMapChart` on every
/// build. That is what lets a zoom be a matrix change over geometry that was
/// compiled once.
///
/// ```dart
/// final KumoGeoMapData data =
///     const KumoGeoJsonParser().parse(jsonDecode(body) as Map<String, Object?>);
/// ```
class KumoGeoMapData {
  /// Creates map data from already-parsed parts.
  const KumoGeoMapData({required this.features, required this.bounds});

  /// The parsed regions, in file order.
  final List<KumoGeoFeature> features;

  /// The union of every feature's box, in world coordinates.
  final KumoGeoBounds bounds;

  /// Whether the source had no drawable geometry.
  bool get isEmpty => features.isEmpty;

  /// The smallest finite magnitude, or `0` when no feature carries one.
  double get minValue {
    double result = double.infinity;
    for (final KumoGeoFeature feature in features) {
      final double? value = feature.value;
      if (value != null && value.isFinite && value < result) {
        result = value;
      }
    }
    return result.isFinite ? result : 0;
  }

  /// The largest finite magnitude, or `0` when no feature carries one.
  double get maxValue {
    double result = double.negativeInfinity;
    for (final KumoGeoFeature feature in features) {
      final double? value = feature.value;
      if (value != null && value.isFinite && value > result) {
        result = value;
      }
    }
    return result.isFinite ? result : 0;
  }
}

/// Reads a GeoJSON `FeatureCollection` into cached world-space paths.
///
/// Accepts an already-decoded `Map`, so the package takes no dependency on how
/// the bytes arrived — `dart:convert`, a streaming platform decoder, or a
/// literal in a test all work.
///
/// ```dart
/// final KumoGeoMapData data =
///     const KumoGeoJsonParser().parse(jsonDecode(body) as Map<String, Object?>);
/// ```
///
/// The parser holds no state between calls: everything it accumulates lives in
/// the returned [KumoGeoMapData]. Two parses cannot interfere with each other,
/// and a map already on screen cannot move because something else was parsed.
///
/// ## What is read, and what is skipped
///
/// `Polygon` and `MultiPolygon` geometry, from a `FeatureCollection`, a bare
/// `Feature`, or a bare geometry. Anything else — points, lines, geometry
/// collections — is skipped rather than thrown on, so one stray marker in a file
/// does not blank an entire map.
///
/// Rings are forced to [PathFillType.evenOdd]. The spec asks an exterior ring to
/// wind counter-clockwise and its holes clockwise, but real-world files are
/// inconsistent about it, and even-odd makes a hole a hole whichever way its ring
/// happens to wind. Interior rings therefore work on data that would otherwise
/// fill them in solid.
class KumoGeoJsonParser {
  /// Creates a parser.
  ///
  /// [projection] decides how coordinates become world space; a parsed map
  /// caches paths, so changing it means parsing again. [valueKey] and [nameKey]
  /// name the properties that feed [KumoGeoFeature.value] and
  /// [KumoGeoFeature.name].
  const KumoGeoJsonParser({
    this.projection = const KumoGeoProjection(),
    this.valueKey = 'value',
    this.nameKey = 'name',
  });

  /// The projection applied to every coordinate.
  final KumoGeoProjection projection;

  /// The property read as a magnitude. Numeric strings are accepted.
  final String valueKey;

  /// The property read as a label.
  final String nameKey;

  /// Parses [geoJson] into features and their union box.
  KumoGeoMapData parse(Map<String, Object?> geoJson) {
    final List<Object?> entries = switch (geoJson['type']) {
      'FeatureCollection' => _asList(geoJson['features']),
      // A bare Feature or geometry is a one-entry collection. Being lenient here
      // costs two lines and saves every caller a shape check.
      'Feature' || 'Polygon' || 'MultiPolygon' => <Object?>[geoJson],
      _ => const <Object?>[],
    };

    final List<KumoGeoFeature> features = <KumoGeoFeature>[];
    KumoGeoBounds bounds = const KumoGeoBounds.empty();
    for (int i = 0; i < entries.length; i++) {
      final KumoGeoFeature? feature = _parseFeature(entries[i], i);
      if (feature != null) {
        features.add(feature);
        bounds = bounds.union(feature.bounds);
      }
    }

    return KumoGeoMapData(
      features: features,
      // A map with no coordinates still needs a box to fit, or a projector has
      // nothing to scale and nothing to centre.
      bounds: bounds.isEmpty ? const KumoGeoBounds.world() : bounds,
    );
  }

  KumoGeoFeature? _parseFeature(Object? node, int index) {
    final Map<String, Object?>? feature = _asMap(node);
    if (feature == null) {
      return null;
    }

    final Map<String, Object?> geometry =
        _asMap(feature['type'] == 'Feature' ? feature['geometry'] : feature) ??
        const <String, Object?>{};
    final Path? path = _buildPath(geometry);
    if (path == null) {
      return null;
    }

    final Map<String, Object?> properties =
        _asMap(feature['properties']) ?? const <String, Object?>{};
    final Object? rawName = properties[nameKey];
    final Object? rawId = feature['id'];
    final String id = switch (rawId) {
      final String value when value.isNotEmpty => value,
      final num value => '$value',
      _ => 'feature-$index',
    };

    return KumoGeoFeature(
      id: id,
      path: path,
      bounds: _boundsOf(geometry),
      name: rawName == null ? id : '$rawName',
      value: _asDouble(properties[valueKey]),
      properties: properties,
    );
  }

  /// Compiles a `Polygon` or `MultiPolygon` geometry into one path.
  ///
  /// One path per feature, not one per ring: a feature's fill is a single
  /// decision, and a hole only means anything relative to the ring around it.
  Path? _buildPath(Map<String, Object?> geometry) {
    switch (geometry['type']) {
      case 'Polygon':
        final Path path = Path()..fillType = PathFillType.evenOdd;
        return _addPolygon(path, geometry['coordinates']) ? path : null;
      case 'MultiPolygon':
        final Path path = Path()..fillType = PathFillType.evenOdd;
        bool added = false;
        for (final Object? polygon in _asList(geometry['coordinates'])) {
          added = _addPolygon(path, polygon) || added;
        }
        return added ? path : null;
      default:
        return null;
    }
  }

  /// Adds one polygon (a list of rings) to [path], reporting whether any ring
  /// had enough points to enclose an area.
  bool _addPolygon(Path path, Object? coordinates) {
    bool added = false;
    for (final Object? ring in _asList(coordinates)) {
      if (_addRing(path, ring)) {
        added = true;
      }
    }
    return added;
  }

  bool _addRing(Path path, Object? ring) {
    final List<Object?> positions = _asList(ring);
    bool started = false;
    double firstX = 0;
    double firstY = 0;
    int drawn = 0;

    for (final Object? position in positions) {
      final List<Object?> pair = _asList(position);
      if (pair.length < 2) {
        continue;
      }
      final double? longitude = _asDouble(pair[0]);
      final double? latitude = _asDouble(pair[1]);
      if (longitude == null || latitude == null) {
        continue;
      }
      final double x = projection.worldX(longitude);
      final double y = projection.worldY(latitude);
      if (!started) {
        path.moveTo(x, y);
        firstX = x;
        firstY = y;
        started = true;
        drawn = 1;
        continue;
      }
      // GeoJSON closes a ring by repeating its first position. Closing the path
      // does that already, so the duplicate is dropped rather than drawn.
      if (x == firstX && y == firstY) {
        continue;
      }
      path.lineTo(x, y);
      drawn++;
    }

    if (drawn < 3) {
      // Two points are a line and one is a dot; neither encloses an area.
      return false;
    }
    path.close();
    return true;
  }

  KumoGeoBounds _boundsOf(Map<String, Object?> geometry) {
    KumoGeoBounds bounds = const KumoGeoBounds.empty();
    if (geometry['type'] == 'MultiPolygon') {
      for (final Object? polygon in _asList(geometry['coordinates'])) {
        bounds = _expandRings(polygon, bounds);
      }
      return bounds;
    }
    return _expandRings(geometry['coordinates'], bounds);
  }

  KumoGeoBounds _expandRings(Object? coordinates, KumoGeoBounds bounds) {
    for (final Object? ring in _asList(coordinates)) {
      for (final Object? position in _asList(ring)) {
        final List<Object?> pair = _asList(position);
        if (pair.length < 2) {
          continue;
        }
        final double? longitude = _asDouble(pair[0]);
        final double? latitude = _asDouble(pair[1]);
        if (longitude != null && latitude != null) {
          bounds = bounds.expandedWith(projection, longitude, latitude);
        }
      }
    }
    return bounds;
  }

  static List<Object?> _asList(Object? value) =>
      value is List ? value.cast<Object?>() : const <Object?>[];

  static Map<String, Object?>? _asMap(Object? value) =>
      value is Map ? value.cast<String, Object?>() : null;

  static double? _asDouble(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text),
    _ => null,
  };
}
