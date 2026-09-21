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
///
/// ## The `context` these statics need
///
/// Both `drawer` and `child` are built as descendants of the scope this widget
/// publishes, so any context from inside either one reaches [open], [close] and
/// [isDocked]. What does *not* reach them is the context of the build that
/// **created** this widget — that one is an ancestor of the scope.
///
/// That distinction bites when a callback closes over an outer context. Building
/// the drawer with a context of its own is what fixes it, because then the rows'
/// callbacks are descendants:
///
/// ```dart
/// KumoDrawerScaffold(
///   // A Builder gives the rows a context below the scaffold, so
///   // `KumoDrawerScaffold.close` resolves. Closing over the enclosing
///   // context would not.
///   drawer: Builder(
///     builder: (BuildContext drawerContext) => KumoDrawer(
///       children: <Widget>[
///         KumoDrawerItem(
///           label: 'Home',
///           onTap: () {
///             KumoDrawerScaffold.close(drawerContext);
///             drawerContext.go('/');
///           },
///         ),
///       ],
///     ),
///   ),
///   child: page,
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
  ///
  /// [context] must be a descendant of this widget — see the note on the class.
  /// A call from outside the scaffold is a no-op in a release build and an
  /// assertion failure in debug.
  static void open(BuildContext context) => _scopeOrNull(context)?.open();

  /// Closes the drawer. Harmless when it is docked.
  ///
  /// [context] must be a descendant of this widget — see the note on the class.
  static void close(BuildContext context) => _scopeOrNull(context)?.close();

  /// Whether the drawer is docked rather than hidden behind a menu action.
  ///
  /// Use it to decide whether to render a menu affordance at all. Answers
  /// `false` when no [KumoDrawerScaffold] encloses [context]; pair it with
  /// [hasScaffold] when the caller may be rendered outside one, because this
  /// lookup asserts on a missing scaffold in debug.
  static bool isDocked(BuildContext context) =>
      _scopeOrNull(context)?.isDocked ?? false;

  /// Whether a [KumoDrawerScaffold] encloses [context].
  ///
  /// The non-asserting probe, for a widget that may be rendered either inside or
  /// outside a shell. [isDocked] answers a different question — "is the drawer
  /// showing permanently?" — and cannot distinguish `false` from absent.
  static bool hasScaffold(BuildContext context) => _findScope(context) != null;

  static _KumoDrawerScope? _findScope(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_KumoDrawerScope>();

  static _KumoDrawerScope? _scopeOrNull(BuildContext context) {
    final _KumoDrawerScope? scope = _findScope(context);
    assert(
      scope != null,
      'KumoDrawerScaffold was looked up from a context with no '
      'KumoDrawerScaffold above it.\n'
      'The context has to be a descendant of the scaffold — normally the page '
      'passed as `child`, or a widget built by the drawer.\n'
      'The usual cause is a callback that closed over the build context that '
      'CREATED the scaffold, which is an ancestor of it. Wrap that widget in a '
      'Builder so its callbacks capture a context of their own. Call '
      'KumoDrawerScaffold.hasScaffold(context) first if the widget may also be '
      'rendered outside a scaffold.',
    );
    return scope;
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
