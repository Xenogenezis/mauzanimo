import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class InquiriesScreen extends StatelessWidget {
  const InquiriesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Adoption inquiries')),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('inquiries').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No inquiries yet', style: TextStyle(color: Colors.grey)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final id = snapshot.data!.docs[index].id;
            return Container(
              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(data['applicantName'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                  _Badge(status: data['status'] ?? 'pending'),
                ]),
                const SizedBox(height: 6),
                Text('Pet: ' + (data['petName'] ?? 'Unknown'), style: const TextStyle(fontSize: 13, color: AppTheme.primary)),
                Text(data['email'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Text(data['phone'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => _update(id, 'rejected'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text('Reject'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () => _update(id, 'approved'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text('Approve'))),
                ]),
              ]),
            );
          });
      }),
  );
  Future<void> _update(String id, String status) =>
    FirebaseFirestore.instance.collection('inquiries').doc(id).update({'status': status});
}
class _Badge extends StatelessWidget {
  final String status;
  const _Badge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)));
  }
}