import 'dart:async';
import 'dart:math' as math;

import 'package:kumo_ui/kumo_ui.dart';

/// The live timeseries engine the example owns for the whole app.
///
/// It is deliberately not owned by the route that draws it. A dashboard that
/// loses its history because the operator opened another screen is the bug this
/// shape exists to avoid: the buffer, the viewport and the run/pause state all
/// live above the router, so navigating away and back resumes onto the same
/// series instead of an empty one.
///
/// The feed is the streaming path the library documents, end to end: a
/// simulated server-sent-event stream, through [KumoStreamingChartSource], into
/// a [KumoChartController], which coalesces a burst into one repaint per frame
/// and notifies the chart through a [Listenable] rather than a rebuild.
/// [series] is the raster-friendly mirror of the controller's points, which is
/// what `KumoTimeseriesChart` draws from.
class LiveSeriesFeed {
  /// Creates a paused feed.
  ///
  /// Call [start] to open the stream. Nothing ticks until then, which keeps a
  /// screen that never shows the chart free of timers.
  LiveSeriesFeed({
    this.capacity = 2048,
    this.interval = const Duration(milliseconds: 40),
    this.windowLength = const Duration(seconds: 20),
  }) : series = KumoSeriesBuffer(capacity: capacity),
       // A request rate is a magnitude, so the value axis is pinned to include
       // zero rather than floating on whatever the window happens to contain.
       window = KumoTimeWindow.last(
         windowLength,
         endTimestamp: 0,
         includeZero: true,
       ) {
    controller = KumoChartController<double>(capacity: capacity);
    // Registered before any painter binds itself to the controller, so the
    // mirror is already current by the time the frame that repaint schedules
    // actually paints.
    controller.addListener(_mirror);
  }

  /// Points retained before the oldest are dropped.
  final int capacity;

  /// Delay between simulated messages.
  final Duration interval;

  /// Elapsed time the viewport shows.
  Duration windowLength;

  /// The points the chart rasterises.
  final KumoSeriesBuffer series;

  /// The sliding viewport over [series].
  final KumoTimeWindow window;

  /// The controller the chart binds to as `repaint`.
  ///
  /// A notification re-runs the series layer's `paint` and touches no widget.
  late final KumoChartController<double> controller;

  KumoStreamingChartSource<double>? _source;
  int _received = 0;
  int _mirrored = 0;
  double _timestamp = 0;
  double _latest = 0;

  /// Whether the simulated stream is open.
  bool get isRunning => _source != null;

  /// Number of points currently drawn.
  int get sampleCount => series.length;

  /// The most recent value, for a readout.
  double get latest => _latest;

  /// The most recent value's timestamp, in seconds since the feed started.
  double get elapsed => _timestamp;

  /// The last error the stream reported, if any.
  String? get lastError => _lastError;
  String? _lastError;

  /// Opens the simulated stream.
  void start() {
    if (_source != null) {
      return;
    }
    _lastError = null;
    _source = KumoStreamingChartSource<double>(
      stream: _messages(),
      // The parser is where a raw message becomes a point, so it is also where
      // arrivals are counted: the mirror needs to know how many points are new.
      parser: (dynamic raw) {
        _received++;
        return raw as double;
      },
      controller: controller,
      onError: (Object error) => _lastError = error.toString(),
    );
  }

  /// Closes the simulated stream. The buffer and the viewport are untouched.
  void stop() {
    final KumoStreamingChartSource<double>? source = _source;
    _source = null;
    if (source != null) {
      unawaited(source.dispose());
    }
  }

  /// Opens the stream if it is closed, and closes it if it is open.
  void toggle() => isRunning ? stop() : start();

  /// Drops every point and rewinds the viewport.
  void clear() {
    // Reset the counters first: `controller.clear()` notifies synchronously,
    // and the mirror runs on that notification.
    _received = 0;
    _mirrored = 0;
    controller.clear();
    series.clear();
    _timestamp = 0;
    _latest = 0;
    window.slideTo(0);
  }

  /// Re-fits the value domain to what the viewport currently shows.
  ///
  /// Called from the page's once-a-second rebuild rather than from every tick:
  /// the axis is read at that rate anyway, and a domain that re-fits 25 times a
  /// second is a line that visibly breathes.
  void refreshDomain() {
    window.fitY(series, fromTimestamp: window.minTimestamp);
  }

  /// Changes how much elapsed time the viewport shows, keeping its right edge.
  ///
  /// The duration is a viewport, not a stride: widening it does not rescale the
  /// data, it reveals more of it, which is why the oldest points stay put.
  void setWindowLength(Duration length) {
    windowLength = length;
    window.minTimestamp =
        window.maxTimestamp - length.inMicroseconds / 1000000;
    refreshDomain();
  }

  /// Releases the stream and the controller.
  void dispose() {
    stop();
    controller.removeListener(_mirror);
    controller.dispose();
  }

  /// Copies the controller's newly arrived points into [series].
  ///
  /// The controller is the ingest buffer and [series] is the drawing mirror.
  /// Both are fixed-capacity rings that drop their oldest entry, so the number
  /// of fresh points is arrivals minus arrivals already mirrored — clamped to
  /// what the controller still retains, which is what it does when a burst
  /// arrives larger than its capacity.
  void _mirror() {
    final int length = controller.length;
    if (length == 0) {
      return;
    }
    final int fresh = math.min(_received - _mirrored, length);
    if (fresh <= 0) {
      return;
    }
    for (int i = length - fresh; i < length; i++) {
      _timestamp += interval.inMicroseconds / 1000000;
      series.add(_timestamp, controller.pointAt(i));
    }
    _mirrored = _received;
    _latest = controller.pointAt(length - 1);
    window.slideTo(_timestamp);
  }

  /// A simulated WebSocket: one decoded message every [interval], carrying a
  /// request-rate that has a daily swell, a short cycle and a little noise.
  Stream<double> _messages() =>
      Stream<double>.periodic(interval, (int i) {
        final double seconds = i * interval.inMicroseconds / 1000000;
        return 120 +
            58 * math.sin(seconds / 3.1) +
            22 * math.sin(seconds / 0.7) +
            9 * math.sin(seconds / 0.13);
      });
}
