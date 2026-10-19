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
