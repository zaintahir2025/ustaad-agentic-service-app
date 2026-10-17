import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustaad_flutter/src/ai_engine_router.dart';
import 'package:ustaad_flutter/src/models.dart';

void main() {
  group('Live AI Engine & Fallback Comprehensive Verification', () {
    late String openRouterKey;

    setUpAll(() async {
      // Read key from .env file directly for this live verification
      openRouterKey = '';
      final envFile = File('.env');
      if (await envFile.exists()) {
        final lines = await envFile.readAsLines();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('OPENROUTER_API_KEY=')) {
            openRouterKey = trimmed.substring('OPENROUTER_API_KEY='.length).trim();
            break;
          }
        }
      }
    });

    test('OpenRouter API key format validation (when configured)', () {
      if (openRouterKey.isNotEmpty) {
        expect(openRouterKey.startsWith('sk-or-v1-'), isTrue);
      }
    });

    test('Rung 1: Live Cloud AI successfully extracts structured intent and validates schema', () async {
      if (openRouterKey.isEmpty) return;

      final router = AIEngineRouter(apiKey: openRouterKey);
      expect(router.hasCloudKey, isTrue);

      const localFallback = ServiceIntent(
        role: 'General',
        description: 'Fallback description',
        urgency: 'Normal',
        location: 'Islamabad',
        timeLabel: 'Normal',
        language: 'English',
        confidence: 0.5,
      );

      final result = await router.executeIntentLadder(
        problemText: 'Hamare ghar ka AC cooling nahi kar raha aur garam hawa de raha hai',
        fallbackLocation: 'F-7, Islamabad',
        localFallback: localFallback,
      );

      // Verify that Cloud AI successfully resolved this
      expect(result.resolvedEngine, equals(AIEngineType.openRouterCloud));
      expect(result.intent.role, equals('AC Repair'));
      expect(result.intent.urgency, isIn(['High', 'Normal']));
      expect(result.intent.description, isNotEmpty);
      expect(result.intent.confidence, greaterThanOrEqualTo(0.8));
      expect(result.ladderAuditLog.any((l) => l.contains('SUCCESS & VALIDATED')), isTrue);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Rung 1: Live Cloud AI handles conversational chat successfully', () async {
      if (openRouterKey.isEmpty) return;

      final router = AIEngineRouter(apiKey: openRouterKey);

      final reply = await router.executeChatLadder(
        history: const [],
        userMessage: 'Ghar ke kitchen mein paani leak ho raha hai, kya karun?',
      );

      expect(reply, isNotEmpty);
      expect(reply.length, greaterThan(20));
      // Cloud DeepSeek AI should give a helpful contextual answer
      final lower = reply.toLowerCase();
      expect(
        lower.contains('plumb') || lower.contains('valve') || lower.contains('water') || lower.contains('paani') || lower.contains('leak'),
        isTrue,
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Failover: When API key is invalid, router cascades seamlessly to Safety Net', () async {
      final invalidRouter = AIEngineRouter(apiKey: 'sk-or-v1-invalid-deadbeef');
      expect(invalidRouter.hasCloudKey, isTrue);

      const localFallback = ServiceIntent(
        role: 'Electrician',
        description: 'Breaker tripping',
        urgency: 'High',
        location: 'G-13, Islamabad',
        timeLabel: 'Immediate',
        language: 'Roman Urdu',
        confidence: 0.9,
      );

      final result = await invalidRouter.executeIntentLadder(
        problemText: 'Main switch se sparks nikal rahay hain',
        fallbackLocation: 'G-13, Islamabad',
        localFallback: localFallback,
      );

      // Must cascade past Rung 1 and Rung 2 to Rung 3 safety net
      expect(result.resolvedEngine, equals(AIEngineType.localHeuristic));
      expect(result.intent.role, equals('Electrician'));
      expect(result.ladderAuditLog.any((l) => l.contains('FAILED')), isTrue);
      expect(result.ladderAuditLog.any((l) => l.contains('Activated as safety net')), isTrue);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('Failover: Chat cascades cleanly to offline heuristic responses when key is invalid', () async {
      final invalidRouter = AIEngineRouter(apiKey: 'sk-or-v1-invalid-deadbeef');

      final acReply = await invalidRouter.executeChatLadder(
        history: const [],
        userMessage: 'AC is not cooling at all',
      );
      expect(acReply.toLowerCase(), contains('ac'));

      final electricReply = await invalidRouter.executeChatLadder(
        history: const [],
        userMessage: 'Bijli ka fuse urh gaya',
      );
      expect(electricReply.toLowerCase(), contains('electric'));

      final plumbingReply = await invalidRouter.executeChatLadder(
        history: const [],
        userMessage: 'Kitchen sink pipe is leaking water',
      );
      expect(plumbingReply.toLowerCase(), contains('plumb'));
    });
  });
}
