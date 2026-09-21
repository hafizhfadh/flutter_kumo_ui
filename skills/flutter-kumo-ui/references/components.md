# kumo_ui component reference

Every public constructor in `kumo_ui` 1.4.0. Signatures are exact. `super.key` is
omitted from the tables because every widget takes it.

Types: `Widget`, `String`, `bool`, `Color`, `VoidCallback`, `ValueChanged<T>`,
`TextEditingController`, `RouteFactory`, `GlobalKey<NavigatorState>`,
`TransitionBuilder`, `RouterConfig<Object>`, `RouterDelegate<Object>`,
`RouteInformationParser<Object>`, `RouteInformationProvider`,
`BackButtonDispatcher`, `PhosphorIconData` (from `phosphor_icons`).

---

## App

### `KumoApp`

The `MaterialApp` equivalent: theme + navigator + root text style + platform
brightness in one widget.

| Param | Type | Default |
| --- | --- | --- |
| `title` | `String` | `''` |
| `light` | `KumoColors` | `KumoColors.light()` |
| `dark` | `KumoColors` | `KumoColors.dark()` |
| `mode` | `KumoThemeMode` | `KumoThemeMode.system` |
| `home` | `Widget?` | `null` |
| `routes` | `Map<String, WidgetBuilder>` | `{}` |
| `initialRoute` | `String?` | `null` |
| `onGenerateRoute` | `RouteFactory?` | `null` |
| `onUnknownRoute` | `RouteFactory?` | `null` |
| `navigatorKey` | `GlobalKey<NavigatorState>?` | `null` |
| `builder` | `TransitionBuilder?` | `null` |
| `debugShowCheckedModeBanner` | `bool` | `true` |

Asserts the platform boundary on mount. Supplies its own `pageRouteBuilder`, and
observes platform brightness so `KumoThemeMode.system` repaints on change.

### `KumoApp.router`

The `MaterialApp.router` equivalent. Same theme params (`title`, `light`, `dark`,
`mode`, `builder`, `debugShowCheckedModeBanner`) plus:

| Param | Type | Default |
| --- | --- | --- |
| `routeInformationProvider` | `RouteInformationProvider?` | `null` |
| `routeInformationParser` | `RouteInformationParser<Object>?` | `null` |
| `routerDelegate` | `RouterDelegate<Object>?` | `null` |
| `routerConfig` | `RouterConfig<Object>?` | `null` |
| `backButtonDispatcher` | `BackButtonDispatcher?` | `null` |

`routerConfig` is mutually exclusive with the other three, and `routerDelegate`
is required when `routerConfig` is null. There is no `home`, `routes`,
`initialRoute`, `onGenerateRoute` or `navigatorKey`.

`KumoThemeMode` is `system`, `light`, `dark`.

---

## Form and input

### `KumoInput`

| Param | Type | Default |
| --- | --- | --- |
| `label` | `String?` | `null` |
| `placeholder` | `String?` | `null` |
| `controller` | `TextEditingController?` | `null` (self-owned) |
| `obscureText` | `bool` | `false` |
| `errorMessage` | `String?` | `null` (non-empty shows the error state) |
| `prefixIcon` | `Widget?` | `null` |
| `suffixIcon` | `Widget?` | `null` |
| `onChanged` | `ValueChanged<String>?` | `null` |
| `maxLines` | `int?` | `1` (pass `null` to grow without limit) |
| `minLines` | `int?` | `null` |

Built on `EditableText`. Border states: resting `border`, focused `primary`, error
`danger`. The label renders uppercased. With `maxLines` above 1 the field grows
with its content and aligns a `prefixIcon` to the first line.

### `KumoSwitch`

| Param | Type | Default |
| --- | --- | --- |
| `value` | `bool` | required |
| `onChanged` | `ValueChanged<bool>` | required |
| `isDisabled` | `bool` | `false` |

40x22 track inside a 48x48 target. Track is `primary` when on, `border` when off;
the knob is the scheme's `textPrimary`.

### `KumoCheckbox`

| Param | Type | Default |
| --- | --- | --- |
| `value` | `bool` | required |
| `onChanged` | `ValueChanged<bool>` | required |
| `label` | `String?` | `null` |
| `isDisabled` | `bool` | `false` |

Also `static const double KumoCheckbox.boxSize = 18`. Checked fill is `primary`,
glyph is `canvas`. The whole row is one 48px tap target.

### `KumoRadio<T>`

| Param | Type | Default |
| --- | --- | --- |
| `value` | `T` | required |
| `groupValue` | `T` | required |
| `onChanged` | `ValueChanged<T>?` | `null` (renders inert) |
| `label` | `String?` | `null` |
| `isDisabled` | `bool` | `false` |

