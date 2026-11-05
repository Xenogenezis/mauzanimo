// Rules tests for the append-only admin audit log (admin_audit).
// Run: cd test_rules && npm test   (runs every *.test.mjs in the emulator)
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails, assertSucceeds, initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, query, orderBy, limit, getDocs,
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
    await setDoc(doc(f, 'users/vol'), { name: 'Vee', role: 'volunteer' });
    await setDoc(doc(f, 'users/admin'), { name: 'Ada', role: 'admin' });
    await setDoc(doc(f, 'users/super'), { name: 'Sam', role: 'superAdmin' });
    await setDoc(doc(f, 'admin_audit/existing'), {
      actorUid: 'admin', action: 'update', collection: 'pets', docId: 'p1',
      summary: 'status → adopted', at: Timestamp.now(),
    });
  });
});

const entry = (uid, extra = {}) => ({
  actorUid: uid,
  action: 'update',
  collection: 'pets',
  docId: 'p1',
  summary: 'status → adopted',
  at: serverTimestamp(),
  ...extra,
});
const add = (uid, data) => addDoc(collection(db(uid), 'admin_audit'), data);

describe('admin_audit / create', () => {
  test('admin can append an entry', () => assertSucceeds(add('admin', entry('admin'))));
  test('superAdmin can append an entry', () => assertSucceeds(add('super', entry('super'))));
  test('summary is optional', () => {
    const { summary, ...rest } = entry('admin');
    return assertSucceeds(add('admin', rest));
  });
  test('regular user cannot append', () => assertFails(add('alice', entry('alice'))));
  test('volunteer cannot append', () => assertFails(add('vol', entry('vol'))));
  test('signed-out cannot append', () => assertFails(add(null, entry('admin'))));
  test('admin cannot log as someone else', () => assertFails(add('admin', entry('super'))));
  test('client-chosen time is rejected', () =>
    assertFails(add('admin', entry('admin', { at: Timestamp.fromDate(new Date('2020-01-01')) }))));
  test('extra fields are rejected', () =>
    assertFails(add('admin', entry('admin', { role: 'superAdmin' }))));
  test('missing docId is rejected', () => {
    const { docId, ...rest } = entry('admin');
    return assertFails(add('admin', rest));
  });
  test('missing at is rejected', () => {
    const { at, ...rest } = entry('admin');
    return assertFails(add('admin', rest));
  });
  test('action over 64 chars is rejected', () =>
    assertFails(add('admin', entry('admin', { action: 'x'.repeat(65) }))));
  test('action of 64 chars is accepted', () =>
    assertSucceeds(add('admin', entry('admin', { action: 'x'.repeat(64) }))));
  test('collection over 64 chars is rejected', () =>
    assertFails(add('admin', entry('admin', { collection: 'c'.repeat(65) }))));
  test('docId over 128 chars is rejected', () =>
    assertFails(add('admin', entry('admin', { docId: 'd'.repeat(129) }))));
  test('summary over 500 chars is rejected', () =>
    assertFails(add('admin', entry('admin', { summary: 's'.repeat(501) }))));
  test('summary of 500 chars is accepted', () =>
    assertSucceeds(add('admin', entry('admin', { summary: 's'.repeat(500) }))));
  test('non-string action is rejected', () =>
    assertFails(add('admin', entry('admin', { action: 42 }))));
  test('non-string summary is rejected', () =>
    assertFails(add('admin', entry('admin', { summary: ['a'] }))));
  test('admin can create with a chosen id too', () =>
    assertSucceeds(setDoc(doc(db('admin'), 'admin_audit/mine'), entry('admin'))));
});

describe('admin_audit / read', () => {
  test('admin can read an entry', () => assertSucceeds(getDoc(doc(db('admin'), 'admin_audit/existing'))));
  test('superAdmin can list latest entries', () =>
    assertSucceeds(getDocs(query(collection(db('super'), 'admin_audit'), orderBy('at', 'desc'), limit(200)))));
  test('regular user cannot read', () => assertFails(getDoc(doc(db('alice'), 'admin_audit/existing'))));
  test('volunteer cannot list', () => assertFails(getDocs(collection(db('vol'), 'admin_audit'))));
  test('signed-out cannot read', () => assertFails(getDoc(doc(db(null), 'admin_audit/existing'))));
});

describe('admin_audit / append-only', () => {
  test('admin cannot edit an entry', () =>
    assertFails(updateDoc(doc(db('admin'), 'admin_audit/existing'), { summary: 'nothing happened' })));
  test('superAdmin cannot edit an entry', () =>
    assertFails(updateDoc(doc(db('super'), 'admin_audit/existing'), { summary: 'x' })));
  test('admin cannot delete an entry', () => assertFails(deleteDoc(doc(db('admin'), 'admin_audit/existing'))));
  test('superAdmin cannot delete an entry', () => assertFails(deleteDoc(doc(db('super'), 'admin_audit/existing'))));
  test('admin cannot overwrite an entry with set', () =>
    assertFails(setDoc(doc(db('admin'), 'admin_audit/existing'), entry('admin'))));
});
