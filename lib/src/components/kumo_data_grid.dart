import 'package:flutter/widgets.dart';

import '../layout/kumo_responsive_layout.dart';
import '../theme/kumo_theme.dart';
import 'kumo_data_grid_scope.dart';

/// Lays a collection of resource cards out adaptively.
///
/// Below [breakpoint] the children stack vertically with 12px between them,
/// which keeps every card full width and avoids horizontal overflow on phones.
/// At or above [breakpoint] they are laid out as a multi-column grid whose cells
/// share 1px dividers in the border color, and each cell is marked with a
/// [KumoDataGridScope] so cards drop their own outline.
class KumoDataGrid extends StatelessWidget {
  /// Creates an adaptive grid of [children].
  const KumoDataGrid({
    super.key,
    required this.children,
    this.maxColumns = 3,
    this.breakpoint = kKumoBreakpoint,
  });

  /// Narrowest comfortable cell width, used to derive the column count.
  static const double _minCellWidth = 260;

  /// Cards to lay out, usually [KumoDataCard] widgets.
  final List<Widget> children;

  /// Upper bound on how many columns the desktop grid may use.
  final int maxColumns;

  /// Width in logical pixels at which the grid stops stacking.
  final double breakpoint;

  int _columnCount(double width) {
    final fitted = width ~/ _minCellWidth;
    if (fitted < 1) {
      return 1;
    }
    return fitted > maxColumns ? maxColumns : fitted;
  }

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                children[index],
              ],
            ],
          );
        }

        final columns = _columnCount(constraints.maxWidth);
        final rows = <TableRow>[];
        for (var start = 0; start < children.length; start += columns) {
          rows.add(
            TableRow(
              children: <Widget>[
                for (var column = 0; column < columns; column++)
                  start + column < children.length
                      ? children[start + column]
                      : const SizedBox.shrink(),
              ],
            ),
          );
        }

        return KumoDataGridScope(
          isCell: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Table(
              border: TableBorder.all(
                color: colors.border,
                borderRadius: BorderRadius.circular(8),
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.fill,
              columnWidths: <int, TableColumnWidth>{
                for (var column = 0; column < columns; column++)
                  column: const FlexColumnWidth(),
              },
              children: rows,
            ),
          ),
        );
      },
    );
  }
}
