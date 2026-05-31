#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const catalogDir = path.join(root, 'lib', 'l10n', 'catalog');
const locales = ['zh', 'en', 'ja', 'de', 'fr', 'es', 'ru'];
const placeholderPattern = /\{([A-Za-z_][A-Za-z0-9_]*)\}/g;

function placeholdersOf(value) {
  return Array.from(
    new Set(String(value).matchAll(placeholderPattern).map((match) => match[1])),
  ).sort();
}

function parseCsvRows(raw) {
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;

  function endField() {
    row.push(field);
    field = '';
  }

  function endRow() {
    endField();
    rows.push(row);
    row = [];
  }

  for (let index = 0; index < raw.length; index += 1) {
    const char = raw[index];
    if (inQuotes) {
      if (char === '"') {
        if (raw[index + 1] === '"') {
          field += '"';
          index += 1;
        } else {
          inQuotes = false;
        }
      } else {
        field += char;
      }
      continue;
    }

    if (char === '"') {
      inQuotes = true;
    } else if (char === ',') {
      endField();
    } else if (char === '\n') {
      endRow();
    } else if (char === '\r') {
      if (raw[index + 1] === '\n') {
        index += 1;
      }
      endRow();
    } else {
      field += char;
    }
  }

  if (field.length > 0 || row.length > 0) {
    endRow();
  }

  return rows;
}

function readCsvCatalog(filePath) {
  const rows = parseCsvRows(fs.readFileSync(filePath, 'utf8'));
  if (rows.length === 0) {
    throw new Error(`Empty CSV catalog: ${filePath}`);
  }
  const header = rows[0].map((cell) => String(cell).trim());
  const keyIndex = header.indexOf('key');
  if (keyIndex < 0) {
    throw new Error(`CSV catalog is missing key column: ${filePath}`);
  }
  const localeIndexes = Object.fromEntries(
    locales.map((locale) => [locale, header.indexOf(locale)]),
  );
  const catalogs = Object.fromEntries(
    locales.map((locale) => [locale, Object.create(null)]),
  );

  for (const row of rows.slice(1)) {
    const key = row[keyIndex] == null ? '' : String(row[keyIndex]).trim();
    if (key.length === 0 || key.startsWith('@@')) {
      continue;
    }
    for (const locale of locales) {
      const index = localeIndexes[locale];
      if (index < 0) {
        continue;
      }
      catalogs[locale][key] = row[index] == null ? '' : String(row[index]);
    }
  }

  return catalogs;
}

function walk(dir, predicate, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const filePath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === '.dart_tool' || entry.name === 'build') {
        continue;
      }
      walk(filePath, predicate, out);
    } else if (predicate(filePath)) {
      out.push(filePath);
    }
  }
  return out;
}

function findMatchingClose(source, openIndex) {
  let depth = 0;
  let quote = null;
  let escaped = false;
  for (let index = openIndex; index < source.length; index += 1) {
    const char = source[index];
    if (quote != null) {
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char === '\\') {
        escaped = true;
        continue;
      }
      if (char === quote) {
        quote = null;
      }
      continue;
    }
    if (char === "'" || char === '"') {
      quote = char;
      continue;
    }
    if (char === '(') {
      depth += 1;
    } else if (char === ')') {
      depth -= 1;
      if (depth === 0) {
        return index;
      }
    }
  }
  return -1;
}

function lineOf(source, index) {
  return source.slice(0, index).split(/\r?\n/).length;
}

function relative(filePath) {
  return path.relative(root, filePath).replace(/\\/g, '/');
}

