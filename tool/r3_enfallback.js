// PLAN_417：量化运行时被引用 key 的多语言回退（ja..ru == en）规模
const fs = require('fs');
const path = require('path');

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

const recs = parseCSV(fs.readFileSync('lib/l10n/catalog/app_texts.csv', 'utf8'));
const COLS = ['key', 'zh', 'en', 'ja', 'de', 'fr', 'es', 'ru'];

function walk(dir, out) {
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) { if (name !== '.dart_tool' && !name.startsWith('.')) walk(p, out); }
    else if (name.endsWith('.dart')) out.push(p);
  }
  return out;
}
const keySet = new Set();
for (let i = 1; i < recs.length; i++) keySet.add(recs[i][0]);
const literals = new Set();
const litRe = /'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)"/g;
for (const f of walk('lib', []).concat(walk('test', []))) {
  const src = fs.readFileSync(f, 'utf8');
  let m;
  while ((m = litRe.exec(src)) !== null) {
    const v = m[1] !== undefined ? m[1] : m[2];
    if (v.includes('.') && v.length > 3 && v.length < 220 && /^[a-z0-9_.{}]+$/.test(v)) literals.add(v);
  }
}
const referenced = [...literals].filter(k => keySet.has(k));

// 回退判定：ja/de/fr/es/ru 全部与 en 相同，且 en 为较长英文句子（排除品牌名/专名）
const fallback = [];
for (const k of referenced) {
  if (k.startsWith('literal.') || k.startsWith('arb.') || k.startsWith('inline.') || k.startsWith('ref.')) continue;
  const idx = recs.findIndex(r => r[0] === k); // 性能：改用 map
}
const byKey = new Map();
for (let i = 1; i < recs.length; i++) byKey.set(recs[i][0], recs[i]);
for (const k of referenced) {
  if (k.startsWith('literal.') || k.startsWith('arb.') || k.startsWith('inline.') || k.startsWith('ref.')) continue;
  const r = byKey.get(k);
  if (!r || r.length !== 8) continue;
  const en = r[2];
  if (!en || en.length < 16 || !/[a-zA-Z]{4}/.test(en)) continue;
  const others = [r[3], r[4], r[5], r[6], r[7]];
  if (others.every(v => v === en)) fallback.push(k);
}
console.log('full en-fallback runtime keys:', fallback.length);
const domCount = new Map();
for (const k of fallback) {
  const d = k.split('.').slice(0, 3).join('.');
  domCount.set(d, (domCount.get(d) || 0) + 1);
}
console.log([...domCount.entries()].sort((a, b) => b[1] - a[1]).map(([d, n]) => d + '\t' + n).join('\n'));
fs.writeFileSync('tool/r3_enfallback.json', JSON.stringify(fallback, null, 1), 'utf8');
