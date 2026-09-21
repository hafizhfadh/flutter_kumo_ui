import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';
import 'kumo_input.dart';

/// A text field for secrets, with a reveal toggle.
///
/// [KumoInput] masks what it is told to mask and nothing else, which is right
/// for a password never meant to be read back. A secret the user has to paste
/// and verify, such as an API token, needs a way to check it: this adds that
/// affordance and nothing else, by composing [KumoInput] rather than
/// reimplementing it.
class KumoSensitiveInput extends StatefulWidget {
  /// Creates a sensitive text field.
  const KumoSensitiveInput({
    super.key,
    this.label,
    this.placeholder,
    this.controller,
    this.errorMessage,
    this.onChanged,
  });

  /// Micro label rendered above the field in uppercase.
  final String? label;

  /// Hint shown while the field is empty.
  final String? placeholder;

  /// Controller for the field. One is created and owned by the field when this
  /// is omitted.
  final TextEditingController? controller;

  /// Validation message, shown beneath the field.
  final String? errorMessage;

  /// Called each time the text changes.
  final ValueChanged<String>? onChanged;

  @override
  State<KumoSensitiveInput> createState() => _KumoSensitiveInputState();
}

class _KumoSensitiveInputState extends State<KumoSensitiveInput> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final String action = _isRevealed ? 'Hide' : 'Show';

    return KumoInput(
      label: widget.label,
      placeholder: widget.placeholder,
      controller: widget.controller,
      errorMessage: widget.errorMessage,
      onChanged: widget.onChanged,
      obscureText: !_isRevealed,
      suffixIcon: Semantics(
        button: true,
        label: '$action the value',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _isRevealed = !_isRevealed),
          child: KumoFocusable(
            onActivate: () => setState(() => _isRevealed = !_isRevealed),
            borderRadius: BorderRadius.circular(6),
            mouseCursor: SystemMouseCursors.click,
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              alignment: Alignment.center,
              child: PhosphorIcon(
                _isRevealed ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
                size: 16,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
