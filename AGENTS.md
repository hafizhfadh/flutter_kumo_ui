# KUMO_UI AGENT RULES

`kumo_ui` is a mobile-first Flutter design system: Cloudflare's Kumo UI rebuilt
from `package:flutter/widgets.dart` alone. Stable and published to pub.dev
(currently 1.3.0). These rules are binding for every change in this repository.

## 1. Design and skill alignment

Tokens are the source of truth, never hex codes. A widget resolves a semantic
token from `KumoTheme.of(context)`; it never writes a raw `Color(0x...)`.

- Semantic tokens (`KumoColors`): `canvas`, `surface`, `subtleSurface`, `border`,
  `primary`, `focus`, `textPrimary`, `textSecondary`, `textMuted`, `info`,
  `success`, `warning`, `danger`, `dangerText`, `scrim`, `brightness`.
- Raw scales (`KumoPalette`, `KumoLightPalette`) are read by `KumoColors` and by
  nothing else. A component that references a raw step is a bug.
- `danger` is an indicator tone (fills, dots, borders). Words in red use
  `dangerText`.
- Text colour comes from `KumoTheme.textStylesOf(context)`. The `KumoTypography`
  statics carry the dark tones and are correct only outside a themed subtree.
- Both schemes ship, so a colour change is checked in light and dark. Every text
  token clears WCAG 2.1 AA (4.5:1) on `canvas`, `surface` and `subtleSurface`;
  non-text clears 3:1. Compute the ratio, never eyeball it.
- Follow the Cloudflare design guidance in `.agents/skills/kumo-design/` and the
  anti-slop rules in `.agents/skills/antislop*/`:
  - No `// TODO` comments and no truncated placeholder methods.
  - No redundant wrappers, no unused state fields.
  - Generate full, compilable Dart.
- `skills/flutter-kumo-ui/` is the consumer-facing agent skill. If a public API
  changes, update that skill in the same change.

## 2. Core constraints

- Package imports are limited to `package:flutter/widgets.dart`,
  `package:flutter/services.dart`, `package:flutter/foundation.dart`,
  `package:vector_math/vector_math_64.dart` and
  `package:phosphor_icons/phosphor_icons.dart`. Every `dart:` SDK library is
  unrestricted, `dart:typed_data` and `dart:ui` included.
  - `dart:ui` is how geometry arrives where `widgets.dart` would be dead weight:
    `Path`, `PathFillType`, `Rect`, `Offset` and `Color` in the GeoJSON parser.
    Reaching for it inside a widget is a mistake — a widget has a `BuildContext`
    and should use `widgets.dart`.
  - `dart:convert` is not used. `KumoGeoJsonParser` takes an already-decoded
    `Map`, so the package takes no position on how the bytes arrived.
  - `vector_math` is permitted **only** in `lib/src/charts/`, for `Matrix4`,
    `Vector3` and the geo projection. That projection is pure math and imports no
    Flutter widgets at all, and Flutter re-exports `Matrix4` but not `Vector3`.
    It is the same math package Flutter itself depends on, so it adds no
    transitive weight. Do not reach for it elsewhere.
  - `phosphor_flutter` is NOT usable: 2.1.0 declares
    `class PhosphorIconData extends IconData`, and `IconData` is a `final class`
    since Flutter 3.43. `phosphor_icons` is the maintained fork that fixes this.
  - `services.dart` is permitted only where a widget genuinely needs a platform
    service or key constant (`Clipboard`, `LogicalKeyboardKey`) that
    `widgets.dart` does not re-export.
  - `foundation.dart` is permitted only for the `kIsWeb` platform guard in
    `KumoTheme`.
- NEVER import `material.dart` or `cupertino.dart`, in `lib/`, `test/` or
  `example/`.
- Transparency is `const Color(0x00000000)`. `Colors.transparent` lives in
  Material. That literal is the only raw colour a component may contain.
- Consumers import the `kumo_ui.dart` barrel, which re-exports a curated
  `widgets.dart` subset plus every component. Inside `lib/`, import the specific
  file instead.
- Every interactive widget keeps a 48px minimum tap target, paints a visible
  focus ring, activates on Enter/Space, and carries `Semantics`.
- Colour is never the only signal. Pair a status colour with text or an icon.
- A chart layer's `paint` body allocates nothing. Every `Paint`, `Path`,
  `TextPainter`, `RRect`, `Rect` and `Offset` is built in `prepare()`, which runs
  once per layout. A `paint` body that constructs one of those is a bug even when
  it renders correctly: it is invisible in a screenshot and costs frames the
  moment data streams. Tokens come from `KumoChartContext`, never from
  `KumoTheme.of(context)` inside a layer.
