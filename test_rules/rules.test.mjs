// Firestore security rules tests. Run: cd test_rules && npm install && npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails, assertSucceeds, initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, query, where, getDocs,
  GeoPoint, serverTimestamp, Timestamp, arrayUnion,
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
    // Field is `totalPoints` in the app (UserGamification.toMap); `points`
    // is not a field of this doc and the whitelist now rejects it.
    await assertSucceeds(setDoc(doc(db('alice'), 'user_gamification/alice'), { userId: 'alice', totalPoints: 0 }));
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

// ---------------------------------------------------------------------------
// Rules hardening (Nov 2026): whitelists, owner/createdAt immutability,
// length caps, admin moderation. "app payload" tests copy the exact maps the
// Dart code writes (serverTimestamp() for FieldValue.serverTimestamp()).
// ---------------------------------------------------------------------------
const seed = (path, data) => env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), path), data));
const past = Timestamp.fromDate(new Date('2020-01-01T00:00:00Z'));
const img = 'data:image/jpeg;base64,' + 'A'.repeat(1000);

describe('hardening: pets', () => {
  // upload_pet_screen.dart
  const upload = (uid, extra = {}) => ({
    name: 'Rex', type: 'Dog', location: 'Grand Baie', description: 'Friendly', imageUrl: img,
    age: '2 years', gender: 'Male', vaccinated: true, sterilized: false, dewormed: true,
    status: 'available', contact: '57123456', uploadedBy: uid, isUserUpload: true,
    createdAt: serverTimestamp(), ...extra,
  });
  test('app payload: upload_pet_screen create succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'pets'), upload('alice'))));
  test('app payload: Pet.toMap (PetRepository.addPet) succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'pets'), {
      name: 'Rex', type: 'Dog', location: 'Port Louis', description: '', imageUrl: null, age: '1',
      gender: 'Female', vaccinated: false, sterilized: false, dewormed: false, status: 'available',
      contact: '', uploadedBy: 'alice', uploaderEmail: null, isUserUpload: true, adoptionFee: null,
    })));
  test('extra field rejected (incl. hidden on create)', async () => {
    await assertFails(addDoc(collection(db('alice'), 'pets'), upload('alice', { featured: true })));
    await assertFails(addDoc(collection(db('alice'), 'pets'), upload('alice', { hidden: false })));
  });
  test('owner spoofing rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'pets'), upload('bob'))));
  test('createdAt spoofing rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'pets'), upload('alice', { createdAt: past }))));
  test('oversize name rejected', () =>
    assertFails(addDoc(collection(db('alice'), 'pets'), upload('alice', { name: 'x'.repeat(81) }))));
  test('oversize location / contact rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'pets'), upload('alice', { location: 'x'.repeat(201) })));
    await assertFails(addDoc(collection(db('alice'), 'pets'), upload('alice', { contact: '5'.repeat(61) })));
  });
  test('wrong types rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'pets'), upload('alice', { vaccinated: 'yes' })));
    await assertFails(addDoc(collection(db('alice'), 'pets'), upload('alice', { name: 42 })));
  });
  test('cannot create a pet already adopted', () =>
    assertFails(addDoc(collection(db('alice'), 'pets'), upload('alice', { status: 'adopted' }))));
  test('app payload: owner edit (edit_pet_screen) succeeds', () =>
    assertSucceeds(updateDoc(doc(db('bob'), 'pets/p1'), {
      name: 'Rexy', type: 'Dog', location: 'Flic en Flac', description: 'Calm', age: '3',
      gender: 'Male', contact: '57000000', vaccinated: true, sterilized: true, dewormed: true,
    })));
  test('app payload: owner marks adopted (my_pets_screen) succeeds', () =>
    assertSucceeds(updateDoc(doc(db('bob'), 'pets/p1'), { status: 'adopted' })));
  test('owner cannot hand the pet to someone else (uploadedBy immutable)', () =>
    assertFails(updateDoc(doc(db('bob'), 'pets/p1'), { uploadedBy: 'alice' })));
  test('owner cannot rewrite createdAt', () =>
    assertFails(updateDoc(doc(db('bob'), 'pets/p1'), { createdAt: past })));
  test('admin can set hidden', () =>
    assertSucceeds(updateDoc(doc(db('admin'), 'pets/p1'), { hidden: true })));
});

