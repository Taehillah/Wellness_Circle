import 'package:riverpod/riverpod.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

enum GeoPermissionStatus {
  unknown,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class GeolocationService {
  Future<GeoPermissionStatus> checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return GeoPermissionStatus.serviceDisabled;
    }
    final permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        return GeoPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return GeoPermissionStatus.deniedForever;
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return GeoPermissionStatus.granted;
      case LocationPermission.unableToDetermine:
        return GeoPermissionStatus.unknown;
    }
  }

  Future<GeoPermissionStatus> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return GeoPermissionStatus.serviceDisabled;
    }
    final permission = await Geolocator.requestPermission();
    switch (permission) {
      case LocationPermission.denied:
        return GeoPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return GeoPermissionStatus.deniedForever;
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return GeoPermissionStatus.granted;
      case LocationPermission.unableToDetermine:
        return GeoPermissionStatus.unknown;
    }
  }

  Future<Position> currentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final parts = <String>[
        place.street ?? '',
        place.subLocality ?? '',
        place.locality ?? '',
        place.administrativeArea ?? '',
        place.postalCode ?? '',
        place.country ?? '',
      ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
      if (parts.isEmpty) return null;
      return parts.toSet().join(', ');
    } catch (_) {
      return null;
    }
  }
}

final geolocationServiceProvider = Provider<GeolocationService>(
  (ref) => GeolocationService(),
);
