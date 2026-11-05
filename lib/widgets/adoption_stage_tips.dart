import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/models/adoption.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/info/care_guide_screen.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

/// String keys (see `strings_adoption_tips.dart`) of the adopter tips shown
/// for [stage], in display order.
List<String> adoptionTipKeys(AdoptionStage stage) {
  final count = switch (stage) {
    AdoptionStage.application => 4,
    AdoptionStage.screening => 4,
    AdoptionStage.meet_greet => 4,
    AdoptionStage.trial => 4,
    AdoptionStage.completed => 4,
    AdoptionStage.rejected => 3,
  };
  return [for (var i = 1; i <= count; i++) 'adopt_tip_${stage.name}_$i'];
}

/// Collapsible card with practical tips for the adopter at [stage], plus a
/// link to the pet care guide.
class AdoptionStageTips extends StatelessWidget {
  final AdoptionStage stage;
  final bool initiallyExpanded;

  const AdoptionStageTips({
    super.key,
    required this.stage,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);

    return Card(
      elevation: 0,
      color: AppTheme.accent.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        // Reset the expanded state when the stage changes.
        key: ValueKey(stage),
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.lightbulb_outline,
              color: AppTheme.textDark, size: 22),
        ),
        title: Text(t('adopt_tips_title'),
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final key in adoptionTipKeys(stage))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7, right: 10),
                    child: Icon(Icons.circle, size: 6, color: AppTheme.primary),
                  ),
                  Expanded(
                      child: Text(t(key),
                          style: const TextStyle(
                              height: 1.5, color: AppTheme.textDark))),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CareGuideScreen()),
              ),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: Text(t('adopt_tips_care_guide')),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
