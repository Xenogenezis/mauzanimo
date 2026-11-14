// Rules tests for private admin notes (admin_notes).
// Run: cd test_rules && npm test   (runs every *.test.mjs in the emulator)
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails, assertSucceeds, initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, deleteDoc, serverTimestamp, Timestamp,
} from 'firebase/firestore';

let env;
// Signed-in test users are verified accounts unless a test says otherwise.
const db = (uid) => (uid ? env.authenticatedContext(uid, { email_verified: true }) : env.unauthenticatedContext()).firestore();

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
    await setDoc(doc(f, 'users/vol'), { name: 'Vee', role: 'volunteer' });
    await setDoc(doc(f, 'users/admin'), { name: 'Ada', role: 'admin' });
    await setDoc(doc(f, 'users/super'), { name: 'Sam', role: 'superAdmin' });
    await setDoc(doc(f, 'adoptions/a1'), { adopterId: 'alice', petId: 'p1', currentStage: 'application' });
    await setDoc(doc(f, 'admin_notes/adoptions_a1'), {
      text: 'Home visit OK', updatedBy: 'admin', updatedAt: Timestamp.now(),
    });
  });
});

const note = (uid, extra = {}) => ({ text: 'Has a fenced garden', updatedBy: uid, updatedAt: serverTimestamp(), ...extra });
const put = (uid, data, id = 'adoptions_a1') => setDoc(doc(db(uid), `admin_notes/${id}`), data);

describe('admin_notes / read', () => {
  test('admin can read a note', () => assertSucceeds(getDoc(doc(db('admin'), 'admin_notes/adoptions_a1'))));
  test('superAdmin can read a note', () => assertSucceeds(getDoc(doc(db('super'), 'admin_notes/adoptions_a1'))));
  test('the adopter cannot read notes about their adoption', () =>
    assertFails(getDoc(doc(db('alice'), 'admin_notes/adoptions_a1'))));
  test('volunteer cannot read', () => assertFails(getDoc(doc(db('vol'), 'admin_notes/adoptions_a1'))));
  test('signed-out cannot read', () => assertFails(getDoc(doc(db(null), 'admin_notes/adoptions_a1'))));
});

describe('admin_notes / write', () => {
  test('admin can create a note', () => assertSucceeds(put('admin', note('admin'), 'users_alice')));
  test('admin can update a note', () => assertSucceeds(put('admin', note('admin'))));
  test('superAdmin can update a note', () => assertSucceeds(put('super', note('super'))));
  test('admin can delete a note', () => assertSucceeds(deleteDoc(doc(db('admin'), 'admin_notes/adoptions_a1'))));
  test('regular user cannot write', () => assertFails(put('alice', note('alice'))));
  test('volunteer cannot write', () => assertFails(put('vol', note('vol'))));
  test('regular user cannot delete', () => assertFails(deleteDoc(doc(db('alice'), 'admin_notes/adoptions_a1'))));
  test('admin cannot sign as someone else', () => assertFails(put('admin', note('super'))));
  test('client-chosen time is rejected', () =>
    assertFails(put('admin', note('admin', { updatedAt: Timestamp.fromDate(new Date('2020-01-01')) }))));
  test('extra fields are rejected', () => assertFails(put('admin', note('admin', { role: 'superAdmin' }))));
  test('non-string text is rejected', () => assertFails(put('admin', note('admin', { text: 42 }))));
  test('text over 4000 chars is rejected', () => assertFails(put('admin', note('admin', { text: 'x'.repeat(4001) }))));
  test('text of 4000 chars is accepted', () => assertSucceeds(put('admin', note('admin', { text: 'x'.repeat(4000) }))));
});
