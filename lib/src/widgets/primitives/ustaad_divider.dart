import 'package:flutter/material.dart';
import '../../theme/ustaad_theme.dart';

/// Industrial-Grade Divider Primitive using warm neutral tokens.
class UstaadDivider extends StatelessWidget {
  const UstaadDivider({
    super.key,
    this.label,
    this.height = 1.0,
    this.color,
    this.margin = UstaadSpacing.insetsVMd,
  });

  final String? label;
  final double height;
  final Color? color;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = color ?? (isDark ? UstaadColors.darkBorder : UstaadColors.border);

    if (label == null) {
      return Padding(
        padding: margin,
        child: Divider(
          height: height,
          thickness: height,
          color: lineColor,
        ),
      );
    }

    return Padding(
      padding: margin,
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: height,
              thickness: height,
              color: lineColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!,
              style: UstaadTypography.labelSmall(
                color: isDark ? UstaadColors.darkTextMuted : UstaadColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              height: height,
              thickness: height,
              color: lineColor,
            ),
          ),
        ],
      ),
    );
  }
}
