import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../layout/kumo_responsive_layout.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_typography.dart';
import 'kumo_bottom_sheet.dart';
import 'kumo_focusable.dart';

/// A single-choice control that adapts its picker to the viewport.
///
/// Kumo treats a select as two different interactions rather than one scaled
/// one. On a desktop viewport the choices open in a popover anchored to the
/// trigger; below [kKumoBreakpoint] they open in a [KumoBottomSheet] action
/// sheet, where every option is a full-width row at a 48px tap height.
///
/// The value type doubles as the option key, so any equatable `T` works.
class KumoSelect<T> extends StatefulWidget {
  /// Creates a Kumo select.
  const KumoSelect({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.label,
  });

  /// The currently selected option key.
  final T value;

  /// Choices in display order. Keys are reported to [onChanged] and values are
  /// the visible labels.
  final Map<T, String> options;

  /// Called with the chosen key.
  final ValueChanged<T> onChanged;

  /// Optional micro label rendered above the trigger.
  final String? label;

  @override
  State<KumoSelect<T>> createState() => _KumoSelectState<T>();
}

class _KumoSelectState<T> extends State<KumoSelect<T>> {
  OverlayEntry? _popover;

  bool get _isOpen => _popover != null;

  @override
  void dispose() {
    _dismissPopover();
    super.dispose();
  }

  void _dismissPopover() {
    _popover?.remove();
    _popover = null;
  }

  void _handleTrigger() {
    if (_isOpen) {
      setState(_dismissPopover);
      return;
    }
    if (KumoResponsiveLayout.isDesktop(context)) {
      _showPopover();
    } else {
      _showActionSheet();
    }
  }

  void _showPopover() {
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    final RenderObject? trigger = context.findRenderObject();
    final RenderObject? theater = overlay?.context.findRenderObject();
    if (overlay == null || trigger is! RenderBox || theater is! RenderBox) {
      return;
    }

    final KumoColors colors = KumoTheme.of(context);
    final Offset origin = trigger.localToGlobal(Offset.zero, ancestor: theater);
    final double top = origin.dy + trigger.size.height + 4;
    final double width = trigger.size.width;

    setState(() {
      _popover = OverlayEntry(
        builder: (BuildContext context) => KumoTheme(
          colors: colors,
          child: _KumoPopover<T>(
            left: origin.dx,
            top: top,
            width: width,
            value: widget.value,
            options: widget.options,
            onSelected: (T value) {
              _dismissPopover();
              widget.onChanged(value);
            },
            onDismiss: () => setState(_dismissPopover),
          ),
        ),
      );
    });
    overlay.insert(_popover!);
  }

  Future<void> _showActionSheet() async {
    final _Selection<T>? picked = await KumoBottomSheet.show<_Selection<T>>(
      context: context,
      title: widget.label ?? 'Select an option',
      child: Builder(
        builder: (BuildContext sheetContext) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final MapEntry<T, String> entry in widget.options.entries)
              KumoBottomSheetItem(
                label: entry.value,
                isSelected: entry.key == widget.value,
                onTap: () =>
                    Navigator.of(sheetContext).pop(_Selection<T>(entry.key)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      widget.onChanged(picked.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final String selectedLabel = widget.options[widget.value] ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.label!.toUpperCase(),
              style: KumoTypography.caption.copyWith(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        Semantics(
          button: true,
          expanded: _isOpen,
          label: widget.label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTrigger,
            child: KumoFocusable(
              onActivate: _handleTrigger,
              borderRadius: BorderRadius.circular(8),
              mouseCursor: SystemMouseCursors.click,
              child: Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.subtleSurface,
                  border: Border.all(
                    color: _isOpen ? colors.primary : colors.border,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KumoTypography.body,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PhosphorIcon(
                      PhosphorIconsRegular.caretDown,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Wrapper that keeps a dismissed sheet distinguishable from a chosen `null`.
class _Selection<T> {
  const _Selection(this.value);

  final T value;
}

class _KumoPopover<T> extends StatelessWidget {
  const _KumoPopover({
    required this.left,
    required this.top,
    required this.width,
    required this.value,
    required this.options,
    required this.onSelected,
    required this.onDismiss,
  });

  final double left;
  final double top;
  final double width;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: const ColoredBox(color: Color(0x00000000)),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: width,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final MapEntry<T, String> entry in options.entries)
                    KumoBottomSheetItem(
                      label: entry.value,
                      isSelected: entry.key == value,
                      onTap: () => onSelected(entry.key),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
