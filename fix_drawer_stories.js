const fs = require('fs');
let content = fs.readFileSync('lib/screens/drawer_menu.dart', 'utf8');

content = content.replace(
  "import 'package:stray_pets_mu/screens/info/volunteer_screen.dart';",
  "import 'package:stray_pets_mu/screens/info/volunteer_screen.dart';\nimport 'package:stray_pets_mu/screens/stories/success_stories_screen.dart';"
);

content = content.replace(
  "                _DrawerTile(\n                  icon: Icons.favorite_outline,\n                  title: 'Donate to Us',",
  "                _DrawerTile(\n                  icon: Icons.auto_stories_outlined,\n                  title: 'Success Stories',\n                  subtitle: 'Pets that found their home',\n                  color: Colors.green,\n                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SuccessStoriesScreen())); },\n                ),\n                _DrawerTile(\n                  icon: Icons.favorite_outline,\n                  title: 'Donate to Us',"
);

fs.writeFileSync('lib/screens/drawer_menu.dart', content);
console.log('Done!');
