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

## Free Service Stack

The app avoids paid map and routing APIs:

- Maps: OpenStreetMap tiles through `flutter_map`.
- Place search: Nominatim, with an offline Islamabad sector fallback.
- Route/ETA estimates: OSRM public route service, with a local haversine fallback.
- Voice input: device speech recognition through `speech_to_text`; no cloud speech key.
- Provider contact: device phone and WhatsApp intents through `url_launcher`; no Twilio key.
- AI matching: local multilingual parser and ranking logic; no LLM key required.
- Hosting: GitHub Pages for web and GitHub Releases/Drive for APK sharing.

Services that still need your setup for production:

- Push notifications: create a Firebase project, add Android/iOS apps, download `google-services.json` and `GoogleService-Info.plist`, then connect FCM to a Supabase Edge Function.
- Production map tiles: create a free Stadia Maps or MapTiler account if traffic exceeds OpenStreetMap's public tile policy.
- Production AI chat: create a Gemini API key in Google AI Studio if you want real generative responses instead of local simulated chat.

## Supabase Auth Setup

Email confirmation and password recovery are implemented in the app. Add these redirect URLs in Supabase Dashboard -> Authentication -> URL Configuration -> Additional Redirect URLs:

- `https://zaintahir2025.github.io/ustaad-agentic-service-app/`
- `com.ustaad.service://auth-callback`

Keep **Confirm email** enabled. New users will stay on a check-email state until they open the confirmation link. Password reset links return to the app and show a secure new-password screen.

Supabase's built-in email sender has strict rate limits. The app handles this with a cooldown message and guest access for demos. For production, configure a custom SMTP provider in Supabase Dashboard -> Authentication -> SMTP Settings.

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
