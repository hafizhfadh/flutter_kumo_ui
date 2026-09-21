# kumo_ui theming reference

## Two layers

**Raw scales** are the source of truth for values. **Semantic tokens** are what
widgets read. A component never touches a raw step.

| Layer | Type | Who reads it |
| --- | --- | --- |
| `KumoPalette` (dark), `KumoLightPalette` (light) | `abstract final class`, `static const Color` | only `KumoColors` |
| `KumoColors` | `@immutable`, 16 `Color`/`Brightness` fields | `KumoTheme.of(context)` in components |

Both scales keep the same index convention: `gray0` is the darkest step, `gray9`
the lightest. `gray1`, `gray4` and `gray6` have no semantic consumer in one or
both schemes; they exist so the ramp stays continuous and consumer code can pick
an intermediate tone.

## Raw palettes

| Step | Dark (`KumoPalette`) | Light (`KumoLightPalette`) |
| --- | --- | --- |
| `gray0` | `#111111` | `#111111` |
| `gray1` | `#1D1D1D` | `#3F3F46` |
| `gray2` | `#262626` | `#52525B` |
| `gray3` | `#333333` | `#5A5F6B` |
| `gray4` | `#4D4D4D` | `#A1A1AA` |
| `gray5` | `#8D8D99` | `#D4D4D8` |
| `gray6` | `#A1A1AA` | `#E4E4E7` |
| `gray7` | `#C7C7CE` | `#EAEAEA` |
| `gray8` | `#DCDCE0` | `#F7F7F7` |
| `gray9` | `#EDEDED` | `#FFFFFF` |
| `orange5` | `#F38020` | `#B03A0A` |
| `blue5` | `#0EA5E9` | `#0369A1` |
| `red5` | `#EF4444` | `#DC2626` |
| `green5` | `#34D399` | `#036B4E` |
| `amber5` | `#F59E0B` | `#9A4D08` |

The light accents are deeper on purpose. The brand orange at `#F38020` measures
2.6:1 on a white canvas, which is fine for a fill and nowhere near enough for
text, so the light scheme takes the same hue down to `#B03A0A`.

## Semantic tokens

| Token | Dark | Light | Role |
| --- | --- | --- | --- |
| `canvas` | `#111111` | `#F7F7F7` | Page background |
| `surface` | `#1D1D1D` | `#FFFFFF` | Default raised surface |
| `subtleSurface` | `#262626` | `#EAEAEA` | Recessed fill (inputs, toggles, badges) |
| `border` | `#333333` | `#D4D4D8` | Hairline dividers and outlines |
| `primary` | `#F38020` | `#B03A0A` | Brand signal and active fill |
| `focus` | `#E9E9E9` | `#111111` | Focus ring (not a ramp step in dark) |
| `textPrimary` | `#EDEDED` | `#111111` | High-emphasis text and icons |
| `textSecondary` | `#A1A1AA` | `#52525B` | Labels, hints, placeholders |
| `textMuted` | `#8D8D99` | `#5A5F6B` | Lowest-emphasis text that still clears AA |
| `info` | `#0EA5E9` | `#0369A1` | Info status |
| `success` | `#34D399` | `#036B4E` | Success status |
| `warning` | `#F59E0B` | `#9A4D08` | Warning status |
| `danger` | `#EF4444` | `#DC2626` | Destructive **indicator** only |
| `dangerText` | `#F87171` | `#B91C1C` | Destructive **text** (contrast-safe) |
| `scrim` | 60% black | 20% black | Modal and sheet barrier wash |
| `brightness` | `dark` | `light` | Which scheme this set is |

`border` is a hairline by design (about 1.2:1 against `subtleSurface`); it is a
separator, not a control boundary. `danger` clears 3:1 (the non-text floor) but
sits below 4.5:1 on the recessed surfaces, which is exactly why `dangerText`
exists. Never put words in `danger`.

`focus` is a literal in both schemes rather than a ramp step, matching Kumo's
`--color-kumo-focus` token.

## Measured contrast

