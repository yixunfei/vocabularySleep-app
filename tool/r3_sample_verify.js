// PLAN_417：修复后抽样验证
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');

function parseCSV(s) {
  const r = [];
  let cur = [], f = '', q = false;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (q) {
      if (c === '"') { if (s[i + 1] === '"') { f += '"'; i++; } else q = false; }
      else f += c;
    } else {
      if (c === '"') q = true;
      else if (c === ',') { cur.push(f); f = ''; }
      else if (c === '\n') { cur.push(f); r.push(cur); cur = []; f = ''; }
      else if (c !== '\r') f += c;
    }
  }
  if (f !== '' || cur.length) { cur.push(f); r.push(cur); }
  return r;
}

const recs = parseCSV(fs.readFileSync(path.join(ROOT, 'lib/l10n/catalog/app_texts.csv'), 'utf8'));
const m = new Map(recs.map(r => [r[0], r]));
const L = ['key', 'zh', 'en', 'ja', 'de', 'fr', 'es', 'ru'];
const keys = [
  'toolbox.sound.focus.quick_presets.subtitle',
  'ref.toolbox.sound.focus.quick_presets.subtitle',
  'toolbox.sound.focus.quick_presets.deep.subtitle',
  'toolbox.hub.section.calm.subtitle',
  'toolbox.sleep.library.advice_weekly_sleep_amount.title',
  'toolbox.sleep.library.advice_weekly_sleep_amount.body',
  'toolbox.crypto.veracrypt.title',
  'toolbox.crypto.veracrypt.subtitle',
  'daily_choice.wear.advisor.quick_fixes.title',
  'study.library.wordbook.deferred.summary',
  'toolbox.sound.focus.quick_presets.sprint.subtitle',
];
let out = '';
for (const k of keys) {
  const r = m.get(k);
  if (!r) { out += k + ' MISSING\n'; continue; }
  out += '== ' + k + ' (cols=' + r.length + ')\n';
  for (let i = 0; i < r.length; i++) out += '  ' + L[i] + ': ' + r[i] + '\n';
}
fs.writeFileSync(path.join(__dirname, 'r3_sample_verify.txt'), out, 'utf8');
console.log('done');
