import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class EditPetScreen extends StatefulWidget {
  final String petId;
  final Map<String, dynamic> pet;
  const EditPetScreen({super.key, required this.petId, required this.pet});
  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}
class _EditPetScreenState extends State<EditPetScreen> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _ageController;
  late TextEditingController _contactController;
  late String _type;
  late String _gender;
  late bool _vaccinated;
  late bool _sterilized;
  late bool _dewormed;
  bool _isLoading = false;
  final _types = ['dogs', 'cats', 'others'];
  final _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet['name'] ?? '');
    _locationController = TextEditingController(text: widget.pet['location'] ?? '');
    _descriptionController = TextEditingController(text: widget.pet['description'] ?? '');
    _ageController = TextEditingController(text: widget.pet['age'] ?? '');
    _contactController = TextEditingController(text: widget.pet['contact'] ?? '');
    _type = widget.pet['type'] ?? 'dogs';
    _gender = widget.pet['gender'] ?? 'Male';
    _vaccinated = widget.pet['vaccinated'] == true;
    _sterilized = widget.pet['sterilized'] == true;
    _dewormed = widget.pet['dewormed'] == true;
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('pets').doc(widget.petId).update({
        'name': _nameController.text.trim(),
        'type': _type,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _gender,
        'contact': _contactController.text.trim(),
        'vaccinated': _vaccinated,
        'sterilized': _sterilized,
        'dewormed': _dewormed,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listing updated successfully')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong please try again')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.edit_outlined, color: AppTheme.primary),
              SizedBox(width: 12),
              Expanded(child: Text('Update your pet listing details below', style: TextStyle(fontSize: 13, color: AppTheme.textDark))),
            ]),
          ),
          const SizedBox(height: 20),
          _f(_nameController, 'Pet Name', Icons.pets),
          const SizedBox(height: 16),
          _f(_ageController, 'Age', Icons.cake_outlined),
          const SizedBox(height: 16),
          _f(_locationController, 'Location', Icons.location_on_outlined),
          const SizedBox(height: 16),
          _f(_descriptionController, 'Description', Icons.description_outlined, maxLines: 4),
          const SizedBox(height: 16),
          _f(_contactController, 'Contact Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          Text('Type', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
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
          Text('Gender', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Row(children: _genders.map((g) => GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: Container(margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _gender == g ? AppTheme.primary : AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(20)),
              child: Text(g, style: TextStyle(color: _gender == g ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500))))).toList()),
          SwitchListTile(title: Text('Vaccinated'), value: _vaccinated, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _vaccinated = v)),
          SwitchListTile(title: Text('Sterilized'), value: _sterilized, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _sterilized = v)),
          SwitchListTile(title: Text('Dewormed'), value: _dewormed, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _dewormed = v)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('Save changes', style: TextStyle(fontSize: 16)))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _f(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
    TextField(controller: c, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}
