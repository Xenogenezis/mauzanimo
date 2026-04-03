import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({super.key});
  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}
class _AddStoryScreenState extends State<AddStoryScreen> {
  final _nameController = TextEditingController();
  final _petNameController = TextEditingController();
  final _storyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  Future<void> _submit() async {
    if (_petNameController.text.isEmpty || _storyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('stories').add({
        'petName': _petNameController.text.trim(),
        'adopterName': _nameController.text.trim(),
        'story': _storyController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _submitted = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong please try again')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Share your story')),
      body: _submitted ? _success() : _form(),
    );
  }

  Widget _success() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.favorite, size: 100, color: Colors.red),
      const SizedBox(height: 24),
      Text('Story shared', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 12),
      Text('Thank you for sharing your adoption stor',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Go back')),
    ])));

  Widget _form() => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.favorite, color: Colors.green),
          SizedBox(width: 12),
          Expanded(child: Text('Share your adoption story and inspire ot',
            style: TextStyle(fontSize: 13, color: AppTheme.textDark))),
        ])),
      const SizedBox(height: 24),
      _f(_nameController, 'Your Name (optional)', Icons.person_outline),
      const SizedBox(height: 16),
      _f(_petNameController, 'Pet Name', Icons.pets),
      const SizedBox(height: 16),
      _f(_imageUrlController, 'Photo URL (optional)', Icons.image_outlined),
      const SizedBox(height: 16),
      _f(_storyController, 'Tell us your story...', Icons.auto_stories_outlined, maxLines: 6),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('Share story', style: TextStyle(fontSize: 16)))),
    ]));

  Widget _f(TextEditingController c, String label, IconData icon, {int maxLines = 1}) =>
    TextField(controller: c, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}