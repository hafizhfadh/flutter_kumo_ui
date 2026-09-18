# kumo_ui

**A mobile-first Flutter implementation of Cloudflare's Kumo UI design system, built on `package:flutter/widgets.dart` alone.**

![version](https://img.shields.io/badge/version-1.0.1-F38020)
![platforms](https://img.shields.io/badge/platform-android_%7C_ios_%7C_macos_%7C_linux_%7C_windows-3DDC84)
![web](https://img.shields.io/badge/web-not_supported-critical)
![flutter](https://img.shields.io/badge/flutter-widgets.dart_only-02569B)

`kumo_ui` reconstructs the Cloudflare dashboard's dark, high-density visual
language — a near-black canvas, layered surfaces, hairline borders and a single
orange brand signal — without ever importing `material.dart` or
`cupertino.dart`. Every widget is composed from `widgets.dart` primitives and
resolves its colors from `KumoTheme.of(context)`.

## Platform support

| Platform | Status |
| --- | --- |
| Android | Supported |
| iOS | Supported |
| macOS | Supported |
| Linux | Supported |
| Windows | Supported |
| **Web** | **Not supported — throws `UnsupportedError`** |

## Platform & architectural philosophy

- **Zero Material, zero Cupertino.** The library imports only
  `package:flutter/widgets.dart`, `package:flutter/services.dart` (clipboard
  services), `package:flutter/foundation.dart` (the `kIsWeb` platform guard)
  and `package:phosphor_icons/phosphor_icons.dart`. There are no
  `MaterialApp`, `Theme`, `Card` or `InkWell` dependencies to leak into your
  widget tree, so `kumo_ui` composes cleanly with any navigation or state
  solution you already use.
- **Single-import ergonomics.** The core `widgets.dart` primitives are
  re-exported from `kumo_ui.dart`, so an app builds a whole screen from one
  import. Material and Cupertino are still never exposed.
- **Mobile-first, then adaptive.** Layouts are designed at phone widths first:
  full-width tap targets with a 48px minimum height, vertical stacks instead of
  forced multi-column rows, and expandable cards for dense resource data. The
  same widgets then unfold into denser arrangements as the available width
  grows.
- **Adaptive to the container, not just the window.** Adaptive widgets read
  their own `LayoutBuilder` constraints, so a sidebar, split pane or embedded
  view adapts on its own instead of assuming it owns the whole screen. The
  shared switchover point lives in `kKumoBreakpoint` (600 logical pixels).
- **An explicit web boundary.** Cloudflare's canonical Kumo UI is the
  React/Tailwind implementation that ships with the dashboard. To avoid
  fragmenting that ecosystem with an unofficial browser re-implementation,
  `kumo_ui` refuses to run on Flutter Web: `KumoTheme.of` re-asserts
  `kIsWeb` and throws `UnsupportedError`. This package makes no claim to, and
  does not reproduce, Cloudflare's official web assets or trademarks.

## Getting started

Add the package and its icon dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  kumo_ui: ^1.0.1
  phosphor_icons: ^3.0.1
```

Then import it:

```dart
import 'package:kumo_ui/kumo_ui.dart';
```

That single import is enough to build a screen. `kumo_ui` re-exports the core
Flutter primitives it is itself built from — `Widget`, `StatelessWidget`,
`StatefulWidget`, `State`, `BuildContext`, `Column`, `Row`, `Stack`,
`Container`, `Text`, `Color`, `WidgetsApp`, `Navigator`, `MediaQuery` and
friends — so you do not have to add `package:flutter/widgets.dart` alongside
it.

Two things worth knowing about those re-exports:

- **They come from `package:flutter/widgets.dart` only.** Material and Cupertino
  symbols are never exposed. Because both paths resolve to the *same* Flutter
  declarations, importing `kumo_ui` next to `material.dart` cannot produce an
  ambiguous name.
- **It is a curated subset, not the whole of `widgets.dart`.** If you reach for
  something outside it, add `package:flutter/widgets.dart` yourself — the
  compiler will point at the missing name immediately.

The Phosphor glyph constants still come from `phosphor_icons`, since that is
where the icon names are declared:

```dart
import 'package:phosphor_icons/phosphor_icons.dart';
```

`kumo_ui` targets Android, iOS, macOS, Linux and Windows. Do not add a web
target; the package will throw at runtime if you do.

## Usage

### 1. Wrap your app in `KumoTheme` and `WidgetsApp`

`KumoTheme` supplies the palette to every descendant, and `WidgetsApp` provides
the navigator, text direction and `MediaQuery` that Kumo widgets rely on —
without pulling in Material.

```dart
import 'package:kumo_ui/kumo_ui.dart';

void main() {
  // Fails fast on Flutter Web with a clear UnsupportedError.
  KumoTheme.ensureSupportedPlatform();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KumoTheme(
      colors: const KumoColors(),
      child: WidgetsApp(
        title: 'Kumo',
        color: const Color(0xFF111111),
        textStyle: KumoTypography.body,
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
            PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  builder(context),
            ),
        home: const HomeScreen(),
      ),
    );
  }
}
```

### 2. Build a mobile list with `KumoListGroup` and `KumoListItem`

```dart
import 'package:kumo_ui/kumo_ui.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

class SettingsList extends StatelessWidget {
  const SettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return KumoListGroup(
      title: 'Zone settings',
      children: [
        KumoListItem(
          title: 'DNS records',
          subtitle: '42 records',
          leading: const PhosphorIcon(PhosphorIconsRegular.globe, size: 18),
          onTap: () {},
        ),
        KumoListItem(
          title: 'Caching',
          subtitle: 'Standard',
          leading: const PhosphorIcon(PhosphorIconsRegular.lightning, size: 18),
          trailing: const KumoSwitch(value: true, onChanged: _noop),
        ),
      ],
    );
  }

  static void _noop(bool _) {}
}
```

Rows keep a 56px minimum height, share one rounded outline, and are separated by
1px dividers. A trailing caret appears automatically on any row that has an
`onTap`.

### 3. Render expandable `KumoDataCard` resources in a `KumoDataGrid`

`KumoDataGrid` stacks its children on phones and lays them out as a bordered
multi-column grid on wider containers, reusing the very same cards in both
arrangements.

```dart
import 'package:kumo_ui/kumo_ui.dart';

class ZoneOverview extends StatelessWidget {
  const ZoneOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return KumoDataGrid(
      maxColumns: 3,
      children: [
        const KumoDataCard(
          title: 'example.com',
          subtitle: 'Zone · Pro plan',
          statusLabel: 'Active',
          details: [
            KumoDataPair(label: 'Nameservers', value: 'ada.ns.cloudflare.com'),
            KumoDataPair(label: 'Records', value: '42'),
          ],
        ),
        KumoDataCard(
          title: 'Global DNS',
          subtitle: 'Zone · Free plan',
          statusLabel: 'Pending',
          // Pull a status token straight from the palette.
          statusColor: KumoTheme.of(context).warning,
          details: const [
            KumoDataPair(label: 'Nameservers', value: 'bob.ns.cloudflare.com'),
          ],
        ),
      ],
    );
  }
}
```

Each card reveals its key/value pairs when its header is tapped. On desktop
viewports those pairs sit side by side; on phones each pair stacks, so long
values never overflow.

### 4. Adapt between mobile and desktop with `KumoResponsiveLayout`

```dart
import 'package:kumo_ui/kumo_ui.dart';

