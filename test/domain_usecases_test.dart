import 'package:flutter_test/flutter_test.dart';
import 'package:ustaad_flutter/src/domain/entities/achievement_badge.dart';
import 'package:ustaad_flutter/src/domain/entities/provider_profile.dart';
import 'package:ustaad_flutter/src/domain/entities/service_intent.dart';
import 'package:ustaad_flutter/src/domain/usecases/build_workflow_trace_use_case.dart';
import 'package:ustaad_flutter/src/domain/usecases/calculate_quote_use_case.dart';
import 'package:ustaad_flutter/src/domain/usecases/evaluate_achievements_use_case.dart';
import 'package:ustaad_flutter/src/domain/usecases/extract_intent_use_case.dart';
import 'package:ustaad_flutter/src/domain/usecases/rank_providers_use_case.dart';

void main() {
  group('Domain Use Cases: ExtractIntentUseCase', () {
    const useCase = ExtractIntentUseCase();

    test('parses Urdu text and identifies Electrician role with High urgency', () {
      final intent = useCase.execute('بجلی کا بریکر جلدی ٹھیک کرو', 'G-13, Islamabad');
      expect(intent.role, equals('Electrician'));
      expect(intent.urgency, equals('High'));
      expect(intent.language, equals('Urdu'));
      expect(intent.description, equals('Breaker & Short Circuit Fault'));
    });

    test('parses Roman Urdu and extracts explicit budget and time label', () {
      final intent = useCase.execute(
        'kal subah pani ka nalka leak kar raha hai 800 rupay mein plumber chahiye',
        'F-10, Islamabad',
      );
      expect(intent.role, equals('Plumber'));
      expect(intent.timeLabel, equals('Tomorrow morning'));
      expect(intent.userBudget, equals(800));
      expect(intent.language, equals('Roman Urdu'));
    });

    test('extracts sector label properly from various location formats', () {
      expect(useCase.sectorFromLocation('Street 12, G-13/2, Islamabad'), equals('G-13'));
      expect(useCase.sectorFromLocation('Sector F-10 Markaz'), equals('F-10'));
      expect(useCase.sectorFromLocation('Rawalpindi Saddar'), equals('Islamabad'));
    });
  });

  group('Domain Use Cases: RankProvidersUseCase', () {
    const useCase = RankProvidersUseCase();

    final testProviders = <UstaadProviderProfile>[
      const UstaadProviderProfile(
        id: 'p1',
        name: 'Affordable Plumber',
        role: 'Plumber',
        rating: 4.5,
        price: 500,
        distanceKm: 5,
        reliability: 0.95,
        jobsCompleted: 100,
        responseTimeMinutes: 10,
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
        verified: true,
        city: 'Islamabad',
        phone: '+923001111111',
      ),
      const UstaadProviderProfile(
        id: 'p2',
        name: 'Expensive Plumber',
        role: 'Plumber',
        rating: 4.8,
        price: 1000,
        distanceKm: 15,
        reliability: 0.85,
        jobsCompleted: 50,
        responseTimeMinutes: 30,
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
        verified: true,
        city: 'Islamabad',
        phone: '+923002222222',
      ),
    ];

    test('ranks affordable and closer provider ahead when user offer is 500', () {
      const intent = ServiceIntent(
        role: 'Plumber',
        description: 'Leak repair',
        urgency: 'Normal',
        location: 'G-13',
        timeLabel: 'Immediate',
        language: 'English',
        confidence: 0.9,
        userBudget: 500,
      );

      final ranked = useCase.execute(
        providers: testProviders,
        intent: intent,
        offer: 500,
      );

      expect(ranked.first.id, equals('p1'));
      expect(ranked.first.score, greaterThan(ranked.last.score));
      expect(ranked.first.reason, contains('Exact match'));
    });
  });

  group('Domain Use Cases: CalculateQuoteUseCase', () {
    const useCase = CalculateQuoteUseCase();

    test('calculates correct base, distance, urgency pricing and difference with offer', () {
      const provider = UstaadProviderProfile(
        id: 'p1',
        name: 'Test Pro',
        role: 'Electrician',
        rating: 4.9,
        price: 600,
        distanceKm: 4,
        reliability: 0.95,
        jobsCompleted: 20,
        responseTimeMinutes: 15,
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
        verified: true,
        city: 'Islamabad',
        phone: '+923000000000',
      );

      const highUrgencyIntent = ServiceIntent(
        role: 'Electrician',
        description: 'Urgent spark',
        urgency: 'High',
        location: 'G-13',
        timeLabel: 'Immediate',
        language: 'English',
        confidence: 0.95,
        userBudget: 1000,
      );

      final quote = useCase.execute(
        provider: provider,
        intent: highUrgencyIntent,
        offer: 1000,
      );

      expect(quote.basePrice, equals(600));
      expect(quote.distancePrice, equals(4 * 50)); // 200
      expect(quote.urgencyPrice, equals(500)); // High urgency
      expect(quote.total, equals(600 + 200 + 500)); // 1300
      expect(quote.userOffer, equals(1000));
      expect(quote.differenceWithOffer, equals(-400)); // 400 below offer
      expect(quote.isWithinOffer, isTrue);

      final overQuote = useCase.execute(
        provider: provider,
        intent: highUrgencyIntent,
        offer: 500,
      );
      expect(overQuote.differenceWithOffer, equals(100)); // 100 above offer
      expect(overQuote.isWithinOffer, isFalse);
    });
  });

  group('Domain Use Cases: BuildWorkflowTraceUseCase', () {
    const useCase = BuildWorkflowTraceUseCase();

    test('generates expected 9 multi-agent workflow trace events', () {
      const intent = ServiceIntent(
        role: 'Electrician',
        description: 'Fan repair',
        urgency: 'Normal',
        location: 'G-13, Islamabad',
        timeLabel: 'Today',
        language: 'English',
        confidence: 0.9,
      );

      const provider = UstaadProviderProfile(
        id: 'p1',
        name: 'Ali Raza',
        role: 'Electrician',
        rating: 4.8,
        price: 500,
        distanceKm: 3,
        reliability: 0.92,
        jobsCompleted: 80,
        responseTimeMinutes: 12,
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
        verified: true,
        city: 'Islamabad',
        phone: '+923001234567',
      );

      final events = useCase.execute(
        intent: intent,
        ranked: [provider],
        offer: 500,
      );

      expect(events.length, equals(9));
      expect(events.map((e) => e.agentName).toList(), containsAll([
        'Engine Router',
        'NLP Interpreter',
        'Context Agent',
        'Discovery Agent',
        'Ranking Agent',
        'Decision Agent',
        'Quote Agent',
        'Booking Agent',
        'Follow-up Agent',
      ]));
    });
  });

  group('Domain Use Cases: EvaluateAchievementsUseCase', () {
    const useCase = EvaluateAchievementsUseCase();

    test('unlocks first_request and multilingual when problem is submitted in Roman Urdu', () {
      final initialBadges = AchievementBadge.defaultBadges();
      final result = useCase.execute(
        lastProblem: 'pani ka masla hai',
        totalBookingsCount: 0,
        language: 'Roman Urdu',
        currentBadges: initialBadges,
      );

      expect(result.newlyUnlocked.map((b) => b.id), containsAll(['first_request', 'multilingual']));
      final unlockedIds = result.allBadges.where((b) => b.unlocked).map((b) => b.id);
      expect(unlockedIds, containsAll(['first_request', 'multilingual']));
    });

    test('unlockById unlocks emergency_hero badge', () {
      final initialBadges = AchievementBadge.defaultBadges();
      final result = useCase.unlockById(
        id: 'emergency_hero',
        currentBadges: initialBadges,
      );

      expect(result.newlyUnlocked.map((b) => b.id), contains('emergency_hero'));
      expect(result.allBadges.firstWhere((b) => b.id == 'emergency_hero').unlocked, isTrue);
    });
  });
}
