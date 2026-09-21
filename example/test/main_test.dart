import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:kumo_ui_example/main.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Section headings that prove every showcase block rendered.
const List<String> _sectionLabels = <String>[
  'Theme',
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
  'Modal',
];

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

void main() {
  testWidgets('mobile viewport stacks the adaptive layouts', (tester) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    for (final String label in _sectionLabels) {
      expect(find.text(label), findsOneWidget);
    }

    final double titleTop = tester.getTopLeft(find.text('Kumo UI')).dy;

    // KumoHeader stacks its action beneath the heading on phones.
    final double actionTop = tester
        .getTopLeft(find.byType(KumoButton).first)
        .dy;
    expect(actionTop, greaterThan(titleTop + 20));

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

    // The modal still presents from a phone viewport.
    await tester.ensureVisible(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Deploy worker'), findsOneWidget);
  });

  testWidgets('mobile drives the selection, feedback and navigation widgets', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    // The example follows the platform by default, and the test platform
    // reports light. Pin the dark scheme so the color assertions below are
    // deterministic.
    await _revealAndTap(tester, find.text('Dark'));

    // Checkbox toggles in place: the fill drops from the brand orange back to
    // the resting tone.
    BoxDecoration checkboxFill() =>
        tester
                .widget<AnimatedContainer>(
                  find
                      .descendant(
                        of: find.byType(KumoCheckbox),
                        matching: find.byType(AnimatedContainer),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;

    expect(checkboxFill().color, const KumoColors().primary);
    await _revealAndTap(tester, find.text('Enable caching'));
    expect(checkboxFill().color, const KumoColors().subtleSurface);

    // Select opens the touch-friendly action sheet, not a popover, and the
    // sheet carries the field label as its title.
    await _revealAndTap(tester, find.text('Free'));
    expect(find.byType(KumoBottomSheetItem), findsNWidgets(3));
    expect(find.text('Plan'), findsOneWidget);

    await _revealAndTap(tester, find.text('Business'));
    expect(find.text('Business'), findsOneWidget);
    expect(find.byType(KumoBottomSheetItem), findsNothing);

    // Tabs switch the selection.
    await _revealAndTap(tester, find.text('Security'));
    expect(find.text('Tab index 2 is selected.'), findsOneWidget);

    // Pagination advances a page.
    await _revealAndTap(tester, find.text('Next'));
    expect(find.text('Page 3 of 5'), findsOneWidget);

    // Toast overlays the screen and auto-dismisses.
    await _revealAndTap(tester, find.text('Show success toast'));
    expect(find.text('Worker deployed'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Worker deployed'), findsNothing);
  });

  testWidgets('desktop viewport pairs the adaptive layouts', (tester) async {
    _setViewport(tester, const Size(1200, 900));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    final double titleTop = tester.getTopLeft(find.text('Kumo UI')).dy;

    // KumoHeader puts the action on the same row as the heading.
    expect(
      tester.getTopLeft(find.byType(KumoButton).first).dy,
      moreOrLessEquals(titleTop, epsilon: 1),
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
      moreOrLessEquals(
        tester.getTopLeft(find.text('EDGE RULES')).dy,
        epsilon: 1,
      ),
    );
    expect(
      tester.getTopLeft(find.text('CACHING RULES')).dx,
      greaterThan(tester.getTopLeft(find.text('EDGE RULES')).dx),
    );
  });

  testWidgets('desktop opens the select as an anchored popover', (
    tester,
  ) async {
    _setViewport(tester, const Size(1200, 900));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    await _revealAndTap(tester, find.text('Free'));

    // The desktop picker renders options in place, with no sheet title.
    expect(find.byType(KumoBottomSheetItem), findsNWidgets(3));
    expect(find.text('Plan'), findsNothing);

    await _revealAndTap(tester, find.text('Pro'));
    expect(find.text('Pro'), findsOneWidget);
    expect(find.byType(KumoBottomSheetItem), findsNothing);
  });

  testWidgets('the theme selector repaints the app in the chosen scheme', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(const KumoExampleApp());
    await tester.pumpAndSettle();

    // The scaffold paints the scheme canvas, so it reports the active mode.
    Color canvas() =>
        tester.widget<ColoredBox>(find.byType(ColoredBox).first).color;

    await _revealAndTap(tester, find.text('Dark'));
    expect(canvas(), const KumoColors.dark().canvas);

    await _revealAndTap(tester, find.text('Light'));
    expect(canvas(), const KumoColors.light().canvas);
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
  });
}
