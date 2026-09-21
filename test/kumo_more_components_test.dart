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

/// Hosts [child] in a real [WidgetsApp], so an overlay exists for the tooltip.
Widget _appHost(Widget child) {
  return KumoTheme(
    child: WidgetsApp(
      color: const Color(0xFF111111),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          ),
      home: Center(child: SizedBox(width: 320, child: child)),
    ),
  );
}

void main() {
  group('KumoRadio', () {
    testWidgets('reports its value when chosen', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              KumoRadio<String>(
                value: 'free',
                groupValue: 'pro',
                label: 'Free',
                onChanged: (String value) => picked = value,
              ),
              KumoRadio<String>(
                value: 'pro',
                groupValue: 'pro',
                label: 'Pro',
                onChanged: (String value) => picked = value,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Free'));
      expect(picked, 'free');
    });

    testWidgets('announces selection in a mutually exclusive group', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            KumoRadio<String>(
              value: 'pro',
              groupValue: 'pro',
              label: 'Pro',
              onChanged: (String _) {},
            ),
          ),
        );

        expect(
          tester.getSemantics(find.byType(KumoRadio<String>)),
          isSemantics(
            isChecked: true,
            isInMutuallyExclusiveGroup: true,
            isEnabled: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('is inert when disabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          KumoRadio<String>(
            value: 'free',
            groupValue: 'pro',
            label: 'Free',
            isDisabled: true,
            onChanged: (String _) => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Free'), warnIfMissed: false);
      expect(taps, 0);
    });
  });

  group('KumoBanner', () {
    testWidgets('renders the title, message and action', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _host(
          KumoBanner(
            kind: KumoBannerKind.error,
            title: 'Deploy failed',
            message: 'The Worker could not be published.',
            action: KumoButton(label: 'Retry', onPressed: () => retries++),
          ),
        ),
      );

      expect(find.text('Deploy failed'), findsOneWidget);
      expect(find.text('The Worker could not be published.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('paints the kind accent as a non-text indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const KumoBanner(message: 'Quota nearly spent', kind: KumoBannerKind.warning)),
      );

      final PhosphorIcon icon = tester.widget<PhosphorIcon>(
        find.byType(PhosphorIcon),
      );
      expect(icon.color, const KumoColors().warning);
    });

    testWidgets('dismisses when it has a close action', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        _host(
          KumoBanner(message: 'Heads up', onDismiss: () => dismissed++),
        ),
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.x));
      expect(dismissed, 1);
    });

    testWidgets('renders no close action without a callback', (tester) async {
      await tester.pumpWidget(_host(const KumoBanner(message: 'Heads up')));

      expect(find.byIcon(PhosphorIconsRegular.x), findsNothing);
    });
  });

  group('KumoSensitiveInput', () {
    testWidgets('masks by default and reveals on demand', (tester) async {
      await tester.pumpWidget(
        _host(const KumoSensitiveInput(label: 'Api token')),
      );

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
      expect(find.byIcon(PhosphorIconsRegular.eye), findsOneWidget);

      await tester.tap(find.byIcon(PhosphorIconsRegular.eye));
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse,
      );
      expect(find.byIcon(PhosphorIconsRegular.eyeSlash), findsOneWidget);
    });
  });

  group('KumoTooltip', () {
    testWidgets('shows the bubble after a long press and hides on release', (
      tester,
    ) async {
      await tester.pumpWidget(
        _appHost(
          const KumoTooltip(
            message: 'Publishes the Worker',
            child: KumoButton(label: 'Deploy'),
          ),
        ),
      );

      expect(find.text('Publishes the Worker'), findsNothing);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Deploy')),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Publishes the Worker'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Publishes the Worker'), findsNothing);
    });

    testWidgets('exposes the message as a semantics tooltip', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _appHost(
            const KumoTooltip(
              message: 'Publishes the Worker',
              child: KumoButton(label: 'Deploy'),
            ),
          ),
        );

        expect(
          tester.getSemantics(find.bySemanticsLabel('Deploy')),
          isSemantics(tooltip: 'Publishes the Worker'),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
