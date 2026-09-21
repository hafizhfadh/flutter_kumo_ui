import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';

/// Presents Kumo-styled bottom sheets without Material's `showModalBottomSheet`.
///
/// This is the touch-friendly home for choices that a desktop build would put
/// in a popover or a dialog: the sheet slides up from the bottom edge, keeps
/// every row at a full 48px tap height, and insets itself for the home
/// indicator through [SafeArea].
class KumoBottomSheet {
  /// Shows [child] in a sheet anchored to the bottom edge.
  ///
  /// Returns a future that completes with the value the sheet is popped with,
  /// or `null` when [barrierDismissible] is true and the barrier is tapped.
  ///
  /// The palette of the nearest [KumoTheme] ancestor is captured before the
  /// route is pushed and re-applied above the navigator, so the sheet keeps its
  /// styling even when the navigator sits above the theme.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool barrierDismissible = true,
  }) {
    final colors = KumoTheme.of(context);
    final BorderRadius radius = const BorderRadius.vertical(
      top: Radius.circular(16),
    );

    return Navigator.of(context, rootNavigator: true).push<T>(
      RawDialogRoute<T>(
        barrierDismissible: barrierDismissible,
        barrierLabel: title ?? 'Options',
        barrierColor: colors.scrim,
        transitionDuration: const Duration(milliseconds: 220),
        transitionBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final Animation<double> curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => KumoTheme(
              colors: colors,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _KumoBottomSheetSurface(
                  title: title,
                  borderRadius: radius,
                  child: child,
                ),
              ),
            ),
      ),
    );
  }
}

class _KumoBottomSheetSurface extends StatelessWidget {
  const _KumoBottomSheetSurface({
    required this.title,
    required this.borderRadius,
    required this.child,
  });

  final String? title;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);
    final String? heading = title;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      if (heading != null)
                        Expanded(child: Text(heading, style: styles.h2))
                      else
                        const Spacer(),
                      KumoFocusable(
                        onActivate: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(6),
                        mouseCursor: SystemMouseCursors.click,
                        child: Semantics(
                          button: true,
                          label: 'Close sheet',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Close',
                                style: styles.body.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single tappable row inside a [KumoBottomSheet].
///
/// Rows keep a full 48px minimum height so a sheet stays comfortable to use
/// one-handed on a phone.
class KumoBottomSheetItem extends StatelessWidget {
  /// Creates a sheet row.
  const KumoBottomSheetItem({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  /// Row text.
  final String label;

  /// Whether this row represents the current selection.
  final bool isSelected;

  /// Called when the row is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: KumoFocusable(
          enabled: onTap != null,
          onActivate: onTap,
          mouseCursor: onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              style: styles.body.copyWith(
                color: isSelected ? colors.primary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
