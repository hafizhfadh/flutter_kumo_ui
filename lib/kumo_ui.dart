/// A mobile-first Flutter implementation of Cloudflare's Kumo UI design
/// system, built on `package:flutter/widgets.dart` alone.
///
/// Importing this library is enough to build a screen: the Flutter primitives a
/// Kumo screen needs are re-exported below, so an app never has to add
/// `package:flutter/widgets.dart` alongside it.
///
/// ```dart
/// import 'package:kumo_ui/kumo_ui.dart';
/// ```
///
/// Material and Cupertino are deliberately not re-exported.
library;

// ---------------------------------------------------------------------------
// Flutter primitives
// ---------------------------------------------------------------------------

/// Core Flutter widget primitives, re-exported for single-import ergonomics.
///
/// There is deliberately no `Margin` entry: Flutter has no such class, and
/// spacing is expressed with [EdgeInsets] / [EdgeInsetsGeometry].
export 'package:flutter/widgets.dart'
    show
        // Core framework types
        Widget,
        StatelessWidget,
        StatefulWidget,
        State,
        InheritedWidget,
        BuildContext,
        Key,
        ValueKey,
        GlobalKey,
        Brightness,
        // Layout primitives
        Column,
        Row,
        Stack,
        Positioned,
        Expanded,
        Flexible,
        Spacer,
        Container,
        SizedBox,
        Padding,
        Align,
        Center,
        ConstrainedBox,
        BoxConstraints,
        CrossAxisAlignment,
        MainAxisSize,
        Wrap,
        Builder,
        // Geometry, paints and insets
        EdgeInsets,
        EdgeInsetsGeometry,
        Alignment,
        AlignmentGeometry,
        BorderRadius,
        BoxDecoration,
        Border,
        BorderSide,
        BoxShape,
        Color,
        ColoredBox,
        // Text
        Text,
        TextStyle,
        TextEditingController,
        TextOverflow,
        // Scroll and lists
        ListView,
        SingleChildScrollView,
        CustomScrollView,
        SliverList,
        SliverGrid,
        // Interactivity and gestures
        GestureDetector,
        MouseRegion,
        Focus,
        FocusNode,
        Semantics,
        SystemMouseCursors,
        VoidCallback,
        ValueChanged,
        // Animation essentials
        AnimatedContainer,
        AnimatedOpacity,
        AnimatedCrossFade,
        SizeTransition,
        AnimationController,
        // Navigation and app scaffolding
        runApp,
        WidgetsApp,
        Navigator,
        PageRouteBuilder,
        RouteSettings,
        WidgetBuilder,
        MediaQuery,
        LayoutBuilder,
        SafeArea,
        // Router (Navigator 2.0), so a KumoApp.router can be typed with the
        // single import
        RouteInformation,
        RouteInformationProvider,
        RouteInformationParser,
        RouterConfig,
        RouterDelegate,
        BackButtonDispatcher;

// ---------------------------------------------------------------------------
// App entry point
// ---------------------------------------------------------------------------

export 'src/kumo_app.dart';

// ---------------------------------------------------------------------------
// Kumo components
// ---------------------------------------------------------------------------

export 'src/components/kumo_accordion.dart';
export 'src/components/kumo_badge.dart';
export 'src/components/kumo_banner.dart';
export 'src/components/kumo_bottom_sheet.dart';
export 'src/components/kumo_breadcrumb.dart';
export 'src/components/kumo_button.dart';
export 'src/components/kumo_checkbox.dart';
export 'src/components/kumo_code_block.dart';
export 'src/components/kumo_data_card.dart';
export 'src/components/kumo_data_grid.dart';
export 'src/components/kumo_drawer.dart';
export 'src/components/kumo_drawer_scaffold.dart';
export 'src/components/kumo_empty.dart';
export 'src/components/kumo_header.dart';
export 'src/components/kumo_input.dart';
export 'src/components/kumo_label.dart';
export 'src/components/kumo_link.dart';
export 'src/components/kumo_list_group.dart';
export 'src/components/kumo_loader.dart';
export 'src/components/kumo_meter.dart';
export 'src/components/kumo_modal.dart';
export 'src/components/kumo_pagination.dart';
export 'src/components/kumo_radio.dart';
export 'src/components/kumo_scaffold.dart';
export 'src/components/kumo_segmented_control.dart';
export 'src/components/kumo_select.dart';
export 'src/components/kumo_sensitive_input.dart';
export 'src/components/kumo_skeleton.dart';
export 'src/components/kumo_switch.dart';
export 'src/components/kumo_tabs.dart';
export 'src/components/kumo_toast.dart';
export 'src/components/kumo_tooltip.dart';

// ---------------------------------------------------------------------------
// Charts
// ---------------------------------------------------------------------------

export 'src/charts/kumo_chart_container.dart';
export 'src/charts/kumo_chart_controller.dart';
export 'src/charts/kumo_lttb.dart';
export 'src/charts/kumo_ring_buffer.dart';

// ---------------------------------------------------------------------------
// Layout helpers
// ---------------------------------------------------------------------------

export 'src/layout/kumo_responsive_layout.dart';

// ---------------------------------------------------------------------------
// Theming
// ---------------------------------------------------------------------------

export 'src/theme/kumo_colors.dart';
export 'src/theme/kumo_theme.dart';
export 'src/theme/kumo_typography.dart';
