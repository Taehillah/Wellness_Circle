# Wellness Circle Flutter Client

A multi-platform Flutter client for the Wellness Circle wellbeing platform. The app targets iOS, Android, web, and desktop and now relies on Firebase (Auth + Firestore) alongside the Node/Express backend (`http://localhost:4000` by default). It replaces the former React client with a state-driven Flutter experience that keeps daily check-ins, emergency alerts, contact management, and the circle dashboard in sync across platforms.

## Key Capabilities
- Daily wellness check-ins with streak tracking, a configurable countdown timer, and minute-level Android reminders (`flutter_local_notifications`).
- Emergency “Need help” flow with optional geolocation, plus offline logging of requests to an on-device SQLite database for audit recovery.
- Contact book CRUD with preferred contact selection, quick dial actions, and seeded demo data for sample accounts.
- Circle tab fed by Firestore streams that groups members by status, surfaces recent alerts, and gracefully falls back to demo data when Firebase isn’t configured.
- Role-aware admin dashboard with metrics, activity charts, and recent help requests.
- Settings screen for theme mode, reminder interval, location sharing, and preferred contact—persisted per user via `SharedPreferences`.
- Biometric unlock (Face ID / Touch ID / device credential) that protects the stored session and allows returning users to resume instantly.

## Architecture Overview
```
lib/
 ├─ main.dart + src/bootstrap.dart        // entry + shared service initialisation
 ├─ src/app.dart                          // MaterialApp.router + GoRouter configuration
 ├─ src/shared/
 │   ├─ config/                           // runtime configuration + API base
 │   ├─ data/, network/, utils/, widgets/ // cross-cutting helpers + UI primitives
 │   ├─ providers/                        // Riverpod providers for app-wide singletons
 │   ├─ services/                         // Notifications, SQLite DB, biometrics, prefs, geo
 │   ├─ settings/                         // Settings controllers (timer, location, preferred contact)
 │   └─ theme/                            // Material 3 theme + theme controller
 └─ src/features/
     ├─ auth/                             // AuthController, biometrics-aware login/register UI
     ├─ home/                             // Dashboard, countdown, quick actions
     ├─ history/                          // Check-in history + streak calculations
     ├─ contacts/                         // Contact management + preferred contact wiring
     ├─ alerts/                           // Emergency controller, payload models, bottom sheet UI
     ├─ dashboard/                        // Admin metrics and recent requests
     └─ settings/                         // Settings screen presentation widgets
```
Riverpod 3’s `Notifier` API drives state. Feature-first folders collocate domain logic, repositories, and presentation, while shared services (Firebase, HTTP client, preferences, notifications, local DB, biometrics, geolocation) are injected through providers to keep testing simple.

### Shared Services Initialisation
`src/bootstrap.dart` wires up the app by:
- Grabbing a singleton `SharedPreferences` instance for session, countdown, and settings persistence.
- Initialising `NotificationsService` (Android channel + permissions) for recurring reminders.
- Opening `AppDatabase` (`sqflite`) where members and help requests are stored offline alongside API data.
- Providing these instances via Riverpod overrides so features can read/write without manual plumbing.

## Prerequisites
- Flutter **3.35.4** (stable) + Dart **3.9.2**
- Xcode 15+ with a configured simulator (iOS)
- Android Studio / Android SDK 33+ with an emulator or physical device (Android)
- Node backend running locally on `http://localhost:4000`

## Getting Started
1. Clone the repository and open the Flutter workspace:
   ```bash
   git clone <repo-url>
   cd Wellness_Circle/wellcheck
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. (Optional) Enable desktop platforms as needed, e.g. `flutter config --enable-macos-desktop`.
4. Start the Node/Express backend separately so API requests succeed.

## Running the App
Use `--dart-define=API_BASE_URL=<url>` to target other environments (default `http://localhost:4000`).

### Web (Chrome)
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
```

### iOS Simulator
```bash
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:4000
```

### Android
- Emulator (backend on host `localhost`):
  ```bash
  flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:4000
  ```
  `10.0.2.2` bridges the emulator to your host machine.

- Physical device on the same LAN:
  ```bash
  flutter run -d android --dart-define=API_BASE_URL=http://<YOUR-LAN-IP>:4000
  ```
  Replace `<YOUR-LAN-IP>` with your computer’s IP (example `http://192.168.1.50:4000`) and allow inbound connections through your firewall.

### Desktop (optional)
```bash
flutter run -d macos --dart-define=API_BASE_URL=https://staging.yourdomain.com
```

## Tests
Run the unit and widget suites:
```bash
flutter test
```
Coverage includes authentication session restoration and logout flows, check-in streak/stat calculations, emergency payload construction, and a smoke test for the app shell.

## Configuration & Settings
- `API_BASE_URL` (dart-define) – REST API base (default `http://localhost:4000`).
- Reminder timer – Adjust via Settings → Reminder timer slider (1–24 hours). The countdown state persists through app restarts in `SharedPreferences`.
- Location sharing – Toggle in Settings to control whether coordinates are attached to help requests. When disabled the emergency flow still works without GPS.
- Preferred contact – Select in Settings to surface a quick-call shortcut on the home screen.
- Theme – Switch light/dark/system from Settings or via the home app bar icon.
- Biometric login – Requires one successful credential login to persist the session. Subsequent launches can unlock via biometrics/device PIN.

## Platform Notes
- Android reminders rely on `flutter_local_notifications`; ensure the emulator/device allows notifications for the app. iOS/web currently no-op but remain safe to call.
- Local data (members + help requests) is stored in `sqflite` at `wellcheck.db` within the app documents directory.
- Geolocation requires runtime permission. If denied, the emergency request still sends but omits coordinates and shows a fallback message.

## Troubleshooting
- **401 responses auto-logout** – The auth interceptor clears the stored session and returns to the login screen. Sign back in or use biometrics if you already unlocked a session.
- **Android emulator cannot reach backend** – Use `http://10.0.2.2:4000` as the API host.
- **Biometrics prompt missing** – First log in with credentials to persist a session, and confirm the device supports biometrics (`local_auth`).
- **Notifications not firing on Android** – Confirm the channel permission is enabled in system settings; reminders only run on real devices/emulators that support scheduled notifications.
- **Web geolocation denied** – The emergency sheet displays fallback messaging; allow location access in the browser to include coordinates.

Happy building!
