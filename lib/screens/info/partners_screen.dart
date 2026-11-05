import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';

class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final textColor = context.textStrong;
    final vet = AppStrings.get('ui_partner_vet', lang);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('partners', lang))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.handshake_outlined, size: 80, color: AppTheme.primary)),
            const SizedBox(height: 16),
            Center(child: Text(AppStrings.get('partners', lang),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor))),
            const SizedBox(height: 8),
            Center(child: Text(AppStrings.get('working_together_for_animal_welfare_in_m', lang),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6)))),
            const SizedBox(height: 32),
            Text(AppStrings.get('veterinary_clinics', lang),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            _PartnerCard(name: 'Grand Baie Vet Clinic', type: vet, location: 'Grand Baie', icon: Icons.medical_services_outlined, color: Colors.blue),
            const SizedBox(height: 8),
            _PartnerCard(name: 'Pamplemousses Animal Hospital', type: vet, location: 'Pamplemousses', icon: Icons.local_hospital_outlined, color: Colors.red),
            const SizedBox(height: 24),
            Text(AppStrings.get('animal_shelters', lang),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            _PartnerCard(name: 'MSPCA Mauritius', type: AppStrings.get('ui_partner_shelter', lang), location: 'Port Louis', icon: Icons.home_outlined, color: Colors.orange),
            const SizedBox(height: 8),
            _PartnerCard(name: 'Animal Rescue Mauritius', type: AppStrings.get('ui_partner_ngo', lang), location: AppStrings.get('ui_nationwide', lang), icon: Icons.volunteer_activism_outlined, color: Colors.green),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.add_business_outlined, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppStrings.get('become_a_partner', lang), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  Text(AppStrings.get('contact_us_to_join_our_network', lang), style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
      decoration: BoxDecoration(color: context.cardBackground, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: context.textStrong)),
          const SizedBox(height: 4),
          Text('$type - $location', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
      ]),
    );
  }
}
