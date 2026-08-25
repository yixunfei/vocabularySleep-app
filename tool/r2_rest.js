// 剩余标记按域抽查：输出本轮触达域的全部剩余标记
const fs = require('fs');
const s = fs.readFileSync('tool/r2_flags.csv', 'utf8');
const lines = s.split(/\r?\n/).filter(Boolean);
let out = '';
let n = 0;
for (const l of lines.slice(1)) {
  if (/inline\.plan29[456]|daily_choice|zen_sand|sudoku|brief24|typing/.test(l)) {
    out += l.slice(0, 200) + '\n';
    n++;
  }
}
console.log('remaining in touched domains:', n);
console.log(out);
