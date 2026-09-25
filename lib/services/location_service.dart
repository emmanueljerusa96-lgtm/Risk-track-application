import 'dart:async';

/// Simulated location data used by the demo app.
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

/// Location errors kept for compatibility with the existing UI.
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

/// Fully simulated location service.
///
/// The demo never requests GPS permission, accesses device location, or calls
/// a geocoding provider. It returns a fixed location in Lagos so the app can
/// be previewed offline and without device services.
class LocationService {
  static const _demoLocation = LocationResult(
    latitude: 6.5244,
    longitude: 3.3792,
    address: 'Demo location, Lagos',
  );

  Future<bool> isLocationServiceEnabled() async => true;

  Future<Object> checkPermission() async => _SimulatedPermission.granted;

  Future<LocationResult> currentLocation() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _demoLocation;
  }

  Future<Object?> getCurrentLocation() async => _demoLocation;

  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async => _demoLocation.address;

  Future<String> reverseGeocode(double latitude, double longitude) async =>
      _demoLocation.address;

  Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async => {
        'latitude': _demoLocation.latitude,
        'longitude': _demoLocation.longitude,
        'accuracy': 10.0,
        'altitude': 0.0,
        'speed': 0.0,
        'heading': 0.0,
        'address': _demoLocation.address,
      };

  Stream<Object> getLocationStream() => Stream<Object>.value(_demoLocation);

  Future<String> getAddressFromPosition(Object position) async =>
      _demoLocation.address;

  Future<bool> openLocationSettings() async => true;

  Future<bool> openAppSettings() async => true;
}

enum _SimulatedPermission { granted }
