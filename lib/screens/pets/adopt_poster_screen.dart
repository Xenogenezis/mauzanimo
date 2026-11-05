import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../lang/app_strings.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/poster_export.dart';
import '../../widgets/app_image.dart';

/// Localised, singular label for a pet `type` value ('dogs', 'cats', ...).
/// Unknown values are shown as stored.
String adoptPosterTypeLabel(String? type, String lang) {
  final t = (type ?? '').trim().toLowerCase();
  if (t.startsWith('dog')) return AppStrings.get('pd_type_dogs', lang);
  if (t.startsWith('cat')) return AppStrings.get('pd_type_cats', lang);
  if (t.startsWith('other') || t == 'pet') {
    return AppStrings.get('pd_type_others', lang);
  }
  return (type ?? '').trim();
}

String _genderLabel(String? gender, String lang) {
  final g = (gender ?? '').trim().toLowerCase();
  if (g == 'male') return AppStrings.get('pd_gender_male', lang);
  if (g == 'female') return AppStrings.get('pd_gender_female', lang);
  return g == 'unknown' ? '' : (gender ?? '').trim();
}

String _text(dynamic v) {
  final s = (v ?? '').toString().trim();
  return s.toLowerCase() == 'unknown' ? '' : s;
}

/// Printable / shareable A4-style "Adopt me" poster for a pet listing.
class AdoptPosterScreen extends StatefulWidget {
  /// The pet document data (name, type, age, gender, description, location,
  /// contact, imageUrl, vaccinated, sterilized, dewormed).
  final Map<String, dynamic> pet;
  final String petId;

  const AdoptPosterScreen({super.key, required this.pet, required this.petId});

  @override
  State<AdoptPosterScreen> createState() => _AdoptPosterScreenState();
}

class _AdoptPosterScreenState extends State<AdoptPosterScreen> {
  final _posterKey = GlobalKey();
  bool _busy = false;

  String get _fileName {
    final slug = _text(widget.pet['name'])
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'mauzanimo-adopt-${slug.isEmpty ? 'poster' : slug}.png';
  }

  String _shareText(String lang) {
    final p = widget.pet;
    final name = _text(p['name']);
    final type = adoptPosterTypeLabel(p['type'] as String?, lang);
    final location = _text(p['location']);
    final contact = _text(p['contact']);
    return [
      '${AppStrings.get('pd_poster_adopt_me', lang)}: '
          '$name${type.isNotEmpty ? ' ($type)' : ''}',
      if (location.isNotEmpty)
        '${AppStrings.get('pd_poster_location', lang)}: $location',
      if (contact.isNotEmpty)
        '${AppStrings.get('pd_poster_call', lang)}: $contact',
      '',
      AppStrings.get('pd_poster_footer', lang),
    ].join('\n');
  }

  Future<void> _sharePoster(BuildContext buttonContext, String lang) async {
    setState(() => _busy = true);
    // Needed by iPad share sheets; read before any await.
    final origin = shareOriginOf(buttonContext);
    try {
      final result = await exportPoster(
        boundaryKey: _posterKey,
        fileName: _fileName,
        shareText: _shareText(lang),
        shareOrigin: origin,
      );
      if (result == PosterExportResult.downloaded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get('pd_poster_downloaded', lang))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get('pd_poster_error', lang))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('pd_poster_title', lang))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RepaintBoundary(
                  key: _posterKey,
                  child: AspectRatio(
                    aspectRatio: 1 / 1.414,
                    child: _AdoptPoster(pet: widget.pet, lang: lang),
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (buttonContext) => ElevatedButton.icon(
                    onPressed: _busy ? null : () => _sharePoster(buttonContext, lang),
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(kIsWeb ? Icons.download : Icons.share),
                    label: Text(AppStrings.get(
                        kIsWeb ? 'pd_download_poster' : 'pd_share_poster', lang)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get('pd_poster_hint', lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The poster itself. Sizes scale with the poster width so the captured
/// image looks the same on every screen.
class _AdoptPoster extends StatelessWidget {
  final Map<String, dynamic> pet;
  final String lang;

  const _AdoptPoster({required this.pet, required this.lang});

  @override
  Widget build(BuildContext context) {
    final imageUrl = _text(pet['imageUrl']);
    final name = _text(pet['name']);
    final type = adoptPosterTypeLabel(pet['type'] as String?, lang);
    final age = _text(pet['age']);
    final gender = _genderLabel(pet['gender'] as String?, lang);
    final description = _text(pet['description']);
    final location = _text(pet['location']);
    final contact = _text(pet['contact']);
    final facts = [
      type,
      if (age.isNotEmpty) '${AppStrings.get('pd_poster_age', lang)}: $age',
      gender,
    ].where((f) => f.isNotEmpty).toList();
    final health = [
      if (pet['vaccinated'] == true) 'pd_poster_vaccinated',
      if (pet['sterilized'] == true || pet['sterilised'] == true)
        'pd_poster_sterilised',
      if (pet['dewormed'] == true) 'pd_poster_dewormed',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.maxWidth / 400;

        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand header: teal band with a gold underline.
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.accent, width: 6 * s),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 16 * s),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pets, size: 40 * s, color: AppTheme.accent),
                      SizedBox(width: 12 * s),
                      Text(
                        AppStrings.get('pd_poster_adopt_me', lang),
                        style: TextStyle(
                          fontSize: 52 * s,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3 * s,
                        ),
                      ),
                      SizedBox(width: 12 * s),
                      Icon(Icons.favorite, size: 36 * s, color: AppTheme.accent),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10 * s),
                          child: imageUrl.isNotEmpty
                              ? AppImage(imageUrl, width: double.infinity, decodeWidth: 1200)
                              : Container(
                                  color: AppTheme.lightGrey,
                                  child: Icon(Icons.pets,
                                      size: 72 * s,
                                      color: AppTheme.primary.withValues(alpha: 0.4)),
                                ),
                        ),
                      ),
                      SizedBox(height: 8 * s),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 30 * s,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      if (facts.isNotEmpty)
                        Text(
                          facts.join('  ·  '),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15 * s,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      if (health.isNotEmpty) ...[
                        SizedBox(height: 6 * s),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final key in health)
                                _healthBadge(AppStrings.get(key, lang), s),
                            ],
                          ),
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        SizedBox(height: 6 * s),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13 * s,
                            height: 1.3,
                            color: AppTheme.textDark.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                      if (location.isNotEmpty) ...[
                        SizedBox(height: 6 * s),
                        Text.rich(
                          TextSpan(
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(Icons.location_on,
                                    size: 15 * s, color: AppTheme.primary),
                              ),
                              TextSpan(text: ' $location'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13 * s,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                      if (contact.isNotEmpty) ...[
                        SizedBox(height: 8 * s),
                        Text(
                          AppStrings.get('pd_poster_call', lang),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14 * s,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        SizedBox(height: 2 * s),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone, size: 30 * s, color: AppTheme.textDark),
                              SizedBox(width: 8 * s),
                              Text(
                                contact,
                                style: TextStyle(
                                  fontSize: 36 * s,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 8 * s),
                padding: EdgeInsets.symmetric(vertical: 6 * s, horizontal: 12 * s),
                color: AppTheme.accent,
                child: Text(
                  AppStrings.get('pd_poster_footer', lang),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11 * s,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _healthBadge(String label, double s) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3 * s),
      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14 * s, color: AppTheme.primary),
          SizedBox(width: 4 * s),
          Text(
            label,
            style: TextStyle(
              fontSize: 12 * s,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
