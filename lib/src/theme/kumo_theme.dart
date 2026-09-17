import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'kumo_colors.dart';

export 'kumo_colors.dart';

/// Exposes [KumoColors] to a subtree of Kumo widgets.
///
/// Wrap an app or a screen with [KumoTheme] to override the palette; every Kumo
/// component resolves its tokens with [KumoTheme.of].
class KumoTheme extends InheritedWidget {
  /// Creates a theme that provides [colors] to its descendants.
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

  @override
  bool updateShouldNotify(KumoTheme oldWidget) => colors != oldWidget.colors;
}
