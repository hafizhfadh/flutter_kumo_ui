import 'dart:async';

import 'package:flutter/widgets.dart';

import 'kumo_ring_buffer.dart';

/// Runs [callback] once, after the current frame.
///
/// The default flush policy for [KumoDataBuffer]: a burst of socket messages
/// lands in one frame's work instead of one rebuild each. Swap it in tests, or
/// to drive flushes from a timer.
typedef KumoFlushScheduler = void Function(VoidCallback callback);

/// The default scheduler: one flush per frame, via the Flutter binding.
///
/// Needs a binding, which any widget-based app has. Inject a different
/// [KumoFlushScheduler] in a pure Dart environment.
void scheduleAfterFrame(VoidCallback callback) {
  WidgetsBinding.instance.addPostFrameCallback((Duration _) => callback());
}

/// Coalesces high-frequency appends into one flush per frame.
///
/// A socket pushing 100 messages a second cannot be allowed to trigger 100
/// rebuilds: at 60Hz the extra 40 are work the display cannot even show, and
/// each one re-runs layout. This buffers arrivals and calls [onFlush] at most
/// once per frame, with backpressure that keeps the *newest* [capacity] entries
/// when a burst overflows.
class KumoDataBuffer<T> {
  /// Creates a buffer that flushes through [onFlush].
  KumoDataBuffer({
    required this.capacity,
    required this.onFlush,
    KumoFlushScheduler? scheduler,
  }) : assert(capacity > 0, 'capacity must be positive'),
       _scheduler = scheduler ?? scheduleAfterFrame,
       _pending = KumoRingBuffer<T>(capacity);

  /// Maximum entries held between flushes.
  final int capacity;

  /// Called with each pending batch, at most once per frame.
  final void Function(List<T> batch) onFlush;

  final KumoFlushScheduler _scheduler;
  final KumoRingBuffer<T> _pending;
  bool _isScheduled = false;
  bool _isDisposed = false;

  /// Entries waiting for the next flush.
  int get pendingCount => _pending.length;

  /// Whether a flush is already queued for this frame.
  bool get isFlushScheduled => _isScheduled;

  /// Queues one entry.
  void append(T value) {
    if (_isDisposed) {
      return;
    }
    _pending.add(value);
    _schedule();
  }

  /// Queues [values] in order.
  void appendBatch(Iterable<T> values) {
    if (_isDisposed) {
      return;
    }
    _pending.addAll(values);
    _schedule();
  }

  void _schedule() {
    if (_isScheduled) {
      return;
    }
    _isScheduled = true;
    _scheduler(_flush);
  }

  /// Flushes immediately instead of waiting for the frame callback. Safe to
  /// call when nothing is pending, which makes it a convenient teardown step.
  void flush() {
    if (_isScheduled) {
      _isScheduled = false;
    }
    _flush();
  }

  void _flush() {
    _isScheduled = false;
    if (_isDisposed || _pending.isEmpty) {
      return;
    }
    final List<T> batch = _pending.toList();
    _pending.clear();
    onFlush(batch);
  }

  /// Drops anything pending without flushing it.
  void clear() => _pending.clear();

  /// Stops flushing. Further appends are ignored.
  void dispose() {
    _isDisposed = true;
    _pending.clear();
  }
}

/// Holds the points a chart draws, and the single notification that says they
/// changed.
///
/// Bind it straight to a painter: `CustomPaint(painter: MyPainter(repaint:
/// controller))`. A [Listenable] repaint re-runs `paint` without rebuilding the
/// widget tree, which is what keeps a streaming chart off the build phase.
class KumoChartController<T> extends ChangeNotifier {
  /// Creates a controller retaining at most [capacity] points.
  KumoChartController({this.capacity = 1024, KumoFlushScheduler? scheduler})
    : _scheduler = scheduler ?? scheduleAfterFrame;

  /// Maximum points retained. Older points are dropped, not reallocated.
  final int capacity;

  final KumoFlushScheduler _scheduler;
  late final KumoRingBuffer<T> _points = KumoRingBuffer<T>(capacity);
  late final KumoDataBuffer<T> _buffer = KumoDataBuffer<T>(
    capacity: capacity,
    onFlush: (List<T> batch) {
      for (final T point in batch) {
        _points.add(point);
      }
      notifyListeners();
    },
    scheduler: _scheduler,
  );

  /// Number of points currently retained.
  int get length => _points.length;

  /// Whether nothing is retained.
  bool get isEmpty => _points.isEmpty;

  /// Point at [index], where `0` is the oldest.
  T pointAt(int index) => _points[index];

  /// Visits every retained point, oldest first, without building a list.
  void forEach(void Function(T point) action) => _points.forEach(action);

  /// Queues one point. Listeners are notified at most once per frame.
  void append(T point) => _buffer.append(point);

  /// Queues several points in order.
  void appendBatch(Iterable<T> points) => _buffer.appendBatch(points);

  /// Pushes anything queued through immediately, then notifies.
  void flush() => _buffer.flush();

  /// Drops every retained point.
  void clear() {
    _buffer.clear();
    _points.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _buffer.dispose();
    super.dispose();
  }
}

/// Feeds a [KumoChartController] from a stream.
///
/// The adapter for SSE, WebSocket or any other [Stream] of decoded messages:
/// hand it the stream and a parser, and it appends through the controller's
/// batching path, so a fast producer never turns into a per-message rebuild.
class KumoStreamingChartSource<T> {
  /// Subscribes to [stream], parsing each message with [parser].
  KumoStreamingChartSource({
    required this.stream,
    required this.parser,
    required this.controller,
    this.onError,
  }) {
    _subscription = stream.listen(
      (dynamic raw) => controller.append(parser(raw)),
      onError: (Object error, StackTrace stackTrace) =>
          onError?.call(error),
      cancelOnError: false,
    );
  }

  /// The messages to consume.
  final Stream<dynamic> stream;

  /// Maps one raw message onto a point.
  final T Function(dynamic raw) parser;

  /// Where parsed points are delivered.
  final KumoChartController<T> controller;

  /// Called when the stream reports an error. The subscription stays open, so a
  /// transient socket error does not silently end the chart.
  final void Function(Object error)? onError;

  late final StreamSubscription<dynamic> _subscription;

  /// Whether the source is still consuming.
  bool get isListening => !_isDisposed;

  bool _isDisposed = false;

  /// Cancels the subscription.
  Future<void> dispose() async {
    _isDisposed = true;
    await _subscription.cancel();
  }
}
