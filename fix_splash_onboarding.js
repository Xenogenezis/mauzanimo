const fs = require('fs');
let content = fs.readFileSync('lib/screens/splash_screen.dart', 'utf8');

content = content.replace(
  "import 'package:firebase_auth/firebase_auth.dart';",
  "import 'package:firebase_auth/firebase_auth.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\nimport 'package:stray_pets_mu/screens/onboarding_screen.dart';"
);

content = content.replace(
  "    Future.delayed(const Duration(seconds: 3), () {\n      final user = FirebaseAuth.instance.currentUser;\n      if (!mounted) return;\n      Navigator.pushReplacement(\n        context,\n        MaterialPageRoute(\n          builder: (_) => user != null ? HomeScreen() : LoginScreen(),\n        ),\n      );\n    });",
  "    Future.delayed(const Duration(seconds: 3), () async {\n      final prefs = await SharedPreferences.getInstance();\n      final onboardingDone = prefs.getBool('onboarding_done') ?? false;\n      final user = FirebaseAuth.instance.currentUser;\n      if (!mounted) return;\n      if (!onboardingDone) {\n        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OnboardingScreen()));\n      } else {\n        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => user != null ? HomeScreen() : LoginScreen()));\n      }\n    });"
);

fs.writeFileSync('lib/screens/splash_screen.dart', content);
console.log('Done!');
