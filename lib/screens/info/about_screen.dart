import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/utils/app_version.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final textColor = context.textStrong;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('about_app', lang))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Icon(Icons.pets, size: 80, color: AppTheme.primary)),
          const SizedBox(height: 16),
          Center(child: Text('MauZanimo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor))),
          const SizedBox(height: 8),
          Center(child: Text(AppStrings.get('connecting_stray_pets_with_loving_homes_', lang),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6)))),
          const SizedBox(height: 32),
          Text(AppStrings.get('our_mission', lang),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text(AppStrings.get('mauzanimo_is_a_digital_adoption_platform', lang),
            style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
          const SizedBox(height: 24),
          Text(AppStrings.get('our_values', lang),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          _ValueTile(icon: Icons.favorite_outline, color: Colors.red,
            title: AppStrings.get('ui_value_compassion', lang),
            description: AppStrings.get('ui_value_compassion_desc', lang)),
          const SizedBox(height: 8),
          _ValueTile(icon: Icons.verified_outlined, color: AppTheme.primary,
            title: AppStrings.get('ui_value_transparency', lang),
            description: AppStrings.get('ui_value_transparency_desc', lang)),
          const SizedBox(height: 8),
          _ValueTile(icon: Icons.groups_outlined, color: Colors.orange,
            title: AppStrings.get('ui_value_community', lang),
            description: AppStrings.get('ui_value_community_desc', lang)),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${AppStrings.get('ui_powered_by', lang)} JCI Grand Baie',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 4),
              Text(AppStrings.get('junior_chamber_international_grand_baie_', lang),
                style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 16),
          Center(child: Text(
            AppStrings.get('ui_version', lang).replaceAll('{version}', kAppVersion),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400))),
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
    decoration: BoxDecoration(color: context.cardBackground, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: context.textStrong)),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
    ]),
  );
}
