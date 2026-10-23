import 'dart:math' as math;

import '../../config/ranking_config.dart';
import '../entities/provider_profile.dart';

/// Detailed score breakdown for a provider across distance, rating, and price.
class ProviderScoreBreakdown {
  const ProviderScoreBreakdown({
    required this.distanceScore,
    required this.ratingScore,
    required this.priceScore,
    required this.weightedDistance,
    required this.weightedRating,
    required this.weightedPrice,
    required this.totalScore,
    required this.summaryReason,
  });

  /// Raw score for proximity (0.0 to 100.0).
  final double distanceScore;

  /// Raw score for customer rating (0.0 to 100.0).
  final double ratingScore;

  /// Raw score for price / budget affinity (0.0 to 100.0).
  final double priceScore;

  /// Distance score weighted by configuration weight.
  final double weightedDistance;

  /// Rating score weighted by configuration weight.
  final double weightedRating;

  /// Price score weighted by configuration weight.
  final double weightedPrice;

  /// Final combined weighted composite score.
  final double totalScore;

  /// Human-readable explanation string for why the provider was ranked at this score.
  final String summaryReason;
}

/// Service responsible for scoring and sorting service providers based on configurable weights.
///
/// Default configuration:
/// - 30% Distance / Proximity
/// - 40% Customer Rating
/// - 30% Price / Budget Affinity
class ProviderRankingService {
  final RankingConfig config;

  const ProviderRankingService({this.config = const RankingConfig()});

  /// Static convenience method to rank providers directly without instantiating the service.
  static List<UstaadProviderProfile> rankProviders(
    List<UstaadProviderProfile> providers, {
    RankingConfig config = const RankingConfig(),
    int? targetBudget,
  }) {
    return ProviderRankingService(config: config).rank(
      providers,
      targetBudget: targetBudget,
    );
  }

  /// Evaluates and ranks a list of [providers] in descending order of composite score.
  ///
  /// Can optionally accept an [overrideConfig] to apply dynamic weights for a specific calculation,
  /// and an optional [targetBudget] representing the customer's budget or InDrive offer.
  List<UstaadProviderProfile> rank(
    List<UstaadProviderProfile> providers, {
    RankingConfig? overrideConfig,
    int? targetBudget,
  }) {
    if (providers.isEmpty) return const [];

    final activeConfig = overrideConfig ?? config;

    if (providers.length == 1) {
      final single = providers.first;
      final breakdown = calculateScore(
        single,
        config: activeConfig,
        targetBudget: targetBudget,
        pool: providers,
      );
      return [single.withScore(breakdown.totalScore, breakdown.summaryReason)];
    }

    final scoredList = providers.map((provider) {
      final breakdown = calculateScore(
        provider,
        config: activeConfig,
        targetBudget: targetBudget,
        pool: providers,
      );
      return provider.withScore(breakdown.totalScore, breakdown.summaryReason);
    }).toList();

    // Sort in strictly descending order of score.
    // If composite scores tie, break ties by distance (closer wins), then by rating (higher wins).
    scoredList.sort((a, b) {
      final diff = b.score.compareTo(a.score);
      if (diff != 0) return diff;
      final distDiff = a.distanceKm.compareTo(b.distanceKm);
      if (distDiff != 0) return distDiff;
      return b.rating.compareTo(a.rating);
    });

    return scoredList;
  }

  /// Computes component scores and composite score for a single provider.
  ProviderScoreBreakdown calculateScore(
    UstaadProviderProfile provider, {
    required RankingConfig config,
    int? targetBudget,
    List<UstaadProviderProfile>? pool,
  }) {
    // -------------------------------------------------------------
    // 1. Distance Score (0.0 to 100.0)
    // Closer is better.
    // At 0 km -> 100.0 score.
    // At or beyond maxDistanceKm (e.g. 30 km) -> 0.0 score.
    // -------------------------------------------------------------
    final double distanceScore;
    if (provider.distanceKm <= 0) {
      distanceScore = 100.0;
    } else if (provider.distanceKm >= config.maxDistanceKm) {
      distanceScore = 0.0;
    } else {
      distanceScore =
          ((config.maxDistanceKm - provider.distanceKm) / config.maxDistanceKm) *
              100.0;
    }

    // -------------------------------------------------------------
    // 2. Rating Score (0.0 to 100.0)
    // Edge case: unrated or new providers (rating <= 0.0)
    // -------------------------------------------------------------
    final double ratingScore;
    if (provider.rating <= 0.0) {
      ratingScore =
          (config.unratedDefaultRating / config.maxRating).clamp(0.0, 1.0) *
              100.0;
    } else {
      ratingScore =
          (provider.rating / config.maxRating).clamp(0.0, 1.0) * 100.0;
    }

    // -------------------------------------------------------------
    // 3. Price Score (0.0 to 100.0)
    // Cheaper is better.
    // If targetBudget is provided:
    //   - At or below budget gets maximum score (100.0).
    //   - Exceeding budget scales down linearly with overspend.
    // If targetBudget is not provided:
    //   - Normalizes against referencePriceCeiling (default 3000 PKR).
    // -------------------------------------------------------------
    final double priceScore;
    if (targetBudget != null && targetBudget > 0) {
      if (provider.price <= targetBudget) {
        priceScore = 100.0;
      } else {
        final overspendRatio = (provider.price - targetBudget) / targetBudget;
        priceScore = math.max(0.0, (1.0 - overspendRatio) * 100.0);
      }
    } else {
      priceScore = math.max(
            0.0,
            1.0 - (provider.price / config.referencePriceCeiling),
          ) *
          100.0;
    }

    // Apply normalized weights
    final weightedDistance = distanceScore * config.normalizedDistanceWeight;
    final weightedRating = ratingScore * config.normalizedRatingWeight;
    final weightedPrice = priceScore * config.normalizedPriceWeight;

    final totalScore = weightedDistance + weightedRating + weightedPrice;

    final reason =
        '${provider.distanceKm} km · ${provider.rating > 0 ? "${provider.rating.toStringAsFixed(1)}★" : "Unrated"} · PKR ${provider.price}';

    return ProviderScoreBreakdown(
      distanceScore: distanceScore,
      ratingScore: ratingScore,
      priceScore: priceScore,
      weightedDistance: weightedDistance,
      weightedRating: weightedRating,
      weightedPrice: weightedPrice,
      totalScore: totalScore,
      summaryReason: reason,
    );
  }
}
