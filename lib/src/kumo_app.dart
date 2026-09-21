import 'package:flutter/widgets.dart';

import 'theme/kumo_theme.dart';

/// A whole Kumo application in a single widget.
///
/// Equivalent to Material's `MaterialApp`: it wraps [KumoTheme] and
/// [WidgetsApp], resolves the color scheme from [mode], and derives the two
/// values a Kumo app always needs from that scheme — the OS task-switcher
/// `color` and the root `textStyle`. What stays out is everything that would
/// pull Material in.
///
/// ```dart
/// void main() {
///   runApp(KumoApp(home: const HomeScreen()));
/// }
/// ```
///
/// The default is [KumoThemeMode.system], so the app follows the platform
/// setting and repaints when it changes. Pin it, or swap either scheme, when
/// the app needs to own that decision:
///
/// ```dart
/// KumoApp(
///   dark: KumoColors.dark(primary: brandOrange),
///   mode: KumoThemeMode.dark,
///   home: const HomeScreen(),
/// )
/// ```
///
/// The widget asserts the platform boundary once, on mount, so a Flutter Web
/// build fails immediately instead of rendering an unofficial Kumo surface.
class KumoApp extends StatefulWidget {
  /// Creates a Kumo application.
  const KumoApp({
    super.key,
    this.title = '',
    this.light = const KumoColors.light(),
    this.dark = const KumoColors.dark(),
    this.mode = KumoThemeMode.system,
    this.home,
    this.routes = const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorKey,
    this.builder,
    this.debugShowCheckedModeBanner = true,
  });

  /// A one-line description of the app, used by the host operating system.
  final String title;

  /// Scheme used when the effective brightness is light.
  final KumoColors light;

  /// Scheme used when the effective brightness is dark.
  final KumoColors dark;

  /// Which scheme is in scope.
  final KumoThemeMode mode;

  /// The widget for the default route.
  final Widget? home;

  /// The app's named routes, keyed by name.
  final Map<String, WidgetBuilder> routes;

  /// Name of the first route to show.
  final String? initialRoute;

  /// Called to build a route the app does not have a builder for.
  final RouteFactory? onGenerateRoute;

  /// Called when [onGenerateRoute] fails to produce a route.
  final RouteFactory? onUnknownRoute;

  /// Key for the app's navigator, for code that needs to drive it directly.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Wraps the navigator, for injecting providers above every route.
  final TransitionBuilder? builder;

  /// Whether to paint the debug banner in debug builds.
  final bool debugShowCheckedModeBanner;

  @override
  State<KumoApp> createState() => _KumoAppState();
}

class _KumoAppState extends State<KumoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    KumoTheme.ensureSupportedPlatform();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Only system mode follows the platform; an explicit choice stays put.
    if (widget.mode == KumoThemeMode.system) {
      setState(() {});
    }
  }

  /// The scheme [mode] selects, read against the current platform brightness.
  ///
  /// The platform value is read from [WidgetsBinding] rather than `MediaQuery`
  /// because this widget builds the `WidgetsApp` that creates it.
  KumoColors get _colors {
    final bool isLight =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.light;

    return switch (widget.mode) {
      KumoThemeMode.system => isLight ? widget.light : widget.dark,
      KumoThemeMode.light => widget.light,
      KumoThemeMode.dark => widget.dark,
    };
  }

  @override
  Widget build(BuildContext context) {
    final KumoColors colors = _colors;

    return KumoTheme(
      colors: colors,
      child: WidgetsApp(
        title: widget.title,
        color: colors.canvas,
        textStyle: KumoTypography.resolve(colors).body,
        debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
        navigatorKey: widget.navigatorKey,
        home: widget.home,
        routes: widget.routes,
        initialRoute: widget.initialRoute,
        onGenerateRoute: widget.onGenerateRoute,
        onUnknownRoute: widget.onUnknownRoute,
        builder: widget.builder,
        // WidgetsApp asserts that one of `builder`, `onGenerateRoute` or
        // `pageRouteBuilder` is supplied, so KumoApp always provides the last
        // one. It is what gives every pushed route its transition.
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
            PageRouteBuilder<T>(
              settings: settings,
              pageBuilder:
                  (
                    BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) => builder(context),
            ),
      ),
    );
  }
}
