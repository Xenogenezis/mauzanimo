const fs = require('fs');

// Fix upload_pet_screen - remove duplicate dewormed
let upload = fs.readFileSync('lib/screens/pets/upload_pet_screen.dart', 'utf8');
upload = upload.replace(
  "  bool _vaccinated = false;\n  bool _sterilized = false;\n  bool _dewormed = false;\n  bool _dewormed = false;",
  "  bool _vaccinated = false;\n  bool _sterilized = false;\n  bool _dewormed = false;"
);
fs.writeFileSync('lib/screens/pets/upload_pet_screen.dart', upload);
console.log('upload_pet_screen fixed!');

// Fix add_pet_screen - remove duplicate dewormed
let admin = fs.readFileSync('lib/screens/admin/add_pet_screen.dart', 'utf8');
admin = admin.replace(
  "  bool _vaccinated = false; bool _sterilized = false; bool _dewormed = false;\n  bool _dewormed = false; bool _isLoading = false;",
  "  bool _vaccinated = false; bool _sterilized = false; bool _dewormed = false; bool _isLoading = false;"
);
fs.writeFileSync('lib/screens/admin/add_pet_screen.dart', admin);
console.log('add_pet_screen fixed!');
