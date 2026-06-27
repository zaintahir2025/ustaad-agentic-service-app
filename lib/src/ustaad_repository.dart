import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'models.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class UstaadRepository {
  UstaadRepository();

  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const _networkTimeout = Duration(seconds: 8);

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

  UstaadUser _userFromFirebase(auth.User user) {
    return UstaadUser(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      phone: user.phoneNumber,
      avatarUrl: user.photoURL ?? '',
    );
  }

  UstaadUser? currentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _userFromFirebase(user);
  }

  DateTime? currentSessionExpiresAt() {
    // Firebase auth tokens are generally managed automatically
    // You could decode the JWT to find exactly when it expires, but usually we just consider it valid if currentUser is not null.
    // For now returning null or a generic far future date.
    if (_auth.currentUser != null) {
      return DateTime.now().add(const Duration(hours: 1));
    }
    return null;
  }

  Future<UstaadUser?> fetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('profiles').doc(user.uid).get();
      if (!doc.exists) return _userFromFirebase(user);
      return UstaadUser.fromProfileMap(
        doc.data()!,
        fallbackId: user.uid,
        fallbackEmail: user.email ?? '',
      );
    } catch (_) {
      return _userFromFirebase(user);
    }
  }

  Future<UstaadUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('Unable to sign in.');
      }
      return await fetchProfile() ?? _userFromFirebase(user);
    } on auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Unable to sign in.');
    } catch (e) {
      throw const AuthException('Unable to sign in.');
    }
  }

  Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<AuthSignUpResult> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('Unable to create account.');
      }

      await user.updateDisplayName(name);

      _upsertProfileSilently(user.uid, name, email, phone);

      // In Firebase, we can trigger email verification here if we want.
      // await user.sendEmailVerification();
      // Let's assume for now it's not strictly blocking, so emailConfirmationRequired = false
      final confirmationRequired = false;

      return AuthSignUpResult(
        user: await fetchProfile() ?? _userFromFirebase(user),
        emailConfirmationRequired: confirmationRequired,
      );
    } on auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Unable to create account.');
    } catch (e) {
      throw const AuthException('Unable to create account.');
    }
  }

  Future<UstaadUser?> trySignInAfterSignUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final user = await signIn(email: email, password: password);
      _upsertProfileSilently(user.id, name, email, phone);
      return user;
    } catch (_) {
      return null;
    }
  }

  void _upsertProfileSilently(
    String userId,
    String name,
    String email,
    String phone,
  ) {
    _db.collection('profiles').doc(userId).set({
      'id': userId,
      'full_name': name,
      'email': email,
      'phone': phone,
      'city': 'Islamabad',
      'preferred_language': 'English',
    }, SetOptions(merge: true)).catchError((_) {});
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
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to update your profile.');
    }

    try {
      await user.updateDisplayName(name);
      if (avatarUrl != null) {
        await user.updatePhotoURL(avatarUrl);
      }
    } catch (_) {}

    await _db.collection('profiles').doc(user.uid).set({
      'id': user.uid,
      'full_name': name,
      'email': user.email ?? '',
      'phone': phone,
      'avatar_url': avatarUrl ?? '',
      'city': city,
      'address': address,
      'preferred_language': preferredLanguage,
      'bio': bio,
    }, SetOptions(merge: true));

    return await fetchProfile() ??
        _userFromFirebase(user).copyWith(
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
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to upload a profile photo.');
    }

    final cleanName = fileName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_.-]'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    final path = '${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
    
    final ref = _storage.ref().child('avatars').child(path);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  Future<void> resendEmailConfirmation(String email) async {
    final user = _auth.currentUser;
    if (user != null && user.email == email && !user.emailVerified) {
       await user.sendEmailVerification();
    } else {
      throw const AuthException('User not found or already verified.');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Failed to send password reset email.');
    }
  }

  Future<UstaadUser> updatePassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Open the reset link before setting password.');
    }
    try {
      await user.updatePassword(password);
      return await fetchProfile() ?? _userFromFirebase(user);
    } on auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Failed to update password.');
    }
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<List<UstaadProviderProfile>> fetchProviders() async {
    try {
      final snapshot = await _db
          .collection('service_providers')
          .where('active', isEqualTo: true)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs
          .map<UstaadProviderProfile>(
            (doc) => UstaadProviderProfile.fromMap(doc.data()),
          )
          .toList();
    } catch (_) {
      // Return empty or seed if failed
      return seedProviders;
    }
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

  Future<LocationSuggestion> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': latitude.toStringAsFixed(7),
      'lon': longitude.toStringAsFixed(7),
      'format': 'jsonv2',
      'addressdetails': '1',
      'zoom': '18',
    });

    try {
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'Ustaad/1.0 (com.ustaad.service)',
        },
      ).timeout(_networkTimeout);
      if (response.statusCode != 200) {
        return _fallbackReverseLocation(latitude, longitude);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return _fallbackReverseLocation(latitude, longitude);
      }
      final suggestion = LocationSuggestion.fromNominatim(
        Map<String, dynamic>.from(decoded),
      );
      return suggestion.label.trim().isEmpty
          ? _fallbackReverseLocation(latitude, longitude)
          : suggestion;
    } catch (_) {
      return _fallbackReverseLocation(latitude, longitude);
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
    final user = _auth.currentUser;
    if (user == null) return const [];

    try {
      final snapshot = await _db
          .collection('bookings')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map<BookingRecord>(
            (doc) => BookingRecord.fromMap(doc.data()..['id'] = doc.id),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<BookingRecord> createBooking({
    required UstaadProviderProfile provider,
    required ServiceIntent intent,
    required QuoteEstimate quote,
    required String problemText,
    required List<WorkflowEvent> workflowEvents,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to create a booking.');
    }

    final docRef = await _db.collection('bookings').add({
      'user_id': user.uid,
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
      'created_at': FieldValue.serverTimestamp(),
    });

    final bookingDoc = await docRef.get();
    
    try {
      final batch = _db.batch();
      for (var i = 0; i < workflowEvents.length; i++) {
        final event = workflowEvents[i];
        final eventRef = _db.collection('agent_events').doc();
        batch.set(eventRef, {
          'user_id': user.uid,
          'booking_id': docRef.id,
          'sequence': i + 1,
          'agent_name': event.agentName,
          'step': event.step,
          'message': event.message,
          'tool_name': event.toolName,
          'status': event.status,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {
    }

    return BookingRecord.fromMap(
      bookingDoc.data()!..['id'] = docRef.id,
      providerFallback: provider,
    );
  }

  Future<BookingRecord> createEmergencyBooking({
    required UstaadProviderProfile provider,
    required EmergencyRequest emergency,
    required QuoteEstimate quote,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return _localEmergencyBooking(
        provider: provider,
        emergency: emergency,
        quote: quote,
      );
    }

    try {
      final docRef = await _db.collection('bookings').add({
        'user_id': user.uid,
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
        'created_at': FieldValue.serverTimestamp(),
      });

      final bookingDoc = await docRef.get();

      return BookingRecord.fromMap(
        bookingDoc.data()!..['id'] = docRef.id,
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
    final docRef = _db.collection('bookings').doc(bookingId);
    await docRef.update({'status': status});
    final doc = await docRef.get();
    return BookingRecord.fromMap(doc.data()!..['id'] = doc.id);
  }

  Future<List<ReviewRecord>> fetchReviews(String providerId) async {
    try {
      final snapshot = await _db
          .collection('reviews')
          .where('provider_id', isEqualTo: providerId)
          .orderBy('created_at', descending: true)
          .get();
      final reviews = snapshot.docs
          .map<ReviewRecord>(
            (doc) => ReviewRecord.fromMap(doc.data()..['id'] = doc.id),
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
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to leave a review.');
    }

    final docRef = await _db.collection('reviews').add({
      'provider_id': providerId,
      'rating': rating,
      'comment': comment,
      'language': language,
      'booking_id': bookingId,
      'customer_name': user.displayName ?? 'Customer',
      'created_at': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return ReviewRecord.fromMap(doc.data()!..['id'] = doc.id);
  }

  LocationSuggestion _fallbackReverseLocation(
    double latitude,
    double longitude,
  ) {
    final nearest = _nearestKnownLocation(latitude, longitude);
    if (nearest != null) {
      return LocationSuggestion(
        label: 'Near ${nearest.label}',
        subtitle: nearest.subtitle,
        latitude: latitude,
        longitude: longitude,
      );
    }
    return LocationSuggestion(
      label: 'Current location',
      subtitle:
          '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
      latitude: latitude,
      longitude: longitude,
    );
  }

  LocationSuggestion? _nearestKnownLocation(double latitude, double longitude) {
    const locations = [
      LocationSuggestion(
        label: 'G-13, Islamabad',
        subtitle: 'Capital Territory',
        latitude: 33.6493,
        longitude: 72.9712,
      ),
      LocationSuggestion(
        label: 'F-8, Islamabad',
        subtitle: 'Capital Territory',
        latitude: 33.7127,
        longitude: 73.0381,
      ),
      LocationSuggestion(
        label: 'Bahria Town, Rawalpindi',
        subtitle: 'Punjab',
        latitude: 33.5358,
        longitude: 73.1147,
      ),
    ];

    LocationSuggestion? best;
    double bestDist = double.infinity;

    for (final loc in locations) {
      final d = geoDistanceKm(latitude, longitude, loc.latitude, loc.longitude);
      if (d < bestDist && d < 10) {
        bestDist = d;
        best = loc;
      }
    }
    return best;
  }

  List<LocationSuggestion> _fallbackLocations(String query) {
    final lower = query.toLowerCase();
    const all = [
      LocationSuggestion(
        label: 'G-13, Islamabad',
        subtitle: 'Capital Territory, Pakistan',
        latitude: 33.6493,
        longitude: 72.9712,
      ),
      LocationSuggestion(
        label: 'F-8, Islamabad',
        subtitle: 'Capital Territory, Pakistan',
        latitude: 33.7127,
        longitude: 73.0381,
      ),
      LocationSuggestion(
        label: 'Bahria Town Phase 7, Rawalpindi',
        subtitle: 'Punjab, Pakistan',
        latitude: 33.5358,
        longitude: 73.1147,
      ),
      LocationSuggestion(
        label: 'DHA Phase 2, Islamabad',
        subtitle: 'Capital Territory, Pakistan',
        latitude: 33.5262,
        longitude: 73.1491,
      ),
      LocationSuggestion(
        label: 'Blue Area, Islamabad',
        subtitle: 'Commercial Avenue, Pakistan',
        latitude: 33.7088,
        longitude: 73.0531,
      ),
    ];

    final matches = all.where((l) =>
        l.label.toLowerCase().contains(lower) ||
        l.subtitle.toLowerCase().contains(lower));
    return matches.toList();
  }
}

int etaMinutesFor(UstaadProviderProfile provider) {
  if (provider.nextSlot.toLowerCase().contains('today')) {
    return provider.responseTimeMinutes + (provider.distanceKm * 2);
  }
  return 60 * 12;
}
