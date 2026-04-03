import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/admin/add_pet_screen.dart';
import 'package:stray_pets_mu/screens/admin/inquiries_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _StatCard(label: 'Total Pets', icon: Icons.pets, color: AppTheme.primary,
              stream: FirebaseFirestore.instance.collection('pets').snapshots())),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Inquiries', icon: Icons.mail_outline, color: AppTheme.accent,
              stream: FirebaseFirestore.instance.collection('inquiries').snapshots())),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard(label: 'Adopted', icon: Icons.favorite, color: Colors.green,
              stream: FirebaseFirestore.instance.collection('pets').where('status', isEqualTo: 'adopted').snapshots())),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Pending', icon: Icons.hourglass_empty, color: Colors.orange,
              stream: FirebaseFirestore.instance.collection('inquiries').where('status', isEqualTo: 'pending').snapshots())),
          ]),
          const SizedBox(height: 32),
          Text('Quick actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          _Tile(icon: Icons.add_circle_outline, title: 'Add New Pet', subtitle: 'Register a new pet',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPetScreen()))),
          const SizedBox(height: 12),
          _Tile(icon: Icons.inbox_outlined, title: 'View Inquiries', subtitle: 'Manage adoption inquiries',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InquiriesScreen()))),
        ],
      )),
    );
  }
}
class _StatCard extends StatelessWidget {
  final String label; final IconData icon; final Color color; final Stream<QuerySnapshot> stream;
  const _StatCard({required this.label, required this.icon, required this.color, required this.stream});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: stream,
    builder: (c, snap) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28), const SizedBox(height: 12),
        Text((snap.data?.docs.length ?? 0).toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
      ]),
    ));
}
class _Tile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppTheme.primary)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    ]),
  ));
}