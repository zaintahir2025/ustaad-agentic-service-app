import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustaad_flutter/src/models.dart';
import 'package:ustaad_flutter/src/ustaad_repository.dart';
import 'package:ustaad_flutter/src/ustaad_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('InDrive Bidding and Budget Matching Tests', () {
    test('Natural language budget extraction from problem text', () async {
      final state = UstaadState(UstaadRepository());

      // Test 1: Urdu/Roman Urdu budget phrasing
      await state.startAnalysis('500 mein plumber chahiye kitchen ke liye', 'G-13, Islamabad');
      expect(state.intent?.userBudget, equals(500));
      expect(state.activeOffer, equals(500));

      // Test 2: Explicit budget keyword
      await state.startAnalysis('AC service karni hai budget: 1200', 'F-7, Islamabad');
      expect(state.intent?.userBudget, equals(1200));
      expect(state.activeOffer, equals(1200));

      // Test 3: PKR format
      await state.startAnalysis('Wiring check pkr 800', 'Rawalpindi');
      expect(state.intent?.userBudget, equals(800));
      expect(state.activeOffer, equals(800));
    });

    test('Initial offer parameter overrides or sets user offer', () async {
      final state = UstaadState(UstaadRepository());

      await state.startAnalysis(
        'AC cooling issue',
        'G-13, Islamabad',
        initialOffer: 1500,
      );

      expect(state.userOffer, equals(1500));
      expect(state.activeOffer, equals(1500));
      expect(state.quote?.userOffer, equals(1500));
    });

    test('Real-time offer adjustment re-ranks providers according to budget affinity', () async {
      final state = UstaadState(UstaadRepository());

      await state.startAnalysis('Plumber needed for water leak', 'G-13, Islamabad', initialOffer: 500);
      expect(state.rankedProviders, isNotEmpty);
      expect(state.activeOffer, equals(500));

      // Adjust offer up by 200
      state.adjustUserOffer(200);
      expect(state.activeOffer, equals(700));
      expect(state.quote?.userOffer, equals(700));

      // Check providers have InDrive score tags in reason
      for (final p in state.rankedProviders) {
        expect(p.reason, contains('km'));
      }

      // Explicitly set offer
      state.setUserOffer(1000);
      expect(state.activeOffer, equals(1000));
      expect(state.quote?.userOffer, equals(1000));
    });

    test('QuoteEstimate calculates difference with offer correctly', () {
      final quoteWithin = QuoteEstimate(
        basePrice: 500,
        distancePrice: 50,
        urgencyPrice: 0,
        userOffer: 600,
      );

      expect(quoteWithin.isWithinOffer, isTrue);
      expect(quoteWithin.differenceWithOffer, equals(-100)); // 100 below offer

      final quoteAbove = QuoteEstimate(
        basePrice: 800,
        distancePrice: 50,
        urgencyPrice: 0,
        userOffer: 600,
      );

      expect(quoteAbove.isWithinOffer, isFalse);
      expect(quoteAbove.differenceWithOffer, equals(200)); // 200 above offer
    });

    test('BookingRecord preserves user offer in local and copyWith', () {
      const intent = ServiceIntent(
        role: 'Plumber',
        description: 'Leak repair',
        urgency: 'Normal',
        location: 'G-13',
        timeLabel: 'Immediate',
        language: 'English',
        confidence: 0.9,
        userBudget: 550,
      );

      final quote = QuoteEstimate(
        basePrice: 500,
        distancePrice: 50,
        urgencyPrice: 0,
        userOffer: 550,
      );

      final provider = UstaadRepository.seedProviders.first;

      final booking = BookingRecord.local(
        provider: provider,
        intent: intent,
        quote: quote,
        problemText: 'Leak in bathroom',
        offer: 550,
      );

      expect(booking.userOffer, equals(550));

      final updated = booking.copyWith(status: 'completed', userOffer: 600);
      expect(updated.status, equals('completed'));
      expect(updated.userOffer, equals(600));
    });
  });
}
