import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../lang/app_strings.dart';
import '../../models/sighting.dart';
import '../../providers/language_provider.dart';
import '../../repositories/sighting_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/geo_utils.dart';
import '../../utils/location_service.dart';
import '../../widgets/app_image.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/login_required_view.dart';
import '../../widgets/report_button.dart';
import 'report_sighting_screen.dart';

/// Map + list of recent sightings, with "near me" filtering.
///
/// When [lostReportId] is given, only sightings attached to that lost-animal
/// report are shown (the owner's view).
class SightingsScreen extends StatefulWidget {
  final String? lostReportId;
  final String? title;
  const SightingsScreen({super.key, this.lostReportId, this.title});

  @override
  State<SightingsScreen> createState() => _SightingsScreenState();
}

class _SightingsScreenState extends State<SightingsScreen> {
  final _repo = SightingRepository();
  final _mapController = MapController();
  bool _showMap = true;
  LatLng? _me;
  double? _radiusKm; // null = everywhere
  late final Stream<List<Sighting>> _stream = widget.lostReportId != null
      ? _repo.watchForLostReport(widget.lostReportId!)
      : _repo.watchOpen();

  Future<void> _nearMe(double km) async {
    try {
      final fix = await const LocationService().currentFix();
      if (!mounted) return;
      setState(() {
        _me = LatLng(fix.latitude, fix.longitude);
        _radiusKm = km;
      });
      // The controller only works while the map is on screen.
      if (_showMap) {
        try {
          _mapController.move(_me!, km <= 2 ? 14 : 12);
        } catch (_) {}
      }
    } on LocationException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('gps_unknown_error', context.read<LanguageProvider>().lang))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);

    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('sightings'))),
        body: const LoginRequiredView(icon: Icons.location_searching),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? t('sightings')),
        actions: [
          IconButton(
            tooltip: _showMap ? t('list_view') : t('map_view'),
            icon: Icon(_showMap ? Icons.view_list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      floatingActionButton: widget.lostReportId != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportSightingScreen()),
              ),
              icon: const Icon(Icons.add_a_photo),
              label: Text(t('report_sighting')),
            ),
      body: StreamBuilder<List<Sighting>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(t('something_went_wrong')));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Moderated sightings stay out of both the map and the list.
          var items = snap.data!.where((s) => !s.hidden).toList();
          if (_me != null && _radiusKm != null) {
            items = SightingRepository.within(items, _me!.latitude, _me!.longitude, _radiusKm!);
          }

          return Column(
            children: [
              if (widget.lostReportId == null)
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      ChoiceChip(
                        label: Text(t('everywhere')),
                        selected: _radiusKm == null,
                        onSelected: (_) => setState(() => _radiusKm = null),
                      ),
                      for (final km in const [1.0, 5.0, 15.0]) ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.near_me, size: 16),
                          label: Text('${km.toStringAsFixed(0)} km'),
                          selected: _radiusKm == km,
                          onSelected: (_) => _nearMe(km),
                        ),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(t('no_sightings'), textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey)),
                        ),
                      )
                    : _showMap
                        ? _map(items)
                        : _list(items, t),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _map(List<Sighting> items) {
    final first = items.first;
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _me ??
                (widget.lostReportId != null
                    ? LatLng(first.latitude, first.longitude)
                    : const LatLng(mauritiusLat, mauritiusLng)),
            initialZoom: widget.lostReportId != null ? 13 : 10,
          ),
          children: [
            osmTileLayer(),
            if (_me != null && _radiusKm != null)
              CircleLayer(circles: [
                CircleMarker(
                  point: _me!,
                  radius: _radiusKm! * 1000,
                  useRadiusInMeter: true,
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderColor: AppTheme.primary,
                  borderStrokeWidth: 1,
                ),
              ]),
            MarkerLayer(markers: [
              if (_me != null)
                Marker(
                  point: _me!,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              for (final s in items)
                Marker(
                  point: LatLng(s.latitude, s.longitude),
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => _showDetail(s),
                    child: Icon(
                      Icons.location_pin,
                      size: 40,
                      color: s.isLinkedToLostReport ? Colors.orange : AppTheme.primary,
                    ),
                  ),
                ),
            ]),
          ],
        ),
        osmAttribution(),
      ],
    );
  }

  Widget _list(List<Sighting> items, String Function(String) t) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = items[i];
        final dist = _me == null ? null : haversineKm(_me!.latitude, _me!.longitude, s.latitude, s.longitude);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () => _showDetail(s),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppImage(s.imageUrl, width: 56, height: 56),
            ),
            title: Text('${s.animalType}${s.locationLabel != null ? ' · ${s.locationLabel}' : ''}'),
            subtitle: Text(
              [
                if (s.createdAt != null) DateFormat('d MMM, HH:mm').format(s.createdAt!),
                if (dist != null) formatDistance(dist),
                if (s.isLinkedToLostReport) t('matches_lost_report'),
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s.reporterId != FirebaseAuth.instance.currentUser?.uid)
                  ReportButton(
                    targetCollection: 'sightings',
                    targetId: s.id,
                    iconSize: 20,
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetail(Sighting s) {
    final lang = context.read<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppImage(s.imageUrl, height: 240, width: double.infinity),
              ),
              const SizedBox(height: 12),
              Text(s.animalType, style: Theme.of(ctx).textTheme.titleLarge),
              if (s.createdAt != null)
                Text(DateFormat('EEEE d MMM yyyy, HH:mm').format(s.createdAt!),
                    style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              if (s.description.isNotEmpty) Text(s.description),
              const SizedBox(height: 8),
              Text(
                '${s.locationLabel ?? ''}  ${formatLatLng(s.latitude, s.longitude)}'
                '${s.accuracyMeters != null ? '  (±${s.accuracyMeters!.round()} m)' : ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: Text(t('directions')),
                      onPressed: () => launchUrl(
                        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${s.latitude},${s.longitude}'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),
                  if (s.reporterId == uid) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(t('mark_resolved')),
                        onPressed: () async {
                          await _repo.setStatus(s.id, 'resolved');
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
