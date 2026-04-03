const fs = require('fs');
let content = fs.readFileSync('lib/screens/splash_screen.dart', 'utf8');

content = content.replace(
  "              Text(\n                'Find your perfect companion',\n                style: TextStyle(\n                  fontSize: 16,\n                  color: Colors.white.withOpacity(0.8),\n                ),\n              ),",
  "              Text(\n                'Find your perfect companion',\n                style: TextStyle(\n                  fontSize: 16,\n                  color: Colors.white.withOpacity(0.8),\n                ),\n              ),\n              const SizedBox(height: 48),\n              Text(\n                'Powered by',\n                style: TextStyle(\n                  fontSize: 12,\n                  color: Colors.white.withOpacity(0.6),\n                  letterSpacing: 1,\n                ),\n              ),\n              const SizedBox(height: 8),\n              Image.asset(\n                'assets/images/jci_grand_baie.png',\n                height: 80,\n              ),"
);

fs.writeFileSync('lib/screens/splash_screen.dart', content);
console.log('Done!');
