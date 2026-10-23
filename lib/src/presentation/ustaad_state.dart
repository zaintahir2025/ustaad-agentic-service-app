import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import '../models.dart';
import '../currency.dart';
import '../ustaad_repository.dart';
import '../gemini_service.dart';
import '../ai_engine_router.dart';
import '../domain/usecases/extract_intent_use_case.dart';
import '../domain/usecases/rank_providers_use_case.dart';
import '../domain/usecases/calculate_quote_use_case.dart';
import '../domain/usecases/build_workflow_trace_use_case.dart';
import '../domain/usecases/evaluate_achievements_use_case.dart';

/// Clean Presentation State: Manages UI state, user sessions, and reactive mutations.
///
/// Responsibilities for Intent Extraction (NLP), Provider Ranking (InDrive scoring),
/// Quote Estimation, Agentic Traces, and Gamification are delegated to their
/// respective domain use cases.
class UstaadState extends ChangeNotifier {
  UstaadState(
    this._repository, {
    ExtractIntentUseCase extractIntentUseCase = const ExtractIntentUseCase(),
    RankProvidersUseCase rankProvidersUseCase = const RankProvidersUseCase(),
    CalculateQuoteUseCase calculateQuoteUseCase = const CalculateQuoteUseCase(),
    BuildWorkflowTraceUseCase buildWorkflowTraceUseCase =
        const BuildWorkflowTraceUseCase(),
    EvaluateAchievementsUseCase evaluateAchievementsUseCase =
        const EvaluateAchievementsUseCase(),
  })  : _extractIntentUseCase = extractIntentUseCase,
        _rankProvidersUseCase = rankProvidersUseCase,
        _calculateQuoteUseCase = calculateQuoteUseCase,
        _buildWorkflowTraceUseCase = buildWorkflowTraceUseCase,
        _evaluateAchievementsUseCase = evaluateAchievementsUseCase {
    _authSubscription = _repository.authStateChanges.listen(_handleAuthChange);
  }

  final UstaadRepository _repository;
  final ExtractIntentUseCase _extractIntentUseCase;
  final RankProvidersUseCase _rankProvidersUseCase;
  final CalculateQuoteUseCase _calculateQuoteUseCase;
  final BuildWorkflowTraceUseCase _buildWorkflowTraceUseCase;
  final EvaluateAchievementsUseCase _evaluateAchievementsUseCase;

  final AIEngineRouter aiRouter = AIEngineRouter();
  GeminiService get geminiService =>
      GeminiService(initialApiKey: aiRouter.geminiApiKey);
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
  UstaadScreen? requestedScreen;

  void setScreen(UstaadScreen target) {
    screen = target;
    requestedScreen = target;
    notifyListeners();
  }

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

  int get activeOffer => _rankProvidersUseCase.resolveActiveOffer(
        userOffer: userOffer,
        intent: intent,
      );

