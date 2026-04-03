const fs = require('fs');
let content = fs.readFileSync('lib/screens/splash_screen.dart', 'utf8');

content = content.replace(
  "import 'package:stray_pets_mu/screens/onboarding_screen.dart';",
  "import 'package:stray_pets_mu/screens/onboarding_screen.dart';\nimport 'package:stray_pets_mu/screens/language_select_screen.dart';"
);

content = content.replace(
  "if (!onboardingDone) {\n        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OnboardingScreen()));",
  "if (!onboardingDone) {\n        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LanguageSelectScreen()));"
);

fs.writeFileSync('lib/screens/splash_screen.dart', content);
console.log('Done!');
