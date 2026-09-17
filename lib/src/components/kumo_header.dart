import 'package:flutter/widgets.dart';

import '../layout/kumo_responsive_layout.dart';
import '../theme/kumo_typography.dart';

/// A section header that reflows between phone and desktop arrangements.
///
/// On phones the heading and the action stack vertically with 12px between
/// them, and the action stretches to the full width to remain an easy touch
/// target. On desktop the heading and action sit on one row, pushed to opposite
/// ends with [MainAxisAlignment.spaceBetween].
class KumoHeader extends StatelessWidget {
  /// Creates an adaptive section header.
  const KumoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.leading,
  });

  /// Primary heading text.
  final String title;

  /// Optional supporting line rendered beneath [title].
  final String? subtitle;

  /// Widget pushed to the trailing edge on desktop and stacked on mobile.
  final Widget? action;

  /// Widget rendered immediately before the heading, such as a back control.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final heading = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KumoTypography.h2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: KumoTypography.bodyMuted,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kKumoBreakpoint) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: heading),
              if (action != null) ...[const SizedBox(width: 16), action!],
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        );
      },
    );
  }
}
