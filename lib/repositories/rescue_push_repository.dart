import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/rescue_alerts.dart';

/// Languages the notifyNearbyRescuers Cloud Function can write in.
const List<String> rescuePushLanguages = ['en', 'fr', 'mfe'];

/// The `rescue_subscribers/{uid}` document. Field names and limits mirror
/// firestore.rules (rescueSubscriberOk) and functions/index.js.
Map<String, Object?> buildRescueSubscriber({
  required RescueAlertPrefs prefs,
  required List<String> tokens,
  required String lang,
  Object? updatedAt,
}) =>
    {
      'enabled': true,
      'geo': GeoPoint(prefs.latitude!, prefs.longitude!),
      'radiusKm': prefs.radiusKm,
      'urgentOnly': prefs.urgentOnly,
      'tokens': tokens,
      'lang': rescuePushLanguages.contains(lang) ? lang : 'en',
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };

/// Rescue phone notifications through Firebase Cloud Messaging.
///
/// Android app only for now: web push needs a VAPID key and a service
/// worker, and iOS is not configured for this project.
class FcmRescuePushGateway implements RescuePushGateway {
  final FirebaseFirestore? _firestoreOverride;
  FcmRescuePushGateway({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('rescue_subscribers').doc(uid);

  @override
  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> subscribe(String uid, RescueAlertPrefs prefs) async {
    if (!supported || !prefs.wantsPush) return false;
    final messaging = FirebaseMessaging.instance;
    // Android 13+ shows the system permission dialog here.
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return false;
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return false;

    // Keep the rescuer's other devices registered.
    var existing = const <Object?>[];
    try {
      final snap = await _doc(uid).get();
      final t = snap.data()?['tokens'];
      if (t is List) existing = t;
    } catch (_) {
      // First time, or offline: start from this device only.
    }

    final sp = await SharedPreferences.getInstance();
    await _doc(uid).set(buildRescueSubscriber(
      prefs: prefs,
      tokens: mergePushTokens(existing, token),
      lang: sp.getString('language') ?? 'en',
    ));
    return true;
  }

  @override
  Future<void> unsubscribe(String uid) => _doc(uid).delete();

  @override
  Future<void> forgetDevice() async {
    if (!supported) return;
    // The old token stops working; the Cloud Function drops it from the
    // signed-out account the next time a send to it fails.
    await FirebaseMessaging.instance.deleteToken();
  }
}
