const fs = require('fs');
const path = require('path');

function fixFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  let changed = false;

  // 1. Remove const before Text(AppStrings.get(...))
  const before = content;
  content = content.replace(/const\s+Text\s*\(\s*AppStrings\.get\s*\(/g, 'Text(AppStrings.get(');
  
  // 2. Remove const before SnackBar(content: Text(AppStrings.get(...)))
  content = content.replace(/const\s+SnackBar\s*\(\s*content:\s*Text\s*\(\s*AppStrings\.get\s*\(/g, 'SnackBar(content: Text(AppStrings.get(');

  // 3. Remove const before Center(child: Text(AppStrings.get(...)))
  content = content.replace(/const\s+Center\s*\(\s*child:\s*Text\s*\(\s*AppStrings\.get\s*\(/g, 'Center(child: Text(AppStrings.get(');

  // 4. Replace _getLang(context) with inline provider call
  content = content.replace(/_getLang\s*\(\s*context\s*\)/g, 'Provider.of<LanguageProvider>(context, listen: false).lang');

  // 5. Remove the _getLang helper method if added incorrectly outside class
  content = content.replace(/String _getLang\(BuildContext context\) => Provider\.of<LanguageProvider>\(context, listen: false\)\.lang;\n\nclass /g, 'class ');

  // 6. Add _getLang as proper method inside StatefulWidget state classes only
  // For StatelessWidgets, inline is already handled by step 4

  if (content !== before) {
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
for (const file of getAllDartFiles('./lib')) {
  if (fixFile(file)) {
    console.log('Fixed:', path.basename(file));
    fixed++;
  }
}
console.log(`\nDone! Fixed ${fixed} files.`);
