import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern Desi Professional Design System: Colors
///
/// Palette rooted in authentic Pakistani aesthetic:
/// - Rich Emerald greens (#0F6E56, #14876A) evoking trust and prosperity
/// - Warm Amber (#F5A623) representing craftsmanship, energy, and ratings
/// - Warm neutrals (#FAFAF7 cream background, #1A1A1A charcoal text)
/// - Explicitly avoids sterile, cold corporate blue-greys.
class UstaadColors {
  const UstaadColors._();

  // --- Primary Emeralds ---
  static const Color primary = Color(0xFF0F6E56);
  static const Color primaryDark = Color(0xFF0A4C3B);
  static const Color primaryLight = Color(0xFF14876A);
  static const Color primaryContainer = Color(0xFFE8F5F1);
  static const Color primaryContainerDark = Color(0xFF123B30);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F6E56),
      Color(0xFF0A4C3B),
    ],
  );

  // --- Accent Ambers ---
  static const Color accent = Color(0xFFF5A623);
  static const Color accentDark = Color(0xFFD98207);
  static const Color accentLight = Color(0xFFFDBF5E);
  static const Color accentContainer = Color(0xFFFEF5E7);

  // --- Warm Neutrals (Light Mode) ---
  static const Color background = Color(0xFFFAFAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF5F5EE);
  static const Color border = Color(0xFFE7E6DF);
  static const Color borderStrong = Color(0xFFD3D1C7);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5A5954);
  static const Color textMuted = Color(0xFF75736B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Warm Neutrals (Dark Mode) ---
  static const Color darkBackground = Color(0xFF141513);
  static const Color darkSurface = Color(0xFF1E201D);
  static const Color darkSurfaceElevated = Color(0xFF282B26);
  static const Color darkBorder = Color(0xFF32362F);
  static const Color darkBorderStrong = Color(0xFF484C43);
  static const Color darkTextPrimary = Color(0xFFF8F8F5);
  static const Color darkTextSecondary = Color(0xFFB5B4AC);
  static const Color darkTextMuted = Color(0xFF88877F);

  // --- Semantics ---
  static const Color success = Color(0xFF0F6E56);
  static const Color successContainer = Color(0xFFE6F4EA);
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFD9383A);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoContainer = Color(0xFFE0F2FE);

  // --- Verified & Trust Badges ---
  static const Color verifiedBlue = Color(0xFF2563EB);
  static const Color verifiedBlueContainer = Color(0xFFEFF6FF);
}

/// Modern Desi Professional Design System: Spacing Scale
///
/// Geometric spacing on 4 / 8 / 12 / 16 / 24 / 32 / 48 pt scale.
class UstaadSpacing {
  const UstaadSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Insets Helpers
  static const EdgeInsets insetsAllXxs = EdgeInsets.all(xxs);
  static const EdgeInsets insetsAllXs = EdgeInsets.all(xs);
  static const EdgeInsets insetsAllSm = EdgeInsets.all(sm);
  static const EdgeInsets insetsAllMd = EdgeInsets.all(md);
  static const EdgeInsets insetsAllLg = EdgeInsets.all(lg);
  static const EdgeInsets insetsAllXl = EdgeInsets.all(xl);

  static const EdgeInsets insetsHXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets insetsHSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets insetsHMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets insetsHLg = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets insetsVXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets insetsVSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets insetsVMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets insetsVLg = EdgeInsets.symmetric(vertical: lg);

  static const EdgeInsetsDirectional insetsDirectionalMd =
      EdgeInsetsDirectional.all(md);
  static const EdgeInsetsDirectional insetsDirectionalLg =
      EdgeInsetsDirectional.all(lg);
}

/// Modern Desi Professional Design System: Border Radius Scale
///
/// 12 / 16 / 24 / pill scale.
class UstaadRadius {
  const UstaadRadius._();

  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double pill = 999.0;

  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusPill = Radius.circular(pill);

  static final BorderRadius borderSm = BorderRadius.circular(sm);
  static final BorderRadius borderMd = BorderRadius.circular(md);
  static final BorderRadius borderLg = BorderRadius.circular(lg);
  static final BorderRadius borderPill = BorderRadius.circular(pill);
}

