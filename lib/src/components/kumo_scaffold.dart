import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';

/// A Kumo screen shell.
///
/// The Material-free answer to `Scaffold`. It paints the canvas, insets for the
/// system UI, keeps the body clear of the software keyboard, and gives a screen
/// the three regions a Kumo page actually uses: a pinned [header], a scrolling
/// [child], and an optional [bottomBar].
///
/// ```dart
/// KumoScaffold(
///   header: KumoHeader(title: 'Zones', subtitle: '3 active'),
///   child: KumoListGroup(children: [...]),
/// )
/// ```
///
/// The widget fills the space it is given, so it belongs at the root of a route
/// rather than inside an unbounded parent.
class KumoScaffold extends StatelessWidget {
  /// Creates a Kumo screen shell.
  const KumoScaffold({
    super.key,
    required this.child,
    this.header,
    this.bottomBar,
    this.padding = const EdgeInsets.all(20),
    this.scrollable = true,
    this.safeArea = true,
    this.resizeToAvoidBottomInset = true,
  });

  /// The page content.
  final Widget child;

  /// Region pinned above [child]. Normally a [KumoHeader].
  final Widget? header;

  /// Region pinned below [child], for a primary action or a page summary.
  final Widget? bottomBar;

  /// Gutter applied to the body, and to the side and top of [header].
  final EdgeInsets padding;

  /// Whether [child] scrolls. Turn this off when the content owns its own
  /// scrolling, such as a `ListView` or a `KumoDataGrid`.
  final bool scrollable;

  /// Whether to inset for notches, status bars and the home indicator.
  final bool safeArea;

  /// Whether the body shrinks when the software keyboard opens.
  ///
  /// Leave this on for any screen with a text field: without it the keyboard
  /// covers the focused input on a phone.
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final colors = KumoTheme.of(context);
    final double keyboardInset = resizeToAvoidBottomInset
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0;

    Widget body = Padding(padding: padding, child: child);
    if (scrollable) {
      body = SingleChildScrollView(padding: padding, child: child);
    }

    return ColoredBox(
      color: colors.canvas,
      child: SafeArea(
        top: safeArea,
        bottom: safeArea,
        left: safeArea,
        right: safeArea,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (header != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding.left,
                    padding.top,
                    padding.right,
                    0,
                  ),
                  child: header,
                ),
              Expanded(child: body),
              if (bottomBar != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding.left,
                    0,
                    padding.right,
                    padding.bottom,
                  ),
                  child: bottomBar,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
