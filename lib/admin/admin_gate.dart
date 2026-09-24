import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widget.dart';
import 'admin_dashboard.dart';

/// Rechecks the role from Firestore whenever the screen is opened. Firestore
/// rules independently enforce every admin read and write.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});
  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late final String? _uid = AuthService().currentUser?.uid;
  late final Stream<UserModel?>? _profile = _uid == null
      ? null : AuthService().watchProfile(_uid!);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Administration')),
        body: _profile == null
          ? const EmptyState(icon: Icons.lock_outline, title: 'Sign in required',
              message: 'Sign in with an authorized admin account.')
          : StreamBuilder<UserModel?>(stream: _profile,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                if (snapshot.hasError) return EmptyState(
                  icon: Icons.cloud_off, title: 'Could not check permissions',
                  message: AppHelpers.friendlyError(snapshot.error!));
                if (snapshot.data?.isAdmin != true) return const EmptyState(
                  icon: Icons.lock_outline, title: 'Admin access only',
                  message: 'Your account does not have administrator access.');
                return const AdminDashboard();
              },
            ),
      );
}
