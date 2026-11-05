# MauZanimo security audit — 5 November 2026

Scope: `firestore.rules`, Dart client code in `lib/`, platform config
(Android/iOS/web), committed secrets, and the new web admin and VPS deploy.

Rules fixes are verified by 51 Firestore emulator tests in `test_rules/`
(`cd test_rules && npm install && npm test`).

## Fixed

| # | Severity | Finding | Fix |
|---|----------|---------|-----|
| 1 | **Critical** | Any signed-in user could set `role: 'admin'` on their own `users/{uid}` doc (rule allowed any owner update), gaining full admin over every collection. | Owners can no longer change `role`, `verificationLevel` or `badges`. Registration may only pick `adopter`/`rehomer`/`volunteer`. Only a `superAdmin` can grant or revoke admin roles. |
| 2 | High | `isAdmin()` only accepted `admin`, but the app treats `superAdmin` as admin, so super admins were blocked by the database. | `isAdmin()` accepts both roles. |
| 3 | High | Rules named `lost_found`, `success_stories`, `gamification`; the code uses `lostfound`, `stories`, `user_gamification`. Unmatched paths are denied, so Lost & Found, Success Stories and gamification were broken for everyone. | Rules now cover the real collection names. |
| 4 | High | `adoptions` and `fosters` rules checked `userId`; the documents use `adopterId` / `fosterUserId`. Users could not read their own adoptions or fosters. | Rules match the real owner fields. |
| 5 | High | Admins could not read `inquiries`, `adoptions`, `fosters` or `event_registrations` (owner-only reads). Admin screens failed. | Admin read access added. |
| 6 | Medium | `rescue_reports` allowed **any** signed-in user to update any field of any report. | Reporter or admin can edit; volunteers may only assign or resolve. |
| 7 | Medium | Adopters could set a pet's status to anything (the adoption workflow needs them to set `pending`). | Non-owners can only move `available` → `pending` and change nothing else. |
| 8 | Medium | No size limits on content. Images are base64 in documents, so a script could write ~1 MB documents in a loop and inflate the Firebase bill. | `imageUrl` capped at ~850 KB and `description` at 5,000 characters on user-writable collections. |
| 9 | Medium | Pets are publicly readable and stored `uploaderEmail`, so anyone could scrape uploaders' emails. | App no longer writes it; rules reject new emails. **Existing documents still contain it, so run a one-off cleanup (below).** |
| 10 | Medium | iOS `Info.plist` had no camera or photo-library usage text. iOS kills apps that open the camera without one, so pet uploads would crash on iPhone. | Camera, photo and location usage strings added. |
| 11 | Low | WhatsApp link built from raw user-entered contact. | Contact reduced to digits; `+230` added for local numbers. |
| 12 | Low | Writes `await`ed server acknowledgement, so SOS and sighting reports hung forever without signal. | Offline-first writes (`lib/utils/offline_write.dart`). |
| 13 | Low | Users could create foster records already `active`, adoptions already `completed`, or mark themselves `attended` at events. | Creates must start in the initial state; users can only cancel their own registration. |

## Checked and OK

- **No secrets committed.** The only keys are Firebase API keys in `firebase_options.dart` and `google-services.json`. These are public identifiers, not secrets; security comes from the rules.
- **Admin access in the app** (5-tap gesture on login) reads the role from Firestore. With finding 1 fixed, the role can't be forged, and the rules enforce access anyway.
- **User profiles** (`users/*`) are readable only by their owner and by admins.
- **The web admin** is also enforced by the rules: anyone can load the admin page, but a non-admin account sees only "not an administrator" and can't read the data.

## Recommended next steps (not done; need the Firebase console or a paid plan)

1. **Deploy the rules and indexes:** `firebase deploy --only firestore:rules,firestore:indexes`.
   None of the fixes above protect production until this is run.
2. **Restrict the API keys** in Google Cloud Console → Credentials: the Android key
   to the app's package and SHA-1, and the web key to your domain(s) as HTTP referrers.
3. **Enable Firebase App Check** (Play Integrity / App Attest / reCAPTCHA Enterprise)
   and enforce it for Firestore. It's the main defence against scripts that bypass
   the app and call the API directly (spam, scraping).
4. **Move points to a Cloud Function.** Points are calculated on the phone and written
   by the user, so anyone determined can set their own score. Fine for a fun
   leaderboard; not fine if points ever earn rewards. (Requires the Blaze plan.)
5. **Move photos to Cloud Storage.** Base64 in documents makes every list read download
   full images. Storage + thumbnails would cut bandwidth and cost. (New buckets require Blaze.)
6. **Clean up `uploaderEmail`** on existing pets. One-off, with the Admin SDK:
   ```js
   const snap = await db.collection('pets').where('uploaderEmail', '!=', null).get();
   for (const d of snap.docs) await d.ref.update({ uploaderEmail: FieldValue.delete() });
   ```
7. **Firebase Auth settings:** enable email-enumeration protection and a password
   policy, and add your VPS domain under Authentication → Settings → Authorized domains
   (needed for Google sign-in on the web admin).
8. **Moderation:** sightings and lost & found posts are public as soon as they're posted.
   The web admin can hide or delete them; consider a report-abuse button in the app.
