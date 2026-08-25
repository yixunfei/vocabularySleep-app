// PLAN_417 第三轮：提取运行时被引用的标题/副标题/描述类 key 全量审查清单
// 输出：tool/r3_titles.json（按域分组）、tool/r3_titles_count.txt
const fs = require('fs');
const path = require('path');

const CSV = 'lib/l10n/catalog/app_texts.csv';
const text = fs.readFileSync(CSV, 'utf8');

// ---- RFC4180 状态机解析（记录字节偏移供后续基线重放）----
function parseCSV(s) {
  const records = [];
  let cur = [];
  let field = '';
  let inQuotes = false;
  let recStart = 0;
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
      else if (c === '\n') {
        cur.push(field);
        records.push({ fields: cur, start: recStart, end: i + 1 });
        cur = []; field = ''; recStart = i + 1;
      } else if (c === '\r') { /* skip */ }
      else field += c;
    }
  }
  if (field !== '' || cur.length) { cur.push(field); records.push({ fields: cur, start: recStart, end: s.length }); }
  return records;
}

const recs = parseCSV(text);
const header = recs[0].fields;
console.log('records:', recs.length, 'header:', header.join(','));

const map = new Map();
for (let i = 1; i < recs.length; i++) {
  const f = recs[i].fields;
  if (f.length < 3) continue;
  map.set(f[0], { zh: f[1], en: f[2], idx: i });
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
console.log('referenced in catalog:', referenced.length);

// ---- 标题/描述类尾缀过滤（跳过历史快照前缀）----
const SKIP = k => k.startsWith('literal.') || k.startsWith('arb.') || k.startsWith('inline.ui.pages.') || k.startsWith('ref.') || k.startsWith('inline.plan');
const TITLE_SUFFIX = /\.(title|subtitle|sub_title|description|desc|brief|summary|caption|label|hint|intro|tagline|slogan|name|tooltip)$/;
// hub/entry 入口类（工具入口标题副标题常不带尾缀，按前缀抓）
const ENTRY_PREFIX = /^(toolbox\.hub\.|toolbox\.entries\.|toolbox\.quick|toolbox\..*\.entry\.|daily_choice\.hub\.|app\.nav\.|more\.nav\.)/;

const picked = referenced.filter(k => !SKIP(k) && (TITLE_SUFFIX.test(k) || ENTRY_PREFIX.test(k)));
console.log('title/desc-like referenced:', picked.length);

// ---- 按域分组导出 ----
const groups = new Map();
for (const k of picked.sort()) {
  const d = k.split('.').slice(0, 3).join('.');
  if (!groups.has(d)) groups.set(d, []);
  const { zh, en } = map.get(k);
  groups.get(d).push({ k, zh, en });
}
const out = [...groups.entries()].sort((a, b) => b[1].length - a[1].length)
  .map(([d, items]) => ({ domain: d, count: items.length, items }));
fs.writeFileSync('tool/r3_titles.json', JSON.stringify(out, null, 1), 'utf8');

const countLines = out.map(g => g.domain + '\t' + g.count);
fs.writeFileSync('tool/r3_titles_count.txt',
  'total: ' + picked.length + '\n' + countLines.join('\n'), 'utf8');
console.log('domains:', out.length);
console.log(countLines.slice(0, 50).join('\n'));
