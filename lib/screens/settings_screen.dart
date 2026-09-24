import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../widgets/status_badge.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.profile});
  final UserModel profile;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await NotificationService.instance.isEnabled();
      if (mounted) setState(() => _enabled = value);
    } catch (_) {}
  }

  Future<void> _toggle(bool enable) async {
    setState(() => _busy = true);
    try {
      if (enable) {
        final allowed = await NotificationService.instance.enable(widget.profile.uid);
        if (mounted) setState(() => _enabled = allowed);
        if (!allowed && mounted) _message('Notification permission was not granted.');
      } else {
        await NotificationService.instance.disable(widget.profile.uid);
        if (mounted) setState(() => _enabled = false);
      }
    } catch (error) {
      if (mounted) _message(AppHelpers.friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

  Future<void> _editName() async {
    final name = TextEditingController(text: widget.profile.fullName);
    final form = GlobalKey<FormState>();
    final changed = await showDialog<String>(context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Display name'),
        content: Form(key: form, child: TextFormField(
          controller: name, validator: Validators.fullName,
          maxLength: 80, decoration: const InputDecoration(labelText: 'Full name'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
          FilledButton(onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(dialogContext, name.text.trim());
            }
          }, child: const Text('Save')),
        ],
      ));
    name.dispose();
    if (changed == null || !mounted) return;
    try {
      await AuthService().updateFullName(widget.profile.uid, changed);
      if (mounted) _message('Display name updated.');
    } catch (error) {
      if (mounted) _message(AppHelpers.friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('ACCOUNT', style: TextStyle(letterSpacing: 1.4,
            fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted)),
          const SizedBox(height: 9),
          Card(elevation: 0, color: Colors.white,
            child: Column(children: [
              ListTile(leading: const Icon(Icons.badge_outlined),
                title: const Text('Display name'),
                subtitle: Text(widget.profile.fullName),
                trailing: const Icon(Icons.edit_outlined), onTap: _editName),
              ListTile(leading: const Icon(Icons.mail_outline),
                title: const Text('Email address'),
                subtitle: Text(widget.profile.email)),
            ])),
          const SizedBox(height: 22),
          const Text('PERMISSIONS & PRIVACY', style: TextStyle(
            letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.w800,
            color: AppColors.muted)),
          const SizedBox(height: 9),
          Card(elevation: 0, color: Colors.white,
            child: Column(children: [
              SwitchListTile(
                title: const Text('Push notifications'),
                subtitle: const Text('Optional admin review updates. '
                  'In-app notifications do not need this permission.'),
                value: _enabled, onChanged: _busy ? null : _toggle),
              ListTile(leading: const Icon(Icons.location_on_outlined),
                title: const Text('Location permission'),
                subtitle: const Text('GPS is requested only when you choose to use it.'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => LocationService().openAppSettings()),
            ])),
          const SizedBox(height: 22),
          const DisclaimerCard(),
          const SizedBox(height: 14),
          const Text('Map tiles © OpenStreetMap contributors. '
            'Your email is visible only to you and administrators. '
            'Photos should not include personal details.',
            style: TextStyle(fontSize: 12, height: 1.5,
              color: AppColors.muted)),
        ]),
      );
}
