import 'package:flutter/material.dart';
import '../../theme/ustaad_theme.dart';

/// Industrial-Grade Chip Primitive with active/inactive states,
/// pill border radius, and accessible tap padding.
class UstaadChip extends StatelessWidget {
  const UstaadChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.trailing,
    this.count,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? icon;
  final Widget? trailing;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isSelected) {
      bgColor = isDark ? UstaadColors.primaryContainerDark : UstaadColors.primaryContainer;
      borderColor = isDark ? UstaadColors.primaryLight : UstaadColors.primary;
      textColor = isDark ? UstaadColors.primaryLight : UstaadColors.primary;
    } else {
      bgColor = isDark ? UstaadColors.darkSurface : UstaadColors.surface;
      borderColor = isDark ? UstaadColors.darkBorder : UstaadColors.border;
      textColor = isDark ? UstaadColors.darkTextSecondary : UstaadColors.textSecondary;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: UstaadRadius.borderPill,
          splashColor: UstaadColors.primary.withValues(alpha: 0.1),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48), // WCAG tap target
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: UstaadRadius.borderPill,
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected ? UstaadShadows.subtle : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: UstaadTypography.labelMedium(color: textColor).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? UstaadColors.primary : UstaadColors.primaryLight)
                          : (isDark ? UstaadColors.darkBorder : UstaadColors.border),
                      borderRadius: UstaadRadius.borderPill,
                    ),
                    child: Text(
                      count.toString(),
                      style: UstaadTypography.labelSmall(
                        color: isSelected ? Colors.white : textColor,
                      ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
