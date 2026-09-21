import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kumo_ui/kumo_ui.dart';

/// A two-route gallery, so a route change is observable.
GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Home page'),
            KumoButton(
              label: 'Open details',
              // push, not go: go replaces the location, leaving nothing to pop.
              onPressed: () => context.push('/details'),
            ),
          ],
        ),
      ),
    ),
    GoRoute(
      path: '/details',
      builder: (BuildContext context, GoRouterState state) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Details page'),
            KumoButton(label: 'Back', onPressed: () => context.pop()),
          ],
        ),
      ),
    ),
  ],
);

void main() {
  group('KumoApp.router', () {
    testWidgets('renders the initial route of a RouterConfig', (tester) async {
      final GoRouter router = _router();
      addTearDown(router.dispose);

      await tester.pumpWidget(KumoApp.router(routerConfig: router));

      expect(find.text('Home page'), findsOneWidget);
      expect(find.text('Details page'), findsNothing);
    });

    testWidgets('navigates and pops through the router', (tester) async {
      final GoRouter router = _router();
      addTearDown(router.dispose);

      await tester.pumpWidget(KumoApp.router(routerConfig: router));

      await tester.tap(find.text('Open details'));
      await tester.pumpAndSettle();

      expect(find.text('Details page'), findsOneWidget);
      expect(find.text('Home page'), findsNothing);
      expect(router.state.uri.path, '/details');

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Home page'), findsOneWidget);
      expect(find.text('Details page'), findsNothing);
    });

    testWidgets('puts the router in the tree, so GoRouter.of resolves', (
      tester,
    ) async {
      GoRouter? seen;
      final GoRouter router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) {
              // Only reachable when the Router was built *from* this config:
              // InheritedGoRouter is what `context.go` depends on.
              seen = GoRouter.of(context);
              return const Text('Home page');
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(KumoApp.router(routerConfig: router));

      expect(seen, same(router));
    });

    testWidgets('renders a Material-free page under a bare WidgetsApp', (
      tester,
    ) async {
      final GoRouter router = _router();
      addTearDown(router.dispose);

      await tester.pumpWidget(KumoApp.router(routerConfig: router));

      // go_router picks its page type from the app it finds itself in:
      // MaterialPage under a MaterialApp, CupertinoPage under a CupertinoApp,
      // NoTransitionPage under a plain WidgetsApp. Pages are route
      // configuration rather than widgets, so read them off the Navigator.
      final Navigator navigator = tester.widget<Navigator>(
        find.byType(Navigator).first,
      );

      expect(navigator.pages, isNotEmpty);
      expect(navigator.pages.first, isA<NoTransitionPage<void>>());
    });

    testWidgets('applies the scheme and theme on the router path too', (
      tester,
    ) async {
      KumoColors? seen;
      final GoRouter router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                Builder(
                  builder: (BuildContext context) {
                    seen = KumoTheme.of(context);
                    return const Text('Home page');
                  },
                ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        KumoApp.router(routerConfig: router, mode: KumoThemeMode.dark),
      );

      const KumoColors dark = KumoColors.dark();
      expect(seen, dark);
      expect(
        tester.widget<WidgetsApp>(find.byType(WidgetsApp)).color,
        dark.canvas,
      );
    });
  });

  group('KumoApp.router with raw Navigator 2.0 delegates', () {
    testWidgets('drives the app from a RouterDelegate', (tester) async {
      final _CounterDelegate delegate = _CounterDelegate();

      await tester.pumpWidget(
        KumoApp.router(
          routerDelegate: delegate,
          routeInformationParser: _CounterParser(),
        ),
      );

      expect(find.text('Count 0'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pumpAndSettle();

      expect(find.text('Count 1'), findsOneWidget);
    });
  });
}

/// The smallest useful [RouterDelegate]: one page backed by a counter.
class _CounterDelegate extends RouterDelegate<int>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<int> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  int _count = 0;

  @override
  int get currentConfiguration => _count;

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: <Page<void>>[
      NoTransitionPage<void>(
        key: const ValueKey<String>('counter'),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Count $_count'),
              KumoButton(
                label: 'Increment',
                onPressed: () {
                  _count++;
                  notifyListeners();
                },
              ),
            ],
          ),
        ),
      ),
    ],
    onDidRemovePage: (Page<Object?> page) {},
  );

  @override
  Future<void> setNewRoutePath(int configuration) async {
    _count = configuration;
  }
}

class _CounterParser extends RouteInformationParser<int> {
  @override
  Future<int> parseRouteInformation(RouteInformation routeInformation) async =>
      0;

  @override
  RouteInformation? restoreRouteInformation(int configuration) =>
      RouteInformation(uri: Uri.parse('/$configuration'));
}
