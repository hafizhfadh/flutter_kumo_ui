import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';

/// The view a screen shows when it has nothing to display.
///
/// An empty state that only says "No data" tells the user nothing. This one
/// takes a reason and, optionally, the action that fills the screen, which is
/// what a first run or a filtered-to-nothing list actually needs.
class KumoEmpty extends StatelessWidget {
  /// Creates a Kumo empty state.
  const KumoEmpty({
    super.key,
    this.title = 'Nothing here yet',
    this.message,
    this.icon = PhosphorIconsRegular.tray,
    this.action,
  });

  /// Short headline naming the state.
  final String title;

  /// One or two lines explaining why it is empty and what to do next.
  final String? message;

  /// Glyph shown above [title].
  final PhosphorIconData icon;

  /// Optional control that resolves the empty state, such as a create button.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);

    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.subtleSurface,
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(icon, size: 20, color: colors.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: styles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(message!, textAlign: TextAlign.center, style: styles.bodyMuted),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
