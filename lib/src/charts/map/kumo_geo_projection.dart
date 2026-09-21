import 'dart:math' as math;
import 'dart:typed_data';

import 'package:vector_math/vector_math_64.dart';

/// Which way the globe is flattened onto a plane.
///
/// Both are cylindrical: longitude becomes x linearly, and they differ only in
/// how latitude becomes y. Neither can preserve both area and shape — that is
/// Gauss's theorem, not a limitation here — so the choice is a trade.
enum KumoGeoProjectionKind {
  /// Latitude maps linearly. Area is distorted towards the poles, but the
  /// arithmetic is trivial and reversible, which suits choropleths of a single
  /// country or a small region.
  equirectangular,

  /// Web Mercator, the projection the web's map tiles use. Shapes stay locally
  /// correct — a country looks like itself — at the cost of exaggerating
  /// high-latitude area. Latitude is capped at [KumoGeoProjection.maxLatitude]
  /// because the pole is at infinity.
  mercator,
}

/// Maps longitude and latitude onto the unit square.
///
/// The unit square is the intermediate space every other piece of this module
/// works in: a projection puts the globe in it, [KumoGeoBounds] describes a box
/// in it, and one `Matrix4` maps it to pixels. Keeping it normalised means a pan
/// or a zoom is a matrix change rather than a re-projection, and a cached path
/// never has to be rebuilt.
///
/// `x` runs west to east and `y` runs north to south, so `(0, 0)` is the
/// north-western corner of the world and `(1, 1)` the south-eastern one. That
/// matches the y-down convention `Canvas` already uses.
///
/// Pure Dart: this file imports `dart:math`, `dart:typed_data` and
/// `vector_math`, and nothing else.
class KumoGeoProjection {
  /// Creates a projection of [kind], Web Mercator by default.
  const KumoGeoProjection([this.kind = KumoGeoProjectionKind.mercator]);

  /// Which projection this instance applies.
  final KumoGeoProjectionKind kind;

  /// The latitude at which Web Mercator is truncated, in degrees.
  ///
  /// `atan(sinh(pi))`: the latitude whose projected `y` reaches the edge of the
  /// square. Beyond it the projection diverges, so latitude is clamped here.
  static const double maxLatitude = 85.05112877980659;

  /// Horizontal position of [longitude], `0` at 180°W and `1` at 180°E.
  ///
  /// Linear in both projections, and clamped rather than wrapped. Wrapping would
  /// be correct per point and ruinous per shape: one vertex at 180.9° would land
  /// near `0.002` and stretch the bounding box of a whole country across the
  /// globe. Clamping keeps a box sane, at the cost of a shape that genuinely
  /// crosses the antimeridian needing to be split into two features first —
  /// which is what every naive Mercator renderer requires anyway.
  double worldX(double longitude) => (longitude.clamp(-180, 180) + 180) / 360;

  /// Vertical position of [latitude], `0` at the north edge and `1` at the
  /// south edge.
  double worldY(double latitude) {
    final double clamped = latitude.clamp(-90, 90);
    switch (kind) {
      case KumoGeoProjectionKind.equirectangular:
        return (90 - clamped) / 180;
      case KumoGeoProjectionKind.mercator:
        final double capped = clamped.clamp(-maxLatitude, maxLatitude);
        final double radians = capped * math.pi / 180;
        return (1 - math.log(math.tan(radians) + 1 / math.cos(radians)) / math.pi) / 2;
    }
  }

  /// The longitude at the horizontal position [x].
  double worldToLongitude(double x) => x * 360 - 180;

  /// The latitude at the vertical position [y].
  double worldToLatitude(double y) {
    switch (kind) {
      case KumoGeoProjectionKind.equirectangular:
        return 90 - y * 180;
      case KumoGeoProjectionKind.mercator:
        return math.atan(_sinh(math.pi * (1 - 2 * y))) * 180 / math.pi;
    }
  }

  /// Hyperbolic sine, built from `exp` so this stays on `dart:math`'s public
  /// surface.
  static double _sinh(double value) {
    final double e = math.exp(value);
    return (e - 1 / e) / 2;
  }
}