Ratios are against `canvas` / `surface` / `subtleSurface`. Text must clear 4.5:1,
non-text 3:1. `subtleSurface` is the binding constraint in dark and light.

| Token | Dark | Light |
| --- | --- | --- |
| `textPrimary` | 16.13 / 14.40 / 12.93 | 17.63 / 18.88 / 15.70 |
| `textSecondary` | 7.37 / 6.58 / 5.90 | 7.22 / 7.73 / 6.43 |
| `textMuted` | 5.76 / 5.14 / 4.61 | 5.97 / 6.39 / 5.32 |
| `primary` | 7.12 / 6.36 / 5.71 | 5.67 / 6.08 / 5.05 |
| `info` | 6.81 / 6.08 / 5.46 | 5.54 / 5.93 / 4.93 |
| `success` | 9.82 / 8.77 / 7.87 | 6.09 / 6.53 / 5.43 |
| `warning` | 8.79 / 7.85 / 7.05 | 5.70 / 6.11 / 5.08 |
| `dangerText` | 6.83 / 6.09 / 5.47 | 6.04 / 6.47 / 5.38 |
| `danger` (3:1 floor) | 5.02 / 4.48 / 4.02 | 4.51 / 4.83 / 4.01 |
| `focus` (3:1 floor) | 15.55 / 13.88 / 12.46 | 17.63 / 18.88 / 15.70 |
| `canvas` on `primary` (button label) | 7.12 | 5.67 |

## Resolving a scheme

```dart
KumoThemeMode.system   // follows the platform, repaints on change (default)
KumoThemeMode.light
KumoThemeMode.dark

KumoColors.of(Brightness.light)   // == KumoColors.light()
const KumoColors()                // == KumoColors.dark(), the back-compat default
```

`KumoApp` owns the resolution: it reads
`WidgetsBinding.instance.platformDispatcher.platformBrightness` (not `MediaQuery`,
because it builds the `WidgetsApp` that creates one) and re-reads it through a
`WidgetsBindingObserver`. `KumoTheme` itself stays neutral and renders whatever
`KumoColors` it is handed, so a single screen can pin a scheme.

## Typography

Six tokens, shape only plus a tone: `h1` (24/w700), `h2` (18/w600), `body`
(14/w400), `bodyMuted` (14/w400), `caption` (12/w400), `code` (12/w500,
`fontFamily: 'monospace'`).

- `KumoTypography.h1` … `.code` are the **dark** tones. Safe outside a theme,
  wrong inside a light one.
- `KumoTheme.textStylesOf(context)` returns a `KumoTextStyles` tinted for the
  active scheme: `h1`/`h2`/`body`/`code` in `textPrimary`, `bodyMuted`/`caption`
  in `textSecondary`. Use this inside the app.
- `KumoTypography.resolve(colors)` builds the same set from tokens you already
  hold. `textStylesOf` memoizes per `KumoColors` instance via an `Expando`, so it
  is cheap to call in `build`.

## Adding a token

1. Add the field to `KumoColors`, with the default in **all three** constructors
   (`KumoColors`, `.dark`, `.light`). `.dark` duplicates the unnamed defaults on
   purpose so the two schemes read as peers.
2. Extend `operator==` and `hashCode`.
3. If the value comes from a ramp, add the step to `KumoPalette` **and**
   `KumoLightPalette`.
4. Write a dartdoc comment with the role and the measured ratio per surface.
5. If the token carries text, add it to the `textTokens` map in
   `test/kumo_accessibility_test.dart`. That map is what the contrast suite
   iterates over both schemes, so a text token that is not listed is unverified.
6. Update the README token table and this file.

## Verifying a colour decision

Never eyeball a pairing. Compute the ratio, or run the checker the repo already
vendors:

```sh
python3 .agents/skills/antislop-human/contrast-check.py "#B03A0A" "#F7F7F7"
```

`flutter test` runs the same WCAG 2.1 formula as a parameterized suite over both
schemes, so a token that fails AA fails the build.
