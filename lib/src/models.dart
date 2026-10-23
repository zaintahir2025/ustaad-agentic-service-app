import 'dart:math' as math;

import 'package:flutter/material.dart';

export 'domain/entities/service_intent.dart';
export 'domain/entities/quote_estimate.dart';
export 'domain/entities/provider_profile.dart';
export 'domain/entities/workflow_event.dart';
export 'domain/entities/achievement_badge.dart';

import 'domain/entities/service_intent.dart';
import 'domain/entities/quote_estimate.dart';
import 'domain/entities/provider_profile.dart';

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
    this.userOffer,
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
  final int? userOffer;

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
    int? userOffer,
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
      userOffer: userOffer ?? this.userOffer,
    );
  }

  factory BookingRecord.local({
    required UstaadProviderProfile provider,
    required ServiceIntent intent,
    required QuoteEstimate quote,
    required String problemText,
    int? offer,
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
      userOffer: offer ?? quote.userOffer ?? intent.userBudget,
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
      userOffer: map['user_offer'] == null
          ? null
          : _asInt(map['user_offer'], fallback: 0),
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



class AIChatMessage {
  const AIChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedRole,
    this.suggestedAction,
    this.suggestedBudget,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? suggestedRole;
  final String? suggestedAction;
  final int? suggestedBudget;
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

DateTime? _asDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse('$value');
}
