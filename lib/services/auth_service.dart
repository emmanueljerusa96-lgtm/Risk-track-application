import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/session_user.dart';
import '../models/user_model.dart';
import 'demo_mode.dart';
import 'mock_store.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  bool get _demo => DemoMode.enabled && _auth == null && _firestore == null;
  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firebaseDb => _firestore ?? FirebaseFirestore.instance;

  SessionUser? get currentUser => _demo
      ? MockStore.instance.currentUser
      : _session(_firebaseAuth.currentUser);

  Stream<SessionUser?> get authStateChanges => _demo
      ? MockStore.instance.authChanges
      : _firebaseAuth.authStateChanges().map(_session);

  Stream<UserModel?> watchProfile(String uid) => _demo
      ? MockStore.instance.watchProfile(uid)
      : _firebaseDb.collection('users').doc(uid).snapshots()
          .map((snapshot) => snapshot.exists ? UserModel.fromDocument(snapshot) : null);

  SessionUser? _session(User? user) => user == null
      ? null
      : SessionUser(uid: user.uid, email: user.email, displayName: user.displayName);

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final name = fullName.trim();
    if (_demo) {
      MockStore.instance.register(
        fullName: name, email: normalizedEmail, password: password,
      );
      return;
    }
    final credentials = await _firebaseAuth.createUserWithEmailAndPassword(
      email: normalizedEmail, password: password,
    );
    final user = credentials.user;
    if (user == null) throw StateError('Sign-up did not return a user.');
    await user.updateDisplayName(name);
    // Role is forced to user by Firestore rules; this does not grant admin.
    await _firebaseDb.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'fullName': name,
      'email': normalizedEmail,
      'photoUrl': '',
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login({required String email, required String password}) async {
    if (_demo) {
      MockStore.instance.signIn(email: email, password: password);
      return;
    }
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(), password: password,
    );
  }

  Future<void> resetPassword(String email) {
    if (_demo) return Future<void>.value();
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateFullName(String uid, String name) async {
    if (_demo) {
      MockStore.instance.updateFullName(uid, name);
      return;
    }
    await _firebaseDb.collection('users').doc(uid).update({'fullName': name.trim()});
    await _firebaseAuth.currentUser?.updateDisplayName(name.trim());
  }

  /// Recovery for a registration interrupted before its Firestore write.
  /// Use a server read so cached absence can never overwrite an admin profile.
  Future<void> recoverProfile() async {
    if (_demo) return;
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) return;
    final ref = _firebaseDb.collection('users').doc(user.uid);
    final existing = await ref.get(const GetOptions(source: Source.server));
    if (existing.exists) return;
    final name = (user.displayName ?? '').trim();
    await ref.set({
      'uid': user.uid,
      'fullName': name.length >= 2 ? name : 'Community member',
      'email': user.email!,
      'photoUrl': '',
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() {
    if (_demo) {
      MockStore.instance.signOut();
      return Future<void>.value();
    }
    return _firebaseAuth.signOut();
  }
}
