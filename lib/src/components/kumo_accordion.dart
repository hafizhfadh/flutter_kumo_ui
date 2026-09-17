import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/kumo_theme.dart';
import '../theme/kumo_typography.dart';
import 'kumo_focusable.dart';

/// A collapsible section with a tappable header.
///
/// The header sits on the surface fill and swaps between the Phosphor caret
/// icons as [KumoAccordion] opens, while the body reveals itself with a
/// [SizeTransition] so hidden content never captures pointer events.
class KumoAccordion extends StatefulWidget {
  /// Creates a Kumo accordion.
  const KumoAccordion({
    super.key,
    required this.title,
    required this.child,
    this.initialExpanded = false,
  });

  /// Text shown in the always-visible header.
  final String title;

  /// Content revealed beneath the header.
  final Widget child;

  /// Whether the section starts open.
  final bool initialExpanded;

  @override
  State<KumoAccordion> createState() => _KumoAccordionState();
}

class _KumoAccordionState extends State<KumoAccordion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _reveal;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _isExpanded ? 1 : 0,
    );
    _reveal = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              expanded: _isExpanded,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggle,
                child: KumoFocusable(
                  onActivate: _toggle,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                  mouseCursor: SystemMouseCursors.click,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    color: colors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(widget.title, style: KumoTypography.body),
                        ),
                        PhosphorIcon(
                          _isExpanded
                              ? PhosphorIconsRegular.caretUp
                              : PhosphorIconsRegular.caretDown,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _reveal,
              alignment: Alignment.topLeft,
              child: Container(
                width: double.infinity,
                color: colors.canvas,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
