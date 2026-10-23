import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustaad_flutter/src/ustaad_ui.dart';

void main() {
  setUpAll(() {
    Animate.restartOnHotReload = false;
  });

  group('Network & Data States Widget Tests (Loading, Error, Empty)', () {
    testWidgets('UstaadLoadingSkeleton renders shimmer skeleton and loading text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UstaadLoadingSkeleton(
              cardCount: 2,
              message: 'Fetching top rated ustaads in Islamabad...',
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('Fetching top rated ustaads in Islamabad...'), findsOneWidget);
      expect(find.byType(UstaadSkeletonBox), findsWidgets);
    });

    testWidgets('UstaadErrorView displays error and triggers Retry button callback', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UstaadErrorView(
              title: 'Connection Lost',
              message: 'Check your WiFi or mobile data in Rawalpindi/Islamabad.',
              onRetry: () => retried = true,
              retryLabel: 'Try Again',
            ),
          ),
        ),
      );

      expect(find.text('Connection Lost'), findsOneWidget);
      expect(find.text('Check your WiFi or mobile data in Rawalpindi/Islamabad.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('UstaadEmptyView displays title and triggers Call-to-Action button callback', (tester) async {
      bool ctaPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UstaadEmptyView(
              title: 'No Providers Available',
              message: 'No electricians available in your sector right now.',
              ctaLabel: 'Browse All Services',
              onCta: () => ctaPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('No Providers Available'), findsOneWidget);
      expect(find.text('No electricians available in your sector right now.'), findsOneWidget);
      expect(find.text('Browse All Services'), findsOneWidget);

      await tester.tap(find.text('Browse All Services'));
      await tester.pump();

      expect(ctaPressed, isTrue);
    });

    testWidgets('UstaadAsyncView transitions between Loading, Error, Empty and Success states', (tester) async {
      // 1. Loading state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UstaadAsyncView<List<String>>(
              isLoading: true,
              data: null,
              animateSkeleton: false,
              loadingMessage: 'Loading plumbers...',
              builder: (context, data) => Text('Success: ${data.length}'),
            ),
          ),
        ),
      );

      expect(find.text('Loading plumbers...'), findsOneWidget);
      expect(find.text('Success: 0'), findsNothing);

      // 2. Error state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UstaadAsyncView<List<String>>(
              isLoading: false,
              error: 'HTTP 500 Server Error',
              data: null,
              errorTitle: 'Failed to Fetch',
              onRetry: () {},
              builder: (context, data) => Text('Success: ${data.length}'),
            ),
          ),
        ),
      );

      expect(find.text('Failed to Fetch'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // 3. Empty state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UstaadAsyncView<List<String>>(
              isLoading: false,
              data: const [],
              isEmpty: (list) => list.isEmpty,
              emptyTitle: 'Empty Plumber List',
              onCta: () {},
              builder: (context, data) => Text('Success: ${data.length}'),
            ),
          ),
        ),
      );

      expect(find.text('Empty Plumber List'), findsOneWidget);
      expect(find.text('Explore Services'), findsOneWidget);

      // 4. Success state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UstaadAsyncView<List<String>>(
              isLoading: false,
              data: const ['Ahmed', 'Kamran'],
              isEmpty: (list) => list.isEmpty,
              builder: (context, data) => Text('Success: ${data.length} providers'),
            ),
          ),
        ),
      );

      expect(find.text('Success: 2 providers'), findsOneWidget);
    });
  });
}
