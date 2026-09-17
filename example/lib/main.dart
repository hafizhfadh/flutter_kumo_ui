import 'package:flutter/widgets.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

void main() {
  // Refuses to boot on Flutter Web, by design.
  KumoTheme.ensureSupportedPlatform();
  runApp(const KumoExampleApp());
}

/// Root of the Kumo UI showcase.
///
/// Uses [WidgetsApp] so the entire example stays free of Material, matching the
/// library's own constraint.
class KumoExampleApp extends StatelessWidget {
  /// Creates the showcase app.
  const KumoExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KumoTheme(
      child: WidgetsApp(
        title: 'Kumo UI',
        color: const Color(0xFF111111),
        textStyle: KumoTypography.body,
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
            PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  builder(context),
            ),
        home: const KumoExampleHome(),
      ),
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
  int _tabIndex = 0;
  int _page = 2;

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
      _tabIndex = 0;
      _page = 2;
    });
  }

  void _showToast() {
    KumoToastManager.show(
      context,
      title: 'Worker deployed',
      message: 'kumo-worker is live on 3 routes.',
      kind: KumoToastKind.success,
    );
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
            style: KumoTypography.bodyMuted,
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

    final edgeRules = KumoListGroup(
      title: 'Edge rules',
      children: [
        KumoListItem(
          title: 'Always use HTTPS',
          subtitle: 'On',
          leading: const PhosphorIcon(
            PhosphorIconsRegular.shieldCheck,
            size: 18,
          ),
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
              const _SectionLabel('Segmented control'),
              KumoSegmentedControl<String>(
                segments: const <String, String>{
                  'overview': 'Overview',
                  'dns': 'DNS',
                  'workers': 'Workers',
                },
                selected: _segment,
                onSelected: (value) => setState(() => _segment = value),
              ),
              const SizedBox(height: 10),
              Text(
                'Showing the $_segment view.',
                style: KumoTypography.caption,
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Text input'),
              KumoInput(
                label: 'Api token',
                placeholder: 'Paste token',
                controller: _token,
                prefixIcon: PhosphorIcon(
                  PhosphorIconsRegular.key,
                  size: 16,
                  color: colors.textSecondary,
                ),
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
                  const Expanded(
                    child: Text('Notifications', style: KumoTypography.body),
                  ),
                  KumoSwitch(
                    value: _notificationsEnabled,
                    onChanged: (value) =>
                        setState(() => _notificationsEnabled = value),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text('Analytics', style: KumoTypography.body),
                  ),
                  const KumoSwitch(
                    value: true,
                    onChanged: _noop,
                    isDisabled: true,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Accordion'),
              const KumoAccordion(
                title: 'Advanced settings',
                child: Text(
                  'Changes here apply to every request routed through the '
                  'selected zone.',
                  style: KumoTypography.bodyMuted,
                ),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('List group'),
              KumoListGroup(
                title: 'Zone settings',
                children: [
                  const KumoListItem(
                    title: 'DNS records',
                    subtitle: '42 records',
                  ),
                  const KumoListItem(title: 'Caching', subtitle: 'Standard'),
                  KumoListItem(
                    title: 'Add a record',
                    leading: const PhosphorIcon(
                      PhosphorIconsRegular.plus,
                      size: 18,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Resource grid'),
              const KumoDataGrid(
                maxColumns: 3,
                children: [
                  KumoDataCard(
                    title: 'example.com',
                    subtitle: 'Zone · Pro plan',
                    statusLabel: 'Active',
                    details: [
                      KumoDataPair(
                        label: 'Nameservers',
                        value: 'ada.ns.cloudflare.com',
                      ),
                      KumoDataPair(label: 'Records', value: '42'),
                    ],
                  ),
                  KumoDataCard(
                    title: 'Global DNS',
                    subtitle: 'Zone · Free plan',
                    statusLabel: 'Pending',
                    initiallyExpanded: true,
                    details: [
                      KumoDataPair(
                        label: 'Nameservers',
                        value: 'bob.ns.cloudflare.com',
                      ),
                    ],
                  ),
                  KumoDataCard(
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
                mobile: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    edgeRules,
                    const SizedBox(height: 12),
                    cachingRules,
                  ],
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
                  KumoBreadcrumbItem(
                    label: 'Accounts',
                    onTap: () => setState(() => _tabIndex = 0),
                  ),
                  KumoBreadcrumbItem(
                    label: 'example.com',
                    onTap: () => setState(() => _tabIndex = 1),
                  ),
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
              Text(
                'Tab index $_tabIndex is selected.',
                style: KumoTypography.caption,
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Badges'),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  KumoBadge(label: 'Pro plan', variant: KumoBadgeVariant.info),
                  KumoBadge(
                    label: 'Active',
                    variant: KumoBadgeVariant.success,
                    icon: PhosphorIconsRegular.checkCircle,
                  ),
                  KumoBadge(
                    label: 'Proxied',
                    variant: KumoBadgeVariant.warning,
                  ),
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
                onChanged: (bool value) =>
                    setState(() => _cachingEnabled = value),
              ),
              const SizedBox(height: 12),
              KumoSelect<String>(
                value: _plan,
                label: 'Plan',
                options: const <String, String>{
                  'free': 'Free',
                  'pro': 'Pro',
                  'business': 'Business',
                },
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
              const _SectionLabel('Toast'),
              KumoButton(
                label: 'Show success toast',
                icon: PhosphorIconsRegular.checkCircle,
                onPressed: _showToast,
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Code block'),
              const KumoCodeBlock(
                code: 'npx wrangler deploy --env production',
                language: 'bash',
              ),
              const SizedBox(height: 12),
              const KumoCodeBlock(code: 'console.log("copy me")'),
              const SizedBox(height: 28),
              const _SectionLabel('Modal'),
              KumoButton(
                label: 'Open dialog',
                icon: PhosphorIconsRegular.arrowSquareOut,
                onPressed: _openDialog,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  static void _noop(bool _) {}
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: KumoTypography.h2),
    );
  }
}
