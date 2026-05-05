import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/models/rescue_report.dart';
import 'package:stray_pets_mu/providers/rescue_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';

class RescueListScreen extends StatelessWidget {
  const RescueListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final user = FirebaseAuth.instance.currentUser;

    String _(String key) => AppStrings.get(key, lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(_('emergency_rescue')),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rescue_reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs;

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(_('no_reports_yet'),
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final data = reports[index].data() as Map<String, dynamic>;
              final urgency = data['urgency'] as String? ?? 'medium';
              final status = data['status'] as String? ?? 'pending';
              final urgencyColor = urgency == 'critical'
                  ? Colors.red : urgency == 'high' ? Colors.orange : Colors.amber.shade700;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: urgencyColor.withValues(alpha: 0.5),
                    width: urgency == 'critical' ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: urgencyColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _('urgency_$urgency'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: urgencyColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _('rescue_report_$status'),
                            style: TextStyle(fontSize: 11, color: _statusColor(status)),
                          ),
                        ),
                        const Spacer(),
                        Text(data['animalType'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                      const SizedBox(height: 8),
                      Text(data['description'] ?? '',
                          style: const TextStyle(fontSize: 14, color: AppTheme.textDark)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(data['location'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey))),
                      ]),
                      const SizedBox(height: 4),
                      Text('${_('reported_by')} ${data['reporterName'] ?? ''} - ${data['reporterPhone'] ?? ''}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      if (status == 'pending' && user != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final provider = context.read<RescueProvider>();
                              final success = await provider.assignVolunteer(
                                reports[index].id,
                                user.uid,
                                user.displayName ?? user.email ?? 'Volunteer',
                              );
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_('assigned_to_you'))),
                                );
                              }
                            },
                            icon: const Icon(Icons.volunteer_activism, size: 18),
                            label: Text(_('assign_to_me')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      if (status == 'assigned' &&
                          data['assignedVolunteerId'] == user?.uid) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('rescue_reports')
                                  .doc(reports[index].id)
                                  .update({'status': 'resolved', 'resolvedAt': FieldValue.serverTimestamp()});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_('marked_resolved'))),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: Text(_('mark_resolved')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pending' => Colors.orange,
      'assigned' => Colors.blue,
      'in_progress' => Colors.purple,
      'resolved' => Colors.green,
      _ => Colors.grey,
    };
  }
}
