import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';
import 'kumo_focusable.dart';

/// A horizontal selector that switches between a fixed set of values.
///
/// The control is fully controlled: it renders [selected] and reports taps
/// through [onSelected] without tracking any state of its own. The active
/// segment is lifted onto the surface fill with a hairline border and the
/// brand accent.
class KumoSegmentedControl<T> extends StatelessWidget {
  /// Creates a Kumo segmented control.
  const KumoSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
  });

  /// Segments to render, in display order. Keys are reported to [onSelected]
  /// and values are the visible labels.
  final Map<T, String> segments;

  /// The segment currently highlighted.
  final T selected;

  /// Called with a segment key when that segment is tapped.
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.subtleSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          for (final MapEntry<T, String> entry in segments.entries)
            Expanded(
              child: _Segment(
                label: entry.value,
                isSelected: entry.key == selected,
                onTap: () => onSelected(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: KumoFocusable(
          onActivate: onTap,
          borderRadius: BorderRadius.circular(4),
          mouseCursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colors.surface : const Color(0x00000000),
              border: Border.all(
                color: isSelected ? colors.border : const Color(0x00000000),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: styles.body.copyWith(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
