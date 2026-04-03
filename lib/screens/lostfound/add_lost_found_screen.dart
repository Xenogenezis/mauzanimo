import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

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
  String _type = 'Lost';
  String _animalType = 'Dog';
  bool _isLoading = false;
  bool _submitted = false;
  final _types = ['Lost', 'Found'];
  final _animalTypes = ['Dog', 'Cat', 'Other'];

  Future<void> _submit() async {
    if (_descriptionController.text.isEmpty || _locationController.text.isEmpty || _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('lostfound').add({
        'type': _type, 'animalType': _animalType,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'contact': _contactController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _submitted = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post lost found')),
      body: _submitted ? _success() : _form(),
    );
  }

  Widget _success() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.check_circle_outline, size: 100, color: Colors.orange),
      const SizedBox(height: 24),
      Text('Report posted', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 12),
      Text('Your report has been posted successfully', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Go back')),
    ])));

  Widget _form() => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Report type', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
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
      Text('Animal type', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
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
      _f(_imageUrlController, 'Photo URL (optional)', Icons.image_outlined),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('Post report', style: TextStyle(fontSize: 16)))),
    ]));

  Widget _f(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
    TextField(controller: c, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}
