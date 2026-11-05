import 'package:stray_pets_mu/utils/jpeg_metadata.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/utils/location_service.dart';
import 'package:stray_pets_mu/utils/offline_write.dart';
import 'package:stray_pets_mu/widgets/location_picker.dart';

class AddLostFoundScreen extends StatefulWidget {
  const AddLostFoundScreen({super.key});
  @override
  State<AddLostFoundScreen> createState() => _AddLostFoundScreenState();
}
class _AddLostFoundScreenState extends State<AddLostFoundScreen> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _photo;
  LatLng? _gps;
  LatLng? _pin;
  bool _locating = false;

  String _t(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      final fix = await const LocationService().currentFix();
      if (mounted) setState(() => _gps = _pin = LatLng(fix.latitude, fix.longitude));
    } on LocationException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_t('ui_lf_gps_failed'))));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 60, maxWidth: 1024);
    if (picked == null) return;
    // Strip GPS and other EXIF metadata: these posts are public.
      final bytes = stripJpegMetadata(await picked.readAsBytes());
    if (mounted) setState(() => _photo = bytes);
  }
  String _type = 'Lost';
  String _animalType = 'Dog';
  bool _isLoading = false;
  bool _submitted = false;
  final _types = ['Lost', 'Found'];
  final _animalTypes = ['Dog', 'Cat', 'Other'];

  /// Display keys for the stored English values.
  static const _typeLabelKeys = {'Lost': 'lf_filter_lost', 'Found': 'lf_filter_found'};
  static const _animalLabelKeys = {'Dog': 'dog', 'Cat': 'cat', 'Other': 'other'};

  Future<void> _submit() async {
    if (_descriptionController.text.isEmpty || _locationController.text.isEmpty || _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('please_fill_in_all_required_fields'))));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await writeOfflineFirst(FirebaseFirestore.instance.collection('lostfound').doc().set({
        'type': _type, 'animalType': _animalType,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'contact': _contactController.text.trim(),
        'imageUrl': _photo != null
            ? 'data:image/jpeg;base64,${base64Encode(_photo!)}'
            : _imageUrlController.text.trim(),
        if (_pin != null) 'geo': GeoPoint(_pin!.latitude, _pin!.longitude),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      }));
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('something_went_wrong_please_try_again'))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('post_lost_found', lang))),
      body: _submitted ? _success(lang) : _form(lang),
    );
  }

  Widget _success(String lang) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.check_circle_outline, size: 100, color: Colors.orange),
      const SizedBox(height: 24),
      Text(AppStrings.get('report_posted', lang), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.textStrong)),
      const SizedBox(height: 12),
      Text(AppStrings.get('your_report_has_been_posted_successfully', lang), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.get('go_back', lang))),
    ])));

  Widget _form(String lang) => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(AppStrings.get('report_type', lang), style: TextStyle(fontWeight: FontWeight.w500, color: context.textStrong)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: _types.map((t) => ChoiceChip(
          label: Text(AppStrings.get(_typeLabelKeys[t]!, lang)),
          selected: _type == t,
          onSelected: (selected) {
            if (selected) setState(() => _type = t);
          },
          selectedColor: _type == 'Lost' ? Colors.red : Colors.green,
          labelStyle: TextStyle(
            color: _type == t ? Colors.white : context.textStrong,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: context.mutedFill,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        )).toList(),
      ),
      const SizedBox(height: 16),
      Text(AppStrings.get('animal_type', lang), style: TextStyle(fontWeight: FontWeight.w500, color: context.textStrong)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: _animalTypes.map((t) => ChoiceChip(
          label: Text(AppStrings.get(_animalLabelKeys[t]!, lang)),
          selected: _animalType == t,
          onSelected: (selected) {
            if (selected) setState(() => _animalType = t);
          },
          selectedColor: AppTheme.primary,
          labelStyle: TextStyle(
            color: _animalType == t ? Colors.white : context.textStrong,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: context.mutedFill,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        )).toList(),
      ),
      const SizedBox(height: 16),
      _f(_descriptionController, AppStrings.get('ui_lf_describe_animal', lang), Icons.description_outlined, maxLines: 3),
      const SizedBox(height: 16),
      _f(_locationController, AppStrings.get('ui_lf_last_seen_location', lang), Icons.location_on_outlined),
      const SizedBox(height: 16),
      _f(_contactController, AppStrings.get('ui_lf_contact_number', lang), Icons.phone_outlined, keyboardType: TextInputType.phone),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: Text(AppStrings.get('pin_location', lang),
            style: TextStyle(fontWeight: FontWeight.w500, color: context.textStrong))),
        TextButton.icon(
          onPressed: _locating ? null : _useGps,
          icon: _locating
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location, size: 18),
          label: Text(AppStrings.get('ui_lf_use_gps', lang)),
        ),
      ]),
      const SizedBox(height: 4),
      LocationPicker(initial: _gps, height: 200, onChanged: (p) => setState(() => _pin = p)),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(AppStrings.get('ui_lf_map_hint', lang),
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ),
      const SizedBox(height: 16),
      Text(AppStrings.get('ui_photo', lang), style: TextStyle(fontWeight: FontWeight.w500, color: context.textStrong)),
      const SizedBox(height: 8),
      if (_photo != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(_photo!, height: 180, width: double.infinity, fit: BoxFit.cover),
        ),
      Row(children: [
        TextButton.icon(onPressed: () => _pickPhoto(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined), label: Text(AppStrings.get('camera', lang))),
        TextButton.icon(onPressed: () => _pickPhoto(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined), label: Text(AppStrings.get('gallery', lang))),
      ]),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(AppStrings.get('post_report', lang), style: const TextStyle(fontSize: 16)))),
    ]));

  Widget _f(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
    TextField(controller: c, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}
