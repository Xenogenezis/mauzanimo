import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../utils/geo_utils.dart';

/// OpenStreetMap tiles. OSM's tile policy requires an identifying user agent.
TileLayer osmTileLayer() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.jcigrandbaie.mauzanimo',
      maxZoom: 19,
    );

/// Required OSM attribution overlay.
Widget osmAttribution() => const Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xCCFFFFFF)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10)),
          ),
        ),
      ),
    );

/// A map with a single pin. Tap anywhere to move it.
class LocationPicker extends StatefulWidget {
  final LatLng? initial;
  final double? accuracyMeters;
  final ValueChanged<LatLng> onChanged;
  final double height;

  const LocationPicker({
    super.key,
    required this.initial,
    required this.onChanged,
    this.accuracyMeters,
    this.height = 220,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _controller = MapController();
  LatLng? _pin;

  @override
  void initState() {
    super.initState();
    _pin = widget.initial;
  }

  @override
  void didUpdateWidget(LocationPicker old) {
    super.didUpdateWidget(old);
    // A fresh GPS fix arrived: recentre on it.
    if (widget.initial != null && widget.initial != old.initial) {
      _pin = widget.initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.move(widget.initial!, 17);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final centre = _pin ?? const LatLng(mauritiusLat, mauritiusLng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: centre,
                initialZoom: _pin == null ? 9.5 : 17,
                onTap: (_, point) {
                  setState(() => _pin = point);
                  widget.onChanged(point);
                },
              ),
              children: [
                osmTileLayer(),
                if (_pin != null && (widget.accuracyMeters ?? 0) > 0)
                  CircleLayer(circles: [
                    CircleMarker(
                      point: _pin!,
                      radius: widget.accuracyMeters!,
                      useRadiusInMeter: true,
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderColor: Colors.blue.withValues(alpha: 0.4),
                      borderStrokeWidth: 1,
                    ),
                  ]),
                if (_pin != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _pin!,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 44),
                    ),
                  ]),
              ],
            ),
            osmAttribution(),
          ],
        ),
      ),
    );
  }
}
