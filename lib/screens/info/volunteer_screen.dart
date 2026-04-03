import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});
  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}
class _VolunteerScreenState extends State<VolunteerScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('volunteers').add({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'message': _messageController.text.trim(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'email': FirebaseAuth.instance.currentUser?.email,
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
      appBar: AppBar(title: Text('Volunteer')),
      body: _submitted ? _success() : _form(),
    );
  }

  Widget _success() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.check_circle_outline, size: 100, color: AppTheme.primary),
      const SizedBox(height: 24),
      Text('Thank you', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 12),
      Text('We have received your volunteer applicat',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Go back')),
    ])));

  Widget _form() => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(child: Icon(Icons.volunteer_activism_outlined, size: 64, color: Colors.orange)),
      const SizedBox(height: 16),
      Center(child: Text('Join our team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
      const SizedBox(height: 8),
      Center(child: Text('Help us make a difference for stray anim',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.6)))),
      const SizedBox(height: 32),
      _f(_nameController, 'Full Name', Icons.person_outline),
      const SizedBox(height: 16),
      _f(_phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
      const SizedBox(height: 16),
      _f(_messageController, 'How would you like to help?', Icons.message_outlined, maxLines: 4),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('Apply to volunteer'))),
    ]));

  Widget _f(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
    TextField(controller: c, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}