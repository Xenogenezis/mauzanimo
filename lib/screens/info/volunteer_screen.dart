import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';

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

  String _t(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('please_fill_in_all_required_fields'))));
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('something_went_wrong'))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('volunteer', lang))),
      body: _submitted ? _success(lang) : _form(lang),
    );
  }

  Widget _success(String lang) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.check_circle_outline, size: 100, color: AppTheme.primary),
      const SizedBox(height: 24),
      Text(AppStrings.get('thank_you', lang), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.textStrong)),
      const SizedBox(height: 12),
      Text(AppStrings.get('we_have_received_your_volunteer_applicat', lang),
        textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.get('go_back', lang))),
    ])));

  Widget _form(String lang) => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Center(child: Icon(Icons.volunteer_activism_outlined, size: 64, color: Colors.orange)),
      const SizedBox(height: 16),
      Center(child: Text(AppStrings.get('join_our_team', lang), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.textStrong))),
      const SizedBox(height: 8),
      Center(child: Text(AppStrings.get('help_us_make_a_difference_for_stray_anim', lang),
        textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: context.textStrong.withValues(alpha: 0.6)))),
      const SizedBox(height: 32),
      _f(_nameController, AppStrings.get('full_name', lang), Icons.person_outline),
      const SizedBox(height: 16),
      _f(_phoneController, AppStrings.get('phone', lang), Icons.phone_outlined, keyboardType: TextInputType.phone),
      const SizedBox(height: 16),
      _f(_messageController, AppStrings.get('ui_how_help', lang), Icons.message_outlined, maxLines: 4),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(AppStrings.get('apply_to_volunteer', lang)))),
    ]));

  Widget _f(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
    TextField(controller: c, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}