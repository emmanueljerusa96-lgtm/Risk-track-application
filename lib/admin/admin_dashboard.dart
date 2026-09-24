import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/loading_widget.dart';
import 'flagged_reports_screen.dart';
import 'manage_reports_screen.dart';
import 'manage_users_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<AdminStats> _stats = FirestoreService().adminStats();

  Future<void> _refresh() async {
    setState(() => _stats = FirestoreService().adminStats());
    try { await _stats; } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Overview', style: TextStyle(fontSize: 24,
            fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 5),
          const Text('Live counts on refresh; reviews are enforced by '
            'Firestore security rules.',
            style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 19),
          FutureBuilder<AdminStats>(future: _stats, builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 160, child: LoadingWidget());
            }
            if (snapshot.hasError) return Padding(
              padding: const EdgeInsets.all(12),
              child: Text(AppHelpers.friendlyError(snapshot.error!)));
            final stats = snapshot.data!;
            return Column(children: [
              Row(children: [
                _stat('Users', stats.users, Icons.people_outline),
                const SizedBox(width: 9),
                _stat('Reports', stats.reports, Icons.assignment_outlined),
              ]),
              const SizedBox(height: 9),
              Row(children: [
                _stat('Pending', stats.pending, Icons.hourglass_empty),
                const SizedBox(width: 9),
                _stat('Verified', stats.verified, Icons.verified_outlined),
              ]),
              const SizedBox(height: 9),
              Row(children: [
                _stat('Rejected', stats.rejected, Icons.block_outlined),
                const SizedBox(width: 9),
                _stat('Resolved', stats.resolved, Icons.check_circle_outline),
              ]),
              const SizedBox(height: 9),
              Row(children: [
                _stat('Flags', stats.flags, Icons.flag_outlined),
                const SizedBox(width: 9),
                const Expanded(child: SizedBox.shrink()),
              ]),
            ]);
          }),
          const SizedBox(height: 24),
          const Text('Manage', style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 8),
          _item(context, Icons.fact_check_outlined, 'Review reports',
            'Verify, reject or mark resolved', const ManageReportsScreen()),
          _item(context, Icons.flag_outlined, 'Flagged concerns',
            'Review incorrect-information reports',
            const FlaggedReportsScreen()),
          _item(context, Icons.manage_accounts_outlined, 'Manage users',
            'View accounts and change roles', const ManageUsersScreen()),
        ]),
      );

  Widget _stat(String label, int count, IconData icon) => Expanded(
        child: Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.teal, size: 22),
              const SizedBox(height: 7),
              Text('$count', style: const TextStyle(fontSize: 24,
                fontWeight: FontWeight.w800, color: AppColors.ink)),
              Text(label, style: const TextStyle(color: AppColors.muted,
                fontSize: 12)),
            ]),
        ),
      );

  Widget _item(BuildContext context, IconData icon, String title,
      String subtitle, Widget page) => Card(
        color: Colors.white, elevation: 0,
        child: ListTile(leading: Icon(icon, color: AppColors.teal),
          title: Text(title), subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => AppRoutes.push(context, page)),
      );
}
