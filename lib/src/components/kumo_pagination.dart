import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';
import '../theme/kumo_typography.dart';
import 'kumo_button.dart';

/// A compact page switcher.
///
/// Prev and Next are [KumoButton]s that disable themselves at the ends of the
/// range, and the current position is reported in monospace so the indicator
/// keeps a stable width as the page number grows.
class KumoPagination extends StatelessWidget {
  /// Creates a pagination control.
  const KumoPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  /// The page currently displayed, 1-based.
  final int currentPage;

  /// Total number of pages. Values below 1 are treated as a single page.
  final int totalPages;

  /// Called with the requested page. Never fires outside `1..totalPages`.
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final int lastPage = totalPages < 1 ? 1 : totalPages;
    final int page = currentPage.clamp(1, lastPage);
    final bool canGoBack = page > 1;
    final bool canGoForward = page < lastPage;

    return Row(
      children: [
        KumoButton(
          label: 'Prev',
          variant: KumoButtonVariant.secondary,
          onPressed: canGoBack ? () => onPageChanged(page - 1) : null,
        ),
        Expanded(
          child: Center(
            child: Text(
              'Page $page of $lastPage',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KumoTypography.code.copyWith(color: colors.textSecondary),
            ),
          ),
        ),
        KumoButton(
          label: 'Next',
          variant: KumoButtonVariant.secondary,
          onPressed: canGoForward ? () => onPageChanged(page + 1) : null,
        ),
      ],
    );
  }
}
