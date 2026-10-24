import 'package:flutter/material.dart';
import '../../theme/ustaad_theme.dart';

enum UstaadBadgeVariant {
  verified,
  topRated,
  success,
  warning,
  error,
  neutral,
}

/// Industrial-Grade Badge Primitive for trust signals, provider verification,
/// ratings, and operational status.
class UstaadBadge extends StatelessWidget {
  const UstaadBadge({
    super.key,
    required this.label,
    this.variant = UstaadBadgeVariant.neutral,
    this.icon,
    this.onTap,
  });

  final String label;
  final UstaadBadgeVariant variant;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Factory helper for CNIC / Nadra verified badges.
  factory UstaadBadge.verified({String label = 'CNIC Verified'}) {
    return UstaadBadge(
      label: label,
      variant: UstaadBadgeVariant.verified,
      icon: Icons.verified_rounded,
    );
  }

  /// Factory helper for Top Rated provider badges.
  factory UstaadBadge.topRated({String label = 'Top Rated'}) {
    return UstaadBadge(
      label: label,
      variant: UstaadBadgeVariant.topRated,
      icon: Icons.star_rounded,
    );
  }

  /// Factory helper for Background Checked badges.
  factory UstaadBadge.backgroundChecked({String label = 'Background Checked'}) {
    return UstaadBadge(
      label: label,
      variant: UstaadBadgeVariant.success,
      icon: Icons.shield_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color fg;
    IconData? defaultIcon;

    switch (variant) {
      case UstaadBadgeVariant.verified:
        bg = UstaadColors.verifiedBlueContainer;
        border = UstaadColors.verifiedBlue.withValues(alpha: 0.3);
        fg = UstaadColors.verifiedBlue;
        defaultIcon = Icons.verified_rounded;
      case UstaadBadgeVariant.topRated:
        bg = UstaadColors.accentContainer;
        border = UstaadColors.accentDark.withValues(alpha: 0.3);
        fg = UstaadColors.accentDark;
        defaultIcon = Icons.star_rounded;
      case UstaadBadgeVariant.success:
        bg = UstaadColors.successContainer;
        border = UstaadColors.success.withValues(alpha: 0.3);
        fg = UstaadColors.success;
        defaultIcon = Icons.check_circle_rounded;
      case UstaadBadgeVariant.warning:
        bg = UstaadColors.warningContainer;
        border = UstaadColors.warning.withValues(alpha: 0.3);
        fg = UstaadColors.warning;
        defaultIcon = Icons.warning_amber_rounded;
      case UstaadBadgeVariant.error:
        bg = UstaadColors.errorContainer;
        border = UstaadColors.error.withValues(alpha: 0.3);
        fg = UstaadColors.error;
        defaultIcon = Icons.error_outline_rounded;
      case UstaadBadgeVariant.neutral:
        bg = UstaadColors.surfaceElevated;
        border = UstaadColors.border;
        fg = UstaadColors.textSecondary;
    }

    final effectiveIcon = icon ?? defaultIcon;

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: UstaadRadius.borderPill,
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (effectiveIcon != null) ...[
            Icon(effectiveIcon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: UstaadTypography.labelSmall(color: fg).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }
    return badge;
  }
}
