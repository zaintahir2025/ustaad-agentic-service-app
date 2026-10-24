# Ustaad Backend Architecture & Industrial Specification (BACKEND.md)

## 1. Overview
This document specifies the backend architecture, Firestore data schema, Cloud Functions, security rules, and authentication flows for the **Ustaad** home services platform.

---

## 2. Authentication & Identity Architecture
Ustaad supports two first-class authentication providers tailored for the Pakistani market:
1. **Pakistani Phone Number Auth (OTP)**:
   - Formatted using the international E.164 convention (`+923XXXXXXXXX`) or local format (`03XXXXXXXXX`).
   - OTP verification codes are 6-digit numeric sequences dispatched via Firebase Authentication.
   - Handled with typed result objects (`Success<AppUser>` / `Failure<AuthError>`).
2. **Email & Password Auth**:
   - Standard email verification and password reset workflows.
3. **Role-Based Access Control (RBAC)**:
   - Supported roles: `customer`, `provider`, `admin`.
   - Role is stored in `users/{userId}.role` and enforced across security rules and Cloud Functions.
4. **Session Persistence**:
   - Encrypted token persistence across app restarts.
   - On sign-out, local session credentials, provider caches, and device FCM tokens are cleared.

---

## 3. Firestore Data Model

### Collection: `users/{userId}`
Stores customer and provider base accounts.
```json
{
  "name": "Tariq Mehmood",
  "phone": "+923001234567",
  "email": "tariq@example.pk",
  "role": "customer", // "customer" | "provider" | "admin"
  "createdAt": "2026-10-24T03:00:00.000Z",
  "fcmTokens": ["fcm_token_device_1", "fcm_token_device_2"],
  "address": "House 12, Street 4, F-10/2",
  "city": "Islamabad",
  "area": "F-10",
  "avatarUrl": "https://storage.googleapis.com/...",
  "isVerified": false
}
```

### Collection: `providers/{providerId}`
Detailed service provider profiles and metrics.
```json
{
  "userId": "user_uid_foreign_key",
  "businessName": "Ali AC & Refrigeration Services",
  "services": ["AC_REPAIR", "AC_GAS_REFILL", "SPLIT_AC_INSTALL"],
  "pricing": {
    "AC_REPAIR": 1500,
    "AC_GAS_REFILL": 3500
  },
  "availability": {
    "monday": ["09:00-13:00", "14:00-18:00"],
    "tuesday": ["09:00-13:00", "14:00-18:00"]
  },
  "rating": 4.9,
  "reviewCount": 128,
  "verified": true,
  "cnicVerified": true,
  "trainedByUstaad": true,
  "location": {
    "geohash": "ts5... ",
    "lat": 33.6938,
    "lng": 73.0652
  },
  "isOnline": true,
  "responseTimeMinutes": 14
}
```

### Collection: `bookings/{bookingId}`
Lifecycle tracking of home service bookings.
```json
{
  "customerId": "user_uid_123",
  "providerId": "provider_uid_456",
  "serviceType": "AC_REPAIR",
  "status": "pending", // "pending" | "confirmed" | "en_route" | "in_progress" | "completed" | "cancelled"
  "scheduledAt": "2026-10-25T14:00:00.000Z",
  "address": "House 12, Street 4, F-10/2, Islamabad",
  "priceEstimate": 2500,
  "finalPrice": 2500,
  "paymentStatus": "pending", // "pending" | "paid" | "cash_on_delivery"
  "createdAt": "2026-10-24T03:15:00.000Z",
  "updatedAt": "2026-10-24T03:15:00.000Z"
}
```

### Collection: `reviews/{reviewId}`
Customer reviews for completed services.
```json
{
  "bookingId": "booking_123",
  "customerId": "user_uid_123",
  "providerId": "provider_uid_456",
  "rating": 5,
  "text": "Bohat zabardast kaam kiya. AC bilkul theek ho gaya.",
  "createdAt": "2026-10-24T04:00:00.000Z"
}
```

### Collection: `chats/{chatId}/messages/{messageId}`
In-app communications between customer and assigned provider.
```json
{
  "senderId": "user_uid_123",
  "text": "Main gate ke samnay pohanch gaya hoon.",
  "timestamp": "2026-10-24T04:05:00.000Z",
  "readBy": ["user_uid_123", "provider_uid_456"]
}
```

### Collection: `payments/{paymentId}`
JazzCash payment logs and audit records.
```json
{
  "bookingId": "booking_123",
  "customerId": "user_uid_123",
  "amount": 2500,
  "gateway": "JazzCash",
  "transactionRef": "T20261024031599",
  "status": "success", // "initiated" | "pending" | "success" | "failed" | "refunded"
  "verifiedByServer": true,
  "timestamp": "2026-10-24T03:16:00.000Z"
}
```

---

## 4. Security Rules Specification (`firestore.rules`)
1. **Default Deny**: `match /{document=**} { allow read, write: if false; }`.
2. **User Profiles**: Users can only read and write their own documents (`request.auth.uid == userId`).
3. **Provider Integrity**: Providers can toggle `isOnline` and update their schedule, but `rating`, `reviewCount`, and verification flags are protected from client write.
4. **Booking Isolation**: Readable only by the customer or assigned provider. Status transitions are restricted to server-side Cloud Functions.
5. **Review Protection**: Only created by the authenticated customer of a `completed` booking; max 1 review per booking.
6. **Chat Isolation**: Readable and writable only by the two booking participants. Messages cannot be edited or deleted.

---

## 5. Cloud Functions Catalog (`functions/`)
- `extractServiceIntent`: Structured AI parsing using Gemini 2.5/Vertex AI for English, Urdu, and Roman Urdu.
- `onBookingCreate`: Availability validation, slot locking, and push notification alert to provider.
- `onBookingStatusChange`: State machine validation (`pending` $\to$ `confirmed` $\to$ `en_route` $\to$ `in_progress` $\to$ `completed`).
- `onReviewCreate`: Atomic transaction updating provider average rating and review count.
- `verifyJazzCashPayment`: Server-side inquiry verification of JazzCash transactions with signature hashing.
- `searchProviders`: Configurable weighted ranking algorithm (`distance`, `rating`, `price`, `responseTime`).
- `onNewChatMessage`: Push notification trigger for offline recipients.
