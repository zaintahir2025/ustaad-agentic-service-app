/// Domain Entity representing a verified service provider.
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'reliability': reliability,
      'distance_km': distanceKm,
      'rating': rating,
      'price': price,
      'avatar_url': avatarUrl,
      'verified': verified,
      'city': city,
      'phone': phone,
      'whatsapp': whatsapp,
      'response_time_minutes': responseTimeMinutes,
      'availability_slots': availabilitySlots,
      'jobs_completed': jobsCompleted,
      'latitude': latitude,
      'longitude': longitude,
      'active': true,
    };
  }
}

double _asDouble(dynamic value, {required double fallback}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _asInt(dynamic value, {required int fallback}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => '$item').toList();
  }
  return const ['Today 4:00 PM', 'Tomorrow 10:00 AM'];
}
