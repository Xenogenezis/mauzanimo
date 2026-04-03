import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/language_provider.dart';

class UploadPetScreen extends StatefulWidget {
  const UploadPetScreen({super.key});
  @override
  State<UploadPetScreen> createState() => _UploadPetScreenState();
}
class _UploadPetScreenState extends State<UploadPetScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  String _type = 'dogs';
  String _gender = 'Male';
  bool _vaccinated = false;
  bool _sterilized = false;
  bool _dewormed = false;
bool _isLoading = false;
  bool _submitted = false;
  XFile? _selectedImage;
  final _picker = ImagePicker();
  final _types = ['dogs', 'cats', 'others'];
  final _genders = ['Male', 'Female'];

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(context, 'Camera permission is required to take photos.', 'Permission camera requise pour prendre des photos.')),
            action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<bool> _requestGalleryPermission() async {
    Permission permission;
    if (Platform.isAndroid) {
      permission = Permission.photos;
    } else {
      permission = Permission.photos;
    }
    final status = await permission.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(context, 'Gallery permission is required to choose photos.', 'Permission galerie requise pour choisir des photos.')),
            action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _pickFromCamera() async {
    final granted = await _requestCameraPermission();
    if (!granted) return;
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1200);
    if (picked != null) setState(() => _selectedImage = picked);
  }

  Future<void> _pickFromGallery() async {
    final granted = await _requestGalleryPermission();
    if (!granted) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1200);
    if (picked != null) setState(() => _selectedImage = picked);
  }

  String _t(BuildContext context, String en, String fr) {
    final lang = Provider.of<LanguageProvider>(context, listen: false).lang;
    return lang == 'fr' ? fr : en;
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_t(context, 'Add Photo', 'Ajouter une photo'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary)),
            title: Text(_t(context, 'Take a Photo', 'Prendre une photo')),
            subtitle: Text(_t(context, 'Use your camera', 'Utiliser votre appareil photo')),
            onTap: () { Navigator.pop(context); _pickFromCamera(); },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.photo_library_outlined, color: Colors.purple)),
            title: Text(_t(context, 'Choose from Gallery', 'Choisir depuis la galerie')),
            subtitle: Text(_t(context, 'Pick an existing photo', 'Selectionner une photo existante')),
            onTap: () { Navigator.pop(context); _pickFromGallery(); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty || _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      String imageBase64 = '';
      if (_selectedImage != null) {
        final file = File(_selectedImage!.path);
        final bytes = await file.readAsBytes();
        // Check file size - 500KB limit
        if (bytes.length > 500 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_t(context, 'Image too large. Please select an image under 500KB.', 'Image trop grande. Veuillez selectionner une image de moins de 500KB.'))),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        imageBase64 = 'data:image/jpeg;base64,' + base64Encode(bytes);
      }
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('pets').add({
        'name': _nameController.text.trim(),
        'type': _type,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageBase64,
        'age': _ageController.text.trim(),
        'gender': _gender,
        'vaccinated': _vaccinated,
        'sterilized': _sterilized,
        'dewormed': _dewormed,
'status': 'available',
        'contact': _contactController.text.trim(),
        'uploadedBy': user?.uid,
        'uploaderEmail': user?.email,
        'isUserUpload': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _submitted = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong please try again')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'List Your Pet', 'Publier votre animal'))),
      body: _submitted ? _success() : _form(),
    );
  }

  Widget _success() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.check_circle_outline, size: 100, color: AppTheme.primary),
      const SizedBox(height: 24),
      Text(_t(context, 'Pet Listed!', 'Animal publie!'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 12),
      Text(_t(context, 'Your pet has been listed for adoption. We hope they find a loving home soon!', 'Votre animal a ete mis en adoption. Nous esperons qu\'il trouvera un foyer aimant bientot!'),
        textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        child: Text(_t(context, 'Back to Home', 'Retour accueil'))),
    ])));

  Widget _form() => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.info_outline, color: AppTheme.primary),
          SizedBox(width: 12),
          Expanded(child: Text(_t(context, 'List your pet for adoption and help them find a loving home.', 'Publiez votre animal pour l\'adoption et aidez-le a trouver un foyer aimant.'),
            style: TextStyle(fontSize: 13, color: AppTheme.textDark))),
        ]),
      ),
      const SizedBox(height: 24),
      Text(_t(context, 'Pet Photo', 'Photo de l\'animal'), style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _showImageOptions,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
          ),
          child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover, width: double.infinity))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo_outlined, size: 48, color: AppTheme.primary.withOpacity(0.6)),
                const SizedBox(height: 12),
                Text(_t(context, 'Tap to add a photo', 'Appuyez pour ajouter une photo'), style: TextStyle(color: AppTheme.primary.withOpacity(0.8), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(_t(context, 'Camera or Gallery', 'Appareil photo ou galerie'), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ]),
        ),
      ),
      if (_selectedImage != null) ...[
        const SizedBox(height: 8),
        Center(child: TextButton.icon(
          onPressed: _showImageOptions,
          icon: const Icon(Icons.edit, size: 16),
          label: Text(_t(context, 'Change Photo', 'Changer la photo')),
        )),
      ],
      const SizedBox(height: 16),
      _f(_nameController, 'Pet Name', Icons.pets),
      const SizedBox(height: 16),
      _f(_ageController, 'Age (e.g. 2 years)', Icons.cake_outlined),
      const SizedBox(height: 16),
      _f(_locationController, 'Location', Icons.location_on_outlined),
      const SizedBox(height: 16),
      _f(_descriptionController, 'Tell us about your pet', Icons.description_outlined, maxLines: 4),
      const SizedBox(height: 16),
      _f(_contactController, 'Your Contact Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
      const SizedBox(height: 16),
      Text(_t(context, 'Type', 'Type'), style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      Row(children: _types.map((t) => GestureDetector(
        onTap: () => setState(() => _type = t),
        child: Container(margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _type == t ? AppTheme.primary : AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(20)),
          child: Text(t[0].toUpperCase() + t.substring(1),
            style: TextStyle(color: _type == t ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500))))).toList()),
      const SizedBox(height: 16),
      Text(_t(context, 'Gender', 'Sexe'), style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      Row(children: _genders.map((g) => GestureDetector(
        onTap: () => setState(() => _gender = g),
        child: Container(margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _gender == g ? AppTheme.primary : AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(20)),
          child: Text(g, style: TextStyle(color: _gender == g ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500))))).toList()),
      SwitchListTile(
        title: Text(_t(context, 'Vaccinated', 'Vaccine')), value: _vaccinated,
        activeColor: AppTheme.primary, onChanged: (v) => setState(() => _vaccinated = v)),
      SwitchListTile(
        title: Text(_t(context, 'Sterilized', 'Sterilise')), value: _sterilized,
        activeColor: AppTheme.primary, onChanged: (v) => setState(() => _sterilized = v)),
      SwitchListTile(title: Text(_t(context, 'Dewormed', 'Vermifuge')), value: _dewormed,
        activeColor: AppTheme.primary, onChanged: (v) => setState(() => _dewormed = v)),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(_t(context, 'List My Pet', 'Publier mon animal'), style: TextStyle(fontSize: 16)))),
      const SizedBox(height: 20),
    ]));

  Widget _f(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
    TextField(controller: c, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}
