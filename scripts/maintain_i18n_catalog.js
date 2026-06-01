#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const catalogDir = path.join(root, 'lib', 'l10n', 'catalog');
const csvPath = path.join(catalogDir, 'app_texts.csv');
const registryPath = path.join(catalogDir, 'app_text_registry.json');
const retirementPath = path.join(catalogDir, 'app_text_retirements.json');
const locales = ['zh', 'en', 'ja', 'de', 'fr', 'es', 'ru'];

function parseArgs(argv) {
  const options = {
    applyRetirements: false,
    failOnRetiredRefs: false,
    json: false,
    limit: 40,
    writeReport: null,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--apply-retirements') {
      options.applyRetirements = true;
    } else if (arg === '--fail-on-retired-refs') {
      options.failOnRetiredRefs = true;
    } else if (arg === '--json') {
      options.json = true;
    } else if (arg === '--write-report') {
      options.writeReport = argv[index + 1];
      index += 1;
    } else if (arg === '--limit') {
      options.limit = Number.parseInt(argv[index + 1], 10);
      index += 1;
    } else if (arg === '--help' || arg === '-h') {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  return options;
}

function printHelp() {
  console.log(`Usage: node scripts/maintain_i18n_catalog.js [options]

Options:
  --apply-retirements     Remove retired keys that have no lib/test references.
  --fail-on-retired-refs  Exit non-zero when retired keys are still referenced.
  --write-report <path>   Write the full maintenance report as JSON.
  --json                  Print the full maintenance report to stdout as JSON.
  --limit <count>         Limit human-readable samples. Default: 40.
  --help                  Show this help.

Default mode is report-only and does not modify files.`);
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

function quoteCsvCell(value) {
  const text = String(value ?? '');
  return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function writeCsvRows(filePath, rows) {
  const raw = rows.map((row) => row.map(quoteCsvCell).join(',')).join('\n');
  fs.writeFileSync(filePath, `${raw}\n`, 'utf8');
}

function readCsvCatalog(filePath) {
  const rows = parseCsvRows(fs.readFileSync(filePath, 'utf8'));
  if (rows.length === 0) {
    throw new Error(`Empty CSV catalog: ${filePath}`);
  }
  const header = rows[0].map((cell) => String(cell).trim());
  const keyIndex = header.indexOf('key');
  if (keyIndex < 0) {
    throw new Error('app_texts.csv is missing the key column');
  }
  const missingLocales = locales.filter((locale) => !header.includes(locale));
  const keyRows = rows.slice(1).filter((row) => {
    const key = String(row[keyIndex] ?? '').trim();
    return key.length > 0 && !key.startsWith('@@');
  });
  const counts = new Map();
  for (const row of keyRows) {
    const key = String(row[keyIndex] ?? '').trim();
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  const duplicateKeys = Array.from(counts.entries())
    .filter(([, count]) => count > 1)
    .map(([key, count]) => ({ key, count }))
    .sort((a, b) => a.key.localeCompare(b.key));

  return {
    rows,
    header,
    keyIndex,
    missingLocales,
    keyRows,
    keys: new Set(keyRows.map((row) => String(row[keyIndex]).trim())),
    duplicateKeys,
  };
}

function readRegistry(filePath) {
  const registry = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const entries = Array.isArray(registry.entries) ? registry.entries : [];
  const counts = new Map();
  for (const entry of entries) {
    if (typeof entry.id !== 'string' || entry.id.length === 0) {
      continue;
    }
    counts.set(entry.id, (counts.get(entry.id) ?? 0) + 1);
  }
  const duplicateIds = Array.from(counts.entries())
    .filter(([, count]) => count > 1)
    .map(([id, count]) => ({ id, count }))
    .sort((a, b) => a.id.localeCompare(b.id));
  return { registry, entries, duplicateIds };
}

function readRetirements(filePath) {
  if (!fs.existsSync(filePath)) {
    return { schemaVersion: '1.0.0', retirements: [] };
  }
  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const retirements = Array.isArray(data.retirements) ? data.retirements : [];
  const counts = new Map();
  for (const item of retirements) {
    if (typeof item.key !== 'string' || item.key.length === 0) {
      continue;
    }
    counts.set(item.key, (counts.get(item.key) ?? 0) + 1);
  }
  const duplicateKeys = Array.from(counts.entries())
    .filter(([, count]) => count > 1)
    .map(([key, count]) => ({ key, count }))
    .sort((a, b) => a.key.localeCompare(b.key));
  return { ...data, retirements, duplicateKeys };
}

function walk(dir, predicate, out = []) {
  if (!fs.existsSync(dir)) {
    return out;
  }
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const filePath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (
        entry.name === '.dart_tool' ||
        entry.name === 'build' ||
        entry.name === '.git'
      ) {
        continue;
      }
      walk(filePath, predicate, out);
    } else if (predicate(filePath)) {
      out.push(filePath);
    }
  }
  return out;
}

function relative(filePath) {
  return path.relative(root, filePath).replace(/\\/g, '/');
}

function lineOf(source, index) {
  return source.slice(0, index).split(/\r?\n/).length;
}

function scanLiteralCatalogRefs(catalogKeys) {
  const refs = new Map();
  for (const key of catalogKeys) {
    refs.set(key, []);
  }
  const dartFiles = [
    ...walk(path.join(root, 'lib'), (filePath) => filePath.endsWith('.dart')),
    ...walk(path.join(root, 'test'), (filePath) => filePath.endsWith('.dart')),
  ].sort();
  const stringPattern = /'((?:\\.|[^'\\])*)'|"((?:\\.|[^"\\])*)"/g;

  for (const filePath of dartFiles) {
    const source = fs.readFileSync(filePath, 'utf8');
    let match;
    while ((match = stringPattern.exec(source)) != null) {
      const literal = match[1] ?? match[2] ?? '';
      if (!catalogKeys.has(literal)) {
        continue;
      }
      refs.get(literal).push({
        file: relative(filePath),
        line: lineOf(source, match.index),
      });
    }
  }
  return refs;
}

