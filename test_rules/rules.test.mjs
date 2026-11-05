// Firestore security rules tests. Run: cd test_rules && npm install && npm test
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
    await setDoc(doc(f, 'users/vol'), { name: 'Vee', role: 'volunteer' });
    await setDoc(doc(f, 'users/admin'), { name: 'Ada', role: 'admin' });
    await setDoc(doc(f, 'users/super'), { name: 'Sam', role: 'superAdmin' });
    await setDoc(doc(f, 'pets/p1'), { name: 'Rex', status: 'available', uploadedBy: 'bob' });
    await setDoc(doc(f, 'adoptions/a1'), { adopterId: 'alice', petId: 'p1', currentStage: 'application' });
    await setDoc(doc(f, 'fosters/f1'), { fosterUserId: 'alice', status: 'pending' });
    await setDoc(doc(f, 'inquiries/i1'), { userId: 'alice', status: 'pending' });
    await setDoc(doc(f, 'rescue_reports/r1'), { reporterId: 'bob', status: 'pending', description: 'hurt dog' });
    await setDoc(doc(f, 'sightings/s1'), { reporterId: 'bob', status: 'open', geo: new GeoPoint(-20, 57.5), lostReportId: 'lf1' });
    await setDoc(doc(f, 'event_registrations/e1'), { userId: 'alice', status: 'registered' });
  });
});

describe('users / privilege escalation', () => {
  test('a user cannot promote themselves to admin', () =>
    assertFails(updateDoc(doc(db('alice'), 'users/alice'), { role: 'admin' })));
  test('a user cannot promote themselves to superAdmin', () =>
    assertFails(updateDoc(doc(db('alice'), 'users/alice'), { role: 'superAdmin' })));
  test('a user cannot self-verify', () =>
    assertFails(updateDoc(doc(db('alice'), 'users/alice'), { verificationLevel: 'verified' })));
  test('a user can edit their own name', () =>
    assertSucceeds(updateDoc(doc(db('alice'), 'users/alice'), { name: 'Alicia' })));
  test('a user cannot read someone else\'s profile', () =>
    assertFails(getDoc(doc(db('alice'), 'users/bob'))));
  test('registration with an admin role is rejected', () =>
    assertFails(setDoc(doc(db('carol'), 'users/carol'), { name: 'C', role: 'admin' })));
  test('registration as volunteer is allowed', () =>
    assertSucceeds(setDoc(doc(db('carol'), 'users/carol'), { name: 'C', role: 'volunteer' })));
  test('registration without a role is allowed (Google sign-in)', () =>
    assertSucceeds(setDoc(doc(db('carol'), 'users/carol'), { name: 'C' })));
  test('admin can make a user a volunteer', () =>
    assertSucceeds(updateDoc(doc(db('admin'), 'users/alice'), { role: 'volunteer' })));
  test('admin cannot grant admin', () =>
    assertFails(updateDoc(doc(db('admin'), 'users/alice'), { role: 'admin' })));
  test('admin cannot demote a superAdmin', () =>
    assertFails(updateDoc(doc(db('admin'), 'users/super'), { role: 'adopter' })));
  test('superAdmin can grant admin', () =>
    assertSucceeds(updateDoc(doc(db('super'), 'users/alice'), { role: 'admin' })));
  test('superAdmin passes isAdmin() (reads any user)', () =>
    assertSucceeds(getDoc(doc(db('super'), 'users/alice'))));
});

describe('collections that were previously denied', () => {
  test('lostfound: create own post', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'lostfound'), { userId: 'alice', type: 'Lost', geo: new GeoPoint(-20.1, 57.5) })));
  test('lostfound: cannot post as someone else', () =>
    assertFails(addDoc(collection(db('alice'), 'lostfound'), { userId: 'bob', type: 'Lost' })));
  test('lostfound: geo must be a GeoPoint', () =>
    assertFails(addDoc(collection(db('alice'), 'lostfound'), { userId: 'alice', geo: 'here' })));
  test('stories: create own story', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'stories'), { userId: 'alice', story: 'yay' })));
  test('user_gamification: write own doc + history', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'user_gamification/alice'), { userId: 'alice', points: 0 }));
    await assertSucceeds(setDoc(doc(db('alice'), 'user_gamification/alice/impact_history/x'), { userId: 'alice' }));
  });
  test('user_gamification: cannot write someone else\'s', () =>
    assertFails(setDoc(doc(db('alice'), 'user_gamification/bob'), { points: 99999 })));
  test('adoptions: adopter reads own (adopterId)', () =>
    assertSucceeds(getDoc(doc(db('alice'), 'adoptions/a1'))));
  test('adoptions: others cannot read', () =>
    assertFails(getDoc(doc(db('bob'), 'adoptions/a1'))));
  test('adoptions: adopter can query their list', () =>
    assertSucceeds(getDocs(query(collection(db('alice'), 'adoptions'), where('adopterId', '==', 'alice')))));
  test('adoptions: adopter cannot skip to completed', () =>
    assertFails(setDoc(doc(db('alice'), 'adoptions/a2'), { adopterId: 'alice', currentStage: 'completed' })));
  test('fosters: foster reads own (fosterUserId)', () =>
    assertSucceeds(getDoc(doc(db('alice'), 'fosters/f1'))));
  test('admin reads inquiries / adoptions / fosters', async () => {
    await assertSucceeds(getDoc(doc(db('admin'), 'inquiries/i1')));
    await assertSucceeds(getDoc(doc(db('admin'), 'adoptions/a1')));
    await assertSucceeds(getDoc(doc(db('super'), 'fosters/f1')));
  });
});

