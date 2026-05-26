import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/models/adoption.dart';
import 'package:stray_pets_mu/providers/adoption_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/widgets/login_required_view.dart';

class AdoptionManagementScreen extends StatefulWidget {
  const AdoptionManagementScreen({super.key});

  @override
  State<AdoptionManagementScreen> createState() => _AdoptionManagementScreenState();
}

class _AdoptionManagementScreenState extends State<AdoptionManagementScreen> {
  Stream<QuerySnapshot>? _stream;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      _stream = FirebaseFirestore.instance
          .collection('adoptions')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final adoptionProvider = context.watch<AdoptionProvider>();

    String _(String key) => AppStrings.get(key, lang);

    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_('adoption_management')),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const LoginRequiredView(icon: Icons.pets),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_('adoption_management')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            if (isPermissionDenied(snapshot.error)) {
              return const LoginRequiredView(icon: Icons.pets);
            }
            return Center(child: Text('${_('error')}: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final adoptions = snapshot.data!.docs;

          if (adoptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(_('no_adoptions'),
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adoptions.length,
            itemBuilder: (context, index) {
              final doc = adoptions[index];
              final data = doc.data() as Map<String, dynamic>;
              final stageName = data['currentStage'] as String? ?? 'application';
              final stage = AdoptionStage.values.firstWhere(
                (s) => s.name == stageName,
                orElse: () => AdoptionStage.application,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _stageColor(stage).withValues(alpha: 0.2),
                    child: Icon(_stageIcon(stage), color: _stageColor(stage), size: 20),
                  ),
                  title: Text(data['petName'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${data['adopterName'] ?? ''} - ${_stageLabel(stage)}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow(_('email'), data['adopterEmail'] ?? ''),
                          _infoRow(_('phone'), data['adopterPhone'] ?? ''),
                          if (data['rejectionReason'] != null)
                            _infoRow(_('rejection_reason'), data['rejectionReason']),
                          const SizedBox(height: 12),
                          if (stage != AdoptionStage.completed &&
                              stage != AdoptionStage.rejected)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _advanceStage(
                                        context, doc.id, stage, adoptionProvider),
                                    icon: const Icon(Icons.arrow_forward, size: 18),
                                    label: Text(_('advance_stage')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _showRejectDialog(context, doc.id, adoptionProvider),
                                    icon: const Icon(Icons.cancel_outlined, size: 18),
                                    label: Text(_('reject')),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _advanceStage(BuildContext context, String id, AdoptionStage current,
      AdoptionProvider provider) async {
    final stages =
        AdoptionStage.values.where((s) => s != AdoptionStage.rejected).toList();
    final idx = stages.indexOf(current);
    if (idx >= stages.length - 1) return;

    final next = stages[idx + 1];
    final lang = context.read<LanguageProvider>().lang;
    final success = await provider.updateStage(id, next, changedBy: 'Admin');
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('stage_advanced', lang))),
      );
    }
  }

  void _showRejectDialog(
      BuildContext context, String id, AdoptionProvider provider) {
    final reasonController = TextEditingController();
    final lang = context.read<LanguageProvider>().lang;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('reject_adoption', lang)),
        content: TextField(
          controller: reasonController,
          decoration:
              InputDecoration(labelText: AppStrings.get('rejection_reason', lang)),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.rejectAdoption(id, reasonController.text);
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.get('adoption_rejected', lang))),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(AppStrings.get('reject', lang)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
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

  String _stageLabel(AdoptionStage stage) {
    return switch (stage) {
      AdoptionStage.application => 'Application',
      AdoptionStage.screening => 'Screening',
      AdoptionStage.meet_greet => 'Meet & Greet',
      AdoptionStage.trial => 'Trial Period',
      AdoptionStage.completed => 'Completed',
      AdoptionStage.rejected => 'Rejected',
    };
  }

}
