import 'dart:async';

import 'package:riverpod/riverpod.dart';

import '../../../shared/services/geolocation_service.dart';
import '../../../shared/settings/settings_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/models/auth_session.dart';
import '../data/alerts_repository.dart';
import '../data/models/help_location.dart';
import '../../../shared/providers/shared_providers.dart';
import 'package:uuid/uuid.dart';
import '../data/models/help_request.dart';
import '../data/models/need_help_payload.dart';

class EmergencyState {
  const EmergencyState({
    required this.permissionStatus,
    required this.isLocating,
    required this.isSending,
    required this.location,
    required this.lastRequest,
    this.statusMessage,
    this.errorMessage,
  });

  final GeoPermissionStatus permissionStatus;
  final bool isLocating;
  final bool isSending;
  final HelpLocation? location;
  final HelpRequest? lastRequest;
  final String? statusMessage;
  final String? errorMessage;

  bool get hasLocation => location != null;
  bool get permissionDenied =>
      permissionStatus == GeoPermissionStatus.denied ||
      permissionStatus == GeoPermissionStatus.deniedForever;

  EmergencyState copyWith({
    GeoPermissionStatus? permissionStatus,
    bool? isLocating,
    bool? isSending,
    HelpLocation? location,
    HelpRequest? lastRequest,
    String? statusMessage,
    String? errorMessage,
  }) {
    return EmergencyState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isLocating: isLocating ?? this.isLocating,
      isSending: isSending ?? this.isSending,
      location: location ?? this.location,
      lastRequest: lastRequest ?? this.lastRequest,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
    );
  }

  factory EmergencyState.initial() => const EmergencyState(
        permissionStatus: GeoPermissionStatus.unknown,
        isLocating: false,
        isSending: false,
        location: null,
        lastRequest: null,
      );
}

class EmergencyController extends Notifier<EmergencyState> {
  late final AlertsRepository _alertsRepository;
  late final GeolocationService _geolocation;
  AuthSession? _session;

  @override
  EmergencyState build() {
    _alertsRepository = ref.read(alertsRepositoryProvider);
    _geolocation = ref.read(geolocationServiceProvider);
    ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
      onSessionChanged(next);
    }, fireImmediately: true);
    return EmergencyState.initial();
  }

  void onSessionChanged(AuthSession? session) {
    _session = session;
  }

  Future<void> refreshLocation() async {
    // Respect app setting to disable location.
    final enabled = ref.read(locationEnabledProvider);
    if (!enabled) {
      state = state.copyWith(
        isLocating: false,
        statusMessage: null,
        errorMessage: null,
        location: null,
      );
      return;
    }
    state = state.copyWith(
      isLocating: true,
      errorMessage: null,
      statusMessage: null,
    );
    try {
      var permission = await _geolocation.checkPermission();
      if (permission == GeoPermissionStatus.denied ||
          permission == GeoPermissionStatus.unknown) {
        permission = await _geolocation.requestPermission();
      }
      if (permission == GeoPermissionStatus.serviceDisabled) {
        state = state.copyWith(
          permissionStatus: permission,
          isLocating: false,
          errorMessage: 'Location services are disabled. Please enable them.',
        );
        return;
      }
      if (permission == GeoPermissionStatus.denied ||
          permission == GeoPermissionStatus.deniedForever) {
        state = state.copyWith(
          permissionStatus: permission,
          isLocating: false,
          errorMessage:
              'Location permission denied. You can still send a request without location.',
        );
        return;
      }
      final position = await _geolocation.currentPosition();
      final location = HelpLocation(
        lat: position.latitude,
        lng: position.longitude,
        address:
            'Lat ${position.latitude.toStringAsFixed(4)}, Lng ${position.longitude.toStringAsFixed(4)}',
      );
      state = state.copyWith(
        permissionStatus: permission,
        location: location,
        isLocating: false,
        statusMessage: null,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLocating: false,
        errorMessage: 'Unable to fetch location: $error',
      );
    }
  }

  Future<void> sendHelp({
    String? message,
  }) async {
    final session = _session;
    if (session == null) {
      state = state.copyWith(
        errorMessage: 'You must be logged in to request help.',
      );
      return;
    }
    state = state.copyWith(
      isSending: true,
      statusMessage: null,
      errorMessage: null,
    );
    try {
      final payload = NeedHelpPayload(
        message: message,
        location: state.location,
      );
      final request = await _alertsRepository.sendNeedHelp(payload);
      // Also persist the help request locally for control centre records.
      final db = ref.read(appDatabaseProvider);
      final uuid = const Uuid();
      await db.insertHelpRequest(
        id: uuid.v4(),
        memberId: _session!.user.id,
        message: message,
        lat: state.location?.lat,
        lng: state.location?.lng,
        address: state.location?.address,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        isSending: false,
        lastRequest: request,
        statusMessage: 'Help request sent. Our team will reach out.',
      );
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage: error.toString(),
      );
    }
  }

  void clearStatus() {
    state = state.copyWith(
      statusMessage: null,
      errorMessage: null,
    );
  }
}

final emergencyControllerProvider =
    NotifierProvider<EmergencyController, EmergencyState>(EmergencyController.new);
