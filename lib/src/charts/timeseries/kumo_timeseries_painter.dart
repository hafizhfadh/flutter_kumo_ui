import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/widgets.dart';

import '../kumo_chart_colors.dart';
import '../kumo_chart_container.dart';
import '../kumo_lttb.dart';
import '../kumo_ring_buffer.dart';
import 'kumo_time_window.dart';

/// Formats a value-axis tick.
typedef KumoAxisLabelBuilder = String Function(double value);

/// Draws the grid and the axis labels.
///
/// Static by construction: it is handed a [KumoChartContext] with no repaint
/// listenable, so a streaming tick cannot repaint it. The grid rasterises once
/// per layout and is reused for every frame in between.
///
/// Grid lines go out through `Canvas.drawRawPoints` against a pre-allocated
/// [Float32List] rather than one `drawLine` per line, because `drawLine` takes
/// [Offset] objects and would allocate two per line per paint.
///
/// The labels come from the [window] as it stood when this layer was built. That
/// is the cost of the zero-repaint guarantee: tick text refreshes when the
/// widget rebuilds, not on every data tick. Rebuilding a time axis at 1Hz is
/// plenty; rebuilding it at 100Hz would defeat the split.
class KumoTimeseriesBackgroundLayer extends KumoChartLayer {
  /// Creates the grid layer.
  KumoTimeseriesBackgroundLayer({
    required super.context,
    required this.window,
    this.valueDivisions = 4,
    this.timeDivisions = 4,
    this.valueLabelBuilder,
    this.timeLabelBuilder,
  });

  /// The window the axis describes.
  final KumoTimeWindow window;

  /// Horizontal grid divisions. Zero draws no value grid.
  final int valueDivisions;

  /// Vertical grid divisions. Zero draws no time grid.
  final int timeDivisions;

  /// Formats a value tick. Defaults to a compact fixed-point form.
  final KumoAxisLabelBuilder? valueLabelBuilder;

  /// Formats a time tick.
  final KumoAxisLabelBuilder? timeLabelBuilder;

  final Paint _gridPaint = Paint();
  late Float32List _gridPoints;
  late TextPainter _label;

  @override
  void prepare() {
    _gridPaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = context.colors.border;
    // Two floats per coordinate, two coordinates per line: four per line.
    _gridPoints = Float32List((valueDivisions + timeDivisions + 2) * 4);
    // One TextPainter, reused for every label. Its TextSpan is rebuilt per
    // paint, which is affordable precisely because this layer paints on layout
    // rather than on every tick.
    _label = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect plot = context.geometry.plot;
    int slot = 0;

    for (int i = 0; i <= valueDivisions; i++) {
      final double y = plot.bottom - (i / valueDivisions) * plot.height;
      _gridPoints[slot++] = plot.left;
      _gridPoints[slot++] = y;
      _gridPoints[slot++] = plot.right;
      _gridPoints[slot++] = y;
    }
    for (int i = 0; i <= timeDivisions; i++) {
      final double x = plot.left + (i / timeDivisions) * plot.width;
      _gridPoints[slot++] = x;
      _gridPoints[slot++] = plot.top;
      _gridPoints[slot++] = x;
      _gridPoints[slot++] = plot.bottom;
    }

    canvas.drawRawPoints(
      PointMode.lines,
      Float32List.sublistView(_gridPoints, 0, slot),
      _gridPaint,
    );

    final TextStyle style = context.styles.caption.copyWith(
      color: context.colors.textMuted,
    );
    for (int i = 0; i <= valueDivisions; i++) {
      final double t = i / valueDivisions;
      final double value = window.minY + t * window.valueSpan;
      _paintLabel(
        canvas,
        (valueLabelBuilder ?? _defaultValueLabel)(value),
        style,
        Offset(plot.left, plot.bottom - t * plot.height - 14),
      );
    }
    for (int i = 0; i <= timeDivisions; i++) {
      final double t = i / timeDivisions;
      final double timestamp = window.minTimestamp + t * window.timeSpan;
      _paintLabel(
        canvas,
        (timeLabelBuilder ?? _defaultTimeLabel)(timestamp),
        style,
        Offset(plot.left + t * plot.width + 4, plot.bottom + 6),
      );
    }
  }

