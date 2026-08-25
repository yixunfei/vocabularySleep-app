// PLAN_417：导出第二轮补译所需的 zh/en 原文
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');

function parseCSV(s) {
  const r = [];
  let cur = [], f = '', q = false;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (q) {
      if (c === '"') { if (s[i + 1] === '"') { f += '"'; i++; } else q = false; }
      else f += c;
    } else {
      if (c === '"') q = true;
      else if (c === ',') { cur.push(f); f = ''; }
      else if (c === '\n') { cur.push(f); r.push(cur); cur = []; f = ''; }
      else if (c !== '\r') f += c;
    }
  }
  if (f !== '' || cur.length) { cur.push(f); r.push(cur); }
  return r;
}

const SKIP = new Set([
  'daily_choice.place.map.provider.carto_light.title',
  'daily_choice.place.map.provider.carto_voyager.title',
  'daily_choice.place.map.provider.osm_de.title',
  'daily_choice.place.map.provider.osm_france_fallback.title',
  'daily_choice.place.map.provider.osm_hot.title',
  'daily_choice.place.map.provider.osm_standard.title',
  'toolbox.crypto.veracrypt.title',
]);

const recs = parseCSV(fs.readFileSync(path.join(ROOT, 'lib/l10n/catalog/app_texts.csv'), 'utf8'));
const m = new Map(recs.map(r => [r[0], r]));
const tk = new Set();
for (const g of JSON.parse(fs.readFileSync(path.join(__dirname, 'r3_titles.json'), 'utf8')))
  for (const it of g.items) tk.add(it.k);
let out = '';
let n = 0;
for (const k of [...tk].sort()) {
  if (SKIP.has(k)) continue;
  const r = m.get(k);
  if (!r || r.length !== 8) continue;
  const en = r[2];
  if (!en) continue;
  if (r[3] === en && r[4] === en && r[5] === en && r[6] === en && r[7] === en) {
    out += k + '\n  zh: ' + r[1] + '\n  en: ' + en + '\n';
    n++;
  }
}
fs.writeFileSync(path.join(__dirname, 'r3_translate_src2.txt'), out, 'utf8');
console.log(n, 'keys exported');
