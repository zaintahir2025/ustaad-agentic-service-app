import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'models.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/command_center_screen.dart';
import 'screens/gateway_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/selection_screen.dart';
import 'screens/workflow_screen.dart';
import 'ustaad_state.dart';

export 'app_router.dart';
export 'screens/ai_chat_screen.dart';
export 'screens/bookings_screen.dart';
export 'screens/command_center_screen.dart';
export 'screens/gateway_screen.dart';
export 'screens/profile_screen.dart';
export 'screens/selection_screen.dart';
export 'screens/workflow_screen.dart';
export 'theme/ustaad_theme.dart';
export 'widgets/auth_widgets.dart';
export 'widgets/booking_card.dart';
export 'widgets/common_widgets.dart';
export 'widgets/osm_map_panel.dart';
export 'widgets/primitives/primitives.dart';
export 'widgets/provider_card.dart';

/// Central router widget switching screens based on application state.
class UstaadRouter extends StatelessWidget {
  const UstaadRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();

    if (!state.bootstrapped) {
      return const LoadingScreen();
    }

    final screen = switch (state.screen) {
      UstaadScreen.gateway => const GatewayScreen(),
      UstaadScreen.commandCenter => const CommandCenterScreen(),
      UstaadScreen.bookings => const BookingsScreen(),
      UstaadScreen.profile => const ProfileScreen(),
      UstaadScreen.selection => const SelectionScreen(),
      UstaadScreen.workflow => const WorkflowScreen(),
      UstaadScreen.aiChat => const AIChatScreen(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: screen,
    );
  }
}

// =============================================================================
// LOADING SKELETON COMPONENTS
// =============================================================================

/// A rounded placeholder container with shimmer animation.
class UstaadSkeletonBox extends StatelessWidget {
  const UstaadSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.color,
    this.animate = true,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color? color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = color ??
        (isDark
            ? ustaadSurface.withValues(alpha: 0.8)
            : ustaadLightBorder.withValues(alpha: 0.9));
    final highlightColor = isDark
        ? ustaadBorder.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.8);

    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    if (!animate) return box;

    return box
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1400),
          color: highlightColor,
        );
  }
}

/// A theme-matched skeleton loader mimicking a list of provider cards and headers.
class UstaadLoadingSkeleton extends StatelessWidget {
  const UstaadLoadingSkeleton({
    super.key,
    this.cardCount = 3,
    this.message = 'Connecting to verified Ustaads...',
    this.animate = true,
  });

  final int cardCount;
  final String message;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const Box640(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            // Header shimmer
            Center(
              child: Column(
                children: [
                  UstaadSkeletonBox(
                    width: 52,
                    height: 52,
                    borderRadius: 26,
                    animate: animate,
                  ),
                  const SizedBox(height: 14),
                  UstaadSkeletonBox(
                    width: 180,
                    height: 18,
                    borderRadius: 6,
                    animate: animate,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Simulated provider cards
            for (int i = 0; i < cardCount; i++) ...[
              _buildSkeletonCard(context),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ustaadSurface : ustaadLightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ustaadBorder : ustaadLightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UstaadSkeletonBox(
                width: 48,
                height: 48,
                borderRadius: 24,
                animate: animate,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UstaadSkeletonBox(
                        width: 140, height: 16, borderRadius: 4, animate: animate),
                    const SizedBox(height: 8),
                    UstaadSkeletonBox(
                        width: 90, height: 12, borderRadius: 4, animate: animate),
                  ],
                ),
              ),
              UstaadSkeletonBox(
                  width: 60, height: 24, borderRadius: 12, animate: animate),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UstaadSkeletonBox(
                  width: 110, height: 14, borderRadius: 4, animate: animate),
              UstaadSkeletonBox(
                  width: 80, height: 32, borderRadius: 8, animate: animate),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ERROR VIEW COMPONENT (WITH RETRY BUTTON)
// =============================================================================

/// Comprehensive error state component with descriptive messaging and a Retry button.
class UstaadErrorView extends StatelessWidget {
  const UstaadErrorView({
    super.key,
    this.title = 'Unable to Load Data',
    this.message = 'Please check your internet connection and try again.',
    this.onRetry,
    this.retryLabel = 'Retry',
    this.icon = Icons.wifi_off_rounded,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ustaadError.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: ustaadError,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    retryLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ustaadPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(140, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// EMPTY STATE COMPONENT (WITH CALL TO ACTION)
// =============================================================================

/// Comprehensive empty state component with informative description and a Call-to-Action.
class UstaadEmptyView extends StatelessWidget {
  const UstaadEmptyView({
    super.key,
    this.title = 'No Results Found',
    this.message = 'There are no items to display at this moment.',
    this.ctaLabel = 'Explore Services',
    this.onCta,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String message;
  final String ctaLabel;
  final VoidCallback? onCta;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ustaadPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: ustaadPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
              if (onCta != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onCta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ustaadPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(160, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    ctaLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// GENERIC ASYNC DATA VIEW (LOADING, ERROR, EMPTY, SUCCESS)
// =============================================================================

/// Reactive state container rendering Loading, Error, Empty, or Data based on state.
class UstaadAsyncView<T> extends StatelessWidget {
  const UstaadAsyncView({
    super.key,
    required this.isLoading,
    this.error,
    this.data,
    this.isEmpty,
    this.onRetry,
    this.onCta,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyCtaLabel,
    this.emptyIcon,
    this.errorTitle,
    this.errorMessage,
    this.loadingMessage,
    this.animateSkeleton = true,
    required this.builder,
  });

  final bool isLoading;
  final Object? error;
  final T? data;
  final bool Function(T data)? isEmpty;
  final VoidCallback? onRetry;
  final VoidCallback? onCta;
  final String? emptyTitle;
  final String? emptyMessage;
  final String? emptyCtaLabel;
  final IconData? emptyIcon;
  final String? errorTitle;
  final String? errorMessage;
  final String? loadingMessage;
  final bool animateSkeleton;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return UstaadLoadingSkeleton(
        message: loadingMessage ?? 'Loading...',
        animate: animateSkeleton,
      );
    }

    if (error != null) {
      return UstaadErrorView(
        title: errorTitle ?? 'Unable to Load Data',
        message: errorMessage ?? error.toString(),
        onRetry: onRetry,
      );
    }

    if (data == null || (isEmpty != null && isEmpty!(data as T))) {
      return UstaadEmptyView(
        title: emptyTitle ?? 'No Results Found',
        message: emptyMessage ?? 'No data is currently available.',
        ctaLabel: emptyCtaLabel ?? 'Explore Services',
        onCta: onCta,
        icon: emptyIcon ?? Icons.inbox_outlined,
      );
    }

    return builder(context, data as T);
  }
}

// =============================================================================
// APPLICATION LOADING SCREEN
// =============================================================================

/// Upgraded theme-matched loading screen with skeleton shimmer.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ustaadBackground : ustaadLightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo branding
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ustaadPrimary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ustaadPrimary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'U',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: ustaadPrimary,
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.96, 0.96),
                      end: const Offset(1.04, 1.04),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(height: 16),
                const Text(
                  'USTAAD',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: ustaadPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pakistan\'s Trusted On-Demand Services',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                const UstaadLoadingSkeleton(
                  cardCount: 2,
                  message: 'Synchronizing local offline cache...',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Box640 extends BoxConstraints {
  const Box640() : super(maxWidth: 640);
}
