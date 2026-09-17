# KUMO_UI BETA AGENT RULES

## 1. Design & Skill Alignment
- Use `npx skills add cloudflare/kumo@kumo-design` token mappings:
  - Canvas: `#111111`
  - Surface: `#1D1D1D`
  - Subtle Surface: `#262626`
  - Borders: `#333333`
  - Primary Brand Signal: `#F38020`
- Strictly follow anti-slop rules (`https://github.com/miqdadbadjuber/anti-slop`):
  - No `// TODO` comments or truncated placeholder methods.
  - No redundant wrappers or unused state fields.
  - Generate full, compilable Dart code blocks.

## 2. Core Constraints
- Import ONLY `package:flutter/widgets.dart`, `package:flutter/services.dart`, `package:flutter/foundation.dart` and `package:phosphor_icons/phosphor_icons.dart`.
  - `phosphor_flutter` is NOT usable: its latest release (2.1.0) does `class PhosphorIconData extends IconData`, and `IconData` is a `final class` since Flutter 3.43. `phosphor_icons` is the maintained fork that fixes this.
  - `package:flutter/services.dart` is permitted only where a widget genuinely needs a platform service (`Clipboard`, etc.) that `widgets.dart` does not re-export.
  - `package:flutter/foundation.dart` is permitted only for the `kIsWeb` platform guard in `KumoTheme`; `widgets.dart` re-exports only `Brightness` and `UniqueKey` from it.
- NEVER import `material.dart` or `cupertino.dart`.
- Use `const Color(0x00000000)` for transparency; `Colors.transparent` lives in `material.dart`.
- Include `dartdoc` comments (`///`) on all public parameters for pub.dev score maxing.

## PLATFORM BOUNDARIES & INTELLECTUAL PROPERTY
- **MOBILE & DESKTOP NATIVE ONLY:** `kumo_ui` is strictly built for mobile (Android, iOS) and native desktop platforms.
- **NO FLUTTER WEB TARGETS:** DO NOT add support, conditional compilation, or web-specific overrides (`dart:html`, `package:web`, or CanvasKit web adapters) to export `kumo_ui` for Flutter Web.
- **RESPECT ORIGINAL KUMO UI:** Cloudflare's official web interface uses the web-native React/Tailwind Kumo UI. Flutter Web implementations are explicitly forbidden to prevent fragmentation and respect Cloudflare's canonical web ecosystem.
