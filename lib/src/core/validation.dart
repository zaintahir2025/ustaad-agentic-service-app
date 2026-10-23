/// Pakistani localized validation utilities for mobile phone numbers and addresses.
class PakistaniPhoneValidator {
  const PakistaniPhoneValidator._();

  /// Regex pattern matching valid Pakistani mobile operator codes:
  /// - 0300 to 0309: Jazz (Mobilink)
  /// - 0310 to 0319: Zong (CMPak)
  /// - 0320 to 0329: Jazz (Warid)
  /// - 0330 to 0337: Ufone (PTCL)
  /// - 0340 to 0349: Telenor
  /// - 0355: Special Communications Organization (SCO / Azad Kashmir & Gilgit-Baltistan)
  static final RegExp _pakistaniMobileRegex = RegExp(
    r'^(?:\+92|0092|92)?(?:0)?(3(?:[0-4][0-9]|55)[0-9]{7})$',
  );

  /// Validates whether [input] is a valid Pakistani mobile number.
  static bool isValid(String? input) {
    if (input == null || input.trim().isEmpty) return false;
    final digits = cleanDigits(input);
    return _pakistaniMobileRegex.hasMatch(digits);
  }

  /// Removes spaces, dashes, parentheses, and non-digit characters (except leading '+').
  static String cleanDigits(String input) {
    var cleaned = input.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (cleaned.startsWith('+')) {
      cleaned = '+${cleaned.replaceAll('+', '')}';
    }
    return cleaned;
  }

  /// Normalizes any valid Pakistani mobile number to standard E.164 format: `+923XXXXXXXXX`.
  ///
  /// Examples:
  /// - `03001234567` ➔ `+923001234567`
  /// - `0300-1234567` ➔ `+923001234567`
  /// - `923001234567` ➔ `+923001234567`
  /// - `00923001234567` ➔ `+923001234567`
  static String? normalize(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final cleaned = cleanDigits(input);
    final match = _pakistaniMobileRegex.firstMatch(cleaned);
    if (match == null) return null;
    final nationalDigits = match.group(1);
    if (nationalDigits == null) return null;
    return '+92$nationalDigits';
  }

  /// Formats phone number into readable national or international display format:
  /// E.g. `0300-1234567` or `+92 300 1234567`.
  static String formatDisplay(String input, {bool international = false}) {
    final normalized = normalize(input);
    if (normalized == null) return input.trim();
    final opCode = normalized.substring(3, 6); // e.g. "300"
    final rest = normalized.substring(6); // e.g. "1234567"
    if (international) {
      return '+92 $opCode $rest';
    }
    return '0$opCode-$rest';
  }

  /// Identifies the telecom network operator based on mobile prefix.
  static String detectOperator(String input) {
    final normalized = normalize(input);
    if (normalized == null) return 'Unknown';
    final prefix = normalized.substring(3, 6);
    final prefixNum = int.tryParse(prefix);
    if (prefixNum == null) return 'Unknown';

    if ((prefixNum >= 300 && prefixNum <= 309) || (prefixNum >= 320 && prefixNum <= 329)) {
      return 'Jazz';
    }
    if (prefixNum >= 310 && prefixNum <= 319) {
      return 'Zong';
    }
    if (prefixNum >= 330 && prefixNum <= 337) {
      return 'Ufone';
    }
    if (prefixNum >= 340 && prefixNum <= 349) {
      return 'Telenor';
    }
    if (prefixNum == 355) {
      return 'SCOM';
    }
    return 'Other';
  }

  /// Form field validation helper suitable for Flutter `TextFormField.validator`.
  static String? validate(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Mobile phone number is required.';
      return null;
    }
    if (!isValid(value)) {
      return 'Enter a valid Pakistani mobile number (e.g. 0300 1234567 or +923001234567).';
    }
    return null;
  }
}

/// Address validation result container.
class AddressValidationResult {
  const AddressValidationResult({
    required this.isValid,
    required this.sanitizedAddress,
    this.errorMessage,
    this.city = 'Islamabad',
    this.sector,
  });

