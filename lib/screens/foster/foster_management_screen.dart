import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/providers/foster_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';

class FosterManagementScreen extends StatelessWidget {
  const FosterManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final fosterProvider = context.read<FosterProvider>();
    String _(String key) => AppStrings.get(key, lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(_('foster_management')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fosters')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final fosters = snapshot.data!.docs;

          if (fosters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(_('no_fosters'),
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fosters.length,
            itemBuilder: (context, index) {
              final doc = fosters[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    child: const Icon(Icons.home, color: AppTheme.primary),
                  ),
                  title: Text(data['petName'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${data['fosterUserName'] ?? ''} - ${_('foster_status_$status')}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['notes'] != null)
                            Text(data['notes'] as String,
                                style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 12),
                          if (status == 'pending')
                            Row(children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await fosterProvider.updateStatus(
                                        doc.id, 'active');
                                  },
                                  icon: const Icon(Icons.check, size: 18),
                                  label: Text(_('approve')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await fosterProvider.updateStatus(
                                        doc.id, 'cancelled');
                                  },
                                  icon: const Icon(Icons.cancel_outlined, size: 18),
                                  label: Text(_('reject')),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                ),
                              ),
                            ]),
                          if (status == 'active')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2030),
                                  ).then((date) {
                                    if (date != null) {
                                      fosterProvider.updateStatus(
                                        doc.id, 'completed',
                                        endDate: date,
                                      );
                                    }
                                  });
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: Text(_('complete_foster')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
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
}
