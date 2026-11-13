import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/providers/rescue_alerts_provider.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/utils/location_service.dart';
import 'package:stray_pets_mu/utils/rescue_alerts.dart';
import 'package:stray_pets_mu/widgets/location_picker.dart';

/// Lets a volunteer/rescuer opt in to "rescues near you" and choose the area
/// they can cover. Everything here is saved on the device only.
class RescueAlertSettingsScreen extends StatefulWidget {
  const RescueAlertSettingsScreen({super.key});

  @override
  State<RescueAlertSettingsScreen> createState() => _RescueAlertSettingsScreenState();
}

class _RescueAlertSettingsScreenState extends State<RescueAlertSettingsScreen> {
  late bool _enabled;
  late int _radiusKm;
  late bool _urgentOnly;
  LatLng? _pin;
  // Moves the map; only changes on a GPS fix so taps don't recentre it.
  LatLng? _mapCentre;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<RescueAlertsProvider>().prefs;
    _enabled = prefs.enabled;
    _radiusKm = prefs.radiusKm;
    _urgentOnly = prefs.urgentOnly;
    if (prefs.hasArea) _pin = _mapCentre = LatLng(prefs.latitude!, prefs.longitude!);
  }

  String _t(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  void _snack(String key) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(key))));
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      final fix = await const LocationService().currentFix();
      if (mounted) setState(() => _pin = _mapCentre = LatLng(fix.latitude, fix.longitude));
    } on LocationException {
      _snack('ui_lf_gps_failed');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_enabled && _pin == null) {
      _snack('ra_need_area');
      return;
    }
    await context.read<RescueAlertsProvider>().savePrefs(RescueAlertPrefs(
          enabled: _enabled,
          latitude: _pin?.latitude,
          longitude: _pin?.longitude,
          radiusKm: _radiusKm,
          urgentOnly: _urgentOnly,
        ));
    if (!mounted) return;
    _snack('ra_saved');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String key) => AppStrings.get(key, lang);
    final heading = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textStrong);

    return Scaffold(
      appBar: AppBar(title: Text(t('ra_settings_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              key: const ValueKey('ra-enable'),
              contentPadding: EdgeInsets.zero,
              title: Text(t('ra_enable'), style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(t('ra_enable_desc')),
              value: _enabled,
              activeThumbColor: AppTheme.primary,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(t('ra_area'), style: heading)),
              TextButton.icon(
                onPressed: _locating ? null : _useGps,
                icon: _locating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, size: 18),
                label: Text(t('ui_lf_use_gps')),
              ),
            ]),
            const SizedBox(height: 4),
            LocationPicker(initial: _mapCentre, height: 220, onChanged: (p) => setState(() => _pin = p)),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(t('ra_area_hint'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            Text(t('ra_radius'), style: heading),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final km in rescueAlertRadii)
                  ChoiceChip(
                    key: ValueKey('ra-radius-$km'),
                    label: Text(t('ra_radius_km').replaceAll('{km}', '$km')),
                    selected: _radiusKm == km,
                    onSelected: (_) => setState(() => _radiusKm = km),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              key: const ValueKey('ra-urgent-only'),
              contentPadding: EdgeInsets.zero,
              title: Text(t('ra_urgent_only')),
              value: _urgentOnly,
              activeThumbColor: AppTheme.primary,
              onChanged: (v) => setState(() => _urgentOnly = v),
            ),
            const SizedBox(height: 12),
            _Note(icon: Icons.lock_outline, text: t('ra_privacy')),
            const SizedBox(height: 8),
            _Note(icon: Icons.info_outline, text: t('ra_no_push')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('ra-save'),
                onPressed: _save,
                child: Text(t('ra_save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Note({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ],
      );
}
