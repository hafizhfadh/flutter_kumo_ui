import 'dart:typed_data';

/// Largest-Triangle-Three-Buckets downsampling.
///
/// A chart is a pixel budget, not a data budget: a 400px wide plot cannot show
/// 50,000 points, and the 49,200 it cannot show still cost raster time. LTTB
/// picks the points that carry the shape — the extremes that preserve peaks and
/// troughs — instead of every nth sample, which would smooth a spike away.
///
/// Every argument is a flat array the caller owns, so a downsample pass
/// allocates nothing. Reuse the same scratch and output arrays across frames.
abstract final class KumoLttb {
  /// Writes at most [threshold] points from the first [length] entries of [xs]
  /// and [ys] into [outXs] and [outYs], and returns how many were written.
  ///
  /// The first and last points are always kept. When [threshold] is at or above
  /// [length] the input is copied unchanged. [outXs] and [outYs] must each hold
  /// at least [threshold] entries.
  static int downsample({
    required Float64List xs,
    required Float64List ys,
    required int length,
    required int threshold,
    required Float64List outXs,
    required Float64List outYs,
  }) {
    assert(length <= xs.length && length <= ys.length, 'length exceeds input');
    assert(outXs.length >= threshold, 'outXs must hold threshold entries');
    assert(outYs.length >= threshold, 'outYs must hold threshold entries');

    if (length <= 0 || threshold <= 0) {
      return 0;
    }
    if (threshold >= length) {
      for (int i = 0; i < length; i++) {
        outXs[i] = xs[i];
        outYs[i] = ys[i];
      }
      return length;
    }
    if (threshold == 1) {
      outXs[0] = xs[0];
      outYs[0] = ys[0];
      return 1;
    }
    if (threshold == 2) {
      outXs[0] = xs[0];
      outYs[0] = ys[0];
      outXs[1] = xs[length - 1];
      outYs[1] = ys[length - 1];
      return 2;
    }

    // Interior points are split into threshold - 2 buckets; the endpoints are
    // pinned, which is what makes the result stable across frames.
    final double bucketSize = (length - 2) / (threshold - 2);
    int selected = 0;

    outXs[0] = xs[0];
    outYs[0] = ys[0];
    int written = 1;

    for (int bucket = 0; bucket < threshold - 2; bucket++) {
      // The mean of the *next* bucket is the triangle's third vertex.
      int averageStart = ((bucket + 1) * bucketSize).floor() + 1;
      int averageEnd = ((bucket + 2) * bucketSize).floor() + 1;
      if (averageEnd > length) {
        averageEnd = length;
      }
      if (averageStart >= averageEnd) {
        averageStart = length - 1;
        averageEnd = length;
      }
      double averageX = 0;
      double averageY = 0;
      for (int i = averageStart; i < averageEnd; i++) {
        averageX += xs[i];
        averageY += ys[i];
      }
      final int averageCount = averageEnd - averageStart;
      averageX /= averageCount;
      averageY /= averageCount;

      int rangeStart = (bucket * bucketSize).floor() + 1;
      int rangeEnd = ((bucket + 1) * bucketSize).floor() + 1;
      if (rangeEnd > length - 1) {
        rangeEnd = length - 1;
      }
      if (rangeEnd <= rangeStart) {
        rangeEnd = rangeStart + 1;
      }

      final double anchorX = xs[selected];
      final double anchorY = ys[selected];
      double largestArea = -1;
      int best = rangeStart;
      for (int i = rangeStart; i < rangeEnd; i++) {
        // Twice the triangle area; the factor of two cancels out of the max.
        final double area =
            ((anchorX - averageX) * (ys[i] - anchorY) -
                    (anchorX - xs[i]) * (averageY - anchorY))
                .abs();
        if (area > largestArea) {
          largestArea = area;
          best = i;
        }
      }

      outXs[written] = xs[best];
      outYs[written] = ys[best];
      written++;
      selected = best;
    }

    outXs[written] = xs[length - 1];
    outYs[written] = ys[length - 1];
    return written + 1;
  }
}
