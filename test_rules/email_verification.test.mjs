// Firestore security rules tests for account verification: email + password
// accounts must confirm their address before they can post.
// Run: cd test_rules && npm install && npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails, assertSucceeds, initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, addDoc, collection, serverTimestamp,
} from 'firebase/firestore';

let env;
const as = (uid, token) => env.authenticatedContext(uid, token).firestore();

// Token shapes Firebase Auth issues for each way of signing in.
const unverified = { email: 'a@example.com', email_verified: false, firebase: { sign_in_provider: 'password' } };
const verified = { email: 'a@example.com', email_verified: true, firebase: { sign_in_provider: 'password' } };
const phone = { phone_number: '+23055555555', firebase: { sign_in_provider: 'phone' } };
const google = { email: 'a@gmail.com', email_verified: true, firebase: { sign_in_provider: 'google.com' } };
// Facebook does not mark emails as verified.
const facebook = { email: 'a@example.com', email_verified: false, firebase: { sign_in_provider: 'facebook.com' } };
const anonymous = { firebase: { sign_in_provider: 'anonymous' } };

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
    await setDoc(doc(f, 'pets/p1'), { name: 'Rex', uploadedBy: 'bob', status: 'available' });
    await setDoc(doc(f, 'favourites/old'), { userId: 'alice', petId: 'p1' });
  });
});

const favourite = () => ({ userId: 'alice', petId: 'p1' });
const report = () => ({
  reporterId: 'alice', targetCollection: 'pets', targetId: 'p1', reason: 'spam',
  status: 'open', createdAt: serverTimestamp(),
});
const rescue = () => ({
  description: 'Injured dog', location: 'Rue Royale', animalType: 'dog', urgency: 'high',
  status: 'pending', imageUrl: null, reporterId: 'alice', reporterName: 'Alice', reporterPhone: '5555',
  assignedVolunteerId: null, assignedVolunteerName: null, createdAt: serverTimestamp(), resolvedAt: null,
});

describe('unverified email + password account', () => {
  test('cannot post anything', async () => {
    const f = as('alice', unverified);
    await assertFails(addDoc(collection(f, 'favourites'), favourite()));
    await assertFails(addDoc(collection(f, 'reports'), report()));
    await assertFails(addDoc(collection(f, 'rescue_reports'), rescue()));
  });

  test('a token with no verification claims at all is treated as unverified', async () => {
    await assertFails(addDoc(collection(as('alice', {}), 'favourites'), favourite()));
  });

  test('can still sign up: create and read its own profile', async () => {
    const f = as('newbie', unverified);
    await assertSucceeds(setDoc(doc(f, 'users/newbie'), { name: 'New', email: 'a@example.com', role: 'adopter' }));
    await assertSucceeds(getDoc(doc(f, 'users/newbie')));
    await assertSucceeds(updateDoc(doc(f, 'users/newbie'), { name: 'Newer' }));
  });

  test('can still browse public content and manage what it already has', async () => {
    const f = as('alice', unverified);
    await assertSucceeds(getDoc(doc(f, 'pets/p1')));
    await assertSucceeds(getDoc(doc(f, 'favourites/old')));
  });
});

describe('verified accounts can post', () => {
  for (const [name, token] of [['verified email', verified], ['phone', phone], ['Google', google], ['Facebook', facebook]]) {
    test(name, async () => {
      const f = as('alice', token);
      await assertSucceeds(addDoc(collection(f, 'favourites'), favourite()));
      await assertSucceeds(addDoc(collection(f, 'reports'), report()));
      await assertSucceeds(addDoc(collection(f, 'rescue_reports'), rescue()));
    });
  }

  test('anonymous sign-in does not count as verified', async () => {
    await assertFails(addDoc(collection(as('alice', anonymous), 'favourites'), favourite()));
  });

  test('verification does not let anyone post as someone else', async () => {
    await assertFails(addDoc(collection(as('mallory', verified), 'favourites'), favourite()));
  });
});
