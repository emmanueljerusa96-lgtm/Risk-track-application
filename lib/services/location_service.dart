import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Location data used by the report and search screens.
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

/// A location error with enough context for the UI to offer the right settings.
class LocationFailure implements Exception {
  const LocationFailure(
    this.message, {
    this.needsSettings = false,
    this.serviceDisabled = false,
  });

  final String message;
  final bool needsSettings;
  final bool serviceDisabled;

  @override
  String toString() => message;
}

class LocationService {
  /// Check whether location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Check and request the required location permission.
  Future<LocationPermission> checkPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Get the user's current GPS position, reporting actionable failures.
  Future<Position> _getPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        'Location services are disabled.',
        needsSettings: true,
        serviceDisabled: true,
      );
    }

    final permission = await checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Location permission is permanently denied. Enable it in app settings.',
        needsSettings: true,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Location permission was denied.',
        needsSettings: true,
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (_) {
      throw const LocationFailure('Unable to determine your current location.');
    }
  }

  /// Compatibility API used by the screens.
  Future<LocationResult> currentLocation() async {
    final position = await _getPosition();
    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: await reverseGeocode(position.latitude, position.longitude),
    );
  }

  /// Get the user's current GPS position.
  Future<Position?> getCurrentLocation() async {
    try {
      return await _getPosition();
    } on LocationFailure {
      return null;
    }
  }

  /// Convert latitude and longitude into a readable address.
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final results = await placemarkFromCoordinates(latitude, longitude);
      if (results.isEmpty) return 'Unknown location';
      final place = results.first;
      final parts = <String>[
        if (place.name != null && place.name!.trim().isNotEmpty) place.name!.trim(),
        if (place.street != null && place.street!.trim().isNotEmpty) place.street!.trim(),
        if (place.locality != null && place.locality!.trim().isNotEmpty) place.locality!.trim(),
        if (place.administrativeArea != null && place.administrativeArea!.trim().isNotEmpty)
          place.administrativeArea!.trim(),
        if (place.country != null && place.country!.trim().isNotEmpty) place.country!.trim(),
      ];
      return parts.isEmpty ? 'Unknown location' : parts.join(', ');
    } catch (_) {
      return 'Unable to determine address';
    }
  }

  /// Compatibility API used by the map picker.
  Future<String> reverseGeocode(double latitude, double longitude) =>
      getAddressFromCoordinates(latitude, longitude);

  /// Get the current position and convert it to a readable address.
  Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    final position = await getCurrentLocation();
    if (position == null) return null;
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'speed': position.speed,
      'heading': position.heading,
      'address': await getAddressFromCoordinates(position.latitude, position.longitude),
    };
  }

  /// Listen continuously for location changes.
  Stream<Position> getLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  Future<String> getAddressFromPosition(Position position) =>
      getAddressFromCoordinates(position.latitude, position.longitude);

  /// Open the operating system's location settings.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Open this application's settings page.
  Future<bool> openAppSettings() async {
    return launchUrl(Uri.parse('app-settings:'));
  }
}
