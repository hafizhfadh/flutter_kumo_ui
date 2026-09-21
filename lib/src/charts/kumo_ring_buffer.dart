import 'dart:typed_data';

/// A fixed-capacity circular buffer.
///
/// Growing a list per tick is the usual cause of garbage-collection pauses in a
/// streaming chart, so this never reallocates: once [capacity] slots are used,
/// the oldest entry is overwritten. See `Performance` in the chart notes.
class KumoRingBuffer<T> {
  /// Creates a buffer holding at most [capacity] entries.
  KumoRingBuffer(this.capacity)
    : assert(capacity > 0, 'capacity must be positive'),
      _items = List<T?>.filled(capacity, null);

  /// Maximum number of entries retained.
  final int capacity;

  final List<T?> _items;
  int _start = 0;
  int _length = 0;

  /// Number of entries currently held.
  int get length => _length;

  /// Whether the buffer holds nothing.
  bool get isEmpty => _length == 0;

  /// Whether the buffer has reached [capacity].
  bool get isFull => _length == capacity;

  /// Appends [value], overwriting the oldest entry when full.
  void add(T value) {
    final int index = (_start + _length) % capacity;
    _items[index] = value;
    if (_length == capacity) {
      _start = (_start + 1) % capacity;
    } else {
      _length++;
    }
  }

  /// Appends every value in [values], in order.
  void addAll(Iterable<T> values) {
    for (final T value in values) {
      add(value);
    }
  }

  /// Entry at [index], where `0` is the oldest.
  T operator [](int index) {
    assert(index >= 0 && index < _length, 'index out of range');
    return _items[(_start + index) % capacity]!;
  }

  /// The oldest entry.
  T get first => this[0];

  /// The newest entry.
  T get last => this[_length - 1];

  /// Visits every entry, oldest first.
  void forEach(void Function(T value) action) {
    for (int i = 0; i < _length; i++) {
      action(this[i]);
    }
  }

  /// Copies the contents, oldest first.
  List<T> toList() => <T>[for (int i = 0; i < _length; i++) this[i]];

  /// Drops every entry while keeping the allocation.
  void clear() {
    for (int i = 0; i < capacity; i++) {
      _items[i] = null;
    }
    _start = 0;
    _length = 0;
  }
}

/// A numeric series backed by [Float64List], with no per-append allocation.
///
/// The storage for one series is two flat arrays read through a start offset, so
/// a ring wrap never copies. Pair it with [KumoLttb] before painting: a 400px
/// wide chart cannot show 50,000 points, and the ones it cannot show still cost
/// raster time.
class KumoSeriesBuffer {
  /// Creates a series holding at most [capacity] points.
  KumoSeriesBuffer({required this.capacity})
    : assert(capacity > 0, 'capacity must be positive'),
      _xs = Float64List(capacity),
      _ys = Float64List(capacity);

  /// Maximum number of points retained.
  final int capacity;

  final Float64List _xs;
  final Float64List _ys;
  int _start = 0;
  int _length = 0;

  /// Number of points currently held.
  int get length => _length;

  /// Whether the series holds nothing.
  bool get isEmpty => _length == 0;

  /// Whether the series has reached [capacity].
  bool get isFull => _length == capacity;

  /// Appends a point, overwriting the oldest when full.
  void add(double x, double y) {
    final int index = (_start + _length) % capacity;
    _xs[index] = x;
    _ys[index] = y;
    if (_length == capacity) {
      _start = (_start + 1) % capacity;
    } else {
      _length++;
    }
  }

  /// The x value at [index], where `0` is the oldest.
  double xAt(int index) {
    assert(index >= 0 && index < _length, 'index out of range');
    return _xs[(_start + index) % capacity];
  }

  /// The y value at [index], where `0` is the oldest.
  double yAt(int index) {
    assert(index >= 0 && index < _length, 'index out of range');
    return _ys[(_start + index) % capacity];
  }

  /// The most recent y value, or null when empty.
  double? get lastY => _length == 0 ? null : yAt(_length - 1);

  /// Copies the series into [outXs] and [outYs] in time order, unwrapping the
  /// ring so a downsample pass can read it contiguously.
  ///
  /// The caller owns both arrays, which is what keeps this allocation-free.
  void linearizeInto(Float64List outXs, Float64List outYs) {
    assert(outXs.length >= _length, 'outXs too small');
    assert(outYs.length >= _length, 'outYs too small');
    final int head = (_start + _length <= capacity) ? _length : capacity - _start;
    for (int i = 0; i < head; i++) {
      outXs[i] = _xs[_start + i];
      outYs[i] = _ys[_start + i];
    }
    for (int i = head; i < _length; i++) {
      outXs[i] = _xs[i - head];
      outYs[i] = _ys[i - head];
    }
  }

  /// The smallest x held, or null when empty.
  double? get minX => _extremeX(least: true);

  /// The largest x held, or null when empty.
  double? get maxX => _extremeX(least: false);

  /// The smallest y held, or null when empty.
  double? get minY => _extremeY(least: true);

  /// The largest y held, or null when empty.
  double? get maxY => _extremeY(least: false);

  double? _extremeX({required bool least}) {
    if (_length == 0) {
      return null;
    }
    double value = xAt(0);
    for (int i = 1; i < _length; i++) {
      final double candidate = xAt(i);
      if (least ? candidate < value : candidate > value) {
        value = candidate;
      }
    }
    return value;
  }

  double? _extremeY({required bool least}) {
    if (_length == 0) {
      return null;
    }
    double value = yAt(0);
    for (int i = 1; i < _length; i++) {
      final double candidate = yAt(i);
      if (least ? candidate < value : candidate > value) {
        value = candidate;
      }
    }
    return value;
  }

  /// Drops every point while keeping the allocation.
  void clear() {
    _start = 0;
    _length = 0;
  }
}
