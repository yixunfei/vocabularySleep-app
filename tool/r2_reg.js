// 查询 r2 flags 中各内联 key 在 registry 中的 status，判断是否 runtime 展示
const fs = require('fs');
const reg = JSON.parse(fs.readFileSync('lib/l10n/catalog/app_text_registry.json', 'utf8'));
const byId = new Map();
for (const e of reg.entries) byId.set(e.id, e);

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
const flags = parseCSV(fs.readFileSync('tool/r2_flags.csv', 'utf8')).slice(1);

const groups = new Map();
for (const r of flags) {
  const k = r[0];
  const e = byId.get(k);
  const status = e ? (e.status || '?') : 'NOT_IN_REGISTRY';
  const prefix = k.split('.').slice(0, 4).join('.');
  const gk = prefix + ' | ' + status;
  if (!groups.has(gk)) groups.set(gk, []);
  groups.get(gk).push(k);
}
let out = '';
for (const [g, ks] of [...groups.entries()].sort()) out += g + '\t(' + ks.length + ')\n  e.g. ' + ks[0] + '\n';
fs.writeFileSync('tool/r2_registry_status.txt', out, 'utf8');
console.log(out);
