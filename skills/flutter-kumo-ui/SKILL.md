---
name: flutter-kumo-ui
description: Build Flutter screens with the kumo_ui package, a mobile-first implementation of Cloudflare's Kumo design system built on widgets.dart alone, with light and dark schemes, a component set, and a pure-Dart chart subsystem, and no Material. Use when the user mentions Kumo, kumo_ui, KumoApp, KumoTheme, KumoColors, a Cloudflare-dashboard look in Flutter, or asks to add screens, widgets, charts, theming, forms, or navigation to an app that depends on kumo_ui.
license: MIT
metadata:
  package: kumo_ui
  version: 1.7.0
  repository: https://github.com/hafizhfadh/flutter_kumo_ui
---

# Flutter Kumo UI

`kumo_ui` is a Flutter design system: the Cloudflare dashboard's dark, high-density
visual language (near-black canvas, layered surfaces, hairline borders, one orange
brand signal) rebuilt from `package:flutter/widgets.dart` primitives. It ships
light and dark schemes, the Cloudflare component set, a pure-Dart chart
subsystem, and zero Material or Cupertino.

## The rule that breaks the build

Never import `package:flutter/material.dart` or `cupertino.dart`. The package's whole
premise is a Material-free widget tree, and a single Material import defeats it.

Also hard:

- No Flutter Web. `KumoTheme.of` and `KumoApp` assert the platform and throw
  `UnsupportedError` on `kIsWeb`. Do not add web targets or conditional web code.
- Transparency is `const Color(0x00000000)`. `Colors.transparent` lives in Material.
- No `phosphor_flutter`. Use `phosphor_icons` (the maintained fork).

## Install

```yaml
dependencies:
  flutter:
    sdk: flutter
  kumo_ui: ^1.7.0
  phosphor_icons: ^3.0.1   # where the Phosphor glyph constants live
```

```dart
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
```

That first import is enough for a whole screen: `kumo_ui` re-exports the
`widgets.dart` primitives it is built from (`Widget`, `Column`, `Row`, `Text`,
`Color`, `BuildContext`, `MediaQuery`, `LayoutBuilder`, `SafeArea`, `Brightness`,
`InheritedWidget`, `Builder`, the router types, and more). You do not need to add
`package:flutter/widgets.dart` alongside it, and doing so is a smell that you
reached for something the barrel does not curate.

## Bootstrap the app

`KumoApp` is the `MaterialApp` equivalent. It resolves the color scheme, wraps
`KumoTheme` around a `WidgetsApp`, derives the root text style and the
task-switcher color from the active scheme, and observes the platform brightness.

```dart
void main() => runApp(KumoApp(home: const HomeScreen()));
```

For Navigator 2.0 (go_router, auto_route, or a raw `RouterDelegate`):

```dart
KumoApp.router(routerConfig: router)
```

`KumoApp.router` deliberately has no `home`, `routes`, `initialRoute`,
`onGenerateRoute` or `navigatorKey`: a router owns the navigator.

Prefer `KumoApp` over hand-rolling `KumoTheme(child: WidgetsApp(...))`. If you do
need the pieces, read `KumoApp`'s source first, because `WidgetsApp` asserts that
one of `builder`, `onGenerateRoute` or `pageRouteBuilder` is supplied.

## Colors and modes

A `KumoColors` describes **one** scheme. The app decides which one is in scope.

```dart
KumoThemeMode.system          // default: follows the platform, repaints on change
KumoThemeMode.light
KumoThemeMode.dark

KumoColors.light()            // the light scheme
KumoColors.dark()             // the dark scheme (same tokens as `const KumoColors()`)
KumoColors.of(Brightness.light)
```

Read tokens with `KumoTheme.of(context)`. The 16 tokens are `canvas`, `surface`,
`subtleSurface`, `border`, `primary`, `focus`, `textPrimary`, `textSecondary`,
`textMuted`, `info`, `success`, `warning`, `danger`, `dangerText`, `scrim` and
`brightness`.

Two traps:

- `danger` is an **indicator** tone (fills, dots, borders). For red *text* use
  `dangerText`, which is the contrast-safe variant in both schemes.
- `KumoTheme.of` falls back to the dark scheme when there is no `KumoTheme`
  ancestor. That is a fallback, not a substitute for wrapping your app.

## Text: use the resolved styles

`KumoTypography`'s statics (`h1`, `h2`, `body`, `bodyMuted`, `caption`, `code`)
carry the **dark** tones. They are safe outside a theme and wrong inside a light
one. Inside a themed subtree resolve the scheme-aware set instead:

```dart
final styles = KumoTheme.textStylesOf(context);
Text('Zone settings', style: styles.h2);
```

`KumoTypography.resolve(colors)` builds the same set when the tokens are already
in hand. `textStylesOf` is memoized per `KumoColors`.

## Components

Twenty public widgets. Full constructor signatures, defaults and notes are in
[references/components.md](references/components.md); read it before you invent a
widget or guess a parameter name.

