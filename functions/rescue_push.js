'use strict';

// Pure helpers for the rescue push function, kept free of Firebase so they
// can be unit tested with `npm test`. The matching rules mirror
// lib/utils/rescue_alerts.dart (nearbyRescues) in the app.

/** Roles that may take rescue requests: isVolunteerOrAbove() in firestore.rules. */
const RESCUER_ROLES = ['volunteer', 'partner', 'admin', 'superAdmin'];

/** Most device tokens kept per subscriber (mirrors firestore.rules). */
const MAX_TOKENS = 5;

/** Great-circle distance in kilometres. */
function haversineKm(lat1, lng1, lat2, lng2) {
  const rad = (d) => (d * Math.PI) / 180;
  const dLat = rad(lat2 - lat1);
  const dLng = rad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.min(1, Math.sqrt(a)));
}

/** "350 m" / "4.2 km" / "14 km", as formatDistance in the app. */
function formatDistance(km) {
  if (km < 1) return `${Math.round(km * 1000)} m`;
  return `${km.toFixed(km < 10 ? 1 : 0)} km`;
}

function isNumber(v) {
  return typeof v === 'number' && Number.isFinite(v);
}

/**
 * Distance in km if `sub` should be told about `report`, otherwise null.
 *
 * report: { status, urgency, reporterId, lat, lng }
 * sub:    { uid, enabled, lat, lng, radiusKm, urgentOnly, tokens }
 * role:   the subscriber's role from users/{uid}
 */
function matchDistanceKm(report, sub, role) {
  if (report.status !== 'pending') return null;
  if (!isNumber(report.lat) || !isNumber(report.lng)) return null;
  if (sub.enabled !== true) return null;
  if (!isNumber(sub.lat) || !isNumber(sub.lng) || !isNumber(sub.radiusKm)) return null;
  if (!Array.isArray(sub.tokens) || sub.tokens.length === 0) return null;
  if (!RESCUER_ROLES.includes(role)) return null;
  // Don't alert someone about their own report.
  if (sub.uid === report.reporterId) return null;
  if (sub.urgentOnly === true && !['critical', 'high'].includes(report.urgency)) return null;
  const km = haversineKm(sub.lat, sub.lng, report.lat, report.lng);
  return km <= sub.radiusKm ? km : null;
}

const TEXT = {
  en: {
    title: { critical: 'Critical rescue near you', high: 'Urgent rescue near you', medium: 'Rescue request near you' },
    animal: { dog: 'Dog', cat: 'Cat', other: 'Animal' },
    away: (d) => `${d} away`,
  },
  fr: {
    title: {
      critical: 'Sauvetage critique près de vous',
      high: 'Sauvetage urgent près de vous',
      medium: 'Demande de sauvetage près de vous',
    },
    animal: { dog: 'Chien', cat: 'Chat', other: 'Animal' },
    away: (d) => `à ${d}`,
  },
  mfe: {
    title: {
      critical: 'Sovtaz kritik pre ar ou',
      high: 'Sovtaz irzan pre ar ou',
      medium: 'Demann sovtaz pre ar ou',
    },
    animal: { dog: 'Lisien', cat: 'Sat', other: 'Zanimo' },
    away: (d) => `a ${d}`,
  },
};

function clip(s, max) {
  const t = String(s || '').replace(/\s+/g, ' ').trim();
  return t.length <= max ? t : `${t.slice(0, max - 1)}…`;
}

/**
 * Localised notification for one subscriber.
 * Body: "Dog · 4.2 km away · Rue Royale, Port Louis".
 * The reporter's name and phone are deliberately left out of the push.
 */
function buildNotification(report, km, lang) {
  const t = TEXT[lang] || TEXT.en;
  const urgency = ['critical', 'high'].includes(report.urgency) ? report.urgency : 'medium';
  const animal = t.animal[report.animalType] || t.animal.other;
  const parts = [animal, t.away(formatDistance(km))];
  const place = clip(report.location, 80);
  if (place) parts.push(place);
  return { title: t.title[urgency], body: parts.join(' · ') };
}

/** FCM error codes that mean the token is dead and should be forgotten. */
function isDeadTokenError(code) {
  return (
    code === 'messaging/registration-token-not-registered' ||
    code === 'messaging/invalid-registration-token' ||
    code === 'messaging/invalid-argument'
  );
}

module.exports = {
  RESCUER_ROLES,
  MAX_TOKENS,
  haversineKm,
  formatDistance,
  matchDistanceKm,
  buildNotification,
  isDeadTokenError,
};
