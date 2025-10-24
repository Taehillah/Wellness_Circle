# WellCheck Flutter Client

A multi-platform Flutter client for the WellCheck wellbeing platform. The app targets iOS, Android, and web while speaking to the existing Node/Express backend (`http://localhost:4000` by default). Feature parity with the former React web client is maintained, including authentication, daily check-ins, emergency alerts, contact management, history, and an admin dashboard.

## Why Riverpod?
Riverpod (with the `Notifier` API) gives us:
- **Deterministic state** with compile-time safety and no global singletons.
- **Fine-grained updates** via `Provider`/`NotifierProvider` selectors that minimise rebuilds across screens.
- **Simple dependency graph** that keeps repositories, services, and controllers injectable for testing (`ProviderContainer` overrides in tests).
- **Platform flexibility**—the same providers hydrate native and web builds without conditional logic.

## Architecture Overview
```
lib/
 ├─ main.dart + src/bootstrap.dart        // entry + dependency wiring
 ├─ src/app.dart                          // MaterialApp.router + GoRouter
 ├─ src/shared/                           // theming, Dio client, services, widgets, utils
 ├─ src/features/
 │   ├─ auth/                             // AuthController, AuthRepository, login/register UI
 │   ├─ home/                             // Home dashboard, check-in CTA, need-help sheet
 │   ├─ history/                          // Check-in history + local streak stats
 │   ├─ contacts/                         // Contact book CRUD with local persistence
 │   ├─ alerts/                           // Emergency controller + payload models
 │   └─ dashboard/                        // Admin metrics and recent help requests
```
Key patterns:
- **Feature-first directories** keep domain logic, data sources, and presentation collocated.
- **Dio** is configured once with auth/logging interceptors. A 401 triggers the `AuthController` to sign the user out.
- **Persistence** uses `SharedPreferences` via a thin `PreferencesService` for session, check-ins, and contacts.
- **Geolocation** is handled with `geolocator`, surfaced through an injectable service so the emergency flow can be tested.
- **Client-side check-ins** mirror the React behaviour: history, streaks, and stats live locally with seeded demo data for the sample accounts.

## Prerequisites
- Flutter **3.35.4** (stable) + Dart **3.9.2**
- Xcode 15+ (for iOS), Android Studio / Android SDK 33+ (for Android)
- Node backend running locally on `http://localhost:4000`

## Installation & Setup
1. Clone the repository and open the Flutter workspace:
   ```bash
   git clone <repo-url>
   cd Wellness_Circle-1/wellcheck
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. (Optional) Enable macOS/Windows/Linux platforms as needed with `flutter config --enable-<platform>`.
4. Start the Node/Express backend separately so API requests succeed.

## Running the App
Use `--dart-define` to target other environments (default is `http://localhost:4000`).

### Web
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
```

### iOS Simulator
```bash
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:4000
```

### Android
- Emulator (host backend):
```bash
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:4000
```
  Use `10.0.2.2` inside the Android emulator to reach `localhost` on the host machine.

- Physical device (host backend via LAN):
```bash
flutter run -d android --dart-define=API_BASE_URL=http://<YOUR-LAN-IP>:4000
```
  Replace `<YOUR-LAN-IP>` with your computer’s IP on the same Wi‑Fi (e.g. `http://192.168.1.50:4000`).
  Ensure your firewall allows inbound connections and the device can ping the host.

### Desktop (optional)
```bash
flutter run -d macos --dart-define=API_BASE_URL=https://staging.yourdomain.com
```

## Tests
Run the unit test suite:
```bash
flutter test
```
Current coverage includes:
- Auth session restoration logic
- Check-in streak/stat calculations
- Emergency payload composition
- Basic widget smoke test for the top-level app shell

## Environment Configuration
- `API_BASE_URL` – REST API base (default `http://localhost:4000`). Provided via `--dart-define`.
- Geolocation permissions are requested at runtime via `geolocator`. On iOS/Android, ensure location permissions are granted for the emergency flow to attach coordinates.

## Feature Highlights
- Auth (login, register, demo credentials), persisted JWT session, `/auth/me` hydration.
- Home screen with streak, latest check-in, check-in action, emergency modal in a bottom sheet, and quick navigation tiles.
- Contacts CRUD with seeded demo data for the sample accounts.
- History view with totals, streak statistics, and recent timeline.
- Admin dashboard (role-gated) with metrics, weekly activity bars, contact summaries, and recent help requests.
- Cross-platform theming (Material 3) with shared gradients, typography, and Lucide iconography.

## Coding Guidelines Recap
- Feature-first structure, strongly typed models, and Riverpod controllers drive state.
- `PreferencesService` abstracts `SharedPreferences` for decoupled persistence.
- `NeedHelpPayload` gracefully omits optional fields; the controller handles location fallbacks and debounced unauthorized responses.

## Troubleshooting
- **401 Responses / Forced logout** – The auth interceptor clears local state; log back in.
- **Android emulator cannot reach backend** – Use `10.0.2.2` for the API host.
- **Web geolocation denied** – The emergency sheet displays fallback messaging; allow location in the browser to include coordinates.

Happy building!
