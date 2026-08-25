// 补丁：what_to_do 面板标题 zh 汉化（模板无占位符，保持七语言占位符集合一致）
const fs = require('fs');
const F = 'lib/l10n/catalog/app_texts.csv';
const s = fs.readFileSync(F, 'utf8');
function parse(raw) {
  const records = []; let fields = [], field = '', q = false, recStart = 0;
  for (let i = 0; i < raw.length; i++) {
    const c = raw[i];
    if (q) { if (c === '"') { if (raw[i + 1] === '"') { field += '"'; i++; } else q = false; } else field += c; }
    else { if (c === '"') q = true; else if (c === ',') { fields.push(field); field = ''; } else if (c === '\n') { fields.push(field); records.push({ fields, start: recStart, end: i + 1 }); fields = []; field = ''; recStart = i + 1; } else field += c; }
  }
  return records;
}
const quote = f => /[",\n]/.test(f) ? '"' + f.replace(/"/g, '""') + '"' : f;
const recs = parse(s);
let out = s; const spans = [];
for (const r of recs) {
  if (r.fields[0] === 'inline.plan295.daily_choice.what_to_do.f2157bc059ce') {
    r.fields[1] = '干什么';
    spans.push(r);
  }
}
spans.sort((a, b) => b.start - a.start);
for (const r of spans) out = out.slice(0, r.start) + r.fields.map(quote).join(',') + '\n' + out.slice(r.end);
fs.writeFileSync(F, out, 'utf8');
console.log('hit', spans.length);
const chk = parse(fs.readFileSync(F, 'utf8'));
console.log('records', chk.length, 'bad', chk.filter(r => r.fields.length !== 8).length);
