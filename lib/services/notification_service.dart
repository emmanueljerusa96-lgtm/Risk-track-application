import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_mode.dart';

/// Optional push notifications.
///
/// Push is Android-only in this build: browsers would additionally need a
/// service worker and a VAPID key, so the web build keeps the switch off and
/// relies on the in-app Firestore notifications instead. Everything here only
/// runs after an explicit tap - the app never asks for notification permission
/// on its own - and the secure Cloud Function, never the phone, sends messages.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _prefs = SharedPreferencesAsync();
  StreamSubscription<String>? _tokenSubscription;
  String? _currentUid;
  static const _enabledKey = 'risk_track_push_enabled';
  static const _deviceKey = 'risk_track_device_id';

  /// False in the browser, where this build has no push transport.
  static bool get isSupported => !kIsWeb;

  Future<bool> isEnabled() async => await _prefs.getBool(_enabledKey) ?? false;

  Future<bool> enable(String uid) async {
    if (!isSupported) return false;
    if (DemoMode.enabled) {
      await _prefs.setBool(_enabledKey, true);
      return true;
    }
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return false;
    }
    await _prefs.setBool(_enabledKey, true);
    await resumeIfEnabled(uid);
    return true;
  }

  Future<void> resumeIfEnabled(String uid) async {
    if (!isSupported || DemoMode.enabled || !await isEnabled()) return;
    _currentUid = uid;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _saveToken(uid, token);
    _tokenSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) {
        final activeUid = _currentUid;
        if (activeUid != null) {
          _saveToken(activeUid, newToken).catchError((Object _) {});
        }
      },
    );
  }

  Future<void> _saveToken(String uid, String token) async {
    var id = await _prefs.getString(_deviceKey);
    if (id == null) {
      id = FirebaseFirestore.instance.collection('users').doc().id;
      await _prefs.setString(_deviceKey, id);
    }
    await FirebaseFirestore.instance.collection('users').doc(uid)
        .collection('devices').doc(id).set({
      'token': token,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> disable(String uid) async {
    if (!isSupported) {
      await _prefs.setBool(_enabledKey, false);
      return;
    }
    if (DemoMode.enabled) {
      await _prefs.setBool(_enabledKey, false);
      return;
    }
    _currentUid = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    try {
      final id = await _prefs.getString(_deviceKey);
      if (id != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid)
            .collection('devices').doc(id).delete();
      }
    } finally {
      // Disable locally even if Firestore is offline; invalidate the token too.
      await _prefs.setBool(_enabledKey, false);
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {
        // Push payloads contain no private report content.
      }
    }
  }
}
