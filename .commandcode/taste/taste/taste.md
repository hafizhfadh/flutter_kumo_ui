# Taste
- Requires every public class, property, and method to carry `dartdoc` (`///`) comments. Confidence: 0.85
- Forbids placeholder/stub comments (e.g. `// TODO: implement rest`); expects complete, fully compilable code rather than partial scaffolding. Confidence: 0.85
- Prefers pulling styling dynamically from a theme provider (e.g. `KumoTheme.of(context)`) instead of inlining raw hex/color values at call sites. Confidence: 0.75
- Avoids generic Material/Cupertino fallbacks; restricts imports to `package:flutter/widgets.dart` (no `material.dart` or `cupertino.dart`). Confidence: 0.8
- Expects `flutter analyze` to run clean (zero static analysis errors) and `flutter test` to pass, across both the library and example packages, as explicit completion criteria before a task is considered done. Confidence: 0.85
- Commits to explicit task specifications with named file locations, exact parameters (pixel sizes, hex values, API signatures), constraints, and acceptance steps. Confidence: 0.7
- For a UI library, expects an interactive example app (`example/lib/main.dart`) that showcases every component, kept in sync as new components are added. Confidence: 0.55
- Prefers mobile-first adaptive layouts that respond to available width: a stacked arrangement on phones and a side-by-side/grid arrangement on wide containers, chosen via `LayoutBuilder`/`MediaQuery` around a shared ~600px breakpoint, with full-width touch targets of at least 48px. Confidence: 0.6
- Avoids Material-only APIs and constants in widgets-only code, e.g. uses `const Color(0x00000000)` instead of `Colors.transparent`. Confidence: 0.7
- Expects new components to ship with widget tests, and the example app to have a test that compiles and renders it (rather than trusting `analyze` alone). Confidence: 0.6
- Requires an accessibility contract on interactive widgets: `Semantics` tags on every clickable control (button/toggled/selected/expanded/enabled state and label), a keyboard focus ring shown on focus change, and `BoxConstraints(minWidth: 48, minHeight: 48)` minimum touch targets on all interactive components. Confidence: 0.85
- Requires color combinations used for text to clear WCAG AA contrast (>= 4.5:1) against every background they are painted on, with the weaker 3:1 threshold reserved for non-text indicators; expects the ratios to be measured, not assumed. Confidence: 0.85
- Prefers design tokens named by semantic role (canvas/surface/border/textPrimary/dangerText) over raw hue ramps, and accepts a documented role model in place of a literal N-step gray scale. Confidence: 0.6
- Prefers work to be grounded in the canonical upstream reference (official docs/site) and any spec premise that conflicts with it to be flagged and reported rather than satisfied by inventing values. Confidence: 0.5
- Targets a maximum pub.dev score: full README with badges, a platform-support table, copy-pasteable usage examples and a component catalog, plus complete public dartdoc. Confidence: 0.55
steable usage examples and a component catalog, plus complete public dartdoc. Confidence: 0.55
