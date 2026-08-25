// PLAN_417：CSV 列完整性与结构性损坏检查
const fs = require('fs');
const s = fs.readFileSync('lib/l10n/catalog/app_texts.csv', 'utf8');

function parse(s) {
  const records = [];
  let cur = [], field = '', q = false;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (q) {
      if (c === '"') {
        if (s[i + 1] === '"') { field += '"'; i++; }
        else q = false;
      } else field += c;
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

const r = parse(s);
console.log('records:', r.length);
const bad = [];
for (let i = 1; i < r.length; i++) {
  if (r[i].length !== 8) bad.push({ line: i + 1, cols: r[i].length, key: r[i][0] });
}
console.log('bad column-count rows:', bad.length);
for (const b of bad.slice(0, 80)) console.log('  line', b.line, 'cols=' + b.cols, b.key);
fs.writeFileSync('tool/r3_badrows.json', JSON.stringify(bad, null, 1), 'utf8');

// 另外检查：所有语言列为空的运行时行（空翻译）暂不统计，先聚焦结构损坏
