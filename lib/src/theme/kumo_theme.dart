import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'kumo_colors.dart';
import 'kumo_typography.dart';

export 'kumo_colors.dart';
export 'kumo_typography.dart';

/// Which scheme an app hands to its [KumoTheme].
///
/// Mirrors Material's `themeMode`: [system] is the default, so an app follows
/// the platform unless it is told otherwise.
enum KumoThemeMode {
  /// Follow the platform setting, and repaint when it changes.
  system,

  /// Always the light scheme.
  light,

  /// Always the dark scheme.
  dark,
}

/// Exposes [KumoColors] to a subtree of Kumo widgets.
///
/// Wrap an app or a screen with [KumoTheme] to choose the color scheme; every
/// Kumo component resolves its tokens with [KumoTheme.of].
///
/// ```dart
/// KumoTheme(
///   colors: KumoColors.of(MediaQuery.platformBrightnessOf(context)),
///   child: WidgetsApp(...),
/// )
/// ```
///
/// The theme does not pick a mode on its own. The app owns that decision, so it
/// can follow the platform, a stored preference, or a user-facing switch, and
/// hand the result to [colors].
class KumoTheme extends InheritedWidget {
  /// Creates a theme that provides [colors] to its descendants.
  ///
  /// Defaults to the dark scheme, matching [KumoColors]' own default.
  const KumoTheme({
    super.key,
    this.colors = const KumoColors(),
    required super.child,
  });

  /// Token set applied to every descendant Kumo widget.
  final KumoColors colors;

  /// Guards the mobile and native-desktop platform boundary.
  ///
  /// `kumo_ui` deliberately does not support Flutter Web, so that it cannot be
  /// used to re-implement Cloudflare's canonical React/Tailwind Kumo UI for the
  /// browser. Call this from `main` to fail fast, or rely on [of] which invokes
  /// it on every token read.
  ///
  /// Throws an [UnsupportedError] when [kIsWeb] is true.
  static void ensureSupportedPlatform() {
    if (kIsWeb) {
      throw UnsupportedError(
        'kumo_ui targets Android, iOS, macOS, Linux and Windows only. '
        'Flutter Web is not supported, to preserve Cloudflare\'s canonical '
        'Kumo UI web boundaries.',
      );
    }
  }

  /// Returns the [KumoColors] of the nearest [KumoTheme] ancestor.
  ///
  /// Falls back to the default Kumo palette when no theme is present, so
  /// components render correctly without an explicit [KumoTheme].
  ///
  /// Every read re-asserts the platform guardrail through
  /// [ensureSupportedPlatform], so web builds fail loudly instead of rendering
  /// an unofficial Kumo surface.
  static KumoColors of(BuildContext context) {
    ensureSupportedPlatform();
    return context.dependOnInheritedWidgetOfExactType<KumoTheme>()?.colors ??
        const KumoColors();
  }

  /// The type scale tinted for the scheme currently in scope.
  ///
  /// This is what a widget paints with: unlike the [KumoTypography] statics,
  /// which carry the dark scheme's tones, these follow whatever [colors] the
  /// nearest [KumoTheme] provides, so text stays legible in both schemes.
  ///
  /// The resolved set is memoized per [KumoColors] instance.
  static KumoTextStyles textStylesOf(BuildContext context) {
    final KumoColors colors = of(context);
    return _resolved[colors] ??= KumoTypography.resolve(colors);
  }

  static final Expando<KumoTextStyles> _resolved =
      Expando<KumoTextStyles>('kumoTextStyles');

  @override
  bool updateShouldNotify(KumoTheme oldWidget) => colors != oldWidget.colors;
}
