#!/usr/bin/env node
/**
 * generate_firestore_indexes.js
 *
 * Scans the Flutter/Dart codebase for Firestore query patterns
 * and generates a firestore.indexes.json file with all required
 * composite indexes.
 *
 * Usage:
 *   node generate_firestore_indexes.js
 *
 * Then deploy with:
 *   firebase deploy --only firestore:indexes
 */

const fs = require('fs');
const path = require('path');

// Walk directory recursively
function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach((f) => {
    const dirPath = path.join(dir, f);
    const isDirectory = fs.statSync(dirPath).isDirectory();
    if (isDirectory && f !== 'test' && !f.startsWith('.')) {
      walkDir(dirPath, callback);
    } else if (!isDirectory && f.endsWith('.dart')) {
      callback(dirPath);
    }
  });
}

// Extract query chains from a Dart file
function extractQueries(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const queries = [];

  // Pattern to match Firestore query chains: collection(...).where(...).orderBy(...)
  const collectionRegex = /collection\(['"]([^'"]+)['"]\)/g;

  // Find all collection references and the surrounding query chain
  let match;
  while ((match = collectionRegex.exec(content)) !== null) {
    const collection = match[1];
    const startIdx = match.index;

    // Look ahead up to 500 chars for where/orderBy/snapshots
    const chunk = content.substring(startIdx, startIdx + 500);

    const wheres = [];
    const orderBys = [];

    // Extract where clauses
    const whereRegex = /\.where\(['"]([^'"]+)['"],\s*(?:isEqualTo|arrayContains|in|notIn):\s*[^)]+\)/g;
    let whereMatch;
    while ((whereMatch = whereRegex.exec(chunk)) !== null) {
      wheres.push(whereMatch[1]);
    }

    // Extract orderBy clauses
    const orderByRegex = /\.orderBy\(['"]([^'"]+)['"](?:,\s*descending:\s*(true|false))?\)/g;
    let orderMatch;
    while ((orderMatch = orderByRegex.exec(chunk)) !== null) {
      orderBys.push({
        field: orderMatch[1],
        descending: orderMatch[2] === 'true',
      });
    }

    if (wheres.length > 0 || orderBys.length > 0) {
      queries.push({
        collection,
        wheres,
        orderBys,
        source: path.relative(process.cwd(), filePath),
      });
    }
  }

  return queries;
}

// Build indexes from extracted queries
function buildIndexes(queries) {
  const indexMap = new Map();

  for (const q of queries) {
    // Composite index needed when: where + orderBy, or multiple where + orderBy
    // Skip single-field indexes (Firestore auto-indexes those)
    if (q.wheres.length === 0 && q.orderBys.length <= 1) continue;

    const fields = [];
    const seenFields = new Set();

    // Add where fields as ascending (equality queries)
    for (const w of q.wheres) {
      if (seenFields.has(w)) continue;
      seenFields.add(w);
      fields.push({ fieldPath: w, order: 'ASCENDING' });
    }

    // Add orderBy fields
    for (const o of q.orderBys) {
      if (seenFields.has(o.field)) continue;
      seenFields.add(o.field);
      fields.push({
        fieldPath: o.field,
        order: o.descending ? 'DESCENDING' : 'ASCENDING',
      });
    }

    // Skip if only one field after deduplication
    if (fields.length < 2) continue;

    // Create a unique key for this index
    const key = `${q.collection}:${fields.map((f) => `${f.fieldPath}:${f.order}`).join(',')}`;

    if (!indexMap.has(key)) {
      indexMap.set(key, {
        collectionGroup: q.collection,
        queryScope: 'COLLECTION',
        fields,
        sources: [q.source],
      });
    } else {
      indexMap.get(key).sources.push(q.source);
    }
  }

  return Array.from(indexMap.values());
}

// Main
function main() {
  const libDir = path.join(process.cwd(), 'lib');
  if (!fs.existsSync(libDir)) {
    console.error('Error: lib/ directory not found. Run from project root.');
    process.exit(1);
  }

  const allQueries = [];
  walkDir(libDir, (filePath) => {
    const queries = extractQueries(filePath);
    allQueries.push(...queries);
  });

  const indexes = buildIndexes(allQueries);

  const output = {
    indexes: indexes.map((idx) => ({
      collectionGroup: idx.collectionGroup,
      queryScope: idx.queryScope,
      fields: idx.fields,
    })),
    fieldOverrides: [],
  };

  // Write firestore.indexes.json
  const outputPath = path.join(process.cwd(), 'firestore.indexes.json');
  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2));

  console.log(`Generated ${indexes.length} composite indexes:`);
  for (const idx of indexes) {
    const fields = idx.fields.map((f) => `${f.fieldPath}(${f.order})`).join(', ');
    console.log(`  - ${idx.collectionGroup}: ${fields}`);
    console.log(`    Used in: ${idx.sources.join(', ')}`);
  }
  console.log(`\nWritten to: ${outputPath}`);
  console.log('\nDeploy with: firebase deploy --only firestore:indexes');
}

main();
