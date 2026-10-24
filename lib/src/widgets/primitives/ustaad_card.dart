import 'package:flutter/material.dart';
import '../../theme/ustaad_theme.dart';

/// Industrial-Grade Card Primitive with subtle border, soft tinted shadow,
/// and smooth press-scale micro-interaction.
class UstaadCard extends StatefulWidget {
  const UstaadCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = UstaadSpacing.insetsAllMd,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shadows,
    this.leftAccentColor,
    this.leftAccentWidth = 4.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final Color? leftAccentColor;
  final double leftAccentWidth;

  @override
  State<UstaadCard> createState() => _UstaadCardState();
}

class _UstaadCardState extends State<UstaadCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = widget.borderRadius ?? UstaadRadius.borderMd;
    final cardColor = widget.color ??
        (isDark ? UstaadColors.darkSurface : UstaadColors.surface);
    final outlineColor = widget.borderColor ??
        (isDark ? UstaadColors.darkBorder : UstaadColors.border);

    Widget inner = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: radius,
        border: Border.all(
          color: outlineColor,
          width: widget.borderWidth,
        ),
        boxShadow: widget.shadows ?? UstaadShadows.card,
      ),
      child: widget.child,
    );

    if (widget.leftAccentColor != null) {
      inner = ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            inner,
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: widget.leftAccentWidth,
              child: Container(color: widget.leftAccentColor),
            ),
          ],
        ),
      );
    }

    if (widget.onTap == null) {
      return inner;
    }

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) {
            if (mounted) setState(() => _isPressed = pressed);
          },
          borderRadius: radius,
          splashColor: UstaadColors.primary.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: inner,
        ),
      ),
    );
  }
}
