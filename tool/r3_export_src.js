// PLAN_417：导出需要补译的标题/描述类 key 的 zh/en 原文
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

const recs = parseCSV(fs.readFileSync(path.join(ROOT, 'lib/l10n/catalog/app_texts.csv'), 'utf8'));
const fb = JSON.parse(fs.readFileSync(path.join(__dirname, 'r3_enfallback.json'), 'utf8'));
const tk = new Set();
for (const g of JSON.parse(fs.readFileSync(path.join(__dirname, 'r3_titles.json'), 'utf8')))
  for (const it of g.items) tk.add(it.k);
const inter = fb.filter(k => tk.has(k) && k !== 'daily_choice.place.map.provider.osm_de.title');
const m = new Map(recs.map(r => [r[0], r]));
let out = '';
for (const k of inter) {
  const r = m.get(k);
  out += k + '\n  zh: ' + (r ? r[1] : '?') + '\n  en: ' + (r ? r[2] : '?') + '\n';
}
fs.writeFileSync(path.join(__dirname, 'r3_translate_src.txt'), out, 'utf8');
console.log(inter.length, 'keys exported');
