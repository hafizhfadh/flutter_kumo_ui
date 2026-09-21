# Charts

`kumo_ui` ships a chart subsystem that is pure Dart and Flutter-native: no
`dart:ui` raster tricks, no external chart package, and no `CustomPaint` body that
allocates on a frame. Everything lives under `lib/src/charts/` and is exported
from the barrel.

Read this file before writing a chart. The subsystem has one rule that is easy to
break by accident and expensive to debug, so it comes first.

| Family | Widget | Use for |
| --- | --- | --- |
| Timeseries | `KumoTimeseriesChart` | streaming line and area over a sliding window |
| Sankey | `KumoSankeyChart` | flow between stages |
| Geo | `KumoGeoMapChart` | choropleth from GeoJSON |
| Custom | `KumoCanvas` | a bespoke visualiser drawn on a raw `Canvas` |
| Bespoke layers | `KumoChartContainer` + `KumoChartLayer` | a chart assembled from layers you write |

## The rule: a paint body allocates nothing

`KumoChartLayer` extends `CustomPainter`, and its contract is:

- **`prepare()`** runs once per layout, outside the paint pass. Every `Paint`,
  `Path`, `TextPainter`, `RRect`, `Rect` and `Offset` is built here.
- **`paint()`** only mutates and draws. No `Paint()`, no `Path()`, no
  `TextSpan()`, not even an `Offset` built for a `paint` call — compute those in
  `prepare` too.

A chart that violates this still looks right in a screenshot and then drops
frames the moment data streams at 60Hz. If you cannot express something without
allocating, put a widget there instead of a painter.

### The repaint split

`KumoChartContainer` takes a `background` and a `foreground` layer:

```dart
KumoChartContainer(
  repaint: controller,
  background: (context) => KumoGridLayer(context: context),
  foreground: (context) => KumoLineLayer(context: context, series: series),
)
```

The background is handed a context whose `repaint` is **null** and sits behind its
own `RepaintBoundary`, so a grid, its axis lines and its tick labels rasterise
once per layout. The foreground is handed `context.withRepaint(repaint)` and
repaints on every tick. The widget tree is not rebuilt for a tick at all —
`CustomPainter.repaint` drives it.

Consequence worth knowing: because a tick does not rebuild, a foreground layer
cannot refresh text per tick. Axis labels come from the widget's last build.
Rebuild a streaming chart about once a second for the time axis and let the line
stream.

The container requires a `foreground`. A chart whose only layer is static passes
it there with no `repaint` listenable: nothing ticks it, so it still rasterises
once per layout.

## Colour

`KumoChartColors` is the chart palette, ported from Kumo's chart tokens. It is
scheme-independent (the same slots in light and dark), which is why it is not
threaded through `KumoColors`.

```dart
const KumoChartColors palette = KumoChartColors();

palette.attention;  // #FC574A  polarity: needs attention
palette.warning;    // #F8A054
palette.success;    // #00A63E
palette.neutral;    // #B9D6FF

palette.categoricalAt(3);  // #8D58EE, cycles with `i % 5`
palette.sequentialAt(1);   // #8EBCF6, 0 is lightest
```

Three systems, three decisions:

- **Semantic** (`attention`, `warning`, `success`) for data that already has
  polarity — pass/fail, healthy/degraded.
- **Categorical** (`categoricalAt`) for nominal series with no order. Ordered for
  perceptual distance between adjacent slots and tested against a colour vision
  deficiency simulator upstream, so do not improvise a palette.
- **Sequential** for one metric varying in magnitude, such as a choropleth:

```dart
final List<Color> steps = KumoChartColors.sequentialFor(brightness);
final int step = KumoChartColors.sequentialIndex(value, data.minValue, data.maxValue);
final Color fill = steps[step];
```

`sequentialFor` reverses the scale in dark mode, because upstream darkens with
magnitude in light mode and lightens in dark mode: the most prominent step is
always the largest value. `sequentialIndex` picks a step by **where the value sits
on the scale**. Never index the list with a loop counter — that cycles the palette
and makes the fourth region look like the largest one.

Colour is never the only signal. When two series share a chart, differ them with a
dash or dot pattern as well.

