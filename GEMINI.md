# Ustaad Engineering & Design Protocol (GEMINI.md)

This document establishes the mandatory architectural rules, design conventions, and verification standards for the Ustaad codebase. All agents and contributors must adhere to these directives without exception.

---

## 1. Zero Hardcoding Mandate
**Never hardcode raw colors, spacing values, border radii, or font sizes in UI code.**
Everything must reference design tokens from `lib/src/theme/ustaad_theme.dart`:
- **Colors**: `UstaadColors.primary`, `UstaadColors.background`, `UstaadColors.textPrimary`, etc.
- **Spacing**: `UstaadSpacing.xs` (8), `UstaadSpacing.md` (16), `UstaadSpacing.lg` (24), etc.
- **Radius**: `UstaadRadius.sm` (12), `UstaadRadius.md` (16), `UstaadRadius.lg` (24), `UstaadRadius.pill`.
- **Typography**: `UstaadTypography.h1()`, `UstaadTypography.bodyLarge()`, `UstaadTypography.urduHeading()`.
- **Elevation**: `UstaadShadows.subtle`, `UstaadShadows.card`, `UstaadShadows.elevated`.

---

## 2. Accessibility & Typography Standards
1. **WCAG AA Compliance**:
   - Contrast ratio between text and background must be at least **4.5:1** (verified in `test/theme_test.dart`).
   - Do not use dark text on dark surfaces or light text on light surfaces.
2. **48dp Minimum Touch Target**:
   - All interactive controls (buttons, chips, icons, selectors) must have a tap bounding box of at least 48x48 dp.
3. **Typography Fonts & Line Heights**:
   - Headings: `Plus Jakarta Sans` (Weights 600/700, line-height `1.2`).
   - Body: `Inter` (Weights 400/500, line-height `1.5`).
   - Urdu & Roman Urdu: `Noto Nastaliq Urdu` (line-height `1.8` strictly required to avoid clipping).

---

## 3. Clean Architecture Structure
Maintain strict separation of concerns:
```
lib/src/
├── config/             # Configurable weights, endpoints, feature flags
├── core/               # Validation (Pakistani phone numbers, addresses), errors
├── domain/
│   ├── entities/       # Pure immutable Dart models
│   ├── services/       # Domain services (e.g. ProviderRankingService)
│   └── usecases/       # Single-responsibility business use cases
├── presentation/       # Lean state notifiers and UI view models
├── screens/            # Application screens
├── services/           # External service adapters & connectivity
├── theme/              # Design tokens and theme definitions
└── widgets/
    ├── primitives/     # Reusable atomic UI building blocks
    └── ...             # Screen-specific composed widgets
```

---

## 4. Verification Workflow
After ANY change or implementation phase:
1. **Static Analysis**:
   ```powershell
   flutter analyze
   ```
   Must produce `No issues found!`.
2. **Automated Unit & Widget Tests**:
   ```powershell
   flutter test
   ```
   Must pass 100% of test suites.
3. **Theme & Contrast Verification**:
   ```powershell
   flutter test test/theme_test.dart
   ```
4. **Visual Review**:
   - Capture rendered screenshots of new or updated screens.
   - Perform self-critique against the "Modern Desi Professional" standards.
   - Seek user sign-off before proceeding to the subsequent phase.