  static int defaultBudgetForRole(String role) =>
      RankProvidersUseCase.defaultBudgetForRole(role);

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
    setScreen(UstaadScreen.aiChat);
  }

  ServiceIntent inferServiceIntent(String problem, String location) {
    return _extractIntentUseCase.execute(problem, location);
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
        userBudget: intent!.userBudget,
      );
      intent = updatedIntent;
      rankedProviders = _rankProviders(updatedIntent, offer: userOffer);
      selectedProvider = rankedProviders.first;
      quote = _quoteFor(selectedProvider!, updatedIntent, offer: userOffer);
      workflowEvents = _buildWorkflowEvents(
        updatedIntent,
        rankedProviders,
        offer: userOffer,
      );
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
    setScreen(UstaadScreen.workflow);

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
      authBusy = false;
      setScreen(UstaadScreen.commandCenter);
      return true;
    } on AuthException catch (error) {
      bannerMessage = error.message;
      authBusy = false;
      notifyListeners();
      return false;
    } catch (_) {
      bannerMessage =
          'Authentication service unavailable. Check your connection.';
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
      authBusy = false;
      setScreen(UstaadScreen.commandCenter);
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
            'Account created locally. Cloud sync will be available once email verification limits reset.',
      );
      authBusy = false;
      notifyListeners();
      return true;
    } catch (_) {
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
    setScreen(UstaadScreen.gateway);
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
      final remote = await _repository.fetchBookings();
      if (remote.isNotEmpty || _repository.isFirebaseInitialized) {
        bookings = remote;
      }
      backendOnline = true;
    } catch (_) {
      backendOnline = false;
    }
    if (!silent) notifyListeners();
  }

  void openHome() {
    setScreen(UstaadScreen.commandCenter);
  }

  Future<void> openBookings() async {
    setScreen(UstaadScreen.bookings);
    await refreshBookings();
  }

  void openProfile() {
    setScreen(UstaadScreen.profile);
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
      bannerMessage = e is AuthException
          ? e.message
          : 'Photo upload failed. Please verify image format and size (<5MB).';
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

    ServiceIntent quickIntent;
    try {
      quickIntent = await _repository.extractServiceIntent(
        problemText: clean,
        location: lastLocation,
      );
    } catch (_) {
      quickIntent = _extractIntentUseCase.execute(clean, lastLocation);
    }
    final hasRole = quickIntent.role != 'General';
    final budget = quickIntent.userBudget;

    final actionLabel = hasRole
        ? (budget != null
            ? 'Find ${quickIntent.role}s (Offer: ${formatPkr(budget)})'
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

  bool get isDemoMode => !aiRouter.hasCloudKey && !aiRouter.hasLocalLlama;

  Future<void> setProxyUrl(String url) async {
    await aiRouter.setCloudConfig(key: aiRouter.apiKey, proxyUrl: url);
    bannerMessage = aiRouter.hasProxy
        ? 'Backend AI proxy configured.'
        : 'Backend AI proxy cleared.';
    notifyListeners();
  }

  Future<void> setCloudApiKey(String key) async {
    await aiRouter.setCloudConfig(key: key);
    bannerMessage = aiRouter.hasCloudKey
        ? 'Cloud AI configured.'
        : 'Cloud AI key cleared (failover will use on-device safety net).';
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String key) async {
    await setCloudApiKey(key);
  }

  Future<void> setSecondaryEngineConfig({
    required String url,
    required String key,
    required String model,
    String? proxyUrl,
  }) async {
    await aiRouter.setCloudConfig(
      url: url,
      key: key,
      model: model,
      proxyUrl: proxyUrl,
    );
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

    // 1. Try server-side Firebase Cloud Function (extractServiceIntent)
    ServiceIntent nextIntent;
    List<String> reasoningSteps = const [];
    try {
      nextIntent = await _repository.extractServiceIntent(
        problemText: lastProblem,
        location: lastLocation,
        initialOffer: initialOffer,
      );
      lastResolvedEngine = AIEngineType.openRouterCloud;
      lastLadderAuditLog = const ['Firebase Cloud Function (extractServiceIntent) ➔ Success'];
      reasoningSteps = const ['Extracted via backend Firebase Cloud Function with Gemini Logic.'];
    } catch (_) {
      // 2. Cascade to local AI Router ladder if Cloud Function is offline/unreachable
      final localFallback = _extractIntentUseCase.execute(
        lastProblem,
        lastLocation,
        initialOffer: initialOffer,
      );

      final ladderResult = await aiRouter.executeIntentLadder(
        problemText: lastProblem,
        fallbackLocation: lastLocation,
        localFallback: localFallback,
      );

      lastResolvedEngine = ladderResult.resolvedEngine;
      lastLadderAuditLog = ladderResult.ladderAuditLog;
      nextIntent = ladderResult.intent;
      reasoningSteps = ladderResult.reasoningSteps;
    }

    userOffer = initialOffer ?? nextIntent.userBudget;

    final ranked = _rankProviders(nextIntent, offer: userOffer);
    final firstProvider = ranked.first;

    intent = nextIntent;
    rankedProviders = ranked;
    selectedProvider = firstProvider;
    quote = _quoteFor(firstProvider, nextIntent, offer: userOffer);
    workflowEvents = _buildWorkflowEvents(
      nextIntent,
      ranked,
      reasoningSteps: reasoningSteps,
      engine: lastResolvedEngine,
      auditLog: lastLadderAuditLog,
      offer: userOffer,
    );
    isAnalyzing = false;
    addToRecentRequests(lastProblem, lastLocation);
    _checkAndUnlockAchievements();
    setScreen(UstaadScreen.selection);
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
    setScreen(UstaadScreen.selection);
  }

  Future<void> bookProvider(UstaadProviderProfile provider) async {
    selectedProvider = provider;
    quote = _quoteFor(provider, intent!, offer: userOffer);
    final bookingEvents = _bookingWorkflowEvents(provider);
    workflowEvents = bookingEvents;
    bookingBusy = true;
    setScreen(UstaadScreen.workflow);

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
      bannerMessage =
          'Booking is active locally and will sync when available.';
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
      latestBooking =
          latestBooking?.id == updated.id ? updated : latestBooking;
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
        language: _extractIntentUseCase.inferLanguage(trimmed),
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

  List<UstaadProviderProfile> _rankProviders(
    ServiceIntent nextIntent, {
    int? offer,
  }) {
    return _rankProvidersUseCase.execute(
      providers: providers,
      intent: nextIntent,
      offer: offer ?? userOffer,
    );
  }

  QuoteEstimate _quoteFor(
    UstaadProviderProfile provider,
    ServiceIntent nextIntent, {
    int? offer,
  }) {
    return _calculateQuoteUseCase.execute(
      provider: provider,
      intent: nextIntent,
      offer: offer ?? userOffer,
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
    return _buildWorkflowTraceUseCase.execute(
      intent: nextIntent,
      ranked: ranked,
      reasoningSteps: reasoningSteps,
      engine: engine,
      auditLog: auditLog,
      offer: offer ?? userOffer,
    );
  }

  List<WorkflowEvent> _bookingWorkflowEvents(UstaadProviderProfile provider) {
    return _buildWorkflowTraceUseCase.buildBookingEvents(
      workflowEvents,
      provider,
    );
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
    final intent = _extractIntentUseCase.execute(problem, location);
    final place = _extractIntentUseCase.sectorFromLocation(location);
    return '${intent.role} - $place';
  }

  Future<void> _incrementBookingCount() async {
    totalBookingsCount += 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ustaad_total_bookings', totalBookingsCount);
  }

  void _checkAndUnlockAchievements() {
    final result = _evaluateAchievementsUseCase.execute(
      lastProblem: lastProblem,
      totalBookingsCount: totalBookingsCount,
      language: intent?.language,
      currentBadges: achievements,
    );
    achievements = result.allBadges;
    if (result.newlyUnlocked.isNotEmpty) {
      newlyUnlockedBadges = [...newlyUnlockedBadges, ...result.newlyUnlocked];
    }
  }

  void _unlockAchievement(String id) {
    final result = _evaluateAchievementsUseCase.unlockById(
      id: id,
      currentBadges: achievements,
    );
    achievements = result.allBadges;
    if (result.newlyUnlocked.isNotEmpty) {
      newlyUnlockedBadges = [...newlyUnlockedBadges, ...result.newlyUnlocked];
    }
  }
}
