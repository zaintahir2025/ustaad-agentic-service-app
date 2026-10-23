import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ustaad_flutter/src/ustaad_repository.dart';

/// Lightweight custom MockHttpClient to intercept and verify Cloud Function callable HTTP requests.
class MockFunctionsHttpClient extends http.BaseClient {
  MockFunctionsHttpClient(this._handler);

  final Future<http.Response> Function(http.Request request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final httpRequest = request as http.Request;
    final response = await _handler(httpRequest);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('UstaadRepository extractServiceIntent Cloud Function Tests', () {
    test('successfully parses Cloud Function 200 result into structured ServiceIntent', () async {
      String? capturedRequestBody;

      final mockClient = MockFunctionsHttpClient((request) async {
        capturedRequestBody = request.body;
        final responsePayload = {
          'result': {
            'role': 'Plumber',
            'description': 'Kitchen Sink & Drain Leak',
            'urgency': 'High',
            'location': 'G-13, Islamabad',
            'timeLabel': 'Tomorrow morning',
            'language': 'Roman Urdu',
            'confidence': 0.98,
            'userBudget': 800,
            'reasoning': 'Extracted via Gemini 2.5 Flash Cloud Logic with multilingual code-switching.',
            'source': 'gemini-cloud',
          }
        };

        return http.Response(
          jsonEncode(responsePayload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = UstaadRepository(httpClient: mockClient);

      final intent = await repository.extractServiceIntent(
        problemText: 'kal subah kitchen sink leak ho raha hai 800 mein plumber chahiye',
        location: 'G-13, Islamabad',
        customEmulatorUrl: 'http://127.0.0.1:5001/ustaad-service-app-17d0a/us-central1/extractServiceIntent',
      );

      // Verify outgoing request payload conforms to Firebase Callable standard
      expect(capturedRequestBody, isNotNull);
      final decodedRequest = jsonDecode(capturedRequestBody!) as Map<String, dynamic>;
      expect(decodedRequest['data'], isNotNull);
      expect(decodedRequest['data']['problemText'], contains('kitchen sink'));
      expect(decodedRequest['data']['location'], equals('G-13, Islamabad'));

      // Verify extracted intent
      expect(intent.role, equals('Plumber'));
      expect(intent.description, equals('Kitchen Sink & Drain Leak'));
      expect(intent.urgency, equals('High'));
      expect(intent.timeLabel, equals('Tomorrow morning'));
      expect(intent.language, equals('Roman Urdu'));
      expect(intent.confidence, equals(0.98));
      expect(intent.userBudget, equals(800));
    });

    test('parses Urdu Nastaliq input via Cloud Function', () async {
      final mockClient = MockFunctionsHttpClient((request) async {
        final responsePayload = {
          'result': {
            'role': 'Electrician',
            'description': 'Breaker & Short Circuit Fault',
            'urgency': 'High',
            'location': 'F-10, Islamabad',
            'timeLabel': 'Immediate',
            'language': 'Urdu',
            'confidence': 0.95,
            'userBudget': 600,
            'reasoning': 'Urdu Nastaliq detected.',
            'source': 'gemini-cloud',
          }
        };

        return http.Response(
          jsonEncode(responsePayload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = UstaadRepository(httpClient: mockClient);

      final intent = await repository.extractServiceIntent(
        problemText: 'بجلی کا بریکر جلدی ٹھیک کرو 600 روپے میں',
        location: 'F-10, Islamabad',
        customEmulatorUrl: 'http://127.0.0.1:5001/ustaad-service-app-17d0a/us-central1/extractServiceIntent',
      );

      expect(intent.role, equals('Electrician'));
      expect(intent.urgency, equals('High'));
      expect(intent.language, equals('Urdu'));
      expect(intent.userBudget, equals(600));
    });

    test('validates and rejects empty problemText with ArgumentError', () async {
      final repository = UstaadRepository();

      expect(
        () => repository.extractServiceIntent(
          problemText: '   ',
          location: 'Islamabad',
        ),
        throwsArgumentError,
      );
    });

    test('falls back gracefully to domain safety net when Cloud Function endpoint returns 500', () async {
      final mockClient = MockFunctionsHttpClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final repository = UstaadRepository(httpClient: mockClient);

      // Even if cloud function fails with 500, repository falls back to local safety net seamlessly
      final intent = await repository.extractServiceIntent(
        problemText: 'urgent AC cooling issue',
        location: 'G-13, Islamabad',
        initialOffer: 1200,
        customEmulatorUrl: 'http://127.0.0.1:5001/test-fail',
      );

      expect(intent.role, equals('AC Repair'));
      expect(intent.urgency, equals('High'));
      expect(intent.userBudget, equals(1200));
    });

    test('initialOffer takes precedence when supplied', () async {
      final mockClient = MockFunctionsHttpClient((request) async {
        final responsePayload = {
          'result': {
            'role': 'Cleaning',
            'description': 'Sofa Cleaning',
            'urgency': 'Normal',
            'location': 'Islamabad',
            'timeLabel': 'Today',
            'language': 'English',
            'confidence': 0.90,
            'userBudget': 500,
          }
        };

        return http.Response(
          jsonEncode(responsePayload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = UstaadRepository(httpClient: mockClient);

      final intent = await repository.extractServiceIntent(
        problemText: 'sofa cleaning needed',
        location: 'Islamabad',
        initialOffer: 900,
        customEmulatorUrl: 'http://127.0.0.1:5001/test',
      );

      expect(intent.userBudget, equals(900));
    });
  });
}
