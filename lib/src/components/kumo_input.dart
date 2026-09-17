import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';

/// A single-line Kumo text field.
///
/// Renders a recessed fill with a hairline outline that switches to the brand
/// signal on focus and to the danger color when [errorMessage] is set. The
/// field is built from [EditableText] so it stays free of Material and Cupertino
/// dependencies.
class KumoInput extends StatefulWidget {
  /// Creates a Kumo text input.
  const KumoInput({
    super.key,
    this.label,
    this.placeholder,
    this.controller,
    this.obscureText = false,
    this.errorMessage,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
  });

  /// Micro label rendered above the field in uppercase.
  final String? label;

  /// Hint shown while the field is empty.
  final String? placeholder;

  /// Controller for the field. One is created and owned by the field when
  /// this is omitted.
  final TextEditingController? controller;

  /// Whether the entered text is masked, for password entry.
  final bool obscureText;

  /// Validation message. When non-null and non-empty the field takes its error
  /// state and the message renders beneath the input.
  final String? errorMessage;

  /// Widget shown inside the field, before the text.
  final Widget? prefixIcon;

  /// Widget shown inside the field, after the text.
  final Widget? suffixIcon;

  /// Called each time the text changes.
  final ValueChanged<String>? onChanged;

  @override
  State<KumoInput> createState() => _KumoInputState();
}

class _KumoInputState extends State<KumoInput> {
  late TextEditingController _controller;
  late bool _ownsController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(KumoInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTap() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final hasError = widget.errorMessage?.isNotEmpty ?? false;
    final isFocused = _focusNode.hasFocus;

    final Color borderColor;
    if (hasError) {
      borderColor = colors.danger;
    } else if (isFocused) {
      borderColor = colors.primary;
    } else {
      borderColor = colors.border;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.label!.toUpperCase(),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.subtleSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              boxShadow: isFocused && !hasError
                  ? <BoxShadow>[
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.18),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      EditableText(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        cursorColor: colors.primary,
                        backgroundCursorColor: colors.subtleSurface,
                        selectionColor: colors.primary.withValues(alpha: 0.25),
                        obscureText: widget.obscureText,
                        maxLines: 1,
                        onChanged: widget.onChanged,
                      ),
                      if (widget.placeholder != null)
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _controller,
                          builder: (context, value, child) {
                            if (value.text.isNotEmpty) {
                              return const SizedBox.shrink();
                            }
                            return IgnorePointer(child: child);
                          },
                          child: Text(
                            widget.placeholder!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.suffixIcon != null) ...[
                  const SizedBox(width: 8),
                  widget.suffixIcon!,
                ],
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.errorMessage!,
              // dangerText, not danger: the error message is text and must
              // clear 4.5:1 on every surface, while [KumoColors.danger] is the
              // indicator tone used for the outline.
              style: TextStyle(color: colors.dangerText, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
