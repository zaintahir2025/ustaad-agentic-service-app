import 'package:flutter_test/flutter_test.dart';
import 'package:ustaad_flutter/src/ai_engine_router.dart';
import 'package:ustaad_flutter/src/gemini_service.dart';
import 'package:ustaad_flutter/src/models.dart';
import 'package:ustaad_flutter/src/ustaad_repository.dart';

void main() {
  group('GeminiService Tests', () {
    test('Unconfigured GeminiService reports isConfigured as false', () {
      final service = GeminiService(initialApiKey: '');
      expect(service.isConfigured, isFalse);
      expect(service.apiKey, isEmpty);
    });

    test('extractIntent falls back gracefully to local heuristic intent when unconfigured', () async {
      final service = GeminiService(initialApiKey: '');
      const fallback = ServiceIntent(
        role: 'Plumber',
        description: 'Water leak',
        urgency: 'High',
        location: 'G-13, Islamabad',
        timeLabel: 'Immediate',
        language: 'Roman Urdu',
        confidence: 0.85,
      );

      final intent = await service.extractIntent(
        problemText: 'Pani ka pipe leak ho gaya hai',
        fallbackLocation: 'G-13, Islamabad',
        localFallback: fallback,
      );

      expect(intent.role, equals('Plumber'));
      expect(intent.urgency, equals('High'));
      expect(intent.location, equals('G-13, Islamabad'));
    });

    test('Offline chat response provides helpful guidance for Pakistani context', () async {
      final service = GeminiService(initialApiKey: '');
      final acReply = await service.sendChatMessage(
        history: const [],
        userMessage: 'AC cooling nahi kar raha',
      );
      expect(acReply.toLowerCase(), contains('ac'));

      final electricReply = await service.sendChatMessage(
        history: const [],
        userMessage: 'Bijli ka breaker bar bar trip ho raha hai',
      );
      expect(electricReply.toLowerCase(), contains('electric'));
    });
  });

  group('Security Input Sanitization Tests', () {
    test('sanitizeInput strips control characters and trims text', () {
      const dirty = '\x00\x08  Hello Ustaad! \x1F\x7F';
      final clean = UstaadRepository.sanitizeInput(dirty);
      expect(clean, equals('Hello Ustaad!'));
    });

    test('sanitizeInput enforces maximum length constraint', () {
      final long = 'A' * 600;
      final clean = UstaadRepository.sanitizeInput(long, maxLength: 50);
      expect(clean.length, equals(50));
      expect(clean, equals('A' * 50));
    });
  });

  group('AIEngineRouter Failover Ladder Tests', () {
    test('AIEngineRouter defaults to OpenRouter and DeepSeek configuration', () {
      final router = AIEngineRouter();
      expect(router.apiUrl, equals('https://openrouter.ai/api/v1'));
      expect(router.model, equals('deepseek/deepseek-chat'));
      expect(router.hasCloudKey, isFalse);
    });

    test('AIEngineRouter executes streamlined ladder down to safety net when unconfigured',
        () async {
      final router = AIEngineRouter();
      const fallback = ServiceIntent(
        role: 'Electrician',
        description: 'Short circuit',
        urgency: 'High',
        location: 'F-10, Islamabad',
        timeLabel: 'Immediate',
        language: 'Urdu',
        confidence: 0.9,
      );

      final result = await router.executeIntentLadder(
        problemText: 'Short circuit ho gaya hai',
        fallbackLocation: 'F-10, Islamabad',
        localFallback: fallback,
      );

      expect(result.resolvedEngine, equals(AIEngineType.localHeuristic));
      expect(result.intent.role, equals('Electrician'));
      expect(result.ladderAuditLog.length, greaterThanOrEqualTo(3));

      // Verify streamlined ladder rungs appear in the audit trail
      expect(result.ladderAuditLog.any((log) => log.contains('Rung 1 [Cloud AI]')), isTrue);
      expect(result.ladderAuditLog.any((log) => log.contains('Rung 2 [On-Device Llama (llamadart)]')), isTrue);
      expect(result.ladderAuditLog.any((log) => log.contains('Rung 3 [Job Queue / On-Device Heuristic Engine]')), isTrue);
    });

    test('AIEngineRouter exposes on-device Llama GGUF configuration and initialization', () async {
      final router = AIEngineRouter();
      expect(router.localLlamaModelPath, isEmpty);
      expect(router.isLlamaInitialized, isFalse);
      expect(router.hasLocalLlama, isFalse);

      // Attempting to init with non-existent path gracefully returns false
      final success = await router.initLocalLlama('non_existent_weights.gguf');
      expect(success, isFalse);
      expect(router.isLlamaInitialized, isFalse);
    });
  });
}
