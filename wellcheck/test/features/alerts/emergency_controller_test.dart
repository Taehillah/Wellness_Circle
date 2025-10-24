import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import 'package:wellcheck/src/features/alerts/application/emergency_controller.dart';
import 'package:wellcheck/src/features/alerts/data/alerts_repository.dart';
import 'package:wellcheck/src/features/alerts/data/models/help_location.dart';
import 'package:wellcheck/src/features/alerts/data/models/need_help_payload.dart';
import 'package:wellcheck/src/features/auth/data/models/auth_session.dart';
import 'package:wellcheck/src/features/auth/data/models/auth_user.dart';
import 'package:wellcheck/src/shared/services/geolocation_service.dart';

class _MockAlertsRepository extends Mock implements AlertsRepository {}

class _MockGeolocationService extends Mock implements GeolocationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NeedHelpPayload());
  });

  test('sendHelp forwards current location to API payload', () async {
    final repository = _MockAlertsRepository();
    final geolocation = _MockGeolocationService();

    when(() => repository.sendNeedHelp(any())).thenAnswer((_) async => null);

    final container = ProviderContainer(overrides: [
      alertsRepositoryProvider.overrideWithValue(repository),
      geolocationServiceProvider.overrideWithValue(geolocation),
    ]);
    addTearDown(container.dispose);

    final controller = container.read(emergencyControllerProvider.notifier);
    controller.onSessionChanged(
      AuthSession(
        token: 'token',
        user: AuthUser(
          id: 1,
          name: 'Admin User',
          email: 'admin@wellcheck.com',
          role: 'admin',
          location: 'Chicago, IL',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );
    controller.state = controller.state.copyWith(
      location: const HelpLocation(lat: 39.7817, lng: -89.6501, address: 'Springfield, IL'),
    );

    await controller.sendHelp(message: 'Check escalation');

    final captured =
        verify(() => repository.sendNeedHelp(captureAny())).captured.single as NeedHelpPayload;
    expect(captured.location?.lat, 39.7817);
    expect(captured.location?.lng, -89.6501);
    expect(captured.message, 'Check escalation');
  });
}
