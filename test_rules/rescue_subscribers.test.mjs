// Firestore security rules tests for `rescue_subscribers` (rescue push
// subscriptions) and the `geo` pin on `rescue_reports`.
// Run: cd test_rules && npm install && npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails, assertSucceeds, initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, getDocs,
  serverTimestamp, GeoPoint,
} from 'firebase/firestore';

let env;
const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-mauzanimo',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8181 },
  });
});
after(() => env.cleanup());

const sub = (over = {}) => ({
  enabled: true,
  geo: new GeoPoint(-20.16, 57.5),
  radiusKm: 10,
  urgentOnly: false,
  tokens: ['token-a'],
  lang: 'en',
  updatedAt: serverTimestamp(),
  ...over,
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    await setDoc(doc(f, 'users/alice'), { name: 'Alice', role: 'adopter' });
    await setDoc(doc(f, 'users/vol'), { name: 'Vee', role: 'volunteer' });
    await setDoc(doc(f, 'users/vol2'), { name: 'Val', role: 'volunteer' });
    await setDoc(doc(f, 'users/partner'), { name: 'Pat', role: 'partner' });
    await setDoc(doc(f, 'users/admin'), { name: 'Ada', role: 'admin' });
    await setDoc(doc(f, 'users/super'), { name: 'Sue', role: 'superAdmin' });
    await setDoc(doc(f, 'rescue_subscribers/vol2'), {
      enabled: true, geo: new GeoPoint(-20.2, 57.5), radiusKm: 20, urgentOnly: false,
      tokens: ['token-v2'], lang: 'fr', updatedAt: new Date(),
    });
  });
});

describe('rescue_subscribers: who may subscribe', () => {
  test('volunteers, partners and admins can create their own', async () => {
    await assertSucceeds(setDoc(doc(db('vol'), 'rescue_subscribers/vol'), sub()));
    await assertSucceeds(setDoc(doc(db('partner'), 'rescue_subscribers/partner'), sub()));
    await assertSucceeds(setDoc(doc(db('admin'), 'rescue_subscribers/admin'), sub()));
  });

  test('adopters and signed-out users cannot', async () => {
    await assertFails(setDoc(doc(db('alice'), 'rescue_subscribers/alice'), sub()));
    await assertFails(setDoc(doc(db(null), 'rescue_subscribers/alice'), sub()));
  });

  test('nobody can write another account\'s subscription', async () => {
    await assertFails(setDoc(doc(db('vol'), 'rescue_subscribers/vol2'), sub()));
    await assertFails(setDoc(doc(db('admin'), 'rescue_subscribers/vol2'), sub()));
    await assertFails(updateDoc(doc(db('vol'), 'rescue_subscribers/vol2'), { enabled: false, updatedAt: serverTimestamp() }));
  });

  test('owner can update their own', async () => {
    await assertSucceeds(setDoc(doc(db('vol2'), 'rescue_subscribers/vol2'), sub({ radiusKm: 50, tokens: ['a', 'b'] })));
  });
});

describe('rescue_subscribers: privacy', () => {
  test('only the owner can read it', async () => {
    await assertSucceeds(getDoc(doc(db('vol2'), 'rescue_subscribers/vol2')));
    await assertFails(getDoc(doc(db('vol'), 'rescue_subscribers/vol2')));
    await assertFails(getDoc(doc(db('admin'), 'rescue_subscribers/vol2')));
    await assertFails(getDoc(doc(db('super'), 'rescue_subscribers/vol2')));
    await assertFails(getDoc(doc(db(null), 'rescue_subscribers/vol2')));
  });

  test('nobody can list subscribers', async () => {
    await assertFails(getDocs(collection(db('vol2'), 'rescue_subscribers')));
    await assertFails(getDocs(collection(db('admin'), 'rescue_subscribers')));
    await assertFails(getDocs(collection(db('super'), 'rescue_subscribers')));
  });

  test('owner and superAdmin can delete; others cannot', async () => {
    await assertFails(deleteDoc(doc(db('vol'), 'rescue_subscribers/vol2')));
    await assertFails(deleteDoc(doc(db('admin'), 'rescue_subscribers/vol2')));
    await assertSucceeds(deleteDoc(doc(db('vol2'), 'rescue_subscribers/vol2')));
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'rescue_subscribers/vol2'), { enabled: true }));
    await assertSucceeds(deleteDoc(doc(db('super'), 'rescue_subscribers/vol2')));
  });
});

describe('rescue_subscribers: field validation', () => {
  const write = (data) => setDoc(doc(db('vol'), 'rescue_subscribers/vol'), data);

  test('rejects unknown fields and wrong types', async () => {
    await assertFails(write(sub({ role: 'admin' })));
    await assertFails(write(sub({ enabled: 'yes' })));
    await assertFails(write(sub({ geo: { lat: 1, lng: 2 } })));
    await assertFails(write(sub({ urgentOnly: 1 })));
    await assertFails(write(sub({ lang: 'de' })));
  });

  test('radius must be one of the offered distances', async () => {
    for (const km of [5, 10, 20, 50]) await assertSucceeds(write(sub({ radiusKm: km })));
    for (const km of [0, 7, 500, '10']) await assertFails(write(sub({ radiusKm: km })));
  });

  test('at most 5 tokens, each a non-empty bounded string', async () => {
    await assertSucceeds(write(sub({ tokens: [] })));
    await assertSucceeds(write(sub({ tokens: ['a', 'b', 'c', 'd', 'e'] })));
    await assertFails(write(sub({ tokens: ['a', 'b', 'c', 'd', 'e', 'f'] })));
    await assertFails(write(sub({ tokens: 'a' })));
    await assertFails(write(sub({ tokens: ['a', 5] })));
    await assertFails(write(sub({ tokens: [''] })));
    await assertFails(write(sub({ tokens: ['x'.repeat(1025)] })));
  });

  test('updatedAt must be the server time', async () => {
    await assertFails(write(sub({ updatedAt: new Date(2020, 0, 1) })));
    const { updatedAt, ...rest } = sub();
    await assertFails(write(rest));
  });
});

describe('rescue_reports: map pin', () => {
  const report = (over = {}) => ({
    description: 'Injured dog', location: 'Rue Royale', animalType: 'dog', urgency: 'high',
    status: 'pending', imageUrl: null, reporterId: 'alice', reporterName: 'Alice', reporterPhone: '5555',
    assignedVolunteerId: null, assignedVolunteerName: null, createdAt: serverTimestamp(), resolvedAt: null,
    ...over,
  });

  test('a report can be created with or without a pin', async () => {
    await assertSucceeds(addDoc(collection(db('alice'), 'rescue_reports'), report()));
    await assertSucceeds(addDoc(collection(db('alice'), 'rescue_reports'), report({ geo: new GeoPoint(-20.16, 57.5) })));
  });

  test('the pin must be a GeoPoint', async () => {
    await assertFails(addDoc(collection(db('alice'), 'rescue_reports'), report({ geo: '-20.16,57.5' })));
    await assertFails(addDoc(collection(db('alice'), 'rescue_reports'), report({ geo: { lat: -20.16, lng: 57.5 } })));
  });
});
