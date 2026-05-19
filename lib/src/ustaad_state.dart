import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'ustaad_repository.dart';

class UstaadState extends ChangeNotifier {
  UstaadState(this._repository);

  final UstaadRepository _repository;

  bool bootstrapped = false;
  bool backendOnline = false;
  bool authBusy = false;
  bool bookingBusy = false;
  bool profileBusy = false;
  bool reviewBusy = false;
  String savedEmail = '';
  String? bannerMessage;
  DateTime? sessionExpiresAt;
  ThemeMode themeMode = ThemeMode.dark;
  UstaadScreen screen = UstaadScreen.gateway;
  UstaadUser? user;

  List<UstaadProviderProfile> providers = UstaadRepository.seedProviders;
  List<UstaadProviderProfile> rankedProviders = const [];
  List<BookingRecord> bookings = const [];
  Map<String, List<ReviewRecord>> providerReviews = const {};
  UstaadProviderProfile? selectedProvider;
  BookingRecord? latestBooking;
  ServiceIntent? intent;
  QuoteEstimate? quote;
  List<WorkflowEvent> workflowEvents = const [];
  String lastProblem = '';
  String lastLocation = 'G-13, Islamabad';

  bool get isSignedIn => user != null;
  bool get isDark => themeMode == ThemeMode.dark;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    savedEmail = prefs.getString('ustaad_user_email') ?? '';
    themeMode = (prefs.getBool('ustaad_dark_theme') ?? true)
        ? ThemeMode.dark
        : ThemeMode.light;
    user = _repository.currentUser();
    sessionExpiresAt = _repository.currentSessionExpiresAt();
    if (user != null) {
      user = await _repository.fetchProfile() ?? user;
      screen = UstaadScreen.commandCenter;
      await refreshBookings(silent: true);
    }
    await refreshProviders(silent: true);
    bootstrapped = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ustaad_dark_theme', themeMode == ThemeMode.dark);
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
      bannerMessage = 'Could not reach Supabase Auth. Check your connection.';
      authBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> join({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool remember,
  }) async {
    authBusy = true;
    notifyListeners();
    try {
      user = await _repository.signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      sessionExpiresAt = _repository.currentSessionExpiresAt();
      await _rememberEmail(email, remember);
      bookings = const [];
      bannerMessage = 'Account ready. Welcome, ${user!.firstName}.';
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
      bannerMessage = 'Could not create the Supabase account yet.';
      authBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    authBusy = true;
    notifyListeners();
    try {
      await _repository.resetPassword(email);
      bannerMessage = 'Password reset email sent.';
      authBusy = false;
      notifyListeners();
      return true;
    } catch (_) {
      bannerMessage = 'Password reset could not be sent.';
      authBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    user = null;
    sessionExpiresAt = null;
    bookings = const [];
    latestBooking = null;
    providerReviews = const {};
    screen = UstaadScreen.gateway;
    notifyListeners();
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
      bannerMessage =
          'Local demo data is active until Supabase SQL is applied.';
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
    } catch (_) {
      bannerMessage = 'Photo upload failed. Check Supabase Storage policies.';
      profileBusy = false;
      notifyListeners();
      return false;
    }
  }

  void startAnalysis(String problem, String location) {
    lastProblem = problem;
    lastLocation =
        location.trim().isEmpty ? 'G-13, Islamabad' : location.trim();
    final nextIntent = _inferIntent(lastProblem, lastLocation);
    final ranked = _rankProviders(nextIntent);
    final firstProvider = ranked.first;

    intent = nextIntent;
    rankedProviders = ranked;
    selectedProvider = firstProvider;
    quote = _quoteFor(firstProvider, nextIntent);
    workflowEvents = _buildWorkflowEvents(nextIntent, ranked);
    screen = UstaadScreen.selection;
    notifyListeners();
  }

  Future<void> bookProvider(UstaadProviderProfile provider) async {
    selectedProvider = provider;
    quote = _quoteFor(provider, intent!);
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
      );
      bookings = [latestBooking!, ...bookings];
      bannerMessage = 'Booking is active locally; Supabase write is pending.';
    }
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
      'wire',
      'wiring',
      'breaker',
      '\u0628\u062c\u0644\u06cc',
      '\u0628\u062a\u06cc',
      '\u0644\u0627\u0626\u0679',
      '\u0648\u0627\u0626\u0631',
      '\u062a\u0627\u0631',
      '\u0628\u0631\u06cc\u06a9\u0631',
      'بجلی',
      'وائر',
    ])) {
      role = 'Electrician';
      description = 'Electrical Repair';
    } else if (_containsAny(value, [
      'plumb',
      'pani',
      'nal',
      'leak',
      'pipe',
      'drain',
      '\u067e\u0627\u0646\u06cc',
      '\u0644\u06cc\u06a9',
      '\u0646\u0644',
      '\u067e\u0627\u0626\u067e',
      '\u06af\u0679\u0631',
      'پانی',
      'لیک',
      'نل',
    ])) {
      role = 'Plumber';
      description = 'Plumbing Issue';
    } else if (_containsAny(value, [
      'ac',
      'cooling',
      'thanda',
      'compressor',
      '\u0627\u06d2 \u0633\u06cc',
      '\u0627\u06cc\u0631 \u06a9\u0646\u0688\u06cc\u0634\u0646\u0631',
      '\u0679\u06be\u0646\u0688\u0627',
      '\u06a9\u0648\u0644\u0646\u06af',
      '\u06a9\u0645\u067e\u0631\u06cc\u0633\u0631',
      'اے سی',
      'ٹھنڈا',
    ])) {
      role = 'AC Repair';
      description = 'AC Maintenance';
    } else if (_containsAny(value, [
      'clean',
      'safai',
      'dust',
      'deep clean',
      '\u0635\u0641\u0627\u0626\u06cc',
      '\u0635\u0627\u0641',
      '\u06af\u0631\u062f',
      '\u062f\u06be\u0648\u0644',
      'صفائی',
    ])) {
      role = 'Cleaning';
      description = 'Cleaning Request';
    } else if (_containsAny(value, [
      'tutor',
      'teacher',
      'ustad',
      'ustaad',
      'math',
      'study',
      'parhai',
      '\u0627\u0633\u062a\u0627\u062f',
      '\u0679\u06cc\u0686\u0631',
      '\u067e\u0691\u06be\u0627\u0626\u06cc',
      '\u067e\u0691\u06be\u0627\u0646\u0627',
      '\u0631\u06cc\u0627\u0636\u06cc',
      'استاد',
      'پڑھائی',
    ])) {
      role = 'Tutor';
      description = 'Tutoring Session';
    } else if (_containsAny(value, [
      'beauty',
      'makeup',
      'salon',
      'bridal',
      'mehndi',
      '\u0628\u06cc\u0648\u0679\u06cc',
      '\u0645\u06cc\u06a9 \u0627\u067e',
      '\u0633\u06cc\u0644\u0648\u0646',
      '\u0645\u06c1\u0646\u062f\u06cc',
      '\u062f\u0644\u06c1\u0646',
      'بیوٹی',
      'میک اپ',
    ])) {
      role = 'Beautician';
      description = 'Beauty Service';
    }

    final urgency = _containsAny(value, [
      'asap',
      'urgent',
      'emergency',
      'jaldi',
      'foran',
      '\u0641\u0648\u0631\u0627\u064b',
      '\u0641\u0648\u0631\u0627',
      '\u062c\u0644\u062f\u06cc',
      '\u0627\u06cc\u0645\u0631\u062c\u0646\u0633\u06cc',
      'فوراً',
      'جلدی',
    ])
        ? 'High'
        : 'Normal';
    final timeLabel = _inferTimeLabel(value);
    final language = _inferLanguage(problem);

    return ServiceIntent(
      role: role,
      description: description,
      urgency: urgency,
      location: location,
      timeLabel: timeLabel,
      language: language,
      confidence: role == 'General' ? 0.72 : 0.93,
    );
  }

  List<UstaadProviderProfile> _rankProviders(ServiceIntent nextIntent) {
    final matching = providers
        .where((provider) =>
            nextIntent.role == 'General' || provider.role == nextIntent.role)
        .toList();
    final pool = matching.isEmpty ? providers : matching;

    final scored = pool.map((provider) {
      final reliability = provider.reliability * 100 * 0.34;
      final distance = math.max(0, 20 - provider.distanceKm) / 20 * 100 * 0.22;
      final rating = provider.rating / 5 * 100 * 0.18;
      final price = math.max(0, 2200 - provider.price) / 2200 * 100 * 0.08;
      final availability = provider.availabilitySlots
              .any((slot) => slot.toLowerCase().contains('today'))
          ? 7
          : 4;
      final experience = math.min(provider.jobsCompleted, 250) / 250 * 7;
      final response = math.max(0, 45 - provider.responseTimeMinutes) / 45 * 6;
      final urgencyBoost =
          nextIntent.urgency == 'High' && provider.reliability >= 0.90 ? 5 : 0;
      final score = reliability +
          distance +
          rating +
          price +
          availability +
          experience +
          response +
          urgencyBoost;
      final reason =
          '${provider.distanceKm} km away, ${provider.responseTimeMinutes} min response, ${provider.rating} rating, ${provider.jobsCompleted} completed jobs.';
      return provider.withScore(score, reason);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored;
  }

  QuoteEstimate _quoteFor(
    UstaadProviderProfile provider,
    ServiceIntent nextIntent,
  ) {
    return QuoteEstimate(
      basePrice: provider.price,
      distancePrice: provider.distanceKm * 50,
      urgencyPrice: nextIntent.urgency == 'High' ? 500 : 0,
    );
  }

  List<WorkflowEvent> _buildWorkflowEvents(
    ServiceIntent nextIntent,
    List<UstaadProviderProfile> ranked,
  ) {
    final best = ranked.first;
    return [
      WorkflowEvent(
        agentName: 'Interpreter',
        step: 'Understand',
        message:
            'Detected ${nextIntent.role}, ${nextIntent.location}, ${nextIntent.timeLabel}; language ${nextIntent.language}; confidence ${(nextIntent.confidence * 100).round()}%.',
        toolName: 'Multilingual parser',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Discovery',
        step: 'Find',
        message:
            'Filtered ${ranked.length} matching providers from Supabase/provider seed.',
        toolName: 'service_providers',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Ranking',
        step: 'Decide',
        message: 'Recommended ${best.name}: ${best.reason}',
        toolName: 'Trust ranking',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Booking',
        step: 'Act',
        message: 'Ready to reserve ${best.nextSlot}.',
        toolName: 'bookings',
        status: 'ready',
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
}
