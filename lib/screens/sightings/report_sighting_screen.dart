import 'package:stray_pets_mu/utils/image_upload.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../lang/app_strings.dart';
import '../../models/sighting.dart';
import '../../providers/language_provider.dart';
import '../../repositories/sighting_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/geo_utils.dart';
import '../../utils/location_service.dart';
import '../../utils/result.dart';
import '../../utils/offline_write.dart';
import '../../widgets/location_picker.dart';

/// Take a photo of an animal in the street; GPS is captured automatically and
/// the pin can be corrected by tapping the map.
///
/// When opened from a lost-animal report, pass [lostReportId] so the owner
/// sees the sighting under their report.
class ReportSightingScreen extends StatefulWidget {
  final String? lostReportId;
  final String? lostReportSummary;
  final String? initialAnimalType;

  /// Open the camera immediately (quick "I see a stray" flow).
  final bool openCameraOnStart;

  const ReportSightingScreen({
    super.key,
    this.lostReportId,
    this.lostReportSummary,
    this.initialAnimalType,
    this.openCameraOnStart = true,
  });

  @override
  State<ReportSightingScreen> createState() => _ReportSightingScreenState();
}

class _ReportSightingScreenState extends State<ReportSightingScreen> {
  final _picker = ImagePicker();
  final _location = const LocationService();
  final _repo = SightingRepository();
  final _descController = TextEditingController();
  final _placeController = TextEditingController();

  Uint8List? _photo;
  LatLng? _gpsPoint;
  LatLng? _pin;
  double? _accuracy;
  bool _manual = false;
  bool _locating = false;
  LocationFailure? _locationError;
  bool _saving = false;
  late String _animalType;

  static const _types = ['Dog', 'Cat', 'Other'];

  @override
  void initState() {
    super.initState();
    _animalType = _types.contains(widget.initialAnimalType) ? widget.initialAnimalType! : 'Dog';
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  /// If location is already allowed, get the GPS fix while the camera is open
  /// so it's ready when the photo is taken. Otherwise ask for location after
  /// the photo: showing a permission dialog while the camera is launching can
  /// cancel one of the two on Android.
  Future<void> _start() async {
    final granted = await _location.hasPermission().catchError((_) => false);
    if (granted) _locate();
    if (widget.openCameraOnStart) await _pick(ImageSource.camera);
    if (!granted && mounted) await _locate();
  }

  @override
  void dispose() {
    _descController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  String _t(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final fix = await _location.currentFix();
      if (!mounted) return;
      setState(() {
        _gpsPoint = LatLng(fix.latitude, fix.longitude);
        _pin = _gpsPoint;
        _accuracy = fix.accuracyMeters;
        _manual = false;
      });
    } on LocationException catch (e) {
      if (mounted) setState(() => _locationError = e.reason);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      // Resized and compressed to keep the Firestore document well under
      // 1 MB, and stripped of GPS/EXIF metadata: these posts are public.
      final bytes = await pickUploadImage(_picker, source);
      if (bytes == null) return;
      if (mounted) setState(() => _photo = bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('sighting_camera_error'))));
      }
    }
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('sighting_need_photo'))));
      return;
    }
    if (_pin == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('sighting_need_location'))));
      return;
    }
    if (_photo!.lengthInBytes > kMaxUploadImageBytes) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('sighting_photo_too_large'))));
      return;
    }

    setState(() => _saving = true);
    final sighting = Sighting(
      id: '',
      reporterId: user.uid,
      reporterName: user.displayName ?? user.email ?? '',
      animalType: _animalType,
      description: _descController.text.trim(),
      imageUrl: 'data:image/jpeg;base64,${base64Encode(_photo!)}',
      latitude: _pin!.latitude,
      longitude: _pin!.longitude,
      accuracyMeters: _manual ? null : _accuracy,
      manuallyPlaced: _manual,
      locationLabel: _placeController.text.trim().isEmpty ? null : _placeController.text.trim(),
      lostReportId: widget.lostReportId,
    );
    final result = await _repo.create(sighting);
    if (!mounted) return;
    setState(() => _saving = false);
    final error = result.errorOrNull;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final queued = result.dataOrNull == WriteOutcome.queued;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(queued ? 'saved_offline' : 'sighting_thanks'))));
    Navigator.pop(context, true);
  }

  String _locationErrorText(LocationFailure f) => switch (f) {
        LocationFailure.serviceDisabled => _t('gps_off'),
        LocationFailure.denied => _t('gps_denied'),
        LocationFailure.deniedForever => _t('gps_denied_forever'),
        LocationFailure.timeout => _t('gps_timeout'),
        LocationFailure.unknown => _t('gps_unknown_error'),
      };

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);
    final outsideMu = _pin != null && !isInMauritiusRegion(_pin!.latitude, _pin!.longitude);

    return Scaffold(
      appBar: AppBar(title: Text(t(widget.lostReportId != null ? 'i_saw_this_animal' : 'report_sighting'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.lostReportSummary != null)
            Card(
              color: Colors.orange.withValues(alpha: 0.1),
              child: ListTile(
                leading: const Icon(Icons.link, color: Colors.orange),
                title: Text(t('sighting_linked_to_lost')),
                subtitle: Text(widget.lostReportSummary!, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),

          // Photo
          GestureDetector(
            onTap: () => _pick(ImageSource.camera),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: _photo == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_camera, size: 48, color: AppTheme.primary),
                        const SizedBox(height: 8),
                        Text(t('sighting_take_photo')),
                      ],
                    )
                  : Image.memory(_photo!, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(t('camera')),
              ),
              TextButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(t('gallery')),
              ),
            ],
          ),

          // Location
          Row(
            children: [
              const Icon(Icons.my_location, size: 18, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _locating
                      ? t('gps_locating')
                      : _pin == null
                          ? t('gps_tap_map')
                          : '${formatLatLng(_pin!.latitude, _pin!.longitude)}'
                              '${!_manual && _accuracy != null ? '  (±${_accuracy!.round()} m)' : ''}'
                              '${_manual ? '  · ${t('gps_adjusted')}' : ''}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: t('gps_refresh'),
                onPressed: _locating ? null : _locate,
                icon: _locating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.gps_fixed),
              ),
            ],
          ),
          if (_locationError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_locationErrorText(_locationError!),
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                  if (_locationError == LocationFailure.deniedForever)
                    TextButton(onPressed: _location.openSettings, child: Text(t('open_settings'))),
                ],
              ),
            ),
          LocationPicker(
            initial: _gpsPoint,
            accuracyMeters: _manual ? null : _accuracy,
            onChanged: (p) => setState(() {
              _pin = p;
              _manual = true;
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(t('gps_tap_to_adjust'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          if (outsideMu)
            Text(t('gps_outside_mauritius'), style: const TextStyle(fontSize: 12, color: Colors.orange)),
          const SizedBox(height: 16),

          // Details
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'Dog', label: Text(t('dog')), icon: const Icon(Icons.pets)),
              ButtonSegment(value: 'Cat', label: Text(t('cat'))),
              ButtonSegment(value: 'Other', label: Text(t('other'))),
            ],
            selected: {_animalType},
            onSelectionChanged: (s) => setState(() => _animalType = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _placeController,
            decoration: InputDecoration(
              labelText: t('sighting_place_label'),
              hintText: t('sighting_place_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: t('sighting_description'),
              hintText: t('sighting_description_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(t('sighting_submit')),
            ),
          ),
        ],
      ),
    );
  }
}