describe('hardening: pet_updates and reviews', () => {
  // PetUpdate.toMap
  const upd = (uid, extra = {}) => ({ petId: 'p1', userId: uid, userName: 'Alice', imageUrl: null, caption: 'Settling in', createdAt: serverTimestamp(), ...extra });
  test('app payload: pet update succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'pet_updates'), upd('alice'))));
  test('pet update: extra field / spoofing / long caption rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'pet_updates'), upd('alice', { pinned: true })));
    await assertFails(addDoc(collection(db('alice'), 'pet_updates'), upd('bob')));
    await assertFails(addDoc(collection(db('alice'), 'pet_updates'), upd('alice', { caption: 'x'.repeat(2001) })));
  });
  test('pet update: owner cannot move it to another pet', async () => {
    await seed('pet_updates/u1', { petId: 'p1', userId: 'alice', caption: 'hi' });
    await assertFails(updateDoc(doc(db('alice'), 'pet_updates/u1'), { petId: 'p2' }));
    await assertSucceeds(updateDoc(doc(db('alice'), 'pet_updates/u1'), { caption: 'hello' }));
  });

  // Review.toMap
  const rev = (uid, extra = {}) => ({ reviewerId: uid, reviewerName: 'Alice', targetUserId: 'bob', rating: 5, comment: null, createdAt: serverTimestamp(), ...extra });
  test('app payload: review succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'reviews'), rev('alice'))));
  test('review: rating must be an int 1..5', async () => {
    await assertFails(addDoc(collection(db('alice'), 'reviews'), rev('alice', { rating: 6 })));
    await assertFails(addDoc(collection(db('alice'), 'reviews'), rev('alice', { rating: 0 })));
    await assertFails(addDoc(collection(db('alice'), 'reviews'), rev('alice', { rating: 4.5 })));
    await assertFails(addDoc(collection(db('alice'), 'reviews'), rev('alice', { rating: '5' })));
  });
  test('review: spoofing / self-review / extra field / long comment / backdating rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'reviews'), rev('bob')));
    await assertFails(addDoc(collection(db('alice'), 'reviews'), rev('alice', { targetUserId: 'alice' })));
    await assertFails(addDoc(collection(db('alice'), 'reviews'), rev('alice', { verified: true })));
    await assertFails(addDoc(collection(db('alice'), 'reviews'), rev('alice', { hidden: false })));
    await assertFails(addDoc(collection(db('alice'), 'reviews'), rev('alice', { comment: 'x'.repeat(2001) })));
    await assertFails(addDoc(collection(db('alice'), 'reviews'), rev('alice', { createdAt: past })));
  });
});

