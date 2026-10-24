# Ustaad Design System — "Modern Desi Professional"

## 1. Philosophy & Aesthetic
Ustaad is a home services booking application rooted in Pakistani culture and craftsmanship. The **Modern Desi Professional** design language balances high-tech reliability with cultural warmth, hospitality, and trust.

### Core Principles
1. **Culturally Grounded (Desi Warmth)**:
   - Primary **Emerald** (`#0F6E56` to `#14876A` gradient) symbolizes trust, prosperity, and Pakistani identity.
   - **Warm Amber** (`#F5A623`) represents artisanal skill, energy, and review ratings.
   - **Warm Neutrals** (`#FAFAF7` background, `#1A1A1A` charcoal text) create an approachable, high-end editorial feel.
   - **Zero Cold Blue-Greys**: Sterile corporate greys (`#ECEFF1`, `#F0F2F5`) are strictly forbidden.
2. **First-Class Bilingualism**:
   - Equal typographic dignity for English, Roman Urdu, and Nastaliq Urdu.
   - Nastaliq Urdu requires line-height **1.8** to prevent clipping of complex ascenders and descenders.
3. **Ergonomic & Accessible (WCAG AA)**:
   - Minimum **48dp tap target** on all interactive surfaces.
   - All text/background contrast ratios strictly meet or exceed **4.5:1** (tested in `test/theme_test.dart`).
   - Tinted emerald drop-shadows replace harsh Material elevations for subtle, clean depth.

---

## 2. Design Tokens Reference

### A. Color Palette (`UstaadColors`)
| Token | Hex / Value | Usage | WCAG AA Ratio |
|---|---|---|---|
| `primary` | `#0F6E56` | Primary brand actions, accents | 5.96:1 on white |
| `primaryLight` | `#14876A` | Gradient end, interactive hovers | 4.62:1 on white |
| `primaryDark` | `#0A4C3B` | Deep containers, header gradients | 8.92:1 on white |
| `primaryContainer` | `#E8F5F1` | Soft badge backgrounds, tint fills | — |
| `accent` | `#F5A623` | Amber badges, stars, highlights | High contrast on dark |
| `accentContainer` | `#FEF5E7` | Warning/rating chip backgrounds | — |
| `background` | `#FAFAF7` | Warm off-white canvas | Base |
| `surface` | `#FFFFFF` | Cards, bottom sheets, dialogs | Base |
| `border` | `#E7E6DF` | Card borders, dividers | Subdued |
| `borderStrong` | `#D3D1C7` | Outlined buttons, inputs | Clear boundary |
| `textPrimary` | `#1A1A1A` | Headings, titles, heavy emphasis | **16.24:1** on background |
| `textSecondary` | `#5A5954` | Body descriptions, metadata | **6.42:1** on background |
| `textMuted` | `#75736B` | Captions, placeholders | **4.55:1** on background |
| `verifiedBlue` | `#2563EB` | Official CNIC verification badges | High contrast |

### B. Typography (`UstaadTypography`)
Powered by Google Fonts:
- **Headings**: `GoogleFonts.plusJakartaSans`
  - Weights: `600` (SemiBold), `700` (Bold)
  - Line-height: **1.2** for tight, modern editorial headlines.
- **Body**: `GoogleFonts.inter`
  - Weights: `400` (Regular), `500` (Medium), `600` (SemiBold)
  - Line-height: **1.5** for relaxed body readability.
- **Urdu Strings**: `GoogleFonts.notoNastaliqUrdu`
  - Weights: `400` (Regular), `700` (Bold)
  - Line-height: **1.8** essential for Nastaliq calligraphy balance.

### C. Spacing Scale (`UstaadSpacing`)
Based strictly on the 4 / 8 / 12 / 16 / 24 / 32 / 48 pt scale:
- `xxs`: 4.0
- `xs`: 8.0
- `sm`: 12.0
- `md`: 16.0
- `lg`: 24.0
- `xl`: 32.0
- `xxl`: 48.0

### D. Corner Radii (`UstaadRadius`)
- `sm`: 12.0 (Buttons, inputs, small cards)
- `md`: 16.0 (Standard cards, modal sheets)
- `lg`: 24.0 (Hero search input cards, bottom sheets)
- `pill`: 999.0 (Chips, pills, avatar indicators)

### E. Soft Tinted Shadows (`UstaadShadows`)
```dart
static const List<BoxShadow> subtle = [
  BoxShadow(
    color: Color(0x140F6E56), // 8% tinted emerald
    blurRadius: 8,
    offset: Offset(0, 2),
  ),
];
```

---

## 3. UI Component Primitives (`lib/src/widgets/primitives/`)

1. **`UstaadButton`**:
   - Variants: `primary`, `secondary`, `ghost`, `danger`.
   - Built-in press-down micro-interaction (`Transform.scale`).
   - Non-shifting loading spinner that preserves button dimensions.
   - Guaranteed minimum 48dp touch target.

2. **`UstaadCard`**:
   - Warm surface with 1px border (`#E7E6DF`) and soft emerald shadow.
   - Interactive mode with spring press animation.
   - Optional left accent highlight bar for "Best Match" / top-tier recommendations.

3. **`UstaadInput`**:
   - Floating label with clear visual focus state.
   - Full RTL and Pakistani script awareness.
   - Integrated error message display with alert icon.

4. **`UstaadChip`**:
   - Filter and recommendation pills with active/inactive states.
   - Icon support and optional count badge.
   - Padded hit target ensuring accessible tapping.

5. **`UstaadBadge`**:
   - Verified CNIC checkmark badge (`UstaadBadge.verified()`).
   - Top Rated star badge (`UstaadBadge.topRated()`).
   - Background Checked badge (`UstaadBadge.backgroundChecked()`).

6. **`UstaadAvatar`**:
   - Sizes: `sm` (32dp), `md` (44dp), `lg` (56dp), `xl` (72dp).
   - Online dot indicator with emerald ring.
   - Verified ring support and initials fallback.

7. **`UstaadDivider`**:
   - Warm neutral divider with optional centered label.

---

## 4. Verification & Testing
- Unit contrast tests: `flutter test test/theme_test.dart`
- Design system interactive gallery: `lib/src/screens/design_system_gallery_screen.dart`
