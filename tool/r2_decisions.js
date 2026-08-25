// 导出决策点 key 的完整七语言行（CSV 安全解析）
const fs = require('fs');
function parseCSV(s) {
  const records = []; let cur = [], field = '', q = false;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (q) { if (c === '"') { if (s[i + 1] === '"') { field += '"'; i++; } else q = false; } else field += c; }
    else { if (c === '"') q = true; else if (c === ',') { cur.push(field); field = ''; } else if (c === '\n') { cur.push(field); records.push(cur); cur = []; field = ''; } else if (c !== '\r') field += c; }
  }
  if (field !== '' || cur.length) { cur.push(field); records.push(cur); }
  return records;
}
const recs = parseCSV(fs.readFileSync('lib/l10n/catalog/app_texts.csv', 'utf8'));
const langs = ['zh', 'en', 'ja', 'de', 'fr', 'es', 'ru'];
let out = '';
const want = (k) =>
  /complete_current|more_are_ready|engines_succeeded|remove_from_quick_access|sudoku\.details/.test(k) ||
  k.startsWith('inline.plan295.life.algorithm');
for (const r of recs) {
  if (r.length < 8 || !want(r[0])) continue;
  out += '\n' + r[0] + '\n';
  for (let i = 0; i < 7; i++) out += '  ' + langs[i] + ' = ' + r[i + 1] + '\n';
}
// 打字语料：找 typing 相关 key
for (const r of recs) {
  if (r.length < 8) continue;
  if (/typing.*passage|passage.*text|typing\.corpus|typing\.text/.test(r[0])) {
    out += '\n' + r[0] + '\n  zh = ' + r[1].slice(0, 120) + '\n  en = ' + r[2].slice(0, 120) + '\n';
  }
}
fs.writeFileSync('tool/r2_decisions.txt', out, 'utf8');
console.log('done, chars:', out.length);
