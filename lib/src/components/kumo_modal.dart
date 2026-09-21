import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';

/// Presents Kumo-styled modal dialogs without Material's `showDialog`.
///
/// [KumoModal.show] pushes a [RawDialogRoute], which supplies the dimmed
/// barrier and the fade transition, and renders a centered card carrying an
/// optional title, the caller's content and a close action.
abstract final class KumoModal {
  /// Shows [child] in a centered Kumo dialog card.
  ///
  /// Returns a future that completes with the value the route is popped with,
  /// or `null` when [barrierDismissible] is true and the barrier is tapped.
  ///
  /// The palette of the nearest [KumoTheme] ancestor is captured before the
  /// route is pushed and re-applied above the navigator, so the dialog keeps
  /// its styling even when the navigator sits above the theme.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool barrierDismissible = true,
  }) {
    final colors = KumoTheme.of(context);
    return Navigator.of(context, rootNavigator: true).push<T>(
      RawDialogRoute<T>(
        barrierDismissible: barrierDismissible,
        barrierLabel: title ?? 'Dialog',
        barrierColor: colors.scrim,
        pageBuilder: (context, animation, secondaryAnimation) => KumoTheme(
          colors: colors,
          child: _KumoModalCard(title: title, child: child),
        ),
      ),
    );
  }
}

class _KumoModalCard extends StatelessWidget {
  const _KumoModalCard({required this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);

    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Expanded(child: Text(title!, style: styles.h2))
                else
                  const Spacer(),
                const SizedBox(width: 12),
                Semantics(
                  button: true,
                  label: 'Close dialog',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: KumoFocusable(
                      onActivate: () => Navigator.of(context).maybePop(),
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
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
