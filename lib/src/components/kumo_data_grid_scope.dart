import 'package:flutter/widgets.dart';

/// Internal marker that tells a card it is being laid out as a grid cell.
///
/// `KumoDataGrid` owns the 1px dividers on desktop, so cards inside a cell must
/// drop their own outline to avoid doubling the lines. The scope is applied
/// only on the desktop branch, which lets the very same card widget keep its
/// outline when the grid falls back to the stacked mobile branch.
///
/// This is plumbing shared between `kumo_data_card.dart` and
/// `kumo_data_grid.dart`; it is intentionally not re-exported from
/// `kumo_ui.dart`.
@immutable
class KumoDataGridScope extends InheritedWidget {
  /// Creates a scope that reports [isCell] to descendant widgets.
  const KumoDataGridScope({
    super.key,
    required this.isCell,
    required super.child,
  });

  /// Whether descendants are laid out as cells of a bordered grid.
  final bool isCell;

  /// Whether the nearest [KumoDataGridScope] marks this subtree as a grid cell.
  static bool isCellOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<KumoDataGridScope>()
            ?.isCell ??
        false;
  }

  @override
  bool updateShouldNotify(KumoDataGridScope oldWidget) =>
      isCell != oldWidget.isCell;
}
