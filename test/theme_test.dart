import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ustaad_flutter/src/theme/ustaad_theme.dart';

/// Computes the relative luminance of a color according to WCAG 2.1 specs.
double calculateRelativeLuminance(Color color) {
  double channelLuminance(double channel) {
    if (channel <= 0.04045) {
      return channel / 12.92;
    } else {
      return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  final r = channelLuminance(color.r);
  final g = channelLuminance(color.g);
  final b = channelLuminance(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calculates the WCAG contrast ratio between two colors: (L1 + 0.05) / (L2 + 0.05).
double calculateContrastRatio(Color foreground, Color background) {
  final l1 = calculateRelativeLuminance(foreground);
  final l2 = calculateRelativeLuminance(background);

  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);

  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Modern Desi Professional Theme Tokens: WCAG AA Contrast Verification', () {
    test('UstaadColors.textPrimary on warm background meets WCAG AA (>= 4.5:1)', () {
      final ratio = calculateContrastRatio(
        UstaadColors.textPrimary,
        UstaadColors.background,
      );
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'Text primary contrast ratio ($ratio) must exceed 4.5:1',
      );
      expect(ratio, greaterThan(14.0)); // Highly legible charcoal on warm cream
    });

    test('UstaadColors.textPrimary on surface card meets WCAG AA (>= 4.5:1)', () {
      final ratio = calculateContrastRatio(
        UstaadColors.textPrimary,
        UstaadColors.surface,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('UstaadColors.textSecondary on warm background meets WCAG AA (>= 4.5:1)', () {
      final ratio = calculateContrastRatio(
        UstaadColors.textSecondary,
        UstaadColors.background,
      );
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'Text secondary contrast ratio ($ratio) must be >= 4.5:1',
      );
    });

    test('UstaadColors.textOnPrimary on primary emerald meets WCAG AA (>= 4.5:1)', () {
      final ratio = calculateContrastRatio(
        UstaadColors.textOnPrimary,
        UstaadColors.primary,
      );
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'White on Emerald contrast ($ratio) must exceed 4.5:1',
      );
    });

    test('UstaadColors.textOnPrimary on primaryDark meets WCAG AAA (>= 7.0:1)', () {
      final ratio = calculateContrastRatio(
        UstaadColors.textOnPrimary,
        UstaadColors.primaryDark,
      );
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('Dark mode: darkTextPrimary on darkBackground meets WCAG AA (>= 4.5:1)', () {
      final ratio = calculateContrastRatio(
        UstaadColors.darkTextPrimary,
        UstaadColors.darkBackground,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Dark mode: darkTextSecondary on darkBackground meets WCAG AA (>= 4.5:1)', () {
      final ratio = calculateContrastRatio(
        UstaadColors.darkTextSecondary,
        UstaadColors.darkBackground,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('UstaadSpacing Scale Specification Verification', () {
    test('strictly adheres to 4/8/12/16/24/32/48 scale', () {
      expect(UstaadSpacing.xxs, equals(4.0));
      expect(UstaadSpacing.xs, equals(8.0));
      expect(UstaadSpacing.sm, equals(12.0));
      expect(UstaadSpacing.md, equals(16.0));
      expect(UstaadSpacing.lg, equals(24.0));
      expect(UstaadSpacing.xl, equals(32.0));
      expect(UstaadSpacing.xxl, equals(48.0));
    });
  });

  group('UstaadRadius Scale Specification Verification', () {
    test('strictly adheres to 12/16/24/pill scale', () {
      expect(UstaadRadius.sm, equals(12.0));
      expect(UstaadRadius.md, equals(16.0));
      expect(UstaadRadius.lg, equals(24.0));
      expect(UstaadRadius.pill, equals(999.0));
    });
  });

  group('UstaadTypography Specification Verification', () {
    test('headings specify 1.2 line height and proper weights', () {
      final h1 = UstaadTypography.h1();
      expect(h1.fontSize, equals(32));
      expect(h1.fontWeight, equals(FontWeight.w700));
      expect(h1.height, equals(1.2));

      final h2 = UstaadTypography.h2();
      expect(h2.fontSize, equals(24));
      expect(h2.fontWeight, equals(FontWeight.w700));
      expect(h2.height, equals(1.2));
    });

    test('body styles specify 1.5 line height', () {
      final body = UstaadTypography.bodyLarge();
      expect(body.fontSize, equals(16));
      expect(body.height, equals(1.5));

      final bodyM = UstaadTypography.bodyMedium();
      expect(bodyM.fontSize, equals(14));
      expect(bodyM.height, equals(1.5));
    });

    test('Urdu Nastaliq typography specifies 1.8 line height for proper ascenders/descenders', () {
      final urduH = UstaadTypography.urduHeading();
      expect(urduH.height, equals(1.8));

      final urduB = UstaadTypography.urduBody();
      expect(urduB.height, equals(1.8));
    });
  });
}
