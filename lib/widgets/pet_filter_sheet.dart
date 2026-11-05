import 'package:flutter/material.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/models/pet_filters.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

/// Bottom sheet for sorting and filtering the pet list.
/// Returns the chosen [PetFilters], or null if dismissed.
Future<PetFilters?> showPetFilterSheet(
    BuildContext context, PetFilters current, String lang) {
  return showModalBottomSheet<PetFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PetFilterSheet(initial: current, lang: lang),
  );
}

class _PetFilterSheet extends StatefulWidget {
  final PetFilters initial;
  final String lang;
  const _PetFilterSheet({required this.initial, required this.lang});

  @override
  State<_PetFilterSheet> createState() => _PetFilterSheetState();
}

class _PetFilterSheetState extends State<_PetFilterSheet> {
  late PetFilters _f = widget.initial;

  String _t(String key) => AppStrings.get(key, widget.lang);

  Widget _heading(String key) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(_t(key),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.textDark),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(_t('filter_sort'),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _f = PetFilters.none),
                child: Text(_t('filter_reset')),
              ),
            ]),
            _heading('sort_by'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in PetSort.values)
                _chip(_t('sort_${s.name}'), _f.sort == s,
                    () => setState(() => _f = _f.copyWith(sort: s))),
            ]),
            _heading('gender'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip(_t('filter_any'), _f.gender == null,
                  () => setState(() => _f = _f.copyWith(clearGender: true))),
              _chip(_t('male'), _f.gender == 'male',
                  () => setState(() => _f = _f.copyWith(gender: 'male'))),
              _chip(_t('female'), _f.gender == 'female',
                  () => setState(() => _f = _f.copyWith(gender: 'female'))),
            ]),
            _heading('age_group'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final a in AgeGroup.values)
                _chip(_t('age_${a.name}'), _f.ageGroup == a,
                    () => setState(() => _f = _f.copyWith(ageGroup: a))),
            ]),
            _heading('health_status'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_t('vaccinated')),
              value: _f.vaccinatedOnly,
              activeThumbColor: AppTheme.primary,
              onChanged: (v) => setState(() => _f = _f.copyWith(vaccinatedOnly: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_t('sterilized')),
              value: _f.sterilizedOnly,
              activeThumbColor: AppTheme.primary,
              onChanged: (v) => setState(() => _f = _f.copyWith(sterilizedOnly: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_t('available_only')),
              value: _f.availableOnly,
              activeThumbColor: AppTheme.primary,
              onChanged: (v) => setState(() => _f = _f.copyWith(availableOnly: v)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _f),
                child: Text(_t('filter_apply')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
