import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';

/// The state a [KumoBanner] reports.
enum KumoBannerKind {
  /// Neutral notice, tinted with the palette info blue.
  info,

  /// Completed work, tinted with the palette success green.
  success,

  /// Something needs attention, tinted with the palette warning amber.
  warning,

  /// Failed work, tinted with the palette error red.
  error,
}

/// A persistent inline message.
///
/// The counterpart to [KumoToast]: a toast is transient and floats above the
/// page, a banner stays where you put it, inside the layout. Use a banner when
/// the message has to survive being read twice, such as a plan limit or a
/// failed deploy with a retry.
///
/// Colour is never the only signal: the kind supplies an icon and the caller
/// supplies the words.
class KumoBanner extends StatelessWidget {
  /// Creates a Kumo banner.
  const KumoBanner({
    super.key,
    required this.message,
    this.title,
    this.kind = KumoBannerKind.info,
    this.action,
    this.onDismiss,
  });

  /// Body text explaining the state.
  final String message;

  /// Optional emphasised first line.
  final String? title;

  /// Which state this banner reports.
  final KumoBannerKind kind;

  /// Optional control that resolves the state, such as a retry button.
  final Widget? action;

  /// Called when the banner is dismissed. When null no dismiss action renders,
  /// which is right for a message the user cannot make go away.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);

    final (IconData icon, Color accent) = switch (kind) {
      KumoBannerKind.info => (PhosphorIconsRegular.info, colors.info),
      KumoBannerKind.success => (
        PhosphorIconsRegular.checkCircle,
        colors.success,
      ),
      KumoBannerKind.warning => (PhosphorIconsRegular.warning, colors.warning),
      // The icon is a graphic, not text, so the indicator red is correct here:
      // danger clears the 3:1 non-text floor in both schemes.
      KumoBannerKind.error => (
        PhosphorIconsRegular.warningCircle,
        colors.danger,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: PhosphorIcon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title != null) ...[
                  Text(
                    title!,
                    style: styles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(message, style: styles.bodyMuted),
                if (action != null) ...[const SizedBox(height: 10), action!],
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Dismiss message',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDismiss,
                child: KumoFocusable(
                  onActivate: onDismiss,
                  borderRadius: BorderRadius.circular(6),
                  mouseCursor: SystemMouseCursors.click,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    alignment: Alignment.center,
                    child: PhosphorIcon(
                      PhosphorIconsRegular.x,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
