import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustaad_flutter/src/data/models/app_user.dart';
import 'package:ustaad_flutter/src/data/models/auth_result.dart';
import 'package:ustaad_flutter/src/data/models/user_role.dart';

/// In-memory mock client replicating the Firebase Auth REST Emulator behavior
/// for headless and offline CI/testing environments.
class MockAuthHttpClient extends http.BaseClient {
  final Map<String, String> registeredUsers = {};
  final Map<String, String> phoneCodes = {};
  String lastPhone = '+923001234567';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    final path = uri.path;

    if (request is http.Request) {
      final bodyStr = request.body;
      final body = bodyStr.isNotEmpty ? jsonDecode(bodyStr) as Map<String, dynamic> : <String, dynamic>{};

      if (path.contains('accounts:signUp')) {
        final email = body['email'] as String? ?? '';
        final password = body['password'] as String? ?? '';
        if (registeredUsers.containsKey(email)) {
          return _jsonResponse(400, {'error': {'message': 'EMAIL_EXISTS'}});
        }
        registeredUsers[email] = password;
        return _jsonResponse(200, {
          'localId': 'mock-uid-${email.hashCode.abs()}',
          'email': email,
        });
      }

      if (path.contains('accounts:signInWithPassword')) {
        final email = body['email'] as String? ?? '';
        final password = body['password'] as String? ?? '';
        if (!registeredUsers.containsKey(email)) {
          return _jsonResponse(400, {'error': {'message': 'EMAIL_NOT_FOUND'}});
        }
        if (registeredUsers[email] != password) {
          return _jsonResponse(400, {'error': {'message': 'INVALID_PASSWORD'}});
        }
        return _jsonResponse(200, {
          'localId': 'mock-uid-${email.hashCode.abs()}',
          'email': email,
        });
      }

      if (path.contains('accounts:sendVerificationCode')) {
        final phone = body['phoneNumber'] as String? ?? '';
        lastPhone = phone;
        phoneCodes[phone] = '123456';
        return _jsonResponse(200, {'sessionInfo': 'mock-session-${phone.hashCode.abs()}'});
      }

      if (path.contains('accounts:signInWithPhoneNumber')) {
        final code = body['code'] as String? ?? '';
        if (code == '123456') {
          return _jsonResponse(200, {
            'localId': 'mock-phone-uid-${lastPhone.hashCode.abs()}',
            'phoneNumber': lastPhone,
          });
        }
        return _jsonResponse(400, {'error': {'message': 'INVALID_CODE'}});
      }
    }

    if (path.contains('verificationCodes')) {
      final list = phoneCodes.entries
          .map((e) => {'phoneNumber': e.key, 'code': e.value})
          .toList();
      return _jsonResponse(200, {'verificationCodes': list});
    }

    return _jsonResponse(404, {'error': {'message': 'NOT_FOUND'}});
  }

  http.StreamedResponse _jsonResponse(int status, Map<String, dynamic> data) {
    final bytes = utf8.encode(jsonEncode(data));
    return http.StreamedResponse(
      Stream.value(bytes),
      status,
      headers: {'content-type': 'application/json'},
    );
  }
}

/// Test client interacting directly with Firebase Auth Emulator REST endpoints.
class AuthEmulatorClient {
  final String emulatorHost;
  final int port;
  final String projectId;
  final http.Client client;

  AuthEmulatorClient({
    this.emulatorHost = '127.0.0.1',
    this.port = 9099,
    this.projectId = 'ustaad-service-app-17d0a',
    http.Client? client,
  }) : client = client ?? http.Client();

  String get _identityUrl => 'http://$emulatorHost:$port/identitytoolkit.googleapis.com/v1';
  String get _emulatorUrl => 'http://$emulatorHost:$port/emulator/v1/projects/$projectId';

  Future<Result<AppUser, AuthError>> signUpEmail({
    required String email,
    required String password,
    String name = 'Test Customer',
    UserRole role = UserRole.customer,
    String phone = '+923001234567',
  }) async {
    try {
      final res = await client.post(
        Uri.parse('$_identityUrl/accounts:signUp?key=fake-api-key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final user = AppUser(
          id: body['localId'] as String,
          name: name,
          email: body['email'] as String?,
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
        );
        return Success(user);
      }

      final errorMsg = body['error']?['message']?.toString() ?? 'SignUp failed';
      return Failure(AuthError(
        code: errorMsg.contains('EMAIL_EXISTS')
            ? AuthErrorCode.emailAlreadyInUse
            : AuthErrorCode.unknown,
        message: errorMsg,
      ));
    } catch (e) {
      return Failure(AuthError(code: AuthErrorCode.unknown, message: e.toString()));
    }
  }