  void _paintLabel(Canvas canvas, String text, TextStyle style, Offset at) {
    _label
      ..text = TextSpan(text: text, style: style)
      ..layout();
    _label.paint(canvas, at);
  }

  static String _defaultValueLabel(double value) {
    final double magnitude = value.abs();
    if (magnitude >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (magnitude >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    if (magnitude >= 10) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(magnitude == 0 ? 0 : 1);
  }

  static String _defaultTimeLabel(double timestamp) {
    // Timestamps are caller-defined, so this stays a plain number rather than
    // assuming a unit or a calendar.
    final double magnitude = timestamp.abs();
    if (magnitude >= 1000000) {
      return '${(timestamp / 1000000).toStringAsFixed(1)}M';
    }
    if (magnitude >= 1000) {
      return '${(timestamp / 1000).toStringAsFixed(1)}k';
    }
    return timestamp.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant KumoTimeseriesBackgroundLayer oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      oldDelegate.window.minTimestamp != window.minTimestamp ||
      oldDelegate.window.maxTimestamp != window.maxTimestamp ||
      oldDelegate.window.minY != window.minY ||
      oldDelegate.window.maxY != window.maxY ||
      oldDelegate.valueDivisions != valueDivisions ||
      oldDelegate.timeDivisions != timeDivisions;
}

/// Draws the series.
///
/// Every object the paint pass touches is allocated in [prepare], which runs
/// once per layout: the scratch arrays, the downsample output, the projected
/// pixels, the two [Path]s, the two [Paint]s and the area shader. `paint` only
/// resets and mutates them, so a streaming frame allocates nothing.
///
/// The pipeline per paint is linearize, downsample, project, path. Downsampling
/// first matters because a 400px plot cannot show 50,000 points and the ones it
/// cannot show still cost raster time.
class KumoTimeseriesForegroundLayer extends KumoChartLayer {
  /// Creates the series layer.
  KumoTimeseriesForegroundLayer({
    required super.context,
    required this.series,
    required this.window,
    this.maxPoints = 480,
    this.lineColor,
    this.showArea = false,
    this.lineWidth = 2,
    this.chartColors = const KumoChartColors(),
  });

  /// The data to draw.
  final KumoSeriesBuffer series;

  /// The viewport the data is drawn through.
  final KumoTimeWindow window;

  /// Upper bound on points handed to the rasteriser. This is the LTTB
  /// threshold, and it should be in the order of the plot's pixel width.
  final int maxPoints;

  /// Line colour. Defaults to the first categorical slot.
  final Color? lineColor;

  /// Whether to fill under the line with a fading gradient.
  final bool showArea;

  /// Stroke width of the line.
  final double lineWidth;

  /// The chart palette.
  final KumoChartColors chartColors;

  // Allocated in prepare(), never in paint().
  late Float64List _linearX;
  late Float64List _linearY;
  late Float64List _downX;
  late Float64List _downY;
  late Float64List _pixelX;
  late Float64List _pixelY;
  late KumoSeriesBuffer _downsampled;
  final Path _line = Path();
  final Path _area = Path();
  final Paint _stroke = Paint();
  final Paint _areaFill = Paint();

  /// Points handed to the rasteriser on the last paint, after downsampling.
  ///
  /// Diagnostics rather than state: it is the cheapest way to see that LTTB ran,
  /// and it is what the downsample test asserts on.
  int get lastRenderedPoints => _lastRenderedPoints;
  int _lastRenderedPoints = 0;

  int _cachedLength = -1;
  double _cachedMinTimestamp = 0;
  double _cachedMinY = 0;
  double _cachedMaxY = 0;
  Rect _cachedPlot = Rect.zero;
  bool _hasPath = false;

  @override
  void prepare() {
    final int capacity = series.capacity;
    _linearX = Float64List(capacity);
    _linearY = Float64List(capacity);
    _downX = Float64List(maxPoints);
    _downY = Float64List(maxPoints);
    _pixelX = Float64List(maxPoints);
    _pixelY = Float64List(maxPoints);
    _downsampled = KumoSeriesBuffer(capacity: maxPoints);

    _stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final Color color = lineColor ?? chartColors.categoricalAt(0);
    _stroke.color = color;
    _areaFill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      // Fades to fully transparent at the baseline, so stacked areas read as
      // depth rather than as a wall of colour. The shader depends on the plot
      // rect, so a resize rebuilds it here rather than in paint.
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          color.withValues(alpha: 0.20),
          color.withValues(alpha: 0),
        ],
      ).createShader(context.geometry.plot);

    _hasPath = false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final int length = series.length;
    final Rect plot = context.geometry.plot;
    if (!_hasPath || length < 2 || plot.isEmpty) {
      _buildPath(plot, length);
      if (!_hasPath) {
        return;
      }
    } else if (_canTranslate(length, plot)) {
      // The window slid and nothing else changed, so the cached path is still
      // correct: translating it is cheaper than reprojecting history.
      final double pixelsPerUnit = plot.width / window.timeSpan;
      canvas
        ..save()
        ..translate(
          -(window.minTimestamp - _cachedMinTimestamp) * pixelsPerUnit,
          0,
        )
        ..clipRect(plot);
      _drawPaths(canvas, plot);
      canvas.restore();
      _cachedMinTimestamp = window.minTimestamp;
      return;
    } else {
      _buildPath(plot, length);
      if (!_hasPath) {
        return;
      }
    }

    canvas
      ..save()
      ..clipRect(plot);
    _drawPaths(canvas, plot);
    canvas.restore();
  }

  bool _canTranslate(int length, Rect plot) {
    return length == _cachedLength &&
        plot == _cachedPlot &&
        window.minY == _cachedMinY &&
        window.maxY == _cachedMaxY &&
        window.hasTimeSpan;
  }

  void _drawPaths(Canvas canvas, Rect plot) {
    if (showArea) {
      canvas.drawPath(_area, _areaFill);
    }
    canvas.drawPath(_line, _stroke);
  }

  void _buildPath(Rect plot, int length) {
    _hasPath = false;
    if (length < 2 || plot.isEmpty) {
      return;
    }

    series.linearizeInto(_linearX, _linearY);
    final int count = KumoLttb.downsample(
      xs: _linearX,
      ys: _linearY,
      length: length,
      threshold: maxPoints,
      outXs: _downX,
      outYs: _downY,
    );
    _downsampled.clear();
    for (int i = 0; i < count; i++) {
      _downsampled.add(_downX[i], _downY[i]);
    }
    final int pixels = window.projectSeries(
      _downsampled,
      _pixelX,
      _pixelY,
      plot,
    );
    if (pixels < 2) {
      return;
    }
    _lastRenderedPoints = pixels;

    _line.reset();
    _area.reset();
    _line.moveTo(_pixelX[0], _pixelY[0]);
    for (int i = 1; i < pixels; i++) {
      _line.lineTo(_pixelX[i], _pixelY[i]);
    }
    if (showArea) {
      _area.addPath(_line, Offset.zero);
      _area
        ..lineTo(_pixelX[pixels - 1], plot.bottom)
        ..lineTo(_pixelX[0], plot.bottom)
        ..close();
    }

    _hasPath = true;
    _cachedLength = length;
    _cachedMinTimestamp = window.minTimestamp;
    _cachedMinY = window.minY;
    _cachedMaxY = window.maxY;
    _cachedPlot = plot;
  }

  @override
  bool shouldRepaint(covariant KumoTimeseriesForegroundLayer oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      !identical(oldDelegate.series, series) ||
      oldDelegate.maxPoints != maxPoints ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.showArea != showArea ||
      oldDelegate.lineWidth != lineWidth;
}
