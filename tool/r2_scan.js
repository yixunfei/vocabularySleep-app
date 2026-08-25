// PLAN_416 第二轮：重建被引用 key 的 zh/en 质量扫描
// 输出：tool/r2_flags.csv（问题行）、tool/r2_domains.txt（域统计）、tool/r2_referenced.json
const fs = require('fs');
const path = require('path');

const CSV = 'lib/l10n/catalog/app_texts.csv';
const text = fs.readFileSync(CSV, 'utf8');

// ---- RFC4180 状态机解析 ----
function parseCSV(s) {
  const records = [];
  let cur = [];
  let field = '';
  let inQuotes = false;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (inQuotes) {
      if (c === '"') {
        if (s[i + 1] === '"') { field += '"'; i++; }
        else inQuotes = false;
      } else field += c;
    } else {
      if (c === '"') inQuotes = true;
      else if (c === ',') { cur.push(field); field = ''; }
      else if (c === '\n') { cur.push(field); records.push(cur); cur = []; field = ''; }
      else if (c === '\r') { /* skip */ }
      else field += c;
    }
  }
  if (field !== '' || cur.length) { cur.push(field); records.push(cur); }
  return records;
}

const recs = parseCSV(text);
const header = recs[0];
console.log('records:', recs.length, 'header:', header.join(','));

const map = new Map();
for (let i = 1; i < recs.length; i++) {
  const r = recs[i];
  if (r.length < 3) continue;
  map.set(r[0], { zh: r[1], en: r[2], idx: i });
}
console.log('catalog keys:', map.size);

// ---- 提取 dart 字符串字面量 ----
function walk(dir, out) {
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) { if (name !== '.dart_tool' && !name.startsWith('.')) walk(p, out); }
    else if (name.endsWith('.dart')) out.push(p);
  }
  return out;
}
const dartFiles = walk('lib', []).concat(walk('test', []));
const literals = new Set();
const litRe = /'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)"/g;
for (const f of dartFiles) {
  const src = fs.readFileSync(f, 'utf8');
  let m;
  while ((m = litRe.exec(src)) !== null) {
    const v = m[1] !== undefined ? m[1] : m[2];
    if (v.includes('.') && v.length > 3 && v.length < 220 && /^[a-z0-9_.{}]+$/.test(v)) literals.add(v);
  }
}
const referenced = [...literals].filter(k => map.has(k));
console.log('dart literals(dot keys):', literals.size, 'referenced in catalog:', referenced.length);

// ---- 质量标记（跳过历史快照前缀）----
const SKIP = k => k.startsWith('literal.') || k.startsWith('arb.') || k.startsWith('inline.ui.pages.') || k.startsWith('ref.');
const CJK = /[\u3400-\u9fff\uf900-\ufaff]/;
const flags = [];
for (const k of referenced) {
  if (SKIP(k)) continue;
  const { zh, en } = map.get(k);
  const f = [];
  const strip = s => s.replace(/\{[^}]*\}/g, '').trim();
  if (strip(zh) && !CJK.test(zh)) f.push('ZH_NO_CJK');
  if (CJK.test(en)) f.push('EN_HAS_CJK');
  if (zh && zh === en && zh.length >= 12) f.push('SAME_LONG');
  if (/\\u[0-9a-fA-F]{4}/.test(zh) || /(?:u[0-9a-fA-F]{4}){2,}/.test(zh) ||
      /\\u[0-9a-fA-F]{4}/.test(en) || /(?:u[0-9a-fA-F]{4}){2,}/.test(en)) f.push('ESCAPE');
  if (/\$\{|\.length|\$\w/.test(zh) || /\$\{/.test(en)) f.push('DART_LEAK');
  if (f.length) flags.push([k, f.join('+'), zh, en]);
}
console.log('flagged:', flags.length);
fs.writeFileSync('tool/r2_flags.csv', '\ufeff' + ['key,flag,zh,en'].concat(flags.map(r => r.map(c => '"' + String(c).replace(/"/g, '""') + '"').join(','))).join('\n'), 'utf8');

// ---- 域统计 ----
const domainCount = new Map();
for (const k of referenced) {
  if (SKIP(k)) continue;
  const d = k.split('.').slice(0, 2).join('.');
  domainCount.set(d, (domainCount.get(d) || 0) + 1);
}
const dom = [...domainCount.entries()].sort((a, b) => b[1] - a[1]).map(([d, n]) => d + '\t' + n);
fs.writeFileSync('tool/r2_domains.txt', dom.join('\n'), 'utf8');
console.log(dom.slice(0, 40).join('\n'));

// ---- 全量引用 key 导出（供审阅）----
const ref = referenced.filter(k => !SKIP(k)).map(k => ({ k, zh: map.get(k).zh, en: map.get(k).en }));
fs.writeFileSync('tool/r2_referenced.json', JSON.stringify(ref), 'utf8');
console.log('non-snapshot referenced exported:', ref.length);
