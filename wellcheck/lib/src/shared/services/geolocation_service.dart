import 'package:riverpod/riverpod.dart';
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
}

final geolocationServiceProvider =
    Provider<GeolocationService>((ref) => GeolocationService());
