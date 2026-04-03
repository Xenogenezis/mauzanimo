const fs = require('fs');

let splash = fs.readFileSync('lib/screens/splash_screen.dart', 'utf8');
splash = splash.replace('Find your perfect companion', 'Rehome responsibly. Adopt locally.');
fs.writeFileSync('lib/screens/splash_screen.dart', splash);
console.log('Splash updated!');

let home = fs.readFileSync('lib/screens/pets/pet_list_screen.dart', 'utf8');
home = home.replace("'Find a companion'", "'Find your pet a loving home'");
home = home.replace("'Give a stray pet a loving home'", "'Rehome responsibly. Adopt locally.'");
fs.writeFileSync('lib/screens/pets/pet_list_screen.dart', home);
console.log('Home updated!');

let onboard = fs.readFileSync('lib/screens/onboarding_screen.dart', 'utf8');
onboard = onboard.replace('Connecting stray pets with loving homes across Mauritius.', 'Helping owners rehome responsibly and families adopt locally across Mauritius.');
onboard = onboard.replace('Browse dogs, cats and other pets looking for a forever home.', 'Browse pets listed by caring owners looking for a loving new home.');
onboard = onboard.replace('Submit an adoption inquiry and our team will guide you step by step.', 'Apply to adopt and connect directly with the pet owner. Simple, safe and transparent.');
onboard = onboard.replace('List your pet, volunteer, donate or partner with us.', 'List your pet for rehoming, volunteer, donate or become a partner.');
onboard = onboard.replace('Aider les proprietaires a trouver un nouveau foyer pour leur animal a Maurice.', 'Aider les proprietaires a placer leur animal dans un foyer aimant a Maurice.');
onboard = onboard.replace("'Find Your Companion'", "'Find a New Home'");
onboard = onboard.replace("'Trouvez votre compagnon'", "'Trouver un nouveau foyer'");
fs.writeFileSync('lib/screens/onboarding_screen.dart', onboard);
console.log('Onboarding updated!');

let strings = fs.readFileSync('lib/lang/app_strings.dart', 'utf8');
strings = strings.replace("'find_companion': 'Find a companion'", "'find_companion': 'Find your pet a loving home'");
strings = strings.replace("'give_home': 'Give a stray pet a loving home'", "'give_home': 'Rehome responsibly. Adopt locally.'");
strings = strings.replace("'tagline': 'Find your perfect companion'", "'tagline': 'Rehome responsibly. Adopt locally.'");
strings = strings.replace("'find_companion': 'Trouver un compagnon'", "'find_companion': 'Trouvez un foyer pour votre animal'");
strings = strings.replace("'give_home': 'Donnez un foyer a un animal errant'", "'give_home': 'Adoption responsable. Localement.'");
strings = strings.replace("'tagline': 'Trouvez votre compagnon ideal'", "'tagline': 'Adoption responsable. Localement.'");
fs.writeFileSync('lib/lang/app_strings.dart', strings);
console.log('Strings updated!');

console.log('\nDone! Press r to hot reload.');
