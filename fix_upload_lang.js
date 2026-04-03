const fs = require('fs');
let content = fs.readFileSync('lib/screens/pets/upload_pet_screen.dart', 'utf8');

content = content.replace(
  "import 'package:stray_pets_mu/theme/app_theme.dart';",
  "import 'package:stray_pets_mu/theme/app_theme.dart';\nimport 'package:provider/provider.dart';\nimport 'package:stray_pets_mu/lang/language_provider.dart';"
);

content = content.replace(
  "  void _showImageOptions() {\n    showModalBottomSheet(",
  "  String _t(BuildContext context, String en, String fr) {\n    final lang = Provider.of<LanguageProvider>(context, listen: false).lang;\n    return lang == 'fr' ? fr : en;\n  }\n\n  void _showImageOptions() {\n    showModalBottomSheet("
);

content = content.replace(
  "content: const Text('Camera permission is required to take photos.'),",
  "content: Text(_t(context, 'Camera permission is required to take photos.', 'Permission camera requise pour prendre des photos.')),"
);

content = content.replace(
  "content: const Text('Gallery permission is required to choose photos.'),",
  "content: Text(_t(context, 'Gallery permission is required to choose photos.', 'Permission galerie requise pour choisir des photos.')),"
);

content = content.replace(
  "content: const Text('Something went wrong. Please try again.')",
  "content: Text(_t(context, 'Something went wrong. Please try again.', 'Une erreur est survenue. Veuillez reessayer.'))"
);

content = content.replace(
  "content: const Text('Please fill in all required fields')",
  "content: Text(_t(context, 'Please fill in all required fields', 'Veuillez remplir tous les champs obligatoires'))"
);

fs.writeFileSync('lib/screens/pets/upload_pet_screen.dart', content);
console.log('Done!');
