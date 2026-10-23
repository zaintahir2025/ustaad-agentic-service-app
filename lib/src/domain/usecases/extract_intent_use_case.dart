import '../entities/service_intent.dart';

/// Clean Architecture Use Case: Extracts structured [ServiceIntent] from raw input.
///
/// Handles multi-lingual parsing (Urdu, Roman Urdu, English), normalization,
/// service category classification, urgency assessment, temporal slot inference,
/// sector recognition, and InDrive budget extraction.
class ExtractIntentUseCase {
  const ExtractIntentUseCase();

  /// Executes natural language intent inference.
  ServiceIntent execute(
    String problem,
    String location, {
    int? initialOffer,
  }) {
    final value = normalizeSearchText(problem);
    var role = 'General';
    var description = 'General Maintenance';

    if (containsAny(value, _electricianKeywords)) {
      role = 'Electrician';
      if (containsAny(value, ['breaker', 'short circuit', 'spark', 'بریکر', 'شارٹ سرکٹ'])) {
        description = 'Breaker & Short Circuit Fault';
      } else if (containsAny(value, ['fan', 'pankha', 'پنکھا'])) {
        description = 'Ceiling Fan Service & Repair';
      } else if (containsAny(value, ['wire', 'wiring', 'تار', 'وائر'])) {
        description = 'Wiring Inspection & Repair';
      } else {
        description = 'Electrical Repair';
      }
    } else if (containsAny(value, _plumberKeywords)) {
      role = 'Plumber';
      if (containsAny(value, ['sink', 'washroom', 'toilet', 'basin', 'commode', 'سنک', 'واشروم', 'بیسن'])) {
        description = 'Washroom Sink & Plumbing Repair';
      } else if (containsAny(value, ['geyser', 'tanki', 'گیزر'])) {
        description = 'Geyser & Water Tank Maintenance';
      } else if (containsAny(value, ['drain', 'gutter', 'sewerage', 'گٹر', 'سیوریج'])) {
        description = 'Drainage & Sewerage Clearance';
      } else if (containsAny(value, ['motor', 'pump', 'موٹر', 'پمپ'])) {
        description = 'Water Pump & Motor Repair';
      } else {
        description = 'Plumbing Issue & Leak Fix';
      }
    } else if (containsAny(value, _acRepairKeywords)) {
      role = 'AC Repair';
      if (containsAny(value, ['gas', 'گیس'])) {
        description = 'AC Gas Refill & Leak Check';
      } else if (containsAny(value, ['cooling', 'thanda', 'کولنگ', 'ٹھنڈا'])) {
        description = 'AC Cooling Fault Troubleshooting';
      } else {
        description = 'AC Service & Maintenance';
      }
    } else if (containsAny(value, _cleaningKeywords)) {
      role = 'Cleaning';
      if (containsAny(value, ['sofa', 'carpet', 'صوفہ', 'کارپٹ'])) {
        description = 'Sofa & Carpet Deep Cleaning';
      } else if (containsAny(value, ['tanki', 'water tank'])) {
        description = 'Water Tank Cleaning & Sanitization';
      } else {
        description = 'Deep Cleaning Request';
      }
    } else if (containsAny(value, _tutorKeywords)) {
      role = 'Tutor';
      description = 'Tutoring Session';
    } else if (containsAny(value, _beauticianKeywords)) {
      role = 'Beautician';
      description = 'Beauty Service & Grooming';
    }

    final urgency = containsAny(value, _urgencyKeywords) ? 'High' : 'Normal';
    final timeLabel = inferTimeLabel(value);
    final language = inferLanguage(problem);
    final extractedBudget = initialOffer ?? extractBudget(problem);

    return ServiceIntent(
      role: role,
      description: description,
      urgency: urgency,
      location: location,
      timeLabel: timeLabel,
      language: language,
      confidence: role == 'General' ? 0.72 : 0.93,
      userBudget: extractedBudget,
    );
  }

  /// Extracts numeric monetary budget from natural language input.
  int? extractBudget(String text) {
    final budgetPatterns = [
      RegExp(r'(?:budget|offer|rs\.?|pkr|rupay|rupees)\s*[:=]?\s*(\d{2,6})', caseSensitive: false),
      RegExp(r'(\d{2,6})\s*(?:rs\.?|pkr|rupay|rupees|rp|mein|me|ma\b)', caseSensitive: false),
    ];

    for (final pattern in budgetPatterns) {
      final matches = pattern.allMatches(text);
      for (final m in matches) {
        final str = m.group(1);
        if (str != null) {
          final val = int.tryParse(str);
          if (val != null && val >= 50 && val <= 100000) {
            return val;
          }
        }
      }
    }
    return null;
  }

  /// Infers scheduled service time from text.
  String inferTimeLabel(String value) {
    if (containsAny(value, ['kal subah', 'tomorrow morning', 'کل صبح'])) {
      return 'Tomorrow morning';
    }
    if (containsAny(value, ['kal', 'tomorrow', 'کل'])) {
      return 'Tomorrow';
    }
    if (containsAny(value, ['aaj', 'today', 'آج'])) {
      return 'Today';
    }
    if (containsAny(value, ['raat', 'tonight', 'evening', 'رات', 'شام'])) {
      return 'Tonight';
    }
    return 'Next available slot';
  }

