import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
  final double latitude;
  final double longitude;
  final String address;
}

class LocationFailure implements Exception {
  const LocationFailure(this.message, {
    this.needsSettings = false,
    this.serviceDisabled = false,
  });
  final String message;
  final bool needsSettings;
  final bool serviceDisabled;
}

class LocationService {
  /// Call only after the user taps a location control; never from app startup.
  Future<LocationResult> currentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationFailure(
          'Turn on device Location, then try again.',
          needsSettings: true, serviceDisabled: true,
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationFailure(
          'Location access is blocked. Enable it in Android app settings.',
          needsSettings: true,
        );
      }
      if (permission == LocationPermission.denied) {
        throw const LocationFailure(
          'Location permission is needed for your position. You can also choose a point on the map.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 18),
        ),
      );
      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: await reverseGeocode(position.latitude, position.longitude),
      );
    } on LocationFailure {
      rethrow;
    } on PermissionDeniedException {
      throw const LocationFailure('Location permission was denied.');
    } on LocationServiceDisabledException {
      throw const LocationFailure(
        'Turn on device Location, then try again.',
        needsSettings: true, serviceDisabled: true,
      );
    } catch (_) {
      throw const LocationFailure(
        'Location is temporarily unavailable. Try again or select a point on the map.',
      );
    }
  }

  Future<String> reverseGeocode(double latitude, double longitude) async {
    try {
      final results = await placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 8));
      if (results.isNotEmpty) {
        final place = results.first;
        final parts = [
          place.street, place.subLocality, place.locality,
          place.administrativeArea, place.country,
        ].whereType<String>().where((part) => part.trim().isNotEmpty).toSet();
        if (parts.isNotEmpty) {
          final address = parts.join(', ');
          return address.length > 300 ? address.substring(0, 300) : address;
        }
      }
    } catch (_) {
      // Reverse geocoding is optional; a precise coordinate is still useful.
    }
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings().then((_) {});
  Future<void> openLocationSettings() =>
      Geolocator.openLocationSettings().then((_) {});
}
