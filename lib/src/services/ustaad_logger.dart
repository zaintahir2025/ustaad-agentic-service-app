import 'package:flutter/foundation.dart';

/// Industrial structured logger with automatic PII redaction.
class UstaadLogger {
  const UstaadLogger._();

  static final RegExp _phonePattern =
      RegExp(r'(\+92|0)?3[0-9]{2}[\s\-]?[0-9]{7}');
  static final RegExp _cnicPattern = RegExp(r'[0-9]{5}[\-]?[0-9]{7}[\-]?[0-9]');
  static final RegExp _emailPattern =
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');

  /// Redacts sensitive Pakistani PII (phone, CNIC, email) from log output.
  static String redact(String message) {
    var safe = message;
    safe = safe.replaceAllMapped(_phonePattern, (m) => '[REDACTED_PHONE]');
    safe = safe.replaceAllMapped(_cnicPattern, (m) => '[REDACTED_CNIC]');
    safe = safe.replaceAllMapped(_emailPattern, (m) => '[REDACTED_EMAIL]');
    return safe;
  }

  static void info(String message, [Map<String, dynamic>? metadata]) {
    final sanitized = redact(message);
    if (kDebugMode) {
      debugPrint('[INFO] $sanitized ${metadata != null ? metadata.toString() : ""}');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stack]) {
    final sanitized = redact(message);
    debugPrint('[ERROR] $sanitized: $error');
    if (stack != null && kDebugMode) {
      debugPrint(stack.toString());
    }
  }

  static void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    info('Event: $eventName', parameters);
  }
}
