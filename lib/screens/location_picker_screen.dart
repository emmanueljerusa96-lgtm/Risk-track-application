import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/custom_button.dart';

/// A map pin requires no GPS permission. A tap on the map chooses a coordinate.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialPoint});
  final LatLng? initialPoint;
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _point;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _point = widget.initialPoint;
  }

  Future<void> _choose() async {
    final point = _point;
    if (point == null) return;
    setState(() => _busy = true);
    final address = await LocationService()
        .reverseGeocode(point.latitude, point.longitude);
    if (!mounted) return;
    Navigator.of(context).pop(LocationResult(
      latitude: point.latitude,
      longitude: point.longitude,
      address: address,
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Choose a location')),
        body: Column(children: [
          const Padding(padding: EdgeInsets.all(14),
            child: Text('Move the map and tap the reported location to drop a pin. '
              'GPS is not needed.', textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted))),
          Expanded(child: FlutterMap(
            options: MapOptions(initialCenter: widget.initialPoint ??
                AppConstants.initialMapCenter,
              initialZoom: widget.initialPoint == null ? 11 : 15,
              onTap: (_, point) => setState(() => _point = point)),
            children: [
              TileLayer(urlTemplate: AppConstants.mapTiles,
                userAgentPackageName: AppConstants.mapUserAgent),
              if (_point != null) MarkerLayer(markers: [Marker(
                point: _point!, width: 48, height: 48,
                child: const Icon(Icons.location_on, size: 44,
                  color: AppColors.coral),
              )]),
              RichAttributionWidget(attributions: [
                TextSourceAttribution('OpenStreetMap contributors',
                  onTap: () => launchUrl(Uri.parse(
                    AppConstants.mapAttributionUrl))),
              ]),
            ],
          )),
          Padding(padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(_point == null ? 'Tap a point on the map'
                  : AppHelpers.coordinates(_point!.latitude, _point!.longitude),
                style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              CustomButton(label: 'Use this location',
                onPressed: _point == null ? null : _choose, loading: _busy),
            ]),
          ),
        ]),
      );
}
