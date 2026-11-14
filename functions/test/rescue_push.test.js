'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  haversineKm,
  formatDistance,
  matchDistanceKm,
  buildNotification,
  isDeadTokenError,
} = require('../rescue_push');

// Port Louis, and points roughly 3 km and 35 km away.
const PL = { lat: -20.1609, lng: 57.5012 };
const NEAR = { lat: -20.185, lng: 57.515 };
const FAR = { lat: -20.408, lng: 57.7 };

const report = (over = {}) => ({
  status: 'pending',
  urgency: 'high',
  animalType: 'dog',
  location: 'Rue Royale, Port Louis',
  reporterId: 'reporter',
  ...NEAR,
  ...over,
});

const sub = (over = {}) => ({
  uid: 'rescuer',
  enabled: true,
  ...PL,
  radiusKm: 10,
  urgentOnly: false,
  tokens: ['t1'],
  ...over,
});

test('haversineKm matches known distances', () => {
  assert.equal(haversineKm(PL.lat, PL.lng, PL.lat, PL.lng), 0);
  const d = haversineKm(PL.lat, PL.lng, NEAR.lat, NEAR.lng);
  assert.ok(d > 2 && d < 4, `got ${d}`);
});

test('formatDistance', () => {
  assert.equal(formatDistance(0.35), '350 m');
  assert.equal(formatDistance(4.24), '4.2 km');
  assert.equal(formatDistance(14.4), '14 km');
});

test('a rescuer inside the radius is matched with the distance', () => {
  const km = matchDistanceKm(report(), sub(), 'volunteer');
  assert.ok(km > 2 && km < 4);
});

test('outside the radius is not matched', () => {
  assert.equal(matchDistanceKm(report(FAR), sub(), 'volunteer'), null);
  assert.ok(matchDistanceKm(report(FAR), sub({ radiusKm: 50 }), 'volunteer') > 30);
});

test('only rescuer roles are notified', () => {
  for (const role of ['volunteer', 'partner', 'admin', 'superAdmin']) {
    assert.notEqual(matchDistanceKm(report(), sub(), role), null, role);
  }
  for (const role of ['adopter', 'rehomer', null, undefined, 'hacker']) {
    assert.equal(matchDistanceKm(report(), sub(), role), null, String(role));
  }
});

test('the reporter is not notified about their own report', () => {
  assert.equal(matchDistanceKm(report({ reporterId: 'rescuer' }), sub(), 'volunteer'), null);
});

test('urgentOnly drops medium urgency', () => {
  assert.equal(matchDistanceKm(report({ urgency: 'medium' }), sub({ urgentOnly: true }), 'volunteer'), null);
  assert.notEqual(matchDistanceKm(report({ urgency: 'critical' }), sub({ urgentOnly: true }), 'volunteer'), null);
  assert.notEqual(matchDistanceKm(report({ urgency: 'medium' }), sub(), 'volunteer'), null);
});

test('disabled, tokenless, pinless and non-pending cases are skipped', () => {
  assert.equal(matchDistanceKm(report(), sub({ enabled: false }), 'volunteer'), null);
  assert.equal(matchDistanceKm(report(), sub({ tokens: [] }), 'volunteer'), null);
  assert.equal(matchDistanceKm(report(), sub({ lat: null }), 'volunteer'), null);
  assert.equal(matchDistanceKm(report(), sub({ radiusKm: 'far' }), 'volunteer'), null);
  assert.equal(matchDistanceKm(report({ lat: null, lng: null }), sub(), 'volunteer'), null);
  assert.equal(matchDistanceKm(report({ status: 'assigned' }), sub(), 'volunteer'), null);
});

test('buildNotification is localised and leaves out the reporter', () => {
  const en = buildNotification(report({ reporterName: 'Jane', reporterPhone: '5555' }), 4.2, 'en');
  assert.equal(en.title, 'Urgent rescue near you');
  assert.equal(en.body, 'Dog · 4.2 km away · Rue Royale, Port Louis');
  assert.ok(!en.body.includes('Jane') && !en.body.includes('5555'));

  const fr = buildNotification(report({ urgency: 'critical', animalType: 'cat' }), 0.35, 'fr');
  assert.equal(fr.title, 'Sauvetage critique près de vous');
  assert.equal(fr.body, 'Chat · à 350 m · Rue Royale, Port Louis');

  const mfe = buildNotification(report({ urgency: 'medium', animalType: 'other', location: '' }), 12, 'mfe');
  assert.equal(mfe.title, 'Demann sovtaz pre ar ou');
  assert.equal(mfe.body, 'Zanimo · a 12 km');
});

test('buildNotification falls back to English and clips long locations', () => {
  const n = buildNotification(report({ location: 'x'.repeat(200), urgency: 'weird' }), 1, 'de');
  assert.equal(n.title, 'Rescue request near you');
  assert.ok(n.body.length < 110);
  assert.ok(n.body.endsWith('…'));
});

test('isDeadTokenError', () => {
  assert.ok(isDeadTokenError('messaging/registration-token-not-registered'));
  assert.ok(isDeadTokenError('messaging/invalid-registration-token'));
  assert.ok(!isDeadTokenError('messaging/internal-error'));
  assert.ok(!isDeadTokenError(undefined));
});