Also `static const double KumoRadio.size = 18`. Fully controlled: compare
`value` with `groupValue` yourself by threading the selected value through your
own state. Announced as a mutually exclusive group.

### `KumoSelect<T>`

| Param | Type | Default |
| --- | --- | --- |
| `value` | `T` | required |
| `options` | `Map<T, String>` | required (keys are values, values are labels) |
| `onChanged` | `ValueChanged<T>` | required |
| `label` | `String?` | `null` |

Popover on desktop, `KumoBottomSheet` action sheet below `kKumoBreakpoint`.

### `KumoSegmentedControl<T>`

| Param | Type | Default |
| --- | --- | --- |
| `segments` | `Map<T, String>` | required |
| `selected` | `T` | required |
| `onSelected` | `ValueChanged<T>` | required |

Fully controlled. Selected segment lifts onto `surface` with a `primary` label.

### `KumoButton`

| Param | Type | Default |
| --- | --- | --- |
| `label` | `String` | required |
| `onPressed` | `VoidCallback?` | `null` (null renders disabled and inert) |
| `icon` | `PhosphorIconData?` | `null` |
| `variant` | `KumoButtonVariant` | `KumoButtonVariant.primary` |

`KumoButtonVariant` is `primary` (brand fill, label in `canvas`) or `secondary`
(`subtleSurface` fill, `border` outline). 48px minimum.

### `KumoSensitiveInput`

| Param | Type | Default |
| --- | --- | --- |
| `label` | `String?` | `null` |
| `placeholder` | `String?` | `null` |
| `controller` | `TextEditingController?` | `null` (self-owned) |
| `errorMessage` | `String?` | `null` |
| `onChanged` | `ValueChanged<String>?` | `null` |

`KumoInput` composed with a reveal toggle in its suffix slot. Masked by default;
the toggle is a 48px target. Use `KumoInput(obscureText: true)` instead when the
value never needs reading back.

---

## Navigation

### `KumoBreadcrumb`

| Param | Type | Default |
| --- | --- | --- |
| `items` | `List<KumoBreadcrumbItem>` | required |

### `KumoBreadcrumbItem`

| Param | Type | Default |
| --- | --- | --- |
| `label` | `String` | required |
| `onTap` | `VoidCallback?` | `null` (null marks the current page) |

### `KumoTabs`

| Param | Type | Default |
| --- | --- | --- |
| `tabs` | `List<String>` | required |
| `selectedIndex` | `int` | required |
| `onTabChanged` | `ValueChanged<int>` | required |

2px `primary` indicator under the active tab; the bar scrolls horizontally.

### `KumoPagination`

| Param | Type | Default |
| --- | --- | --- |
| `currentPage` | `int` | required (1-based) |
| `totalPages` | `int` | required (below 1 is treated as 1) |
| `onPageChanged` | `ValueChanged<int>` | required |

Never fires outside `1..totalPages`.

---

## Structure and layout

### `KumoHeader`

| Param | Type | Default |
| --- | --- | --- |
| `title` | `String` | required |
| `subtitle` | `String?` | `null` |
| `action` | `Widget?` | `null` |
| `leading` | `Widget?` | `null` |

Stacks `action` under the title below `kKumoBreakpoint`, aligns it on one row
above. `leading` renders immediately before the heading (a back control, a glyph).

### `KumoListGroup`

| Param | Type | Default |
| --- | --- | --- |
| `title` | `String?` | `null` (rendered uppercased) |
| `children` | `List<Widget>` | required |

An empty `children` list renders `SizedBox.shrink()`.

### `KumoListItem`

| Param | Type | Default |
| --- | --- | --- |
| `title` | `String` | required |
| `subtitle` | `String?` | `null` |
| `leading` | `Widget?` | `null` |
| `trailing` | `Widget?` | `null` (replaces the default caret) |
| `onTap` | `VoidCallback?` | `null` |

56px minimum height. A trailing caret appears when `onTap` is set and `trailing`
is not.

### `KumoDataGrid`

| Param | Type | Default |
| --- | --- | --- |
| `children` | `List<Widget>` | required |
| `maxColumns` | `int` | `3` |
| `breakpoint` | `double` | `kKumoBreakpoint` |

Vertical stack below the breakpoint, bordered multi-column grid above. Children
are normally `KumoDataCard`s; cards inside a grid cell drop their own outline.

### `KumoDataCard`

