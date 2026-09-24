import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../models/risk_report_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widget.dart';
import '../widgets/risk_card.dart';
import 'risk_details_screen.dart';

class SearchReportsScreen extends StatefulWidget {
  const SearchReportsScreen({super.key});
  @override
  State<SearchReportsScreen> createState() => _SearchReportsScreenState();
}

class _SearchReportsScreenState extends State<SearchReportsScreen> {
  final _search = TextEditingController();
  RiskCategory? _category;
  ReportStatus? _status;
  VerificationStatus? _verification;
  int? _days;
  double? _radiusKm;
  LocationResult? _origin;
  bool _locating = false;
  late Stream<List<RiskReportModel>> _reports;

  @override
  void initState() {
    super.initState();
    _updateQuery(notify: false);
    _search.addListener(_onSearch);
  }

  void _onSearch() => setState(() {});

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  void _updateQuery({bool notify = true}) {
    _reports = FirestoreService().watchReports(
      category: _category,
      status: _status,
      verification: _verification,
      since: _days == null ? null : DateTime.now().subtract(
        Duration(days: _days!)),
    );
    if (notify && mounted) setState(() {});
  }

  Future<void> _enableDistance() async {
    setState(() => _locating = true);
    try {
      final location = await LocationService().currentLocation();
      if (mounted) setState(() {
        _origin = location;
        _radiusKm = 10;
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppHelpers.friendlyError(error))));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Search reports')),
        body: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search title, description or location',
                prefixIcon: Icon(Icons.search))),
          ),
          ExpansionTile(title: const Text('Filters'),
            leading: const Icon(Icons.tune, color: AppColors.teal),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              Align(alignment: Alignment.centerLeft,
                child: Text('Category', style: Theme.of(context)
                  .textTheme.titleSmall)),
              Align(alignment: Alignment.centerLeft,
                child: Wrap(spacing: 6,
                  children: [
                    FilterChip(label: const Text('All'),
                      selected: _category == null,
                      onSelected: (_) { _category = null; _updateQuery(); }),
                    ...RiskCategory.values.map((c) => FilterChip(
                      label: Text(c.label), selected: _category == c,
                      onSelected: (_) { _category = c; _updateQuery(); })),
                  ])),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: DropdownButtonFormField<ReportStatus?>(
                  initialValue: _status, isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem<ReportStatus?>(value: null,
                      child: Text('Any status')),
                    ...ReportStatus.values.map((v) =>
                      DropdownMenuItem<ReportStatus?>(value: v,
                        child: Text(v.label, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) { _status = v; _updateQuery(); },
                )),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField<VerificationStatus?>(
                  initialValue: _verification, isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Review'),
                  items: [
                    const DropdownMenuItem<VerificationStatus?>(value: null,
                      child: Text('Any review')),
                    ...VerificationStatus.values.map((v) =>
                      DropdownMenuItem<VerificationStatus?>(value: v,
                        child: Text(v == VerificationStatus.pending
                          ? 'Pending' : v == VerificationStatus.verified
                          ? 'Verified' : 'Rejected'))),
                  ],
                  onChanged: (v) { _verification = v; _updateQuery(); },
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DropdownButtonFormField<int?>(
                  initialValue: _days, isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Date'),
                  items: const [
                    DropdownMenuItem<int?>(value: null, child: Text('Any date')),
                    DropdownMenuItem<int?>(value: 7, child: Text('Last 7 days')),
                    DropdownMenuItem<int?>(value: 30, child: Text('Last 30 days')),
                    DropdownMenuItem<int?>(value: 90, child: Text('Last 90 days')),
                  ],
                  onChanged: (v) { _days = v; _updateQuery(); },
                )),
                const SizedBox(width: 8),
                Expanded(child: _origin == null
                  ? OutlinedButton.icon(
                      onPressed: _locating ? null : _enableDistance,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: Text(_locating ? 'Locating…' : 'Use GPS'))
                  : DropdownButtonFormField<double?>(
                      initialValue: _radiusKm, isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Within'),
                      items: const [
                        DropdownMenuItem<double?>(value: null,
                          child: Text('Any distance')),
                        DropdownMenuItem<double?>(value: 5, child: Text('5 km')),
                        DropdownMenuItem<double?>(value: 10, child: Text('10 km')),
                        DropdownMenuItem<double?>(value: 25, child: Text('25 km')),
                        DropdownMenuItem<double?>(value: 50, child: Text('50 km')),
                      ],
                      onChanged: (v) => setState(() => _radiusKm = v),
                    )),
              ]),
            ],
          ),
          const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 7),
            child: Text('Showing up to 100 most recent matches. Text and '
              'distance search apply to those results.',
              style: TextStyle(color: AppColors.muted, fontSize: 11))),
          Expanded(child: StreamBuilder<List<RiskReportModel>>(
            stream: _reports,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }
              if (snapshot.hasError) return EmptyState(
                icon: Icons.cloud_off, title: 'Search unavailable',
                message: AppHelpers.friendlyError(snapshot.error!));
              final query = _search.text.trim().toLowerCase();
              final results = (snapshot.data ?? []).where((r) {
                if (query.isNotEmpty && !('${r.title} ${r.description} '
                    '${r.address} ${r.category.label}').toLowerCase()
                      .contains(query)) return false;
                if (_origin != null && _radiusKm != null &&
                    AppHelpers.distanceKm(_origin!.latitude, _origin!.longitude,
                      r.latitude, r.longitude) > _radiusKm!) return false;
                return true;
              }).toList();
              if (results.isEmpty) return const EmptyState(
                icon: Icons.search_off, title: 'No matches',
                message: 'Try another category, date, location or search term.');
              return ListView(padding: const EdgeInsets.all(16),
                children: results.map((r) => RiskCard(report: r,
                  showStatus: true,
                  distanceKm: _origin == null ? null : AppHelpers.distanceKm(
                    _origin!.latitude, _origin!.longitude,
                    r.latitude, r.longitude),
                  onTap: () => AppRoutes.push(context,
                    RiskDetailsScreen(reportId: r.reportId)))).toList());
            },
          )),
        ])),
      );
}
