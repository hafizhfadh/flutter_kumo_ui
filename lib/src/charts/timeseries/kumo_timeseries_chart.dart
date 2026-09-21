import 'package:flutter/widgets.dart';

import '../kumo_chart_colors.dart';
import '../kumo_chart_container.dart';
import '../kumo_ring_buffer.dart';
import 'kumo_time_window.dart';
import 'kumo_timeseries_painter.dart';

/// A streaming timeseries chart.
///
/// Assembles the three pieces: [KumoSeriesBuffer] holds the points,
/// [KumoTimeWindow] decides which slice is visible, and [KumoChartContainer]
/// splits the grid from the series so a data tick repaints only the series.
///
/// ```dart
/// final series = KumoSeriesBuffer(capacity: 4096);
/// final window = KumoTimeWindow.last(const Duration(minutes: 5), endTimestamp: 0);
/// final controller = KumoChartController<KumoSeriesPoint>(capacity: 4096);
///
/// KumoTimeseriesChart(series: series, window: window, repaint: controller)
/// ```
///
/// A tick through [repaint] repaints the line without rebuilding this widget and
/// without touching the grid. That is why the axis labels come from the [window]
/// as it stood when the widget last rebuilt: refreshing tick text per frame
/// would mean rebuilding `TextSpan`s in a paint pass. Rebuild at whatever rate
/// a readable time axis needs — about once a second — and let the line stream.
class KumoTimeseriesChart extends StatelessWidget {
  /// Creates a timeseries chart.
  const KumoTimeseriesChart({
    super.key,
    required this.series,
    required this.window,
    this.repaint,
    this.height = 220,
    this.maxPoints = 480,
    this.lineColor,
    this.showArea = true,
    this.valueDivisions = 4,
    this.timeDivisions = 4,
    this.valueLabelBuilder,
    this.timeLabelBuilder,
    this.chartColors = const KumoChartColors(),
    this.insets = const EdgeInsets.fromLTRB(12, 12, 12, 28),
  });

  /// The points to draw.
  final KumoSeriesBuffer series;

  /// The visible window.
  final KumoTimeWindow window;

  /// Notified on every data tick. Normally a `KumoChartController`.
  final Listenable? repaint;

  /// Height of the chart. Width comes from the parent.
  final double height;

  /// LTTB threshold, in points. Keep it near the plot's pixel width.
  final int maxPoints;

  /// Line colour. Defaults to the first categorical slot.
  final Color? lineColor;

  /// Whether to fill under the line.
  final bool showArea;

  /// Horizontal grid divisions.
  final int valueDivisions;

  /// Vertical grid divisions.
  final int timeDivisions;

  /// Formats a value tick.
  final KumoAxisLabelBuilder? valueLabelBuilder;

  /// Formats a time tick.
  final KumoAxisLabelBuilder? timeLabelBuilder;

  /// The chart palette.
  final KumoChartColors chartColors;

  /// Room reserved for the axes.
  final EdgeInsets insets;

  @override
  Widget build(BuildContext context) {
    return KumoChartContainer(
      height: height,
      insets: insets,
      repaint: repaint,
      background: (KumoChartContext context) => KumoTimeseriesBackgroundLayer(
        context: context,
        window: window,
        valueDivisions: valueDivisions,
        timeDivisions: timeDivisions,
        valueLabelBuilder: valueLabelBuilder,
        timeLabelBuilder: timeLabelBuilder,
      ),
      foreground: (KumoChartContext context) => KumoTimeseriesForegroundLayer(
        context: context,
        series: series,
        window: window,
        maxPoints: maxPoints,
        lineColor: lineColor,
        showArea: showArea,
        chartColors: chartColors,
      ),
    );
  }
}
