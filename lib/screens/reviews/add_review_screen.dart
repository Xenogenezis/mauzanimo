import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/models/review.dart';
import 'package:stray_pets_mu/providers/review_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';

class AddReviewScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const AddReviewScreen({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  String _(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_('select_rating'))),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final review = Review(
        id: '',
        reviewerId: user.uid,
        reviewerName: user.displayName ?? user.email ?? 'User',
        targetUserId: widget.targetUserId,
        rating: _rating,
        comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
        createdAt: DateTime.now(),
      );

      final provider = context.read<ReviewProvider>();
      final success = await provider.addReview(review);
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
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_('write_review')),
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
            Text(_('review_submitted'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            Text(_('thank_you_for_review'),
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
          Text(_('reviewing') + ' ${widget.targetUserName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 24),
          Center(
            child: Text(_('rating'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: AppTheme.accent,
                    size: 44,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                );
              }),
            ),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                _rating == 1 ? _('rating_poor') :
                _rating == 2 ? _('rating_fair') :
                _rating == 3 ? _('rating_good') :
                _rating == 4 ? _('rating_very_good') : _('rating_excellent'),
                style: TextStyle(fontSize: 14, color: AppTheme.accent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: _('your_comment'),
              hintText: _('comment_hint'),
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
                  : Text(_('submit_review'), style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
