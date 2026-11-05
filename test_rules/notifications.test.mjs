// Firestore security rules tests for `notifications`.
// Run: cd test_rules && npm install && npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails, assertSucceeds, initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, query, where, getDocs,
  serverTimestamp, Timestamp,
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
    await setDoc(doc(f, 'users/carol'), { name: 'Carol', role: 'adopter' });
    await setDoc(doc(f, 'users/vol'), { name: 'Vee', role: 'volunteer' });
    await setDoc(doc(f, 'users/admin'), { name: 'Ada', role: 'admin' });
    await setDoc(doc(f, 'adoptions/ad1'), { adopterId: 'alice', petName: 'Rex', currentStage: 'screening' });
    // Bob lost his dog; Carol has a lost post too.
    await setDoc(doc(f, 'lostfound/lostBob'), { userId: 'bob', type: 'lost', petName: 'Max' });
    await setDoc(doc(f, 'lostfound/lostCarol'), { userId: 'carol', type: 'lost', petName: 'Mimi' });
    // Alice reported a sighting on Bob's post.
    await setDoc(doc(f, 'sightings/s1'), { reporterId: 'alice', lostReportId: 'lostBob', status: 'open' });
    // Bob reported a sighting on his own post.
    await setDoc(doc(f, 'sightings/sOwn'), { reporterId: 'bob', lostReportId: 'lostBob', status: 'open' });
    await setDoc(doc(f, 'notifications/n1'), {
      toUid: 'alice', type: 'adoption_stage', params: { petName: 'Rex', stage: 'trial' },
      refCollection: 'adoptions', refId: 'ad1', fromUid: 'admin', read: false,
      createdAt: Timestamp.now(),
    });
  });
});

const stageNotif = (over = {}) => ({
  toUid: 'alice', type: 'adoption_stage', params: { petName: 'Rex', stage: 'trial' },
  refCollection: 'adoptions', refId: 'ad1', fromUid: 'admin', read: false,
  createdAt: serverTimestamp(), ...over,
});

const sightingNotif = (over = {}) => ({
  toUid: 'bob', type: 'sighting', params: { animalType: 'Dog', sightingId: 's1' },
  refCollection: 'lostfound', refId: 'lostBob', fromUid: 'alice', read: false,
  createdAt: serverTimestamp(), ...over,
});

describe('notifications: read / update / delete', () => {
  test('recipient can read and list their own', async () => {
    await assertSucceeds(getDoc(doc(db('alice'), 'notifications/n1')));
    await assertSucceeds(getDocs(query(collection(db('alice'), 'notifications'), where('toUid', '==', 'alice'))));
  });

  test('others cannot read or list', async () => {
    await assertFails(getDoc(doc(db('bob'), 'notifications/n1')));
    await assertFails(getDoc(doc(db(null), 'notifications/n1')));
    await assertFails(getDocs(collection(db('bob'), 'notifications')));
    await assertFails(getDocs(query(collection(db('bob'), 'notifications'), where('toUid', '==', 'alice'))));
  });

  test('recipient can mark read, but change nothing else', async () => {
    await assertSucceeds(updateDoc(doc(db('alice'), 'notifications/n1'), { read: true }));
    await assertFails(updateDoc(doc(db('alice'), 'notifications/n1'), { toUid: 'bob' }));
    await assertFails(updateDoc(doc(db('alice'), 'notifications/n1'), { read: true, params: { petName: 'X', stage: 'trial' } }));
    await assertFails(updateDoc(doc(db('alice'), 'notifications/n1'), { read: 'yes' }));
  });

  test('others cannot update or delete', async () => {
    await assertFails(updateDoc(doc(db('bob'), 'notifications/n1'), { read: true }));
    await assertFails(updateDoc(doc(db('admin'), 'notifications/n1'), { read: true }));
    await assertFails(deleteDoc(doc(db('bob'), 'notifications/n1')));
  });

  test('recipient can delete', async () => {
    await assertSucceeds(deleteDoc(doc(db('alice'), 'notifications/n1')));
  });
});

