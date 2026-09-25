/// Signed-in identity used by the UI. Live Firebase users are mapped into this
/// so sample-data mode does not need a Firebase [User] instance.
class SessionUser {
  const SessionUser({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;
}
