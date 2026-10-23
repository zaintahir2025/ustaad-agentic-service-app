import 'package:flutter/material.dart';

// Professional, Trusted Emerald & Amber Palette
const Color ustaadPrimary = Color(0xFF10B981); // Modern Emerald Mint
const Color ustaadSecondary = Color(0xFFF59E0B); // Warm Amber
const Color ustaadBackground = Color(0xFF0F172A); // Deep Night Slate
const Color ustaadSurface = Color(0xFF1E293B); // Elevated Slate Card
const Color ustaadFieldFill = Color(0xFF0B1120); // Darker Field Fill
const Color ustaadBorder = Color(0xFF334155); // Subtle Slate Outline
const Color ustaadMuted = Color(0xFF94A3B8); // Cool Slate Muted Text
const Color ustaadText = Color(0xFFF8FAFC); // High Contrast Pure White
const Color ustaadError = Color(0xFFF87171); // Soft Red Error

// Light Theme System
const Color ustaadLightPrimary = Color(0xFF0D9488); // Deep Emerald Teal
const Color ustaadLightBackground = Color(0xFFF8FAFC); // Soft Crisp White
const Color ustaadLightSurface = Color(0xFFFFFFFF); // Pure White Card
const Color ustaadLightFieldFill = Color(0xFFF1F5F9); // Soft Gray Field Fill
const Color ustaadLightBorder = Color(0xFFE2E8F0); // Light Slate Border
const Color ustaadLightMuted = Color(0xFF64748B); // Slate Muted Text
const Color ustaadLightText = Color(0xFF0F172A); // Deep Slate Text

// Accents
const Color ustaadEmergency = Color(0xFFDC2626);
const Color ustaadEmergencyLight = Color(0xFFFEE2E2);
const Color ustaadGold = Color(0xFFF59E0B);
const Color ustaadGoldDark = Color(0xFFD97706);
const Color ustaadSuccess = Color(0xFF10B981);

const TextStyle ustaadBadgeTitle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.3,
);

const TextStyle ustaadEmergencyLabel = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w900,
  color: Colors.white,
  letterSpacing: 1.2,
);

class UstaadTheme {
  static BoxDecoration get emergencyBannerDecoration {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [ustaadEmergency, Color(0xFF991B1B)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ustaadEmergencyLight.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: ustaadEmergency.withValues(alpha: 0.22),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration achievementCardDecoration(bool unlocked) {
    if (unlocked) {
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEF3C7), ustaadGold, ustaadGoldDark],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ustaadGold, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: ustaadGold.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );
    }

    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF334155)),
    );
  }

  static BoxDecoration get mapLegendDecoration {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: ustaadLightPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: ustaadLightPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFCCFBF1),
      onPrimaryContainer: const Color(0xFF115E59),
      secondary: ustaadSecondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFEF3C7),
      onSecondaryContainer: const Color(0xFF92400E),
      surface: ustaadLightSurface,
      onSurface: ustaadLightText,
      onSurfaceVariant: ustaadLightMuted,
      surfaceContainerHighest: const Color(0xFFF1F5F9),
      outline: const Color(0xFF94A3B8),
      outlineVariant: ustaadLightBorder,
      error: ustaadEmergency,
      onError: Colors.white,
    );

    return _base(
      scheme,
      background: ustaadLightBackground,
      card: ustaadLightSurface,
      divider: ustaadLightBorder,
      fieldFill: ustaadLightFieldFill,
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: ustaadPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: ustaadPrimary,
      onPrimary: const Color(0xFF064E3B),
      primaryContainer: const Color(0xFF064E3B),
      onPrimaryContainer: const Color(0xFF6EE7B7),
      secondary: ustaadSecondary,
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF451A03),
      onSecondaryContainer: const Color(0xFFFDE68A),
      surface: ustaadSurface,
      onSurface: ustaadText,
      onSurfaceVariant: ustaadMuted,
      surfaceContainerHighest: const Color(0xFF283548),
      outline: const Color(0xFF475569),
      outlineVariant: ustaadBorder,
      error: ustaadError,
      onError: Colors.black,
    );

    return _base(
      scheme,
      background: ustaadBackground,
      card: ustaadSurface,
      divider: ustaadBorder,
      fieldFill: ustaadFieldFill,
    );
  }

  static ThemeData _base(
    ColorScheme scheme, {
    required Color background,
    required Color card,
    required Color divider,
    required Color fieldFill,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      fontFamily: 'Roboto',
      fontFamilyFallback: const [
        'Noto Nastaliq Urdu',
        'Urdu Typesetting',
        'Arial',
      ],
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: divider,
      canvasColor: background,
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: scheme.primary.withValues(alpha: 0.35),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 1,
          shadowColor: scheme.primary.withValues(alpha: 0.25),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 48),
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.3),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.5), width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(48, 48),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fieldFill,
        selectedColor: scheme.primary.withValues(alpha: 0.16),
        disabledColor: fieldFill.withValues(alpha: 0.5),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondaryLabelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        iconTheme: IconThemeData(color: scheme.primary, size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: divider),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: card,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w900
                : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: divider),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
