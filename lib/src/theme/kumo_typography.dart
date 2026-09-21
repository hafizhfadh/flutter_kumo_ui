import 'package:flutter/widgets.dart';

import 'kumo_colors.dart';

/// The Kumo type scale.
///
/// Every token is a complete [TextStyle] carrying size, weight and a text tone,
/// so a widget can apply one named style instead of rebuilding it inline.
///
/// These statics resolve to the **dark** scheme's tones, which is what makes
/// them safe as a default and keeps them stable for consumer code. A widget
/// painting inside a themed surface must use the scheme-aware styles instead:
/// [KumoTheme.textStylesOf] at a call site, or [resolve] when the [KumoColors]
/// is already in hand. Those carry the light scheme's tones when the light
/// scheme is active.
///
/// The size and weight of a token are identical in both schemes; only the tone
/// changes, so [KumoTextStyles] and these statics line up one to one.
abstract final class KumoTypography {
  /// Largest heading, used for screen titles. 24px, semibold, primary text.
  static const TextStyle h1 = TextStyle(
    color: KumoPalette.gray9,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  /// Section heading. 18px, medium-semibold, primary text.
  static const TextStyle h2 = TextStyle(
    color: KumoPalette.gray9,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  /// Default content text. 14px, regular, primary text.
  static const TextStyle body = TextStyle(
    color: KumoPalette.gray9,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Secondary content text for captions and supporting copy. 14px, regular,
  /// secondary text.
  static const TextStyle bodyMuted = TextStyle(
    color: KumoPalette.gray6,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Smallest supporting text, such as hints and table metadata. 12px,
  /// regular, secondary text.
  static const TextStyle caption = TextStyle(
    color: KumoPalette.gray6,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Monospaced text for code and identifiers. 12px, medium, primary text.
  static const TextStyle code = TextStyle(
    color: KumoPalette.gray9,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'monospace',
  );

  /// The type scale with [colors]' text tones applied.
  ///
  /// Headings, body text and code take [KumoColors.textPrimary]; the muted and
  /// caption tones take [KumoColors.textSecondary]. Sizes and weights are
  /// unchanged, so this is the same scale as the statics above, tinted for the
  /// scheme.
  static KumoTextStyles resolve(KumoColors colors) {
    return KumoTextStyles(
      h1: h1.copyWith(color: colors.textPrimary),
      h2: h2.copyWith(color: colors.textPrimary),
      body: body.copyWith(color: colors.textPrimary),
      bodyMuted: bodyMuted.copyWith(color: colors.textSecondary),
      caption: caption.copyWith(color: colors.textSecondary),
      code: code.copyWith(color: colors.textPrimary),
    );
  }
}

/// The Kumo type scale resolved against one [KumoColors] scheme.
///
/// Returned by [KumoTypography.resolve] and [KumoTheme.textStylesOf], so a
/// component applies one named style that already carries the scheme's text
/// tone. Pass the styles straight to [Text]; a `copyWith` on them is only
/// needed to override weight or size for a single element.
@immutable
class KumoTextStyles {
  /// Creates a resolved type scale. Prefer [KumoTypography.resolve].
  const KumoTextStyles({
    required this.h1,
    required this.h2,
    required this.body,
    required this.bodyMuted,
    required this.caption,
    required this.code,
  });

  /// Screen titles. [KumoTypography.h1] in [KumoColors.textPrimary].
  final TextStyle h1;

  /// Section headings. [KumoTypography.h2] in [KumoColors.textPrimary].
  final TextStyle h2;

  /// Default content text. [KumoTypography.body] in [KumoColors.textPrimary].
  final TextStyle body;

  /// Supporting copy. [KumoTypography.bodyMuted] in
  /// [KumoColors.textSecondary].
  final TextStyle bodyMuted;

  /// Hints and metadata. [KumoTypography.caption] in
  /// [KumoColors.textSecondary].
  final TextStyle caption;

  /// Code and identifiers. [KumoTypography.code] in [KumoColors.textPrimary].
  final TextStyle code;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is KumoTextStyles &&
        other.h1 == h1 &&
        other.h2 == h2 &&
        other.body == body &&
        other.bodyMuted == bodyMuted &&
        other.caption == caption &&
        other.code == code;
  }

  @override
  int get hashCode => Object.hash(h1, h2, body, bodyMuted, caption, code);
}