/// Modern Desi Professional Design System: Subtle Elevation Shadows
///
/// Uses tinted emerald shadows (rgba(15,110,86, 0.08)) for premium soft depth.
/// Completely avoids harsh default Material drop-shadows.
class UstaadShadows {
  const UstaadShadows._();

  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x140F6E56), // ~8% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x140F6E56),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
    BoxShadow(
      color: Color(0x0A1A1A1A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x1F0F6E56), // ~12% opacity
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> popover = [
    BoxShadow(
      color: Color(0x290F6E56), // ~16% opacity
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> glowEmerald = [
    BoxShadow(
      color: Color(0x330F6E56),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}

/// Modern Desi Professional Design System: Typography
///
/// - Headings: GoogleFonts.plusJakartaSans (weights 600/700, line-height 1.2)
/// - Body: GoogleFonts.inter (weights 400/500, line-height 1.5)
/// - Urdu: GoogleFonts.notoNastaliqUrdu (weights 400/700, line-height 1.8 for Nastaliq breathing room)
class UstaadTypography {
  const UstaadTypography._();

  // --- English / Latin Typography ---

  static TextStyle h1({Color color = UstaadColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle h2({Color color = UstaadColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle h3({Color color = UstaadColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle h4({Color color = UstaadColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  static TextStyle bodyLarge({Color color = UstaadColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMedium({Color color = UstaadColors.textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle bodySmall({Color color = UstaadColors.textMuted}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle labelLarge({Color color = UstaadColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle labelMedium({Color color = UstaadColors.textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle labelSmall({Color color = UstaadColors.textMuted}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.3,
        color: color,
      );

  // --- Pakistani Urdu Typography (Nastaliq line-height: 1.8) ---

  static TextStyle urduHeading({Color color = UstaadColors.textPrimary}) =>
      GoogleFonts.notoNastaliqUrdu(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.8,
        color: color,
      );

  static TextStyle urduBody({Color color = UstaadColors.textSecondary}) =>
      GoogleFonts.notoNastaliqUrdu(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.8,
        color: color,
      );

  static TextStyle urduSubtext({Color color = UstaadColors.textMuted}) =>
      GoogleFonts.notoNastaliqUrdu(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.8,
        color: color,
      );
}

/// Unified Theme Provider configuring Material 3 with Ustaad design tokens.
class UstaadThemeData {
  const UstaadThemeData._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: UstaadColors.primary,
      scaffoldBackgroundColor: UstaadColors.background,
      colorScheme: const ColorScheme.light(
        primary: UstaadColors.primary,
        onPrimary: UstaadColors.textOnPrimary,
        primaryContainer: UstaadColors.primaryContainer,
        secondary: UstaadColors.accent,
        onSecondary: Colors.white,
        secondaryContainer: UstaadColors.accentContainer,
        surface: UstaadColors.surface,
        onSurface: UstaadColors.textPrimary,
        error: UstaadColors.error,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: UstaadColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: UstaadRadius.borderMd,
          side: const BorderSide(color: UstaadColors.border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: UstaadColors.surface,
        foregroundColor: UstaadColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: UstaadTypography.h3(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UstaadColors.primary,
          foregroundColor: UstaadColors.textOnPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: UstaadRadius.borderSm,
          ),
          textStyle: UstaadTypography.labelLarge(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UstaadColors.primary,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: UstaadColors.borderStrong, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: UstaadRadius.borderSm,
          ),
          textStyle: UstaadTypography.labelLarge(color: UstaadColors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: UstaadColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: UstaadRadius.borderSm,
          borderSide: const BorderSide(color: UstaadColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: UstaadRadius.borderSm,
          borderSide: const BorderSide(color: UstaadColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: UstaadRadius.borderSm,
          borderSide: const BorderSide(color: UstaadColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: UstaadRadius.borderSm,
          borderSide: const BorderSide(color: UstaadColors.error, width: 1.2),
        ),
        labelStyle: UstaadTypography.bodyMedium(color: UstaadColors.textSecondary),
        hintStyle: UstaadTypography.bodyMedium(color: UstaadColors.textMuted),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: UstaadColors.primary,
      scaffoldBackgroundColor: UstaadColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: UstaadColors.primaryLight,
        onPrimary: UstaadColors.textOnPrimary,
        primaryContainer: UstaadColors.primaryContainerDark,
        secondary: UstaadColors.accent,
        onSecondary: Colors.black,
        secondaryContainer: UstaadColors.accentDark,
        surface: UstaadColors.darkSurface,
        onSurface: UstaadColors.darkTextPrimary,
        error: UstaadColors.error,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: UstaadColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: UstaadRadius.borderMd,
          side: const BorderSide(color: UstaadColors.darkBorder, width: 1),
        ),
      ),
    );
  }
}
