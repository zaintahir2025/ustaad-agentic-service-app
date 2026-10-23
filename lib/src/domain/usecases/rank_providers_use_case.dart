import 'dart:math' as math;

import '../../currency.dart';
import '../entities/provider_profile.dart';
import '../entities/service_intent.dart';

/// Clean Architecture Use Case: Ranks providers using InDrive multi-criteria affinity scoring.
///
/// Implements a multi-criteria decision algorithm weighting budget affinity (35%),
/// historical reliability (22%), geographical proximity (18%), rating (15%),
/// completed jobs experience (5%), response agility (5%), and urgency boost (5%).
class RankProvidersUseCase {
  const RankProvidersUseCase();

  /// Default baseline budget for a given service role in PKR.
  static int defaultBudgetForRole(String role) {
    return switch (role.toLowerCase()) {
      'electrician' => 700,
      'plumber' => 600,
      'ac repair' => 1200,
      'cleaning' => 900,
      'tutor' => 800,
      'beautician' => 1500,
      _ => 600,
    };
  }

  /// Resolves the currently active InDrive offer based on explicit offer or intent budget.
  int resolveActiveOffer({int? userOffer, ServiceIntent? intent}) {
    if (userOffer != null) return userOffer;
    if (intent?.userBudget != null) return intent!.userBudget!;
    return defaultBudgetForRole(intent?.role ?? 'General');
  }

  /// Multi-criteria provider ranking algorithm.
  List<UstaadProviderProfile> execute({
    required List<UstaadProviderProfile> providers,
    required ServiceIntent intent,
    int? offer,
  }) {
    final targetBudget = offer ?? intent.userBudget ?? defaultBudgetForRole(intent.role);
    final matching = providers
        .where((provider) =>
            intent.role == 'General' || provider.role == intent.role)
        .toList();
    final pool = matching.isEmpty ? providers : matching;

    final scored = pool.map((provider) {
      // InDrive Budget Match Affinity (35% weight)
      final priceDiff = provider.price - targetBudget;
      double budgetAffinity;
      String matchTag;
      if (priceDiff <= 0) {
        budgetAffinity = 100.0;
        final savings = targetBudget - provider.price;
        matchTag = savings > 0 ? '${formatPkr(savings)} below offer' : 'Exact match';
      } else if (priceDiff <= 150) {
        budgetAffinity = 80.0;
        matchTag = 'Counter: +${formatPkr(priceDiff)}';
      } else if (priceDiff <= 350) {
        budgetAffinity = 55.0;
        matchTag = 'Counter: +${formatPkr(priceDiff)}';
      } else {
        budgetAffinity = math.max(0, 100 - (priceDiff / 10)).toDouble();
        matchTag = 'Rate: ${formatPkr(provider.price)}';
      }
      final budgetScore = budgetAffinity * 0.35;

      final reliability = provider.reliability * 100 * 0.22;
      final distance = math.max(0, 20 - provider.distanceKm) / 20 * 100 * 0.18;
      final rating = provider.rating / 5 * 100 * 0.15;
      final experience = math.min(provider.jobsCompleted, 250) / 250 * 5;
      final response = math.max(0, 45 - provider.responseTimeMinutes) / 45 * 5;
      final urgencyBoost =
          intent.urgency == 'High' && provider.reliability >= 0.90 ? 5 : 0;
      final score = budgetScore +
          reliability +
          distance +
          rating +
          experience +
          response +
          urgencyBoost;
      final reason =
          '$matchTag · ${provider.distanceKm} km · ${provider.rating}★ (${provider.jobsCompleted} jobs)';
      return provider.withScore(score, reason);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored;
  }
}
