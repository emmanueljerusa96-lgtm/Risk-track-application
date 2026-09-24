import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widget.dart';
import 'risk_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.uid});
  final String uid;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final _stream = FirestoreService().watchNotifications(widget.uid);
  bool _pushEnabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _readPreference();
  }

  Future<void> _readPreference() async {
    try {
      final enabled = await NotificationService.instance.isEnabled();
      if (mounted) setState(() => _pushEnabled = enabled);
    } catch (_) {
      // In-app notifications still work when optional push is unavailable.
    }
  }

  Future<void> _enable() async {
    setState(() => _busy = true);
    try {
      final allowed = await NotificationService.instance.enable(widget.uid);
      if (!mounted) return;
      setState(() => _pushEnabled = allowed);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(allowed
        ? 'Push alerts enabled for report updates.'
        : 'Notification permission was not granted. In-app updates still work.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppHelpers.friendlyError(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(NotificationModel item) async {
    if (!item.read) {
      try {
        await FirestoreService().markNotificationRead(widget.uid, item.id);
      } catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppHelpers.friendlyError(error))));
      }
    }
    if (mounted && item.reportId.isNotEmpty) {
      AppRoutes.push(context, RiskDetailsScreen(reportId: item.reportId));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: Column(children: [
          if (!_pushEnabled)
            Container(width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: AppColors.mint,
                borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Get optional push alerts', style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  const Text('In-app updates work without push. We only '
                    'request notification permission if you choose to enable it.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  TextButton(onPressed: _busy ? null : _enable,
                    child: Text(_busy ? 'Enabling…' : 'Enable alerts')),
                ]),
            ),
          Expanded(child: StreamBuilder<List<NotificationModel>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }
              if (snapshot.hasError) return EmptyState(
                icon: Icons.cloud_off, title: 'Updates unavailable',
                message: AppHelpers.friendlyError(snapshot.error!));
              final items = snapshot.data ?? [];
              if (items.isEmpty) return const EmptyState(
                icon: Icons.notifications_none,
                title: 'All caught up',
                message: 'Updates about reports you submitted appear here '
                  'when an admin reviews them.');
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(color: item.read ? Colors.white : AppColors.mint,
                    elevation: 0,
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.white,
                        child: Icon(Icons.notifications_active_outlined,
                          color: AppColors.teal)),
                      title: Text(item.title, style: TextStyle(
                        fontWeight: item.read ? FontWeight.w500 : FontWeight.w800)),
                      subtitle: Text('${item.body}\n${AppHelpers.timeAgo(item.createdAt)}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(item),
                    ),
                  );
                },
              );
            },
          )),
        ]),
      );
}
