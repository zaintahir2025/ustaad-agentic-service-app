import 'dart:math' as math;

import 'package:flutter/material.dart';

enum UstaadScreen {
  gateway,
  commandCenter,
  bookings,
  profile,
  selection,
  workflow,
  aiChat,
}

class UstaadUser {
  const UstaadUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl = '',
    this.city = 'Islamabad',
    this.address = '',
    this.preferredLanguage = 'English',
    this.bio = '',
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String avatarUrl;
  final String city;
  final String address;
  final String preferredLanguage;
  final String bio;

  String get firstName =>
      name.trim().isEmpty ? 'Customer' : name.split(' ').first;

  UstaadUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? city,
    String? address,
    String? preferredLanguage,
    String? bio,
  }) {
    return UstaadUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      address: address ?? this.address,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      bio: bio ?? this.bio,
    );
  }

  factory UstaadUser.fromProfileMap(
    Map<String, dynamic> map, {
    required String fallbackId,
    required String fallbackEmail,
  }) {
    return UstaadUser(
      id: '${map['id'] ?? fallbackId}',
      name: '${map['full_name'] ?? fallbackEmail.split('@').first}',
      email: '${map['email'] ?? fallbackEmail}',
      phone: map['phone']?.toString(),
      avatarUrl: '${map['avatar_url'] ?? ''}',
      city: '${map['city'] ?? 'Islamabad'}',
      address: '${map['address'] ?? ''}',
      preferredLanguage: '${map['preferred_language'] ?? 'English'}',
      bio: '${map['bio'] ?? ''}',
    );
  }
}

class AuthSignUpResult {
  const AuthSignUpResult({
    required this.user,
    required this.emailConfirmationRequired,
  });

  final UstaadUser user;
  final bool emailConfirmationRequired;
}

class UstaadProviderProfile {
  const UstaadProviderProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.reliability,
    required this.distanceKm,
    required this.rating,
    required this.price,
    required this.avatarUrl,
    required this.verified,
    required this.city,
    this.phone = '+923001234567',
    this.whatsapp = '+923001234567',
    this.responseTimeMinutes = 18,
    this.availabilitySlots = const ['Today 4:00 PM', 'Tomorrow 10:00 AM'],
    this.jobsCompleted = 120,
    this.score = 0,
    this.reason = '',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String role;
  final double reliability;
  final int distanceKm;
  final double rating;
  final int price;
  final String avatarUrl;
  final bool verified;
  final String city;
  final String phone;
  final String whatsapp;
  final int responseTimeMinutes;
  final List<String> availabilitySlots;
  final int jobsCompleted;
  final double score;
  final String reason;
  final double? latitude;
  final double? longitude;

  String get nextSlot =>
      availabilitySlots.isEmpty ? 'Tomorrow 10:00 AM' : availabilitySlots.first;

  UstaadProviderProfile withScore(double value, String rankingReason) {
    return UstaadProviderProfile(
      id: id,
      name: name,
      role: role,
      reliability: reliability,
      distanceKm: distanceKm,
      rating: rating,
      price: price,
      avatarUrl: avatarUrl,
      verified: verified,
      city: city,
      phone: phone,
      whatsapp: whatsapp,
      responseTimeMinutes: responseTimeMinutes,
      availabilitySlots: availabilitySlots,
      jobsCompleted: jobsCompleted,
      score: value,
      reason: rankingReason,
      latitude: latitude,
      longitude: longitude,
    );
  }

  UstaadProviderProfile withDistanceKm(int value) {
    return UstaadProviderProfile(
      id: id,
      name: name,
      role: role,
      reliability: reliability,
      distanceKm: value,
      rating: rating,
      price: price,
      avatarUrl: avatarUrl,
      verified: verified,
      city: city,
      phone: phone,
      whatsapp: whatsapp,
      responseTimeMinutes: responseTimeMinutes,
      availabilitySlots: availabilitySlots,
      jobsCompleted: jobsCompleted,
      score: score,
      reason: reason,
      latitude: latitude,
      longitude: longitude,
    );
  }

