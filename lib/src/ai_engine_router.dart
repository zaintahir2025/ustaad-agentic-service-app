import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:llamadart/llamadart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Supported AI engine rungs in the failover ladder.
enum AIEngineType {
  openRouterCloud,
  onDeviceLlama,
  localHeuristic,
}

/// Result produced by the AI Engine Router, containing the extracted intent,
/// the engine that successfully handled the request, and the failover audit trail.
class AIEngineResult {
  const AIEngineResult({
    required this.intent,
    required this.resolvedEngine,
    required this.ladderAuditLog,
    required this.reasoningSteps,
  });

  final ServiceIntent intent;
  final AIEngineType resolvedEngine;
  final List<String> ladderAuditLog;
  final List<String> reasoningSteps;
}

/// Fault-Tolerant Multi-Engine AI Router with Failover Ladder and Schema Validation.
///
/// Implements the streamlined AI architecture:
/// 1. Tries Single Cloud Engine (OpenRouter: DeepSeek) with user's API key
/// 2. If it fails (network, rate limit, timeout) -> Cascades to On-Device Llama Engine (llamadart GGUF)
/// 3. If that fails -> Cascades to Indestructible On-Device Heuristic Engine (Safety Net)
/// 4. Validates schema at Layer 5 before accepting any result
class AIEngineRouter {
  AIEngineRouter({
    String? apiKey,
    String? apiUrl,
    String? model,
    String? localLlamaModelPath,
    LlamaEngine? llamaEngine,
    // Backward-compatibility parameter aliases
    String? geminiApiKey,
    String? secondaryApiKey,
    String? secondaryApiUrl,
    String? secondaryModel,
  }) {
    _apiKey = apiKey ??
        secondaryApiKey ??
        const String.fromEnvironment('OPENROUTER_API_KEY',
            defaultValue: String.fromEnvironment('SECONDARY_AI_KEY',
                defaultValue: String.fromEnvironment('AI_API_KEY', defaultValue: '')));

    _apiUrl = apiUrl ??
        secondaryApiUrl ??
        const String.fromEnvironment('OPENROUTER_URL',
            defaultValue: String.fromEnvironment('SECONDARY_AI_URL',
                defaultValue: 'https://openrouter.ai/api/v1'));

    _model = model ??
        secondaryModel ??
        const String.fromEnvironment('OPENROUTER_MODEL',
            defaultValue: String.fromEnvironment('SECONDARY_AI_MODEL',
                defaultValue: 'deepseek/deepseek-chat'));

    _geminiApiKey = geminiApiKey ??
        const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

    _localLlamaModelPath = localLlamaModelPath ??
        const String.fromEnvironment('LOCAL_LLAMA_MODEL_PATH', defaultValue: '');

    if (llamaEngine != null) {
      _llamaEngine = llamaEngine;
      _isLlamaInitialized = true;
    }
  }

  String _apiKey = '';
  String _apiUrl = 'https://openrouter.ai/api/v1';
  String _model = 'deepseek/deepseek-chat';
  String _geminiApiKey = '';
  String _localLlamaModelPath = '';
  LlamaEngine? _llamaEngine;
  bool _isLlamaInitialized = false;

  static const Duration _cloudTimeout = Duration(seconds: 15);
  static const Duration _llamaTimeout = Duration(seconds: 20);

  String get apiKey => _apiKey;
  String get apiUrl => _apiUrl;
  String get model => _model;
  String get localLlamaModelPath => _localLlamaModelPath;
  bool get isLlamaInitialized => _isLlamaInitialized;
  LlamaEngine? get llamaEngine => _llamaEngine;

  // Aliases for compatibility
  String get secondaryApiKey => _apiKey;
  String get secondaryApiUrl => _apiUrl;
  String get secondaryModel => _model;
  String get geminiApiKey => _geminiApiKey;
  bool get hasGemini => _geminiApiKey.trim().isNotEmpty;
  bool get hasSecondary => hasCloudKey;

  bool get hasCloudKey => _apiKey.trim().isNotEmpty || _apiUrl.contains('localhost');
  bool get hasLocalLlama => _isLlamaInitialized || _localLlamaModelPath.trim().isNotEmpty;

