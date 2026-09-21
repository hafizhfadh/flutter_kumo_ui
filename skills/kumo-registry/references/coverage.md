# Coverage against Cloudflare's Kumo component set

Matrix for `kumo_ui` 1.4.0. Upstream inventory from
https://kumo-ui.com/components and https://kumo-ui.com/registry.

Status: **covered** (direct widget), **partial** (capability exists inside
another widget), **missing**, or **excluded** (deliberately not ported).

## Components

| Upstream | kumo_ui | Status | Note |
| --- | --- | --- | --- |
| Autocomplete | - | missing | |
| Badge | `KumoBadge` | covered | 5 variants |
| Banner | `KumoBanner` | covered | inline and persistent; `KumoToast` stays for transient |
| Breadcrumbs | `KumoBreadcrumb` | covered | |
| Button | `KumoButton` | covered | 2 variants |
| Button Group | - | missing | |
| Checkbox | `KumoCheckbox` | covered | |
| Clipboard Text | `KumoCodeBlock` | partial | copy action only, no standalone widget |
| Cloudflare Logo | - | excluded | unaffiliated package ships no Cloudflare marks |
| CodeHighlighted | `KumoCodeBlock` | partial | monospace surface, no syntax highlighting |
| Collapsible | `KumoAccordion` | covered | |
| Combobox | - | missing | |
| Command Palette | - | missing | |
| Date Picker | - | missing | |
| Dialog | `KumoModal` | covered | `KumoModal.show<T>` |
| Dropdown | `KumoSelect` | covered | popover on desktop |
| Empty | `KumoEmpty` | covered | added in 1.4.0 |
| Flow | - | missing | |
| Grid | `KumoDataGrid` | partial | card grid, not a general layout grid |
| Inline Copy Text | `KumoCodeBlock` | partial | copy action only |
| Input | `KumoInput` | covered | |
| InputArea | `KumoInput` | covered | `KumoInput(maxLines: n)`, not a second widget |
| InputGroup | - | missing | |
| Label | `KumoLabel` | covered | added in 1.4.0 |
| Layer Card | `KumoDataCard` | partial | resource card, not a general layer |
| Layer Dialog | - | missing | |
| Link | `KumoLink` | covered | added in 1.4.0 |
| Loader | `KumoLoader` | covered | added in 1.4.0 |
| Meter | `KumoMeter` | covered | added in 1.4.0 |
| Pagination | `KumoPagination` | covered | |
| Popover | - | missing | `KumoSelect` has an internal one |
| Radio | `KumoRadio` | covered | added in 1.5.0 |
| Select | `KumoSelect` | covered | |
| Sensitive Input | `KumoSensitiveInput` | covered | `KumoInput` plus a reveal toggle |
| Sidebar | `KumoDrawerScaffold` | covered | added in 1.6.0; an adaptive rail that becomes a drawer below `kKumoBreakpoint` |
| Skeleton Line | `KumoSkeleton` | covered | added in 1.4.0 |
| Switch | `KumoSwitch` | covered | |
| Table | `KumoDataGrid` | partial | cards, not a true data table |
| Table of Contents | - | missing | |
| Tag Input | - | missing | |
| Tabs | `KumoTabs` | covered | |
| Text | `KumoTypography` | covered | type scale, not a widget |
| Toolbar | - | missing | |
| Toast | `KumoToast` | covered | plus `KumoToastManager` |
| Tooltip | `KumoTooltip` | covered | hover on desktop, long press on touch |
| **Scaffold** | `KumoScaffold` | kumo_ui only | no upstream equivalent |

## Charts

| Upstream | kumo_ui | Status |
| --- | --- | --- |
| Timeseries | - | missing |
| Maps | - | missing |
| Sankey | - | missing |
| Custom Chart | - | missing |

## Blocks

| Upstream | kumo_ui | Status |
| --- | --- | --- |
| Page Header | `KumoHeader` | covered |
| Resource List | `KumoDataGrid` + `KumoDataCard` | partial |
| Delete Resource | `KumoModal` | partial | a pattern, not a component |

## Summary at 1.6.0

- **45 upstream components: 26 covered, 6 partial, 12 missing, 1 excluded.**
- `KumoScaffold` has no upstream equivalent, so it is not one of those 45.
- `scripts/check_coverage.sh` prints `covered 33, missing 13`. The two counts
  answer different questions: the script asks "does the mapped symbol still
  exist", so it reports the 26 covered plus the 6 partial plus `KumoScaffold` as
  33 covered, and folds the excluded logo in with the missing 12 to make 13.
  The summary above is the parity count.
- Upstream's `Sidebar` is a large composable system (collapsible groups,
  icon-only mode, peeking, drag-to-resize, sliding views, a mobile sheet).
  `KumoDrawerScaffold` covers the adaptive part: a docked rail on a wide screen
  and a drawer sheet below the breakpoint, with a scrim, Escape to close and
  focus moved inside. The collapsible sub-menus, resizing, peeking and sliding
  views are not ported.
- Charts are absent entirely. Note that the 1.0.0 changelog claimed
  "metric blocks, and telemetry charts"; that claim was false and was corrected
  in 1.4.0.
- The remaining gaps, roughly in value order: `Popover`, `Table`, `InputGroup`,
  `Layer Dialog`, `Toolbar`, `Tag Input`, `Combobox`, `Autocomplete`,
  `Date Picker`, `Command Palette`, `Flow`, `Button Group`.