import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoder;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

/// A coordinate plus the best human-readable address available for it.
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

/// Location errors that the interface knows how to explain and recover from.
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

/// Real device and browser location.
///
/// * GPS comes from `geolocator`, which uses the Android/iOS location services
///   on a phone and the browser Geolocation API on the web.
/// * Reverse geocoding first asks the operating system through the `geocoding`
///   plugin. That plugin has no web implementation, so browsers - and phones
///   whose system geocoder is unavailable or rate limited - fall back to the
///   public OpenStreetMap Nominatim service over HTTPS.
/// * Nothing is requested until the user taps a button in the interface.
class LocationService {
  /// Nominatim asks clients to identify themselves. Browsers refuse to set a
  /// User-Agent header, so it is only sent on native builds, where the browser
  /// Referer is unavailable anyway.
  static const _nominatimEndpoint =
      'https://nominatim.openstreetmap.org/reverse';
  static const _addressTimeout = Duration(seconds: 10);

  /// True when the phone or browser reports that location is switched on.
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Reads the current permission without prompting.
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  /// Asks for permission. This is the call that shows the system/browser prompt.
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  /// One GPS fix with the best address that can be attached to it.
  Future<LocationResult> currentLocation() async {
    if (!await isLocationServiceEnabled()) {
      throw LocationFailure(
        kIsWeb
            ? 'This browser has no location service available. Check that '
                'location is switched on, or choose the reported location on '
                'the map.'
            : 'Device location (GPS) is off. Turn it on and try again, or '
                'choose the reported location on the map.',
        needsSettings: !kIsWeb,
        serviceDisabled: true,
      );
    }

    var permission = await checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure(
        kIsWeb
            ? 'Location is blocked for this site. Allow it in the browser site '
                'settings, or choose the reported location on the map.'
            : 'Location permission is blocked. Open the app settings to allow '
                'it, or choose the reported location on the map.',
        needsSettings: !kIsWeb,
      );
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const LocationFailure(
        'Location permission was not granted. You can still choose the '
        'reported location on the map.',
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
    } on TimeoutException {
      throw const LocationFailure(
        'Getting a GPS fix took too long. Move to an open area and retry, or '
        'choose the reported location on the map.',
      );
    } catch (_) {
      throw const LocationFailure(
        'Could not read the current location. Check your internet connection '
        'and location settings, or choose the reported location on the map.',
      );
    }

    final address =
        await reverseGeocode(position.latitude, position.longitude);
    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
  }

  /// Turns coordinates into an address. Never throws: when no provider can
  /// answer, the printable coordinate pair is returned instead.
  Future<String> reverseGeocode(double latitude, double longitude) async {
    final fromDevice = await _deviceAddress(latitude, longitude);
    if (fromDevice != null && fromDevice.isNotEmpty) return fromDevice;
    final fromOpenStreetMap = await _nominatimAddress(latitude, longitude);
    if (fromOpenStreetMap != null && fromOpenStreetMap.isNotEmpty) {
      return fromOpenStreetMap;
    }
    return _coordinates(latitude, longitude);
  }

  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) =>
      reverseGeocode(latitude, longitude);

  /// Alias kept for screens that used the earlier service shape.
  Future<LocationResult> getCurrentLocation() => currentLocation();

  Future<Map<String, dynamic>> getCurrentLocationWithAddress() async {
    final fix = await currentLocation();
    return {
      'latitude': fix.latitude,
      'longitude': fix.longitude,
      'address': fix.address,
    };
  }

  /// Live position updates, each with a reverse-geocoded address.
  Stream<LocationResult> getLocationStream({int distanceFilter = 10}) =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(distanceFilter: distanceFilter),
      ).asyncMap((position) async => LocationResult(
            latitude: position.latitude,
            longitude: position.longitude,
            address:
                await reverseGeocode(position.latitude, position.longitude),
          ));

  Future<String> getAddressFromPosition(Position position) =>
      reverseGeocode(position.latitude, position.longitude);

  /// Opens the operating system location settings. Browsers keep this per
  /// site, so the call is a no-op that reports false on the web.
  Future<bool> openLocationSettings() async {
    if (kIsWeb) return false;
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Opens the operating system app settings. Unsupported in browsers.
  Future<bool> openAppSettings() async {
    if (kIsWeb) return false;
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------

  /// The `geocoding` plugin implements Android, iOS and macOS only.
  Future<String?> _deviceAddress(double latitude, double longitude) async {
    if (kIsWeb) return null;
    try {
      final marks = await geocoder.Geocoding()
          .placemarkFromCoordinates(latitude, longitude);
      if (marks.isEmpty) return null;
      final formatted = _formatPlacemark(marks.first);
      return formatted.isEmpty ? null : formatted;
    } catch (_) {
      // Rate limits and missing Play Services are common; use OSM instead.
      return null;
    }
  }

  String _formatPlacemark(geocoder.Placemark mark) {
    final parts = <String>[];
    for (final part in <String?>[
      mark.name,
      mark.street,
      mark.subLocality,
      mark.locality,
      mark.administrativeArea,
      mark.country,
    ]) {
      final value = part?.trim() ?? '';
      if (value.isNotEmpty && !parts.contains(value)) parts.add(value);
    }
    return parts.join(', ');
  }

  /// HTTPS lookup used by the browser build and as a native fallback.
  /// See https://operations.osmfoundation.org/policies/nominatim/
  Future<String?> _nominatimAddress(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(_nominatimEndpoint).replace(queryParameters: {
        'format': 'jsonv2',
        'lat': latitude.toStringAsFixed(6),
        'lon': longitude.toStringAsFixed(6),
        'zoom': '18',
        'addressdetails': '1',
      });
      final response = await http.get(
        uri,
        headers: {
          if (!kIsWeb)
            'User-Agent': 'RiskTrack/1.0 (${AppConstants.mapUserAgent})',
          'Accept': 'application/json',
        },
      ).timeout(_addressTimeout);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final display = body['display_name'];
      if (display is String && display.trim().isNotEmpty) {
        return display.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _coordinates(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}
