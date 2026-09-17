import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';

/// Wraps an interactive Kumo control with its keyboard and focus affordances.
///
/// kumo-ui.com/accessibility documents that Kumo manages interaction while
/// "it's the developer's responsibility to visually indicate focus ... handled
/// by styling the `:focus` or `:focus-visible` CSS pseudo-classes". This widget
/// is the Flutter equivalent of that contract:
///
/// * [FocusableActionDetector.onShowFocusHighlight] follows the platform focus
///   highlight strategy, so the ring appears for keyboard traversal and stays
///   out of the way for pointer interaction — `:focus-visible`, not `:focus`.
/// * Enter, Space and Select activate the control through the framework's
///   [ActivateIntent], so it can be operated without a pointer.
/// * The hover cursor lives here, so controls do not need a second
///   [MouseRegion] wrapper.
///
/// The ring is painted with [Container.foregroundDecoration], which does not
/// consume layout, so showing focus never shifts the control.
///
/// This is shared plumbing between the Kumo controls and is not exported from
/// `kumo_ui.dart`.
class KumoFocusable extends StatefulWidget {
  /// Wraps [child] with focus, activation and hover handling.
  const KumoFocusable({
    super.key,
    required this.child,
    this.onActivate,
    this.borderRadius,
    this.enabled = true,
    this.mouseCursor,
  });

  /// The control's visual, which the focus ring hugs.
  final Widget child;

  /// Invoked when the control is activated by pointer or by keyboard.
  ///
  /// When null the control is not focusable.
  final VoidCallback? onActivate;

  /// Radius used to draw the ring so it matches the control's own outline.
  final BorderRadius? borderRadius;

  /// Whether the control accepts focus and reacts to activation keys.
  final bool enabled;

  /// Cursor shown while the pointer is over the control. Defaults to
  /// [MouseCursor.defer].
  final MouseCursor? mouseCursor;

  @override
  State<KumoFocusable> createState() => _KumoFocusableState();
}

class _KumoFocusableState extends State<KumoFocusable> {
  bool _showFocusRing = false;

  void _handleShowFocusHighlight(bool value) {
    if (_showFocusRing != value) {
      setState(() => _showFocusRing = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final VoidCallback? activate = widget.onActivate;
    final bool isInteractive = widget.enabled && activate != null;

    return FocusableActionDetector(
      enabled: isInteractive,
      mouseCursor: widget.mouseCursor ?? MouseCursor.defer,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            activate?.call();
            return null;
          },
        ),
      },
      onShowFocusHighlight: _handleShowFocusHighlight,
      child: Container(
        foregroundDecoration: _showFocusRing
            ? BoxDecoration(
                borderRadius: widget.borderRadius,
                border: Border.all(color: colors.focus, width: 2),
              )
            : null,
        child: widget.child,
      ),
    );
  }
}
