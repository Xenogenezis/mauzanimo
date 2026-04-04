import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/favourites_provider.dart';
import 'providers/lost_found_provider.dart';
import 'providers/event_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/pet_repository.dart';
import 'repositories/lost_found_repository.dart';
import 'repositories/event_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create repositories
  final authRepository = AuthRepository();
  final petRepository = PetRepository();
  final lostFoundRepository = LostFoundRepository();
  final eventRepository = EventRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => PetProvider(petRepository)),
        ChangeNotifierProvider(create: (_) => LostFoundProvider(lostFoundRepository)),
        ChangeNotifierProvider(create: (_) => EventProvider(eventRepository)),
      ],
      child: MauZanimoApp(authRepository: authRepository, petRepository: petRepository),
    ),
  );
}

class MauZanimoApp extends StatelessWidget {
  final AuthRepository authRepository;
  final PetRepository petRepository;

  const MauZanimoApp({
    super.key,
    required this.authRepository,
    required this.petRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => FavouritesProvider(petRepository, authProvider.uid),
            ),
          ],
          child: MaterialApp(
            title: 'MauZanimo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: SplashScreen(),
          ),
        );
      },
    );
  }
}
