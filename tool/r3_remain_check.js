// PLAN_417：修复后统计标题/描述类 key 的 en 回退残留
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
const m = new Map(recs.map(r => [r[0], r]));
const fb = JSON.parse(fs.readFileSync(path.join(__dirname, 'r3_enfallback.json'), 'utf8'));
const tk = new Set();
for (const g of JSON.parse(fs.readFileSync(path.join(__dirname, 'r3_titles.json'), 'utf8')))
  for (const it of g.items) tk.add(it.k);
// 修复后重新判断：标题/描述类且五语言列仍全部等于 en
let remain = [];
for (const k of tk) {
  const r = m.get(k);
  if (!r || r.length !== 8) continue;
  const en = r[2];
  if (!en) continue;
  if (r[3] === en && r[4] === en && r[5] === en && r[6] === en && r[7] === en) remain.push(k);
}
console.log('title/desc en-fallback remain:', remain.length);
for (const k of remain) console.log(' ', k);