  factory UstaadProviderProfile.fromMap(Map<String, dynamic> map) {
    return UstaadProviderProfile(
      id: '${map['id']}',
      name: '${map['name'] ?? 'Provider'}',
      role: '${map['role'] ?? 'General'}',
      reliability: _asDouble(map['reliability'], fallback: 0.85),
      distanceKm: _asInt(map['distance_km'], fallback: 5),
      rating: _asDouble(map['rating'], fallback: 4.5),
      price: _asInt(map['price'], fallback: 800),
      avatarUrl: '${map['avatar_url'] ?? ''}',
      verified: map['verified'] == true,
      city: '${map['city'] ?? 'Islamabad'}',
      phone: '${map['phone'] ?? '+923001234567'}',
      whatsapp: '${map['whatsapp'] ?? '+923001234567'}',
      responseTimeMinutes: _asInt(map['response_time_minutes'], fallback: 18),
      availabilitySlots: _asStringList(map['availability_slots']),
      jobsCompleted: _asInt(map['jobs_completed'], fallback: 120),
      latitude: map['latitude'] == null
          ? null
          : _asDouble(map['latitude'], fallback: 33.6938),
      longitude: map['longitude'] == null
          ? null
          : _asDouble(map['longitude'], fallback: 73.0652),
    );
  }
}

class BookingRecord {
  const BookingRecord({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.serviceRole,
    required this.problemText,
    required this.location,
    required this.status,
    required this.quoteTotal,
    required this.etaMinutes,
    required this.slotLabel,
    required this.confirmationMessage,
    required this.createdAt,
    this.providerPhone = '',
    this.providerWhatsapp = '',
    this.providerAvatarUrl = '',
    this.providerRating = 0,
  });

  final String id;
  final String providerId;
  final String providerName;
  final String serviceRole;
  final String problemText;
  final String location;
  final String status;
  final int quoteTotal;
  final int etaMinutes;
  final String slotLabel;
  final String confirmationMessage;
  final DateTime createdAt;
  final String providerPhone;
  final String providerWhatsapp;
  final String providerAvatarUrl;
  final double providerRating;

  String get statusLabel {
    return switch (status) {
      'scheduled' => 'Scheduled',
      'en_route' => 'En route',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      'issue_reported' => 'Issue reported',
      _ => status,
    };
  }

  bool get canReview => status == 'completed' || status == 'en_route';

  BookingRecord copyWith({
    String? status,
  }) {
    return BookingRecord(
      id: id,
      providerId: providerId,
      providerName: providerName,
      serviceRole: serviceRole,
      problemText: problemText,
      location: location,
      status: status ?? this.status,
      quoteTotal: quoteTotal,
      etaMinutes: etaMinutes,
      slotLabel: slotLabel,
      confirmationMessage: confirmationMessage,
      createdAt: createdAt,
      providerPhone: providerPhone,
      providerWhatsapp: providerWhatsapp,
      providerAvatarUrl: providerAvatarUrl,
      providerRating: providerRating,
    );
  }

  factory BookingRecord.local({
    required UstaadProviderProfile provider,
    required ServiceIntent intent,
    required QuoteEstimate quote,
    required String problemText,
  }) {
    return BookingRecord(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      providerId: provider.id,
      providerName: provider.name,
      serviceRole: provider.role,
      problemText: problemText,
      location: intent.location,
      status: 'en_route',
      quoteTotal: quote.total,
      etaMinutes: etaMinutesFor(provider),
      slotLabel: provider.nextSlot,
      confirmationMessage:
          'Confirmed ${provider.role} with ${provider.name} for ${provider.nextSlot}.',
      createdAt: DateTime.now(),
      providerPhone: provider.phone,
      providerWhatsapp: provider.whatsapp,
      providerAvatarUrl: provider.avatarUrl,
      providerRating: provider.rating,
    );
  }