  final bool isValid;
  final String sanitizedAddress;
  final String? errorMessage;
  final String city;
  final String? sector;
}

/// Pakistani localized address validator and parser.
class PakistaniAddressValidator {
  const PakistaniAddressValidator._();

  static const List<String> majorPakistaniCities = [
    'Islamabad',
    'Rawalpindi',
    'Lahore',
    'Karachi',
    'Peshawar',
    'Quetta',
    'Faisalabad',
    'Multan',
    'Taxila',
    'Wah Cantt',
    'Gujranwala',
    'Sialkot',
    'Abbottabad',
    'Bahawalpur',
    'Hyderabad',
    'Gujrat',
    'Sargodha',
    'Jhelum',
    'Murree',
  ];

  /// Sanitizes input address by stripping dangerous HTML tags and control characters.
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Detects whether the address belongs to a recognized Pakistani city.
  static String detectCity(String address, {String fallback = 'Islamabad'}) {
    final lower = address.toLowerCase();
    for (final city in majorPakistaniCities) {
      if (lower.contains(city.toLowerCase())) {
        return city;
      }
    }
    return fallback;
  }

  /// Extracts sector, block, or phase identifier (e.g. G-13, F-10/2, DHA Phase 2, Bahria Town Phase 4).
  static String? detectSectorOrArea(String address) {
    // Islamabad/Rawalpindi sectors: e.g. G-13, G-13/2, F-10, I-8/4, D-12
    final sectorMatch = RegExp(
      r'\b([A-I]-?\d{1,2}(?:/\d)?)\b',
      caseSensitive: false,
    ).firstMatch(address);
    if (sectorMatch != null) {
      return sectorMatch.group(1)?.toUpperCase();
    }

    // DHA / Bahria / Model Town / Gulberg / Saddar phases
    final areaMatch = RegExp(
      r'\b(DHA\s+Phase\s+\d+|Bahria\s+Town(?:\s+Phase\s+\d+)?|Gulberg(?:\s+[I|V|X]+)?|Model\s+Town|Saddar|Satellite\s+Town|Blue\s+Area)\b',
      caseSensitive: false,
    ).firstMatch(address);
    if (areaMatch != null) {
      return areaMatch.group(1);
    }

    return null;
  }

  /// Validates a Pakistani address string.
  static AddressValidationResult validate(String? input, {int minLength = 5, int maxLength = 300}) {
    if (input == null || input.trim().isEmpty) {
      return const AddressValidationResult(
        isValid: false,
        sanitizedAddress: '',
        errorMessage: 'Address is required.',
      );
    }

    // Reject malicious script tags or SQL injection patterns
    final rawLower = input.toLowerCase();
    if (rawLower.contains('<script') || rawLower.contains('javascript:') || rawLower.contains('onerror=') || rawLower.contains('drop table')) {
      return AddressValidationResult(
        isValid: false,
        sanitizedAddress: sanitize(input),
        errorMessage: 'Address contains prohibited or invalid characters.',
      );
    }

    final sanitized = sanitize(input);

    if (sanitized.length < minLength) {
      return AddressValidationResult(
        isValid: false,
        sanitizedAddress: sanitized,
        errorMessage: 'Address is too short. Please include street, sector/area, or house details (minimum $minLength characters).',
      );
    }

    if (sanitized.length > maxLength) {
      return AddressValidationResult(
        isValid: false,
        sanitizedAddress: sanitized,
        errorMessage: 'Address exceeds maximum length of $maxLength characters.',
      );
    }

    final city = detectCity(sanitized);
    final sector = detectSectorOrArea(sanitized);

    return AddressValidationResult(
      isValid: true,
      sanitizedAddress: sanitized,
      city: city,
      sector: sector,
    );
  }

  /// Form field validation helper suitable for Flutter `TextFormField.validator`.
  static String? formFieldValidator(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Address is required.';
      return null;
    }
    final result = validate(value);
    return result.isValid ? null : result.errorMessage;
  }
}
