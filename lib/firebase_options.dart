import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCTlkenSFNrD2iG3ISwhwxAqrvP4Vq1MPA',
    appId: '1:403123018094:web:f5aa29100a4a3797dfc97f',
    messagingSenderId: '403123018094',
    projectId: 'ustaad-service-app-17d0a',
    authDomain: 'ustaad-service-app-17d0a.firebaseapp.com',
    storageBucket: 'ustaad-service-app-17d0a.firebasestorage.app',
    measurementId: 'G-CF59VT7GXY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCT3-hFV6WzznUnvc1CN-BO7NbjRGhGyG8',
    appId: '1:403123018094:android:590c82eda2ab1df1dfc97f',
    messagingSenderId: '403123018094',
    projectId: 'ustaad-service-app-17d0a',
    storageBucket: 'ustaad-service-app-17d0a.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-otmWWjLHAM8biVnEI_byw9okCKb9wXQ',
    appId: '1:403123018094:ios:f90010c58d737505dfc97f',
    messagingSenderId: '403123018094',
    projectId: 'ustaad-service-app-17d0a',
    storageBucket: 'ustaad-service-app-17d0a.firebasestorage.app',
    iosBundleId: 'com.ustaad.service',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA-otmWWjLHAM8biVnEI_byw9okCKb9wXQ',
    appId: '1:403123018094:ios:55d0c632637892c7dfc97f',
    messagingSenderId: '403123018094',
    projectId: 'ustaad-service-app-17d0a',
    storageBucket: 'ustaad-service-app-17d0a.firebasestorage.app',
    iosBundleId: 'com.ustaad.ustaadFlutter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCTlkenSFNrD2iG3ISwhwxAqrvP4Vq1MPA',
    appId: '1:403123018094:web:75dcd04c27adbf48dfc97f',
    messagingSenderId: '403123018094',
    projectId: 'ustaad-service-app-17d0a',
    authDomain: 'ustaad-service-app-17d0a.firebaseapp.com',
    storageBucket: 'ustaad-service-app-17d0a.firebasestorage.app',
    measurementId: 'G-9LWXZSJLRP',
  );
}
