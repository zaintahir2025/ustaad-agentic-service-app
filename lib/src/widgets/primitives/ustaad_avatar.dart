import 'package:flutter/material.dart';
import '../../theme/ustaad_theme.dart';

enum UstaadAvatarSize {
  sm,
  md,
  lg,
  xl,
}

/// Industrial-Grade Avatar Primitive supporting image loading, graceful initials fallback,
/// online status indicator dot, and verified ring.
class UstaadAvatar extends StatelessWidget {
  const UstaadAvatar({
    super.key,
    this.imageUrl,
    this.name = 'Ustaad',
    this.size = UstaadAvatarSize.md,
    this.isOnline = false,
    this.showOnlineBadge = false,
    this.isVerified = false,
  });

  final String? imageUrl;
  final String name;
  final UstaadAvatarSize size;
  final bool isOnline;
  final bool showOnlineBadge;
  final bool isVerified;

  double get _dimension {
    return switch (size) {
      UstaadAvatarSize.sm => 32.0,
      UstaadAvatarSize.md => 48.0,
      UstaadAvatarSize.lg => 56.0,
      UstaadAvatarSize.xl => 72.0,
    };
  }

  double get _fontSize {
    return switch (size) {
      UstaadAvatarSize.sm => 12.0,
      UstaadAvatarSize.md => 16.0,
      UstaadAvatarSize.lg => 20.0,
      UstaadAvatarSize.xl => 26.0,
    };
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dim = _dimension;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatarImage;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatarImage = Image.network(
        imageUrl!,
        width: dim,
        height: dim,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(isDark),
      );
    } else {
      avatarImage = _buildFallback(isDark);
    }

    Widget core = Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isVerified
            ? Border.all(
                color: UstaadColors.primary,
                width: 2.0,
              )
            : Border.all(
                color: isDark ? UstaadColors.darkBorder : UstaadColors.border,
                width: 1.0,
              ),
      ),
      child: ClipOval(child: avatarImage),
    );

    if (!showOnlineBadge) {
      return core;
    }

    final badgeSize = dim * 0.28;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        core,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: isOnline ? UstaadColors.success : UstaadColors.textMuted,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? UstaadColors.darkSurface : Colors.white,
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallback(bool isDark) {
    return Container(
      color: isDark ? UstaadColors.primaryContainerDark : UstaadColors.primaryContainer,
      child: Center(
        child: Text(
          _initials,
          style: UstaadTypography.labelLarge(
            color: isDark ? UstaadColors.primaryLight : UstaadColors.primary,
          ).copyWith(
            fontSize: _fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
