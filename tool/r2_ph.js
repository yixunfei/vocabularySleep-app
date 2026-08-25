// 核实待修 key 的七语言占位符集合与调用点参数
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
const header = recs[0];
const ph = s => [...new Set([...String(s).matchAll(/\{([A-Za-z_][A-Za-z0-9_]*)\}/g)].map(m => m[1]))].sort().join(',');
const want = [
  'inline.plan294.zen_sand.applied_value_3041c0f2',
  'inline.plan294.zen_sand.layered_value_onto_the_current_tray_2f704183',
  'inline.plan296.ui.app.shell.complete_current.eb38379612',
  'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.hub.remove_from_quick_access.c39e2e9b07',
  'inline.plan296.ui.pages.toolbox.daily.choice.daily.choice.manager.sheet.more_are_ready_to_load.a79fa6572b',
  'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.reverse.image.engines_succeeded_with_entries.d49d89aaaf',
  'inline.plan295.life.algorithm.1f86c487e91d',
  'inline.plan295.daily_choice.where_to_go.5e249f9e8d96',
  'inline.plan295.daily_choice.what_to_do.f2157bc059ce',
  'inline.plan295.daily_choice.what_for_category_titleen_tolowercas.4b9f52de36d4',
  'inline.plan295.daily_choice.tool_titleen_category_titleen.ca8660c39c29',
  'inline.plan295.daily_choice.category_titleen_scene_titleen.9cb81855c227',
  'inline.plan295.daily_choice.distance_selecteddistance_titleen.d2dae2086fe7',
  'inline.plan295.daily_choice.scene_selectedscene_titleen.36a46f133169',
  'inline.plan295.daily_choice.the_current_selecteddistance_titleen.c289a8372f20',
  'inline.plan295.daily_choice.the_current_selecteddistance_titleen.c5724f7be4ad',
  'inline.plan295.daily_choice.there_are_no_candidates_for_selected.02201253e526',
  'inline.plan295.daily_choice.manual_selection_temperature_titleen.645fc37db6a4',
  'inline.plan295.daily_choice.suggest_recommendedtemperature_title.9edbb2638d54',
  'inline.plan295.daily_choice.place_kinden_about_dailychoicedistan.950e9d6994e3',
  'inline.plan295.daily_choice.category_subtitleen_current_set_coll.912e0bcfb629',
  'inline.plan295.daily_choice.category_subtitleen_then_randomize_a.ef4bd170b52d',
  'inline.plan295.daily_choice.exact_ingredient_matches_lead_the_po.6f5398af9222',
  'inline.plan295.daily_choice.exact_ingredient_matches_lead_the_po.503206b0115c',
  'inline.plan295.daily_choice.no_exact_match_yet_so_the_pool_prefe.493be8d1e1d1',
  'inline.plan295.daily_choice.no_strong_overlap_yet_so_the_pool_ke.ba302e738567',
  'inline.plan295.daily_choice.no_ingredient_hit_yet_so_the_full_fi.fb50bf11239e',
  'inline.plan295.daily_choice.filter_by_group_titleen.a79a5a261df1',
  'inline.plan295.daily_choice.filter_by_contextlabelen.301714535181',
  'toolbox.sudoku.details.hide',
  'toolbox.sudoku.details.show',
  'toolbox.sleep.rhythm.ok',
];
let out = '';
for (const r of recs) {
  if (!want.includes(r[0])) continue;
  out += r[0] + '\n';
  for (let i = 1; i <= 7; i++) out += '  ' + header[i] + ' ph=[' + ph(r[i]) + '] ' + r[i].slice(0, 90) + '\n';
}
fs.writeFileSync('tool/r2_ph.txt', out, 'utf8');
console.log('done', out.length);
