import 'package:go_router/go_router.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'live_feed.dart';

/// Every destination the shell offers, and the route path behind it.
///
/// One list, read by both the router and the drawer, so the highlight cannot
/// drift away from the route: the drawer marks the entry whose [path] equals
/// the active location, and the router builds a page per entry from the same
/// constant.
enum KumoExampleDestination {
  /// The component gallery.
  overview('/overview', 'Gallery', PhosphorIconsRegular.squaresFour),

  /// The live streaming timeseries.
  timeseries('/charts/timeseries', 'Realtime series', PhosphorIconsRegular.chartLine),

  /// The Sankey flow network.
  sankey('/charts/sankey', 'Flow network', PhosphorIconsRegular.flowArrow),

  /// The vector choropleth.
  geomap('/charts/geomap', 'Vector map', PhosphorIconsRegular.mapTrifold),

  /// The custom canvas visualiser.
  custom('/charts/custom', 'Custom canvas', PhosphorIconsRegular.paintBrush),

  /// App settings.
  settings('/settings', 'Settings', PhosphorIconsRegular.gear);

  const KumoExampleDestination(this.path, this.label, this.icon);

  /// Location this destination is routed at.
  final String path;

  /// Drawer label and page title.
  final String label;

  /// Glyph shown beside [label].
  final PhosphorIconData icon;

  /// The destination routed at [location], or null when nothing matches.
  static KumoExampleDestination? forLocation(String location) {
    for (final KumoExampleDestination destination in values) {
      if (destination.path == location) {
        return destination;
      }
    }
    return null;
  }
}

/// Carries the app-owned state to every routed page.
///
/// A route builder runs once per location, not once per rebuild, so a page
/// cannot receive the theme mode or the feed as a constructor argument without
/// going stale or losing its buffers. Handing them down through the tree above
/// the router is what keeps both the mode selector and the chart history alive
/// across navigation.
class ExampleScope extends InheritedWidget {
  /// Creates the scope.
  const ExampleScope({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.feed,
    required super.child,
  });

  /// The scheme the app is currently painting.
  final KumoThemeMode mode;

  /// Called when a page reports a new mode.
  final ValueChanged<KumoThemeMode> onModeChanged;

  /// The app-level live timeseries.
  final LiveSeriesFeed feed;

  /// The nearest scope above [context].
  static ExampleScope of(BuildContext context) {
    final ExampleScope? scope = context
        .dependOnInheritedWidgetOfExactType<ExampleScope>();
    assert(scope != null, 'No ExampleScope above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(ExampleScope oldWidget) =>
      mode != oldWidget.mode ||
      onModeChanged != oldWidget.onModeChanged ||
      feed != oldWidget.feed;
}

/// The persistent navigation shell every routed page is placed inside.
///
/// A `ShellRoute` builds this once per location and hands it the matched page,
/// so the [KumoDrawer] — and the scroll position, and the live chart — survive
/// a route change instead of being rebuilt with the page. [location] is the
/// active route path, which is the single input the highlight needs.
class KumoExampleShell extends StatelessWidget {
  /// Creates the shell.
  const KumoExampleShell({super.key, required this.location, required this.child});

  /// The active route path.
  final String location;

  /// The matched page.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final KumoColors colors = KumoTheme.of(context);
    final KumoTextStyles styles = KumoTheme.textStylesOf(context);
    final KumoExampleDestination? active = KumoExampleDestination.forLocation(location);

    return KumoDrawerScaffold(
      // Built inside a Builder so the rows can reach the scaffold: closing a
      // sheet goes through the scaffold's own scope, and this widget's build
      // context sits above it.
      drawer: Builder(
        builder: (BuildContext drawerContext) {
          Widget item(KumoExampleDestination destination) => KumoDrawerItem(
            label: destination.label,
            icon: destination.icon,
            isSelected: destination == active,
            onTap: () {
              // Close first where the drawer is a sheet, so the page is not
              // revealed underneath an open one. Harmless where it is docked.
              KumoDrawerScaffold.close(drawerContext);
              drawerContext.go(destination.path);
            },
          );

          return KumoDrawer(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Kumo UI', style: styles.h2),
                const SizedBox(height: 2),
                Text(
                  'Example shell',
                  style: styles.caption.copyWith(color: colors.textMuted),
                ),
              ],
            ),
            footer: item(KumoExampleDestination.settings),
            children: <Widget>[
              KumoDrawerGroup(
                label: 'Views',
                children: <Widget>[item(KumoExampleDestination.overview)],
              ),
              KumoDrawerGroup(
                label: 'Charts',
                children: <Widget>[
                  item(KumoExampleDestination.timeseries),
                  item(KumoExampleDestination.sankey),
                  item(KumoExampleDestination.geomap),
                  item(KumoExampleDestination.custom),
                ],
              ),
            ],
          );
        },
      ),
      child: child,
    );
  }
}
