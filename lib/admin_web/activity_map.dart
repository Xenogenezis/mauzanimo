// Activity map shown under the Overview dashboard (web admin and the in-app
// admin dashboard): sightings and geotagged lost & found posts from the last
// week.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/geo_utils.dart';
import '../widgets/app_image.dart';
import '../widgets/location_picker.dart';

/// "Last 7 days on the map" heading plus the map, sized for the Overview page.
class ActivityMapSection extends StatelessWidget {
  final double height;
  const ActivityMapSection({super.key, this.height = 460});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Last 7 days on the map', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(height: height, child: const ActivityMap()),
      ]);
}

/// Sightings and geotagged lost & found posts from the last week.
class ActivityMap extends StatelessWidget {
  const ActivityMap({super.key});

  @override
  Widget build(BuildContext context) {
    final since = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    final db = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('sightings').where('createdAt', isGreaterThan: since).snapshots(),
      builder: (context, sightings) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('lostfound').where('createdAt', isGreaterThan: since).snapshots(),
        builder: (context, lost) {
          final markers = <Marker>[
            for (final d in sightings.data?.docs ?? const [])
              if (d.data()['geo'] is GeoPoint)
                _marker(context, d.data(), d.data()['geo'] as GeoPoint, Colors.teal, 'Sighting'),
            for (final d in lost.data?.docs ?? const [])
              if (d.data()['geo'] is GeoPoint)
                _marker(context, d.data(), d.data()['geo'] as GeoPoint,
                    d.data()['type'] == 'Found' ? Colors.green : Colors.red, d.data()['type'] as String? ?? 'Lost'),
          ];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(children: [
              FlutterMap(
                options: const MapOptions(initialCenter: LatLng(mauritiusLat, mauritiusLng), initialZoom: 10),
                children: [osmTileLayer(), MarkerLayer(markers: markers)],
              ),
              osmAttribution(),
              Positioned(
                left: 8,
                top: 8,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      _Legend(Colors.teal, 'Sighting'),
                      _Legend(Colors.red, 'Lost'),
                      _Legend(Colors.green, 'Found'),
                    ]),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Marker _marker(BuildContext context, Map<String, dynamic> d, GeoPoint g, Color color, String kind) => Marker(
        point: LatLng(g.latitude, g.longitude),
        width: 36,
        height: 36,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => showActivityRecord(context, kind, d, g),
          child: Icon(Icons.location_pin, color: color, size: 36),
        ),
      );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.location_pin, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]);
}

/// Dialog with the photo, date, description and location of a map record.
void showActivityRecord(BuildContext context, String kind, Map<String, dynamic> d, GeoPoint g) {
  final created = d['createdAt'];
  showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('$kind · ${d['animalType'] ?? ''}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppImage(d['imageUrl'] as String?, height: 240, width: double.infinity, decodeWidth: 420),
            ),
            const SizedBox(height: 8),
            if (created is Timestamp) Text(DateFormat('EEE d MMM yyyy, HH:mm').format(created.toDate())),
            Text(d['description'] as String? ?? ''),
            const SizedBox(height: 4),
            SelectableText(
              '${d['locationLabel'] ?? d['location'] ?? ''}  ${formatLatLng(g.latitude, g.longitude)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${g.latitude},${g.longitude}')),
          child: const Text('Open in Google Maps'),
        ),
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
      ],
    ),
  );
}
