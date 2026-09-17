import 'package:flutter/widgets.dart';

/// The raw Kumo color scale.
///
/// A ten-step neutral ramp (`gray0`–`gray9`, darkest to lightest) plus the five
/// accent steps the components draw from. Semantic tokens in [KumoColors] are
/// defined in terms of these steps, so the scale is the single source of truth
/// for every value in the palette.
///
/// The ramp is a partial view of Cloudflare's `kumo-neutral` ramp — the steps
/// this dark-only port needs. `gray4`, `gray7` and `gray8` are not consumed by
/// any semantic token; they exist so the scale stays continuous and so consumer
/// code can interpolate or pick an intermediate tone.
///
/// Accent steps are the indicator tones. Where Kumo ships a separate
/// higher-contrast text variant, [KumoColors] carries it as its own token
/// ([KumoColors.dangerText] against [red5]).
abstract final class KumoPalette {
  /// Darkest step. The page canvas.
  static const Color gray0 = Color(0xFF111111);

  /// Default component surface.
  static const Color gray1 = Color(0xFF1D1D1D);

  /// Recessed fill, used by inputs, toggles and badges.
  static const Color gray2 = Color(0xFF262626);

  /// Hairline borders and dividers.
  static const Color gray3 = Color(0xFF333333);

  /// Intermediate step with no semantic consumer.
  static const Color gray4 = Color(0xFF4D4D4D);

  /// Lowest-emphasis text still clearing WCAG AA.
  static const Color gray5 = Color(0xFF8D8D99);

  /// Secondary labels and supporting copy.
  static const Color gray6 = Color(0xFFA1A1AA);

  /// Intermediate step with no semantic consumer.
  static const Color gray7 = Color(0xFFC7C7CE);

  /// Intermediate step with no semantic consumer.
  static const Color gray8 = Color(0xFFDCDCE0);

  /// Highest-emphasis text and icons.
  static const Color gray9 = Color(0xFFEDEDED);

  /// Brand orange.
  static const Color orange5 = Color(0xFFF38020);

  /// Informational blue.
  static const Color blue5 = Color(0xFF0EA5E9);

  /// Error red, as an indicator tone.
  static const Color red5 = Color(0xFFEF4444);

  /// Success green.
  static const Color green5 = Color(0xFF34D399);

  /// Warning amber.
  static const Color amber5 = Color(0xFFF59E0B);
}

/// Immutable set of color tokens describing the Kumo surface hierarchy.
///
/// Kumo names color by **role**, not by hue — `canvas`, `surface` and `border`
/// describe where a color is used, and its value can change per theme without
/// touching component code. Each token here resolves to a step of
/// [KumoPalette], so the raw scale and the semantic layer stay in sync.
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
    this.canvas = KumoPalette.gray0,
    this.surface = KumoPalette.gray1,
    this.subtleSurface = KumoPalette.gray2,
    this.border = KumoPalette.gray3,
    this.primary = KumoPalette.orange5,
    this.focus = const Color(0xFFE9E9E9),
    this.textPrimary = KumoPalette.gray9,
    this.textSecondary = KumoPalette.gray6,
    this.textMuted = KumoPalette.gray5,
    this.info = KumoPalette.blue5,
    this.success = KumoPalette.green5,
    this.warning = KumoPalette.amber5,
    this.danger = KumoPalette.red5,
    this.dangerText = const Color(0xFFF87171),
  });

  /// Page background sitting behind every other surface. [KumoPalette.gray0].
  final Color canvas;

  /// Default raised surface, one step above [canvas].
  /// [KumoPalette.gray1].
  final Color surface;

  /// Recessed surface used as the fill for inputs, toggles and badges.
  /// [KumoPalette.gray2].
  final Color subtleSurface;

  /// Hairline divider and resting control outline. Non-text, 1.20:1 against
  /// [subtleSurface] by design so it stays a hairline rather than a hard edge.
  /// [KumoPalette.gray3].
  final Color border;

  /// Brand signal and active control fill. 7.12:1 on [canvas], 6.36:1 on
  /// [surface], 5.71:1 on [subtleSurface], so it is safe as text.
  /// [KumoPalette.orange5].
  final Color primary;

  /// Focus ring color, matching Kumo's `--color-kumo-focus` token
  /// (dark mode: `neutral-150`, which is not one of the ten ramp steps).
  /// 15.55:1 on [canvas], 13.88:1 on [surface], 12.46:1 on [subtleSurface],
  /// well past the 3:1 WCAG 1.4.11 minimum for a focus indicator.
  final Color focus;

  /// High-emphasis text and icon color. 16.13:1 on [canvas], 14.40:1 on
  /// [surface], 12.93:1 on [subtleSurface]. [KumoPalette.gray9].
  final Color textPrimary;

  /// Low-emphasis text used for labels, hints and placeholders. 7.37:1 on
  /// [canvas], 6.58:1 on [surface], 5.90:1 on [subtleSurface].
  /// [KumoPalette.gray6].
  final Color textSecondary;

  /// Lowest-emphasis text used for metadata that must recede further than
  /// [textSecondary], while still clearing AA. 5.76:1 on [canvas], 5.14:1 on
  /// [surface], 4.61:1 on [subtleSurface]. [KumoPalette.gray5].
  final Color textMuted;

  /// Informational status color, for neutral notices and info badges.
  /// 6.81:1 on [canvas], 6.08:1 on [surface], 5.46:1 on [subtleSurface], so it
  /// is safe as text. [KumoPalette.blue5].
  final Color info;

  /// Positive status color for healthy and completed states. 9.82:1 on
  /// [canvas], 8.77:1 on [surface], 7.87:1 on [subtleSurface], so it is safe as
  /// text. [KumoPalette.green5].
  final Color success;

  /// Cautionary status color for degraded states. 8.79:1 on [canvas], 7.85:1
  /// on [surface], 7.05:1 on [subtleSurface], so it is safe as text.
  /// [KumoPalette.amber5].
  final Color warning;

  /// Destructive **indicator** color, for status dots, fills and outlines.
  /// 5.02:1 on [canvas], 4.48:1 on [surface], 4.02:1 on [subtleSurface] —
  /// comfortably past the 3:1 non-text minimum, but below the 4.5:1 text
  /// minimum on the darker surfaces. Use [dangerText] wherever this color
  /// carries words. [KumoPalette.red5].
  final Color danger;

  /// Destructive **text** color, matching Kumo's `text-kumo-danger` token
  /// (dark mode: `red-400`, a step lighter than [danger]). 6.83:1 on [canvas],
  /// 6.09:1 on [surface], 5.47:1 on [subtleSurface].
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
        other.info == info &&
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
    info,
    success,
    warning,
    danger,
    dangerText,
  );
}
