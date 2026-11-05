import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../lang/app_strings.dart';
import '../../providers/language_provider.dart';
import '../../widgets/login_required_view.dart';
import 'add_lost_found_screen.dart';
import 'edit_lost_found_screen.dart';
import '../sightings/report_sighting_screen.dart';
import '../sightings/sightings_screen.dart';
import '../../widgets/app_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/distance_sort.dart';
import '../../utils/geo_utils.dart';
import '../../utils/location_service.dart';
import '../../utils/moderation.dart';
import '../../widgets/report_button.dart';
import 'lost_poster_screen.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Lost', 'Found'];
  static const _filterLabelKeys = {
    'All': 'all',
    'Lost': 'lf_filter_lost',
    'Found': 'lf_filter_found',
  };

  final _location = const LocationService();
  LocationFix? _myFix;
  bool _sortByDistance = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _locateSilently();
  }

  /// Shows distances straight away when location is already allowed,
  /// without ever triggering a permission dialog.
  Future<void> _locateSilently() async {
    try {
      if (!await _location.hasPermission()) return;
      final fix = await _location.currentFix();
      if (mounted) setState(() => _myFix = fix);
    } catch (_) {
      // Distances are optional; stay quiet.
    }
  }

  Future<void> _toggleNearMe(String lang) async {
    if (_sortByDistance) {
      setState(() => _sortByDistance = false);
      return;
    }
    setState(() => _locating = true);
    try {
      final fix = await _location.currentFix();
      if (!mounted) return;
      setState(() {
        _myFix = fix;
        _sortByDistance = true;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get(
            e.reason == LocationFailure.deniedForever
                ? 'gps_denied_forever'
                : 'gps_unknown_error',
            lang,
          )),
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  double? _distanceKm(Map<String, dynamic> data) {
    final fix = _myFix;
    if (fix == null) return null;
    return distanceKmToGeo(data['geo'], fix.latitude, fix.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.get('lost_found', lang))),
        body: const LoginRequiredView(icon: Icons.search),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('lost_found', lang)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddLostFoundScreen()),
        ),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          AppStrings.get('post_lost_found', lang),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.get('report_a_lost_or_found_animal_in_your_ar', lang),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length + 1,
              itemBuilder: (context, index) {
                if (index == _filters.length) {
                  return ChoiceChip(
                    avatar: _locating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.orange),
                          )
                        : Icon(
                            Icons.near_me,
                            size: 16,
                            color: _sortByDistance ? Colors.white : AppTheme.textDark,
                          ),
                    showCheckmark: false,
                    label: Text(AppStrings.get('lf_near_me', lang)),
                    selected: _sortByDistance,
                    onSelected: _locating ? null : (_) => _toggleNearMe(lang),
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: _sortByDistance ? Colors.white : AppTheme.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: AppTheme.lightGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }
                final f = _filters[index];
                final isSelected = f == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(AppStrings.get(_filterLabelKeys[f]!, lang)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = f);
                    },
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: AppTheme.lightGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filter == 'All'
                  ? FirebaseFirestore.instance
                      .collection('lostfound')
                      .orderBy('createdAt', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('lostfound')
                      .where('type', isEqualTo: _filter)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.get('ui_lf_error_loading', lang),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                }

                var docs = withoutHidden(snapshot.data?.docs ?? <QueryDocumentSnapshot>[],
                    (d) => d.data() as Map<String, dynamic>?);
                if (_sortByDistance && _myFix != null) {
                  docs = sortByDistance(
                    docs,
                    (d) => _distanceKm(d.data() as Map<String, dynamic>),
                  );
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.get('no_reports_yet', lang),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final reportId = docs[index].id;
                    final isLost = data['type'] == 'Lost';
                    final isOwner = data['userId'] == user.uid;

                    return _ReportCard(
                      reportId: reportId,
                      data: data,
                      isLost: isLost,
                      isOwner: isOwner,
                      distanceKm: _distanceKm(data),
                      onDelete: () => _confirmDelete(context, reportId, lang),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String reportId, String lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('delete_listing', lang)),
        content: Text(
          AppStrings.get('ui_lf_delete_confirm', lang),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppStrings.get('delete', lang)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('lostfound')
            .doc(reportId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.get('listing_deleted_successfully', lang)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

class _ReportCard extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> data;
  final bool isLost;
  final bool isOwner;
  final double? distanceKm;
  final VoidCallback onDelete;

  const _ReportCard({
    required this.reportId,
    required this.data,
    required this.isLost,
    required this.isOwner,
    required this.onDelete,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLost
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppStrings.get(isLost ? 'lf_filter_lost' : 'lf_filter_found', lang),
                    style: TextStyle(
                      fontSize: 11,
                      color: isLost ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['animalType'] ?? 'Animal',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (!isOwner)
                      ReportButton(
                        targetCollection: 'lostfound',
                        targetId: reportId,
                        color: Colors.grey,
                        iconSize: 18,
                      ),
                  ],
                ),
              ],
            ),
            if ((data['imageUrl'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppImage(data['imageUrl'] as String?, height: 160, width: double.infinity),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              data['description'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textDark.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data['location'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                if (data['geo'] is GeoPoint)
                  InkWell(
                    onTap: () {
                      final g = data['geo'] as GeoPoint;
                      launchUrl(
                        Uri.parse('https://www.google.com/maps/search/?api=1&query=${g.latitude},${g.longitude}'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.map_outlined, size: 18, color: AppTheme.primary),
                    ),
                  ),
              ],
            ),
            if (distanceKm != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.near_me_outlined, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.get('lf_distance_away', lang)
                        .replaceAll('{distance}', formatDistance(distanceKm!)),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data['contact'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primary),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LostPosterScreen(data: data),
                    ),
                  ),
                  icon: const Icon(Icons.campaign_outlined, size: 16),
                  label: Text(AppStrings.get('lf_poster', lang)),
                  style: TextButton.styleFrom(
                    foregroundColor: isLost ? Colors.red : Colors.green,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            if (isLost) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!isOwner)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportSightingScreen(
                              lostReportId: reportId,
                              lostReportSummary:
                                  '${data['animalType'] ?? ''} - ${data['description'] ?? ''}',
                              initialAnimalType: data['animalType'] as String?,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.add_a_photo, size: 16),
                        label: Text(AppStrings.get('i_saw_this_animal', lang)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                    ),
                  if (!isOwner) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SightingsScreen(
                            lostReportId: reportId,
                            title: AppStrings.get('view_sightings', lang),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.location_searching, size: 16),
                      label: Text(AppStrings.get('view_sightings', lang)),
                    ),
                  ),
                ],
              ),
            ],
            if (isOwner) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditLostFoundScreen(
                            reportId: reportId,
                            report: data,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(AppStrings.get('edit', lang)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(AppStrings.get('delete', lang)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