## Timeseries

```dart
final KumoSeriesBuffer series = KumoSeriesBuffer(capacity: 4096);
final KumoTimeWindow window = KumoTimeWindow.last(
  const Duration(minutes: 5),
  endTimestamp: now,
);
final KumoChartController<double> controller = KumoChartController<double>(
  capacity: 4096,
);

// on each sample:
series.add(timestamp, value);
controller.append(timestamp);      // schedules a frame; coalesced per frame

KumoTimeseriesChart(series: series, window: window, repaint: controller);
```

- `KumoSeriesBuffer.add` never allocates: storage is two `Float64List`s read
  through a start offset, so a wrap does not copy.
- `KumoTimeWindow.last(duration, endTimestamp:)` fixes the viewport. The duration
  is a viewport, not a stride: it does not change as points arrive, which is what
  lets the window slide. `slideTo` / `slideBy` move it.
- `window.fitY(series, fromTimestamp:, toTimestamp:)` derives the value domain
  from the data, scanning only the slice worth fitting. Headroom (`yPadding`) and
  `includeZero` are set on the `KumoTimeWindow` itself, since they are properties
  of the viewport rather than of one fit.
- `KumoLttb.downsample(...)` runs inside the painter, and `maxPoints` (default
  480) is its threshold. Keep it near the plot's pixel width: LTTB keeps the
  extremes that carry the shape, but 50,000 points still cost raster time.
- `maxPoints`, `lineColor`, `showArea`, `valueDivisions`, `timeDivisions` and the
  label builders are on `KumoTimeseriesChart`.

## Sankey

```dart
KumoSankeyChart(
  graph: KumoSankeyGraph(
    nodes: <KumoSankeyNode>[
      KumoSankeyNode(id: 'edge', label: 'Edge'),
      KumoSankeyNode(id: 'cache', label: 'Cache'),
    ],
    links: <KumoSankeyLink>[
      KumoSankeyLink(source: 'edge', target: 'cache', value: 62),
    ],
  ),
  height: 320,
)
```

`KumoSankeySolver` is the layout engine and is usable on its own — it imports no
Flutter, only `dart:typed_data` and `dart:ui` for `Color`, so it can be tested
without a widget harness.

- Columns come from longest-path depth via Kahn's algorithm. Input node order does
  not affect the result.
- **Cycles are safe.** Kahn's queue drains even when no node has in-degree zero,
  so the solver cannot hang. Cycle members are then swept breadth-first from the
  settled frontier: a cycle hanging off the acyclic part gets real depths, and a
  cycle with no entry point stays in column zero.
- One scale for every column, sized so the busiest column fits with its padding.
  Overlap is impossible rather than merely unlikely, with no relaxation pass.
- Bands are ordered by the other endpoint's position, which is what keeps ribbons
  from crossing.
- `layout()` writes into caller-owned `KumoSankeyNodeLayout` /
  `KumoSankeyLinkLayout` structs. A resize reuses them.

Ribbons are filled closed paths, not strokes: a stroke has one width along its
whole length, and a ribbon has to be as thick as its flow at both ends.

## Geo maps

```dart
final KumoGeoMapData data = const KumoGeoJsonParser().parse(
  jsonDecode(body) as Map<String, Object?>,
);   // parse once, keep it

KumoGeoMapChart(
  data: data,
  zoom: 1.5,
  focus: Offset(data.features.first.bounds.centerX, data.features.first.bounds.centerY),
)
```

Three pieces, in order of dependency:

1. **`KumoGeoProjection`** maps longitude and latitude into a unit square —
   `KumoGeoProjectionKind.mercator` (default) or `.equirectangular`. Pure math:
   `dart:math`, `dart:typed_data`, `vector_math`, nothing else. `worldX` clamps
   longitude rather than wrapping, because wrapping is right per point and ruins
   per shape; a polygon crossing the antimeridian must be split into two features
   first.
2. **`KumoGeoJsonParser`** reads an already-decoded `Map` into
   `KumoGeoMapData` — features, their union `bounds`, and the magnitude domain.
   `Polygon` and `MultiPolygon` only; points, lines and geometry collections are
   skipped rather than thrown on. Rings are forced to `PathFillType.evenOdd`, so
   a hole is a hole whichever way its ring winds.
