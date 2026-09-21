## 1.5.0

Four more upstream components, moving coverage to 25 of 45.

- `KumoRadio<T>` closes the highest-value gap in the form set. It mirrors
  `KumoCheckbox` deliberately: an 18px control, one 48px tap target per row, the
  brand signal when chosen, and a mutually exclusive group announced to
  assistive technology.
- `KumoBanner` is the persistent counterpart to `KumoToast`: an inline message
  that stays where you put it, with four kinds, an optional action and an
  optional dismiss. It upgrades Banner from partial to covered, because a
  transient toast could not carry a message the user needs to read twice.
- `KumoSensitiveInput` adds a reveal toggle for secrets the user has to verify,
  composing `KumoInput` rather than reimplementing it.
- `KumoTooltip` shows a short label on hover (desktop) or long press (touch),
  and attaches the same text as a semantics tooltip for platforms with no hover.

## 1.4.0

The screen shell, plus the primitives the component set was missing.

- `KumoScaffold` is the Material-free answer to `Scaffold`: it paints the
  canvas, insets for the system UI, keeps the body above the software keyboard,
  and gives a screen a pinned `header`, a scrolling `child` and an optional
  `bottomBar`. It replaces the `ColoredBox` + `SafeArea` +
  `SingleChildScrollView` boilerplate every screen was repeating.
- Seven new widgets, closing gaps against Cloudflare's Kumo component set:
  `KumoLoader` (indeterminate progress, drawn with `CustomPaint` rather than
  Material's indicator), `KumoEmpty` (an empty state that names a reason and an
  action, not just "No data"), `KumoSkeleton` (a static placeholder line),
  `KumoLink`, `KumoLabel`, `KumoMeter` (determinate progress) and
  `KumoInputArea`'s job.
- `KumoInput` gained `maxLines` and `minLines`, so a multi-line area is the same
  field rather than a near-duplicate widget. Multi-line fields align a
  `prefixIcon` to the first line.
- The example's settings route now uses `KumoScaffold`, and a new Primitives
  section demonstrates the added widgets.
- Corrected a claim in the 1.0.0 entry: it listed "metric blocks, and telemetry
  charts", which the package has never contained.

## 1.3.0

Navigator 2.0 support: `KumoApp.router`.

- `KumoApp.router` is the `MaterialApp.router` equivalent. It drives
  `WidgetsApp.router` from a `RouterConfig`, or from a raw `RouterDelegate` plus
  `RouteInformationParser`, and keeps the scheme resolution, theme wrapper and
  platform-brightness observer `KumoApp` already had. go_router and auto_route
  both hand over a `RouterConfig`, so they plug in unchanged.
- `home`, `routes`, `initialRoute`, `onGenerateRoute` and `navigatorKey` are
  absent from that constructor, mirroring `MaterialApp.router`: a router owns the
  navigator, and `WidgetsApp.router` asserts they cannot be combined.
- Re-export the router types (`RouterConfig`, `RouterDelegate`,
  `RouteInformationParser`, `RouteInformationProvider`, `BackButtonDispatcher`,
  `RouteInformation`) and `InheritedWidget`, so both paths stay usable from the
  single import.
- go_router stays Material-free under `KumoApp.router`: it chooses its page type
  from the app it finds itself in and falls back to `NoTransitionPage` under a
  plain `WidgetsApp`. Asserted by test rather than assumed.
- The bundled example is now a routed app: `KumoApp.router` with `/` and
  `/settings`. Its theme mode reaches the pages through an `InheritedWidget`,
  because a route builder does not re-run when the app rebuilds.

## 1.2.0

`KumoApp`, the app entry point.

- `KumoApp` collapses the theme and the `WidgetsApp` wiring into one widget, the
  way `MaterialApp` does, and derives the root text style and the task-switcher
  color from the scheme in scope. `runApp(KumoApp(home: HomeScreen()))` is a
  complete app, with no nested theming.
- `KumoThemeMode` (`system`, `light`, `dark`) picks the scheme and defaults to
  `system`, so an app follows the platform setting and repaints when it changes.
- `KumoColors.dark()` now accepts the same per-token overrides as
  `KumoColors.light()`, so the two schemes read as peers.
- `WidgetsBinding` and `WidgetsBindingObserver` are no longer re-exported. They
  were added in 1.1.0 for the example's manual brightness wiring, which
  `KumoApp` now owns; both stay available from `package:flutter/widgets.dart`.
  `Brightness` and `Builder` remain in the barrel.
- The bundled example is now a single `KumoApp`.

## 1.1.0

