#!/usr/bin/env node

/* Validate the checked-in offline timeline, periodic-table, and image data. */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const referenceDir = path.join(root, 'tool', 'reference_data');
const dataDir = path.join(
  root,
  'lib',
  'src',
  'ui',
  'pages',
  'toolbox_life_tools',
);

function fail(message) {
  throw new Error(`[timeline-periodic] ${message}`);
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function parseTsv(filePath) {
  const lines = fs
    .readFileSync(filePath, 'utf8')
    .split(/\r?\n/)
    .filter((line) => line.trim().length > 0);
  const header = lines
    .shift()
    .replace(/^\s*#\s*/, '')
    .split('\t');
  return lines.map((line, index) => {
    const cells = line.split('\t');
    if (cells.length !== header.length) {
      fail(`${path.basename(filePath)} row ${index + 2} has an invalid column count`);
    }
    return Object.fromEntries(header.map((key, cellIndex) => [key, cells[cellIndex]]));
  });
}

function assertUnique(values, label) {
  const seen = new Set();
  for (const value of values) {
    if (seen.has(value)) fail(`${label} contains duplicate ${value}`);
    seen.add(value);
  }
  return seen;
}

function readCatalogKeys() {
  const lines = fs
    .readFileSync(path.join(root, 'lib', 'l10n', 'catalog', 'app_texts.csv'), 'utf8')
    .split(/\r?\n/)
    .filter((line) => line.trim().length > 0);
  const keys = new Set(lines.slice(1).map((line) => line.split(',', 1)[0]));
  if (keys.size === 0) fail('catalog contains no keys');
  return keys;
}

function readGeneratedFacts(prefix) {
  const files = fs
    .readdirSync(dataDir)
    .filter((name) => name.startsWith(prefix) && name.endsWith('.dart'))
    .sort();
  if (files.length === 0) fail(`no generated files found for ${prefix}`);
  const facts = [];
  const pattern = /_TimelineFact\(\s*id:\s*'([^']+)',([\s\S]*?)\n\s*\),/g;
  for (const file of files) {
    const source = fs.readFileSync(path.join(dataDir, file), 'utf8');
    for (const match of source.matchAll(pattern)) {
      const body = match[2];
      const collection = body.match(/collection:\s*'([^']+)'/)?.[1] ?? '';
      const years = body.match(/yearsBeforePresent:\s*([0-9.]+)/)?.[1];
      const read = (field) => body.match(new RegExp(`${field}:\\s*'([^']*)'`))?.[1] ?? '';
      const imageAsset = body.match(/imageAsset:\s*'([^']+)'/)?.[1] ?? null;
      if (!collection || years == null) {
        fail(`${file} contains an incomplete fact ${match[1]}`);
      }
      facts.push({
        id: match[1],
        collection,
        yearsBeforePresent: Number(years),
        displayKey: read('displayKey'),
        titleKey: read('titleKey'),
        detailKey: read('detailKey'),
        sourceNameKey: read('sourceNameKey'),
        sourceUrl: read('sourceUrl'),
        imageAsset,
      });
    }
  }
  return facts;
}

function readGeneratedElements() {
  const files = fs
    .readdirSync(dataDir)
    .filter((name) => name.startsWith('toolbox_life_tools_timeline_periodic_element_data_') && name.endsWith('.dart'))
    .sort();
  const elements = [];
  const pattern = /_ElementFact\(\s*atomicNumber:\s*(\d+),([\s\S]*?)\n\s*\),/g;
  const requiredFields = [
    'symbol',
    'nameKey',
    'atomicMass',
    'groupBlock',
    'standardState',
    'period',
    'group',
    'displayRow',
    'displayColumn',
  ];
  for (const file of files) {
    const source = fs.readFileSync(path.join(dataDir, file), 'utf8');
    for (const match of source.matchAll(pattern)) {
      const body = match[2];
      const atomicNumber = Number(match[1]);
      for (const field of requiredFields) {
        if (!new RegExp(`\\b${field}:`).test(body)) {
          fail(`${file} element ${atomicNumber} is missing ${field}`);
        }
      }
      const readInt = (field) => Number(body.match(new RegExp(`${field}:\\s*(\\d+)`))?.[1]);
      elements.push({
        atomicNumber,
        period: readInt('period'),
        group: readInt('group'),
        displayRow: readInt('displayRow'),
        displayColumn: readInt('displayColumn'),
      });
    }
  }
  return elements;
}

function validateSourceRows() {
  const general = parseTsv(path.join(referenceDir, 'history_timeline_general.tsv'));
  const china = parseTsv(path.join(referenceDir, 'history_timeline_china.tsv'));
  const legacy = parseTsv(path.join(referenceDir, 'history_timeline_legacy.tsv'));
  if (general.length < 200 || general.length > 260) fail(`general seed count is ${general.length}`);
  if (china.length < 100 || china.length > 150) fail(`China overview count is ${china.length}`);
  if (legacy.length < 150) fail(`legacy anchor count is ${legacy.length}`);
  for (const [label, rows] of [['general', general], ['china', china], ['legacy', legacy]]) {
    assertUnique(rows.map((row) => row.id), `${label} TSV`);
    for (const row of rows) {
      if (!row.wikidata_search && label !== 'legacy') fail(`${label} row ${row.id} has no source query`);
      if (label === 'general' && !row.years_before_present && !row.start_year && !row.end_year) {
        fail(`general row ${row.id} has no date`);
      }
      if (label === 'china' && !row.start_year && !row.end_year) fail(`China row ${row.id} has no date`);
    }
  }
  return { general, china, legacy };
}

