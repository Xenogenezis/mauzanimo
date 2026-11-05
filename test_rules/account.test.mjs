// Account deletion / data export rules tests. Run: cd test_rules && npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails, assertSucceeds, initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs,
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
    await setDoc(doc(f, 'users/alice'), { name: 'Alice', role: 'adopter', phone: '5123' });
    await setDoc(doc(f, 'users/bob'), { name: 'Bob', role: 'adopter' });
    await setDoc(doc(f, 'users/admin'), { name: 'Ada', role: 'admin' });
    await setDoc(doc(f, 'users/super'), { name: 'Sam', role: 'superAdmin' });
    await setDoc(doc(f, 'favourites/fa'), { userId: 'alice', petId: 'p1' });
    await setDoc(doc(f, 'favourites/fb'), { userId: 'bob', petId: 'p1' });
    await setDoc(doc(f, 'pets/pa'), { name: 'Rex', status: 'available', uploadedBy: 'alice' });
    await setDoc(doc(f, 'lostfound/la'), { userId: 'alice', type: 'Lost' });
    await setDoc(doc(f, 'sightings/sa'), { reporterId: 'alice', status: 'open', geo: new GeoPoint(-20, 57.5) });
    await setDoc(doc(f, 'stories/sta'), { userId: 'alice', story: 'yay' });
    await setDoc(doc(f, 'pet_updates/ua'), { userId: 'alice', text: 'growing' });
    await setDoc(doc(f, 'event_registrations/ea'), { userId: 'alice', status: 'registered' });
    await setDoc(doc(f, 'user_gamification/alice'), { totalPoints: 10, showOnLeaderboard: true });
    await setDoc(doc(f, 'user_gamification/alice/impact_history/h1'), { points: 10 });
    await setDoc(doc(f, 'adoptions/aa'), { adopterId: 'alice', currentStage: 'application' });
    await setDoc(doc(f, 'fosters/fo'), { fosterUserId: 'alice', status: 'pending' });
    await setDoc(doc(f, 'inquiries/ia'), { userId: 'alice', status: 'pending' });
    await setDoc(doc(f, 'pending_users/x'), { email: 'x@y.mu' });
  });
});

describe('users: self-deletion', () => {
  test('a user can delete their own profile', () =>
    assertSucceeds(deleteDoc(doc(db('alice'), 'users/alice'))));
  test('a user cannot delete someone else\'s profile', () =>
    assertFails(deleteDoc(doc(db('alice'), 'users/bob'))));
  test('signed-out callers cannot delete profiles', () =>
    assertFails(deleteDoc(doc(db(null), 'users/alice'))));
  test('an admin (not super) still cannot delete profiles', () =>
    assertFails(deleteDoc(doc(db('admin'), 'users/alice'))));
  test('a superAdmin can still delete profiles', () =>
    assertSucceeds(deleteDoc(doc(db('super'), 'users/alice'))));
  test('a user can read their own profile for export', () =>
    assertSucceeds(getDoc(doc(db('alice'), 'users/alice'))));
  test('self-deletion did not open role escalation', () =>
    assertFails(updateDoc(doc(db('alice'), 'users/alice'), { role: 'admin' })));
});

describe('pending_users: admin only (unchanged)', () => {
  test('users cannot read pending_users', () =>
    assertFails(getDoc(doc(db('alice'), 'pending_users/x'))));
  test('users cannot delete pending_users', () =>
    assertFails(deleteDoc(doc(db('alice'), 'pending_users/x'))));
  test('admins can manage pending_users', () =>
    assertSucceeds(deleteDoc(doc(db('admin'), 'pending_users/x'))));
});

describe('favourites: own docs', () => {
  test('owner can list and delete their favourites', async () => {
    const snap = await assertSucceeds(getDocs(query(collection(db('alice'), 'favourites'), where('userId', '==', 'alice'))));
    for (const d of snap.docs) await assertSucceeds(deleteDoc(d.ref));
  });
  test('cannot delete another user\'s favourite', () =>
    assertFails(deleteDoc(doc(db('alice'), 'favourites/fb'))));
  test('cannot list another user\'s favourites', () =>
    assertFails(getDocs(query(collection(db('alice'), 'favourites'), where('userId', '==', 'bob')))));
});

// Documents the deletion plan in lib/utils/account_data.dart against the
// current rules of blocks this feature does not own.
describe('account deletion plan vs other blocks', () => {
  test('delete own pet', () => assertSucceeds(deleteDoc(doc(db('alice'), 'pets/pa'))));
  test('delete own lost & found post', () => assertSucceeds(deleteDoc(doc(db('alice'), 'lostfound/la'))));
  test('delete own sighting', () => assertSucceeds(deleteDoc(doc(db('alice'), 'sightings/sa'))));
  test('delete own story', () => assertSucceeds(deleteDoc(doc(db('alice'), 'stories/sta'))));
  test('delete own pet update', () => assertSucceeds(deleteDoc(doc(db('alice'), 'pet_updates/ua'))));
  // Owner-delete of event_registrations / user_gamification is decided by
  // other blocks; the app falls back to these writes when delete is denied.
  test('event registration: owner can cancel', () =>
    assertSucceeds(updateDoc(doc(db('alice'), 'event_registrations/ea'), { status: 'cancelled', cancelledAt: serverTimestamp() })));
  test('gamification: owner can anonymise the doc', () =>
    assertSucceeds(updateDoc(doc(db('alice'), 'user_gamification/alice'), {
      showOnLeaderboard: false, recentActions: [], certificates: [], lastWeekSummary: null,
    })));
  test('gamification: owner can delete impact history', () =>
    assertSucceeds(deleteDoc(doc(db('alice'), 'user_gamification/alice/impact_history/h1'))));
  test('owner can read own adoptions / fosters / inquiries for export', async () => {
    await assertSucceeds(getDocs(query(collection(db('alice'), 'adoptions'), where('adopterId', '==', 'alice'))));
    await assertSucceeds(getDocs(query(collection(db('alice'), 'fosters'), where('fosterUserId', '==', 'alice'))));
    await assertSucceeds(getDocs(query(collection(db('alice'), 'inquiries'), where('userId', '==', 'alice'))));
  });
  test('cannot export someone else\'s adoptions', () =>
    assertFails(getDocs(query(collection(db('bob'), 'adoptions'), where('adopterId', '==', 'alice')))));
  test('export queries on public collections succeed', async () => {
    await assertSucceeds(getDocs(query(collection(db('alice'), 'pets'), where('uploadedBy', '==', 'alice'))));
    await assertSucceeds(getDocs(query(collection(db('alice'), 'lostfound'), where('userId', '==', 'alice'))));
    await assertSucceeds(getDocs(query(collection(db('alice'), 'sightings'), where('reporterId', '==', 'alice'))));
    await assertSucceeds(getDocs(query(collection(db('alice'), 'event_registrations'), where('userId', '==', 'alice'))));
  });
});
