// Everything Flutter-facing comes from kumo_ui: no `package:flutter/widgets.dart`
// import is needed. The Phosphor glyph constants come from their own package,
// because that is where the icon names are declared, and go_router supplies the
// Navigator 2.0 router.
import 'package:go_router/go_router.dart';
import 'package:kumo_ui/kumo_ui.dart';

import 'live_feed.dart';
import 'pages/custom_canvas_page.dart';
import 'pages/geomap_page.dart';
import 'pages/overview_page.dart';
import 'pages/sankey_page.dart';
import 'pages/settings_page.dart';
import 'pages/timeseries_page.dart';
import 'shell.dart';

void main() {
  // Refuses to boot on Flutter Web, by design.
  KumoTheme.ensureSupportedPlatform();
  runApp(const KumoExampleApp());
}

/// Root of the Kumo UI showcase.
///
/// Uses [KumoApp] so the entire example stays free of Material, and so the
/// theme, navigator and platform-brightness wiring live in one place.
///
/// The router is Navigator 2.0 throughout: every screen is a page of one
/// `RouterConfig`, a `ShellRoute` keeps the navigation drawer mounted across
/// page changes, and the drawer drives `context.go` rather than a Navigator
/// stack.
class KumoExampleApp extends StatefulWidget {
  /// Creates the showcase app.
  const KumoExampleApp({super.key});

  @override
  State<KumoExampleApp> createState() => _KumoExampleAppState();
}

class _KumoExampleAppState extends State<KumoExampleApp> {
  KumoThemeMode _mode = KumoThemeMode.system;

  // Owned here, above the router, so the streaming chart's buffer and viewport
  // outlive the route that draws them.
  final LiveSeriesFeed _feed = LiveSeriesFeed();

  // Built once: a router holds the current location, so recreating it on every
  // rebuild would throw that state away. The routes take no arguments, because a
  // route builder runs once per location rather than once per rebuild — anything
  // a page needs reaches it through ExampleScope.
  late final GoRouter _router = GoRouter(
    initialLocation: KumoExampleDestination.overview.path,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        // The gallery is the landing page; `/` is a link, not a screen.
        redirect: (BuildContext context, GoRouterState state) =>
            KumoExampleDestination.overview.path,
      ),
      ShellRoute(
        // Built once per location, and handed the matched page. That is what
        // keeps the drawer — and everything the pages own above themselves —
        // alive across a route change.
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            KumoExampleShell(location: state.uri.path, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: KumoExampleDestination.overview.path,
            builder: (BuildContext context, GoRouterState state) =>
                const KumoExampleOverview(),
          ),
          GoRoute(
            path: KumoExampleDestination.timeseries.path,
            builder: (BuildContext context, GoRouterState state) =>
                const KumoExampleTimeseries(),
          ),
          GoRoute(
            path: KumoExampleDestination.sankey.path,
            builder: (BuildContext context, GoRouterState state) =>
                const KumoExampleSankey(),
          ),
          GoRoute(
            path: KumoExampleDestination.geomap.path,
            builder: (BuildContext context, GoRouterState state) =>
                const KumoExampleGeoMap(),
          ),
          GoRoute(
            path: KumoExampleDestination.custom.path,
            builder: (BuildContext context, GoRouterState state) =>
                const KumoExampleCustomCanvas(),
          ),
          GoRoute(
            path: KumoExampleDestination.settings.path,
            builder: (BuildContext context, GoRouterState state) =>
                const KumoExampleSettings(),
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _feed.dispose();
    super.dispose();
  }

  void _setMode(KumoThemeMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    return KumoApp.router(
      title: 'Kumo UI',
      mode: _mode,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      // Sits above the router's pages, so a routed screen can read the mode and
      // reach the live feed. Handing either to a route builder instead would go
      // stale or drop the chart's history.
      builder: (BuildContext context, Widget? child) => ExampleScope(
        mode: _mode,
        onModeChanged: _setMode,
        feed: _feed,
        child: child!,
      ),
    );
  }
}