| Param | Type | Default |
| --- | --- | --- |
| `title` | `String` | required |
| `subtitle` | `String?` | `null` |
| `statusLabel` | `String?` | `null` |
| `statusColor` | `Color?` | `null` (`success`) |
| `details` | `List<KumoDataPair>` | `const []` |
| `initiallyExpanded` | `bool` | `false` |

An empty `details` list makes the card static (no expansion). `statusColor` tints
text, so it must be contrast-safe: `success`, `warning` or `dangerText`.

### `KumoDataPair`

| Param | Type | Default |
| --- | --- | --- |
| `label` | `String` | required |
| `value` | `String` | required |

Side by side on desktop, stacked on mobile.

### `KumoAccordion`

| Param | Type | Default |
| --- | --- | --- |
| `title` | `String` | required |
| `child` | `Widget` | required |
| `initialExpanded` | `bool` | `false` |

`SizeTransition` reveal, so collapsed content never captures pointers.

### `KumoBottomSheet` (static)

| Param | Type | Default |
| --- | --- | --- |
| `context` | `BuildContext` | required |
| `child` | `Widget` | required |
| `title` | `String?` | `null` |
| `barrierDismissible` | `bool` | `true` |

`static Future<T?> show<T>({...})`. Pushed on a `RawDialogRoute` with a `scrim`
barrier. Captures the palette before pushing.

### `KumoBottomSheetItem`

| Param | Type | Default |
| --- | --- | --- |
| `label` | `String` | required |
| `isSelected` | `bool` | `false` |
| `onTap` | `VoidCallback?` | `null` |

Full-width 48px row. Selected rows use `primary` and weight 600.

### `KumoResponsiveLayout`

| Param | Type | Default |
| --- | --- | --- |
| `mobile` | `Widget` | required |
| `desktop` | `Widget?` | `null` (falls back to `mobile`) |
| `breakpoint` | `double` | `kKumoBreakpoint` |

`static bool isDesktop(BuildContext context, {double breakpoint = kKumoBreakpoint})`
answers from `MediaQuery`; the widget itself uses its own `LayoutBuilder`
constraints.

`kKumoBreakpoint` is a top-level `const double` equal to `600.0`.

---

## Content and overlay

### `KumoCodeBlock`

| Param | Type | Default |
| --- | --- | --- |
| `code` | `String` | required |
| `language` | `String?` | `null` |
| `showCopyButton` | `bool` | `true` |

12px monospace on `canvas`. The copy action confirms with `success` and resets
after 1500ms.

### `KumoModal` (static)

Same shape as `KumoBottomSheet.show`, but renders a centred card (max width 420)
on a `RawDialogRoute` with a `scrim` barrier.

### `KumoToast`

| Param | Type | Default |
| --- | --- | --- |
| `message` | `String` | required |
| `title` | `String?` | `null` |
| `kind` | `KumoToastKind` | `KumoToastKind.info` |
| `onClose` | `VoidCallback?` | `null` |

`KumoToastKind` is `info`, `success`, `warning`, `error`. The `info`/`success`/
`warning` accents are their tokens; `error` uses `danger` because the icon is
non-text (3:1 applies, not 4.5:1).

### `KumoToastManager` (static)

| Member | Signature |
| --- | --- |
| `defaultDuration` | `static const Duration` (4s) |
| `activeCount` | `static int get` |
| `show` | `static void show(BuildContext context, {required String message, String? title, KumoToastKind kind = KumoToastKind.info, Duration duration = defaultDuration})` |
| `dismiss` | `static void dismiss(int id)` |
| `clear` | `static void clear()` |

Stacks upward from the bottom centre, auto-dismisses, and lazily inserts an
overlay that is torn down once the last toast leaves. The layer follows the
active scheme, so a mode switch repaints live toasts.

### `KumoBadge`

| Param | Type | Default |
| --- | --- | --- |
| `label` | `String` | required |
| `variant` | `KumoBadgeVariant` | `KumoBadgeVariant.neutral` |
| `icon` | `PhosphorIconData?` | `null` |

`KumoBadgeVariant` is `info`, `success`, `warning`, `error`, `neutral`. 11px
monospace pill so tags of different words line up in a column. `subtleSurface`
fill, `border` outline. The `error` variant uses `dangerText`.

---

## Shell

### `KumoScaffold`

The screen shell. Fills the space it is given, so use it at the root of a route.

| Param | Type | Default |
| --- | --- | --- |
| `child` | `Widget` | required |
| `header` | `Widget?` | `null` (pinned above the body) |
| `bottomBar` | `Widget?` | `null` (pinned below the body) |
| `padding` | `EdgeInsets` | `EdgeInsets.all(20)` |
| `scrollable` | `bool` | `true` |
| `safeArea` | `bool` | `true` |
| `resizeToAvoidBottomInset` | `bool` | `true` |

