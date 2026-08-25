// 查看上一轮提交中打字语料的实际修改
const { execSync } = require('child_process');
const fs = require('fs');
const diff = execSync('git show 3b3db3f0 -- lib/l10n/catalog/app_texts.csv', { maxBuffer: 400 * 1024 * 1024 }).toString('utf8');
const lines = diff.split('\n').filter(l => l.includes('typing.passage') && (l.startsWith('+') || l.startsWith('-')));
fs.writeFileSync('tool/r2_prev_typing.txt', lines.join('\n'), 'utf8');
console.log('lines:', lines.length);
