const fs = require('fs');

// Clean add_pet_screen - remove ALL dewormed then add once correctly
let admin = fs.readFileSync('lib/screens/admin/add_pet_screen.dart', 'utf8');

// Remove all dewormed variable declarations (keep only one)
let count = 0;
admin = admin.replace(/bool _dewormed = false;?\s*/g, () => {
  count++;
  return count === 1 ? 'bool _dewormed = false; ' : '';
});

// Remove duplicate dewormed firestore entries
count = 0;
admin = admin.replace(/'dewormed': _dewormed,?\s*/g, () => {
  count++;
  return count === 1 ? "'dewormed': _dewormed,\n" : '';
});

// Remove duplicate SwitchListTile dewormed
count = 0;
admin = admin.replace(/SwitchListTile\(title: const Text\('Dewormed'\)[\s\S]*?onChanged: \(v\) => setState\(\(\) => _dewormed = v\)\),/g, () => {
  count++;
  return count === 1 ? "SwitchListTile(title: const Text('Dewormed'), value: _dewormed, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _dewormed = v))," : '';
});

fs.writeFileSync('lib/screens/admin/add_pet_screen.dart', admin);
console.log('add_pet_screen fixed! Remaining dewormed:', (admin.match(/dewormed/g) || []).length);

// Clean upload_pet_screen
let upload = fs.readFileSync('lib/screens/pets/upload_pet_screen.dart', 'utf8');

count = 0;
upload = upload.replace(/bool _dewormed = false;?\s*/g, () => {
  count++;
  return count === 1 ? 'bool _dewormed = false;\n' : '';
});

count = 0;
upload = upload.replace(/'dewormed': _dewormed,?\s*/g, () => {
  count++;
  return count === 1 ? "'dewormed': _dewormed,\n" : '';
});

count = 0;
upload = upload.replace(/SwitchListTile\(title: const Text\('Dewormed'\)[\s\S]*?onChanged: \(v\) => setState\(\(\) => _dewormed = v\)\),/g, () => {
  count++;
  return count === 1 ? "SwitchListTile(title: const Text('Dewormed'), value: _dewormed,\n        activeColor: AppTheme.primary, onChanged: (v) => setState(() => _dewormed = v))," : '';
});

fs.writeFileSync('lib/screens/pets/upload_pet_screen.dart', upload);
console.log('upload_pet_screen fixed! Remaining dewormed:', (upload.match(/dewormed/g) || []).length);