Light and dark color modes.

- `KumoColors.light()` joins `KumoColors.dark()`, with `KumoColors.of(brightness)`
  to pick a scheme and a `brightness` field to read it back. Both schemes clear
  WCAG 2.1 AA (4.5:1 for text, 3:1 for non-text), verified by the same test
  suite rather than by eye.
- `KumoLightPalette` carries the light half of the raw scale. The dark accents
  cannot be reused on light surfaces: the brand orange is 2.6:1 on white, so the
  light `orange5` is deepened until it clears AA as text.
- `KumoTextStyles` and `KumoTypography.resolve(colors)` expose the type scale
  tinted for one scheme, and `KumoTheme.textStylesOf(context)` resolves it for
  the active one. Components paint with those instead of the dark-only statics,
  which is what makes the light scheme legible.
- New `scrim` token drives the modal and bottom-sheet barriers, so the light
  scheme dims its background instead of washing it black.
- The checkbox check glyph now uses `canvas`, the same tone the primary button
  uses for its label. That lifts it from 2.9:1 to 7.12:1 on the dark fill.
- Fixed: the toast overlay layer captured the colors of whichever toast opened
  it, so toasts shown after a color-mode switch kept the previous scheme.
- The bundled example gains a System / Light / Dark selector plus sections for
  the bottom sheet, the inline toast, every toast kind, the raw palette and
  `kKumoBreakpoint`, so every public widget is demonstrated.
- Additive only: no existing signature changed, and `const KumoColors()` is
  still the dark scheme.

## 1.0.2

Documentation and packaging release.

- README now documents every public widget, enum and theming token, adding
  `KumoListItem`, `KumoBreadcrumbItem`, `KumoDataPair`, `KumoBottomSheetItem`,
  the `KumoButtonVariant` / `KumoBadgeVariant` / `KumoToastKind` enums, and the
  `KumoToastManager` / `KumoResponsiveLayout.isDesktop` helpers.
- Adds a screenshots gallery backed by the new `doc/images/` phone captures
  of the bundled example app.
- No public API changes; `1.0.2` is a drop-in replacement for `1.0.1`.

## 1.0.1

Developer-experience release.

- `lib/kumo_ui.dart` now re-exports the core Flutter widget primitives
  (`Widget`, `Column`, `Text`, `Color`, `WidgetsApp`, `Navigator` and friends), so
  an app can build a Kumo screen from a single
  `import 'package:kumo_ui/kumo_ui.dart';`.
- Re-exports come from `package:flutter/widgets.dart` only. No Material or
  Cupertino symbols are exposed.
- There is no `Margin` re-export: Flutter has no such class, and spacing is
  expressed with `EdgeInsets`.
- The bundled example now compiles without importing
  `package:flutter/widgets.dart`.

## 1.0.0

- Initial stable release of `kumo_ui`.
- Complete component suite including inputs, navigation and responsive layouts.

## 0.1.0-beta.1

Initial public preview of the Kumo UI component set for Flutter.

* Added `KumoTheme`, `KumoColors`, `KumoPalette` and `KumoTypography`, with the
  `kKumoBreakpoint` mobile/desktop switchover constant.
* Added form controls: `KumoInput`, `KumoSwitch`, `KumoCheckbox`,
  `KumoSelect<T>`, `KumoSegmentedControl<T>` and `KumoButton`.
* Added navigation widgets: `KumoBreadcrumb`, `KumoTabs` and `KumoPagination`.
* Added structure widgets: `KumoHeader`, `KumoListGroup` with `KumoListItem`,
  `KumoDataGrid` with `KumoDataCard`, `KumoAccordion`, `KumoBottomSheet` with
  `KumoBottomSheetItem`, and `KumoResponsiveLayout`.
* Added content and overlay widgets: `KumoCodeBlock`, `KumoModal`, `KumoToast`
  with `KumoToastManager`, and `KumoBadge`.
* `KumoPalette` exposes the raw ten-step `gray0`–`gray9` ramp plus the
  `orange5`, `blue5`, `red5`, `green5` and `amber5` accents, and every
  `KumoColors` token resolves to a step of it.
* Every text token clears WCAG 2.1 AA (4.5:1) against each surface it is
  painted on, verified by a contrast test suite.
* Interactive widgets carry `Semantics` annotations, keep a 48px minimum touch
  target, and show a `:focus-visible`-style focus ring with Enter/Space
  activation.
* Web targets throw `UnsupportedError` through `KumoTheme.of`, and the library
  is built without `material.dart` or `cupertino.dart`.