describe('pets', () => {
  test('anyone can read pets, even signed out', () => assertSucceeds(getDoc(doc(db(null), 'pets/p1'))));
  test('adopter can mark an available pet pending (adoption workflow)', () =>
    assertSucceeds(updateDoc(doc(db('alice'), 'pets/p1'), { status: 'pending' })));
  test('adopter cannot mark a pet adopted', () =>
    assertFails(updateDoc(doc(db('alice'), 'pets/p1'), { status: 'adopted' })));
  test('adopter cannot change other fields', () =>
    assertFails(updateDoc(doc(db('alice'), 'pets/p1'), { status: 'pending', name: 'Hacked' })));
  test('owner can edit their pet', () =>
    assertSucceeds(updateDoc(doc(db('bob'), 'pets/p1'), { name: 'Rexy' })));
  test('cannot create a pet attributed to someone else', () =>
    assertFails(addDoc(collection(db('alice'), 'pets'), { name: 'X', uploadedBy: 'bob' })));
  test('non-owner cannot delete', () => assertFails(deleteDoc(doc(db('alice'), 'pets/p1'))));
});

describe('abuse limits / privacy', () => {
  const big = 'data:image/jpeg;base64,' + 'A'.repeat(900000);
  test('oversized image is rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'lostfound'), { userId: 'alice', imageUrl: big })));
  test('normal image is accepted', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'lostfound'), { userId: 'alice', imageUrl: 'data:image/jpeg;base64,' + 'A'.repeat(100000) })));
  test('huge description is rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'stories'), { userId: 'alice', description: 'x'.repeat(6000) })));
  test('new pet cannot publish uploader email', () =>
    assertFails(addDoc(collection(db('alice'), 'pets'), { name: 'X', uploadedBy: 'alice', uploaderEmail: 'a@b.c' })));
  test('owner can still edit an old pet that already has an email', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'pets/old'), { uploadedBy: 'bob', uploaderEmail: 'bob@x.mu', status: 'available' }));
    await assertSucceeds(updateDoc(doc(db('bob'), 'pets/old'), { name: 'Old boy' }));
  });
});

describe('sightings', () => {
  const s = (uid, extra = {}) => ({ reporterId: uid, status: 'open', geo: new GeoPoint(-20.01, 57.58), createdAt: serverTimestamp(), ...extra });
  test('signed-in user can report a sighting', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'sightings'), s('alice'))));
  test('a sighting needs a GeoPoint', () =>
    assertFails(addDoc(collection(db('alice'), 'sightings'), s('alice', { geo: null }))));
  test('cannot create already-resolved/hidden', () =>
    assertFails(addDoc(collection(db('alice'), 'sightings'), s('alice', { status: 'hidden' }))));
  test('signed-out users cannot report', () =>
    assertFails(addDoc(collection(db(null), 'sightings'), s('x'))));
  test('sightings for a lost report are queryable', () =>
    assertSucceeds(getDocs(query(collection(db('alice'), 'sightings'), where('lostReportId', '==', 'lf1')))));
  test('volunteer can triage status', () =>
    assertSucceeds(updateDoc(doc(db('vol'), 'sightings/s1'), { status: 'resolved', handledBy: 'vol' })));
  test('volunteer cannot move the pin', () =>
    assertFails(updateDoc(doc(db('vol'), 'sightings/s1'), { geo: new GeoPoint(0, 0) })));
  test('random user cannot change status', () =>
    assertFails(updateDoc(doc(db('alice'), 'sightings/s1'), { status: 'hidden' })));
  test('admin can hide', () =>
    assertSucceeds(updateDoc(doc(db('admin'), 'sightings/s1'), { status: 'hidden' })));
});

describe('rescue reports', () => {
  test('volunteer can self-assign', () =>
    assertSucceeds(updateDoc(doc(db('vol'), 'rescue_reports/r1'), { status: 'assigned', assignedVolunteerId: 'vol', assignedVolunteerName: 'Vee' })));
  test('volunteer cannot rewrite the description', () =>
    assertFails(updateDoc(doc(db('vol'), 'rescue_reports/r1'), { description: 'nothing here' })));
  test('a plain adopter can no longer edit someone\'s report', () =>
    assertFails(updateDoc(doc(db('alice'), 'rescue_reports/r1'), { status: 'resolved' })));
});

describe('event registrations', () => {
  test('user can cancel own registration', () =>
    assertSucceeds(updateDoc(doc(db('alice'), 'event_registrations/e1'), { status: 'cancelled' })));
  test('user cannot mark themselves attended', () =>
    assertFails(updateDoc(doc(db('alice'), 'event_registrations/e1'), { status: 'attended' })));
});
