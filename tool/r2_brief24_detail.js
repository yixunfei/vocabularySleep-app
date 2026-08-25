// brief24 detail 规模统计
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
let n = 0, zhChars = 0, sameCount = 0;
const samples = [];
for (const r of recs) {
  if (r.length < 8 || !r[0].startsWith('toolbox.life.timeline.brief24.')) continue;
  if (r[0].endsWith('.display') || r[0].endsWith('.title')) continue;
  n++;
  zhChars += r[1].length;
  if (r[1] === r[2]) sameCount++;
  if (samples.length < 3) samples.push(r[0] + '\n  suffix=' + r[0].split('.').pop() + '\n  zh(80)=' + r[1].slice(0, 80) + '\n  en(80)=' + r[2].slice(0, 80));
}
console.log('detail rows:', n, '| zh==en rows:', sameCount, '| total zh chars:', zhChars);
console.log(samples.join('\n\n'));
