import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

/// A scheduler that queues callbacks so a test decides when a frame happens.
class _ManualScheduler {
  final List<VoidCallback> _queued = <VoidCallback>[];

  void call(VoidCallback callback) => _queued.add(callback);

  /// Runs everything queued so far.
  void frame() {
    final List<VoidCallback> batch = List<VoidCallback>.of(_queued);
    _queued.clear();
    for (final VoidCallback callback in batch) {
      callback();
    }
  }
}

void main() {
  group('KumoRingBuffer', () {
    test('keeps insertion order and drops the oldest past capacity', () {
      final KumoRingBuffer<int> buffer = KumoRingBuffer<int>(3);

      expect(buffer.isEmpty, isTrue);
      buffer.addAll(<int>[1, 2, 3]);
      expect(buffer.isFull, isTrue);
      expect(buffer.toList(), <int>[1, 2, 3]);
      expect(buffer.first, 1);
      expect(buffer.last, 3);

      // Wrapping must preserve order, which a naive ring gets wrong.
      buffer.add(4);
      buffer.add(5);
      expect(buffer.length, 3);
      expect(buffer.toList(), <int>[3, 4, 5]);
      expect(buffer[0], 3);
      expect(buffer[2], 5);
    });

    test('clear drops entries but keeps the capacity', () {
      final KumoRingBuffer<int> buffer = KumoRingBuffer<int>(2)..addAll(<int>[1, 2]);
      buffer.clear();

      expect(buffer.isEmpty, isTrue);
      expect(buffer.capacity, 2);
      buffer.add(9);
      expect(buffer.toList(), <int>[9]);
    });
  });

  group('KumoSeriesBuffer', () {
    test('linearizes a wrapped series back into time order', () {
      final KumoSeriesBuffer series = KumoSeriesBuffer(capacity: 4);
      for (int i = 0; i < 6; i++) {
        series.add(i.toDouble(), (i * 10).toDouble());
      }

      expect(series.length, 4);
      expect(series.xAt(0), 2);
      expect(series.lastY, 50);

      final Float64List xs = Float64List(4);
      final Float64List ys = Float64List(4);
      series.linearizeInto(xs, ys);

      expect(xs, <double>[2, 3, 4, 5]);
      expect(ys, <double>[20, 30, 40, 50]);
      expect(series.minX, 2);
      expect(series.maxX, 5);
      expect(series.minY, 20);
      expect(series.maxY, 50);
    });
  });

  group('KumoLttb', () {
    /// A flat line with one spike, which every-nth sampling would lose.
    (Float64List, Float64List) spikeSeries(int length, int spikeAt) {
      final Float64List xs = Float64List(length);
      final Float64List ys = Float64List(length);
      for (int i = 0; i < length; i++) {
        xs[i] = i.toDouble();
        ys[i] = i == spikeAt ? 1000 : 1;
      }
      return (xs, ys);
    }

    test('writes exactly threshold points and pins the endpoints', () {
      final (Float64List xs, Float64List ys) = spikeSeries(1000, 500);
      const int threshold = 50;
      final Float64List outXs = Float64List(threshold);
      final Float64List outYs = Float64List(threshold);

      final int written = KumoLttb.downsample(
        xs: xs,
        ys: ys,
        length: 1000,
        threshold: threshold,
        outXs: outXs,
        outYs: outYs,
      );

      expect(written, threshold);
      expect(outXs[0], xs[0]);
      expect(outYs[0], ys[0]);
      expect(outXs[threshold - 1], xs[999]);
      expect(outYs[threshold - 1], ys[999]);
    });

    test('keeps a single spike that every-nth sampling would drop', () {
      final (Float64List xs, Float64List ys) = spikeSeries(1000, 499);
      const int threshold = 40;
      final Float64List outXs = Float64List(threshold);
      final Float64List outYs = Float64List(threshold);

      KumoLttb.downsample(
        xs: xs,
        ys: ys,
        length: 1000,
        threshold: threshold,
        outXs: outXs,
        outYs: outYs,
      );

      double peak = 0;
      for (int i = 0; i < threshold; i++) {
        if (outYs[i] > peak) {
          peak = outYs[i];
        }
      }
      expect(peak, 1000, reason: 'the peak carries the shape and must survive');
    });

    test('copies the input when the threshold is already large enough', () {
      final (Float64List xs, Float64List ys) = spikeSeries(10, 5);
      final Float64List outXs = Float64List(20);
      final Float64List outYs = Float64List(20);

      final int written = KumoLttb.downsample(
        xs: xs,
        ys: ys,
        length: 10,
        threshold: 20,
        outXs: outXs,
        outYs: outYs,
      );

      expect(written, 10);
      expect(outYs[5], 1000);
    });

    test('honours a two-point threshold', () {
      final (Float64List xs, Float64List ys) = spikeSeries(100, 50);
      final Float64List outXs = Float64List(2);
      final Float64List outYs = Float64List(2);

      final int written = KumoLttb.downsample(
        xs: xs,
        ys: ys,
        length: 100,
        threshold: 2,
        outXs: outXs,
        outYs: outYs,
      );

      expect(written, 2);
      expect(outXs, <double>[0, 99]);
    });
  });

  group('KumoDataBuffer', () {
    test('coalesces a burst into a single flush', () {
      final _ManualScheduler scheduler = _ManualScheduler();
      final List<List<int>> flushes = <List<int>>[];
      final KumoDataBuffer<int> buffer = KumoDataBuffer<int>(
        capacity: 100,
        onFlush: flushes.add,
        scheduler: scheduler.call,
      );

      for (int i = 0; i < 100; i++) {
        buffer.append(i);
      }

      expect(buffer.pendingCount, 100);
      expect(buffer.isFlushScheduled, isTrue);
      expect(flushes, isEmpty, reason: 'nothing flushes before the frame');

      scheduler.frame();

      expect(flushes.length, 1, reason: '100 appends, 1 flush');
      expect(flushes.single.length, 100);
      expect(buffer.pendingCount, 0);
    });

    test('keeps the newest entries when a burst overflows', () {
      final _ManualScheduler scheduler = _ManualScheduler();
      final List<List<int>> flushes = <List<int>>[];
      final KumoDataBuffer<int> buffer = KumoDataBuffer<int>(
        capacity: 3,
        onFlush: flushes.add,
        scheduler: scheduler.call,
      );

      buffer.appendBatch(<int>[1, 2, 3, 4, 5]);
      scheduler.frame();

      expect(flushes.single, <int>[3, 4, 5]);
    });

    test('flush pushes a pending batch through immediately', () {
      final _ManualScheduler scheduler = _ManualScheduler();
      final List<List<int>> flushes = <List<int>>[];
      final KumoDataBuffer<int> buffer = KumoDataBuffer<int>(
        capacity: 4,
        onFlush: flushes.add,
        scheduler: scheduler.call,
      );

      buffer.append(7);
      buffer.flush();

      expect(flushes.single, <int>[7]);
      expect(buffer.isFlushScheduled, isFalse);

      // The queued frame callback must not flush the same batch twice.
      scheduler.frame();
      expect(flushes.length, 1);
    });

    test('ignores appends after dispose', () {
      final _ManualScheduler scheduler = _ManualScheduler();
      final List<List<int>> flushes = <List<int>>[];
      final KumoDataBuffer<int> buffer = KumoDataBuffer<int>(
        capacity: 4,
        onFlush: flushes.add,
        scheduler: scheduler.call,
      );

      buffer.dispose();
      buffer.append(1);
      scheduler.frame();

      expect(flushes, isEmpty);
    });
  });

  group('KumoChartController', () {
    test('notifies once per frame and retains the points', () {
      final _ManualScheduler scheduler = _ManualScheduler();
      final KumoChartController<int> controller = KumoChartController<int>(
        capacity: 10,
        scheduler: scheduler.call,
      );
      addTearDown(controller.dispose);
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.appendBatch(<int>[1, 2, 3]);
      expect(notifications, 0);

      scheduler.frame();

      expect(notifications, 1);
      expect(controller.length, 3);
      expect(controller.pointAt(0), 1);
      expect(controller.pointAt(2), 3);

      final List<int> seen = <int>[];
      controller.forEach(seen.add);
      expect(seen, <int>[1, 2, 3]);
    });

    test('drops the oldest points past capacity', () {
      final _ManualScheduler scheduler = _ManualScheduler();
      final KumoChartController<int> controller = KumoChartController<int>(
        capacity: 3,
        scheduler: scheduler.call,
      );
      addTearDown(controller.dispose);

      controller.appendBatch(<int>[1, 2, 3, 4]);
      scheduler.frame();

      expect(controller.length, 3);
      expect(controller.pointAt(0), 2);
    });
  });

  group('KumoStreamingChartSource', () {
    test('parses each message into the controller in one flush', () async {
      final _ManualScheduler scheduler = _ManualScheduler();
      final KumoChartController<int> controller = KumoChartController<int>(
        capacity: 10,
        scheduler: scheduler.call,
      );
      addTearDown(controller.dispose);

      final StreamController<dynamic> messages = StreamController<dynamic>();
      final KumoStreamingChartSource<int> source = KumoStreamingChartSource<int>(
        stream: messages.stream,
        parser: (dynamic raw) => (raw as num).toInt(),
        controller: controller,
      );
      addTearDown(source.dispose);

      int notifications = 0;
      controller.addListener(() => notifications++);

      messages.add(1);
      messages.add(2.0);
      messages.add(3.9);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isEmpty, isTrue, reason: 'still batched');
      scheduler.frame();

      expect(notifications, 1, reason: 'three messages, one notification');
      expect(controller.pointAt(2), 3);
    });

    test('reports a stream error without ending the subscription', () async {
      final _ManualScheduler scheduler = _ManualScheduler();
      final KumoChartController<int> controller = KumoChartController<int>(
        capacity: 10,
        scheduler: scheduler.call,
      );
      addTearDown(controller.dispose);

      final StreamController<dynamic> messages = StreamController<dynamic>();
      final List<Object> errors = <Object>[];
      final KumoStreamingChartSource<int> source = KumoStreamingChartSource<int>(
        stream: messages.stream,
        parser: (dynamic raw) => (raw as num).toInt(),
        controller: controller,
        onError: errors.add,
      );
      addTearDown(source.dispose);

      messages.add(1);
      messages.addError(StateError('socket reset'));
      messages.add(2);
      await Future<void>.delayed(Duration.zero);

      expect(errors.single, isA<StateError>());
      expect(source.isListening, isTrue);

      scheduler.frame();
      expect(controller.length, 2, reason: 'messages after the error still land');
    });
  });
}
