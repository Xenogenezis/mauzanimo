const fs = require('fs');
const path = require('path');

// ── CONFIG ──────────────────────────────────────────────
const SCREENS_DIR = './lib/screens';
const STRINGS_FILE = './lib/lang/app_strings.dart';
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY || '';

// Files to skip (already handled or system files)
const SKIP_FILES = ['language_select_screen.dart', 'onboarding_screen.dart'];

// ── EXTRACT STRINGS ─────────────────────────────────────
function extractStrings(code) {
  const strings = new Set();

  // Match Text('...'), label: '...', hint: '...', title: '...', subtitle: '...', content: Text('...')
  const patterns = [
    /Text\s*\(\s*'([^']{3,})'\s*[\),]/g,
    /Text\s*\(\s*"([^"]{3,})"\s*[\),]/g,
    /labelText:\s*'([^']{3,})'/g,
    /hintText:\s*'([^']{3,})'/g,
    /label:\s*const\s*Text\s*\(\s*'([^']{3,})'\s*\)/g,
    /title:\s*const\s*Text\s*\(\s*'([^']{3,})'\s*\)/g,
    /subtitle:\s*const\s*Text\s*\(\s*'([^']{3,})'\s*\)/g,
    /content:\s*const\s*Text\s*\(\s*'([^']{3,})'\s*\)/g,
    /content:\s*Text\s*\(\s*'([^']{3,})'\s*\)/g,
    /SnackBar\s*\(\s*content:\s*(?:const\s*)?Text\s*\(\s*'([^']{3,})'\s*\)/g,
    /title:\s*const\s*Text\s*\(\s*'([^']{3,})'\s*\)/g,
    /AppBar\s*\(\s*title:\s*const\s*Text\s*\(\s*'([^']{3,})'\s*\)/g,
  ];

  patterns.forEach(pattern => {
    let match;
    const regex = new RegExp(pattern.source, pattern.flags);
    while ((match = regex.exec(code)) !== null) {
      const str = match[1].trim();
      // Skip if it looks like a variable, key, or is too short
      if (
        str.length > 2 &&
        !str.startsWith('_') &&
        !str.match(/^[a-z_]+$/) &&
        !str.match(/^\d/) &&
        !str.includes('${') &&
        !str.match(/^[A-Z_]+$/)
      ) {
        strings.add(str);
      }
    }
  });

  return [...strings];
}

// ── LOAD EXISTING TRANSLATIONS ──────────────────────────
function loadExistingTranslations() {
  const content = fs.readFileSync(STRINGS_FILE, 'utf8');
  const existing = {};
  const enMatch = content.match(/'en':\s*\{([\s\S]*?)\},\s*'fr'/);
  if (enMatch) {
    const enBlock = enMatch[1];
    const pairs = enBlock.matchAll(/'([^']+)':\s*'([^']+)'/g);
    for (const pair of pairs) {
      existing[pair[2]] = pair[1]; // value -> key
    }
  }
  return existing;
}

// ── GENERATE KEY FROM STRING ────────────────────────────
function toKey(str) {
  return str
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .trim()
    .replace(/\s+/g, '_')
    .substring(0, 40);
}

// ── TRANSLATE VIA CLAUDE API ────────────────────────────
async function translateStrings(strings) {
  if (!ANTHROPIC_API_KEY) {
    console.log('No API key found. Set ANTHROPIC_API_KEY env variable.');
    process.exit(1);
  }

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-6',
      max_tokens: 4000,
      messages: [{
        role: 'user',
        content: `Translate these English strings to French for a Mauritian pet adoption app called MauZanimo. 
Return ONLY a JSON object where each key is the English string and the value is the French translation.
Keep translations natural and appropriate for a mobile app. Do not add accents/special characters that might cause encoding issues.
Use simple ASCII French where possible (e coeur -> coeur, etc).

Strings to translate:
${JSON.stringify(strings, null, 2)}

Return only valid JSON, no explanation.`
      }]
    })
  });

  const data = await response.json();
  const text = data.content[0].text;
  
  try {
    const clean = text.replace(/```json|```/g, '').trim();
    return JSON.parse(clean);
  } catch(e) {
    console.error('Parse error:', e.message);
    return {};
  }
}

// ── UPDATE STRINGS FILE ─────────────────────────────────
function updateStringsFile(newPairs) {
  let content = fs.readFileSync(STRINGS_FILE, 'utf8');
  
  // Find where to insert in EN block
  const enInsertPoint = content.lastIndexOf("'language': 'Language',");
  const frInsertPoint = content.lastIndexOf("'language': 'Langue',");
  
  if (enInsertPoint === -1 || frInsertPoint === -1) {
    console.log('Could not find insert points in strings file');
    return {};
  }

  const keyMap = {};
  let enInserts = '';
  let frInserts = '';

  for (const [en, fr] of Object.entries(newPairs)) {
    const key = toKey(en);
    if (!key) continue;
    keyMap[en] = key;
    enInserts += `\n      '${key}': '${en.replace(/'/g, "\\'")}',`;
    frInserts += `\n      '${key}': '${fr.replace(/'/g, "\\'")}',`;
  }

  // Insert EN strings
  content = content.substring(0, enInsertPoint + "'language': 'Language',".length) +
    enInserts +
    content.substring(enInsertPoint + "'language': 'Language',".length);

  // Recalculate FR insert point after EN insertion
  const newFrPoint = content.lastIndexOf("'language': 'Langue',");
  content = content.substring(0, newFrPoint + "'language': 'Langue',".length) +
    frInserts +
    content.substring(newFrPoint + "'language': 'Langue',".length);

  fs.writeFileSync(STRINGS_FILE, content);
  return keyMap;
}

