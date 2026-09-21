import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';

/// A bordered container that groups related [KumoListItem] rows.
///
/// Rows are separated by 1px dividers and share one rounded outline, which is
/// the mobile-first pattern Kumo uses for settings and resource lists.
class KumoListGroup extends StatelessWidget {
  /// Creates a group around [children].
  const KumoListGroup({super.key, this.title, required this.children});

  /// Optional heading rendered above the group in uppercase micro type.
  final String? title;

  /// Rows to render, usually [KumoListItem] widgets.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              title!.toUpperCase(),
              style: styles.caption.copyWith(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  if (index > 0) Container(height: 1, color: colors.border),
                  children[index],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A single tappable row inside a [KumoListGroup].
///
/// Rows keep a 56px minimum height, well past the 48px touch-target minimum,
/// and reveal a trailing caret whenever [onTap] is provided and no [trailing]
/// widget is set. Tappable rows are reachable by keyboard and activate on
/// Enter or Space.
class KumoListItem extends StatelessWidget {
  /// Creates a list row.
  const KumoListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  /// Primary row text.
  final String title;

  /// Optional supporting text rendered beneath [title].
  final String? subtitle;

  /// Widget shown before the text block.
  final Widget? leading;

  /// Widget shown after the text block, replacing the default caret.
  final Widget? trailing;

  /// Called when the row is tapped. A null callback renders an inert row.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
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
            constraints: const BoxConstraints(minWidth: 48, minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: styles.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: styles.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ] else if (onTap != null) ...[
                  const SizedBox(width: 8),
                  PhosphorIcon(
                    PhosphorIconsRegular.caretRight,
                    size: 14,
                    color: colors.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
