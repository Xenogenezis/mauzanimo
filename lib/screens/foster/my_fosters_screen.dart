import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';

class MyFostersScreen extends StatelessWidget {
  const MyFostersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final user = FirebaseAuth.instance.currentUser;
    String _(String key) => AppStrings.get(key, lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(_('my_fosters')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? Center(child: Text(_('sign_in_to_continue')))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fosters')
                  .where('fosterUserId', isEqualTo: user.uid)
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
                    final data = fosters[index].data() as Map<String, dynamic>;
                    final status = data['status'] as String? ?? 'pending';
                    final statusColor = status == 'active'
                        ? Colors.green : status == 'pending' ? Colors.orange :
                        status == 'completed' ? Colors.blue : Colors.red;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(data['petName'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(_('foster_status_$status'),
                                    style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                              ),
                            ]),
                            if (data['startDate'] != null) ...[
                              const SizedBox(height: 4),
                              Text('${_('start_date')}: ${_formatDate((data['startDate'] as Timestamp).toDate())}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                            if (data['endDate'] != null) ...[
                              const SizedBox(height: 2),
                              Text('${_('end_date')}: ${_formatDate((data['endDate'] as Timestamp).toDate())}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                            if (data['notes'] != null) ...[
                              const SizedBox(height: 8),
                              Text(data['notes'] as String,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
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

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
