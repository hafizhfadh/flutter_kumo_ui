## 1.0.2

Documentation and packaging release.

- README now documents every public widget, enum and theming token, adding
  `KumoListItem`, `KumoBreadcrumbItem`, `KumoDataPair`, `KumoBottomSheetItem`,
  the `KumoButtonVariant` / `KumoBadgeVariant` / `KumoToastKind` enums, and the
  `KumoToastManager` / `KumoResponsiveLayout.isDesktop` helpers.
- Adds a screenshots gallery backed by the new `docs/images/` phone captures
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