describe('notifications: adoption_stage create', () => {
  test('admin can notify the adopter', async () => {
    await assertSucceeds(addDoc(collection(db('admin'), 'notifications'), stageNotif()));
  });

  test('non-admins cannot', async () => {
    await assertFails(addDoc(collection(db('bob'), 'notifications'), stageNotif({ fromUid: 'bob' })));
    await assertFails(addDoc(collection(db('vol'), 'notifications'), stageNotif({ fromUid: 'vol' })));
    await assertFails(addDoc(collection(db('alice'), 'notifications'), stageNotif({ fromUid: 'alice' })));
  });

  test('admin cannot target someone other than the adopter', async () => {
    await assertFails(addDoc(collection(db('admin'), 'notifications'), stageNotif({ toUid: 'bob' })));
  });

  test('rejects spoofed sender, pre-read, client time, extra keys, bad params', async () => {
    const c = collection(db('admin'), 'notifications');
    await assertFails(addDoc(c, stageNotif({ fromUid: 'alice' })));
    await assertFails(addDoc(c, stageNotif({ read: true })));
    await assertFails(addDoc(c, stageNotif({ createdAt: Timestamp.fromMillis(0) })));
    await assertFails(addDoc(c, stageNotif({ title: 'Hello' })));
    await assertFails(addDoc(c, stageNotif({ refCollection: 'pets' })));
    await assertFails(addDoc(c, stageNotif({ params: { petName: 'Rex', stage: 'hacked' } })));
    await assertFails(addDoc(c, stageNotif({ params: { petName: 'x'.repeat(101), stage: 'trial' } })));
    await assertFails(addDoc(c, stageNotif({ params: { petName: 'Rex', stage: 'trial', extra: 'x' } })));
    await assertFails(addDoc(c, stageNotif({ type: 'promo' })));
  });
});

describe('notifications: sighting create', () => {
  test('reporter can notify the lost post owner', async () => {
    await assertSucceeds(addDoc(collection(db('alice'), 'notifications'), sightingNotif()));
  });

  test('spoofing toUid on a sighting for someone else\'s post is denied', async () => {
    // Alice tries to notify Carol, who does not own lostBob.
    await assertFails(addDoc(collection(db('alice'), 'notifications'), sightingNotif({ toUid: 'carol' })));
    // ...or points at Carol's post with a sighting that belongs to lostBob.
    await assertFails(addDoc(collection(db('alice'), 'notifications'),
      sightingNotif({ toUid: 'carol', refId: 'lostCarol' })));
  });

  test('cannot use someone else\'s sighting or a missing one', async () => {
    await assertFails(addDoc(collection(db('carol'), 'notifications'), sightingNotif({ fromUid: 'carol' })));
    await assertFails(addDoc(collection(db('alice'), 'notifications'),
      sightingNotif({ params: { animalType: 'Dog', sightingId: 'nope' } })));
  });

  test('owner cannot notify themselves', async () => {
    await assertFails(addDoc(collection(db('bob'), 'notifications'),
      sightingNotif({ fromUid: 'bob', params: { animalType: 'Dog', sightingId: 'sOwn' } })));
  });

  test('signed-out users and bad shapes are denied', async () => {
    await assertFails(addDoc(collection(db(null), 'notifications'), sightingNotif()));
    const c = collection(db('alice'), 'notifications');
    await assertFails(addDoc(c, sightingNotif({ refCollection: 'adoptions' })));
    await assertFails(addDoc(c, sightingNotif({ read: true })));
    await assertFails(addDoc(c, sightingNotif({ fromUid: 'bob' })));
    await assertFails(addDoc(c, sightingNotif({ params: { animalType: 'x'.repeat(41), sightingId: 's1' } })));
    await assertFails(addDoc(c, sightingNotif({ params: { animalType: 'Dog' } })));
    await assertFails(addDoc(c, sightingNotif({ extra: 1 })));
  });
});
