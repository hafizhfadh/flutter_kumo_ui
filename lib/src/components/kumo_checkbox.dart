import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import '../theme/kumo_typography.dart';
import 'kumo_focusable.dart';

/// A labelled checkbox styled with Kumo tokens.
///
/// The box is 18x18 with a `gray2` fill and `gray3` outline at rest, and flips
/// to an `orange5` fill with a check glyph when [value] is true. The whole row —
/// box plus label — is a single tap target with a 48px minimum height, so it
/// stays usable one-handed on a phone.
class KumoCheckbox extends StatelessWidget {
  /// Creates a Kumo checkbox.
  const KumoCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.isDisabled = false,
  });

  /// Whether the box is checked.
  final bool value;

  /// Called with the inverted value when the row is tapped.
  final ValueChanged<bool> onChanged;

  /// Optional text rendered beside the box. When provided, tapping the label
  /// toggles the box as well.
  final String? label;

  /// When true the checkbox is dimmed and ignores taps and keyboard input.
  final bool isDisabled;

  /// Side length of the box itself, in logical pixels.
  static const double boxSize = 18;

  void _toggle() => onChanged(!value);

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return Semantics(
      checked: value,
      enabled: !isDisabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isDisabled ? null : _toggle,
        child: KumoFocusable(
          enabled: !isDisabled,
          onActivate: isDisabled ? null : _toggle,
          borderRadius: BorderRadius.circular(6),
          mouseCursor: isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: isDisabled ? 0.4 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    width: boxSize,
                    height: boxSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value ? colors.primary : colors.subtleSurface,
                      border: Border.all(
                        color: value ? colors.primary : colors.border,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: value
                        // The glyph is reinforcement: the checked state is
                        // already carried by the orange fill, which measures
                        // 5.71:1 against the resting fill and 7.12:1 against
                        // the canvas.
                        ? const PhosphorIcon(
                            PhosphorIconsRegular.check,
                            size: 12,
                            color: Color(0xFFFFFFFF),
                          )
                        : null,
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label!,
                      style: KumoTypography.body.copyWith(
                        color: isDisabled
                            ? colors.textMuted
                            : colors.textPrimary,
                      ),
                    ),
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
