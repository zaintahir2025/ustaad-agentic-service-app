# Ustaad Flutter

Ustaad is a professional service-booking app for Pakistan's informal economy. It supports English, Urdu, and Roman Urdu requests, ranks trusted nearby providers, manages bookings, profiles, provider contacts, reviews, and Supabase-backed workflow traces.

## Core Flow

1. User signs in with Supabase Auth.
2. User describes a service request, for example `Mujhe kal subah G-13 mein AC technician chahiye`.
3. The app extracts service, location, time, language, urgency, and confidence.
4. Providers are loaded from Supabase `service_providers`, with local seed fallback for demos.
5. Ranking uses distance, availability, rating, reliability, completed jobs, urgency, and price.
6. Booking writes to Supabase `bookings`, unlocks provider contact details, and trace steps write to `agent_events`.
7. Users can track booking status, complete/cancel bookings, and review providers.
8. Users can edit profile details, preferred language, and upload profile photos through Supabase Storage.

## Architecture

- `lib/main.dart`: Supabase initialization and Provider root.
- `lib/src/ustaad_state.dart`: orchestration state, multilingual parser, ranking logic, profiles, bookings, reviews.
- `lib/src/ustaad_repository.dart`: Supabase Auth, Storage avatars, provider reads, booking writes, review writes, agent event writes.
- `lib/src/ustaad_ui.dart`: responsive Flutter UI for mobile, tablet, and web.
- `android/`, `ios/`, `web/`: platform runners.
- `supabase/migrations/`: SQL schema, RLS policies, Storage bucket, seed providers, booking/event/review tables.

## Antigravity Use

The app models the required Antigravity-style orchestration as a traceable pipeline:

`Interpreter Agent -> Discovery Agent -> Ranking Agent -> Booking Agent -> Follow-up Agent`

For the hackathon demo, each step is visible in the app and persisted to `agent_events`. If Google Antigravity runtime/API access is available, replace the parser/ranking methods in `UstaadState` with Antigravity tool calls while keeping the same UI and Supabase persistence contracts.

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

If using the direct connection flow, pass the real database password at the prompt or with `--password`. Do not commit that password.

Tables:

- `profiles`
- `service_providers`
- `bookings`
- `agent_events`
- `reviews`
- Storage bucket: `avatars`

All public tables have RLS enabled. Client code only uses the publishable key.

Current remote migration check:

- 8 service providers seeded.
- 3 public reviews seeded.
- `avatars` bucket created.

## Run

```sh
flutter pub get
flutter run -d chrome
```

Android:

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

## Demo Notes

Show one full request from input to confirmed booking. Then open bookings, copy contact details, mark the booking complete, post a review, and update the user profile photo/details. Open the workflow trace on the provider match screen to demonstrate reasoning, tool usage, action execution, and follow-up automation.
