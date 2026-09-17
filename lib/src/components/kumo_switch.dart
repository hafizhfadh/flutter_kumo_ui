import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';

/// A compact on/off toggle styled with Kumo tokens.
///
/// The visible track is 40x22 and fills with the brand signal while [value] is
/// true, with the thumb sliding between the track edges. The touch target is
/// padded out to a 48x48 minimum without changing the track, and the control
/// takes part in keyboard traversal with a focus ring and Enter/Space
/// activation.
class KumoSwitch extends StatefulWidget {
  /// Creates a Kumo toggle.
  const KumoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.isDisabled = false,
  });

  /// Whether the switch is currently on.
  final bool value;

  /// Called with the next value when the switch is tapped.
  final ValueChanged<bool> onChanged;

  /// When true the switch ignores taps and renders at reduced opacity.
  final bool isDisabled;

  @override
  State<KumoSwitch> createState() => _KumoSwitchState();
}

class _KumoSwitchState extends State<KumoSwitch> {
  static const Duration _duration = Duration(milliseconds: 150);

  void _handleActivate() => widget.onChanged(!widget.value);

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final isDisabled = widget.isDisabled;

    return Semantics(
      toggled: widget.value,
      enabled: !isDisabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isDisabled ? null : _handleActivate,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: KumoFocusable(
              enabled: !isDisabled,
              onActivate: isDisabled ? null : _handleActivate,
              borderRadius: BorderRadius.circular(11),
              mouseCursor: isDisabled
                  ? SystemMouseCursors.forbidden
                  : SystemMouseCursors.click,
              child: Opacity(
                opacity: isDisabled ? 0.4 : 1.0,
                child: AnimatedContainer(
                  duration: _duration,
                  curve: Curves.easeOut,
                  width: 40,
                  height: 22,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: widget.value ? colors.primary : colors.border,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: AnimatedAlign(
                    duration: _duration,
                    curve: Curves.easeOut,
                    alignment: widget.value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
