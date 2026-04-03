const fs = require('fs');
let content = fs.readFileSync('lib/screens/drawer_menu.dart', 'utf8');

content = content.replace("subtitle: 'Pets that found their home',", "subtitle: lang == 'fr' ? 'Animaux qui ont trouve un foyer' : 'Pets that found their home',");
content = content.replace("subtitle: 'Support our mission',", "subtitle: lang == 'fr' ? 'Soutenez notre mission' : 'Support our mission',");
content = content.replace("subtitle: 'Vets, shelters and NGOs',", "subtitle: lang == 'fr' ? 'Vets, refuges et ONG' : 'Vets, shelters and NGOs',");
content = content.replace("subtitle: 'Join our community',", "subtitle: lang == 'fr' ? 'Rejoignez notre communaute' : 'Join our community',");
content = content.replace("subtitle: 'Our story and mission',", "subtitle: lang == 'fr' ? 'Notre histoire et mission' : 'Our story and mission',");
content = content.replace("subtitle: 'Get help from our team',", "subtitle: lang == 'fr' ? 'Obtenir de l aide' : 'Get help from our team',");
content = content.replace("subtitle: 'Report or find lost animals',", "subtitle: lang == 'fr' ? 'Signalez ou trouvez des animaux' : 'Report or find lost animals',");
content = content.replace("subtitle: 'Upcoming events near you',", "subtitle: lang == 'fr' ? 'Evenements a venir' : 'Upcoming events near you',");
content = content.replace("subtitle: 'Register a new pet',", "subtitle: lang == 'fr' ? 'Ajouter un animal' : 'Register a new pet',");
content = content.replace("subtitle: 'Manage adoption inquiries',", "subtitle: lang == 'fr' ? 'Gerer les demandes' : 'Manage adoption inquiries',");

fs.writeFileSync('lib/screens/drawer_menu.dart', content);
console.log('Done!');
