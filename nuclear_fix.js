const fs = require('fs');
const path = require('path');

function fixFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  const original = content;

  // Remove all AppStrings.get('key', ...) and replace with empty string placeholder
  // Pattern: AppStrings.get('some_key', Provider.of<LanguageProvider>(context, listen: false).lang)
  content = content.replace(
    /AppStrings\.get\('([^']+)',\s*Provider\.of<LanguageProvider>\(context,\s*listen:\s*false\)\.lang\)/g,
    (match, key) => {
      // Convert key back to readable string
      const readable = key.replace(/_/g, ' ');
      const capitalized = readable.charAt(0).toUpperCase() + readable.slice(1);
      return `'${capitalized}'`;
    }
  );

  // Remove const before Text( when it now has dynamic content - no longer needed
  // Actually keep const removal since some were already non-const
  content = content.replace(/const\s+Text\s*\(\s*'([^']+)'\s*\)/g, "Text('$1')");
  content = content.replace(/const\s+Text\s*\(\s*'([^']+)'\s*,/g, "Text('$1',");

  // Remove stray _getLang method
  content = content.replace(/String _getLang\(BuildContext context\)[^\n]*\n+/g, '');

  // Remove unused imports added by auto_translate
  if (!content.includes('Provider.of') && !content.includes('LanguageProvider')) {
    content = content.replace(/import 'package:provider\/provider\.dart';\n/g, '');
    content = content.replace(/import 'package:stray_pets_mu\/lang\/language_provider\.dart';\n/g, '');
    content = content.replace(/import 'package:stray_pets_mu\/lang\/app_strings\.dart';\n/g, '');
  }

  if (content !== original) {
    fs.writeFileSync(filePath, content);
    return true;
  }
  return false;
}

function getAllDartFiles(dir) {
  const files = [];
  for (const item of fs.readdirSync(dir)) {
    const full = path.join(dir, item);
    if (fs.statSync(full).isDirectory()) files.push(...getAllDartFiles(full));
    else if (item.endsWith('.dart')) files.push(full);
  }
  return files;
}

let fixed = 0;
for (const file of getAllDartFiles('./lib/screens')) {
  if (fixFile(file)) {
    console.log('Fixed:', path.basename(file));
    fixed++;
  }
}
console.log(`\nDone! Fixed ${fixed} files.`);
