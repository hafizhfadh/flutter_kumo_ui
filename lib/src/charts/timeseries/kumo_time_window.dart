import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

import '../kumo_ring_buffer.dart';

/// The viewport a timeseries is drawn through.
///
/// Pure Dart: no canvas, no widgets, no `BuildContext`. It answers three
/// questions and nothing else: which slice of time is visible, which slice of
/// value is visible, and where a point lands inside a plot rectangle.
///
/// ```dart
/// final window = KumoTimeWindow.last(
///   const Duration(minutes: 5),
///   endTimestamp: latest,
/// );
/// window.fitY(series);
/// final int count = window.projectSeries(series, outX, outY, plot);
/// ```
///
/// Timeseries are monotonic, so both axes are linear. That is what makes the
/// whole projection expressible as one affine [Matrix4], and what makes a
/// sliding window a translation rather than a recomputation over history.
class KumoTimeWindow {
  /// Creates a window over an explicit range.
  KumoTimeWindow({
    required this.minTimestamp,
    required this.maxTimestamp,
    this.minY = 0,
    this.maxY = 1,
    this.yPadding = 0.05,
    this.includeZero = false,
  }) : assert(yPadding >= 0, 'yPadding must not be negative');

  /// A window of a fixed [duration] ending at [endTimestamp].
  ///
  /// The duration is a viewport, not a stride: it does not change when points
  /// arrive, which is what lets the window slide instead of rescaling.
  factory KumoTimeWindow.last(
    Duration duration, {
    required double endTimestamp,
    double minY = 0,
    double maxY = 1,
    double yPadding = 0.05,
    bool includeZero = false,
  }) {
    return KumoTimeWindow(
      minTimestamp: endTimestamp - duration.inMicroseconds / 1000000,
      maxTimestamp: endTimestamp,
      minY: minY,
      maxY: maxY,
      yPadding: yPadding,
      includeZero: includeZero,
    );
  }

  /// Left edge of the window, in the caller's timestamp unit.
  double minTimestamp;

  /// Right edge of the window.
  double maxTimestamp;

  /// Bottom of the value domain.
  double minY;

  /// Top of the value domain.
  double maxY;

  /// Fraction of the value span left as headroom by [fitY], applied to both
  /// ends. `0.05` keeps a peak off the top edge.
  final double yPadding;

  /// Whether [fitY] always widens the domain to include zero.
  final bool includeZero;

  /// Elapsed time across the window.
  double get timeSpan => maxTimestamp - minTimestamp;

  /// Value range across the window.
  double get valueSpan => maxY - minY;

  /// Whether the window covers any elapsed time.
  bool get hasTimeSpan => timeSpan > 0;

  /// Whether the value domain covers any range.
  bool get hasValueSpan => valueSpan > 0;

  /// Whether [timestamp] falls inside the window.
  bool containsTimestamp(double timestamp) =>
      timestamp >= minTimestamp && timestamp <= maxTimestamp;

  /// Whether [value] falls inside the value domain.
  bool containsValue(double value) => value >= minY && value <= maxY;

  /// Horizontal position of [timestamp] in `0..1`, left to right.
  ///
  /// A zero-width window has no position to report, so it collapses to the
  /// centre rather than dividing by zero. The result is not clamped: a caller
  /// clips to the plot rect instead, which keeps a line crossing the window
  /// edge straight instead of flattening it against the border.
  double normalizedX(double timestamp) =>
      hasTimeSpan ? (timestamp - minTimestamp) / timeSpan : 0.5;

  /// Vertical position of [value] in `0..1`, bottom to top.
  ///
  /// A flat series has no range to report, so it sits on the centre line.
  double normalizedY(double value) =>
      hasValueSpan ? (value - minY) / valueSpan : 0.5;

  /// Slides the window so it ends at [endTimestamp], keeping its duration.
  void slideTo(double endTimestamp) {
    final double span = timeSpan;
    maxTimestamp = endTimestamp;
    minTimestamp = endTimestamp - span;
  }

  /// Shifts the window by [delta] in timestamp units.
  void slideBy(double delta) {
    minTimestamp += delta;
    maxTimestamp += delta;
  }

  /// Sets the value domain from the data, with [yPadding] headroom.
  ///
  /// Restrict the scan with [fromTimestamp] and [toTimestamp] to fit only what
  /// is visible, which is what a sliding window usually wants: a spike that has
  /// scrolled off should stop stretching the axis.
  void fitY(
    KumoSeriesBuffer series, {
    double? fromTimestamp,
    double? toTimestamp,
    int start = 0,
    int? end,
  }) {
    final int last = end ?? series.length;
    if (last <= start) {
      return;
    }

    double lowest = double.infinity;
    double highest = double.negativeInfinity;
    for (int i = start; i < last; i++) {
      if (fromTimestamp != null && series.xAt(i) < fromTimestamp) {
        continue;
      }
      if (toTimestamp != null && series.xAt(i) > toTimestamp) {
        continue;
      }
      final double value = series.yAt(i);
      if (value < lowest) {
        lowest = value;
      }
      if (value > highest) {
        highest = value;
      }
    }
    if (lowest > highest) {
      return;
    }

    if (includeZero) {
      lowest = math.min(lowest, 0);
      highest = math.max(highest, 0);
    }

    final double padding = (highest - lowest) * yPadding;
    minY = lowest - padding;
    maxY = highest + padding;
  }

