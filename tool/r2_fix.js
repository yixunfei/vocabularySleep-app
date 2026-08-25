// PLAN_416 第二轮修复：RFC4180 偏移定位 + 逐记录替换，只触碰目标行
// 用法: node tool/r2_fix.js
const fs = require('fs');
const CSV = 'lib/l10n/catalog/app_texts.csv';
const raw = fs.readFileSync(CSV, 'utf8');

// ---- 带偏移量的 RFC4180 解析 ----
function parseWithOffsets(s) {
  const records = [];
  let fields = [], field = '', q = false, recStart = 0;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (q) {
      if (c === '"') { if (s[i + 1] === '"') { field += '"'; i++; } else q = false; }
      else field += c;
    } else {
      if (c === '"') q = true;
      else if (c === ',') { fields.push(field); field = ''; }
      else if (c === '\n') {
        fields.push(field);
        records.push({ fields, start: recStart, end: i + 1 });
        fields = []; field = ''; recStart = i + 1;
      } else field += c;
    }
  }
  if (field !== '' || fields.length) {
    fields.push(field);
    records.push({ fields, start: recStart, end: s.length });
  }
  return records;
}
function quote(f) {
  return /[",\n]/.test(f) ? '"' + f.replace(/"/g, '""') + '"' : f;
}

// ---- 编辑清单: key -> { colIndex: newValue } (1=zh 2=en 3=ja 4=de 5=fr 6=es 7=ru) ----
const edits = new Map();
function edit(key, cols) { edits.set(key, cols); }

// A. daily_choice zh 句式汉化（占位符名不变）
edit('inline.plan295.daily_choice.category_subtitleen_then_randomize_a.ef4bd170b52d',
  { 1: '{categorySubtitleEn}，然后在整个集合中随机挑选。' });
edit('inline.plan295.daily_choice.category_subtitleen_current_set_coll.912e0bcfb629',
  { 1: '{categorySubtitleEn}。当前集合：{collectionTitle}。' });
edit('inline.plan295.daily_choice.distance_selecteddistance_titleen.d2dae2086fe7',
  { 1: '距离 {selectedDistanceTitleEn}' });
edit('inline.plan295.daily_choice.filter_by_contextlabelen.301714535181',
  { 1: '按 {contextLabelEn} 筛选' });
edit('inline.plan295.daily_choice.filter_by_group_titleen.a79a5a261df1',
  { 1: '按 {groupTitleEn} 筛选' });
edit('inline.plan295.daily_choice.manual_selection_temperature_titleen.645fc37db6a4',
  { 1: '手动选择：{temperatureTitleEn}。天气建议 {suggestionTemperatureIdTitleEn}。' });
edit('inline.plan295.daily_choice.scene_selectedscene_titleen.36a46f133169',
  { 1: '场景 {selectedSceneTitleEn}' });
edit('inline.plan295.daily_choice.suggest_recommendedtemperature_title.9edbb2638d54',
  { 1: '建议 {recommendedTemperatureTitleEn}' });
edit('inline.plan295.daily_choice.exact_ingredient_matches_lead_the_po.503206b0115c',
  { 1: '完全匹配的食材优先进入候选池。' });
edit('inline.plan295.daily_choice.exact_ingredient_matches_lead_the_po.6f5398af9222',
  { 1: '完全匹配的食材优先进入候选池，再加入高度重叠的菜谱丰富选择。' });
edit('inline.plan295.daily_choice.no_exact_match_yet_so_the_pool_prefe.493be8d1e1d1',
  { 1: '暂无完全匹配，候选池优先保留食材高度重叠的菜谱。' });
edit('inline.plan295.daily_choice.no_ingredient_hit_yet_so_the_full_fi.fb50bf11239e',
  { 1: '还没有食材命中，筛选后的完整候选池保持可用。' });
edit('inline.plan295.daily_choice.no_strong_overlap_yet_so_the_pool_ke.ba302e738567',
  { 1: '暂无高度重叠，候选池保留至少匹配一种食材的菜谱。' });
edit('inline.plan295.daily_choice.place_kinden_about_dailychoicedistan.950e9d6994e3',
  { 1: '{placeKindEn} · 约 {dailyChoiceDistanceLabelEnPlaceDistanceMeters}' });
edit('inline.plan295.daily_choice.from_nearby_map_kinden_about_distanc.99a40d8e9ecf',
  { 1: '来自附近地图 · {kindEn} · 约 {distanceLabelEn}' });
edit('inline.plan295.daily_choice.the_current_selecteddistance_titleen.c289a8372f20',
  { 1: '当前「{selectedDistanceTitleEn}」档位共有 {distanceCount} 个场所，覆盖 {sceneCoverageCount} 种场景。只想出门走走时，按距离优先随机很实用。' });
edit('inline.plan295.daily_choice.the_current_selecteddistance_titleen.c5724f7be4ad',
  { 1: '当前「{selectedDistanceTitleEn} × {selectedSceneTitleEn}」筛选共有 {candidateCount} 个候选。详情包含地图查询，数据模型已为粗略定位和开放地理数据预留空间。' });
edit('inline.plan295.daily_choice.there_are_no_candidates_for_selected.02201253e526',
  { 1: '暂时没有「{selectedDistanceTitleEn} × {selectedSceneTitleEn}」的候选，可切换场景，或在管理中添加自己的场所。' });
edit('inline.plan295.daily_choice.what_for_category_titleen_tolowercas.4b9f52de36d4',
  { 1: '{categoryTitleEn}吃什么' });
edit('inline.plan295.daily_choice.where_to_go.5e249f9e8d96',
  { 1: '去哪儿' });

// B. 禅意沙盘预设提示（运行时传当前语言标题，占位符名保持不变）
edit('inline.plan294.zen_sand.applied_value_3041c0f2',
  { 1: '已应用「{presetTitleEn}」。' });
edit('inline.plan294.zen_sand.layered_value_onto_the_current_tray_2f704183',
  { 1: '已将「{presetTitleEn}」叠加到当前沙盘。' });

// C. 预热进度提示（七语言占位符集合保持一致，仅汉化句式）
edit('inline.plan296.ui.app.shell.complete_current.eb38379612',
  { 1: '{remotePrewarmCompletedCount} / {remotePrewarmTotalCount} 已完成。当前：{p3}' });

// G. 管理页加载提示 / 反图引擎结果
edit('inline.plan296.ui.pages.toolbox.daily.choice.daily.choice.manager.sheet.more_are_ready_to_load.a79fa6572b',
  { 1: '还有 {length} 个 {p1} 可以加载。' });
edit('inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.reverse.image.engines_succeeded_with_entries.d49d89aaaf',
  { 1: '{_successCount}/{length} 个引擎成功，共 {_totalEntries} 条结果{p4}。' });

// F. 快捷入口移除确认：代码传 title，占位符 {titleEn} 运行时不会被替换（真实 bug）
// 七语言同步改名并本地化
edit('inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.hub.remove_from_quick_access.c39e2e9b07',
  {
    1: '将「{title}」从快捷入口移除？',
    2: 'Remove "{title}" from quick access?',
    3: '「{title}」をクイックアクセスから削除しますか？',
    4: '„{title}“ aus dem Schnellzugriff entfernen?',
    5: 'Retirer « {title} » de l\'accès rapide ?',
    6: '¿Quitar "{title}" del acceso rápido?',
    7: 'Удалить «{title}» из быстрого доступа?',
  });

// D. 数独详情折叠按钮
edit('toolbox.sudoku.details.hide', { 1: '隐藏' });
edit('toolbox.sudoku.details.show', { 1: '显示' });

// E. 图片压缩算法标签
edit('inline.plan295.life.algorithm.1f86c487e91d', { 1: '压缩算法' });

// I. 打字语料：英文/日文语料的 zh 列补齐中文（运行时按语料语言取列，属 catalog 一致性整理）
edit('inline.plan297.human_tests.typing.passage.a_calm_mind_can_move_quickly_without_feeling_rus.8573264db4',
  { 1: '平静的心可以快速运转，却不觉得匆忙。' });
edit('inline.plan297.human_tests.typing.passage.a_useful_word_becomes_stronger_each_time_it_appe.c707bf7a73',
  { 1: '一个有用的词，每出现在新的语境里就会更牢固一分。' });
edit('inline.plan297.human_tests.typing.passage.clean_code_keeps_fast_ideas_from_becoming_expens.dabdfb7c93',
  { 1: '干净的代码，让快速的想法不至于变成昂贵的噪音。' });
edit('inline.plan297.human_tests.typing.passage.flutter_widget_tree_state_first_layout_second_po.47ec49ada6',
  { 1: 'Flutter 组件树：先状态，再布局，最后打磨。' });
edit('inline.plan297.human_tests.typing.passage.focus_25_minutes_rest_5_minutes_then_review_one_.c80a46ff7f',
  { 1: '专注 25 分钟，休息 5 分钟，再回顾一个小成果。' });
edit('inline.plan297.human_tests.typing.passage.memory_improves_when_attention_has_a_gentle_rhyt.a28836ac59',
  { 1: '当注意力有了舒缓的节奏，记忆也会随之变好。' });
edit('inline.plan297.human_tests.typing.passage.sleep_mode_dim_light_soft_voice_zero_pressure.604f0fd0e0',
  { 1: '睡眠模式：灯光调暗，声音放轻，毫无压力。' });
edit('inline.plan297.human_tests.typing.passage.the_quiet_station_clock_counted_every_suitcase_a.a4da437e92',
  { 1: '安静的车站时钟，数过每一只行李箱和每一次告别。' });
edit('inline.plan297.human_tests.typing.passage.the_train_crossed_the_river_just_as_the_city_ope.12a131898a',
  { 1: '列车驶过江面时，城市正好推开了窗。' });
edit('inline.plan297.human_tests.typing.passage.at_the_rainy_station_only_the_old_ticket_remembe.c594bc3b1e',
  { 1: '雨中的车站里，只有旧车票还记得旅程的延续。' });
edit('inline.plan297.human_tests.typing.passage.in_the_harbor_morning_a_white_ship_quietly_untie.ba575a8fb8',
  { 1: '清晨的港口，一艘白船静静解开缆绳出发了。' });
edit('inline.plan297.human_tests.typing.passage.new_words_slowly_take_shape_inside_example_sente.855a3dcc93',
  { 1: '新词在例句之中，慢慢长成自己的形状。' });
edit('inline.plan297.human_tests.typing.passage.quiet_focus_grows_from_short_breaks_and_small_ch.ac1b5542b6',
  { 1: '安静的专注，来自短暂的休息和小小的确认。' });
edit('inline.plan297.human_tests.typing.passage.read_the_night_words_slowly_and_recall_them_agai.5231376cd9',
  { 1: '夜里的单词慢慢读，清晨再回想一遍。' });
edit('inline.plan297.human_tests.typing.passage.small_functions_become_kind_guides_for_the_next_.bf71c48128',
  { 1: '小小的函数，会成为后来阅读者的亲切指引。' });

// H. brief24 时间线 en 列
const brief24Display = {
  brief24_002: '2500–2034 BC', brief24_003: '2033–1562 BC', brief24_004: '1562–1066 BC',
  brief24_005: '1066–256 BC', brief24_006: '2070–256 BC', brief24_007: '770–221 BC',
  brief24_008: '221–206 BC', brief24_012: '202 BC–AD 8',
  brief24_013: 'AD 25–220', brief24_014: 'AD 220–265', brief24_015: 'AD 221–263',
  brief24_016: 'AD 229–280', brief24_017: 'AD 265–317', brief24_019: 'AD 317–420',
  brief24_020: 'AD 304–439', brief24_021: 'AD 420–479', brief24_022: 'AD 479–502',
  brief24_023: 'AD 502–557', brief24_024: 'AD 555–587', brief24_025: 'AD 557–589',
  brief24_026: 'AD 386–534', brief24_027: 'AD 534–550', brief24_028: 'AD 535–557',
  brief24_029: 'AD 550–577', brief24_030: 'AD 557–581', brief24_031: 'AD 581–618',
  brief24_032: 'AD 618–907', brief24_033: 'AD 907–960', brief24_034: 'AD 902–979',
  brief24_035: 'AD 960–1127', brief24_036: 'AD 1127–1279', brief24_037: 'AD 907–1125',
  brief24_038: 'AD 1115–1234', brief24_039: 'AD 1032–1227', brief24_040: 'AD 1206–1370',
  brief24_041: 'AD 1251–1310', brief24_042: 'AD 1225–1370', brief24_043: 'AD 1243–1361',
  brief24_044: 'AD 1264–1265', brief24_045: 'AD 1368–1644', brief24_046: 'AD 1644–1850',
  brief24_047: 'AD 1840–1912', brief24_048: 'AD 1842–1911',
};
const SHIJI = 'Records of the Grand Historian';
const brief24Title = {
  brief24_002: SHIJI + ': Lineage of the Five Emperors',
  brief24_003: SHIJI + ': Lineage of the Xia Kings',
  brief24_004: SHIJI + ': Lineage of the Shang Kings',
  brief24_005: SHIJI + ': Lineage of the Zhou Kings',
  brief24_006: SHIJI + ': Xia–Shang–Zhou Chronology Project Chronological Table',
  brief24_007: SHIJI + ': Lineages of Spring and Autumn and Warring States Rulers',
  brief24_008: SHIJI + ': Qin Imperial Lineage',
  brief24_012: 'Book of Han: Western Han Imperial Lineage',
  brief24_013: 'Book of the Later Han: Eastern Han Imperial Lineage',
  brief24_014: 'Records of the Three Kingdoms: Cao Wei Imperial Lineage',
  brief24_015: 'Records of the Three Kingdoms: Shu Han Imperial Lineage',
  brief24_016: 'Records of the Three Kingdoms: Sun Wu Imperial Lineage',
  brief24_017: 'Book of Jin: Western Jin Imperial Lineage',
  brief24_019: 'Book of Jin: Eastern Jin Imperial Lineage',
  brief24_020: 'Book of Jin: Rise and Fall of the Sixteen Kingdoms',
  brief24_021: 'Book of Song, Southern Qi, Liang and Chen: Liu Song Imperial Lineage',
  brief24_022: 'Book of Song, Southern Qi, Liang and Chen: Southern Qi Imperial Lineage',
  brief24_023: 'Book of Song, Southern Qi, Liang and Chen: Liang Imperial Lineage',
  brief24_024: 'Book of Song, Southern Qi, Liang and Chen: Later Liang Imperial Lineage',
  brief24_025: 'Book of Song, Southern Qi, Liang and Chen: Chen Imperial Lineage',
  brief24_026: 'Book of Wei, Northern Qi, Zhou and Sui: Northern Wei Imperial Lineage',
  brief24_027: 'Book of Wei, Northern Qi, Zhou and Sui: Eastern Wei Imperial Lineage',
  brief24_028: 'Book of Wei, Northern Qi, Zhou and Sui: Western Wei Imperial Lineage',
  brief24_029: 'Book of Wei, Northern Qi, Zhou and Sui: Northern Qi Imperial Lineage',
  brief24_030: 'Book of Wei, Northern Qi, Zhou and Sui: Northern Zhou Imperial Lineage',
  brief24_031: 'Book of Wei, Northern Qi, Zhou and Sui: Sui Imperial Lineage',
  brief24_032: 'Book of Tang: Tang Imperial Lineage',
  brief24_033: 'History of the Five Dynasties: Five Dynasties Imperial Lineages',
  brief24_034: 'History of the Five Dynasties: Lineages of the Ten Kingdoms Rulers',
  brief24_035: 'Histories of the Northern and Southern Song: Northern Song Imperial Lineage',
  brief24_036: 'Histories of the Northern and Southern Song: Southern Song Imperial Lineage',
  brief24_037: 'Histories of Liao, Jin and Western Xia: Liao Imperial Lineage',
  brief24_038: 'Histories of Liao, Jin and Western Xia: Jin Imperial Lineage',
  brief24_039: 'Histories of Liao, Jin and Western Xia: Western Xia Imperial Lineage',
  brief24_040: 'History of Yuan: Yuan Imperial Lineage',
  brief24_041: 'History of Yuan: Ogedei Khanate',
  brief24_042: 'History of Yuan: Chagatai Khanate',
  brief24_043: 'History of Yuan: Kipchak Khanate',
  brief24_044: 'History of Yuan: Ilkhanate',
  brief24_045: 'History of Ming: Ming Imperial Lineage',
  brief24_046: 'History of Qing before 1840: Qing Imperial Lineage',
  brief24_047: 'History of the Late Qing: Late Qing Imperial Lineage',
  brief24_048: 'History of the Late Qing: Late Qing Treaty Ports',
};

// ---- 应用 ----
const records = parseWithOffsets(raw);
console.log('records:', records.length);
const touched = [];
const missing = [];
for (const rec of records) {
  const f = rec.fields;
  if (f.length !== 8) continue;
  const key = f[0];
  if (edits.has(key)) {
    const cols = edits.get(key);
    for (const [ci, v] of Object.entries(cols)) f[Number(ci)] = v;
    touched.push({ rec, key });
    edits.delete(key);
  } else {
    const m = key.match(/^toolbox\.life\.timeline\.brief24\.(brief24_\d+)_[0-9a-f]+\.(display|title)$/);
    if (m) {
      const map = m[2] === 'display' ? brief24Display : brief24Title;
      if (map[m[1]] !== undefined) {
        f[2] = map[m[1]];
        delete map[m[1]];
        touched.push({ rec, key });
      }
    }
  }
}
for (const k of edits.keys()) missing.push(k);
for (const k of Object.keys(brief24Display)) missing.push('brief24 display ' + k);
for (const k of Object.keys(brief24Title)) missing.push('brief24 title ' + k);
if (missing.length) {
  console.error('未命中的编辑目标:');
  missing.forEach(m => console.error('  - ' + m));
  process.exit(1);
}

// 占位符集合一致性自检（编辑后的行）
const phRe = /\{([A-Za-z_][A-Za-z0-9_]*)\}/g;
for (const { rec, key } of touched) {
  const sets = rec.fields.slice(1, 8).map(v =>
    [...new Set((v.match(phRe) || []).map(x => x.slice(1, -1)))].sort().join(','));
  if (new Set(sets).size > 1) {
    console.error('占位符集合不一致: ' + key + ' -> ' + JSON.stringify(sets));
    process.exit(1);
  }
}

// 从后往前拼接替换
let out = raw;
const spans = touched
  .map(({ rec }) => ({
    start: rec.start, end: rec.end,
    text: rec.fields.map(quote).join(',') + '\n',
  }))
  .sort((a, b) => b.start - a.start);
for (const sp of spans) out = out.slice(0, sp.start) + sp.text + out.slice(sp.end);
fs.writeFileSync(CSV, out, 'utf8');
console.log('touched records:', touched.length);

// 回读校验
const check = parseWithOffsets(fs.readFileSync(CSV, 'utf8'));
console.log('records after:', check.length);
let bad = 0;
for (const r of check) if (r.fields.length !== 8) bad++;
console.log('bad rows:', bad);
