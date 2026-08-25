// 检查 CSV 物理格式：换行符、引号行数、尾行
const fs = require('fs');
const raw = fs.readFileSync('lib/l10n/catalog/app_texts.csv');
const s = raw.toString('utf8');
console.log('CRLF count:', (s.match(/\r\n/g) || []).length);
console.log('LF-only count:', (s.match(/(?<!\r)\n/g) || []).length);
console.log('ends with newline:', s.endsWith('\n'));
console.log('quoted fields:', (s.match(/"/g) || []).length);
console.log('last 120 chars:', JSON.stringify(s.slice(-120)));