class AdaptivePanel extends StatelessWidget {
  const AdaptivePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return KumoResponsiveLayout(
      breakpoint: kKumoBreakpoint,
      mobile: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KumoAccordion(
            title: 'Advanced settings',
            child: Text('Zone tag and routing rules.'),
          ),
          SizedBox(height: 12),
          KumoCodeBlock(code: 'npx wrangler deploy'),
        ],
      ),
      desktop: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: KumoAccordion(
              title: 'Advanced settings',
              child: Text('Zone tag and routing rules.'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(child: KumoCodeBlock(code: 'npx wrangler deploy')),
        ],
      ),
    );
  }
}
```

`KumoResponsiveLayout` decides from its own constraints, so it also adapts
correctly inside a sidebar or split pane.

## Component catalog

**Form and input**

- `KumoInput` — single-line text field with label, placeholder, prefix/suffix
  icons, obscured entry and inline error state.
- `KumoSwitch` — compact on/off toggle with a 150ms eased thumb slide.
- `KumoCheckbox` — labelled 18px checkbox that flips to the brand fill when
  checked, with the whole row as one 48px tap target.
- `KumoSelect<T>` — single-choice field that opens a popover on desktop and a
  `KumoBottomSheet` action sheet on phones.
- `KumoSegmentedControl<T>` — horizontal segmented selector for switching
  between sibling views.
- `KumoButton` — brand-filled or outlined action with a 48px touch target and
  optional Phosphor icon.

**Navigation**

- `KumoBreadcrumb` — scrollable parent-route trail with caret separators and a
  non-interactive current page.
- `KumoTabs` — tab bar with a 2px brand indicator under the active tab.
- `KumoPagination` — Prev/Next switcher with a monospace `Page X of Y`
  indicator.

**Structure and layout**

- `KumoHeader` — section header that stacks its action under the title on
  phones and aligns it across the row on desktop.
- `KumoListGroup` — bordered group that separates `KumoListItem` rows with 1px
  dividers.
- `KumoDataGrid` — adaptive card container: a vertical stack on phones, a
  bordered multi-column grid on desktop.
- `KumoDataCard` — expandable resource card with a status chip and adaptive
  key/value details.
- `KumoResponsiveLayout` — swaps any two arrangements at a configurable
  breakpoint based on the local constraints.
- `KumoAccordion` — collapsible section using a `SizeTransition` reveal.
- `KumoBottomSheet` — bottom-anchored surface for touch-first choices, with
  `KumoBottomSheetItem` rows at a full 48px tap height.

**Content and overlay**

- `KumoCodeBlock` — monospace code surface with an optional language label and a
  clipboard copy action.
- `KumoModal` — modal dialog built on a custom `RawDialogRoute`, with a dimmed
  barrier and a centered card.
- `KumoToast` and `KumoToastManager` — stacked, auto-dismissing status banners
  overlaid at the bottom centre for info, success, warning and error states.
- `KumoBadge` — 11px monospace pill tag for metadata, plan types and status
  flags, in info, success, warning, error and neutral variants.

**Theming**

- `KumoTheme` — `InheritedWidget` that supplies the palette and asserts the
  platform guardrail.
- `KumoPalette` — the raw scale: a ten-step `gray0`–`gray9` ramp plus
  `orange5`, `blue5`, `red5`, `green5` and `amber5` accents.
- `KumoColors` — the semantic layer. Every token resolves to a `KumoPalette`
  step: canvas, surface, subtle surface, border, brand accent, focus ring, four
  text tones and info/success/warning/error status colors.
- `KumoTypography` — `h1`, `h2`, `body`, `bodyMuted`, `caption` and `code`
  text styles.
- `kKumoBreakpoint` — the shared 600px mobile/desktop switchover point.

## Example

A runnable showcase lives in [`example/`](example/lib/main.dart). It exercises
every component at both a phone and a desktop viewport, and imports only
`package:kumo_ui/kumo_ui.dart` plus the Phosphor glyph constants:

```sh
cd example
flutter run
```

## Additional information

- Contributions, bug reports and feature requests are welcome via the
  [issue tracker](https://github.com/hafizhfadh/flutter_kumo_ui/issues).
- `kumo_ui` follows semantic versioning from 1.0.0: additive API ships in minor
  releases, and fixes or internal changes ship in patches. See
  [CHANGELOG.md](CHANGELOG.md) for the detail of each release.
- `kumo_ui` is an independent, community implementation of a visual language. It
  is not affiliated with, endorsed by, or published by Cloudflare, Inc.

## Disclaimer & Trademark Notice

`kumo_ui` is an independent, community-driven Flutter package inspired by Cloudflare's Kumo UI design system. 

- **Independent Project:** This package is **NOT** affiliated, endorsed, sponsored, or maintained by Cloudflare, Inc.
- **Trademarks:** "Cloudflare", "Kumo", and "Kumo UI" are registered trademarks of Cloudflare, Inc.
- **Platform Scope:** This package is explicitly designed for native mobile and desktop Flutter applications. Web targets are intentionally disabled to respect Cloudflare's canonical React web component ecosystem (`@cloudflare/kumo`).
