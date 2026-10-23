/// Domain Entity representing an itemized quote estimate and InDrive bargaining delta.
class QuoteEstimate {
  const QuoteEstimate({
    required this.basePrice,
    required this.distancePrice,
    required this.urgencyPrice,
    this.userOffer,
  });

  final int basePrice;
  final int distancePrice;
  final int urgencyPrice;
  final int? userOffer;

  int get total => basePrice + distancePrice + urgencyPrice;
  bool get isWithinOffer => userOffer != null && basePrice <= userOffer!;
  int get differenceWithOffer => userOffer == null ? 0 : basePrice - userOffer!;

  QuoteEstimate copyWith({
    int? basePrice,
    int? distancePrice,
    int? urgencyPrice,
    int? userOffer,
  }) {
    return QuoteEstimate(
      basePrice: basePrice ?? this.basePrice,
      distancePrice: distancePrice ?? this.distancePrice,
      urgencyPrice: urgencyPrice ?? this.urgencyPrice,
      userOffer: userOffer ?? this.userOffer,
    );
  }
}
