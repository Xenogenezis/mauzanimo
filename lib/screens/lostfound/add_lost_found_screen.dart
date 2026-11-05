import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/utils/location_service.dart';
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
            const SnackBar(content: Text('Could not get GPS location - tap the map instead')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 60, maxWidth: 1024);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _photo = bytes);
  }
  String _type = 'Lost';
  String _animalType = 'Dog';
  bool _isLoading = false;
  bool _submitted = false;
  final _types = ['Lost', 'Found'];
  final _animalTypes = ['Dog', 'Cat', 'Other'];

  Future<void> _submit() async {
    if (_descriptionController.text.isEmpty || _locationController.text.isEmpty || _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('lostfound').add({
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
      });
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post lost found')),
      body: _submitted ? _success() : _form(),
    );
  }

  Widget _success() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.check_circle_outline, size: 100, color: Colors.orange),
      const SizedBox(height: 24),
      const Text('Report posted', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 12),
      const Text('Your report has been posted successfully', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go back')),
    ])));

  Widget _form() => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Report type', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: _types.map((t) => ChoiceChip(
          label: Text(t),
          selected: _type == t,
          onSelected: (selected) {
            if (selected) setState(() => _type = t);
          },
          selectedColor: _type == 'Lost' ? Colors.red : Colors.green,
          labelStyle: TextStyle(
            color: _type == t ? Colors.white : AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: AppTheme.lightGrey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        )).toList(),
      ),
      const SizedBox(height: 16),
      const Text('Animal type', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: _animalTypes.map((t) => ChoiceChip(
          label: Text(t),
          selected: _animalType == t,
          onSelected: (selected) {
            if (selected) setState(() => _animalType = t);
          },
          selectedColor: AppTheme.primary,
          labelStyle: TextStyle(
            color: _animalType == t ? Colors.white : AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: AppTheme.lightGrey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        )).toList(),
      ),
      const SizedBox(height: 16),
      _f(_descriptionController, 'Describe the animal', Icons.description_outlined, maxLines: 3),
      const SizedBox(height: 16),
      _f(_locationController, 'Last seen location', Icons.location_on_outlined),
      const SizedBox(height: 16),
      _f(_contactController, 'Your contact number', Icons.phone_outlined, keyboardType: TextInputType.phone),
      const SizedBox(height: 16),
      Row(children: [
        const Expanded(child: Text('Pin location on map',
            style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark))),
        TextButton.icon(
          onPressed: _locating ? null : _useGps,
          icon: _locating
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location, size: 18),
          label: const Text('Use GPS'),
        ),
      ]),
      const SizedBox(height: 4),
      LocationPicker(initial: _gps, height: 200, onChanged: (p) => setState(() => _pin = p)),
      const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('Tap the map to set where the animal was last seen (optional).',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      ),
      const SizedBox(height: 16),
      const Text('Photo', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      if (_photo != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(_photo!, height: 180, width: double.infinity, fit: BoxFit.cover),
        ),
      Row(children: [
        TextButton.icon(onPressed: () => _pickPhoto(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined), label: const Text('Camera')),
        TextButton.icon(onPressed: () => _pickPhoto(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery')),
      ]),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Post report', style: TextStyle(fontSize: 16)))),
    ]));

  Widget _f(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
    TextField(controller: c, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}
