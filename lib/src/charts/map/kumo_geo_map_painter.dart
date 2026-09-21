import 'package:flutter/widgets.dart';

import '../kumo_chart_colors.dart';
import '../kumo_chart_container.dart';
import 'kumo_geo_projection.dart';
import 'kumo_geojson_parser.dart';

/// Draws a [KumoGeoMapData] as a choropleth.
///
/// One path per feature, compiled once, in world coordinates. The layer's only
/// per-layout work is a matrix and a fill colour per feature — no coordinate
/// arithmetic at all, and nothing is re-projected when the viewport moves.
///
/// The view is `Canvas.transform`, not a re-projection, so pan and zoom are a
/// matrix change over cached geometry. Pan and zoom arrive as widget arguments
/// and therefore as rebuilds, which is cheap here for exactly that reason: a
/// rebuild costs a matrix and a handful of `Paint` colours, not a re-parse.
class KumoGeoMapLayer extends KumoChartLayer {
  /// Creates a map layer.
  KumoGeoMapLayer({
    required super.context,
    required this.data,
    this.projection = const KumoGeoProjection(),
    this.zoom = 1,
    this.focus,
    this.chartColors = const KumoChartColors(),
    this.selectedFeatureId,
    this.borderWidth = 0.75,
    this.selectedBorderWidth = 1.5,
  });

  /// The shapes to draw.
  final KumoGeoMapData data;

  /// The projection the paths were compiled with.
  final KumoGeoProjection projection;

  /// Magnification about [focus]. `1` fits [KumoGeoMapData.bounds] to the plot.
  final double zoom;

  /// The world point held at the plot's centre, or null for the centre of
  /// [KumoGeoMapData.bounds].
  ///
  /// Panning is a change of focus, which is why it costs no geometry work.
  final Offset? focus;

  /// The chart palette.
  final KumoChartColors chartColors;

  /// The feature whose outline is drawn in `textPrimary`.
  final String? selectedFeatureId;

  /// Border width in device pixels, held constant across zoom.
  final double borderWidth;

  /// Selected border width in device pixels.
  final double selectedBorderWidth;

  final Paint _water = Paint();
  final Paint _border = Paint();
  final Paint _selection = Paint();

  late List<Paint> _fills;
  late Rect _plot;
  late Matrix4 _view;

  @override
  void prepare() {
    _plot = context.geometry.plot;
    _view = KumoGeoProjector(
      projection: projection,
      bounds: data.bounds,
    ).computeViewMatrix(
      left: _plot.left,
      top: _plot.top,
      width: _plot.width,
      height: _plot.height,
      zoom: zoom,
      focusX: focus?.dx,
      focusY: focus?.dy,
    );

    // The transform scales the stroke as well as the shape, so a raw 0.75 would
    // thicken as you zoom in. Dividing by the scale keeps a hairline a hairline.
    final double scale = KumoGeoProjector.scaleOf(_view);
    final double hairline = scale <= 0 ? borderWidth : borderWidth / scale;
    final double selected = scale <= 0
        ? selectedBorderWidth
        : selectedBorderWidth / scale;

    _water
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = context.colors.canvas;
    _border
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeWidth = hairline
      ..color = context.colors.border;
    _selection
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeWidth = selected
      ..color = context.colors.textPrimary;

    final List<Color> sequence = KumoChartColors.sequentialFor(
      context.colors.brightness,
    );
    final double min = data.minValue;
    final double max = data.maxValue;

    _fills = List<Paint>.generate(data.features.length, (int i) {
      final double? value = data.features[i].value;
      return Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        // A region with no value is not a region with a low value, so it takes
        // the neutral surface instead of the bottom of the scale.
        ..color = value == null || !value.isFinite
            ? context.colors.subtleSurface
            : sequence[KumoChartColors.sequentialIndex(value, min, max)];
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      return;
    }
    canvas
      ..save()
      ..clipRect(_plot);
    // The unmapped canvas is the water, which is what makes land read as land.
    canvas
      ..drawRect(_plot, _water)
      ..transform(_view.storage);

    final List<KumoGeoFeature> features = data.features;
    for (int i = 0; i < features.length; i++) {
      canvas.drawPath(features[i].path, _fills[i]);
    }
    for (int i = 0; i < features.length; i++) {
      final KumoGeoFeature feature = features[i];
      canvas.drawPath(
        feature.path,
        feature.id == selectedFeatureId ? _selection : _border,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant KumoGeoMapLayer oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      !identical(oldDelegate.data, data) ||
      oldDelegate.zoom != zoom ||
      oldDelegate.focus != focus ||
      oldDelegate.selectedFeatureId != selectedFeatureId ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.selectedBorderWidth != selectedBorderWidth ||
      oldDelegate.projection.kind != projection.kind;
}