  factory BookingRecord.fromMap(
    Map<String, dynamic> map, {
    UstaadProviderProfile? providerFallback,
  }) {
    final provider = map['service_providers'];
    final providerMap =
        provider is Map ? Map<String, dynamic>.from(provider) : null;
    return BookingRecord(
      id: '${map['id']}',
      providerId: '${map['provider_id'] ?? providerFallback?.id ?? ''}',
      providerName:
          '${map['provider_name'] ?? providerFallback?.name ?? 'Provider'}',
      serviceRole:
          '${map['service_role'] ?? providerFallback?.role ?? 'General'}',
      problemText: '${map['problem_text'] ?? ''}',
      location: '${map['service_location'] ?? ''}',
      status: '${map['status'] ?? 'scheduled'}',
      quoteTotal:
          _asInt(map['quote_total'], fallback: providerFallback?.price ?? 0),
      etaMinutes: _asInt(
        map['eta_minutes'],
        fallback:
            providerFallback == null ? 15 : etaMinutesFor(providerFallback),
      ),
      slotLabel:
          '${map['slot_label'] ?? providerFallback?.nextSlot ?? 'Next available slot'}',
      confirmationMessage: '${map['confirmation_message'] ?? ''}',
      createdAt: _asDateTime(map['created_at']) ?? DateTime.now(),
      providerPhone:
          '${map['provider_phone'] ?? providerMap?['phone'] ?? providerFallback?.phone ?? ''}',
      providerWhatsapp:
          '${map['provider_whatsapp'] ?? providerMap?['whatsapp'] ?? providerFallback?.whatsapp ?? ''}',
      providerAvatarUrl:
          '${providerMap?['avatar_url'] ?? providerFallback?.avatarUrl ?? ''}',
      providerRating: _asDouble(
        providerMap?['rating'],
        fallback: providerFallback?.rating ?? 0,
      ),
    );
  }
}

class ReviewRecord {
  const ReviewRecord({
    required this.id,
    required this.providerId,
    required this.rating,
    required this.comment,
    required this.customerName,
    required this.language,
    required this.createdAt,
    this.bookingId,
    this.customerAvatarUrl = '',
  });

  final String id;
  final String providerId;
  final int rating;
  final String comment;
  final String customerName;
  final String language;
  final DateTime createdAt;
  final String? bookingId;
  final String customerAvatarUrl;

  factory ReviewRecord.fromMap(Map<String, dynamic> map) {
    return ReviewRecord(
      id: '${map['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      providerId: '${map['provider_id']}',
      rating: _asInt(map['rating'], fallback: 5),
      comment: '${map['comment'] ?? ''}',
      customerName: '${map['customer_name'] ?? 'Customer'}',
      customerAvatarUrl: '${map['customer_avatar_url'] ?? ''}',
      language: '${map['language'] ?? 'English'}',
      bookingId: map['booking_id']?.toString(),
      createdAt: _asDateTime(map['created_at']) ?? DateTime.now(),
    );
  }
}

class ServiceIntent {
  const ServiceIntent({
    required this.role,
    required this.description,
    required this.urgency,
    required this.location,
    required this.timeLabel,
    required this.language,
    required this.confidence,
  });

  final String role;
  final String description;
  final String urgency;
  final String location;
  final String timeLabel;
  final String language;
  final double confidence;
}

class QuoteEstimate {
  const QuoteEstimate({
    required this.basePrice,
    required this.distancePrice,
    required this.urgencyPrice,
  });

  final int basePrice;
  final int distancePrice;
  final int urgencyPrice;

  int get total => basePrice + distancePrice + urgencyPrice;
}

class WorkflowEvent {
  const WorkflowEvent({
    required this.agentName,
    required this.step,
    required this.message,
    required this.toolName,
    required this.status,
  });

  final String agentName;
  final String step;
  final String message;
  final String toolName;
  final String status;
}

class EmergencyRequest {
  const EmergencyRequest({
    required this.id,
    required this.serviceType,
    required this.location,
    required this.urgencyLevel,
    required this.requestedAt,
    this.status = 'dispatching',
  });

  final String id;
  final String serviceType;
  final String location;
  final String urgencyLevel;
  final DateTime requestedAt;
  final String status;

  factory EmergencyRequest.now(String serviceType, String location) {
    final now = DateTime.now();
    return EmergencyRequest(
      id: 'emergency-${now.microsecondsSinceEpoch}',
      serviceType: serviceType,
      location: location,
      urgencyLevel: 'CRITICAL',
      requestedAt: now,
    );
  }
}

