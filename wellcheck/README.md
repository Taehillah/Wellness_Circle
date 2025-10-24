# WellCheck Flutter Client

A multi-platform Flutter client for the WellCheck wellbeing platform. The app targets iOS, Android, and web while speaking to the existing Node/Express backend (`http://localhost:4000` by default). Feature parity with the former React web client is maintained, including authentication, daily check-ins, emergency alerts, contact management, history, and an admin dashboard.

## Why Riverpod?
Riverpod (with the `Notifier` API) gives us:
- **Deterministic state** with compile-time safety and no global singletons.
- **Fine-grained updates** via provider selectors that minimise rebuilds across screens.
- **Simple dependency graph** that keeps repositories, services, and controllers injectable for testing (`ProviderContainer` overrides in tests).
- **Platform flexibility**—the same providers hydrate native and web builds without conditional logic.

## Architecture Overview
```
lib/
 ├─ main.dart + src/bootstrap.dart        // entry + dependency wiring
 ├─ src/app.dart                          // MaterialApp.router + GoRouter
 ├─ src/shared/                           // theming, Dio client, services, widgets, utils
 ├─ src/features/
 │   ├─ auth/                             // AuthController, repo, login/register UI
 │   ├─ home/                             // Home dashboard, check-in CTA, need-help sheet
 │   ├─ history/                          // Check-in history + local streak stats
 │   ├─ contacts/                         // Contact book CRUD with local persistence
 │   ├─ alerts/                           // Emergency controller + payload models
 │   └─ dashboard/                        // Admin metrics & help request feed
```
Key patterns:
- **Feature-first folders** keep domain logic, data sources, and presentation collocated.
- **Dio** is initialised once with auth/logging interceptors. A 401 triggers an automatic logout.
- **Persistence** uses `SharedPreferences` via a thin `PreferencesService` for session, check-ins, and contacts.
- **Geolocation** is handled with `geolocator`, surfaced through an injectable service so the emergency flow can be tested or mocked.
- **Client-side check-ins** mirror the React behaviour: history, streaks, and stats live locally with seeded demo data for the sample accounts.

## Prerequisites
- Flutter **3.35.4** (stable) + Dart **3.9.2**
- Xcode 15+ (for iOS), Android Studio / Android SDK 33+ (for Android)
- Node backend running locally on `http://localhost:4000`

## Installation & Setup
1. Clone the repository and move into the Flutter workspace:
   ```bash
   git clone <repo-url>
   cd Wellness_Circle-1/wellcheck
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. (Optional) Enable desktop platforms as needed (`flutter config --enable-macos-desktop`, etc.).
4. Start the Node/Express backend separately so API requests succeed.

## Running the App
Use `--dart-define` to target other environments (default is `http://localhost:4000`).

### Web (Chromium)
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
```

### iOS Simulator
```bash
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:4000
```

### Android Emulator / Device
```bash
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:4000
```
*(Use `10.0.2.2` in the Android emulator to reach host `localhost`.)*

### Desktop (optional)
```bash
flutter run -d macos --dart-define=API_BASE_URL=https://staging.yourdomain.com
```

## Tests
Run the unit tests:
```bash
flutter test
```
Coverage currently includes:
- Auth session restoration logic
- Check-in streak/stat calculations
- Emergency payload composition
- App shell smoke test

## Environment Configuration
- `API_BASE_URL` – REST API base (defaults to `http://localhost:4000`). Provide via `--dart-define`.
- Geolocation permissions are requested at runtime via `geolocator`. Allow location for the emergency flow to attach coordinates; graceful fallbacks display if denied.

## Feature Highlights
- Auth (login, register, demo credentials), persisted JWT session, `/auth/me` hydration.
- Home screen with streaks, latest check-in summary, daily check-in action, emergency bottom sheet, and quick navigation.
- Contacts CRUD with seeded demo data for the sample accounts.
- History view with totals, streak stats, and reverse-chronological timeline.
- Admin dashboard (role-gated) with metrics, weekly activity visual, contact tiles, and recent help requests.
- Cross-platform theming (Material 3) with shared gradients, typography, and Lucide icons.

## Troubleshooting
- **401 responses** – The auth interceptor clears local session and returns to the login screen.
- **Android emulator cannot reach backend** – Point `API_BASE_URL` to `http://10.0.2.2:4000`.
- **Web geolocation denied** – Emergency sheet keeps working and displays a fallback note when coordinates cannot be attached.

Happy building!
