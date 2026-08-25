// PLAN_417：CSV 与 registry 对照，识别内容错位/截断行
const fs = require('fs');

function parseCSV(s) {
  const records = [];
  let cur = [], field = '', q = false;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (q) {
      if (c === '"') { if (s[i + 1] === '"') { field += '"'; i++; } else q = false; }
      else field += c;
    } else {
      if (c === '"') q = true;
      else if (c === ',') { cur.push(field); field = ''; }
      else if (c === '\n') { cur.push(field); records.push(cur); cur = []; field = ''; }
      else if (c !== '\r') field += c;
    }
  }
  if (field !== '' || cur.length) { cur.push(field); records.push(cur); }
  return records;
}

const csvText = fs.readFileSync('lib/l10n/catalog/app_texts.csv', 'utf8');
const recs = parseCSV(csvText);
const COLS = ['key', 'zh', 'en', 'ja', 'de', 'fr', 'es', 'ru'];

const reg = JSON.parse(fs.readFileSync('lib/l10n/catalog/app_text_registry.json', 'utf8'));
const regMap = new Map();
for (const e of reg.entries) {
  let texts = null;
  if (e.texts && typeof e.texts === 'object') texts = e.texts;
  else if (Array.isArray(e.sources) && e.sources.length && e.sources[0].texts) texts = e.sources[0].texts;
  if (texts) regMap.set(e.id, texts);
}
console.log('registry texts extracted:', regMap.size);

// ---- 模式 1：与 registry 不一致 ----
const diffs = [];
for (let i = 1; i < recs.length; i++) {
  const r = recs[i];
  if (r.length !== 8) continue;
  const key = r[0];
  if (key.startsWith('ref.')) continue; // ref 镜像行单独处理
  const rt = regMap.get(key);
  if (!rt) continue;
  const d = {};
  for (let c = 1; c < 8; c++) {
    const col = COLS[c];
    const cv = r[c] || '';
    const rv = (rt[col] !== undefined && rt[col] !== null) ? String(rt[col]) : '';
    if (cv !== rv) d[col] = { csv: cv, reg: rv };
  }
  if (Object.keys(d).length) diffs.push({ key, d });
}
console.log('csv-vs-registry diff rows:', diffs.length);

// ---- 模式 2：结构性碎片特征（不依赖 registry）----
const fragRows = [];
for (let i = 1; i < recs.length; i++) {
  const r = recs[i];
  if (r.length !== 8) continue;
  const reasons = [];
  for (let c = 1; c < 8; c++) {
    const v = r[c];
    // 语言列以空格+小写字母开头：典型逗号切分碎片
    if (/^ [a-z]/.test(v)) reasons.push(COLS[c] + ':lead-space-frag');
    // 非 zh 列含中文（EN_HAS_CJK 类已由 r2 覆盖，跳过）
  }
  // en 与 ja 完全相同且较长（英文被复制到 ja）
  if (r[2] === r[3] && r[2].length >= 20 && /[a-zA-Z]/.test(r[2])) reasons.push('en==ja long');
  if (reasons.length) fragRows.push({ key: r[0], reasons, zh: r[1], en: r[2] });
}
console.log('fragment-pattern rows:', fragRows.length);
for (const f of fragRows.slice(0, 40)) console.log('  ', f.key, '|', f.reasons.join('+'));

fs.writeFileSync('tool/r3_regy_diff.json', JSON.stringify(diffs, null, 1), 'utf8');
fs.writeFileSync('tool/r3_frag.json', JSON.stringify(fragRows, null, 1), 'utf8');

// 汇总：按域统计 diff
const domCount = new Map();
for (const d of diffs) {
  const dom = d.key.split('.').slice(0, 3).join('.');
  domCount.set(dom, (domCount.get(dom) || 0) + 1);
}
console.log('\ndiff by domain (top 40):');
console.log([...domCount.entries()].sort((a, b) => b[1] - a[1]).slice(0, 40).map(([d, n]) => d + '\t' + n).join('\n'));