class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    this.unlocked = false,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String emoji;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;

  AchievementBadge copyWith({
    bool? unlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementBadge(
      id: id,
      title: title,
      emoji: emoji,
      description: description,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  static List<AchievementBadge> defaultBadges() {
    return const [
      AchievementBadge(
        id: 'first_request',
        title: 'First Request',
        emoji: '🚀',
        description: 'Made your first service request',
      ),
      AchievementBadge(
        id: 'first_booking',
        title: 'First Booking',
        emoji: '🏆',
        description: 'Successfully booked your first Ustaad',
      ),
      AchievementBadge(
        id: 'multilingual',
        title: 'Language Master',
        emoji: '🌐',
        description: 'Used Urdu or Roman Urdu input',
      ),
      AchievementBadge(
        id: 'emergency_hero',
        title: 'Emergency Hero',
        emoji: '⚡',
        description: 'Used Emergency Fast-Track mode',
      ),
      AchievementBadge(
        id: 'power_user',
        title: 'Power User',
        emoji: '💎',
        description: 'Made 3 or more bookings',
      ),
    ];
  }
}

class SmartSuggestion {
  const SmartSuggestion({
    required this.label,
    required this.fullText,
    required this.category,
    required this.icon,
  });

  final String label;
  final String fullText;
  final String category;
  final IconData icon;

  static List<SmartSuggestion> popularSuggestions() {
    return const [
      SmartSuggestion(
        label: 'AC Repair - G-13',
        fullText: 'Mujhe kal subah G-13 mein AC technician chahiye',
        category: 'popular',
        icon: Icons.ac_unit,
      ),
      SmartSuggestion(
        label: 'Kitchen leak',
        fullText: 'Urgent pani leak in kitchen, plumber chahiye',
        category: 'popular',
        icon: Icons.water_drop,
      ),
      SmartSuggestion(
        label: 'Electrician',
        fullText: 'Bijli ka masla hai, electrician foran chahiye',
        category: 'popular',
        icon: Icons.electrical_services,
      ),
      SmartSuggestion(
        label: 'Deep cleaning',
        fullText: 'I need deep cleaning service for my apartment',
        category: 'popular',
        icon: Icons.cleaning_services,
      ),
      SmartSuggestion(
        label: 'Math tutor',
        fullText: 'Math tutor chahiye grade 8 ke liye',
        category: 'popular',
        icon: Icons.school,
      ),
      SmartSuggestion(
        label: 'Beautician',
        fullText: 'Home beautician chahiye makeup aur styling ke liye',
        category: 'popular',
        icon: Icons.face_retouching_natural,
      ),
    ];
  }
}

class ProviderMapMarker {
  const ProviderMapMarker({
    required this.providerId,
    required this.providerName,
    required this.role,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.distanceKm,
    this.isRecommended = false,
  });

  final String providerId;
  final String providerName;
  final String role;
  final double latitude;
  final double longitude;
  final double rating;
  final int distanceKm;
  final bool isRecommended;

  static List<ProviderMapMarker> mockMarkersForIslamabad() {
    return const [
      ProviderMapMarker(
        providerId: '00000000-0000-0000-0000-000000000001',
        providerName: 'Ahmed Khan',
        role: 'Electrician',
        latitude: 33.6938,
        longitude: 73.0652,
        rating: 4.9,
        distanceKm: 5,
        isRecommended: true,
      ),
      ProviderMapMarker(
        providerId: '00000000-0000-0000-0000-000000000002',
        providerName: 'Bilal Tariq',
        role: 'Electrician',
        latitude: 33.7215,
        longitude: 73.0433,
        rating: 4.2,
        distanceKm: 2,
      ),
      ProviderMapMarker(
        providerId: '00000000-0000-0000-0000-000000000003',
        providerName: 'Kamran Ali',
        role: 'Plumber',
        latitude: 33.6835,
        longitude: 73.0477,
        rating: 4.7,
        distanceKm: 8,
      ),
      ProviderMapMarker(
        providerId: '00000000-0000-0000-0000-000000000004',
        providerName: 'Sajid Hussain',
        role: 'AC Repair',
        latitude: 33.7083,
        longitude: 73.0479,
        rating: 4.5,
        distanceKm: 3,
      ),
      ProviderMapMarker(
        providerId: '00000000-0000-0000-0000-000000000005',
        providerName: 'Usman Ghani',
        role: 'Electrician',
        latitude: 33.6602,
        longitude: 73.1167,
        rating: 5.0,
        distanceKm: 12,
      ),
      ProviderMapMarker(
        providerId: '00000000-0000-0000-0000-000000000006',
        providerName: 'Nadia Services',
        role: 'Cleaning',
        latitude: 33.7294,
        longitude: 73.0935,
        rating: 4.8,
        distanceKm: 6,
      ),
      ProviderMapMarker(
        providerId: '00000000-0000-0000-0000-000000000007',
        providerName: 'Ayesha Tutors',
        role: 'Tutor',
        latitude: 33.7018,
        longitude: 73.0551,
        rating: 4.9,
        distanceKm: 4,
      ),
      ProviderMapMarker(
        providerId: '00000000-0000-0000-0000-000000000008',
        providerName: 'Zara Beauty Studio',
        role: 'Beautician',
        latitude: 33.7139,
        longitude: 73.1089,
        rating: 4.8,
        distanceKm: 7,
      ),
    ];
  }
}

class LocationSuggestion {
  const LocationSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
    this.subtitle = '',
  });

  final String label;
  final String subtitle;
  final double latitude;
  final double longitude;

  String get locationText {
    return label;
  }

  String get coordinateText =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  factory LocationSuggestion.fromNominatim(Map<String, dynamic> map) {
    final display = '${map['display_name'] ?? 'Islamabad'}';
    final parts = display.split(',').map((part) => part.trim()).toList();
    final title = parts.take(2).join(', ');
    final subtitle = parts.skip(2).take(3).join(', ');
    return LocationSuggestion(
      label: title.isEmpty ? display : title,
      subtitle: subtitle,
      latitude: _asDouble(map['lat'], fallback: 33.6938),
      longitude: _asDouble(map['lon'], fallback: 73.0652),
    );
  }
}