describe('hardening: inquiries, adoptions, fosters', () => {
  // adoption_inquiry_screen.dart
  const inq = (uid, extra = {}) => ({
    petId: 'p1', petName: 'Rex', applicantName: 'Alice', email: 'a@x.mu', phone: '57123456',
    message: 'I have a garden', status: 'pending', createdAt: serverTimestamp(), userId: uid, ...extra,
  });
  test('app payload: inquiry succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'inquiries'), inq('alice'))));
  test('app payload: inquiry for a pet with no name succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'inquiries'), inq('alice', { petName: null }))));
  test('inquiry: pre-approved / spoofed / extra / oversize rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'inquiries'), inq('alice', { status: 'approved' })));
    await assertFails(addDoc(collection(db('alice'), 'inquiries'), inq('bob')));
    await assertFails(addDoc(collection(db('alice'), 'inquiries'), inq('alice', { priority: 1 })));
    await assertFails(addDoc(collection(db('alice'), 'inquiries'), inq('alice', { message: 'x'.repeat(5001) })));
  });

  // Adoption.toMap
  const adoption = (uid, extra = {}) => ({
    petId: 'p1', petName: 'Rex', adopterId: uid, adopterName: 'Alice', adopterEmail: 'a@x.mu',
    adopterPhone: '57123456', currentStage: 'application', stageHistory: [],
    createdAt: serverTimestamp(), rejectionReason: null, ...extra,
  });
  test('app payload: adoption succeeds', () =>
    assertSucceeds(setDoc(doc(db('alice'), 'adoptions/new1'), adoption('alice'))));
  test('adoption: spoofed / pre-filled history / backdated / extra rejected', async () => {
    await assertFails(setDoc(doc(db('alice'), 'adoptions/n2'), adoption('bob')));
    await assertFails(setDoc(doc(db('alice'), 'adoptions/n3'), adoption('alice', {
      stageHistory: [{ stage: 'approved', timestamp: Timestamp.now(), notes: null, changedBy: 'Admin' }],
    })));
    await assertFails(setDoc(doc(db('alice'), 'adoptions/n4'), adoption('alice', { createdAt: past })));
    await assertFails(setDoc(doc(db('alice'), 'adoptions/n5'), adoption('alice', { feeWaived: true })));
  });
  test('adoption: adopter cannot advance their own stage', () =>
    assertFails(updateDoc(doc(db('alice'), 'adoptions/a1'), { currentStage: 'approved' })));

  // Foster.toMap
  const foster = (uid, extra = {}) => ({
    petId: 'p1', petName: 'Rex', fosterUserId: uid, fosterUserName: 'Alice', startDate: serverTimestamp(),
    endDate: null, status: 'pending', notes: 'Motivation: x\nExperience: y\nAvailability: z',
    createdAt: serverTimestamp(), ...extra,
  });
  test('app payload: foster application succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'fosters'), foster('alice'))));
  test('foster: spoofed / ended / extra / long notes rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'fosters'), foster('bob')));
    await assertFails(addDoc(collection(db('alice'), 'fosters'), foster('alice', { endDate: Timestamp.now() })));
    await assertFails(addDoc(collection(db('alice'), 'fosters'), foster('alice', { approved: true })));
    await assertFails(addDoc(collection(db('alice'), 'fosters'), foster('alice', { notes: 'x'.repeat(5001) })));
  });
});

describe('hardening: lostfound, stories', () => {
  // add_lost_found_screen.dart
  const lf = (uid, extra = {}) => ({
    type: 'Lost', animalType: 'Dog', description: 'Brown dog, red collar', location: 'Trou aux Biches',
    contact: '57123456', imageUrl: img, geo: new GeoPoint(-20.03, 57.55), userId: uid,
    createdAt: serverTimestamp(), ...extra,
  });
  test('app payload: lost & found post succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'lostfound'), lf('alice'))));
  test('app payload: LostFound.toMap via repository succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'lostfound'), {
      type: 'Found', animalType: 'Cat', description: 'd', location: 'l', contact: 'c', imageUrl: null,
      userId: 'alice', createdAt: serverTimestamp(),
    })));
  test('lost & found: extra / future-dated / oversize contact+location rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'lostfound'), lf('alice', { hidden: false })));
    await assertFails(addDoc(collection(db('alice'), 'lostfound'), lf('alice', { createdAt: Timestamp.fromDate(new Date('2099-01-01')) })));
    await assertFails(addDoc(collection(db('alice'), 'lostfound'), lf('alice', { contact: '5'.repeat(61) })));
    await assertFails(addDoc(collection(db('alice'), 'lostfound'), lf('alice', { location: 'x'.repeat(201) })));
  });
  test('lost & found: owner edit (edit_lost_found_screen) succeeds; userId/createdAt immutable', async () => {
    await seed('lostfound/lf1', { type: 'Lost', userId: 'alice', createdAt: past, description: 'x' });
    await assertSucceeds(updateDoc(doc(db('alice'), 'lostfound/lf1'), {
      type: 'Found', animalType: 'Dog', description: 'Found him', location: 'Grand Baie', contact: '57123456',
      imageUrl: '', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db('alice'), 'lostfound/lf1'), { userId: 'bob' }));
    await assertFails(updateDoc(doc(db('alice'), 'lostfound/lf1'), { createdAt: Timestamp.now() }));
    await assertFails(updateDoc(doc(db('alice'), 'lostfound/lf1'), { updatedAt: past }));
  });

  // add_story_screen.dart / edit_story_screen.dart
  const story = (uid, extra = {}) => ({ petName: 'Rex', adopterName: 'Alice', story: 'He loves the beach', imageUrl: '', userId: uid, createdAt: serverTimestamp(), ...extra });
  test('app payload: story create succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'stories'), story('alice'))));
  test('story: spoofed / extra / oversize rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'stories'), story('bob')));
    await assertFails(addDoc(collection(db('alice'), 'stories'), story('alice', { featured: true })));
    await assertFails(addDoc(collection(db('alice'), 'stories'), story('alice', { story: 'x'.repeat(5001) })));
    await assertFails(addDoc(collection(db('alice'), 'stories'), story('alice', { petName: 'x'.repeat(81) })));
  });
  test('story: owner edit (edit_story_screen) succeeds; userId immutable', async () => {
    await seed('stories/st1', { petName: 'Rex', story: 'a', userId: 'alice', createdAt: past });
    await assertSucceeds(updateDoc(doc(db('alice'), 'stories/st1'), {
      petName: 'Rex', adopterName: 'Alice', story: 'Updated', imageUrl: '', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db('alice'), 'stories/st1'), { userId: 'bob' }));
  });
});

