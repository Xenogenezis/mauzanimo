const fs = require('fs');
let content = fs.readFileSync('lib/screens/home_screen.dart', 'utf8');

content = content.replace(
  "import 'package:stray_pets_mu/screens/profile_screen.dart';",
  "import 'package:stray_pets_mu/screens/profile_screen.dart';\nimport 'package:stray_pets_mu/screens/pets/upload_pet_screen.dart';"
);

content = content.replace(
  "body: _screens[_currentIndex],",
  "body: _screens[_currentIndex],\n      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(\n        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UploadPetScreen())),\n        backgroundColor: AppTheme.primary,\n        icon: const Icon(Icons.add, color: Colors.white),\n        label: const Text('List a Pet', style: TextStyle(color: Colors.white)),\n      ) : null,"
);

fs.writeFileSync('lib/screens/home_screen.dart', content);
console.log('Done!');
