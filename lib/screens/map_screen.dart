import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/routes.dart';
import '../models/risk_report_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/risk_marker.dart';
import '../widgets/status_badge.dart';
import 'risk_details_screen.dart';
import 'search_reports_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.focusReport});
  final RiskReportModel? focusReport;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _controller = MapController();
  late final _reports = FirestoreService().watchReports();
  RiskReportModel? _selected;
  LatLng? _myLocation;
  RiskCategory? _category;
  bool _locating = false;
  bool _tilesUnavailable = false;
  int _tileRetry = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.focusReport;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _centerOnMe() async {
    setState(() => _locating = true);
    try {
      final found = await LocationService().currentLocation();
      if (!mounted) return;
      final point = LatLng(found.latitude, found.longitude);
      setState(() => _myLocation = point);
      _controller.move(point, 14);
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Community map'), actions: [
          IconButton(tooltip: 'Search and filter',
            onPressed: () => AppRoutes.push(context, const SearchReportsScreen()),
            icon: const Icon(Icons.tune)),
        ]),
        body: StreamBuilder<List<RiskReportModel>>(
          stream: _reports,
          builder: (context, snapshot) {
            final reports = snapshot.data ?? [];
            final filtered = _category == null ? reports
                : reports.where((r) => r.category == _category).toList();
            final center = widget.focusReport == null
                ? AppConstants.initialMapCenter
                : LatLng(widget.focusReport!.latitude,
                    widget.focusReport!.longitude);
            return Stack(children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(initialCenter: center,
                  initialZoom: widget.focusReport == null ? 11 : 15),
                children: [
                  TileLayer(key: ValueKey(_tileRetry),
                    urlTemplate: AppConstants.mapTiles,
                    userAgentPackageName: AppConstants.mapUserAgent,
                    errorTileCallback: (_, _, _) {
                      if (_tilesUnavailable) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_tilesUnavailable) {
                          setState(() => _tilesUnavailable = true);
                        }
                      });
                    }),
                  MarkerLayer(markers: [
                    for (final r in filtered)
                      Marker(point: LatLng(r.latitude, r.longitude),
                        width: 50, height: 50,
                        child: RiskMarker(report: r,
                          highlighted: _selected?.reportId == r.reportId,
                          onTap: () => setState(() => _selected = r))),
                    if (widget.focusReport != null &&
                        !filtered.any((r) => r.reportId == widget.focusReport!.reportId))
                      Marker(point: center, width: 50, height: 50,
                        child: RiskMarker(report: widget.focusReport!,
                          highlighted: true, onTap: () => setState(
                            () => _selected = widget.focusReport))),
                    if (_myLocation != null)
                      Marker(point: _myLocation!, width: 34, height: 34,
                        child: const Icon(Icons.my_location,
                          size: 30, color: Colors.blue)),
                  ]),
                  RichAttributionWidget(attributions: [
                    TextSourceAttribution('OpenStreetMap contributors',
                      onTap: () => launchUrl(Uri.parse(
                        AppConstants.mapAttributionUrl))),
                  ]),
                ],
              ),
              if (_tilesUnavailable)
                Positioned(top: 72, left: 12, right: 73,
                  child: Material(color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 3,
                    child: Padding(padding: const EdgeInsets.all(10),
                      child: Column(children: [
                        const Text('Map tiles unavailable. Check your internet.',
                          style: TextStyle(fontSize: 12)),
                        TextButton(onPressed: () => setState(() {
                          _tilesUnavailable = false;
                          _tileRetry++;
                        }), child: const Text('Retry map')),
                      ])),
                  )),
              Positioned(top: 12, left: 12, right: 74,
                child: Material(
                  color: Colors.white, borderRadius: BorderRadius.circular(12),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(child: DropdownButton<RiskCategory?>(
                      value: _category,
                      isExpanded: true,
                      hint: const Text('All reported categories'),
                      items: [
                        const DropdownMenuItem<RiskCategory?>(value: null,
                          child: Text('All reported categories')),
                        ...RiskCategory.values.map((category) =>
                          DropdownMenuItem<RiskCategory?>(value: category,
                            child: Text(category.label))),
                      ],
                      onChanged: (value) => setState(() => _category = value),
                    )),
                  ),
                ),
              ),
              Positioned(right: 12, top: 12, child: Column(children: [
                _mapButton(Icons.add, 'Zoom in', () => _controller.move(
                  _controller.camera.center, _controller.camera.zoom + 1)),
                const SizedBox(height: 8),
                _mapButton(Icons.remove, 'Zoom out', () => _controller.move(
                  _controller.camera.center, _controller.camera.zoom - 1)),
                const SizedBox(height: 8),
                _mapButton(Icons.my_location, 'Center on my location',
                  _locating ? null : _centerOnMe),
              ])),
              Positioned(left: 12, right: 12, bottom: 45,
                child: _selected == null
                  ? Container(padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                      child: Text(snapshot.hasError
                        ? AppHelpers.friendlyError(snapshot.error!)
                        : 'Showing up to 100 recent community reports · '
                          'tap a marker for details. GPS is off until requested.',
                        style: const TextStyle(fontSize: 12, color: AppColors.ink)))
                  : Card(color: Colors.white, elevation: 3,
                      child: InkWell(onTap: () => AppRoutes.push(context,
                        RiskDetailsScreen(reportId: _selected!.reportId)),
                        child: Padding(padding: const EdgeInsets.all(13),
                          child: Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selected!.title,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                StatusBadge(label: _selected!.verificationStatus.label,
                                  color: _selected!.verificationStatus.color),
                              ],
                            )),
                            IconButton(tooltip: 'Close marker details',
                              onPressed: () => setState(() => _selected = null),
                              icon: const Icon(Icons.close)),
                          ]),
                        ),
                      )),
              ),
            ]);
          },
        ),
      );

  Widget _mapButton(IconData icon, String tooltip, VoidCallback? callback) =>
      Material(elevation: 3, color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: IconButton(tooltip: tooltip, onPressed: callback, icon: Icon(icon)));
}