describe('hardening: sightings', () => {
  // Sighting.toMap (report_sighting_screen.dart)
  const sighting = (uid, extra = {}) => ({
    reporterId: uid, reporterName: 'Alice', animalType: 'Dog', description: 'Limping near the bus stop',
    imageUrl: img, geo: new GeoPoint(-20.01, 57.58), accuracyMeters: 12.5, manuallyPlaced: false,
    locationLabel: null, lostReportId: null, status: 'open', createdAt: serverTimestamp(), ...extra,
  });
  test('app payload: sighting succeeds (GPS and manual pin)', async () => {
    await assertSucceeds(addDoc(collection(db('alice'), 'sightings'), sighting('alice')));
    await assertSucceeds(addDoc(collection(db('alice'), 'sightings'), sighting('alice', { accuracyMeters: null, manuallyPlaced: true, locationLabel: 'Market', lostReportId: 'lf1' })));
  });
  test('sighting: extra / spoofed / backdated / oversize / wrong type rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'sightings'), sighting('alice', { handledBy: 'alice' })));
    await assertFails(addDoc(collection(db('alice'), 'sightings'), sighting('alice', { hidden: false })));
    await assertFails(addDoc(collection(db('alice'), 'sightings'), sighting('bob')));
    await assertFails(addDoc(collection(db('alice'), 'sightings'), sighting('alice', { createdAt: past })));
    await assertFails(addDoc(collection(db('alice'), 'sightings'), sighting('alice', { description: 'x'.repeat(1001) })));
    await assertFails(addDoc(collection(db('alice'), 'sightings'), sighting('alice', { manuallyPlaced: 'no' })));
  });
  test('app payload: reporter marks resolved (SightingRepository.setStatus)', () =>
    assertSucceeds(updateDoc(doc(db('bob'), 'sightings/s1'), { status: 'resolved', updatedAt: serverTimestamp() })));
  test('reporter cannot hide, move the pin, or re-assign the sighting', async () => {
    await assertFails(updateDoc(doc(db('bob'), 'sightings/s1'), { status: 'hidden' }));
    await assertFails(updateDoc(doc(db('bob'), 'sightings/s1'), { geo: new GeoPoint(0, 0) }));
    await assertFails(updateDoc(doc(db('bob'), 'sightings/s1'), { reporterId: 'alice' }));
  });
  test('reporter cannot reopen a sighting hidden by status moderation', async () => {
    await seed('sightings/s2', { reporterId: 'bob', status: 'hidden', geo: new GeoPoint(-20, 57.5) });
    await assertFails(updateDoc(doc(db('bob'), 'sightings/s2'), { status: 'open' }));
  });
  test('volunteer cannot sign triage as someone else', () =>
    assertFails(updateDoc(doc(db('vol'), 'sightings/s1'), { status: 'resolved', handledBy: 'admin' })));
});

