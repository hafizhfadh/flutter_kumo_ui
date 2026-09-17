import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';

Widget _host(Widget child) {
  return KumoTheme(
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 320, child: child)),
      ),
    ),
  );
}

BoxDecoration _inputDecoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(KumoInput),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('KumoInput', () {
    testWidgets('renders an uppercase label and the placeholder hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const KumoInput(label: 'Api token', placeholder: 'Paste token')),
      );

      expect(find.text('API TOKEN'), findsOneWidget);
      expect(find.text('Paste token'), findsOneWidget);
    });

    testWidgets('hides the placeholder once the field holds text', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(KumoInput(controller: controller, placeholder: 'Paste token')),
      );
      expect(find.text('Paste token'), findsOneWidget);

      controller.text = 'abc';
      await tester.pump();

      expect(find.text('Paste token'), findsNothing);
    });

    testWidgets('renders the error message and reports edits', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final edits = <String>[];

      await tester.pumpWidget(
        _host(
          KumoInput(
            controller: controller,
            errorMessage: 'Token is required',
            onChanged: edits.add,
          ),
        ),
      );

      expect(find.text('Token is required'), findsOneWidget);
      expect(
        (_inputDecoration(tester).border! as Border).top.color,
        const KumoColors().danger,
      );

      await tester.enterText(find.byType(EditableText), 'secret');
      expect(edits, <String>['secret']);
    });

    testWidgets('switches the outline to the brand signal on focus', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const KumoInput(placeholder: 'Token')));
      expect(
        (_inputDecoration(tester).border! as Border).top.color,
        const KumoColors().border,
      );

      await tester.tap(find.byType(EditableText));
      await tester.pump();

      expect(
        (_inputDecoration(tester).border! as Border).top.color,
        const KumoColors().primary,
      );
    });
  });

  group('KumoSwitch', () {
    testWidgets('reports the flipped value when tapped', (tester) async {
      bool? next;
      await tester.pumpWidget(
        _host(KumoSwitch(value: false, onChanged: (value) => next = value)),
      );

      await tester.tap(find.byType(KumoSwitch));

      expect(next, isTrue);
    });

    testWidgets('ignores taps while disabled', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          KumoSwitch(value: false, onChanged: (_) => calls++, isDisabled: true),
        ),
      );

      await tester.tap(find.byType(KumoSwitch), warnIfMissed: false);

      expect(calls, 0);
    });
  });
}
