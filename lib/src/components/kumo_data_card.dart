import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../layout/kumo_responsive_layout.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_typography.dart';
import 'kumo_data_grid_scope.dart';
import 'kumo_focusable.dart';

/// A single labelled metadata entry rendered by [KumoDataCard].
@immutable
class KumoDataPair {
  /// Creates a label/value pair.
  const KumoDataPair({required this.label, required this.value});

  /// Left-hand or stacked label, rendered in muted micro type.
  final String label;

  /// Right-hand or stacked value, rendered in primary body type.
  final String value;
}

/// An expandable card summarising one resource.
///
/// The header is always visible and carries the resource name, an optional
/// status chip and the expansion caret. Tapping it reveals [details], which are
/// laid out as side-by-side key/value rows on desktop viewports and as stacked
/// pairs on mobile.
///
/// When rendered inside a [KumoDataGrid] cell on desktop the card drops its own
/// outline, because the grid draws the shared 1px dividers.
class KumoDataCard extends StatefulWidget {
  /// Creates an expandable resource card.
  const KumoDataCard({
    super.key,
    required this.title,
    this.subtitle,
    this.statusLabel,
    this.statusColor,
    this.details = const <KumoDataPair>[],
    this.initiallyExpanded = false,
  });

  /// Resource name shown in the header.
  final String title;

  /// Optional secondary line shown beneath [title].
  final String? subtitle;

  /// Optional status text, rendered beside a coloured dot.
  final String? statusLabel;

  /// Dot color for [statusLabel]. Defaults to the palette success color.
  ///
  /// The same color tints [statusLabel], which is text, so it must clear 4.5:1
  /// against the card fill. [KumoColors.success] and [KumoColors.warning] do;
  /// use [KumoColors.dangerText] rather than [KumoColors.danger], which is an
  /// indicator-only tone.
  final Color? statusColor;

  /// Key/value metadata revealed when the card is expanded. An empty list
  /// renders a static, non-expandable card.
  final List<KumoDataPair> details;

  /// Whether the card starts expanded.
  final bool initiallyExpanded;

  @override
  State<KumoDataCard> createState() => _KumoDataCardState();
}

class _KumoDataCardState extends State<KumoDataCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _reveal;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
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
    final canExpand = widget.details.isNotEmpty;
    final isGridCell = KumoDataGridScope.isCellOf(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: isGridCell ? null : Border.all(color: colors.border),
        borderRadius: isGridCell ? null : BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: canExpand,
            expanded: canExpand ? _isExpanded : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canExpand ? _toggle : null,
              child: KumoFocusable(
                enabled: canExpand,
                onActivate: canExpand ? _toggle : null,
                borderRadius: BorderRadius.circular(8),
                mouseCursor: canExpand
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: KumoTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                style: KumoTypography.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.statusLabel != null) ...[
                        const SizedBox(width: 12),
                        _StatusChip(
                          label: widget.statusLabel!,
                          color: widget.statusColor ?? colors.success,
                        ),
                      ],
                      if (canExpand) ...[
                        const SizedBox(width: 12),
                        PhosphorIcon(
                          _isExpanded
                              ? PhosphorIconsRegular.caretUp
                              : PhosphorIconsRegular.caretDown,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (canExpand)
            SizeTransition(
              sizeFactor: _reveal,
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: _Details(
                  details: widget.details,
                  useSideBySide: KumoResponsiveLayout.isDesktop(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.details, required this.useSideBySide});

  /// Label column width used by the side-by-side desktop arrangement.
  static const double _labelWidth = 140;

  final List<KumoDataPair> details;
  final bool useSideBySide;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < details.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          if (useSideBySide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Text(
                    details[index].label,
                    style: KumoTypography.caption.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(details[index].value, style: KumoTypography.body),
                ),
              ],
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details[index].label,
                  style: KumoTypography.caption.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(details[index].value, style: KumoTypography.body),
              ],
            ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: KumoTypography.caption.copyWith(color: color)),
      ],
    );
  }
}
