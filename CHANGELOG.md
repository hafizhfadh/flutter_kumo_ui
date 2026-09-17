## 0.1.0-beta.1

Initial public preview of the Kumo UI component set for Flutter.

* Added `KumoTheme`, `KumoColors` and `KumoTypography`, with the
  `kKumoBreakpoint` mobile/desktop switchover constant.
* Added form controls: `KumoInput`, `KumoSwitch`, `KumoSegmentedControl<T>` and
  `KumoButton`.
* Added structure widgets: `KumoHeader`, `KumoListGroup` with `KumoListItem`,
  `KumoDataGrid` with `KumoDataCard`, `KumoAccordion` and
  `KumoResponsiveLayout`.
* Added content and overlay widgets: `KumoCodeBlock` and `KumoModal`.
* Web targets throw `UnsupportedError` through `KumoTheme.of`, and the library
  is built without `material.dart` or `cupertino.dart`.
