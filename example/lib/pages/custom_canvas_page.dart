import 'dart:async';
import 'dart:math' as math;

import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../page_parts.dart';

/// The custom canvas route: a bespoke visualiser drawn straight onto a
/// [Canvas] through [KumoCanvas].
///
/// The chart manages everything around the drawing — the surface, the plot
/// rect, the gridlines and ticks, the tokens, and the repaint split — and the
/// painter below only decides what the bars look like.
class KumoExampleCustomCanvas extends StatefulWidget {
  /// Creates the custom visualiser screen.
  const KumoExampleCustomCanvas({super.key});

  @override
  State<KumoExampleCustomCanvas> createState() =>
      _KumoExampleCustomCanvasState();
}

class _KumoExampleCustomCanvasState extends State<KumoExampleCustomCanvas> {
  static const int _bucketCount = 24;
  static const Duration _tick = Duration(milliseconds: 50);
  static const List<double> _thresholdChoices = <double>[120, 160, 200];

  /// The chart palette is scheme-independent, so one const instance serves both.
  static const KumoChartColors _palette = KumoChartColors();

  /// The frame-coalesced repaint signal, exactly as the built-in charts use it.
  final KumoChartController<double> _repaint = KumoChartController<double>(
    capacity: 64,
  );
  final List<double> _values = List<double>.filled(_bucketCount, 0);
  final math.Random _random = math.Random(7);

  // Everything the paint pass touches is allocated here, once. A Paint or a
  // Path built inside the painter would be built every frame.
  final Paint _barPaint = Paint();
  final Paint _trendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeJoin = StrokeJoin.round;
  final Paint _thresholdPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Path _bars = Path();
  final Path _trend = Path();
  final Path _thresholdLine = Path();

  Timer? _animation;
  double _threshold = 160;
  double _peak = 1;
  int _phase = 0;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _sample();
    _start();
  }

  @override
  void dispose() {
    _animation?.cancel();
    _repaint.dispose();
    super.dispose();
  }

  void _start() {
    _animation?.cancel();
    _animation = Timer.periodic(_tick, (_) => _sample());
  }

  void _toggle() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _start();
      } else {
        _animation?.cancel();
        _animation = null;
      }
    });
  }

  /// Recomputes the buckets and asks the canvas to repaint.
  void _sample() {
    _phase++;
    for (int i = 0; i < _bucketCount; i++) {
      final double t = (_phase + i * 7) * 0.12;
      _values[i] =
          150 + 90 * math.sin(t / 2.4) + 40 * math.sin(t * 1.7) + 18 * math.cos(t * 0.6);
    }
    _recomputePeak();
    // Appending through the controller coalesces to one repaint per frame and
    // rebuilds no widget.
    _repaint.append(_peak);
  }

  void _shuffle() {
    for (int i = 0; i < _bucketCount; i++) {
      _values[i] = 40 + _random.nextDouble() * 210;
    }
    _recomputePeak();
    setState(() {});
    _repaint.append(_peak);
  }

  void _recomputePeak() {
    double peak = _threshold;
    for (int i = 0; i < _bucketCount; i++) {
      if (_values[i] > peak) {
        peak = _values[i];
      }
    }
    // A little headroom keeps the tallest bar off the top edge.
    _peak = peak * 1.05;
  }

  /// Draws the buckets. No `Paint`, `Path` or `Rect` is created in here.
  void _paint(Canvas canvas, Size size, KumoChartContext context) {
    final Rect plot = context.geometry.plot;
    if (plot.isEmpty) {
      return;
    }

    final double slot = plot.width / _bucketCount;
    final double inset = slot * 0.18;

    _barPaint.color = context.colors.primary.withValues(alpha: 0.85);
    _trendPaint.color = _palette.categoricalAt(1);
    _thresholdPaint.color = context.colors.warning;

    _bars.reset();
    _trend.reset();
    for (int i = 0; i < _bucketCount; i++) {
      final double ratio = (_values[i] / _peak).clamp(0.0, 1.0);
      final double left = plot.left + i * slot + inset;
      final double right = plot.left + (i + 1) * slot - inset;
      final double top = plot.bottom - plot.height * ratio;

      // A rectangle as four segments: no RRect and no Rect, so nothing is
      // allocated per bar per frame.
      _bars
        ..moveTo(left, plot.bottom)
        ..lineTo(left, top)
        ..lineTo(right, top)
        ..lineTo(right, plot.bottom)
        ..close();

      if (i == 0) {
        _trend.moveTo((left + right) / 2, top);
      } else {
        _trend.lineTo((left + right) / 2, top);
      }
    }

    canvas.drawPath(_bars, _barPaint);
    canvas.drawPath(_trend, _trendPaint);

    final double thresholdY =
        plot.bottom - plot.height * (_threshold / _peak).clamp(0.0, 1.0);
    _thresholdLine
      ..reset()
      ..moveTo(plot.left, thresholdY)
      ..lineTo(plot.right, thresholdY);
    canvas.drawPath(_thresholdLine, _thresholdPaint);
  }

  @override
  Widget build(BuildContext context) {
    final KumoTextStyles styles = KumoTheme.textStylesOf(context);

    return KumoScaffold(
      header: ExamplePageHeader(
        title: 'Custom visualiser',
        subtitle: '/charts/custom',
        action: KumoButton(
          label: _isRunning ? 'Pause' : 'Resume',
          icon: _isRunning ? PhosphorIconsRegular.pause : PhosphorIconsRegular.play,
          onPressed: _toggle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Buckets of request volume, drawn with raw Canvas calls. The grid, '
            'the ticks, the surface and the repaint split are the chart\'s.',
            style: styles.bodyMuted,
          ),
          const SizedBox(height: 16),
          KumoCanvas(
            repaint: _repaint,
            height: 260,
            gridDivisions: 4,
            painter: _paint,
            overlay: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: <Widget>[
                  Text('peak ${_peak.toStringAsFixed(0)}', style: styles.caption),
                  const SizedBox(width: 12),
                  Text(
                    'threshold ${_threshold.toStringAsFixed(0)}',
                    style: styles.caption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const ExampleSectionLabel('Threshold'),
          KumoSegmentedControl<double>(
            segments: <double, String>{
              for (final double choice in _thresholdChoices)
                choice: choice.toStringAsFixed(0),
            },
            selected: _threshold,
            onSelected: (double choice) => setState(() {
              _threshold = choice;
              _recomputePeak();
              _repaint.append(_peak);
            }),
          ),
          const SizedBox(height: 20),
          const ExampleSectionLabel('Drawing'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              KumoButton(
                label: 'Shuffle buckets',
                variant: KumoButtonVariant.secondary,
                icon: PhosphorIconsRegular.shuffle,
                onPressed: _shuffle,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'The painter holds its Paint and Path objects as fields and only '
            'mutates them, so a tick costs no allocations in the paint pass.',
            style: styles.caption,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