describe('hardening: moderation flag `hidden` (admin only)', () => {
  // [collection, docId, owner, seed data] for each moderated collection.
  const cases = [
    ['pets', 'mp', 'bob', { name: 'Rex', status: 'available', uploadedBy: 'bob' }],
    ['lostfound', 'ml', 'bob', { type: 'Lost', userId: 'bob' }],
    ['sightings', 'ms', 'bob', { reporterId: 'bob', status: 'open', geo: new GeoPoint(-20, 57.5) }],
    ['stories', 'mt', 'bob', { story: 'yay', userId: 'bob' }],
    ['reviews', 'mr', 'bob', { reviewerId: 'bob', targetUserId: 'alice', rating: 4 }],
  ];
  for (const [col, id, owner, data] of cases) {
    test(`${col}: owner cannot set hidden`, async () => {
      await seed(`${col}/${id}`, data);
      await assertFails(updateDoc(doc(db(owner), `${col}/${id}`), { hidden: true }));
    });
    test(`${col}: owner cannot un-hide after admin hid it; admin can`, async () => {
      await seed(`${col}/${id}`, data);
      await assertSucceeds(updateDoc(doc(db('admin'), `${col}/${id}`), { hidden: true }));
      await assertFails(updateDoc(doc(db(owner), `${col}/${id}`), { hidden: false }));
      await assertFails(updateDoc(doc(db('vol'), `${col}/${id}`), { hidden: false }));
      await assertSucceeds(updateDoc(doc(db('super'), `${col}/${id}`), { hidden: false }));
    });
  }
  test('reviews: author cannot edit their review', async () => {
    await seed('reviews/mr', { reviewerId: 'bob', targetUserId: 'alice', rating: 1 });
    await assertFails(updateDoc(doc(db('bob'), 'reviews/mr'), { rating: 5 }));
  });
  test('pets: an adopter flagging pending cannot touch hidden', async () => {
    await seed('pets/mp', { status: 'available', uploadedBy: 'bob', hidden: true });
    await assertFails(updateDoc(doc(db('alice'), 'pets/mp'), { status: 'pending', hidden: false }));
  });
});

