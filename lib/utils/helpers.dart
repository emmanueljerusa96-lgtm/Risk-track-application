import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../services/location_service.dart';

abstract final class AppHelpers {
  static String friendlyError(Object error) {
    if (error is LocationFailure) return error.message;
    if (error is AuthFailure) return error.message;
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'email-already-in-use':
          return 'This email is already registered. Try signing in.';
        case 'weak-password':
          return 'Choose a stronger password (at least 8 characters).';
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          return 'Email or password is incorrect.';
        case 'too-many-requests':
          return 'Too many attempts. Wait a little before trying again.';
        case 'network-request-failed':
          return 'You appear to be offline. Check your connection and retry.';
      }
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'network-request-failed':
          return 'Cannot connect right now. Check your internet and retry.';
        case 'permission-denied':
          return 'You do not have permission to do that. Check your account.';
        case 'failed-precondition':
          return 'This search is not ready yet. Ask an admin to deploy the Firestore indexes.';
        case 'resource-exhausted':
          return 'The service is busy. Please wait and retry.';
        case 'unauthenticated':
          return 'Your session has ended. Please sign in again.';
        case 'unauthorized':
        case 'storage/unauthorized':
          return 'Photo upload is not permitted for this account.';
        case 'retry-limit-exceeded':
          return 'Photo upload timed out. Check your connection and retry.';
        case 'object-not-found':
          return 'This item is no longer available.';
      }
    }
    if (error is PhotoFailure) return error.message;
    return 'Something went wrong. Please try again.';
  }

  static String date(DateTime value) {
    if (value.millisecondsSinceEpoch == 0) return 'Just now';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = value.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  static String timeAgo(DateTime value) {
    if (value.millisecondsSinceEpoch == 0) return 'Just now';
    final delta = DateTime.now().difference(value);
    if (delta.isNegative || delta.inMinutes < 1) return 'Just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    if (delta.inDays < 7) return '${delta.inDays}d ago';
    return date(value);
  }

  static String coordinates(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  /// Spherical distance. Nearby filtering is limited to the retrieved page.
  static double distanceKm(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const radiusKm = 6371.0;
    final aLat = (lat2 - lat1) * math.pi / 180;
    final aLon = (lon2 - lon1) * math.pi / 180;
    final part = math.pow(math.sin(aLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(aLon / 2), 2);
    return radiusKm * 2 * math.asin(math.sqrt(math.min(1, part.toDouble())));
  }
}

class PhotoFailure implements Exception {
  const PhotoFailure(this.message);
  final String message;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}
