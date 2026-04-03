import 'package:flutter/material.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Donate to Us')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Icon(Icons.favorite, size: 80, color: Colors.red.shade400)),
          const SizedBox(height: 16),
          Center(child: Text('Support mauzanimo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
          const SizedBox(height: 8),
          Center(child: Text('Your donation helps stray pets find lovi',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.6)))),
          const SizedBox(height: 32),
          _InfoCard(icon: Icons.medical_services_outlined, color: Colors.red,
            title: 'Veterinary Care', description: 'Help cover medical costs for rescued animals'),
          const SizedBox(height: 12),
          _InfoCard(icon: Icons.home_outlined, color: Colors.orange,
            title: 'Shelter Support', description: 'Fund shelter operations and animal care'),
          const SizedBox(height: 12),
          _InfoCard(icon: Icons.campaign_outlined, color: AppTheme.primary,
            title: 'Awareness Campaigns', description: 'Spread the word about responsible pet ownership'),
          const SizedBox(height: 32),
          Text('Bank transfer details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(12)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bank mcb mauritius', style: TextStyle(fontSize: 14, color: AppTheme.textDark)),
              SizedBox(height: 6),
              Text('Account name jci grand baie', style: TextStyle(fontSize: 14, color: AppTheme.textDark)),
              SizedBox(height: 6),
              Text('Account no xxxxxxxxxxxx', style: TextStyle(fontSize: 14, color: AppTheme.textDark)),
              SizedBox(height: 6),
              Text('Reference mauzanimo donation', style: TextStyle(fontSize: 14, color: AppTheme.textDark)),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.email_outlined),
            label: Text('Contact us for other payment methods'))),
        ],
      )),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final Color color; final String title, description;
  const _InfoCard({required this.icon, required this.color, required this.title, required this.description});
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