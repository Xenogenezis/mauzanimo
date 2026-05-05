import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/models/foster.dart';
import 'package:stray_pets_mu/providers/foster_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';

class FosterApplicationScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const FosterApplicationScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<FosterApplicationScreen> createState() => _FosterApplicationScreenState();
}

class _FosterApplicationScreenState extends State<FosterApplicationScreen> {
  final _motivationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _availabilityController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  String _(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  @override
  void dispose() {
    _motivationController.dispose();
    _experienceController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_motivationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_('please_fill_required_fields'))),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final foster = Foster(
        id: '',
        petId: widget.petId,
        petName: widget.petName,
        fosterUserId: user.uid,
        fosterUserName: user.displayName ?? user.email ?? 'User',
        startDate: DateTime.now(),
        status: 'pending',
        notes: '${_('motivation')}: ${_motivationController.text.trim()}\n'
            '${_('experience')}: ${_experienceController.text.trim()}\n'
            '${_('availability')}: ${_availabilityController.text.trim()}',
        createdAt: DateTime.now(),
      );

      final provider = context.read<FosterProvider>();
      final success = await provider.createFoster(foster);
      if (success) {
        setState(() => _submitted = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? _('something_went_wrong'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_('something_went_wrong'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_('apply_to_foster')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 100, color: AppTheme.primary),
            const SizedBox(height: 24),
            Text(_('foster_application_submitted'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            Text(_('foster_review_message'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_('go_back')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_('apply_to_foster') + ' ${widget.petName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text(_('foster_program_desc'),
              style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.6))),
          const SizedBox(height: 24),
          _field(_motivationController, _('foster_motivation'), Icons.favorite_outline,
              hint: _('foster_motivation_hint'), maxLines: 4),
          const SizedBox(height: 16),
          _field(_experienceController, _('experience'), Icons.history,
              hint: _('experience_hint'), maxLines: 3),
          const SizedBox(height: 16),
          _field(_availabilityController, _('availability'), Icons.schedule,
              hint: _('availability_hint')),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_('submit_application'), style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {String? hint, int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }
}