// ── REPLACE STRINGS IN FILE ─────────────────────────────
function replaceStringsInFile(filePath, keyMap) {
  let content = fs.readFileSync(filePath, 'utf8');
  let changed = false;

  // Add provider import if needed
  const needsProvider = Object.keys(keyMap).length > 0;
  if (needsProvider && !content.includes('language_provider.dart')) {
    const lastImport = content.lastIndexOf("import '");
    const endOfImport = content.indexOf(';', lastImport) + 1;
    content = content.substring(0, endOfImport) +
      "\nimport 'package:provider/provider.dart';\nimport 'package:stray_pets_mu/lang/language_provider.dart';\nimport 'package:stray_pets_mu/lang/app_strings.dart';" +
      content.substring(endOfImport);
    changed = true;
  }

  for (const [str, key] of Object.entries(keyMap)) {
    const escapedStr = str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    
    // Replace Text('string') with Text(AppStrings.get('key', lang))
    const textPattern = new RegExp(`Text\\s*\\(\\s*'${escapedStr}'\\s*([,)])`, 'g');
    const newContent1 = content.replace(textPattern, `Text(AppStrings.get('${key}', _getLang(context))$1`);
    if (newContent1 !== content) { content = newContent1; changed = true; }

    // Replace const Text('string') with Text(AppStrings.get(...))
    const constTextPattern = new RegExp(`const\\s+Text\\s*\\(\\s*'${escapedStr}'\\s*([,)])`, 'g');
    const newContent2 = content.replace(constTextPattern, `Text(AppStrings.get('${key}', _getLang(context))$1`);
    if (newContent2 !== content) { content = newContent2; changed = true; }

    // Replace labelText: 'string'
    const labelPattern = new RegExp(`labelText:\\s*'${escapedStr}'`, 'g');
    const newContent3 = content.replace(labelPattern, `labelText: AppStrings.get('${key}', _getLang(context))`);
    if (newContent3 !== content) { content = newContent3; changed = true; }

    // Replace hintText: 'string'
    const hintPattern = new RegExp(`hintText:\\s*'${escapedStr}'`, 'g');
    const newContent4 = content.replace(hintPattern, `hintText: AppStrings.get('${key}', _getLang(context))`);
    if (newContent4 !== content) { content = newContent4; changed = true; }
  }

  if (changed) {
    // Add _getLang helper if not present
    if (!content.includes('_getLang(') && content.includes('AppStrings.get(')) {
      content = content.replace(
        /class _(\w+State) extends State/,
        `String _getLang(BuildContext context) => Provider.of<LanguageProvider>(context, listen: false).lang;\n\nclass _$1State extends State`
      );
    }
    fs.writeFileSync(filePath, content);
    return true;
  }
  return false;
}

// ── SCAN ALL DART FILES ─────────────────────────────────
function getAllDartFiles(dir) {
  const files = [];
  const items = fs.readdirSync(dir);
  for (const item of items) {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      files.push(...getAllDartFiles(fullPath));
    } else if (item.endsWith('.dart') && !SKIP_FILES.includes(item)) {
      files.push(fullPath);
    }
  }
  return files;
}

// ── MAIN ─────────────────────────────────────────────────
async function main() {
  console.log('Scanning dart files for untranslated strings...\n');
  
  const existingTranslations = loadExistingTranslations();
  const allFiles = getAllDartFiles(SCREENS_DIR);
  
  // Collect all new strings across all files
  const allNewStrings = new Set();
  const fileStringMap = {};

  for (const file of allFiles) {
    const code = fs.readFileSync(file, 'utf8');
    // Skip if already fully using AppStrings
    const strings = extractStrings(code);
    const newStrings = strings.filter(s => !existingTranslations[s]);
    if (newStrings.length > 0) {
      fileStringMap[file] = newStrings;
      newStrings.forEach(s => allNewStrings.add(s));
      console.log(`Found ${newStrings.length} new strings in: ${path.basename(file)}`);
    }
  }

  if (allNewStrings.size === 0) {
    console.log('\nAll strings already translated!');
    return;
  }

  console.log(`\nTotal new strings to translate: ${allNewStrings.size}`);
  console.log('Sending to Claude API for translation...\n');

  const translations = await translateStrings([...allNewStrings]);
  console.log(`Received ${Object.keys(translations).length} translations\n`);

  // Update strings file
  const keyMap = updateStringsFile(translations);
  console.log(`Updated app_strings.dart with ${Object.keys(keyMap).length} new entries\n`);

  // Update dart files
  let updatedFiles = 0;
  for (const [file, strings] of Object.entries(fileStringMap)) {
    const fileKeyMap = {};
    strings.forEach(s => { if (keyMap[s]) fileKeyMap[s] = keyMap[s]; });
    if (Object.keys(fileKeyMap).length > 0) {
      const updated = replaceStringsInFile(file, fileKeyMap);
      if (updated) {
        console.log(`Updated: ${path.basename(file)}`);
        updatedFiles++;
      }
    }
  }

  console.log(`\nDone! Updated ${updatedFiles} files.`);
  console.log('Run: flutter run -d chrome to see translations in action!');
}

main().catch(console.error);
