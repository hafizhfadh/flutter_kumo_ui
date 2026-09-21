import 'package:go_router/go_router.dart';
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../page_parts.dart';
import '../shell.dart';

/// The second-level route, reached by pushing `/settings`.
///
/// It is a child of the shell like every other destination, so the drawer stays
/// put while the page changes underneath it.
class KumoExampleSettings extends StatelessWidget {
  /// Creates the settings screen.
  const KumoExampleSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final KumoTextStyles styles = KumoTheme.textStylesOf(context);

    return KumoScaffold(
      header: ExamplePageHeader(
        title: 'App settings',
        subtitle: 'Routed at /settings.',
        action: KumoButton(
          label: 'Back',
          variant: KumoButtonVariant.secondary,
          icon: PhosphorIconsRegular.arrowLeft,
          // A deep link can land here with nothing to pop, so fall back to the
          // gallery instead of throwing.
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(KumoExampleDestination.overview.path),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const ExampleSectionLabel('Notifications'),
          const KumoListGroup(
            title: 'Deploy alerts',
            children: <Widget>[
              KumoListItem(title: 'Deploy finished', subtitle: 'Push and email'),
              KumoListItem(title: 'Weekly digest', subtitle: 'Mondays, 09:00'),
            ],
          ),
          const SizedBox(height: 28),
          const ExampleSectionLabel('Route'),
          Text(
            'This screen is a page of the same RouterConfig, wrapped by the same '
            'shell as every other destination.',
            style: styles.bodyMuted,
          ),
          const SizedBox(height: 12),
          const KumoCodeBlock(code: "context.push('/settings')", language: 'dart'),
        ],
      ),
    );
  }
}
