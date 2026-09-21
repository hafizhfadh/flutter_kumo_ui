import 'package:flutter/widgets.dart';

/// The raw Kumo color scale for the dark scheme.
///
/// A ten-step neutral ramp (`gray0`–`gray9`, darkest to lightest) plus the five
/// accent steps the components draw from. Semantic tokens in [KumoColors] are
/// defined in terms of these steps, so the scale is the single source of truth
/// for every value in the palette.
///
/// The ramp is a partial view of Cloudflare's `kumo-neutral` ramp — the steps
/// this port needs. `gray4`, `gray7` and `gray8` are not consumed by any
/// semantic token; they exist so the scale stays continuous and so consumer
/// code can interpolate or pick an intermediate tone.
///
/// The light scheme has its own scale, [KumoLightPalette], because these steps
/// were chosen for contrast on dark surfaces: `gray6` on a light canvas is
/// barely 2:1, so the ramp cannot simply be inverted.
///
/// Accent steps are the indicator tones. Where Kumo ships a separate
/// higher-contrast text variant, [KumoColors] carries it as its own token
/// ([KumoColors.dangerText] against [red5]).
abstract final class KumoPalette {
  /// Darkest step. The dark scheme's page canvas.
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

/// The raw Kumo color scale for the light scheme.
///
/// Mirrors [KumoPalette] step for step — `gray0` stays the darkest step and
/// `gray9` the lightest — so a semantic token reads the same index in both
/// schemes and only the scale changes underneath it.
///
/// The accents are **not** the same values as the dark scheme's. The brand
/// orange in particular is 2.6:1 on white, so it cannot carry text on a light
/// surface; [orange5] here is the same hue taken deep enough to clear the
/// 4.5:1 AA floor, and the other accents are darkened for the same reason.
///
/// As in the dark scale, `gray1`, `gray4` and `gray6` have no semantic
/// consumer: they keep the ramp continuous.
abstract final class KumoLightPalette {
  /// Darkest step. The light scheme's highest-emphasis text.
  static const Color gray0 = Color(0xFF111111);

  /// Intermediate step with no semantic consumer.
  static const Color gray1 = Color(0xFF3F3F46);

  /// Secondary labels and supporting copy.
  static const Color gray2 = Color(0xFF52525B);

  /// Lowest-emphasis text still clearing WCAG AA.
  static const Color gray3 = Color(0xFF5A5F6B);

  /// Intermediate step with no semantic consumer.
  static const Color gray4 = Color(0xFFA1A1AA);

  /// Hairline borders and dividers.
  static const Color gray5 = Color(0xFFD4D4D8);

  /// Intermediate step with no semantic consumer.
  static const Color gray6 = Color(0xFFE4E4E7);

  /// Recessed fill, used by inputs, toggles and badges.
  static const Color gray7 = Color(0xFFEAEAEA);

  /// The light scheme's page canvas.
  static const Color gray8 = Color(0xFFF7F7F7);

  /// Default component surface.
  static const Color gray9 = Color(0xFFFFFFFF);

  /// Brand orange, deepened so it clears AA as text on a light surface.
  static const Color orange5 = Color(0xFFB03A0A);

  /// Informational blue.
  static const Color blue5 = Color(0xFF0369A1);

  /// Error red, as an indicator tone.
  static const Color red5 = Color(0xFFDC2626);

  /// Success green.
  static const Color green5 = Color(0xFF036B4E);