function validateGeneratedFacts(sourceRows) {
  const catalogKeys = readCatalogKeys();
  const factsByPrefix = {
    legacy: readGeneratedFacts('toolbox_life_tools_timeline_periodic_legacy_data_'),
    general: readGeneratedFacts('toolbox_life_tools_timeline_periodic_general_data_'),
    china: readGeneratedFacts('toolbox_life_tools_timeline_periodic_china_data_'),
  };
  const expected = {
    legacy: sourceRows.legacy.length,
    general: sourceRows.general.length,
    china: sourceRows.china.length,
  };
  for (const [label, facts] of Object.entries(factsByPrefix)) {
    if (facts.length !== expected[label]) {
      fail(`${label} generated count ${facts.length} != ${expected[label]}`);
    }
    assertUnique(facts.map((fact) => fact.id), `${label} generated data`);
    for (const fact of facts) {
      if (!Number.isFinite(fact.yearsBeforePresent) || fact.yearsBeforePresent < 0) {
        fail(`${label} fact ${fact.id} has an invalid date`);
      }
      for (const field of ['displayKey', 'titleKey', 'detailKey', 'sourceNameKey']) {
        if (!fact[field]) fail(`${label} fact ${fact.id} is missing ${field}`);
        if (!catalogKeys.has(fact[field])) {
          fail(`${label} fact ${fact.id} references missing catalog key ${fact[field]}`);
        }
      }
      if (!/^https?:\/\//.test(fact.sourceUrl)) {
        fail(`${label} fact ${fact.id} has an invalid source URL`);
      }
    }
  }
  const allFacts = Object.values(factsByPrefix).flat();
  assertUnique(
    allFacts.map((fact) => `${fact.collection}:${fact.id}`),
    'merged timeline data within each collection',
  );
  if (allFacts.length !== 544) fail(`all generated fact count is ${allFacts.length}`);
  return allFacts;
}

function validateElements() {
  const elements = readGeneratedElements();
  if (elements.length !== 118) fail(`generated element count is ${elements.length}`);
  assertUnique(elements.map((element) => element.atomicNumber), 'element atomic numbers');
  const positions = new Set();
  for (const element of elements) {
    if (element.atomicNumber < 1 || element.atomicNumber > 118) {
      fail(`element ${element.atomicNumber} is outside the official range`);
    }
    if (element.period < 1 || element.period > 7 || element.group < 1 || element.group > 18) {
      fail(`element ${element.atomicNumber} has an invalid period/group`);
    }
    if (element.displayRow < 1 || element.displayRow > 9 || element.displayColumn < 1 || element.displayColumn > 18) {
      fail(`element ${element.atomicNumber} has an invalid display position`);
    }
    const position = `${element.displayRow}:${element.displayColumn}`;
    if (positions.has(position)) fail(`duplicate element display position ${position}`);
    positions.add(position);
  }
  return elements;
}

function validateImages(facts) {
  const manifest = readJson(path.join(referenceDir, 'history_timeline_images.json'));
  if (!Array.isArray(manifest.images) || manifest.images.length !== 12) {
    fail('image manifest must contain exactly 12 images');
  }
  const assets = new Set();
  let totalBytes = 0;
  for (const image of manifest.images) {
    if (image.isPublicDomain !== true) fail(`image ${image.asset} is not marked public domain`);
    if (!/^assets\/toolbox\/history_timeline\/[^/]+\.webp$/.test(image.asset)) {
      fail(`image asset path is invalid: ${image.asset}`);
    }
    if (assets.has(image.asset)) fail(`duplicate image asset ${image.asset}`);
    assets.add(image.asset);
    const filePath = path.join(root, image.asset);
    if (!fs.existsSync(filePath)) fail(`missing image asset ${image.asset}`);
    const bytes = fs.readFileSync(filePath);
    if (bytes.length !== image.bytes) fail(`byte count mismatch for ${image.asset}`);
    if (bytes.subarray(0, 4).toString('ascii') !== 'RIFF' || bytes.subarray(8, 12).toString('ascii') !== 'WEBP') {
      fail(`asset is not a WebP RIFF file: ${image.asset}`);
    }
    const sha256 = crypto.createHash('sha256').update(bytes).digest('hex');
    if (sha256 !== image.sha256) fail(`SHA-256 mismatch for ${image.asset}`);
    if (image.objectId == null || image.isPublicDomain !== true || !image.objectUrl || !image.imageUrl) {
      fail(`image ${image.asset} is missing source metadata`);
    }
    totalBytes += bytes.length;
  }
  const generatedAssets = new Set(facts.filter((fact) => fact.imageAsset).map((fact) => fact.imageAsset));
  for (const asset of generatedAssets) {
    if (!assets.has(asset)) fail(`generated fact references unlisted image ${asset}`);
  }
  if (totalBytes !== manifest.derivative.totalBytes) fail('manifest totalBytes does not match assets');
  return { count: manifest.images.length, totalBytes };
}

function main() {
  const sourceRows = validateSourceRows();
  const facts = validateGeneratedFacts(sourceRows);
  const elements = validateElements();
  const images = validateImages(facts);
  console.log(JSON.stringify({
    generalSeed: sourceRows.general.length,
    legacyGeneral: sourceRows.legacy.length,
    generalMerged: sourceRows.general.length + sourceRows.legacy.length,
    allGeneratedFacts: facts.length,
    chinaOverview: sourceRows.china.length,
    elements: elements.length,
    images: images.count,
    imageBytes: images.totalBytes,
  }, null, 2));
}

main();
