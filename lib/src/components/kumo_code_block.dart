import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';

/// A read-only code surface with an inline copy affordance.
///
/// The block renders [code] verbatim in a monospace style on the canvas fill,
/// with an optional language label and a copy button that confirms the write
/// before resetting itself.
class KumoCodeBlock extends StatefulWidget {
  /// Creates a Kumo code block.
  const KumoCodeBlock({
    super.key,
    required this.code,
    this.language,
    this.showCopyButton = true,
  });

  /// Source text rendered verbatim.
  final String code;

  /// Optional language label shown in the block header.
  final String? language;

  /// Whether the copy button is rendered.
  final bool showCopyButton;

  @override
  State<KumoCodeBlock> createState() => _KumoCodeBlockState();
}

class _KumoCodeBlockState extends State<KumoCodeBlock> {
  static const Duration _feedbackDuration = Duration(milliseconds: 1500);

  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(_feedbackDuration, () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);
    final hasHeader = widget.language != null || widget.showCopyButton;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader) ...[
            Row(
              children: [
                if (widget.language != null)
                  Expanded(
                    child: Text(
                      widget.language!,
                      style: styles.caption,
                    ),
                  )
                else
                  const Spacer(),
                if (widget.showCopyButton)
                  _CopyButton(copied: _copied, onPressed: _handleCopy),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(widget.code, style: styles.code),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.copied, required this.onPressed});

  final bool copied;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);
    final Color tint = copied ? colors.success : colors.textSecondary;

    return Semantics(
      button: true,
      label: copied ? 'Copied' : 'Copy code',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: KumoFocusable(
          onActivate: onPressed,
          borderRadius: BorderRadius.circular(6),
          mouseCursor: SystemMouseCursors.click,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  copied
                      ? PhosphorIconsRegular.check
                      : PhosphorIconsRegular.copy,
                  size: 14,
                  color: tint,
                ),
                const SizedBox(width: 4),
                Text(
                  copied ? 'Copied' : 'Copy',
                  style: styles.caption.copyWith(color: tint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
