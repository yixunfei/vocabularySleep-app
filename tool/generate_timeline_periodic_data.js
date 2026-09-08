#!/usr/bin/env node

/* Generate offline life-tool data; checked-in caches keep it reproducible. */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const {
  addCatalogEntries,
  buildEventCatalog,
  writeManifest,
} = require('./timeline_periodic_catalog');

const root = path.resolve(__dirname, '..');
const referenceDir = path.join(root, 'tool', 'reference_data');
const generalCopyPath = path.join(
  referenceDir,
  'history_timeline_general_copy.json',
);
const dataDir = path.join(
  root,
  'lib',
  'src',
  'ui',
  'pages',
  'toolbox_life_tools',
);
const catalogPath = path.join(root, 'lib', 'l10n', 'catalog', 'app_texts.csv');
const registryPath = path.join(
  root,
  'lib',
  'l10n',
  'catalog',
  'app_text_registry.json',
);
const locales = ['zh', 'en', 'ja', 'de', 'fr', 'es', 'ru'];
const referenceYear = 2026;
const legacyRelativeFiles = [
  'lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_data.dart',
  'lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_data.dart',
  'lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_premodern_data.dart',
  'lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_modern_data.dart',
];

function parseArgs(argv) {
  return {
    refreshWikidata: argv.includes('--refresh-wikidata'),
    refreshPubchem: argv.includes('--refresh-pubchem'),
  };
}

function parseTsv(filePath) {
  const lines = fs
    .readFileSync(filePath, 'utf8')
    .split(/\r?\n/)
    .filter((line) => line.trim().length > 0);
  if (lines.length === 0) {
    throw new Error(`Empty TSV: ${filePath}`);
  }
  const header = lines
    .shift()
    .replace(/^\s*#\s*/, '')
    .split('\t')
    .map((value) => value.trim());
  return lines.map((line, index) => {
    const cells = line.split('\t');
    if (cells.length !== header.length) {
      throw new Error(
        `${path.basename(filePath)} row ${index + 2} has ${cells.length} ` +
          `columns; expected ${header.length}`,
      );
    }
    return Object.fromEntries(header.map((key, cellIndex) => [key, cells[cellIndex]]));
  });
}

function parseLegacyFacts(source) {
  const facts = [];
  const pattern = /_TimelineFact\(\s*id:\s*'([^']+)',([\s\S]*?)\n\s*\),/g;
  for (const match of source.matchAll(pattern)) {
    const body = match[2];
    const read = (name) => body.match(new RegExp(`${name}:\\s*'([^']*)'`))?.[1] ?? '';
    const years = body.match(/yearsBeforePresent:\s*([0-9.]+)/)?.[1];
    if (!years || !read('displayKey') || !read('titleKey') || !read('detailKey')) {
      continue;
    }
    facts.push({
      id: match[1],
      category: read('category'),
      collection: 'general',
      yearsBeforePresent: Number(years),
      displayKey: read('displayKey'),
      titleKey: read('titleKey'),
      detailKey: read('detailKey'),
      sourceName: read('sourceName'),
      sourceUrl: read('sourceUrl'),
    });
  }
  return facts;
}

function legacySourceNameKey(sourceName, sourceUrl) {
  const source = `${sourceName ?? ''} ${sourceUrl ?? ''}`.toLowerCase();
  if (source.includes('britannica')) return 'toolbox.life.timeline.source.britannica';
  if (source.includes('smithsonian') || source.includes('humanorigins')) {
    return 'toolbox.life.timeline.source.smithsonian';
  }
  if (source.includes('metmuseum') || source.includes('met heilbrunn')) {
    return 'toolbox.life.timeline.source.met';
  }
  if (source.includes('nasa')) return 'toolbox.life.timeline.source.nasa';
  if (source.includes('usgs')) return 'toolbox.life.timeline.source.usgs';
  if (source.includes('unesco')) return 'toolbox.life.timeline.source.unesco';
  if (source.includes('nobel')) return 'toolbox.life.timeline.source.nobel';
  if (source.includes('wto')) return 'toolbox.life.timeline.source.wto';
  if (source.includes('cern')) return 'toolbox.life.timeline.source.cern';
  if (source.includes('darpa')) return 'toolbox.life.timeline.source.darpa';
  if (source.includes('cdc')) return 'toolbox.life.timeline.source.cdc';
  if (source.includes('iaea')) return 'toolbox.life.timeline.source.iaea';
  if (source.includes('who')) return 'toolbox.life.timeline.source.who';
  if (source.includes('noaa')) return 'toolbox.life.timeline.source.noaa';
  if (source.includes('nih')) return 'toolbox.life.timeline.source.nih';
  if (
    source.includes('archive') ||
    source.includes('office of the historian')
  ) {
    return 'toolbox.life.timeline.source.archives';
  }
  if (source.includes('european union')) return 'toolbox.life.timeline.source.eu';
  if (source.includes('iupac')) return 'toolbox.life.timeline.source.iupac';
  if (
    source.includes('stratigraphy') ||
    source.includes('international commission on stratigraphy')
  ) {
    return 'toolbox.life.timeline.source.ics';
  }
  if (source.includes('nato')) return 'toolbox.life.timeline.source.nato';
  if (source.includes('stanford')) return 'toolbox.life.timeline.source.stanford';
  if (source.includes('ligo')) return 'toolbox.life.timeline.source.ligo';
  if (source.includes('louvre')) return 'toolbox.life.timeline.source.louvre';
  if (source.includes('intel')) return 'toolbox.life.timeline.source.intel';
  if (
    source.includes('unfccc') ||
    source.includes('un digital') ||
    source.includes('united nations') ||
    /\bun\b/.test(source)
  ) {
    return 'toolbox.life.timeline.source.un';
  }
  return 'toolbox.life.timeline.source.reference';
}

