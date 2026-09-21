import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

/// Reports the scheme [KumoTheme] resolves to at this point in the tree.
class _SchemeProbe extends StatelessWidget {
  const _SchemeProbe(this.onColors);

  final ValueChanged<KumoColors> onColors;

  @override
  Widget build(BuildContext context) {
    onColors(KumoTheme.of(context));
    return const SizedBox.shrink();
  }
}

void main() {
  group('KumoApp', () {
    testWidgets('follows the platform brightness by default', (tester) async {
      KumoColors? seen;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpWidget(KumoApp(home: _SchemeProbe((c) => seen = c)));
      expect(seen, const KumoColors.dark());

      // A platform change repaints without the app rebuilding anything.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(seen, const KumoColors.light());
    });

    testWidgets('pins the scheme when the mode is explicit', (tester) async {
      KumoColors? seen;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      // Platform says light; the mode says otherwise.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpWidget(
        KumoApp(
          mode: KumoThemeMode.dark,
          home: _SchemeProbe((c) => seen = c),
        ),
      );
      expect(seen, const KumoColors.dark());

      await tester.pumpWidget(
        KumoApp(
          mode: KumoThemeMode.light,
          home: _SchemeProbe((c) => seen = c),
        ),
      );
      expect(seen, const KumoColors.light());
    });

    testWidgets('uses the supplied schemes, in system mode too', (
      tester,
    ) async {
      const Color brand = Color(0xFF123456);
      final KumoColors customLight = KumoColors.light(primary: brand);
      final KumoColors customDark = KumoColors.dark(primary: brand);
      KumoColors? seen;

      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;

      await tester.pumpWidget(
        KumoApp(
          light: customLight,
          dark: customDark,
          home: _SchemeProbe((c) => seen = c),
        ),
      );

      // System mode has to reach for the supplied scheme, not a built-in one.
      expect(seen?.primary, brand);
      expect(seen, customLight);
    });

    testWidgets('derives the task-switcher color and root text style', (
      tester,
    ) async {
      await tester.pumpWidget(
        KumoApp(mode: KumoThemeMode.dark, home: const SizedBox.shrink()),
      );

      final WidgetsApp app = tester.widget<WidgetsApp>(find.byType(WidgetsApp));
      const KumoColors dark = KumoColors.dark();

      expect(app.color, dark.canvas);
      expect(app.textStyle?.color, dark.textPrimary);
      expect(app.title, isEmpty);
    });

    testWidgets('provides the navigator and overlay a modal needs', (
      tester,
    ) async {
      await tester.pumpWidget(
        KumoApp(
          home: Builder(
            builder: (BuildContext context) => Center(
              child: SizedBox(
                width: 200,
                child: KumoButton(
                  label: 'Open dialog',
                  onPressed: () => KumoModal.show<void>(
                    context: context,
                    title: 'Deploy worker',
                    child: const Text('Dialog body'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Deploy worker'), findsOneWidget);
      expect(find.text('Dialog body'), findsOneWidget);
    });

    testWidgets('exposes its navigator, which pushes and pops', (tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        KumoApp(navigatorKey: navigator, home: const Text('Home')),
      );
      expect(find.text('Home'), findsOneWidget);

      navigator.currentState!.push<void>(
        PageRouteBuilder<void>(
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) => const Text('Pushed'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pushed'), findsOneWidget);
      expect(find.text('Home'), findsNothing);

      navigator.currentState!.pop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('forwards named routes to the navigator', (tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        KumoApp(
          navigatorKey: navigator,
          home: const Text('Home'),
          routes: <String, WidgetBuilder>{
            '/second': (BuildContext context) => const Text('Second'),
          },
        ),
      );

      navigator.currentState!.pushNamed('/second');
      await tester.pumpAndSettle();

      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });
  });
}
