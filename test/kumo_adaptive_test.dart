import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Hosts [child] at a fixed layout width while reporting an independent
/// viewport width, so container-driven and media-query-driven behaviour can be
/// tested separately.
Widget _host(Widget child, {double width = 360, double viewport = 360}) {
  return KumoTheme(
    child: MediaQuery(
      data: MediaQueryData(size: Size(viewport, 800)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

BoxDecoration _cardDecoration(WidgetTester tester, int index) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(KumoDataCard).at(index),
          matching: find.byType(Container),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('KumoTheme', () {
    test('exposes the role-based palette', () {
      // textMuted was raised from #71717A to clear WCAG AA; see
      // kumo_accessibility_test.dart for the measured ratios.
      expect(const KumoColors().textMuted, const Color(0xFF8D8D99));
      expect(const KumoColors().focus, const Color(0xFFE9E9E9));
      expect(const KumoColors().danger, const Color(0xFFEF4444));
      expect(const KumoColors().dangerText, const Color(0xFFF87171));
      expect(const KumoColors().info, const Color(0xFF0EA5E9));
      expect(const KumoColors().success, const Color(0xFF34D399));
      expect(const KumoColors().primary, const Color(0xFFF38020));
    });

    test('semantic tokens resolve to steps of the raw palette', () {
      const KumoColors colors = KumoColors();
      expect(colors.canvas, KumoPalette.gray0);
      expect(colors.surface, KumoPalette.gray1);
      expect(colors.subtleSurface, KumoPalette.gray2);
      expect(colors.border, KumoPalette.gray3);
      expect(colors.textMuted, KumoPalette.gray5);
      expect(colors.textSecondary, KumoPalette.gray6);
      expect(colors.textPrimary, KumoPalette.gray9);
      expect(colors.primary, KumoPalette.orange5);
      expect(colors.info, KumoPalette.blue5);
      expect(colors.danger, KumoPalette.red5);
      expect(colors.success, KumoPalette.green5);
      expect(colors.warning, KumoPalette.amber5);
    });

    test('the unnamed constructor is the dark scheme', () {
      expect(const KumoColors(), const KumoColors.dark());
      expect(const KumoColors().brightness, Brightness.dark);
      expect(const KumoColors.light().brightness, Brightness.light);
    });

    test('KumoColors.of picks the scheme for a brightness', () {
      expect(KumoColors.of(Brightness.dark), const KumoColors.dark());
      expect(KumoColors.of(Brightness.light), const KumoColors.light());
    });

    test('the two schemes are distinct at every surface token', () {
      const KumoColors dark = KumoColors.dark();
      const KumoColors light = KumoColors.light();
      expect(light.canvas, isNot(dark.canvas));
      expect(light.surface, isNot(dark.surface));
      expect(light.subtleSurface, isNot(dark.subtleSurface));
      expect(light.textPrimary, isNot(dark.textPrimary));
      expect(light.primary, isNot(dark.primary));
    });

    test('light tokens resolve to steps of the light palette', () {
      const KumoColors colors = KumoColors.light();
      expect(colors.canvas, KumoLightPalette.gray8);
      expect(colors.surface, KumoLightPalette.gray9);
      expect(colors.subtleSurface, KumoLightPalette.gray7);
      expect(colors.border, KumoLightPalette.gray5);
      expect(colors.textPrimary, KumoLightPalette.gray0);
      expect(colors.textSecondary, KumoLightPalette.gray2);
      expect(colors.textMuted, KumoLightPalette.gray3);
      expect(colors.primary, KumoLightPalette.orange5);
      expect(colors.info, KumoLightPalette.blue5);
      expect(colors.danger, KumoLightPalette.red5);
      expect(colors.success, KumoLightPalette.green5);
      expect(colors.warning, KumoLightPalette.amber5);
    });

    test('the light palette is also a ten-step ascending ramp', () {
      const List<Color> grays = <Color>[
        KumoLightPalette.gray0,
        KumoLightPalette.gray1,
        KumoLightPalette.gray2,
        KumoLightPalette.gray3,
        KumoLightPalette.gray4,
        KumoLightPalette.gray5,
        KumoLightPalette.gray6,
        KumoLightPalette.gray7,
        KumoLightPalette.gray8,
        KumoLightPalette.gray9,
      ];
      expect(grays.toSet().length, 10);

      for (var index = 1; index < grays.length; index++) {
        expect(grays[index].r, greaterThan(grays[index - 1].r));
      }
    });

    test('the palette is a ten-step gray ramp plus five accents', () {
      const List<Color> grays = <Color>[
        KumoPalette.gray0,
        KumoPalette.gray1,
        KumoPalette.gray2,
        KumoPalette.gray3,
        KumoPalette.gray4,
        KumoPalette.gray5,
        KumoPalette.gray6,
        KumoPalette.gray7,
        KumoPalette.gray8,
        KumoPalette.gray9,
      ];
      expect(grays.toSet().length, 10);

      // The ramp must climb from darkest to lightest. Every step is a neutral
      // or near-neutral gray, so the red channel alone orders the scale.
      for (var index = 1; index < grays.length; index++) {
        expect(grays[index].r, greaterThan(grays[index - 1].r));
      }
    });

    test('platform guard is inert on native targets', () {
      expect(KumoTheme.ensureSupportedPlatform, returnsNormally);
    });
  });

  group('KumoResponsiveLayout', () {
    testWidgets('renders the mobile arrangement below the breakpoint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const KumoResponsiveLayout(
            mobile: Text('mobile'),
            desktop: Text('desktop'),
          ),
          width: 320,
        ),
      );

      expect(find.text('mobile'), findsOneWidget);
      expect(find.text('desktop'), findsNothing);
    });

    testWidgets('renders the desktop arrangement at the breakpoint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const KumoResponsiveLayout(
            mobile: Text('mobile'),
            desktop: Text('desktop'),
          ),
          width: kKumoBreakpoint,
        ),
      );

      expect(find.text('desktop'), findsOneWidget);
      expect(find.text('mobile'), findsNothing);
    });

    testWidgets('falls back to mobile when no desktop arrangement is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const KumoResponsiveLayout(mobile: Text('mobile')), width: 700),
      );

      expect(find.text('mobile'), findsOneWidget);
    });
  });

  group('KumoHeader', () {
    testWidgets('stacks the action under the title on mobile', (tester) async {
      await tester.pumpWidget(
        _host(
          const KumoHeader(
            title: 'Zones',
            subtitle: '3 active',
            action: Text('Add zone'),
          ),
          width: 360,
        ),
      );

      final titleY = tester.getTopLeft(find.text('Zones')).dy;
      final actionY = tester.getTopLeft(find.text('Add zone')).dy;

      expect(actionY, greaterThan(titleY));
    });

    testWidgets('aligns the action beside the title on desktop', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const KumoHeader(title: 'Zones', action: Text('Add zone')),
          width: 700,
        ),
      );

      final titleY = tester.getTopLeft(find.text('Zones')).dy;
      final actionY = tester.getTopLeft(find.text('Add zone')).dy;

      expect(actionY, moreOrLessEquals(titleY, epsilon: 1.0));
      expect(
        tester.getTopLeft(find.text('Add zone')).dx,
        greaterThan(tester.getTopLeft(find.text('Zones')).dx),
      );
    });
  });

  group('KumoDataGrid', () {
    testWidgets('stacks bordered cards vertically on mobile', (tester) async {
      await tester.pumpWidget(
        _host(
          const KumoDataGrid(
            children: [
              KumoDataCard(title: 'Zone A'),
              KumoDataCard(title: 'Zone B'),
            ],
          ),
          width: 360,
        ),
      );

      expect(find.byType(Table), findsNothing);
      expect(
        tester.getTopLeft(find.text('Zone B')).dy,
        greaterThan(tester.getTopLeft(find.text('Zone A')).dy),
      );
      expect(_cardDecoration(tester, 0).border, isNotNull);
    });

    testWidgets('lays cards out on one row with grid dividers on desktop', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const KumoDataGrid(
            children: [
              KumoDataCard(title: 'Zone A'),
              KumoDataCard(title: 'Zone B'),
            ],
          ),
          width: 700,
        ),
      );

      expect(find.byType(Table), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Zone B')).dy,
        moreOrLessEquals(tester.getTopLeft(find.text('Zone A')).dy, epsilon: 1),
      );
      expect(
        tester.getTopLeft(find.text('Zone B')).dx,
        greaterThan(tester.getTopLeft(find.text('Zone A')).dx),
      );
      expect(_cardDecoration(tester, 0).border, isNull);
    });

    testWidgets('renders nothing when there are no cards', (tester) async {
      await tester.pumpWidget(_host(const KumoDataGrid(children: [])));

      expect(find.byType(Table), findsNothing);
      expect(find.byType(Container), findsNothing);
    });
  });

  group('KumoDataCard', () {
    testWidgets('reveals details when the header is tapped', (tester) async {
      await tester.pumpWidget(
        _host(
          const KumoDataCard(
            title: 'example.com',
            subtitle: 'Zone',
            statusLabel: 'Active',
            details: [KumoDataPair(label: 'Plan', value: 'Pro')],
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(tester.getSize(find.byType(SizeTransition)).height, 0);

      await tester.tap(find.text('example.com'));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(SizeTransition)).height,
        greaterThan(0),
      );
      expect(find.text('Pro'), findsOneWidget);
    });

    testWidgets('stacks pairs on a narrow viewport and pairs them on desktop', (
      tester,
    ) async {
      const card = KumoDataCard(
        title: 'example.com',
        initiallyExpanded: true,
        details: [KumoDataPair(label: 'Plan', value: 'Pro')],
      );

      await tester.pumpWidget(_host(card, width: 360, viewport: 360));
      expect(
        tester.getTopLeft(find.text('Pro')).dy,
        greaterThan(tester.getTopLeft(find.text('Plan')).dy),
      );

      await tester.pumpWidget(_host(card, width: 360, viewport: 1000));
      expect(
        tester.getTopLeft(find.text('Pro')).dy,
        moreOrLessEquals(tester.getTopLeft(find.text('Plan')).dy, epsilon: 1),
      );
    });

    testWidgets('is inert when it carries no details', (tester) async {
      await tester.pumpWidget(
        _host(const KumoDataCard(title: 'Static', statusLabel: 'Unknown')),
      );

      await tester.tap(find.text('Static'));
      await tester.pumpAndSettle();

      expect(find.byType(SizeTransition), findsNothing);
    });
  });

  group('KumoListGroup', () {
    testWidgets('renders rows, a group title and a caret on tappable rows', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          KumoListGroup(
            title: 'Settings',
            children: [
              KumoListItem(title: 'General', onTap: () => taps++),
              const KumoListItem(title: 'Billing', subtitle: 'Monthly'),
            ],
          ),
        ),
      );

      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);

      await tester.tap(find.text('General'));
      expect(taps, 1);

      expect(find.byType(PhosphorIcon), findsOneWidget);
    });
  });

  group('KumoButton', () {
    testWidgets('invokes onPressed and keeps a 48px touch target', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(KumoButton(label: 'Deploy', onPressed: () => taps++)),
      );

      expect(
        tester.getSize(find.byType(KumoButton)).height,
        greaterThanOrEqualTo(48),
      );

      await tester.tap(find.text('Deploy'));
      expect(taps, 1);
    });

    testWidgets('renders an inert button when onPressed is null', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const KumoButton(label: 'Deploy')));

      await tester.tap(find.text('Deploy'), warnIfMissed: false);

      expect(find.text('Deploy'), findsOneWidget);
    });
  });
}
