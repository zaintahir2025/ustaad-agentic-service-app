import 'package:flutter/material.dart';

const Color ustaadPrimary = Color(0xFFBEFF3D);
const Color ustaadSecondary = Color(0xFFFF8B2E);
const Color ustaadBackground = Color(0xFF101010);
const Color ustaadSurface = Color(0xFF1D1D1D);
const Color ustaadFieldFill = Color(0xFF111111);
const Color ustaadBorder = Color(0xFF303030);
const Color ustaadMuted = Color(0xFF8D8F94);
const Color ustaadText = Color(0xFFF7F7F7);
const Color ustaadError = Color(0xFFFF8A80);
const Color ustaadLightPrimary = Color(0xFF6D9700);
const Color ustaadLightBackground = Color(0xFFF7F8F0);
const Color ustaadLightSurface = Color(0xFFFFFFFF);
const Color ustaadLightFieldFill = Color(0xFFFFFFFF);
const Color ustaadLightBorder = Color(0xFFD7DDCB);
const Color ustaadLightMuted = Color(0xFF62685B);
const Color ustaadLightText = Color(0xFF101010);
const Color ustaadEmergency = Color(0xFFE53935);
const Color ustaadEmergencyLight = Color(0xFFFFCDD2);
const Color ustaadGold = Color(0xFFFFD700);
const Color ustaadGoldDark = Color(0xFFFF8F00);
const Color ustaadSuccess = Color(0xFF43A047);

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
        colors: [ustaadEmergency, Color(0xFFB71C1C)],
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ustaadEmergencyLight.withValues(alpha: 0.7)),
      boxShadow: [
        BoxShadow(
          color: ustaadEmergency.withValues(alpha: 0.24),
          blurRadius: 18,
          offset: const Offset(0, 8),
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
          colors: [Color(0xFFFFF4B8), ustaadGold, ustaadGoldDark],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ustaadGold, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: ustaadGold.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );
    }

    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF343434), Color(0xFF202020)],
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF575757)),
    );
  }

  static BoxDecoration get mapLegendDecoration {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: ustaadLightPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: ustaadLightPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE9F7C8),
      onPrimaryContainer: const Color(0xFF253500),
      secondary: ustaadSecondary,
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFFFFE2CC),
      onSecondaryContainer: const Color(0xFF3C1B00),
      surface: ustaadLightSurface,
      onSurface: ustaadLightText,
      onSurfaceVariant: ustaadLightMuted,
      surfaceContainerHighest: const Color(0xFFEFF3E6),
      outline: const Color(0xFF818875),
      outlineVariant: ustaadLightBorder,
      error: const Color(0xFFB3261E),
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
      onPrimary: ustaadFieldFill,
      primaryContainer: const Color(0xFF263611),
      onPrimaryContainer: ustaadPrimary,
      secondary: ustaadSecondary,
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF351D0F),
      onSecondaryContainer: ustaadSecondary,
      surface: ustaadSurface,
      onSurface: ustaadText,
      onSurfaceVariant: ustaadMuted,
      surfaceContainerHighest: const Color(0xFF242424),
      outline: const Color(0xFF505050),
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
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: divider,
      canvasColor: background,
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.34),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.72),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.42)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fieldFill,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        disabledColor: fieldFill.withValues(alpha: 0.5),
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.primary),
        iconTheme: IconThemeData(color: scheme.primary, size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: divider),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 64,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
