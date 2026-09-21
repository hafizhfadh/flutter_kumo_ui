---
name: kumo-registry
description: Check what of Cloudflare's Kumo component set is available in the Flutter kumo_ui package, and what is still missing. Use when asked whether Kumo has a component, whether kumo_ui covers one, what is missing from the package, whether a widget duplicates an upstream component, or before adding a new widget to kumo_ui.
license: MIT
metadata:
  package: kumo_ui
  upstream: https://kumo-ui.com/registry
---

# Kumo registry

`kumo_ui` is a partial port of Cloudflare's Kumo design system. Upstream ships
around 44 components plus charts and blocks; the Flutter package covers a subset.
This skill answers "is it available?" and "what is missing?" without guessing and
without a Figma token.

## Source of truth

The authorised inventories are the upstream docs:

- Components: https://kumo-ui.com/components
- Registry: https://kumo-ui.com/registry
- Design rules: https://kumo-ui.com/skill (vendored here as `.agents/skills/kumo-design/`)

Cloudflare also publishes a **Figma plugin** at https://kumo-ui.com/figma. It is
not an MCP server and it is not a query surface: it generates Figma components
from Cloudflare's `component-registry.json`, needs a local clone of the
`cloudflare/kumo` monorepo plus `pnpm`, requires Figma **Desktop**, and its token
sync needs `FIGMA_TOKEN` and `FIGMA_FILE_KEY`. Nothing in that flow can be read
by an agent without those credentials, and it describes *Cloudflare's* Figma
file, not this package. Use the docs, which are public.

## Answering "is X available?"

1. Read `references/coverage.md`. It maps every upstream component to its
   `kumo_ui` equivalent and its status.
2. Status meanings:
   - **covered** - a direct Flutter widget exists.
   - **partial** - the capability exists inside another widget, so document the
     gap rather than claiming parity (for example syntax highlighting in
     `KumoCodeBlock`).
   - **missing** - no Flutter equivalent yet.
   - **excluded** - deliberately not ported. `Cloudflare Logo` is excluded: the
     package is unaffiliated and ships no Cloudflare marks.
3. If a component is missing and the user asks for it, say so plainly, then
   check whether a smaller existing widget already covers the need before
   proposing a new one. Do not add a near-duplicate: `InputArea` is
   `KumoInput(maxLines: n)`, not a second widget.

## Keeping the matrix honest

The matrix is the package's own claim about itself, so it must not drift. Run:

```sh
sh scripts/check_coverage.sh .
```

The script extracts every `Kumo*` symbol from `lib/src`, then walks the mapping
and prints one line per upstream component:

- `covered` - the mapped symbol is present.
- `REGRESSED` - the mapping claims a symbol that no longer exists. A rename or a
  deletion broke the claim; fix the code or the matrix.
- `missing` - no equivalent, which is expected for the unported set.

Exit code is 0 either way, because a partial port is the normal state. Read the
summary line, and treat any `REGRESSED` as a bug to fix in the same change.

When a widget is added or renamed, update **both**
`references/coverage.md` and the `MAP` block in `scripts/check_coverage.sh`.

## Adding the next component

Before writing code, check the matrix so the new widget fills a real gap. Then
follow the package rules: semantic tokens only, 48px targets, both colour
schemes, dartdoc on every public member, a test, and a section in the bundled
example. See `skills/flutter-kumo-ui/` for the API and the conventions.