function collectStaleRegistrySources(entries) {
  const stale = [];
  for (const entry of entries) {
    for (const source of Array.isArray(entry.sources) ? entry.sources : []) {
      if (typeof source.file !== 'string' || source.file.length === 0) {
        continue;
      }
      if (/[*?[\]]/.test(source.file)) {
        continue;
      }
      const absolute = path.join(root, source.file);
      if (!fs.existsSync(absolute)) {
        stale.push({
          id: entry.id,
          referencedKey: entry.referencedKey,
          file: source.file,
        });
      }
    }
  }
  return stale.sort((a, b) => {
    const fileCompare = a.file.localeCompare(b.file);
    return fileCompare === 0 ? String(a.id).localeCompare(String(b.id)) : fileCompare;
  });
}

function registryCatalogIds(entries) {
  return new Set(
    entries
      .filter((entry) => {
        const kind = String(entry.kind ?? '');
        return kind.includes('app_i18n_key') || kind.includes('catalog');
      })
      .map((entry) => entry.id)
      .filter((id) => typeof id === 'string' && id.length > 0),
  );
}

function buildReport() {
  const csv = readCsvCatalog(csvPath);
  const { registry, entries, duplicateIds } = readRegistry(registryPath);
  const retirements = readRetirements(retirementPath);
  const refs = scanLiteralCatalogRefs(csv.keys);
  const referencedKeys = new Set(
    Array.from(refs.entries())
      .filter(([, locations]) => locations.length > 0)
      .map(([key]) => key),
  );
  const registryIds = registryCatalogIds(entries);
  const staleRegistrySources = collectStaleRegistrySources(entries);

  const retiredKeys = new Set(
    retirements.retirements
      .filter((item) => item.appliedAt == null)
      .map((item) => item.key)
      .filter((key) => typeof key === 'string' && key.length > 0),
  );
  const retired = Array.from(retiredKeys)
    .sort()
    .map((key) => ({
      key,
      inCatalog: csv.keys.has(key),
      inRegistry: entries.some(
        (entry) => entry.id === key || entry.referencedKey === key,
      ),
      references: refs.get(key) ?? [],
    }));
  const retiredBlocked = retired.filter((item) => item.references.length > 0);
  const retiredReady = retired.filter(
    (item) => item.inCatalog && item.references.length === 0,
  );

  return {
    generatedAt: new Date().toISOString(),
    files: {
      csv: relative(csvPath),
      registry: relative(registryPath),
      retirements: relative(retirementPath),
    },
    summary: {
      catalogKeys: csv.keys.size,
      registryEntries: entries.length,
      literalReferencedCatalogKeys: referencedKeys.size,
      unreferencedCatalogKeys: csv.keys.size - referencedKeys.size,
      staleRegistrySources: staleRegistrySources.length,
      activeRetirements: retired.length,
      retiredReady: retiredReady.length,
      retiredBlocked: retiredBlocked.length,
    },
    fatal: {
      missingLocaleColumns: csv.missingLocales,
      duplicateCsvKeys: csv.duplicateKeys,
      duplicateRegistryIds: duplicateIds,
      duplicateRetirementKeys: retirements.duplicateKeys ?? [],
    },
    reportOnly: {
      catalogKeysMissingRegistry: Array.from(csv.keys)
        .filter((key) => !registryIds.has(key))
        .sort(),
      registryCatalogIdsMissingCsv: Array.from(registryIds)
        .filter((id) => !csv.keys.has(id))
        .sort(),
      unreferencedCatalogKeys: Array.from(csv.keys)
        .filter((key) => !referencedKeys.has(key))
        .sort(),
      staleRegistrySources,
    },
    retirements: {
      active: retired,
      ready: retiredReady,
      blocked: retiredBlocked,
      raw: retirements,
    },
    registry,
    csvRows: csv.rows,
    csvKeyIndex: csv.keyIndex,
  };
}

