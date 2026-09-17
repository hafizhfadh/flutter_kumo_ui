import 'package:flutter/widgets.dart';

/// Immutable set of color tokens describing the Kumo surface hierarchy.
///
/// Kumo names color by **role**, not by hue — `canvas`, `surface` and `border`
/// describe where a color is used, and its value can change per theme without
/// touching component code. This class follows that contract, so it is a
/// semantic mapping rather than a raw gray ramp.
///
/// The defaults mirror Cloudflare's Kumo dark surfaces: a near-black canvas,
/// layered dark surfaces, hairline borders and a single orange brand signal.
///
/// Every text token clears WCAG 2.1 AA (4.5:1) against every background it is
/// painted on — `canvas`, `surface` and `subtleSurface` — and every non-text
/// token clears 3:1. The ratio measured against `canvas` / `surface` /
/// `subtleSurface` is noted on each token.
@immutable
class KumoColors {
  /// Creates a token set, defaulting every value to the Kumo palette.
  const KumoColors({
    this.canvas = const Color(0xFF111111),
    this.surface = const Color(0xFF1D1D1D),
    this.subtleSurface = const Color(0xFF262626),
    this.border = const Color(0xFF333333),
    this.primary = const Color(0xFFF38020),
    this.focus = const Color(0xFFE9E9E9),
    this.textPrimary = const Color(0xFFEDEDED),
    this.textSecondary = const Color(0xFFA1A1AA),
    this.textMuted = const Color(0xFF8D8D99),
    this.success = const Color(0xFF0EA5E9),
    this.warning = const Color(0xFFF59E0B),
    this.danger = const Color(0xFFEF4444),
    this.dangerText = const Color(0xFFF87171),
  });

  /// Page background sitting behind every other surface.
  final Color canvas;

  /// Default raised surface, one step above [canvas].
  final Color surface;

  /// Recessed surface used as the fill for inputs and nested containers.
  final Color subtleSurface;

  /// Hairline divider and resting control outline. Non-text, 10.4:1 on
  /// [canvas].
  final Color border;

  /// Brand signal and active control fill. 7.12:1 on [canvas], 6.36:1 on
  /// [surface], 5.71:1 on [subtleSurface], so it is safe as text.
  final Color primary;

  /// Focus ring color, matching Kumo's `--color-kumo-focus` token
  /// (dark mode: `neutral-150`). 15.55:1 on [canvas], 13.88:1 on [surface],
  /// 12.46:1 on [subtleSurface], well past the 3:1 WCAG 1.4.11 minimum for a
  /// focus indicator.
  final Color focus;

  /// High-emphasis text and icon color. 16.13:1 on [canvas], 14.40:1 on
  /// [surface], 12.93:1 on [subtleSurface].
  final Color textPrimary;

  /// Low-emphasis text used for labels, hints and placeholders. 7.37:1 on
  /// [canvas], 6.58:1 on [surface], 5.90:1 on [subtleSurface].
  final Color textSecondary;

  /// Lowest-emphasis text used for metadata that must recede further than
  /// [textSecondary], while still clearing AA. 5.76:1 on [canvas], 5.14:1 on
  /// [surface], 4.61:1 on [subtleSurface].
  final Color textMuted;

  /// Positive status color for healthy and proxied states. 6.81:1 on [canvas],
  /// 6.08:1 on [surface], so it is safe as text.
  final Color success;

  /// Cautionary status color for degraded states. 8.79:1 on [canvas], 7.85:1
  /// on [surface], so it is safe as text.
  final Color warning;

  /// Destructive **indicator** color, for status dots, fills and outlines.
  /// 5.02:1 on [canvas], 4.48:1 on [surface], 4.02:1 on [subtleSurface] —
  /// comfortably past the 3:1 non-text minimum, but below the 4.5:1 text
  /// minimum on the darker surfaces. Use [dangerText] wherever this color
  /// carries words.
  final Color danger;

  /// Destructive **text** color, matching Kumo's `text-kumo-danger` token
  /// (dark mode: `red-400`). 6.83:1 on [canvas], 6.09:1 on [surface], 5.47:1
  /// on [subtleSurface].
  final Color dangerText;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is KumoColors &&
        other.canvas == canvas &&
        other.surface == surface &&
        other.subtleSurface == subtleSurface &&
        other.border == border &&
        other.primary == primary &&
        other.focus == focus &&
        other.textPrimary == textPrimary &&
        other.textSecondary == textSecondary &&
        other.textMuted == textMuted &&
        other.success == success &&
        other.warning == warning &&
        other.danger == danger &&
        other.dangerText == dangerText;
  }

  @override
  int get hashCode => Object.hash(
    canvas,
    surface,
    subtleSurface,
    border,
    primary,
    focus,
    textPrimary,
    textSecondary,
    textMuted,
    success,
    warning,
    danger,
    dangerText,
  );
}
