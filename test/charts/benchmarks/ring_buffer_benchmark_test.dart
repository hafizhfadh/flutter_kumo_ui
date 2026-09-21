import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

/// Appends measured. A stream pushing once per millisecond produces 3.6M an
/// hour, so 100k is a small fraction of a live session.
const int _appends = 100000;

/// Capacity of each buffer. Deliberately much smaller than [_appends], so every
/// pass exercises the overwrite-the-oldest path rather than only filling up.
const int _capacity = 4096;

void main() {
  group('KumoSeriesBuffer', () {
    test('100,000 appends are far faster than the feed can produce them', () {
      final KumoSeriesBuffer series = KumoSeriesBuffer(capacity: _capacity);

      // Warm up, including a wrap, so the measured loop is not the first time
      // the modulo path runs.
      for (int i = 0; i < _capacity * 2; i++) {
        series.add(i.toDouble(), i.toDouble());
      }

      final Stopwatch stopwatch = Stopwatch()..start();
      for (int i = 0; i < _appends; i++) {
        series.add(i.toDouble(), (i % 100).toDouble());
      }
      stopwatch.stop();

      final double microsPerAppend = stopwatch.elapsedMicroseconds / _appends;
      final double appendsPerSecond =
          _appends / (stopwatch.elapsedMicroseconds / 1000000);
      // ignore: avoid_print
      print(
        'KumoSeriesBuffer: $_appends appends in '
        '${stopwatch.elapsedMilliseconds}ms '
        '(${microsPerAppend.toStringAsFixed(4)}us/append, '
        '${appendsPerSecond.toStringAsFixed(0)} appends/sec)',
      );

      // The storage is two fixed Float64Lists, so the buffer never grows.
      expect(series.capacity, _capacity);
      expect(series.length, _capacity);
      expect(series.isFull, isTrue);
      // The newest point survived the wrap, and the ring kept time order.
      expect(series.lastY, ((_appends - 1) % 100).toDouble());
      expect(series.xAt(_capacity - 1), (_appends - 1).toDouble());
      expect(
        series.xAt(0),
        (_appends - _capacity).toDouble(),
        reason: 'the oldest retained point is exactly one capacity back',
      );

      expect(
        appendsPerSecond,
        greaterThan(_appends),
        reason: 'must comfortably exceed the 100k/sec feed it serves',
      );
    });

    test('wrapping does not leak into min/max', () {
      final KumoSeriesBuffer series = KumoSeriesBuffer(capacity: 4);
      for (int i = 0; i < 10; i++) {
        series.add(i.toDouble(), i.toDouble());
      }
      expect(series.minY, 6);
      expect(series.maxY, 9);
    });
  });

  group('KumoRingBuffer', () {
    test('100,000 appends keep constant capacity and no growth', () {
      final KumoRingBuffer<int> ring = KumoRingBuffer<int>(_capacity);

      for (int i = 0; i < _capacity * 2; i++) {
        ring.add(i);
      }

      final Stopwatch stopwatch = Stopwatch()..start();
      for (int i = 0; i < _appends; i++) {
        ring.add(i);
      }
      stopwatch.stop();

      final double microsPerAppend = stopwatch.elapsedMicroseconds / _appends;
      final double appendsPerSecond =
          _appends / (stopwatch.elapsedMicroseconds / 1000000);
      // ignore: avoid_print
      print(
        'KumoRingBuffer: $_appends appends in '
        '${stopwatch.elapsedMilliseconds}ms '
        '(${microsPerAppend.toStringAsFixed(4)}us/append, '
        '${appendsPerSecond.toStringAsFixed(0)} appends/sec)',
      );

      expect(ring.capacity, _capacity);
      expect(ring.length, _capacity);
      expect(ring.isFull, isTrue);
      expect(ring.last, _appends - 1);
      expect(ring.first, _appends - _capacity);
      expect(ring[0], _appends - _capacity);
      expect(ring[_capacity - 1], _appends - 1);

      expect(appendsPerSecond, greaterThan(_appends));
    });

    test('clear() drops the entries and keeps the allocation', () {
      final KumoRingBuffer<int> ring = KumoRingBuffer<int>(_capacity);
      for (int i = 0; i < _appends; i++) {
        ring.add(i);
      }
      ring.clear();

      expect(ring.length, 0);
      expect(ring.isEmpty, isTrue);
      expect(ring.capacity, _capacity, reason: 'the backing store is reused');

      ring.add(7);
      expect(ring.length, 1);
      expect(ring.first, 7);
    });
  });

  group('KumoDataBuffer coalescing', () {
    test('a burst of 100,000 arrivals collapses to one flush per frame', () {
      final List<List<int>> flushes = <List<int>>[];
      final List<VoidCallback> scheduled = <VoidCallback>[];
      final KumoDataBuffer<int> buffer = KumoDataBuffer<int>(
        capacity: _capacity,
        onFlush: flushes.add,
        scheduler: scheduled.add,
      );

      final Stopwatch stopwatch = Stopwatch()..start();
      for (int i = 0; i < _appends; i++) {
        buffer.append(i);
      }
      stopwatch.stop();

      // ignore: avoid_print
      print(
        'KumoDataBuffer: $_appends arrivals queued in '
        '${stopwatch.elapsedMilliseconds}ms, '
        '${scheduled.length} flush(es) scheduled',
      );

      expect(
        scheduled.length,
        1,
        reason: '100k arrivals inside one frame schedule exactly one flush',
      );
      expect(
        buffer.pendingCount,
        _capacity,
        reason: 'overflow keeps the newest',
      );

      scheduled.removeAt(0)();
      expect(flushes, hasLength(1));
      expect(flushes.first, hasLength(_capacity));
      expect(
        flushes.first.last,
        _appends - 1,
        reason: 'backpressure drops the oldest, never the newest',
      );
    });
  });
}
