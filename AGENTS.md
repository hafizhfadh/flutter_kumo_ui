# KUMO_UI PACKAGE GUIDELINES

1. DEPENDENCY STACK:
   - ZERO imports of `package:flutter/material.dart` or `package:flutter/cupertino.dart`.
   - Strictly use `package:flutter/widgets.dart`.
   - Use `phosphor_flutter` for icons.

2. COMPONENT ARCHITECTURE:
   - All components must depend on `KumoTheme.of(context)` for token extraction.
   - Use `MouseRegion` and `GestureDetector` to manage active, hover, and focus states.
   - Provide explicit constructor parameters for custom styling overrides, but default strictly to Kumo tokens.
   - Include clear `dartdoc` comments (`///`) on every public widget and property for pub.dev automated docs.
