import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import '../theme/kumo_typography.dart';
import 'kumo_focusable.dart';

/// Visual treatments for [KumoButton].
enum KumoButtonVariant {
  /// Brand-filled button, reserved for the primary action of a screen.
  primary,

  /// Outlined button, used for every secondary action.
  secondary,
}

/// A tap target styled with Kumo tokens.
///
/// The button enforces a 48px minimum height so it stays a comfortable touch
/// target on phones, and drops to a muted treatment when [onPressed] is null.
class KumoButton extends StatelessWidget {
  /// Creates a Kumo button.
  const KumoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = KumoButtonVariant.primary,
  });

  /// Text rendered inside the button.
  final String label;

  /// Called when the button is tapped. A null callback renders the button in
  /// its disabled state and makes it inert.
  final VoidCallback? onPressed;

  /// Optional Phosphor glyph shown before [label].
  final PhosphorIconData? icon;

  /// Visual treatment applied when the button is enabled.
  final KumoButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final glyph = icon;
    final isEnabled = onPressed != null;
    final isPrimary = variant == KumoButtonVariant.primary;

    final Color fill;
    final Color foreground;
    final Color outline;
    if (!isEnabled) {
      fill = colors.subtleSurface;
      foreground = colors.textMuted;
      outline = colors.border;
    } else if (isPrimary) {
      fill = colors.primary;
      foreground = colors.canvas;
      outline = const Color(0x00000000);
    } else {
      fill = colors.subtleSurface;
      foreground = colors.textPrimary;
      outline = colors.border;
    }

    return Semantics(
      button: true,
      enabled: isEnabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: KumoFocusable(
          enabled: isEnabled,
          onActivate: onPressed,
          borderRadius: BorderRadius.circular(6),
          mouseCursor: isEnabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: outline),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (glyph != null) ...[
                  PhosphorIcon(glyph, size: 16, color: foreground),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KumoTypography.body.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
