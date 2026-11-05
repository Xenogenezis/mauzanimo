import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/models/adoption.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/utils/adoption_sorting.dart';

/// Colour used for [stage] across the adoption screens.
Color adoptionStageColor(AdoptionStage stage) => switch (stage) {
      AdoptionStage.application => Colors.blue,
      AdoptionStage.screening => Colors.orange,
      AdoptionStage.meet_greet => Colors.purple,
      AdoptionStage.trial => Colors.teal,
      AdoptionStage.completed => Colors.green,
      AdoptionStage.rejected => Colors.red,
    };

String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

/// Presentational list of the user's adoptions, grouped into in-progress and
/// closed sections, with an empty state. Has no Firebase dependency.
class MyAdoptionsList extends StatelessWidget {
  final List<Adoption> adoptions;
  final ValueChanged<Adoption> onTap;
  final VoidCallback onBrowse;

  const MyAdoptionsList({
    super.key,
    required this.adoptions,
    required this.onTap,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);
    final groups = groupAdoptions(adoptions);

    if (groups.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volunteer_activism_outlined,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(t('my_adoptions_empty_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
              const SizedBox(height: 8),
              Text(t('my_adoptions_empty_body'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onBrowse,
                icon: const Icon(Icons.pets),
                label: Text(t('my_adoptions_browse')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
          child: Text(text,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark)),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (groups.active.isNotEmpty) ...[
          header(t('my_adoptions_active')),
          for (final a in groups.active)
            MyAdoptionCard(adoption: a, onTap: () => onTap(a)),
        ],
        if (groups.closed.isNotEmpty) ...[
          if (groups.active.isNotEmpty) const SizedBox(height: 12),
          header(t('my_adoptions_closed')),
          for (final a in groups.closed)
            MyAdoptionCard(adoption: a, onTap: () => onTap(a)),
        ],
      ],
    );
  }
}

/// One adoption: pet name, stage chip, application date and step progress.
class MyAdoptionCard extends StatelessWidget {
  final Adoption adoption;
  final VoidCallback onTap;

  const MyAdoptionCard(
      {super.key, required this.adoption, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);
    final stage = adoption.currentStage;
    final color = adoptionStageColor(stage);
    final rejected = stage == AdoptionStage.rejected;
    final reached = adoptionReachedStep(adoption);
    final reason = adoption.rejectionReason;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pets, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adoption.petName.isNotEmpty
                              ? adoption.petName
                              : t('my_adoptions_unknown_pet'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t('my_adoptions_applied_on').replaceAll(
                              '{date}', _formatDate(adoption.createdAt)),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        t('stage_${stage.name}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AdoptionStepProgress(
                reached: reached,
                color: rejected ? Colors.red.shade300 : color,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t('stage_label_${stage.name}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  if (!rejected)
                    Text(
                      t('my_adoptions_step_of')
                          .replaceAll('{n}', '${reached + 1}')
                          .replaceAll('{total}', '${kAdoptionSteps.length}'),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                ],
              ),
              if (rejected && reason != null && reason.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  t('my_adoptions_reason')
                      .replaceAll('{reason}', reason.trim()),
                  style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact segmented bar: one segment per step in [kAdoptionSteps], filled
/// up to and including [reached].
class AdoptionStepProgress extends StatelessWidget {
  final int reached;
  final Color color;

  const AdoptionStepProgress(
      {super.key, required this.reached, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < kAdoptionSteps.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              key: ValueKey('adoption_step_$i'),
              height: 6,
              decoration: BoxDecoration(
                color: i <= reached ? color : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
