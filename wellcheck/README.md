# Wellness Circle Flutter Client

A multi-platform Flutter client for the Wellness Circle wellbeing platform. The app targets iOS, Android, web, and desktop. It integrates Firebase (Auth, Firestore, FCM) and talks to the Node/Express backend (`http://localhost:4000` by default). Core flows include daily check‑ins with reminders, an emergency “Need help” flow with optional geolocation, contacts, history, a role‑aware admin dashboard, and biometric unlock.

For a deep dive into architecture and cross‑platform notes, see the root README at `../README.md`.

## Why Riverpod?
Riverpod 3’s `Notifier` API provides:
- Deterministic state with compile‑time safety.
- Fine‑grained UI updates via provider selectors.
- Simple dependency injection for tests (override providers in a `ProviderContainer`).
- Platform flexibility: the same providers hydrate native, web, and desktop.

## Architecture Overview
```
lib/
 ├─ main.dart + src/bootstrap.dart        // entry + shared service initialisation
 ├─ src/app.dart                          // MaterialApp.router + GoRouter
 ├─ src/shared/
 │   ├─ config/, providers/, services/    // config, Firebase, notifications, prefs, local DB
 │   ├─ network/, utils/, widgets/        // Dio client, helpers, UI primitives
 └─ src/features/
     ├─ auth/ home/ history/ contacts/
     ├─ alerts/ dashboard/ settings/ circle/
```

Key patterns:
- Feature-first folders collocate domain logic, repositories, and presentation.
- Firebase is initialised in `src/bootstrap.dart`, with optional emulator support.
- Notifications use `flutter_local_notifications` and FCM; tokens are stored per‑user in Firestore.
- Offline data is persisted via `sqflite` and `SharedPreferences` where appropriate.
- Android emulator networking uses `10.0.2.2` automatically when no `API_BASE_URL` is provided.

## Prerequisites
- Flutter 3.35.4 (stable) + Dart 3.9.2
- Android Studio / Android SDK 33+, Xcode 15+
- Firebase CLI (`npm i -g firebase-tools`) and FlutterFire CLI (`dart pub global activate flutterfire_cli`)
- Node backend on `http://localhost:4000`

## Installation & Setup
1) Clone the repo and open the Flutter workspace:
   ```bash
   git clone <repo-url>
   cd Wellness_Circle/wellcheck
   ```
2) Install dependencies:
   ```bash
   flutter pub get
   ```
3) Configure Firebase for your project (Android/iOS/web/desktop as needed):
   ```bash
   flutterfire configure
   ```
   This writes `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`.
4) (Optional) Use local emulators during development:
   ```bash
   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
   ```
5) Start your Node/Express backend separately so API requests succeed.

## Running the App
Provide an API base when needed; otherwise sensible defaults apply (`10.0.2.2` on Android, `localhost` elsewhere).

Web (Chromium)
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
```
iOS Simulator
```bash
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:4000
```
Android Emulator / Device
```bash
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:4000
```
Desktop (optional)
```bash
flutter run -d macos --dart-define=API_BASE_URL=https://staging.yourdomain.com
```

## Building a Release APK
```bash
flutter clean
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com
```
Artifacts are emitted to `build/app/outputs/flutter-apk/app-release.apk`.

## Tests
```bash
flutter test
```
Coverage includes authentication session restoration, streak/stat calculations, emergency payload construction, and a shell smoke test.

## Configuration & Settings
- `API_BASE_URL` — REST API base (default `http://localhost:4000`; Android auto‑uses `10.0.2.2`).
- `USE_FIREBASE_EMULATOR` — When `true`, points Auth + Firestore to local emulators.
- Reminder timer, theme, and location sharing are persisted per user via `SharedPreferences`.

## Feature Highlights
- Auth with biometric unlock; session persistence.
- Daily check‑ins with streak tracking and Android reminders.
- Emergency “Need help” flow with optional geolocation and Firestore logging.
- Contacts CRUD and preferred contact.
- Circle dashboard powered by Firestore streams.
- Admin dashboard with metrics and recent help requests.
- Push notifications via FCM with token registration.

## Troubleshooting
- 401 responses auto‑logout; sign in again or unlock via biometrics.
- Android emulator cannot reach backend: use `http://10.0.2.2:4000`.
- Notifications not firing on Android: check channel permissions in system settings.
- Web geolocation denied: emergency flow still works without coordinates.

Happy building!
