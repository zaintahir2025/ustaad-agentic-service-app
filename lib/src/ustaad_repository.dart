import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class UstaadRepository {
  UstaadRepository(this._client);

  final SupabaseClient _client;

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

  Future<UstaadUser> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
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

    if (response.session != null) {
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

    return await fetchProfile() ?? _userFromSupabase(user);
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

  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email);
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
