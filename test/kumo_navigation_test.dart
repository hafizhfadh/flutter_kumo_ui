import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

Widget _host(Widget child, {double width = 360}) {
  return KumoTheme(
    child: MediaQuery(
      data: const MediaQueryData(size: Size(1000, 800)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

Color _tabIndicatorColor(WidgetTester tester, String label) {
  final AnimatedContainer tab = tester.widget<AnimatedContainer>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  final BoxDecoration decoration = tab.decoration! as BoxDecoration;
  final Border border = decoration.border! as Border;
  return border.bottom.color;
}

void main() {
  group('KumoBreadcrumb', () {
    testWidgets('renders the trail separated by carets', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _host(
          KumoBreadcrumb(
            items: <KumoBreadcrumbItem>[
              KumoBreadcrumbItem(label: 'Accounts', onTap: () => tapped++),
              const KumoBreadcrumbItem(label: 'example.com'),
              const KumoBreadcrumbItem(label: 'DNS'),
            ],
          ),
        ),
      );

      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('example.com'), findsOneWidget);
      expect(find.text('DNS'), findsOneWidget);

      // One caret between each pair of steps.
      expect(find.byType(PhosphorIcon), findsNWidgets(2));

      await tester.tap(find.text('Accounts'));
      expect(tapped, 1);
    });

    testWidgets('the current page is not interactive', (tester) async {
      await tester.pumpWidget(
        _host(
          const KumoBreadcrumb(
            items: <KumoBreadcrumbItem>[KumoBreadcrumbItem(label: 'Only')],
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
      expect(find.byType(PhosphorIcon), findsNothing);
    });

    testWidgets('gives tappable steps a 48px target', (tester) async {
      await tester.pumpWidget(
        _host(
          KumoBreadcrumb(
            items: <KumoBreadcrumbItem>[
              KumoBreadcrumbItem(label: 'Accounts', onTap: () {}),
              const KumoBreadcrumbItem(label: 'DNS'),
            ],
          ),
        ),
      );

      final Finder target = find
          .ancestor(of: find.text('Accounts'), matching: find.byType(Container))
          .first;
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    });

    testWidgets('scrolls rather than overflowing a long trail', (tester) async {
      await tester.pumpWidget(
        _host(
          KumoBreadcrumb(
            items: <KumoBreadcrumbItem>[
              for (var index = 0; index < 12; index++)
                KumoBreadcrumbItem(
                  label: 'Segment number $index',
                  onTap: () {},
                ),
            ],
          ),
          width: 240,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('KumoPagination', () {
    testWidgets('reports the previous and next pages', (tester) async {
      final List<int> requested = <int>[];
      await tester.pumpWidget(
        _host(
          KumoPagination(
            currentPage: 2,
            totalPages: 5,
            onPageChanged: requested.add,
          ),
        ),
      );

      expect(find.text('Page 2 of 5'), findsOneWidget);

      await tester.tap(find.text('Prev'));
      await tester.tap(find.text('Next'));
      expect(requested, <int>[1, 3]);
    });

    testWidgets('disables Prev on the first page', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          KumoPagination(
            currentPage: 1,
            totalPages: 3,
            onPageChanged: (_) => calls++,
          ),
        ),
      );

      await tester.tap(find.text('Prev'), warnIfMissed: false);
      expect(calls, 0);
    });

    testWidgets('disables Next on the last page', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          KumoPagination(
            currentPage: 3,
            totalPages: 3,
            onPageChanged: (_) => calls++,
          ),
        ),
      );

      await tester.tap(find.text('Next'), warnIfMissed: false);
      expect(calls, 0);
    });

    testWidgets('clamps out-of-range input into the available pages', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          KumoPagination(currentPage: 99, totalPages: 0, onPageChanged: (_) {}),
        ),
      );

      expect(find.text('Page 1 of 1'), findsOneWidget);
    });
  });

  group('KumoTabs', () {
    testWidgets('renders the tabs and reports the tapped index', (
      tester,
    ) async {
      final List<int> changes = <int>[];
      await tester.pumpWidget(
        _host(
          KumoTabs(
            tabs: const <String>['Overview', 'DNS', 'Workers'],
            selectedIndex: 0,
            onTabChanged: changes.add,
          ),
        ),
      );

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('DNS'), findsOneWidget);
      expect(find.text('Workers'), findsOneWidget);

      await tester.tap(find.text('Workers'));
      expect(changes, <int>[2]);
    });

    testWidgets('underlines only the active tab in the brand orange', (
      tester,
    ) async {
      final KumoColors colors = KumoColors();
      await tester.pumpWidget(
        _host(
          KumoTabs(
            tabs: const <String>['Overview', 'DNS'],
            selectedIndex: 1,
            onTabChanged: (_) {},
          ),
        ),
      );

      expect(_tabIndicatorColor(tester, 'DNS'), colors.primary);
      expect(_tabIndicatorColor(tester, 'Overview'), const Color(0x00000000));
    });

    testWidgets('keeps every tab at a 48px tap height', (tester) async {
      await tester.pumpWidget(
        _host(
          KumoTabs(
            tabs: const <String>['Overview', 'DNS'],
            selectedIndex: 0,
            onTabChanged: (_) {},
          ),
        ),
      );

      final Finder tab = find
          .ancestor(
            of: find.text('Overview'),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      expect(tester.getSize(tab).height, greaterThanOrEqualTo(48));
    });

    testWidgets('is announced as a selected tab', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            KumoTabs(
              tabs: const <String>['Overview', 'DNS'],
              selectedIndex: 0,
              onTabChanged: (_) {},
            ),
          ),
        );

        expect(
          tester.getSemantics(find.text('Overview')),
          isSemantics(isButton: true, isSelected: true, hasTapAction: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
