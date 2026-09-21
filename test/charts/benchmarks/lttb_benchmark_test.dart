import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

/// Length of the source series, and the LTTB threshold it is reduced to.
const int _length = 10000;
const int _threshold = 500;

/// Warm-up passes to let the JIT settle before the measured loop.
const int _warmup = 200;

/// Measured passes. Large enough that one scheduling hiccup cannot dominate.
const int _iterations = 2000;

/// A sine stack, so the downsampler has real peaks to preserve rather than a
/// straight line it could reduce trivially.
Float64List _xs() {
  final Float64List xs = Float64List(_length);
  for (int i = 0; i < _length; i++) {
    xs[i] = i.toDouble();
  }
  return xs;
}

Float64List _ys() {
  final Float64List ys = Float64List(_length);
  for (int i = 0; i < _length; i++) {
    ys[i] = math.sin(i / 40) * 50 + math.sin(i / 7) * 8 + (i % 13) * 0.5;
  }
  return ys;
}

void main() {
  group('KumoLttb.downsample', () {
    late Float64List xs;
    late Float64List ys;
    late Float64List outXs;
    late Float64List outYs;

    setUp(() {
      xs = _xs();
      ys = _ys();
      outXs = Float64List(_threshold);
      outYs = Float64List(_threshold);
    });

    test('10,000 points to 500 lands in the microsecond range', () {
      for (int i = 0; i < _warmup; i++) {
        KumoLttb.downsample(
          xs: xs,
          ys: ys,
          length: _length,
          threshold: _threshold,
          outXs: outXs,
          outYs: outYs,
        );
      }

      final Stopwatch stopwatch = Stopwatch()..start();
      int written = 0;
      for (int i = 0; i < _iterations; i++) {
        written = KumoLttb.downsample(
          xs: xs,
          ys: ys,
          length: _length,
          threshold: _threshold,
          outXs: outXs,
          outYs: outYs,
        );
      }
      stopwatch.stop();

      final double microsPerPass = stopwatch.elapsedMicroseconds / _iterations;
      final double microsPerPoint = microsPerPass / _length;
      // ignore: avoid_print
      print(
        'LTTB: $_length -> $_threshold in '
        '${microsPerPass.toStringAsFixed(2)}us/pass '
        '(${microsPerPoint.toStringAsFixed(4)}us per input point, '
        '$_iterations passes)',
      );

      expect(written, _threshold);
      // A ceiling, not a target: the measured figure is one to two orders of
      // magnitude below it, and this exists to catch a regression that makes
      // the pass accidentally quadratic rather than to pin a microsecond.
      expect(
        microsPerPass,
        lessThan(2000),
        reason: 'a 10k -> 500 pass must stay far below a millisecond',
      );
    });

    test('writes through the caller-owned arrays and allocates none', () {
      int written = KumoLttb.downsample(
        xs: xs,
        ys: ys,
        length: _length,
        threshold: _threshold,
        outXs: outXs,
        outYs: outYs,
      );
      expect(written, _threshold);

      // Dart exposes no allocation counter, so "zero heap allocations" cannot
      // be asserted directly. What is asserted is the observable half of the
      // claim: the API returns a count rather than a collection, and the only
      // arrays it touches are the ones the caller handed over — same identity,
      // same length, mutated in place. A pass that allocated its result would
      // have to return it, and this signature has nowhere to put one.
      final int outXsIdentity = identityHashCode(outXs);
      final int outYsIdentity = identityHashCode(outYs);
      final int outXsBytes = outXs.buffer.lengthInBytes;
      final int outYsBytes = outYs.buffer.lengthInBytes;
      final Float64List firstXs = Float64List.fromList(outXs);
      final Float64List firstYs = Float64List.fromList(outYs);

      final int second = KumoLttb.downsample(
        xs: xs,
        ys: ys,
        length: _length,
        threshold: _threshold,
        outXs: outXs,
        outYs: outYs,
      );

      expect(second, written, reason: 'the pass is deterministic');
      expect(identityHashCode(outXs), outXsIdentity);
      expect(identityHashCode(outYs), outYsIdentity);
      expect(outXs.buffer.lengthInBytes, outXsBytes);
      expect(outYs.buffer.lengthInBytes, outYsBytes);
      expect(outXs.length, _threshold, reason: 'never resized');
      expect(outYs.length, _threshold, reason: 'never resized');
      expect(outXs, firstXs, reason: 'the same buffer, rewritten not replaced');
      expect(outYs, firstYs);

      // Nothing written past the reported count, and the endpoints pinned.
      expect(outXs[0], xs[0]);
      expect(outXs[written - 1], xs[_length - 1]);
      expect(outYs[0], ys[0]);
      expect(outYs[written - 1], ys[_length - 1]);
    });

    test('reusing the scratch arrays for a second input rebuilds cleanly', () {
      KumoLttb.downsample(
        xs: xs,
        ys: ys,
        length: _length,
        threshold: _threshold,
        outXs: outXs,
        outYs: outYs,
      );
      final double first = outYs[_threshold ~/ 2];

      final Float64List otherYs = Float64List(_length);
      for (int i = 0; i < _length; i++) {
        otherYs[i] = -ys[i];
      }
      final int written = KumoLttb.downsample(
        xs: xs,
        ys: otherYs,
        length: _length,
        threshold: _threshold,
        outXs: outXs,
        outYs: outYs,
      );

      expect(written, _threshold);
      expect(
        outYs[_threshold ~/ 2],
        isNot(first),
        reason: 'the reused buffer holds the second run, not a stale first',
      );
    });
  });
}
