import 'package:flutter/widgets.dart';

/// Width in logical pixels at which Kumo layouts switch from the mobile
/// arrangement to the desktop arrangement.
///
/// Every adaptive Kumo widget defaults its own `breakpoint` to this value so
/// the whole library flips at the same screen width.
const double kKumoBreakpoint = 600.0;

/// Swaps between a [mobile] and a [desktop] arrangement of the same content.
///
/// The decision is made from the incoming [LayoutBuilder] constraints rather
/// than the window size, so the layout also adapts correctly when a Kumo view
/// is embedded in a sidebar, a split pane or any other narrow container.
///
/// When [desktop] is omitted, [mobile] is used at every width.
class KumoResponsiveLayout extends StatelessWidget {
  /// Creates an adaptive layout that picks between two arrangements.
  const KumoResponsiveLayout({
    super.key,
    required this.mobile,
    this.desktop,
    this.breakpoint = kKumoBreakpoint,
  });

  /// Arrangement used below [breakpoint].
  final Widget mobile;

  /// Arrangement used at or above [breakpoint]. Falls back to [mobile] when
  /// omitted.
  final Widget? desktop;

  /// Width in logical pixels at which [desktop] takes over.
  final double breakpoint;

  /// Whether the viewport is currently at least [breakpoint] wide.
  ///
  /// Use this for decisions that must follow the whole window rather than a
  /// local container, such as the density of a full-screen sidebar.
  static bool isDesktop(
    BuildContext context, {
    double breakpoint = kKumoBreakpoint,
  }) {
    return MediaQuery.sizeOf(context).width >= breakpoint;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return desktop ?? mobile;
        }
        return mobile;
      },
    );
  }
}
