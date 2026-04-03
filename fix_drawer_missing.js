const fs = require('fs');
let content = fs.readFileSync('lib/screens/drawer_menu.dart', 'utf8');

content = content.replace(
  "import 'package:stray_pets_mu/screens/stories/success_stories_screen.dart';",
  "import 'package:stray_pets_mu/screens/stories/success_stories_screen.dart';\nimport 'package:stray_pets_mu/screens/lostfound/lost_found_screen.dart';\nimport 'package:stray_pets_mu/screens/events/events_screen.dart';"
);

content = content.replace(
  "                _DrawerTile(\n                  icon: Icons.auto_stories_outlined,",
  "                _DrawerTile(\n                  icon: Icons.search,\n                  title: AppStrings.get('lost_found', lang),\n                  subtitle: lang == 'fr' ? 'Signalez ou trouvez des animaux' : 'Report or find lost animals',\n                  color: Colors.orange,\n                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => LostFoundScreen())); },\n                ),\n                _DrawerTile(\n                  icon: Icons.event_outlined,\n                  title: AppStrings.get('events', lang),\n                  subtitle: lang == 'fr' ? 'Evenements a venir' : 'Upcoming events near you',\n                  color: AppTheme.primary,\n                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => EventsScreen())); },\n                ),\n                _DrawerTile(\n                  icon: Icons.auto_stories_outlined,"
);

fs.writeFileSync('lib/screens/drawer_menu.dart', content);
console.log('Done!');