describe('hardening: rescue reports', () => {
  // RescueReport.toMap (rescue_report_screen.dart)
  const report = (uid, extra = {}) => ({
    description: 'Injured dog', location: 'Pereybere', animalType: 'Dog', urgency: 'high', status: 'pending',
    imageUrl: null, reporterId: uid, reporterName: 'Alice', reporterPhone: '57123456',
    assignedVolunteerId: null, assignedVolunteerName: null, createdAt: serverTimestamp(), resolvedAt: null, ...extra,
  });
  test('app payload: rescue report succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'rescue_reports'), report('alice'))));
  test('rescue: spoofed / pre-assigned / extra / backdated rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'rescue_reports'), report('bob')));
    await assertFails(addDoc(collection(db('alice'), 'rescue_reports'), report('alice', { status: 'assigned', assignedVolunteerId: 'vol' })));
    await assertFails(addDoc(collection(db('alice'), 'rescue_reports'), report('alice', { priority: 1 })));
    await assertFails(addDoc(collection(db('alice'), 'rescue_reports'), report('alice', { createdAt: past })));
  });
  test('volunteer cannot assign someone else', () =>
    assertFails(updateDoc(doc(db('vol'), 'rescue_reports/r1'), { status: 'assigned', assignedVolunteerId: 'alice', assignedVolunteerName: 'A' })));
  test('app payload: assigned volunteer resolves (rescue_list_screen)', async () => {
    await seed('rescue_reports/r2', { reporterId: 'bob', status: 'assigned', assignedVolunteerId: 'vol', description: 'x' });
    await assertSucceeds(updateDoc(doc(db('vol'), 'rescue_reports/r2'), { status: 'resolved', resolvedAt: serverTimestamp() }));
  });
  test('another volunteer cannot resolve or re-take an assigned report', async () => {
    await seed('users/vol2', { role: 'volunteer' });
    await seed('rescue_reports/r2', { reporterId: 'bob', status: 'assigned', assignedVolunteerId: 'vol', description: 'x' });
    await assertFails(updateDoc(doc(db('vol2'), 'rescue_reports/r2'), { status: 'resolved', resolvedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db('vol2'), 'rescue_reports/r2'), { status: 'assigned', assignedVolunteerId: 'vol2', assignedVolunteerName: 'V2' }));
  });
  test('reporter can edit text but not ownership or volunteer', async () => {
    await assertFails(updateDoc(doc(db('bob'), 'rescue_reports/r1'), { reporterId: 'alice' }));
    await assertFails(updateDoc(doc(db('bob'), 'rescue_reports/r1'), { assignedVolunteerId: 'bob' }));
    await assertSucceeds(updateDoc(doc(db('bob'), 'rescue_reports/r1'), { description: 'Hurt dog, left paw' }));
  });
});

describe('hardening: events, volunteers', () => {
  // EventRepository.registerForEvent
  const reg = (uid, extra = {}) => ({ eventId: 'ev1', userId: uid, userName: 'Alice', userEmail: 'a@x.mu', userPhone: null, registeredAt: serverTimestamp(), status: 'registered', ...extra });
  test('app payload: event registration succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'event_registrations'), reg('alice'))));
  test('registration: attended / spoofed / extra / backdated rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'event_registrations'), reg('alice', { status: 'attended' })));
    await assertFails(addDoc(collection(db('alice'), 'event_registrations'), reg('bob')));
    await assertFails(addDoc(collection(db('alice'), 'event_registrations'), reg('alice', { vip: true })));
    await assertFails(addDoc(collection(db('alice'), 'event_registrations'), reg('alice', { registeredAt: past })));
  });
  test('registration: cannot cancel an attended registration or change the event', async () => {
    await seed('event_registrations/e2', { userId: 'alice', eventId: 'ev1', status: 'attended' });
    await assertFails(updateDoc(doc(db('alice'), 'event_registrations/e2'), { status: 'cancelled' }));
    await assertFails(updateDoc(doc(db('alice'), 'event_registrations/e1'), { status: 'cancelled', eventId: 'ev9' }));
  });
  test('non-admin cannot create events', () =>
    assertFails(addDoc(collection(db('alice'), 'events'), { title: 'Spam' })));

  // volunteer_screen.dart
  const vol = (uid, extra = {}) => ({ name: 'Alice', phone: '57123456', message: 'Weekends', userId: uid, email: 'a@x.mu', createdAt: serverTimestamp(), ...extra });
  test('app payload: volunteer sign-up succeeds', () =>
    assertSucceeds(addDoc(collection(db('alice'), 'volunteers'), vol('alice'))));
  test('volunteer sign-up: spoofed / extra / oversize rejected', async () => {
    await assertFails(addDoc(collection(db('alice'), 'volunteers'), vol('bob')));
    await assertFails(addDoc(collection(db('alice'), 'volunteers'), vol('alice', { role: 'admin' })));
    await assertFails(addDoc(collection(db('alice'), 'volunteers'), vol('alice', { name: 'x'.repeat(101) })));
  });
});

