// 汇总 r2_flags.csv 的标记分布，并按标记分组导出可读文本供审阅
const fs = require('fs');

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

const recs = parseCSV(fs.readFileSync('tool/r2_flags.csv', 'utf8'));
const rows = recs.slice(1).filter(r => r.length >= 4);
const byFlag = {};
for (const r of rows) byFlag[r[1]] = (byFlag[r[1]] || 0) + 1;
fs.writeFileSync('tool/r2_flag_summary.txt',
  'total=' + rows.length + '\n' + Object.entries(byFlag).map(([f, n]) => f + '\t' + n).join('\n') + '\n\n' +
  rows.map(r => `[${r[1]}] ${r[0]}\n  zh: ${r[2]}\n  en: ${r[3]}`).join('\n'), 'utf8');
console.log('total', rows.length);
console.log(byFlag);
