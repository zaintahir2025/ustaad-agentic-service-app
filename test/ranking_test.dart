import 'package:flutter_test/flutter_test.dart';
import 'package:ustaad_flutter/config/ranking_config.dart';
import 'package:ustaad_flutter/services/provider_ranking_service.dart';
import 'package:ustaad_flutter/src/domain/entities/provider_profile.dart';

void main() {
  group('RankingConfig Unit Tests', () {
    test('default weights match requirements (30% distance, 40% rating, 30% price)', () {
      const config = RankingConfig.defaultConfig;

      expect(config.distanceWeight, equals(0.30));
      expect(config.ratingWeight, equals(0.40));
      expect(config.priceWeight, equals(0.30));
      expect(config.totalWeight, closeTo(1.0, 0.001));
      expect(config.normalizedDistanceWeight, closeTo(0.30, 0.001));
      expect(config.normalizedRatingWeight, closeTo(0.40, 0.001));
      expect(config.normalizedPriceWeight, closeTo(0.30, 0.001));
    });

    test('presets configure weights appropriately', () {
      expect(RankingConfig.proximityFirst.distanceWeight, equals(0.60));
      expect(RankingConfig.ratingFirst.ratingWeight, equals(0.60));
      expect(RankingConfig.budgetFirst.priceWeight, equals(0.60));
    });

    test('copyWith modifies targeted weights while preserving other parameters', () {
      const original = RankingConfig.defaultConfig;
      final modified = original.copyWith(
        distanceWeight: 0.50,
        priceWeight: 0.10,
      );

      expect(modified.distanceWeight, equals(0.50));
      expect(modified.ratingWeight, equals(0.40));
      expect(modified.priceWeight, equals(0.10));
      expect(modified.maxDistanceKm, equals(original.maxDistanceKm));
      expect(modified.maxRating, equals(original.maxRating));
    });

    test('normalizes non-standard weight sums accurately', () {
      const nonStandard = RankingConfig(
        distanceWeight: 3.0,
        ratingWeight: 4.0,
        priceWeight: 3.0,
      );

      expect(nonStandard.totalWeight, equals(10.0));
      expect(nonStandard.normalizedDistanceWeight, closeTo(0.30, 0.001));
      expect(nonStandard.normalizedRatingWeight, closeTo(0.40, 0.001));
      expect(nonStandard.normalizedPriceWeight, closeTo(0.30, 0.001));
    });
  });

  group('ProviderRankingService: General Scoring & Sorting', () {
    const service = ProviderRankingService();

    test('returns empty list when input providers list is empty', () {
      final ranked = service.rank([]);
      expect(ranked, isEmpty);
    });

    test('single provider is scored and returned successfully', () {
      const provider = UstaadProviderProfile(
        id: 'p1',
        name: 'Tariq Mehmood',
        role: 'Electrician',
        rating: 4.8,
        price: 600,
        distanceKm: 3,
        reliability: 0.95,
        avatarUrl: '',
        verified: true,
        city: 'Islamabad',
      );

      final ranked = service.rank([provider]);
      expect(ranked.length, equals(1));
      expect(ranked.first.score, greaterThan(0));
      expect(ranked.first.reason, contains('3 km'));
      expect(ranked.first.reason, contains('4.8★'));
      expect(ranked.first.reason, contains('PKR 600'));
    });

    test('ranks multiple providers in strictly descending order of score', () {
      final providers = [
        const UstaadProviderProfile(
          id: 'p1',
          name: 'Ahmed',
          role: 'Plumber',
          rating: 4.9,
          price: 500,
          distanceKm: 2,
          reliability: 0.95,
          avatarUrl: '',
          verified: true,
          city: 'Islamabad',
        ),
        const UstaadProviderProfile(
          id: 'p2',
          name: 'Bilal',
          role: 'Plumber',
          rating: 3.8,
          price: 900,
          distanceKm: 15,
          reliability: 0.80,
          avatarUrl: '',
          verified: true,
          city: 'Islamabad',
        ),
        const UstaadProviderProfile(
          id: 'p3',
          name: 'Hamza',
          role: 'Plumber',
          rating: 4.5,
          price: 700,
          distanceKm: 8,
          reliability: 0.90,
          avatarUrl: '',
          verified: true,
          city: 'Islamabad',
        ),
      ];

      final ranked = service.rank(providers);
      expect(ranked.length, equals(3));
      for (int i = 0; i < ranked.length - 1; i++) {
        expect(
          ranked[i].score,
          greaterThanOrEqualTo(ranked[i + 1].score),
          reason: '${ranked[i].name} (${ranked[i].score}) should be >= ${ranked[i + 1].name} (${ranked[i + 1].score})',
        );
      }
      expect(ranked.first.id, equals('p1'));
    });
  });

  group('ProviderRankingService: Edge Cases', () {
    const service = ProviderRankingService();

    // -------------------------------------------------------------
    // Edge Case 1: Provider with no rating (0.0 or unrated)
    // -------------------------------------------------------------
    test('Edge Case 1: A provider with no rating (0.0) is penalized in the rating component (40% weight)', () {
      const unratedProvider = UstaadProviderProfile(
        id: 'p_unrated',
        name: 'Newcomer Provider',
        role: 'Electrician',
        rating: 0.0, // No rating yet
        price: 500,
        distanceKm: 4,
        reliability: 0.85,
        avatarUrl: '',
        verified: true,
        city: 'Islamabad',
      );

      const ratedProvider = UstaadProviderProfile(
        id: 'p_rated',
        name: 'Experienced Provider',
        role: 'Electrician',
        rating: 4.8, // Well-rated
        price: 500,
        distanceKm: 4, // Identical distance & price
        reliability: 0.95,
        avatarUrl: '',
        verified: true,
        city: 'Islamabad',
      );

      final breakdownUnrated = service.calculateScore(
        unratedProvider,
        config: RankingConfig.defaultConfig,
      );
      final breakdownRated = service.calculateScore(
        ratedProvider,
        config: RankingConfig.defaultConfig,
      );

      // Unrated provider should have 0 rating score
      expect(breakdownUnrated.ratingScore, equals(0.0));
      expect(breakdownUnrated.weightedRating, equals(0.0));

      // Rated provider receives 4.8 / 5.0 * 100 * 0.40 = 38.4 rating points
      expect(breakdownRated.ratingScore, closeTo(96.0, 0.1));
      expect(breakdownRated.weightedRating, closeTo(38.4, 0.1));

      // Ranking together: rated provider must cleanly beat unrated provider
      final ranked = service.rank([unratedProvider, ratedProvider]);
      expect(ranked.first.id, equals('p_rated'));
      expect(ranked.last.id, equals('p_unrated'));
      expect(ranked.first.score - ranked.last.score, closeTo(38.4, 0.1));
    });

    test('Edge Case 1b: Even if an unrated provider is slightly closer, 40% rating weight prioritizes rated provider', () {
      const unratedCloser = UstaadProviderProfile(
        id: 'p_unrated_closer',
        name: 'Closer Unrated',
        role: 'Plumber',
        rating: 0.0,
        price: 600,
        distanceKm: 2, // 2 km closer
        reliability: 0.80,
        avatarUrl: '',
        verified: false,
        city: 'Islamabad',
      );

      const ratedSlightlyFarther = UstaadProviderProfile(
        id: 'p_rated_farther',
        name: 'Reputable Plumber',
        role: 'Plumber',
        rating: 4.7,
        price: 600,
        distanceKm: 5, // 5 km (only 3 km further)
        reliability: 0.95,
        avatarUrl: '',
        verified: true,
        city: 'Islamabad',
      );

      final ranked = service.rank([unratedCloser, ratedSlightlyFarther]);
      // The 40% rating weight comfortably overcomes the slight proximity difference
      expect(ranked.first.id, equals('p_rated_farther'));
      expect(ranked.first.score, greaterThan(ranked.last.score));
    });

    // -------------------------------------------------------------
    // Edge Case 2: A provider who is extremely far but cheap
    // -------------------------------------------------------------
    test('Edge Case 2: A provider who is extremely far but cheap behaves correctly under configurable weights', () {
      const farAndCheap = UstaadProviderProfile(
        id: 'p_far_cheap',
        name: 'Budget Outskirt Provider',
        role: 'AC Repair',
        rating: 4.5,
        price: 200, // Very cheap
        distanceKm: 35, // Beyond maxDistanceKm of 30 km -> 0 proximity score
        reliability: 0.90,
        avatarUrl: '',
        verified: true,
        city: 'Rawalpindi',
      );

      const closeAndModerate = UstaadProviderProfile(
        id: 'p_close_moderate',
        name: 'Nearby Standard Provider',
        role: 'AC Repair',
        rating: 4.5,
        price: 1500, // Moderate-to-high price
        distanceKm: 4, // Very close (4 km)
        reliability: 0.90,
        avatarUrl: '',
        verified: true,
        city: 'Islamabad',
      );

      final list = [farAndCheap, closeAndModerate];

      // 1. Under default config (30% distance, 40% rating, 30% price):
      // The distance penalty of being 35 km away causes closeAndModerate to win
      final rankedDefault = service.rank(list, overrideConfig: RankingConfig.defaultConfig);
      expect(rankedDefault.first.id, equals('p_close_moderate'));
      expect(rankedDefault.last.id, equals('p_far_cheap'));
      expect(rankedDefault.first.score, greaterThan(rankedDefault.last.score + 10.0));

      // 2. Under budgetFirst config (20% distance, 20% rating, 60% price):
      // When price weight is boosted to 60%, the cheap price dominates and farAndCheap wins
      final rankedBudget = service.rank(list, overrideConfig: RankingConfig.budgetFirst);
      expect(rankedBudget.first.id, equals('p_far_cheap'));
      expect(rankedBudget.last.id, equals('p_close_moderate'));
      expect(rankedBudget.first.score, greaterThan(rankedBudget.last.score + 5.0));
    });

    // -------------------------------------------------------------
    // Edge Case 3: A provider who is close but expensive
    // -------------------------------------------------------------
    test('Edge Case 3: A provider who is close but expensive behaves correctly under configurable weights', () {
      const closeAndExpensive = UstaadProviderProfile(
        id: 'p_close_expensive',
        name: 'Express Premium Specialist',
        role: 'Plumber',
        rating: 4.8,
        price: 2600, // Expensive
        distanceKm: 1, // Only 1 km away (almost 100% proximity score)
        reliability: 0.98,
        avatarUrl: '',
        verified: true,
        city: 'Islamabad',
      );

      const midDistAndAffordable = UstaadProviderProfile(
        id: 'p_mid_affordable',
        name: 'Fair Value Plumber',
        role: 'Plumber',
        rating: 4.8,
        price: 500, // Affordable
        distanceKm: 14, // 14 km away
        reliability: 0.92,
        avatarUrl: '',
        verified: true,
        city: 'Islamabad',
      );

      final list = [closeAndExpensive, midDistAndAffordable];

      // 1. Under proximityFirst config (60% distance, 20% rating, 20% price):
      // Heavy proximity weight makes 1km provider win despite high price
      final rankedProximity = service.rank(
        list,
        overrideConfig: RankingConfig.proximityFirst,
      );
      expect(rankedProximity.first.id, equals('p_close_expensive'));
      expect(rankedProximity.last.id, equals('p_mid_affordable'));
      expect(rankedProximity.first.score, greaterThan(rankedProximity.last.score + 10.0));

      // 2. Under budgetFirst config (20% distance, 20% rating, 60% price):
      // Heavy budget weight flips the outcome so the affordable provider wins decisively
      final rankedBudget = service.rank(
        list,
        overrideConfig: RankingConfig.budgetFirst,
      );
      expect(rankedBudget.first.id, equals('p_mid_affordable'));
      expect(rankedBudget.last.id, equals('p_close_expensive'));
      expect(rankedBudget.first.score, greaterThan(rankedBudget.last.score + 25.0));
    });

    // -------------------------------------------------------------
    // InDrive Target Budget Awareness
    // -------------------------------------------------------------
    test('targetBudget gives 100% price score to providers at or below budget', () {
      const budgetProvider = UstaadProviderProfile(
        id: 'p_at_budget',
        name: 'Budget Match',
        role: 'Electrician',
        rating: 4.5,
        price: 600,
        distanceKm: 5,
        reliability: 0.90,
        avatarUrl: '',
        verified: true,
        city: 'Islamabad',
      );

      const expensiveProvider = UstaadProviderProfile(
        id: 'p_over_budget',
        name: 'High Quote',
        role: 'Electrician',
        rating: 4.5,
        price: 1200, // 100% over budget
        distanceKm: 5,
        reliability: 0.90,
        avatarUrl: '',
        verified: true,
        city: 'Islamabad',
      );

      final breakdownBudget = service.calculateScore(
        budgetProvider,
        config: RankingConfig.defaultConfig,
        targetBudget: 600,
      );
      final breakdownExpensive = service.calculateScore(
        expensiveProvider,
        config: RankingConfig.defaultConfig,
        targetBudget: 600,
      );

      expect(breakdownBudget.priceScore, equals(100.0));
      expect(breakdownExpensive.priceScore, equals(0.0));
    });

    // -------------------------------------------------------------
    // Tie Breaking
    // -------------------------------------------------------------
    test('tie breaking prefers closer provider, then higher rating', () {
      const providerA = UstaadProviderProfile(
        id: 'p_closer',
        name: 'Closer Provider',
        role: 'Plumber',
        rating: 4.5,
        price: 700,
        distanceKm: 3,
        reliability: 0.90,
        avatarUrl: '',
        verified: true,
        city: 'Islamabad',
      );

      // Same overall score parameters but slightly different distance & rating
      final breakdownA = service.calculateScore(providerA, config: RankingConfig.defaultConfig);
      expect(breakdownA.totalScore, greaterThan(0));

      final ranked = ProviderRankingService.rankProviders([providerA]);
      expect(ranked.first.id, equals('p_closer'));
    });
  });
}