### `KumoDrawerScaffold`

Places a `KumoDrawer` adaptively: docked rail at or above `breakpoint`, drawer
sheet below it.

| Param | Type | Default |
| --- | --- | --- |
| `child` | `Widget` | required |
| `drawer` | `Widget` | required (normally a `KumoDrawer`) |
| `breakpoint` | `double` | `kKumoBreakpoint` |
| `fullScreenOnMobile` | `bool` | `false` |

Statics: `open(context)`, `close(context)`, `isDocked(context)`,
`hasScaffold(context)`. Use `isDocked` to decide whether to render a menu
affordance at all. Below the breakpoint the sheet closes on a scrim tap and on
Escape, and focus moves inside while open.

`open`, `close` and `isDocked` need a context **below** the scaffold — the page
passed as `child`, or a widget the drawer builds. A callback that closes over the
context that *created* the scaffold is an ancestor of it and will not resolve, so
build the drawer through a `Builder` when its rows call `close`:

```dart
KumoDrawerScaffold(
  drawer: Builder(
    builder: (BuildContext drawerContext) => KumoDrawer(
      children: <Widget>[
        KumoDrawerItem(
          label: 'Home',
          onTap: () {
            KumoDrawerScaffold.close(drawerContext);
            drawerContext.go('/');
          },
        ),
      ],
    ),
  ),
  child: page,
)
```

`hasScaffold(context)` is the non-asserting probe: it separates "there is no
scaffold" from "the scaffold is not docked", which `isDocked` cannot, and never
asserts. A call from outside the scaffold is a debug assertion and a release no-op.

### `KumoDrawer`

| Param | Type | Default |
| --- | --- | --- |
| `children` | `List<Widget>` | required (usually `KumoDrawerGroup`s) |
| `header` | `Widget?` | `null` (pinned) |
| `footer` | `Widget?` | `null` (pinned) |
| `isCollapsed` | `bool` | `false` (icon-only rail) |

Preferred widths: `kKumoDrawerWidth` (240) and `kKumoDrawerCollapsedWidth` (68).

### `KumoDrawerItem`

| Param | Type | Default |
| --- | --- | --- |
| `label` | `String` | required |
| `icon` | `PhosphorIconData?` | `null` |
| `isSelected` | `bool` | `false` |
| `onTap` | `VoidCallback?` | `null` |
| `trailing` | `Widget?` | `null` |
| `isSubItem` | `bool` | `false` (indents) |
| `isCollapsed` | `bool` | `false` |

### `KumoDrawerGroup`

| Param | Type | Default |
| --- | --- | --- |
| `children` | `List<Widget>` | required |
| `label` | `String?` | `null` (uppercase micro label) |
| `isCollapsed` | `bool` | `false` |

---

## Feedback and primitives

### `KumoBanner`

| Param | Type | Default |
| --- | --- | --- |
| `message` | `String` | required |
| `title` | `String?` | `null` |
| `kind` | `KumoBannerKind` | `KumoBannerKind.info` |
| `action` | `Widget?` | `null` |
| `onDismiss` | `VoidCallback?` | `null` |

`KumoBannerKind` is `info`, `success`, `warning`, `error`. An inline, persistent
message. The counterpart to `KumoToast`, which is transient and floats above the
page. `error` uses `danger` for the icon, which is non-text, so 3:1 applies.

### `KumoTooltip`

| Param | Type | Default |
| --- | --- | --- |
| `message` | `String` | required |
| `child` | `Widget` | required |
| `placement` | `KumoTooltipPlacement` | `KumoTooltipPlacement.top` |

Shows on hover (desktop) or long press (touch), and attaches `message` to the
child as a semantics tooltip. `KumoTooltipPlacement` is `top` or `bottom`.

### `KumoLoader`

| Param | Type | Default |
| --- | --- | --- |
| `size` | `double` | `20` |
| `label` | `String?` | `null` (`'Loading'`) |

Indeterminate progress, drawn with a `CustomPaint` arc. Its animation never
settles, so a widget test must `pump()` a duration rather than `pumpAndSettle()`.

### `KumoMeter`

| Param | Type | Default |
| --- | --- | --- |
| `value` | `double` | required (clamped to `0..max`) |
| `label` | `String?` | `null` |
| `tone` | `KumoMeterTone` | `KumoMeterTone.primary` |
| `max` | `double` | `1` |
| `showValue` | `bool` | `true` |

