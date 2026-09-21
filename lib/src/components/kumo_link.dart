import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';

/// A text link.
///
/// Renders as brand-coloured text rather than a filled control, for navigation
/// and secondary actions that would be too heavy as a [KumoButton]. Keeps a
/// 48px tap target and activates on Enter or Space, so it stays reachable by
/// keyboard even though it does not look like a button.
class KumoLink extends StatelessWidget {
  /// Creates a Kumo link.
  const KumoLink({super.key, required this.label, this.onPressed, this.icon});

  /// Link text.
  final String label;

  /// Called when the link is activated. A null callback renders it as inert
  /// muted text, which is how a disabled link should read.
  final VoidCallback? onPressed;

  /// Optional trailing glyph, typically [PhosphorIconsRegular.arrowUpRight] for
  /// a link that leaves the app.
  final PhosphorIconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);
    final bool isEnabled = onPressed != null;
    final PhosphorIconData? glyph = icon;

    final Widget text = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: styles.body.copyWith(
              color: isEnabled ? colors.primary : colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (glyph != null) ...[
          const SizedBox(width: 4),
          PhosphorIcon(
            glyph,
            size: 14,
            color: isEnabled ? colors.primary : colors.textMuted,
          ),
        ],
      ],
    );

    if (!isEnabled) {
      return text;
    }

    return Semantics(
      link: true,
      enabled: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: KumoFocusable(
          onActivate: onPressed,
          borderRadius: BorderRadius.circular(6),
          mouseCursor: SystemMouseCursors.click,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            alignment: AlignmentDirectional.centerStart,
            child: text,
          ),
        ),
      ),
    );
  }
}
