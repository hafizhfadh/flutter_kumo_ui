import 'package:flutter/widgets.dart';

/// The chart colour systems, ported from Cloudflare Kumo's chart tokens.
///
/// Three systems, because a chart makes three different colour decisions:
///
/// - **Semantic** ([attention], [warning], [success]) for data that already has
///   polarity — pass/fail, healthy/degraded. Derived from the status tokens but
///   less saturated, so a dashboard of charts does not read as a dashboard of
///   alarms.
/// - **Categorical** ([categorical]) for nominal series with no order. Ordered
///   for perceptual distance between adjacent slots, and tested against a colour
///   vision deficiency simulator upstream, which is why a series palette is not
///   something to improvise.
/// - **Sequential** ([sequential]) for one metric varying in magnitude, such as
///   a choropleth. Darker encodes higher in light mode; lighter encodes higher
///   in dark mode, so the most prominent step is always the largest value.
///
/// The palette is scheme-independent: the same slots are used in light and dark,
/// which is why it is not threaded through [KumoColors].
///
/// Colour is never the only signal. When two series share a chart, differ them
/// with a dash or dot pattern as well, and avoid patterns on the lighter slots
/// because they fade.
@immutable
class KumoChartColors {
  /// Creates the Kumo chart palette.
  const KumoChartColors();

  /// Needs attention. `#FC574A`.
  Color get attention => const Color(0xFFFC574A);

  /// Degraded or approaching a limit. `#F8A054`.
  Color get warning => const Color(0xFFF8A054);

  /// Healthy or completed. `#00A63E`.
  Color get success => const Color(0xFF00A63E);

  /// Neutral comparison data. `#B9D6FF`.
  Color get neutral => const Color(0xFFB9D6FF);

  /// Nominal series colours, in slot order.
  static const List<Color> categorical = <Color>[
    Color(0xFF4290F0),
    Color(0xFFF5B647),
    Color(0xFFE8649D),
    Color(0xFF8D58EE),
    Color(0xFF50C3B6),
  ];

  /// Magnitude steps, light to dark.
  static const List<Color> sequential = <Color>[
    Color(0xFFE1EAF4),
    Color(0xFF8EBCF6),
    Color(0xFF4290F0),
    Color(0xFF0E58B4),
    Color(0xFF03254F),
  ];

  /// The categorical slot for the [index]th series.
  ///
  /// Cycles with a modulo rather than widening the palette, which is what keeps
  /// series three and series eight looking the same across charts.
  Color categoricalAt(int index) =>
      categorical[index % categorical.length];

  /// The sequential step for [index], where `0` is the lightest.
  Color sequentialAt(int index) =>
      sequential[index.clamp(0, sequential.length - 1)];

  /// [sequential] reversed, which is the dark-mode magnitude order.
  static const List<Color> sequentialDark = <Color>[
    Color(0xFF03254F),
    Color(0xFF0E58B4),
    Color(0xFF4290F0),
    Color(0xFF8EBCF6),
    Color(0xFFE1EAF4),
  ];

  /// The magnitude steps for [brightness], ordered so the last entry is the
  /// largest value.
  ///
  /// Light mode darkens with magnitude and dark mode lightens, so the step that
  /// stands out most is always the biggest number. A choropleth that used
  /// [sequential] in both schemes would read upside down in the dark.
  static List<Color> sequentialFor(Brightness brightness) =>
      brightness == Brightness.dark ? sequentialDark : sequential;

  /// The palette index for [value] across a `min`..`max` domain.
  ///
  /// Magnitude has to pick a step by *where it sits on the scale*. Stepping the
  /// list with a counter instead would cycle the palette, so the fourth region
  /// parsed would look exactly like the largest one.
  ///
  /// A domain with no span, or a value that is not finite, resolves to the most
  /// prominent step: one number has no distribution to place it in.
  static int sequentialIndex(double value, double min, double max) {
    final int steps = sequential.length;
    if (!value.isFinite || !max.isFinite || !min.isFinite || max <= min) {
      return steps - 1;
    }
    final double position = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return (position * (steps - 1)).round();
  }
}