| Area | Widgets |
| --- | --- |
| Shell | `KumoScaffold` |
| Form | `KumoInput` (single or multi-line), `KumoSensitiveInput`, `KumoSwitch`, `KumoCheckbox`, `KumoRadio<T>`, `KumoSelect<T>`, `KumoSegmentedControl<T>`, `KumoButton`, `KumoLabel` |
| Navigation | `KumoBreadcrumb` + `KumoBreadcrumbItem`, `KumoTabs`, `KumoPagination`, `KumoLink` |
| Structure | `KumoHeader`, `KumoListGroup` + `KumoListItem`, `KumoDataGrid`, `KumoDataCard` + `KumoDataPair`, `KumoAccordion`, `KumoBottomSheet` + `KumoBottomSheetItem`, `KumoResponsiveLayout` |
| Feedback | `KumoBanner`, `KumoLoader`, `KumoMeter`, `KumoEmpty`, `KumoSkeleton`, `KumoToast` + `KumoToastManager`, `KumoBadge` |
| Overlay | `KumoCodeBlock`, `KumoModal`, `KumoTooltip` |

Start every screen from `KumoScaffold` unless it needs a nested layout. For the
full upstream component set and what the package still lacks, see the companion
`kumo-registry` skill.

Two are pushed through static methods rather than constructors:

```dart
await KumoModal.show<void>(context: context, title: 'Deploy worker', child: body);
await KumoBottomSheet.show<String>(context: context, title: 'Zone actions', child: rows);

KumoToastManager.show(context, title: 'Worker deployed', message: 'Live on 3 routes.');
```

Everything else is a normal widget. The house style is named parameters, and the
cross-cutting conventions are: 48px minimum tap targets, focus rings with
Enter/Space activation, and `Semantics` on anything interactive.

## Layout that adapts

`kKumoBreakpoint` is `600.0`. Adaptive widgets read their own `LayoutBuilder`
constraints, not `MediaQuery`, so they reflow correctly inside a sidebar or split
pane:

```dart
KumoResponsiveLayout(
  breakpoint: kKumoBreakpoint,
  mobile: Column(children: [...]),
  desktop: Row(children: [...]),
)
```

`KumoResponsiveLayout.isDesktop(context)` gives you the same decision outside a
builder (it reads `MediaQuery`, so use it for media-query-driven cases only).

## Checklist before you say it is done

1. No `material.dart` or `cupertino.dart` import anywhere in the diff.
2. No raw `Color(0x...)` in a widget: resolve a token via `KumoTheme.of(context)`,
   or add a semantic token if none fits. `KumoPalette` and `KumoLightPalette` are
   the raw scales; components must never reference them directly.
3. Text colours come from `KumoTheme.textStylesOf(context)`, so both schemes work.
4. Every tap target is at least 48px and reachable by keyboard.
5. Text clears WCAG AA (4.5:1) on `canvas`, `surface` and `subtleSurface`; non-text
   clears 3:1.
6. Any widget that pushes a route captures `KumoTheme.of(context)` **before** the
   push and re-provides `KumoTheme` above the navigator or overlay.
7. `///` dartdoc on every public class, member and parameter.
8. Full, compilable code. No `// TODO` stubs, no placeholder methods, no unused
   state fields or redundant wrappers.

## Verify

```sh
flutter analyze          # must be clean; the analyzer is the first gate
flutter test             # includes a contrast suite parameterized over both schemes
cd example && flutter test   # if the repo has the bundled example
```

If you touch the theme, colours or a component's colours, run the tests: the
contrast suite measures both schemes and fails on a regression rather than
letting it ship.

## Pitfalls, each of which cost a release or a test

- **A route builder runs once per location, not once per app rebuild.** Never pass
  app state into a route builder; it goes stale. Put it in an `InheritedWidget`
  above the router and read it from context. The bundled example does exactly this
  for its theme mode.
- **go_router under `KumoApp.router` renders `NoTransitionPage`**, because
  go_router picks its page type from the app it finds itself in (`MaterialPage`
  under a `MaterialApp`, `NoTransitionPage` under a plain `WidgetsApp`). Routes
  therefore do not animate, and no Material widget enters the tree. That is the
  intended trade-off.
- **auto_route defaults to `RouteType.material()`**, which renders a `MaterialPage`.
  Pass a non-Material route type if the zero-Material guarantee matters.
- **`KumoSelect` is two interactions, not one scaled one**: a popover on desktop and
  a `KumoBottomSheet` action sheet below `kKumoBreakpoint`.
- **`KumoDataCard(statusColor:)` is used for text**, so it must be text-safe
  (`success`, `warning`, `dangerText`). Not `danger`.
- **`KumoCheckbox` exposes `boxSize` (18)**; do not hardcode the box dimension.
- **The toast overlay layer outlives individual toasts** and follows the active
  scheme. `KumoToastManager.activeCount` is not a listenable, so a UI that shows a
  live count has to rebuild itself after each show or clear.

## Charts

The package ships a pure-Dart chart subsystem under `lib/src/charts/`, with no
chart package underneath: `KumoTimeseriesChart`, `KumoSankeyChart` and
`KumoGeoMapChart`, plus `KumoCanvas` for a bespoke drawing on a raw `Canvas`, and
`KumoChartContainer` for a chart assembled from layers you write.

Read [references/charts.md](references/charts.md) before writing any chart. The
one rule that matters most: a `paint` body allocates nothing, because everything
it needs is built in `prepare()` once per layout.

## Reference files

- [references/charts.md](references/charts.md) - the chart subsystem: the layer
  contract, the repaint split, `KumoChartColors`, the `KumoCanvas` escape hatch,
  and the timeseries, Sankey and GeoJSON families.
- [references/components.md](references/components.md) - every public constructor,
  parameter, default, enum and static service.
- [references/theming.md](references/theming.md) - both raw palettes, the semantic
  token table with measured contrast, mode resolution, and how to add a token.
- [references/recipes.md](references/recipes.md) - complete, compilable screens: a
  settings list, a validated form, and a routed app with a mode toggle.
