import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/routes.dart';
import '../models/risk_report_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/risk_card.dart';
import '../widgets/risk_marker.dart';
import '../widgets/status_badge.dart';
import 'risk_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.profile, required this.onReport,
    required this.onMap, required this.onAlerts, required this.onBrowse});
  final UserModel profile;
  final VoidCallback onReport;
  final VoidCallback onMap;
  final VoidCallback onAlerts;
  final VoidCallback onBrowse;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _reports = FirestoreService().watchReports();
  LocationResult? _location;
  bool _locating = false;

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final result = await LocationService().currentLocation();
      if (mounted) setState(() => _location = result);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppHelpers.friendlyError(error)),
        action: error is LocationFailure && error.needsSettings
            ? SnackBarAction(label: 'Settings',
                onPressed: () => error.serviceDisabled
                  ? LocationService().openLocationSettings()
                  : LocationService().openAppSettings())
            : null,
      ));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _openReport(RiskReportModel report) => AppRoutes.push(
    context, RiskDetailsScreen(reportId: report.reportId),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: StreamBuilder<List<RiskReportModel>>(
          stream: _reports,
          builder: (context, snapshot) {
            final reports = snapshot.data ?? [];
            final nearby = _location == null ? <RiskReportModel>[] : reports
                .where((r) => AppHelpers.distanceKm(
                  _location!.latitude, _location!.longitude,
                  r.latitude, r.longitude,
                ) <= 10).toList()
              ..sort((a, b) => AppHelpers.distanceKm(
                  _location!.latitude, _location!.longitude,
                  a.latitude, a.longitude).compareTo(AppHelpers.distanceKm(
                  _location!.latitude, _location!.longitude,
                  b.latitude, b.longitude)));
            return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GOOD TO SEE YOU', style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5, color: AppColors.teal)),
                      const SizedBox(height: 3),
                      Text('Hello, ${widget.profile.fullName.split(' ').first}',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 26,
                          fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ],
                  )),
                  IconButton.filledTonal(onPressed: widget.onAlerts,
                    tooltip: 'Notifications',
                    icon: const Icon(Icons.notifications_none)),
                ]),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    const CircleAvatar(backgroundColor: AppColors.mint,
                      child: Icon(Icons.my_location, color: AppColors.teal)),
                    const SizedBox(width: 11),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('YOUR LOCATION', style: TextStyle(fontSize: 10,
                          color: AppColors.muted, letterSpacing: 1.2,
                          fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(_location?.address ?? 'Not shared', maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                      ],
                    )),
                    _locating
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(onPressed: _locate,
                          child: Text(_location == null ? 'Use GPS' : 'Refresh')),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.deepTeal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.add_location_alt_outlined,
                        size: 31, color: Color(0xFFC8EEE0)),
                      const SizedBox(height: 11),
                      const Text('Notice something worth sharing?',
                        style: TextStyle(color: Colors.white,
                          fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text('Share a community report. Others can stay aware '
                        'while it awaits verification.',
                        style: TextStyle(color: Color(0xFFDAF3EC), height: 1.4)),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(onPressed: widget.onReport,
                        icon: const Icon(Icons.add),
                        label: const Text('Report a location')),
                    ]),
                ),
                const SizedBox(height: 26),
                _heading('Map preview', action: 'Explore map',
                  onAction: widget.onMap),
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(16),
                  child: SizedBox(height: 177, child: Stack(children: [
                    FlutterMap(
                      key: ValueKey(_location?.latitude),
                      options: MapOptions(
                        initialCenter: _location == null
                            ? AppConstants.initialMapCenter
                            : LatLng(_location!.latitude, _location!.longitude),
                        initialZoom: 11,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none),
                      ),
                      children: [
                        TileLayer(urlTemplate: AppConstants.mapTiles,
                          userAgentPackageName: AppConstants.mapUserAgent),
                        MarkerLayer(markers: reports.take(10).map((r) => Marker(
                          point: LatLng(r.latitude, r.longitude),
                          width: 44, height: 44,
                          child: RiskMarker(report: r,
                            onTap: () => _openReport(r)),
                        )).toList()),
                        RichAttributionWidget(attributions: [
                          TextSourceAttribution('OpenStreetMap contributors',
                            onTap: () => launchUrl(Uri.parse(
                              AppConstants.mapAttributionUrl))),
                        ]),
                      ],
                    ),
                    Positioned(top: 10, left: 10,
                      child: FilledButton.tonal(onPressed: widget.onMap,
                        child: const Text('Open map'))),
                  ])),
                ),
                const SizedBox(height: 23),
                _heading('Nearby reports', action: 'Search',
                  onAction: widget.onBrowse),
                const SizedBox(height: 9),
                if (_location == null)
                  _info('Enable GPS to see nearby reports. Location is only '
                    'requested when you tap Use GPS.')
                else if (nearby.isEmpty)
                  _info('No reports within 10 km among the 100 most recent reports.')
                else
                  ...nearby.take(3).map((r) => RiskCard(report: r,
                    distanceKm: AppHelpers.distanceKm(_location!.latitude,
                      _location!.longitude, r.latitude, r.longitude),
                    onTap: () => _openReport(r))),
                const SizedBox(height: 23),
                _heading('Recent community reports', action: 'See all',
                  onAction: widget.onBrowse),
                const SizedBox(height: 9),
                if (snapshot.hasError)
                  _info(AppHelpers.friendlyError(snapshot.error!))
                else if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator()))
                else if (reports.isEmpty)
                  _info('No community reports yet. Be the first to share an observation.')
                else
                  ...reports.take(3).map((r) => RiskCard(report: r,
                    onTap: () => _openReport(r))),
                const SizedBox(height: 13),
                const DisclaimerCard(),
              ],
            );
          },
        )),
      );

  Widget _heading(String title, {required String action,
    required VoidCallback onAction}) => Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontSize: 18,
        fontWeight: FontWeight.w800, color: AppColors.ink))),
      TextButton(onPressed: onAction, child: Text(action)),
    ]);

  Widget _info(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(14)),
    child: Text(text, style: const TextStyle(color: AppColors.muted, height: 1.4)),
  );
}
