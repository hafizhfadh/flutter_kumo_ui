import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';

/// The micro label above a field.
///
/// Extracted from the label treatment `KumoInput` and `KumoSelect` already
/// paint, so a form built from scratch still matches them: 11px, semibold,
/// uppercase, tracked, in the secondary text tone.
class KumoLabel extends StatelessWidget {
  /// Creates a Kumo field label.
  const KumoLabel(this.text, {super.key, this.isDisabled = false});

  /// Label text. Rendered upper-cased.
  final String text;

  /// Whether the field it labels is disabled, which mutes the label.
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return Text(
      text.toUpperCase(),
      style: KumoTheme.textStylesOf(context).caption.copyWith(
        color: isDisabled ? colors.textMuted : colors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}
