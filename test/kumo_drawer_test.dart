import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Hosts [child] at a fixed width, anchored top-left so global tap coordinates
/// stay predictable.
Widget _host(Widget child, {double width = 800}) {
  return KumoTheme(
    child: MediaQuery(
      data: const MediaQueryData(size: Size(800, 600)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: width, height: 600, child: child),
        ),
      ),
    ),
  );
}

Widget _drawer({bool isCollapsed = false}) => KumoDrawer(
  isCollapsed: isCollapsed,
  children: <Widget>[
    KumoDrawerGroup(
      label: 'Overview',
      isCollapsed: isCollapsed,
      children: <Widget>[
        KumoDrawerItem(
          label: 'Home',
          icon: PhosphorIconsRegular.house,
          isSelected: true,
          isCollapsed: isCollapsed,
          onTap: () {},
        ),
        KumoDrawerItem(
          label: 'Domains',
          icon: PhosphorIconsRegular.globe,
          isCollapsed: isCollapsed,
          onTap: () {},
        ),
      ],
    ),
  ],
);

/// Hosts [child] with loose constraints, so a preferred width is respected.
Widget _loose(Widget child) => _host(
  Align(alignment: AlignmentDirectional.topStart, child: child),
);

void main() {
  group('KumoDrawerScaffold docked', () {
    testWidgets('docks the drawer beside the page on a wide viewport', (
      tester,
    ) async {
      bool? docked;
      await tester.pumpWidget(
        _host(
          KumoDrawerScaffold(
            drawer: _drawer(),
            child: Builder(
              builder: (BuildContext context) {
                docked = KumoDrawerScaffold.isDocked(context);
                return const Text('Page');
              },
            ),
          ),
        ),
      );

      expect(docked, isTrue);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Page'), findsOneWidget);
    });

    testWidgets('places the page to the right of the drawer', (tester) async {
      await tester.pumpWidget(
        _host(
          KumoDrawerScaffold(drawer: _drawer(), child: const Text('Page')),
        ),
      );

      expect(
        tester.getTopLeft(find.text('Page')).dx,
        greaterThan(tester.getTopLeft(find.text('Home')).dx),
      );
    });
  });

  group('KumoDrawerScaffold as a drawer', () {
    testWidgets('hides the drawer on a narrow viewport', (tester) async {
      bool? docked;
      await tester.pumpWidget(
        _host(
          KumoDrawerScaffold(
            drawer: _drawer(),
            child: Builder(
              builder: (BuildContext context) {
                docked = KumoDrawerScaffold.isDocked(context);
                return const Text('Page');
              },
            ),
          ),
          width: 400,
        ),
      );

      expect(docked, isFalse);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('opens over the page and closes on a scrim tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          KumoDrawerScaffold(
            drawer: _drawer(),
            child: Builder(
              builder: (BuildContext context) => KumoButton(
                label: 'Menu',
                onPressed: () => KumoDrawerScaffold.open(context),
              ),
            ),
          ),
          width: 400,
        ),
      );

      expect(find.text('Home'), findsNothing);

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      // Right of the 240px panel, so this lands on the scrim.
      await tester.tapAt(const Offset(380, 300));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('closes on Escape', (tester) async {
      await tester.pumpWidget(
        _host(
          KumoDrawerScaffold(
            drawer: _drawer(),
            child: Builder(
              builder: (BuildContext context) => KumoButton(
                label: 'Menu',
                onPressed: () => KumoDrawerScaffold.open(context),
              ),
            ),
          ),
          width: 400,
        ),
      );

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
    });
  });

  group('KumoDrawerScaffold scope lookup', () {
    testWidgets('drawer rows built with their own context can close it', (
      tester,
    ) async {
      // The drawer is built by a `Builder`, so its rows capture a context below
      // the scaffold. This is the wiring the class documents, and the one a
      // callback closing over the creating context gets wrong.
      await tester.pumpWidget(
        _host(
          KumoDrawerScaffold(
            drawer: Builder(
              builder: (BuildContext drawerContext) => KumoDrawer(
                children: <Widget>[
                  KumoDrawerItem(
                    label: 'Home',
                    onTap: () => KumoDrawerScaffold.close(drawerContext),
                  ),
                ],
              ),
            ),
            child: Builder(
              builder: (BuildContext context) => KumoButton(
                label: 'Menu',
                onPressed: () => KumoDrawerScaffold.open(context),
              ),
            ),
          ),
          width: 400,
        ),
      );

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a context above the scaffold asserts with a fix, not a crash', (
      tester,
    ) async {
      late BuildContext creatingContext;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (BuildContext context) {
              creatingContext = context;
              return KumoDrawerScaffold(
                drawer: _drawer(),
                child: const Text('Page'),
              );
            },
          ),
        ),
      );

      // The builds that create the scaffold, its drawer and its page are all
      // ancestors of the scope, so their contexts are not descendants and the
      // lookup fails. It fails with an explanation rather than a bare
      // null-check, which is what the old `scope!` produced in a release build.
      expect(
        () => KumoDrawerScaffold.close(creatingContext),
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.message,
            'message',
            allOf(
              contains('KumoDrawerScaffold'),
              contains('Builder'),
              contains('hasScaffold'),
            ),
          ),
        ),
      );
      expect(
        () => KumoDrawerScaffold.open(creatingContext),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('hasScaffold reports absence without asserting', (
      tester,
    ) async {
      bool? outside;
      bool? inside;

      await tester.pumpWidget(
        _host(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Builder(
                builder: (BuildContext context) {
                  outside = KumoDrawerScaffold.hasScaffold(context);
                  return const SizedBox.shrink();
                },
              ),
              SizedBox(
                height: 400,
                child: KumoDrawerScaffold(
                  drawer: _drawer(),
                  child: Builder(
                    builder: (BuildContext context) {
                      inside = KumoDrawerScaffold.hasScaffold(context);
                      return const Text('Page');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // `isDocked` cannot tell "not docked" from "no scaffold at all", which is
      // the whole reason the non-asserting probe exists.
      expect(outside, isFalse);
      expect(inside, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('KumoDrawer', () {
    testWidgets('paints the selected row with the recessed fill', (
      tester,
    ) async {
      await tester.pumpWidget(_loose(_drawer()));

      final Container selected = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(KumoDrawerItem).first,
              matching: find.byType(Container),
            )
            .last,
      );
      expect(
        (selected.decoration! as BoxDecoration).color,
        const KumoColors().subtleSurface,
      );

      final Container resting = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(KumoDrawerItem).last,
              matching: find.byType(Container),
            )
            .last,
      );
      expect(
        (resting.decoration! as BoxDecoration).color,
        const Color(0x00000000),
      );
    });

    testWidgets('announces the current destination', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_loose(_drawer()));

        expect(
          tester.getSemantics(find.byType(KumoDrawerItem).first),
          isSemantics(isButton: true, isSelected: true),
        );
        expect(
          tester.getSemantics(find.byType(KumoDrawerItem).last),
          isSemantics(isButton: true, isSelected: false),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('renders icons only when collapsed', (tester) async {
      await tester.pumpWidget(_loose(_drawer(isCollapsed: true)));

      expect(find.text('Home'), findsNothing);
      expect(find.text('OVERVIEW'), findsNothing);
      expect(find.byType(PhosphorIcon), findsNWidgets(2));
      expect(tester.getSize(find.byType(KumoDrawer)).width, 68);
    });

    testWidgets('keeps the label reachable as a semantics label when collapsed', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_loose(_drawer(isCollapsed: true)));

        expect(find.bySemanticsLabel('Home'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });
}
