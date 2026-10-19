import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import 'models.dart';
import 'ustaad_repository.dart';
import 'gemini_service.dart';
import 'ai_engine_router.dart';

class UstaadState extends ChangeNotifier {
  UstaadState(this._repository) {
    _authSubscription = _repository.authStateChanges.listen(_handleAuthChange);
  }

  final UstaadRepository _repository;
  final AIEngineRouter aiRouter = AIEngineRouter();
  GeminiService get geminiService => GeminiService(initialApiKey: aiRouter.geminiApiKey);
  late final StreamSubscription<auth.User?> _authSubscription;

  AIEngineType lastResolvedEngine = AIEngineType.localHeuristic;
  List<String> lastLadderAuditLog = const [];

  bool bootstrapped = false;
  bool backendOnline = false;
  bool isAnalyzing = false;
  bool chatBusy = false;
  List<AIChatMessage> chatMessages = [
    AIChatMessage(
      id: 'welcome',
      text:
          'Assalamu Alaikum! I am Ustaad AI, your intelligent booking assistant. You can describe any repair or maintenance issue in Urdu, Roman Urdu, or English, and I will recommend the right certified professional.',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];
  bool authBusy = false;
  bool bookingBusy = false;
  bool profileBusy = false;
  bool reviewBusy = false;
  String savedEmail = '';
  String? bannerMessage;
  String? pendingConfirmationEmail;
  bool passwordRecoveryActive = false;
  DateTime? authEmailCooldownUntil;
  DateTime? sessionExpiresAt;
  ThemeMode themeMode = ThemeMode.dark;
  UstaadScreen screen = UstaadScreen.gateway;
  UstaadUser? user;
  String selectedLanguage = 'English';

  Locale get currentLocale {
    final lang = (user?.preferredLanguage.isNotEmpty == true)
        ? user!.preferredLanguage
        : selectedLanguage;
    return switch (lang.toLowerCase()) {
      'urdu' => const Locale('ur'),
      'roman urdu' => const Locale('en', 'PK'),
      _ => const Locale('en'),
    };
  }

  bool get isRtl => currentLocale.languageCode == 'ur';

  List<UstaadProviderProfile> providers = UstaadRepository.seedProviders;
  List<UstaadProviderProfile> rankedProviders = const [];
  List<BookingRecord> bookings = const [];
  List<String> savedProviderIds = const [];
  List<SmartSuggestion> recentRequests = const [];
  Map<String, List<ReviewRecord>> providerReviews = const {};
  UstaadProviderProfile? selectedProvider;
  BookingRecord? latestBooking;
  ServiceIntent? intent;
  QuoteEstimate? quote;
  int? userOffer;

  int get activeOffer {
    if (userOffer != null) return userOffer!;
    if (intent?.userBudget != null) return intent!.userBudget!;
    return defaultBudgetForRole(intent?.role ?? 'General');
  }

  static int defaultBudgetForRole(String role) {
    return switch (role.toLowerCase()) {
      'electrician' => 700,
      'plumber' => 600,
      'ac repair' => 1200,
      'cleaning' => 900,
      'tutor' => 800,
      'beautician' => 1500,
      _ => 600,
    };
  }

  void setUserOffer(int amount) {
    userOffer = amount.clamp(50, 50000);
    if (intent != null) {
      rankedProviders = _rankProviders(intent!, offer: userOffer);
      if (selectedProvider != null) {
        quote = _quoteFor(selectedProvider!, intent!, offer: userOffer);
      }
    }
    notifyListeners();
  }

  void adjustUserOffer(int delta) {
    final current = activeOffer;
    setUserOffer(current + delta);
  }

  List<WorkflowEvent> workflowEvents = const [];
  String lastProblem = '';
  String lastLocation = 'G-13, Islamabad';
  bool isListening = false;
  String voiceTranscript = '';
  bool emergencyModeActive = false;
  EmergencyRequest? activeEmergency;
  List<AchievementBadge> achievements = AchievementBadge.defaultBadges();
  List<AchievementBadge> newlyUnlockedBadges = const [];
  int totalBookingsCount = 0;
  bool showMapView = false;
  bool locationSearchBusy = false;
  List<LocationSuggestion> locationSuggestions = const [];
  LocationSuggestion? activeLocation;

  bool get isSignedIn => user != null;
  bool get isDark => themeMode == ThemeMode.dark;
  bool get authEmailCoolingDown {
    final until = authEmailCooldownUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  int get authEmailCooldownSeconds {
    final until = authEmailCooldownUntil;
    if (until == null) return 0;
    return until.difference(DateTime.now()).inSeconds.clamp(0, 3600);
  }

  List<UstaadProviderProfile> get savedProviders {
    final saved = savedProviderIds.toSet();
    return providers.where((provider) => saved.contains(provider.id)).toList();
  }

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    savedEmail = prefs.getString('ustaad_user_email') ?? '';
    themeMode = (prefs.getBool('ustaad_dark_theme') ?? true)
        ? ThemeMode.dark
        : ThemeMode.light;
    savedProviderIds =
        prefs.getStringList('ustaad_saved_providers') ?? const [];
    recentRequests = (prefs.getStringList('ustaad_recent_requests') ?? const [])
        .map(_suggestionFromStoredText)
        .toList();
    totalBookingsCount = prefs.getInt('ustaad_total_bookings') ?? 0;
    selectedLanguage = prefs.getString('ustaad_selected_language') ?? 'English';
    user = _repository.currentUser();
    sessionExpiresAt = _repository.currentSessionExpiresAt();
    if (user != null) {
      user = await _repository.fetchProfile() ?? user;
      if (user!.preferredLanguage.isNotEmpty) {
        selectedLanguage = user!.preferredLanguage;
      }
      screen = UstaadScreen.commandCenter;
      await refreshBookings(silent: true);
    }
    await _repository.seedDatabaseIfEmpty();
    await refreshProviders(silent: true);
    await aiRouter.initialize();
    bootstrapped = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _handleAuthChange(auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      user = null;
      sessionExpiresAt = null;
      passwordRecoveryActive = false;
      screen = UstaadScreen.gateway;
      notifyListeners();
      return;
    }

    final current = _repository.currentUser();
    if (current == null) return;
    user = await _repository.fetchProfile() ?? current;
    sessionExpiresAt = _repository.currentSessionExpiresAt();
    pendingConfirmationEmail = null;
    if (!passwordRecoveryActive) {
      screen = UstaadScreen.commandCenter;
      await refreshBookings(silent: true);
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ustaad_dark_theme', themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    selectedLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ustaad_selected_language', language);
    if (user != null) {
      user = user!.copyWith(preferredLanguage: language);
      await _repository.updateProfile(
        name: user!.name,
        phone: user!.phone ?? '',
        city: user!.city,
        address: user!.address,
        preferredLanguage: language,
        bio: user!.bio,
        avatarUrl: user!.avatarUrl,
      );
    }
    notifyListeners();
  }

  Future<void> toggleSavedProvider(String providerId) async {
    final next = savedProviderIds.toSet();
    if (!next.add(providerId)) {
      next.remove(providerId);
      bannerMessage = 'Provider removed from saved.';
    } else {
      bannerMessage = 'Provider saved.';
    }
    savedProviderIds = next.toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ustaad_saved_providers', savedProviderIds);
    notifyListeners();
  }

  bool isSavedProvider(String providerId) {
    return savedProviderIds.contains(providerId);
  }

  void startVoiceListening() {
    isListening = true;
    voiceTranscript = '';
    notifyListeners();
  }

  void onVoiceResult(String transcript) {
    isListening = false;
    voiceTranscript = transcript;
    notifyListeners();
  }

  void stopVoiceListening() {
    isListening = false;
    notifyListeners();
  }

  void dismissAchievement(AchievementBadge badge) {
    newlyUnlockedBadges =
        newlyUnlockedBadges.where((item) => item.id != badge.id).toList();
    notifyListeners();
  }

  void openAIChat() {
    screen = UstaadScreen.aiChat;
    notifyListeners();
  }

  ServiceIntent inferServiceIntent(String problem, String location) {
    return _inferIntent(problem, location);
  }

  void toggleMapView() {
    showMapView = !showMapView;
    notifyListeners();
  }

  Future<void> searchLocations(String query) async {
    locationSearchBusy = true;
    notifyListeners();
    locationSuggestions = await _repository.searchLocations(query);
    locationSearchBusy = false;
    notifyListeners();
  }

  Future<LocationSuggestion> resolveCurrentAddress({
    required double latitude,
    required double longitude,
  }) async {
    final location = await _repository.reverseGeocode(
      latitude: latitude,
      longitude: longitude,
    );
    setActiveLocation(location);
    return location;
  }

  void setActiveLocation(LocationSuggestion location) {
    activeLocation = location;
    lastLocation = location.locationText;
    providers = providers.map((provider) {
      final lat = provider.latitude;
      final lng = provider.longitude;
      if (lat == null || lng == null) return provider;
      final km = geoDistanceKm(
        location.latitude,
        location.longitude,
        lat,
        lng,
      ).round().clamp(1, 999);
      return provider.withDistanceKm(km);
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    if (intent != null && rankedProviders.isNotEmpty) {
      final updatedIntent = ServiceIntent(
        role: intent!.role,
        description: intent!.description,
        urgency: intent!.urgency,
        location: location.locationText,
        timeLabel: intent!.timeLabel,
        language: intent!.language,
        confidence: intent!.confidence,
      );
      intent = updatedIntent;
      rankedProviders = _rankProviders(updatedIntent);
      selectedProvider = rankedProviders.first;
      quote = _quoteFor(selectedProvider!, updatedIntent);
      workflowEvents = _buildWorkflowEvents(updatedIntent, rankedProviders);
    }
    notifyListeners();
  }

  Future<RouteEstimate> estimateRouteToProvider(
    UstaadProviderProfile provider,
  ) {
    return _repository.estimateRoute(
      fromLat: activeLocation?.latitude ?? 33.6938,
      fromLng: activeLocation?.longitude ?? 73.0652,
      toLat: provider.latitude ?? 33.6938,
      toLng: provider.longitude ?? 73.0652,
    );
  }

  void triggerEmergencyMode(String serviceType, String location) {
    final request = EmergencyRequest.now(
      serviceType,
      location.trim().isEmpty ? lastLocation : location.trim(),
    );
    emergencyModeActive = true;
    activeEmergency = request;
    _unlockAchievement('emergency_hero');
    startAnalysis(
      'urgent emergency ${request.serviceType} needed immediately',
      request.location,
    );
  }

  void dismissEmergencyMode() {
    emergencyModeActive = false;
    activeEmergency = null;
    notifyListeners();
  }

  Future<void> bookEmergencyProvider(UstaadProviderProfile provider) async {
    final emergency = activeEmergency;
    if (emergency == null) {
      await bookProvider(provider);
      return;
    }

    selectedProvider = provider;
    intent ??= ServiceIntent(
      role: emergency.serviceType,
      description: 'Emergency ${emergency.serviceType}',
      urgency: 'High',
      location: emergency.location,
      timeLabel: 'Immediate',
      language: user?.preferredLanguage ?? 'English',
      confidence: 0.96,
    );
    quote = QuoteEstimate(
      basePrice: provider.price,
      distancePrice: provider.distanceKm * 50,
      urgencyPrice: 500,
    );
    workflowEvents = _bookingWorkflowEvents(provider);
    bookingBusy = true;
    screen = UstaadScreen.workflow;
    notifyListeners();

    latestBooking = await _repository.createEmergencyBooking(
      provider: provider,
      emergency: emergency,
      quote: quote!,
    );
    bookings = [
      latestBooking!,
      ...bookings.where((b) => b.id != latestBooking!.id)
    ];
    await _incrementBookingCount();
    _checkAndUnlockAchievements();
    bannerMessage = 'Emergency provider dispatched.';
    bookingBusy = false;
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
    required bool remember,
  }) async {
    authBusy = true;
    notifyListeners();
    try {
      user = await _repository.signIn(email: email, password: password);
      sessionExpiresAt = _repository.currentSessionExpiresAt();
      await _rememberEmail(email, remember);
      await refreshBookings(silent: true);
      bannerMessage = 'Welcome back, ${user!.firstName}.';
      screen = UstaadScreen.commandCenter;
      authBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      bannerMessage = error.message;
      authBusy = false;
      notifyListeners();
      return false;
    } catch (_) {
      bannerMessage = 'Authentication service unavailable. Check your connection.';
      authBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> continueAsGuest() async {
    authBusy = true;
    notifyListeners();
    try {
      user = await _repository.signInAnonymously();
      sessionExpiresAt = _repository.currentSessionExpiresAt();
      pendingConfirmationEmail = null;
      passwordRecoveryActive = false;
      bookings = const [];
      bannerMessage = 'Guest mode active.';
      screen = UstaadScreen.commandCenter;
      authBusy = false;
      notifyListeners();
    } catch (e) {
      bannerMessage = 'Could not sign in as guest: $e';
      authBusy = false;
      notifyListeners();
    }
  }

  Future<void> _activateLocalSignup({
    required String name,
    required String email,
    required String phone,
    required bool remember,
    String? message,
  }) async {
    user = UstaadUser(
      id: 'local-${email.trim().toLowerCase().hashCode.abs()}',
      name: name.trim().isEmpty ? email.split('@').first : name.trim(),
      email: email.trim(),
      phone: phone.trim().isEmpty ? '+923001234567' : phone.trim(),
    );
    pendingConfirmationEmail = email;
    passwordRecoveryActive = false;
    sessionExpiresAt = null;
    bookings = const [];
    await _rememberEmail(email, remember);
    bannerMessage = message ??
        'Account created locally. Sign in with your credentials to sync with the cloud.';
    screen = UstaadScreen.commandCenter;
  }

  Future<bool> join({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool remember,
  }) async {
    if (authEmailCoolingDown) {
      await _activateLocalSignup(
        name: name,
        email: email,
        phone: phone,
        remember: remember,
        message:
            'Account created locally. Email limit reached, cloud sync can occur after confirmation.',
      );
      notifyListeners();
      return true;
    }

    authBusy = true;
    notifyListeners();
    try {
      final result = await _repository.signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      user = result.emailConfirmationRequired ? null : result.user;
      sessionExpiresAt = _repository.currentSessionExpiresAt();
      await _rememberEmail(email, remember);
      bookings = const [];
      if (result.emailConfirmationRequired) {
        await _activateLocalSignup(
          name: name,
          email: email,
          phone: phone,
          remember: remember,
          message:
              'Account created. Check your email later to confirm and enable cloud sync.',
        );
      } else {
        pendingConfirmationEmail = null;
        bannerMessage = 'Account ready. Welcome, ${user!.firstName}.';
        screen = UstaadScreen.commandCenter;
      }
      authBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      _handleAuthEmailError(error, email);

      // The account may have been created despite the rate-limit error on
      // the confirmation email. Try signing in with the credentials.
      final cloudUser = await _repository.trySignInAfterSignUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      if (cloudUser != null) {
        user = cloudUser;
        sessionExpiresAt = _repository.currentSessionExpiresAt();
        await _rememberEmail(email, remember);
        pendingConfirmationEmail = null;
        bookings = const [];
        bannerMessage = 'Account ready. Welcome, ${user!.firstName}.';
        screen = UstaadScreen.commandCenter;
        authBusy = false;
        notifyListeners();
        return true;
      }

      // Sign-in also failed; fall back to local account.
      await _activateLocalSignup(
        name: name,
        email: email,
        phone: phone,
        remember: remember,
        message:
            'Account created locally. Cloud sync will be available once email verification limits reset.',
      );
      authBusy = false;
      notifyListeners();
      return true;
    } catch (_) {
      // Network or unknown error — try signing in (account may already exist).
      final cloudUser = await _repository.trySignInAfterSignUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      if (cloudUser != null) {
        user = cloudUser;
        sessionExpiresAt = _repository.currentSessionExpiresAt();
        await _rememberEmail(email, remember);
        pendingConfirmationEmail = null;
        bookings = const [];
        bannerMessage = 'Account ready. Welcome, ${user!.firstName}.';
        screen = UstaadScreen.commandCenter;
        authBusy = false;
        notifyListeners();
        return true;
      }

      await _activateLocalSignup(
        name: name,
        email: email,
        phone: phone,
        remember: remember,
        message:
            'Account created locally. Cloud signup will be available when connection is restored.',
      );
      authBusy = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> resetPassword(String email) async {
    if (authEmailCoolingDown) {
      bannerMessage =
          'Email sending is cooling down. Try again in ${authEmailCooldownSeconds}s.';
      notifyListeners();
      return false;
    }

    authBusy = true;
    notifyListeners();
    try {
      await _repository.resetPassword(email);
      bannerMessage = 'Password reset email sent to $email.';
      authBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      _handleAuthEmailError(error, email);
      authBusy = false;
      notifyListeners();
      return false;
    } catch (_) {
      bannerMessage = 'Password reset could not be sent.';
      authBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendConfirmationEmail(String email) async {
    if (authEmailCoolingDown) {
      bannerMessage =
          'Email sending is cooling down. Try again in ${authEmailCooldownSeconds}s.';
      notifyListeners();
      return false;
    }

    authBusy = true;
    notifyListeners();
    try {
      await _repository.resendEmailConfirmation(email);
      pendingConfirmationEmail = email;
      bannerMessage = 'Confirmation email sent to $email.';
      authBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      _handleAuthEmailError(error, email);
      authBusy = false;
      notifyListeners();
      return false;
    } catch (_) {
      bannerMessage = 'Could not resend confirmation email.';
      authBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String password) async {
    authBusy = true;
    notifyListeners();
    try {
      user = await _repository.updatePassword(password);
      sessionExpiresAt = _repository.currentSessionExpiresAt();
      passwordRecoveryActive = false;
      pendingConfirmationEmail = null;
      await refreshBookings(silent: true);
      bannerMessage = 'Password updated. You are signed in.';
      screen = UstaadScreen.commandCenter;
      authBusy = false;
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      bannerMessage = error.message;
      authBusy = false;
      notifyListeners();
      return false;
    } catch (_) {
      bannerMessage = 'Could not update password.';
      authBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    user = null;
    sessionExpiresAt = null;
    passwordRecoveryActive = false;
    bookings = const [];
    latestBooking = null;
    providerReviews = const {};
    screen = UstaadScreen.gateway;
    notifyListeners();
  }

  void _handleAuthEmailError(AuthException error, String email) {
    final message = error.message.toLowerCase();
    if (message.contains('rate') || message.contains('limit')) {
      authEmailCooldownUntil = DateTime.now().add(const Duration(minutes: 5));
      pendingConfirmationEmail = email;
      bannerMessage =
          'Email rate limit reached. Wait ${authEmailCooldownSeconds}s, sign in if already confirmed, or continue as guest.';
      return;
    }
    bannerMessage = error.message;
  }

  Future<void> refreshProviders({bool silent = false}) async {
    try {
      final remoteProviders = await _repository.fetchProviders();
      if (remoteProviders.isNotEmpty) {
        providers = remoteProviders;
        backendOnline = true;
        bannerMessage = null;
      }
    } catch (_) {
      providers = UstaadRepository.seedProviders;
      backendOnline = false;
      bannerMessage = 'Offline provider catalog is active.';
    }
    if (!silent) notifyListeners();
  }

  Future<void> refreshBookings({bool silent = false}) async {
    if (!isSignedIn) {
      bookings = const [];
      if (!silent) notifyListeners();
      return;
    }

    try {
      bookings = await _repository.fetchBookings();
      backendOnline = true;
    } catch (_) {
      backendOnline = false;
    }
    if (!silent) notifyListeners();
  }

  void openHome() {
    screen = UstaadScreen.commandCenter;
    notifyListeners();
  }

  Future<void> openBookings() async {
    screen = UstaadScreen.bookings;
    notifyListeners();
    await refreshBookings();
  }

  void openProfile() {
    screen = UstaadScreen.profile;
    notifyListeners();
  }

  Future<bool> saveProfile({
    required String name,
    required String phone,
    required String city,
    required String address,
    required String preferredLanguage,
    required String bio,
  }) async {
    profileBusy = true;
    notifyListeners();
    try {
      user = await _repository.updateProfile(
        name: name,
        phone: phone,
        city: city,
        address: address,
        preferredLanguage: preferredLanguage,
        bio: bio,
        avatarUrl: user?.avatarUrl,
      );
      bannerMessage = 'Profile updated.';
      profileBusy = false;
      notifyListeners();
      return true;
    } catch (_) {
      bannerMessage = 'Profile could not be saved.';
      profileBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final current = user;
    if (current == null) return false;

    profileBusy = true;
    notifyListeners();
    try {
      final avatarUrl = await _repository.uploadAvatar(
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      user = await _repository.updateProfile(
        name: current.name,
        phone: current.phone ?? '',
        city: current.city,
        address: current.address,
        preferredLanguage: current.preferredLanguage,
        bio: current.bio,
        avatarUrl: avatarUrl,
      );
      bannerMessage = 'Profile photo updated.';
      profileBusy = false;
      notifyListeners();
      return true;
    } catch (e) {
      bannerMessage = e is AuthException ? e.message : 'Photo upload failed. Please verify image format and size (<5MB).';
      profileBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> sendChatMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final userMsg = AIChatMessage(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      text: clean,
      isUser: true,
      timestamp: DateTime.now(),
    );
    chatMessages = [...chatMessages, userMsg];
    chatBusy = true;
    notifyListeners();

    final replyText = await aiRouter.executeChatLadder(
      history: chatMessages,
      userMessage: clean,
    );

    final quickIntent = _inferIntent(clean, lastLocation);
    final hasRole = quickIntent.role != 'General';
    final budget = quickIntent.userBudget;

    final actionLabel = hasRole
        ? (budget != null
            ? 'Find ${quickIntent.role}s (Offer: Rs. $budget)'
            : 'Find ${quickIntent.role}s')
        : null;

    final aiMsg = AIChatMessage(
      id: 'ai-${DateTime.now().microsecondsSinceEpoch}',
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      suggestedRole: hasRole ? quickIntent.role : null,
      suggestedAction: actionLabel,
      suggestedBudget: budget,
    );

    chatMessages = [...chatMessages, aiMsg];
    chatBusy = false;
    notifyListeners();
  }

  void clearChat() {
    chatMessages = [
      AIChatMessage(
        id: 'welcome-${DateTime.now().millisecondsSinceEpoch}',
        text:
            'Assalamu Alaikum! How can I help you today? Describe your service requirement in Urdu, Roman Urdu, or English.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  Future<void> setCloudApiKey(String key) async {
    await aiRouter.setCloudConfig(key: key);
    bannerMessage = aiRouter.hasCloudKey
        ? 'OpenRouter Cloud AI key configured.'
        : 'Cloud AI key cleared (failover will use on-device Llama/heuristics).';
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String key) async {
    await setCloudApiKey(key);
  }

  Future<void> setSecondaryEngineConfig({
    required String url,
    required String key,
    required String model,
  }) async {
    await aiRouter.setCloudConfig(url: url, key: key, model: model);
    bannerMessage = 'Cloud AI configuration saved.';
    notifyListeners();
  }

  Future<void> startAnalysis(
    String problem,
    String location, {
    int? initialOffer,
  }) async {
    lastProblem = problem;
    lastLocation =
        location.trim().isEmpty ? 'G-13, Islamabad' : location.trim();
    isAnalyzing = true;
    notifyListeners();

    final localFallback = _inferIntent(lastProblem, lastLocation);
    userOffer = initialOffer ?? localFallback.userBudget;

    // Execute Neuroscript-style Failover Engine Ladder
    final ladderResult = await aiRouter.executeIntentLadder(
      problemText: lastProblem,
      fallbackLocation: lastLocation,
      localFallback: localFallback,
    );

    lastResolvedEngine = ladderResult.resolvedEngine;
    lastLadderAuditLog = ladderResult.ladderAuditLog;

    final nextIntent = ladderResult.intent;
    userOffer ??= nextIntent.userBudget;

    final ranked = _rankProviders(nextIntent, offer: userOffer);
    final firstProvider = ranked.first;

    intent = nextIntent;
    rankedProviders = ranked;
    selectedProvider = firstProvider;
    quote = _quoteFor(firstProvider, nextIntent, offer: userOffer);
    workflowEvents = _buildWorkflowEvents(
      nextIntent,
      ranked,
      reasoningSteps: ladderResult.reasoningSteps,
      engine: ladderResult.resolvedEngine,
      auditLog: ladderResult.ladderAuditLog,
      offer: userOffer,
    );
    isAnalyzing = false;
    screen = UstaadScreen.selection;
    addToRecentRequests(lastProblem, lastLocation);
    _checkAndUnlockAchievements();
    notifyListeners();
  }

  void previewProvider(UstaadProviderProfile provider) {
    userOffer ??= provider.price;
    final nextIntent = ServiceIntent(
      role: provider.role,
      description: '${provider.role} service',
      urgency: 'Normal',
      location: lastLocation,
      timeLabel: provider.nextSlot,
      language: user?.preferredLanguage ?? 'English',
      confidence: 0.88,
      userBudget: userOffer,
    );
    final ranked = _rankProviders(nextIntent, offer: userOffer);
    final focused = ranked.firstWhere(
      (item) => item.id == provider.id,
      orElse: () => provider.withScore(82, provider.reason),
    );
    intent = nextIntent;
    rankedProviders = [
      focused,
      ...ranked.where((item) => item.id != provider.id),
    ];
    selectedProvider = focused;
    quote = _quoteFor(focused, nextIntent, offer: userOffer);
    workflowEvents = _buildWorkflowEvents(
      nextIntent,
      rankedProviders,
      offer: userOffer,
    );
    screen = UstaadScreen.selection;
    notifyListeners();
  }

  Future<void> bookProvider(UstaadProviderProfile provider) async {
    selectedProvider = provider;
    quote = _quoteFor(provider, intent!, offer: userOffer);
    final bookingEvents = _bookingWorkflowEvents(provider);
    workflowEvents = bookingEvents;
    bookingBusy = true;
    screen = UstaadScreen.workflow;
    notifyListeners();

    try {
      latestBooking = await _repository.createBooking(
        provider: provider,
        intent: intent!,
        quote: quote!,
        problemText: lastProblem,
        workflowEvents: bookingEvents,
      );
      bookings = [
        latestBooking!,
        ...bookings.where((b) => b.id != latestBooking!.id)
      ];
      backendOnline = true;
      bannerMessage = 'Booking confirmed and saved.';
    } catch (_) {
      latestBooking = BookingRecord.local(
        provider: provider,
        intent: intent!,
        quote: quote!,
        problemText: lastProblem,
        offer: userOffer ?? quote!.userOffer ?? intent!.userBudget,
      );
      bookings = [latestBooking!, ...bookings];
      bannerMessage = 'Booking is active locally and will sync when available.';
    }
    await _incrementBookingCount();
    _checkAndUnlockAchievements();
    bookingBusy = false;
    notifyListeners();
  }

  Future<bool> updateBookingStatus(BookingRecord booking, String status) async {
    if (booking.id.startsWith('local-')) {
      bookings = bookings
          .map((item) =>
              item.id == booking.id ? item.copyWith(status: status) : item)
          .toList();
      latestBooking = latestBooking?.id == booking.id
          ? latestBooking!.copyWith(status: status)
          : latestBooking;
      notifyListeners();
      return true;
    }

    bookingBusy = true;
    notifyListeners();
    try {
      final updated = await _repository.updateBookingStatus(
        bookingId: booking.id,
        status: status,
      );
      bookings = bookings
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      latestBooking = latestBooking?.id == updated.id ? updated : latestBooking;
      bannerMessage = 'Booking status updated.';
      bookingBusy = false;
      notifyListeners();
      return true;
    } catch (_) {
      bannerMessage = 'Status update failed.';
      bookingBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reportBookingIssue(BookingRecord booking, String note) async {
    final ok = await updateBookingStatus(booking, 'issue_reported');
    if (ok) {
      bannerMessage = note.trim().isEmpty
          ? 'Issue reported. Support will follow up.'
          : 'Issue reported: ${note.trim()}';
      notifyListeners();
    }
    return ok;
  }

  Future<void> loadReviews(String providerId) async {
    try {
      final reviews = await _repository.fetchReviews(providerId);
      providerReviews = {
        ...providerReviews,
        providerId: reviews,
      };
      notifyListeners();
    } catch (_) {
      providerReviews = {
        ...providerReviews,
        providerId: UstaadRepository.seedReviews[providerId] ?? const [],
      };
      notifyListeners();
    }
  }

  Future<bool> submitReview({
    required String providerId,
    required int rating,
    required String comment,
    String? bookingId,
  }) async {
    final trimmed = comment.trim();
    if (trimmed.length < 3) {
      bannerMessage = 'Review needs a short comment.';
      notifyListeners();
      return false;
    }

    reviewBusy = true;
    notifyListeners();
    try {
      final review = await _repository.createReview(
        providerId: providerId,
        rating: rating,
        comment: trimmed,
        language: _inferLanguage(trimmed),
        bookingId: bookingId,
      );
      providerReviews = {
        ...providerReviews,
        providerId: [review, ...(providerReviews[providerId] ?? const [])],
      };
      bannerMessage = 'Review posted.';
      reviewBusy = false;
      notifyListeners();
      return true;
    } catch (_) {
      bannerMessage = 'Review could not be posted yet.';
      reviewBusy = false;
      notifyListeners();
      return false;
    }
  }

  ServiceIntent _inferIntent(String problem, String location) {
    final value = _normalizeSearchText(problem);
    var role = 'General';
    var description = 'General Maintenance';

    if (_containsAny(value, [
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
    ])) {
      role = 'Electrician';
      if (_containsAny(value, ['breaker', 'short circuit', 'spark', 'بریکر', 'شارٹ سرکٹ'])) {
        description = 'Breaker & Short Circuit Fault';
      } else if (_containsAny(value, ['fan', 'pankha', 'پنکھا'])) {
        description = 'Ceiling Fan Service & Repair';
      } else if (_containsAny(value, ['wire', 'wiring', 'تار', 'وائر'])) {
        description = 'Wiring Inspection & Repair';
      } else {
        description = 'Electrical Repair';
      }
    } else if (_containsAny(value, [
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
    ])) {
      role = 'Plumber';
      if (_containsAny(value, ['sink', 'washroom', 'toilet', 'basin', 'commode', 'سنک', 'واشروم', 'بیسن'])) {
        description = 'Washroom Sink & Plumbing Repair';
      } else if (_containsAny(value, ['geyser', 'tanki', 'گیزر'])) {
        description = 'Geyser & Water Tank Maintenance';
      } else if (_containsAny(value, ['drain', 'gutter', 'sewerage', 'گٹر', 'سیوریج'])) {
        description = 'Drainage & Sewerage Clearance';
      } else if (_containsAny(value, ['motor', 'pump', 'موٹر', 'پمپ'])) {
        description = 'Water Pump & Motor Repair';
      } else {
        description = 'Plumbing Issue & Leak Fix';
      }
    } else if (_containsAny(value, [
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
    ])) {
      role = 'AC Repair';
      if (_containsAny(value, ['gas', 'گیس'])) {
        description = 'AC Gas Refill & Leak Check';
      } else if (_containsAny(value, ['cooling', 'thanda', 'کولنگ', 'ٹھنڈا'])) {
        description = 'AC Cooling Fault Troubleshooting';
      } else {
        description = 'AC Service & Maintenance';
      }
    } else if (_containsAny(value, [
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
    ])) {
      role = 'Cleaning';
      if (_containsAny(value, ['sofa', 'carpet', 'صوفہ', 'کارپٹ'])) {
        description = 'Sofa & Carpet Deep Cleaning';
      } else if (_containsAny(value, ['tanki', 'water tank'])) {
        description = 'Water Tank Cleaning & Sanitization';
      } else {
        description = 'Deep Cleaning Request';
      }
    } else if (_containsAny(value, [
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
    ])) {
      role = 'Tutor';
      description = 'Tutoring Session';
    } else if (_containsAny(value, [
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
    ])) {
      role = 'Beautician';
      description = 'Beauty Service & Grooming';
    }

    final urgency = _containsAny(value, [
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
    ])
        ? 'High'
        : 'Normal';
    final timeLabel = _inferTimeLabel(value);
    final language = _inferLanguage(problem);

    int? extractedBudget;
    final budgetPatterns = [
      RegExp(r'(?:budget|offer|rs\.?|pkr|rupay|rupees)\s*[:=]?\s*(\d{2,6})', caseSensitive: false),
      RegExp(r'(\d{2,6})\s*(?:rs\.?|pkr|rupay|rupees|rp|mein|me|ma\b)', caseSensitive: false),
    ];
    for (final pattern in budgetPatterns) {
      final matches = pattern.allMatches(problem);
      for (final m in matches) {
        final str = m.group(1);
        if (str != null) {
          final val = int.tryParse(str);
          if (val != null && val >= 50 && val <= 100000) {
            extractedBudget = val;
            break;
          }
        }
      }
      if (extractedBudget != null) break;
    }

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

  List<UstaadProviderProfile> _rankProviders(
    ServiceIntent nextIntent, {
    int? offer,
  }) {
    final targetBudget =
        offer ?? userOffer ?? nextIntent.userBudget ?? defaultBudgetForRole(nextIntent.role);
    final matching = providers
        .where((provider) =>
            nextIntent.role == 'General' || provider.role == nextIntent.role)
        .toList();
    final pool = matching.isEmpty ? providers : matching;

    final scored = pool.map((provider) {
      // InDrive Budget Match Affinity (35% weight)
      final priceDiff = provider.price - targetBudget;
      double budgetAffinity;
      String matchTag;
      if (priceDiff <= 0) {
        budgetAffinity = 100.0;
        final savings = targetBudget - provider.price;
        matchTag = savings > 0 ? 'Rs. $savings below offer' : 'Exact match';
      } else if (priceDiff <= 150) {
        budgetAffinity = 80.0;
        matchTag = 'Counter: +Rs. $priceDiff';
      } else if (priceDiff <= 350) {
        budgetAffinity = 55.0;
        matchTag = 'Counter: +Rs. $priceDiff';
      } else {
        budgetAffinity = math.max(0, 100 - (priceDiff / 10)).toDouble();
        matchTag = 'Rate: Rs. ${provider.price}';
      }
      final budgetScore = budgetAffinity * 0.35;

      final reliability = provider.reliability * 100 * 0.22;
      final distance = math.max(0, 20 - provider.distanceKm) / 20 * 100 * 0.18;
      final rating = provider.rating / 5 * 100 * 0.15;
      final experience = math.min(provider.jobsCompleted, 250) / 250 * 5;
      final response = math.max(0, 45 - provider.responseTimeMinutes) / 45 * 5;
      final urgencyBoost =
          nextIntent.urgency == 'High' && provider.reliability >= 0.90 ? 5 : 0;
      final score = budgetScore +
          reliability +
          distance +
          rating +
          experience +
          response +
          urgencyBoost;
      final reason =
          '$matchTag · ${provider.distanceKm} km · ${provider.rating}★ (${provider.jobsCompleted} jobs)';
      return provider.withScore(score, reason);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored;
  }

  QuoteEstimate _quoteFor(
    UstaadProviderProfile provider,
    ServiceIntent nextIntent, {
    int? offer,
  }) {
    final targetOffer = offer ?? userOffer ?? nextIntent.userBudget;
    return QuoteEstimate(
      basePrice: provider.price,
      distancePrice: provider.distanceKm * 50,
      urgencyPrice: nextIntent.urgency == 'High' ? 500 : 0,
      userOffer: targetOffer,
    );
  }

  List<WorkflowEvent> _buildWorkflowEvents(
    ServiceIntent nextIntent,
    List<UstaadProviderProfile> ranked, {
    List<String> reasoningSteps = const [],
    AIEngineType engine = AIEngineType.localHeuristic,
    List<String> auditLog = const [],
    int? offer,
  }) {
    final best = ranked.first;
    final second = ranked.length > 1 ? ranked[1] : best;
    final estimate = _quoteFor(best, nextIntent, offer: offer);
    final tokenCount = nextIntent.description.split(RegExp(r'\s+')).length + 6;
    final sector = _sectorFromLocation(nextIntent.location);
    final nearbyCount =
        ranked.where((provider) => provider.distanceKm <= 15).length;

    final engineName = switch (engine) {
      AIEngineType.openRouterCloud => 'OpenRouter DeepSeek (Cloud Primary)',
      AIEngineType.onDeviceLlama => 'On-Device Llama (llamadart GGUF JSON)',
      AIEngineType.localHeuristic => 'On-Device Heuristic Engine (Safety Net)',
    };

    final nlpMessage = reasoningSteps.isNotEmpty
        ? reasoningSteps.first
        : 'Input processed in ${nextIntent.language}. Tokenized $tokenCount words. Extracted service=${nextIntent.role}, location=${nextIntent.location}, urgency=${nextIntent.urgency}. Confidence: ${(nextIntent.confidence * 100).round()}%.';

    final ladderSummary = auditLog.isNotEmpty
        ? auditLog.join(' ➔ ')
        : 'Engine cascade validated.';

    return [
      WorkflowEvent(
        agentName: 'Engine Router',
        step: 'Failover Ladder Resolution',
        message: 'Ladder evaluation: $ladderSummary',
        toolName: 'Failover Cascade Ladder',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'NLP Interpreter',
        step: 'Semantic Extraction',
        message: '$nlpMessage [Resolved via $engineName]',
        toolName: engineName,
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Context Agent',
        step: 'Enrich Context',
        message: reasoningSteps.length > 1
            ? reasoningSteps[1]
            : 'Resolved ${nextIntent.location} to target sector $sector. Activated 15km service zone.',
        toolName: 'Location Resolver',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Discovery Agent',
        step: 'Provider Search',
        message:
            'Queried service_providers table with filter role=${nextIntent.role}. Found ${ranked.length} candidates in database. Applied city filter. $nearbyCount providers within 15km radius.',
        toolName: 'Cloud Firestore / Catalog',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Ranking Agent',
        step: 'InDrive Budget Ranking',
        message:
            'Applied InDrive budget-weighted ranking: budget match(35%), reliability(22%), distance(18%), rating(15%), experience(5%), response(5%). Top score: ${best.score.toStringAsFixed(1)}/100.',
        toolName: 'Trust & Budget Match Engine',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Decision Agent',
        step: 'Select Provider',
        message:
            'Selected ${best.name} (${best.role}) - Score ${best.score.toStringAsFixed(1)}. Reason: ${best.reason}. Alternative: ${second.name} at score ${second.score.toStringAsFixed(1)}.',
        toolName: 'Best-Match Selector',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Quote Agent',
        step: 'Price Estimate & Bidding',
        message:
            'Base: Rs.${estimate.basePrice}${estimate.userOffer != null ? " (Offer: Rs.${estimate.userOffer})" : ""} + Distance: Rs.${estimate.distancePrice} + Urgency: Rs.${estimate.urgencyPrice} = Total: Rs.${estimate.total}.',
        toolName: 'InDrive Bidding & Pricing Engine',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Booking Agent',
        step: 'Reserve Slot',
        message:
            'Slot ${best.nextSlot} reserved. Booking ID generated. Provider notified via simulated push notification.',
        toolName: 'Booking API',
        status: 'ready',
      ),
      WorkflowEvent(
        agentName: 'Follow-up Agent',
        step: 'Schedule Reminders',
        message:
            'Reminder set for 1 hour before appointment. Post-job review prompt scheduled. Status polling every 5 minutes until completed.',
        toolName: 'Notification Scheduler',
        status: 'scheduled',
      ),
    ];
  }

  List<WorkflowEvent> _bookingWorkflowEvents(UstaadProviderProfile provider) {
    return [
      ...workflowEvents,
      WorkflowEvent(
        agentName: 'Booking',
        step: 'Confirm',
        message:
            'Booked ${provider.name} for ${provider.nextSlot}; contact unlocked.',
        toolName: 'bookings',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Follow-up',
        step: 'Monitor',
        message:
            'Reminder prepared 1 hour before ${provider.nextSlot}; review prompt enabled.',
        toolName: 'agent_events',
        status: 'scheduled',
      ),
    ];
  }

  String _inferTimeLabel(String value) {
    if (_containsAny(value, [
      'kal subah',
      'tomorrow morning',
      '\u06a9\u0644 \u0635\u0628\u062d',
    ])) {
      return 'Tomorrow morning';
    }
    if (_containsAny(value, ['kal', 'tomorrow', '\u06a9\u0644'])) {
      return 'Tomorrow';
    }
    if (_containsAny(value, ['aaj', 'today', '\u0622\u062c'])) {
      return 'Today';
    }
    if (_containsAny(value, [
      'raat',
      'tonight',
      'evening',
      '\u0631\u0627\u062a',
      '\u0634\u0627\u0645',
    ])) {
      return 'Tonight';
    }
    if (_containsAny(value, ['kal subah', 'tomorrow morning', 'کل صبح'])) {
      return 'Tomorrow morning';
    }
    if (_containsAny(value, ['kal', 'tomorrow', 'کل'])) {
      return 'Tomorrow';
    }
    if (_containsAny(value, ['aaj', 'today', 'آج'])) {
      return 'Today';
    }
    if (_containsAny(value, ['raat', 'tonight', 'evening', 'رات'])) {
      return 'Tonight';
    }
    return 'Next available slot';
  }

  String _inferLanguage(String value) {
    if (RegExp(r'[\u0600-\u06ff]').hasMatch(value)) return 'Urdu';
    if (_containsAny(_normalizeSearchText(value), [
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
    ])) {
      return 'Roman Urdu';
    }
    return 'English';
  }

  bool _containsAny(String value, List<String> terms) {
    return terms.any(value.contains);
  }

  String _normalizeSearchText(String value) {
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

  String _sectorFromLocation(String value) {
    final match =
        RegExp(r'\b[A-I]-?\d{1,2}\b', caseSensitive: false).firstMatch(value);
    return match?.group(0)?.toUpperCase() ?? 'Islamabad';
  }

  Future<void> _rememberEmail(String email, bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      savedEmail = email;
      await prefs.setString('ustaad_user_email', email);
    } else {
      savedEmail = '';
      await prefs.remove('ustaad_user_email');
    }
  }

  Future<void> addToRecentRequests(String problemText, String location) async {
    await _rememberRequest(problemText, location);
    notifyListeners();
  }

  Future<void> _rememberRequest(String problem, String location) async {
    final trimmed = problem.trim();
    if (trimmed.isEmpty) return;
    final label = _suggestionLabel(trimmed, location);
    final suggestion = SmartSuggestion(
      label: label,
      fullText: trimmed,
      category: 'recent',
      icon: Icons.history,
    );
    final next = [
      suggestion,
      ...recentRequests.where(
        (item) => item.fullText.toLowerCase() != trimmed.toLowerCase(),
      ),
    ].take(3).toList();
    recentRequests = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'ustaad_recent_requests',
      next.map((item) => item.fullText).toList(),
    );
  }

  SmartSuggestion _suggestionFromStoredText(String value) {
    return SmartSuggestion(
      label: _suggestionLabel(value, lastLocation),
      fullText: value,
      category: 'recent',
      icon: Icons.history,
    );
  }

  String _suggestionLabel(String problem, String location) {
    final intent = _inferIntent(problem, location);
    final place = _sectorFromLocation(location);
    return '${intent.role} - $place';
  }

  Future<void> _incrementBookingCount() async {
    totalBookingsCount += 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ustaad_total_bookings', totalBookingsCount);
  }

  void _checkAndUnlockAchievements() {
    if (lastProblem.isNotEmpty) _unlockAchievement('first_request');
    if (totalBookingsCount >= 1) _unlockAchievement('first_booking');
    if (totalBookingsCount >= 3) _unlockAchievement('power_user');
    final language = intent?.language;
    if (language == 'Roman Urdu' || language == 'Urdu') {
      _unlockAchievement('multilingual');
    }
  }

  void _unlockAchievement(String id) {
    final index = achievements.indexWhere((badge) => badge.id == id);
    if (index == -1 || achievements[index].unlocked) return;
    final unlocked = achievements[index].copyWith(
      unlocked: true,
      unlockedAt: DateTime.now(),
    );
    achievements = [
      ...achievements.take(index),
      unlocked,
      ...achievements.skip(index + 1),
    ];
    newlyUnlockedBadges = [...newlyUnlockedBadges, unlocked];
  }
}
