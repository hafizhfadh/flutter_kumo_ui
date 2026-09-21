import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:kumo_ui_example/main.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Section headings that prove every showcase block rendered.
const List<String> _gallerySections = <String>[
  'Theme',
  'Navigation',
  'Segmented control',
  'Text input',
  'Toggle',
  'Accordion',
  'List group',
  'Resource grid',
  'Responsive split',
  'Breadcrumb',
  'Tabs',
  'Badges',
  'Checkbox and select',
  'Pagination',
  'Bottom sheet',
  'Toast',
  'Code block',
  'Palette',
  'Primitives',
  'Modal',
];

/// Every drawer entry, and the page title it routes to.
const Map<String, String> _destinations = <String, String>{
  'Gallery': 'Component gallery',
  'Realtime series': 'Live request rate',
  'Flow network': 'Request flow network',
  'Vector map': 'Traffic by region',
  'Custom canvas': 'Custom visualiser',
  'Settings': 'App settings',
};

/// Advances far enough for a route transition to finish.
///
/// The live chart routes animate for as long as they are mounted, so
/// `pumpAndSettle` would never return on them; time is advanced explicitly
/// instead.
Future<void> _advanceRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Unmounts the app so a live route's timers are cancelled before the test
/// framework checks for pending timers.
Future<void> _shutdown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

/// Scrolls [finder] into the viewport and taps it.
Future<void> _revealAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Matches [title] inside a resource card, so breadcrumb and card labels that
/// happen to share the same text stay distinguishable.
Finder _cardTitle(String title) =>
    find.descendant(of: find.byType(KumoDataCard), matching: find.text(title));

/// The gallery header's action, matched by widget rather than by its label: the
/// label is centred inside a 48px button, so its top is not the button's.
Finder _headerAction() => find.ancestor(
  of: find.text('Reset fields'),
  matching: find.byType(KumoButton),
);

/// Whether the drawer row labelled [label] reports itself as the current route.
bool _isDrawerItemSelected(WidgetTester tester, String label) {
  final Finder semanticsAncestors = find.ancestor(
    of: find.text(label),
    matching: find.byType(Semantics),
  );
  for (final element in semanticsAncestors.evaluate()) {
    final Semantics semantics = element.widget as Semantics;
    final bool? selected = semantics.properties.selected;
    if (selected != null) {
      return selected;
    }
  }
  throw StateError('No drawer row with a selected flag above "$label".');
}

/// The buffered point count the timeseries route reports.
int _bufferedPoints(WidgetTester tester) {
  final Text text = tester.widget<Text>(find.textContaining('points buffered'));
  return int.parse((text.data ?? '').split(' ').first);
}

/// Asserts the choropleth is truly on screen: every region inside the plot,
/// centred, and filling the axis the aspect-correct fit constrains.
///
/// Read from the rendered [KumoGeoMapChart] and re-derived through the public
/// projector, so it checks the viewport the widget actually asked for rather
/// than a number copied from the page.
void _expectChoroplethFillsThePlot(WidgetTester tester) {
  final KumoGeoMapChart chart = tester.widget<KumoGeoMapChart>(
    find.byType(KumoGeoMapChart),
  );
  final Size size = tester.getSize(find.byType(KumoGeoMapChart));
  // A map reserves no axis room, so its plot is the whole surface.
  const Rect plot = Rect.fromLTWH(0, 0, 0, 0);

  final KumoGeoProjector projector = KumoGeoProjector(
    projection: chart.projection,
    bounds: chart.data.bounds,
  );
  final view = projector.computeViewMatrix(
    left: plot.left,
    top: plot.top,
    width: size.width,
    height: size.height,
    zoom: chart.zoom,
    focusX: chart.focus?.dx,
    focusY: chart.focus?.dy,
  );

  final KumoGeoBounds bounds = chart.data.bounds;
  final double scale = KumoGeoProjector.scaleOf(view);
  final double left = KumoGeoProjector.translationX(view) + bounds.minX * scale;
  final double right = KumoGeoProjector.translationX(view) + bounds.maxX * scale;
  final double top = KumoGeoProjector.translationY(view) + bounds.minY * scale;
  final double bottom = KumoGeoProjector.translationY(view) + bounds.maxY * scale;

  expect(left, greaterThanOrEqualTo(-0.5), reason: 'the west edge is on screen');
  expect(top, greaterThanOrEqualTo(-0.5), reason: 'the north edge is on screen');
  expect(right, lessThanOrEqualTo(size.width + 0.5));
  expect(bottom, lessThanOrEqualTo(size.height + 0.5));
  expect((left + right) / 2, moreOrLessEquals(size.width / 2, epsilon: 1));
  expect((top + bottom) / 2, moreOrLessEquals(size.height / 2, epsilon: 1));
  expect(
    (right - left) >= size.width - 0.5 || (bottom - top) >= size.height - 0.5,
    isTrue,
    reason: 'the fit fills the constraining axis rather than shrinking inside',
  );
}

