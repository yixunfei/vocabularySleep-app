// 导出第二轮待修目标的完整行与调用上下文
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
const want = k => k.startsWith('inline.plan296.ui.pages.') || k.startsWith('daily_choice.place.map.provider.') || k === 'inline.plan296.ui.app.shell.complete_current.eb38379612';
for (const r of recs) {
  if (r.length < 3 || !want(r[0])) continue;
  out += r[0] + '\n  zh: ' + r[1] + '\n  en: ' + r[2] + '\n';
}
// 打字语料全清单（只列 key + zh）
out += '\n=== typing passages ===\n';
for (const r of recs) {
  if (r.length < 3 || !r[0].startsWith('inline.plan297.human_tests.typing.passage.')) continue;
  out += r[0].slice(34) + '\n  zh: ' + r[1] + '\n';
}
fs.writeFileSync('tool/r2_targets.txt', out, 'utf8');
console.log('written', out.length);
