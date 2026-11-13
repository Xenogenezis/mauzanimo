import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/providers/rescue_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/widgets/login_required_view.dart';
import 'package:stray_pets_mu/providers/rescue_alerts_provider.dart';
import 'package:stray_pets_mu/screens/rescue/rescue_alert_settings_screen.dart';
import 'package:stray_pets_mu/utils/geo_utils.dart';
import 'package:stray_pets_mu/utils/rescue_alerts.dart';

class RescueListScreen extends StatefulWidget {
  const RescueListScreen({super.key});

  @override
  State<RescueListScreen> createState() => _RescueListScreenState();
}

class _RescueListScreenState extends State<RescueListScreen> {
  Stream<QuerySnapshot>? _stream;
  // Show only open requests inside the rescuer's alert area.
  bool _nearOnly = false;

  @override
  void initState() {
    super.initState();
    // Opening the list counts as having seen the nearby requests.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RescueAlertsProvider?>()?.markSeen();
    });
    if (FirebaseAuth.instance.currentUser != null) {
      _stream = FirebaseFirestore.instance
          .collection('rescue_reports')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final user = FirebaseAuth.instance.currentUser;

    String _(String key) => AppStrings.get(key, lang);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_('emergency_rescue')),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
        ),
        body: const LoginRequiredView(icon: Icons.volunteer_activism),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_('emergency_rescue')),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (context.watch<RescueAlertsProvider?>()?.canRescue ?? false)
            IconButton(
              key: const ValueKey('ra-open-settings'),
              tooltip: _('ra_settings_title'),
              icon: Icon((context.watch<RescueAlertsProvider?>()?.prefs.isActive ?? false)
                  ? Icons.notifications_active
                  : Icons.notifications_none),
              onPressed: _openAlertSettings,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            if (isPermissionDenied(snapshot.error)) {
              return const LoginRequiredView(icon: Icons.volunteer_activism);
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allReports = snapshot.data!.docs;
          final alerts = context.watch<RescueAlertsProvider?>();
          final prefs = alerts?.prefs ?? const RescueAlertPrefs();
          final nearIds = {for (final n in alerts?.nearby ?? const <NearbyRescue>[]) n.report.id};
          final showNear = _nearOnly && prefs.isActive;
          final reports = showNear ? allReports.where((d) => nearIds.contains(d.id)).toList() : allReports;
          Widget withHeader(Widget child) => Column(children: [
                _alertsHeader(alerts, _, nearIds.length),
                Expanded(child: child),
              ]);

          if (reports.isEmpty) {
            return withHeader(Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(_(showNear ? 'ra_none_near' : 'no_reports_yet'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  ),
                ],
              ),
            ));
          }

          return withHeader(ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final data = reports[index].data() as Map<String, dynamic>;
              final urgency = data['urgency'] as String? ?? 'medium';
              final status = data['status'] as String? ?? 'pending';
              final geo = data['geo'];
              final distanceKm = geo is GeoPoint && prefs.hasArea
                  ? haversineKm(prefs.latitude!, prefs.longitude!, geo.latitude, geo.longitude)
                  : null;
              final urgencyColor = urgency == 'critical'
                  ? Colors.red : urgency == 'high' ? Colors.orange : Colors.amber.shade700;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: urgencyColor.withValues(alpha: 0.5),
                    width: urgency == 'critical' ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: urgencyColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _('urgency_$urgency'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: urgencyColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _('rescue_report_$status'),
                            style: TextStyle(fontSize: 11, color: _statusColor(status)),
                          ),
                        ),
                        const Spacer(),
                        Text(data['animalType'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                      const SizedBox(height: 8),
                      Text(data['description'] ?? '',
                          style: const TextStyle(fontSize: 14, color: AppTheme.textDark)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(data['location'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey))),
                        if (distanceKm != null)
                          Text(_('ra_distance_away').replaceAll('{d}', formatDistance(distanceKm)),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                      ]),
                      const SizedBox(height: 4),
                      Text('${_('reported_by')} ${data['reporterName'] ?? ''} - ${data['reporterPhone'] ?? ''}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      if (status == 'pending') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final provider = context.read<RescueProvider>();
                              final success = await provider.assignVolunteer(
                                reports[index].id,
                                user.uid,
                                user.displayName ?? user.email ?? 'Volunteer',
                              );
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_('assigned_to_you'))),
                                );
                              }
                            },
                            icon: const Icon(Icons.volunteer_activism, size: 18),
                            label: Text(_('assign_to_me')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      if (status == 'assigned' &&
                          data['assignedVolunteerId'] == user.uid) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('rescue_reports')
                                  .doc(reports[index].id)
                                  .update({'status': 'resolved', 'resolvedAt': FieldValue.serverTimestamp()});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_('marked_resolved'))),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: Text(_('mark_resolved')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ));
        },
      ),
    );
  }

  void _openAlertSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RescueAlertSettingsScreen()));
  }

  /// For volunteers/rescuers: a prompt to turn alerts on, or the
  /// All / Near me filter once they have.
  Widget _alertsHeader(RescueAlertsProvider? alerts, String Function(String) t, int nearCount) {
    if (alerts == null || !alerts.canRescue) return const SizedBox.shrink();
    if (!alerts.prefs.isActive) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Material(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.primary),
            title: Text(t('ra_setup_prompt'), style: const TextStyle(fontSize: 14)),
            trailing: TextButton(
              key: const ValueKey('ra-setup'),
              onPressed: _openAlertSettings,
              child: Text(t('ra_setup')),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        ChoiceChip(
          label: Text(t('ra_filter_all')),
          selected: !_nearOnly,
          onSelected: (_) => setState(() => _nearOnly = false),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          key: const ValueKey('ra-filter-near'),
          label: Text(t('ra_filter_near').replaceAll('{n}', '$nearCount')),
          selected: _nearOnly,
          onSelected: (_) => setState(() => _nearOnly = true),
        ),
      ]),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pending' => Colors.orange,
      'assigned' => Colors.blue,
      'in_progress' => Colors.purple,
      'resolved' => Colors.green,
      _ => Colors.grey,
    };
  }
}
