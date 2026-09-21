import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';

/// How a [KumoMeter] reads its value.
enum KumoMeterTone {
  /// Brand signal. The default, for usage that is neither good nor bad news.
  primary,

  /// Healthy headroom.
  success,

  /// Getting close to a limit.
  warning,

  /// At or over the limit.
  danger,
}

/// A determinate progress or usage meter.
///
/// The counterpart to [KumoLoader]: use this when the amount of work is known.
/// The fill is an indicator, not text, so the tone is free to use the palette's
/// status colours; when you label the meter, the label is text and must clear
/// AA, which is why it stays in the secondary text tone rather than following
/// the fill.
class KumoMeter extends StatelessWidget {
  /// Creates a Kumo meter.
  const KumoMeter({
    super.key,
    required this.value,
    this.label,
    this.tone = KumoMeterTone.primary,
    this.max = 1,
    this.showValue = true,
  });

  /// Current value, clamped to `0..max`.
  final double value;

  /// Optional label rendered above the track.
  final String? label;

  /// Which tone the fill uses.
  final KumoMeterTone tone;

  /// Value that represents a full meter. Defaults to `1`, so [value] can be a
  /// fraction.
  final double max;

  /// Whether the percentage is printed beside [label].
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);

    final double ratio = max <= 0 ? 0 : (value / max).clamp(0.0, 1.0);
    final int percent = (ratio * 100).round();
    final Color fill = switch (tone) {
      KumoMeterTone.primary => colors.primary,
      KumoMeterTone.success => colors.success,
      KumoMeterTone.warning => colors.warning,
      KumoMeterTone.danger => colors.danger,
    };

    return Semantics(
      label: label,
      value: '$percent%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (label != null || showValue) ...[
            Row(
              children: <Widget>[
                if (label != null)
                  Expanded(
                    child: Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: styles.caption,
                    ),
                  )
                else
                  const Spacer(),
                if (showValue)
                  Text(
                    '$percent%',
                    style: styles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0x00000000)),
                  ),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) =>
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            width: constraints.maxWidth * ratio,
                            decoration: BoxDecoration(
                              color: fill,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
