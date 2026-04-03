const fs = require('fs');
let content = fs.readFileSync('lib/screens/home_screen.dart', 'utf8');

content = content.replace(
  "import 'package:stray_pets_mu/screens/auth/login_screen.dart';",
  "import 'package:stray_pets_mu/screens/auth/login_screen.dart';\nimport 'package:stray_pets_mu/screens/profile_screen.dart';"
);

content = content.replace(
  "final List<Widget> _screens = [PetListScreen(), const Center(child: Text(\"Coming soon\")), const Center(child: Text(\"Coming soon\"))];",
  "final List<Widget> _screens = [PetListScreen(), const Center(child: Text(\"Saved - Coming soon\")), const ProfileScreen()];"
);

fs.writeFileSync('lib/screens/home_screen.dart', content);
console.log('Done!');
