// Everything Flutter-facing comes from kumo_ui: no `package:flutter/widgets.dart`
// import is needed. Only the Phosphor glyph constants come from elsewhere,
// because that is where the icon names are declared.
import 'package:go_router/go_router.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

void main() {
  // Refuses to boot on Flutter Web, by design.
  KumoTheme.ensureSupportedPlatform();
  runApp(const KumoExampleApp());
}

/// Root of the Kumo UI showcase.
///
/// Uses [KumoApp] so the entire example stays free of Material, and so the
/// theme, navigator and platform-brightness wiring live in one place.
class KumoExampleApp extends StatefulWidget {
  /// Creates the showcase app.
  const KumoExampleApp({super.key});

  @override
  State<KumoExampleApp> createState() => _KumoExampleAppState();
}

class _KumoExampleAppState extends State<KumoExampleApp> {
  KumoThemeMode _mode = KumoThemeMode.system;

  // Built once: a router holds the current location, so recreating it on every
  // rebuild would throw that state away. Note that the routes take no
  // arguments: a route builder runs once per location, not once per rebuild of
  // this State, so anything a page needs has to reach it through context.
  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const KumoExampleHome(),
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) => const KumoExampleSettings(),
      ),
    ],
  );

  void _setMode(KumoThemeMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    return KumoApp.router(
      title: 'Kumo UI',
      mode: _mode,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      // Sits above the router's pages, so a routed screen can read and change
      // the mode. Handing it to a route builder instead would go stale.
      builder: (BuildContext context, Widget? child) => _ModeScope(mode: _mode, onChanged: _setMode, child: child!),
    );
  }
}

/// Scrollable screen exercising every component in the library.
class KumoExampleHome extends StatefulWidget {
  /// Creates the showcase screen.
  const KumoExampleHome({super.key});

  @override
  State<KumoExampleHome> createState() => _KumoExampleHomeState();
}

class _KumoExampleHomeState extends State<KumoExampleHome> {
  final TextEditingController _token = TextEditingController();

  String _segment = 'overview';
  String _plan = 'free';
  bool _notificationsEnabled = true;
  bool _cachingEnabled = true;
  bool _inlineToastVisible = true;
  int _tabIndex = 0;
  int _page = 2;
  String? _lastSheetAction;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  void _reset() {
    _token.clear();
    setState(() {
      _segment = 'overview';
      _plan = 'free';
      _notificationsEnabled = false;
      _cachingEnabled = false;
      _inlineToastVisible = true;
      _tabIndex = 0;
      _page = 2;
      _lastSheetAction = null;
    });
  }

  void _showToast(KumoToastKind kind) {
    KumoToastManager.show(
      context,
      title: switch (kind) {
        KumoToastKind.info => 'Sync queued',
        KumoToastKind.success => 'Worker deployed',
        KumoToastKind.warning => 'Quota nearly spent',
        KumoToastKind.error => 'Deploy failed',
      },
      message: 'kumo-worker is live on 3 routes.',
      kind: kind,
    );
    // Rebuild so the active count below reflects the new stack.
    setState(() {});
  }

  void _clearToasts() {
    KumoToastManager.clear();
    setState(() {});
  }

