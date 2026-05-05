import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/providers/auth_provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/models/rescue_report.dart';
import 'package:stray_pets_mu/providers/rescue_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';

class RescueReportScreen extends StatefulWidget {
  const RescueReportScreen({super.key});

  @override
  State<RescueReportScreen> createState() => _RescueReportScreenState();
}

class _RescueReportScreenState extends State<RescueReportScreen> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  String _animalType = 'dog';
  String _urgency = 'high';
  bool _isSubmitting = false;
  bool _submitted = false;

  String _(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _phoneController.text = authProvider.userProfile?.phone ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descriptionController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_('please_fill_required_fields'))),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final report = RescueReport(
        id: '',
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        animalType: _animalType,
        urgency: _urgency,
        status: 'pending',
        reporterId: user.uid,
        reporterName: user.displayName ?? user.email ?? 'User',
        reporterPhone: _phoneController.text.trim(),
        createdAt: DateTime.now(),
      );

      final provider = context.read<RescueProvider>();
      final success = await provider.createReport(report);
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
        title: Text(_('emergency_rescue')),
        backgroundColor: Colors.red.shade700,
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
            const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
            const SizedBox(height: 24),
            Text(_('report_posted'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            Text(_('rescue_report_received'),
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
    final urgencyColor = _urgency == 'critical'
        ? Colors.red : _urgency == 'high' ? Colors.orange : Colors.amber;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(_('report_injured_stray'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red.shade700))),
            ]),
          ),
          const SizedBox(height: 24),
          Text(_('animal_type'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _animalType,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.pets),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              DropdownMenuItem(value: 'dog', child: Text(_('dogs'))),
              DropdownMenuItem(value: 'cat', child: Text(_('cats'))),
              DropdownMenuItem(value: 'other', child: Text(_('others'))),
            ],
            onChanged: (v) => setState(() => _animalType = v!),
          ),
          const SizedBox(height: 16),
          Text(_('urgency'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(_('urgency_critical'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  subtitle: Text(_('urgency_critical_desc'), style: const TextStyle(fontSize: 12)),
                  value: 'critical',
                  groupValue: _urgency,
                  activeColor: Colors.red,
                  onChanged: (v) => setState(() => _urgency = v!),
                ),
                Divider(height: 1),
                RadioListTile<String>(
                  title: Text(_('urgency_high'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  subtitle: Text(_('urgency_high_desc'), style: const TextStyle(fontSize: 12)),
                  value: 'high',
                  groupValue: _urgency,
                  activeColor: Colors.orange,
                  onChanged: (v) => setState(() => _urgency = v!),
                ),
                Divider(height: 1),
                RadioListTile<String>(
                  title: Text(_('urgency_medium'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade700)),
                  subtitle: Text(_('urgency_medium_desc'), style: const TextStyle(fontSize: 12)),
                  value: 'medium',
                  groupValue: _urgency,
                  activeColor: Colors.amber.shade700,
                  onChanged: (v) => setState(() => _urgency = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _field(_descriptionController, _('description'), Icons.description, maxLines: 3),
          const SizedBox(height: 16),
          _field(_locationController, _('location'), Icons.location_on_outlined),
          const SizedBox(height: 16),
          _field(_phoneController, _('phone'), Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: const Icon(Icons.warning_amber_rounded),
              label: Text(_('submit_rescue'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: urgencyColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
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