/// An axis-aligned box in projected world coordinates.
///
/// Immutable, and expressed in the unit square a [KumoGeoProjection] produces.
/// Grow one by chaining [expandedTo] or [expandedWith], and combine two with
/// [union]:
///
/// ```dart
/// final bounds = const KumoGeoBounds.empty()
///     .expandedWith(projection, -124.7, 48.4)
///     .expandedWith(projection, -116.9, 45.5);
/// ```
///
/// A value object rather than an accumulator, because boxes get compared,
/// cached and handed to a projector; the extra box per vertex costs nothing
/// next to the `Path` being built in the same loop.
class KumoGeoBounds {
  /// Creates a box from explicit world coordinates.
  const KumoGeoBounds.fromLTRB({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  /// An empty box. [isEmpty] is true, and any point widens it.
  const KumoGeoBounds.empty()
    : minX = double.infinity,
      minY = double.infinity,
      maxX = double.negativeInfinity,
      maxY = double.negativeInfinity;

  /// The whole world, as a projection produces it.
  ///
  /// The sensible starting box when data has no coordinates to derive one from:
  /// a projector given an empty box has nothing to fit.
  const KumoGeoBounds.world() : minX = 0, minY = 0, maxX = 1, maxY = 1;

  /// Left edge.
  final double minX;

  /// Top edge.
  final double minY;

  /// Right edge.
  final double maxX;

  /// Bottom edge.
  final double maxY;

  /// Whether nothing has been added yet.
  bool get isEmpty => minX > maxX || minY > maxY;

  /// Width, or zero when empty.
  double get width => isEmpty ? 0 : maxX - minX;

  /// Height, or zero when empty.
  double get height => isEmpty ? 0 : maxY - minY;

  /// Horizontal midpoint, or `0.5` when empty.
  double get centerX => isEmpty ? 0.5 : (minX + maxX) / 2;

  /// Vertical midpoint, or `0.5` when empty.
  double get centerY => isEmpty ? 0.5 : (minY + maxY) / 2;

  /// A box grown to include the world point `(x, y)`.
  KumoGeoBounds expandedTo(double x, double y) => KumoGeoBounds.fromLTRB(
    minX: x < minX ? x : minX,
    minY: y < minY ? y : minY,
    maxX: x > maxX ? x : maxX,
    maxY: y > maxY ? y : maxY,
  );

  /// A box grown to include a coordinate, projected.
  KumoGeoBounds expandedWith(
    KumoGeoProjection projection,
    double longitude,
    double latitude,
  ) => expandedTo(projection.worldX(longitude), projection.worldY(latitude));

  /// The smallest box containing both this box and [other].
  KumoGeoBounds union(KumoGeoBounds other) => KumoGeoBounds.fromLTRB(
    minX: other.minX < minX ? other.minX : minX,
    minY: other.minY < minY ? other.minY : minY,
    maxX: other.maxX > maxX ? other.maxX : maxX,
    maxY: other.maxY > maxY ? other.maxY : maxY,
  );

  @override
  bool operator ==(Object other) =>
      other is KumoGeoBounds &&
      other.minX == minX &&
      other.minY == minY &&
      other.maxX == maxX &&
      other.maxY == maxY;

  @override
  int get hashCode => Object.hash(minX, minY, maxX, maxY);

  @override
  String toString() => 'KumoGeoBounds($minX, $minY, $maxX, $maxY)';
}

/// Turns world coordinates into plot pixels.
///
/// One `Matrix4` carries the whole view: the fit of [bounds] inside the plot at
/// its centre, times the zoom, around a focus point. Because it is a plain
/// affine transform, panning and zooming never touch the cached geometry — a
/// painter applies it with `Canvas.transform(matrix.storage)` and the paths
/// beneath are reused untouched.
class KumoGeoProjector {
  /// Creates a projector fitting [bounds] with [projection].
  const KumoGeoProjector({required this.projection, required this.bounds});

  /// The projection applied to coordinates.
  final KumoGeoProjection projection;

  /// The world-space box the view fits.
  final KumoGeoBounds bounds;

  /// The matrix mapping world coordinates into a `left, top, width, height`
  /// plot, aspect-correct.
  ///
  /// The fit takes the smaller of the two axis ratios, so the content always
  /// fits and is centred, with slack on the longer axis. Stretching to fill
  /// would be wrong for a map: a country would change shape with the aspect
  /// ratio of whatever box it was dropped into.
  ///
  /// [zoom] scales about the focus, and [focusX]/[focusY] move the point held at
  /// the plot's centre — pan is a focus change, which is why it costs no
  /// geometry work. Both default to the centre of [bounds].
  Matrix4 computeViewMatrix({
    required double left,
    required double top,
    required double width,
    required double height,
    double zoom = 1,
    double? focusX,
    double? focusY,
  }) {
    final double boxWidth = bounds.width;
    final double boxHeight = bounds.height;
    final double safeZoom = !zoom.isFinite || zoom <= 0 ? 1 : zoom;
    if (boxWidth <= 0 || boxHeight <= 0 || width <= 0 || height <= 0) {
      // Nothing to fit. Collapse to the plot's centre so a caller's markers
      // land somewhere visible rather than at the origin.
      return Matrix4.identity()
        ..setTranslationRaw(left + width / 2, top + height / 2, 0);
    }

    final double fit = math.min(width / boxWidth, height / boxHeight);
    final double scale = fit * safeZoom;
    final double focusPointX = focusX ?? bounds.centerX;
    final double focusPointY = focusY ?? bounds.centerY;
    return Matrix4.identity()
      ..translateByDouble(
        left + width / 2 - focusPointX * scale,
        top + height / 2 - focusPointY * scale,
        0,
        1,
      )
      // Translate first, then scale, so a point maps as `scale * p + t` and the
      // focus is the one coordinate that does not move.
      ..scaleByDouble(scale, scale, 1, 1);
  }

  /// The uniform scale baked into [view].
  ///
  /// A painter divides its stroke width by this, which is what keeps a border
  /// one device pixel wide at every zoom instead of growing with the map.
  /// Assumes the axis-aligned view [computeViewMatrix] returns.
  static double scaleOf(Matrix4 view) => view.storage[0];

  /// The horizontal translation baked into [view].
  static double translationX(Matrix4 view) => view.storage[12];

  /// The vertical translation baked into [view].
  static double translationY(Matrix4 view) => view.storage[13];

  /// Maps one coordinate to plot pixels through [view], writing two entries
  /// into [out].
  ///
  /// [view] must be axis-aligned, as [computeViewMatrix] returns. A rotated
  /// view would need a full matrix multiply; nothing in this package builds
  /// one.
  void projectPoint({
    required double longitude,
    required double latitude,
    required Matrix4 view,
    required Float64List out,
  }) {
    assert(out.length >= 2, 'out must hold two entries');
    final Float64List m = view.storage;
    out[0] = projection.worldX(longitude) * m[0] + m[12];
    out[1] = projection.worldY(latitude) * m[5] + m[13];
  }

  /// Maps [length] coordinates in pairs into [outPixels], `x` then `y`.
  ///
  /// Every argument is a buffer the caller owns, so a marker pass projecting
  /// thousands of points per frame allocates nothing.
  void projectInto({
    required Float64List longitudes,
    required Float64List latitudes,
    required int length,
    required Matrix4 view,
    required Float64List outPixels,
  }) {
    assert(length <= longitudes.length && length <= latitudes.length);
    assert(outPixels.length >= length * 2, 'outPixels must hold two per point');
    final Float64List m = view.storage;
    final double scaleX = m[0];
    final double scaleY = m[5];
    final double translateX = m[12];
    final double translateY = m[13];
    for (int i = 0; i < length; i++) {
      final int offset = i * 2;
      outPixels[offset] = projection.worldX(longitudes[i]) * scaleX + translateX;
      outPixels[offset + 1] =
          projection.worldY(latitudes[i]) * scaleY + translateY;
    }
  }
}
