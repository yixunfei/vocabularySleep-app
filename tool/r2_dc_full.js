// 导出 daily_choice / zen_sand 模板行完整文本 + 调用点上下文
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
  if (r[0].startsWith('inline.plan295.daily_choice.') ||
      r[0].startsWith('inline.plan294.zen_sand.')) {
    // 只保留七语言完全相同的行（错置英文模板）
    const same = r.slice(1, 8).every(v => v === r[1]);
    if (!same) continue;
    out += r[0] + '\n  ' + r[1] + '\n';
  }
}
fs.writeFileSync('tool/r2_dc_full.txt', out, 'utf8');
console.log('done');