function literalKeyFromCall(body) {
  const match = body.match(/^\s*(['"])(.*?)\1/);
  return match == null ? null : match[2];
}

function callHasParams(body) {
  return /\bparams\s*:/.test(body);
}

function paramKeysFromLiteralMap(body) {
  if (!callHasParams(body)) {
    return null;
  }
  const paramIndex = body.search(/\bparams\s*:/);
  const tail = body.slice(paramIndex);
  const openBrace = tail.indexOf('{');
  if (openBrace < 0) {
    return null;
  }
  const beforeBrace = tail.slice(0, openBrace);
  if (!/\bparams\s*:\s*(?:const\s*)?(?:<[^{}]*>\s*)?$/.test(beforeBrace)) {
    return null;
  }
  const keys = new Set();
  const mapText = tail.slice(openBrace);
  for (const match of mapText.matchAll(/['"]([A-Za-z_][A-Za-z0-9_]*)['"]\s*:/g)) {
    keys.add(match[1]);
  }
  return keys;
}

const catalogs = readCsvCatalog(path.join(catalogDir, 'app_texts.csv'));

const baseKeys = Object.keys(catalogs.zh).sort();
const missingCatalog = [];
const placeholderMismatches = [];
const requiredPlaceholders = new Map();

for (const key of baseKeys) {
  const union = new Set();
  for (const locale of locales) {
    if (!(key in catalogs[locale])) {
      missingCatalog.push(`${locale}:${key}`);
      continue;
    }
    for (const placeholder of placeholdersOf(catalogs[locale][key])) {
      union.add(placeholder);
    }
  }
  if (union.size > 0) {
    requiredPlaceholders.set(key, Array.from(union).sort());
  }
  const zhSet = placeholdersOf(catalogs.zh[key]).join('|');
  for (const locale of locales) {
    if (!(key in catalogs[locale])) {
      continue;
    }
    const localeSet = placeholdersOf(catalogs[locale][key]).join('|');
    if (localeSet !== zhSet) {
      placeholderMismatches.push(`${locale}:${key}: ${localeSet} != ${zhSet}`);
    }
  }
}

for (const locale of locales) {
  if (locale === 'zh') {
    continue;
  }
  for (const key of Object.keys(catalogs[locale])) {
    if (!(key in catalogs.zh)) {
      missingCatalog.push(`${locale}:${key}`);
    }
  }
}

const dartFiles = walk(
  path.join(root, 'lib'),
  (filePath) => filePath.endsWith('.dart'),
).sort();
const missingParams = [];
const missingParamKeys = [];
const dynamicParams = [];

for (const filePath of dartFiles) {
  const source = fs.readFileSync(filePath, 'utf8');
  const callPattern = /\.t\s*\(/g;
  let match;
  while ((match = callPattern.exec(source)) != null) {
    const openIndex = source.indexOf('(', match.index);
    const closeIndex = findMatchingClose(source, openIndex);
    if (closeIndex < 0) {
      continue;
    }
    const body = source.slice(openIndex + 1, closeIndex);
    const key = literalKeyFromCall(body);
    if (key == null || !requiredPlaceholders.has(key)) {
      continue;
    }
    const required = requiredPlaceholders.get(key);
    const location = `${relative(filePath)}:${lineOf(source, match.index)}`;
    if (!callHasParams(body)) {
      missingParams.push({ location, key, required });
      continue;
    }
    const literalKeys = paramKeysFromLiteralMap(body);
    if (literalKeys == null) {
      dynamicParams.push({ location, key, required });
      continue;
    }
    const missing = required.filter((placeholder) => !literalKeys.has(placeholder));
    if (missing.length > 0) {
      missingParamKeys.push({ location, key, missing, required });
    }
  }
}

function printItems(title, items, formatter) {
  if (items.length === 0) {
    return;
  }
  console.log(`\n${title} (${items.length})`);
  for (const item of items) {
    console.log(formatter(item));
  }
}

console.log(
  `catalog keys=${baseKeys.length}, placeholderKeys=${requiredPlaceholders.size}`,
);
console.log(
  `catalog missing=${missingCatalog.length}, placeholderMismatch=${placeholderMismatches.length}`,
);
console.log(
  `dart missingParams=${missingParams.length}, missingParamKeys=${missingParamKeys.length}, dynamicParams=${dynamicParams.length}`,
);

printItems('catalog missing', missingCatalog.slice(0, 80), (item) => item);
printItems('catalog placeholder mismatches', placeholderMismatches.slice(0, 80), (item) => item);
printItems('dart missing params', missingParams, (item) =>
  `${item.location}: ${item.key} requires {${item.required.join(', ')}}`,
);
printItems('dart missing param keys', missingParamKeys, (item) =>
  `${item.location}: ${item.key} missing {${item.missing.join(', ')}} requires {${item.required.join(', ')}}`,
);
printItems('dart dynamic params (not failed)', dynamicParams, (item) =>
  `${item.location}: ${item.key} requires {${item.required.join(', ')}}`,
);

if (
  missingCatalog.length > 0 ||
  placeholderMismatches.length > 0 ||
  missingParams.length > 0 ||
  missingParamKeys.length > 0
) {
  process.exit(1);
}
