import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<UserModel?> watchProfile(String uid) => _firestore
      .collection('users').doc(uid).snapshots()
      .map((snapshot) => snapshot.exists ? UserModel.fromDocument(snapshot) : null);

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final name = fullName.trim();
    final credentials = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail, password: password,
    );
    final user = credentials.user;
    if (user == null) throw StateError('Sign-up did not return a user.');
    await user.updateDisplayName(name);
    // Role is forced to user by Firestore rules; this does not grant admin.
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'fullName': name,
      'email': normalizedEmail,
      'photoUrl': '',
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(), password: password,
    );
  }

  Future<void> resetPassword(String email) => _auth.sendPasswordResetEmail(
        email: email.trim(),
      );

  Future<void> updateFullName(String uid, String name) async {
    await _firestore.collection('users').doc(uid).update({'fullName': name.trim()});
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  /// Recovery for a registration interrupted before its Firestore write.
  /// Use a server read so cached absence can never overwrite an admin profile.
  Future<void> recoverProfile() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;
    final ref = _firestore.collection('users').doc(user.uid);
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

  Future<void> signOut() => _auth.signOut();
}
