import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
export 'widgets/auth_widgets.dart';
export 'widgets/booking_card.dart';
export 'widgets/common_widgets.dart';
export 'widgets/osm_map_panel.dart';
export 'widgets/provider_card.dart';

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

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
