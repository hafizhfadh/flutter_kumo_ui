import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../layout/kumo_responsive_layout.dart';
import '../theme/kumo_theme.dart';
import 'kumo_drawer.dart';

/// Places a [KumoDrawer] adaptively: a docked rail on a wide screen, a drawer
/// sheet over the page on a narrow one.
///
/// This is the one-widget answer to upstream Kumo's `Sidebar`, which does the
/// same thing with its `mobileBreakpoint`. Above [breakpoint] the drawer sits
/// beside the page and cannot be dismissed, because there is room for it. Below
/// it, the drawer is hidden, and [open] slides it over a scrim that dismisses
/// on tap. Escape closes it, and focus moves inside while it is open.
///
/// ```dart
/// KumoDrawerScaffold(
///   drawer: KumoDrawer(children: <Widget>[
///     KumoDrawerItem(label: 'Home', icon: PhosphorIconsRegular.house, onTap: () {}),
///   ]),
///   child: KumoScaffold(
///     header: KumoHeader(
///       title: 'Zones',
///       // Only offer the menu where the drawer is not already docked.
///       leading: KumoDrawerScaffold.isDocked(context)
///           ? null
///           : KumoButton(label: 'Menu', onPressed: () => KumoDrawerScaffold.open(context)),
///     ),
///     child: content,
///   ),
/// )
/// ```
class KumoDrawerScaffold extends StatefulWidget {
  /// Creates an adaptive drawer layout.
  const KumoDrawerScaffold({
    super.key,
    required this.child,
    required this.drawer,
    this.breakpoint = kKumoBreakpoint,
    this.fullScreenOnMobile = false,
  });

  /// The page.
  final Widget child;

  /// The panel, normally a [KumoDrawer].
  final Widget drawer;

  /// Width at or above which the drawer is docked instead of sliding.
  final double breakpoint;

  /// Whether the sheet covers the whole viewport on a narrow screen, instead of
  /// leaving a sliver of the page visible.
  final bool fullScreenOnMobile;

  /// Opens the drawer. Does nothing when it is already docked.
  static void open(BuildContext context) => _scopeOf(context).open();

  /// Closes the drawer. Harmless when it is docked.
  static void close(BuildContext context) => _scopeOf(context).close();

  /// Whether the drawer is docked rather than hidden behind a menu action.
  ///
  /// Use it to decide whether to render a menu affordance at all.
  static bool isDocked(BuildContext context) => _scopeOf(context).isDocked;

  static _KumoDrawerScope _scopeOf(BuildContext context) {
    final _KumoDrawerScope? scope =
        context.dependOnInheritedWidgetOfExactType<_KumoDrawerScope>();
    assert(scope != null, 'No KumoDrawerScaffold above this widget.');
    return scope!;
  }

  @override
  State<KumoDrawerScaffold> createState() => _KumoDrawerScaffoldState();
}

class _KumoDrawerScaffoldState extends State<KumoDrawerScaffold> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDocked = constraints.maxWidth >= widget.breakpoint;

        return _KumoDrawerScope(
          isDocked: isDocked,
          open: () => setState(() => _isOpen = true),
          close: () => setState(() => _isOpen = false),
          child: ColoredBox(
            color: colors.canvas,
            child: isDocked
                ? SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        widget.drawer,
                        Expanded(child: widget.child),
                      ],
                    ),
                  )
                : Stack(
                    children: <Widget>[
                      widget.child,
                      if (_isOpen) ...<Widget>[
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _isOpen = false),
                            child: ColoredBox(color: colors.scrim),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: widget.fullScreenOnMobile
                                  ? constraints.maxWidth
                                  : math.min(
                                      kKumoDrawerWidth,
                                      constraints.maxWidth * 0.85,
                                    ),
                            ),
                            child: Focus(
                              autofocus: true,
                              onKeyEvent: (FocusNode _, KeyEvent event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.escape) {
                                  setState(() => _isOpen = false);
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: SafeArea(child: widget.drawer),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Carries the drawer's open state to the page below it, so a menu button can
/// reach it without threading a callback through every layer.
class _KumoDrawerScope extends InheritedWidget {
  const _KumoDrawerScope({
    required this.isDocked,
    required this.open,
    required this.close,
    required super.child,
  });

  final bool isDocked;
  final VoidCallback open;
  final VoidCallback close;

  @override
  bool updateShouldNotify(_KumoDrawerScope oldWidget) =>
      isDocked != oldWidget.isDocked ||
      open != oldWidget.open ||
      close != oldWidget.close;
}