class RouteEstimate {
  const RouteEstimate({
    required this.distanceKm,
    required this.durationMinutes,
    required this.source,
  });

  final double distanceKm;
  final int durationMinutes;
  final String source;

  factory RouteEstimate.fromOsrm(Map<String, dynamic> map) {
    final routes = map['routes'];
    final route = routes is List && routes.isNotEmpty ? routes.first : null;
    final routeMap = route is Map ? Map<String, dynamic>.from(route) : null;
    return RouteEstimate(
      distanceKm: _asDouble(routeMap?['distance'], fallback: 0) / 1000,
      durationMinutes: math.max(
          1, (_asDouble(routeMap?['duration'], fallback: 60) / 60).round()),
      source: 'OSRM',
    );
  }

  factory RouteEstimate.fallback({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final km = _haversineKm(fromLat, fromLng, toLat, toLng);
    return RouteEstimate(
      distanceKm: km,
      durationMinutes: math.max(5, (km * 4).round()),
      source: 'Local estimate',
    );
  }
}

double geoDistanceKm(
  double fromLat,
  double fromLng,
  double toLat,
  double toLng,
) {
  const earthKm = 6371.0;
  final dLat = _degreesToRadians(toLat - fromLat);
  final dLng = _degreesToRadians(toLng - fromLng);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degreesToRadians(fromLat)) *
          math.cos(_degreesToRadians(toLat)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _haversineKm(
  double fromLat,
  double fromLng,
  double toLat,
  double toLng,
) {
  return geoDistanceKm(fromLat, fromLng, toLat, toLng);
}

double _degreesToRadians(double value) {
  return value * math.pi / 180;
}

int etaMinutesFor(UstaadProviderProfile provider) {
  return math.max(8, provider.distanceKm * 3).toInt();
}

int _asInt(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

double _asDouble(Object? value, {required double fallback}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? fallback;
}

List<String> _asStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => '$item')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const ['Today 4:00 PM', 'Tomorrow 10:00 AM'];
}

DateTime? _asDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse('$value');
}
