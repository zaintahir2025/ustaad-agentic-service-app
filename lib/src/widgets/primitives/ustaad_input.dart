import 'package:flutter/material.dart';
import '../../theme/ustaad_theme.dart';

/// Industrial-Grade Text Field Primitive conforming to Modern Desi Professional design tokens.
///
/// Features:
/// - RTL-aware alignment and padding (English and Urdu/Arabic support).
/// - Floating label support and clear inline error state.
/// - Minimum 48dp accessible touch target.
/// - Emerald focus ring and clear/action trailing slot.
class UstaadInput extends StatefulWidget {
  const UstaadInput({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.autofocus = false,
    this.textDirection,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool autofocus;
  final TextDirection? textDirection;

  @override
  State<UstaadInput> createState() => _UstaadInputState();
}

class _UstaadInputState extends State<UstaadInput> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final baseFill = isDark ? UstaadColors.darkSurface : UstaadColors.surface;
    final borderColor = hasError
        ? UstaadColors.error
        : (_isFocused
            ? UstaadColors.primary
            : (isDark ? UstaadColors.darkBorder : UstaadColors.border));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 2, bottom: 6),
            child: Text(
              widget.label!,
              style: UstaadTypography.labelMedium(
                color: hasError
                    ? UstaadColors.error
                    : (_isFocused
                        ? UstaadColors.primary
                        : (isDark
                            ? UstaadColors.darkTextSecondary
                            : UstaadColors.textSecondary)),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: baseFill,
            borderRadius: UstaadRadius.borderSm,
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.8 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: hasError
                          ? UstaadColors.error.withValues(alpha: 0.12)
                          : UstaadColors.primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textDirection: widget.textDirection,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            style: UstaadTypography.bodyLarge(
              color: isDark
                  ? UstaadColors.darkTextPrimary
                  : UstaadColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              hintStyle: UstaadTypography.bodyMedium(
                color: isDark
                    ? UstaadColors.darkTextMuted
                    : UstaadColors.textMuted,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 14,
                        end: 10,
                      ),
                      child: widget.prefixIcon,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 48,
              ),
              suffixIcon: widget.suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 10,
                        end: 14,
                      ),
                      child: widget.suffixIcon,
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 48,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
        if (hasError) ...[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, top: 5),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: UstaadColors.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: UstaadTypography.labelSmall(
                      color: UstaadColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (widget.helperText != null) ...[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, top: 4),
            child: Text(
              widget.helperText!,
              style: UstaadTypography.labelSmall(
                color: isDark
                    ? UstaadColors.darkTextMuted
                    : UstaadColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
