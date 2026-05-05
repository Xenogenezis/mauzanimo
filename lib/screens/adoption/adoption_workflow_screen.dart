import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/models/adoption.dart';
import 'package:stray_pets_mu/providers/adoption_provider.dart';
import 'package:stray_pets_mu/providers/auth_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';

class AdoptionWorkflowScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  final String petId;

  const AdoptionWorkflowScreen({super.key, required this.pet, required this.petId});

  @override
  State<AdoptionWorkflowScreen> createState() => _AdoptionWorkflowScreenState();
}

class _AdoptionWorkflowScreenState extends State<AdoptionWorkflowScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;
  String? _adoptionId;
  AdoptionStage? _currentStage;
  List<StageRecord> _stageHistory = [];

  String _(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController.text = authProvider.userProfile?.name ?? '';
    _emailController.text = authProvider.email ?? '';
    _phoneController.text = authProvider.userProfile?.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_('please_fill_in_all_required_fields'))),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final adoptionId = FirebaseFirestore.instance.collection('adoptions').doc().id;
      final adoption = Adoption(
        id: adoptionId,
        petId: widget.petId,
        petName: widget.pet['name'] ?? '',
        adopterId: user.uid,
        adopterName: _nameController.text.trim(),
        adopterEmail: _emailController.text.trim(),
        adopterPhone: _phoneController.text.trim(),
        currentStage: AdoptionStage.application,
        stageHistory: [],
        createdAt: DateTime.now(),
      );

      final provider = context.read<AdoptionProvider>();
      final success = await provider.createAdoption(adoption);

      if (success) {
        await FirebaseFirestore.instance.collection('pets').doc(widget.petId).update({
          'status': 'pending',
        });
        setState(() {
          _submitted = true;
          _adoptionId = adoptionId;
          _currentStage = AdoptionStage.application;
        });
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().userProfile?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_('adoption_workflow')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: !_submitted ? _buildApplicationForm() : _buildWorkflowStepper(isAdmin),
    );
  }

  Widget _buildApplicationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_('your_details'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          _field(_nameController, _('full_name'), Icons.person_outline),
          const SizedBox(height: 16),
          _field(_emailController, _('email'), Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _field(_phoneController, _('phone'), Icons.phone_outlined,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _field(_messageController, _('why_adopt_message'), Icons.message_outlined, maxLines: 4),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_('submit_application'), style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStepper(bool isAdmin) {
    final stages =
        AdoptionStage.values.where((s) => s != AdoptionStage.rejected).toList();
    final titles = [
      _('stage_application'),
      _('stage_screening'),
      _('stage_meet_greet'),
      _('stage_trial'),
      _('stage_completed'),
    ];

    final currentIndex = stages.indexOf(_currentStage ?? AdoptionStage.application);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('adoptions')
          .doc(_adoptionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          _currentStage = AdoptionStage.values.firstWhere(
            (s) => s.name == data['currentStage'],
            orElse: () => _currentStage ?? AdoptionStage.application,
          );
          _stageHistory = (data['stageHistory'] as List<dynamic>?)
                  ?.map((e) => StageRecord.fromMap(e as Map<String, dynamic>))
                  .toList() ?? [];
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(widget.pet['name'] ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_('stage_label_${_currentStage?.name ?? 'application'}'),
                        style: TextStyle(
                            fontSize: 14,
                            color: _stageColor(_currentStage ?? AdoptionStage.application))),
                  ],
                ),
              ),
            ),
            ...List.generate(stages.length, (i) {
              final isActive = i == currentIndex;
              final isDone = i < currentIndex;
              return _buildStageTile(stages[i], titles[i], isActive, isDone);
            }),
            if (_currentStage == AdoptionStage.rejected) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(children: [
                  const Icon(Icons.cancel, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                      child:
                          Text(_('stage_rejected'), style: const TextStyle(color: Colors.red))),
                ]),
              ),
            ],
            if (isAdmin &&
                _currentStage != AdoptionStage.completed &&
                _currentStage != AdoptionStage.rejected) ...[
              const SizedBox(height: 24),
              _buildAdminActions(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStageTile(AdoptionStage stage, String title, bool isActive, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive ? AppTheme.primary : Colors.transparent,
            width: isActive ? 2 : 0,
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                isDone ? Colors.green : isActive ? AppTheme.primary : Colors.grey.shade300,
            child: Icon(
              isDone ? Icons.check : _stageIcon(stage),
              color: isDone || isActive ? Colors.white : Colors.grey,
            ),
          ),
          title: Text(title,
              style:
                  TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          subtitle: _findStageRecord(stage) != null
              ? Text(
                  '${_findStageRecord(stage)!.changedBy ?? ''} - ${_formatDate(_findStageRecord(stage)!.timestamp)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey))
              : null,
        ),
      ),
    );
  }

  Widget _buildAdminActions() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_('admin_actions'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_currentStage != AdoptionStage.completed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _advanceStage(),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(_('advance_stage')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRejectDialog(),
                icon: const Icon(Icons.cancel_outlined),
                label: Text(_('reject_adoption')),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _advanceStage() async {
    final next = _nextStage(_currentStage!);
    if (next == null) return;

    final provider = context.read<AdoptionProvider>();
    final success = await provider.updateStage(_adoptionId!, next, changedBy: 'Admin');
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_('stage_advanced'))),
      );
      if (next == AdoptionStage.completed) {
        await FirebaseFirestore.instance
            .collection('pets')
            .doc(widget.petId)
            .update({'status': 'adopted'});
      }
    }
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_('reject_adoption')),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: _('rejection_reason')),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<AdoptionProvider>();
              await provider.rejectAdoption(_adoptionId!, reasonController.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_('adoption_rejected'))),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(_('reject')),
          ),
        ],
      ),
    );
  }

  StageRecord? _findStageRecord(AdoptionStage stage) {
    try {
      return _stageHistory.firstWhere((r) => r.stage == stage);
    } catch (_) {
      return null;
    }
  }

  AdoptionStage? _nextStage(AdoptionStage current) {
    final stages =
        AdoptionStage.values.where((s) => s != AdoptionStage.rejected).toList();
    final idx = stages.indexOf(current);
    if (idx < stages.length - 1) return stages[idx + 1];
    return null;
  }

  Color _stageColor(AdoptionStage stage) {
    return switch (stage) {
      AdoptionStage.application => Colors.blue,
      AdoptionStage.screening => Colors.orange,
      AdoptionStage.meet_greet => Colors.purple,
      AdoptionStage.trial => Colors.teal,
      AdoptionStage.completed => Colors.green,
      AdoptionStage.rejected => Colors.red,
    };
  }

  IconData _stageIcon(AdoptionStage stage) {
    return switch (stage) {
      AdoptionStage.application => Icons.edit_note,
      AdoptionStage.screening => Icons.search,
      AdoptionStage.meet_greet => Icons.handshake,
      AdoptionStage.trial => Icons.home,
      AdoptionStage.completed => Icons.celebration,
      AdoptionStage.rejected => Icons.cancel,
    };
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

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
