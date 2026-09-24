import 'package:flutter/material.dart';

import '../admin/admin_gate.dart';
import '../app/routes.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/status_badge.dart';
import 'my_reports_screen.dart';
import 'search_reports_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.profile});
  final UserModel profile;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _busy = false;

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      if (await NotificationService.instance.isEnabled()) {
        await NotificationService.instance.disable(widget.profile.uid);
      }
    } catch (_) {
      // Push contains only generic status text (no private report information).
      // A notification deletion may be queued until Firestore reconnects.
    }
    try {
      await AuthService().signOut();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppHelpers.friendlyError(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your profile')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Container(padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border)),
            child: Column(children: [
              CircleAvatar(radius: 36, backgroundColor: AppColors.mint,
                child: Text(widget.profile.fullName.isNotEmpty
                  ? widget.profile.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.teal,
                    fontWeight: FontWeight.w800, fontSize: 28))),
              const SizedBox(height: 12),
              Text(widget.profile.fullName, style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 20,
                color: AppColors.ink)),
              const SizedBox(height: 3),
              Text(widget.profile.email,
                style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 10),
              StatusBadge(label: widget.profile.isAdmin
                ? 'Community admin' : 'Community member',
                color: AppColors.teal),
            ]),
          ),
          const SizedBox(height: 22),
          _item(Icons.assignment_outlined, 'My reports',
            'Review the reports you submitted',
            () => AppRoutes.push(context, const MyReportsScreen())),
          _item(Icons.search, 'Search reports',
            'Browse and filter community reports',
            () => AppRoutes.push(context, const SearchReportsScreen())),
          if (widget.profile.isAdmin)
            _item(Icons.admin_panel_settings_outlined, 'Admin dashboard',
              'Review reports and manage users',
              () => AppRoutes.push(context, const AdminGate())),
          _item(Icons.settings_outlined, 'Settings',
            'Profile, alerts and privacy',
            () => AppRoutes.push(context,
              SettingsScreen(profile: widget.profile))),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: _busy ? null : _signOut,
            icon: const Icon(Icons.logout), label: Text(_busy
              ? 'Signing out…' : 'Sign out')),
          const SizedBox(height: 22),
          const DisclaimerCard(),
        ]),
      );

  Widget _item(IconData icon, String title, String subtitle,
    VoidCallback onTap) => Card(
      elevation: 0, color: Colors.white,
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(onTap: onTap,
        leading: Icon(icon, color: AppColors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right)),
    );
}
