import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustaad_flutter/src/currency.dart';
import 'package:ustaad_flutter/src/l10n/app_localizations.dart';
import 'package:ustaad_flutter/src/models.dart';
import 'package:ustaad_flutter/src/screens/bookings_screen.dart';
import 'package:ustaad_flutter/src/screens/command_center_screen.dart';
import 'package:ustaad_flutter/src/screens/selection_screen.dart';
import 'package:ustaad_flutter/src/ustaad_repository.dart';
import 'package:ustaad_flutter/src/ustaad_state.dart';
import 'package:ustaad_flutter/src/widgets/booking_card.dart';
import 'package:ustaad_flutter/src/widgets/provider_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PKR Currency Formatting Tests', () {
    test('formats positive and negative amounts correctly in English', () {
      expect(formatPkr(1200), equals('PKR 1,200'));
      expect(formatPkr(600), equals('PKR 600'));
      expect(formatPkr(25000), equals('PKR 25,000'));
      expect(formatPkr(-300), equals('-PKR 300'));
    });

    test('formats amounts correctly in Urdu', () {
      expect(formatPkr(1200, isUrdu: true), equals('روپے 1,200'));
      expect(formatPkr(600, isUrdu: true), equals('روپے 600'));
      expect(formatPkr(-300, isUrdu: true), equals('-روپے 300'));
    });
  });

  group('Main Booking Flow Widget Tests', () {
    testWidgets('End-to-end booking flow: search -> provider card -> accept offer -> booking list verification',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = UstaadState(UstaadRepository());
      // Set test user so shell screens work without redirect
      state.user = const UstaadUser(
        id: 'test-user-1',
        name: 'Taimoor',
        email: 'taimoor@test.com',
        phone: '+923001234567',
        city: 'Islamabad',
        address: 'G-13/2',
        preferredLanguage: 'English',
        bio: 'Tester',
      );

      state.setScreen(UstaadScreen.commandCenter);

      Widget createHostWidget() {
        return ChangeNotifierProvider<UstaadState>.value(
          value: state,
          child: Consumer<UstaadState>(
            builder: (context, appState, _) {
              return MaterialApp(
                locale: appState.currentLocale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: switch (appState.screen) {
                  UstaadScreen.commandCenter => const CommandCenterScreen(),
                  UstaadScreen.selection => const SelectionScreen(),
                  UstaadScreen.bookings => const BookingsScreen(),
                  _ => const CommandCenterScreen(),
                },
              );
            },
          ),
        );
      }

      await tester.pumpWidget(createHostWidget());
      await tester.pumpAndSettle();

      // 1. Verify CommandCenter loads
      expect(find.text('Hi Taimoor'), findsOneWidget);
      expect(find.byType(CommandCenterScreen), findsOneWidget);

      // 2. Select AC quick chip to populate problem and budget
      final acChip = find.text('AC (PKR 1,200)');
      expect(acChip, findsOneWidget);
      await tester.tap(acChip);
      await tester.pumpAndSettle();

      // 3. Tap "Find providers" button
      final findProvidersBtn = find.text('Find providers');
      expect(findProvidersBtn, findsOneWidget);
      await tester.tap(findProvidersBtn);
      await tester.pumpAndSettle();

      // 4. Verify transitioned to SelectionScreen with ranked providers
      expect(state.screen, equals(UstaadScreen.selection));
      expect(find.byType(SelectionScreen), findsOneWidget);
      expect(find.text('Your InDrive Offer'), findsOneWidget);
      expect(find.byType(ProviderCard), findsWidgets);

      // 5. Book the first provider by tapping Accept Offer
      final acceptOfferBtn = find.widgetWithText(ElevatedButton, 'Accept Offer (PKR 1,200)');
      expect(acceptOfferBtn, findsWidgets);
      await tester.ensureVisible(acceptOfferBtn.first);
      await tester.pumpAndSettle();
      await tester.tap(acceptOfferBtn.first);
      await tester.pumpAndSettle();

      // 6. Verify booking was confirmed and created
      expect(state.bookings.length, equals(1));
      final booking = state.bookings.first;
      expect(booking.serviceRole, equals('AC Repair'));
      expect(booking.providerName.isNotEmpty, isTrue);
      expect(booking.quoteTotal, equals(state.quote?.total ?? 1450));
      expect(state.screen, equals(UstaadScreen.workflow));

      // 7. Transition to BookingsScreen and verify BookingCard displays details
      state.openBookings();
      await tester.pumpWidget(createHostWidget());
      await tester.pumpAndSettle();

      expect(state.screen, equals(UstaadScreen.bookings));
      expect(find.byType(BookingsScreen), findsOneWidget);
      expect(find.byType(BookingCard), findsOneWidget);
      expect(find.text(booking.providerName), findsOneWidget);
      expect(find.text('AC Repair • ${formatPkr(booking.quoteTotal)}'), findsOneWidget);
    });

    testWidgets('Empty request validation prevents finding providers without description',
        (tester) async {
      final state = UstaadState(UstaadRepository());
      state.setScreen(UstaadScreen.commandCenter);
      state.user = const UstaadUser(
        id: 'test-user-2',
        name: 'Sara',
        email: 'sara@test.com',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<UstaadState>.value(
          value: state,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CommandCenterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Find Providers with empty problem
      final findProvidersBtn = find.text('Find providers');
      await tester.tap(findProvidersBtn);
      await tester.pump();

      // Verify SnackBar warning appears and screen remains on commandCenter
      expect(find.text('Describe the service first.'), findsOneWidget);
      expect(state.screen, equals(UstaadScreen.commandCenter));
    });
  });
}
