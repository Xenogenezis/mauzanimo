import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/favourites_provider.dart';
import 'providers/lost_found_provider.dart';
import 'providers/event_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/adoption_provider.dart';
import 'providers/review_provider.dart';
import 'providers/rescue_provider.dart';
import 'providers/foster_provider.dart';
import 'providers/pet_update_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/pet_repository.dart';
import 'repositories/lost_found_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/gamification_repository.dart';
import 'repositories/adoption_repository.dart';
import 'repositories/review_repository.dart';
import 'repositories/rescue_repository.dart';
import 'repositories/foster_repository.dart';
import 'repositories/pet_update_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRepository = AuthRepository();
  final petRepository = PetRepository();
  final lostFoundRepository = LostFoundRepository();
  final eventRepository = EventRepository();
  final gamificationRepository = GamificationRepository();
  final adoptionRepository = AdoptionRepository();
  final reviewRepository = ReviewRepository();
  final rescueRepository = RescueRepository();
  final fosterRepository = FosterRepository();
  final petUpdateRepository = PetUpdateRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => PetProvider(petRepository)),
        ChangeNotifierProvider(create: (_) => LostFoundProvider(lostFoundRepository)),
        ChangeNotifierProvider(create: (_) => EventProvider(eventRepository)),
        ChangeNotifierProvider(create: (_) => AdoptionProvider(adoptionRepository)),
        ChangeNotifierProvider(create: (_) => RescueProvider(rescueRepository)),
        ChangeNotifierProvider(create: (_) => FosterProvider(fosterRepository)),
      ],
      child: Builder(
        builder: (context) {
          return MauZanimoApp(
            authRepository: authRepository,
            petRepository: petRepository,
            gamificationRepository: gamificationRepository,
            reviewRepository: reviewRepository,
            petUpdateRepository: petUpdateRepository,
          );
        },
      ),
    ),
  );
}

class MauZanimoApp extends StatelessWidget {
  final AuthRepository authRepository;
  final PetRepository petRepository;
  final GamificationRepository gamificationRepository;
  final ReviewRepository reviewRepository;
  final PetUpdateRepository petUpdateRepository;

  const MauZanimoApp({
    super.key,
    required this.authRepository,
    required this.petRepository,
    required this.gamificationRepository,
    required this.reviewRepository,
    required this.petUpdateRepository,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => FavouritesProvider(petRepository, authProvider.uid),
            ),
            ChangeNotifierProvider(
              create: (_) => GamificationProvider(
                gamificationRepository,
                userId: authProvider.uid,
              )..loadGamification(),
            ),
            ChangeNotifierProvider(
              create: (_) => ReviewProvider(reviewRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => PetUpdateProvider(petUpdateRepository),
            ),
          ],
          child: MaterialApp(
            title: 'MauZanimo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
