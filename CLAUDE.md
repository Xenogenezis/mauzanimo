# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MauZanimo** is a Flutter mobile/web app for responsible pet rehoming in Mauritius. It connects people rehoming stray pets with local adopters.

- **Package name:** `stray_pets_mu`
- **Version:** 1.0.0+1
- **Tagline:** "Rehome responsibly. Adopt locally."
- **Platforms:** Android, iOS, Web, Windows, macOS, Linux

## Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Run Dart linter
flutter test             # Run tests
flutter run              # Run on connected device/emulator
flutter build apk        # Build Android APK
flutter build web        # Build web version
flutter build windows    # Build Windows desktop
flutter run -d chrome -t lib/main_admin.dart                  # Web admin panel
flutter build web -t lib/main_admin.dart --base-href /admin/  # Build web admin
cd test_rules && npm install && npm test   # Firestore rules tests (emulator; needs Java,
                                           # e.g. Android Studio's jbr/bin on PATH)
cd functions && npm install && npm test    # Cloud Function unit tests
firebase deploy --only functions           # needs the Blaze plan
firebase deploy --only firestore:rules,firestore:indexes

# Firebase Hosting (https://stray-pets-mu.web.app, admin at /admin/).
# Run from PowerShell: Git Bash rewrites the --base-href paths.
flutter build web -t lib/main.dart --release --no-web-resources-cdn --base-href / --output build/hosting
flutter build web -t lib/main_admin.dart --release --no-web-resources-cdn --base-href /admin/ --output build/hosting/admin
firebase deploy --only hosting
```

## Architecture

### Tech Stack

- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Auth, Firestore, Cloud Storage)
- **State Management:** Provider (language, theme, auth and per-feature providers)
- **Maps / GPS:** `flutter_map` with OpenStreetMap tiles (no API key), `geolocator`
- **Offline:** Firestore persistence (100 MB cache); user-facing creates use
  `writeOfflineFirst()` in `lib/utils/offline_write.dart` so they don't hang
  without signal; `OfflineBanner` (connectivity_plus) wraps the app
- **Auth:** Firebase Auth + Google Sign-in
- **Local Storage:** SharedPreferences (onboarding flag, language preference)

### App Flow

```
main() → Firebase.initializeApp() → ChangeNotifierProvider(LanguageProvider)
  └─ SplashScreen
      ├─ onboarding_done (SharedPreferences)
      │   └─ false → LanguageSelectScreen → OnboardingScreen → LoginScreen
      └─ FirebaseAuth.currentUser
          ├─ logged in → HomeScreen
          └─ not logged in → LoginScreen
```

**HomeScreen** uses bottom tab navigation: Pets | Saved | Profile, plus a drawer with Lost & Found, Events, Success Stories, Donate, Partners, Volunteer, About, Contact.

**Admin access:** tapping the login screen icon 5 times opens the in-app admin dashboard
(role `admin`/`superAdmin` required). There is also a desktop **web admin**
(`lib/main_admin.dart` → `lib/admin_web/`) built on a generic `CollectionTable`
(search, filter, inline status edit, CSV export). Access is enforced by `firestore.rules`.

**Sightings:** `sightings` collection, photo + `geo` GeoPoint, optional `lostReportId`
linking to a `lostfound` doc. Screens in `lib/screens/sightings/`.

### Directory Structure

```
lib/
├── main.dart                  # Entry point: Firebase init, LanguageProvider
├── firebase_options.dart      # Firebase config (web + Android configured)
├── theme/app_theme.dart       # Brand colors: #2A9D8F (teal), #E9C46A (gold)
├── lang/
│   ├── app_strings.dart       # All UI strings in English & French
│   └── language_provider.dart # ChangeNotifier for en/fr switching
└── screens/
    ├── auth/                  # LoginScreen, RegisterScreen
    ├── pets/                  # PetListScreen, PetDetailScreen, UploadPetScreen, etc.
    ├── adoption/              # AdoptionInquiryScreen (WhatsApp integration)
    ├── admin/                 # AdminDashboard, AddPetScreen, InquiriesScreen
    ├── lostfound/             # LostFoundScreen, AddLostFoundScreen
    ├── events/                # EventsScreen
    ├── stories/               # SuccessStoriesScreen, AddStoryScreen
    └── info/                  # About, Contact, Donate, Partners, Volunteer
```

**Rescue alerts:** volunteers/rescuers (role `volunteer` and above, shown as
"Volunteer/Rescuer") see `rescue_reports` in `RescueListScreen` and can opt in to
alerts for an area + radius (`lib/utils/rescue_alerts.dart`,
`RescueAlertsProvider`). In-app matching runs on the device and the area stays in
SharedPreferences. Phone notifications are a separate opt-in: the area and FCM
tokens go to `rescue_subscribers/{uid}` (owner-read only) and the
`notifyNearbyRescuers` Cloud Function in `functions/` sends the push when a
report with a `geo` pin is created. Keep the matching rules in
`functions/rescue_push.js` and `rescue_alerts.dart` in step.

### Localization

All user-facing strings live in `lib/lang/app_strings.dart` as a map keyed by language code (`en`, `fr`, `mfe` = Kreol Morisien). Use `AppStrings.get(key, lang)` with `lang` from `LanguageProvider`. Add every new key to all three maps, and avoid duplicate keys (the last duplicate silently wins).

### Firebase / Firestore

- Primary collection: `pets` (pet profiles for adoption)
- Pet list screen uses `StreamBuilder` for real-time updates
- Images are stored as base64 `data:` URIs inside documents (rules cap them at ~850 KB). Always render with `AppImage` (`lib/widgets/app_image.dart`), which handles both data URIs and https URLs and decodes at display size
- Collection names that matter for rules: `lostfound` (not lost_found), `stories`, `user_gamification`; owner fields: pets `uploadedBy`, adoptions `adopterId`, fosters `fosterUserId`, sightings/rescue `reporterId`
- Any rules change must keep `test_rules/` green; add a test for new access paths
- Firebase is configured for Android and Web; iOS/macOS/Windows/Linux require additional FlutterFire CLI setup

### Deployment

The live site is on Firebase Hosting; the `hosting` section of `firebase.json` mirrors the headers in `deploy/nginx.conf` (CSP enforced on `/admin/`, report-only elsewhere), so keep the two in step when the CSP changes.

`deploy/` contains a Dockerfile (builds app at `/` and admin at `/admin/`), nginx config (security headers set only at server level — never add `add_header` inside a location), Caddy for HTTPS and `deploy.sh`. See README.

### Security

See `SECURITY_AUDIT.md` for the audit and the open recommendations (App Check, API key restrictions, moving gamification to Cloud Functions).
