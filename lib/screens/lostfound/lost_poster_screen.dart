import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../lang/app_strings.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/poster_export.dart';
import '../../widgets/app_image.dart';

/// Printable / shareable A4-style poster for a Lost & Found report.
class LostPosterScreen extends StatefulWidget {
  /// The report document data (type, animalType, description, location,
  /// contact, imageUrl, createdAt, optional geo).
  final Map<String, dynamic> data;

  const LostPosterScreen({super.key, required this.data});

  @override
  State<LostPosterScreen> createState() => _LostPosterScreenState();
}

class _LostPosterScreenState extends State<LostPosterScreen> {
  static const _fileName = 'mauzanimo-poster.png';
  final _posterKey = GlobalKey();
  bool _busy = false;

  bool get _isLost => (widget.data['type'] ?? 'Lost') != 'Found';

  String _shareText(String lang) {
    final d = widget.data;
    final header =
        AppStrings.get(_isLost ? 'lf_poster_lost' : 'lf_poster_found', lang);
    final place = AppStrings.get(
        _isLost ? 'lf_poster_last_seen' : 'lf_poster_found_at', lang);
    return '$header: ${d['animalType'] ?? ''}\n'
        '$place: ${d['location'] ?? ''}\n'
        '${AppStrings.get(_isLost ? 'lf_poster_call_lost' : 'lf_poster_call_found', lang)}: '
        '${d['contact'] ?? ''}\n\n'
        '${AppStrings.get('lf_poster_footer', lang)}';
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
          SnackBar(content: Text(AppStrings.get('lf_poster_downloaded', lang))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get('lf_poster_error', lang))),
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
      appBar: AppBar(title: Text(AppStrings.get('lf_poster_title', lang))),
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
                    child: _Poster(data: widget.data, isLost: _isLost, lang: lang),
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
                        kIsWeb ? 'lf_download_poster' : 'lf_share_poster', lang)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get('lf_poster_hint', lang),
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
class _Poster extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLost;
  final String lang;

  const _Poster({required this.data, required this.isLost, required this.lang});

  @override
  Widget build(BuildContext context) {
    final accent = isLost ? Colors.red.shade700 : Colors.green.shade700;
    final imageUrl = data['imageUrl'] as String? ?? '';
    final created = data['createdAt'];
    final date = created is Timestamp
        ? DateFormat('dd/MM/yyyy').format(created.toDate())
        : null;
    final location = (data['location'] as String? ?? '').trim();
    final description = (data['description'] as String? ?? '').trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.maxWidth / 400;

        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: accent,
                padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 16 * s),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppStrings.get(isLost ? 'lf_poster_lost' : 'lf_poster_found', lang),
                    style: TextStyle(
                      fontSize: 56 * s,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4 * s,
                    ),
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
                          borderRadius: BorderRadius.circular(8 * s),
                          child: imageUrl.isNotEmpty
                              ? AppImage(imageUrl, width: double.infinity, decodeWidth: 1200)
                              : Container(
                                  color: AppTheme.lightGrey,
                                  child: Icon(Icons.pets,
                                      size: 72 * s,
                                      color: accent.withValues(alpha: 0.4)),
                                ),
                        ),
                      ),
                      SizedBox(height: 10 * s),
                      Text(
                        data['animalType'] as String? ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22 * s,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        SizedBox(height: 4 * s),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13 * s,
                            height: 1.3,
                            color: AppTheme.textDark.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                      SizedBox(height: 8 * s),
                      if (location.isNotEmpty)
                        _infoLine(
                          '${AppStrings.get(isLost ? 'lf_poster_last_seen' : 'lf_poster_found_at', lang)}: ',
                          location,
                          s,
                        ),
                      if (date != null)
                        _infoLine('${AppStrings.get('lf_poster_date', lang)}: ', date, s),
                      SizedBox(height: 10 * s),
                      Text(
                        AppStrings.get(isLost ? 'lf_poster_call_lost' : 'lf_poster_call_found', lang),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w600,
                          color: accent,
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
                              data['contact'] as String? ?? '',
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
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 8 * s),
                padding: EdgeInsets.symmetric(vertical: 6 * s, horizontal: 12 * s),
                color: AppTheme.primary,
                child: Text(
                  AppStrings.get('lf_poster_footer', lang),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11 * s, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoLine(String label, String value, double s) {
    return Padding(
      padding: EdgeInsets.only(top: 2 * s),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13 * s, color: AppTheme.textDark),
      ),
    );
  }
}
