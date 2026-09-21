import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../page_parts.dart';
import '../sample_data.dart';

/// The vector choropleth route.
///
/// The map is parsed once and held: every control below moves the viewport, and
/// a viewport is one `Matrix4` over paths that never change.
class KumoExampleGeoMap extends StatefulWidget {
  /// Creates the map screen.
  const KumoExampleGeoMap({super.key});

  @override
  State<KumoExampleGeoMap> createState() => _KumoExampleGeoMapState();
}

class _KumoExampleGeoMapState extends State<KumoExampleGeoMap> {
  /// Zoom used when the view is fitted to a single region.
  static const double _regionZoom = 6;

  final KumoGeoMapData _data = sampleChoropleth;

  /// Viewport. `1` fits every region to the plot, which is where the route
  /// opens: a choropleth zoomed onto one cell on arrival is a blank-looking
  /// screen, and the whole point of the map is the distribution.
  double _zoom = 1;
  Offset? _focus;
  String? _selected;

  KumoGeoFeature? get _selectedFeature {
    final String? selected = _selected;
    if (selected == null) {
      return null;
    }
    for (final KumoGeoFeature feature in _data.features) {
      if (feature.id == selected) {
        return feature;
      }
    }
    return null;
  }

  /// Moves the viewport. Picking a region zooms to it; `all` fits every region.
  ///
  /// Both are widget arguments rather than painter state, so each one is a
  /// rebuild that recomputes one matrix — no path is re-parsed or re-projected.
  void _selectRegion(String id) {
    setState(() {
      if (id == 'all') {
        _selected = null;
        _focus = null;
        _zoom = 1;
        return;
      }
      _selected = id;
      for (final KumoGeoFeature feature in _data.features) {
        if (feature.id == id) {
          _focus = Offset(feature.bounds.centerX, feature.bounds.centerY);
          _zoom = _regionZoom;
          return;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final KumoColors colors = KumoTheme.of(context);
    final KumoTextStyles styles = KumoTheme.textStylesOf(context);
    final KumoGeoFeature? selected = _selectedFeature;
    final List<Color> steps = KumoChartColors.sequentialFor(colors.brightness);

    return KumoScaffold(
      header: const ExamplePageHeader(
        title: 'Traffic by region',
        subtitle: '/charts/geomap',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // A choropleth needs a key: colour alone is not a signal.
          Row(
            children: <Widget>[
              Text('${_data.minValue.toStringAsFixed(0)} req/s', style: styles.caption),
              const SizedBox(width: 8),
              for (final Color step in steps)
                Container(
                  width: 24,
                  height: 10,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: step,
                    border: Border.all(color: colors.border),
                  ),
                ),
              const SizedBox(width: 8),
              Text('${_data.maxValue.toStringAsFixed(0)} req/s', style: styles.caption),
            ],
          ),
          const SizedBox(height: 16),
          KumoGeoMapChart(
            data: _data,
            zoom: _zoom,
            focus: _focus,
            selectedFeatureId: _selected,
            height: 360,
          ),
          const SizedBox(height: 20),
          const ExampleSectionLabel('Region'),
          KumoSelect<String>(
            value: _selected ?? 'all',
            label: 'Zoom to',
            options: <String, String>{
              'all': 'All regions',
              for (final KumoGeoFeature feature in _data.features)
                feature.id:
                    '${feature.name ?? feature.id} · '
                    '${feature.value?.toStringAsFixed(0) ?? '--'} req/s',
            },
            onChanged: _selectRegion,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              KumoButton(
                label: 'Zoom in',
                variant: KumoButtonVariant.secondary,
                icon: PhosphorIconsRegular.arrowsOut,
                onPressed: () => setState(() => _zoom = (_zoom * 1.5).clamp(1, 40)),
              ),
              KumoButton(
                label: 'Zoom out',
                variant: KumoButtonVariant.secondary,
                icon: PhosphorIconsRegular.arrowsIn,
                onPressed: () => setState(() => _zoom = (_zoom / 1.5).clamp(1, 40)),
              ),
              KumoButton(
                label: 'Reset view',
                variant: KumoButtonVariant.secondary,
                icon: PhosphorIconsRegular.arrowsClockwise,
                onPressed: () => _selectRegion('all'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const ExampleSectionLabel('Selection'),
          if (selected == null)
            Text('Showing the whole map.', style: styles.bodyMuted)
          else
            Text(
              '${selected.name ?? selected.id} · '
              '${selected.value?.toStringAsFixed(1) ?? '--'} req/s · '
              '${_data.features.length} regions parsed',
              style: styles.bodyMuted,
            ),
          const SizedBox(height: 10),
          Text(
            'Panning and zooming change the matrix, never the geometry: the '
            'paths were compiled once when the map was parsed.',
            style: styles.caption,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