  /// Projects `start..end` of [series] into [outX] and [outY], and returns how
  /// many points were written.
  ///
  /// Both output arrays are caller-owned and are written in place, so a
  /// streaming frame allocates nothing here. Points outside the window are
  /// projected anyway; clip to [plotRect] when painting, so the line crosses
  /// the edge instead of stopping short of it.
  int projectSeries(
    KumoSeriesBuffer series,
    Float64List outX,
    Float64List outY,
    Rect plotRect, {
    int start = 0,
    int? end,
  }) {
    final int last = end ?? series.length;
    assert(last <= series.length, 'end exceeds the series');
    assert(outX.length >= last - start, 'outX is too small');
    assert(outY.length >= last - start, 'outY is too small');

    // One affine mapping per axis, hoisted out of the loop. These are the same
    // expressions computeDomainTransform puts in the matrix, so the matrix and
    // this pass cannot disagree.
    final double spanX = timeSpan;
    final double spanY = valueSpan;
    final bool hasX = spanX > 0;
    final bool hasY = spanY > 0;

    final double scaleX = hasX ? plotRect.width / spanX : 0;
    final double translateX = hasX
        ? plotRect.left - minTimestamp * scaleX
        : plotRect.center.dx;
    final double scaleY = hasY ? -plotRect.height / spanY : 0;
    final double translateY = hasY
        ? plotRect.bottom - minY * scaleY
        : plotRect.center.dy;

    for (int i = start; i < last; i++) {
      final int slot = i - start;
      outX[slot] = series.xAt(i) * scaleX + translateX;
      outY[slot] = series.yAt(i) * scaleY + translateY;
    }
    return last - start;
  }

  /// The matrix mapping normalized coordinates into [plotRect] pixels.
  ///
  /// `x` runs left to right and `y` bottom to top, so normalized `(0, 0)` is the
  /// bottom-left of the plot and `(1, 1)` the top-right. Use it when a caller
  /// works in normalized space; use [computeDomainTransform] when it works in
  /// timestamps and values.
  Matrix4 computeTransform(Rect plotRect) {
    final Matrix4 matrix = Matrix4.zero();
    matrix.setEntry(0, 0, plotRect.width);
    matrix.setEntry(0, 3, plotRect.left);
    matrix.setEntry(1, 1, -plotRect.height);
    matrix.setEntry(1, 3, plotRect.bottom);
    matrix.setEntry(2, 2, 1);
    matrix.setEntry(3, 3, 1);
    return matrix;
  }

  /// The matrix mapping `(timestamp, value)` straight into [plotRect] pixels.
  ///
  /// This is [computeTransform] composed with the window mapping, so a point
  /// can be projected with one `transform3` instead of normalizing first.
  Matrix4 computeDomainTransform(Rect plotRect) {
    final Matrix4 matrix = Matrix4.zero();

    if (hasTimeSpan) {
      final double scaleX = plotRect.width / timeSpan;
      matrix.setEntry(0, 0, scaleX);
      matrix.setEntry(0, 3, plotRect.left - minTimestamp * scaleX);
    } else {
      matrix.setEntry(0, 3, plotRect.center.dx);
    }

    if (hasValueSpan) {
      final double scaleY = -plotRect.height / valueSpan;
      matrix.setEntry(1, 1, scaleY);
      matrix.setEntry(1, 3, plotRect.bottom - minY * scaleY);
    } else {
      matrix.setEntry(1, 3, plotRect.center.dy);
    }

    matrix.setEntry(2, 2, 1);
    matrix.setEntry(3, 3, 1);
    return matrix;
  }

  /// Writes only the translation entries of a [computeDomainTransform] matrix
  /// for the window's current bounds.
  ///
  /// The cheap path for a live chart: when only the window moved and its spans
  /// are unchanged, the scale entries still hold, so two entries change instead
  /// of the whole matrix being rebuilt. Nothing over history is reprojected.
  void updateTranslation(Matrix4 matrix, Rect plotRect) {
    if (hasTimeSpan) {
      matrix.setEntry(0, 3, plotRect.left - minTimestamp * matrix.entry(0, 0));
    } else {
      matrix.setEntry(0, 3, plotRect.center.dx);
    }
    if (hasValueSpan) {
      matrix.setEntry(1, 3, plotRect.bottom - minY * matrix.entry(1, 1));
    } else {
      matrix.setEntry(1, 3, plotRect.center.dy);
    }
  }

  /// Projects one point with [computeDomainTransform] maths, allocating a
  /// [Vector3].
  ///
  /// For a single readout, not for a loop: use [projectSeries] in a paint pass.
  Vector3 projectPoint(double timestamp, double value, Rect plotRect) {
    final Matrix4 matrix = computeDomainTransform(plotRect);
    return matrix.transform3(Vector3(timestamp, value, 0));
  }
}
