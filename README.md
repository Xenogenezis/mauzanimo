# MauZanimo

**Rehome responsibly. Adopt locally.** A Flutter + Firebase app for pet rehoming
and stray-animal welfare in Mauritius, by JCI Grand Baie. Available in English,
French and Kreol Morisien.

## Features

**Mobile app (Android / iOS)**
- Pet listings with photos, health info, favourites, WhatsApp contact and sharing
- Adoption inquiries and a staged adoption workflow (application → screening → meet & greet → trial → completed)
- **Street sightings:** photograph a stray or a lost pet. GPS is captured
  automatically and the pin can be adjusted on the map. Sightings appear on a
  map with "near me" filters, and *I saw this animal* on a lost-pet report
  links the sighting to it so the owner can see where their pet was spotted.
- Lost & Found with camera photo and map pin
- Emergency rescue (SOS) reports with volunteer assignment
- Fostering, events, success stories, reviews, and points/badges with a leaderboard
- **Works offline:** recently viewed data is cached on the phone, and reports
  made without signal are queued and upload automatically when back online

**Web admin panel** (`/admin/`)
- Live overview: counts plus a map of the last 7 days of sightings and lost/found posts
- Search, filter, edit status and export CSV for pets, sightings, adoptions,
  inquiries, lost & found, rescues, fosters, events, stories, volunteers and users
- Role management (only a super admin can create admins)

## Project layout

```
lib/
  main.dart              mobile app entry
  main_admin.dart        web admin entry
  admin_web/             admin panel (tables, overview map, CSV export)
  models/ repositories/ providers/   data layer (Result<T>-based repositories)
  screens/               app screens (sightings/, lostfound/, pets/, ...)
  widgets/               shared widgets (AppImage, LocationPicker, OfflineBanner)
  utils/                 geo maths, location service, offline-first writes
  lang/app_strings.dart  all UI strings (en / fr / mfe)
firestore.rules          security rules (tested in test_rules/)
firestore.indexes.json   composite indexes
deploy/                  Dockerfile, nginx, Caddy (HTTPS), docker-compose
test/                    Dart unit and widget tests
test_rules/              Firestore rules tests (emulator)
```

## Development

```bash
flutter pub get
flutter run                                  # mobile app
flutter run -d chrome -t lib/main_admin.dart # web admin
flutter analyze
flutter test
```

Rules tests (needs Node 18+ and Java 17+):

```bash
cd test_rules && npm install && npm test
```

## Firebase

Project `stray-pets-mu`; Android and Web are configured in `lib/firebase_options.dart`.
**After changing rules or indexes, deploy them:**

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Collections: `users`, `pets`, `favourites`, `adoptions`, `inquiries`, `fosters`,
`lostfound`, `sightings`, `rescue_reports`, `stories`, `events`,
`event_registrations`, `volunteers`, `reviews`, `pet_updates`, `partners`,
`user_gamification`, `pending_users`.

To make the first admin, set `role: "superAdmin"` on your own `users/{uid}`
document in the Firebase console. After that, manage roles from the web admin.

## Deploying the web admin to a VPS

Any Linux VPS with Docker and a domain pointing at it. Data stays in Firebase;
the VPS only serves the built web files.

```bash
git clone https://github.com/Xenogenezis/mauzanimo && cd mauzanimo
cp deploy/.env.example deploy/.env      # set DOMAIN and ACME_EMAIL
./deploy/deploy.sh
```

This builds both web targets in Docker and serves them with nginx behind Caddy,
which gets HTTPS certificates automatically:

- `https://DOMAIN/` is the public web app
- `https://DOMAIN/admin/` is the admin panel

Then, in the Firebase console, add `DOMAIN` under **Authentication → Settings →
Authorized domains** so sign-in works. Run `./deploy/deploy.sh` again to update.

Without Docker: run `flutter build web -t lib/main_admin.dart --base-href /admin/ --no-web-resources-cdn`
and serve `build/web` with `deploy/nginx.conf`.

## Security

See [SECURITY_AUDIT.md](SECURITY_AUDIT.md) for the latest audit and recommended next steps.
