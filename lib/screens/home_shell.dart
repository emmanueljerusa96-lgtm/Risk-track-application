import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'report_risk_screen.dart';
import 'risk_details_screen.dart';
import 'search_reports_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user, required this.profile});
  final User user;
  final UserModel profile;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selected = 0;
  StreamSubscription<RemoteMessage>? _foregroundMessages;
  StreamSubscription<RemoteMessage>? _openedMessages;
  final _handledPushIds = <String>{};

  @override
  void initState() {
    super.initState();
    NotificationService.instance.resumeIfEnabled(widget.user.uid).catchError(
      (Object _) {},
    );
    _foregroundMessages = FirebaseMessaging.onMessage.listen((message) {
      if (!mounted || message.notification == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message.notification?.title ?? 'A report was updated'),
        action: SnackBarAction(label: 'Alerts', onPressed: () {
          setState(() => _selected = 3);
        }),
      ));
    });
    _openedMessages = FirebaseMessaging.onMessageOpenedApp.listen(_openPush);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _openPush(message);
    }).catchError((Object _) {});
  }

  void _openPush(RemoteMessage message) {
    final value = message.data['reportId'];
    if (value is! String || value.isEmpty) return;
    final reportId = value;
    final id = message.messageId ?? reportId;
    if (!_handledPushIds.add(id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppRoutes.push(context, RiskDetailsScreen(reportId: reportId));
      }
    });
  }

  @override
  void dispose() {
    _foregroundMessages?.cancel();
    _openedMessages?.cancel();
    super.dispose();
  }

  Future<void> _compose() async {
    final reportId = await AppRoutes.push<String>(
      context, const ReportRiskScreen(),
    );
    if (!mounted || reportId == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Community report submitted. It is pending verification.'),
    ));
    setState(() => _selected = 0);
  }

  @override
  Widget build(BuildContext context) {
    final screen = switch (_selected) {
      0 => HomeScreen(
          profile: widget.profile,
          onReport: _compose,
          onMap: () => setState(() => _selected = 1),
          onAlerts: () => setState(() => _selected = 3),
          onBrowse: () => AppRoutes.push(context, const SearchReportsScreen()),
        ),
      1 => const MapScreen(),
      3 => NotificationsScreen(uid: widget.user.uid),
      4 => ProfileScreen(profile: widget.profile),
      _ => const SizedBox.shrink(),
    };
    return Scaffold(
      body: screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        onDestinationSelected: (index) {
          if (index == 2) {
            _compose();
          } else {
            setState(() => _selected = index);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
