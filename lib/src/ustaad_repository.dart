import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class UstaadRepository {
  UstaadRepository(this._client);

  final SupabaseClient _client;
  static const _networkTimeout = Duration(seconds: 8);
  static const _nativeAuthRedirectUrl = 'com.ustaad.service://auth-callback';

  static const List<UstaadProviderProfile> seedProviders = [
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Ahmed Khan',
      role: 'Electrician',
      reliability: 0.95,
      distanceKm: 5,
      rating: 4.9,
      price: 500,
      avatarUrl: 'https://i.pravatar.cc/100?img=11',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111001',
      whatsapp: '+923001111001',
      responseTimeMinutes: 14,
      availabilitySlots: ['Today 4:00 PM', 'Tomorrow 10:00 AM'],
      jobsCompleted: 182,
      latitude: 33.6938,
      longitude: 73.0652,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000002',
      name: 'Bilal Tariq',
      role: 'Electrician',
      reliability: 0.80,
      distanceKm: 2,
      rating: 4.2,
      price: 400,
      avatarUrl: 'https://i.pravatar.cc/100?img=12',
      verified: false,
      city: 'Rawalpindi',
      phone: '+923001111002',
      whatsapp: '+923001111002',
      responseTimeMinutes: 18,
      availabilitySlots: ['Today 6:30 PM', 'Tomorrow 11:30 AM'],
      jobsCompleted: 74,
      latitude: 33.7215,
      longitude: 73.0433,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000003',
      name: 'Kamran Ali',
      role: 'Plumber',
      reliability: 0.90,
      distanceKm: 8,
      rating: 4.7,
      price: 600,
      avatarUrl: 'https://i.pravatar.cc/100?img=13',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111003',
      whatsapp: '+923001111003',
      responseTimeMinutes: 16,
      availabilitySlots: ['Tomorrow 9:30 AM', 'Tomorrow 3:00 PM'],
      jobsCompleted: 141,
      latitude: 33.6835,
      longitude: 73.0477,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000004',
      name: 'Sajid Hussain',
      role: 'AC Repair',
      reliability: 0.85,
      distanceKm: 3,
      rating: 4.5,
      price: 800,
      avatarUrl: 'https://i.pravatar.cc/100?img=14',
      verified: true,
      city: 'Lahore',
      phone: '+923001111004',
      whatsapp: '+923001111004',
      responseTimeMinutes: 20,
      availabilitySlots: ['Tomorrow 10:00 AM', 'Tomorrow 5:00 PM'],
      jobsCompleted: 217,
      latitude: 33.7083,
      longitude: 73.0479,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000005',
      name: 'Usman Ghani',
      role: 'Electrician',
      reliability: 0.98,
      distanceKm: 12,
      rating: 5.0,
      price: 700,
      avatarUrl: 'https://i.pravatar.cc/100?img=15',
      verified: true,
      city: 'Karachi',
      phone: '+923001111005',
      whatsapp: '+923001111005',
      responseTimeMinutes: 22,
      availabilitySlots: ['Today 8:00 PM', 'Tomorrow 2:00 PM'],
      jobsCompleted: 236,
      latitude: 33.6602,
      longitude: 73.1167,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000006',
      name: 'Nadia Services',
      role: 'Cleaning',
      reliability: 0.92,
      distanceKm: 6,
      rating: 4.8,
      price: 650,
      avatarUrl: 'https://i.pravatar.cc/100?img=16',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111006',
      whatsapp: '+923001111006',
      responseTimeMinutes: 24,
      availabilitySlots: ['Today 5:30 PM', 'Tomorrow 12:00 PM'],
      jobsCompleted: 96,
      latitude: 33.7294,
      longitude: 73.0935,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000007',
      name: 'Ayesha Tutors',
      role: 'Tutor',
      reliability: 0.94,
      distanceKm: 4,
      rating: 4.9,
      price: 1200,
      avatarUrl: 'https://i.pravatar.cc/100?img=17',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111007',
      whatsapp: '+923001111007',
      responseTimeMinutes: 35,
      availabilitySlots: ['Tomorrow 9:00 AM', 'Tomorrow 6:00 PM'],
      jobsCompleted: 128,
      latitude: 33.7018,
      longitude: 73.0551,
    ),
    UstaadProviderProfile(
      id: '00000000-0000-0000-0000-000000000008',
      name: 'Zara Beauty Studio',
      role: 'Beautician',
      reliability: 0.91,
      distanceKm: 7,
      rating: 4.8,
      price: 1500,
      avatarUrl: 'https://i.pravatar.cc/100?img=18',
      verified: true,
      city: 'Islamabad',
      phone: '+923001111008',
      whatsapp: '+923001111008',
      responseTimeMinutes: 40,
      availabilitySlots: ['Today 7:00 PM', 'Tomorrow 1:00 PM'],
      jobsCompleted: 109,
      latitude: 33.7139,
      longitude: 73.1089,
    ),
  ];

  static final Map<String, List<ReviewRecord>> seedReviews = {
    '00000000-0000-0000-0000-000000000001': [
      ReviewRecord(
        id: 'seed-review-1',
        providerId: '00000000-0000-0000-0000-000000000001',
        rating: 5,
        comment: 'Clean work, clear pricing, arrived on time.',
        customerName: 'Verified customer',
        language: 'English',
        createdAt: DateTime(2026, 5, 10),
      ),
    ],
    '00000000-0000-0000-0000-000000000003': [
      ReviewRecord(
        id: 'seed-review-2',
        providerId: '00000000-0000-0000-0000-000000000003',
        rating: 5,
        comment: 'Kitchen leak fixed fast. Bohat professional.',
        customerName: 'Verified customer',
        language: 'Roman Urdu',
        createdAt: DateTime(2026, 5, 11),
      ),
    ],
    '00000000-0000-0000-0000-000000000004': [
      ReviewRecord(
        id: 'seed-review-3',
        providerId: '00000000-0000-0000-0000-000000000004',
        rating: 4,
        comment: 'AC cooling restored and the status updates were useful.',
        customerName: 'Verified customer',
        language: 'English',
        createdAt: DateTime(2026, 5, 12),
      ),
    ],
  };

  UstaadUser? currentUser() {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _userFromSupabase(user);
  }

  DateTime? currentSessionExpiresAt() {
    final expiresAt = _client.auth.currentSession?.expiresAt;
    if (expiresAt == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
  }

  Future<UstaadUser?> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final rows =
          await _client.from('profiles').select().eq('id', user.id).limit(1);
      if (rows.isEmpty) return _userFromSupabase(user);
      return UstaadUser.fromProfileMap(
        Map<String, dynamic>.from(rows.first),
        fallbackId: user.id,
        fallbackEmail: user.email ?? '',
      );
    } catch (_) {
      return _userFromSupabase(user);
    }
  }

  Future<UstaadUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Unable to sign in.');
    }
    return await fetchProfile() ?? _userFromSupabase(user);
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  String authRedirectUrl() {
    if (!kIsWeb) return _nativeAuthRedirectUrl;
    final base = Uri.base;
    final path = base.path.isEmpty
        ? '/'
        : base.path.endsWith('/')
            ? base.path
            : '${base.path}/';
    return '${base.origin}$path';
  }

  Future<AuthSignUpResult> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: authRedirectUrl(),
      data: {
        'full_name': name,
        'phone': phone,
        'preferred_language': 'English'
      },
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Unable to create account.');
    }

    final confirmationRequired = response.session == null;
    if (!confirmationRequired) {
      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': name,
          'email': email,
          'phone': phone,
          'city': 'Islamabad',
          'preferred_language': 'English',
        });
      } catch (_) {
        // The account can still be usable while the SQL migration is pending.
      }
    }

    return AuthSignUpResult(
      user: await fetchProfile() ?? _userFromSupabase(user),
      emailConfirmationRequired: confirmationRequired,
    );
  }

  Future<UstaadUser> updateProfile({
    required String name,
    required String phone,
    required String city,
    required String address,
    required String preferredLanguage,
    required String bio,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to update your profile.');
    }

    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': name,
          'phone': phone,
          'avatar_url': avatarUrl ?? '',
          'preferred_language': preferredLanguage,
        },
      ),
    );

    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': name,
      'email': user.email ?? '',
      'phone': phone,
      'avatar_url': avatarUrl ?? '',
      'city': city,
      'address': address,
      'preferred_language': preferredLanguage,
      'bio': bio,
    });

    return await fetchProfile() ??
        _userFromSupabase(user).copyWith(
          name: name,
          phone: phone,
          city: city,
          address: address,
          preferredLanguage: preferredLanguage,
          bio: bio,
          avatarUrl: avatarUrl,
        );
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to upload a profile photo.');
    }

    final cleanName = fileName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_.-]'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    final path =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> resendEmailConfirmation(String email) {
    return _client.auth.resend(
      email: email,
      type: OtpType.signup,
      emailRedirectTo: authRedirectUrl(),
    );
  }

  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: authRedirectUrl(),
    );
  }

  Future<UstaadUser> updatePassword(String password) async {
    final response = await _client.auth.updateUser(
      UserAttributes(password: password),
    );
    final updatedUser = response.user ?? _client.auth.currentUser;
    if (updatedUser == null) {
      throw const AuthException('Open the reset link before setting password.');
    }
    return await fetchProfile() ?? _userFromSupabase(updatedUser);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<List<UstaadProviderProfile>> fetchProviders() async {
    final rows = await _client
        .from('service_providers')
        .select()
        .eq('active', true)
        .order('rating', ascending: false);

    return rows
        .map<UstaadProviderProfile>(
          (row) =>
              UstaadProviderProfile.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<LocationSuggestion>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$trimmed, Pakistan',
      'format': 'jsonv2',
      'limit': '5',
      'addressdetails': '1',
    });

    try {
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'Ustaad/1.0 (com.ustaad.service)',
        },
      ).timeout(_networkTimeout);
      if (response.statusCode != 200) return _fallbackLocations(trimmed);
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return _fallbackLocations(trimmed);
      final results = decoded
          .whereType<Map>()
          .map((item) => LocationSuggestion.fromNominatim(
                Map<String, dynamic>.from(item),
              ))
          .toList();
      return results.isEmpty ? _fallbackLocations(trimmed) : results;
    } catch (_) {
      return _fallbackLocations(trimmed);
    }
  }

  Future<RouteEstimate> estimateRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$fromLng,$fromLat;$toLng,$toLat?overview=false',
    );

    try {
      final response = await http.get(uri).timeout(_networkTimeout);
      if (response.statusCode != 200) {
        return RouteEstimate.fallback(
          fromLat: fromLat,
          fromLng: fromLng,
          toLat: toLat,
          toLng: toLng,
        );
      }
      return RouteEstimate.fromOsrm(
        Map<String, dynamic>.from(jsonDecode(response.body)),
      );
    } catch (_) {
      return RouteEstimate.fallback(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );
    }
  }

  Future<List<BookingRecord>> fetchBookings() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];

    try {
      final rows = await _client
          .from('bookings')
          .select(
            '*, service_providers(phone, whatsapp, avatar_url, rating)',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return rows
          .map<BookingRecord>(
            (row) => BookingRecord.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
    } catch (_) {
      final rows = await _client
          .from('bookings')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return rows
          .map<BookingRecord>(
            (row) => BookingRecord.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
    }
  }

  Future<BookingRecord> createBooking({
    required UstaadProviderProfile provider,
    required ServiceIntent intent,
    required QuoteEstimate quote,
    required String problemText,
    required List<WorkflowEvent> workflowEvents,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to create a booking.');
    }

    final booking = await _client
        .from('bookings')
        .insert({
          'user_id': user.id,
          'provider_id': provider.id,
          'provider_name': provider.name,
          'service_role': provider.role,
          'problem_text': problemText,
          'service_location': intent.location,
          'urgency': intent.urgency.toLowerCase(),
          'quote_base': quote.basePrice,
          'quote_distance': quote.distancePrice,
          'quote_urgency': quote.urgencyPrice,
          'quote_total': quote.total,
          'status': 'en_route',
          'eta_minutes': etaMinutesFor(provider),
          'slot_label': provider.nextSlot,
          'provider_phone': provider.phone,
          'provider_whatsapp': provider.whatsapp,
          'confirmation_message':
              'Confirmed ${provider.role} with ${provider.name} for ${provider.nextSlot}.',
        })
        .select()
        .single();

    final bookingId = '${booking['id']}';
    try {
      await _client.from('agent_events').insert(
            workflowEvents.asMap().entries.map((entry) {
              final event = entry.value;
              return {
                'user_id': user.id,
                'booking_id': bookingId,
                'sequence': entry.key + 1,
                'agent_name': event.agentName,
                'step': event.step,
                'message': event.message,
                'tool_name': event.toolName,
                'status': event.status,
              };
            }).toList(),
          );
    } catch (_) {
      // Booking is still valid if the optional trace table is not migrated yet.
    }

    return BookingRecord.fromMap(
      Map<String, dynamic>.from(booking),
      providerFallback: provider,
    );
  }

  Future<BookingRecord> createEmergencyBooking({
    required UstaadProviderProfile provider,
    required EmergencyRequest emergency,
    required QuoteEstimate quote,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return _localEmergencyBooking(
        provider: provider,
        emergency: emergency,
        quote: quote,
      );
    }

    try {
      final booking = await _client
          .from('bookings')
          .insert({
            'user_id': user.id,
            'provider_id': provider.id,
            'provider_name': provider.name,
            'service_role': provider.role,
            'problem_text': 'Emergency ${emergency.serviceType} request',
            'service_location': emergency.location,
            'urgency': 'CRITICAL',
            'quote_base': quote.basePrice,
            'quote_distance': quote.distancePrice,
            'quote_urgency': quote.urgencyPrice,
            'quote_total': quote.total,
            'status': 'en_route',
            'eta_minutes': 10,
            'slot_label': 'Immediate dispatch',
            'provider_phone': provider.phone,
            'provider_whatsapp': provider.whatsapp,
            'confirmation_message':
                'EMERGENCY booking - provider dispatched immediately.',
          })
          .select()
          .single();

      return BookingRecord.fromMap(
        Map<String, dynamic>.from(booking),
        providerFallback: provider,
      );
    } catch (_) {
      return _localEmergencyBooking(
        provider: provider,
        emergency: emergency,
        quote: quote,
      );
    }
  }

  BookingRecord _localEmergencyBooking({
    required UstaadProviderProfile provider,
    required EmergencyRequest emergency,
    required QuoteEstimate quote,
  }) {
    return BookingRecord(
      id: 'local-emergency-${DateTime.now().microsecondsSinceEpoch}',
      providerId: provider.id,
      providerName: provider.name,
      serviceRole: provider.role,
      problemText: 'Emergency ${emergency.serviceType} request',
      location: emergency.location,
      status: 'en_route',
      quoteTotal: quote.total,
      etaMinutes: 10,
      slotLabel: 'Immediate dispatch',
      confirmationMessage:
          'EMERGENCY booking - provider dispatched immediately.',
      createdAt: DateTime.now(),
      providerPhone: provider.phone,
      providerWhatsapp: provider.whatsapp,
      providerAvatarUrl: provider.avatarUrl,
      providerRating: provider.rating,
    );
  }

  Future<BookingRecord> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final row = await _client
        .from('bookings')
        .update({'status': status})
        .eq('id', bookingId)
        .select()
        .single();
    return BookingRecord.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<ReviewRecord>> fetchReviews(String providerId) async {
    try {
      final rows = await _client
          .from('reviews')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      final reviews = rows
          .map<ReviewRecord>(
            (row) => ReviewRecord.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
      return reviews.isEmpty ? (seedReviews[providerId] ?? const []) : reviews;
    } catch (_) {
      return seedReviews[providerId] ?? const [];
    }
  }

  List<LocationSuggestion> _fallbackLocations(String query) {
    final lower = query.toLowerCase();
    const locations = [
      LocationSuggestion(
        label: 'G-13, Islamabad',
        subtitle: 'Islamabad Capital Territory',
        latitude: 33.6938,
        longitude: 73.0652,
      ),
      LocationSuggestion(
        label: 'F-8, Islamabad',
        subtitle: 'Islamabad Capital Territory',
        latitude: 33.7215,
        longitude: 73.0433,
      ),
      LocationSuggestion(
        label: 'I-8, Islamabad',
        subtitle: 'Islamabad Capital Territory',
        latitude: 33.6835,
        longitude: 73.0477,
      ),
      LocationSuggestion(
        label: 'E-11, Islamabad',
        subtitle: 'Islamabad Capital Territory',
        latitude: 33.7294,
        longitude: 73.0935,
      ),
      LocationSuggestion(
        label: 'Blue Area, Islamabad',
        subtitle: 'Islamabad Capital Territory',
        latitude: 33.7136,
        longitude: 73.0605,
      ),
    ];

    final matches = locations
        .where((location) => location.label.toLowerCase().contains(lower))
        .toList();
    return matches.isEmpty ? locations.take(3).toList() : matches;
  }

  Future<ReviewRecord> createReview({
    required String providerId,
    required int rating,
    required String comment,
    required String language,
    String? bookingId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to add a review.');
    }

    final profile = await fetchProfile();
    final payload = {
      'user_id': user.id,
      'provider_id': providerId,
      'rating': rating,
      'comment': comment,
      'customer_name': profile?.name ?? _userFromSupabase(user).name,
      'customer_avatar_url': profile?.avatarUrl ?? '',
      'language': language,
      if (bookingId != null && !bookingId.startsWith('local-'))
        'booking_id': bookingId,
    };

    final row = await _client.from('reviews').insert(payload).select().single();
    return ReviewRecord.fromMap(Map<String, dynamic>.from(row));
  }

  UstaadUser _userFromSupabase(User user) {
    final meta = user.userMetadata ?? <String, dynamic>{};
    final fullName = '${meta['full_name'] ?? ''}'.trim();
    return UstaadUser(
      id: user.id,
      name: fullName.isEmpty
          ? (user.email ?? 'Customer').split('@').first
          : fullName,
      email: user.email ?? '',
      phone: meta['phone']?.toString(),
      avatarUrl: '${meta['avatar_url'] ?? ''}',
      city: '${meta['city'] ?? 'Islamabad'}',
      address: '${meta['address'] ?? ''}',
      preferredLanguage: '${meta['preferred_language'] ?? 'English'}',
      bio: '${meta['bio'] ?? ''}',
    );
  }
}