  /// Warning amber.
  static const Color amber5 = Color(0xFF9A4D08);
}

/// Immutable set of color tokens describing the Kumo surface hierarchy.
///
/// Kumo names color by **role**, not by hue — `canvas`, `surface` and `border`
/// describe where a color is used, and its value can change per theme without
/// touching component code. Each token here resolves to a step of
/// [KumoPalette] (dark) or [KumoLightPalette] (light), so the raw scale and the
/// semantic layer stay in sync.
///
/// The unnamed constructor is the **dark** scheme, which mirrors Cloudflare's
/// Kumo dark surfaces: a near-black canvas, layered dark surfaces, hairline
/// borders and a single orange brand signal. Use [KumoColors.light] for the
/// light scheme, or [KumoColors.of] to pick one from a [Brightness].
///
/// Every text token clears WCAG 2.1 AA (4.5:1) against every background it is
/// painted on — `canvas`, `surface` and `subtleSurface` — and every non-text
/// token clears 3:1. Both schemes are verified by the same test suite. The
/// ratio measured against `canvas` / `surface` / `subtleSurface` is noted on
/// each token.
@immutable
class KumoColors {
  /// Creates the dark token set, defaulting every value to [KumoPalette].
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
    this.scrim = const Color(0x99000000),
    this.brightness = Brightness.dark,
  });

  /// The dark scheme, defaulting every value to [KumoPalette].
  ///
  /// Identical to the unnamed constructor, which carries the dark defaults for
  /// backward compatibility. Both exist so the two schemes read as peers:
  /// `KumoColors.dark(primary: brand)` and `KumoColors.light(primary: brand)`
  /// are the same shape.
  const KumoColors.dark({
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
    this.scrim = const Color(0x99000000),
    this.brightness = Brightness.dark,
  });

  /// The light scheme, defaulting every value to [KumoLightPalette].
  const KumoColors.light({
    this.canvas = KumoLightPalette.gray8,
    this.surface = KumoLightPalette.gray9,
    this.subtleSurface = KumoLightPalette.gray7,
    this.border = KumoLightPalette.gray5,
    this.primary = KumoLightPalette.orange5,
    this.focus = KumoLightPalette.gray0,
    this.textPrimary = KumoLightPalette.gray0,
    this.textSecondary = KumoLightPalette.gray2,
    this.textMuted = KumoLightPalette.gray3,
    this.info = KumoLightPalette.blue5,
    this.success = KumoLightPalette.green5,
    this.warning = KumoLightPalette.amber5,
    this.danger = KumoLightPalette.red5,
    this.dangerText = const Color(0xFFB91C1C),
    this.scrim = const Color(0x33000000),
    this.brightness = Brightness.light,
  });

  /// The token set for [brightness].
  ///
  /// ```dart
  /// final colors = KumoColors.of(MediaQuery.platformBrightnessOf(context));
  /// ```
  static KumoColors of(Brightness brightness) {
    return brightness == Brightness.light
        ? const KumoColors.light()
        : const KumoColors.dark();
  }

  /// Page background sitting behind every other surface.
  /// [KumoPalette.gray0] in dark, [KumoLightPalette.gray8] in light.
  final Color canvas;

  /// Default raised surface, one step above [canvas].
  /// [KumoPalette.gray1] in dark, [KumoLightPalette.gray9] in light.
  final Color surface;

  /// Recessed surface used as the fill for inputs, toggles and badges.
  /// [KumoPalette.gray2] in dark, [KumoLightPalette.gray7] in light.
  final Color subtleSurface;

  /// Hairline divider and resting control outline. Non-text, ~1.2:1 against
  /// [subtleSurface] by design so it stays a hairline rather than a hard edge.
  /// [KumoPalette.gray3] in dark, [KumoLightPalette.gray5] in light.
  final Color border;

  /// Brand signal and active control fill. 7.12:1 on the dark canvas and
  /// 5.67:1 on the light canvas, so it is safe as text in both schemes.
  /// [KumoPalette.orange5] in dark, [KumoLightPalette.orange5] in light.
  final Color primary;

  /// Focus ring color, matching Kumo's `--color-kumo-focus` token (not one of
  /// the ten ramp steps in either scheme). 15.55:1 on the dark canvas and
  /// 17.63:1 on the light canvas, well past the 3:1 WCAG 1.4.11 minimum for a
  /// focus indicator.
  final Color focus;

  /// High-emphasis text and icon color. 16.13:1 on the dark canvas, 17.63:1 on
  /// the light canvas. [KumoPalette.gray9] in dark, [KumoLightPalette.gray0]
  /// in light.
  final Color textPrimary;

  /// Low-emphasis text used for labels, hints and placeholders. 7.37:1 on the
  /// dark canvas, 7.22:1 on the light canvas. [KumoPalette.gray6] in dark,
  /// [KumoLightPalette.gray2] in light.
  final Color textSecondary;

  /// Lowest-emphasis text used for metadata that must recede further than
  /// [textSecondary], while still clearing AA. 5.76:1 on the dark canvas,
  /// 5.97:1 on the light canvas. [KumoPalette.gray5] in dark,
  /// [KumoLightPalette.gray3] in light.
  final Color textMuted;

  /// Informational status color, for neutral notices and info badges.
  /// 6.81:1 on the dark canvas, 5.54:1 on the light canvas, so it is safe as
  /// text. [KumoPalette.blue5] in dark, [KumoLightPalette.blue5] in light.
  final Color info;

  /// Positive status color for healthy and completed states. 9.82:1 on the
  /// dark canvas, 6.09:1 on the light canvas, so it is safe as text.
  /// [KumoPalette.green5] in dark, [KumoLightPalette.green5] in light.
  final Color success;

  /// Cautionary status color for degraded states. 8.79:1 on the dark canvas,
  /// 5.70:1 on the light canvas, so it is safe as text. [KumoPalette.amber5]
  /// in dark, [KumoLightPalette.amber5] in light.
  final Color warning;

  /// Destructive **indicator** color, for status dots, fills and outlines.
  /// 5.02:1 on the dark canvas, 4.51:1 on the light canvas — past the 3:1
  /// non-text minimum, but below the 4.5:1 text minimum on the recessed
  /// surfaces. Use [dangerText] wherever this color carries words.
  /// [KumoPalette.red5] in dark, [KumoLightPalette.red5] in light.
  final Color danger;

  /// Destructive **text** color, matching Kumo's `text-kumo-danger` token (a
  /// step lighter than [danger] in dark, a step deeper in light). 6.83:1 on
  /// the dark canvas, 6.04:1 on the light canvas.
  final Color dangerText;

  /// Barrier wash painted behind modals and bottom sheets.
  ///
  /// A 60% black in dark and a 20% black in light, so the surface behind the
  /// scrim dims without the dialog losing its contrast against it.
  final Color scrim;

  /// Which scheme this token set describes.
  ///
  /// Components resolve every value from the tokens themselves, so this is
  /// only needed by consumer code that has to branch on the mode — a status
  /// bar style, for example.
  final Brightness brightness;

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
        other.dangerText == dangerText &&
        other.scrim == scrim &&
        other.brightness == brightness;
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
    scrim,
    brightness,
  );
}
