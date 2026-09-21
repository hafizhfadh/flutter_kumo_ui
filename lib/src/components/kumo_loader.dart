import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';

/// An indeterminate progress indicator.
///
/// A rotating arc, drawn with [CustomPaint] so the package stays free of
/// Material's `CircularProgressIndicator`. Use it for work whose duration is
/// unknown; for known progress use [KumoMeter].
///
/// The arc animates forever by design, so a widget test must `pump()` a fixed
/// duration rather than `pumpAndSettle()`, which would never settle.
class KumoLoader extends StatefulWidget {
  /// Creates a Kumo loader.
  const KumoLoader({super.key, this.size = 20, this.label});

  /// Diameter of the spinner, in logical pixels.
  final double size;

  /// Accessible description announced to assistive technology. Defaults to
  /// `'Loading'`, which is right for most screens.
  final String? label;

  @override
  State<KumoLoader> createState() => _KumoLoaderState();
}

class _KumoLoaderState extends State<KumoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return Semantics(
      label: widget.label ?? 'Loading',
      liveRegion: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: RotationTransition(
          turns: _controller,
          child: CustomPaint(
            painter: _KumoSpinnerPainter(
              track: colors.subtleSurface,
              indicator: colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _KumoSpinnerPainter extends CustomPainter {
  const _KumoSpinnerPainter({required this.track, required this.indicator});

  final Color track;
  final Color indicator;

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = math.max(2, size.shortestSide / 9);
    final Rect arc = (Offset.zero & size).deflate(stroke / 2);

    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = indicator,
    );
  }

  @override
  bool shouldRepaint(_KumoSpinnerPainter oldDelegate) =>
      oldDelegate.track != track || oldDelegate.indicator != indicator;
}
