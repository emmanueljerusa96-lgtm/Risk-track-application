import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widget.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late final _users = FirestoreService().watchUsers();
  final _busy = <String>{};

  Future<void> _changeRole(UserModel user) async {
    final promote = !user.isAdmin;
    final confirmed = await showDialog<bool>(context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(promote ? 'Grant admin access?' : 'Remove admin access?'),
        content: Text('${user.fullName} will ${promote ? 'gain' : 'lose'} '
          'permission to review reports and manage user roles.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm')),
        ],
      ));
    if (confirmed != true || !mounted) return;
    setState(() => _busy.add(user.uid));
    try {
      await FirestoreService().setUserRole(user.uid, admin: promote);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppHelpers.friendlyError(error))));
    } finally {
      if (mounted) setState(() => _busy.remove(user.uid));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Manage users')),
        body: StreamBuilder<List<UserModel>>(stream: _users,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }
            if (snapshot.hasError) return EmptyState(
              icon: Icons.cloud_off, title: 'Users unavailable',
              message: AppHelpers.friendlyError(snapshot.error!));
            final users = snapshot.data ?? [];
            if (users.isEmpty) return const EmptyState(
              icon: Icons.people_outline, title: 'No users yet',
              message: 'Registered community members appear here.');
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Only a trusted administrator can grant roles. '
                'The initial admin must be set through Firebase Admin SDK.',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 12),
              ...users.map((user) => Card(color: Colors.white, elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: AppColors.mint,
                    child: Text(user.fullName.isEmpty ? '?' :
                      user.fullName[0].toUpperCase())),
                  title: Text(user.fullName),
                  subtitle: Text('${user.email}\n${user.isAdmin ? 'Admin' : 'Member'}'),
                  isThreeLine: true,
                  trailing: _busy.contains(user.uid)
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(onPressed: user.uid == AuthService().currentUser?.uid
                        ? null : () => _changeRole(user),
                      child: Text(user.isAdmin ? 'Revoke' : 'Promote')),
                ),
              )),
            ]);
          },
        ),
      );
}
