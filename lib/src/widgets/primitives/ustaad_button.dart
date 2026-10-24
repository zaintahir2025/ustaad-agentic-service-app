import 'package:flutter/material.dart';
import '../../theme/ustaad_theme.dart';

enum UstaadButtonVariant {
  primary,
  secondary,
  ghost,
  danger,
}

enum UstaadButtonSize {
  sm,
  md,
  lg,
}

/// Industrial-Grade Button Primitive conforming to Modern Desi Professional design tokens.
///
/// Features:
/// - Guaranteed minimum 48dp tap target across all screen densities.
/// - Primary (Emerald Gradient), Secondary (Bordered), Ghost, and Danger variants.
/// - Seamless loading state without layout shift.
/// - Subtle press-scale micro-interaction.
class UstaadButton extends StatefulWidget {
  const UstaadButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = UstaadButtonVariant.primary,
    this.size = UstaadButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final UstaadButtonVariant variant;
  final UstaadButtonSize size;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool fullWidth;

  @override
  State<UstaadButton> createState() => _UstaadButtonState();
}

class _UstaadButtonState extends State<UstaadButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  double get _height {
    return switch (widget.size) {
      UstaadButtonSize.sm => 48.0, // Minimum 48dp enforced for accessibility
      UstaadButtonSize.md => 52.0,
      UstaadButtonSize.lg => 58.0,
    };
  }

  EdgeInsets get _padding {
    return switch (widget.size) {
      UstaadButtonSize.sm => const EdgeInsets.symmetric(horizontal: 16),
      UstaadButtonSize.md => const EdgeInsets.symmetric(horizontal: 20),
      UstaadButtonSize.lg => const EdgeInsets.symmetric(horizontal: 24),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve Colors & Background
    BoxDecoration decoration;
    Color textColor;
    Color spinnerColor;

    switch (widget.variant) {
      case UstaadButtonVariant.primary:
        textColor = UstaadColors.textOnPrimary;
        spinnerColor = Colors.white;
        decoration = BoxDecoration(
          gradient: _isEnabled ? UstaadColors.primaryGradient : null,
          color: _isEnabled ? null : (isDark ? UstaadColors.darkBorder : UstaadColors.border),
          borderRadius: UstaadRadius.borderSm,
          boxShadow: _isEnabled && !_isPressed ? UstaadShadows.subtle : null,
        );
      case UstaadButtonVariant.secondary:
        textColor = _isEnabled ? UstaadColors.primary : UstaadColors.textMuted;
        spinnerColor = UstaadColors.primary;
        decoration = BoxDecoration(
          color: isDark ? UstaadColors.darkSurface : UstaadColors.surface,
          borderRadius: UstaadRadius.borderSm,
          border: Border.all(
            color: _isEnabled
                ? (isDark ? UstaadColors.primaryLight : UstaadColors.primary)
                : (isDark ? UstaadColors.darkBorder : UstaadColors.border),
            width: 1.4,
          ),
          boxShadow: _isEnabled && !_isPressed ? UstaadShadows.subtle : null,
        );
      case UstaadButtonVariant.ghost:
        textColor = _isEnabled
            ? (isDark ? UstaadColors.darkTextPrimary : UstaadColors.textPrimary)
            : UstaadColors.textMuted;
        spinnerColor = textColor;
        decoration = BoxDecoration(
          color: _isPressed
              ? (isDark
                  ? UstaadColors.primaryContainerDark.withValues(alpha: 0.3)
                  : UstaadColors.primaryContainer.withValues(alpha: 0.4))
              : Colors.transparent,
          borderRadius: UstaadRadius.borderSm,
        );
      case UstaadButtonVariant.danger:
        textColor = Colors.white;
        spinnerColor = Colors.white;
        decoration = BoxDecoration(
          color: _isEnabled
              ? UstaadColors.error
              : (isDark ? UstaadColors.darkBorder : UstaadColors.border),
          borderRadius: UstaadRadius.borderSm,
        );
    }

    Widget content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          ),
          const SizedBox(width: UstaadSpacing.xs),
        ] else if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: UstaadSpacing.xs),
        ],
        Text(
          widget.label,
          style: UstaadTypography.labelLarge(color: textColor).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!widget.isLoading && widget.trailingIcon != null) ...[
          const SizedBox(width: UstaadSpacing.xs),
          widget.trailingIcon!,
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.label,
      child: AnimatedScale(
        scale: _isPressed && _isEnabled ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isEnabled ? widget.onPressed : null,
            onHighlightChanged: (pressed) {
              if (_isEnabled && mounted) {
                setState(() => _isPressed = pressed);
              }
            },
            borderRadius: UstaadRadius.borderSm,
            splashColor: UstaadColors.primary.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: _height,
              padding: _padding,
              constraints: BoxConstraints(
                minHeight: 48,
                minWidth: widget.fullWidth ? double.infinity : 48,
              ),
              decoration: decoration,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
