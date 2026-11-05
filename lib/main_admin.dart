// Entry point for the desktop web admin panel.
//
//   flutter run -d chrome -t lib/main_admin.dart
//   flutter build web -t lib/main_admin.dart --output build/admin
//
// Shares models, theme and Firebase project with the mobile app; access is
// enforced by firestore.rules (admin / superAdmin role on users/{uid}).
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'admin_web/admin_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminWebApp());
}
