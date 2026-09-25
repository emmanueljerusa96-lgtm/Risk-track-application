import 'package:flutter/material.dart';

import '../models/session_user.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';
import 'home_shell.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthService();
  late final Stream<SessionUser?> _authStream = _auth.authStateChanges;

  @override
  Widget build(BuildContext context) => StreamBuilder<SessionUser?>(
        stream: _authStream,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: LoadingWidget(message: 'Checking your account…'));
          }
          final user = authSnapshot.data;
          if (user == null) return const LoginScreen();
          return StreamBuilder(
            stream: _auth.watchProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: LoadingWidget(message: 'Loading your profile…'));
              }
              if (profileSnapshot.hasError) {
                return _ProfileProblem(
                  message: AppHelpers.friendlyError(profileSnapshot.error!),
                  onRetry: () => setState(() {}),
                  onSignOut: _auth.signOut,
                );
              }
              final profile = profileSnapshot.data;
              if (profile == null) {
                return _MissingProfile(auth: _auth);
              }
              return HomeShell(key: ValueKey(user.uid), user: user, profile: profile);
            },
          );
        },
      );
}

class _ProfileProblem extends StatelessWidget {
  const _ProfileProblem({required this.message, required this.onRetry,
    required this.onSignOut});
  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 60, color: AppColors.muted),
            const SizedBox(height: 20),
            const Text('Could not load your profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 22),
            CustomButton(label: 'Retry', onPressed: onRetry),
            TextButton(onPressed: () => onSignOut(),
              child: const Text('Sign out')),
          ])),
        )),
      );
}

class _MissingProfile extends StatefulWidget {
  const _MissingProfile({required this.auth});
  final AuthService auth;
  @override
  State<_MissingProfile> createState() => _MissingProfileState();
}

class _MissingProfileState extends State<_MissingProfile> {
  bool _busy = false;
  String? _error;

  Future<void> _recover() async {
    setState(() { _busy = true; _error = null; });
    try {
      await widget.auth.recoverProfile();
      // Profile stream above will show HomeShell once the write is observed.
    } catch (error) {
      if (mounted) setState(() => _error = AppHelpers.friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_add_alt_1_outlined, size: 58,
              color: AppColors.teal),
            const SizedBox(height: 16),
            const Text('Finish setting up your profile',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Your sign-up may have been interrupted. Reconnect and retry.',
              textAlign: TextAlign.center),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.coral)),
            ],
            const SizedBox(height: 22),
            CustomButton(label: 'Complete profile', loading: _busy,
              onPressed: _recover),
            TextButton(onPressed: _busy ? null : () => widget.auth.signOut(),
              child: const Text('Sign out')),
          ])),
        )),
      );
}
