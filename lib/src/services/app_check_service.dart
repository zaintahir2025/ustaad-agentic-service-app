import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Industrial Firebase App Check initialization service.
class AppCheckService {
  const AppCheckService._();

  static Future<void> initialize({bool isDebug = false}) async {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: isDebug
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: isDebug
            ? const AppleDebugProvider()
            : const AppleAppAttestProvider(),
        providerWeb: isDebug
            ? ReCaptchaV3Provider('recaptcha-v3-site-key-debug')
            : ReCaptchaV3Provider('6Ld_placeholder_site_key'),
      );
    } catch (e) {
      debugPrint('[AppCheckService] App Check initialization note: $e');
    }
  }
}
