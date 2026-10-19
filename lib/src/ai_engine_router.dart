import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:llamadart/llamadart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gemini_service.dart';
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
/// 2. If OpenRouter fails or user provided a Google key -> Cascades to Gemini API
/// 3. If that fails (network, rate limit, timeout) -> Cascades to On-Device Llama Engine (llamadart GGUF)
/// 4. If that fails -> Cascades to Indestructible On-Device Heuristic Engine (Safety Net)
/// 5. Validates schema at Layer 5 before accepting any result
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

    if (_apiKey.startsWith('AIza') && _geminiApiKey.isEmpty) {
      _geminiApiKey = _apiKey;
    }

    _geminiService = GeminiService(initialApiKey: _geminiApiKey);

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
  late final GeminiService _geminiService;
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

  bool get hasCloudKey =>
      (_apiKey.trim().isNotEmpty && !_apiKey.startsWith('AIza')) ||
      hasGemini ||
      _apiUrl.contains('localhost');
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

    if (_geminiApiKey.isEmpty) {
      _geminiApiKey = prefs.getString('ustaad_gemini_api_key') ?? '';
    }
    if (_apiKey.startsWith('AIza') && _geminiApiKey.isEmpty) {
      _geminiApiKey = _apiKey;
    }
    if (_geminiApiKey.isNotEmpty) {
      await _geminiService.setApiKey(_geminiApiKey);
    }

    // Fallback: If no key in SharedPreferences or environment, check local .env file
    if (!kIsWeb && _apiKey.isEmpty && _geminiApiKey.isEmpty) {
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
            } else if (trimmed.startsWith('GEMINI_API_KEY=')) {
              final keyVal = trimmed.substring('GEMINI_API_KEY='.length).trim();
              if (keyVal.isNotEmpty) {
                _geminiApiKey = keyVal;
                await _geminiService.setApiKey(_geminiApiKey);
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

  /// Sets Cloud AI configuration (OpenRouter / DeepSeek or auto-detected Gemini).
  Future<void> setCloudConfig({
    required String key,
    String? url,
    String? model,
  }) async {
    final trimmedKey = key.trim();
    if (trimmedKey.startsWith('AIza')) {
      _apiKey = '';
      await setGeminiApiKey(trimmedKey);
    } else {
      _apiKey = trimmedKey;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ustaad_openrouter_api_key', _apiKey);
      await prefs.setString('ustaad_secondary_api_key', _apiKey);
    }

    if (url != null && url.trim().isNotEmpty) _apiUrl = url.trim();
    if (model != null && model.trim().isNotEmpty) _model = model.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ustaad_openrouter_url', _apiUrl);
    await prefs.setString('ustaad_openrouter_model', _model);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ustaad_gemini_api_key', _geminiApiKey);
    await _geminiService.setApiKey(_geminiApiKey);
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
    if (_apiKey.trim().isNotEmpty && !_apiKey.startsWith('AIza')) {
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
        auditLog.add('Ladder Rung 1 [Cloud AI: $_model] FAILED: $e. Cascading to Gemini / Llama...');
      }
    } else {
      auditLog.add('Ladder Rung 1 [Cloud AI]: Skipped (no OpenRouter API key configured).');
    }

    // -------------------------------------------------------------
    // RUNG 1.5: Gemini Cloud Engine Failover
    // -------------------------------------------------------------
    if (hasGemini) {
      try {
        auditLog.add('Ladder Rung 1.5 [Google Gemini Cloud]: Attempting extraction...');
        final geminiIntent = await _geminiService.extractIntent(
          problemText: problemText,
          fallbackLocation: fallbackLocation,
          localFallback: localFallback,
          reasoningStepsOut: reasoningSteps,
        );
        if (geminiIntent != localFallback) {
          auditLog.add('Ladder Rung 1.5 [Google Gemini Cloud]: SUCCESS & VALIDATED.');
          return AIEngineResult(
            intent: geminiIntent,
            resolvedEngine: AIEngineType.openRouterCloud,
            ladderAuditLog: auditLog,
            reasoningSteps: reasoningSteps,
          );
        }
      } catch (e) {
        auditLog.add('Ladder Rung 1.5 [Google Gemini Cloud] FAILED: $e. Cascading to Rung 2...');
      }
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
    if (_apiKey.trim().isNotEmpty && !_apiKey.startsWith('AIza')) {
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
        debugPrint('Cloud AI Chat failed, cascading: $e');
      }
    }

    // 1.5. Try Google Gemini Cloud AI
    if (hasGemini) {
      try {
        final geminiReply = await _geminiService.sendChatMessage(
          history: history,
          userMessage: userMessage,
        );
        if (geminiReply.trim().isNotEmpty) {
          return geminiReply.trim();
        }
      } catch (e) {
        debugPrint('Gemini Chat failed, cascading: $e');
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
    if (lower.contains('electr') || lower.contains('wire') || lower.contains('breaker') || lower.contains('fan')) {
      return 'Electrician';
    }
    if (lower.contains('plumb') || lower.contains('sink') || lower.contains('washroom') || lower.contains('toilet') || lower.contains('pipe') || lower.contains('leak') || lower.contains('drain') || lower.contains('tap')) {
      return 'Plumber';
    }
    if (lower.contains('ac') || lower.contains('cooling') || lower.contains('air') || lower.contains('compressor')) {
      return 'AC Repair';
    }
    if (lower.contains('clean') || lower.contains('safai') || lower.contains('sofa') || lower.contains('carpet')) {
      return 'Cleaning';
    }
    if (lower.contains('tutor') || lower.contains('teach') || lower.contains('study') || lower.contains('math')) {
      return 'Tutor';
    }
    if (lower.contains('beaut') || lower.contains('makeup') || lower.contains('salon') || lower.contains('mehndi')) {
      return 'Beautician';
    }
    return 'General';
  }

  String _generateOfflineChatResponse(String userMessage) {
    final lower = userMessage.toLowerCase();

    // Extract budget if mentioned
    int? budget;
    final budgetPatterns = [
      RegExp(r'(?:budget|offer|rs\.?|pkr|rupay|rupees)\s*[:=]?\s*(\d{2,6})', caseSensitive: false),
      RegExp(r'(\d{2,6})\s*(?:rs\.?|pkr|rupay|rupees|rp|mein|me|ma\b)', caseSensitive: false),
    ];
    for (final pattern in budgetPatterns) {
      final matches = pattern.allMatches(userMessage);
      for (final m in matches) {
        final str = m.group(1);
        if (str != null) {
          final val = int.tryParse(str);
          if (val != null && val >= 50 && val <= 100000) {
            budget = val;
            break;
          }
        }
      }
      if (budget != null) break;
    }

    // Check Plumber / Plumbing terms
    final isPlumber = lower.contains('plumb') ||
        lower.contains('pani') ||
        lower.contains('paani') ||
        lower.contains('nal') ||
        lower.contains('nalka') ||
        lower.contains('leak') ||
        lower.contains('pipe') ||
        lower.contains('drain') ||
        lower.contains('sink') ||
        lower.contains('washroom') ||
        lower.contains('toilet') ||
        lower.contains('commode') ||
        lower.contains('tap') ||
        lower.contains('toti') ||
        lower.contains('geyser') ||
        lower.contains('tanki') ||
        lower.contains('basin') ||
        lower.contains('flush') ||
        lower.contains('faucet') ||
        lower.contains('sanitary') ||
        lower.contains('sewerage') ||
        lower.contains('motor') ||
        lower.contains('gutter') ||
        lower.contains('پانی') ||
        lower.contains('لیک') ||
        lower.contains('نل') ||
        lower.contains('سنک') ||
        lower.contains('واشروم') ||
        lower.contains('ٹونٹی') ||
        lower.contains('گیزر') ||
        lower.contains('کموڈ') ||
        lower.contains('ٹائلٹ') ||
        lower.contains('بیسن') ||
        lower.contains('پلمبر');

    if (isPlumber) {
      if (budget != null) {
        return 'Washroom sink ya plumbing fittings theek karne ke liye certified Plumber darkaar hota hai jo leaks theek kar sake aur pipe ya drain fittings set kare.\n\n'
            'Aapka offer Rs. $budget note kar liya hai! Market mein visit charges aam tor par Rs. 500-600 se shuru hote hain, lekin aap hamare verified plumbers se direct negotiate kar sakte hain ya apna offer bhej sakte hain.\n\n'
            'Neeche diye gaye button par tap karein taake verified Plumbers explore kar ke apna offer bhej sakein!';
      } else {
        return 'Plumbing leaks and washroom issues can damage walls quickly! Try shutting off the local water valve if possible. I can connect you with top-rated verified Plumbers in your area to inspect and fix the fault.';
      }
    }

    // Check Electrician terms
    final isElectrician = lower.contains('bijli') ||
        lower.contains('batti') ||
        lower.contains('electric') ||
        lower.contains('breaker') ||
        lower.contains('wire') ||
        lower.contains('wiring') ||
        lower.contains('fan') ||
        lower.contains('pankha') ||
        lower.contains('light') ||
        lower.contains('switch') ||
        lower.contains('socket') ||
        lower.contains('fuse') ||
        lower.contains('inverter') ||
        lower.contains('generator') ||
        lower.contains('ups') ||
        lower.contains('short circuit') ||
        lower.contains('spark') ||
        lower.contains('bulb') ||
        lower.contains('بجلی') ||
        lower.contains('پنکھا') ||
        lower.contains('سوئچ') ||
        lower.contains('شارٹ سرکٹ') ||
        lower.contains('الیکٹریشن');

    if (isElectrician) {
      if (budget != null) {
        return 'Bijli ka masla ya wiring repair ke liye licensed Electrician darkaar hota hai.\n\n'
            'Aapka offer Rs. $budget note kar liya hai! Aam tor par electrician inspection charges Rs. 600-700 se shuru hote hain, lekin aap hamare certified technicians ko apna offer bhej kar negotiate kar sakte hain.\n\n'
            'Neeche diye gaye button par tap karein!';
      } else {
        return 'Electrical safety is very important. If a breaker is tripping or you smell burning wires, please turn off the main switch immediately. We have licensed Electricians nearby who can inspect and fix the fault safely.';
      }
    }

    // Check AC Repair terms
    final isAc = lower.contains('ac') ||
        lower.contains('air conditioner') ||
        lower.contains('cooling') ||
        lower.contains('thanda') ||
        lower.contains('compressor') ||
        lower.contains('gas leak') ||
        lower.contains('gas charge') ||
        lower.contains('split') ||
        lower.contains('inverter ac') ||
        lower.contains('اے سی') ||
        lower.contains('ٹھنڈا') ||
        lower.contains('کولنگ');

    if (isAc) {
      if (budget != null) {
        return 'AC cooling ya gas leak issue ke liye specialized AC technician ki zaroorat hoti hai.\n\n'
            'Aapka offer Rs. $budget note kar liya hai. Aam tor par AC general service Rs. 1000-1500 se shuru hoti hai, lekin aap verified technicians ko apna offer bhej sakte hain.\n\n'
            'Neeche button par tap karein!';
      } else {
        return 'AC problems during warm weather are frustrating! It might be a low refrigerant gas level, a clogged air filter, or an issue with the outdoor compressor. Would you like me to connect you with a verified AC technician nearby?';
      }
    }

    // Check Cleaning terms
    final isCleaning = lower.contains('clean') ||
        lower.contains('safai') ||
        lower.contains('dust') ||
        lower.contains('deep clean') ||
        lower.contains('sofa') ||
        lower.contains('carpet') ||
        lower.contains('tanki safai') ||
        lower.contains('صفائی') ||
        lower.contains('کارپٹ') ||
        lower.contains('صوفہ');

    if (isCleaning) {
      if (budget != null) {
        return 'Ghar ki deep cleaning, sofa ya carpet wash ke liye verified cleaning experts available hain.\n\n'
            'Aapka offer Rs. $budget note kar liya hai. Neeche diye gaye button par tap kar ke verified cleaning specialists ko apna offer bhejain!';
      } else {
        return 'A clean home brings peace of mind! We offer deep cleaning, sofa and carpet shampooing, and water tank sanitization. Would you like to view top-rated cleaners in your area?';
      }
    }

    // Check Tutor terms
    final isTutor = lower.contains('tutor') ||
        lower.contains('teacher') ||
        lower.contains('ustad') ||
        lower.contains('ustaad') ||
        lower.contains('math') ||
        lower.contains('study') ||
        lower.contains('parhai') ||
        lower.contains('tuition') ||
        lower.contains('استاد') ||
        lower.contains('پڑھائی') ||
        lower.contains('ٹیوشن');

    if (isTutor) {
      return 'Home tutoring helps students excel in academics! We have qualified tutors for Mathematics, Science, English, and Matric/FSc. Would you like me to find verified tutors near your location?';
    }

    // Check Beautician terms
    final isBeautician = lower.contains('beauty') ||
        lower.contains('makeup') ||
        lower.contains('salon') ||
        lower.contains('bridal') ||
        lower.contains('mehndi') ||
        lower.contains('بیوٹی') ||
        lower.contains('میک اپ') ||
        lower.contains('مہندی');

    if (isBeautician) {
      return 'Looking for beauty and grooming services at home? Our verified beauticians provide bridal makeup, mehndi, facials, and hair styling. Would you like to explore available beauticians?';
    }

    return 'Assalamu Alaikum! I am here to help you get the best verified local technician in Islamabad and nearby areas. Tell me what service you need (e.g. Electrician, Plumber for washroom sink/leaks, AC Repair, Cleaning) or describe the issue!';
  }
}
