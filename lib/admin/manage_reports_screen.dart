import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../models/risk_report_model.dart';
import '../screens/risk_details_screen.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widget.dart';
import '../widgets/risk_card.dart';

enum _ReviewFilter { pending, verified, rejected, resolved, all }

class ManageReportsScreen extends StatefulWidget {
  const ManageReportsScreen({super.key});
  @override
  State<ManageReportsScreen> createState() => _ManageReportsScreenState();
}

class _ManageReportsScreenState extends State<ManageReportsScreen> {
  _ReviewFilter _filter = _ReviewFilter.pending;
  late Stream<List<RiskReportModel>> _stream = _query();

  Stream<List<RiskReportModel>> _query() => FirestoreService().watchReports(
    verification: switch (_filter) {
      _ReviewFilter.pending => VerificationStatus.pending,
      _ReviewFilter.verified => VerificationStatus.verified,
      _ReviewFilter.rejected => VerificationStatus.rejected,
      _ => null,
    },
    status: _filter == _ReviewFilter.resolved ? ReportStatus.resolved : null,
  );

  void _select(_ReviewFilter value) => setState(() {
    _filter = value;
    _stream = _query();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Review reports')),
        body: Column(children: [
          SizedBox(height: 57,
            child: ListView(scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _ReviewFilter.values.map((filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(filter.name[0].toUpperCase() +
                  filter.name.substring(1)),
                  selected: _filter == filter,
                  onSelected: (_) => _select(filter)),
              )).toList()),
          ),
          Expanded(child: StreamBuilder<List<RiskReportModel>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }
              if (snapshot.hasError) return EmptyState(
                icon: Icons.cloud_off, title: 'Reports unavailable',
                message: AppHelpers.friendlyError(snapshot.error!));
              final reports = snapshot.data ?? [];
              if (reports.isEmpty) return const EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'Nothing to review here',
                message: 'New reports and review changes will appear automatically.');
              return ListView(padding: const EdgeInsets.all(16),
                children: [
                  const Text('Showing up to 100 most recent matches.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 9),
                  ...reports.map((report) => RiskCard(report: report,
                    showStatus: true,
                    onTap: () => AppRoutes.push(context, RiskDetailsScreen(
                      reportId: report.reportId, adminMode: true)))),
                ]);
            },
          )),
        ]),
      );
}