  /// Detects whether text is Urdu, Roman Urdu, or English.
  String inferLanguage(String value) {
    if (RegExp(r'[\u0600-\u06ff]').hasMatch(value)) return 'Urdu';
    if (containsAny(normalizeSearchText(value), _romanUrduMarkers)) {
      return 'Roman Urdu';
    }
    return 'English';
  }

  /// Normalizes and cleans Arabic/Urdu and Latin characters for robust search.
  String normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .replaceAll('\u064a', '\u06cc')
        .replaceAll('\u0649', '\u06cc')
        .replaceAll('\u0643', '\u06a9')
        .replaceAll('\u06c0', '\u06c1')
        .replaceAll('\u200c', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Checks if [value] contains any of the provided [terms].
  bool containsAny(String value, List<String> terms) {
    return terms.any(value.contains);
  }

  /// Extracts sector label (e.g. G-13, F-10, DHA) from location string.
  String sectorFromLocation(String value) {
    final match = RegExp(r'\b[A-I]-?\d{1,2}\b', caseSensitive: false).firstMatch(value);
    return match?.group(0)?.toUpperCase() ?? 'Islamabad';
  }

  static const List<String> _electricianKeywords = [
    'bijli',
    'batti',
    'electric',
    'electrician',
    'wire',
    'wiring',
    'breaker',
    'fan',
    'pankha',
    'light',
    'switch',
    'socket',
    'fuse',
    'inverter',
    'generator',
    'ups',
    'short circuit',
    'spark',
    'sparking',
    'board',
    'voltage',
    'bulb',
    'tube light',
    'chula',
    'heater',
    'main switch',
    'بجلی',
    'بتی',
    'لائٹ',
    'وائر',
    'تار',
    'بریکر',
    'پنکھا',
    'سوئچ',
    'ساکٹ',
    'فیوز',
    'یو پی ایس',
    'جنریٹر',
    'شارٹ سرکٹ',
    'بلب',
    'الیکٹریشن',
  ];

  static const List<String> _plumberKeywords = [
    'plumb',
    'plumber',
    'pani',
    'paani',
    'nal',
    'nalka',
    'leak',
    'leakage',
    'pipe',
    'drain',
    'gutter',
    'drainage',
    'sink',
    'washroom',
    'toilet',
    'commode',
    'tap',
    'toti',
    'geyser',
    'tanki',
    'water tank',
    'basin',
    'flush',
    'faucet',
    'sanitary',
    'sewerage',
    'motor',
    'water pump',
    'boring',
    'submersible',
    'fitting',
    'پانی',
    'لیک',
    'نل',
    'نلکا',
    'پائپ',
    'گٹر',
    'سنک',
    'واشروم',
    'ٹونٹی',
    'گیزر',
    'کموڈ',
    'ٹائلٹ',
    'بیسن',
    'موٹر',
    'پلمبر',
    'فلیش',
    'سیوریج',
    'سینیٹری',
    'پمپ',
  ];

  static const List<String> _acRepairKeywords = [
    'ac',
    'air conditioner',
    'cooling',
    'thanda',
    'compressor',
    'gas leak',
    'gas charge',
    'split',
    'chilled',
    'inverter ac',
    'ac service',
    'heating',
    'remote',
    'filter',
    'outdoor',
    'اے سی',
    'ایئر کنڈیشنر',
    'ٹھنڈا',
    'کولنگ',
    'کمپریسر',
    'گیس',
  ];

  static const List<String> _cleaningKeywords = [
    'clean',
    'cleaning',
    'safai',
    'safayi',
    'dust',
    'deep clean',
    'sofa',
    'carpet',
    'kitchen cleaning',
    'washroom cleaning',
    'floor cleaning',
    'mattress',
    'curtain',
    'water tank cleaning',
    'tanki safai',
    'dhulai',
    'صفائی',
    'صاف',
    'گرد',
    'دھول',
    'کارپٹ',
    'صوفہ',
    'دھلائی',
  ];

  static const List<String> _tutorKeywords = [
    'tutor',
    'teacher',
    'ustad',
    'ustaad',
    'math',
    'maths',
    'study',
    'parhai',
    'parhana',
    'tuition',
    'physics',
    'english',
    'matric',
    'fsc',
    'science',
    'استاد',
    'ٹیچر',
    'پڑھائی',
    'پڑھانا',
    'ریاضی',
    'ٹیوشن',
  ];

  static const List<String> _beauticianKeywords = [
    'beauty',
    'makeup',
    'make up',
    'salon',
    'parlour',
    'bridal',
    'mehndi',
    'haircut',
    'facial',
    'waxing',
    'manicure',
    'pedicure',
    'بیوٹی',
    'میک اپ',
    'سیلون',
    'مہندی',
    'دلہن',
    'پارلر',
  ];

  static const List<String> _urgencyKeywords = [
    'asap',
    'urgent',
    'emergency',
    'jaldi',
    'foran',
    'theek',
    'kharab',
    'toot',
    'tota',
    'leakage',
    'sparks',
    'danger',
    'فوراً',
    'جلدی',
    'خراب',
    'ٹوٹ',
  ];

  static const List<String> _romanUrduMarkers = [
    'mujhe',
    'chahiye',
    'kal',
    'subah',
    'pani',
    'bijli',
    'jaldi',
    'foran',
    'parhai',
    'ustad',
    'ustaad',
    'safai',
    'thanda',
    'raat',
    'aaj',
  ];
}
