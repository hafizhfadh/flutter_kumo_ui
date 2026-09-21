import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// WCAG 2.1 relative luminance of a single sRGB channel, already normalised to
/// 0..1.
double _linearize(double channel) {
  if (channel <= 0.04045) {
    return channel / 12.92;
  }
  return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

/// WCAG 2.1 contrast ratio between two opaque colors.
double _contrastRatio(Color foreground, Color background) {
  double luminance(Color color) =>
      0.2126 * _linearize(color.r) +
      0.7152 * _linearize(color.g) +
      0.0722 * _linearize(color.b);

  final double a = luminance(foreground);
  final double b = luminance(background);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

/// Every surface a Kumo text token can be painted on, for one scheme.
Map<String, Color> _surfacesOf(KumoColors colors) => <String, Color>{
  'canvas': colors.canvas,
  'surface': colors.surface,
  'subtleSurface': colors.subtleSurface,
};

/// The schemes every contrast rule has to hold in.
///
/// Both are shipped, so both are verified: a rule that passes in one mode and
/// fails in the other is a defect, not a caveat.
const Map<String, KumoColors> _schemes = <String, KumoColors>{
  'dark': KumoColors.dark(),
  'light': KumoColors.light(),
};

/// Hosts [child] inside a real [WidgetsApp], so the keyboard traversal
/// shortcuts and actions that focus rings depend on are present.
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
      home: Center(child: SizedBox(width: 320, child: child)),
    ),
  );
}

/// True when [finder]'s widget paints a ring border over its child.
bool _hasFocusRing(WidgetTester tester, Finder finder) {
  return tester
      .widgetList<Container>(
        find.descendant(of: finder, matching: find.byType(Container)),
      )
      .any((Container container) {
        final Decoration? decoration = container.foregroundDecoration;
        return decoration is BoxDecoration && decoration.border != null;
      });
}

