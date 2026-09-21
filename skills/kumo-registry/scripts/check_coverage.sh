#!/usr/bin/env sh
# kumo_ui coverage check against Cloudflare's upstream Kumo component set.
#
# Usage: sh check_coverage.sh [package-root]
#
# Prints one line per upstream component: covered, REGRESSED or missing.
# A REGRESSED line means the mapping below names a symbol that is no longer in
# lib/src, so this file and references/coverage.md are out of date.
set -eu

ROOT=${1:-.}
SYMS=$(grep -rhoE '\bKumo[A-Z][A-Za-z]+' "$ROOT/lib/src" 2>/dev/null | sort -u)

if [ -z "$SYMS" ]; then
  echo "No Kumo* symbols found under $ROOT/lib/src" >&2
  exit 1
fi

covered=0
missing=0

while IFS='|' read -r upstream ours; do
  case "${upstream:-}" in ''|\#*) continue ;; esac
  if [ "$ours" = "MISSING" ]; then
    printf '  missing    %-20s\n' "$upstream"
    missing=$((missing + 1))
  elif printf '%s\n' "$SYMS" | grep -qx "$ours"; then
    printf '  covered    %-20s -> %s\n' "$upstream" "$ours"
    covered=$((covered + 1))
  else
    printf '  REGRESSED  %-20s -> %s (symbol not found)\n' "$upstream" "$ours"
    missing=$((missing + 1))
  fi
done <<'MAP'
Autocomplete|MISSING
Badge|KumoBadge
Banner|MISSING
Breadcrumbs|KumoBreadcrumb
Button|KumoButton
Button Group|MISSING
Checkbox|KumoCheckbox
Clipboard Text|KumoCodeBlock
Cloudflare Logo|MISSING
CodeHighlighted|KumoCodeBlock
Collapsible|KumoAccordion
Combobox|MISSING
Command Palette|MISSING
Date Picker|MISSING
Dialog|KumoModal
Dropdown|KumoSelect
Empty|KumoEmpty
Flow|MISSING
Grid|KumoDataGrid
Inline Copy Text|KumoCodeBlock
Input|KumoInput
InputArea|KumoInput
InputGroup|MISSING
Label|KumoLabel
Layer Card|KumoDataCard
Layer Dialog|MISSING
Link|KumoLink
Loader|KumoLoader
Meter|KumoMeter
Pagination|KumoPagination
Popover|MISSING
Radio|MISSING
Select|KumoSelect
Sensitive Input|MISSING
Sidebar|MISSING
Skeleton Line|KumoSkeleton
Switch|KumoSwitch
Table|MISSING
Table of Contents|MISSING
Tag Input|MISSING
Tabs|KumoTabs
Text|KumoTypography
Toolbar|MISSING
Toast|KumoToast
Tooltip|MISSING
Scaffold (kumo_ui only)|KumoScaffold
MAP

printf '\ncovered %d, missing %d\n' "$covered" "$missing"
printf 'Matrix: references/coverage.md\n'
