import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Service that orchestrates communication with Google Gemini for intelligent
/// multilingual intent extraction and conversational booking assistance.
class GeminiService {
  GeminiService({String? initialApiKey}) {
    _apiKey = initialApiKey ??
        const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  }

  String _apiKey = '';
  GenerativeModel? _model;
  GenerativeModel? _chatModel;

  String get apiKey => _apiKey;
  bool get isConfigured => _apiKey.trim().isNotEmpty;

  /// Initializes the service from stored preferences or environment.
  Future<void> initialize() async {
    if (_apiKey.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('ustaad_gemini_api_key') ?? '';
    }

    if (_apiKey.isNotEmpty) {
      _initModels();
    }
  }

  /// Sets or updates the Gemini API key at runtime.
  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ustaad_gemini_api_key', _apiKey);
    _initModels();
  }

  void _initModels() {
    if (_apiKey.isEmpty) {
      _model = null;
      _chatModel = null;
      return;
    }

    // Use gemini-1.5-flash for ultra-fast, low-latency multilingual extraction
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
      systemInstruction: Content.system(
        'You are an expert AI service triage agent for "Ustaad", Pakistan\'s premier '
        'home service platform. You understand Urdu, Roman Urdu, and English fluently. '
        'Your goal is to parse user service requests into structured JSON containing: '
        '"role" (one of: Electrician, Plumber, AC Repair, Cleaning, Tutor, Beautician, General), '
        '"description" (concise English summary of the issue), '
        '"urgency" ("High" if emergency/water leak/sparking/no electricity/urgent, else "Normal"), '
        '"location" (extracted neighborhood/sector/city, or fallback to the provided location), '
        '"timeLabel" (e.g. "Immediate", "Today afternoon", "Tomorrow morning"), '
        '"language" (e.g. "Urdu", "Roman Urdu", "English"), '
        '"confidence" (number between 0.8 and 1.0), '
        '"reasoningSteps" (list of 3-4 short strings describing your analysis steps).',
      ),
    );

    _chatModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
      ),
      systemInstruction: Content.system(
        'You are Ustaad AI, a helpful, polite, and culturally aware home services assistant '
        'in Pakistan. You communicate fluently in English, Urdu (both native script and Roman Urdu), '
        'and code-switched Pakistani speech. '
        'You help users diagnose problems in their homes (electrical issues, plumbing leaks, AC cooling, '
        'deep cleaning, home tutoring, bridal makeup), give immediate safety tips when appropriate, '
        'and recommend the right certified technician on the Ustaad platform. '
        'Keep your answers concise, empathetic, and actionable.',
      ),
    );
  }

  /// Analyzes natural language problem description using Gemini and returns a [ServiceIntent].
  /// If the API is unconfigured or encounters an error, seamlessly falls back to [localFallback].
  Future<ServiceIntent> extractIntent({
    required String problemText,
    required String fallbackLocation,
    required ServiceIntent localFallback,
    List<String>? reasoningStepsOut,
  }) async {
    if (!isConfigured || _model == null) {
      return localFallback;
    }

    try {
      final prompt = jsonEncode({
        'user_request': problemText,
        'current_location': fallbackLocation,
      });

      final response = await _model!.generateContent([Content.text(prompt)]);
      final rawJson = response.text;
      if (rawJson == null || rawJson.trim().isEmpty) {
        return localFallback;
      }

      final parsed = jsonDecode(rawJson);
      if (parsed is! Map<String, dynamic>) {
        return localFallback;
      }

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

      return ServiceIntent(
        role: role,
        description: description,
        urgency: urgency,
        location: location,
        timeLabel: timeLabel,
        language: language,
        confidence: confidence,
      );
    } catch (e) {
      debugPrint('Gemini extraction fallback: $e');
      return localFallback;
    }
  }

  /// Generates a conversational assistant response for the AI Chat screen.
  Future<String> sendChatMessage({
    required List<AIChatMessage> history,
    required String userMessage,
  }) async {
    if (!isConfigured || _chatModel == null) {
      return _generateOfflineChatResponse(userMessage);
    }

    try {
      final contents = <Content>[];
      // Include recent history (up to last 6 turns)
      final recent = history.length > 6 ? history.sublist(history.length - 6) : history;
      for (final msg in recent) {
        contents.add(
          msg.isUser
              ? Content.text(msg.text)
              : Content.model([TextPart(msg.text)]),
        );
      }
      contents.add(Content.text(userMessage));

      final response = await _chatModel!.generateContent(contents);
      return response.text ?? _generateOfflineChatResponse(userMessage);
    } catch (e) {
      debugPrint('Gemini chat fallback: $e');
      return _generateOfflineChatResponse(userMessage);
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