function normalizeLegacyFact(row) {
  const sourceName = row.sourceName ?? row.source_name ?? '';
  const sourceUrl = row.sourceUrl ?? row.source_url ?? '';
  const years = numeric(row.yearsBeforePresent ?? row.years_before_present);
  const fact = {
    id: row.id,
    category: row.category ?? '',
    collection: 'general',
    yearsBeforePresent: years,
    displayKey: row.displayKey ?? row.display_key ?? '',
    titleKey: row.titleKey ?? row.title_key ?? '',
    detailKey: row.detailKey ?? row.detail_key ?? '',
    sourceName,
    sourceNameKey:
      row.sourceNameKey ?? legacySourceNameKey(sourceName, sourceUrl),
    sourceUrl,
  };
  if (!fact.id || years == null) {
    throw new Error(`Legacy timeline fact ${fact.id ?? '(unknown)'} has no date`);
  }
  if (!fact.displayKey || !fact.titleKey || !fact.detailKey) {
    throw new Error(`Legacy timeline fact ${fact.id} has incomplete catalog keys`);
  }
  return fact;
}

function loadLegacyFacts() {
  const legacyPath = path.join(referenceDir, 'history_timeline_legacy.tsv');
  if (fs.existsSync(legacyPath)) {
    return parseTsv(legacyPath).map(normalizeLegacyFact);
  }
  const all = [];
  for (const relativeFile of legacyRelativeFiles) {
    try {
      const source = execFileSync('git', ['show', `HEAD:${relativeFile}`], {
        cwd: root,
        encoding: 'utf8',
        maxBuffer: 16 * 1024 * 1024,
      });
      all.push(...parseLegacyFacts(source));
    } catch (error) {
      throw new Error(`Cannot read legacy timeline source ${relativeFile}: ${error.message ?? error}`);
    }
  }
  const unique = [
    ...new Map(
      all.map((fact) => {
        const normalized = normalizeLegacyFact(fact);
        return [normalized.id, normalized];
      }),
    ).values(),
  ];
  const header = '# id\tcategory\tyears_before_present\tdisplay_key\ttitle_key\tdetail_key\tsource_name\tsource_url';
  const rows = unique.map((fact) => [
    fact.id,
    fact.category,
    fact.yearsBeforePresent,
    fact.displayKey,
    fact.titleKey,
    fact.detailKey,
    fact.sourceName,
    fact.sourceUrl,
  ].join('\t'));
  fs.writeFileSync(legacyPath, `${header}\n${rows.join('\n')}\n`, 'utf8');
  return unique;
}

function parseCsv(raw) {
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;
  for (let index = 0; index < raw.length; index += 1) {
    const char = raw[index];
    if (quoted) {
      if (char === '"' && raw[index + 1] === '"') {
        field += '"';
        index += 1;
      } else if (char === '"') {
        quoted = false;
      } else {
        field += char;
      }
    } else if (char === '"') {
      quoted = true;
    } else if (char === ',') {
      row.push(field);
      field = '';
    } else if (char === '\n' || char === '\r') {
      if (char === '\r' && raw[index + 1] === '\n') index += 1;
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
    } else {
      field += char;
    }
  }
  if (field.length > 0 || row.length > 0) {
    row.push(field);
    rows.push(row);
  }
  return rows;
}

