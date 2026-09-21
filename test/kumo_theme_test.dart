import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

/// Hosts [child] under [colors] at a phone width.
Widget _host(Widget child, KumoColors colors) {
  return KumoTheme(
    colors: colors,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 360, child: child)),
      ),
    ),
  );
}

/// Hosts a [KumoButton] trigger inside a real [WidgetsApp], so the toast
/// manager has an [Overlay] to attach to.
Widget _appHost(KumoColors colors, void Function(BuildContext) onTap) {
  return KumoTheme(
    colors: colors,
    child: WidgetsApp(
      color: colors.canvas,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => builder(context),
          ),
      home: Builder(
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 200,
            child: KumoButton(
              label: 'Toast',
              onPressed: () => onTap(context),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The painted color of the first [Text] labelled [label].
///
/// The toast test can have several banners on screen at once, so this reads the
/// first match rather than asserting uniqueness.
Color _textColor(WidgetTester tester, String label) =>
    tester.widgetList<Text>(find.text(label)).first.style!.color!;

void main() {
  // Both schemes are shipped, so both are painted here. These tests are the
  // regression guard for the light scheme: each one fails if a component
  // reaches for a dark-only text tone instead of the resolved styles.
  const Map<String, KumoColors> schemes = <String, KumoColors>{
    'dark': KumoColors.dark(),
    'light': KumoColors.light(),
  };

  schemes.forEach((String scheme, KumoColors colors) {
    group('$scheme scheme paints its own text tones', () {
      testWidgets('KumoHeader', (tester) async {
        await tester.pumpWidget(
          _host(const KumoHeader(title: 'Zones', subtitle: '3 active'), colors),
        );

        expect(_textColor(tester, 'Zones'), colors.textPrimary);
        expect(_textColor(tester, '3 active'), colors.textSecondary);
      });

      testWidgets('KumoAccordion', (tester) async {
        await tester.pumpWidget(
          _host(
            const KumoAccordion(title: 'Advanced settings', child: Text('Body')),
            colors,
          ),
        );

        expect(_textColor(tester, 'Advanced settings'), colors.textPrimary);
      });

      testWidgets('KumoCodeBlock', (tester) async {
        await tester.pumpWidget(
          _host(
            const KumoCodeBlock(code: 'wrangler deploy', language: 'bash'),
            colors,
          ),
        );

        expect(_textColor(tester, 'wrangler deploy'), colors.textPrimary);
        expect(_textColor(tester, 'bash'), colors.textSecondary);
      });

      testWidgets('KumoListGroup', (tester) async {
        await tester.pumpWidget(
          _host(
            const KumoListGroup(
              title: 'Zone settings',
              children: <Widget>[
                KumoListItem(title: 'DNS records', subtitle: '42 records'),
              ],
            ),
            colors,
          ),
        );

        expect(_textColor(tester, 'DNS records'), colors.textPrimary);
        expect(_textColor(tester, '42 records'), colors.textSecondary);
        expect(_textColor(tester, 'ZONE SETTINGS'), colors.textMuted);
      });

      testWidgets('KumoDataCard', (tester) async {
        await tester.pumpWidget(
          _host(
            const KumoDataCard(
              title: 'example.com',
              subtitle: 'Zone',
              initiallyExpanded: true,
              details: <KumoDataPair>[
                KumoDataPair(label: 'Plan', value: 'Pro'),
              ],
            ),
            colors,
          ),
        );

        expect(_textColor(tester, 'example.com'), colors.textPrimary);
        expect(_textColor(tester, 'Zone'), colors.textSecondary);
        expect(_textColor(tester, 'Plan'), colors.textMuted);
        expect(_textColor(tester, 'Pro'), colors.textPrimary);
      });

      testWidgets('KumoToast', (tester) async {
        await tester.pumpWidget(
          _host(
            const KumoToast(
              title: 'Worker deployed',
              message: 'Live on 3 routes',
            ),
            colors,
          ),
        );

        expect(_textColor(tester, 'Worker deployed'), colors.textPrimary);
        expect(_textColor(tester, 'Live on 3 routes'), colors.textSecondary);
      });
    });
  });

  group('scheme switching', () {
    testWidgets('repaints a widget when the scheme changes', (tester) async {
      await tester.pumpWidget(
        _host(const KumoHeader(title: 'Zones'), const KumoColors.dark()),
      );
      expect(_textColor(tester, 'Zones'), const KumoColors.dark().textPrimary);

      await tester.pumpWidget(
        _host(const KumoHeader(title: 'Zones'), const KumoColors.light()),
      );
      expect(_textColor(tester, 'Zones'), const KumoColors.light().textPrimary);
    });

    testWidgets('textStylesOf resolves against the scheme in scope', (
      tester,
    ) async {
      late KumoTextStyles styles;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (BuildContext context) {
              styles = KumoTheme.textStylesOf(context);
              return const SizedBox.shrink();
            },
          ),
          const KumoColors.light(),
        ),
      );

      expect(styles.body.color, const KumoColors.light().textPrimary);
      expect(styles.bodyMuted.color, const KumoColors.light().textSecondary);
    });
  });

  group('KumoToastManager', () {
    // The toast overlay layer outlives individual toasts. Before 1.1.0 it
    // captured the colors of whichever toast opened it, so a toast shown after
    // a mode switch kept painting in the previous scheme.
    testWidgets('a reused layer follows a scheme change', (tester) async {
      void trigger(BuildContext context) => KumoToastManager.show(
        context,
        title: 'Worker deployed',
        message: 'Live on 3 routes',
      );

      await tester.pumpWidget(_appHost(const KumoColors.dark(), trigger));
      await tester.tap(find.text('Toast'));
      await tester.pump();

      expect(
        _textColor(tester, 'Worker deployed'),
        const KumoColors.dark().textPrimary,
      );

      // Keep the first toast up, switch the app scheme, then show another. The
      // layer is reused, and has to follow the new scheme.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(_appHost(const KumoColors.light(), trigger));
      await tester.tap(find.text('Toast'));
      await tester.pump();

      expect(
        _textColor(tester, 'Worker deployed'),
        const KumoColors.light().textPrimary,
      );

      // Drain the auto-dismiss timers and tear the layer down.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(KumoToastManager.activeCount, 0);
    });
  });
}