void main() {
  testWidgets('wide: the drawer is docked and every destination routes', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 900));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    // The shell is the drawer scaffold, and the gallery is the landing route.
    expect(find.byType(KumoDrawerScaffold), findsOneWidget);
    expect(find.byType(KumoDrawer), findsOneWidget);
    expect(find.text('Component gallery'), findsOneWidget);
    for (final String label in _gallerySections) {
      expect(find.text(label), findsOneWidget);
    }
    for (final String label in _destinations.keys) {
      expect(find.text(label), findsOneWidget);
    }
    expect(_isDrawerItemSelected(tester, 'Gallery'), isTrue);

    // A docked drawer offers no menu affordance, because it would open nothing.
    expect(find.text('Menu'), findsNothing);

    // Sankey.
    await tester.tap(find.text('Flow network'));
    await tester.pumpAndSettle();
    expect(find.text('Request flow network'), findsOneWidget);
    expect(find.text('/charts/sankey'), findsOneWidget);
    expect(find.byType(KumoSankeyChart), findsOneWidget);
    expect(_isDrawerItemSelected(tester, 'Flow network'), isTrue);
    expect(_isDrawerItemSelected(tester, 'Gallery'), isFalse);

    // The solver readout is derived from the library's own layout pass.
    expect(find.textContaining('columns'), findsOneWidget);

    // Choropleth.
    await tester.tap(find.text('Vector map'));
    await tester.pumpAndSettle();
    expect(find.text('Traffic by region'), findsOneWidget);
    expect(find.text('/charts/geomap'), findsOneWidget);
    expect(find.byType(KumoGeoMapChart), findsOneWidget);

    // Custom canvas — animating, so time is advanced rather than settled.
    await tester.tap(find.text('Custom canvas'));
    await _advanceRoute(tester);
    expect(find.text('Custom visualiser'), findsOneWidget);
    expect(find.text('/charts/custom'), findsOneWidget);
    expect(find.byType(KumoCanvas), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Leaving an animating route settles again.
    await tester.tap(find.text('Gallery'));
    await _advanceRoute(tester);
    await tester.pumpAndSettle();
    expect(find.text('Component gallery'), findsOneWidget);

    await _shutdown(tester);
  });

  testWidgets('the choropleth route renders the whole map', (tester) async {
    _setViewport(tester, const Size(1280, 900));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vector map'));
    await tester.pumpAndSettle();

    expect(find.text('Traffic by region'), findsOneWidget);
    expect(find.text('/charts/geomap'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final KumoGeoMapChart chart = tester.widget<KumoGeoMapChart>(
      find.byType(KumoGeoMapChart),
    );
    // Populated: the fixture parses and has a real magnitude domain to colour by.
    expect(chart.data.features.length, greaterThan(20));
    expect(chart.data.maxValue, greaterThan(chart.data.minValue));
    expect(chart.data.bounds.isEmpty, isFalse);

    // Rendered: the map is fitted to the plot rather than opened zoomed into a
    // single region, so the choropleth is actually visible on arrival.
    _expectChoroplethFillsThePlot(tester);

    // Zooming to a region still narrows the viewport onto it.
    await tester.ensureVisible(find.text('All regions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All regions'));
    await tester.pumpAndSettle();
    final String firstRegion = chart.data.features.first.name ?? '';
    await tester.tap(find.textContaining(firstRegion));
    await tester.pumpAndSettle();
    expect(
      tester.widget<KumoGeoMapChart>(find.byType(KumoGeoMapChart)).zoom,
      greaterThan(1),
    );
    expect(tester.takeException(), isNull);

    await _shutdown(tester);
  });

  testWidgets('narrow: the drawer slides over the page and drives the route', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    // The drawer is a sheet here, so it is not built until it is opened.
    expect(find.text('Gallery'), findsNothing);
    expect(find.text('Menu'), findsOneWidget);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Realtime series'), findsOneWidget);

    await tester.tap(find.text('Vector map'));
    await _advanceRoute(tester);
    expect(find.text('Traffic by region'), findsOneWidget);
    expect(find.text('/charts/geomap'), findsOneWidget);

    // Choosing a destination closed the sheet, so the page is not covered —
    // and closing it reached the scaffold through the row's own context rather
    // than throwing a lookup assertion.
    expect(find.text('Gallery'), findsNothing);
    expect(tester.takeException(), isNull);

    await _shutdown(tester);
  });

  testWidgets('wide: the gallery keeps its desktop arrangements', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 900));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    final double headingTop = tester.getTopLeft(find.text('Component gallery')).dy;

    // KumoHeader puts the action on the same row as the heading.
    expect(
      tester.getTopLeft(_headerAction()).dy,
      moreOrLessEquals(headingTop, epsilon: 2),
    );

    // KumoDataGrid lays the cards out side by side.
    expect(
      tester.getTopLeft(find.text('Global DNS')).dy,
      moreOrLessEquals(
        tester.getTopLeft(_cardTitle('example.com')).dy,
        epsilon: 1,
      ),
    );
    expect(
      tester.getTopLeft(find.text('Global DNS')).dx,
      greaterThan(tester.getTopLeft(_cardTitle('example.com')).dx),
    );

    // KumoResponsiveLayout picks the side-by-side arrangement.
    expect(
      tester.getTopLeft(find.text('CACHING RULES')).dy,
      moreOrLessEquals(tester.getTopLeft(find.text('EDGE RULES')).dy, epsilon: 1),
    );
    expect(
      tester.getTopLeft(find.text('CACHING RULES')).dx,
      greaterThan(tester.getTopLeft(find.text('EDGE RULES')).dx),
    );

    await _shutdown(tester);
  });

  testWidgets('narrow: the gallery stacks its adaptive layouts', (tester) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    final double headingTop = tester.getTopLeft(find.text('Component gallery')).dy;

    // KumoHeader stacks its action beneath the heading on phones.
    expect(
      tester.getTopLeft(_headerAction()).dy,
      greaterThan(headingTop + 20),
    );

    // KumoDataGrid becomes a vertical stack of cards.
    expect(
      tester.getTopLeft(find.text('Global DNS')).dy,
      greaterThan(tester.getTopLeft(_cardTitle('example.com')).dy),
    );

    // KumoResponsiveLayout picks the stacked arrangement.
    expect(
      tester.getTopLeft(find.text('CACHING RULES')).dy,
      greaterThan(tester.getTopLeft(find.text('EDGE RULES')).dy),
    );

    await _shutdown(tester);
  });

  testWidgets('the theme selector repaints the app in the chosen scheme', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    // The shell paints the scheme canvas, so it reports the active mode.
    Color canvas() =>
        tester.widget<ColoredBox>(find.byType(ColoredBox).first).color;

    await _revealAndTap(tester, find.text('Dark'));
    expect(canvas(), const KumoColors.dark().canvas);
    expect(find.text('Painting the dark scheme.'), findsOneWidget);

    await _revealAndTap(tester, find.text('Light'));
    expect(canvas(), const KumoColors.light().canvas);

    // The selector itself shows the choice, which only holds if `mode` reaches
    // the routed page and not just the theme.
    expect(
      tester.widget<Text>(find.text('Light')).style?.color,
      const KumoColors.light().primary,
    );

    await _shutdown(tester);
  });

  testWidgets('the settings route pushes and pops through the shell', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    await _revealAndTap(tester, find.text('Open settings'));
    expect(find.text('Routed at /settings.'), findsOneWidget);
    expect(find.byType(KumoDrawer), findsNothing);

    await _revealAndTap(tester, find.text('Back'));
    expect(find.text('Component gallery'), findsOneWidget);

    await _shutdown(tester);
  });

  testWidgets('the select opens a sheet on a phone and a popover on desktop', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    await _revealAndTap(tester, find.text('Free'));
    expect(find.byType(KumoBottomSheetItem), findsNWidgets(3));
    expect(find.text('Plan'), findsOneWidget);

    await _revealAndTap(tester, find.text('Business'));
    expect(find.text('Business'), findsOneWidget);
    expect(find.byType(KumoBottomSheetItem), findsNothing);

    await _shutdown(tester);

    _setViewport(tester, const Size(1280, 900));
    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    await _revealAndTap(tester, find.text('Free'));
    expect(find.byType(KumoBottomSheetItem), findsNWidgets(3));
    expect(find.text('Plan'), findsNothing);

    await _revealAndTap(tester, find.text('Pro'));
    expect(find.text('Pro'), findsOneWidget);
    expect(find.byType(KumoBottomSheetItem), findsNothing);

    await _shutdown(tester);
  });

  testWidgets('the bottom sheet opens and reports the chosen action', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    await _revealAndTap(tester, find.text('Zone actions'));
    expect(find.byType(KumoBottomSheetItem), findsNWidgets(3));
    expect(find.text('Rename'), findsOneWidget);

    await _revealAndTap(tester, find.text('Duplicate'));
    expect(find.byType(KumoBottomSheetItem), findsNothing);
    expect(find.text('Chose Duplicate.'), findsOneWidget);

    await _shutdown(tester);
  });

  testWidgets('the live chart streams, pauses, and keeps its buffer', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 900));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Realtime series'));
    await _advanceRoute(tester);
    expect(find.text('Live request rate'), findsOneWidget);
    expect(find.text('/charts/timeseries'), findsOneWidget);
    expect(find.byType(KumoTimeseriesChart), findsOneWidget);
    expect(find.text('Streaming'), findsOneWidget);

    // Let the simulated socket deliver a burst.
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final int streaming = _bufferedPoints(tester);
    expect(streaming, greaterThan(0));

    // Pausing stops the stream without clearing what it already delivered.
    await tester.tap(find.text('Pause stream'));
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    final int paused = _bufferedPoints(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(_bufferedPoints(tester), paused);

    // Clearing drops the history while the stream stays open.
    await tester.tap(find.text('Clear buffer'));
    await tester.pump();
    expect(_bufferedPoints(tester), 0);

    // Resume, so there is history to carry across the route change.
    await tester.tap(find.text('Resume stream'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final int refilled = _bufferedPoints(tester);
    expect(refilled, greaterThan(0));

    // Leaving the route stops the stream but keeps the feed's buffer, because
    // the feed is owned above the router rather than by the page.
    await tester.tap(find.text('Gallery'));
    await _advanceRoute(tester);
    await tester.pumpAndSettle();
    expect(find.text('Component gallery'), findsOneWidget);

    await tester.tap(find.text('Realtime series'));
    await _advanceRoute(tester);
    expect(_bufferedPoints(tester), greaterThanOrEqualTo(refilled));

    await _shutdown(tester);
  });

  testWidgets('the custom canvas draws through the escape hatch', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 900));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Custom canvas'));
    await _advanceRoute(tester);
    expect(find.byType(KumoCanvas), findsOneWidget);
    expect(find.text('threshold 160'), findsOneWidget);

    // The threshold is a managed control over the custom drawing.
    await tester.tap(find.text('200'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('threshold 200'), findsOneWidget);

    await tester.tap(find.text('Shuffle buckets'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    // Pausing stops the animation timer, and the drawing stays put.
    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Resume'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _shutdown(tester);
  });
}
