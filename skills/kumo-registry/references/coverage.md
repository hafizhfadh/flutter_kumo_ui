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
| Banner | `KumoToast` | partial | toasts are transient; no inline banner |
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
| Radio | - | missing | highest-value gap in the form set |
| Select | `KumoSelect` | covered | |
| Sensitive Input | `KumoInput` | partial | `obscureText`, no reveal affordance |
| Sidebar | - | missing | desktop navigation shell |
| Skeleton Line | `KumoSkeleton` | covered | added in 1.4.0 |
| Switch | `KumoSwitch` | covered | |
| Table | `KumoDataGrid` | partial | cards, not a true data table |
| Table of Contents | - | missing | |
| Tag Input | - | missing | |
| Tabs | `KumoTabs` | covered | |
| Text | `KumoTypography` | covered | type scale, not a widget |
| Toolbar | - | missing | |
| Toast | `KumoToast` | covered | plus `KumoToastManager` |
| Tooltip | - | missing | |
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

## Summary at 1.4.0

- **45 upstream components: 21 covered, 8 partial, 15 missing, 1 excluded.**
- `KumoScaffold` has no upstream equivalent, so it is not one of those 45.
- `scripts/check_coverage.sh` prints `covered 30, missing 16`. The two counts
  answer different questions: the script asks "does the mapped symbol still
  exist", so it reports the 21 covered plus the 8 partial plus `KumoScaffold` as
  30 covered, and folds the excluded logo in with the missing 15 to make 16.
  The summary above is the parity count.
- Charts are absent entirely. Note that the 1.0.0 changelog claimed
  "metric blocks, and telemetry charts"; that claim was false and was corrected
  in 1.4.0.
- The remaining gaps, roughly in value order: `Radio`, `Tooltip`, `Popover`,
  `Table`, `Sidebar`, `Banner`, `Sensitive Input`, `InputGroup`,
  `Layer Dialog`, `Toolbar`, `Tag Input`, `Combobox`, `Autocomplete`,
  `Date Picker`, `Command Palette`, `Flow`, `Button Group`, `Table of Contents`.