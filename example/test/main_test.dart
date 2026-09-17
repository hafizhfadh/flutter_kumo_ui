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
  'Segmented control',
  'Text input',
  'Toggle',
  'Accordion',
  'List group',
  'Resource grid',
  'Responsive split',
  'Code block',
  'Modal',
];

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
      greaterThan(tester.getTopLeft(find.text('example.com')).dy),
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
        tester.getTopLeft(find.text('example.com')).dy,
        epsilon: 1,
      ),
    );
    expect(
      tester.getTopLeft(find.text('Global DNS')).dx,
      greaterThan(tester.getTopLeft(find.text('example.com')).dx),
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
}
