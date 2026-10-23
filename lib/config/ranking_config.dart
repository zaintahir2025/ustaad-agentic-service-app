/// Configuration holding weights and normalization parameters for provider ranking.
class RankingConfig {
  /// Weight given to provider proximity / geographical distance (default 0.30 for 30%).
  final double distanceWeight;

  /// Weight given to provider customer rating (default 0.40 for 40%).
  final double ratingWeight;

  /// Weight given to provider price / budget affinity (default 0.30 for 30%).
  final double priceWeight;

  /// Maximum distance in kilometers used as a normalization boundary.
  /// A provider at or beyond this distance receives 0 proximity points.
  final double maxDistanceKm;

  /// Maximum rating scale (standard 5.0 stars).
  final double maxRating;

  /// Fallback rating for unrated or new providers (default 0.0).
  final double unratedDefaultRating;

  /// Reference ceiling price in PKR when no target budget or range is provided.
  final int referencePriceCeiling;

  const RankingConfig({
    this.distanceWeight = 0.30,
    this.ratingWeight = 0.40,
    this.priceWeight = 0.30,
    this.maxDistanceKm = 30.0,
    this.maxRating = 5.0,
    this.unratedDefaultRating = 0.0,
    this.referencePriceCeiling = 3000,
  })  : assert(distanceWeight >= 0, 'distanceWeight cannot be negative'),
        assert(ratingWeight >= 0, 'ratingWeight cannot be negative'),
        assert(priceWeight >= 0, 'priceWeight cannot be negative'),
        assert(
          distanceWeight + ratingWeight + priceWeight > 0,
          'Sum of weights must be greater than 0',
        );

  /// Default configuration: 30% distance, 40% rating, 30% price.
  static const RankingConfig defaultConfig = RankingConfig(
    distanceWeight: 0.30,
    ratingWeight: 0.40,
    priceWeight: 0.30,
  );

  /// Preset prioritizing geographical proximity (60% distance, 20% rating, 20% price).
  static const RankingConfig proximityFirst = RankingConfig(
    distanceWeight: 0.60,
    ratingWeight: 0.20,
    priceWeight: 0.20,
  );

  /// Preset prioritizing highest quality / customer ratings (20% distance, 60% rating, 20% price).
  static const RankingConfig ratingFirst = RankingConfig(
    distanceWeight: 0.20,
    ratingWeight: 0.60,
    priceWeight: 0.20,
  );

  /// Preset prioritizing affordable pricing / budget (20% distance, 20% rating, 60% price).
  static const RankingConfig budgetFirst = RankingConfig(
    distanceWeight: 0.20,
    ratingWeight: 0.20,
    priceWeight: 0.60,
  );

  /// Total sum of all three ranking weights.
  double get totalWeight => distanceWeight + ratingWeight + priceWeight;

  /// Normalized distance weight (proportion of total weight).
  double get normalizedDistanceWeight => distanceWeight / totalWeight;

  /// Normalized rating weight (proportion of total weight).
  double get normalizedRatingWeight => ratingWeight / totalWeight;

  /// Normalized price weight (proportion of total weight).
  double get normalizedPriceWeight => priceWeight / totalWeight;

  /// Creates a copy of this [RankingConfig] with the specified fields replaced.
  RankingConfig copyWith({
    double? distanceWeight,
    double? ratingWeight,
    double? priceWeight,
    double? maxDistanceKm,
    double? maxRating,
    double? unratedDefaultRating,
    int? referencePriceCeiling,
  }) {
    return RankingConfig(
      distanceWeight: distanceWeight ?? this.distanceWeight,
      ratingWeight: ratingWeight ?? this.ratingWeight,
      priceWeight: priceWeight ?? this.priceWeight,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      maxRating: maxRating ?? this.maxRating,
      unratedDefaultRating: unratedDefaultRating ?? this.unratedDefaultRating,
      referencePriceCeiling:
          referencePriceCeiling ?? this.referencePriceCeiling,
    );
  }

  @override
  String toString() =>
      'RankingConfig(distance: ${(distanceWeight * 100).toStringAsFixed(0)}%, '
      'rating: ${(ratingWeight * 100).toStringAsFixed(0)}%, '
      'price: ${(priceWeight * 100).toStringAsFixed(0)}%)';
}
