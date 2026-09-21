import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';

/// A placeholder bar shown while content loads.
///
/// Static by design: a pulsing skeleton competes for attention with the content
/// it is standing in for, and an endless animation makes `pumpAndSettle`
/// unusable in tests. Pair it with [KumoLoader] when the wait needs to be
/// visible.
///
/// Pass [lines] above 1 for a text block; the final bar is shortened so the
/// block does not read as a solid rectangle.
class KumoSkeleton extends StatelessWidget {
  /// Creates a skeleton bar, or a stack of them.
  const KumoSkeleton({
    super.key,
    this.width,
    this.height = 12,
    this.lines = 1,
    this.spacing = 8,
  });

  /// Width of each bar. Null stretches to the available width.
  final double? width;

  /// Height of each bar.
  final double height;

  /// How many bars to stack.
  final int lines;

  /// Vertical gap between bars.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    Widget bar(double barWidth) => Container(
      width: barWidth,
      height: height,
      decoration: BoxDecoration(
        color: colors.subtleSurface,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );

    return Semantics(
      label: 'Loading content',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var index = 0; index < lines; index++) ...[
            if (index > 0) SizedBox(height: spacing),
            if (width != null)
              bar(width!)
            else
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: lines > 1 && index == lines - 1 ? 0.6 : 1,
                child: bar(double.infinity),
              ),
          ],
        ],
      ),
    );
  }
}
