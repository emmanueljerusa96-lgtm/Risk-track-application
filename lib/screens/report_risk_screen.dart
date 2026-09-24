import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../app/routes.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/status_badge.dart';
import 'location_picker_screen.dart';

class ReportRiskScreen extends StatefulWidget {
  const ReportRiskScreen({super.key});
  @override
  State<ReportRiskScreen> createState() => _ReportRiskScreenState();
}

class _ReportRiskScreenState extends State<ReportRiskScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  RiskCategory? _category;
  LocationResult? _location;
  XFile? _image;
  bool _busy = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _restorePhoto();
  }

  @override
  void dispose() {
    _title.dispose(); _description.dispose();
    super.dispose();
  }

  Future<void> _restorePhoto() async {
    // Android may kill the app while the camera/gallery intent is open.
    try {
      final lost = await ImagePicker().retrieveLostData();
      if (!mounted || lost.isEmpty) return;
      final files = lost.files;
      if (files != null && files.isNotEmpty) {
        setState(() => _image = files.first);
      }
    } catch (_) {
      // The user can simply choose the photo again.
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source, imageQuality: 75, maxWidth: 1600, maxHeight: 1600,
      );
      if (image == null) return;
      if (await image.length() > AppConstants.maxImageBytes) {
        throw const PhotoFailure('Choose a photo smaller than 5 MB.');
      }
      if (mounted) setState(() => _image = image);
    } catch (error) {
      if (mounted) _showError(AppHelpers.friendlyError(error));
    }
  }

  void _showPhotoOptions() => showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'), onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              }),
            ListTile(leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'), onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              }),
          ],
        )),
      );

  Future<void> _getGps() async {
    setState(() => _locating = true);
    try {
      final result = await LocationService().currentLocation();
      if (mounted) setState(() => _location = result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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

  Future<void> _pickOnMap() async {
    final result = await AppRoutes.push<LocationResult>(context,
      LocationPickerScreen(initialPoint: _location == null
        ? null : LatLng(_location!.latitude, _location!.longitude)));
    if (mounted && result != null) setState(() => _location = result);
  }

  void _showError(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_category == null) {
      _showError('Choose a category for this community report.');
      return;
    }
    if (_location == null) {
      _showError('Use GPS or choose the reported location on the map.');
      return;
    }
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      _showError('Please sign in again before submitting a report.');
      return;
    }
    setState(() => _busy = true);
    final service = FirestoreService();
    final reportId = service.newReportId();
    UploadedReportPhoto? photo;
    try {
      if (_image != null) {
        photo = await StorageService().uploadReportImage(
          uid: uid, reportId: reportId, image: _image!);
      }
      await service.createReport(
        reportId: reportId, userId: uid, title: _title.text,
        description: _description.text, category: _category!,
        latitude: _location!.latitude, longitude: _location!.longitude,
        address: _location!.address, imageUrl: photo?.url ?? '',
      );
      if (mounted) Navigator.of(context).pop(reportId);
    } catch (error) {
      if (photo != null) {
        await StorageService().deleteOrphanedPhoto(photo.path);
      }
      if (mounted) _showError(AppHelpers.friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New community report')),
        body: SafeArea(child: Form(key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            children: [
              const DisclaimerCard(),
              const SizedBox(height: 22),
              _label('What did you observe?'),
              const SizedBox(height: 9),
              CustomTextField(controller: _title, label: 'Report title',
                hint: 'e.g. Water across the main road',
                maxLength: 100, validator: Validators.title),
              const SizedBox(height: 10),
              _label('Category'),
              const SizedBox(height: 7),
              CategorySelector(selected: _category,
                onSelected: (value) => setState(() => _category = value)),
              const SizedBox(height: 18),
              _label('Description'),
              const SizedBox(height: 9),
              CustomTextField(controller: _description, label: 'Details',
                hint: 'Describe what you saw and when. Avoid names or private details.',
                maxLines: 5, maxLength: 1500,
                validator: Validators.description),
              const SizedBox(height: 14),
              _label('Reported location'),
              const SizedBox(height: 6),
              const Text('We only request GPS when you tap Use current GPS. '
                'You can place a pin instead.',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.place_outlined, color: AppColors.teal),
                  const SizedBox(width: 9),
                  Expanded(child: Text(_location?.address ?? 'No location selected',
                    style: const TextStyle(color: AppColors.ink))),
                ]),
              ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity,
                child: OutlinedButton.icon(onPressed: _locating ? null : _getGps,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(_locating ? 'Locating…' : 'Use current GPS'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity,
                child: OutlinedButton.icon(onPressed: _pickOnMap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Choose on the map'))),
              const SizedBox(height: 22),
              _label('Photo (optional)'),
              const SizedBox(height: 5),
              const Text('Avoid including faces, number plates, or private information.',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 10),
              if (_image != null) ...[
                ClipRRect(borderRadius: BorderRadius.circular(14),
                  child: Image.file(File(_image!.path),
                    height: 170, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(height: 80,
                      child: Center(child: Text('Could not preview photo'))))),
                TextButton.icon(onPressed: () => setState(() => _image = null),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove photo')),
              ] else OutlinedButton.icon(onPressed: _showPhotoOptions,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Camera or gallery')),
              if (_image != null)
                OutlinedButton.icon(onPressed: _showPhotoOptions,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Change photo')),
              const SizedBox(height: 24),
              CustomButton(label: 'Submit community report',
                icon: Icons.send_outlined, loading: _busy, onPressed: _submit),
              const SizedBox(height: 10),
              const Text('Your report will show as Pending Verification until '
                'an admin reviews it.', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        )),
      );

  Widget _label(String text) => Text(text, style: const TextStyle(
    fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink));
}
