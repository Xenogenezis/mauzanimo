const fs = require('fs');
const path = require('path');

function restoreFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Remove all AppStrings.get replacements - revert to original strings
  // Pattern: Text(AppStrings.get('key', Provider.of...)) -> Text('original')
  // We can't recover originals, so instead fix the syntax issues
  
  // Fix 1: Remove const before any widget that contains AppStrings.get
  content = content.replace(/const\s+(Text|Center|SnackBar|ElevatedButton|TextButton)\s*\(/g, '$1(');
  
  // Fix 2: Replace Provider.of<LanguageProvider>(context, listen: false).lang with a safe call
  // For StatelessWidgets we need context from build method
  // Simplest fix: replace all AppStrings.get('key', Provider...) with just the hardcoded string lookup
  
  // Fix 3: Remove stray _getLang method declarations outside classes  
  content = content.replace(/String _getLang\(BuildContext context\)[^\n]*\n\n/g, '');
  
  fs.writeFileSync(filePath, content);
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

for (const file of getAllDartFiles('./lib/screens')) {
  restoreFile(file);
}
console.log('Done!');
