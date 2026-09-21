import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';

/// One step in a [KumoBreadcrumb] trail.
@immutable
class KumoBreadcrumbItem {
  /// Creates a breadcrumb step.
  const KumoBreadcrumbItem({required this.label, this.onTap});

  /// Text for this step.
  final String label;

  /// Called when the step is tapped. A null callback marks the step as the
  /// current page, which renders it as non-interactive text.
  final VoidCallback? onTap;
}

/// A horizontal trail of parent routes ending in the current page.
///
/// Steps are separated by a 12px caret. Tappable ancestors are 48px tall so
/// they remain comfortable targets on a phone, and the trail scrolls
/// horizontally rather than overflowing when a deep path is shown.
class KumoBreadcrumb extends StatelessWidget {
  /// Creates a breadcrumb trail.
  const KumoBreadcrumb({super.key, required this.items});

  /// Trail steps in reading order. The last step is the current page.
  final List<KumoBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var index = 0; index < items.length; index++) ...<Widget>[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: PhosphorIcon(
                  PhosphorIconsRegular.caretRight,
                  size: 12,
                  color: colors.textMuted,
                ),
              ),
            _KumoBreadcrumbStep(
              item: items[index],
              isCurrent: index == items.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _KumoBreadcrumbStep extends StatelessWidget {
  const _KumoBreadcrumbStep({required this.item, required this.isCurrent});

  final KumoBreadcrumbItem item;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);
    final VoidCallback? onTap = isCurrent ? null : item.onTap;

    final Widget label = Text(
      item.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: styles.body.copyWith(
        color: isCurrent ? colors.textPrimary : colors.textSecondary,
        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
      ),
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: label,
      );
    }

    return Semantics(
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: KumoFocusable(
          onActivate: onTap,
          borderRadius: BorderRadius.circular(6),
          mouseCursor: SystemMouseCursors.click,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            alignment: AlignmentDirectional.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: label,
          ),
        ),
      ),
    );
  }
}
