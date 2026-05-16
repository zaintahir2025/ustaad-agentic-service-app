import 'dart:math' as math;

enum UstaadScreen {
  gateway,
  commandCenter,
  bookings,
  profile,
  selection,
  workflow,
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
