import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';

/// Preferred width of an expanded [KumoDrawer].
const double kKumoDrawerWidth = 240;

/// Width of a [KumoDrawer] collapsed to its icons.
const double kKumoDrawerCollapsedWidth = 68;

/// One row in a [KumoDrawer].
///
/// Keeps the 48px tap height the rest of the package uses, insets the selected
/// fill so it reads as a pill rather than a full-bleed bar, and carries
/// `Semantics(selected:)` so the current route is announced, not just painted.
class KumoDrawerItem extends StatelessWidget {
  /// Creates a navigation row.
  const KumoDrawerItem({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.trailing,
    this.isSubItem = false,
    this.isCollapsed = false,
  });

  /// Row text. Hidden when [isCollapsed], where [tooltip] stands in for it.
  final String label;

  /// Glyph shown before the label.
  final PhosphorIconData? icon;

  /// Whether this row is the current destination.
  final bool isSelected;

  /// Called when the row is tapped.
  final VoidCallback? onTap;

  /// Optional trailing content, such as a badge or count.
  final Widget? trailing;

  /// Indents the row, for nested navigation under a parent item.
  final bool isSubItem;

  /// Icon-only rendering, matching [KumoDrawer.isCollapsed].
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);
    final PhosphorIconData? glyph = icon;

    final Color foreground = isSelected
        ? colors.textPrimary
        : colors.textSecondary;

    final Widget row = Container(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: isSubItem ? 20 : 12),
      alignment: isCollapsed ? Alignment.center : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: isSelected ? colors.subtleSurface : const Color(0x00000000),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (glyph != null) ...[
            PhosphorIcon(
              glyph,
              size: 18,
              color: isSelected ? colors.primary : colors.textMuted,
            ),
            if (!isCollapsed) const SizedBox(width: 10),
          ],
          if (!isCollapsed) ...[
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styles.body.copyWith(
                  color: foreground,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: isCollapsed ? label : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: KumoFocusable(
          enabled: onTap != null,
          onActivate: onTap,
          borderRadius: BorderRadius.circular(6),
          mouseCursor: onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: row,
        ),
      ),
    );
  }
}

/// A labelled run of [KumoDrawerItem]s.
class KumoDrawerGroup extends StatelessWidget {
  /// Creates a navigation group.
  const KumoDrawerGroup({
    super.key,
    this.label,
    required this.children,
    this.isCollapsed = false,
  });

  /// Optional group heading, rendered in the uppercase micro label style.
  final String? label;

  /// The group's rows.
  final List<Widget> children;

  /// Icon-only rendering, matching [KumoDrawer.isCollapsed].
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (label != null && !isCollapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Text(
              label!.toUpperCase(),
              style: KumoTheme.textStylesOf(context).caption.copyWith(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ...children,
      ],
    );
  }
}

/// The navigation panel a [KumoDrawerScaffold] places.
///
/// Pure content: it does not decide whether it is docked to the side of a
/// desktop window or sliding over a phone screen. The scaffold owns that, which
/// is what lets the same panel serve both.
class KumoDrawer extends StatelessWidget {
  /// Creates a navigation panel.
  const KumoDrawer({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.isCollapsed = false,
  });

  /// Pinned above the scrollable nav area.
  final Widget? header;

  /// Pinned below the scrollable nav area, for a trigger or a user chip.
  final Widget? footer;

  /// The navigation itself, usually [KumoDrawerGroup]s.
  final List<Widget> children;

  /// Renders icons only, for the collapsed rail.
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return Container(
      width: isCollapsed ? kKumoDrawerCollapsedWidth : kKumoDrawerWidth,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: header,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: footer,
            ),
        ],
      ),
    );
  }
}
