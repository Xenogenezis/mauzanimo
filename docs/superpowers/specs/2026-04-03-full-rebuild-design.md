# MauZanimo Full Rebuild Design

**Date:** 2026-04-03  
**Approach:** Phased MVP rebuild — three phases, each leaving the app in a shippable state.  
**Scope:** Bug fixes, architecture restructure, hardening. No new features.  
**Post-MVP (out of scope):** Google Sign-In, Firebase Cloud Storage.

---

## Target Architecture

```
lib/
├── main.dart
├── firebase_options.dart
├── theme/app_theme.dart
├── lang/                         # unchanged
├── models/                       # plain Dart data classes
│   ├── pet.dart
│   ├── lost_found.dart
│   └── user_profile.dart
├── repositories/                 # all Firebase access
│   ├── pet_repository.dart
│   ├── auth_repository.dart
│   └── lost_found_repository.dart
├── providers/                    # state + business logic
│   ├── auth_provider.dart
│   ├── pet_provider.dart
│   └── language_provider.dart   # moved from lang/
├── widgets/                      # shared reusable widgets
│   └── pet_card.dart            # moved from screens/pets/
└── screens/                      # UI only — no Firebase, no business logic
    ├── auth/
    ├── pets/
    ├── admin/
    ├── lostfound/
    ├── events/
    ├── stories/
    └── info/
```

**Rules:**
- Screens only call providers — never Firestore or Firebase Auth directly
- Repositories own all Firebase SDK calls
- Models are plain Dart classes with `fromMap`/`toMap`
- Providers expose streams/futures that screens listen to

---

## Phase 1 — Stabilize

Make the app demonstrable. No restructuring.

| # | Issue | File(s) | Fix |
|---|-------|---------|-----|
| 1 | Base64 images not displaying | `upload_pet_screen.dart`, `pet_detail_screen.dart` | Use `Image.memory` with decoded bytes for base64; `Image.network` for URLs. Add 500KB size guard before encoding. |
| 2 | Crashes after async ops | `login_screen.dart`, `register_screen.dart`, `favourites_screen.dart` | Add `if (!mounted) return` before every `Navigator` call after `await` |
| 3 | Truncated UI strings | `adoption_inquiry_screen.dart`, `upload_pet_screen.dart` | Fix cut-off strings; move all hardcoded text into `app_strings.dart` |
| 4 | Duplicate imports | `splash_screen.dart`, `drawer_menu.dart` | Remove duplicate import lines |
| 5 | Home screen rebuilds on tab switch | `home_screen.dart` | Move `_screens` list to class level |
| 6 | 46 root JS scripts | `/` | Delete all `.js` files — not part of the Flutter app |

**Exit criteria:** App runs without crashes, images display, all visible text is complete and translated.

---

## Phase 2 — Restructure

Introduce the target architecture screen by screen.

### Step 1 — Models
Create typed Dart classes for `Pet`, `UserProfile`, `LostFound` with `fromMap`/`toMap`. Replace all raw `data['field']` map access in screens.

### Step 2 — Repositories

| Repository | Owns |
|---|---|
| `PetRepository` | CRUD for pets collection, favorites |
| `AuthRepository` | sign in, register, sign out, current user |
| `LostFoundRepository` | CRUD for lost/found collection |

### Step 3 — Providers

| Provider | Replaces |
|---|---|
| `AuthProvider` | inline `FirebaseAuth` calls in login/register screens |
| `PetProvider` | `StreamBuilder` in `PetListScreen`, `MyPetsScreen` |
| `FavouritesProvider` | nested `StreamBuilder`+`FutureBuilder` in `FavouritesScreen` |

### Step 4 — Translations
Audit every screen for hardcoded strings. All text goes into `app_strings.dart`. Add a single helper method for lookups — screens never access the map directly.

### Step 5 — Input Validation
Add format validation (not just empty checks) for email, phone number, required text fields. Centralise in a `Validators` utility class.

### Step 6 — Dependency cleanup
Remove `google_sign_in` from active wiring. Keep the package in `pubspec.yaml` for post-MVP Google Sign-In.

**Exit criteria:** No screen imports `cloud_firestore` or `firebase_auth` directly — only through repositories/providers.

---

## Phase 3 — Harden

### Error Handling
- Wrap all repository calls in typed result objects (`Success`/`Failure`) — screens show meaningful error messages
- Check network connectivity before form submissions — show a snackbar instead of silently freezing

### Image Robustness
- Guard base64 decode with try/catch — show placeholder on corrupt image
- Enforce 500KB limit at the UI layer with a visible error message

### Firestore Query Safety
- Replace client-side pet search (loads all docs into memory) with server-side `where` + `orderBy` queries
- Add `.where('uploadedBy', isEqualTo: uid)` to `MyPetsScreen` (currently client-side filtered)

### Tests — critical paths only

| What | Type |
|---|---|
| `PetRepository` CRUD | Unit test with Firestore emulator |
| `AuthRepository` sign in / register | Unit test |
| `Pet.fromMap` / `toMap` | Unit test |
| `PetListScreen` loads and displays pets | Widget test |
| `LoginScreen` shows error on bad credentials | Widget test |

### Accessibility
Replace all 19 `GestureDetector` tap handlers with `InkWell` or proper button widgets.

**Exit criteria:** No silent failures, search works at scale, critical paths have test coverage.

---

## Out of Scope (Post-MVP)
- Google Sign-In integration
- Firebase Cloud Storage for images (currently: URL or base64 in Firestore)
- CI/CD pipeline
- Additional languages beyond English and French
