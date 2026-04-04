import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../lang/app_strings.dart';
import '../../providers/language_provider.dart';

class EditLostFoundScreen extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> report;

  const EditLostFoundScreen({
    super.key,
    required this.reportId,
    required this.report,
  });

  @override
  State<EditLostFoundScreen> createState() => _EditLostFoundScreenState();
}

class _EditLostFoundScreenState extends State<EditLostFoundScreen> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _contactController;
  late final TextEditingController _imageUrlController;
  late String _type;
  late String _animalType;
  bool _isLoading = false;

  final _types = ['Lost', 'Found'];
  final _animalTypes = ['Dog', 'Cat', 'Other'];

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data
    _descriptionController = TextEditingController(
      text: widget.report['description'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.report['location'] ?? '',
    );
    _contactController = TextEditingController(
      text: widget.report['contact'] ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.report['imageUrl'] ?? '',
    );
    _type = widget.report['type'] ?? 'Lost';
    _animalType = widget.report['animalType'] ?? 'Dog';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false).lang;

    if (_descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.get('please_fill_in_all_required_fields', lang),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('lostfound')
          .doc(widget.reportId)
          .update({
        'type': _type,
        'animalType': _animalType,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'contact': _contactController.text.trim(),
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
            Text(
              AppStrings.get('report_type', lang),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                final isSelected = _type == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _type = t);
                  },
                  selectedColor: t == 'Lost' ? Colors.red : Colors.green,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: AppTheme.lightGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('animal_type', lang),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _animalTypes.map((t) {
                final isSelected = _animalType == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _animalType = t);
                  },
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: AppTheme.lightGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _field(
              _descriptionController,
              AppStrings.get('description', lang),
              Icons.description_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _field(
              _locationController,
              AppStrings.get('location', lang),
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            _field(
              _contactController,
              AppStrings.get('contact', lang),
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _field(
              _imageUrlController,
              'Photo URL (${lang == 'fr' ? 'optionnel' : 'optional'})',
              Icons.image_outlined,
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
