import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';

/// Where a [KumoTooltip] bubble sits relative to its child.
enum KumoTooltipPlacement {
  /// Above the child. The default, which keeps it clear of the thumb.
  top,

  /// Below the child.
  bottom,
}

/// A short label shown on hover or long press.
///
/// For a control whose meaning is not obvious from its glyph. On a desktop the
/// bubble follows the pointer in and out; on a phone it appears on a long
/// press, which is the touch equivalent.
///
/// The message is also attached to the child as a semantics tooltip, so it
/// reaches assistive technology on platforms where no hover exists.
class KumoTooltip extends StatefulWidget {
  /// Creates a tooltip around [child].
  const KumoTooltip({
    super.key,
    required this.message,
    required this.child,
    this.placement = KumoTooltipPlacement.top,
  });

  /// Text shown in the bubble.
  final String message;

  /// The widget the tooltip describes.
  final Widget child;

  /// Which side of [child] the bubble appears on.
  final KumoTooltipPlacement placement;

  @override
  State<KumoTooltip> createState() => _KumoTooltipState();
}

class _KumoTooltipState extends State<KumoTooltip> {
  OverlayEntry? _entry;

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  void _show() {
    if (_entry != null) {
      return;
    }
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    final RenderObject? box = context.findRenderObject();
    if (overlay == null || box is! RenderBox || !box.hasSize) {
      return;
    }

    final Offset origin = box.localToGlobal(Offset.zero);
    _entry = OverlayEntry(
      builder: (BuildContext context) => _KumoTooltipBubble(
        message: widget.message,
        anchor: origin,
        anchorSize: box.size,
        placement: widget.placement,
      ),
    );
    overlay.insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      tooltip: widget.message,
      child: MouseRegion(
        // The pointer event types live in gestures.dart, which the package does
        // not import, so let them infer from the callback signature.
        onEnter: (_) => _show(),
        onExit: (_) => _hide(),
        child: GestureDetector(
          onLongPress: _show,
          onLongPressEnd: (_) => _hide(),
          child: widget.child,
        ),
      ),
    );
  }
}

class _KumoTooltipBubble extends StatelessWidget {
  const _KumoTooltipBubble({
    required this.message,
    required this.anchor,
    required this.anchorSize,
    required this.placement,
  });

  final String message;
  final Offset anchor;
  final Size anchorSize;
  final KumoTooltipPlacement placement;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);
    final double screenHeight = MediaQuery.sizeOf(context).height;

    // Anchoring the top placement by its bottom edge means the bubble does not
    // have to be measured before it can be positioned.
    final Widget bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(message, style: styles.caption),
      ),
    );

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (placement == KumoTooltipPlacement.top)
            Positioned(
              left: anchor.dx,
              bottom: screenHeight - anchor.dy + 6,
              child: bubble,
            )
          else
            Positioned(
              left: anchor.dx,
              top: anchor.dy + anchorSize.height + 6,
              child: bubble,
            ),
        ],
      ),
    );
  }
}