- `///` dartdoc on every public class, member and parameter.
- A new widget or behaviour ships with tests, and the bundled example
  demonstrates it. The one documented exception is `KumoLoader`: its animation
  never settles, so a screen that always shows one makes `pumpAndSettle` hang.
- Coverage against Cloudflare's upstream component set is tracked in
  `skills/kumo-registry/`. Consult it before adding a widget, so a new one fills
  a real gap rather than duplicating an existing component under a new name.

## 3. Theming

- `KumoColors` is immutable and describes ONE scheme. `KumoColors.dark()` and
  `KumoColors.light()` are peers, and both accept per-token overrides.
- `const KumoColors()` is the dark scheme, kept for backward compatibility.
- Three constructors carry colour defaults. A new token goes into all three, plus
  `operator ==` and `hashCode`.
- A new text token must join the `textTokens` map in
  `test/kumo_accessibility_test.dart`, or it ships unverified.
- A widget that pushes a route captures `KumoTheme.of(context)` BEFORE the push
  and re-provides `KumoTheme` above the navigator or overlay.
- `KumoApp` owns scheme resolution for an app. `KumoTheme` stays neutral and
  renders whatever `KumoColors` it is handed.

## 4. Platform boundaries and intellectual property

- **MOBILE AND DESKTOP NATIVE ONLY.** `kumo_ui` targets Android, iOS, macOS,
  Linux and Windows.
- **NO FLUTTER WEB TARGETS.** Do not add support, conditional compilation, or
  web-specific overrides (`dart:html`, `package:web`, CanvasKit adapters).
  `KumoTheme.of` and `KumoApp` assert the boundary and throw `UnsupportedError`
  on `kIsWeb`, and that assertion is deliberate.
- **RESPECT ORIGINAL KUMO UI.** Cloudflare's official web interface is the
  web-native React/Tailwind Kumo UI. Flutter Web implementations are forbidden,
  to avoid fragmenting that ecosystem. The package claims no affiliation with
  Cloudflare; keep the trademark disclaimer in the README.

## 5. Project shape

```
lib/kumo_ui.dart          public barrel: curated widgets.dart re-export + every component
lib/src/kumo_app.dart     KumoApp and KumoApp.router
lib/src/components/       the 32 public component widgets (one file each, plus
                          KumoFocusable, the wrapper they are all built from)
lib/src/charts/           chart subsystem: the layer contract, the palette and
                          KumoCanvas at the root, then timeseries/, sankey/ and
                          map/ per family
lib/src/layout/           kKumoBreakpoint, KumoResponsiveLayout
lib/src/theme/            KumoPalette, KumoLightPalette, KumoColors, KumoTheme, KumoTypography
example/                  runnable gallery, routed with go_router, single-import
test/                     unit and widget tests, including the both-scheme contrast suite
skills/flutter-kumo-ui/   consumer-facing agent skill (installable from GitHub)
doc/images/               README screenshots
```

Two widgets are pushed through static methods rather than constructed:
`KumoModal.show<T>` and `KumoBottomSheet.show<T>`. `KumoToastManager` and
`KumoPalette` / `KumoTypography` are static-only surfaces.

## 6. Commands

```sh
flutter analyze                 # must be clean before anything else
flutter test                    # root suite, includes both-scheme contrast checks
cd example && flutter test      # example suite
flutter pub publish --dry-run   # must report 0 warnings
```

The example must keep importing only `kumo_ui`, `phosphor_icons` and
`go_router`. If you need another primitive, add it to the barrel's curated
re-export list rather than adding a `widgets.dart` import to the example.

## 7. Release

- Bump `version` in `pubspec.yaml`, add a matching `CHANGELOG.md` entry, and move
  the README badge and install snippet with it.
- Additive changes are minor releases, breaking changes are major.
- Commit, tag `vX.Y.Z`, push `main` and the tag, then publish. `dart pub publish`
  refuses a dirty tree, so commit first.
- Keep `skills/flutter-kumo-ui/SKILL.md` version metadata in step with the
  package version.

## 8. Consumers install the skill

`skills/flutter-kumo-ui/` teaches any coding agent to build UIs with this
package. It follows the Agent Skills standard (a `SKILL.md` with YAML
frontmatter), so it is agent-agnostic: Claude Code, Codex, Cursor, Gemini CLI,
Command Code and anything else implementing the standard can read it.

```sh
npx skills add hafizhfadh/flutter_kumo_ui
```

The project-local copies at `.agents/skills/flutter-kumo-ui` and
`.commandcode/skills/flutter-kumo-ui` are symlinks to the canonical
`skills/flutter-kumo-ui/`. Edit the canonical directory only.
