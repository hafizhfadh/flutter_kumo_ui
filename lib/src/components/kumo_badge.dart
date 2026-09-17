import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import '../theme/kumo_typography.dart';

/// The status a [KumoBadge] reports.
enum KumoBadgeVariant {
  /// Informational, tinted with the palette info blue.
  info,

  /// Healthy or completed, tinted with the palette success green.
  success,

  /// Needs attention, tinted with the palette warning amber.
  warning,

  /// Failed or destructive, tinted with the AA-safe error red.
  error,

  /// No status, tinted with the secondary text tone.
  neutral,
}

/// A compact pill tag for metadata, plan types and status flags.
///
/// The label is set in 11px monospace so tags of different words still line up
/// in a table column. Every variant tint clears WCAG AA as text against the
/// badge fill.
class KumoBadge extends StatelessWidget {
  /// Creates a Kumo badge.
  const KumoBadge({
    super.key,
    required this.label,
    this.variant = KumoBadgeVariant.neutral,
    this.icon,
  });

  /// Tag text.
  final String label;

  /// Which status this badge reports.
  final KumoBadgeVariant variant;

  /// Optional Phosphor glyph shown before [label].
  final PhosphorIconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final Color accent = switch (variant) {
      KumoBadgeVariant.info => colors.info,
      KumoBadgeVariant.success => colors.success,
      KumoBadgeVariant.warning => colors.warning,
      // Badge text needs the 4.5:1 text variant, not the indicator red.
      KumoBadgeVariant.error => colors.dangerText,
      KumoBadgeVariant.neutral => colors.textSecondary,
    };
    final PhosphorIconData? glyph = icon;

    return Container(
      decoration: BoxDecoration(
        color: colors.subtleSurface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            PhosphorIcon(glyph, size: 12, color: accent),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KumoTypography.code.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
