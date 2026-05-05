import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/models/pet_update.dart';
import 'package:stray_pets_mu/providers/pet_update_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';

class PetUpdateFormScreen extends StatefulWidget {
  final String petId;

  const PetUpdateFormScreen({super.key, required this.petId});

  @override
  State<PetUpdateFormScreen> createState() => _PetUpdateFormScreenState();
}

class _PetUpdateFormScreenState extends State<PetUpdateFormScreen> {
  final _captionController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  String _(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final update = PetUpdate(
        id: '',
        petId: widget.petId,
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'User',
        caption: _captionController.text.trim().isNotEmpty ? _captionController.text.trim() : null,
        createdAt: DateTime.now(),
        imageUrl: null,
      );

      final provider = context.read<PetUpdateProvider>();
      final success = await provider.addUpdate(update);
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
        title: Text(_('add_update')),
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
            Text(_('update_added'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
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
          Text(_('add_update'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text(_('add_update_subtitle'),
              style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.6))),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(_('add_photo'), style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _captionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: _('caption'),
              hintText: _('caption_hint'),
              prefixIcon: const Icon(Icons.message_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
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
}
