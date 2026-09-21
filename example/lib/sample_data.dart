import 'dart:math' as math;

import 'package:kumo_ui/kumo_ui.dart';

/// The sample choropleth, parsed once for the process's lifetime.
///
/// Parsing compiles every ring into a world-space [Path], and that work does not
/// depend on the viewport, so the result is held rather than rebuilt: a zoom, a
/// pan and a resize all reuse these paths and change only the matrix.
final KumoGeoMapData sampleChoropleth = const KumoGeoJsonParser().parse(
  _choroplethFeatureCollection(),
);

/// One flow network the Sankey route can show.
class SampleFlow {
  /// Creates a named flow network.
  const SampleFlow({
    required this.name,
    required this.summary,
    required this.graph,
  });

  /// Label shown in the picker.
  final String name;

  /// One line describing what the flows are.
  final String summary;

  /// The graph itself.
  final KumoSankeyGraph graph;
}

/// The flow networks the Sankey route switches between.
const List<SampleFlow> sampleFlows = <SampleFlow>[
  SampleFlow(
    name: 'Edge traffic',
    summary: 'Requests through the edge, split by what served them.',
    graph: KumoSankeyGraph(
      nodes: <KumoSankeyNode>[
        KumoSankeyNode(id: 'client', label: 'Client'),
        KumoSankeyNode(id: 'edge', label: 'Edge'),
        KumoSankeyNode(id: 'cache', label: 'Cache'),
        KumoSankeyNode(id: 'worker', label: 'Worker'),
        KumoSankeyNode(id: 'origin', label: 'Origin'),
        KumoSankeyNode(id: 'db', label: 'Database'),
        KumoSankeyNode(id: 'store', label: 'Object store'),
      ],
      links: <KumoSankeyLink>[
        KumoSankeyLink(source: 'client', target: 'edge', value: 100),
        KumoSankeyLink(source: 'edge', target: 'cache', value: 55),
        KumoSankeyLink(source: 'edge', target: 'worker', value: 45),
        KumoSankeyLink(source: 'cache', target: 'origin', value: 33),
        KumoSankeyLink(source: 'worker', target: 'origin', value: 45),
        KumoSankeyLink(source: 'origin', target: 'db', value: 48),
        KumoSankeyLink(source: 'origin', target: 'store', value: 30),
      ],
    ),
  ),
  SampleFlow(
    name: 'Origin offload',
    summary: 'The same edge with more work pushed into the Worker.',
    graph: KumoSankeyGraph(
      nodes: <KumoSankeyNode>[
        KumoSankeyNode(id: 'client', label: 'Client'),
        KumoSankeyNode(id: 'edge', label: 'Edge'),
        KumoSankeyNode(id: 'cache', label: 'Cache'),
        KumoSankeyNode(id: 'worker', label: 'Worker'),
        KumoSankeyNode(id: 'origin', label: 'Origin'),
        KumoSankeyNode(id: 'db', label: 'Database'),
        KumoSankeyNode(id: 'store', label: 'Object store'),
      ],
      links: <KumoSankeyLink>[
        KumoSankeyLink(source: 'client', target: 'edge', value: 100),
        KumoSankeyLink(source: 'edge', target: 'cache', value: 38),
        KumoSankeyLink(source: 'edge', target: 'worker', value: 62),
        KumoSankeyLink(source: 'cache', target: 'origin', value: 22),
        KumoSankeyLink(source: 'worker', target: 'origin', value: 28),
        KumoSankeyLink(source: 'origin', target: 'db', value: 26),
        KumoSankeyLink(source: 'origin', target: 'store', value: 24),
        KumoSankeyLink(source: 'worker', target: 'store', value: 34),
      ],
    ),
  ),
];

/// Builds a synthetic choropleth: a honeycomb of hexagonal regions over a
/// plausible continental box, each carrying a magnitude.
///
/// Synthetic on purpose. The point of the route is the vector path pipeline, and
/// a honeycomb makes it obvious that the map is drawing real polygons rather
/// than a picture of one — while keeping the example free of a data dependency.
Map<String, Object?> _choroplethFeatureCollection() {
  const double west = -122;
  const double east = -70;
  const double south = 26;
  const double north = 49;
  const int columns = 7;
  const int rows = 4;

  final double cellWidth = (east - west) / columns;
  final double cellHeight = (north - south) / rows;
  final double radiusX = cellWidth / 2;
  final double radiusY = cellHeight / 2;

  final List<Map<String, Object?>> features = <Map<String, Object?>>[];
  for (int row = 0; row < rows; row++) {
    // Alternate rows are offset by half a cell, which is what turns a grid of
    // boxes into a honeycomb.
    final double rowOffset = row.isOdd ? 0.5 : 0;
    for (int column = 0; column < columns; column++) {
      final double centerX = west + (column + 0.5 + rowOffset) * cellWidth;
      if (centerX + radiusX > east) {
        continue;
      }
      final double centerY = south + (row + 0.5) * cellHeight;
      final String id = 'sector-${row + 1}${String.fromCharCode(97 + column)}';
      final double value = 60 + 30 * math.sin(centerX / 18) + 26 * math.cos(centerY / 7);

      features.add(<String, Object?>{
        'type': 'Feature',
        'id': id,
        'properties': <String, Object?>{
          'name': 'Sector ${row + 1}${String.fromCharCode(65 + column)}',
          'value': double.parse(value.toStringAsFixed(1)),
        },
        'geometry': <String, Object?>{
          'type': 'Polygon',
          'coordinates': <Object?>[
            _hexRing(centerX, centerY, radiusX, radiusY),
          ],
        },
      });
    }
  }

  return <String, Object?>{
    'type': 'FeatureCollection',
    'features': features,
  };
}

/// A six-sided ring around `(centerX, centerY)`, closed the way GeoJSON closes
/// one by repeating its first position.
List<List<double>> _hexRing(
  double centerX,
  double centerY,
  double radiusX,
  double radiusY,
) {
  final List<List<double>> ring = <List<double>>[];
  for (int i = 0; i < 6; i++) {
    final double angle = math.pi / 3 * i + math.pi / 6;
    ring.add(<double>[
      centerX + radiusX * math.cos(angle),
      centerY + radiusY * math.sin(angle),
    ]);
  }
  ring.add(<double>[ring.first[0], ring.first[1]]);
  return ring;
}
