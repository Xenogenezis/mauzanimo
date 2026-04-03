const fs = require('fs');
fs.writeFileSync('lib/screens/pets/upload_pet_screen.dart', `import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:stray_pets_mu/theme/app_theme.dart';

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
  bool _isLoading = false;
  bool _submitted = false;
  XFile? _selectedImage;
  final _picker = ImagePicker();
  final _types = ['dogs', 'cats', 'others'];
  final _genders = ['Male', 'Female'];

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1200);
    if (picked != null) setState(() => _selectedImage = picked);
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Add Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary)),
            title: const Text('Take a Photo'),
            subtitle: const Text('Use your camera'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.photo_library_outlined, color: Colors.purple)),
            title: const Text('Choose from Gallery'),
            subtitle: const Text('Pick an existing photo'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty || _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      String imageBase64 = '';
      if (_selectedImage != null) {
        final bytes = await File(_selectedImage!.path).readAsBytes();
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
        'status': 'available',
        'contact': _contactController.text.trim(),
        'uploadedBy': user?.uid,
        'uploaderEmail': user?.email,
        'isUserUpload': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _submitted = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong. Please try again.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List Your Pet')),
      body: _submitted ? _success() : _form(),
    );
  }

  Widget _success() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.check_circle_outline, size: 100, color: AppTheme.primary),
      const SizedBox(height: 24),
      const Text('Pet Listed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 12),
      const Text('Your pet has been listed for adoption. We hope they find a loving home soon!',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Back to Home')),
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
          Expanded(child: Text('List your pet for adoption and help them find a loving home.', style: TextStyle(fontSize: 13, color: AppTheme.textDark))),
        ]),
      ),
      const SizedBox(height: 24),
      const Text('Pet Photo', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _showImageOptions,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2, style: BorderStyle.solid),
          ),
          child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover, width: double.infinity),
              )
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo_outlined, size: 48, color: AppTheme.primary.withOpacity(0.6)),
                const SizedBox(height: 12),
                Text('Tap to add a photo', style: TextStyle(color: AppTheme.primary.withOpacity(0.8), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Camera or Gallery', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ]),
        ),
      ),
      if (_selectedImage != null) ...[
        const SizedBox(height: 8),
        Center(child: TextButton.icon(
          onPressed: _showImageOptions,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Change Photo'),
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
      const Text('Type', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      Row(children: _types.map((t) => GestureDetector(
        onTap: () => setState(() => _type = t),
        child: Container(margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: _type == t ? AppTheme.primary : AppTheme.lightGrey, borderRadius: BorderRadius.circular(20)),
          child: Text(t[0].toUpperCase() + t.substring(1), style: TextStyle(color: _type == t ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500))))).toList()),
      const SizedBox(height: 16),
      const Text('Gender', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      Row(children: _genders.map((g) => GestureDetector(
        onTap: () => setState(() => _gender = g),
        child: Container(margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: _gender == g ? AppTheme.primary : AppTheme.lightGrey, borderRadius: BorderRadius.circular(20)),
          child: Text(g, style: TextStyle(color: _gender == g ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500))))).toList()),
      SwitchListTile(title: const Text('Vaccinated'), value: _vaccinated, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _vaccinated = v)),
      SwitchListTile(title: const Text('Sterilized'), value: _sterilized, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _sterilized = v)),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('List My Pet', style: TextStyle(fontSize: 16)))),
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
`);
console.log('Done!');
