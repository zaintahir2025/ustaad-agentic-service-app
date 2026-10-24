import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/auth_result.dart';
import '../models/user_role.dart';

/// Abstract contract for authentication operations.
abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;

  Future<Result<AppUser, AuthError>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Result<AppUser, AuthError>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    UserRole role = UserRole.customer,
    String city = 'Islamabad',
    String area = 'F-10',
    String address = '',
  });

  Future<Result<void, AuthError>> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthError error) onVerificationFailed,
    required void Function(AppUser user) onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
    Duration timeout = const Duration(seconds: 60),
  });

  Future<Result<AppUser, AuthError>> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
    UserRole role = UserRole.customer,
  });

  Future<Result<void, AuthError>> sendPasswordResetEmail(String email);

  Future<Result<void, AuthError>> signOut();

  Future<Result<AppUser, AuthError>> syncUserProfile(AppUser user);
}

/// Industrial-grade Firebase Authentication implementation.
class FirebaseAuthRepository implements AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final SharedPreferences? _prefs;

  AppUser? _cachedUser;

  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
  })  : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _prefs = prefs;

  @override
  AppUser? get currentUser => _cachedUser;

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) {
        _cachedUser = null;
        return null;
      }
      try {
        final doc = await _firestore.collection('users').doc(fbUser.uid).get();
        if (doc.exists && doc.data() != null) {
          _cachedUser = AppUser.fromMap(doc.data()!, fbUser.uid);
        } else {
          // Initialize fresh user profile if document does not exist yet
          final freshUser = AppUser(
            id: fbUser.uid,
            name: fbUser.displayName ?? (fbUser.email?.split('@').first ?? 'User'),
            email: fbUser.email,
            phone: fbUser.phoneNumber,
            role: UserRole.customer,
            createdAt: DateTime.now(),
          );
          await _firestore
              .collection('users')
              .doc(fbUser.uid)
              .set(freshUser.toMap(), SetOptions(merge: true));
          _cachedUser = freshUser;
        }
        return _cachedUser;
      } catch (_) {
        // Fallback to basic Firebase user info if Firestore query fails offline
        _cachedUser = AppUser(
          id: fbUser.uid,
          name: fbUser.displayName ?? 'Ustaad User',
          email: fbUser.email,
          phone: fbUser.phoneNumber,
          role: UserRole.customer,
          createdAt: DateTime.now(),
        );
        return _cachedUser;
      }
    });
  }

  @override
  Future<Result<AppUser, AuthError>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        return const Failure(AuthError(
          code: AuthErrorCode.userNotFound,
          message: 'User could not be identified after sign in.',
        ));
      }

      // Fetch Firestore profile
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      final user = doc.exists && doc.data() != null
          ? AppUser.fromMap(doc.data()!, fbUser.uid)
          : AppUser(
              id: fbUser.uid,
              name: fbUser.displayName ?? email.split('@').first,
              email: fbUser.email,
              role: UserRole.customer,
              createdAt: DateTime.now(),
            );

      _cachedUser = user;
      await _persistSession(user);
      return Success(user);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Failure(AuthError(
        code: AuthErrorCode.unknown,
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<Result<AppUser, AuthError>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    UserRole role = UserRole.customer,
    String city = 'Islamabad',
    String area = 'F-10',
    String address = '',
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        return const Failure(AuthError(
          code: AuthErrorCode.unknown,
          message: 'Account creation failed.',
        ));
      }

      final appUser = AppUser(
        id: fbUser.uid,
        name: name.trim().isNotEmpty ? name.trim() : 'Ustaad User',
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        city: city,
        area: area,
        address: address,
        createdAt: DateTime.now(),
      );

      // Save user document in Firestore users collection
      await _firestore
          .collection('users')
          .doc(fbUser.uid)
          .set(appUser.toMap(), SetOptions(merge: true));

      _cachedUser = appUser;
      await _persistSession(appUser);
      return Success(appUser);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Failure(AuthError(
        code: AuthErrorCode.unknown,
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<Result<void, AuthError>> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthError error) onVerificationFailed,
    required void Function(AppUser user) onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        timeout: timeout,
        forceResendingToken: resendToken,
        verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
          try {
            final authResult =
                await _firebaseAuth.signInWithCredential(credential);
            final fbUser = authResult.user;
            if (fbUser != null) {
              final user = await _getOrCreateUser(fbUser, phoneNumber);
              _cachedUser = user;
              await _persistSession(user);
              onVerificationCompleted(user);
            }
          } catch (e) {
            onVerificationFailed(AuthError(
              code: AuthErrorCode.unknown,
              message: e.toString(),
            ));
          }
        },
        verificationFailed: (fb_auth.FirebaseAuthException e) {
          onVerificationFailed(_mapFirebaseAuthException(e));
        },
        codeSent: (String verificationId, int? token) {
          onCodeSent(verificationId, token);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onCodeAutoRetrievalTimeout(verificationId);
        },
      );
      return const Success(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Failure(AuthError(
        code: AuthErrorCode.unknown,
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<Result<AppUser, AuthError>> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final authResult = await _firebaseAuth.signInWithCredential(credential);
      final fbUser = authResult.user;
      if (fbUser == null) {
        return const Failure(AuthError(
          code: AuthErrorCode.userNotFound,
          message: 'Unable to sign in with OTP.',
        ));
      }

      final user = await _getOrCreateUser(
        fbUser,
        fbUser.phoneNumber ?? '',
        customName: name,
        role: role,
      );

      _cachedUser = user;
      await _persistSession(user);
      return Success(user);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Failure(AuthError(
        code: AuthErrorCode.unknown,
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<Result<void, AuthError>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return const Success(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Failure(AuthError(
        code: AuthErrorCode.unknown,
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<Result<void, AuthError>> signOut() async {
    try {
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid != null) {
        // Clean FCM tokens and local session
        try {
          await _firestore.collection('users').doc(uid).update({
            'fcmTokens': FieldValue.arrayRemove([]),
          });
        } catch (_) {}
      }

      _cachedUser = null;
      await _clearPersistedSession();
      await _firebaseAuth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(AuthError(
        code: AuthErrorCode.unknown,
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Result<AppUser, AuthError>> syncUserProfile(AppUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true));
      _cachedUser = user;
      return Success(user);
    } catch (e) {
      return Failure(AuthError(
        code: AuthErrorCode.unknown,
        message: e.toString(),
      ));
    }
  }

  Future<AppUser> _getOrCreateUser(
    fb_auth.User fbUser,
    String phone, {
    String? customName,
    UserRole role = UserRole.customer,
  }) async {
    final doc = await _firestore.collection('users').doc(fbUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!, fbUser.uid);
    }

    final fresh = AppUser(
      id: fbUser.uid,
      name: customName ?? fbUser.displayName ?? 'Ustaad Customer',
      phone: phone.isNotEmpty ? phone : fbUser.phoneNumber,
      email: fbUser.email,
      role: role,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(fbUser.uid)
        .set(fresh.toMap(), SetOptions(merge: true));

    return fresh;
  }

  Future<void> _persistSession(AppUser user) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString('ustaad_session_uid', user.id);
      await prefs.setString('ustaad_session_role', user.role.value);
      if (user.email != null) {
        await prefs.setString('ustaad_session_email', user.email!);
      }
    } catch (_) {}
  }

  Future<void> _clearPersistedSession() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove('ustaad_session_uid');
      await prefs.remove('ustaad_session_role');
      await prefs.remove('ustaad_session_email');
    } catch (_) {}
  }

  AuthError _mapFirebaseAuthException(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthError(
          code: AuthErrorCode.invalidEmail,
          message: 'The email address is badly formatted.',
          originalError: e,
        );
      case 'user-not-found':
        return AuthError(
          code: AuthErrorCode.userNotFound,
          message: 'No account found with this email or phone number.',
          originalError: e,
        );
      case 'wrong-password':
      case 'invalid-credential':
        return AuthError(
          code: AuthErrorCode.wrongPassword,
          message: 'Incorrect password or invalid credentials.',
          originalError: e,
        );
      case 'email-already-in-use':
        return AuthError(
          code: AuthErrorCode.emailAlreadyInUse,
          message: 'An account already exists with this email address.',
          originalError: e,
        );
      case 'weak-password':
        return AuthError(
          code: AuthErrorCode.weakPassword,
          message: 'Password must be at least 6 characters.',
          originalError: e,
        );
      case 'invalid-phone-number':
        return AuthError(
          code: AuthErrorCode.invalidPhoneNumber,
          message: 'Please enter a valid Pakistani phone number (+923XXXXXXXXX).',
          originalError: e,
        );
      case 'invalid-verification-code':
        return AuthError(
          code: AuthErrorCode.invalidVerificationCode,
          message: 'The 6-digit OTP entered is incorrect.',
          originalError: e,
        );
      case 'session-expired':
        return AuthError(
          code: AuthErrorCode.codeExpired,
          message: 'The verification code has expired. Please request a new code.',
          originalError: e,
        );
      case 'quota-exceeded':
      case 'too-many-requests':
        return AuthError(
          code: AuthErrorCode.quotaExceeded,
          message: 'Too many requests. Please wait a few moments before trying again.',
          originalError: e,
        );
      case 'user-disabled':
        return AuthError(
          code: AuthErrorCode.userDisabled,
          message: 'This user account has been deactivated.',
          originalError: e,
        );
      default:
        return AuthError(
          code: AuthErrorCode.unknown,
          message: e.message ?? 'An unexpected authentication error occurred.',
          originalError: e,
        );
    }
  }
}