`KumoMeterTone` is `primary`, `success`, `warning`, `danger`. The fill is an
indicator, so the tone may use the status colours; the label stays in
`textSecondary` because it is text.

### `KumoEmpty`

| Param | Type | Default |
| --- | --- | --- |
| `title` | `String` | `'Nothing here yet'` |
| `message` | `String?` | `null` |
| `icon` | `PhosphorIconData` | `PhosphorIconsRegular.tray` |
| `action` | `Widget?` | `null` |

### `KumoSkeleton`

| Param | Type | Default |
| --- | --- | --- |
| `width` | `double?` | `null` (stretches) |
| `height` | `double` | `12` |
| `lines` | `int` | `1` |
| `spacing` | `double` | `8` |

Static, not animated: a pulsing skeleton competes with the content it stands in
for and makes `pumpAndSettle` unusable.

### `KumoLink`

| Param | Type | Default |
| --- | --- | --- |
| `label` | `String` | required |
| `onPressed` | `VoidCallback?` | `null` (renders inert and muted) |
| `icon` | `PhosphorIconData?` | `null` |

### `KumoLabel`

| Param | Type | Default |
| --- | --- | --- |
| `text` | `String` | required (positional, rendered upper-cased) |
| `isDisabled` | `bool` | `false` |

---

## Theme

### `KumoTheme`

| Param | Type | Default |
| --- | --- | --- |
| `colors` | `KumoColors` | `const KumoColors()` (dark) |
| `child` | `Widget` | required |

- `static KumoColors of(BuildContext context)`
- `static KumoTextStyles textStylesOf(BuildContext context)`
- `static void ensureSupportedPlatform()` (throws `UnsupportedError` on web)

### `KumoColors`

`const KumoColors({canvas, surface, subtleSurface, border, primary, focus,
textPrimary, textSecondary, textMuted, info, success, warning, danger, dangerText,
scrim, brightness})`, plus `KumoColors.dark({...})` (identical defaults),
`KumoColors.light({...})` and `static KumoColors of(Brightness)`.

### `KumoTextStyles`

`const KumoTextStyles({required h1, required h2, required body, required
bodyMuted, required caption, required code})`, all `TextStyle`.

### `KumoTypography`

`static const TextStyle h1, h2, body, bodyMuted, caption, code` (dark tones), plus
`static KumoTextStyles resolve(KumoColors colors)`.

---

## Re-exported Flutter primitives

`lib/kumo_ui.dart` re-exports a curated `show` list from
`package:flutter/widgets.dart`. Grouped as in the barrel: core framework
(`Widget`, `StatelessWidget`, `StatefulWidget`, `State`, `InheritedWidget`,
`BuildContext`, `Key`, `ValueKey`, `GlobalKey`); layout (`Column`, `Row`, `Stack`,
`Positioned`, `Expanded`, `Flexible`, `Spacer`, `Container`, `SizedBox`,
`Padding`, `Align`, `Center`, `ConstrainedBox`, `BoxConstraints`,
`CrossAxisAlignment`, `MainAxisSize`, `Wrap`, `Builder`); geometry and paint
(`EdgeInsets`, `EdgeInsetsGeometry`, `Alignment`, `AlignmentGeometry`,
`BorderRadius`, `BoxDecoration`, `Border`, `BorderSide`, `BoxShape`, `Color`,
`ColoredBox`, and the paint primitives the chart subsystem's public surface is
built from: `Canvas`, `Paint`, `PaintingStyle`, `Path`, `Rect`, `Offset`, `Size`,
`StrokeCap`, `StrokeJoin`); text (`Text`, `TextStyle`, `TextEditingController`,
`TextOverflow`); scrolling (`ListView`, `SingleChildScrollView`,
`CustomScrollView`, `SliverList`, `SliverGrid`); interaction (`GestureDetector`,
`MouseRegion`, `Focus`, `FocusNode`, `Semantics`, `SystemMouseCursors`,
`VoidCallback`, `ValueChanged`); animation (`AnimatedContainer`,
`AnimatedOpacity`, `AnimatedCrossFade`, `SizeTransition`, `AnimationController`);
navigation (`runApp`, `WidgetsApp`, `Navigator`, `PageRouteBuilder`,
`RouteSettings`, `WidgetBuilder`, `MediaQuery`, `LayoutBuilder`, `SafeArea`,
`Brightness`); router (`RouteInformation`, `RouteInformationProvider`,
`RouteInformationParser`, `RouterConfig`, `RouterDelegate`,
`BackButtonDispatcher`).

If you need something outside that list, import `package:flutter/widgets.dart`
yourself. Never `material.dart`.
