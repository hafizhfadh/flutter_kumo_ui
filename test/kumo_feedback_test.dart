import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Hosts [child] in a real app so an [Overlay] is present for the toast layer.
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

/// A button-shaped trigger that shows a toast for its own context.
Widget _toastTrigger({
  String message = 'Saved',
  String? title,
  KumoToastKind kind = KumoToastKind.info,
  Duration duration = const Duration(seconds: 4),
}) {
  return Builder(
    builder: (BuildContext context) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => KumoToastManager.show(
        context,
        message: message,
        title: title,
        kind: kind,
        duration: duration,
      ),
      child: const SizedBox(width: 200, height: 48),
    ),
  );
}

Color _badgeTextColor(WidgetTester tester) {
  final Text label = tester.widget<Text>(find.byType(Text).first);
  return label.style!.color!;
}

void main() {
  group('KumoBadge', () {
    testWidgets('renders an 11px bold monospace label in a pill', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const KumoBadge(label: 'Pro plan')));

      final Text label = tester.widget<Text>(find.text('Pro plan'));
      expect(label.style!.fontSize, 11);
      expect(label.style!.fontWeight, FontWeight.w700);
      expect(label.style!.fontFamily, 'monospace');

      final Container pill = tester.widget<Container>(
        find.byType(Container).first,
      );
      final BoxDecoration decoration = pill.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(999));
    });

    testWidgets('tints each variant with its own semantic token', (
      tester,
    ) async {
      const KumoColors colors = KumoColors();
      final Map<KumoBadgeVariant, Color> expected = <KumoBadgeVariant, Color>{
        KumoBadgeVariant.info: colors.info,
        KumoBadgeVariant.success: colors.success,
        KumoBadgeVariant.warning: colors.warning,
        KumoBadgeVariant.error: colors.dangerText,
        KumoBadgeVariant.neutral: colors.textSecondary,
      };

      for (final MapEntry<KumoBadgeVariant, Color> entry in expected.entries) {
        await tester.pumpWidget(
          _host(KumoBadge(label: 'Status', variant: entry.key)),
        );
        expect(
          _badgeTextColor(tester),
          entry.value,
          reason: '${entry.key} must use its semantic token',
        );
      }
    });

    testWidgets('renders an optional leading icon', (tester) async {
      await tester.pumpWidget(
        _host(
          const KumoBadge(
            label: 'Active',
            variant: KumoBadgeVariant.success,
            icon: PhosphorIconsRegular.checkCircle,
          ),
        ),
      );

      expect(find.byType(PhosphorIcon), findsOneWidget);
    });
  });

  group('KumoToast', () {
    testWidgets('renders a title, a message and a close action', (
      tester,
    ) async {
      var closed = 0;
      await tester.pumpWidget(
        _host(
          KumoToast(
            title: 'Deploy failed',
            message: 'Worker script is invalid.',
            kind: KumoToastKind.error,
            onClose: () => closed++,
          ),
        ),
      );

      expect(find.text('Deploy failed'), findsOneWidget);
      expect(find.text('Worker script is invalid.'), findsOneWidget);

      // The state icon leads; the close action is the trailing icon.
      expect(find.byType(PhosphorIcon), findsNWidgets(2));
      await tester.tap(find.byType(PhosphorIcon).last);
      expect(closed, 1);
    });

    testWidgets('hides the close action when onClose is null', (tester) async {
      await tester.pumpWidget(_host(const KumoToast(message: 'Heads up')));

      expect(find.byType(PhosphorIcon), findsOneWidget); // the state icon only
    });
  });

  group('KumoToastManager', () {
    tearDown(KumoToastManager.clear);

    testWidgets('shows a toast in the overlay and auto-dismisses it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _toastTrigger(
            message: 'Saved',
            duration: const Duration(milliseconds: 100),
          ),
        ),
      );

      expect(KumoToastManager.activeCount, 0);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(KumoToastManager.activeCount, 1);
      expect(find.text('Saved'), findsOneWidget);

      // Auto-dismiss fires after the toast's own duration.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      expect(KumoToastManager.activeCount, 0);
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('the close action removes the toast immediately', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_toastTrigger(message: 'Dismiss me')));

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(find.text('Dismiss me'), findsOneWidget);

      await tester.tap(find.byType(PhosphorIcon).last);
      await tester.pump();

      expect(find.text('Dismiss me'), findsNothing);
    });

    testWidgets('stacks multiple toasts instead of overlapping them', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_toastTrigger(message: 'First')));

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pumpWidget(_host(_toastTrigger(message: 'Second')));
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(KumoToastManager.activeCount, 2);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Second')).dy,
        greaterThan(tester.getTopLeft(find.text('First')).dy),
      );

      KumoToastManager.clear();
      await tester.pump();
      expect(KumoToastManager.activeCount, 0);
    });
  });
}
