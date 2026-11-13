import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stray_pets_mu/lang/strings_rescue.dart';
import 'package:stray_pets_mu/models/rescue_report.dart';
import 'package:stray_pets_mu/models/user_role.dart';
import 'package:stray_pets_mu/providers/rescue_alerts_provider.dart';
import 'package:stray_pets_mu/utils/rescue_alerts.dart';
import 'package:stray_pets_mu/widgets/nearby_rescue_banner.dart';

// Port Louis, and points roughly 3 km, 14 km and 40 km away.
const _plLat = -20.1609, _plLng = 57.5012;
const _near = (-20.1850, 57.5150); // ~3 km
const _mid = (-20.2650, 57.4800); // ~12 km (Quatre Bornes)
const _far = (-20.4080, 57.7000); // ~35 km (Mahebourg)

RescueReport _report(
  String id, {
  (double, double)? at,
  String status = 'pending',
  String urgency = 'high',
}) =>
    RescueReport(
      id: id,
      description: 'd',
      location: 'l',
      animalType: 'dog',
      urgency: urgency,
      status: status,
      reporterId: 'u',
      reporterName: 'n',
      reporterPhone: 'p',
      createdAt: DateTime(2026, 1, 1),
      latitude: at?.$1,
      longitude: at?.$2,
    );

const _prefs = RescueAlertPrefs(enabled: true, latitude: _plLat, longitude: _plLng, radiusKm: 20);

