const fs = require('fs');
let content = fs.readFileSync('lib/screens/home_screen.dart', 'utf8');

content = content.replace(
  "import 'package:stray_pets_mu/screens/pets/upload_pet_screen.dart';",
  "import 'package:stray_pets_mu/screens/pets/upload_pet_screen.dart';\nimport 'package:stray_pets_mu/screens/drawer_menu.dart';"
);

content = content.replace(
  "    return Scaffold(",
  "    return Scaffold(\n      drawer: const AppDrawer(),"
);

fs.writeFileSync('lib/screens/home_screen.dart', content);
console.log('Done!');
