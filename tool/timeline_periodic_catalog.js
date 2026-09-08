/* Helpers for merging generated timeline text into the shared catalog. */

const fs = require('fs');

function buildEventCatalog(facts, locales) {
  const entries = [];
  for (const fact of facts) {
    entries.push([
      `toolbox.life.timeline.${fact.collection}.${fact.id}.date`,
      Object.fromEntries(locales.map((locale) => [locale, fact.dates[locale]])),
    ]);
    entries.push([
      `toolbox.life.timeline.${fact.collection}.${fact.id}.title`,
      Object.fromEntries(locales.map((locale) => [locale, fact.title[locale]])),
    ]);
    entries.push([
      `toolbox.life.timeline.${fact.collection}.${fact.id}.detail`,
      Object.fromEntries(locales.map((locale) => [locale, fact.detail[locale]])),
    ]);
  }
  return entries;
}

function addCatalogEntries(
  entries,
  sourcePaths,
  { catalogPath, registryPath, parseCsv, quoteCsv, readJson, replaceFile },
) {
  const rows = parseCsv(fs.readFileSync(catalogPath, 'utf8'));
  const header = rows.shift();
  const keyIndex = header.indexOf('key');
  const byKey = new Map(entries);
  const existing = new Set();
  const updated = [];
  for (const row of rows) {
    const key = row[keyIndex];
    if (!key) continue;
    existing.add(key);
    const texts = byKey.get(key);
    if (!texts) continue;
    for (let index = 0; index < header.length; index += 1) {
      const column = header[index];
      if (
        column !== 'key' &&
        Object.prototype.hasOwnProperty.call(texts, column)
      ) {
        row[index] = texts[column];
      }
    }
    updated.push(key);
  }
  const additions = [];
  for (const [key, texts] of entries) {
    if (existing.has(key)) continue;
    const row = header.map((column) =>
      column === 'key' ? key : texts[column] ?? '',
    );
    rows.push(row);
    additions.push(key);
  }
  const output =
    [header, ...rows]
      .map((row) => row.map(quoteCsv).join(','))
      .join('\n') +
    '\n';
  fs.writeFileSync(catalogPath, output, 'utf8');
  updateRegistry(
    entries.map(([key]) => key),
    entries,
    sourcePaths,
    additions,
    updated,
    { registryPath, readJson, replaceFile },
  );
  return additions;
}

function updateRegistry(
  keys,
  entries,
  sourcePaths,
  additions,
  updates,
  { registryPath, readJson, replaceFile },
) {
  const registry = readJson(registryPath, {
    schemaVersion: '1.0.0',
    entries: [],
  });
  const byKey = new Map(entries);
  for (const key of keys) {
    const textValues = byKey.get(key);
    const registered = registry.entries.find((entry) => entry.id === key);
    const placeholders = Array.from(
      String(textValues?.zh ?? '').matchAll(
        /\{([A-Za-z_][A-Za-z0-9_]*)\}/g,
      ),
    ).map((match) => match[1]);
    if (registered) {
      registered.texts = textValues;
      registered.placeholders = placeholders;
      continue;
    }
    registry.entries.push({
      id: key,
      kind: 'i18n_runtime_reference',
      status: 'runtime_wired',
      sourceSystem: 'AppI18n.t',
      texts: textValues,
      sources: [
        {
          file: sourcePaths[0],
          line: 1,
          context: 'PLAN_424 generated timeline and periodic-table data',
        },
      ],
      sourceCount: 1,
      placeholders,
    });
  }
  registry.summary = registry.summary ?? {};
  registry.summary.generatedAt = new Date().toISOString().slice(0, 10);
  registry.summary.updatedAt = new Date().toISOString().slice(0, 10);
  registry.summary.totals = registry.summary.totals ?? {};
  registry.summary.totals.entries = registry.entries.length;
  registry.summary.totals.appI18nKeys = registry.entries.filter((entry) =>
    entry.kind.includes('i18n'),
  ).length;
  registry.lastPlan424HistoryPeriodic = {
    date: new Date().toISOString().slice(0, 10),
    addedCatalogKeys: additions.length,
    updatedCatalogKeys: updates.length,
    source: 'Wikidata CC0 and PubChem offline caches',
  };
  replaceFile(registryPath, `${JSON.stringify(registry, null, 2)}\n`);
}

function writeManifest(
  legacyFacts,
  generalFacts,
  chinaFacts,
  elements,
  generalCopy,
  { manifestPath, writeJson, referenceYear },
) {
  writeJson(manifestPath, {
    schemaVersion: '1.0.0',
    generatedAt: new Date().toISOString(),
    referenceYear,
    collections: {
      general: {
        count: generalFacts.length + legacyFacts.length,
        target: '400-500 after merge',
      },
      china_overview: { count: chinaFacts.length, target: '100-150' },
    },
    curatedCopy: {
      file: 'tool/reference_data/history_timeline_general_copy.json',
      count: Object.keys(generalCopy).length,
    },
    sources: [
      {
        name: 'Wikidata',
        url: 'https://www.wikidata.org/wiki/Wikidata:Licensing',
        license: 'CC0 1.0',
      },
      {
        name: 'PubChem periodic table',
        url: 'https://pubchem.ncbi.nlm.nih.gov/rest/pug/periodictable/JSON',
        license: 'Public domain / NIH open data',
      },
      {
        name: 'The Met Open Access',
        url: 'https://www.metmuseum.org/hubs/open-access',
        license: 'CC0 for marked public-domain objects',
      },
      {
        name: 'IUPAC periodic table',
        url: 'https://iupac.org/what-we-do/periodic-table-of-elements/',
        license: 'Reference source; not redistributed',
      },
    ],
    unresolvedWikidata: [...generalFacts, ...chinaFacts]
      .filter((fact) => fact.qid == null)
      .map((fact) => fact.id),
    legacy: {
      count: legacyFacts.length,
      source: 'Existing reviewed in-app anchors retained with their catalog keys',
    },
    elements: {
      count: elements.length,
      fields: [
        'atomicMass',
        'standardState',
        'meltingPoint',
        'boilingPoint',
        'density',
        'atomicRadius',
        'ionizationEnergy',
        'electronAffinity',
        'oxidationStates',
      ],
    },
  });
}

module.exports = {
  addCatalogEntries,
  buildEventCatalog,
  writeManifest,
};
