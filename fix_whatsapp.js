const fs = require('fs');
let content = fs.readFileSync('lib/screens/pets/pet_detail_screen.dart', 'utf8');

content = content.replace(
  "import 'package:stray_pets_mu/screens/adoption/adoption_inquiry_screen.dart';",
  "import 'package:stray_pets_mu/screens/adoption/adoption_inquiry_screen.dart';\nimport 'package:url_launcher/url_launcher.dart';"
);

content = content.replace(
  "                  const SizedBox(height: 20),\n                ],",
  "                  const SizedBox(height: 12),\n                  SizedBox(\n                    width: double.infinity,\n                    child: OutlinedButton.icon(\n                      onPressed: () async {\n                        final phone = pet['contact'] ?? '';\n                        final name = pet['name'] ?? 'this pet';\n                        final message = 'Hi, I am interested in adopting ' + name + ' from MauZanimo!';\n                        final url = 'https://wa.me/' + phone.replaceAll(' ', '') + '?text=' + Uri.encodeComponent(message);\n                        if (await canLaunchUrl(Uri.parse(url))) {\n                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);\n                        }\n                      },\n                      icon: const Icon(Icons.chat, color: Color(0xFF25D366)),\n                      label: const Text('Chat on WhatsApp', style: TextStyle(color: Color(0xFF25D366))),\n                      style: OutlinedButton.styleFrom(\n                        side: const BorderSide(color: Color(0xFF25D366)),\n                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),\n                      ),\n                    ),\n                  ),\n                  const SizedBox(height: 20),\n                ],"
);

fs.writeFileSync('lib/screens/pets/pet_detail_screen.dart', content);
console.log('Done!');
