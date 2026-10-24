# Ustaad Production Deployment Guide (DEPLOYMENT.md)

This runbook contains step-by-step instructions to deploy Cloud Functions, Firestore security rules, Firebase indexes, and build the Flutter client for production.

---

## 1. Prerequisites
- **Node.js**: v18 or higher (`node -v`)
- **Firebase CLI**: v13+ (`npm install -g firebase-tools`)
- **Flutter SDK**: 3.24+ (`flutter doctor`)
- **Google Cloud SDK**: authenticated with project permissions

Log in to Firebase and ensure the active project is configured:
```powershell
firebase login
firebase use ustaad-service-app-17d0a
```

---

## 2. Secrets & Environment Configuration
Never hardcode production secrets in source files. Store sensitive keys in Google Cloud Secret Manager or Firebase Functions secrets:
```powershell
# Set Gemini API Key for Server-side AI intent extraction
firebase functions:secrets:set GEMINI_API_KEY

# Set JazzCash Merchant Credentials for Payment Verification
firebase functions:secrets:set JAZZCASH_MERCHANT_ID
firebase functions:secrets:set JAZZCASH_PASSWORD
firebase functions:secrets:set JAZZCASH_INTEGRITY_SALT
```

---

## 3. Deploying Firestore Security Rules & Indexes
Deploy strict rules ensuring user-scoped isolation, role-based protection, and default-deny policies:
```powershell
# Deploy Firestore rules and composite indexes
firebase deploy --only firestore:rules,firestore:indexes
```

To test rules against the emulator before deploying to production:
```powershell
firebase emulators:exec --only firestore "npm test --prefix functions"
```

---

## 4. Deploying Cloud Functions
Cloud Functions reside in the `functions/` directory and execute server-side AI intent extraction, booking state machine triggers, and payment verification.

```powershell
# Install functions dependencies
cd functions
npm ci

# Run local linter and function tests
npm test

# Deploy Cloud Functions with runtime secrets
firebase deploy --only functions
```

---

## 5. Deploying Firebase Storage Rules
Deploy security rules guarding avatars and service proof attachments:
```powershell
firebase deploy --only storage
```

---

## 6. Building the Flutter Client for Production

### A. Android Release (Google Play Store)
Build the signed Android App Bundle (AAB):
```powershell
flutter build appbundle --release `
  --dart-define=APP_ENV=production `
  --dart-define=ENABLE_APP_CHECK=true
```
The output bundle will be located at:
`build/app/outputs/bundle/release/app-release.aab`

### B. Web Release (GitHub Pages / Firebase Hosting)
Build the optimized Flutter web client with canvaskit/html hybrid renderer:
```powershell
flutter build web --release `
  --base-href="/" `
  --dart-define=APP_ENV=production
```
To deploy directly to Firebase Hosting:
```powershell
firebase deploy --only hosting
```

### C. iOS Release (Apple App Store)
```powershell
flutter build ipa --release `
  --dart-define=APP_ENV=production `
  --dart-define=ENABLE_APP_CHECK=true
```

---

## 7. Local Development with Firebase Emulator Suite
For rapid local iteration with zero cloud cost and simulated offline conditions:
```powershell
# Start all emulators (Auth, Firestore, Functions, Storage, UI)
firebase emulators:start

# Run automated Flutter integration tests against the emulator
flutter test test/auth_emulator_test.dart
```
Emulator Hub UI is accessible at `http://127.0.0.1:4000`.