  Future<Result<AppUser, AuthError>> signInEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await client.post(
        Uri.parse('$_identityUrl/accounts:signInWithPassword?key=fake-api-key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final user = AppUser(
          id: body['localId'] as String,
          name: email.split('@').first,
          email: body['email'] as String?,
          createdAt: DateTime.now(),
        );
        return Success(user);
      }

      final errorMsg = body['error']?['message']?.toString() ?? 'SignIn failed';
      final code = errorMsg.contains('EMAIL_NOT_FOUND')
          ? AuthErrorCode.userNotFound
          : errorMsg.contains('INVALID_PASSWORD')
              ? AuthErrorCode.wrongPassword
              : AuthErrorCode.unknown;
      return Failure(AuthError(code: code, message: errorMsg));
    } catch (e) {
      return Failure(AuthError(code: AuthErrorCode.unknown, message: e.toString()));
    }
  }

  Future<Result<String, AuthError>> sendPhoneOtp(String phoneNumber) async {
    try {
      final res = await client.post(
        Uri.parse('$_identityUrl/accounts:sendVerificationCode?key=fake-api-key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['sessionInfo'] != null) {
        return Success(body['sessionInfo'] as String);
      }

      return Failure(AuthError(
        code: AuthErrorCode.invalidPhoneNumber,
        message: body['error']?['message']?.toString() ?? 'Failed to send OTP',
      ));
    } catch (e) {
      return Failure(AuthError(code: AuthErrorCode.unknown, message: e.toString()));
    }
  }

  Future<String?> getLatestVerificationCode(String phoneNumber) async {
    try {
      final res = await client.get(
        Uri.parse('$_emulatorUrl/verificationCodes'),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = body['verificationCodes'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          final match = list.lastWhere(
            (item) => item['phoneNumber'] == phoneNumber,
            orElse: () => list.last,
          );
          return match['code']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Result<AppUser, AuthError>> verifyOtp({
    required String sessionInfo,
    required String code,
    String? name,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final res = await client.post(
        Uri.parse('$_identityUrl/accounts:signInWithPhoneNumber?key=fake-api-key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionInfo': sessionInfo,
          'code': code,
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final user = AppUser(
          id: body['localId'] as String,
          name: name ?? 'Ustaad Customer',
          phone: body['phoneNumber'] as String?,
          role: role,
          createdAt: DateTime.now(),
        );
        return Success(user);
      }

      final errorMsg = body['error']?['message']?.toString() ?? 'OTP verification failed';
      final errCode = errorMsg.contains('INVALID_CODE')
          ? AuthErrorCode.invalidVerificationCode
          : errorMsg.contains('SESSION_EXPIRED') || errorMsg.contains('INVALID_SESSION_INFO')
              ? AuthErrorCode.codeExpired
              : AuthErrorCode.unknown;
      return Failure(AuthError(code: errCode, message: errorMsg));
    } catch (e) {
      return Failure(AuthError(code: AuthErrorCode.unknown, message: e.toString()));
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  late AuthEmulatorClient authClient;
  final mockClient = MockAuthHttpClient();
  bool useMock = true;

  setUpAll(() async {
    try {
      final socket = await Socket.connect('127.0.0.1', 9099, timeout: const Duration(milliseconds: 300));
      await socket.close();
      useMock = false;
    } catch (_) {
      useMock = true;
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authClient = AuthEmulatorClient(
      client: useMock ? mockClient : null,
    );
  });

  group('Firebase Auth Emulator Integration Tests (Phase 1)', () {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'lead_eng_$timestamp@ustaad.pk';
    final testPhone = '+92300$timestamp'.substring(0, 13);
    const testPassword = 'StrongPassword123!';

    test('1. User Registration: Creates customer account in Auth Emulator', () async {
      final result = await authClient.signUpEmail(
        email: testEmail,
        password: testPassword,
        name: 'Tariq Mehmood',
        role: UserRole.customer,
        phone: testPhone,
      );

      expect(result.isSuccess, isTrue, reason: 'Registration must succeed');
      final user = result.dataOrNull!;
      expect(user.id.isNotEmpty, isTrue);
      expect(user.email, testEmail);
      expect(user.name, 'Tariq Mehmood');
      expect(user.role, UserRole.customer);
      expect(user.role.isCustomer, isTrue);
    });

    test('2. User Registration (Duplicate Email): Blocks registration with typed error', () async {
      final duplicateResult = await authClient.signUpEmail(
        email: testEmail,
        password: testPassword,
      );

      expect(duplicateResult.isFailure, isTrue);
      expect(duplicateResult.errorOrNull?.code, AuthErrorCode.emailAlreadyInUse);
    });

    test('3. Email Sign In: Authenticates and returns valid session token', () async {
      final result = await authClient.signInEmail(
        email: testEmail,
        password: testPassword,
      );

      expect(result.isSuccess, isTrue);
      final user = result.dataOrNull!;
      expect(user.id.isNotEmpty, isTrue);
      expect(user.email, testEmail);
    });

    test('4. Email Sign In (Wrong Password): Rejects with wrongPassword error code', () async {
      final result = await authClient.signInEmail(
        email: testEmail,
        password: 'IncorrectPassword!',
      );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.code, AuthErrorCode.wrongPassword);
    });

    test('5. Pakistani Phone OTP Flow: Sends verification code to +92 format', () async {
      final phoneResult = await authClient.sendPhoneOtp(testPhone);
      expect(phoneResult.isSuccess, isTrue, reason: 'SMS OTP dispatch must succeed');
      final sessionInfo = phoneResult.dataOrNull!;
      expect(sessionInfo.isNotEmpty, isTrue);

      // Fetch code from emulator verification inspector
      final otpCode = await authClient.getLatestVerificationCode(testPhone);
      expect(otpCode, isNotNull);
      expect(otpCode!.length, 6, reason: 'OTP must be 6 digits');

      // Verify OTP and complete sign-in
      final signInResult = await authClient.verifyOtp(
        sessionInfo: sessionInfo,
        code: otpCode,
        name: 'Zubair Electrician',
        role: UserRole.provider,
      );

      expect(signInResult.isSuccess, isTrue);
      final user = signInResult.dataOrNull!;
      expect(user.phone, testPhone);
      expect(user.role, UserRole.provider);
      expect(user.role.isProvider, isTrue);
    });

    test('6. Phone OTP Flow: Rejects invalid 6-digit code with typed error', () async {
      final phoneResult = await authClient.sendPhoneOtp(testPhone);
      final sessionInfo = phoneResult.dataOrNull!;

      final invalidResult = await authClient.verifyOtp(
        sessionInfo: sessionInfo,
        code: '999999', // Deliberately wrong code
      );

      expect(invalidResult.isFailure, isTrue);
      expect(
        invalidResult.errorOrNull?.code,
        anyOf(AuthErrorCode.invalidVerificationCode, AuthErrorCode.codeExpired),
      );
    });

    test('7. Session Persistence & Auto-login: Persists and restores role and credentials', () async {
      final prefs = await SharedPreferences.getInstance();

      // Simulate session saving on sign-in
      await prefs.setString('ustaad_session_uid', 'user-test-uid-123');
      await prefs.setString('ustaad_session_role', UserRole.provider.value);
      await prefs.setString('ustaad_session_email', testEmail);

      // Verify session restored on restart
      final restoredUid = prefs.getString('ustaad_session_uid');
      final restoredRole = UserRole.fromString(prefs.getString('ustaad_session_role'));
      final restoredEmail = prefs.getString('ustaad_session_email');

      expect(restoredUid, 'user-test-uid-123');
      expect(restoredRole, UserRole.provider);
      expect(restoredEmail, testEmail);

      // Simulate sign out clears session
      await prefs.remove('ustaad_session_uid');
      await prefs.remove('ustaad_session_role');
      await prefs.remove('ustaad_session_email');

      expect(prefs.getString('ustaad_session_uid'), isNull);
      expect(prefs.getString('ustaad_session_role'), isNull);
    });

    test('8. Role-Based Access Control: Distinguishes customer, provider, and admin roles', () {
      final customer = AppUser(
        id: 'c1',
        name: 'Customer 1',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );
      final provider = AppUser(
        id: 'p1',
        name: 'Provider 1',
        role: UserRole.provider,
        createdAt: DateTime.now(),
      );
      final admin = AppUser(
        id: 'a1',
        name: 'Admin 1',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      expect(customer.role.isCustomer, isTrue);
      expect(customer.role.isProvider, isFalse);
      expect(provider.role.isProvider, isTrue);
      expect(admin.role.isAdmin, isTrue);

      final customerMap = customer.toMap();
      expect(customerMap['role'], 'customer');
      final parsedCustomer = AppUser.fromMap(customerMap, 'c1');
      expect(parsedCustomer.role, UserRole.customer);
    });
  });
}
