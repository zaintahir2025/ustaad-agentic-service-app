import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

GoRouter createUstaadRouter(UstaadState state) {
  return GoRouter(
    initialLocation: state.isSignedIn ? '/' : '/auth',
    refreshListenable: state,
    redirect: (context, routerState) {
      if (!state.bootstrapped) return null;

      final signedIn = state.isSignedIn;
      final location = routerState.matchedLocation;
      final goingToAuth = location == '/auth';

      // 1. Unauthenticated users must be on /auth
      if (!signedIn && !goingToAuth) {
        return '/auth';
      }

      // 2. Authenticated users should not stay on /auth
      if (signedIn && goingToAuth) {
        return '/';
      }

      // 3. Handle programmatic screen navigation requested from state
      if (signedIn && state.requestedScreen != null) {
        final target = state.requestedScreen!;
        state.requestedScreen = null;
        final targetPath = switch (target) {
          UstaadScreen.gateway => '/auth',
          UstaadScreen.commandCenter => '/',
          UstaadScreen.bookings => '/bookings',
          UstaadScreen.profile => '/profile',
          UstaadScreen.selection => '/selection',
          UstaadScreen.workflow => '/workflow',
          UstaadScreen.aiChat => '/chat',
        };
        if (location != targetPath) {
          return targetPath;
        }
      }

      // 4. Guard against deep linking into uninitialized selection or workflow
      if (signedIn) {
        if (location == '/selection' && (state.intent == null || state.quote == null)) {
          return '/';
        }
        if (location == '/workflow' && state.selectedProvider == null) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, routerState) {
          _syncScreen(context, UstaadScreen.commandCenter);
          return const CommandCenterScreen();
        },
      ),
      GoRoute(
        path: '/auth',
        builder: (context, routerState) {
          _syncScreen(context, UstaadScreen.gateway);
          return const GatewayScreen();
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (context, routerState) {
          _syncScreen(context, UstaadScreen.aiChat);
          return const AIChatScreen();
        },
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, routerState) {
          _syncScreen(context, UstaadScreen.bookings);
          return const BookingsScreen();
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, routerState) {
          _syncScreen(context, UstaadScreen.profile);
          return const ProfileScreen();
        },
      ),
      GoRoute(
        path: '/selection',
        builder: (context, routerState) {
          _syncScreen(context, UstaadScreen.selection);
          return const SelectionScreen();
        },
      ),
      GoRoute(
        path: '/workflow',
        builder: (context, routerState) {
          _syncScreen(context, UstaadScreen.workflow);
          return const WorkflowScreen();
        },
      ),
    ],
    errorBuilder: (context, routerState) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              'Page not found: ${routerState.uri}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Return Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

void _syncScreen(BuildContext context, UstaadScreen target) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final state = context.read<UstaadState>();
    if (state.screen != target) {
      state.screen = target;
      // Do not notify listeners here to avoid loop with router redirect
    }
  });
}