  Future<void> _openSheet() async {
    final String? action = await KumoBottomSheet.show<String>(
      context: context,
      title: 'Zone actions',
      child: Builder(
        builder: (BuildContext sheetContext) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final String label in <String>['Rename', 'Duplicate', 'Delete'])
              KumoBottomSheetItem(label: label, onTap: () => Navigator.of(sheetContext).pop(label)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action != null && mounted) {
      setState(() => _lastSheetAction = action);
    }
  }

  void _openDialog() {
    KumoModal.show<void>(
      context: context,
      title: 'Deploy worker',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This dialog is drawn from a RawDialogRoute, so no Material '
            'scaffolding is involved.',
            style: KumoTheme.textStylesOf(context).bodyMuted,
          ),
          const SizedBox(height: 16),
          const KumoCodeBlock(code: 'npx wrangler deploy', language: 'bash'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final styles = KumoTheme.textStylesOf(context);
    final _ModeScope modeScope = _ModeScope.of(context);
    final bool isLight = colors.brightness == Brightness.light;

    final edgeRules = KumoListGroup(
      title: 'Edge rules',
      children: [
        KumoListItem(
          title: 'Always use HTTPS',
          subtitle: 'On',
          leading: const PhosphorIcon(PhosphorIconsRegular.shieldCheck, size: 18),
          onTap: () {},
        ),
        const KumoListItem(title: 'Automatic HTTPS rewrites', subtitle: 'On'),
      ],
    );

    final cachingRules = KumoListGroup(
      title: 'Caching rules',
      children: [
        KumoListItem(
          title: 'Cache level',
          subtitle: 'Standard',
          leading: const PhosphorIcon(PhosphorIconsRegular.lightning, size: 18),
          onTap: () {},
        ),
        const KumoListItem(title: 'Browser cache TTL', subtitle: '4 hours'),
      ],
    );

    // The raw scale is per-scheme, so the swatches follow the active one.
    final List<(String, Color)> accents = isLight
        ? <(String, Color)>[
            ('orange5', KumoLightPalette.orange5),
            ('blue5', KumoLightPalette.blue5),
            ('green5', KumoLightPalette.green5),
            ('amber5', KumoLightPalette.amber5),
            ('red5', KumoLightPalette.red5),
          ]
        : <(String, Color)>[
            ('orange5', KumoPalette.orange5),
            ('blue5', KumoPalette.blue5),
            ('green5', KumoPalette.green5),
            ('amber5', KumoPalette.amber5),
            ('red5', KumoPalette.red5),
          ];

    return ColoredBox(
      color: colors.canvas,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KumoHeader(
                title: 'Kumo UI',
                subtitle: 'A widgets-only take on the Cloudflare dashboard.',
                action: KumoButton(
                  label: 'Reset fields',
                  variant: KumoButtonVariant.secondary,
                  icon: PhosphorIconsRegular.arrowCounterClockwise,
                  onPressed: _reset,
                ),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Theme'),
              KumoSegmentedControl<KumoThemeMode>(
                segments: const <KumoThemeMode, String>{
                  KumoThemeMode.system: 'System',
                  KumoThemeMode.light: 'Light',
                  KumoThemeMode.dark: 'Dark',
                },
                selected: modeScope.mode,
                onSelected: modeScope.onChanged,
              ),
              const SizedBox(height: 10),
              Text('Painting the ${isLight ? 'light' : 'dark'} scheme.', style: styles.caption),
              const SizedBox(height: 28),
              const _SectionLabel('Navigation'),
              KumoButton(
                label: 'Open settings',
                variant: KumoButtonVariant.secondary,
                icon: PhosphorIconsRegular.arrowRight,
                onPressed: () => context.push('/settings'),
              ),
              const SizedBox(height: 10),
              Text('Pushed onto the go_router stack.', style: styles.caption),
              const SizedBox(height: 28),
              const _SectionLabel('Segmented control'),
              KumoSegmentedControl<String>(
                segments: const <String, String>{'overview': 'Overview', 'dns': 'DNS', 'workers': 'Workers'},
                selected: _segment,
                onSelected: (value) => setState(() => _segment = value),
              ),
              const SizedBox(height: 10),
              Text('Showing the $_segment view.', style: styles.caption),
              const SizedBox(height: 28),
              const _SectionLabel('Text input'),
              KumoInput(
                label: 'Api token',
                placeholder: 'Paste token',
                controller: _token,
                prefixIcon: PhosphorIcon(PhosphorIconsRegular.key, size: 16, color: colors.textSecondary),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              KumoInput(
                label: 'Account id',
                placeholder: '32 character hex id',
                obscureText: true,
                errorMessage: _token.text.isEmpty ? 'Required to deploy' : null,
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Toggle'),
              Row(
                children: [
                  Expanded(child: Text('Notifications', style: styles.body)),
                  KumoSwitch(
                    value: _notificationsEnabled,
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Analytics', style: styles.body)),
                  const KumoSwitch(value: true, onChanged: _noop, isDisabled: true),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Accordion'),
              const KumoAccordion(
                title: 'Advanced settings',
                child: Text(
                  'Changes here apply to every request routed through the '
                  'selected zone.',
                ),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('List group'),
              KumoListGroup(
                title: 'Zone settings',
                children: [
                  const KumoListItem(title: 'DNS records', subtitle: '42 records'),
                  const KumoListItem(title: 'Caching', subtitle: 'Standard'),
                  KumoListItem(
                    title: 'Add a record',
                    leading: const PhosphorIcon(PhosphorIconsRegular.plus, size: 18),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Resource grid'),
              KumoDataGrid(
                maxColumns: 3,
                children: [
                  const KumoDataCard(
                    title: 'example.com',
                    subtitle: 'Zone · Pro plan',
                    statusLabel: 'Active',
                    details: [
                      KumoDataPair(label: 'Nameservers', value: 'ada.ns.cloudflare.com'),
                      KumoDataPair(label: 'Records', value: '42'),
                    ],
                  ),
                  KumoDataCard(
                    title: 'Global DNS',
                    subtitle: 'Zone · Free plan',
                    statusLabel: 'Pending',
                    // An explicit status chip color, instead of the default.
                    statusColor: colors.warning,
                    initiallyExpanded: true,
                    details: const [KumoDataPair(label: 'Nameservers', value: 'bob.ns.cloudflare.com')],
                  ),
                  const KumoDataCard(
                    title: 'workers.dev',
                    subtitle: 'Worker · Bundled',
                    statusLabel: 'Active',
                    details: [
                      KumoDataPair(label: 'Routes', value: '3'),
                      KumoDataPair(label: 'Requests', value: '1.2M'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Responsive split'),
              KumoResponsiveLayout(
                breakpoint: kKumoBreakpoint,
                mobile: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [edgeRules, const SizedBox(height: 12), cachingRules],
                ),
                desktop: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: edgeRules),
                    const SizedBox(width: 16),
                    Expanded(child: cachingRules),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Breadcrumb'),
              KumoBreadcrumb(
                items: <KumoBreadcrumbItem>[
                  KumoBreadcrumbItem(label: 'Accounts', onTap: () => setState(() => _tabIndex = 0)),
                  KumoBreadcrumbItem(label: 'example.com', onTap: () => setState(() => _tabIndex = 1)),
                  const KumoBreadcrumbItem(label: 'DNS'),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Tabs'),
              KumoTabs(
                tabs: const <String>['General', 'Traffic', 'Security'],
                selectedIndex: _tabIndex,
                onTabChanged: (int index) => setState(() => _tabIndex = index),
              ),
              const SizedBox(height: 12),
              Text('Tab index $_tabIndex is selected.', style: styles.caption),
              const SizedBox(height: 28),
              const _SectionLabel('Badges'),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  KumoBadge(label: 'Pro plan', variant: KumoBadgeVariant.info),
                  KumoBadge(label: 'Active', variant: KumoBadgeVariant.success, icon: PhosphorIconsRegular.checkCircle),
                  KumoBadge(label: 'Proxied', variant: KumoBadgeVariant.warning),
                  KumoBadge(
                    label: 'Errored',
                    variant: KumoBadgeVariant.error,
                    icon: PhosphorIconsRegular.warningCircle,
                  ),
                  KumoBadge(label: 'Draft'),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Checkbox and select'),
              KumoCheckbox(
                value: _cachingEnabled,
                label: 'Enable caching',
                onChanged: (bool value) => setState(() => _cachingEnabled = value),
              ),
              const SizedBox(height: 12),
              const KumoCheckbox(value: true, label: 'Always online', onChanged: _noop, isDisabled: true),
              const SizedBox(height: 12),
              KumoSelect<String>(
                value: _plan,
                label: 'Plan',
                options: const <String, String>{'free': 'Free', 'pro': 'Pro', 'business': 'Business'},
                onChanged: (String value) => setState(() => _plan = value),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Pagination'),
              KumoPagination(
                currentPage: _page,
                totalPages: 5,
                onPageChanged: (int page) => setState(() => _page = page),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Bottom sheet'),
              KumoButton(
                label: 'Zone actions',
                variant: KumoButtonVariant.secondary,
                icon: PhosphorIconsRegular.caretUp,
                onPressed: _openSheet,
              ),
              if (_lastSheetAction != null) ...[
                const SizedBox(height: 10),
                Text('Chose $_lastSheetAction.', style: styles.caption),
              ],
              const SizedBox(height: 28),
              const _SectionLabel('Toast'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  KumoButton(
                    label: 'Show success toast',
                    icon: PhosphorIconsRegular.checkCircle,
                    onPressed: () => _showToast(KumoToastKind.success),
                  ),
                  KumoButton(
                    label: 'Info',
                    variant: KumoButtonVariant.secondary,
                    onPressed: () => _showToast(KumoToastKind.info),
                  ),
                  KumoButton(
                    label: 'Warning',
                    variant: KumoButtonVariant.secondary,
                    onPressed: () => _showToast(KumoToastKind.warning),
                  ),
                  KumoButton(
                    label: 'Error',
                    variant: KumoButtonVariant.secondary,
                    onPressed: () => _showToast(KumoToastKind.error),
                  ),
                  KumoButton(label: 'Clear toasts', variant: KumoButtonVariant.secondary, onPressed: _clearToasts),
                ],
              ),
              const SizedBox(height: 10),
              Text('Active toasts: ${KumoToastManager.activeCount}', style: styles.caption),
              const SizedBox(height: 12),
              // The banner itself, rendered in place rather than queued.
              if (_inlineToastVisible)
                KumoToast(
                  title: 'Inline banner',
                  message: 'Rendered directly, not pushed to the overlay.',
                  kind: KumoToastKind.info,
                  onClose: () => setState(() => _inlineToastVisible = false),
                )
              else
                KumoButton(
                  label: 'Restore inline banner',
                  variant: KumoButtonVariant.secondary,
                  onPressed: () => setState(() => _inlineToastVisible = true),
                ),
              const SizedBox(height: 28),
              const _SectionLabel('Code block'),
              const KumoCodeBlock(code: 'npx wrangler deploy --env production', language: 'bash'),
              const SizedBox(height: 12),
              const KumoCodeBlock(code: 'console.log("copy me")'),
              const SizedBox(height: 28),
              const _SectionLabel('Palette'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  for (final (String name, Color swatch) in accents)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: swatch,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: colors.border),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(name, style: styles.caption),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Primitives'),
              const KumoLabel('Field label'),
              const SizedBox(height: 12),
              KumoLink(
                label: 'View the deployment logs',
                icon: PhosphorIconsRegular.arrowUpRight,
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              const KumoSkeleton(lines: 2),
              const SizedBox(height: 12),
              const KumoMeter(label: 'Cache hit rate', value: 0.72),
              const SizedBox(height: 12),
              const KumoEmpty(
                title: 'No logs yet',
                message: 'Requests appear here once the Worker takes traffic.',
                icon: PhosphorIconsRegular.tray,
              ),
              const SizedBox(height: 12),
              KumoSensitiveInput(label: 'Api token', placeholder: 'Paste a token'),
              const SizedBox(height: 12),
              KumoRadio<String>(
                value: 'standard',
                groupValue: 'standard',
                label: 'Standard caching',
                onChanged: (String _) {},
              ),
              const SizedBox(height: 12),
              KumoTooltip(
                message: 'Publishes the Worker to every route',
                child: KumoButton(
                  label: 'Deploy',
                  variant: KumoButtonVariant.secondary,
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: 12),
              KumoBanner(
                kind: KumoBannerKind.warning,
                title: 'Quota nearly spent',
                message: 'This zone has 8% of its monthly requests left.',
                onDismiss: () {},
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Modal'),
              KumoButton(label: 'Open dialog', icon: PhosphorIconsRegular.arrowSquareOut, onPressed: _openDialog),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  static void _noop(bool _) {}
}

/// The second route, reached by pushing '/settings' rather than a Navigator 1.0
/// route, which is what makes this a Navigator 2.0 app.
class KumoExampleSettings extends StatelessWidget {
  /// Creates the settings screen.
  const KumoExampleSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final styles = KumoTheme.textStylesOf(context);

    return KumoScaffold(
      header: KumoHeader(
        title: 'Settings',
        subtitle: 'Routed at /settings.',
        leading: KumoButton(
          label: 'Back',
          variant: KumoButtonVariant.secondary,
          icon: PhosphorIconsRegular.arrowLeft,
          // A deep link can land here with nothing to pop, so fall back
          // to the gallery instead of throwing.
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SectionLabel('Notifications'),
          const KumoListGroup(
            title: 'Deploy alerts',
            children: <Widget>[
              KumoListItem(title: 'Deploy finished', subtitle: 'Push and email'),
              KumoListItem(title: 'Weekly digest', subtitle: 'Mondays, 09:00'),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionLabel('Route'),
          Text('This screen is a page of the same RouterConfig.', style: styles.bodyMuted),
          const SizedBox(height: 12),
          const KumoCodeBlock(code: "context.push('/settings')", language: 'dart'),
        ],
      ),
    );
  }
}

/// Carries the app's theme mode to routed pages.
///
/// The app owns the mode, but the pages are built by the router, so they cannot
/// receive it as a constructor argument — a route builder runs once per
/// location. Passing it down through context is what keeps the selector in sync
/// after the mode changes.
class _ModeScope extends InheritedWidget {
  const _ModeScope({required this.mode, required this.onChanged, required super.child});

  /// The mode the app is currently painting.
  final KumoThemeMode mode;

  /// Called when a screen reports a new mode.
  final ValueChanged<KumoThemeMode> onChanged;

  static _ModeScope of(BuildContext context) {
    final _ModeScope? scope = context.dependOnInheritedWidgetOfExactType<_ModeScope>();
    assert(scope != null, 'No _ModeScope above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(_ModeScope oldWidget) => mode != oldWidget.mode || onChanged != oldWidget.onChanged;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: KumoTheme.textStylesOf(context).h2),
    );
  }
}
