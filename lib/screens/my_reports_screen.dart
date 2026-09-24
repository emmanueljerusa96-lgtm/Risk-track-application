import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../models/risk_report_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widget.dart';
import '../widgets/risk_card.dart';
import 'risk_details_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});
  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late final String _uid = AuthService().currentUser!.uid;
  late final _reports = FirestoreService().watchMyReports(_uid);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My reports')),
        body: StreamBuilder<List<RiskReportModel>>(
          stream: _reports,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }
            if (snapshot.hasError) return EmptyState(
              icon: Icons.cloud_off, title: 'Reports unavailable',
              message: AppHelpers.friendlyError(snapshot.error!));
            final reports = snapshot.data ?? [];
            if (reports.isEmpty) return const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No reports yet',
              message: 'Reports you submit will appear here, along with their review status.');
            return ListView(padding: const EdgeInsets.all(16),
              children: [
                const Text('Your latest 100 submissions and their review status.'),
                const SizedBox(height: 12),
                ...reports.map((r) => RiskCard(report: r, showStatus: true,
                  onTap: () => AppRoutes.push(context,
                    RiskDetailsScreen(reportId: r.reportId)))),
              ],
            );
          },
        ),
      );
}
