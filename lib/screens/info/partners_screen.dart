import 'package:flutter/material.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Our Partners')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Icon(Icons.handshake_outlined, size: 80, color: AppTheme.primary)),
            const SizedBox(height: 16),
            Center(child: Text('Our Partners',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
            const SizedBox(height: 8),
            Center(child: Text('Working together for animal welfare in m',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.6)))),
            const SizedBox(height: 32),
            Text('Veterinary clinics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            _PartnerCard(name: 'Grand Baie Vet Clinic', type: 'Veterinary', location: 'Grand Baie', icon: Icons.medical_services_outlined, color: Colors.blue),
            const SizedBox(height: 8),
            _PartnerCard(name: 'Pamplemousses Animal Hospital', type: 'Veterinary', location: 'Pamplemousses', icon: Icons.local_hospital_outlined, color: Colors.red),
            const SizedBox(height: 24),
            Text('Animal shelters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            _PartnerCard(name: 'MSPCA Mauritius', type: 'Shelter', location: 'Port Louis', icon: Icons.home_outlined, color: Colors.orange),
            const SizedBox(height: 8),
            _PartnerCard(name: 'Animal Rescue Mauritius', type: 'NGO', location: 'Nationwide', icon: Icons.volunteer_activism_outlined, color: Colors.green),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.add_business_outlined, color: AppTheme.primary),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Become a partner', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  Text('Contact us to join our network', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ])),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final String name, type, location;
  final IconData icon;
  final Color color;
  const _PartnerCard({required this.name, required this.type, required this.location, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 4),
          Text('$type - $location', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
      ]),
    );
  }
}