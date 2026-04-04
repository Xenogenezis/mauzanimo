import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});
  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}
class _AddPetScreenState extends State<AddPetScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _ageController = TextEditingController();
  String _type = 'dogs'; String _gender = 'Male';
  bool _vaccinated = false; bool _sterilized = false; bool _dewormed = false; bool _isLoading = false;
  final _types = ['dogs', 'cats', 'others'];
  final _genders = ['Male', 'Female'];

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('pets').add({
        'name': _nameController.text.trim(), 'type': _type,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'age': _ageController.text.trim(), 'gender': _gender,
        'vaccinated': _vaccinated, 'sterilized': _sterilized, 'dewormed': _dewormed,
'status': 'available', 'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pet added')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong')));
    } finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Add new pet')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _f(_nameController, 'Pet Name', Icons.pets),
        const SizedBox(height: 16), _f(_ageController, 'Age', Icons.cake_outlined),
        const SizedBox(height: 16), _f(_locationController, 'Location', Icons.location_on_outlined),
        const SizedBox(height: 16), _f(_imageUrlController, 'Image URL', Icons.image_outlined),
        const SizedBox(height: 16), _f(_descriptionController, 'Description', Icons.description_outlined, maxLines: 4),
        const SizedBox(height: 16),
        Text('Type', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _types.map((t) => ChoiceChip(
            label: Text(t[0].toUpperCase() + t.substring(1)),
            selected: _type == t,
            onSelected: (selected) {
              if (selected) setState(() => _type = t);
            },
            selectedColor: AppTheme.primary,
            labelStyle: TextStyle(
              color: _type == t ? Colors.white : AppTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: AppTheme.lightGrey,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          )).toList(),
        ),
        const SizedBox(height: 16),
        Text('Gender', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _genders.map((g) => ChoiceChip(
            label: Text(g),
            selected: _gender == g,
            onSelected: (selected) {
              if (selected) setState(() => _gender = g);
            },
            selectedColor: AppTheme.primary,
            labelStyle: TextStyle(
              color: _gender == g ? Colors.white : AppTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: AppTheme.lightGrey,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          )).toList(),
        ),
        SwitchListTile(title: Text('Vaccinated'), value: _vaccinated, activeThumbColor: AppTheme.primary, onChanged: (v) => setState(() => _vaccinated = v)),
        SwitchListTile(title: Text('Sterilized'), value: _sterilized, activeThumbColor: AppTheme.primary, onChanged: (v) => setState(() => _sterilized = v)),
        SwitchListTile(title: Text('Dewormed'), value: _dewormed, activeThumbColor: AppTheme.primary, onChanged: (v) => setState(() => _dewormed = v)),
        
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('Save pet'))),
      ],
    )),
  );
  Widget _f(TextEditingController c, String label, IconData icon, {int maxLines = 1}) =>
    TextField(controller: c, maxLines: maxLines, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}