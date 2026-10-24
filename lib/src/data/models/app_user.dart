import 'user_role.dart';

/// Clean data model for an authenticated Ustaad user.
class AppUser {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final UserRole role;
  final String city;
  final String area;
  final String address;
  final List<String> fcmTokens;
  final DateTime createdAt;
  final String? avatarUrl;
  final bool isVerified;

  const AppUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.role = UserRole.customer,
    this.city = 'Islamabad',
    this.area = 'F-10',
    this.address = '',
    this.fcmTokens = const [],
    required this.createdAt,
    this.avatarUrl,
    this.isVerified = false,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Ustaad User',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      role: UserRole.fromString(data['role'] as String?),
      city: data['city'] as String? ?? 'Islamabad',
      area: data['area'] as String? ?? 'F-10',
      address: data['address'] as String? ?? '',
      fcmTokens: (data['fcmTokens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is DateTime
              ? data['createdAt'] as DateTime
              : DateTime.tryParse(data['createdAt'].toString()) ??
                  DateTime.now())
          : DateTime.now(),
      avatarUrl: data['avatarUrl'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'role': role.value,
      'city': city,
      'area': area,
      'address': address,
      'fcmTokens': fcmTokens,
      'createdAt': createdAt.toIso8601String(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'isVerified': isVerified,
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? city,
    String? area,
    String? address,
    List<String>? fcmTokens,
    DateTime? createdAt,
    String? avatarUrl,
    bool? isVerified,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      city: city ?? this.city,
      area: area ?? this.area,
      address: address ?? this.address,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
