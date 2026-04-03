const fs = require('fs');

// Add dewormed to upload_pet_screen
let upload = fs.readFileSync('lib/screens/pets/upload_pet_screen.dart', 'utf8');
upload = upload.replace(
  "  bool _vaccinated = false;\n  bool _sterilized = false;",
  "  bool _vaccinated = false;\n  bool _sterilized = false;\n  bool _dewormed = false;"
);
upload = upload.replace(
  "        'vaccinated': _vaccinated,\n        'sterilized': _sterilized,",
  "        'vaccinated': _vaccinated,\n        'sterilized': _sterilized,\n        'dewormed': _dewormed,"
);
upload = upload.replace(
  "      SwitchListTile(title: const Text('Sterilized'), value: _sterilized,\n        activeColor: AppTheme.primary, onChanged: (v) => setState(() => _sterilized = v)),",
  "      SwitchListTile(title: const Text('Sterilized'), value: _sterilized,\n        activeColor: AppTheme.primary, onChanged: (v) => setState(() => _sterilized = v)),\n      SwitchListTile(title: const Text('Dewormed'), value: _dewormed,\n        activeColor: AppTheme.primary, onChanged: (v) => setState(() => _dewormed = v)),"
);
fs.writeFileSync('lib/screens/pets/upload_pet_screen.dart', upload);
console.log('Upload screen updated!');

// Add dewormed to add_pet_screen (admin)
let admin = fs.readFileSync('lib/screens/admin/add_pet_screen.dart', 'utf8');
admin = admin.replace(
  "  bool _vaccinated = false; bool _sterilized = false;",
  "  bool _vaccinated = false; bool _sterilized = false; bool _dewormed = false;"
);
admin = admin.replace(
  "        'vaccinated': _vaccinated, 'sterilized': _sterilized,",
  "        'vaccinated': _vaccinated, 'sterilized': _sterilized, 'dewormed': _dewormed,"
);
admin = admin.replace(
  "        SwitchListTile(title: const Text('Sterilized'), value: _sterilized, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _sterilized = v)),",
  "        SwitchListTile(title: const Text('Sterilized'), value: _sterilized, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _sterilized = v)),\n        SwitchListTile(title: const Text('Dewormed'), value: _dewormed, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _dewormed = v)),"
);
fs.writeFileSync('lib/screens/admin/add_pet_screen.dart', admin);
console.log('Admin screen updated!');

// Add dewormed chip to pet_detail_screen
let detail = fs.readFileSync('lib/screens/pets/pet_detail_screen.dart', 'utf8');
detail = detail.replace(
  "                    _healthChip('Sterilized', pet['sterilized'] == true),",
  "                    _healthChip('Sterilized', pet['sterilized'] == true),\n                      const SizedBox(width: 10),\n                    _healthChip('Dewormed', pet['dewormed'] == true),"
);
fs.writeFileSync('lib/screens/pets/pet_detail_screen.dart', detail);
console.log('Pet detail updated!');
