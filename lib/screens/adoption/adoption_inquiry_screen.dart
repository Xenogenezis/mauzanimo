import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class AdoptionInquiryScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  final String petId;
  const AdoptionInquiryScreen({super.key, required this.pet, required this.petId});
  @override
  State<AdoptionInquiryScreen> createState() => _AdoptionInquiryScreenState();
}
class _AdoptionInquiryScreenState extends State<AdoptionInquiryScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('inquiries').add({
        'petId': widget.petId,
        'petName': widget.pet['name'],
        'applicantName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
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
      appBar: AppBar(title: Text('Adoption Inquiry')),
      body: _submitted ? _success() : _form(),
    );
  }

  Widget _success() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.check_circle_outline, size: 100, color: AppTheme.primary),
      const SizedBox(height: 24),
      Text('Inquiry Submitted!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 12),
      Text('Thank you! Our team will get in touch with you shortly.',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        child: Text('Back to Home')),
    ])));

  Widget _form() => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Your Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 16),
      _field(_nameController, 'Full Name', Icons.person_outline),
      const SizedBox(height: 16),
      _field(_emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 16),
      _field(_phoneController, 'Phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
      const SizedBox(height: 16),
      _field(_messageController, 'Why do you want to adopt?', Icons.message_outlined, maxLines: 4),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('Submit Inquiry'))),
    ]));

  Widget _field(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
    TextField(controller: c, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}
