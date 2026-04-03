# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MauZanimo** is a Flutter mobile/web app for responsible pet rehoming in Mauritius, built by JCI Grand Baie. It connects people rehoming stray pets with local adopters.

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
```

## Architecture

### Tech Stack

- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Auth, Firestore, Cloud Storage)
- **State Management:** Provider (`LanguageProvider` for i18n)
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

**Admin access:** Long-press on the login screen icon reveals the hidden admin dashboard.

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

### Localization

All user-facing strings live in `lib/lang/app_strings.dart` as a map keyed by language code (`en`/`fr`). Access strings via `LanguageProvider` from the widget tree. The root directory contains `auto_translate.js` which uses the Anthropic Claude API to generate French translations automatically.

### Firebase / Firestore

- Primary collection: `pets` (pet profiles for adoption)
- Pet list screen uses `StreamBuilder` for real-time updates
- Pet images stored in Cloud Storage
- Firebase is configured for Android and Web; iOS/macOS/Windows/Linux require additional FlutterFire CLI setup

### Code Generation Scripts

The root directory contains ~46 Node.js `.js` scripts used to generate Dart screen files. These were used during initial development to scaffold features. The generated output lives in `lib/screens/`. Do not run these scripts unless regenerating screens from scratch — editing the generated Dart files directly is the standard workflow.