describe('hardening: user_gamification', () => {
  // GamificationRepository.getOrCreateUserGamification
  const fresh = {
    totalPoints: 0, tier: 'supporter', recentActions: [], certificates: [], lastWeekSummary: null,
    weeklySummaryViewedAt: null, showOnLeaderboard: false, leaderboardRank: 0,
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  };
  const action = { action: 'listPet', points: 50, timestamp: Timestamp.now(), description: null, relatedEntityId: null };
  test('app payload: getOrCreate succeeds', () =>
    assertSucceeds(setDoc(doc(db('alice'), 'user_gamification/alice'), fresh)));
  test('create: inflated points / rank / backdating / other userId rejected', async () => {
    await assertFails(setDoc(doc(db('alice'), 'user_gamification/alice'), { ...fresh, totalPoints: 99999 }));
    await assertFails(setDoc(doc(db('alice'), 'user_gamification/alice'), { ...fresh, leaderboardRank: 1 }));
    await assertFails(setDoc(doc(db('alice'), 'user_gamification/alice'), { ...fresh, createdAt: past }));
    await assertFails(setDoc(doc(db('alice'), 'user_gamification/alice'), { ...fresh, userId: 'bob' }));
  });
  test('app payload: recordAction (first action, doc missing) succeeds', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'user_gamification/alice'), {
      totalPoints: 50, tier: 'supporter', updatedAt: serverTimestamp(), certificates: [],
      userId: 'alice', recentActions: [{ ...action, id: 'h0' }], showOnLeaderboard: false,
      leaderboardRank: 0, createdAt: serverTimestamp(),
    }));
  });
  test('app payload: recordAction update + history, leaderboard toggle, summary viewed succeed', async () => {
    await seed('user_gamification/alice', { totalPoints: 100, tier: 'supporter', recentActions: [], certificates: [], showOnLeaderboard: false, leaderboardRank: 0, createdAt: past });
    await assertSucceeds(updateDoc(doc(db('alice'), 'user_gamification/alice'), {
      totalPoints: 150, tier: 'supporter', updatedAt: serverTimestamp(), certificates: [],
      recentActions: arrayUnion({ ...action, id: 'h1' }),
    }));
    await assertSucceeds(setDoc(doc(db('alice'), 'user_gamification/alice/impact_history/h1'), { ...action, userId: 'alice' }));
    await assertSucceeds(updateDoc(doc(db('alice'), 'user_gamification/alice'), { showOnLeaderboard: true, updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(db('alice'), 'user_gamification/alice'), { weeklySummaryViewedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  });
  test('update: point jumps, decreases, rank and createdAt changes rejected', async () => {
    await seed('user_gamification/alice', { totalPoints: 100, leaderboardRank: 0, createdAt: past });
    await assertFails(updateDoc(doc(db('alice'), 'user_gamification/alice'), { totalPoints: 100000 }));
    await assertFails(updateDoc(doc(db('alice'), 'user_gamification/alice'), { totalPoints: 50 }));
    await assertFails(updateDoc(doc(db('alice'), 'user_gamification/alice'), { leaderboardRank: 1 }));
    await assertFails(updateDoc(doc(db('alice'), 'user_gamification/alice'), { createdAt: Timestamp.now() }));
  });
  test('history is append-only with bounded points', async () => {
    await seed('user_gamification/alice/impact_history/h1', { ...action, userId: 'alice' });
    await assertFails(updateDoc(doc(db('alice'), 'user_gamification/alice/impact_history/h1'), { points: 100 }));
    await assertFails(setDoc(doc(db('alice'), 'user_gamification/alice/impact_history/h2'), { ...action, points: 5000, userId: 'alice' }));
  });
});
