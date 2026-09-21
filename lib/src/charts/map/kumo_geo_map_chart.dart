import 'package:flutter/widgets.dart';

import '../kumo_chart_colors.dart';
import '../kumo_chart_container.dart';
import 'kumo_geo_map_painter.dart';
import 'kumo_geo_projection.dart';
import 'kumo_geojson_parser.dart';

/// A choropleth map.
///
/// ```dart
/// KumoGeoMapChart(
///   data: KumoGeoMapData.parse(
///     jsonDecode(body) as Map<String, Object?>,
///   ),
///   zoom: 1.5,
/// )
/// ```
///
/// Shapes are compiled once into world-space paths, so a resize, a pan and a
/// zoom all reuse them; the viewport is a `Matrix4` applied at paint time.
///
/// The map takes the container's *foreground* slot only because the container
/// requires one, and it is handed no repaint listenable. So it still rasterises
/// exactly once per layout: nothing ticks a map, and only a rebuild moves it.
///
/// Pan and zoom are widget arguments, so they drive a rebuild. That is the
/// intended path rather than a compromise — the rebuild recomputes one matrix
/// and a few `Paint` colours, and touches no coordinates.
class KumoGeoMapChart extends StatelessWidget {
  /// Creates a map chart.
  const KumoGeoMapChart({
    super.key,
    required this.data,
    this.zoom = 1,
    this.focus,
    this.height = 320,
    this.projection = const KumoGeoProjection(),
    this.chartColors = const KumoChartColors(),
    this.selectedFeatureId,
    this.borderWidth = 0.75,
    this.selectedBorderWidth = 1.5,
    this.showSurface = true,
    this.insets = EdgeInsets.zero,
    this.overlay,
  });

  /// The parsed map to draw.
  final KumoGeoMapData data;

  /// Magnification about [focus]. `1` fits the data's bounds to the plot.
  final double zoom;

  /// The world point held at the plot's centre, or null for the centre of
  /// [KumoGeoMapData.bounds].
  ///
  /// Use a feature's [KumoGeoFeature.bounds] centre to zoom to a region.
  final Offset? focus;

  /// Height of the surface. Width comes from the parent.
  final double height;

  /// The projection the data was parsed with. Kept in step by the caller, and
  /// used to fit the bounds.
  final KumoGeoProjection projection;

  /// The chart palette.
  final KumoChartColors chartColors;

  /// The feature outlined in `textPrimary`, normally the one under the cursor.
  final String? selectedFeatureId;

  /// Border width in device pixels, held constant across zoom.
  final double borderWidth;

  /// Selected border width in device pixels.
  final double selectedBorderWidth;

  /// Whether to paint the surface fill, outline and radius. Turn off to drop a
  /// map into a card that already provides them.
  final bool showSurface;

  /// Room reserved inside the surface. Zero by default: a map has no axes.
  final EdgeInsets insets;

  /// Interaction chrome drawn above the map, such as a legend or a readout.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return KumoChartContainer(
      height: height,
      insets: insets,
      showSurface: showSurface,
      overlay: overlay,
      foreground: (KumoChartContext chartContext) => KumoGeoMapLayer(
        context: chartContext,
        data: data,
        projection: projection,
        zoom: zoom,
        focus: focus,
        chartColors: chartColors,
        selectedFeatureId: selectedFeatureId,
        borderWidth: borderWidth,
        selectedBorderWidth: selectedBorderWidth,
      ),
    );
  }
}
