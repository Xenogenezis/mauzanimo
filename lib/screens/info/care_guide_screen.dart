import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';

/// Topics in display order. Each has `care_<id>_title` and `care_<id>_body`
/// strings; bodies use one tip per line.
const List<(String, IconData, Color)> kCareTopics = [
  ('first_days', Icons.home_outlined, AppTheme.primary),
  ('vet', Icons.medical_services_outlined, Colors.redAccent),
  ('sterilise', Icons.health_and_safety_outlined, Colors.purple),
  ('parasites', Icons.bug_report_outlined, Colors.brown),
  ('food_heat', Icons.wb_sunny_outlined, Colors.orange),
  ('cyclone', Icons.storm_outlined, Colors.blueGrey),
  ('lost', Icons.search, Colors.deepOrange),
];

/// Offline pet-care guide written for Mauritius.
class CareGuideScreen extends StatelessWidget {
  const CareGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);
    return Scaffold(
      appBar: AppBar(title: Text(t('care_guide'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('care_intro'),
              style: const TextStyle(color: Colors.grey, height: 1.5)),
          const SizedBox(height: 12),
          for (final (id, icon, color) in kCareTopics)
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                title: Text(t('care_${id}_title'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: context.textStrong)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in t('care_${id}_body').split('\n'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: 10),
                            child: Icon(Icons.circle, size: 6, color: color),
                          ),
                          Expanded(
                              child: Text(line,
                                  style: const TextStyle(height: 1.5))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(t('care_disclaimer'),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
