import 'package:flutter_test/flutter_test.dart';
import 'package:ustaad_flutter/src/models.dart';
import 'package:ustaad_flutter/src/widgets/auth_widgets.dart';
import 'package:ustaad_flutter/src/widgets/common_widgets.dart';

void main() {
  group('Auth Utilities Tests', () {
    test('calculatePasswordStrength evaluates character variety', () {
      final weak = calculatePasswordStrength('12345');
      expect(weak.acceptable, isFalse);
      expect(weak.label, 'Weak');

      final medium = calculatePasswordStrength('Abc12345');
      expect(medium.score, greaterThanOrEqualTo(4));

      final strong = calculatePasswordStrength('Abc!12345#');
      expect(strong.acceptable, isTrue);
      expect(strong.label, 'Excellent');
    });
  });

  group('Common UI Helpers Tests', () {
    test('stars function renders correct count of stars', () {
      expect(stars(5.0), '★★★★★');
      expect(stars(3.0), '★★★☆☆');
      expect(stars(1.0), '★☆☆☆☆');
      expect(stars(0.0), '★☆☆☆☆'); // clamped to min 1
    });

    test('averageRating computes correct mean', () {
      final reviews = <ReviewRecord>[
        ReviewRecord(
          id: '1',
          bookingId: 'b1',
          providerId: 'p1',
          customerName: 'Ali',
          language: 'English',
          rating: 4,
          comment: 'Good',
          createdAt: DateTime(2026, 1, 1),
        ),
        ReviewRecord(
          id: '2',
          bookingId: 'b2',
          providerId: 'p1',
          customerName: 'Zara',
          language: 'English',
          rating: 5,
          comment: 'Great',
          createdAt: DateTime(2026, 1, 2),
        ),
      ];
      expect(averageRating(reviews), 4.5);
      expect(averageRating(const []), 0.0);
    });

    test('contentTypeFor maps extensions to MIME types', () {
      expect(contentTypeFor('photo.png'), 'image/png');
      expect(contentTypeFor('photo.webp'), 'image/webp');
      expect(contentTypeFor('photo.jpg'), 'image/jpeg');
      expect(contentTypeFor('photo.jpeg'), 'image/jpeg');
    });

    test('shortDateTime formats consistently', () {
      final dt = DateTime(2026, 5, 12, 14, 30);
      final formatted = shortDateTime(dt);
      expect(formatted, contains('5/12'));
      expect(formatted, contains('14:30'));
    });
  });
}
