import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../lang/app_strings.dart';
import '../../providers/language_provider.dart';

class EditStoryScreen extends StatefulWidget {
  final String storyId;
  final Map<String, dynamic> story;

  const EditStoryScreen({
    super.key,
    required this.storyId,
    required this.story,
  });

  @override
  State<EditStoryScreen> createState() => _EditStoryScreenState();
}

class _EditStoryScreenState extends State<EditStoryScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _petNameController;
  late final TextEditingController _storyController;
  late final TextEditingController _imageUrlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data
    _nameController = TextEditingController(
      text: widget.story['adopterName'] ?? '',
    );
    _petNameController = TextEditingController(
      text: widget.story['petName'] ?? '',
    );
    _storyController = TextEditingController(
      text: widget.story['story'] ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.story['imageUrl'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _petNameController.dispose();
    _storyController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false).lang;

    if (_petNameController.text.isEmpty || _storyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.get('please_fill_required_fields', lang),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(widget.storyId)
          .update({
        'petName': _petNameController.text.trim(),
        'adopterName': _nameController.text.trim(),
        'story': _storyController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.get('listing_updated_successfully', lang),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.get('something_went_wrong_please_try_again', lang),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('edit_listing', lang)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.get('share_your_adoption_story_and_inspire_ot', lang),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _field(
              _nameController,
              lang == 'fr' ? 'Votre nom (optionnel)' : 'Your Name (optional)',
              Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _field(
              _petNameController,
              AppStrings.get('pet_name', lang),
              Icons.pets,
            ),
            const SizedBox(height: 16),
            _field(
              _imageUrlController,
              'Photo URL (${lang == 'fr' ? 'optionnel' : 'optional'})',
              Icons.image_outlined,
            ),
            const SizedBox(height: 16),
            _field(
              _storyController,
              AppStrings.get('share_your_story', lang),
              Icons.auto_stories_outlined,
              maxLines: 6,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(AppStrings.get('save_changes', lang)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }
}