function applyRetirements(report) {
  const blocked = report.retirements.blocked;
  if (blocked.length > 0) {
    throw new Error(
      `Cannot apply retirements while keys are still referenced: ${blocked
        .map((item) => item.key)
        .join(', ')}`,
    );
  }
  const readyKeys = new Set(report.retirements.ready.map((item) => item.key));
  if (readyKeys.size === 0) {
    return { removedKeys: [] };
  }

  const filteredRows = report.csvRows.filter((row, index) => {
    if (index === 0) {
      return true;
    }
    const key = String(row[report.csvKeyIndex] ?? '').trim();
    return !readyKeys.has(key);
  });
  writeCsvRows(csvPath, filteredRows);

  const registry = report.registry;
  registry.entries = registry.entries.filter(
    (entry) => !readyKeys.has(entry.id) && !readyKeys.has(entry.referencedKey),
  );
  fs.writeFileSync(registryPath, `${JSON.stringify(registry, null, 2)}\n`, 'utf8');

  const raw = report.retirements.raw;
  const today = new Date().toISOString().slice(0, 10);
  raw.retirements = raw.retirements.map((item) =>
    readyKeys.has(item.key) && item.appliedAt == null
      ? { ...item, appliedAt: today }
      : item,
  );
  fs.writeFileSync(retirementPath, `${JSON.stringify(raw, null, 2)}\n`, 'utf8');
  return { removedKeys: Array.from(readyKeys).sort() };
}

function sample(items, limit) {
  return items.slice(0, Math.max(0, limit));
}

function printHumanReport(report, options, applyResult) {
  console.log('i18n maintenance report');
  console.log(`catalogKeys=${report.summary.catalogKeys}`);
  console.log(`registryEntries=${report.summary.registryEntries}`);
  console.log(
    `literalReferencedCatalogKeys=${report.summary.literalReferencedCatalogKeys}`,
  );
  console.log(`unreferencedCatalogKeys=${report.summary.unreferencedCatalogKeys}`);
  console.log(`staleRegistrySources=${report.summary.staleRegistrySources}`);
  console.log(
    `activeRetirements=${report.summary.activeRetirements}, ready=${report.summary.retiredReady}, blocked=${report.summary.retiredBlocked}`,
  );
  console.log(
    `fatal duplicateCsvKeys=${report.fatal.duplicateCsvKeys.length}, duplicateRegistryIds=${report.fatal.duplicateRegistryIds.length}, missingLocaleColumns=${report.fatal.missingLocaleColumns.length}`,
  );

  if (applyResult != null) {
    console.log(`appliedRetirements=${applyResult.removedKeys.length}`);
    for (const key of sample(applyResult.removedKeys, options.limit)) {
      console.log(`  removed ${key}`);
    }
  }

  const sections = [
    ['retired keys still referenced', report.retirements.blocked.map((item) => item.key)],
    ['retired keys ready for apply', report.retirements.ready.map((item) => item.key)],
    ['stale registry sources', report.reportOnly.staleRegistrySources.map((item) => `${item.file} -> ${item.id}`)],
    ['unreferenced catalog keys', report.reportOnly.unreferencedCatalogKeys],
  ];
  for (const [title, items] of sections) {
    if (items.length === 0) {
      continue;
    }
    console.log(`\n${title} (${items.length}, sample ${Math.min(options.limit, items.length)})`);
    for (const item of sample(items, options.limit)) {
      console.log(`  ${item}`);
    }
  }
}

function fatalCount(report) {
  return (
    report.fatal.missingLocaleColumns.length +
    report.fatal.duplicateCsvKeys.length +
    report.fatal.duplicateRegistryIds.length +
    report.fatal.duplicateRetirementKeys.length
  );
}

function stripInternalFields(report) {
  const { registry, csvRows, csvKeyIndex, ...publicReport } = report;
  return publicReport;
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  const report = buildReport();
  let applyResult = null;

  if (options.applyRetirements) {
    applyResult = applyRetirements(report);
  }

  const publicReport = stripInternalFields(report);
  if (options.writeReport != null) {
    const reportPath = path.resolve(root, options.writeReport);
    fs.mkdirSync(path.dirname(reportPath), { recursive: true });
    fs.writeFileSync(reportPath, `${JSON.stringify(publicReport, null, 2)}\n`, 'utf8');
  }

  if (options.json) {
    console.log(JSON.stringify(publicReport, null, 2));
  } else {
    printHumanReport(publicReport, options, applyResult);
  }

  if (fatalCount(publicReport) > 0) {
    process.exit(1);
  }
  if (options.failOnRetiredRefs && publicReport.retirements.blocked.length > 0) {
    process.exit(1);
  }
}

main();