void main() {
  group('RescueAlertPrefs', () {
    test('round-trips through encode/decode', () {
      const p = RescueAlertPrefs(enabled: true, latitude: -20.1, longitude: 57.5, radiusKm: 20, urgentOnly: true);
      final back = RescueAlertPrefs.decode(p.encode());
      expect(back.enabled, isTrue);
      expect(back.latitude, -20.1);
      expect(back.longitude, 57.5);
      expect(back.radiusKm, 20);
      expect(back.urgentOnly, isTrue);
      expect(back.isActive, isTrue);
    });

    test('missing or corrupt data gives alerts off', () {
      for (final raw in [null, '', 'not json', '[]', '{"radiusKm": 7}']) {
        final p = RescueAlertPrefs.decode(raw);
        expect(p.enabled, isFalse, reason: '$raw');
        expect(p.radiusKm, 10, reason: '$raw');
        expect(p.isActive, isFalse, reason: '$raw');
      }
    });

    test('enabled without an area is not active', () {
      expect(const RescueAlertPrefs(enabled: true).isActive, isFalse);
    });
  });

  group('nearbyRescues', () {
    test('keeps pending reports with a pin inside the radius', () {
      final found = nearbyRescues([
        _report('near', at: _near),
        _report('mid', at: _mid),
        _report('far', at: _far),
        _report('no-pin'),
        _report('assigned', at: _near, status: 'assigned'),
        _report('resolved', at: _near, status: 'resolved'),
      ], _prefs);
      expect(found.map((n) => n.report.id), ['near', 'mid']);
      expect(found.first.distanceKm, inInclusiveRange(2, 4));
    });

    test('radius is respected', () {
      final small = _prefs.copyWith(radiusKm: 5);
      expect(nearbyRescues([_report('near', at: _near), _report('mid', at: _mid)], small).map((n) => n.report.id),
          ['near']);
      final island = _prefs.copyWith(radiusKm: 50);
      expect(nearbyRescues([_report('far', at: _far)], island), hasLength(1));
    });

    test('sorts most urgent first, then nearest', () {
      final found = nearbyRescues([
        _report('medium-near', at: _near, urgency: 'medium'),
        _report('high-mid', at: _mid, urgency: 'high'),
        _report('critical-mid', at: _mid, urgency: 'critical'),
        _report('high-near', at: _near, urgency: 'high'),
      ], _prefs);
      expect(found.map((n) => n.report.id), ['critical-mid', 'high-near', 'high-mid', 'medium-near']);
    });

    test('urgentOnly drops medium urgency', () {
      final found = nearbyRescues([
        _report('medium', at: _near, urgency: 'medium'),
        _report('high', at: _near, urgency: 'high'),
      ], _prefs.copyWith(urgentOnly: true));
      expect(found.map((n) => n.report.id), ['high']);
    });

    test('nothing when alerts are off or no area is set', () {
      final reports = [_report('near', at: _near)];
      expect(nearbyRescues(reports, _prefs.copyWith(enabled: false)), isEmpty);
      expect(nearbyRescues(reports, const RescueAlertPrefs(enabled: true)), isEmpty);
    });
  });

  group('RescueReport geo', () {
    test('reads and writes the map pin as a GeoPoint', () {
      final r = _report('a', at: _near);
      final map = r.toMap();
      expect(map['geo'], isA<GeoPoint>());
      final back = RescueReport.fromMap('a', {...map, 'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1))});
      expect(back.hasGeo, isTrue);
      expect(back.latitude, _near.$1);
      expect(back.longitude, _near.$2);
    });

    test('a report without a pin has no geo field, and old documents still load', () {
      expect(_report('a').toMap().containsKey('geo'), isFalse);
      // createdAt is null in the local snapshot until the server sets it.
      final back = RescueReport.fromMap('a', {'description': 'x', 'createdAt': null});
      expect(back.hasGeo, isFalse);
      expect(back.status, 'pending');
    });
  });

  group('RescueAlertsProvider', () {
    late StreamController<List<RescueReport>> reports;
    late int opened;

    RescueAlertsProvider build() => RescueAlertsProvider(() {
          opened++;
          return reports.stream;
        });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      reports = StreamController<List<RescueReport>>.broadcast();
      opened = 0;
    });

    tearDown(() => reports.close());

    test('does nothing for accounts that cannot rescue', () async {
      final p = build()..setUser('u1', canRescue: false);
      await pumpEventQueue();
      expect(p.canRescue, isFalse);
      expect(opened, 0);
      expect(p.nearby, isEmpty);
    });

    test('does not watch reports until alerts are switched on', () async {
      final p = build()..setUser('u1', canRescue: true);
      await pumpEventQueue();
      expect(opened, 0);

      await p.savePrefs(_prefs);
      expect(opened, 1);
      reports.add([_report('near', at: _near), _report('far', at: _far)]);
      await pumpEventQueue();
      expect(p.nearby.map((n) => n.report.id), ['near']);
      expect(p.unseenCount, 1);
    });

    test('markSeen clears the count, and it stays cleared after a restart', () async {
      final p = build()..setUser('u1', canRescue: true);
      await pumpEventQueue();
      await p.savePrefs(_prefs);
      reports.add([_report('near', at: _near)]);
      await pumpEventQueue();
      await p.markSeen();
      expect(p.unseenCount, 0);
      expect(p.nearby, hasLength(1));

      // A new report in the area counts again.
      reports.add([_report('near', at: _near), _report('mid', at: _mid)]);
      await pumpEventQueue();
      expect(p.unseenCount, 1);

      // Same account on a fresh provider: settings and seen ids are restored.
      final again = build()..setUser('u1', canRescue: true);
      await pumpEventQueue();
      expect(again.prefs.isActive, isTrue);
      reports.add([_report('near', at: _near)]);
      await pumpEventQueue();
      expect(again.unseenCount, 0);
    });

    test('settings are per account and cleared from memory on sign-out', () async {
      final p = build()..setUser('u1', canRescue: true);
      await pumpEventQueue();
      await p.savePrefs(_prefs);

      p.setUser('u2', canRescue: true);
      await pumpEventQueue();
      expect(p.prefs.enabled, isFalse);

      p.setUser(null, canRescue: false);
      await pumpEventQueue();
      expect(p.prefs.enabled, isFalse);
      expect(p.nearby, isEmpty);
    });

    test('switching alerts off stops showing nearby reports', () async {
      final p = build()..setUser('u1', canRescue: true);
      await pumpEventQueue();
      await p.savePrefs(_prefs);
      reports.add([_report('near', at: _near)]);
      await pumpEventQueue();
      expect(p.nearby, hasLength(1));

      await p.savePrefs(_prefs.copyWith(enabled: false));
      expect(p.nearby, isEmpty);
      expect(p.unseenCount, 0);
    });
  });

  test('banner text uses the singular for one request', () {
    expect(nearbyRescueBannerText(1, 'en'), '1 rescue request near you');
    expect(nearbyRescueBannerText(3, 'en'), '3 rescue requests near you');
    expect(nearbyRescueBannerText(3, 'fr'), '3 demandes de sauvetage près de vous');
  });

  test('the volunteer role is shown as Volunteer/Rescuer and may take rescues', () {
    expect(UserRole.volunteer.displayName, 'Volunteer/Rescuer');
    expect(UserRole.volunteer.canAccess(UserRole.volunteer), isTrue);
    expect(UserRole.partner.canAccess(UserRole.volunteer), isTrue);
    expect(UserRole.admin.canAccess(UserRole.volunteer), isTrue);
    expect(UserRole.adopter.canAccess(UserRole.volunteer), isFalse);
    expect(UserRole.rehomer.canAccess(UserRole.volunteer), isFalse);
  });

  test('rescue strings have the same non-empty keys in en, fr and mfe', () {
    final en = rescueStrings['en']!;
    for (final lang in ['fr', 'mfe']) {
      expect(rescueStrings[lang]!.keys.toSet(), en.keys.toSet(), reason: lang);
      for (final e in rescueStrings[lang]!.entries) {
        expect(e.value, isNotEmpty, reason: '$lang ${e.key}');
      }
    }
  });
}
