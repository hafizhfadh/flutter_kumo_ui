import 'package:flutter/widgets.dart';

/// The Kumo type scale.
///
/// Every token is a complete [TextStyle] carrying size, weight and the default
/// [KumoColors] text tone, so a widget can apply one named style instead of
/// rebuilding it inline. Components that must follow an overridden palette
/// still read surfaces and accents from `KumoTheme.of(context)`.
abstract final class KumoTypography {
  /// Largest heading, used for screen titles. 24px, semibold, primary text.
  static const TextStyle h1 = TextStyle(
    color: Color(0xFFEDEDED),
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  /// Section heading. 18px, medium-semibold, primary text.
  static const TextStyle h2 = TextStyle(
    color: Color(0xFFEDEDED),
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  /// Default content text. 14px, regular, primary text.
  static const TextStyle body = TextStyle(
    color: Color(0xFFEDEDED),
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Secondary content text for captions and supporting copy. 14px, regular,
  /// secondary text.
  static const TextStyle bodyMuted = TextStyle(
    color: Color(0xFFA1A1AA),
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Smallest supporting text, such as hints and table metadata. 12px,
  /// regular, secondary text.
  static const TextStyle caption = TextStyle(
    color: Color(0xFFA1A1AA),
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Monospaced text for code and identifiers. 12px, medium, primary text.
  static const TextStyle code = TextStyle(
    color: Color(0xFFEDEDED),
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'monospace',
  );
}
