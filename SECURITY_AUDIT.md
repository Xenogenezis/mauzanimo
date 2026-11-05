# MauZanimo security audit — 5 November 2026

Scope: `firestore.rules`, Dart client code in `lib/`, platform config
(Android/iOS/web), committed secrets, and the new web admin and VPS deploy.

Rules fixes are verified by Firestore emulator tests in `test_rules/`
(`cd test_rules && npm install && npm test`; `rules.test.mjs` alone has 122).

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

## Rules hardening (Nov 2026)

Schema checks for every user-writable collection except `users`, `pending_users`
and `favourites`. The field lists come from what the Dart code writes and are
tested with those exact payloads.

- **Field whitelists on create** (`keys().hasOnly`) for `pets`, `pet_updates`, `reviews`,
  `inquiries`, `adoptions`, `fosters`, `lostfound`, `sightings`, `stories`,
  `rescue_reports`, `event_registrations`, `volunteers`, `user_gamification` and
  `impact_history`. Clients can't add fields such as `hidden`, `featured` or `verified`.
- **Owner field must be the caller** on create (`uploadedBy`, `userId`, `reviewerId`,
  `adopterId`, `fosterUserId`, `reporterId`). On update it is immutable, because
  non-admin updates may only change listed fields (`diff().affectedKeys().hasOnly`).
- **No backdating.** `createdAt`, `registeredAt` and `startDate` must equal
  `request.time` (server timestamp) when present. `updatedAt`, `resolvedAt` and
  `cancelledAt` must be server time when changed. `createdAt` can't be edited.
- **Length and type caps.** Pet name and story pet name 80; location 200;
  contact 60; phone 40; person names 100 (254 where the app falls back to the
  email); messages, notes and stories 5,000; captions and review comments
  2,000; sighting description 1,000 (the UI allows 500). Booleans must be bool,
  `geo` must be a GeoPoint and `accuracyMeters` a number.
- **Initial states.** New pets must be `available`. Inquiries start `pending`.
  Adoptions start at `application` with an empty `stageHistory` and no
  `rejectionReason`. Fosters have no `endDate`. Rescue reports start unassigned
  and unresolved. Registrations start `registered`.
- **Reviews:** `rating` must be an int from 1 to 5, and authors can't edit reviews.
  The app uses auto ids, so one review per user per target is **not** enforced.
  That needs a `{reviewerId}_{targetUserId}` doc id in `ReviewRepository`.
- **Moderation:** only admins can set or clear `hidden` on pets, lost & found,
  sightings, stories and reviews. Reporters also can't reopen a sighting whose
  `status` an admin set to `hidden`.
- **Narrower owner and volunteer updates:**
  - Sighting reporters may only set `open` or `resolved`.
  - Volunteers must sign triage as themselves.
  - Rescue reporters can no longer reassign the volunteer.
  - Volunteers can only claim `pending` reports for themselves, and only the
    assigned volunteer can resolve.
  - Users can cancel only a `registered` registration.
- **Gamification:** clients can't change `leaderboardRank` or `createdAt`.
  `totalPoints` can't go down or rise by more than 100 (the largest single
  action) per write. History is append-only. Points are still client-trusted
  (see next steps).
- **Left as is (public reads kept):**
  - `rescue_reports` are world-readable and include `reporterPhone`.
  - `sightings`, `rescue_reports`, `reviews` and `pet_updates` store a display
    name that falls back to the user's **email**.
  - Consider dropping the email fallback in the app, or limiting rescue reads
    to volunteers.

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

## Web hardening (VPS deploy and web admin)

**HTTP headers** (`deploy/nginx.conf`, `deploy/Caddyfile`). Caddy terminates TLS and
sends `Strict-Transport-Security` (1 year, subdomains) and strips `Server`/`Via`. nginx
(`server_tokens off`) sends the rest on every response: `X-Content-Type-Options: nosniff`,
`X-Frame-Options: DENY` + CSP `frame-ancestors 'none'`, `Referrer-Policy:
strict-origin-when-cross-origin`, `Permissions-Policy: camera=(self), geolocation=(self),
microphone=()`, and cache headers (`no-cache` for `index.html`, `flutter_bootstrap.js`,
`main.dart.js`, `version.json`, service worker and manifest, since Flutter doesn't hash
file names; one week for CanvasKit, images and fonts). Caddy only fills in the
non-CSP headers if nginx ever stops sending them.

**Content-Security-Policy.** Enforced on `/admin/`; `Content-Security-Policy-Report-Only`
on the public app. Why: the admin is the high-value target and has a small, known set
of origins; the public app shows user-supplied image URLs and more third-party
flows, and there is no `report-uri` collector yet, so a mistake there would only show
up as broken features for users. To enforce everywhere, change the `default` lines of
`$mz_csp_enforce` / `$mz_csp_report` in `nginx.conf` as its comment describes.

The policy does not need `'unsafe-inline'` or `'unsafe-eval'` for scripts: it uses
`'wasm-unsafe-eval'` (CanvasKit) and **sha256 hashes for five inline scripts**: the two
`<script>` blocks in `web/index.html` and the three loaders FlutterFire injects for
`firebase_core`, `firebase_firestore` and `firebase_auth` (they embed the Firebase JS SDK
version, currently 12.9.0). Builds use `--no-web-resources-cdn`, so CanvasKit comes from
`'self'`, not gstatic. **After editing those inline scripts in `web/index.html` or
upgrading any `firebase_*` plugin, the hashes change and the admin will stay on a blank
splash screen.** Re-check before deploying:

```bash
flutter build web --release -t lib/main_admin.dart --no-web-resources-cdn
NODE_PATH=$(npm root -g) node deploy/csp_check.cjs build/web deploy/nginx.conf
```

It loads the build in headless Chromium with the policy injected as `<meta>` and prints
every CSP violation plus the hash of each inline script on the page (exit code 1 on
violations). Verified 5 Nov 2026: **0 violations** for the admin build. Without network
access Firebase never initialises, so the check covers bootstrap, CanvasKit and the
Firebase loaders, not Firestore/Auth traffic, fonts or map tiles after sign-in: watch
the browser console on the first real deploy. Known limit: CanvasKit fetches network
images with XHR, so an image hosted outside `connect-src` (e.g. an event `imageUrl` on
some other site) won't display. Base64 images and Google-hosted ones are fine.

Suggestions for `web/index.html` (not changed here): move the two inline scripts to a
file such as `web/boot.js` so no hashes are needed for them, and set
`window.flutterfire_ignore_scripts` with explicit `<script type="module">` Firebase
imports to drop the FlutterFire hashes.

**Admin audit log.** Every write the web admin makes (status/stage changes, role
changes, deletes, new events, and the pet status that follows an adoption stage) adds an
entry to `admin_audit` (`actorUid`, `action`, `collection`, `docId`, optional `summary`,
`at`). Rules: only admins create, only for themselves, with `at == request.time`; admins
read; nobody updates or deletes (append-only; tested in `test_rules/admin_audit.test.mjs`).
Logging is best effort and never blocks the admin action. The admin's "Audit log"
section lists the latest 200 entries with a filter by action. Note that an admin could
still skip logging by writing to Firestore directly; a tamper-proof trail needs Cloud
Functions triggers (Blaze plan).

**Idle sign-out.** The web admin signs out after 30 minutes without pointer or keyboard
input, after a 60-second "Still there?" countdown (`lib/admin_web/session_timeout.dart`).
