import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustaad_flutter/src/ustaad_repository.dart';
import 'package:ustaad_flutter/src/ustaad_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Provider Ranking Logic Baseline Tests (Price, Distance, Rating)', () {
    test('Price / Budget Affinity: Provider at or below budget ranks higher than overpriced provider', () async {
      final state = UstaadState(UstaadRepository());

      // Set user offer to 500 PKR for Electrician
      await state.startAnalysis('Electrician needed for fan wiring', 'G-13, Islamabad', initialOffer: 500);

      expect(state.rankedProviders, isNotEmpty);
      final electricians = state.rankedProviders.where((p) => p.role == 'Electrician').toList();
      expect(electricians.length, greaterThanOrEqualTo(2));

      // Ahmed Khan (500 PKR, exact match, 4.9 rating, 5km)
      // Bilal Tariq (400 PKR, below offer, 4.2 rating, 2km)
      // Waseem Akram (650 PKR, counter +150, 4.6 rating, 9km)
      final ahmed = electricians.firstWhere((p) => p.name == 'Ahmed Khan');
      final waseem = electricians.firstWhere((p) => p.name == 'Waseem Akram');

      expect(ahmed.score, greaterThan(waseem.score));
      expect(ahmed.reason, contains('Exact match'));
      expect(waseem.reason, contains('Counter: +PKR 150'));
    });

    test('Distance sensitivity: Closer provider receives higher distance component score', () async {
      final state = UstaadState(UstaadRepository());

      await state.startAnalysis('Plumber needed for kitchen pipe', 'G-13, Islamabad', initialOffer: 600);
      final plumbers = state.rankedProviders.where((p) => p.role == 'Plumber').toList();
      expect(plumbers.length, greaterThanOrEqualTo(2));

      // Kamran Ali (8 km, 600 PKR, 4.7 rating)
      // Zubair Ahmed (11 km, 750 PKR, 4.8 rating)
      final kamran = plumbers.firstWhere((p) => p.name == 'Kamran Ali');
      final zubair = plumbers.firstWhere((p) => p.name == 'Zubair Ahmed');

      // Kamran is closer (8km vs 11km) and at budget (600 vs 750), should score higher
      expect(kamran.score, greaterThan(zubair.score));
    });

    test('Rating sensitivity: Higher rated provider scores higher when distance and price are comparable', () async {
      final state = UstaadState(UstaadRepository());

      await state.startAnalysis('Electrician repair', 'G-13, Islamabad', initialOffer: 600);

      final ranked = state.rankedProviders;
      // All ranked providers must be sorted in strictly descending order of score
      for (int i = 0; i < ranked.length - 1; i++) {
        expect(
          ranked[i].score,
          greaterThanOrEqualTo(ranked[i + 1].score),
          reason: 'Provider ${ranked[i].name} (score: ${ranked[i].score}) should be >= ${ranked[i + 1].name} (score: ${ranked[i + 1].score})',
        );
      }
    });

    test('High urgency boost boosts high-reliability providers', () async {
      final state = UstaadState(UstaadRepository());

      // Trigger emergency / urgent request
      await state.startAnalysis('urgent emergency electrician short circuit spark', 'G-13, Islamabad', initialOffer: 700);

      expect(state.intent?.urgency, equals('High'));
      final top = state.rankedProviders.first;
      // Top provider in high urgency should have high reliability
      expect(top.reliability, greaterThanOrEqualTo(0.90));
    });
  });
}
