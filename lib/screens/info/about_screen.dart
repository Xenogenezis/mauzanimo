import 'package:flutter/material.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About MauZanimo')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Icon(Icons.pets, size: 80, color: AppTheme.primary)),
          const SizedBox(height: 16),
          Center(child: Text('MauZanimo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
          const SizedBox(height: 8),
          Center(child: Text('Connecting stray pets with loving homes ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.6)))),
          const SizedBox(height: 32),
          Text('Our mission',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text('Mauzanimo is a digital adoption platform',
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
          const SizedBox(height: 24),
          Text('Our values',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          _ValueTile(icon: Icons.favorite_outline, color: Colors.red, title: 'Compassion', description: 'Every animal matters'),
          const SizedBox(height: 8),
          _ValueTile(icon: Icons.verified_outlined, color: AppTheme.primary, title: 'Transparency', description: 'Open and honest adoption process'),
          const SizedBox(height: 8),
          _ValueTile(icon: Icons.groups_outlined, color: Colors.orange, title: 'Community', description: 'Building a kinder Mauritius together'),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Powered by JCI Grand Baie', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              SizedBox(height: 4),
              Text('Junior chamber international grand baie ',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 16),
          Center(child: Text('Version 100', style: TextStyle(fontSize: 12, color: Colors.grey.shade400))),
        ],
      )),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final IconData icon; final Color color; final String title, description;
  const _ValueTile({required this.icon, required this.color, required this.title, required this.description});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
    ]),
  );
}