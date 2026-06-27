<div align="center">
  
# 🛠️ Ustaad Service App

**A production-minded service-booking application for Pakistan's informal economy.**

[![Flutter CI](https://github.com/zaintahir2025/ustaad-agentic-service-app/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/zaintahir2025/ustaad-agentic-service-app/actions/workflows/flutter-ci.yml)
[![Deploy Web App](https://github.com/zaintahir2025/ustaad-agentic-service-app/actions/workflows/github-pages.yml/badge.svg)](https://zaintahir2025.github.io/ustaad-agentic-service-app/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

*Supporting English, Urdu, and Roman Urdu requests, intelligently matching users with nearby professionals.*

[**Live Demo (Web)**](https://zaintahir2025.github.io/ustaad-agentic-service-app/)

---

</div>

## 🚀 Product Flow

1. **Seamless Sign-in:** Customers authenticate via Firebase Auth (Email/Password or Anonymous Guest).
2. **Natural Language Input:** Describe a service need in your own words (e.g., "Mera AC theek nahi chal raha").
3. **Smart Extraction:** The app automatically extracts the required service type, location, time, language preference, and urgency.
4. **Intelligent Ranking:** Providers are ranked based on distance, availability, ratings, reliability score, and price.
5. **Effortless Booking:** Send a request to a provider, unlock contact details, and track your booking workflow.
6. **Provider Management:** Save trusted professionals, leave reviews, and manage your custom profile.

---

## 🏗️ Architecture

- `lib/main.dart`: Firebase initialization and Provider root.
- `lib/src/ustaad_state.dart`: Orchestration state, NLP parsing, provider ranking, booking management, and UI logic.
- `lib/src/ustaad_repository.dart`: Firebase Firestore interactions (Profiles, Providers, Bookings, Reviews) and Authentication.
- `lib/src/ustaad_ui.dart`: Beautiful, responsive Flutter UI for mobile, tablet, desktop, and web.
- `android/`, `ios/`, `web/`: Native Flutter platform runners.

---

## 🔥 Firebase Setup

This app is powered entirely by **Firebase** instead of Supabase. It uses Firebase Authentication for secure sign-ins and Cloud Firestore as a NoSQL backend for data storage.

### Prerequisites
1. You must have a Firebase project created in your [Firebase Console](https://console.firebase.google.com/).
2. You must have the Firebase CLI and FlutterFire CLI installed locally.

### Configuration
We have already run `flutterfire configure` which generated the `lib/firebase_options.dart` and native configuration files.

> **Note:** Do NOT commit your `firebase_options.dart` or `google-services.json` to public repositories if they contain restrictive billing keys.

### Enabling Authentication
Make sure you enable **Email/Password** and **Anonymous** sign-in methods in your Firebase Console under **Authentication -> Sign-in method**. Otherwise, the Guest and Login buttons will not work!

---

## 🛠️ Free Service Stack

The app is built to be extremely cost-effective and avoids paid mapping or routing APIs where possible:

- **Maps:** OpenStreetMap tiles through `flutter_map`.
- **Place Search:** Nominatim, with an offline fallback for local sectors.
- **Route Estimates:** OSRM public route service, with a local haversine mathematical fallback.
- **Voice Input:** On-device speech recognition via `speech_to_text` (no cloud keys needed).
- **Provider Contact:** Native phone dialer and WhatsApp intents via `url_launcher`.
- **Hosting:** Fully deployed and hosted on **GitHub Pages**.

---

## 💻 Running the App

### Prerequisites
- Flutter SDK (stable channel)
- Firebase configured (see above)

### Commands

**1. Install Dependencies:**
```sh
flutter pub get
```

**2. Run locally (Chrome):**
```sh
flutter run -d chrome
```

**3. Build for Web (Production):**
```sh
flutter build web --release --base-href "/ustaad-agentic-service-app/"
```

**4. Build for Android:**
```sh
flutter build apk --debug
```

---

<div align="center">
  Made with ❤️ by Zain Tahir
</div>
