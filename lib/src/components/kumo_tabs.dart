import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';
import '../theme/kumo_typography.dart';
import 'kumo_focusable.dart';

/// A horizontal tab bar with a sliding accent indicator.
///
/// Each tab keeps a 48px tap height, the active tab is underlined in the brand
/// orange, and the label eases between the secondary and primary text tones
/// when the selection moves. The bar scrolls horizontally so a long set of tabs
/// never forces horizontal overflow on a phone.
class KumoTabs extends StatelessWidget {
  /// Creates a Kumo tab bar.
  const KumoTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  /// Tab labels in display order.
  final List<String> tabs;

  /// Index of the active tab.
  final int selectedIndex;

  /// Called with the index of a tapped tab.
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var index = 0; index < tabs.length; index++)
            _KumoTab(
              label: tabs[index],
              isActive: index == selectedIndex,
              onTap: () => onTabChanged(index),
            ),
        ],
      ),
    );
  }
}

class _KumoTab extends StatelessWidget {
  const _KumoTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  static const Duration _duration = Duration(milliseconds: 150);

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return Semantics(
      button: true,
      selected: isActive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: KumoFocusable(
          onActivate: onTap,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          mouseCursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: _duration,
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive ? colors.primary : const Color(0x00000000),
                  width: 2,
                ),
              ),
            ),
            child: AnimatedDefaultTextStyle(
              duration: _duration,
              curve: Curves.easeOut,
              style: KumoTypography.body.copyWith(
                color: isActive ? colors.textPrimary : colors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ),
    );
  }
}
