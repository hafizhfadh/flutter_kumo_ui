# kumo_ui recipes

Four complete screens. Each compiles against `kumo_ui` 1.3.0 as written.

## There is no `Scaffold`

The first thing a Material developer looks for. `kumo_ui` has no scaffold widget,
because a scaffold is mostly Material's `AppBar`/`FloatingActionButton`/`SnackBar`
machinery. A Kumo screen is composed directly, and this four-line shape is the
convention every screen in the bundled example follows:

```dart
ColoredBox(
  color: colors.canvas,          // the page background
  child: SafeArea(               // respects notches and the home indicator
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[/* sections */],
      ),
    ),
  ),
)
```

Use `KumoHeader` for the title row, `KumoModal`/`KumoBottomSheet` for dialogs, and
`KumoToastManager` for transient feedback.

---

## 1. A whole app

```dart
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

void main() => runApp(const ZonesApp());

class ZonesApp extends StatelessWidget {
  const ZonesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KumoApp(
      title: 'Zones',
      // `system` is the default; pin it when the app should own the choice.
      mode: KumoThemeMode.system,
      home: const ZoneListScreen(),
    );
  }
}
```

`KumoApp` supplies the `KumoTheme`, the navigator, the root text style and the
task-switcher color, and asserts the platform boundary on mount.

---

## 2. A list screen

```dart
class ZoneListScreen extends StatelessWidget {
  const ZoneListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);

    return ColoredBox(
      color: colors.canvas,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const KumoHeader(title: 'Zones', subtitle: '3 active'),
              const SizedBox(height: 20),
              KumoListGroup(
                title: 'Zone settings',
                children: <Widget>[
                  KumoListItem(
                    title: 'DNS records',
                    subtitle: '42 records',
                    leading: const PhosphorIcon(
                      PhosphorIconsRegular.globe,
                      size: 18,
                    ),
                    onTap: () {},
                  ),
                  const KumoListItem(title: 'Caching', subtitle: 'Standard'),
                ],
              ),
              const SizedBox(height: 20),
              Text('Resource grid', style: styles.h2),
              const SizedBox(height: 10),
              const KumoDataGrid(
                maxColumns: 3,
                children: <Widget>[
                  KumoDataCard(
                    title: 'example.com',
                    subtitle: 'Zone / Pro plan',
                    statusLabel: 'Active',
                    details: <KumoDataPair>[
                      KumoDataPair(label: 'Nameservers', value: 'ada.ns.cloudflare.com'),
                      KumoDataPair(label: 'Records', value: '42'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

The list rows keep a 56px minimum height, share one rounded outline, and grow a
trailing caret automatically because `onTap` is set.

---

## 3. A validated form

State lives in the screen; `KumoInput` is controlled and reports errors through
`errorMessage`.

```dart
class DeployForm extends StatefulWidget {
  const DeployForm({super.key});

  @override
  State<DeployForm> createState() => _DeployFormState();
}

class _DeployFormState extends State<DeployForm> {
  final TextEditingController _token = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  void _submit() {
    if (_token.text.trim().isEmpty) {
      setState(() => _error = 'An API token is required');
      return;
    }
    setState(() => _error = null);
    KumoToastManager.show(
      context,
      title: 'Worker deployed',
      message: 'kumo-worker is live on 3 routes.',
      kind: KumoToastKind.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return ColoredBox(
      color: colors.canvas,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const KumoHeader(title: 'Deploy', subtitle: 'Publish a Worker'),
              const SizedBox(height: 20),
              KumoInput(
                label: 'Api token',
                placeholder: 'Paste token',
                controller: _token,
                errorMessage: _error,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 20),
              KumoButton(
                label: 'Deploy',
                icon: PhosphorIconsRegular.rocket,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`errorMessage` as null means "no error"; a non-empty string switches the outline
to `danger` and prints the message. The error is text, not just a red border, so
it still reads for a colour-blind user.

---

## 4. A routed app with a mode toggle

`go_router` hands over a `RouterConfig`, so `KumoApp.router` takes it directly.
The subtlety worth copying: **a route builder runs once per location, not once per
app rebuild**, so app state has to reach the pages through `context`.

```dart
import 'package:go_router/go_router.dart';
import 'package:kumo_ui/kumo_ui.dart';

/// Carries the app's theme mode to routed pages.
class ModeScope extends InheritedWidget {
  const ModeScope({
    super.key,
    required this.mode,
    required this.onChanged,
    required super.child,
  });

  final KumoThemeMode mode;
  final ValueChanged<KumoThemeMode> onChanged;

  static ModeScope of(BuildContext context) {
    final ModeScope? scope =
        context.dependOnInheritedWidgetOfExactType<ModeScope>();
    assert(scope != null, 'No ModeScope above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(ModeScope oldWidget) =>
      mode != oldWidget.mode || onChanged != oldWidget.onChanged;
}

class RoutedApp extends StatefulWidget {
  const RoutedApp({super.key});

  @override
  State<RoutedApp> createState() => _RoutedAppState();
}

class _RoutedAppState extends State<RoutedApp> {
  KumoThemeMode _mode = KumoThemeMode.system;

  // Built once: a router holds the current location.
  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return KumoApp.router(
      mode: _mode,
      routerConfig: _router,
      // Above the router's pages, so a screen can read and change the mode.
      builder: (BuildContext context, Widget? child) => ModeScope(
        mode: _mode,
        onChanged: (KumoThemeMode mode) => setState(() => _mode = mode),
        child: child!,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final ModeScope scope = ModeScope.of(context);

    return ColoredBox(
      color: colors.canvas,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const KumoHeader(title: 'Kumo', subtitle: 'Routed showcase'),
              const SizedBox(height: 20),
              KumoSegmentedControl<KumoThemeMode>(
                segments: const <KumoThemeMode, String>{
                  KumoThemeMode.system: 'System',
                  KumoThemeMode.light: 'Light',
                  KumoThemeMode.dark: 'Dark',
                },
                selected: scope.mode,
                onSelected: scope.onChanged,
              ),
              const SizedBox(height: 20),
              KumoButton(
                label: 'Settings',
                variant: KumoButtonVariant.secondary,
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return ColoredBox(
      color: colors.canvas,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              KumoHeader(
                title: 'Settings',
                leading: KumoButton(
                  label: 'Back',
                  variant: KumoButtonVariant.secondary,
                  icon: PhosphorIconsRegular.arrowLeft,
                  // A deep link can land here with nothing to pop.
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Note `context.push` rather than `context.go` when you want something to pop: `go`
replaces the location and leaves an empty stack.

Under a bare `WidgetsApp`, go_router renders `NoTransitionPage`, so pages do not
animate. That is what keeps the tree Material-free.
