import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Hosts [child] in a real app so an [Overlay] and a [Navigator] are present.
Widget _host(Widget child) {
  return KumoTheme(
    child: WidgetsApp(
      color: const Color(0xFF111111),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => builder(context),
          ),
      home: Center(child: SizedBox(width: 360, child: child)),
    ),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('KumoCheckbox', () {
    testWidgets('renders a label and toggles on tap', (tester) async {
      bool? next;
      await tester.pumpWidget(
        _host(
          KumoCheckbox(
            value: false,
            label: 'Enable caching',
            onChanged: (bool value) => next = value,
          ),
        ),
      );

      expect(find.text('Enable caching'), findsOneWidget);
      expect(find.byType(PhosphorIcon), findsNothing);

      await tester.tap(find.text('Enable caching'));
      expect(next, isTrue);
    });

    testWidgets('shows the check glyph when checked', (tester) async {
      await tester.pumpWidget(
        _host(KumoCheckbox(value: true, onChanged: (bool _) {})),
      );

      expect(find.byType(PhosphorIcon), findsOneWidget);
    });

    testWidgets('paints the orange fill when checked', (tester) async {
      await tester.pumpWidget(
        _host(KumoCheckbox(value: true, onChanged: (bool _) {})),
      );

      final AnimatedContainer box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final BoxDecoration decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, const KumoColors().primary);
      expect(decoration.border, isNotNull);
    });

    testWidgets('keeps a 48x48 target and ignores taps when disabled', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          KumoCheckbox(
            value: false,
            label: 'Locked',
            isDisabled: true,
            onChanged: (bool _) => calls++,
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(KumoCheckbox));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));

      await tester.tap(find.text('Locked'), warnIfMissed: false);
      expect(calls, 0);
    });

    testWidgets('is announced as a checkbox with its state', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(KumoCheckbox(value: true, onChanged: (bool _) {})),
        );

        expect(
          tester.getSemantics(find.byType(KumoCheckbox)),
          isSemantics(
            isEnabled: true,
            isFocusable: true,
            hasCheckedState: true,
            isChecked: true,
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('KumoSelect', () {
    const Map<String, String> options = <String, String>{
      'alpha': 'Alpha',
      'beta': 'Beta',
      'gamma': 'Gamma',
    };

    testWidgets('desktop opens an anchored popover and reports a choice', (
      tester,
    ) async {
      _setViewport(tester, const Size(1000, 800));
      String selected = 'alpha';

      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                KumoSelect<String>(
                  value: selected,
                  options: options,
                  label: 'Zone',
                  onChanged: (String value) => setState(() => selected = value),
                ),
          ),
        ),
      );

      expect(find.text('ZONE'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      // Popover lists every option, anchored to the trigger.
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.byType(KumoBottomSheetItem), findsNWidgets(3));

      await tester.tap(find.text('Gamma'));
      await tester.pumpAndSettle();

      expect(selected, 'gamma');
      expect(find.text('Beta'), findsNothing);
    });

    testWidgets('desktop popover dismisses on an outside tap', (tester) async {
      _setViewport(tester, const Size(1000, 800));

      await tester.pumpWidget(
        _host(
          KumoSelect<String>(
            value: 'alpha',
            options: options,
            onChanged: (String _) {},
          ),
        ),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(find.text('Beta'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Beta'), findsNothing);
    });

    testWidgets('mobile opens a bottom sheet action sheet', (tester) async {
      _setViewport(tester, const Size(390, 844));
      String selected = 'alpha';

      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                KumoSelect<String>(
                  value: selected,
                  options: options,
                  label: 'Zone',
                  onChanged: (String value) => setState(() => selected = value),
                ),
          ),
        ),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(find.byType(KumoBottomSheetItem), findsNWidgets(3));
      expect(find.text('Zone'), findsOneWidget);

      // Sheet rows are full-width 48px targets.
      expect(
        tester.getSize(find.byType(KumoBottomSheetItem).first).height,
        greaterThanOrEqualTo(48),
      );

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();

      expect(selected, 'beta');
      expect(find.byType(KumoBottomSheetItem), findsNothing);
    });

    testWidgets('selecting the current option is a no-op change', (
      tester,
    ) async {
      _setViewport(tester, const Size(1000, 800));
      String selected = 'alpha';

      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                KumoSelect<String>(
                  value: selected,
                  options: options,
                  onChanged: (String value) => setState(() => selected = value),
                ),
          ),
        ),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();

      expect(selected, 'beta');
    });
  });

  group('KumoBottomSheet', () {
    testWidgets('renders a title, a close action and its child', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (BuildContext context) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => KumoBottomSheet.show<void>(
                context: context,
                title: 'Choose a plan',
                child: const KumoBottomSheetItem(label: 'Pro'),
              ),
              child: const SizedBox(width: 200, height: 48),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.text('Choose a plan'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a plan'), findsNothing);
    });
  });
}
