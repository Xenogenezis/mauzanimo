// Rules tests for the report-abuse queue (`reports`) and admin moderation.
// Run: cd test_rules && npm install && npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails, assertSucceeds, initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, query, where, getDocs,
  GeoPoint, serverTimestamp,
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

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    await setDoc(doc(f, 'users/alice'), { name: 'Alice', role: 'adopter' });
    await setDoc(doc(f, 'users/bob'), { name: 'Bob', role: 'adopter' });
    await setDoc(doc(f, 'users/admin'), { name: 'Ada', role: 'admin' });
    await setDoc(doc(f, 'users/super'), { name: 'Sam', role: 'superAdmin' });
    await setDoc(doc(f, 'pets/p1'), { name: 'Rex', status: 'available', uploadedBy: 'bob' });
    await setDoc(doc(f, 'lostfound/lf1'), { userId: 'bob', type: 'Lost' });
    await setDoc(doc(f, 'sightings/s1'), { reporterId: 'bob', status: 'open', geo: new GeoPoint(-20, 57.5) });
    await setDoc(doc(f, 'stories/st1'), { userId: 'bob', story: 'yay' });
    await setDoc(doc(f, 'reviews/rv1'), { reviewerId: 'bob', targetUserId: 'alice', rating: 5 });
    await setDoc(doc(f, 'reports/byBob'), {
      reporterId: 'bob', targetCollection: 'pets', targetId: 'p1', reason: 'spam', status: 'open',
    });
    await setDoc(doc(f, 'reports/byAlice'), {
      reporterId: 'alice', targetCollection: 'stories', targetId: 'st1', reason: 'other', status: 'open',
    });
  });
});

const report = (uid, extra = {}) => ({
  reporterId: uid,
  targetCollection: 'pets',
  targetId: 'p1',
  reason: 'scam',
  details: 'Asks for money upfront',
  status: 'open',
  createdAt: serverTimestamp(),
  ...extra,
});

describe('reports / create', () => {
  test('signed-in user can file a valid report', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'reports'), report('alice'))));
  test('details are optional', () => {
    const { details, ...noDetails } = report('alice');
    return assertSucceeds(addDoc(collection(db('alice'), 'reports'), noDetails));
  });
  test('every target collection and reason is accepted', async () => {
    for (const targetCollection of ['pets', 'lostfound', 'sightings', 'stories', 'reviews']) {
      await assertSucceeds(addDoc(collection(db('alice'), 'reports'), report('alice', { targetCollection })));
    }
    for (const reason of ['spam', 'scam', 'animal_welfare', 'inappropriate', 'wrong_info', 'other']) {
      await assertSucceeds(addDoc(collection(db('alice'), 'reports'), report('alice', { reason })));
    }
  });
  test('cannot report as someone else', () =>
    assertFails(addDoc(collection(db('alice'), 'reports'), report('bob'))));
  test('extra fields are rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'reports'), report('alice', { priority: 'urgent' }))));
  test('missing required field is rejected', () => {
    const { reason, ...noReason } = report('alice');
    return assertFails(addDoc(collection(db('alice'), 'reports'), noReason));
  });
  test('unknown reason is rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'reports'), report('alice', { reason: 'boring' }))));
  test('unknown target collection is rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'reports'), report('alice', { targetCollection: 'users' }))));
  test('status other than open is rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'reports'), report('alice', { status: 'actioned' }))));
  test('client-chosen createdAt is rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'reports'), report('alice', { createdAt: new Date(2020, 0, 1) }))));
  test('details over 1000 chars are rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'reports'), report('alice', { details: 'x'.repeat(1001) }))));
  test('details must be a string', () =>
    assertFails(addDoc(collection(db('alice'), 'reports'), report('alice', { details: null }))));
  test('targetId over 128 chars is rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'reports'), report('alice', { targetId: 'p'.repeat(129) }))));
  test('unauthenticated users cannot report', () =>
    assertFails(addDoc(collection(db(null), 'reports'), report('alice'))));
});

describe('reports / read, update, delete', () => {
  test('reporter can read their own report', () =>
    assertSucceeds(getDoc(doc(db('bob'), 'reports/byBob'))));
  test('reporter can query their own reports', () =>
    assertSucceeds(getDocs(query(collection(db('bob'), 'reports'), where('reporterId', '==', 'bob')))));
  test('reading someone else\'s report is denied', () =>
    assertFails(getDoc(doc(db('alice'), 'reports/byBob'))));
  test('listing all reports is denied to non-admins', () =>
    assertFails(getDocs(collection(db('alice'), 'reports'))));
  test('unauthenticated cannot read reports', () =>
    assertFails(getDoc(doc(db(null), 'reports/byBob'))));
  test('reporter cannot update their own report', () =>
    assertFails(updateDoc(doc(db('bob'), 'reports/byBob'), { status: 'dismissed' })));
  test('reporter cannot delete their own report', () =>
    assertFails(deleteDoc(doc(db('bob'), 'reports/byBob'))));
  test('admin can list open reports', () =>
    assertSucceeds(getDocs(query(collection(db('admin'), 'reports'), where('status', '==', 'open')))));
  test('admin can read any report', () =>
    assertSucceeds(getDoc(doc(db('admin'), 'reports/byAlice'))));
  test('admin can update a report status', () =>
    assertSucceeds(updateDoc(doc(db('admin'), 'reports/byBob'), { status: 'dismissed' })));
  test('superAdmin can update a report status', () =>
    assertSucceeds(updateDoc(doc(db('super'), 'reports/byBob'), { status: 'actioned' })));
  test('admin can delete a report', () =>
    assertSucceeds(deleteDoc(doc(db('admin'), 'reports/byAlice'))));
});

describe('moderation / hidden flag on targets', () => {
  for (const path of ['pets/p1', 'lostfound/lf1', 'sightings/s1', 'stories/st1', 'reviews/rv1']) {
    test(`admin can hide ${path}`, () =>
      assertSucceeds(updateDoc(doc(db('admin'), path), { hidden: true })));
    test(`a non-owner user cannot hide ${path}`, () =>
      assertFails(updateDoc(doc(db('alice'), path), { hidden: true })));
  }
});
