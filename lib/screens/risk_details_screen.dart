import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/routes.dart';
import '../models/risk_report_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widget.dart';
import '../widgets/status_badge.dart';
import 'map_screen.dart';

class RiskDetailsScreen extends StatefulWidget {
  const RiskDetailsScreen({super.key, required this.reportId,
    this.adminMode = false});
  final String reportId;
  final bool adminMode;

  @override
  State<RiskDetailsScreen> createState() => _RiskDetailsScreenState();
}

class _RiskDetailsScreenState extends State<RiskDetailsScreen> {
  late final _report = FirestoreService().watchReport(widget.reportId);
  bool _reviewing = false;

  Future<void> _flag() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final reason = TextEditingController();
    final form = GlobalKey<FormState>();
    String? failure;
    var busy = false;
    final result = await showDialog<bool>(context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) {
          return AlertDialog(
            title: const Text('Report incorrect information'),
            content: Form(key: form, child: TextFormField(
              controller: reason, maxLines: 4, maxLength: 500,
              validator: Validators.flagReason,
              decoration: const InputDecoration(
                labelText: 'What needs review?',
                hintText: 'Explain the inaccurate or outdated detail.',
              ),
            )),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
              FilledButton(onPressed: busy ? null : () async {
                if (!form.currentState!.validate()) return;
                update(() => busy = true);
                try {
                  final created = await FirestoreService().reportIncorrectInformation(
                    reportId: widget.reportId, uid: uid, reason: reason.text,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, created);
                } catch (error) {
                  failure = AppHelpers.friendlyError(error);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                }
              }, child: const Text('Send for review')),
            ],
          );
        },
      ),
    );
    reason.dispose();
    if (!mounted) return;
    final message = failure ?? (result == true
      ? 'Thanks. Your concern has been sent for admin review.'
      : result == false ? 'You have already flagged this report.' : null);
    if (message != null) ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _review({ReportStatus? status,
    VerificationStatus? verification}) async {
    final verb = verification == VerificationStatus.verified
        ? 'verify' : verification == VerificationStatus.rejected
        ? 'reject' : 'mark resolved';
    final yes = await showDialog<bool>(context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirm $verb?'),
        content: const Text('This action updates the report for everyone '
          'and notifies its author.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm')),
        ],
      ));
    if (yes != true || !mounted) return;
    setState(() => _reviewing = true);
    try {
      await FirestoreService().reviewReport(widget.reportId,
        status: status, verification: verification);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report review saved.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppHelpers.friendlyError(error))));
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Report details')),
        body: StreamBuilder<RiskReportModel?>(stream: _report,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget(message: 'Loading report…');
            }
            if (snapshot.hasError) return EmptyState(
              icon: Icons.cloud_off, title: 'Could not load report',
              message: AppHelpers.friendlyError(snapshot.error!));
            final report = snapshot.data;
            if (report == null) return const EmptyState(
              icon: Icons.search_off, title: 'Report not found',
              message: 'This community report may no longer be available.');
            return ListView(padding: const EdgeInsets.fromLTRB(20, 7, 20, 27),
              children: [
                if (report.hasImage) ...[
                  ClipRRect(borderRadius: BorderRadius.circular(17),
                    child: Image.network(report.imageUrl, height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 110, color: AppColors.mint,
                        child: const Center(child: Text('Photo unavailable'))))),
                  const SizedBox(height: 17),
                ],
                Row(children: [
                  Icon(report.category.icon, color: report.category.color),
                  const SizedBox(width: 7),
                  Text(report.category.label, style: TextStyle(
                    color: report.category.color, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 8),
                Text(report.title, style: const TextStyle(fontSize: 25,
                  fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 10),
                Wrap(spacing: 7, runSpacing: 7, children: [
                  StatusBadge(label: report.verificationStatus.label,
                    color: report.verificationStatus.color),
                  StatusBadge(label: report.status.label,
                    color: report.status.color),
                ]),
                const SizedBox(height: 19),
                Text('Reported ${AppHelpers.date(report.createdAt)} · '
                  'by ${report.reporterName}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 22),
                _heading('What was reported'),
                const SizedBox(height: 8),
                Text(report.description, style: const TextStyle(
                  height: 1.55, color: AppColors.ink, fontSize: 15)),
                const SizedBox(height: 24),
                _heading('Location'),
                const SizedBox(height: 7),
                Text(report.address, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(AppHelpers.coordinates(report.latitude, report.longitude),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(16),
                  child: SizedBox(height: 190, child: FlutterMap(
                    options: MapOptions(initialCenter: LatLng(
                      report.latitude, report.longitude), initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none)),
                    children: [
                      TileLayer(urlTemplate: AppConstants.mapTiles,
                        userAgentPackageName: AppConstants.mapUserAgent),
                      MarkerLayer(markers: [Marker(
                        point: LatLng(report.latitude, report.longitude),
                        width: 45, height: 45,
                        child: Icon(report.category.icon,
                          size: 36, color: report.category.color),
                      )]),
                      RichAttributionWidget(attributions: [
                        TextSourceAttribution('OpenStreetMap contributors',
                          onTap: () => launchUrl(Uri.parse(
                            AppConstants.mapAttributionUrl))),
                      ]),
                    ],
                  )),
                ),
                const SizedBox(height: 13),
                CustomButton(label: 'View on map', icon: Icons.map_outlined,
                  onPressed: () => AppRoutes.push(context, MapScreen(
                    focusReport: report))),
                const SizedBox(height: 22),
                const DisclaimerCard(),
                const SizedBox(height: 10),
                TextButton.icon(onPressed: _flag,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Report incorrect information')),
                if (widget.adminMode) ...[
                  const Divider(height: 40),
                  _heading('Admin review'),
                  const SizedBox(height: 11),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilledButton.icon(onPressed: _reviewing ? null : () =>
                        _review(verification: VerificationStatus.verified),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Verify')),
                    OutlinedButton.icon(onPressed: _reviewing ? null : () =>
                        _review(verification: VerificationStatus.rejected),
                      icon: const Icon(Icons.block_outlined),
                      label: const Text('Reject')),
                    OutlinedButton.icon(onPressed: _reviewing ? null : () =>
                        _review(status: ReportStatus.resolved),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark resolved')),
                  ]),
                  const SizedBox(height: 20),
                  _heading('Community concerns'),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirestoreService().watchFlags(report.reportId),
                    builder: (context, flags) {
                      if (flags.hasError) return Text(
                        AppHelpers.friendlyError(flags.error!));
                      final entries = flags.data ?? [];
                      if (entries.isEmpty) return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No concerns flagged yet.'));
                      return Column(children: entries.map((flag) => ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: Text(flag['reason'] as String? ?? 'Concern'),
                      )).toList());
                    },
                  ),
                ],
              ],
            );
          },
        ),
      );

  Widget _heading(String text) => Text(text, style: const TextStyle(
    fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink));
}
