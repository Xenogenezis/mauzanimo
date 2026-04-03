import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/firebase_options.dart';
import 'package:stray_pets_mu/screens/splash_screen.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/lang/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MauZanimoApp(),
    ),
  );
}

class MauZanimoApp extends StatelessWidget {
  const MauZanimoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MauZanimo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
    );
  }
}
