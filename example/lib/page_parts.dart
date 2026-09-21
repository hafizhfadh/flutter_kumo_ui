import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// The drawer affordance, offered only where the drawer is not already docked.
class ExampleDrawerMenuButton extends StatelessWidget {
  /// Creates the menu button.
  const ExampleDrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return KumoButton(
      label: 'Menu',
      variant: KumoButtonVariant.secondary,
      icon: PhosphorIconsRegular.list,
      onPressed: () => KumoDrawerScaffold.open(context),
    );
  }
}

/// A page header that carries the drawer affordance where it is needed.
///
/// Above the breakpoint the drawer is docked and a menu button would open
/// nothing, so it is left out rather than rendered inert.
class ExamplePageHeader extends StatelessWidget {
  /// Creates a page header.
  const ExamplePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  /// Primary heading.
  final String title;

  /// Supporting line, normally the route path.
  final String? subtitle;

  /// Trailing control.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    // Probe for the scaffold before asking whether it is docked: `isDocked`
    // asserts when there is no scaffold, and this header is also usable on a
    // page rendered outside the shell.
    final bool canOpenDrawer =
        KumoDrawerScaffold.hasScaffold(context) &&
        !KumoDrawerScaffold.isDocked(context);
    return KumoHeader(
      title: title,
      subtitle: subtitle,
      action: action,
      leading: canOpenDrawer ? const ExampleDrawerMenuButton() : null,
    );
  }
}

/// A section heading inside a gallery page.
class ExampleSectionLabel extends StatelessWidget {
  /// Creates a section heading.
  const ExampleSectionLabel(this.label, {super.key});

  /// The heading text.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: KumoTheme.textStylesOf(context).h2),
    );
  }
}
