// PLAN_417：在运行时被引用的 key 中定位结构性碎片损坏行
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

// 运行时引用集合（复用 r3_scan 逻辑结果）
const ref = JSON.parse(fs.readFileSync('tool/r3_titles.json', 'utf8'));
// 需要全量引用集合，重新提取
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
const referenced = new Set([...literals].filter(k => keySet.has(k)));
console.log('referenced:', referenced.size);

const hits = [];
for (let i = 1; i < recs.length; i++) {
  const r = recs[i];
  if (r.length !== 8) continue;
  const key = r[0];
  if (!referenced.has(key)) continue;
  if (key.startsWith('literal.') || key.startsWith('arb.') || key.startsWith('inline.') || key.startsWith('ref.')) continue;
  const reasons = [];
  for (let c = 1; c < 8; c++) {
    const v = r[c];
    if (/^ [a-z]/.test(v)) reasons.push(COLS[c] + ':lead-space');
    if (/^[ ]*$/.test(v) && c === 2 && r[1]) reasons.push('en:empty');
  }
  // en==ja 且为长英文（英译被复制到日语列）
  if (r[2] === r[3] && r[2].length >= 16 && /[a-zA-Z]{4}/.test(r[2]) && !/[\u3040-\u30ff]/.test(r[3])) reasons.push('en==ja');
  // zh/en 与后续列完全重复（逗号切分后尾部重复）
  if (r[7] && r[7] === r[2] && r[2].length >= 8) reasons.push('ru==en dup');
  if (reasons.length) hits.push({ key, reasons, row: r });
}
console.log('runtime fragment hits:', hits.length);
for (const h of hits) {
  console.log('\n' + h.key + ' | ' + h.reasons.join('+'));
  for (let c = 1; c < 8; c++) console.log('  ' + COLS[c] + ': ' + JSON.stringify(h.row[c]));
}
fs.writeFileSync('tool/r3_frag_runtime.json', JSON.stringify(hits.map(h => ({ key: h.key, reasons: h.reasons, row: h.row })), null, 1), 'utf8');
