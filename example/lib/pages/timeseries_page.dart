import 'dart:async';

import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../live_feed.dart';
import '../page_parts.dart';
import '../shell.dart';

/// The live timeseries route.
///
/// A simulated socket feeds [LiveSeriesFeed], which lives above the router, so
/// the series and the viewport survive a trip to another route and back.
class KumoExampleTimeseries extends StatefulWidget {
  /// Creates the live timeseries screen.
  const KumoExampleTimeseries({super.key});

  @override
  State<KumoExampleTimeseries> createState() => _KumoExampleTimeseriesState();
}

class _KumoExampleTimeseriesState extends State<KumoExampleTimeseries> {
  static const List<Duration> _windowChoices = <Duration>[
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 60),
  ];

  Timer? _axisRefresh;
  late LiveSeriesFeed _feed;

  @override
  void initState() {
    super.initState();
    // The axis is drawn from the window as it stood when this widget last
    // rebuilt — that is the price of never repainting the grid on a tick. One
    // rebuild a second keeps the tick labels honest while the line streams at
    // the frame rate.
    _axisRefresh = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      _feed.refreshDomain();
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _feed = ExampleScope.of(context).feed;
    _feed.start();
  }

  @override
  void dispose() {
    _axisRefresh?.cancel();
    // The feed outlives this page. Closing the stream keeps a hidden route from
    // doing work, while the points it already collected stay in the buffer.
    _feed.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final KumoTextStyles styles = KumoTheme.textStylesOf(context);
    final bool isRunning = _feed.isRunning;

    return KumoScaffold(
      header: ExamplePageHeader(
        title: 'Live request rate',
        subtitle: '/charts/timeseries',
        action: KumoButton(
          label: isRunning ? 'Pause stream' : 'Resume stream',
          icon: isRunning ? PhosphorIconsRegular.pause : PhosphorIconsRegular.play,
          onPressed: () => setState(_feed.toggle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              KumoBadge(
                label: isRunning ? 'Streaming' : 'Paused',
                variant: isRunning ? KumoBadgeVariant.success : KumoBadgeVariant.warning,
              ),
              Text('${_feed.sampleCount} points buffered', style: styles.caption),
              Text('latest ${_feed.latest.toStringAsFixed(1)} req/s', style: styles.caption),
              Text('t+${_feed.elapsed.toStringAsFixed(0)}s', style: styles.caption),
            ],
          ),
          const SizedBox(height: 16),
          // The chart is handed the buffer, the viewport and the controller. A
          // message repaints the series layer through the controller and touches
          // neither the grid nor the widget tree.
          KumoTimeseriesChart(
            series: _feed.series,
            window: _feed.window,
            repaint: _feed.controller,
            height: 280,
            maxPoints: 480,
          ),
          const SizedBox(height: 20),
          const ExampleSectionLabel('Viewport'),
          KumoSegmentedControl<Duration>(
            segments: <Duration, String>{
              for (final Duration choice in _windowChoices)
                choice: '${choice.inSeconds}s',
            },
            selected: _feed.windowLength,
            onSelected: (Duration choice) =>
                setState(() => _feed.setWindowLength(choice)),
          ),
          const SizedBox(height: 10),
          Text(
            'The viewport is a translation: widening it reveals more history '
            'rather than rescaling what is already drawn.',
            style: styles.bodyMuted,
          ),
          const SizedBox(height: 20),
          const ExampleSectionLabel('Buffer'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              KumoButton(
                label: 'Clear buffer',
                variant: KumoButtonVariant.secondary,
                icon: PhosphorIconsRegular.arrowCounterClockwise,
                onPressed: () => setState(_feed.clear),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Clearing drops the history but leaves the stream open. Navigating '
            'away keeps it too — the feed is owned above the router, not by '
            'this route.',
            style: styles.bodyMuted,
          ),
          if (_feed.lastError != null) ...<Widget>[
            const SizedBox(height: 16),
            KumoBanner(
              kind: KumoBannerKind.error,
              title: 'Stream error',
              message: _feed.lastError!,
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
