import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

Widget _host(Widget child) {
  return KumoTheme(
    child: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 320, child: child)),
      ),
    ),
  );
}

Widget _navigatorHost(WidgetBuilder builder) {
  return KumoTheme(
    child: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          onGenerateRoute: (settings) => PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) =>
                builder(context),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('KumoTypography', () {
    test('exposes the documented type scale', () {
      expect(KumoTypography.h1.fontSize, 24);
      expect(KumoTypography.h1.fontWeight, FontWeight.w700);
      expect(KumoTypography.h1.color, const Color(0xFFEDEDED));

      expect(KumoTypography.h2.fontSize, 18);
      expect(KumoTypography.h2.fontWeight, FontWeight.w600);

      expect(KumoTypography.body.fontSize, 14);
      expect(KumoTypography.body.fontWeight, FontWeight.w400);

      expect(KumoTypography.bodyMuted.color, const Color(0xFFA1A1AA));
      expect(KumoTypography.caption.fontSize, 12);
      expect(KumoTypography.caption.color, const Color(0xFFA1A1AA));

      expect(KumoTypography.code.fontSize, 12);
      expect(KumoTypography.code.fontWeight, FontWeight.w500);
      expect(KumoTypography.code.fontFamily, 'monospace');
    });

    test('resolve tints the scale with the scheme text tones', () {
      final KumoTextStyles dark = KumoTypography.resolve(
        const KumoColors.dark(),
      );
      final KumoTextStyles light = KumoTypography.resolve(
        const KumoColors.light(),
      );

      expect(dark.body.color, const KumoColors.dark().textPrimary);
      expect(dark.bodyMuted.color, const KumoColors.dark().textSecondary);
      expect(light.body.color, const KumoColors.light().textPrimary);
      expect(light.bodyMuted.color, const KumoColors.light().textSecondary);
      expect(light.body.color, isNot(dark.body.color));
    });

    test('resolve keeps the size, weight and family of every token', () {
      final KumoTextStyles styles = KumoTypography.resolve(
        const KumoColors.light(),
      );

      expect(styles.h1.fontSize, KumoTypography.h1.fontSize);
      expect(styles.h1.fontWeight, KumoTypography.h1.fontWeight);
      expect(styles.h2.fontSize, KumoTypography.h2.fontSize);
      expect(styles.body.fontSize, KumoTypography.body.fontSize);
      expect(styles.bodyMuted.fontSize, KumoTypography.bodyMuted.fontSize);
      expect(styles.caption.fontSize, KumoTypography.caption.fontSize);
      expect(styles.code.fontFamily, 'monospace');
    });
  });

  group('KumoCodeBlock', () {
    testWidgets('renders the code, language and copy action', (tester) async {
      await tester.pumpWidget(
        _host(const KumoCodeBlock(code: 'wrangler deploy', language: 'bash')),
      );

      expect(find.text('wrangler deploy'), findsOneWidget);
      expect(find.text('bash'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('copies the code and confirms, then resets', (tester) async {
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await tester.pumpWidget(
        _host(const KumoCodeBlock(code: 'wrangler deploy')),
      );

      await tester.tap(find.text('Copy'));
      await tester.pump();

      expect(calls.single.method, 'Clipboard.setData');
      expect(
        (calls.single.arguments as Map<Object?, Object?>)['text'],
        'wrangler deploy',
      );
      expect(find.text('Copied'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1600));

      expect(find.text('Copied'), findsNothing);
      expect(find.text('Copy'), findsOneWidget);
    });
  });

  group('KumoModal', () {
    testWidgets('presents the title and child, then closes', (tester) async {
      await tester.pumpWidget(
        _navigatorHost(
          (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => KumoModal.show<void>(
              context: context,
              title: 'Deploy worker',
              child: const Text('Dialog body'),
            ),
            child: const SizedBox(width: 120, height: 40),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.text('Deploy worker'), findsOneWidget);
      expect(find.text('Dialog body'), findsOneWidget);

      await tester.tap(find.byType(PhosphorIcon));
      await tester.pumpAndSettle();

      expect(find.text('Deploy worker'), findsNothing);
      expect(find.text('Dialog body'), findsNothing);
    });
  });

  group('KumoAccordion', () {
    testWidgets('stays collapsed, then expands on tap', (tester) async {
      await tester.pumpWidget(
        _host(
          const KumoAccordion(
            title: 'Advanced settings',
            child: Text('Hidden body'),
          ),
        ),
      );

      expect(tester.getSize(find.byType(SizeTransition)).height, 0);

      await tester.tap(find.text('Advanced settings'));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(SizeTransition)).height,
        greaterThan(0),
      );
    });

    testWidgets('can start expanded', (tester) async {
      await tester.pumpWidget(
        _host(
          const KumoAccordion(
            title: 'Advanced settings',
            initialExpanded: true,
            child: Text('Hidden body'),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(SizeTransition)).height,
        greaterThan(0),
      );

      await tester.tap(find.text('Advanced settings'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(SizeTransition)).height, 0);
    });
  });

  group('KumoSegmentedControl', () {
    testWidgets('renders every segment and reports the tapped one', (
      tester,
    ) async {
      String? picked;

      await tester.pumpWidget(
        _host(
          KumoSegmentedControl<String>(
            segments: const <String, String>{
              'overview': 'Overview',
              'dns': 'DNS',
              'workers': 'Workers',
            },
            selected: 'overview',
            onSelected: (value) => picked = value,
          ),
        ),
      );

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('DNS'), findsOneWidget);
      expect(find.text('Workers'), findsOneWidget);

      await tester.tap(find.text('Workers'));
      expect(picked, 'workers');

      await tester.tap(find.text('DNS'));
      expect(picked, 'dns');
    });
  });
}