3. **`KumoGeoMapChart`** draws it. Paths are compiled once in **world**
   coordinates, so a resize, a pan and a zoom reuse them: the viewport is a
   `Matrix4` applied with `Canvas.transform`, and no coordinate is re-projected.
   `KumoGeoProjector.computeViewMatrix` fits the bounds aspect-correct (the
   smaller axis constrains), so a country never changes shape with the box it was
   dropped into. Border widths are divided by the matrix scale, which keeps a
   hairline a hairline at any zoom.

Pass the **same** `KumoGeoMapData` instance to `KumoGeoMapChart` on every build.
That is the whole reason parsing is separate from drawing. Zoom, pan and
selection are widget arguments and therefore rebuilds — cheap, because a rebuild
recomputes one matrix and a few `Paint` colours.

Unmapped canvas is filled with `colors.canvas` (the water), land with
`sequentialFor(brightness)` by magnitude, and borders with `colors.border`. A
feature with no value gets `colors.subtleSurface`, not the bottom of the scale: a
region with no value is not a region with a low value.

## Custom canvases

`KumoCanvas` is the escape hatch for a visualiser the three families do not
cover, without surrendering the scaffolding around it:

```dart
KumoCanvas(
  repaint: controller,                       // a KumoChartController, for ticks
  painter: (Canvas canvas, Size size, KumoChartContext context) {
    final Rect plot = context.geometry.plot; // the data area, after insets
    canvas.drawPath(_path, _paint);
  },
)
```

The chart still owns the surface fill and outline, the plot rect, the gridlines
and axis ticks (`showGrid`, `gridDivisions`), the resolved tokens on
`context.colors` and `context.styles`, and the repaint split — `repaint` re-runs
the callback without rebuilding the widget tree. There is no `background`
parameter, because the managed grid *is* the background; `KumoCanvasGridLayer` is
the layer it places there, exported if you want it on its own.

The callback inherits the paint discipline. Declare `Paint`, `Path` and
`TextPainter` outside it — as fields on a `State`, or above the `build` that
returns the `KumoCanvas` — and only mutate them inside. Read tokens from
`context`, and size geometry against `context.geometry.plot` rather than `size`,
which includes the room reserved for axes.

## Bespoke charts

For anything the three families do not cover, build layers against
`KumoChartContainer` directly. `KumoChartGeometry.plot` is the data area after
`insets`; `KumoChartContext.colors` and `.styles` are the resolved tokens, so a
`paint` body never calls `KumoTheme.of(context)`.

Available building blocks:

- `KumoRingBuffer<T>`, `KumoSeriesBuffer`, `KumoDataBuffer<T>`,
  `KumoChartController<T>`, `KumoStreamingChartSource<T>`
- `KumoLttb.downsample` — caller-owned arrays in, count out
- `KumoTimeWindow` — windowing, Y-domain fitting, `projectSeries` into
  caller-owned `Float64List`s, and the `Matrix4` transforms
- `KumoCanvas` / `KumoCanvasGridLayer` — a raw-canvas painter with the managed
  grid, for a drawing that is not a chart of layers at all

## Common mistakes

- Building a `Paint` inside `paint()`. It will look fine and stream badly.
- Reading `KumoTheme.of(context)` in a paint body, which is the same mistake with
  a nicer name. The tokens are on `KumoChartContext`.
- Rebuilding the widget on every data tick instead of passing a `Listenable` to
  `repaint`.
- Indexing `KumoChartColors.sequential` with a counter instead of
  `sequentialIndex(value, min, max)`.
- Expecting a foreground layer's axis labels to update per tick. They cannot; see
  the repaint split above.
- Re-parsing GeoJSON on every build. Parse once into `KumoGeoMapData` and hold it.
- Mutating a `KumoSankeyGraph` in place and expecting a relayout. The chart
  compares by identity; hand over a new graph.
- Allocating inside a `KumoCanvas` painter. The escape hatch is an escape from the
  component's opinions, not from its discipline.
