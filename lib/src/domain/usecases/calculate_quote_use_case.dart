import '../entities/provider_profile.dart';
import '../entities/quote_estimate.dart';
import '../entities/service_intent.dart';

/// Clean Architecture Use Case: Computes an itemized quote estimate.
class CalculateQuoteUseCase {
  const CalculateQuoteUseCase();

  /// Calculates itemized quote estimate for a provider and intent.
  QuoteEstimate execute({
    required UstaadProviderProfile provider,
    required ServiceIntent intent,
    int? offer,
  }) {
    final targetOffer = offer ?? intent.userBudget;
    return QuoteEstimate(
      basePrice: provider.price,
      distancePrice: provider.distanceKm * 50,
      urgencyPrice: intent.urgency == 'High' ? 500 : 0,
      userOffer: targetOffer,
    );
  }
}
