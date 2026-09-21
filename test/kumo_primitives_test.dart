import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

/// Hosts [child] at a phone size, with optional keyboard insets.
Widget _host(
  Widget child, {
  Size size = const Size(400, 800),
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  return KumoTheme(
    child: MediaQuery(
      data: MediaQueryData(size: size, viewInsets: viewInsets),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      ),
    ),
  );
}

/// Hosts [child] inside a real [WidgetsApp], so keyboard traversal works.
Widget _keyboardHost(Widget child) {
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
  group('KumoScaffold', () {
    testWidgets('paints the canvas and renders header and body', (tester) async {
      await tester.pumpWidget(
        _host(
          const KumoScaffold(
            header: Text('Zones'),
            child: Text('Body content'),
          ),
        ),
      );

      expect(find.text('Zones'), findsOneWidget);
      expect(find.text('Body content'), findsOneWidget);
      expect(
        tester.widget<ColoredBox>(find.byType(ColoredBox).first).color,
        const KumoColors().canvas,
      );
    });

    testWidgets('scrolls the body by default', (tester) async {
      await tester.pumpWidget(
        _host(const KumoScaffold(child: Text('Body'))),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('leaves the body unscrolled when asked', (tester) async {
      await tester.pumpWidget(
        _host(const KumoScaffold(scrollable: false, child: Text('Body'))),
      );

      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('keeps the body above the software keyboard', (tester) async {
      const double keyboard = 300;
      await tester.pumpWidget(
        _host(
          const KumoScaffold(
            bottomBar: Text('Bottom'),
            child: Text('Field'),
          ),
          viewInsets: const EdgeInsets.only(bottom: keyboard),
        ),
      );

      // The bottom bar is pushed up by the inset, so nothing sits under it.
      expect(
        tester.getBottomLeft(find.text('Bottom')).dy,
        lessThanOrEqualTo(800 - keyboard),
      );
    });
  });

  group('KumoLoader', () {
    testWidgets('exposes an accessible label and paints', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_host(const KumoLoader()));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.bySemanticsLabel('Loading'), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('honours a custom size and label', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        // Centred, because a bare SizedBox under tight constraints is forced to
        // the parent's size; a real screen always gives it loose constraints.
        await tester.pumpWidget(
          _host(const Center(child: KumoLoader(size: 40, label: 'Deploying'))),
        );

        expect(find.bySemanticsLabel('Deploying'), findsOneWidget);
        expect(tester.getSize(find.byType(KumoLoader)).width, 40);
      } finally {
        handle.dispose();
      }
    });
  });

  group('KumoEmpty', () {
    testWidgets('renders the title, message and action', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          KumoEmpty(
            title: 'No zones yet',
            message: 'Add a zone to start routing traffic.',
            action: KumoButton(label: 'Add zone', onPressed: () => taps++),
          ),
        ),
      );

      expect(find.text('No zones yet'), findsOneWidget);
      expect(find.text('Add a zone to start routing traffic.'), findsOneWidget);

      await tester.tap(find.text('Add zone'));
      expect(taps, 1);
    });

    testWidgets('works without a message or action', (tester) async {
      await tester.pumpWidget(_host(const KumoEmpty()));

      expect(find.text('Nothing here yet'), findsOneWidget);
    });
  });

  group('KumoSkeleton', () {
    testWidgets('renders one bar per line', (tester) async {
      await tester.pumpWidget(
        _host(const SizedBox(width: 300, child: KumoSkeleton(lines: 3))),
      );

      expect(find.byType(Container), findsNWidgets(3));
    });
  });

  group('KumoLink', () {
    testWidgets('activates on tap and on Enter', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _keyboardHost(
          KumoLink(label: 'View docs', onPressed: () => taps++),
        ),
      );

      await tester.tap(find.text('View docs'));
      await tester.pumpAndSettle();
      expect(taps, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 2);
    });

    testWidgets('is inert without a callback', (tester) async {
      await tester.pumpWidget(_host(const KumoLink(label: 'Disabled')));

      await tester.tap(find.text('Disabled'), warnIfMissed: false);
      expect(find.text('Disabled'), findsOneWidget);
    });
  });

  group('KumoLabel', () {
    testWidgets('upper-cases the text and mutes when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              KumoLabel('Api token'),
              KumoLabel('Account id', isDisabled: true),
            ],
          ),
        ),
      );

      expect(find.text('API TOKEN'), findsOneWidget);

      final KumoColors colors = const KumoColors();
      expect(
        tester.widget<Text>(find.text('API TOKEN')).style?.color,
        colors.textSecondary,
      );
      expect(
        tester.widget<Text>(find.text('ACCOUNT ID')).style?.color,
        colors.textMuted,
      );
    });
  });

  group('KumoMeter', () {
    testWidgets('reports the percentage and clamps out-of-range values', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const SizedBox(width: 300, child: KumoMeter(value: 0.42))),
      );
      expect(find.text('42%'), findsOneWidget);

      await tester.pumpWidget(
        _host(const SizedBox(width: 300, child: KumoMeter(value: 4))),
      );
      expect(find.text('100%'), findsOneWidget);

      await tester.pumpWidget(
        _host(const SizedBox(width: 300, child: KumoMeter(value: -1))),
      );
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('fills with the tone colour', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: KumoMeter(value: 1, tone: KumoMeterTone.danger),
          ),
        ),
      );

      final Container fill = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(KumoMeter),
              matching: find.byType(Container),
            )
            .last,
      );
      expect(
        (fill.decoration! as BoxDecoration).color,
        const KumoColors().danger,
      );
    });
  });

  group('KumoInput multi-line', () {
    testWidgets('grows when maxLines is raised', (tester) async {
      await tester.pumpWidget(
        _host(
          const KumoInput(label: 'Notes', maxLines: 4, minLines: 2),
        ),
      );

      final EditableText field = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(field.maxLines, 4);
      expect(field.minLines, 2);
    });

    testWidgets('stays single-line by default', (tester) async {
      await tester.pumpWidget(_host(const KumoInput(label: 'Token')));

      expect(tester.widget<EditableText>(find.byType(EditableText)).maxLines, 1);
    });
  });
}
