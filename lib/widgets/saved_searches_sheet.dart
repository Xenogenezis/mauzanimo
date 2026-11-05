import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/models/pet.dart';
import 'package:stray_pets_mu/models/saved_search.dart';
import 'package:stray_pets_mu/providers/pet_provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

/// "My alerts": the user's saved searches with their new-match counts.
/// Returns the tapped [SavedSearch], or null if dismissed.
Future<SavedSearch?> showSavedSearchesSheet(BuildContext context, String lang) {
  return showModalBottomSheet<SavedSearch>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SavedSearchesSheet(lang: lang),
  );
}

/// Formats "N new matches" in [lang].
String newMatchesLabel(int n, String lang) {
  if (n == 0) return AppStrings.get('alerts_no_new', lang);
  if (n == 1) return AppStrings.get('alerts_new_matches_one', lang);
  return AppStrings.get('alerts_new_matches', lang).replaceAll('{n}', '$n');
}

class SavedSearchesSheet extends StatefulWidget {
  final String lang;
  const SavedSearchesSheet({super.key, required this.lang});

  @override
  State<SavedSearchesSheet> createState() => _SavedSearchesSheetState();
}

class _SavedSearchesSheetState extends State<SavedSearchesSheet> {
  late final Future<List<Pet>> _recent;

  @override
  void initState() {
    super.initState();
    _recent = context.read<PetProvider>().recentPetsForAlerts();
  }

  String _t(String key) => AppStrings.get(key, widget.lang);

  String _summary(SavedSearch s) {
    final parts = <String>[_t(s.typeFilter.toLowerCase())];
    if (s.query.trim().isNotEmpty) parts.add('"${s.query.trim()}"');
    final n = s.filters.activeCount;
    if (n > 0) {
      parts.add(_t('alerts_filters_count').replaceAll('{n}', '$n'));
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetProvider>();
    final searches = provider.savedSearches;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('alerts_my_alerts'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            if (searches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(_t('alerts_empty'),
                    style: const TextStyle(color: Colors.grey)),
              )
            else
              Flexible(
                child: FutureBuilder<List<Pet>>(
                  future: _recent,
                  builder: (context, snap) => ListView(
                    shrinkWrap: true,
                    children: [
                      for (final s in searches)
                        _tile(s, snap.hasData ? s.newMatchCount(snap.data!) : null),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(SavedSearch s, int? newCount) {
    final hasNew = (newCount ?? 0) > 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
        child: Icon(
            hasNew ? Icons.notifications_active : Icons.bookmark_outline,
            color: AppTheme.primary),
      ),
      title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_summary(s), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (newCount != null)
            Text(
              newMatchesLabel(newCount, widget.lang),
              style: TextStyle(
                color: hasNew ? AppTheme.primary : Colors.grey,
                fontWeight: hasNew ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
      trailing: IconButton(
        tooltip: _t('alerts_delete'),
        icon: const Icon(Icons.delete_outline),
        onPressed: () => context.read<PetProvider>().deleteSavedSearch(s.id),
      ),
      onTap: () => Navigator.pop(context, s),
    );
  }
}
