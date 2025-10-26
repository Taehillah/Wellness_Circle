import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/network/http_exception.dart';
import '../../../shared/services/geolocation_service.dart';
import '../../../shared/settings/settings_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/models/auth_session.dart';
import '../../../shared/providers/shared_providers.dart';
import '../data/alerts_repository.dart';
import '../data/models/help_request.dart';
import '../data/models/need_help_payload.dart';
import '../data/models/help_location.dart';

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

  static const Object _sentinel = Object();

  EmergencyState copyWith({
    GeoPermissionStatus? permissionStatus,
    bool? isLocating,
    bool? isSending,
    Object? location = _sentinel,
    Object? lastRequest = _sentinel,
    Object? statusMessage = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return EmergencyState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isLocating: isLocating ?? this.isLocating,
      isSending: isSending ?? this.isSending,
      location: identical(location, _sentinel)
          ? this.location
          : location as HelpLocation?,
      lastRequest: identical(lastRequest, _sentinel)
          ? this.lastRequest
          : lastRequest as HelpRequest?,
      statusMessage: identical(statusMessage, _sentinel)
          ? this.statusMessage
          : statusMessage as String?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
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
          location: null,
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
          location: null,
        );
        return;
      }
      final position = await _geolocation.currentPosition();
      final resolvedAddress = await _geolocation.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final coordinateLabel =
          'Lat ${position.latitude.toStringAsFixed(4)}, Lng ${position.longitude.toStringAsFixed(4)}';
      final location = HelpLocation(
        lat: position.latitude,
        lng: position.longitude,
        address: (resolvedAddress == null || resolvedAddress.isEmpty)
            ? coordinateLabel
            : resolvedAddress,
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
        location: null,
      );
    }
  }

  Future<void> sendHelp({String? message}) async {
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
    String? fallbackMessage;
    try {
      final payload = NeedHelpPayload(
        message: message,
        location: state.location,
      );
      HelpRequest? request;
      try {
        request = await _alertsRepository.sendNeedHelp(payload);
      } on HttpRequestException catch (error) {
        debugPrint('Failed to notify backend about help request: $error');
        fallbackMessage = error.isConnectivity
            ? 'We could not reach the remote help desk, but your circle has been notified.'
            : 'Help desk is unavailable right now, but your circle has been notified.';
      }
      await _recordAlertInFirestore(
        session: session,
        payload: payload,
        request: request,
      );
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
        statusMessage:
            fallbackMessage ?? 'Help request sent. Our team will reach out.',
      );
    } catch (error) {
      state = state.copyWith(isSending: false, errorMessage: error.toString());
    }
  }

  void clearStatus() {
    state = state.copyWith(statusMessage: null, errorMessage: null);
  }

  Future<void> _recordAlertInFirestore({
    required AuthSession session,
    required NeedHelpPayload payload,
    HelpRequest? request,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final circleId = (session.user.circleId?.trim().isNotEmpty ?? false)
          ? session.user.circleId!.trim()
          : 'circle-${session.user.id}';
      final circleDoc = firestore.collection('circles').doc(circleId);
      final alertsCollection = circleDoc.collection('alerts');

      final location = payload.location;
      final coordsText = location == null
          ? null
          : 'Lat ${location.lat.toStringAsFixed(4)}, '
                'Lng ${location.lng.toStringAsFixed(4)}';
      final locationText = location == null
          ? null
          : (() {
              final address = location.address?.trim();
              if (address == null || address.isEmpty || address == coordsText) {
                return coordsText;
              }
              return '$address\n$coordsText';
            })();

      final alertData = <String, dynamic>{
        'senderId': session.user.id,
        'senderName': session.user.name,
        'senderEmail': session.user.email,
        if (request != null) 'requestId': request.id,
        if (payload.message != null && payload.message!.isNotEmpty)
          'message': payload.message,
        if (location != null)
          'location': {
            'lat': location.lat,
            'lng': location.lng,
            if (location.address != null) 'address': location.address,
          },
        if (locationText != null) 'locationText': locationText,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtLocal': DateTime.now().toIso8601String(),
      };

      final alertDoc = request == null
          ? alertsCollection.doc()
          : alertsCollection.doc(request.id.toString());
      await alertDoc.set(alertData, SetOptions(merge: true));

      final membersCollection = circleDoc.collection('members');
      await membersCollection.doc(session.user.id.toString()).set({
        'displayName': session.user.name,
        'lastAlertAt': FieldValue.serverTimestamp(),
        'lastAlertAtLocal': DateTime.now().toIso8601String(),
        'status': 'needsAttention',
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      debugPrint('Failed to record help alert in Firestore: $error');
      debugPrint('$stackTrace');
    }
  }
}

final emergencyControllerProvider =
    NotifierProvider<EmergencyController, EmergencyState>(
      EmergencyController.new,
    );
