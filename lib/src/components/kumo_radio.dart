import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';

/// A labelled radio button.
///
/// Deliberately mirrors [KumoCheckbox] so a form reads consistently: an 18px
/// control, the whole row as a single 48px tap target, the brand signal when
/// chosen, and Enter/Space activation with a focus ring.
///
/// The control is fully controlled. Compare [value] with [groupValue] yourself
/// by threading the selected value through your own state.
class KumoRadio<T> extends StatelessWidget {
  /// Creates a Kumo radio button.
  const KumoRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.label,
    this.isDisabled = false,
  });

  /// The value this button stands for.
  final T value;

  /// The value currently selected in the group.
  final T groupValue;

  /// Called with [value] when this button is chosen. A null callback renders it
  /// inert.
  final ValueChanged<T>? onChanged;

  /// Optional text rendered beside the control.
  final String? label;

  /// When true the button is dimmed and ignores taps and keyboard input.
  final bool isDisabled;

  /// Diameter of the control itself, in logical pixels.
  static const double size = 18;

  bool get _isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);
    final bool isEnabled = onChanged != null && !isDisabled;

    void select() => onChanged?.call(value);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: _isSelected,
      enabled: isEnabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled ? select : null,
        child: KumoFocusable(
          enabled: isEnabled,
          onActivate: isEnabled ? select : null,
          borderRadius: BorderRadius.circular(6),
          mouseCursor: isEnabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Opacity(
                  opacity: isEnabled ? 1 : 0.4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isSelected
                          ? colors.primary
                          : colors.subtleSurface,
                      border: Border.all(
                        color: _isSelected ? colors.primary : colors.border,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: _isSelected
                        // Reinforcement only: the fill already carries the
                        // state, the same way the checkbox glyph does.
                        ? Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.canvas,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label!,
                      style: styles.body.copyWith(
                        color: isEnabled ? colors.textPrimary : colors.textMuted,
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