function quoteCsv(value) {
  const text = String(value ?? '');
  return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function readJson(filePath, fallback) {
  if (!fs.existsSync(filePath)) return fallback;
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function loadGeneralCopy() {
  const data = readJson(generalCopyPath, { events: {} });
  return data.events ?? {};
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
}

function replaceFile(filePath, contents) {
  const tempPath = `${filePath}.${process.pid}.tmp`;
  fs.writeFileSync(tempPath, contents, 'utf8');
  try {
    for (let attempt = 0; attempt < 5; attempt += 1) {
      try {
        fs.renameSync(tempPath, filePath);
        return;
      } catch (error) {
        if (attempt === 4) {
          // Some Windows file watchers deny rename while allowing a shared
          // write. Keep the atomic path first, then use a byte-for-byte copy.
          fs.copyFileSync(tempPath, filePath);
          return;
        }
      }
    }
  } finally {
    if (fs.existsSync(tempPath)) fs.unlinkSync(tempPath);
  }
}

function fetchViaPowerShell(url) {
  const command = [
    "$headers=@{'User-Agent'='vocabularySleep-app/1.0 (open-data-preparation)'}",
    `Invoke-RestMethod -Uri '${url}' -Headers $headers | ConvertTo-Json -Depth 40`,
  ].join('; ');
  const output = execFileSync(
    'powershell.exe',
    ['-NoProfile', '-NonInteractive', '-Command', command],
    { encoding: 'utf8', timeout: 90000, maxBuffer: 32 * 1024 * 1024 },
  );
  return JSON.parse(output);
}

function humanize(value) {
  return value
    .replace(/[_-]+/g, ' ')
    .replace(/\b\w/g, (character) => character.toUpperCase());
}

function parseBoolean(value) {
  return String(value).trim().toLowerCase() === 'true';
}

function numeric(value) {
  if (value == null || String(value).trim() === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function yearsBeforePresent(row) {
  const direct = numeric(row.years_before_present);
  if (direct != null) return Math.max(0, direct);
  const start = numeric(row.start_year);
  const end = numeric(row.end_year);
  if (start == null && end == null) {
    throw new Error(`Missing date for ${row.id}`);
  }
  const midpoint = ((start ?? end) + (end ?? start)) / 2;
  return Math.max(0, referenceYear - midpoint);
}

function formatAgo(value, locale, approximate) {
  const prefix = approximate ? 'c. ' : '';
  if (locale === 'zh') {
    const unit = value >= 1e9 ? `${(value / 1e8).toFixed(value >= 1e10 ? 0 : 1)} 亿`
      : value >= 1e6 ? `${(value / 1e6).toFixed(value >= 1e7 ? 0 : 1)} 百万`
      : value >= 1e3 ? `${(value / 1e3).toFixed(value >= 1e4 ? 0 : 1)} 千`
      : `${Math.round(value)}`;
    return `${approximate ? '约 ' : ''}${unit}年前`;
  }
  const unit = value >= 1e9 ? `${(value / 1e9).toFixed(value >= 1e10 ? 0 : 1)} billion years`
    : value >= 1e6 ? `${(value / 1e6).toFixed(value >= 1e7 ? 0 : 1)} million years`
    : value >= 1e3 ? `${(value / 1e3).toFixed(value >= 1e4 ? 0 : 1)} thousand years`
    : `${Math.round(value)} years`;
  return `${prefix}${unit} ago`;
}

function formatYear(year, locale) {
  const value = Math.abs(year);
  if (locale === 'zh') return year < 0 ? `公元前${value}年` : `${value}年`;
  if (locale === 'en') return year < 0 ? `${value} BCE` : `${value} CE`;
  return year < 0 ? `${value} BCE` : `${value} CE`;
}

function dateTexts(row) {
  const direct = numeric(row.years_before_present);
  if (direct != null) {
    return Object.fromEntries(
      locales.map((locale) => [
        locale,
        formatAgo(direct, locale, parseBoolean(row.approximate)),
      ]),
    );
  }
  const start = numeric(row.start_year);
  const end = numeric(row.end_year);
  const values = locales.map((locale) => {
    const first = formatYear(start ?? end, locale);
    const last = formatYear(end ?? start, locale);
    if (first === last) return `${parseBoolean(row.approximate) ? (locale === 'zh' ? '约' : 'c. ') : ''}${first}`;
    return `${parseBoolean(row.approximate) ? (locale === 'zh' ? '约' : 'c. ') : ''}${first}–${last}`;
  });
  return Object.fromEntries(locales.map((locale, index) => [locale, values[index]]));
}

function cacheKey(value) {
  return value.trim().toLowerCase();
}

function loadWikidata(rows, refresh) {
  const cachePath = path.join(referenceDir, 'wikidata_cache.json');
  const cache = readJson(cachePath, { schemaVersion: '1.0.0', entities: {} });
  const searches = [...new Set(rows.map((row) => row.wikidata_search).filter(Boolean))];
  if (!refresh) return cache;
  let changed = false;
  for (const search of searches) {
    const key = cacheKey(search);
    if (cache.entities[key]) continue;
    const url =
      'https://www.wikidata.org/w/api.php?action=wbsearchentities&search=' +
      `${encodeURIComponent(search)}&language=en&uselang=en&format=json&limit=5`;
    try {
      const result = fetchViaPowerShell(url);
      const candidates = Array.isArray(result.search) ? result.search : [];
      const exact = candidates.find(
        (candidate) => cacheKey(candidate.label ?? '') === key,
      );
      const selected = exact ?? candidates[0];
      const labels = {};
      const descriptions = {};
      if (selected?.label) labels.en = selected.label;
      if (selected?.description) descriptions.en = selected.description;
      cache.entities[key] = {
        qid: selected?.id ?? null,
        candidates: candidates.slice(0, 5).map((candidate) => ({
          qid: candidate.id,
          label: candidate.label ?? '',
          description: candidate.description ?? '',
        })),
        labels,
        descriptions,
      };
      changed = true;
    } catch (error) {
      cache.entities[key] = {
        qid: null,
        candidates: [],
        labels: {},
        descriptions: {},
        error: String(error.message ?? error),
      };
      changed = true;
    }
  }
  if (refresh) changed ||= hydrateWikidata(cache);
  if (changed) writeJson(cachePath, cache);
  return cache;
}

function resolveEntity(cache, search) {
  return cache.entities[cacheKey(search)] ?? null;
}

function localizedFromEntity(entity, field, locale) {
  return entity?.[field]?.[locale] ?? '';
}

function applyEntityTranslations(target, entity) {
  for (const field of ['labels', 'descriptions']) {
    for (const locale of locales) {
      const value = entity?.[field]?.[locale]?.value;
      if (value) target[field][locale] = value;
    }
  }
}

function hydrateWikidata(cache) {
  const entriesByQid = new Map();
  for (const entry of Object.values(cache.entities ?? {})) {
    if (!entry?.qid) continue;
    const entries = entriesByQid.get(entry.qid) ?? [];
    entries.push(entry);
    entriesByQid.set(entry.qid, entries);
  }
  const qids = [...entriesByQid.keys()];
  let changed = false;
  for (let start = 0; start < qids.length; start += 50) {
    const batch = qids.slice(start, start + 50);
    const url =
      'https://www.wikidata.org/w/api.php?action=wbgetentities&ids=' +
      `${batch.join('|')}&props=labels|descriptions&languages=${locales.join('|')}&format=json`;
    try {
      const result = fetchViaPowerShell(url);
      for (const [qid, entity] of Object.entries(result.entities ?? {})) {
        for (const entry of entriesByQid.get(qid) ?? []) {
          const before = JSON.stringify([entry.labels, entry.descriptions]);
          applyEntityTranslations(entry, entity);
          changed ||= before !== JSON.stringify([entry.labels, entry.descriptions]);
        }
      }
    } catch (error) {
      console.warn(
        `Wikidata label hydration failed for ${batch.length} entities: ${error.message ?? error}`,
      );
    }
  }
  return changed;
}

function fallbackDetail(row, locale, title) {
  const templates = {
    cosmic: {
      zh: '该节点概括宇宙演化中的关键阶段，年代依据天文学观测与模型估计。',
      en: 'This node summarizes a key stage of cosmic evolution, dated from astronomical observations and models.',
    },
    earth: {
      zh: '该节点概括地球环境或生物演化的重要转折，具体年代会随研究更新。',
      en: 'This node summarizes a major turn in Earth history or biological evolution; dates may be refined as research advances.',
    },
    human: {
      zh: '考古与人类学证据将该节点用于讨论早期人类的技术、迁徙或社会行为。',
      en: 'Archaeological and anthropological evidence uses this node to discuss early human technology, movement, or behavior.',
    },
    civilization: {
      zh: '该节点概括一项文明、制度或跨区域交流的发展，证据来自考古材料与历史文献。',
      en: 'This node summarizes a development in civilization, institutions, or long-distance exchange, based on archaeology and historical records.',
    },
    science: {
      zh: '该节点记录知识、技术或科学方法的一项重要进展，影响范围因领域而异。',
      en: 'This node records an important advance in knowledge, technology, or scientific method, with impact varying by field.',
    },
    modern: {
      zh: '该节点概括近现代国际、政治或社会进程中的重要转折，采用描述性表述。',
      en: 'This node summarizes an important turn in modern international, political, or social history using descriptive wording.',
    },
  };
  const copy = templates[row.category.trim()] ?? templates.modern;
  return `${title}: ${copy[locale === 'zh' ? 'zh' : 'en']}`;
}

function textForGeneral(row, entity, field, locale) {
  const cached = localizedFromEntity(entity, field, locale);
  if (cached) return cached;
  const english = localizedFromEntity(entity, field, 'en');
  if (english) return english;
  if (field === 'labels') return humanize(row.id);
  return fallbackDetail(row, locale, humanize(row.id));
}

function imageAsset(row) {
  return row.image_id ? `assets/toolbox/history_timeline/${row.image_id}.webp` : null;
}

function dartString(value) {
  return String(value ?? '')
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/\$/g, '\\$');
}

function factSourceUrl(entity, search) {
  return entity?.qid
    ? `https://www.wikidata.org/wiki/${entity.qid}`
    : `https://www.wikidata.org/w/index.php?search=${encodeURIComponent(search)}`;
}

function buildFacts(rows, cache, collection, copyById = {}) {
  return rows.map((row) => {
    const entity = resolveEntity(cache, row.wikidata_search);
    const copy = copyById[row.id] ?? {};
    const titleZh =
      row.title_zh || copy.title_zh || textForGeneral(row, entity, 'labels', 'zh');
    const titleEn =
      row.title_en || copy.title_en || textForGeneral(row, entity, 'labels', 'en');
    const detailZh =
      row.detail_zh ||
      row.note_zh ||
      copy.detail_zh ||
      textForGeneral(row, entity, 'descriptions', 'zh');
    const detailEn =
      row.detail_en ||
      row.note_en ||
      copy.detail_en ||
      textForGeneral(row, entity, 'descriptions', 'en');
    const title = Object.fromEntries(
      locales.map((locale) => [locale, locale === 'zh' ? titleZh : titleEn]),
    );
    const detail = Object.fromEntries(
      locales.map((locale) => [
        locale,
        locale === 'zh' ? detailZh : detailEn,
      ]),
    );
    return {
      id: row.id,
      category: row.category.trim(),
      collection,
      yearsBeforePresent: yearsBeforePresent(row),
      dates: dateTexts(row),
      title,
      detail,
      sourceNameKey: 'toolbox.life.timeline.source.wikidata',
      sourceUrl: factSourceUrl(entity, row.wikidata_search || row.id),
      imageAsset: imageAsset(row),
      qid: entity?.qid ?? null,
      search: row.wikidata_search || row.id,
    };
  });
}

function factDart(fact, index) {
  const dateKey = fact.displayKey || `toolbox.life.timeline.${fact.collection}.${fact.id}.date`;
  const titleKey = fact.titleKey || `toolbox.life.timeline.${fact.collection}.${fact.id}.title`;
  const detailKey = fact.detailKey || `toolbox.life.timeline.${fact.collection}.${fact.id}.detail`;
  const lines = [
    '  _TimelineFact(',
    `    id: '${dartString(fact.id)}',`,
    `    collection: '${dartString(fact.collection)}',`,
    `    category: '${dartString(fact.category)}',`,
    `    yearsBeforePresent: ${fact.yearsBeforePresent},`,
    `    displayKey: '${dateKey}',`,
    `    titleKey: '${titleKey}',`,
    `    detailKey: '${detailKey}',`,
    `    sourceNameKey: '${fact.sourceNameKey || 'toolbox.life.timeline.source.wikidata'}',`,
    `    sourceUrl: '${dartString(fact.sourceUrl)}',`,
  ];
  if (fact.imageAsset) lines.push(`    imageAsset: '${fact.imageAsset}',`);
  lines.push('  ),');
  return lines.join('\n');
}

function writeFactParts(name, facts, perPart) {
  const paths = [];
  for (let start = 0, part = 1; start < facts.length; start += perPart, part += 1) {
    const chunk = facts.slice(start, start + perPart);
    const variable = `_${name}TimelineFacts${String(part).padStart(2, '0')}`;
    const fileName = `toolbox_life_tools_timeline_periodic_${name}_data_${String(part).padStart(2, '0')}.dart`;
    const filePath = path.join(dataDir, fileName);
    const body = [
      "part of '../toolbox_life_tools.dart';",
      '',
      `const List<_TimelineFact> ${variable} = <_TimelineFact>[`,
      ...chunk.map(factDart),
      '];',
      '',
    ].join('\n');
    fs.writeFileSync(filePath, body, 'utf8');
    paths.push({ fileName, variable, facts: chunk });
  }
  return paths;
}

function writeTimelineAggregate(legacyParts, generalParts, chinaParts) {
  const spreads = [...legacyParts, ...generalParts, ...chinaParts]
    .map((part) => `  ...${part.variable},`)
    .join('\n');
  const body = [
    "part of '../toolbox_life_tools.dart';",
    '',
    'final List<_TimelineFact> _timelineFacts = _sortedTimelineFacts(<_TimelineFact>[',
    spreads,
    ']);',
    '',
  'List<_TimelineFact> _sortedTimelineFacts(List<_TimelineFact> facts) {',
  '  final unique = <String, _TimelineFact>{};',
  '  for (final fact in facts) {',
    "    unique.putIfAbsent('${fact.collection}:${fact.id}', () => fact);",
  '  }',
    '  final sorted = unique.values.toList()',
    '    ..sort((a, b) => b.yearsBeforePresent.compareTo(a.yearsBeforePresent));',
    '  return List<_TimelineFact>.unmodifiable(sorted);',
    '}',
    '',
  ].join('\n');
  fs.writeFileSync(
    path.join(dataDir, 'toolbox_life_tools_timeline_periodic_history_data.dart'),
    body,
    'utf8',
  );
}

function parsePubchemRows(table) {
  const rows = table?.Table?.Row ?? table?.Table?.Row ?? [];
  return rows.map((row) => {
    const cells = Array.isArray(row.Cell) ? row.Cell : [];
    return Object.fromEntries([
      'atomicNumber',
      'symbol',
      'name',
      'atomicMass',
      'color',
      'electronConfiguration',
      'electronegativity',
      'atomicRadius',
      'ionizationEnergy',
      'electronAffinity',
      'oxidationStates',
      'standardState',
      'meltingPoint',
      'boilingPoint',
      'density',
      'groupBlock',
      'yearDiscovered',
    ].map((key, index) => [key, String(cells[index] ?? '')]));
  });
}

function loadPubchem(refresh) {
  const cachePath = path.join(referenceDir, 'pubchem_periodic_table.json');
  if (!refresh && fs.existsSync(cachePath)) return readJson(cachePath, {});
  try {
    const table = fetchViaPowerShell(
      'https://pubchem.ncbi.nlm.nih.gov/rest/pug/periodictable/JSON',
    );
    writeJson(cachePath, table);
    return table;
  } catch (error) {
    if (fs.existsSync(cachePath)) return readJson(cachePath, {});
    throw new Error(`Unable to load PubChem data: ${error.message ?? error}`);
  }
}

const groupByAtomicNumber = new Map([
  [1, 1], [2, 18], [3, 1], [4, 2], [5, 13], [6, 14], [7, 15], [8, 16], [9, 17], [10, 18],
  [11, 1], [12, 2], [13, 13], [14, 14], [15, 15], [16, 16], [17, 17], [18, 18],
  [19, 1], [20, 2], [21, 3], [22, 4], [23, 5], [24, 6], [25, 7], [26, 8], [27, 9], [28, 10], [29, 11], [30, 12], [31, 13], [32, 14], [33, 15], [34, 16], [35, 17], [36, 18],
  [37, 1], [38, 2], [39, 3], [40, 4], [41, 5], [42, 6], [43, 7], [44, 8], [45, 9], [46, 10], [47, 11], [48, 12], [49, 13], [50, 14], [51, 15], [52, 16], [53, 17], [54, 18],
  [55, 1], [56, 2], [72, 4], [73, 5], [74, 6], [75, 7], [76, 8], [77, 9], [78, 10], [79, 11], [80, 12], [81, 13], [82, 14], [83, 15], [84, 16], [85, 17], [86, 18],
  [87, 1], [88, 2], [104, 4], [105, 5], [106, 6], [107, 7], [108, 8], [109, 9], [110, 10], [111, 11], [112, 12], [113, 13], [114, 14], [115, 15], [116, 16], [117, 17], [118, 18],
]);

function elementPeriod(atomicNumber) {
  return atomicNumber <= 2 ? 1
    : atomicNumber <= 10 ? 2
    : atomicNumber <= 18 ? 3
    : atomicNumber <= 36 ? 4
    : atomicNumber <= 54 ? 5
    : atomicNumber <= 86 ? 6
    : 7;
}

function elementPosition(atomicNumber) {
  if (atomicNumber >= 57 && atomicNumber <= 71) {
    return { row: 8, column: atomicNumber - 54 };
  }
  if (atomicNumber >= 89 && atomicNumber <= 103) {
    return { row: 9, column: atomicNumber - 86 };
  }
  return {
    row: elementPeriod(atomicNumber),
    column: groupByAtomicNumber.get(atomicNumber) ?? 18,
  };
}

const chineseElementNames = [
  '氢', '氦', '锂', '铍', '硼', '碳', '氮', '氧', '氟', '氖', '钠', '镁', '铝', '硅', '磷', '硫', '氯', '氩', '钾', '钙', '钪', '钛', '钒', '铬', '锰', '铁', '钴', '镍', '铜', '锌', '镓', '锗', '砷', '硒', '溴', '氪', '铷', '锶', '钇', '锆', '铌', '钼', '锝', '钌', '铑', '钯', '银', '镉', '铟', '锡', '锑', '碲', '碘', '氙', '铯', '钡', '镧', '铈', '镨', '钕', '钷', '钐', '铕', '钆', '铽', '镝', '钬', '铒', '铥', '镱', '镥', '铪', '钽', '钨', '铼', '锇', '铱', '铂', '金', '汞', '铊', '铅', '铋', '钋', '砹', '氡', '钫', '镭', '锕', '钍', '镤', '铀', '镎', '钚', '镅', '锔', '锫', '锎', '锿', '镄', '钔', '锘', '铹', '𬬻', '𬭊', '𬭳', '𬭛', '𬭶', '鿏', '𫟼', '𬬭', '鿔', '鿭', '𫓧', '镆', '𫟷', '鿬', '鿫',
];

const blockSlugs = {
  'Alkali metal': 'alkali_metal',
  'Alkaline earth metal': 'alkaline_earth_metal',
  'Transition metal': 'transition_metal',
  'Post-transition metal': 'post_transition_metal',
  Metalloid: 'metalloid',
  Nonmetal: 'nonmetal',
  Halogen: 'halogen',
  'Noble gas': 'noble_gas',
  Lanthanide: 'lanthanide',
  Actinide: 'actinide',
};

function elementFacts(table) {
  const rows = parsePubchemRows(table).sort(
    (a, b) => Number(a.atomicNumber) - Number(b.atomicNumber),
  );
  if (rows.length !== 118) throw new Error(`PubChem returned ${rows.length} elements`);
  return rows.map((row) => {
    const atomicNumber = Number(row.atomicNumber);
    const position = elementPosition(atomicNumber);
    const slug = row.symbol.toLowerCase();
    return {
      ...row,
      atomicNumber,
      nameKey: `toolbox.life.element.${slug}.name`,
      blockKey: `toolbox.life.element.block.${blockSlugs[row.groupBlock] ?? 'unknown'}`,
      period: elementPeriod(atomicNumber),
      group: groupByAtomicNumber.get(atomicNumber) ?? 3,
      displayRow: position.row,
      displayColumn: position.column,
    };
  });
}

function elementDart(element) {
  const values = [
    `    atomicNumber: ${element.atomicNumber},`,
    `    symbol: '${dartString(element.symbol)}',`,
    `    nameKey: '${element.nameKey}',`,
    `    nameEn: '${dartString(element.name)}',`,
    `    atomicMass: '${dartString(element.atomicMass)}',`,
    `    groupBlock: '${dartString(element.groupBlock)}',`,
    `    groupBlockKey: '${element.blockKey}',`,
    `    standardState: '${dartString(element.standardState)}',`,
    `    yearDiscovered: '${dartString(element.yearDiscovered)}',`,
    `    electronConfiguration: '${dartString(element.electronConfiguration)}',`,
    `    electronegativity: '${dartString(element.electronegativity)}',`,
    `    atomicRadius: '${dartString(element.atomicRadius)}',`,
    `    ionizationEnergy: '${dartString(element.ionizationEnergy)}',`,
    `    electronAffinity: '${dartString(element.electronAffinity)}',`,
    `    oxidationStates: '${dartString(element.oxidationStates)}',`,
    `    meltingPoint: '${dartString(element.meltingPoint)}',`,
    `    boilingPoint: '${dartString(element.boilingPoint)}',`,
    `    density: '${dartString(element.density)}',`,
    `    period: ${element.period},`,
    `    group: ${element.group},`,
    `    displayRow: ${element.displayRow},`,
    `    displayColumn: ${element.displayColumn},`,
  ];
  return ['  _ElementFact(', ...values, '  ),'].join('\n');
}

function writeElementParts(elements, perPart) {
  const paths = [];
  for (let start = 0, part = 1; start < elements.length; start += perPart, part += 1) {
    const chunk = elements.slice(start, start + perPart);
    const variable = `_elementFacts${String(part).padStart(2, '0')}`;
    const fileName = `toolbox_life_tools_timeline_periodic_element_data_${String(part).padStart(2, '0')}.dart`;
    fs.writeFileSync(
      path.join(dataDir, fileName),
      [
        "part of '../toolbox_life_tools.dart';",
        '',
        `const List<_ElementFact> ${variable} = <_ElementFact>[`,
        ...chunk.map(elementDart),
        '];',
        '',
      ].join('\n'),
      'utf8',
    );
    paths.push({ fileName, variable, elements: chunk });
  }
  return paths;
}

function writeElementAggregate(parts) {
  fs.writeFileSync(
    path.join(dataDir, 'toolbox_life_tools_timeline_periodic_element_data.dart'),
    [
      "part of '../toolbox_life_tools.dart';",
      '',
      'const List<_ElementFact> _elementFacts = <_ElementFact>[',
      ...parts.map((part) => `  ...${part.variable},`),
      '];',
      '',
    ].join('\n'),
    'utf8',
  );
}

function localizedValues(zh, en, others = {}) {
  return {
    zh,
    en,
    ...Object.fromEntries(locales.filter((locale) => !['zh', 'en'].includes(locale)).map((locale) => [locale, others[locale] ?? en])),
  };
}

function uiCatalogEntries(elements) {
  const entries = [
    ['toolbox.life.timeline.collection.general', localizedValues('通用历史年表', 'General history timeline')],
    ['toolbox.life.timeline.collection.china_overview', localizedValues('中国历史年表概要', 'China history overview')],
    ['toolbox.life.timeline.source.wikidata', localizedValues('Wikidata（CC0 数据）', 'Wikidata (CC0 data)')],
    ['toolbox.life.timeline.source.met', localizedValues('大都会艺术博物馆开放数据', 'The Met Open Access')],
    ['toolbox.life.timeline.source.britannica', localizedValues('大英百科全书', 'Encyclopaedia Britannica')],
    ['toolbox.life.timeline.source.smithsonian', localizedValues('史密森学会', 'Smithsonian Institution')],
    ['toolbox.life.timeline.source.nasa', localizedValues('NASA 科学资料', 'NASA Science')],
    ['toolbox.life.timeline.source.usgs', localizedValues('美国地质调查局', 'U.S. Geological Survey')],
    ['toolbox.life.timeline.source.unesco', localizedValues('联合国教科文组织', 'UNESCO')],
    ['toolbox.life.timeline.source.nobel', localizedValues('诺贝尔奖资料', 'Nobel Prize')],
    ['toolbox.life.timeline.source.wto', localizedValues('世界贸易组织', 'World Trade Organization')],
    ['toolbox.life.timeline.source.cern', localizedValues('欧洲核子研究中心', 'CERN')],
    ['toolbox.life.timeline.source.darpa', localizedValues('美国国防高级研究计划局', 'DARPA')],
    ['toolbox.life.timeline.source.cdc', localizedValues('美国疾病控制与预防中心', 'CDC')],
    ['toolbox.life.timeline.source.iaea', localizedValues('国际原子能机构', 'IAEA')],
    ['toolbox.life.timeline.source.who', localizedValues('世界卫生组织', 'WHO')],
    ['toolbox.life.timeline.source.noaa', localizedValues('美国国家海洋和大气管理局', 'NOAA')],
    ['toolbox.life.timeline.source.nih', localizedValues('美国国立卫生研究院', 'NIH')],
    ['toolbox.life.timeline.source.archives', localizedValues('国家档案馆', 'National Archives')],
    ['toolbox.life.timeline.source.eu', localizedValues('欧盟资料', 'European Union')],
    ['toolbox.life.timeline.source.iupac', localizedValues('国际纯粹与应用化学联合会', 'IUPAC')],
    ['toolbox.life.timeline.source.ics', localizedValues('国际地层委员会', 'International Commission on Stratigraphy')],
    ['toolbox.life.timeline.source.nato', localizedValues('北约资料', 'NATO')],
    ['toolbox.life.timeline.source.stanford', localizedValues('斯坦福大学人工智能指数', 'Stanford AI Index')],
    ['toolbox.life.timeline.source.ligo', localizedValues('LIGO', 'LIGO')],
    ['toolbox.life.timeline.source.louvre', localizedValues('卢浮宫', 'Louvre')],
    ['toolbox.life.timeline.source.intel', localizedValues('英特尔', 'Intel')],
    ['toolbox.life.timeline.source.un', localizedValues('联合国资料', 'United Nations')],
    ['toolbox.life.timeline.source.reference', localizedValues('参考资料', 'Reference source')],
    ['toolbox.life.timeline.search', localizedValues('搜索事件或年份', 'Search events or years')],
    ['toolbox.life.timeline.search_hint', localizedValues('输入标题、关键词或年份', 'Enter a title, keyword, or year')],
    ['toolbox.life.timeline.clear_search', localizedValues('清除搜索', 'Clear search')],
    ['toolbox.life.timeline.date.unknown', localizedValues('暂无年代', 'Date unavailable')],
    ['toolbox.life.timeline.image.attribution', localizedValues('图片来源与许可', 'Image source and license')],
    ['toolbox.life.timeline.image.unavailable', localizedValues('图片暂不可用', 'Image unavailable')],
    ['toolbox.life.timeline.image.open_source', localizedValues('查看来源', 'View source')],
    ['toolbox.life.timeline.overview_title', localizedValues('历史年表概要', 'Timeline overview')],
    ['toolbox.life.timeline.overview_body', localizedValues('按时间、地区与主题浏览离线编年节点。', 'Browse offline chronological anchors by time, region, and theme.')],
    ['toolbox.life.timeline.results', localizedValues('{count} 个节点', '{count} events')],
    ['toolbox.life.timeline.no_results', localizedValues('没有符合当前条件的节点。', 'No events match the current filters.')],
    ['toolbox.life.timeline.filters', localizedValues('年表筛选', 'Timeline filters')],
    ['toolbox.life.timeline.all_periods', localizedValues('全部时期', 'All periods')],
    ['toolbox.life.timeline.all_topics', localizedValues('全部主题', 'All topics')],
    ['toolbox.life.timeline.story_mode', localizedValues('列表', 'Story')],
    ['toolbox.life.timeline.map_mode', localizedValues('时间轴', 'Map')],
    ['toolbox.life.timeline.fullscreen', localizedValues('全屏查看', 'View fullscreen')],
    ['toolbox.life.timeline.reset_view', localizedValues('重置视图', 'Reset view')],
    ['toolbox.life.timeline.sources', localizedValues('数据来源', 'Data sources')],
    ['toolbox.life.timeline.source_note', localizedValues('数据在构建时整理并内置，离线可用；日期为约略值时会明确标注。', 'Data is curated at build time and embedded for offline use; approximate dates are marked.')],
    ['toolbox.life.periodic.overview_title', localizedValues('元素周期表', 'Periodic table')],
    ['toolbox.life.periodic.overview_body', localizedValues('先看完整布局，再按名称、符号或原子序数定位元素。', 'Start with the complete layout, then locate an element by name, symbol, or atomic number.')],
    ['toolbox.life.periodic.search', localizedValues('搜索元素', 'Search elements')],
    ['toolbox.life.periodic.search_hint', localizedValues('名称、符号或原子序数', 'Name, symbol, or atomic number')],
    ['toolbox.life.periodic.clear_search', localizedValues('清除搜索', 'Clear search')],
    ['toolbox.life.periodic.overview_mode', localizedValues('全表概览', 'Overview')],
    ['toolbox.life.periodic.detail_mode', localizedValues('详细浏览', 'Details')],
    ['toolbox.life.periodic.focus', localizedValues('定位选中元素', 'Focus selected element')],
    ['toolbox.life.periodic.all_elements', localizedValues('118 个元素', '118 elements')],
    ['toolbox.life.periodic.filtered_elements', localizedValues('当前显示 {count} 个', '{count} shown')],
    ['toolbox.life.periodic.data_note', localizedValues('物性字段来自 PubChem；空值表示暂无可靠数据或不适用。', 'Physical-property fields come from PubChem; empty values mean unavailable or not applicable.')],
    ['toolbox.life.periodic.unavailable', localizedValues('暂无可靠数据', 'Unavailable')],
    ['toolbox.life.periodic.not_applicable', localizedValues('不适用', 'Not applicable')],
    ['toolbox.life.periodic.units.kelvin', localizedValues('K', 'K')],
    ['toolbox.life.periodic.units.g_cm3', localizedValues('g/cm³', 'g/cm³')],
    ['toolbox.life.periodic.units.pm', localizedValues('pm', 'pm')],
    ['toolbox.life.periodic.units.ev', localizedValues('eV', 'eV')],
    ['toolbox.life.periodic.atomic_number', localizedValues('原子序数', 'Atomic number')],
    ['toolbox.life.periodic.atomic_mass', localizedValues('相对原子质量', 'Atomic mass')],
    ['toolbox.life.periodic.state', localizedValues('标准状态', 'Standard state')],
    ['toolbox.life.periodic.discovery', localizedValues('发现年份', 'Discovery year')],
    ['toolbox.life.periodic.configuration', localizedValues('电子排布', 'Electron configuration')],
    ['toolbox.life.periodic.electronegativity', localizedValues('电负性', 'Electronegativity')],
    ['toolbox.life.periodic.atomic_radius', localizedValues('原子半径', 'Atomic radius')],
    ['toolbox.life.periodic.ionization_energy', localizedValues('第一电离能', 'First ionization energy')],
    ['toolbox.life.periodic.electron_affinity', localizedValues('电子亲和能', 'Electron affinity')],
    ['toolbox.life.periodic.oxidation_states', localizedValues('常见氧化态', 'Common oxidation states')],
    ['toolbox.life.periodic.melting_point', localizedValues('熔点', 'Melting point')],
    ['toolbox.life.periodic.boiling_point', localizedValues('沸点', 'Boiling point')],
    ['toolbox.life.periodic.density', localizedValues('密度', 'Density')],
    ['toolbox.life.periodic.period_group', localizedValues('第 {period} 周期 · 第 {group} 族', 'Period {period} · Group {group}')],
    ['toolbox.life.element.block.label', localizedValues('元素类别', 'Element category')],
  ];
  const blocks = Object.entries(blockSlugs).map(([label, slug]) => [
    `toolbox.life.element.block.${slug}`,
    localizedValues(label === 'Alkali metal' ? '碱金属' : label === 'Alkaline earth metal' ? '碱土金属' : label === 'Transition metal' ? '过渡金属' : label === 'Post-transition metal' ? '后过渡金属' : label === 'Metalloid' ? '类金属' : label === 'Nonmetal' ? '非金属' : label === 'Halogen' ? '卤素' : label === 'Noble gas' ? '稀有气体' : label === 'Lanthanide' ? '镧系元素' : '锕系元素', label),
  ]);
  for (const element of elements) {
    const index = element.atomicNumber - 1;
    const zh = chineseElementNames[index] || element.name;
    entries.push([`toolbox.life.element.${element.symbol.toLowerCase()}.name`, localizedValues(zh, element.name)]);
  }
  return [...entries, ...blocks];
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  const generalRows = parseTsv(path.join(referenceDir, 'history_timeline_general.tsv'));
  const chinaRows = parseTsv(path.join(referenceDir, 'history_timeline_china.tsv'));
  const generalCopy = loadGeneralCopy();
  const legacyFacts = loadLegacyFacts();
  const allRows = [...generalRows, ...chinaRows];
  const cache = loadWikidata(allRows, options.refreshWikidata);
  const generalFacts = buildFacts(generalRows, cache, 'general', generalCopy);
  const chinaFacts = buildFacts(chinaRows, cache, 'china_overview');
  const legacyParts = writeFactParts('legacy', legacyFacts, 70);
  const generalParts = writeFactParts('general', generalFacts, 76);
  const chinaParts = writeFactParts('china', chinaFacts, 58);
  writeTimelineAggregate(legacyParts, generalParts, chinaParts);
  const elements = elementFacts(loadPubchem(options.refreshPubchem));
  const elementParts = writeElementParts(elements, 39);
  writeElementAggregate(elementParts);
  const catalogEntries = [
    ...uiCatalogEntries(elements),
    ...buildEventCatalog([...generalFacts, ...chinaFacts], locales),
  ];
  const sourcePaths = [
    `lib/src/ui/pages/toolbox_life_tools/${generalParts[0].fileName}`,
  ];
  const added = addCatalogEntries(catalogEntries, sourcePaths, {
    catalogPath,
    registryPath,
    parseCsv,
    quoteCsv,
    readJson,
    replaceFile,
  });
  writeManifest(
    legacyFacts,
    generalFacts,
    chinaFacts,
    elements,
    generalCopy,
    {
      manifestPath: path.join(referenceDir, 'history_timeline_sources.json'),
      writeJson,
      referenceYear,
    },
  );
  console.log(JSON.stringify({
    generalSeed: generalFacts.length,
    legacyGeneral: legacyFacts.length,
    generalMerged: generalFacts.length + legacyFacts.length,
    chinaOverview: chinaFacts.length,
    curatedGeneralCopy: Object.keys(generalCopy).length,
    elements: elements.length,
    addedCatalogKeys: added.length,
    unresolvedWikidata: [...generalFacts, ...chinaFacts].filter((fact) => fact.qid == null).length,
  }, null, 2));
}

main();