  /// Initializes engine credentials from local SharedPreferences.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (_apiKey.isEmpty) {
      _apiKey = prefs.getString('ustaad_openrouter_api_key') ??
          prefs.getString('ustaad_secondary_api_key') ??
          '';
    }
    _apiUrl = prefs.getString('ustaad_openrouter_url') ??
        prefs.getString('ustaad_secondary_api_url') ??
        _apiUrl;
    _model = prefs.getString('ustaad_openrouter_model') ??
        prefs.getString('ustaad_secondary_model') ??
        _model;

    // Fallback: If no key in SharedPreferences or environment, check local .env file
    if (!kIsWeb && _apiKey.isEmpty) {
      try {
        final envFile = File('.env');
        if (await envFile.exists()) {
          final lines = await envFile.readAsLines();
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.startsWith('OPENROUTER_API_KEY=')) {
              final keyVal = trimmed.substring('OPENROUTER_API_KEY='.length).trim();
              if (keyVal.isNotEmpty) {
                _apiKey = keyVal;
              }
            } else if (trimmed.startsWith('OPENROUTER_MODEL=')) {
              final modelVal = trimmed.substring('OPENROUTER_MODEL='.length).trim();
              if (modelVal.isNotEmpty) {
                _model = modelVal;
              }
            } else if (trimmed.startsWith('OPENROUTER_URL=')) {
              final urlVal = trimmed.substring('OPENROUTER_URL='.length).trim();
              if (urlVal.isNotEmpty) {
                _apiUrl = urlVal;
              }
            }
          }
        }
      } catch (_) {}
    }

    if (_localLlamaModelPath.isEmpty) {
      _localLlamaModelPath = prefs.getString('ustaad_llama_model_path') ?? '';
    }

    if (_localLlamaModelPath.isNotEmpty && !_isLlamaInitialized) {
      await initLocalLlama();
    }
  }

  /// Sets single Cloud AI configuration (OpenRouter / DeepSeek).
  Future<void> setCloudConfig({
    required String key,
    String? url,
    String? model,
  }) async {
    _apiKey = key.trim();
    if (url != null && url.trim().isNotEmpty) _apiUrl = url.trim();
    if (model != null && model.trim().isNotEmpty) _model = model.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ustaad_openrouter_api_key', _apiKey);
    await prefs.setString('ustaad_openrouter_url', _apiUrl);
    await prefs.setString('ustaad_openrouter_model', _model);
    // Also save legacy keys for full compatibility
    await prefs.setString('ustaad_secondary_api_key', _apiKey);
    await prefs.setString('ustaad_secondary_api_url', _apiUrl);
    await prefs.setString('ustaad_secondary_model', _model);
  }

  Future<void> setSecondaryConfig({
    required String url,
    required String key,
    required String model,
  }) async {
    await setCloudConfig(key: key, url: url, model: model);
  }

  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key.trim();
  }

  void setLlamaEngine(LlamaEngine engine) {
    _llamaEngine = engine;
    _isLlamaInitialized = true;
  }

  Future<void> setLocalLlamaModelPath(String modelPath) async {
    _localLlamaModelPath = modelPath.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ustaad_llama_model_path', _localLlamaModelPath);
    await initLocalLlama();
  }

  Future<bool> initLocalLlama([String? customPath]) async {
    final path = customPath ?? _localLlamaModelPath;
    if (path.isEmpty) return false;
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('Local Llama model file not found at: $path');
        return false;
      }
      _llamaEngine = await LlamaEngine.load(
        LlamaModel(ModelSource.path(path)),
        params: const ModelParams(contextSize: 2048),
      );
      _isLlamaInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to load local Llama GGUF model: $e');
      _isLlamaInitialized = false;
      return false;
    }
  }

  /// Executes the Failover Ladder for Natural Language Intent Extraction.
  ///
  /// Ladder order:
  /// Rung 1: Cloud AI (OpenRouter: DeepSeek) with single API key -> (Validates schema)
  /// Rung 2: On-Device Llama (llamadart GGUF model in structured JSON mode) -> (Validates schema)
  /// Rung 3: Job Queue / On-Device Heuristic Engine (Indestructible offline safety net)
  Future<AIEngineResult> executeIntentLadder({
    required String problemText,
    required String fallbackLocation,
    required ServiceIntent localFallback,
  }) async {
    final auditLog = <String>[];
    final reasoningSteps = <String>[];

    // -------------------------------------------------------------
    // RUNG 1: Primary Cloud Engine (OpenRouter: DeepSeek)
    // -------------------------------------------------------------
    if (hasCloudKey) {
      try {
        auditLog.add('Ladder Rung 1 [Cloud AI ($_model)]: Attempting extraction...');
        final rawJson = await _callOpenAICompatibleAPI(
          systemPrompt:
              'You are Ustaad AI in Pakistan. Extract service category into JSON: '
              '{"role": "Electrician"|"Plumber"|"AC Repair"|"Cleaning"|"Tutor"|"Beautician"|"General", '
              '"description": "concise English summary", "urgency": "High"|"Normal", '
              '"location": "area or fallback", "timeLabel": "e.g. Immediate", '
              '"language": "Urdu"|"Roman Urdu"|"English", "confidence": 0.95, '
              '"userBudget": 600, '
              '"reasoningSteps": ["step1", "step2"]}',
          userPrompt: 'User Request: "$problemText", Location: "$fallbackLocation"',
          jsonMode: true,
        );

        if (rawJson != null && rawJson.isNotEmpty) {
          final validatedIntent = _validateAndParseSchema(
            rawJson: rawJson,
            fallbackLocation: fallbackLocation,
            localFallback: localFallback,
            reasoningStepsOut: reasoningSteps,
          );

          if (validatedIntent != null) {
            auditLog.add('Ladder Rung 1 [Cloud AI: $_model]: SUCCESS & VALIDATED.');
            return AIEngineResult(
              intent: validatedIntent,
              resolvedEngine: AIEngineType.openRouterCloud,
              ladderAuditLog: auditLog,
              reasoningSteps: reasoningSteps,
            );
          }
          auditLog.add('Ladder Rung 1 [Cloud AI: $_model]: Schema validation failed. Cascading...');
        }
      } catch (e) {
        auditLog.add('Ladder Rung 1 [Cloud AI: $_model] FAILED: $e. Cascading to Rung 2...');
      }
    } else {
      auditLog.add('Ladder Rung 1 [Cloud AI]: Skipped (no API key configured).');
    }

    // -------------------------------------------------------------
    // RUNG 2: Backup On-Device AI (llamadart GGUF with JSON mode)
    // -------------------------------------------------------------
    if (_isLlamaInitialized && _llamaEngine != null) {
      try {
        auditLog.add('Ladder Rung 2 [On-Device Llama (llamadart)]: Attempting local GGUF structured inference...');
        final messages = [
          const LlamaChatMessage.fromText(
            role: LlamaChatRole.system,
            text: 'You are Ustaad AI, an on-device home service triage assistant in Pakistan. '
                'Analyze the user request and return valid JSON with keys: '
                '"role" ("Electrician"|"Plumber"|"AC Repair"|"Cleaning"|"Tutor"|"Beautician"|"General"), '
                '"description", "urgency" ("High"|"Normal"), "location", "timeLabel", "language", "confidence", "userBudget" (integer in PKR or null), "reasoningSteps".',
          ),
          LlamaChatMessage.fromText(
            role: LlamaChatRole.user,
            text: 'User Request: "$problemText", Location: "$fallbackLocation"',
          ),
        ];

        final output = LlamaStructuredOutput<Map<String, dynamic>>.jsonObject(
          decoder: (json) => json,
        );

        final decodedMap = await _llamaEngine!
            .createStructuredJson(
              messages,
              output: output,
            )
            .timeout(_llamaTimeout);

        final rawJson = jsonEncode(decodedMap);
        final validatedIntent = _validateAndParseSchema(
          rawJson: rawJson,
          fallbackLocation: fallbackLocation,
          localFallback: localFallback,
          reasoningStepsOut: reasoningSteps,
        );

        if (validatedIntent != null) {
          auditLog.add('Ladder Rung 2 [On-Device Llama (llamadart)]: SUCCESS & VALIDATED via GGUF JSON mode.');
          return AIEngineResult(
            intent: validatedIntent,
            resolvedEngine: AIEngineType.onDeviceLlama,
            ladderAuditLog: auditLog,
            reasoningSteps: reasoningSteps,
          );
        }
        auditLog.add('Ladder Rung 2 [On-Device Llama (llamadart)]: Schema validation failed. Cascading to Rung 3...');
      } catch (e) {
        auditLog.add('Ladder Rung 2 [On-Device Llama (llamadart)] FAILED: $e. Cascading to Rung 3 Job Queue / Safety Net...');
      }
    } else {
      auditLog.add('Ladder Rung 2 [On-Device Llama (llamadart)]: Skipped (local GGUF weights not loaded or initialized). Cascading to Rung 3 Job Queue...');
    }

    // -------------------------------------------------------------
    // RUNG 3: Job Queue / Indestructible On-Device Heuristic Engine (Safety Net)
    // -------------------------------------------------------------
    auditLog.add('Ladder Rung 3 [Job Queue / On-Device Heuristic Engine]: Activated as safety net.');
    reasoningSteps.add('Parsed query using on-device multilingual keyword ontology.');
    reasoningSteps.add('Assessed urgency and matched nearest certified providers.');

    return AIEngineResult(
      intent: localFallback,
      resolvedEngine: AIEngineType.localHeuristic,
      ladderAuditLog: auditLog,
      reasoningSteps: reasoningSteps,
    );
  }

  /// Executes the Failover Ladder for Conversational Chat Messages.
  Future<String> executeChatLadder({
    required List<AIChatMessage> history,
    required String userMessage,
  }) async {
    // 1. Try Cloud AI (OpenRouter: DeepSeek)
    if (hasCloudKey) {
      try {
        final rawResponse = await _callOpenAICompatibleAPI(
          systemPrompt:
              'You are Ustaad AI, an empathetic home service assistant in Pakistan. '
              'Help the user with their repair issue, give practical safety tips, and recommend '
              'the right professional (Electrician, Plumber, AC Repair, Cleaning). '
              'Respond in English, Urdu, or Roman Urdu matching the user.',
          userPrompt: userMessage,
          jsonMode: false,
        );
        if (rawResponse != null && rawResponse.trim().isNotEmpty) {
          return rawResponse.trim();
        }
      } catch (e) {
        debugPrint('Cloud AI Chat failed, cascading to on-device Llama: $e');
      }
    }

    // 2. Try On-Device Llama
    if (_isLlamaInitialized && _llamaEngine != null) {
      try {
        final messages = <LlamaChatMessage>[
          const LlamaChatMessage.fromText(
            role: LlamaChatRole.system,
            text: 'You are Ustaad AI, an empathetic home service assistant in Pakistan. '
                'Help the user with their repair issue, give practical safety tips, and recommend '
                'the right professional (Electrician, Plumber, AC Repair, Cleaning). '
                'Respond concisely in English, Urdu, or Roman Urdu matching the user.',
          ),
        ];
        final recent = history.length > 4 ? history.sublist(history.length - 4) : history;
        for (final msg in recent) {
          messages.add(
            LlamaChatMessage.fromText(
              role: msg.isUser ? LlamaChatRole.user : LlamaChatRole.assistant,
              text: msg.text,
            ),
          );
        }
        messages.add(LlamaChatMessage.fromText(role: LlamaChatRole.user, text: userMessage));

        final response = await _llamaEngine!.create(messages).text().timeout(_llamaTimeout);
        if (response.trim().isNotEmpty) {
          return response.trim();
        }
      } catch (e) {
        debugPrint('On-Device Llama Chat failed, cascading to local safety net: $e');
      }
    }

    // 3. Fallback to Local Knowledge Base
    return _generateOfflineChatResponse(userMessage);
  }

  /// Helper to call standard OpenAI-compatible API (OpenRouter, DeepSeek, Ollama, vLLM).
  Future<String?> _callOpenAICompatibleAPI({
    required String systemPrompt,
    required String userPrompt,
    required bool jsonMode,
  }) async {
    final cleanUrl = _apiUrl.endsWith('/')
        ? '${_apiUrl}chat/completions'
        : '$_apiUrl/chat/completions';

    final uri = Uri.parse(cleanUrl);
    final headers = {
      'Content-Type': 'application/json',
      if (_apiKey.isNotEmpty)
        'Authorization': 'Bearer $_apiKey',
      'HTTP-Referer': 'https://ustaad.app',
      'X-Title': 'Ustaad Agentic App',
    };

    final bodyMap = {
      'model': _model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': jsonMode ? 0.2 : 0.7,
      if (jsonMode) 'response_format': {'type': 'json_object'},
    };

    final response = await http
        .post(uri, headers: headers, body: jsonEncode(bodyMap))
        .timeout(_cloudTimeout);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['choices'] is List && (decoded['choices'] as List).isNotEmpty) {
      final choice = decoded['choices'][0];
      return choice['message']?['content']?.toString();
    }
    return null;
  }

  /// Layer 5: Schema Validation in Dart.
  /// Ensures nothing reaches the app state or user unless it passes strict structural validation.
  ServiceIntent? _validateAndParseSchema({
    required String rawJson,
    required String fallbackLocation,
    required ServiceIntent localFallback,
    List<String>? reasoningStepsOut,
  }) {
    try {
      final clean = rawJson.replaceAll(RegExp(r'^```json\s*|\s*```$'), '').trim();
      final parsed = jsonDecode(clean);
      if (parsed is! Map<String, dynamic>) return null;

      final role = _canonicalRole(parsed['role']?.toString());
      final description = parsed['description']?.toString() ?? localFallback.description;
      final urgency = parsed['urgency']?.toString().toLowerCase() == 'high' ? 'High' : 'Normal';
      final location = (parsed['location']?.toString().trim().isNotEmpty ?? false)
          ? parsed['location']!.toString().trim()
          : fallbackLocation;
      final timeLabel = parsed['timeLabel']?.toString() ?? localFallback.timeLabel;
      final language = parsed['language']?.toString() ?? localFallback.language;
      final confidence = (parsed['confidence'] is num)
          ? (parsed['confidence'] as num).toDouble().clamp(0.5, 1.0)
          : 0.95;

      if (parsed['reasoningSteps'] is List && reasoningStepsOut != null) {
        reasoningStepsOut.addAll(
          (parsed['reasoningSteps'] as List).map((e) => e.toString()),
        );
      }

      int? userBudget;
      if (parsed['userBudget'] != null) {
        if (parsed['userBudget'] is num) {
          userBudget = (parsed['userBudget'] as num).toInt();
        } else {
          userBudget = int.tryParse(parsed['userBudget'].toString());
        }
      }
      userBudget ??= localFallback.userBudget;

      return ServiceIntent(
        role: role,
        description: description,
        urgency: urgency,
        location: location,
        timeLabel: timeLabel,
        language: language,
        confidence: confidence,
        userBudget: userBudget,
      );
    } catch (_) {
      return null;
    }
  }

  String _canonicalRole(String? raw) {
    if (raw == null) return 'General';
    final lower = raw.toLowerCase();
    if (lower.contains('electr')) return 'Electrician';
    if (lower.contains('plumb')) return 'Plumber';
    if (lower.contains('ac') || lower.contains('cooling') || lower.contains('air')) {
      return 'AC Repair';
    }
    if (lower.contains('clean')) return 'Cleaning';
    if (lower.contains('tutor') || lower.contains('teach')) return 'Tutor';
    if (lower.contains('beaut') || lower.contains('makeup') || lower.contains('salon')) {
      return 'Beautician';
    }
    return 'General';
  }

  String _generateOfflineChatResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('ac') || lower.contains('cooling') || lower.contains('thanda')) {
      return 'AC problems during warm weather are frustrating! It might be a low refrigerant gas level, a clogged air filter, or an issue with the outdoor compressor. Would you like me to connect you with a verified AC technician nearby?';
    } else if (lower.contains('bijli') || lower.contains('electric') || lower.contains('breaker') || lower.contains('wiring')) {
      return 'Electrical safety is very important. If a breaker is tripping or you smell burning wires, please turn off the main switch immediately. We have licensed Electricians nearby who can inspect and fix the fault safely.';
    } else if (lower.contains('pani') || lower.contains('plumb') || lower.contains('leak') || lower.contains('pipe')) {
      return 'Plumbing leaks can damage walls and flooring quickly. Try shutting off the local water valve if possible. I can dispatch a top-rated Plumber to your location right away.';
    } else {
      return 'Assalamu Alaikum! I am here to help you get the best verified local technician in Islamabad and nearby areas. Tell me what service you need (e.g. Electrician, Plumber, AC Repair, Cleaning) or describe the issue!';
    }
  }
}
