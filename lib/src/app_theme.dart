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

class UstaadTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: ustaadPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: ustaadPrimary,
      onPrimary: ustaadFieldFill,
      primaryContainer: const Color(0xFF2A3A14),
      onPrimaryContainer: ustaadPrimary,
      secondary: ustaadSecondary,
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF3B2414),
      onSecondaryContainer: ustaadSecondary,
      surface: const Color(0xFF181818),
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
      background: const Color(0xFF151515),
      card: const Color(0xFF202020),
      divider: const Color(0xFF343434),
      fieldFill: const Color(0xFF151515),
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
      brightness: Brightness.dark,
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
        labelStyle: const TextStyle(
          color: ustaadMuted,
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: const TextStyle(
          color: ustaadPrimary,
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
