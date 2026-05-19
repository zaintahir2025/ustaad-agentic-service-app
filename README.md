# Ustaad Flutter

Ustaad is a production-minded service-booking app for Pakistan's informal economy. It supports English, Urdu, and Roman Urdu requests, ranks nearby providers, manages bookings, saved professionals, profile details, provider contacts, reviews, and Supabase-backed workflow traces.

## Product Flow

1. Customers sign in with Supabase Auth.
2. Customers describe a service need in natural language.
3. The app extracts service type, location, time, language, urgency, and confidence.
4. Providers load from Supabase, with an offline catalog fallback.
5. Ranking weighs distance, availability, rating, reliability, completed jobs, urgency, and price.
6. Booking writes to Supabase, unlocks provider contact details, and stores trace events.
7. Customers can search bookings, rebook, cancel, complete, report an issue, and review providers.
8. Customers can save trusted providers and manage their profile, language, address, and avatar.

## Architecture

- `lib/main.dart`: Supabase initialization and Provider root.
- `lib/src/ustaad_state.dart`: orchestration state, parser, ranking, profiles, bookings, saved providers, reviews.
- `lib/src/ustaad_repository.dart`: Supabase Auth, Storage avatars, provider reads, booking writes, review writes, event writes.
- `lib/src/ustaad_ui.dart`: responsive Flutter UI for mobile, tablet, desktop, and web.
- `android/`, `ios/`, `web/`: Flutter platform runners.
- `supabase/migrations/`: SQL schema, RLS policies, Storage bucket, seed providers, booking/event/review tables.

## Supabase

Configured project:

```dart
https://dcsioxiiyazchampqulz.supabase.co
```

Apply migrations:

```sh
supabase login
supabase link --project-ref dcsioxiiyazchampqulz
supabase db push
```

Do not commit database passwords or private service keys. Client code uses only the publishable key.

## Run

```sh
flutter pub get
flutter run -d chrome
```

Build web:

```sh
flutter build web --release --base-href "/ustaad-agentic-service-app/"
```

Build Android:

```sh
flutter build apk --debug
```

## Verify

```sh
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```
