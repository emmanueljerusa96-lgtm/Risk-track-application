import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../screens/risk_details_screen.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widget.dart';

class FlaggedReportsScreen extends StatefulWidget {
  const FlaggedReportsScreen({super.key});
  @override
  State<FlaggedReportsScreen> createState() => _FlaggedReportsScreenState();
}

class _FlaggedReportsScreenState extends State<FlaggedReportsScreen> {
  late final _flags = FirestoreService().watchAllFlags();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Flagged concerns')),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _flags,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }
            if (snapshot.hasError) return EmptyState(
              icon: Icons.cloud_off, title: 'Concerns unavailable',
              message: AppHelpers.friendlyError(snapshot.error!));
            final flags = snapshot.data ?? [];
            if (flags.isEmpty) return const EmptyState(
              icon: Icons.flag_outlined, title: 'No flagged concerns',
              message: 'Community requests for corrections appear here.');
            return ListView.builder(padding: const EdgeInsets.all(16),
              itemCount: flags.length,
              itemBuilder: (context, index) {
                final flag = flags[index];
                final reportId = flag['reportId'] as String? ?? '';
                return Card(color: Colors.white, elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.flag_outlined,
                      color: AppColors.coral),
                    title: Text(flag['reason'] as String? ?? 'Concern'),
                    subtitle: const Text('Tap to review the linked report'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: reportId.isEmpty ? null : () => AppRoutes.push(
                      context, RiskDetailsScreen(reportId: reportId,
                        adminMode: true)),
                  ));
              },
            );
          },
        ),
      );
}
