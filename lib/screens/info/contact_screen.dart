import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final textColor = context.textStrong;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('ui_contact_support', lang))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Icon(Icons.support_agent_outlined, size: 80, color: Colors.purple)),
          const SizedBox(height: 16),
          Center(child: Text(AppStrings.get('we_are_here_to_help', lang),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor))),
          const SizedBox(height: 8),
          Center(child: Text(AppStrings.get('reach_out_to_us_through_any_of_the_chann', lang),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6)))),
          const SizedBox(height: 32),
          _ContactTile(icon: Icons.email_outlined, color: AppTheme.primary,
            title: AppStrings.get('ui_email_us', lang), subtitle: 'jcigrandbaie@gmail.com'),
          const SizedBox(height: 12),
          _ContactTile(icon: Icons.phone_outlined, color: Colors.green,
            title: AppStrings.get('ui_call_us', lang), subtitle: '+230 5704 7576'),
          const SizedBox(height: 12),
          const _ContactTile(icon: Icons.chat_outlined, color: Colors.blue,
            title: 'WhatsApp', subtitle: '+230 5704 7576'),
          const SizedBox(height: 12),
          _ContactTile(icon: Icons.location_on_outlined, color: Colors.orange,
            title: AppStrings.get('ui_find_us', lang), subtitle: 'Avenue des Goyaviers, Quatre Bornes, Mauritius'),
        ],
      )),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon; final Color color; final String title, subtitle;
  const _ContactTile({required this.icon, required this.color, required this.title, required this.subtitle});
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
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
    ]),
  );
}
