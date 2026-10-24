/// Explicit user roles in the Ustaad platform.
/// Stored in Firestore `users/{userId}.role` and enforced server-side.
enum UserRole {
  customer,
  provider,
  admin;

  static UserRole fromString(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'provider':
        return UserRole.provider;
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  String get value => name;

  bool get isCustomer => this == UserRole.customer;
  bool get isProvider => this == UserRole.provider;
  bool get isAdmin => this == UserRole.admin;
}
