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
- Complete component suite including inputs, navigation, responsive layouts, metric blocks, and telemetry charts.

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
