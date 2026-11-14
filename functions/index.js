'use strict';

// Phase 2 of rescue alerts: a phone notification for volunteers/rescuers
// when a rescue request is posted inside the area they chose.
//
// The app writes rescue_subscribers/{uid} (area, radius, device tokens) only
// when a rescuer switches on "phone notifications". That document is
// readable by its owner alone; this function reads it with the Admin SDK.
//
// Deploy: firebase deploy --only functions   (needs the Blaze plan)

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const { matchDistanceKm, buildNotification, isDeadTokenError, MAX_TOKENS } = require('./rescue_push');

admin.initializeApp();

// The Firestore database is in eur3 (Europe multi-region).
const REGION = 'europe-west1';

exports.notifyNearbyRescuers = functions
  .region(REGION)
  .runWith({ memory: '256MB', timeoutSeconds: 60, maxInstances: 5 })
  .firestore.document('rescue_reports/{reportId}')
  .onCreate(async (snap, context) => {
    const db = admin.firestore();
    const data = snap.data() || {};
    const geo = data.geo;
    const report = {
      status: data.status || 'pending',
      urgency: data.urgency || 'medium',
      animalType: data.animalType || '',
      location: data.location || '',
      reporterId: data.reporterId || '',
      lat: geo && typeof geo.latitude === 'number' ? geo.latitude : null,
      lng: geo && typeof geo.longitude === 'number' ? geo.longitude : null,
    };
    // No map pin: nobody can be matched by distance.
    if (report.lat === null || report.lng === null) return null;

    const subsSnap = await db.collection('rescue_subscribers').where('enabled', '==', true).get();
    if (subsSnap.empty) return null;

    // The role decides who may take rescues; never trust the subscriber doc.
    const userRefs = subsSnap.docs.map((d) => db.collection('users').doc(d.id));
    const userSnaps = await db.getAll(...userRefs);
    const roleOf = new Map(userSnaps.map((u) => [u.id, u.exists ? u.get('role') : null]));

    let sent = 0;
    let failed = 0;
    await Promise.all(
      subsSnap.docs.map(async (doc) => {
        const s = doc.data();
        const sub = {
          uid: doc.id,
          enabled: s.enabled,
          lat: s.geo && typeof s.geo.latitude === 'number' ? s.geo.latitude : null,
          lng: s.geo && typeof s.geo.longitude === 'number' ? s.geo.longitude : null,
          radiusKm: s.radiusKm,
          urgentOnly: s.urgentOnly,
          tokens: Array.isArray(s.tokens) ? s.tokens.filter((t) => typeof t === 'string').slice(0, MAX_TOKENS) : [],
        };
        const km = matchDistanceKm(report, sub, roleOf.get(doc.id));
        if (km === null) return;

        const res = await admin.messaging().sendEachForMulticast({
          tokens: sub.tokens,
          notification: buildNotification(report, km, s.lang),
          data: { type: 'rescue', reportId: context.params.reportId },
          android: { priority: 'high', notification: { channelId: 'rescue_alerts' } },
        });
        sent += res.successCount;
        failed += res.failureCount;

        // Forget tokens FCM says are gone (app uninstalled, token rotated).
        const dead = sub.tokens.filter((_, i) => {
          const r = res.responses[i];
          return !r.success && r.error && isDeadTokenError(r.error.code);
        });
        if (dead.length > 0) {
          await doc.ref.update({ tokens: admin.firestore.FieldValue.arrayRemove(...dead) });
        }
      }),
    );

    functions.logger.info('rescue push', { reportId: context.params.reportId, sent, failed });
    return null;
  });
