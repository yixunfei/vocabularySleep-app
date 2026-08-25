// 导出 brief24 全部 display/title 的 zh 原值，用于构建 en 列映射
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
let out = '';
for (const r of recs) {
  if (r.length < 8) continue;
  if (!r[0].startsWith('toolbox.life.timeline.brief24.')) continue;
  if (!(r[0].endsWith('.display') || r[0].endsWith('.title'))) continue;
  out += r[0] + '\tzh=' + r[1] + '\ten=' + r[2] + '\n';
}
fs.writeFileSync('tool/r2_brief24.txt', out, 'utf8');
console.log('lines:', out.split('\n').length - 1);