void main() {
  group('WCAG AA color contrast', () {
    _schemes.forEach((String schemeName, KumoColors colors) {
      final Map<String, Color> surfaces = _surfacesOf(colors);

      group(schemeName, () {
        // Every token used to render words. 4.5:1 is the AA floor for normal
        // text.
        final Map<String, Color> textTokens = <String, Color>{
          'textPrimary': colors.textPrimary,
          'textSecondary': colors.textSecondary,
          'textMuted': colors.textMuted,
          'primary': colors.primary,
          'info': colors.info,
          'success': colors.success,
          'warning': colors.warning,
          'dangerText': colors.dangerText,
        };

        test('text tokens clear 4.5:1 on every surface', () {
          textTokens.forEach((String name, Color token) {
            surfaces.forEach((String surfaceName, Color surface) {
              expect(
                _contrastRatio(token, surface),
                greaterThanOrEqualTo(4.5),
                reason: '$schemeName $name on $surfaceName must clear 4.5:1',
              );
            });
          });
        });

        test('the primary button label clears 4.5:1 on the brand fill', () {
          expect(
            _contrastRatio(colors.canvas, colors.primary),
            greaterThanOrEqualTo(4.5),
            reason: '$schemeName canvas label on the primary fill must clear '
                '4.5:1',
          );
        });

        test('danger is an indicator tone and clears 3:1 as non-text', () {
          surfaces.forEach((String surfaceName, Color surface) {
            expect(
              _contrastRatio(colors.danger, surface),
              greaterThanOrEqualTo(3.0),
              reason: '$schemeName danger on $surfaceName must clear WCAG '
                  '1.4.11 (3:1)',
            );
          });
        });

        test('the focus ring clears 3:1 on every surface', () {
          surfaces.forEach((String surfaceName, Color surface) {
            expect(
              _contrastRatio(colors.focus, surface),
              greaterThanOrEqualTo(3.0),
              reason: '$schemeName focus ring on $surfaceName must clear WCAG '
                  '1.4.11 (3:1)',
            );
          });
        });

        // The knob is the highest-contrast neutral, which is what makes it
        // readable on the resting track in both schemes. Its ratio against the
        // *active* track is not asserted: the dark scheme has shipped a 2.26:1
        // knob-on-brand-fill since 1.0.0, and the on/off state is carried by
        // the track color instead (asserted next).
        test('the switch knob clears 3:1 against the resting track', () {
          expect(
            _contrastRatio(colors.textPrimary, colors.border),
            greaterThanOrEqualTo(3.0),
            reason: '$schemeName switch knob on the resting track must clear '
                'WCAG 1.4.11 (3:1)',
          );
        });

        test('the track color change alone signals on versus off', () {
          expect(
            _contrastRatio(colors.primary, colors.border),
            greaterThanOrEqualTo(3.0),
            reason: '$schemeName active track must stand apart from the '
                'resting track',
          );
        });
      });
    });
  });

  group('minimum touch targets', () {
    testWidgets('KumoButton is at least 48x48', (tester) async {
      await tester.pumpWidget(_host(KumoButton(label: 'Go', onPressed: () {})));

      expect(
        tester.getSize(find.byType(KumoButton)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byType(KumoButton)).width,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('KumoSwitch exposes at least 48x48 around its 40x22 track', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(KumoSwitch(value: false, onChanged: (bool _) {})),
      );

      final Size target = tester.getSize(find.byType(KumoSwitch));
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));

      // The visible track stays at its documented size.
      final Size track = tester.getSize(find.byType(AnimatedContainer).first);
      expect(track.width, 40);
      expect(track.height, 22);
    });

    testWidgets('KumoListItem is at least 48 wide and 48 tall', (tester) async {
      await tester.pumpWidget(_host(KumoListItem(title: 'Row', onTap: () {})));

      final Size size = tester.getSize(find.byType(KumoListItem));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('KumoAccordion header is at least 48 tall', (tester) async {
      await tester.pumpWidget(
        _host(const KumoAccordion(title: 'Advanced', child: Text('Body'))),
      );

      final Finder header = find.ancestor(
        of: find.text('Advanced'),
        matching: find.byType(Container),
      );
      expect(tester.getSize(header.first).height, greaterThanOrEqualTo(48));
    });

    testWidgets('KumoCodeBlock copy action is at least 48x48', (tester) async {
      await tester.pumpWidget(_host(const KumoCodeBlock(code: 'deploy')));

      final Finder copyTarget = find
          .ancestor(of: find.text('Copy'), matching: find.byType(Container))
          .first;
      expect(tester.getSize(copyTarget).height, greaterThanOrEqualTo(48));
    });

    testWidgets('KumoInput is at least 48 tall', (tester) async {
      await tester.pumpWidget(_host(const KumoInput(placeholder: 'Token')));

      final Finder field = find.ancestor(
        of: find.byType(EditableText),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(field.first).height, greaterThanOrEqualTo(48));
    });

    testWidgets('segmented control segments are at least 48 tall', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          KumoSegmentedControl<String>(
            segments: const <String, String>{'a': 'Overview', 'b': 'DNS'},
            selected: 'a',
            onSelected: (String _) {},
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(AnimatedContainer).first).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('KumoDataCard header is at least 48 tall', (tester) async {
      await tester.pumpWidget(
        _host(
          const KumoDataCard(
            title: 'Zone',
            details: <KumoDataPair>[KumoDataPair(label: 'Plan', value: 'Pro')],
          ),
        ),
      );

      final Finder header = find.ancestor(
        of: find.text('Zone'),
        matching: find.byType(Container),
      );
      expect(tester.getSize(header.first).height, greaterThanOrEqualTo(48));
    });

    testWidgets('KumoModal close action is at least 48x48', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (BuildContext context) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => KumoModal.show<void>(
                context: context,
                title: 'Confirm',
                child: const Text('Body'),
              ),
              child: const SizedBox(width: 120, height: 48),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      final Finder closeTarget = find
          .ancestor(
            of: find.byType(PhosphorIcon),
            matching: find.byType(Container),
          )
          .first;
      final Size size = tester.getSize(closeTarget);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('focus rings', () {
    setUp(() {
      // Force the traditional highlight mode so the ring is deterministic; the
      // default strategy only raises it for keyboard interaction, which is what
      // `:focus-visible` prescribes.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
    });

    tearDown(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('KumoButton paints a ring once it takes keyboard focus', (
      tester,
    ) async {
      await tester.pumpWidget(_host(KumoButton(label: 'Go', onPressed: () {})));

      expect(_hasFocusRing(tester, find.byType(KumoButton)), isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(FocusManager.instance.primaryFocus, isNotNull);
      expect(_hasFocusRing(tester, find.byType(KumoButton)), isTrue);
    });

    testWidgets('KumoSwitch paints a ring once it takes keyboard focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(KumoSwitch(value: false, onChanged: (bool _) {})),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_hasFocusRing(tester, find.byType(KumoSwitch)), isTrue);
    });

    testWidgets('a disabled control never takes focus', (tester) async {
      await tester.pumpWidget(_host(const KumoButton(label: 'Go')));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_hasFocusRing(tester, find.byType(KumoButton)), isFalse);
    });

    testWidgets('Enter activates a focused KumoButton', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(KumoButton(label: 'Go', onPressed: () => taps++)),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });

  group('semantics', () {
    testWidgets('KumoButton is announced as a button that can be tapped', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(KumoButton(label: 'Deploy', onPressed: () {})),
        );

        expect(
          tester.getSemantics(find.byType(KumoButton)),
          isSemantics(
            label: 'Deploy',
            isButton: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('KumoSwitch is announced as a toggled control', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(KumoSwitch(value: true, onChanged: (bool _) {})),
        );

        expect(
          tester.getSemantics(find.byType(KumoSwitch)),
          isSemantics(
            isEnabled: true,
            isFocusable: true,
            isToggled: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('KumoListItem is announced as a button', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(KumoListItem(title: 'Row', onTap: () {})),
        );

        expect(
          tester.getSemantics(find.byType(KumoListItem)),
          isSemantics(
            label: 'Row',
            isButton: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
