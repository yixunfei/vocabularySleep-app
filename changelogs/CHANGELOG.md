## [Unreleased-I18N-SOUND-COPY-CLEANUP] - 2026-05-31

### 原因
- 修复工具箱声音类模块中由 key 名机械翻译造成的标题、说明和按钮文案错位，例如“竖琴标题”“焦点节拍标题”“仪表开关”“低音炮”“赛博木鱼”等。

### 修复
- 统一修正游戏/声音工具入口与内部标题：模拟乐器、专注节拍、电子木鱼、舒缓轻音乐、拾音器等均改为业务语义文案。
- 补齐拾音器动态按钮和指标缺失 key，并修复百分比参数被转义后直接显示 `${...}` 的问题。
- 修正专注节拍摘要与段落预览中的硬编码分隔文本，改为 catalog key + params。
- 清理 `app_texts.csv` 中遗留的 35 个 NUL 字节，避免搜索工具把 catalog 误判为二进制文件。

### 验证
- `node scripts/audit_i18n_placeholders.js` 通过：catalog missing 0，placeholderMismatch 0，Dart 缺参 0。
- 旧 helper 与 catalog Dart 插值表达式扫描无命中。
- 目标 `dart analyze` 通过，No issues found。
- `flutter test test/app_i18n_catalog_test.dart --reporter compact` 通过。
- `git diff --check` 通过。

## [Unreleased-PLAN_303-FIRST-RUN-SETUP-GUIDE] - 2026-05-31

### 原因
- 用户要求先提交当前 i18n 修复，再增加首次安装后的客制化引导，覆盖语言、主题、权限说明、隐私承诺和基于场景的初始功能开关。

### 新增
- 新增首次安装设置引导弹窗：首次启动后先选择语言、主题，并用场景多选初始化模块开关。
- 新增 `first_run_setup_completed_v1` 持久化标记，并检测已有核心设置以避免老用户升级后被误判为首次安装。
- 新增权限说明分区：必须权限为无；麦克风、系统语音识别、相机、位置、日历、通知/闹钟/提醒、文件与媒体、网络访问、音量控制、壁纸设置均说明为按功能触发的可选权限。
- 新增隐私说明：应用没有自有远端服务、账号系统或遥测，不主动收集、上传或售卖使用信息；联网能力仅在用户主动使用对应功能时访问公开资源或用户配置的外部服务。
- 新增 `onboarding.first_run.*` 44 个七语言 catalog key，并同步 registry。

### 修改
- App 启动弹窗顺序调整为首次安装引导优先，完成后再显示每日概览。
- 当初始场景关闭专注模块时，启动流程不再弹出每日待办概览。
- 初始场景预设覆盖全部、工作专注清单、实用工具、安全工具、学习、趣味消遣，并保留“更多”模块用于后续调整。

### 验证
- JSON catalog 解析通过。
- `node scripts/audit_i18n_placeholders.js` 通过：catalog missing 0，placeholderMismatch 0，Dart 缺参 0。
- 旧 helper 扫描无命中。
- catalog Dart 插值表达式扫描无命中。
- `flutter test test/app_i18n_catalog_test.dart --reporter compact` 通过。
- `flutter analyze lib/src/ui/app_shell.dart lib/src/ui/widgets/first_run_setup_dialog.dart lib/src/state/app_state.dart lib/src/services/settings_service.dart` 通过。

## [Unreleased-PLAN_302-I18N-GLOBAL-PLACEHOLDER-AUDIT] - 2026-05-31

### 原因
- 用户反馈每日决策等页面仍直接显示 `{categoryTitleEn}` 一类原始占位符，需要用全局脚本审计七语言文案占位符与 Dart 调用参数覆盖。

### 新增
- 新增 `scripts/audit_i18n_placeholders.js`，检查七语言 catalog key/占位符集合一致性，并扫描 `lib/**/*.dart` 中静态 `AppI18n.t(...)` / `i18n.t(...)` 缺参调用。

### 修复
- 补齐全局扫描命中的 194 处缺失 `params` 与 21 处缺失具体参数名调用，最终运行时占位符缺参归零。
- 覆盖每日决策、声音工具、呼吸引导、睡眠工具、识别设置、播放天气、复习会话、数独、播放器、单词详情、ambient 面板和通用 app shell 等页面。
- 保持七语言 catalog key 集合和占位符集合一致，未引入新的硬编码展示文本或旧 source-pair helper。

### 验证
- `node scripts/audit_i18n_placeholders.js` 通过：catalog keys 49511，placeholderKeys 4044，missing 0，placeholderMismatch 0，Dart 缺参 0。
- JSON catalog 解析通过。
- 旧 helper 扫描无命中。
- catalog Dart 插值表达式扫描无命中。
- `flutter test test/app_i18n_catalog_test.dart --reporter compact` 通过。
- 目标 `flutter analyze` 通过，No issues found。
- `git diff --check` 通过。

## [Unreleased-PLAN_301-I18N-HUMAN-TESTS-PLACEHOLDER-REPAIR] - 2026-05-31

### 原因
- 用户反馈练习中心、人类测试中心及幸运测试（刮刮乐）、听力测试、双手协调、视觉感知等页面仍有 `{label}`、`{roundCount}`、`{observeMilliseconds}` 等占位符直接显示。

### 修复
- 补齐 `practice*.dart` 与 `toolbox_human_tests*.dart` 中所有带占位符 catalog key 的运行时 `params`，缺参扫描从 124 处收敛到 0。
- 覆盖练习中心、笔记本、练习回顾、幸运测试、听力测试、听力实验室、双手协调、手眼协调、视觉感知、视觉搜索、视觉记忆、动态视觉、数字记忆和单词记忆等页面。
- 清理本轮触达练习页面中的未使用 import，保持目标分析无警告。

### 验证
- JSON catalog 解析通过。
- 旧 helper 扫描无命中。
- catalog Dart 插值表达式扫描无命中。
- 七语言 catalog parity：key 49511，missing 0，placeholderMismatch 0。
- 运行时占位符缺参扫描：0。
- `flutter test test/app_i18n_catalog_test.dart --reporter compact` 通过。
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/practice_page.dart lib/src/ui/pages/practice_notebook_page.dart lib/src/ui/pages/practice_review_page.dart lib/src/ui/pages/practice_session_page.dart` 通过。
- `git diff --check` 通过。

## [Unreleased-PLAN_300-I18N-TEXT-QUALITY-REPAIR] - 2026-05-31

### 原因
- 修复截图反馈中暴露的 i18n 文本质量问题，包括 `????` 乱码、占位符未传参、模块说明缺失感和中文命名误译。

### 修改
- 设置中心当前摘要、高级播放播放策略、语言设置启动页提示、呼吸引导完成摘要与语音提示补齐 `AppI18n.t(..., params: ...)`。
- 恢复 zh catalog 中 20 个 `????` 文案，覆盖模块管理、播放练习、数独直输、单词本编辑与单词本管理。
- 将应用内学习页语境的“图书馆”改为“单词本”，同时保留地点/环境音语境中的“图书馆”。
- 修正中文命名：人类测试中心、呼吸引导、番茄钟、视觉感知、摇杆、切换、单词记忆、刮刮乐、听力设置、手速。
- 新增 `settings.language.system_default` 与人类测试视觉感知短标题 key，并同步七语言 catalog 与 registry。
- 清理呼吸引导与人类测试文件中因本轮调整暴露的未使用 import/局部声明。

### 验证
- JSON 解析检查通过。
- `????` 扫描无命中。
- 旧 helper 扫描无命中。
- 七语言 catalog/registry 覆盖检查：key 数 49511，缺失 0，占位符不一致 0。
- 目标文件带占位符 key 直接调用复扫：0。
- `flutter test test/app_i18n_catalog_test.dart --reporter compact` 通过。
- `dart analyze` 目标文件通过，No issues found。

## [Unreleased-PLAN_299-I18N-FOLLOWUP-CLEANUP] - 2026-05-31

### 原因
- 完成 `plans/PLAN_299_i18n_followup_todo.md` 中记录的 i18n 后续收口任务，避免界面继续暴露 Dart 插值、旧中文命名、残留英文说明或已废弃模块入口。

### 修改
- 修复学习、播放、图书馆、练习、单词本、更多页和模块禁用提示中的动态文案渲染，统一通过 `AppI18n.t(key, params: {...})` 传入真实值。
- 统一 catalog 中的动态占位符格式，将 `$name` / `${...}` 类 Dart 插值改为 `{name}`，并同步七语言 catalog 与 registry 的 key 覆盖和占位符集合。
- 核对并补齐 `study`、`play`、`library`、`wordbook`、`word_entry`、`module_access` 相关入口文案。
- 修正中文命名：游戏中心、人类测试、舒缓轻音乐、模拟乐器、疗愈音钵、声源定位、静心念珠、随心沙盘、番茄钟、计划与笔记。
- 清理生活实用模块说明中的英文残留和错误中文摘要。
- 将其他工具误借用 `toolbox.sound.locator.*` 的展示文案改回各自语义 key。
- 恢复鼓垫工具状态逻辑仍在使用的 `_barsPlayed` 状态字段，修复 Windows build 中 `drum_pad_state_logic.dart` 找不到 getter/setter 的错误。

### 移除
- 移除声源定位模块的模块 ID、registry 描述、工具箱入口、页面、服务、测试和相关 catalog/registry key。

### 验证
- JSON 解析检查通过。
- catalog Dart 插值表达式扫描无命中。
- 旧 helper 扫描无命中。
- 声源定位相关残留扫描无命中。
- 旧中文命名残留扫描无命中。
- 七语言 catalog/registry 覆盖检查：key 数 49509，缺失 0，占位符不一致 0。
- `flutter test test/app_i18n_catalog_test.dart --reporter compact` 通过。
- 触达 Dart 文件 `dart analyze` 通过，No issues found。
- `dart analyze lib/src/ui/pages/toolbox_sound_tools.dart` 通过，No issues found。
- `flutter build windows` 通过。

## [Unreleased-I18N-CSV-CATALOG] - 2026-05-31

### 原因
- 分语言 JSON 文案表不便于人工横向检索和批量维护，需要改为保留稳定 key 的单表多语言结构。

### 新增
- `lib/l10n/catalog/app_texts.csv`
  - 以 `key,zh,en,ja,de,fr,es,ru` 为列结构集中保存全部运行时文案。

### 修改
- `lib/src/i18n/app_i18n_catalog.dart`
  - 从单个 CSV asset 加载文案，并继续提供原有 `language -> key -> text` 查询能力。
- `scripts/audit_i18n_placeholders.js`
  - 改为读取 CSV 主文案表，继续校验 key 覆盖、占位符一致性和 Dart 调用参数。
- `lib/l10n/catalog/README.md`
  - 明确 `app_texts.csv` 是人工维护入口，registry 仅作为审计元数据。

### 移除
- `lib/l10n/catalog/app_texts_zh.json`
- `lib/l10n/catalog/app_texts_en.json`
- `lib/l10n/catalog/app_texts_ja.json`
- `lib/l10n/catalog/app_texts_de.json`
- `lib/l10n/catalog/app_texts_fr.json`
- `lib/l10n/catalog/app_texts_es.json`
- `lib/l10n/catalog/app_texts_ru.json`

## [Unreleased-I18N-TOOLBOX-COPY-FIX] - 2026-05-31

### 原因
- 修正工具箱游戏中心与生活实用入口中仍显示英文或不准确中文名称的问题。

### 修改
- `lib/l10n/catalog/app_texts_zh.json`
- `lib/l10n/catalog/app_text_registry.json`
  - 将工具箱“迷你游戏”统一修正为“游戏中心”。
  - 修正游戏名称：俄罗斯轮盘赌、俄罗斯方块、推箱子、数独、扫雷、五子棋。
  - 补齐生活实用 35 个子模块入口说明的中文文案。

### 验证
- 8 个 catalog/registry JSON 文件解析通过。
- 已反查用户点名的旧中文和英文入口说明残留。

## [Unreleased-I18N-PROCESS-HANDOFF] - 2026-05-31

### 原因
- 本地化清理经过多轮中断后，需要把统一规则、定位流程和后续问题清单固化到项目文档，方便新会话直接接手。

### 新增
- `plans/PLAN_299_i18n_followup_todo.md`
  - 记录插值泄漏、学习/单词本文案、生活实用说明、中文命名修正和移除声源定位模块等后续待办。

### 修改
- `AGENTS.md`
  - 补充 i18n 统一规则、标准修改流程、必跑检查，以及“文本到 key/代码位置定位 Skill”。

## [Unreleased-I18N-RESIDUE-CLEANUP] - 2026-05-30

### 原因
- 合并前最终清理 i18n 迁移阶段残余，避免把临时补全工具、缓存和快照文件继续作为维护入口。

### 移除
- 删除早期 i18n 语言补全临时脚本；当前本地化维护入口统一为 `lib/l10n/catalog/app_texts_*.json` 与 `lib/l10n/catalog/app_text_registry.json`。
- 清理本地忽略目录中的 i18n 翻译缓存、报告和 key 快照残余。

### 修改
- 更新历史 i18n changelog 条目，不再要求保留或运行已移除的临时迁移产物。

### 验证
- 残余文件名扫描无命中。
- 合并后主分支工作区保持干净。

## [Unreleased-PLAN_296-I18N-SINGLE-CATALOG-CLEANUP] - 2026-05-30

### Reason
- Finished the interrupted i18n cleanup for Life Tools and removed source-pair/runtime helper dependence from this path.

### Added
- `lib/src/services/toolbox_i18n_text_ref.dart`
  - Adds a small `key + params` reference object so services can return localizable UI text without hardcoded visible strings.

### Changed
- `lib/src/services/toolbox_ai_interview_service.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_ai_interview.dart`
- Life Tools service/UI files for City Compare, Offer Select, Work Worth, ID Photo, Compass, Date Calculator, Time Screen, Mind Map, and Number Marks
  - Migrated visible service/UI copy to `life.*` JSON catalog keys rendered through `AppI18n.t(key, params: ...)`.
- `lib/l10n/catalog/app_texts_*.json`
- `lib/l10n/catalog/app_text_registry.json`
  - Added and translated 321 Life Tools runtime keys across zh/en/ja/de/fr/es/ru.

### Risk Changes
- External translation was verified against the local OpenAI-compatible endpoint and used only to populate JSON catalog files; runtime code still reads the external catalog only.
- Historical registry audit entries still mention old `pickUiText` source-pair records, but current Dart code no longer references the old helpers.

### Validation
- Old helper scan across `lib/test` Dart files: no matches.
- Life Tools key coverage: 321 referenced keys, missing 0 across seven locale catalogs, registry missing 0, placeholder mismatch 0.
- `dart analyze <PLAN_296 touched Dart files>`: no issues.
- `flutter test test/app_i18n_catalog_test.dart --reporter compact`: passed.
- `flutter test test/toolbox_ai_interview_service_test.dart test/toolbox_city_compare_service_test.dart test/toolbox_offer_select_service_test.dart --reporter compact`: passed.

## [Unreleased-PLAN_297-HUMAN-TESTS-I18N-CATALOG-CLEANUP] - 2026-05-30

### Reason
- Cleaned Human Tests module i18n remnants so scoped UI/model copy no longer depends on `pickUiText(...)` or source-pair lookup.

### Added
- `plans/PLAN_297_human_tests_i18n_catalog_cleanup.md`
  - Records scope, risk boundaries, and verification steps for this Human Tests cleanup.

### Changed
- `lib/src/ui/pages/toolbox_human_tests*.dart`
  - Migrated Human Tests labels, dynamic feedback, typing passages, verbal memory data, number-memory prompts, visual search hints, and auditory stimuli to `AppI18n.t(key, params: ...)`.
- `lib/l10n/catalog/app_texts_*.json`
- `lib/l10n/catalog/app_text_registry.json`
  - Added seven-locale catalog entries and registry records for PLAN_297 runtime keys.

### Risk Changes
- Some surrounding Human Tests files already carried unrelated working-tree edits and analyzer warnings; this pass did not revert them.
- The Windows PowerShell form of the requested wildcard `rg` path is invalid, so validation used the equivalent `lib/src/ui/pages -g "toolbox_human_tests*.dart"` command.

### Validation
- `rg -n "pickUiText" lib/src/ui/pages -g "toolbox_human_tests*.dart"`: no matches.
- PLAN_297 key coverage check: 268 referenced keys, missing 0 across seven locale catalogs, registry missing 0, placeholder mismatch 0.
- `dart format <touched Human Tests Dart files>` completed.
- `dart analyze <touched Human Tests Dart files>`: no errors; 16 warnings and 2 infos remain in touched files.

## [Unreleased-PLAN_298-I18N-PICKUITEXT-CLEANUP-MINI-GAMES-MISC] - 2026-05-30

### Reason
- Cleaned up old `pickUiText(...)` calls in the user-specified mini-game and miscellaneous non-Daily/Life/Human UI files, wiring text through external JSON catalog keys and `AppI18n.t(...)`.

### Added
- `plans/PLAN_298_i18n_pick_ui_text_cleanup_mini_games_misc.md`
  - Records this migration scope, risks, execution notes, and validation results.

### Changed
- `lib/src/ui/app_shell.dart`
- `lib/src/ui/pages/module_management_page.dart`
- `lib/src/ui/pages/play_page.dart`
- `lib/src/ui/pages/play_page_weather.dart`
- `lib/src/ui/pages/toolbox_mind_tools_schulte.dart`
- `lib/src/ui/pages/toolbox_mini_games*.dart`
- `lib/src/ui/pages/toolbox_prayer_beads_tool.dart`
- `lib/src/ui/pages/toolbox_sudoku_card.dart`
- `lib/src/ui/pages/wordbook_editor_page.dart`
- `lib/src/ui/pages/wordbook_management_page.dart`
  - Replaced scoped direct `pickUiText(...)` calls and local `_text/_t` wrappers with `AppI18n.t(key, params: ...)`.
- `lib/l10n/catalog/app_texts_*.json`
- `lib/l10n/catalog/app_text_registry.json`
  - Added seven-locale catalog entries and registry records for the new runtime keys.

### Risk Changes
- Some source Chinese strings were already mojibake, so zh catalog text was rebuilt from readable context and English meaning; non-zh locales use stable English fallback for these new keys.
- The working tree contains many unrelated edits from other agents; this pass did not revert or normalize unrelated changes.

### Validation
- `rg -n "pickUiText|String _text\(|String _t\(|_text\(|_t\(" <specified files>`: no matches.
- PLAN_298 key validation: 313 keys, missing 0, registry missing 0, placeholder mismatch 0.
- `dart analyze <touched Dart files>`: no migration-caused errors; existing warnings/info remain in `app_shell.dart`, `toolbox_mini_games_roulette_view.dart`, and `toolbox_sudoku_card.dart`.

## [Unreleased-PLAN_294-I18N-TOOLBOX-MODULE-TITLES-SETTINGS] - 2026-05-30

### 原因
- 用户明确指出音钵、舒缓轻音类型、木鱼、舒尔特方格、呼吸训练、沙盘和生活实用模块仍有标题说明、设置项和选项文本未完成本地化。

### 新增
- `plans/PLAN_294_i18n_toolbox_module_titles_settings_followup.md`
  - 记录本轮点名模块 i18n 补漏范围、风险边界、key 统计和验证结果。

### 修改
- `lib/src/ui/pages/toolbox_sound_tools/soothing.dart`
  - 将旧版舒缓轻音预设、按钮、预设区标题说明和音量文案改为 `AppI18n.t(...)` 语义 key。
- `lib/src/ui/pages/toolbox_soothing_music_v2_copy.dart`
- `lib/src/ui/pages/toolbox_soothing_music_v2_*.dart`
  - 将舒缓轻音 v2 的 `SoothingMusicCopy.text(...)` 接入 JSON catalog，补齐 9 种模式类型、37 个曲目名、筛选/定时/错误/继续播放设置等七语言文案。
- `lib/src/ui/pages/toolbox_sound_tools/woodfish.dart`
- `lib/src/ui/pages/toolbox_zen_sand_tool*.dart`
- `lib/src/ui/pages/toolbox_singing_bowls_tool*.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 将木鱼、禅意沙盘、音钵和生活实用入口的标题、说明、设置项、弹窗与动态提示统一接入 `pickUiText(...)`/catalog 反查。
- `lib/l10n/catalog/app_texts_*.json`
- `lib/l10n/catalog/app_text_registry.json`
  - 新增/登记 485 个七语言 key，并修正音钵命名、动态占位符和非中英文回退英文问题。
- `docs/i18n/I18N_TEXT_AUDIT.md`
  - 补充 PLAN_294 覆盖范围、统计和校验结果。

### 风险变更
- 生活实用模块文件众多，本轮只收口 hub/入口和用户点名相关展示文案；其它生活工具内的大型数据、单位、URL、导出文件名和服务状态仍按非本轮候选保留。
- 对纯数值、单位、乐理代码和资源路径不做强制翻译，避免污染业务数据或播放资源。

### 验证
- `dart format lib\src\ui\pages\toolbox_sound_tools\soothing.dart lib\src\ui\pages\toolbox_sound_tools\woodfish.dart lib\src\ui\pages\toolbox_zen_sand_tool.dart lib\src\ui\pages\toolbox_zen_sand_tool_config.dart lib\src\ui\pages\toolbox_zen_sand_tool_widgets.dart lib\src\ui\pages\toolbox_singing_bowls_tool.dart lib\src\ui\pages\toolbox_singing_bowls_tool_layout.dart lib\src\ui\pages\toolbox_singing_bowls_tool_sheet.dart lib\src\ui\pages\toolbox_singing_bowls_tool_sheet_controls.dart lib\src\ui\pages\toolbox_singing_bowls_tool_specs.dart lib\src\ui\pages\toolbox_singing_bowls_tool_wide.dart lib\src\ui\pages\toolbox_singing_bowls_tool_wide_tiles.dart lib\src\ui\pages\toolbox_soothing_music_v2_copy.dart lib\src\ui\pages\toolbox_soothing_music_v2_labels.dart lib\src\ui\pages\toolbox_soothing_music_v2_page.dart lib\src\ui\pages\toolbox_soothing_music_v2_stage.dart lib\src\ui\pages\toolbox_soothing_music_v2_arrangement.dart`
- `dart analyze lib\src\ui\pages\toolbox_sound_tools.dart lib\src\ui\pages\toolbox_soothing_music_v2_page.dart lib\src\ui\pages\toolbox_singing_bowls_tool.dart lib\src\ui\pages\toolbox_mind_tools.dart lib\src\ui\pages\toolbox_mind_tools_schulte.dart lib\src\ui\pages\toolbox_breathing_tool.dart lib\src\ui\pages\toolbox_breathing_tool_voice.dart lib\src\ui\pages\toolbox_zen_sand_tool.dart lib\src\ui\pages\toolbox_life_tools.dart lib\src\ui\pages\toolbox_life_tools\toolbox_life_tools_hub.dart lib\src\i18n\app_i18n_catalog.dart lib\src\ui\ui_copy.dart test\app_i18n_catalog_test.dart`
- `flutter test test\app_i18n_catalog_test.dart --reporter compact`
- PLAN_294 485 个 key 七语言校验：缺失 0，占位符不一致 0，registry missing 0，非预期英文回退 0。
- 点名模块 479 处 `pickUiText/_uiText/_text/_lifeText` helper source-pair 扫描：缺失 0。

## [Unreleased-PLAN_293-I18N-DIRECT-UI-LITERAL-FOLLOWUP] - 2026-05-30

### 原因
- 用户指出上一轮仍有弹窗、标题、设置项和工具页状态文案未完全纳入多语言管理，本轮继续按高可信 UI 出口做人工收口。

### 新增
- `plans/PLAN_293_i18n_direct_ui_literal_followup.md`
  - 记录直接 UI 硬编码二次收口范围、风险边界、剩余候选分类和验证结果。

### 修改
- `lib/src/ui/pages/toolbox_sound_tools/focus_arrangement_editor.dart`
- `lib/src/ui/pages/toolbox_sound_tools/focus.dart`
  - 将 Focus 编排编辑器的弹窗、SnackBar、输入框、按钮、模板预设、状态 chip 与节拍摘要统一接入 `AppI18n.t(...)`。
- `lib/src/ui/pages/toolbox_sound_tools/deck.dart`
  - 将 Deck 全屏快速启动 tooltip、快捷提示和当前乐器状态接入运行时 key。
- `lib/src/ui/widgets/word_row.dart`
  - 将“当前”“文本已隐藏”等单词行状态文案接入 `pickUiText(...)`，由 catalog source-pair 统一管理多语言。
- `lib/src/ui/pages/toolbox_life_tools.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart`
  - 为 life tools part 文件增加运行时 key helper，并将以图搜图 Google Lens 手动降级提示、失败摘要和结构化结果摘要改为语义 key + 参数。
- `lib/src/ui/pages/toolbox_daily_choice/daily_choice_place_map_panel.dart`
  - 在展示层映射定位/IP 粗略定位 service 诊断，避免英文诊断原文直接拼进用户可见错误提示。
- `lib/l10n/catalog/app_texts_*.json`
- `lib/l10n/catalog/app_text_registry.json`
  - 新增/登记 18 个运行时 key，并保留本轮 Focus 编辑器 39 个 key 的七语言文案。
- `docs/i18n/I18N_TEXT_AUDIT.md`
  - 补充 PLAN_293 二次收口结果、剩余扫描候选边界和验证数据。

### 风险变更
- `daily_choice_place_map_service.dart` 保留英文诊断字符串作为内部状态来源；最终展示文本已在面板层本地化，避免侵入 service 逻辑。
- 收尾扫描中剩余命中大多是数值、温度、序号、文件名 hint、项目符号、服务诊断或已包含 `i18n.t(...)` 的拼接误报，本轮不进行批量替换。

### 验证
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_place_map_panel.dart lib\src\ui\pages\toolbox_life_tools.dart lib\src\ui\pages\toolbox_life_tools\toolbox_life_tools_reverse_image.dart lib\src\ui\pages\toolbox_sound_tools\deck.dart lib\src\ui\widgets\word_row.dart`
- `dart analyze lib\src\ui\pages\toolbox_daily_choice\daily_choice_hub.dart lib\src\ui\pages\toolbox_life_tools.dart lib\src\ui\pages\toolbox_life_tools\toolbox_life_tools_reverse_image.dart lib\src\ui\pages\toolbox_sound_tools.dart lib\src\ui\pages\toolbox_sound_tools\deck.dart lib\src\ui\pages\toolbox_sound_tools\focus.dart lib\src\ui\pages\toolbox_sound_tools\focus_arrangement_editor.dart lib\src\ui\widgets\word_row.dart lib\src\i18n\app_i18n_catalog.dart lib\src\ui\ui_copy.dart test\app_i18n_catalog_test.dart`
- `flutter test test\app_i18n_catalog_test.dart --reporter compact`
- PLAN_293 相关 57 个 key 七语言校验：缺失 0，占位符不一致 0，`???` 可疑文本 0。

## [Unreleased-PLAN_292-I18N-RUNTIME-FULL-WIRING] - 2026-05-30

### 原因
- 用户反馈上一轮仍有大量弹窗、标题、设置项和工具页面文本没有真正纳入运行时多语言显示，要求全面排查并完成统一管理。

### 新增
- `plans/PLAN_292_i18n_runtime_full_wiring.md`
  - 记录本轮 i18n 运行时接入、硬编码收口、验证和剩余风险。

### 修改
- `lib/src/i18n/app_i18n_catalog.dart`
  - 新增 `zh/en` source-pair、英文 source 和旧内联动态模板索引，用于把已登记的 `pickUiText(...)` 文案接入 JSON catalog。
  - 支持动态旧文案模板保留运行时变量，例如语言名、数量、状态等。
- `lib/src/ui/ui_copy.dart`
  - `pickUiText(...)` 现在中文/英文保留当前代码源文本，其他语言优先读取集中 catalog，避免旧内联写法继续回退英文。
- `lib/src/ui/pages/toolbox_mind_tools.dart`
- `lib/src/ui/pages/toolbox_mini_games_sudoku.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
- `lib/src/ui/pages/toolbox_sound_tools/deck.dart`
  - 首批收口明确用户可见的直接硬编码按钮、指标、SnackBar 与状态提示。
- `lib/l10n/catalog/app_texts_*.json`
  - 新增声音工具 Deck 的 `quick_tips` 与 `current_instrument` 七语言 key。
- `lib/l10n/catalog/app_text_registry.json`
  - 登记本轮新增运行时 key 和 PLAN_292 接入摘要。
- `docs/i18n/I18N_TEXT_AUDIT.md`
  - 补充 2026-05-30 运行时接入结果与剩余候选边界。
- `test/app_i18n_catalog_test.dart`
  - 覆盖旧 `pickUiText` source-pair 反查、动态模板变量保留和 catalog 回退行为。

### 风险变更
- 本轮不批量替换 `dart_string_literal_candidate`，因为其中混有内容数据、资源路径、单位/乐理/数值、存储 key、日志和测试文本；后续仍需按页面/模块人工判断。
- 动态模板索引限定在 `inline.*` 文案，避免过宽模板误匹配普通数值或技术字符串。

### 验证
- `dart analyze lib\src\i18n\app_i18n_catalog.dart lib\src\ui\ui_copy.dart lib\src\ui\pages\toolbox_mind_tools.dart lib\src\ui\pages\toolbox_mini_games.dart lib\src\ui\pages\toolbox_life_tools.dart lib\src\ui\pages\toolbox_sound_tools\deck.dart test\app_i18n_catalog_test.dart`
- `flutter test test\app_i18n_catalog_test.dart --reporter compact`
- `inline_pick_ui_text` 审计：4076 条 source-pair 命中，缺失 0；其中 397 条含动态值由模板索引覆盖。

## [Unreleased-PLAN_291-I18N-LOCALE-COMPLETION-REDO] - 2026-05-29

### 原因
- 用户指出历史补全无法真实覆盖全部内容且存在大量文本问题，要求不参考旧翻译库、旧脚本或历史提交，重新完整补全当前项目 i18n 语言文本。

### 修改
- `lib/l10n/catalog/app_text_registry.json`
- `lib/l10n/catalog/app_texts_zh.json`
- `lib/l10n/catalog/app_texts_ja.json`
- `lib/l10n/catalog/app_texts_de.json`
- `lib/l10n/catalog/app_texts_fr.json`
- `lib/l10n/catalog/app_texts_es.json`
- `lib/l10n/catalog/app_texts_ru.json`
  - 重新补全真实运行时与显式 UI 文案的 zh/ja/de/fr/es/ru 本地化文本，不复用历史提交 `03300ca` 的翻译内容。
  - 保留品牌、单位、音乐术语、格式串和合法同形词；对中文 `titleEn/titleZh`、`subtitleEn/subtitleZh` 等双语分支占位符做兼容处理。
- `plans/PLAN_291_i18n_locale_completion_redo.md`
  - 标记返工计划完成并记录校验结果。

### 风险变更
- 本轮仍不自动翻译 `dart_string_literal_candidate` 和 `platform_metadata_string`，避免资源路径、SQL、存储 key、日志、测试断言或内容数据污染用户 UI 文案。
- 空英文源 ARB 资源仅保留集中登记，不再作为当前 runtime/UI 英文源缺翻统计对象。

### 验证
- `collect_jobs(..., include_zh=True, force_runtime=False)` 为 0。
- `audit(...).unresolvedCount` 为 0。
- `app_text_registry.json` 与 7 个 `app_texts_*.json` 解析成功。
- 非空英文源占位符兼容校验为 0 个不一致。

## [Unreleased-PLAN_290-I18N-LOCALE-COMPLETION] - 2026-05-29

### 原因
- 用户要求在 JSON 文案表接入后，对 i18n 语言文本内容进行一轮本地化语言补全。
- 本条记录对应旧补全方式，已被 `Unreleased-PLAN_291-I18N-LOCALE-COMPLETION-REDO` 返工替代。

### 修改
- `lib/l10n/catalog/app_text_registry.json`
  - 合并回历史提交 `03300ca` 中已完成的 toolbox/focus 日语、德语、法语、西语、俄语翻译。
  - 在 `summary.localeCompletion` 中记录补全来源、策略和各语言补全数量。
- `lib/l10n/catalog/app_texts_ja.json`
- `lib/l10n/catalog/app_texts_de.json`
- `lib/l10n/catalog/app_texts_fr.json`
- `lib/l10n/catalog/app_texts_es.json`
- `lib/l10n/catalog/app_texts_ru.json`
  - 同步写入对应语言补全文案。
- `lib/l10n/catalog/app_texts_zh.json`
- `lib/l10n/catalog/app_texts_en.json`
  - 同步标记本轮补全元数据，正文文案不做无意义改写。
- `plans/PLAN_290_i18n_json_catalog_runtime_and_locale_completion.md`
  - 标记计划已完成。

### 风险变更
- 本条记录中的历史翻译复用策略已废弃，当前有效结果以 PLAN_291 返工记录为准。
- 本轮补全优先恢复已有历史翻译，未对 `dart_string_literal_candidate` 和平台技术字符串做自动翻译，避免把资源路径、SQL、存储 key、日志和内容数据误标为 UI 本地化文本。
- registry 中仍保留大量 `missingLocales`，主要对应 source-only 候选，后续应逐页确认是否用户可见后再翻译。

### 验证
- `node` 解析 `app_text_registry.json` 与 7 个 `app_texts_*.json` 成功。
- 本轮补全统计：ja 4008、de 3976、fr 4008、es 4024、ru 3943 个表项获得补全文案。

## [Unreleased-PLAN_290-I18N-JSON-CATALOG-RUNTIME] - 2026-05-29

### 原因
- 用户要求将上一轮生成的语言 JSON 表接入项目运行时，替换/接管现有 i18n 文案读取路径，并先完成一次提交。

### 新增
- `lib/src/i18n/app_i18n_catalog.dart`
  - 新增集中 JSON 文案表加载器，负责加载 `lib/l10n/catalog/app_texts_*.json` 并提供同步查询能力。
  - 支持测试注入和重置，便于验证 JSON 优先级与回退行为。
- `test/app_i18n_catalog_test.dart`
  - 覆盖 JSON catalog 优先于内置 Map、跨语言回退与占位符替换。

### 修改
- `pubspec.yaml`
  - 注册 `lib/l10n/catalog/` 为 Flutter assets，使语言 JSON 表随应用打包。
- `lib/src/app/app_bootstrap.dart`
  - 启动阶段预加载 i18n JSON catalog。
- `lib/src/i18n/app_i18n.dart`
  - `AppI18n.t(...)` 优先读取 JSON catalog，缺失或未加载时继续回退现有内置 Map 与 humanize 逻辑，保持现有调用点兼容。

### 风险变更
- 启动时会读取 7 个语言 JSON，资源体积较大；本轮保留内置 Map 回退，后续可优化为按当前语言懒加载。
- JSON catalog 仅接管 `i18n.t(...)` 的 key 查询；仍内联使用 `pickUiText(...)` 的页面需要后续逐步迁移到 key。

### 验证
- `dart format lib/src/i18n/app_i18n.dart lib/src/i18n/app_i18n_catalog.dart lib/src/app/app_bootstrap.dart test/app_i18n_catalog_test.dart`
- `dart analyze lib/src/i18n/app_i18n.dart lib/src/i18n/app_i18n_catalog.dart lib/src/app/app_bootstrap.dart test/app_i18n_catalog_test.dart`
- `flutter test test/app_i18n_catalog_test.dart --reporter compact`

## [Unreleased-PLAN_289-I18N-FULL-TEXT-CATALOG-BASELINE] - 2026-05-29

### 原因
- 用户要求先将当前分支还原到 `c38e2fee4f8b5df079d0398745fe82e9b6077ff9` 并丢弃所有修改，再在“不修改任何代码”的边界下，对当前项目所有页面与文本内容做 i18n 集中统一化管理，方便后续集中替换和翻译维护。

### 新增
- `plans/PLAN_289_i18n_full_text_catalog_baseline.md`
  - 记录本轮只新增 i18n 资源、计划、审计和变更记录，不修改 Dart/Kotlin/Gradle/YAML 运行时代码。
- `lib/l10n/catalog/app_text_registry.json`
  - 新增全量机器可读文案总账，覆盖现有 `AppI18n` key、ARB key、`pickUiText` 内联双语文本、`i18n.t(...)` 引用、疑似用户可见 Dart 字面量和平台展示元数据。
  - 为每条文本保留来源文件、行号、文本类型、建议 key、占位符、缺失语言、已有 key 匹配和迁移状态。
- `lib/l10n/catalog/app_texts_zh.json`
- `lib/l10n/catalog/app_texts_en.json`
- `lib/l10n/catalog/app_texts_ja.json`
- `lib/l10n/catalog/app_texts_de.json`
- `lib/l10n/catalog/app_texts_fr.json`
- `lib/l10n/catalog/app_texts_es.json`
- `lib/l10n/catalog/app_texts_ru.json`
  - 新增按语言拆分的平铺文案表，用于集中翻译、批量替换和差异审查；缺失翻译暂按 en/zh/source 回退，真实缺口以 registry 的 `missingLocales` 为准。
- `lib/l10n/catalog/README.md`
  - 说明 i18n 文案目录用途、资源边界和后续代码接入方式。
- `docs/i18n/I18N_TEXT_AUDIT.md`
  - 新增全量文本梳理报告，记录扫描范围、排除范围、类型统计、页面高密度区域和后续迁移建议。
- `docs/i18n/I18N_PAGE_TEXT_COVERAGE.md`
  - 新增页面级覆盖表，按页面/展示层文件列出 `pickUiText`、`i18n.t`、疑似可见 literal 与技术/数据 literal 数量。

### 修改
- 当前分支已通过 `git reset --hard c38e2fee4f8b5df079d0398745fe82e9b6077ff9` 回退到指定提交，并通过 `git clean -fd`、`git clean -ffd` 清理未跟踪文件和嵌套未跟踪目录。

### 风险变更
- 本轮没有修改运行时代码，因此新增集中资源不会自动改变应用显示内容；后续需要按页面逐步把 `pickUiText` 与确认后的可见 literal 迁移到 `AppI18n.t` 或统一生成式本地化入口。
- Dart 字符串候选中包含资源路径、存储 key、SQL、日志和数据文本等非 UI 内容，已在 registry 中标注 `visibility` 与 `status`，后续替换前必须逐项确认。
- 大型词典、测试断言、第三方依赖和内容数据集未混入 UI 文案迁移范围，作为内容/测试/外部资源单独看待。

### 验证
- `node` 解析 `lib/l10n/catalog/app_text_registry.json` 与 7 个 `app_texts_*.json` 成功。
- `git status --short --untracked-files=all` 确认未修改 Dart/Kotlin/Gradle/YAML 代码文件；仅新增 i18n catalog 资源并更新 changelog。

## [Unreleased-PLAN_288-TOOLBOX-HOME-TIP-COMPACT] - 2026-05-29

### 原因
- 用户反馈工具箱首页编辑说明提示在手机首屏占用接近三分之一空间，希望从 UX 屏幕效率出发压缩高度，并保留必要说明入口。

### 新增
- `plans/PLAN_288_工具箱首页提示压缩优化.md`
  - 记录本轮只处理工具箱首页提示展示层，不修改排序、快速入口、隐藏恢复、路由和持久化逻辑。

### 修改
- `lib/src/ui/pages/toolbox/toolbox_page_widgets.dart`
  - 将 `ToolboxIntroPanel` 从常驻大说明卡改为紧凑提示条，默认仅显示标题和一行操作摘要。
  - 新增右侧说明按钮，按需展开底部说明面板，承载完整编辑规则和“长按编辑 / 拖动排序 / 快速入口 / 可恢复”标签。
- `lib/src/ui/pages/toolbox_page.dart`
  - 首页和编辑态提示上下间距由大段 section 间距收缩为卡片间距，让快速入口与工具列表更早进入首屏。
- `test/ui_smoke_test.dart`
  - 增加工具箱首页提示高度与说明展开 smoke test。

### 风险变更
- 本轮未修改工具箱首页布局状态、拖拽排序、快速入口保存、隐藏恢复、模块启停或页面路由逻辑。
- 完整说明从常驻展示改为按需展开，首屏更省空间；用户仍可通过说明按钮查看完整规则。

### 验证
- `dart format lib/src/ui/pages/toolbox_page.dart lib/src/ui/pages/toolbox/toolbox_page_widgets.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_page.dart lib/src/ui/pages/toolbox/toolbox_page_widgets.dart test/ui_smoke_test.dart`（通过；保留 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox intro stays compact and opens editing tips" --reporter compact`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page supports editable home layout" --reporter compact`

## [Unreleased-PLAN_287-HUMAN-TEST-COPY-AND-SWITCH-CUES] - 2026-05-28

### 原因
- 用户希望优化 `工具箱 - 人类测试` 各子模块文案，移除开发式说明、进度口吻和重复叙述，让页面表达更亲近自然；同时增强可切换子模块与可展开设置区的视觉提示。

### 新增
- `plans/PLAN_287_人类测试文案与切换提示优化.md`
  - 记录本轮仅处理人类测试模块展示层文案与轻量样式，不修改玩法、计时、状态机、持久化或数据模型。

### 修改
- `lib/src/ui/pages/toolbox_human_tests*.dart`
  - 优化人类测试入口、常用测试区、各子模块标题说明、状态提示、设置区说明和报告内建议文案。
  - 移除或改写“结构化设置区”“训练边界”“当前页面内统计”“统计报告”“本轮设置”“训练建议”等偏内部或偏机械的表达。
  - 保留开始、切换、设置生效、重开、报告查看、专业检查提醒等关键提示。
- `lib/src/ui/pages/toolbox_human_tests_shared.dart`
  - 子测试卡片增加更明确的进入箭头与 accent 色提示，同时保持既有 118dp 卡片高度，避免入口网格布局变化。
  - 设置折叠区右侧改为“展开 / 收起”文字胶囊，并增强头部渐变、边框与图标承托，让用户更容易看出可展开。

### 风险变更
- 本轮未修改人类测试业务逻辑、计时逻辑、结果计算、路由行为和持久化。
- 英文测试锚点保留，中文文案优先优化自然度；部分英文沿用既有文案以避免测试和本地化范围扩大。

### 验证
- `dart format lib/src/ui/pages/toolbox_human_tests*.dart lib/src/ui/pages/toolbox_tool_shell.dart`
- `dart analyze lib/src/ui/pages/toolbox_tool_shell.dart lib/src/ui/pages/toolbox_human_tests.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart test/toolbox_visual_memory_smoke_test.dart test/toolbox_typing_test_smoke_test.dart test/toolbox_verbal_memory_smoke_test.dart test/toolbox_color_vision_smoke_test.dart --reporter compact`（通过；保留测试中 `Single-side practice` 既有非致命 hit-test 警告）

## [Unreleased-PLAN_286-HUMAN-TEST-VISUAL-MEMORY-DESCRIPTION-DEDUP] - 2026-05-28

### 原因
- 用户反馈 `工具箱 - 人类测试中心 - 视觉记忆` 首屏中“从经典位置到随机目标色，等级越高，干扰色会越接近目标。”在外层标题区和内层主舞台重复展示，造成信息冗余。

### 新增
- `plans/PLAN_286_视觉记忆冗余描述清理.md`
  - 记录本轮仅清理展示层重复文案，不修改视觉记忆玩法、计时、状态机、持久化或数据模型。

### 修改
- `lib/src/ui/pages/toolbox_tool_shell.dart`
  - 为 `ToolboxToolPage` 增加默认开启的 `showPageHeader` 参数，允许特定工具详情页跳过外层 `PageHeader`。
- `lib/src/ui/pages/toolbox_human_tests_shared.dart`
  - 人类测试详情页关闭外层 `PageHeader`，保留内部 `_HumanHeroPanel` 的标题、说明和状态 pill，避免同一 `subtitle` 被渲染两次。

### 位置确认
- 文案源头位于 `lib/src/ui/pages/toolbox_human_tests_visual_memory.dart` 的 `VisualMemoryTestPage.subtitle`。
- 原先第一处渲染位于 `ToolboxToolPage` 的外层 `PageHeader.subtitle`。
- 原先第二处渲染位于 `_HumanTestScaffold` 内的 `_HumanHeroPanel.subtitle`。

### 风险变更
- `showPageHeader` 默认保持 `true`，工具箱其他页面默认展示行为不变。
- 人类测试详情页统一减少一层外部标题说明，内部主舞台信息仍保留，首屏上下文不丢失。

### 验证
- `dart format lib/src/ui/pages/toolbox_tool_shell.dart lib/src/ui/pages/toolbox_human_tests_shared.dart`
- `dart analyze lib/src/ui/pages/toolbox_tool_shell.dart lib/src/ui/pages/toolbox_human_tests.dart`
- `flutter test test/toolbox_visual_memory_smoke_test.dart --reporter compact`

## [Unreleased-PLAN_285-BOTTOM-NAV-AUTO-HIDE] - 2026-05-28

### 原因
- 用户反馈 `工具箱-生活实用` UI 修改后出现底部导航菜单栏消失/不可稳定触达的问题，并希望支持下滑隐藏、点击屏幕或上滑显示，同时可在全局设置中开关该能力。

### 新增
- `plans/PLAN_285_底部导航滚动显隐与全局开关修复.md`
  - 记录本轮只收束全局底部导航显隐与设置开关，不回退用户已有生活实用 UI 文案调整。
- `SettingsService` 新增 `bottom_navigation_auto_hide_enabled_v1` 持久化开关。
- 全局设置页新增“下滑时自动隐藏底部导航”开关，默认关闭以保持主入口始终可见；开启后下滑隐藏，上滑或点击屏幕显示。

### 修改
- `lib/src/ui/app_shell.dart`
  - 底部导航改为由全局纵向滚动通知和屏幕点击驱动：启用后下滑收起，上滑或点击屏幕显示，不再因滚动停止自动显示。
  - 迷你播放器与悬浮环境音入口统一使用当前导航占位高度计算底部避让，避免导航隐藏/显示时遮挡。
- `lib/src/state/app_state.dart` / `lib/src/state/app_state_startup.dart`
  - 底部导航滚动隐藏开关改为 `AppState` 内存缓存，初始化前默认关闭，数据库初始化后再恢复持久化值，避免首帧构建提前读取未初始化数据库。
- `test/ui_smoke_test.dart`
  - 补充测试替身字段与设置页开关 smoke test。
- `test/app_state_init_test.dart`
  - 补充启动期回归断言，覆盖开关初始化前默认值与初始化后持久化恢复。
- `PROJECT_DOMAIN.md`
  - 同步记录底部导航全局显隐行为、默认常驻策略和避让边界。

### 修复
- 修复 `AppShell.build` 在数据库初始化完成前读取新增全局设置导致的 `LateInitializationError: Field '_db' has not been initialized`。
- 修复底部导航自动隐藏开关变更后状态未即时驱动导航行为的问题。

### 风险变更
- 本轮仅新增可关闭的全局导航显隐行为；默认关闭，不改变既有导航常驻体验。
- 滚动监听只处理纵向滚动通知，降低对横向工具条和生活实用内部连续手势的干扰。

### 验证
- `dart format lib/src/ui/app_shell.dart lib/src/services/settings_service.dart lib/src/state/app_state.dart lib/src/state/app_state_startup.dart lib/src/ui/pages/settings_home_page.dart test/settings_service_test.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/app_shell.dart lib/src/services/settings_service.dart lib/src/state/app_state.dart lib/src/state/app_state_startup.dart lib/src/ui/pages/settings_home_page.dart test/settings_service_test.dart test/ui_smoke_test.dart test/app_state_init_test.dart`（通过；仅余 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/settings_service_test.dart`
- `flutter test test/app_state_init_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "settings exposes bottom navigation auto-hide toggle"`

### 追加修复
- 修复生活实用模块仍然没有底部导航栏的问题：工具箱内打开 `Life tool hub` 时不再压入新路由，而是在工具箱页内嵌展示，保留 `AppShell` 的 `NavigationBar`。
- 修复生活实用 Hub 内部子工具继续通过 `Navigator.push` 打开导致底部导航被盖住的问题；子工具改为 Hub 内部状态切换，并通过嵌入式返回入口回到 Hub。

### 追加修改
- `lib/src/ui/pages/toolbox_tool_shell.dart`
  - 新增 `ToolboxEmbeddedNavigation`，为内嵌工具页提供本地返回行为。
- `lib/src/ui/pages/toolbox_page.dart`
  - 工具箱内对生活实用入口使用内嵌工具视图，其它模块仍保持原有路由行为。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 生活实用子工具改为 `_activeTool` 状态驱动，并为工具卡片补充稳定 key，避免测试和交互误命中搜索框文本。
- `lib/src/ui/app_shell.dart`
  - 移除停止滚动后的自动显示计时器，新增轻量点击识别：点击屏幕显示底部导航，拖拽滚动不会被误判为点击。
- `lib/src/ui/pages/settings_home_page.dart` / `PROJECT_DOMAIN.md`
  - 同步更新导航自动隐藏说明，明确恢复方式为上滑或点击屏幕。

### 追加验证
- `dart format lib/src/ui/pages/toolbox_tool_shell.dart lib/src/ui/pages/toolbox_page.dart lib/src/ui/pages/toolbox/toolbox_page_widgets.dart lib/src/ui/pages/toolbox/toolbox_quick_entries.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_tool_shell.dart lib/src/ui/pages/toolbox_page.dart lib/src/ui/pages/toolbox/toolbox_page_widgets.dart lib/src/ui/pages/toolbox/toolbox_quick_entries.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/app_shell.dart test/ui_smoke_test.dart`（通过；仅保留 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/ui_smoke_test.dart --plain-name "app shell keeps bottom navigation inside life tools"`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page opens life tool hub module"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens date calculator progress and candle tabs"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens timeline and periodic visualizations"`
- `flutter test test/ui_smoke_test.dart --plain-name "settings exposes bottom navigation auto-hide toggle"`
- `flutter test test/ui_smoke_test.dart --plain-name "app shell reveals auto-hidden bottom navigation on tap or upward scroll"`
- `flutter test test/app_state_init_test.dart`
- `flutter test test/settings_service_test.dart`

## [Unreleased-PLAN_284-LIFE-RULER-PROTRACTOR-READABILITY] - 2026-05-28

### 原因
- 用户反馈 `工具箱-生活实用-尺子和量角器` 中量角器背景与刻度都是白色，浅色相机画面下难以辨认。

### 新增
- `plans/PLAN_284_生活实用尺子量角器刻度可读性优化.md`
  - 记录本轮只优化量角器展示层、不改相机权限、路由、校准和业务逻辑的边界。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_display.dart`
  - 量角器全屏刻度层增加半透明深色测量盘、外圈承托与中心参考线。
  - 主刻度与角度数字改为暖色高亮，次刻度改为浅蓝灰，并为刻度、弧线和数字增加深色描边，避免白纸、白墙或明亮桌面背景吞掉刻度。
- `PROJECT_DOMAIN.md`
- `modules/toolbox/README.md`
  - 同步记录尺子和量角器的量角器可读性优化与风险边界。

### 风险变更
- 本轮只调整 `CustomPainter` 视觉表达，不改变相机预览、权限请求、横屏沉浸、返回恢复、尺子校准和量角器角度刻度逻辑。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_display.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_display.dart test/ui_smoke_test.dart`（通过；仅余 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens ruler and protractor utility page"`

## [Unreleased-PLAN_283-LIFE-FAKE-CALL-INCALL-STAGE] - 2026-05-28

### 原因
- 用户反馈模拟来电接听后的通话中动画需要展示到中间或全屏，不能只像普通信息区一样停留在上方。

### 新增
- `plans/PLAN_283_生活实用模拟来电通话中动画舞台.md`
  - 记录接听中动画舞台居中/全屏展示、Flutter/Android 双端同步和验证范围。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart`
  - 应用内兜底通话态新增居中大面积波纹通话舞台，接听后动画继续运行，计时保留在上方，挂断按钮保留在底部。
  - 通话舞台根据可用高度动态缩放，避免在较矮屏幕或测试视口中遮挡内容。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/FakeIncomingCallActivity.kt`
  - Android 原生接听态新增居中脉冲通话舞台，使用原生 View 动画展示扩散光环。
  - 挂断、拒绝和 Activity 销毁时取消通话动画，避免动画资源泄漏。
- `test/ui_smoke_test.dart`
  - 模拟来电 smoke 增加通话动画舞台断言。
- `PROJECT_DOMAIN.md`
  - 同步模拟来电通话态动画舞台展示边界。

### 风险变更
- 通话中动画会持续运行到挂断，已限制为轻量圆环动画，并在销毁时清理。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart test/ui_smoke_test.dart`（通过；仅余 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens fake incoming call and starts a session"`
- `flutter build apk --debug`

## [Unreleased-PLAN_282-LIFE-FAKE-CALL-ANSWER-BACKGROUND] - 2026-05-28

### 原因
- 用户要求继续完善 `工具箱-生活实用-模拟来电`：触发后的全屏来电需要真正支持接听、通话效果和挂断退出，并允许来电中与接听后的通话背景分别自定义图片和样式。

### 新增
- `plans/PLAN_282_生活实用模拟来电接听挂断与背景样式.md`
  - 记录接听/挂断状态机、双背景配置、Android 返回桌面和验证范围。

### 修改
- `lib/src/services/toolbox_fake_call_service.dart`
  - `ToolboxFakeCallSpec` 增加来电背景路径/样式与通话背景路径/样式字段，并通过 `vocabulary_sleep/fake_call` MethodChannel 下发。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart`
  - 新增“背景样式”设置区，支持分别选择/清除来电背景与通话背景，并提供 Cover、Dim、Blur 三种显示样式。
  - 应用内全屏兜底页改为来电态/通话态两段流程：接听停止铃声和震动并进入通话计时，挂断退出全屏页。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/FakeCallScheduler.kt`
- `android/app/src/main/kotlin/group/zn/xianyushengxi/FakeCallReceiver.kt`
- `android/app/src/main/kotlin/group/zn/xianyushengxi/MainActivity.kt`
  - 持久化、广播、立即预览和 Activity Intent 全链路透传双背景配置。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/FakeIncomingCallActivity.kt`
  - 原生全屏 Activity 增加来电/通话状态机：拒绝或挂断清理通知并最佳努力返回桌面，接听后停止来电效果并显示通话计时。
  - 背景图片使用全屏 `ImageView` centerCrop 渲染；Android 12+ 对 Blur 样式使用系统 `RenderEffect`，旧系统回退暗化遮罩。
- `test/ui_smoke_test.dart`
  - 扩展模拟来电 smoke，覆盖背景按钮、应用内预览接听、通话中状态和挂断返回页面。
- `PROJECT_DOMAIN.md`
  - 同步模拟来电接听/通话/挂断闭环、双背景样式和风险边界。

### 风险变更
- Android “返回桌面”仍受 Activity 启动栈、厂商后台策略和系统版本影响，本轮采用 `moveTaskToBack(true)` + `finish()` 的最佳努力处理。
- 自定义背景图片依赖用户所选本地路径可读性；Flutter 和 Android 均在图片不可用时回退默认渐变背景。

### 验证
- `dart format lib/src/services/toolbox_fake_call_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/services/toolbox_fake_call_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart test/ui_smoke_test.dart`（通过；仅余 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens fake incoming call and starts a session"`
- `flutter build apk --debug`

## [Unreleased-PLAN_281-TOOLBOX-CRYPTO-SECURITY] - 2026-05-28

### 原因
- 用户希望工具箱新增“加密安全”独立模块，并将 `生活实用` 中的图片/音频/视频隐写迁移到其中；该模块后续会承载大量加密解密相关子模块，因此不能用轻量页签作为总模块结构。

### 新增
- `plans/PLAN_281_工具箱加密安全模块与隐写迁移.md`
  - 记录加密安全模块新增、隐写归属迁移、非页签式 hub 结构和验证风险。
- `lib/src/ui/pages/toolbox_crypto_security.dart`
- `lib/src/ui/pages/toolbox_crypto_security/toolbox_crypto_security_hub.dart`
- `lib/src/ui/pages/toolbox_crypto_security/toolbox_crypto_security_shared.dart`
- `lib/src/ui/pages/toolbox_crypto_security/toolbox_crypto_security_steganography.dart`
  - 新增加密安全中心，以独立子模块卡片接入“图片/音频/视频隐写”，并预留后续加密、解密、密钥、证书、校验、签名等模块空间。

### 修改
- `lib/src/core/module_system/module_id.dart`
- `lib/src/core/module_system/module_registry.dart`
- `lib/src/ui/module/module_access.dart`
- `lib/src/ui/theme/toolbox_colors.dart`
  - 注册 `toolbox.crypto_security` 模块 ID、模块管理文案和加密安全主题色。
- `lib/src/ui/pages/toolbox/toolbox_page_content.dart`
  - 工具箱首页新增“加密安全”分组与“加密安全中心”入口；生活实用计数同步从 37 调整为 36。
- `lib/src/ui/pages/toolbox_life_tools.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 移除生活实用中的 `steganography` 入口与路由，由加密安全中心打开媒体隐写页面。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 补充 Crypto Security 归属、入口、文件边界和兼容路径说明，并给旧 Life Tools Steganography 段落增加迁移备注。
- `test/ui_smoke_test.dart`
  - 隐写 smoke 改为从工具箱首页进入 Crypto Security hub，再打开 Media steganography。
  - 新增生活实用不再展示隐写入口的回归断言。

### 风险变更
- 本轮只迁移模块归属与导航入口，不修改 `ToolboxSteganographyService`、`ToolboxCryptoService` 的加密、还原、容量、密钥文件或媒体载荷算法。
- 隐写页面内部仍保留部分 `life_stego_*` key 与 `life_tools/steganography` 存储/导出兜底路径，用于兼容既有测试、持久化和导出行为。

### 验证
- `dart format lib/src/core/module_system/module_id.dart lib/src/core/module_system/module_registry.dart lib/src/ui/module/module_access.dart lib/src/ui/theme/toolbox_colors.dart lib/src/ui/pages/toolbox/toolbox_page_content.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_crypto_security.dart lib/src/ui/pages/toolbox_crypto_security/toolbox_crypto_security_hub.dart lib/src/ui/pages/toolbox_crypto_security/toolbox_crypto_security_shared.dart lib/src/ui/pages/toolbox_crypto_security/toolbox_crypto_security_steganography.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/core/module_system/module_id.dart lib/src/core/module_system/module_registry.dart lib/src/ui/module/module_access.dart lib/src/ui/theme/toolbox_colors.dart lib/src/ui/pages/toolbox/toolbox_page_content.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_crypto_security.dart test/ui_smoke_test.dart`（通过；仅余 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "crypto security opens steganography controls"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools no longer lists steganography entry"`

## [Unreleased-PLAN_279-LIFE-FAKE-CALL-INDEPENDENT-REDESIGN] - 2026-05-28

### 原因
- 用户反馈 `工具箱-生活实用-模拟来电` 当前实现走成了基于日历/通知的提醒工具，核心需求应是点击开始后在指定时间全屏播放模拟来电动画、铃声和震动。

### 新增
- `plans/PLAN_279_生活实用模拟来电独立重做.md`
  - 记录模拟来电从 todo reminder / calendar 剥离、独立调度、全屏触发和验证风险。
- `lib/src/services/toolbox_fake_call_service.dart`
  - 新增 `vocabulary_sleep/fake_call` 平台服务，支持能力检查、调度、取消、立即预览和权限入口，并带 2 秒超时兜底。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/FakeCallScheduler.kt`
- `android/app/src/main/kotlin/group/zn/xianyushengxi/FakeCallReceiver.kt`
  - 新增独立模拟来电原生调度、持久化、通知渠道、full-screen intent 和触发接收器。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart`
  - 页面重做为来电预览主舞台、来电信息、触发时间、来电效果、开始/取消和投递能力结构。
  - 点击开始后只启动一次模拟来电会话，不再创建待办、不展示提醒列表、不写入系统日历。
  - Android 原生不可用或无响应时进入应用内前台全屏兜底，支持立即预览。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/FakeIncomingCallActivity.kt`
  - 接入独立 `callId`、铃声开关和震动开关，结束时清理对应模拟来电通知。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/MainActivity.kt`
- `android/app/src/main/kotlin/group/zn/xianyushengxi/TodoReminderBootReceiver.kt`
- `android/app/src/main/AndroidManifest.xml`
  - 注册 fake-call MethodChannel、Receiver、通知渠道初始化和开机/时间变化重调度。
- `test/ui_smoke_test.dart`
  - 模拟来电 smoke 改为验证开始一次会话并确认不会创建 `life_fake_call` 待办。
- `PROJECT_DOMAIN.md`
  - 同步模拟来电独立模块边界、原生触发链路和平台风险。

### 风险变更
- Android 后台/锁屏全屏唤起仍受通知权限、精确闹钟权限、full-screen notification 设置和厂商后台策略影响。
- 非 Android 或原生通道不可用时只提供应用内前台兜底，用户需要保持页面打开。

### 验证
- `dart format lib/src/services/toolbox_fake_call_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/services/toolbox_fake_call_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart test/ui_smoke_test.dart`（通过；仅余 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens fake incoming call and starts a session"`
- `flutter build apk --debug`（通过；仅余 Java 8 source/target 过时警告）

## [Unreleased-PLAN_277-LIFE-QR-ART-COMPRESS-VERSION] - 2026-05-28

### 原因
- 用户希望二维码艺术图片过大时也能自动压缩，并增加更多 QR 版本选择与弱纠错定位码版本样式，方便生成更接近艺术二维码的模块密度。

### 新增
- `plans/PLAN_277_生活实用二维码艺术图压缩与版本预设.md`
  - 记录艺术图渲染压缩、扩展版本选择、弱纠错艺术预设和可扫性风险。
- `lib/src/services/toolbox_qr_service.dart`
  - 新增艺术图预览压缩结果模型与 `prepareArtImage`，将大艺术源图压缩为渲染友好的 JPEG 副本。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart`
  - 艺术图导入改为 isolate 自动压缩，并展示源图尺寸/体积、艺术图尺寸/体积、压缩摘要和 SHA。
  - QR 版本选择扩展为快捷档 + Auto/V1-V40 精确下拉。
  - 新增“弱纠错 V25”艺术二维码预设：低纠错、大版本、强定位保护、关闭中心图并收紧模块留白。
- `test/toolbox_qr_service_test.dart`
  - 增加艺术图预览压缩服务测试。
- `test/ui_smoke_test.dart`
  - 增加艺术二维码预设和精确版本控件断言。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步艺术图压缩、V1-V40 版本选择、弱纠错预设和风险边界。

### 风险变更
- 艺术图压缩只用于预览渲染，不改变 QR payload；压缩过强时图片轮廓可能变弱。
- 弱纠错 V25 预设更适合半调艺术效果，但抗污损、遮挡和低对比能力更弱，正式分享前必须使用目标扫码器实测。

### 验证
- `dart format lib/src/services/toolbox_qr_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart test/toolbox_qr_service_test.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/services/toolbox_qr_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart test/toolbox_qr_service_test.dart`
- `flutter test test/toolbox_qr_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens QR generator rich controls"`
- `dart analyze lib/src/services/toolbox_qr_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart test/toolbox_qr_service_test.dart test/ui_smoke_test.dart`（未通过：当前工作树中 `lib/src/ui/pages/toolbox_life_tools.dart` 存在与本轮 QR 改动无关的 `toolbox_fake_call_service.dart` 未使用导入 warning；另有 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/ui_smoke_test.dart --plain-name "life tools QR shows capacity error instead of throwing"`

## [Unreleased-PLAN_279-HUMAN-HAND-EYE-PAUSE-CONTROL] - 2026-05-28

### 原因
- 用户希望工具箱-人类测试中心-手眼协调测试底部主操作从“开始/进行中”扩展为可实际控制的开始/暂停功能。

### 新增
- `plans/PLAN_279_人类测试手眼协调开始暂停控制.md`
  - 记录手眼协调开始、暂停、继续的状态流、计时恢复和验证范围。

### 修改
- `lib/src/ui/pages/toolbox_human_tests_hand_eye.dart`
  - 新增暂停状态，底部主按钮现在按阶段显示开始、暂停、继续、重新开始。
  - 暂停时会停止随机出靶 timer、目标显示 timer、目标运动和反应计时；继续时恢复等待剩余时间或目标剩余显示窗口。
  - 暂停中舞台显示独立提示，且本轮设置继续锁定，避免恢复时参数变化影响计时与目标判定。
- `lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart`
  - 全屏底部主按钮复用同一套开始/暂停/继续逻辑；暂停时全屏动画 ticker 不再推动目标运动。
- `lib/src/ui/pages/toolbox_human_tests_hand_eye_settings.dart`
  - 手眼协调设置锁定条件从仅运行中改为整个会话中，暂停也不会开放参数编辑。
- `test/ui_smoke_test.dart`
  - 扩展手眼协调 smoke，覆盖开始后显示暂停、暂停后显示继续、继续后回到等待状态。

### 风险变更
- 暂停/继续会尽量恢复剩余等待和目标显示窗口；若等待剩余时间已经不可用，会用短等待兜底，避免恢复后立即出现不稳定状态。
- 暂停不清空成绩，重置仍是清空本轮的唯一入口。

### 验证
- `dart format lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_settings.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`（通过；仅余 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/ui_smoke_test.dart --plain-name "hand-eye coordination exposes target settings"`

## [Unreleased-PLAN_278-HUMAN-HAND-EYE-START-FIX] - 2026-05-28

### 原因
- 用户反馈工具箱-人类测试中心-手眼协调测试中，舞台中心开始按钮点击无效，且下侧初始操作状态错误显示为重新开始。

### 新增
- `plans/PLAN_278_人类测试手眼协调开始状态修复.md`
  - 记录手眼协调舞台触控边界、底部主操作状态和回归验证范围。

### 修改
- `lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart`
  - 舞台触控边界仅在等待目标或目标可见阶段启用，避免空闲/完成态抢占中央开始按钮点击。
- `lib/src/ui/pages/toolbox_human_tests_hand_eye.dart`
  - 下侧主按钮按空闲、运行、完成三种阶段分别显示开始、进行中、重新开始。
- `test/ui_smoke_test.dart`
  - 补充手眼协调初始态不显示 Restart、中央开始按钮可触发等待状态、运行态显示 Running 的回归断言。

### 修复
- 修复手眼协调测试舞台中心开始按钮被舞台手势边界拦截导致无法启动的问题。
- 修复下侧主操作按钮在初始空闲态错误显示重新开始的问题。

### 风险变更
- 目标点击和等待阶段仍保留原有手势接管，避免真机窄屏下被父级滚动抢走触点；本轮只放开非运行阶段的按钮点击。

### 验证
- `dart format lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`（通过；仅余 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/ui_smoke_test.dart --plain-name "hand-eye coordination exposes target settings"`

## [Unreleased-PLAN_276-LIFE-QR-QART-HALFTONE] - 2026-05-28

### 原因
- 用户反馈当前二维码艺术化效果仍像破碎背景贴图，无法达到参考 QArt 示例那种图像与二维码模块融合的艺术二维码观感。

### 新增
- `plans/PLAN_276_生活实用二维码艺术化半调升级.md`
  - 记录半调融合、QR 功能区保护、非完整 QArt 编码优化算法边界与验证范围。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart`
  - 将 QArt 图片取色模式升级为“半调画像”：按导入图片的亮度、边缘和稳定抖动值计算模块墨量，让图像轮廓真正参与二维码视觉主体。
  - 艺术 QR 预览保护 finder、timing、alignment、format/version 等功能区，保持高对比黑白结构，降低艺术化破坏可扫性的风险。
  - 调整默认可扫性保护、图像对比和模块留白参数，并更新控件文案。
- `test/ui_smoke_test.dart`
  - 更新 QR rich controls smoke 中的 QArt 模式断言。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步半调艺术融合能力、功能区保护和非完整 QArt 编码优化算法说明。

### 风险变更
- 半调融合仍是渲染层艺术化，不会重写 QR 编码数据位；极复杂或低反差图片仍可能轮廓不清，正式分享前需要用目标扫码器实测。
- 透明融合和低保护设置会提升图像存在感，但可能降低小尺寸预览和低端摄像头下的识别稳定性。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart`
- `dart analyze lib/src/services/toolbox_qr_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart test/toolbox_qr_service_test.dart test/ui_smoke_test.dart`（通过；仅余 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/toolbox_qr_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens QR generator rich controls"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools QR shows capacity error instead of throwing"`

## [Unreleased-PLAN_275-LIFE-QR-QART-IMAGE-FUSION] - 2026-05-27

### 原因
- 用户澄清希望实现 QArt、QRImage、qrcode-art 方向的艺术二维码：二维码模块本身与导入图片融合，而不是简单将图片作为背景或海报贴图；同时要求图片二维码化内容超出承载范围时继续压缩处理。

### 新增
- `plans/PLAN_275_生活实用二维码图片背景与贴图.md`
  - 记录 QArt 风格图片融合、容量回退压缩和可扫性风险边界。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart`
  - 新增 QArt 风格模式：关闭、图片取色、透明融合。
  - 新增导入艺术图、清除图片、可扫性保护层、艺术取色强度和模块留白控制。
  - 新增自绘艺术 QR 预览：从导入图采样颜色，暗模块压暗并保留图像色彩，浅模块保留透明/融合感，定位角强制高对比。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart`
  - 图片 Data URL payload 生成后会按当前 QR 版本/容错能力做容量校验；若仍超出承载范围，会继续尝试更小的 Data URL 目标体积。
- `test/ui_smoke_test.dart`
  - QR rich controls smoke 增加 QArt 风格控件断言。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步 QArt 风格图片融合、非完整 QArt 编码算法说明和超容量继续压缩边界。

### 风险变更
- QArt 风格图片融合会改变二维码视觉对比度，复杂、低反差或暗色图片可能降低扫码成功率；正式分享前仍需用目标设备实测。
- 当前实现是 Flutter 本地“图片采样 + module 艺术绘制”的可扫版本，不是 Qart Go 原版那种通过编码值优化图像匹配的完整算法。
- 图片内容写入二维码依然受 QR 容量限制。自动压缩会尽力缩小缩略图，但不把大图传输包装成二维码文件传输能力。

### 验证
- `dart analyze lib/src/services/toolbox_qr_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart test/toolbox_qr_service_test.dart test/ui_smoke_test.dart`
- `flutter test test/toolbox_qr_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens QR generator rich controls"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools QR shows capacity error instead of throwing"`

## [Unreleased-PLAN_274-LIFE-QR-CAPACITY-PREVIEW-GUARD] - 2026-05-27

### 原因
- 用户反馈二维码图片二维码化后出现 `QrInputTooLongException: Input too long. 17260 > 10208`，说明超容量 payload 仍进入了 `QrImageView` 预览渲染阶段并触发未捕获框架异常。

### 新增
- `plans/PLAN_274_生活实用二维码超容量预览防崩.md`
  - 记录 QR 超容量预览防崩、懒加载校验风险和 UI 验证范围。
- `test/ui_smoke_test.dart`
  - 新增超长 QR 内容 smoke，验证页面显示容量错误且 `tester.takeException()` 为空。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart`
  - 新增安全 QR 校验流程：`QrValidator.validate` 后主动构造 `QrPainter.withQr`，提前触发 QR 库懒加载容量异常。
  - 预览区在校验失败时显示错误面板，不再创建 `QrImageView`；导出按钮继续按校验状态禁用。
  - 有效 QR 预览改为使用已校验的 `QrCode` 构建 `QrImageView.withQr`，降低二次懒校验风险。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步 QR 超容量预览防崩和导出禁用边界。

### 风险变更
- 超容量内容仍无法生成 QR Code，这是二维码标准容量限制；页面现在稳定提示用户缩短内容、降低容错/版本限制或改用中心图，而不是发生框架异常。
- Data Matrix、Aztec、PDF417 仍由 `barcode_widget` 自身 errorBuilder 承接渲染错误。

### 验证
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools QR shows capacity error instead of throwing"`

## [Unreleased-PLAN_273-LIFE-QR-IMAGE-AUTO-COMPRESS] - 2026-05-27

### 原因
- 用户指出二维码模块在“图片二维码化”时，较大图片会直接异常，用户难以判断文件大小限制；需要参照图片压缩能力自动压缩到适合二维码写入的大小。

### 新增
- `plans/PLAN_273_生活实用二维码图片自动压缩.md`
  - 记录图片二维码化自动压缩目标、读取硬上限、容量风险和验证范围。
- `test/toolbox_qr_service_test.dart`
  - 新增 noisy 大图自动压缩测试，验证大图会多档回退到目标 Data URL 体积内。

### 修改
- `lib/src/services/toolbox_qr_service.dart`
  - `encodeImageToDataUrl` 增加 QR payload 专用自动压缩策略：先按用户当前参数编码，若 Data URL 超过目标体积，则自动尝试更小最长边和更低 JPEG 质量，优先选取满足目标的候选。
  - 二维码图片结果新增源图尺寸/体积、目标 Data URL 体积、尝试次数、自动压缩状态和压缩摘要，便于 UI 解释处理结果。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart`
  - 图片二维码化导入从 12MB 直接拒绝改为 32MB 读取硬上限内自动压缩。
  - 页面补充自动压缩说明、原图与结果体积展示，以及最小候选仍超目标时的扫码稳定性警告。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步二维码图片自动压缩能力、32MB 硬上限、2.2KB 目标和中心图兜底建议。

### 风险变更
- 自动压缩降低了大图导入失败概率，但二维码本身容量仍有限；复杂图片即使压到很小也可能导致扫码不稳定。
- 超过 32MB 的源图仍会被拒绝，以避免移动端解码和内存压力；这类图片需要先裁切或使用图片压缩页处理。
- 若 Data URL 最小候选仍超出建议体积，应优先改用中心图模式，而不是把图片内容硬写入二维码。

### 验证
- `dart analyze lib/src/services/toolbox_qr_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart test/toolbox_qr_service_test.dart`
- `flutter test test/toolbox_qr_service_test.dart`

## [Unreleased-PLAN_272-LIFE-OFFER-SELECT] - 2026-05-27

### 原因
- 用户要求参考当前占位网页内容，完成 `工具箱-生活实用-Offer 选择助手` 模块，而不是继续停留在外部资源入口。

### 新增
- `plans/PLAN_272_生活实用Offer选择助手模块.md`
  - 记录参考页字段、六维评分、谈薪追平、隐私和职业决策风险边界。
- `lib/src/services/toolbox_offer_select_service.dart`
  - 新增纯计算服务，复用工作性价比服务的收入、成本、工时、环境和成长口径，输出综合分、六维分、风险旗标、优势项和非首选追平首选所需月 Base 加薪估算。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_offer_select.dart`
  - 新增 Offer 选择助手页面，支持个人履历、多个工作机会、薪资/WLB 评级、福利、社保、工作强度、地点、优缺点、已婉拒、决策权重、排序拆解、决策报告和参考工具链。
- `test/toolbox_offer_select_service_test.dart`
  - 覆盖未婉拒排序、权重翻转、谈薪追平和高风险旗标。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 将 `offer_select` 从占位说明页切换为本地工具页，更新入口摘要、分类和来源说明。
- `test/ui_smoke_test.dart`
  - 新增 life tools Offer 选择助手 smoke，覆盖入口打开、首屏舞台、权重区、排序区、参考工具链和薪资字段更新。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步 Offer 选择助手的本地能力、参考页关系、风险边界和版本历史。

### 风险变更
- Offer 评分只做透明横向比较和谈薪准备，不构成职业、法律、税务或财务建议。
- 页面不上传 Offer 数据，不写入学习记录；合同主体、试用期、奖金/股票兑现、社保缴纳和真实工资条仍需用户自行核验。
- 当非薪资维度差距过大时，追平金额可能提示不适合只靠加薪解决。

### 验证
- `dart analyze lib/src/services/toolbox_offer_select_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_offer_select.dart test/toolbox_offer_select_service_test.dart test/ui_smoke_test.dart`（通过；仅余既有 info 级 lint）
- `flutter test test/toolbox_offer_select_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens offer selector and updates an offer"`

## [Unreleased-PLAN_269-LIFE-SHORT-LINK-QR] - 2026-05-27

### 原因
- 用户要求丰富并完善 `工具箱-生活实用` 下的短链接生成与还原、二维码生成能力，增加样式、内容模板、编码标准，并支持基于用户导入图片的二维码化。

### 新增
- `plans/PLAN_269_生活实用短链接与二维码增强.md`
  - 记录短链接多服务、二维码模板/样式/标准、图片二维码化和移动端风险边界。
- `lib/src/services/toolbox_short_link_service.dart`
  - 新增 URL 规范化、TinyURL/is.gd/v.gd/CleanURI 多服务生成、自定义别名清理、本地短码和重定向链路还原。
- `lib/src/services/toolbox_qr_service.dart`
  - 新增文本、URL、Wi-Fi、vCard、邮件、短信、电话、地理位置、日历和图片 Data URL payload 构建，提供容量提示。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_short_link.dart`
  - 新增短链接工作台，支持服务选择、别名、生成、还原链路、复制和本地短码兜底反馈。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart`
  - 新增本地二维码/二维条码生成页，支持 QR Code、Data Matrix、Aztec、PDF417、内容模板、样式、中心图、图片二维码化和 PNG 导出。
- `test/toolbox_short_link_service_test.dart`
- `test/toolbox_qr_service_test.dart`
  - 覆盖短链接服务基础行为和二维码 payload 构建。

### 修改
- `pubspec.yaml` / `pubspec.lock`
  - 增加 `qr_flutter` 与 `barcode_widget` 依赖，用于本地 QR 和多标准二维条码渲染。
- `lib/src/ui/pages/toolbox_life_tools.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 将 `short_link`、`qr` 从旧占位实现切换到独立工具页，并更新入口摘要、来源与 part 接入。
- `test/ui_smoke_test.dart`
  - 新增 life tools 短链接和二维码工具 smoke 覆盖。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步短链接/二维码增强能力、依赖来源、图片二维码容量和扫码兼容边界。

### 风险变更
- 公开短链接服务可能变更 API、限流或不可达，页面提供多服务和本地短码兜底，但本地短码不是公网可访问短链接。
- 重定向链路还原只展示跳转过程，不判断最终目标是否安全。
- 图片 Data URL 二维码容量很小，只适合极小头像、图标或签名图；品牌露出更建议使用中心图叠加。
- Wi-Fi、日历、联系人和非 QR 标准在不同扫码器上的兼容性不同，正式使用前需要用目标设备实测。

### 验证
- `dart analyze lib/src/services/toolbox_short_link_service.dart lib/src/services/toolbox_qr_service.dart test/toolbox_short_link_service_test.dart test/toolbox_qr_service_test.dart`
- `flutter test test/toolbox_short_link_service_test.dart test/toolbox_qr_service_test.dart`
- `dart analyze test/ui_smoke_test.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_short_link.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens short link tool controls"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens QR generator rich controls"`

## [Unreleased-PLAN_270-LIFE-ID-PHOTO-GENERATOR] - 2026-05-27

### 原因
- 用户要求参考当前占位入口网页完成 `工具箱-生活实用-证件照生成` 模块，将外部入口升级为本地可用工具。

### 新增
- `plans/PLAN_270_生活实用证件照生成模块.md`
  - 记录证件照生成的本地实现目标、参考网页流程、背景替换边界和验证范围。
- `lib/src/services/toolbox_id_photo_service.dart`
  - 新增纯 Dart 证件照生成服务，支持常见规格毫米转像素、EXIF 方向烘焙、按目标比例裁切、缩放、四角取样简易换底色和 PNG/JPEG 编码。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_id_photo.dart`
  - 新增证件照生成页面，支持选择本地图片、配置规格、DPI、底色、导出格式、裁切缩放、位置偏移、背景容差和替换强度。
  - 页面展示源图、生成结果、输出像素、文件体积、裁切区域、换底像素和使用边界说明。
- `test/toolbox_id_photo_service_test.dart`
  - 覆盖规格尺寸换算、纯色背景替换和 JPEG 导出。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 将 `id_photo` 从占位来源入口切换为 `_IdPhotoToolPage`，并更新入口摘要与图像分类。
- `test/ui_smoke_test.dart`
  - 新增 life tools 证件照 smoke，覆盖入口打开、照片舞台、参数面板、选择、生成与导出按钮。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步证件照生成的本地离线处理能力、参考规格范围和简易换底色风险边界。

### 风险变更
- 当前证件照生成全程本地处理，不上传照片；简易换底色通过照片四角取样匹配相近背景，不等同 AI 人像分割或专业抠图。复杂背景、头发边缘、阴影和机构强规范场景仍需以办事机构要求和专业修图结果为准。

### 验证
- `dart analyze lib/src/services/toolbox_id_photo_service.dart lib/src/ui/pages/toolbox_life_tools.dart test/toolbox_id_photo_service_test.dart test/ui_smoke_test.dart`（通过；仅余既有 `test/ui_smoke_test.dart` info 级 const/final 提示）
- `flutter test test/toolbox_id_photo_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens id photo generator controls"`

## [Unreleased-PLAN_271-LIFE-AI-INTERVIEW] - 2026-05-27

### 原因
- 用户要求参考当前占位来源项目完成 `工具箱-生活实用-AI 面试` 模块，而不是继续停留在资源入口。

### 新增
- `plans/PLAN_271_生活实用AI面试训练模块.md`
  - 记录 AI 面试从占位升级为本地训练工作台的目标、参考边界、隐私风险和验证范围。
- `lib/src/services/toolbox_ai_interview_service.dart`
  - 新增本地面试题分析服务，支持自动识别行为面试、技术问答、系统设计、产品/业务 case 和 HR/动机题。
  - 新增回答框架、草稿准备度评分、草稿体检、模拟追问、提示词草稿、下一步清单和合规边界提示。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_ai_interview.dart`
  - 新增 AI 面试训练页面，首屏展示题型、准备度、当前题目和下一步状态。
  - 支持输入面试题、岗位、公司/团队、简历亮点和回答草稿，并配置题型、分析深度、输出语言、表达风格、追问和评分严格度。
- `test/toolbox_ai_interview_service_test.dart`
  - 覆盖题型识别、系统设计输出、STAR 草稿评分和合规提示词边界。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 将 `ai_interview` 入口从占位说明页切换为独立本地页面，并更新摘要、分类和 Snap-Solver 来源说明。
- `test/ui_smoke_test.dart`
  - 新增 life tools AI 面试 smoke，覆盖入口打开、首屏舞台、题目素材、回答框架和提示词草稿。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步 AI 面试本地训练能力、参考项目关系和隐私/合规边界。

### 风险变更
- 当前模块是本地启发式训练与答案组织工具，不接入远程 AI，也不实现屏幕捕获、后台监听或实时代答。若用户复制提示词到第三方 AI，应先移除敏感简历、薪资、客户资料、公司保密题和 NDA 内容。

### 验证
- `dart analyze lib/src/services/toolbox_ai_interview_service.dart test/toolbox_ai_interview_service_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_ai_interview.dart`
- `dart analyze lib/src/services/toolbox_ai_interview_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_ai_interview.dart test/toolbox_ai_interview_service_test.dart test/ui_smoke_test.dart`（通过；仅余 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示）
- `flutter test test/toolbox_ai_interview_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens AI interview practice desk"`

## [Unreleased-PLAN_268-LIFE-IMAGE-TO-WEB-UGUU] - 2026-05-27

### 原因
- 用户要求基于占位参考项目完成 `工具箱-生活实用-图片转网页`，并在该功能模块下新增基于 `https://uguu.se` 的临时图片上传分享。

### 新增
- `plans/PLAN_268_生活实用图片转网页与临时分享.md`
  - 记录图片转网页、Uguu 临时分享、第三方接口变化和敏感图片上传风险。
- `lib/src/services/toolbox_image_to_web_service.dart`
  - 新增图片 MIME 识别、单文件 HTML 生成、文件名清理和 Uguu JSON 上传响应解析。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_to_web.dart`
  - 新增图片转网页页面，支持选择本地图片、配置标题/替代文本/图片适配/背景、保存或复制 HTML。
  - 新增 Uguu 临时分享区，使用 `POST https://uguu.se/upload` 的 `files[]` 表单字段上传原图并显示可复制/可打开的临时 URL。
- `test/toolbox_image_to_web_service_test.dart`
  - 覆盖 HTML 生成、Uguu JSON 解析和常见图片 MIME 识别。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 接入图片转网页服务与页面 part，更新 `image_to_web` 入口摘要和来源说明。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 将 `image_to_web` 从占位说明页切换到 `_ImageToWebToolPage`。
- `test/ui_smoke_test.dart`
  - 新增 life tools 图片转网页 smoke，覆盖入口打开、核心面板和本地/上传操作按钮。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步图片转网页本地 HTML 能力、Uguu 临时分享和隐私/过期边界。

### 风险变更
- 本地 HTML 生成不会上传图片；Uguu 分享会把原图上传到第三方公开临时文件服务。Uguu 当前公开 API 页声明上传端点为 `https://uguu.se/upload`，FAQ 当前声明文件约 3 小时后删除，并保留活动文件的名称、hash、IP 和上传时间到文件过期；接口、可达性、限额和保留策略都可能变化。
- 单文件 HTML 会把图片转为 Base64，文件体积会大于原图；大图复制 HTML 文本可能较慢，建议优先保存为 `.html` 文件。

### 验证
- `dart analyze lib/src/services/toolbox_image_to_web_service.dart lib/src/ui/pages/toolbox_life_tools.dart test/toolbox_image_to_web_service_test.dart test/ui_smoke_test.dart`（通过；仅余既有 `test/ui_smoke_test.dart` info 级 const/final 提示）
- `flutter test test/toolbox_image_to_web_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens image to webpage controls"`

## [Unreleased-PLAN_268-LIFE-STEGANOGRAPHY-DUAL-FILE-PREVIEW] - 2026-05-27

### 原因
- 用户指出隐写模块仍缺少文件双层加密模式和写入预览，导致 UI 暗示的高级能力没有真正闭环。

### 新增
- `plans/PLAN_268_生活实用隐写文件双层与写入预览补齐.md`
  - 记录文件双层、音视频双层槽位、写入预览和验证范围。
- `lib/src/services/toolbox_steganography_service.dart`
  - 新增 `embedDualFile`，文件载荷支持图片双槽、WAV/PCM 样本双槽、MP4/MOV 双 `free` box 写入。
  - 文件容量预检支持双层参数，返回表层/深层所需容量、总容量、每层容量和预计媒介边界。
- `test/toolbox_steganography_service_test.dart`
  - 覆盖图片、音频、视频的双层文本往返和双层文件往返，验证表层/深层口令分别还原对应层。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 文件写入模式接入双层开关，新增表层文件选择、表层口令输入和双层文件请求参数。
  - 文本/文件写入新增“预览写入”按钮，生成前展示媒介、容量、预计载荷、预计输出和双层提示。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步隐写模块文件双层和写入预览能力边界。

### 风险变更
- WAV/PCM 双层仍不抗有损转码；MP4/MOV 双 `free` box 仍可能被重封装工具移除。写入预览为容量估算，实际生成后仍以结果面板的真实输出大小为准。

### 验证
- `dart format lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_steganography_service_test.dart`
- `dart analyze lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_267-LIFE-STEGANOGRAPHY-AUDIO-VIDEO-WRITE] - 2026-05-27

### 原因
- 用户指出图片隐写核心能力已完善，但音频、视频媒介以及写入文件仍是简单实现，需要优化到与图片隐写安全强度和性能基本对齐。

### 新增
- `plans/PLAN_267_生活实用隐写音视频与导出优化.md`
  - 记录 WAV/PCM、MP4/MOV 容器写入、导出可靠性和格式边界风险。
- `lib/src/services/toolbox_steganography_service.dart`
  - 新增 WAV/PCM 音频样本 LSB 后端：使用口令/keyfile 派生定位头、随机样本顺序、公开策略头、容量预检、重复写入拒绝、隐藏载荷清理和成功还原次数消费。
  - 新增 MP4/MOV 容器 `free` box 后端：新写入不再使用裸尾部追加，载荷带密钥定位头、长度掩码、随机 padding、公开策略头、重复写入拒绝和成功次数清理。
- `test/toolbox_steganography_service_test.dart`
  - 覆盖 WAV 文本往返、MP4 文本往返、音视频文件 payload 往返、WAV 成功次数清理、MP4 重复写入拒绝和 WAV 容量预检。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 音频/视频写入按钮不再被旧“等待后端”逻辑禁用。
  - 保存 keyfile、隐写媒体和文件结果时，平台返回可写路径后主动 `writeAsBytes` 落盘；未返回路径时继续使用应用文档目录兜底，Web 保持浏览器下载。
  - 容量不足提示按图片、WAV/PCM 和 MP4/MOV 分别说明可用容量、所需容量和载体建议。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步音视频隐写后端、旧尾部载荷兼容和转码/重封装边界。

### 风险变更
- WAV/PCM 样本 LSB 不抗 MP3/AAC 等有损转码；MP4/MOV `free` box 不抗会剥离自由 box 的重封装或平台二次处理。真正的数据认证仍来自 crypto envelope 的 MAC/AEAD，公开策略头和次数限制仍只是本机当前文件的最佳努力提示与清理。

### 验证
- `dart analyze lib/src/services/toolbox_steganography_service.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
- `dart analyze test/toolbox_steganography_service_test.dart`
- `flutter test test/toolbox_steganography_service_test.dart`

## [Unreleased-PLAN_266-LIFE-MORTGAGE-PRO] - 2026-05-27

### 原因
- 用户要求完成 `工具箱-生活实用-房贷计算器`，在等额本息/等额本金、贷款年限、计算方式、贷款金额、利率和首次还款时间基础上，提供比参考网页更专业且可自定义的本地测算能力。
### 新增
- `plans/PLAN_266_生活实用房贷计算器专业化实现.md`
  - 记录房贷计算器专业化实现目标、公式口径、移动端 UI 边界和风险说明。
- `lib/src/services/toolbox_mortgage_service.dart`
  - 新增纯计算服务，覆盖等额本息、等额本金、贷款金额/住房面积两种计算方式、首付比例/首付金额、首次还款日、已还期数、提前还本金、月供降低/期限缩短和费用统计。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mortgage.dart`
  - 新增专业房贷工作台，展示下期月供、贷款金额、合同总利息、剩余本金、剩余时间、合同费用、已还/剩余明细和后续 12 期还款计划。
- `test/toolbox_mortgage_service_test.dart`
  - 覆盖等额本息、等额本金、面积反推贷款额、费用统计和提前还款缩短期限。
### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 接入房贷计算服务与新页面 part。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 将 `mortgage` 路由从旧占位页切换到 `_MortgageProPage`。
- `test/ui_smoke_test.dart`
  - 新增 life tools 房贷计算器 smoke，覆盖入口打开与住房面积模式切换。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步房贷计算器能力范围、可自定义参数和估算边界。
### 风险变更
- 房贷测算结果按本地公式估算，实际扣款仍可能受银行合同、放款日、计息起点、LPR 调整、商贷/公积金组合、地区税费、保险评估费和提前还款违约金影响。
### 验证
- `dart analyze lib/src/services/toolbox_mortgage_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mortgage.dart test/toolbox_mortgage_service_test.dart test/ui_smoke_test.dart`（通过；仅余既有 `test/ui_smoke_test.dart` info 级 const/final 提示）
- `flutter test test/toolbox_mortgage_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens mortgage calculator and switches mode"` 未通过：当前工作树中 `lib/src/services/toolbox_steganography_service.dart` 缺失音视频隐写相关私有类型/方法（如 `_WavCarrierInfo`、`_Mp4CarrierInfo`），导致 `ui_smoke_test.dart` 编译在进入房贷用例前失败；另一次并行 `flutter test` 触发 Windows `native_assets.json` 文件锁，已改为单独重跑房贷服务测试并通过。

## [Unreleased-PLAN_264-LIFE-DATE-CALCULATOR-PROGRESS] - 2026-05-27

### 原因
- 用户要求优化完善 `工具箱-生活实用-日期计算器`，原实现只是简单占位，需要支持秒级选择、多单位计算、周期剩余进度、目标日期进度和生命烛光图形化展示。

### 新增
- `plans/PLAN_264_生活实用日期计算器专业化增强.md`
  - 记录日期计算器从占位升级为时间工作台的目标、步骤、年份/月度计算风险和验证边界。
- `lib/src/services/toolbox_date_calculator_service.dart`
  - 新增纯 Dart 日期计算服务，支持日历时间差、日期加减、分数/百分比年数、当前周期进度、目标日期进度和生命烛光进度。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_date_calculator.dart`
  - 新增独立日期计算器页面，提供 `时间差 / 加减 / 进度 / 烛光` 四个页签。
  - 起止时间和目标时间支持日期、时分与秒级选择；加减模式支持年、月、天、小时、分钟、秒多单位输入，年可输入 `0.5` 或 `50%`。
  - 进度页展示目标日期进度，以及今年、本月、本周、本日、本小时的动态剩余进度；低层级条目可折叠查看。
  - 烛光页按出生时间和预期寿命展示生命烛光燃烧比例、剩余蜡身、预计终点、已过与剩余时长。
- `test/toolbox_date_calculator_service_test.dart`
  - 覆盖秒级时间差、百分比年、日历月夹取、周期剩余、目标进度和生命烛光比例。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 接入日期计算服务与独立页面 part。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 移除旧占位 `_DateCalculatorPage`，保留路由分发到新独立页面。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_shared.dart`
  - `_LifeSettingsPanel` 支持传入 `key`，供日期页签切换保持稳定动画状态。
- `test/ui_smoke_test.dart`
  - 新增 life tools 日期计算器 smoke，覆盖四个页签、百分比年输入、周期进度与生命烛光入口。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步日期计算器能力、计算口径和非医学预测边界。

### 风险变更
- 整数年/月使用日历推进，月末会按目标月最后一天夹取；小数年/月按对应自然年/月长度折算为秒，避免把所有月份粗略当成固定 30 天。
- 生命烛光默认预期寿命使用 79 年，仅作为时间感知与提醒工具，不构成医学或寿命预测。

### 验证
- `dart analyze lib/src/services/toolbox_date_calculator_service.dart lib/src/ui/pages/toolbox_life_tools.dart test/toolbox_date_calculator_service_test.dart test/ui_smoke_test.dart`（通过；仅余既有 `test/ui_smoke_test.dart` 信息级 lint）
- `flutter test test/toolbox_date_calculator_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens date calculator progress and candle tabs"`

## [Unreleased-PLAN_263-LIFE-BMI-PROFESSIONAL] - 2026-05-27

### 原因
- 用户要求优化完善 `工具箱-生活实用-BMI 计算器`，当前模块只有简单计算，需要参考专业资料加入儿童、青少年、成人、性别等差异，并增加更多相关实用工具。

### 新增
- `plans/PLAN_263_生活实用BMI计算器专业化增强.md`
  - 记录 BMI 专业化增强的成人/儿童青少年口径、资料来源、围度与能量估算边界。
- `lib/src/services/toolbox_bmi_service.dart`
  - 新增纯计算服务，覆盖成人中国/WHO BMI 分类、CDC 2-19 岁 BMI-for-age 百分位、腰高比、腰臀比、Mifflin-St Jeor 基础代谢和活动水平 TDEE 估算。
- `lib/src/services/toolbox_bmi_cdc_data.dart`
  - 内置 CDC `bmiagerev.csv` LMS 参考数据，运行时无需联网即可估算儿童青少年 BMI-for-age 百分位。
- `test/toolbox_bmi_service_test.dart`
  - 覆盖成人中国口径、WHO 肥胖等级、儿童 BMI-for-age 和 2 岁以下不适用边界。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_bmi.dart`
  - BMI 页面重构为 `结果摘要 → 输入参数 → 专业辅助工具 → 参考说明`。
  - 新增年龄、性别、中国成人/WHO 国际成人口径、腰围、臀围和活动水平输入。
  - 成人显示分类、健康体重区间和目标差量；儿童青少年显示 CDC BMI-for-age 百分位与年龄段；专业工具区展示腰高比、腰臀比、BMR 和 TDEE。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 移除已不再使用的旧简版 `_BmiPage`。
  - 沿用当前工作树已接入的房贷服务计算等额本息结果，避免 `toolbox_mortgage_service.dart` 引用悬空。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_date_calculator.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mortgage.dart`
  - 补齐当前 life tools 主文件已引用但缺失的日期/房贷 part 壳，避免阻塞 BMI 定向分析和 smoke。
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 更新 BMI 入口摘要和权威来源入口。
- `test/ui_smoke_test.dart`
  - BMI smoke 覆盖腰高比/BMR 展示和儿童百分位入口。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步 BMI 新口径、辅助工具和非医学诊断边界。

### 风险变更
- 儿童青少年 BMI 使用 CDC 2-19 岁参考数据，并不代表本地儿科诊断标准；2 岁以下不做 BMI-for-age 分类。
- BMR/TDEE、腰高比和腰臀比均为估算辅助，孕期、运动员、增肌、疾病恢复期或特殊病史人群仍应优先使用专业评估。

### 验证
- `dart analyze lib/src/services/toolbox_bmi_service.dart lib/src/services/toolbox_bmi_cdc_data.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_bmi.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_date_calculator.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mortgage.dart test/toolbox_bmi_service_test.dart test/ui_smoke_test.dart`（通过；仍有既有信息级 lint 提示）
- `flutter test test/toolbox_bmi_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools recalculates bmi classification"`

## [Unreleased-PLAN_265-LIFE-WORLD-CLOCK] - 2026-05-27

### 原因
- 用户要求在 `工具箱-生活实用` 中新增 `世界时钟` 模块，并放在 `日期计算器` 下方。

### 新增
- `plans/PLAN_265_生活实用世界时钟模块实现.md`
  - 记录世界时钟入口顺序、内置城市、时区规则、页面拆分和验证边界。
- `lib/src/services/toolbox_world_clock_service.dart`
  - 新增常用城市静态数据、UTC 偏移计算、基础夏令时规则、本地时差、办公时段和搜索筛选能力。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_world_clock.dart`
  - 新增世界时钟页面，包含本地时间主舞台、搜索/地区/办公时间筛选、收藏时钟、城市列表和使用边界说明。
- `test/toolbox_world_clock_service_test.dart`
  - 覆盖时区偏移、南北半球夏令时、搜索和办公时段筛选。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 注册 `world_clock` 工具入口，顺序放在 `date_calculator` 下方。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 接入世界时钟路由分发。
- `test/ui_smoke_test.dart`
  - 新增 life tools 世界时钟打开与筛选 smoke。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步世界时钟能力与内置时区规则风险。

### 风险变更
- 世界时钟使用内置常见城市和基础 DST 规则，适合当前时间速查；不覆盖历史时区校验、政策变化后的新规则或所有城市。

### 验证
- `dart analyze lib/src/services/toolbox_world_clock_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_shared.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_world_clock.dart test/toolbox_world_clock_service_test.dart test/ui_smoke_test.dart`（通过；仅余既有 utilities/test 文件 info 级提示）
- `flutter test test/toolbox_world_clock_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens world clock and filters cities"`

## [Unreleased-PLAN_262-LIFE-FAKE-CALL-TRIGGER-FIX] - 2026-05-27

### 原因
- 用户进一步反馈 `工具箱-生活实用-模拟来电` 不需要触发前来电主舞台，只需要到点全屏播放来电特效；同时存在倒计时输入不符合预期、删除不实时刷新、铃声震动会自动停止和测试到点未触发的问题。

### 新增
- `plans/PLAN_262_生活实用模拟来电触发与倒计时输入修复.md`
  - 记录本轮页面收口、倒计时输入、列表刷新、Android 闹钟级调度和持续响铃震动的修复边界。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart`
  - 移除触发前的来电主舞台预览，页面改为新建模拟来电、触发能力、已创建来电列表。
  - 倒计时改为用户手动输入时长并选择秒/分钟/小时单位，创建时校验正数与最长 7 天边界。
  - 已创建来电的完成、稍后 10 分钟和删除操作后立即刷新当前列表。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/TodoReminderScheduler.kt`
  - `fakeCall` 调度优先使用 `AlarmManager.setAlarmClock`，提升短时测试和锁屏/待机状态下的到点触发可靠性。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/TodoReminderReceiver.kt`
  - 移除模拟来电通知的 45 秒 timeout，通知保持到用户处理。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/FakeIncomingCallActivity.kt`
  - 移除 45 秒自动关闭，铃声与震动持续到用户接听或拒绝。
- `test/ui_smoke_test.dart`
  - 模拟来电 smoke 覆盖手动倒计时、秒单位选择、创建后删除并立即回到空态。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步模拟来电最新模块边界、闹钟级触发链路和权限风险。

### 风险变更
- `setAlarmClock` 更适合准点触发，但部分设备仍可能受通知、全屏通知、闹钟展示或厂商后台策略影响。
- 铃声与震动持续到手动关闭，若用户把来电页切到后台但不接听/拒绝，也会继续播放直到 Activity 销毁或用户关闭。

### 验证
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_notify_me.dart lib/src/services/toolbox_life_notify_service.dart lib/src/services/todo_reminder_service.dart test/ui_smoke_test.dart`（通过；仅余既有 `test/ui_smoke_test.dart` const/final 信息级提示）
- `./gradlew.bat :app:compileDebugKotlin`（通过；仅保留 Android 全屏沉浸旧 API deprecation warning）
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens fake incoming call and creates an item"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens notify me and creates a reminder"`

## [Unreleased-PLAN_261-LIFE-DEVICE-FRAME-STATUS-BAR-REALISM] - 2026-05-27

### 原因
- 用户反馈 `工具箱-生活实用-带壳截图` 状态栏不够拟真：电池状态没有区分低电量/电量不足，右侧状态组比例偏大且未贴近外壳内侧边框。

### 新增
- `plans/PLAN_261_生活实用带壳截图状态栏拟真优化.md`
  - 记录状态栏拟真、电池语义色、右侧布局比例与验证范围。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame_preview.dart`
  - 右侧状态组改为靠右对齐，并通过最大宽度 48% 与 `FittedBox` 限制整体比例，避免超过屏幕的一半。
  - 电池图标与电量文字新增语义色：充电为绿色，低于 30% 为低电量琥珀色，低于 15% 为电量不足红色。
  - 电量不足时使用 `battery_alert` 图标，低电量时使用低电量电池图标，整体字号和图标尺寸同步缩小，更接近真实状态栏比例。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame.dart`
  - 状态栏设置区将充电入口前置为 `电池状态 / Battery state` 分段设置。
  - 电量摘要补充 `正常 / 低电量 / 电量不足 / 充电中` 状态文案。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame_labels.dart`
  - 新增电池状态标签函数，统一中英文状态文案。
- `test/ui_smoke_test.dart`
  - 补充 `toolbox_life_notify_service.dart` import，修复既有模拟来电 smoke 编译符号缺失。
  - 带壳截图 smoke 增加 `Battery state` 与 `Charging` 设置入口断言。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步状态栏拟真、低电量阈值和右侧比例约束。

### 风险变更
- 状态栏拟真属于展示模拟，不读取真实设备电量、网络或充电状态；所有值仍由用户在页面手动配置。

### 验证
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame_labels.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame_preview.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame_models.dart lib/src/ui/pages/toolbox_life_tools.dart test/device_frame_assets_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens device frame controls"`
- `flutter test test/device_frame_assets_test.dart`

## [Unreleased-PLAN_260-LIFE-DEVICE-FRAME-FOCUS-FIX] - 2026-05-27

### 原因
- 用户反馈 `工具箱-生活实用-带壳截图` 模块重点与功能结构错乱，需要围绕“导入截图 → 带壳预览 → 构图调整 → PNG 导出”重新收口。

### 新增
- `plans/PLAN_260_生活实用带壳截图模块收敛与导出优化.md`
  - 记录带壳截图主舞台重整、导入导出边界、文件拆分和验证口径。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame_models.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame_labels.dart`
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame_preview.dart`
  - 拆出机模数据、展示文案和预览渲染，避免主页面继续膨胀并降低后续样式迭代扩散风险。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame.dart`
  - 页面重排为 `截图舞台 → 构图设置 → 状态栏设置 → 使用边界`，首屏直接展示下一步动作、当前预览、导出按钮和关键状态。
  - 新增 `裁切填满 / 完整显示` 截图适配模式，并在原图比例与机模屏幕比例不一致时给出独立提示。
  - 图片导入改为优先走 Web bytes、非 Web read stream / 文件路径读取，并增加 32MB 大图闸门，减少 file picker 直接预读整文件造成的移动端压力。
  - 导出逻辑区分保存对话框取消与平台不可用兜底，继续保留 `RepaintBoundary -> PNG` 与应用文档目录 fallback。
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 注册带壳截图拆分后的 model、label、preview part。
- `test/ui_smoke_test.dart`
  - 带壳截图 smoke 增加截图舞台、预览舞台 key 与“完整显示”适配入口断言。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步带壳截图主流程、导入导出边界和原创机模风险说明。

### 风险变更
- `完整显示` 模式会保留原图完整内容，但当原图比例与机模屏幕差异较大时会出现屏幕内留边；`裁切填满` 更像真机展示，但可能裁掉边缘内容。
- PNG 导出继续依赖 Flutter 渲染树截图与平台保存能力，Web 或移动端保存路径仍可能因平台能力不同而表现不同。

### 验证
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame_labels.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame_models.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame_preview.dart lib/src/ui/pages/toolbox_life_tools.dart test/device_frame_assets_test.dart`
- `flutter test test/device_frame_assets_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens device frame controls"`

## [Unreleased-PLAN_258-LIFE-NOTIFY-ME-CONTROL-FIX] - 2026-05-27

### 原因
- 用户反馈 `工具箱-生活实用-通知自己` 功能混乱、控制粒度不足且存在 bug，需要全面收敛提醒工作台、补齐控制项并修复原生通知动作边界。

### 新增
- `plans/PLAN_258_生活实用通知自己功能收敛与提醒控制完善.md`
  - 记录通知自己页面收敛、提醒控制粒度、Android 通知动作和验证边界。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_notify_me_widgets.dart`
  - 拆出通知自己首屏总览、状态 chip、时间信息块、分钟输入、摘要条和提醒列表卡片，避免主页面 part 超过项目文件大小规范。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_notify_me.dart`
  - 页面重构为 `首屏状态总览 → 投递能力 → 新建提醒 → 已创建提醒` 的工作台结构，首屏直接展示当前预览、触发时间、实际提醒时间、下一条提醒、原生能力和日历镜像状态。
  - 创建表单补齐自定义提前分钟、自定义倒计时分钟、状态栏常驻、进入应用取消、系统日历镜像等细粒度控制，并在提前提醒会落到过去时阻止创建。
  - 已创建提醒列表新增已触发状态识别、稍后 10 分钟、稍后 1 小时、套用配置和删除操作。
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 注册通知自己拆分后的 widgets part。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/TodoReminderReceiver.kt`
  - 通知动作新增 `Snooze 10m` 与 `Dismiss`；`Open detail` 不再强制取消通知，修复“进入应用取消”关闭后仍被移除的问题。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/MainActivity.kt`
  - `consumePendingTodoLaunchId` 改为只读取待跳转 id，不提前清空原生动作，避免 complete/snooze/open 等动作在 Focus 页消费前丢失。
- `modules/toolbox/README.md`
  - 同步通知自己工作台结构、控制粒度、原生动作能力和平台风险边界。
- `PROJECT_DOMAIN.md`
  - 同步 `notify_me` 模块能力边界与 Android 原生提醒动作限制。

### 风险变更
- `通知自己` 继续复用 todo reminder 存储与 Android 原生调度；完整通知、锁屏、精确触发仍受通知权限、精确闹钟权限、Android 版本和厂商后台策略影响。
- 原生 `Dismiss` 只负责移除当前通知，不会删除应用内提醒条目；需要彻底关闭提醒仍应在列表中删除或完成。

### 验证
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/services/toolbox_life_notify_service.dart lib/src/services/todo_reminder_service.dart lib/src/services/system_calendar_service.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens notify me and creates a reminder"`

## [Unreleased-PLAN_259-LIFE-FAKE-CALL-FOCUS-FULLSCREEN] - 2026-05-27

### 原因
- 用户反馈 `工具箱-生活实用-模拟来电` 当前重点和模块职责错乱，需要围绕指定时间触发全屏模拟来电重新修复和收口。

### 新增
- `plans/PLAN_259_生活实用模拟来电模块收口与全屏触发修复.md`
  - 记录本轮模拟来电页面职责、Android full-screen notification 触发路径、风险边界与验证口径。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart`
  - 首屏改为来电主舞台，优先展示来电对象、触发时间、全屏投递状态和来电预览。
  - 联系人姓名/号码前置为核心输入，管理名称改为可选；未填写时自动用姓名或号码生成 `life_fake_call` 待办标题。
  - 倒计时预设补充 1 分钟与 3 分钟，便于真机快速验证。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/TodoReminderScheduler.kt`
  - 新增独立 `todo_fake_incoming_call` 通知渠道，使用系统来电铃声、振动与公开锁屏可见性。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/TodoReminderReceiver.kt`
  - 模拟来电触发改为 high-priority `CATEGORY_CALL` 通知 + `setFullScreenIntent` 拉起全屏 Activity，并保留直接 `startActivity` 兜底。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/FakeIncomingCallActivity.kt`
  - 全屏来电页补充中英本地化文案、底部接听/拒绝操作、圆角操作按钮，并在结束或超时后取消对应通知。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_notify_me.dart`
  - 修复恢复提醒页时的 `meta.presentationType.isFakeCall` 错误引用，确保 `通知自己` 保持普通提醒/锁屏提醒职责。
- `test/ui_smoke_test.dart`
  - 模拟来电 smoke 改为验证“只填写来电姓名也能创建条目”，覆盖管理名称可选的新语义。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步 `模拟来电` 模块边界、Android full-screen intent 触发链路与真机权限风险。

### 风险变更
- `模拟来电` 完整全屏体验仍以 Android 为主；Android 14+ 与部分厂商系统可能要求用户允许全屏通知、通知权限或精确闹钟权限。
- `模拟来电` 继续复用 todo reminder 存储与调度，列表隔离依赖 `life_fake_call` 分类和 fake-call 元数据双重识别。

### 验证
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_notify_me.dart lib/src/services/toolbox_life_notify_service.dart lib/src/services/todo_reminder_service.dart`
- `./gradlew.bat :app:compileDebugKotlin`（通过；仅保留 Android 全屏沉浸旧 API deprecation warning）
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens notify me and creates a reminder"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens fake incoming call and creates an item"`

## [Unreleased-PLAN_256-LIFE-CITY-COMPARE-CUSTOM-ADJUSTMENTS] - 2026-05-27

### 原因
- 用户希望“城市薪资对比工具”不要被静态参考样本锁死，尤其是健身、娱乐等没有统一标准的项目，需要支持个人化修正。

### 新增
- `plans/PLAN_256_生活实用城市薪资对比自定义支出与预设微调.md`
  - 记录本轮自定义支出、预设微调与验证边界。

### 修改
- `lib/src/services/toolbox_city_compare_service.dart`
  - 为 `CityCompareProfile` 增加住房、餐饮、交通、教育、水电网话、健身、娱乐倍数微调参数。
  - 增加健身月费与电影票价单项覆盖值，以及自定义月支出模型与分类。
  - 成本拆解现会把“预设样本 + 倍数微调 + 单项覆盖 + 自定义支出”统一纳入月成本计算。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_city_compare.dart`
  - 页面新增 “Adjustments and custom expenses / 费用微调与自定义支出” 区块。
  - 支持按类目调节预设倍数、覆盖健身/月费与电影票单价，并支持新增/删除自定义月支出。
  - 为自定义支出输入框补充稳定 key，便于移动端 smoke 回归。
- `test/toolbox_city_compare_service_test.dart`
  - 新增自定义支出与倍数微调会影响成本拆解和总额的断言。
- `test/ui_smoke_test.dart`
  - 扩展城市薪资对比 smoke：覆盖微调区可见性、自定义支出录入与结果回显。
- `modules/toolbox/README.md`
  - 同步城市薪资对比工具新增的个人校准层能力与风险边界。
- `PROJECT_DOMAIN.md`
  - 同步 `city_compare` 的预设微调、自定义支出能力与版本记录。

### 风险变更
- 倍数微调、单项覆盖和自定义支出属于个人校准层，用于修正静态参考样本，不代表官方统计均值、实时租售价格或标准收费。

### 验证
- `dart analyze lib/src/services/toolbox_city_compare_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_city_compare.dart test/toolbox_city_compare_service_test.dart`
- `flutter test test/toolbox_city_compare_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens city salary compare and updates target salary"`

## [Unreleased-PLAN_257-LIFE-DEVICE-FRAME-UNIT-EXPANSION] - 2026-05-27

### 原因
- 用户继续聚焦工具箱「生活实用」中的 `带壳截图`、`全能单位换算` 与 `BMI 计算器`，希望进一步修正带壳截图在手机窄屏上的偏移观感，补齐更接近主流真机展示感的机模与状态栏客制化，同时扩展单位换算的覆盖范围。

### 新增
- `plans/PLAN_257_生活实用带壳截图机模扩展与单位换算扩容.md`
  - 记录本轮机模资源扩展、状态栏定制、单位分类扩容、证件照尺寸参考与验证范围。
- `assets/toolbox/device_frames/iphone_obsidian_frame.png`
- `assets/toolbox/device_frames/iphone_obsidian_shadow.png`
- `assets/toolbox/device_frames/iphone_obsidian_glare.png`
- `assets/toolbox/device_frames/android_frost_frame.png`
- `assets/toolbox/device_frames/android_frost_shadow.png`
- `assets/toolbox/device_frames/android_frost_glare.png`
  - 新增两套原创前视机模资源，分别补充深色灵动岛与浅色挖孔屏风格。

### 修改
- `scripts/generate_device_frame_assets.ps1`
  - 修正机模侧键的圆角半径计算，避免按钮在窄屏预览里出现外鼓导致的视觉偏移，并同步生成新增机模资源。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame.dart`
  - 扩展为五套机模预设，补齐窄屏自适应居中预览，并新增时间、电量、充电态、蜂窝信号、Wi-Fi 与网络制式等状态栏定制能力。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_unit_converter.dart`
  - 扩展长度、重量、温度、面积、体积、速度、力、密度、功率、热量/能量、数据、时间与 CSS 尺寸换算，并新增证件照尺寸参考模式与 DPI 像素换算。
- `test/device_frame_assets_test.dart`
  - 覆盖新增的 `iphone_obsidian_*` 与 `android_frost_*` 资源打包校验。
- `test/ui_smoke_test.dart`
  - 更新带壳截图与单位换算 smoke，用例覆盖新状态栏设置入口与新增分类入口。
- `modules/toolbox/README.md`
- `PROJECT_DOMAIN.md`
  - 同步带壳截图增强点、单位换算扩容范围与版本记录。

### 风险变更
- `带壳截图` 仍以仓库内原创展示机模为边界，目标是提升真实展示感，而不是复刻某个厂商的官方营销图或精确 OEM 尺寸。
- `全能单位换算` 的 CSS 与证件照能力属于本地参考换算：`rem/em` 依赖基准字号口径，证件照“寸”属于常见市场别名，结果适合设计、排版和日常核对，不替代专业规范文件。

### 验证
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_unit_converter.dart test/device_frame_assets_test.dart test/ui_smoke_test.dart`
- `flutter test test/device_frame_assets_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens device frame controls"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools converts default unit inputs"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools recalculates bmi classification"`

## [Unreleased-PLAN_256-LIFE-FAKE-CALL-SPLIT-MEME-REAL-PREVIEW] - 2026-05-27

### 原因
- 用户追加要求两点修正：`模拟来电` 必须从 `通知自己` 中拆成平行独立模块；`表情包制作` 的预览必须改为真实渲染，修复文本框与字体大小不匹配、字高截断，以及预览缩放能力不足的问题。

### 新增
- `plans/PLAN_256_生活实用模拟来电独立模块与表情包真实预览修正.md`
  - 记录本轮结构修正、风险边界与验证口径。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart`
  - 新增独立 `模拟来电` 工具页，支持指定时间/倒计时、姓名、号码、归属地、标签、预览与创建后列表管理。

### 修改
- `lib/src/services/toolbox_life_notify_service.dart`
  - 新增 `life_fake_call` 分类兼容，并让提醒解析同时识别提醒页与模拟来电页的元数据来源。
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 将 `fake_call` 注册为 life tools 独立入口，并接入新页面 `part`。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 为 life tools 总览接入 `模拟来电` 路由，并让入口数量改为跟随 `_lifeTools.length` 自动显示。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_notify_me.dart`
  - 页面收口为提醒工作台本身，仅保留 `状态栏通知 / 锁屏提醒`、状态栏锁定、进入应用取消、指定时间/倒计时与系统日历同步。
- `lib/src/services/toolbox_meme_service.dart`
  - 预览与导出统一复用同一套 Canvas 绘制函数，并补上经典描边文本的安全边距，避免描边和字高被裁切。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_meme_maker.dart`
  - 预览舞台改为 `CustomPaint + ToolboxMemeService.paint(...)` 真实渲染；支持空白区整体缩放/平移、图层命中选中、拖动与双指缩放。
- `test/ui_smoke_test.dart`
  - 新增 `模拟来电` 工具入口与创建 smoke 用例。
- `modules/toolbox/README.md`
  - 同步 `通知自己 / 模拟来电 / 表情包制作` 的最新结构边界与能力说明。

### 风险变更
- `模拟来电` 底层仍复用 todo reminder 与 Android 原生提醒调度；旧的 fake-call todo 若仍保存在 `life_notify_me` 分类，页面列表会按元数据语义兼容识别。
- `表情包制作` 当前已统一静态 PNG 预览与导出，但仍不包含 GIF/APNG 时间轴、多帧编辑与额外字体资产包。

### 验证
- `dart analyze lib/src/services/toolbox_life_notify_service.dart lib/src/services/toolbox_meme_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_notify_me.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_fake_call.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_meme_maker.dart test/toolbox_meme_service_test.dart`
- `flutter test test/toolbox_meme_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens notify me and creates a reminder"` 未通过：被项目内既有的 `toolbox_life_tools_text_transform.dart` 缺失私有成员编译错误阻塞，非本轮改动引入。
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens fake incoming call and creates an item"` 未通过：同样被 `toolbox_life_tools_text_transform.dart` 现有编译错误阻塞。
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens meme maker controls"` 未通过：同样被 `toolbox_life_tools_text_transform.dart` 现有编译错误阻塞。

## [Unreleased-PLAN_255-LIFE-CITY-COMPARE-REFERENCE-ANALYSIS] - 2026-05-27

### 原因
- 用户希望继续为“城市薪资对比工具”补充更多细分参考资料条目，并在页面中直接做对比分析，而不是只给出汇总结果。

### 新增
- `plans/PLAN_255_生活实用城市薪资对比参考条目扩展与分析.md`
  - 记录本轮细分条目扩展、参考来源与分析目标。

### 修改
- `lib/src/services/toolbox_city_compare_service.dart`
  - 新增参考条目模型与自动分析模型，补充社保基数、不同租房档位、房价、餐饮、手机套餐、宽带、教育、健身和电影票等原始字段对比。
  - 新增自动分析结论，概括最大差异项、同薪资迁移结果、重点原始条目和目标薪资解释。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_city_compare.dart`
  - 页面新增 “Comparison insights / 对比分析” 与 “Reference detail items / 参考细分条目” 区域。
  - 口径说明补充参考项目 README、`public/city_data.csv` 与 Numbeo 公共数据说明。
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 为 `city_compare` 条目补充 web 与 Numbeo 参考来源。
- `modules/toolbox/README.md`
  - 同步城市薪资对比工具新增的细分参考项与自动分析能力。
- `PROJECT_DOMAIN.md`
  - 同步 `city_compare` 新版参考字段与分析边界。
- `test/toolbox_city_compare_service_test.dart`
  - 新增参考条目与分析结论断言。
- `test/ui_smoke_test.dart`
  - 新增对比分析区与参考细分条目区的 smoke 可见性覆盖。

### 风险变更
- 新增细分条目会提高页面信息密度，但这些字段仍然来自静态参考样本，不代表实时价格或官方收费标准。
- 自动分析属于基于当前样本和简化模型的解释层，不替代真实城市调研、学区核验或税务测算。

### 验证
- `dart analyze lib/src/services/toolbox_city_compare_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_city_compare.dart test/toolbox_city_compare_service_test.dart`
- `flutter test test/toolbox_city_compare_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens city salary compare and updates target salary"`

## [Unreleased-PLAN_255-LIFE-DEVICE-FRAME-MOCKUP] - 2026-05-27

### 原因
- 用户反馈工具箱「生活实用」中的 `带壳截图` 与真实手机展示稿差距较大，并提供参考 APK 与商店应用方向，希望把当前通用壳体升级为更接近真实设备展示的出图体验；同时本轮回归也需要确认 `全能单位换算` 与 `BMI 计算器` 继续稳定。

### 新增
- `plans/PLAN_255_生活实用带壳截图真实机模重构.md`
  - 记录本轮原创机模重构、风险边界与回归范围。
- `assets/toolbox/device_frames/`
  - 新增两套原创前视机模资源及对应阴影/炫光图层：`iphone_titanium_*` 与 `android_graphite_*`。
- `scripts/generate_device_frame_assets.ps1`
  - 新增可复跑的资源生成脚本，便于后续继续补机模或微调质感。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame.dart`
  - 将 `device_frame` 从通用 Flutter 绘制壳体重构为资产化机模合成，支持 `海报卡片 / 钛金灵动岛 / 石墨挖孔屏` 三种风格，并保留本地导入、状态栏补齐、背景切换和 PNG 导出链路。
  - 新增炫光开关、优化预览舞台文案与导出命名，让带壳截图更接近真实棚拍展示稿。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_unit_converter.dart`
  - 为单位下拉框补上 `isExpanded + ellipsis` 收口，修复窄宽度测试视口下的横向溢出。
- `pubspec.yaml`
  - 注册 `assets/toolbox/device_frames/` 资源目录，供生活实用带壳截图页面加载。
- `PROJECT_DOMAIN.md`
  - 同步 `device_frame` 从通用绘制壳体升级为原创机模展示方案，并记录单位换算的窄宽度收口。
- `modules/toolbox/README.md`
  - 同步带壳截图的资源化机模能力、导出边界与单位换算的窄屏适配说明。

### 风险变更
- `带壳截图` 当前虽然已明显提升真实展示感，但仍属于仓库内原创展示机模，不对应任何厂商官方营销图、真实营销渲染管线或精确 OEM 尺寸。
- `全能单位换算` 与 `BMI 计算器` 的计算口径未改变：前者继续依赖本地静态单位表，后者继续仅用于成年人日常自查辅助。

### 验证
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens device frame controls"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools converts default unit inputs"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools recalculates bmi classification"`

## [Unreleased-PLAN_252-LIFE-NOTIFY-FAKE-CALL-MEME-LAYERS] - 2026-05-27

### 原因
- 用户要求继续深挖工具箱「生活实用」中的 `通知自己` 与 `表情包制作`：`通知自己` 需要补到状态栏锁定、勾选完成、进入应用取消、模拟来电和锁屏全屏展示；`表情包制作` 需要补到可拖动、可缩放、可调字体样式与层级，且当前字号/边距等控件必须真实生效。

### 新增
- `plans/PLAN_252_生活实用通知自己模拟来电与表情包图层交互增强.md`
  - 记录本轮原生提醒扩展、模拟来电、图层交互与导出一致性的目标、风险与验证口径。
- `lib/src/services/toolbox_life_notify_service.dart`
  - 新增「通知自己」元数据编解码能力，统一承载提醒说明、提醒展示类型、倒计时、状态栏锁定和模拟来电字段。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/FakeIncomingCallActivity.kt`
  - 新增 Android 全屏模拟来电界面，支持锁屏唤起、来电铃声与振动、姓名/号码/归属地/标签展示，以及接听/挂断交互。

### 修改
- `android/app/src/main/kotlin/group/zn/xianyushengxi/TodoReminderScheduler.kt`
  - 扩展原生提醒规格，支持 `presentationType`、`stickyNotification`、`cancelOnOpen` 和模拟来电字段透传与持久化。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/TodoReminderReceiver.kt`
  - 普通提醒支持状态栏常驻与“进入应用取消”语义；模拟来电在触发时改为直接拉起全屏来电 Activity。
- `android/app/src/main/kotlin/group/zn/xianyushengxi/MainActivity.kt`
  - 原生提醒 MethodChannel 接口扩展为接收状态栏锁定、进入取消与模拟来电字段。
- `android/app/src/main/AndroidManifest.xml`
  - 注册全屏模拟来电 Activity，并声明锁屏展示/点亮屏幕能力。
- `lib/src/services/todo_reminder_service.dart`
  - 在同步本地提醒到 Android 原生调度时解析 `通知自己` 元数据，并下发状态栏锁定、模拟来电与来电信息字段。
- `lib/src/services/system_calendar_service.dart`
  - 系统日历镜像改为写入解析后的提醒说明，模拟来电会补充姓名/号码/归属地/标签摘要。
- `lib/src/services/toolbox_meme_service.dart`
  - 表情包服务重构为统一图层模型，支持字体家族、粗体/斜体、描边/卡片/贴纸气泡、缩放、边距、对齐和层级顺序，并让预览/导出共用同一套布局参数。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_notify_me.dart`
  - 页面重做为真实提醒工作台：支持普通通知/锁屏提醒/模拟来电、指定时间/倒计时、状态栏锁定、进入应用取消、来电字段输入与更完整的列表展示。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_meme_maker.dart`
  - 页面重做为图层编辑器：支持选中图层、预览区拖动与双指缩放、字体/对齐/层级设置，以及与导出一致的 PNG 生成。
- `test/toolbox_meme_service_test.dart`
  - 更新为新的图层渲染请求模型，覆盖多图层 PNG 导出的基本正确性。

### 风险变更
- `通知自己` 的状态栏常驻、锁屏提醒和模拟来电当前完整能力仍主要落在 Android；其他平台继续以页面管理和系统日历镜像为主。
- `通知自己` 当前仍复用 todo 提醒基础设施，因此原生“完成”动作会通过应用回写待办完成状态，而不是纯原生静默完成。
- `表情包制作` 当前已实现静态图文图层编辑与 PNG 导出一致性，但仍不包含 GIF/APNG 动图时间轴与多帧编辑链路。

### 验证
- `dart analyze lib/src/services/toolbox_life_notify_service.dart lib/src/services/todo_reminder_service.dart lib/src/services/system_calendar_service.dart lib/src/services/toolbox_meme_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_notify_me.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_meme_maker.dart test/toolbox_meme_service_test.dart`
- `flutter test test/toolbox_meme_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens notify me and creates a reminder"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens meme maker controls"`
- `android/gradlew.bat :app:compileDebugKotlin`

## [Unreleased-PLAN_254-LIFE-CITY-COMPARE] - 2026-05-27

### 原因
- 用户要求专注于工具箱-生活实用中的“城市薪资对比工具”模块，基于模块内占位参考页完成真实实现，而不是继续停留在资料入口。

### 新增
- `plans/PLAN_254_生活实用城市薪资对比工具实现.md`
  - 记录本轮目标、参考来源、生活方式配置口径与验证方式。
- `lib/src/services/toolbox_city_compare_service.dart`
  - 新增纯计算服务，内置静态城市成本样本，支持双城市成本拆解、简化税费/五险一金估算、同薪资迁移结余和目标月薪求解。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_city_compare.dart`
  - 新增独立“城市薪资对比工具”页面，按首屏结论、城市与薪资输入、生活方式配置、双城拆解和口径说明组织移动端 UI。
- `test/toolbox_city_compare_service_test.dart`
  - 覆盖高成本城市迁移需要更高目标月薪、低成本城市迁移可降低目标月薪等核心计算行为。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 接入城市薪资对比服务与独立页面 part。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 将 `city_compare` 从占位信息页路由切换为真实可用页面。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 把 `city_compare` 纳入 life tools utility 路由分发。
- `modules/toolbox/README.md`
  - 同步城市薪资对比工具的能力范围、输入口径与风险边界。
- `PROJECT_DOMAIN.md`
  - 同步生活实用 `city_compare` 模块的产品边界与版本记录。
- `test/ui_smoke_test.dart`
  - 新增城市薪资对比页面入口与主舞台 smoke 覆盖。

### 风险变更
- 城市样本为静态参考数据，不代表实时租金、学费、交通或消费价格；页面结果适合横向估算，不适合替代真实报价或合同条款。
- 税费与五险一金按统一简化模型估算，不会覆盖个税专项附加扣除、公司补贴、个体社保口径等个体差异。

### 验证
- `dart analyze lib/src/services/toolbox_city_compare_service.dart test/toolbox_city_compare_service_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_city_compare.dart`
- `flutter test test/toolbox_city_compare_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens city salary compare and updates target salary"`

## [Unreleased-PLAN_253-LIFE-WORK-WORTH] - 2026-05-27

### 原因
- 用户要求专注实现工具箱-生活实用中的“工作性价比计算器”，参考 `zippland/worth-calculator` / `worthjob.zippland.com`，并增加生活开销、保险公积金、工作环境健康层级等参数。

### 新增
- `plans/PLAN_253_生活实用工作性价比计算器增强.md`
  - 记录本轮目标、计算口径、风险边界与验证方式。
- `lib/src/services/toolbox_work_worth_service.dart`
  - 新增纯计算服务，覆盖年收入、工作日、PPP 标准化日薪、月可支配、健康损耗预算、环境/生活现金系数、综合价值分与评级。
  - 扩展关键计算项：奖金确定性、现金化福利、加班补偿、无偿加班、成长性、下班边界、心理安全感与自主权，并新增参考标准值模型。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_work_worth.dart`
  - 新增独立工作性价比页面，按主舞台结果、收入与开销、时间成本、环境稳定性和口径说明组织移动端 UI。
  - 新增参考标准值面板，展示标准工时、通勤、年假、公共假期、现金安全垫和健康损耗预留等校准口径。
- `test/toolbox_work_worth_service_test.dart`
  - 覆盖基础计算、生活成本、不健康环境惩罚，以及奖金/福利/加班/上下文因子对结果的影响。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 接入工作性价比计算服务与独立页面 part。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 保持 `work_worth` 路由不变，并将旧简版实现改名为 legacy，避免与新独立页面冲突。
- `test/ui_smoke_test.dart`
  - 增加工作性价比页面入口、主舞台和参考标准值面板 smoke 覆盖。

### 风险变更
- 该模块输出用于 offer/岗位横向比较，不构成财务、医疗或职业建议；PPP、城市、学历经验和健康损耗参数均为估算口径。
- 工作环境、生活开销、税费与职业背景均采用估算系数；页面已展示口径说明，避免把分数当作绝对结论。

### 验证
- `dart analyze lib/src/services/toolbox_work_worth_service.dart test/toolbox_work_worth_service_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_work_worth.dart`
- `flutter test test/toolbox_work_worth_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens work worth calculator and updates score"`

## [Unreleased-PLAN_249-LIFE-NOTIFY-NUMBER-MARK-MEME] - 2026-05-27

### 原因
- 用户要求把工具箱「生活实用」中的 `通知自己`、`数字转标`、`表情包制作` 三个简单占位入口升级为真实可用模块，而不是继续停留在说明页或最小替换演示。

### 新增
- `plans/PLAN_249_生活实用通知自己数字转标表情包制作实现.md`
  - 记录三模块实现目标、平台边界、图片导出风险和验证口径。
- `lib/src/services/toolbox_number_mark_service.dart`
  - 新增纯转换服务，支持上标、下标、带圈、括号编号、全角以及反向还原，并处理多字符最长匹配。
- `lib/src/services/toolbox_meme_service.dart`
  - 新增表情包位图渲染服务，支持顶部/底部标题、贴纸短句、经典描边字和 PNG 导出。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_notify_me.dart`
  - 新增「通知自己」独立页面：提醒创建、状态栏/锁屏文案预览、应用提醒能力状态、系统日历镜像和提醒列表管理。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_number_marks.dart`
  - 新增「数字转标」独立页面：多模式转换、反向还原、示例填充、复制结果和未覆盖字符统计。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_meme_maker.dart`
  - 新增「表情包制作」独立页面：本地图片导入、实时预览、样式控制和 PNG 导出。
- `test/toolbox_number_mark_service_test.dart`
  - 覆盖上标转换、带圈多字符最长匹配和括号编号反向还原。
- `test/toolbox_meme_service_test.dart`
  - 覆盖表情包 PNG 渲染结果的基本正确性。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 为三个模块接入新的服务依赖和 part 文件，并更新 life tools 卡片摘要文案。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 将 `notify_me`、`sup_sub`、`meme_maker` 从占位/工具合集路由切换为真实独立页面。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 将 `sup_sub` 入口切换到新的数字转标页面。
- `test/ui_smoke_test.dart`
  - 新增 life tools smoke：通知自己创建提醒、数字转标转换、表情包制作页面打开。

### 风险变更
- `通知自己` 当前对状态栏/锁屏原生提醒的完整能力主要落在 Android；其他平台仍以系统日历镜像和应用内列表管理为主，页面已显式展示能力边界。
- `数字转标` 依赖 Unicode 现成字符集，上下标天然覆盖不完整；未覆盖字符会保留原文并计入统计，避免静默误改。
- `表情包制作` 当前使用 Flutter Canvas 重新渲染 PNG，适合本地静态图文叠加，不包含 GIF/APNG 动图导出链路。

### 验证
- `dart analyze lib/src/services/toolbox_number_mark_service.dart lib/src/services/toolbox_meme_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_notify_me.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_number_marks.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_meme_maker.dart`
- `dart analyze test/toolbox_number_mark_service_test.dart test/toolbox_meme_service_test.dart test/ui_smoke_test.dart`
- `flutter test test/toolbox_number_mark_service_test.dart test/toolbox_meme_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens notify me and creates a reminder"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens number marks and converts text"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens meme maker controls"`

## [Unreleased-PLAN_248-LIFE-COMPASS-LEVEL-VIBRATION-REDESIGN] - 2026-05-27

### 原因
- 用户要求专注处理工具箱-生活实用中的“指南针 / 水平仪 / 震动仪”三个模块，当前它们存在大量可用性和实现层问题，需要重新实现。

### 新增
- `plans/PLAN_248_生活实用指南针水平仪震动仪重做.md`
  - 记录三模块重做目标、平台边界、风险与验证项。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_compass.dart`
  - 重做指南针页面，新增首屏方向舞台、方向/倾斜/磁场状态 pill、平滑指针、磁场稳定度提示和使用说明。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_level.dart`
  - 重做水平仪页面，新增 `Level / Plumb` 双模式、大舞台气泡反馈、俯仰/横滚读数、找平状态与读数说明。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_vibration.dart`
  - 重做震动仪页面，新增节奏预设、强度/脉冲/间隔/循环参数、图形化波形预览、平台能力提示和测试按钮。
- `test/ui_smoke_test.dart`
  - 新增 `life tools opens compass stage with heading status`
  - 新增 `life tools opens level stage with mode controls`
  - 新增 `life tools opens vibration stage with pattern controls`
- `android/app/src/main/kotlin/group/zn/xianyushengxi/MainActivity.kt`
  - 新增 `vocabulary_sleep/life_device` 原生通道，提供震动能力查询、波形震动播放和停止能力。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 新增 life-device 通道与震动能力封装，供生活实用设备工具复用。
- `PROJECT_DOMAIN.md`
  - 同步生活实用三设备工具的新版能力边界与 Android 原生震动通道说明。
- `modules/toolbox/README.md`
  - 补充指南针、水平仪、震动仪的当前实现、能力边界和移动端使用风险。

### 风险变更
- 指南针与水平仪都依赖真机传感器，结果易受机身姿态、手机壳、桌面材质和周边电器影响，只适合做移动端快速判断，不是工程级测量工具。
- 震动波形优先在 Android 通过原生 `Vibrator/VibrationEffect` 执行；其他平台会降级为轻量触感或仅保留节奏预览，幅度控制并不保证跨平台一致。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_compass.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_level.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_vibration.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_compass.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_level.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_vibration.dart test/ui_smoke_test.dart`
  - 结果仅剩 `test/ui_smoke_test.dart` 既有 info 级提示，无新增 error。

## [Unreleased-PLAN_247-LIFE-TEXT-TRANSFORM-EXPANSION] - 2026-05-27

### 原因
- 用户要求将工具箱-生活实用中的“中文转拼音”并入“文本转换”，并扩充为更完整的文本与历法转换入口，补齐拼音/注音、简繁转换、数字书写、农历公历、干支八字、六十甲子、语言代码，以及既有编码/隐藏/排版/乱码/码表能力。

### 新增
- `plans/PLAN_247_生活实用文本转换模块增强.md`
  - 记录文本转换模块增强目标、风险边界与验证方式。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_text_transform.dart`
  - 新增独立文本转换页面，按“拼音 / 数字 / 历法 / 干支 / 语言 / 编码 / 风格 / 隐藏 / 乱码 / 码表”分组承载多种文本处理模式。
- `test/ui_smoke_test.dart`
  - 更新 `life tools opens text transform modes and conditional fields`，覆盖拼音入口迁移、数字书写、历法分组可达，以及隐藏文本、RC4 密钥框与竖排参数按需显示。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 保持 `text_encoding` 工具 ID 不变，将入口标题改为“文本转换 / Text transform”，同步更新摘要与参考来源，并移除独立拼音入口。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 将 `text_encoding` 从旧的简版 `_TextEncodingPage` 路由切换到新的 `_TextTransformPage`，同时移除旧 `_PinyinPage` 路由实现。
- `PROJECT_DOMAIN.md`
  - 同步生活实用文本转换模块的扩展范围、按需字段规则与历法/干支参考边界。
- `modules/toolbox/README.md`
  - 补充文本转换模块的拼音并入、分组结构、条件字段策略与风险说明。

### 风险变更
- 火星文当前采用本地轻量字形映射和简繁兜底策略，覆盖常见字符但并非完整互联网火星文词库。
- 农历、公历、干支、八字与六十甲子能力定位为本地参考工具：默认使用北京时间与北京真太阳时辅助计算，八字反查仅提供受限年份范围内的候选枚举，不替代权威历法或命理数据库。
- 乱码修复只输出常见编码重解释候选，不承诺唯一正确结果；实际判断仍依赖原始来源编码上下文。
- 竖排排版当前输出为文本版仿古排版结果，优先保证本地可复制、可预览，而非像素级书页排版还原。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_text_transform.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_text_transform.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens text transform modes and conditional fields"`
  - 当前被工作树内既有 `toolbox_life_tools.dart` 编译断链阻塞：`toolbox_life_tools_vibration.dart` 缺失，且 `timeline_periodic` 相关 `part` 依赖未闭合；这些错误在本轮文本转换改动之外。

## [Unreleased-PLAN_246-LIFE-STEGANOGRAPHY-INTERACTION-MEMORY] - 2026-05-27

### 原因
- 用户反馈隐写内容/隐写文件切换时媒体类型被错误隐藏，自由级联组合项远离加密算法，解密导出或触发清理后载体仍可能留在内存，并希望写入前提前提示载荷容量不足。

### 新增
- `plans/PLAN_246_隐写交互状态与载体内存卸载修复.md`
  - 记录本轮交互状态、容量预检、内存卸载和多重加密安全边界。
- `lib/src/services/toolbox_crypto_service.dart`
  - 新增加密 envelope 尺寸估算接口，按当前算法、级联层数、MAC、签名模式和最大随机 padding 估算写入前所需容量，不派生口令也不执行实际加密。
- `lib/src/services/toolbox_steganography_service.dart`
  - 新增文本/文件写入前容量检查：先验证媒体大小、图片像素上限、重复隐写占用和预计载荷尺寸，再返回当前容量、预计需要和最低建议像素数。
- `test/toolbox_steganography_service_test.dart`
  - 覆盖图片容量预检在小载体上提前报告容量不足。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 媒体类型选择从“隐写文本”工作区中解耦，隐写内容与隐写文件模式都能正常选择图片/音频/视频类型。
  - 自由级联组合项移动到加密算法下方，选择“自由级联”后立即展示组合芯片和独立密钥材料说明。
  - 写入文本/文件前先运行容量预检，不足时提示当前图片容量、预计需要、媒体大小上限和最低建议像素尺寸。
  - 写入或还原完成后增加导出/复制提醒；解密文件导出后卸载当前载体，成功/错误次数触发清理后也同步卸载载体内存和预览。
  - 保存路径提示与普通状态提示拆分，避免“已保存”前缀错误包裹清理/浏览器下载类消息。

### 风险变更
- 容量预检采用最大随机 padding 的保守估算，可能比实际某次封装略大；这是为了避免真实写入阶段因随机尺寸波动失败。
- 多重/组合加密的每一层使用同一根密钥派生出的独立 key slice 与独立 nonce，可抵抗单层参数复用问题；但它不是多个互不相关口令域，根密钥或口令被攻破时所有层都会失效。

### 验证
- `dart format lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/toolbox_crypto_service_test.dart`
- `flutter test test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_251-LIFE-TIMELINE-HUMAN-HISTORY-EXPANSION] - 2026-05-27

### 原因
- 用户指出当前人类全历史时间轴仍过于简洁，希望在参考 history-map、ChronoZoom、Big History Online、Chronas、Histography 等项目/网站后，扩展成更完整的人类历史体系；同时测试时发现 Wikimedia Commons 远程背景图超时会触发 Flutter image service 异常。

### 新增
- `plans/PLAN_251_生活实用历史年表人类史扩容与背景兜底.md`
  - 记录本轮人类史扩容、参考来源、远程背景图兜底和验证方式。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_data.dart`
  - 新增独立历史扩展数据 part，在保留原核心年表的基础上追加 68 个基础人类史节点。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_premodern_data.dart`
  - 新增 57 个前现代密集节点，补齐旧石器、农业起源、青铜时代、古典帝国、宗教思想、中世纪欧亚非美洲和早期全球化前夜的宏观进程。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_modern_data.dart`
  - 新增 46 个近现代密集节点，补齐早期现代帝国、革命、工业化、世界大战、冷战、去殖民化、全球治理、数字社会和当代科学节点。
  - 全部历史节点合计为 202 个宏观事件，覆盖人类演化、史前定居、农业与城市文明、古典世界、宗教/思想、跨大陆交流、中世纪、早期现代、殖民与革命、工业化、世界大战、冷战、去殖民化、全球治理、数字时代与当代科技。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 注册新的历史扩展数据 part 与前现代/近现代密集数据 part。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_data.dart`
  - 将原 31 个节点改为 `_coreTimelineFacts`，由扩展数据 part 统一合并排序为 `_timelineFacts`。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic.dart`
  - 将远程背景图从 `Image.network` 改为受控 `http.get` + 4 秒超时 + 内存缓存 + `Image.memory` 渲染；请求失败只显示本地渐变，避免 SocketException 进入 Flutter image resource service。

### 风险变更
- 当前“完整”是面向移动端可读性的精选宏观体系，不等同于专业历史数据库；后续若继续扩展到数千节点，应增加地区、文明、领域、搜索和数据包分层。
- 部分年代采用约值或阶段起点，页面继续按参考型可视化处理，不作为专业断代唯一依据。
- 背景图仍会按需发起远程请求，但失败不再阻断 UI 或向 image service 冒泡异常。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_data.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_data.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_premodern_data.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_modern_data.dart test/ui_smoke_test.dart`
- 节点脚本核对：31 + 68 + 57 + 46 = 202 个 `_TimelineFact`，无重复 timeline id。
- `flutter pub get`
  - 补齐当前 `pubspec.yaml` 已声明但 lock 中缺失的 `locale_names`、`pinyin`、`sxwnl_spa_dart` 依赖。
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_data.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_data.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_premodern_data.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_modern_data.dart`
  - 当前被工作树内既有缺失 part 阻塞：`toolbox_life_tools_device_frame.dart`、`toolbox_life_tools_unit_converter.dart`、`toolbox_life_tools_bmi.dart` 不存在；这些错误在本轮历史年表数据与背景兜底改动之外。
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens timeline and periodic visualizations"`
  - 同样被上述三个缺失 part 阻塞，测试未进入历史年表用例执行阶段。

## [Unreleased-PLAN_250-LIFE-TIMELINE-IMMERSIVE-READABILITY] - 2026-05-27

### 原因
- 当前历史年表横向轴在“全部”范围下节点拥挤、标签遮挡，移动端阅读不清晰；用户希望优化展示，并考虑全屏沉浸或垂直下拉轴，同时引入宇宙、岩石、历史文物等公开资源背景。

### 新增
- `plans/PLAN_250_生活实用历史年表沉浸式清晰化.md`
  - 记录本轮时间轴清晰化、全屏沉浸、公开媒体资源和移动端风险边界。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_data.dart`
  - 新增时间轴背景资源常量，包含 NASA Image Library、USGS/Wikimedia Commons 来源的宇宙、岩石、历史文物和地球图像入口。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic.dart`
  - 新增默认“Story”纵向故事轴，节点以单列卡片、清晰时间线、主题标签、摘要和来源按钮展示。
  - 新增“Immersive”沉浸全屏时间轴路由，使用独立全屏视图、主题背景、退出按钮和纵向滚动体验。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic.dart`
  - 原横向缩放轴改为可选“Map”全景地图轴，增加公开图片背景、加宽舞台、提高时间线高度，并避免首尾标签被裁切。
  - 时间轴筛选区新增浏览方式切换和沉浸全屏入口。
- `test/ui_smoke_test.dart`
  - 扩展历史年表 smoke 测试，覆盖默认 Story 轴、沉浸全屏打开/退出，以及返回后切换元素周期表。

### 风险变更
- 远程背景图仅作视觉氛围增强，加载失败时回退为本地渐变，不影响历史节点和来源文本阅读。
- 背景资源来自 NASA Image Library、USGS 公开媒体说明和 Wikimedia Commons 文件页；运行时会按需请求远程图片，来源按钮保留核验入口。
- 全屏沉浸视图会临时进入 immersive system UI，退出页面时恢复默认方向和系统 UI。

### 验证
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_data.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens timeline and periodic visualizations"`

## [Unreleased-PLAN_244-LIFE-TIMELINE-PERIODIC-VISUALIZATION] - 2026-05-27

### 原因
- 用户希望工具箱-生活实用中的“历史年表/元素周期表”不再停留在资料入口，而是基于真实可靠、低争议或共识性资料做成本地动态可视化展示。

### 新增
- `plans/PLAN_244_生活实用历史年表与元素周期表动态可视化.md`
  - 记录本轮数据来源、交互范围、移动端手势风险和验证方式。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_data.dart`
  - 新增历史年表共识节点数据、118 个元素事实数据和统一资料来源列表；元素数据整理自 PubChem PUG REST，并在页面中保留 IUPAC/CIAAW 等参考入口。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic.dart`
  - 新增历史年表/元素周期表动态页面：历史轴支持范围与主题筛选、对数时间轴、缩放拖动、节点详情和来源跳转；元素周期表支持族块与状态筛选、缩放拖动、元素详情和图例。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 将 `timeline_periodic` 从占位入口升级为“历史年表/元素周期表”，并挂载资料来源说明。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 将 `timeline_periodic` 路由接入新的本地可视化页面。
- `test/ui_smoke_test.dart`
  - 新增生活实用 smoke 测试，覆盖从 hub 搜索进入年表页面、切换元素周期表和关键舞台渲染。

### 风险变更
- 历史节点仅采用宏观、低争议的共识性锚点；年代以“约/范围”表达，不作为精细史学断代或考试唯一标准。
- 元素原子量、发现年份和标准状态会随权威表修订或定义差异变化；页面展示为可核验参考值，并保留 PubChem/IUPAC/CIAAW 来源入口。
- 横向缩放/拖动限定在可视化舞台内，仍需后续真机窄屏回归确认手势是否与页面纵向滚动冲突。

### 验证
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_data.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens timeline and periodic visualizations"`

## [Unreleased-PLAN_242-LIFE-TEXT-COUNTER-SPLIT-COPY] - 2026-05-27

### 原因
- 用户希望在工具箱-生活实用-字数计算模块中，不只统计字数，还能按不同计数标准自动拆分长文本，并支持逐块一键复制。

### 新增
- `plans/PLAN_242_生活实用字数计算自动拆分复制.md`
  - 记录本轮字数计算模块增强的目标、拆分边界、移动端风险与验证方式。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_text_counter.dart`
  - 抽离字数计算子模块，新增按总字符、去符号、去空白、仅正文四种标准统计。
  - 新增固定字数拆分与句末优先拆分，两种模式都会自动生成可单独复制的分块卡片。
  - 新增原文复制、全部分块复制、单块复制与 Snackbar 反馈。
- `test/toolbox_life_text_counter_test.dart`
  - 覆盖去符号拆分保留原文标点、句末优先拆分、无句末符号时硬切分回退三类边界。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 将工具名称从“字数计算”升级为“字数拆分与统计”，并注册新的独立 part 文件。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 原有简版字数计算实现退役为 legacy 占位，避免与新模块重名冲突。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_text_counter.dart`
  - 拆分能力改为独立开关，关闭时只做统计，打开后再展开拆分设置与结果。
  - 每个分块卡片默认折叠，头部保留直接复制，展开后才显示全文，降低长文本时的滚动负担。
  - 新增每块完成勾选，勾选后保留删除线和弱化样式，便于逐块处理与清理进度。

### 风险变更
- “句末优先拆分”属于尽量贴近句意的展示策略；若文本缺少结束符，仍会按字数上限强制切分。
- “去符号 / 去空白 / 仅正文”只影响计数字段与拆分边界，不会改写输出内容本身，复制时仍保留原始文本格式。

## [Unreleased-PLAN_241-LIFE-STEGANOGRAPHY-FILE-PICKER-MEMORY] - 2026-05-27

### 原因
- 用户指出隐写 UI 仍用 `withData: true` 选择媒体、keyfile 和普通文件，大文件会在进入服务层大小检查前先被 file_picker 读入内存；同时模块尚未发布，crypto envelope v2/v3 兼容读取不应继续保留。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 媒体、keyfile、普通文件选择均改为 `withData: false` + `withReadStream: true`。
  - 读取前先检查 `PlatformFile.size`：图片载体、音视频尾部载体、普通文件和 keyfile 分别按服务层上限拒绝超限文件。
  - 读取时优先使用 `PlatformFile.readStream`，其次使用本地路径 `File.openRead()` 分段读取，最后才在 Web/特殊平台回退到 bytes，避免移动端选择阶段额外复制整文件。
  - keyfile 单文件上限复用 `ToolboxCryptoService.maxKeyFileBytes`，多 keyfile 总量增加 8MB 上限。
- `lib/src/services/toolbox_crypto_service.dart`
  - 普通加密输入上限提升到 256MB，cipher/envelope 上限同步扩大。
  - 移除 crypto envelope v2/v3 读取分支和公开 `plainSha256` / `keyFileSha256` 兼容逻辑，v4 成为唯一支持的新 crypto envelope 格式。
- `lib/src/services/toolbox_steganography_service.dart`
  - 图片载体文件上限提升到 128MB，音视频尾部载体上限提升到 512MB；图片像素数上限仍保持 24MP。
- `test/toolbox_crypto_service_test.dart`
  - 覆盖 v2/v3 crypto envelope 被拒绝读取。

### 风险变更
- 原生平台若 file_picker 既不提供 read stream 也不提供路径，会显示“无法流式读取所选文件”；这是为了避免隐式整文件预读。
- 服务层仍以字节形式执行当前加密/隐写格式；本轮降低的是选择阶段的额外内存副本，真正的超大文件流式加密/分块隐写需要后续格式级改造。
- 旧 v2/v3 crypto envelope 试验文件不再可读；模块未正式发布，以 v4 为唯一格式。

### 验证
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_crypto_service_test.dart`
- `flutter test test/toolbox_crypto_service_test.dart`
- `flutter test test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_240-LIFE-STEGANOGRAPHY-PRE-RELEASE-SECURITY-AUDIT] - 2026-05-27

### 原因
- 用户提供发布前安全审计反馈，指出 release 复用 debug 签名、敏感文件可能进入 Android 系统备份、恶意 envelope/图片可触发资源耗尽、签名层语义被误读、公开策略/次数限制不应作为安全边界、envelope 泄漏公开指纹，以及重置未清空主口令。

### 新增
- `android/app/src/main/res/xml/backup_rules.xml`
- `android/app/src/main/res/xml/data_extraction_rules.xml`
  - 明确排除 `life_tools/keys/` 与 `life_tools/steganography/`，并配合 Manifest 禁用系统备份。
- `test/toolbox_crypto_service_test.dart`
  - 覆盖新 envelope 不再写入 `plainSha256` / `keyFileSha256`，并验证超限 KDF 与 stage 数在进入重成本 KDF 前被拒绝。

### 修改
- `android/app/build.gradle.kts`
  - release 不再使用 debug signingConfig，改为读取 `RELEASE_STORE_FILE`、`RELEASE_STORE_PASSWORD`、`RELEASE_KEY_ALIAS`、`RELEASE_KEY_PASSWORD` 或 `android/key.properties`；缺少配置时 release 构建直接失败。
- `android/app/src/main/AndroidManifest.xml`
  - `<application>` 增加 `android:allowBackup="false"`，并挂载备份/迁移排除规则。
- `lib/src/services/toolbox_crypto_service.dart`
  - crypto envelope 升级到 v4，新写入移除公开 `plainSha256` 与 `keyFileSha256`，keyfile 匹配交由 MAC/AEAD 失败处理。
  - 增加 envelope、plaintext、ciphertext、KDF 参数、stage 数、nonce、签名和公钥字段的硬上限，拒绝异常参数后再进入 scrypt 或签名验证。
  - 保留 v2/v3 旧 envelope 的必要读取兼容；旧公开哈希仅用于旧版本校验。
- `lib/src/services/toolbox_steganography_service.dart`
  - 图片隐写解码前增加文件大小上限，解码后增加像素数上限；音视频尾部载体与内嵌 crypto envelope 也增加大小上限。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 重置、切换工作区/模式和页面销毁前清空主口令、表层口令、隐藏文本、keyfile 等 secret 输入。
  - RSA/ECDSA 文案改为“高成本完整性附加校验，不提供独立来源证明”；错误/成功次数限制和公开策略头文案降级为本机当前文件最佳努力清理。

### 风险变更
- 没有 release keystore 配置时 release 构建会失败，这是发布链路安全要求；debug dry-run 不受影响。
- 新 envelope v4 改变未发布格式，新写入不再暴露公开明文哈希与 keyfile 哈希；旧 v2/v3 仍尽量保留读取兼容。
- 图片、媒体和 envelope 上限会拒绝超大载体或异常参数，减少移动端资源耗尽风险。
- 次数限制、公开策略头和轻量尾部校验不承诺抗恶意篡改、抗复制或阅后即焚，仅作为当前客户端/当前文件的最佳努力清理提示。

### 验证
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_crypto_service_test.dart`
- `flutter test test/toolbox_crypto_service_test.dart`
- `flutter test test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`
- `android/gradlew.bat :app:assembleDebug --dry-run`
- `android/gradlew.bat :app:processDebugMainManifest`
- `android/gradlew.bat :app:assembleRelease --dry-run`（缺少 release keystore 配置时按预期失败并提示所需变量）

## [Unreleased-PLAN_239-LIFE-STEGANOGRAPHY-DUAL-LAYER-REWRITE-GUARD] - 2026-05-27

### 原因
- 用户指出已隐写文件被再次写入会产生不可预测结果，并要求推进显式双层模式，同时新增成功还原指定次数后清理载荷的极端保护选项。

### 新增
- `lib/src/services/toolbox_steganography_service.dart`
  - 新增显式图片双层文本隐写：表层和深层分别写入独立 LSB 槽位，使用不同口令；表层口令只还原表层内容，深层口令只还原深层内容。
  - 新增受管理保护块 `VSSG3`，记录最大错误尝试次数与剩余成功还原次数。
  - 新增成功还原保护消费逻辑：剩余次数大于 1 时更新当前载体内计数，等于 1 时清理对应隐藏载荷。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 高级加密参数新增“双层可否认模式”开关，文本写入时显示表层文本与表层口令输入。
  - 高级设置新增“成功还原次数上限”，首次设置为非 0 时弹窗提醒其只影响当前可写文件副本，无法约束已复制文件或外部备份。
- `test/toolbox_steganography_service_test.dart`
  - 覆盖重复写入拒绝、双层表层/深层分别还原，以及成功还原次数消费后清理载荷。

### 修改
- `lib/src/services/toolbox_steganography_service.dart`
  - 写入前对当前格式可确认已占用的载体默认拒绝再次写入，提示使用原始载体、先清理隐藏内容，或将加密文件作为新的隐写 payload。

### 风险变更
- 重复写入拒绝依赖当前格式可确认的占用标记，属于防误操作闸门，不是不可检测性保证。
- 双层模式当前仅支持图片文本载荷；表层不使用选中的 keyfile，keyfile 仍用于深层。
- 成功还原次数限制只能改写当前可写文件副本或当前内存载体，不防止已复制文件继续被还原。

### 验证
- `dart analyze lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_237-LIFE-STEGANOGRAPHY-EXTENSION-CLEANUP] - 2026-05-26

### 原因
- 用户指出隐写服务层 `_cleanExtension` 最大长度为 8，而生活实用隐写 UI 层为 12，可能导致导出扩展名在不同层处理不一致。

### 修改
- `lib/src/services/toolbox_steganography_service.dart`
  - 提取 `ToolboxSteganographyService.cleanExtension` 与 `maxExtensionLength = 12`，统一扩展名清洗入口。
  - 服务层扩展名清洗同步处理清洗后为空字符串的输入，避免返回空扩展名。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 保存文件结果时改用服务层公共扩展名清洗方法，移除 UI 私有重复实现。
- `test/toolbox_steganography_service_test.dart`
  - 补充 12 位扩展名、超长扩展名、非法字符清空和 null 输入的边界测试。

### 风险变更
- 服务层允许的扩展名上限从 8 位统一放宽到 12 位，与既有 UI 行为一致；仍仅保留小写字母数字。

### 验证
- `dart analyze lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_238-ANDROID-AAB-ABI-SPLIT-FIX] - 2026-05-26

### 原因
- Android App Bundle release 打包在 `:app:buildReleasePreBundle` 阶段失败，AGP `PerModuleBundleTask` 读取资源包时遇到多份 ABI split resources，抛出 `Sequence contains more than one matching element`。

### 修改
- `android/app/build.gradle.kts`
  - 根据 Gradle 请求任务名识别 bundle 构建。
  - `splits.abi` 在 bundle 构建时关闭，在 APK 构建时继续启用，避免 AAB 预打包阶段匹配到多份 processed resources。
- `plans/PLAN_238_AppBundle构建ABI拆分冲突修复.md`
  - 记录本轮 AAB 构建修复边界、风险和验证结果。

### 风险变更
- App Bundle 构建不再使用 APK ABI splits；AAB 本身仍由 Android App Bundle 机制处理 ABI 分发。
- APK 构建保留原有 ABI splits 和 universal APK 输出路径。

### 验证
- `flutter build appbundle --release`
- `flutter build apk --release`

## [Unreleased-PLAN_236-ANDROID-AGP-CAMERAX-BUILD-FIX] - 2026-05-26

### 原因
- Android release 打包在 `:app:checkReleaseAarMetadata` 阶段失败，CameraX 1.6.0 要求 Android Gradle Plugin 8.9.1 或更高版本，而项目仍使用 8.7.3。

### 修改
- `android/settings.gradle.kts`
  - 将 `com.android.application` 从 8.7.3 升级到 8.9.1，满足 `camera_android_camerax` 0.7.2 间接引入的 CameraX 1.6.0 AAR metadata 要求。
- `plans/PLAN_236_Android构建AGP兼容修复.md`
  - 记录本轮构建修复目标、风险和验证结果。

### 风险变更
- 本轮只调整 Android 构建链版本，不改业务代码、不改相机逻辑。
- AGP 升级可能影响后续 Android 插件兼容性；本轮已用 release APK 构建验证当前项目可通过。

### 验证
- `flutter build apk --release`

## [Unreleased-PLAN_235-LIFE-STEGANOGRAPHY-WEAK-SIGNATURE] - 2026-05-26

### 原因
- 用户希望在 RSA/ECDSA 签名路径导致移动端性能下降明显的场景下，提供一个由内置长期域 key、随机短签名材料和 SHA-256/HMAC 组合而成的弱签名版本选项，并在选择签名时提示性能开销。

### 新增
- `lib/src/services/toolbox_crypto_service.dart`
  - 新增 `ToolboxCryptoSignatureMode.weakSha256`，使用用户派生签名种子、内置域 key、随机 nonce/padding 和 HMAC-SHA256 生成 32 字节轻量标签。
  - 弱签名路径不生成 RSA/ECDSA 密钥对，不写入可验证公钥，验证时只校验 envelope 附加标签是否匹配。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 隐写高级加密设置新增“弱签名版 快”选项。
  - 选择弱签名时提示其为快速轻量标签、不提供第三方来源证明；选择 RSA/ECDSA 时提示其为高成本完整性附加校验且不提供独立来源证明，移动设备可能需要等待。
- `test/toolbox_crypto_service_test.dart`
  - 覆盖弱签名、RSA 和 ECDSA 签名 envelope 的加解密验证，并补充弱签名标签篡改失败断言。

### 风险变更
- 弱签名不是公钥签名：内置域 key 可被逆向，安全性主要来自用户口令派生种子和现有 AEAD/MAC；它只作为低成本附加标签，不提供第三方来源证明。
- 当前 RSA/ECDSA 仍由口令域确定性派生并把公钥写入同一 envelope，不提供独立来源证明；若未来需要来源证明，应支持外部长期私钥签名和独立公钥/指纹校验。

### 验证
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_234-LIFE-STEGANOGRAPHY-SIGNATURE-REVEAL-UX] - 2026-05-26

### 原因
- 用户反馈签名层会让加解密性能下降数十倍，并要求最大错误次数风险提示前移、还原失败只显示错误次数、还原时隐藏加密算法和加密设置等不相关选项。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 最大错误次数风险弹窗改为第一次修改为非 0 时展示，文案压缩为“文件还原/解密时密码错误达到次数会销毁当前文件隐藏内容”。
  - 生成/写入时不再二次弹出最大错误次数确认。
  - 还原失败提示不再展示 `x/y` 进度，只显示当前文件错误次数。
  - 还原/解密模式隐藏写入阶段才相关的加密算法、强度、安全提示和高级加密参数；仅保留口令、keyfile 与定位算法/强度。
- `test/ui_smoke_test.dart`
  - 覆盖还原模式下加密设置隐藏、定位设置保留。
- `PROJECT_DOMAIN.md`
  - 补充签名层性能边界与还原界面收口说明。

### 风险变更
- 签名层性能分析结论：RSA 路径当前会每个 envelope 确定性生成 2048-bit RSA 密钥对并签名，ECDSA 路径会生成 P-256 密钥对并执行确定性签名；这是纯 Dart 大整数/椭圆曲线运算，成本远高于对称 AEAD 和哈希。该层只适合作为高成本完整性附加校验，不提供独立来源证明，也不宜作为默认加密路径。
- 还原模式隐藏写入设置后，用户无法在还原页修改加密算法；这是预期行为，因为算法来自 envelope，只有定位算法/强度仍需匹配。

### 验证
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_233-LIFE-STEGANOGRAPHY-PERFORMANCE] - 2026-05-26

### 原因
- 用户反馈当前图片/音频/视频隐写模块加密还原明显卡顿；模块尚未正式发布，因此无需保留上一轮试验格式兼容。

### 修改
- `lib/src/services/toolbox_steganography_service.dart`
  - 移除未发布的旧策略头、旧定位器和旧顺序 LSB 图片载荷兼容读取/清理分支，减少错误口令和还原路径的重复尝试。
  - 保留当前定位器 KDF、scrypt 与 AEAD 安全参数，不通过降低默认安全强度换取速度。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 文本隐写生成/还原与文件隐写生成/还原迁移到 Flutter `compute` isolate，避免图片解码、LSB 定位、定位器 KDF、scrypt 和 AEAD 同步阻塞 UI 主线程。
- `PROJECT_DOMAIN.md`
  - 同步性能优化边界：总耗时仍取决于安全 KDF，但主线程卡顿降低。

### 风险变更
- 上一轮本地试验生成的旧策略头/旧定位器/旧顺序 LSB 图片载荷不再保证还原；因模块未正式发布，当前以新格式性能和稳定性为准。
- `compute` isolate 主要改善 UI 响应性，不等同于完全缩短加密/还原总耗时。

### 验证
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_232-LIFE-STEGANOGRAPHY-SECURITY-REVIEW-FIXES] - 2026-05-26

### 原因
- 收到生活实用隐写模块安全反馈：公开策略头校验无密钥、定位器默认 KDF 过弱、策略头固定顺序 LSB 位置可检测、策略头校验长度偏短，以及 MAC/摘要比较先转十六进制字符串。

### 新增
- `plans/PLAN_232_隐写策略头与定位器安全修复.md`
  - 记录本轮安全反馈评估、修复边界和兼容风险。

### 修改
- `lib/src/services/toolbox_steganography_service.dart`
  - 新写入定位器 KDF 强度调整为 standard `4096` 轮、strong `12000` 轮、extreme `24000` 轮；旧 SHA-256 standard 载荷保留兼容读取。
  - 图片公开策略头升级为 `VSSGP2`，校验长度提升到 16 字节，并改为基于图片内容派生位置写入，避免固定前 136 个 LSB。
  - 兼容读取/清理上一轮 `VSSGP1` 顺序策略头和无策略头旧载荷。
  - 旧隐写 envelope 的 MAC/摘要校验改为原始字节常量时间比较。
- `lib/src/services/toolbox_crypto_service.dart`
  - crypto envelope 的 MAC/摘要校验改为原始字节常量时间比较，十六进制仅作为存储编码。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 最大错误尝试次数风险提示明确：公开策略头是本机防误试/清理提示，不抵抗载体副本或策略头篡改。
  - 定位密钥强度选项展示当前轮数。
- `PROJECT_DOMAIN.md`
  - 同步公开策略头的安全边界、定位器 KDF 强度和常量时间比较调整。

### 风险变更
- 新载荷定位器暴力破解成本提高，但写入/还原会比旧 `1` 轮定位器更耗时。
- 无密码可读的公开策略头天然不能提供抗恶意篡改保证；自毁限制只能作为本机执行策略，真正保密性仍依赖定位器 KDF、scrypt、AEAD 与签名/MAC。
- timing side-channel 反馈评估为低风险残留：用户主动选择的 locator strength 仍会影响本地耗时，但不再通过公开策略头暴露 strength 字段。

### 验证
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_231-LIFE-STEGANOGRAPHY-ATTEMPT-LIMIT-FIX] - 2026-05-26

### 原因
- 用户反馈最大错误尝试字节未稳定生效，超过次数后当前内存载体仍可能保留隐写内容；还原失败缺少当前文件错误次数，退出子模块会清空计数，软件级错误限制也不应被错误文件拖累。

### 新增
- `lib/src/services/toolbox_steganography_service.dart`
  - 新增图片轻量策略头，使新图片载荷在错误口令或定位参数不匹配时也能读取最大错误尝试次数。
  - 新增错误口令场景下的图片 RGB LSB 清理兜底，无法精准定位 payload 时仍可破坏当前载体隐藏数据。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 错误次数改为按当前文件路径与内容摘要持久记录，退出并重新进入子模块后不清空。
  - 还原失败提示新增当前文件 5 分钟错误次数与载荷错误次数进度。
  - 非 0 最大错误尝试次数写入前新增风险确认弹窗。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 5 分钟内 10 次错误锁定改为按文件生效，避免一个错误文件锁住整个隐写模块。
  - 最大错误尝试次数提示改为红色风险文案，展示最大 255 次与当前设置；非法输入会提示并重置为 0。
  - 高级加密参数折叠区增加图标、边框和强调底色，提高可展开辨识度。
- `PROJECT_DOMAIN.md`
  - 同步按文件错误限制、策略头与当前内存载体清理边界。

### 风险变更
- 新写入图片会带有最小策略头，用于在错误口令场景执行错误次数限制；payload 内容仍由定位密钥随机化和加密 envelope 保护。
- 超过载荷限制但无法用密钥定位 payload 时，图片清理会归零 RGB LSB，可能同时破坏其他 LSB 隐写内容。

### 验证
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_230-LIFE-STEGANOGRAPHY-SECURITY-ADVANCED] - 2026-05-26

### 原因
- 用户要求优化工具箱-生活实用图片/音频/视频隐写模块：提高选择文件和导出文件按钮辨识度，补充 ChaCha20 加密，并增加错误尝试、防篡改、定位密钥和解码锁定等高级安全设置。

### 新增
- `lib/src/services/toolbox_crypto_service.dart`
  - 新增 ChaCha20-Poly1305 加密算法，并允许在自由级联中作为独立阶段使用。
- `lib/src/services/toolbox_steganography_service.dart`
  - 新增保护块格式：数据段前写入一字节最大允许错误尝试次数，尾部写入前置数据防篡改校验。
  - 新增定位密钥算法与强度参数，保留旧隐写载荷读取兼容。
  - 新增隐藏数据清理能力，用于篡改或超过载荷错误尝试限制后的复写移除。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 高级设置新增最大错误尝试次数、定位密钥算法和定位密钥强度。
  - 还原流程新增模块级连续错误限制：5 分钟内连续 10 次错误后锁定还原功能 5 分钟。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 将选择媒体、选择载体、选择待隐藏文件、导出隐写媒体、导出还原文件和 keyfile 导入/导出类按钮调整为绿色背景，提高移动端操作辨识度。
  - 还原失败时会根据保护策略提示错误次数限制、篡改清理或锁定剩余时间。
- `PROJECT_DOMAIN.md`
  - 同步生活实用隐写模块的 ChaCha20、保护块、防篡改、定位密钥和模块级锁定边界。

### 风险变更
- 最大错误尝试次数需要先成功定位到新保护块后才能读取并执行；定位口令、keyfile、算法或强度不一致时仍由模块级连续错误锁定兜底。
- 自动清理隐藏数据仅在本地文件存在且可复写时能销毁源文件中的隐写数据；Web 或无源路径场景会退回为清理当前内存载体。

### 验证
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_229-LIFE-STEGANOGRAPHY-UI-COMPACT-KEYFILES] - 2026-05-26

### 原因
- 用户反馈生活实用隐写页面在移动端过长，选择媒体、选择文件和密钥文件操作样式过于接近，并要求将密钥文件改为开关选项，支持多密钥文件导入与稳定组合。

### 新增
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 新增“使用密钥文件”开关；开启后才显示导入、生成、导出和清空操作。
  - 支持一次导入多个 keyfile，并按文件名、SHA-256、长度稳定排序后组合为统一派生材料。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 将高级加密设置收进折叠区，标题保留当前算法、强度和 keyfile 状态摘要，减少移动端首屏堆叠。
  - 仅在存在源图或输出图时显示预览区，降低空预览造成的页面长度。
  - 调整选择媒体、选择载体、选择待隐藏文件和 keyfile 操作按钮的视觉层级；生成/导出 keyfile 使用普通紧凑按钮。
  - 文件隐写结果区按文件工作区显示，避免图片结果面板误占位。
- `test/ui_smoke_test.dart`
  - 更新隐写页面 smoke 测试，覆盖折叠高级设置、keyfile 开关显隐和新的文件/哈希入口滚动方式。

### 风险变更
- 多 keyfile 必须在加密和还原时使用同一组文件；组合顺序由文件名、哈希和长度自动稳定排序，避免用户手动选择顺序导致派生材料不一致。
- 高级设置默认折叠会减少页面高度，但用户需要展开后才能看到全部算法细项。

### 验证
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_228-LIFE-STEGANOGRAPHY-SECURITY-HARDENING] - 2026-05-26

### 原因
- 用户要求对生活实用隐写模块做安全收紧：移除 RC4/SHA256 stream 新加密入口，提高 scrypt 强度，消除固定魔数检测预言机，随机化图片 LSB 嵌入顺序，并避免把音视频尾部追加伪装成频域或帧级隐写。

### 新增
- `lib/src/services/toolbox_crypto_service.dart`
  - 新增 v3 crypto envelope，加入随机长度 padding、内置盐密码混合、scrypt 根密钥一次派生与按用途扩展。
  - scrypt 参数提升为 standard `N=2^16`、strong `N=2^17`、extreme `N=2^18`。
- `lib/src/services/toolbox_steganography_service.dart`
  - 图片 LSB 新增密钥派生 header、随机 nonce、长度掩码和 CSPRNG 派生像素/通道顺序，降低固定头与顺序写入特征。
  - 保留旧图片固定头和旧音视频尾部载荷读取兼容。

### 修改
- `lib/src/services/toolbox_crypto_service.dart`
  - RC4 与 SHA256 stream 改为仅旧载荷解密兼容；新加密和自由级联不再允许选择弱算法。
- `lib/src/services/toolbox_steganography_service.dart`
  - 音频/视频新写入停止使用尾部追加；在接入 DCT/DWT/回声隐藏或帧内/运动矢量后端前返回明确错误。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 加密选项增加安全性评级文案，明文模式生成前弹窗确认，强度选项标明 scrypt N。
  - keyfile 生成改为独立弹窗，音视频写入在 UI 中提示后端边界。
- `test/toolbox_crypto_service_test.dart`、`test/toolbox_steganography_service_test.dart`、`test/ui_smoke_test.dart`
  - 覆盖 v3 envelope、padding、scrypt N、弱算法新加密拒绝、图片随机化隐写、音视频写入禁用和 UI 新评级。

### 风险变更
- 新 v3 图片载荷的定位依赖相同口令/keyfile；输错时会表现为未发现新载荷，以避免固定检测预言机。
- scrypt 参数提升会增加移动端耗时；当前通过单次根派生降低重复 KDF 成本。
- 音视频新写入暂不可用，避免继续生成不满足频域/帧级要求的尾部追加载荷。

### 验证
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
- `dart analyze test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart test/ui_smoke_test.dart`（仅剩 `test/ui_smoke_test.dart` 既有 info 提示）
- `flutter test test/toolbox_crypto_service_test.dart`
- `flutter test test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_226-LIFE-VERACRYPT-STYLE-STEGANOGRAPHY-FILE-CRYPTO] - 2026-05-26

### 原因
- 用户要求把生活实用隐写模块升级为可复用加解密库，移除未能可靠实现的 Serpent/Kuznyechik 占位，改用 SHA-256/RSA、ECDSA、Whirlpool，并按 VeraCrypt 策略补齐自由级联、独立密钥材料、keyfile 和文件载荷隐写。

### 新增
- `lib/src/services/toolbox_crypto_service.dart`
  - 新增自由级联 `customCascade`，支持 AES、Twofish、Camellia、SHA256 stream 自由组合，每层独立派生 256/512/1024-bit 密钥材料。
  - 新增 Whirlpool 哈希/MAC，新增 SHA-256/RSA 与 ECDSA 签名验证层，新增指定长度随机 keyfile 生成。
- `lib/src/services/toolbox_steganography_service.dart`
  - 新增文件 payload 写入/还原：文件字节先进入加密 envelope，再作为隐写载荷写入图片 LSB 或音视频尾部块。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 文件工作区从独立 `.vsc` 文件加密改为“选择载体媒体 + 选择文件 + 生成隐写媒体 / 从隐写媒体还原文件”。
  - UI 增加 256/512/1024-bit 密钥材料、Whirlpool MAC、RSA/ECDSA 签名、自由级联选择和 keyfile 生成/导出控件。
- `test/toolbox_crypto_service_test.dart`、`test/toolbox_steganography_service_test.dart`、`test/ui_smoke_test.dart`
  - 覆盖自由级联、Whirlpool、RSA/ECDSA、随机 keyfile、文件载荷在图片/音频/视频中的写入与还原。

### 风险变更
- 本模块借鉴 VeraCrypt 的级联、独立密钥、KDF/hash 与 keyfile 策略，但不生成 VeraCrypt 兼容卷、卷头、XTS 设备或挂载语义。
- 512/1024-bit 选项表示每层派生密钥材料长度；AES/Twofish/Camellia 实际块密码密钥会规范化到算法允许长度，额外材料仍参与密钥收敛。
- 图片载体仍受 LSB 容量限制，较大文件应优先使用音频/视频尾部载荷。

### 验证
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart test/ui_smoke_test.dart`（仅剩 `test/ui_smoke_test.dart` 既有 info 级提示）
- `flutter test test/toolbox_crypto_service_test.dart`
- `flutter test test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_223-LIFE-RELATIVES-LIVE-CALCULATOR] - 2026-05-26

### 原因
- 用户反馈亲戚关系计算器仍偏“点等于后出结果”，关系按钮占屏过大，底部导图不够像家族图谱，且文案存在“关系舞台/关系按键”等不自然表达。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_relatives.dart`
  - 计算器显示屏改为实时展示 `链路 = 称呼`，关系链、目标对象、性别、反向称呼和最短路径设置变化后自动刷新结果。
  - 保留手动刷新按钮 key 兼容测试，但文案从“等于”改为“刷新结果”，避免暗示必须点击后才计算。
  - 将“关系舞台”改为“计算器”，“关系按键”改为“关联关系”，“导图拓扑”改为“家族图谱”，整体说明更短更自然。
  - 关联关系按钮压缩为 3-5 列紧凑布局，减少首屏占用和滚动成本。
  - “我的性别”去掉“未知”，默认使用“男”，仅保留“男 / 女”切换。
  - 底部图谱替换为树状家族图谱节点与连线，展示从“我”到当前关系链的路径。
- `test/ui_smoke_test.dart`
  - 更新亲戚关系计算器 smoke 测试，覆盖新文案、无 Unknown 选项、点击后实时出现 `链路 = 结果` 和退格后实时重算。

### 风险变更
- 实时计算会在目标对象输入变化时同步执行本地 `kinship.relationship`，当前链路长度较短，性能风险较低；若未来允许长文本自然语言输入，需要再加入防抖。
- 家族图谱当前聚焦路径预览，不表达完整多分支亲属网络，复杂关系仍以顶部实时结果为准。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_relatives.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_relatives.dart test/ui_smoke_test.dart`（仅剩既有 info 级提示）
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens relatives calculator and builds chain"`

## [Unreleased-PLAN_225-LIFE-CRYPTO-LIB-FILE-CRYPTO] - 2026-05-26

### 原因
- 用户要求为隐写模块增加 AES、Serpent、Twofish、Camellia、Kuznyechik、组合加密和哈希能力，并沉淀为可复用加解密库，支持密钥文件和文件加密。

### 新增
- `lib/src/services/toolbox_crypto_service.dart`
  - 新增通用加解密服务，支持 AES-GCM、Twofish-GCM、Camellia-GCM、AES+Twofish、AES+Camellia、AES+Twofish+Camellia 组合链路。
  - 新增 `standard`、`strong`、`extreme` 三档强度，使用 scrypt 进行口令/密钥文件混合派生。
  - 新增 SHA-256、SHA-512、SHA3、BLAKE2b 哈希计算。
  - 新增加密文件 JSON 信封，包含算法、强度、KDF、密钥文件校验、密文与 MAC。
- `test/toolbox_crypto_service_test.dart`
  - 覆盖 AES 往返、组合链路、密钥文件校验、哈希和待接入算法状态。

### 修改
- `lib/src/services/toolbox_steganography_service.dart`
  - 隐写载荷加密改为复用 `ToolboxCryptoService`，并保留旧版 SHA256 stream/RC4 隐写载荷还原兼容。
  - 写入/还原支持可选密钥文件。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 页面扩展为「隐写 / 文件 / 哈希」三工作区。
  - 增加算法、强度、密钥文件选择、文件加密/解密、哈希计算与结果展示。
- `pubspec.yaml`
  - 新增 `pointycastle` 依赖承载成熟块密码算法实现。
- `test/ui_smoke_test.dart`
  - 扩展隐写页面 smoke 测试，覆盖文件加密与哈希入口控件。

### 风险变更
- Serpent 与 Kuznyechik 当前在 Flutter 可用成熟库中未启用，页面和服务保留选项但明确标记为待可靠后端接入。
- 组合加密和 `extreme` 强度会增加 CPU 与内存成本，移动端大文件需关注耗时。
- 启用密钥文件后，解密必须同时具备相同口令与相同密钥文件。

### 验证
- `dart format lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/services/toolbox_crypto_service.dart lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools.dart test/toolbox_crypto_service_test.dart test/toolbox_steganography_service_test.dart test/ui_smoke_test.dart`（仅剩既有 `test/ui_smoke_test.dart` info 级提示）
- `flutter test test/toolbox_crypto_service_test.dart`
- `flutter test test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_227-LIFE-MIND-MAP-FULLSCREEN-ACTIONS] - 2026-05-26

### 原因
- 用户要求全屏模式下增加节点操作编辑的小按钮，并放在自动整理小图标旁边，避免占用过多画布空间。

### 新增
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_fullscreen.dart`
  - 全屏顶部新增紧凑图标按钮：编辑标题、添加子节点、添加同级、删除节点，并保留自动整理和吸附按钮。
  - 新增全屏标题编辑弹窗，可在不退出全屏画布的情况下修改当前节点标题。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map.dart`
  - 新增全屏节点编辑快照回调，复用主页面已有改名、增删节点和坐标播种逻辑。

### 修改
- `test/ui_smoke_test.dart`
  - 扩展思维导图 smoke 测试，覆盖全屏改名、添加子节点和删除节点按钮。
- `modules/toolbox/README.md`
  - 补充全屏便捷模式的紧凑节点操作按钮说明。

### 风险变更
- 全屏 AppBar 操作按钮较多，本轮采用 38dp 宽紧凑图标按钮与 tooltip，避免新增文字按钮挤占画布。
- 根节点仍禁用添加同级和删除，避免破坏导图根结构。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_fullscreen.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_canvas.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_fullscreen.dart test/ui_smoke_test.dart`（仅剩既有 info 级提示）
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens simple mind map and edits nodes"`

## [Unreleased-PLAN_226-LIFE-MIND-MAP-FULLSCREEN] - 2026-05-26

### 原因
- 用户要求为工具箱「生活实用」中的「简易思维导图」增加全屏式便捷模式，支持节点吸附和在画布中直接拖拽整理。

### 新增
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_fullscreen.dart`
  - 新增全屏便捷整理页，提供独立全屏画布、当前节点提示、吸附开关和一键自动重排。
  - 拖拽仅在全屏画布内部启用，避免与默认页面纵向滚动手势冲突。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_canvas.dart`
  - 扩展导图画布为可接收节点坐标的布局层，支持节点拖拽回写、边界限制和吸附网格绘制。
  - 吸附拖拽使用累计位移计算，避免小幅连续拖动被网格取整吞掉。

### 修改
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map.dart`
  - 主舞台增加「全屏便捷模式」入口、内联自动重排按钮和节点坐标状态。
  - 新增节点会在已有手动布局中靠近父节点生成；模板切换会重置为自动布局。
- `test/ui_smoke_test.dart`
  - 扩展 `life tools opens simple mind map and edits nodes`，覆盖全屏入口、吸附开关和一次画布节点拖拽。
- `modules/toolbox/README.md`
  - 补充简易思维导图全屏便捷模式、吸附和拖拽交互边界说明。

### 风险变更
- 节点拖拽坐标按画布比例保存，在不同屏幕尺寸下会随画布缩放，必要时可通过自动重排回到结构布局。
- 吸附当前以网格为主，适合快速整理；若后续需要专业排版，可继续增加节点间对齐线或分组吸附。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_canvas.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_fullscreen.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_canvas.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_fullscreen.dart test/ui_smoke_test.dart`（仅剩既有 info 级提示）
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens simple mind map and edits nodes"`

## [Unreleased-PLAN_224-LIFE-MIND-MAP] - 2026-05-26

### 原因
- 用户要求设计并完成落地工具箱「生活实用」中的「简易思维导图」模块，当前 `mind_map` 入口仍停留在占位信息页。

### 新增
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map.dart`
  - 新增简易思维导图本地页面，支持节点舞台、结构连线、节点点击选中和移动端友好的按钮式编辑。
  - 支持编辑当前节点标题、添加子节点、添加同级节点、删除节点、选择节点颜色。
  - 支持空白、项目计划、会议记录、学习主题四类快速模板。
  - 支持结构大纲展示、复制 Markdown 大纲、导出 PNG 图片，并在保存对话框不可用时回退到应用文档目录。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_canvas.dart`
  - 拆出导图画布、节点 chip、连线 painter 与响应式布局计算，避免单个 part 文件过长。
- `test/ui_smoke_test.dart`
  - 新增 `life tools opens simple mind map and edits nodes`，覆盖入口可达、核心控件可见和基础节点编辑。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 接入 mind map part，并补充 `flutter/rendering.dart` 以支持 PNG 导出所需的 `RenderRepaintBoundary`。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 将 `mind_map` 路由接入 `_MindMapToolPage`。

### 修复
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart`
  - 补齐 Google 搜索域名判断 helper，解除同库 life tools 测试编译阻塞。
- `test/ui_smoke_test.dart`
  - 将反向搜图聚合用例的搜索与加载更多点击改为命中可见按钮，避免窄屏滚动状态下误点空白区域。

### 风险变更
- 导图节点很多时，同层节点会自动换行，画布展示仍以简易梳理为主；完整长标题由结构大纲兜底。
- PNG 导出依赖 Flutter 截图与平台保存能力，非桌面平台可能走应用文档目录或浏览器下载兜底。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_canvas.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_mind_map_canvas.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart test/ui_smoke_test.dart`（仅剩既有 info 级提示）
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens simple mind map and edits nodes"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens reverse image aggregation"`

## [Unreleased-PLAN_224-LIFE-MEDIA-STEGANOGRAPHY] - 2026-05-26

### 原因
- 用户要求完成工具箱「生活实用」中的图片/音频/视频隐写模块，支持写入加密文本并从生成媒体中还原信息。

### 新增
- `lib/src/services/toolbox_steganography_service.dart`
  - 新增隐写服务层，统一处理文本加密、载荷封装、MAC/校验与还原。
  - 支持图片 PNG LSB 隐写，以及音频/视频尾部载荷块隐写。
  - 支持 `SHA256 stream`、`RC4 legacy`、`No encryption` 三种模式。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart`
  - 新增图片/音频/视频隐写独立页面。
  - 支持写入/还原模式切换、媒体类型切换、口令输入、结果导出、密文预览与还原文本展示。
- `test/toolbox_steganography_service_test.dart`
  - 覆盖图片、音频、视频写入后还原，以及错误口令拒绝。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 引入隐写服务与隐写页面 part，并更新 `steganography` 入口说明。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 将 `steganography` 路由接入 `_SteganographyToolPage`。
- `test/ui_smoke_test.dart`
  - 新增生活实用隐写页入口与核心控件可见性 smoke 测试。
- `modules/toolbox/README.md`
  - 补充生活实用隐写模块能力与风险边界。

### 风险变更
- 图片隐写输出必须保持 PNG 等无损格式，二次转存 JPEG 会破坏 LSB 载荷。
- 音频/视频尾部载荷通常能保持播放兼容，但少数严格解析器可能拒绝附加尾部数据。
- 当前加密为应用内实现，后续若需要更高安全等级，可评估接入成熟加密库。

### 验证
- `dart format lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_steganography.dart test/toolbox_steganography_service_test.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/services/toolbox_steganography_service.dart lib/src/ui/pages/toolbox_life_tools.dart test/toolbox_steganography_service_test.dart test/ui_smoke_test.dart`
- `flutter test test/toolbox_steganography_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens steganography controls"`

## [Unreleased-PLAN_222-LIFE-IMAGE-COMPRESSION-LOSSY-PREPROCESS-DPI] - 2026-05-26

### ??
- ??????????????????????????????????????????/???? DPI ?????????????

### ??
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_compress.dart`
  - ??????????`Original color`?`Grayscale`?`Black/white`?
  - ?????????`BW threshold`?0.35~0.75??????????
  - ?? DPI ???`No custom DPI`?`Write PNG DPI`???? `72~300 dpi` ?????
  - ?????????DPI ????? PNG ?????JPEG/GIF ?????? DPI ????

### ??
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_compress.dart`
  - ??????? `decode -> orientation -> resize -> preprocess -> encode`???????????????? `auto best` ???
  - PNG ?????? `PngEncoder(pixelDimensions: ...)`???? DPI ????? PNG DPI ????
  - ?????????? DPI ????????`gray`?`bw@0.50`?`dpi144(png-only)`??
  - ????????????????
- `test/ui_smoke_test.dart`
  - ?? `life tools opens image compression controls` ????????????? DPI ??????

### ????
- ??????????????????????????????
- DPI ?????????????????????????? JPEG/GIF ?????????????

### ??
- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_compress.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_compress.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens image compression controls"`?????????????????

﻿# CHANGELOG

## [Unreleased-PLAN_221-LIFE-RELATIVES-CALCULATOR] - 2026-05-26

### 原因
- 用户要求完成工具箱「生活实用」模块中的「亲戚关系计算器」子模块，当前 `relatives` 入口仍落在占位信息页，无法实际使用。

### 新增
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_relatives.dart`
  - 新增亲戚关系计算器独立页面（本地计算）。
  - 支持关系输入、相对对象输入、性别选择、`reverse` 与 `optimal` 参数控制。
  - 支持结果列表、空结果提示和错误提示。
  - 支持常见英文关系词到中文关系词的输入归一化（如 `mom` -> `妈妈`）。
- `test/ui_smoke_test.dart`
  - 新增 `life tools opens relatives calculator and computes`，覆盖入口可达与核心控件可见。

### 修改
- `pubspec.yaml`
  - 增加依赖：`kinship_calculator: ^4.0.0`。
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 增加 `kinship_calculator` import 和 `toolbox_life_tools_relatives.dart` part 声明。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 将 `relatives` 路由接入 `_RelativesToolPage`。

### 风险变更
- 算法包升级后可能带来称谓结果差异，后续需要在版本升级时做回归比对。
- 称谓表达天然存在多义性，结果可能返回多个候选项。

### 验证
- `flutter pub get`
- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_relatives.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_relatives.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens relatives calculator and computes"`

## [Unreleased-PLAN_220-LIFE-IMAGE-COMPRESSION] - 2026-05-26

### 鍘熷洜
- 鐢ㄦ埛瑕佹眰涓撴敞骞跺畬鎴愬伐鍏风銆岀敓娲诲疄鐢ㄣ€嶄腑鐨勫浘鐗囧帇缂╁瓙妯″潡鍔熻兘锛屽綋鍓嶅叆鍙ｄ粛涓哄崰浣嶄俊鎭〉锛屼笉鍙疄闄呬娇鐢ㄣ€?
### 鏂板
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_compress.dart`
  - 鏂板鍥剧墖鍘嬬缉鐙珛椤甸潰锛堟湰鍦扮绾匡級锛氭敮鎸侀€夊浘銆佹寜姣斾緥鍘嬬缉銆佹寜鐩爣瀹藉害鍘嬬缉銆丣PEG 璐ㄩ噺璋冭妭銆?  - 鏂板鍘嬬缉缁撴灉鎸囨爣锛氬師鍥句綋绉€佺粨鏋滀綋绉€佷綋绉崰姣斻€佸帇缂╁箙搴︺€佽緭鍑哄昂瀵搞€?  - 鏂板鍘熷浘/鍘嬬缉鍚庡弻棰勮锛堢獎灞忕旱鍚戙€佸灞忓弻鍒楋級涓庡鍑烘寜閽€?  - 鏂板瀵煎嚭鍏滃簳锛氫紭鍏堜娇鐢ㄤ繚瀛樺璇濇锛岃嫢涓嶅彲鐢ㄥ垯鍥為€€鍒板簲鐢ㄦ枃妗ｇ洰褰?`life_tools/image_compress`銆?- `test/ui_smoke_test.dart`
  - 鏂板 `life tools opens image compression controls`锛岃鐩栧叆鍙ｅ彲杈句笌鏍稿績鎺т欢鍙銆?
### 淇敼
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 鏂板 `image` 鍖呭鍏ヤ笌 `toolbox_life_tools_image_compress.dart` part 澹版槑銆?- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 灏?`image_compress` 鎺ュ叆 utility 璺敱鍒嗗彂銆?- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 灏?`image_compress` 鍒嗘敮鎺ュ叆 `_ImageCompressPage`銆?- `pubspec.yaml`
  - 琛ュ厖鐩存帴渚濊禆锛歚image: ^4.8.0`锛堝師涓?transitive锛屾敼涓烘樉寮忎緷璧栦互绋冲畾缁存姢锛夈€?- `modules/toolbox/README.md`
  - 琛ュ厖鍥剧墖鍘嬬缉瀛愭ā鍧楄兘鍔涗笌杈圭晫璇存槑銆?
### 椋庨櫓鍙樻洿
- 褰撳墠杈撳嚭鍥哄畾涓?JPEG锛歅NG 绛夊甫閫忔槑閫氶亾鍥剧墖浼氳鍘嬪钩鍚庡啀缂栫爜锛岄€傚悎浣撶Н浼樺寲浣嗕笉閫傚悎淇濈暀閫忔槑鑳屾櫙鍦烘櫙銆?- 瓒呭ぇ鍥惧湪涓荤嚎绋嬪帇缂╂椂鍙兘鐭椂鍗￠】锛涘悗缁彲璇勪及 isolate 鍖栧帇缂╀换鍔°€?
### 楠岃瘉
- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_compress.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_compress.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens image compression controls"`
## [Unreleased-PLAN_219B-LIFE-REVERSE-IMAGE-AGGREGATION-PAGING-PARSERS] - 2026-05-26

### 鍘熷洜
- 鐢ㄦ埛瑕佹眰浠ュ浘鎼滃浘缁撴灉涓嶈灞曠ず闀胯姹?缁撴灉 URL 鏂囨湰锛屼笖蹇呴』鏀寔缈婚〉/鍔ㄦ€佸姞杞戒笌鍘婚噸銆?- 鐢ㄦ埛鍙嶉鎼滅嫍鏉ユ簮鍦板潃閿欓厤銆丟oogle 璇锋眰/瑙ｆ瀽寮傚父锛屽苟瑕佹眰浼樺厛钀藉埌 `https://www.google.com/search?vsrid=`銆?- 鐢ㄦ埛鏄庣‘ remove.bg 涓嶆槸鎼滃浘婧愶紝搴斾粠鑱氬悎寮曟搸涓Щ闄わ紝骞舵彁渚涘悗缁彲琛屾€ц瘎浼般€?
### 淇敼
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart`
  - 缁撴灉鍗￠殣钘?Request/Result page 闀?URL 灞曠ず锛屼粎淇濈暀鎵撳紑鎸夐挳銆?  - 缁撴灉鍒楄〃鏀逛负姣忓紩鎿?`Load more` 澧為噺鍔犺浇锛屼笉鍐嶅浐瀹氬彧鏄剧ず鍓?24 鏉°€?  - 鍘婚噸绛栫暐鍗囩骇涓哄熀浜庤鑼冨寲 `sourceUrl/imageUrl/title/site` 鐨勪紭鍏堢骇鍘婚噸锛屽噺灏戦噸澶嶇皣銆?  - Google 閾捐矾鏂板 `vsrid` 瑙ｆ瀽锛氫紭鍏堜粠 Lens 璺宠浆鎴栭〉闈腑鎻愬彇 `google.com/search?vsrid=...`銆?  - 鎼滅嫍閾捐矾鏂板 `window.__INITIAL_STATE__` 涓?`/risapi/pc/risSearchlist` 鐨勭粨鏋勫寲瑙ｆ瀽鍏滃簳銆?  - 鏉＄洰鍗￠殣钘忛暱 URL 鏂囨湰锛屼粎淇濈暀鎵撳紑鏉ユ簮/鍥剧墖鍦板潃鎸夐挳銆?- `lib/src/ui/pages/toolbox_life_tools.dart`
  - reverse image 鏉ユ簮鍒楄〃绉婚櫎 `remove.bg`銆?- `test/ui_smoke_test.dart`
  - 琛ュ厖 Google `vsrid` 璺緞涓庢悳鐙?`risapi` mock锛岃鐩栨柊瑙ｆ瀽鍒嗘敮銆?
### 鍙鎬ц瘎浼帮紙remove.bg锛屽悗缁兘鍔涳級
- remove.bg 閫傚悎鍋氣€滄悳鍥惧墠棰勫鐞嗭紙鎶犲浘澧炲己鐗瑰緛锛夆€濈殑鍙€夋楠わ紝浣嗕笉閫傚悎浣滀负鎼滃浘寮曟搸銆?- 涓婄嚎鍓嶉渶璇勪及锛欰PI Key 绠＄悊銆佽皟鐢ㄦ垚鏈笌棰濆害銆侀殣绉佷笌鍚堣锛堝浘鐗囦笂浼狅級銆佽法鍖虹綉缁滃彲杈炬€т笌绋冲畾鎬с€?
### 楠岃瘉
- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart lib/src/ui/pages/toolbox_life_tools.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart lib/src/ui/pages/toolbox_life_tools.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens reverse image aggregation"`
## [Unreleased-PLAN_219A-LIFE-REVERSE-IMAGE-STRUCTURED-RESULTS] - 2026-05-26

### 閸樼喎娲?- 娴犮儱娴橀幖婊冩禈妞ょ敻娼拌ぐ鎾冲娴犲懎鐫嶇粈铏圭暆閸楁洜濮搁幀浣规喅鐟曚緤绱濋悽銊﹀煕鐟曚焦鐪伴弨閫涜礋缂佺喍绔寸紒鎾寸€崠鏍粵閸氬牏绮ㄩ弸婊愮礄閸ュ墽澧栨穱鈩冧紖 + 濠ф劕婀撮崸鈧敍澶堚偓?- 閻劍鍩涚憰浣圭湴閺堫剙婀撮崶鐐梾缁鳖澀绱崗鍫ｈ泲閹兼粎鍌ㄥ鏇熸惛閻╃绻涚拫鍐暏閿涘苯鏁栭柌蹇庣瑝娓氭繆绂嗘稉瀛樻閸忣剛缍夐崶鎯х哎閵?
### 閺傛澘顤?- reverse image 閺傛澘顤冪紒鐔剁缂佹挻鐏夋い瑙勀侀崹瀣剁礉閹稿绱╅幙搴や粵閸氬牆鐫嶇粈鐑樼垼妫版ǜ鈧焦娼靛┃鎰彲閻愬箍鈧焦绨崷鏉挎絻閵嗕礁娴橀悧鍥ф勾閸р偓閵嗕胶缂夐悾銉ユ禈娑撳孩鎲崇憰浣蜂繆閹垬鈧?- 閺傛澘顤冮惂鎯у閻╃绻涙稉濠佺炊闁炬崘鐭鹃敍姘拱閸︽澘娴?`POST https://graph.baidu.com/upload` 閸氬海娲块崣鏍ㄦ偝缁便垽銆夐獮鎯靶掗弸鎰波閺嬪嫬瀵查崡锛勫閺佺増宓侀妴?- 閺傛澘顤冮惂鎯у缂佹挻鐎崠鏍掗弸鎰剁窗閺€顖涘瘮 `window.cardData` / `window.extData`閿涘苯鑻熼幏澶婂絿 `simipic` 閹恒儱褰涚悰銉ュ弿閻╅晲鎶€閸ョ偓娼靛┃鎰蒋閻╊喓鈧?
### 娣囶喗鏁?- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart` 闁插秵鐎稉琛♀偓婊呮纯鏉╃偘绱崗?+ 缂佺喍绔寸紒鎾寸亯閸掓銆冮垾婵嗙杽閻滆埇鈧?- 閺堫剙婀撮崶鐐梾缁便垻鐡ラ悾銉ㄧ殶閺佺繝璐熼敍?  1. 閸忓牐铔嬮惂鎯у閻╃绻涙稉濠佺炊娑撳海绮ㄩ弸鍕鐟欙絾鐎介妴?  2. 閼汇儲瀣侀崚鏉垮讲濡偓缁便垹娴橀悧?URL閿涘苯顦查悽銊嚉 URL 閺屻儴顕楅崗鏈电铂瀵洘鎼搁妴?  3. 娴犲懎缍嬮弮鐘崇《瀵版鍩岄崣顖涱梾缁?URL 閺冭绱濋崶鐐衡偓鈧稉瀛樻閸忣剛缍夐崶鎯х哎閵?- 娣囨繄鏆€ `remove.bg` 娑撶儤澧滈崝銊ㄋ夐崗鍛弳閸欙綇绱濇担鍡欐捈閸忋儳绮烘稉鈧紒鎾寸亯闂堛垺婢橀弰鍓с仛閵?
### 濞村鐦稉搴ㄧ崣鐠?- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens reverse image aggregation"`

### 妞嬪酣娅撻崣妯绘纯
- 閻ф儳瀹虫い鐢告桨缂佹挻鐎幋?`simipic` 閹恒儱褰涢崣鍌涙殶閸欐ɑ娲块弮璁圭礉缂佹挻鐎崠鏍掗弸鎰波閺嬫粈绱版稉瀣閿涘矂銆夐棃顫窗閼奉亜濮╅崶鐐衡偓鈧崚浼粹偓姘辨暏缂佹挻鐏夋い鐟扮潔缁€鎭掆偓?- 娑撳瓨妞傞崗顒傜秹閸ユ儳绨ユ稉宥呭晙閺勵垶绮拋銈堢熅瀵板嫸绱濇担鍡楁躬閻╃绻涙稉宥呭讲閻劍妞傛禒宥勭窗鐟欙箑褰傞敍宀€鏁ら幋铚傜瑐娴肩娀娈ｇ粔浣告禈閻楀洣绮涢棁鈧拫銊﹀帶閵?
## [Unreleased-PLAN_219-LIFE-REVERSE-IMAGE-AGGREGATION] - 2026-05-26

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴閽€钘夋勾瀹搞儱鍙跨粻渚库偓宀€鏁撳ú璇茬杽閻劊鈧秳鑵戦惃鍕簰閸ョ偓鎮抽崶鎯у閼虫枻绱伴柅澶嬪閸ュ墽澧栭崥搴や粵閸氬牆缍嬮崜宥喣侀崸妤€鐖堕悽銊︽偝缁便垹绱╅幙搴¤嫙濮瑰洦鈧槒绻戦崶鐐电波閺嬫嚎鈧?
### 閺傛澘顤?- 閺傛澘顤?`lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart`閿涘本褰佹笟娑椾簰閸ョ偓鎮抽崶鍓у缁斿銆夐棃顫偓?- 妞ょ敻娼伴弨顖涘瘮娑撱倗顫掓潏鎾冲弳閺傜懓绱￠敍姘垛偓澶嬪閺堫剙婀撮崶鍓у閹存牜娲块幒銉ㄧ翻閸忋儱鍙曞鈧崶鍓у URL閵?- 閺傛澘顤?reverse image 閼辨艾鎮庡ù浣衡柤閿涙碍婀伴崷鏉挎禈閸欘垯绗傛导鐘插煂娑撳瓨妞傞崗顒傜秹 URL閿涘苯鑻熼獮璺哄絺鐠囬攱鐪伴惂鎯у鐠囧棗娴橀妴浣规偝閻欐鐦戦崶淇扁偓涓無ogle Lens閵嗕箠andex閿涘本鐪归幀缁樼槨娑擃亜绱╅幙搴ｆ畱閻樿埖鈧降鈧焦鎲崇憰浣告嫲缂佹挻鐏夐柧鐐复閵?- 娣囨繄鏆€ `remove.bg` 娴ｆ粈璐熺悰銉ュ帠閹靛濮╅崗銉ュ經閿涘瞼绮烘稉鈧痪鍐插弳閸氬矂銆夌紒鎾寸亯閸栬桨绗岄弶銉︾爱閸忔粌绨抽崠鎭掆偓?- 閺傛澘顤?UI smoke 閻劋绶?`life tools opens reverse image aggregation`閿涘矁顩惄鏍晸濞茶鐤勯悽銊ュ弳閸欙絽鍩?reverse image 妞ょ敻娼伴惃鍕讲鐟欎焦鈧傜瑢閸╄櫣顢呮禍銈勭鞍閵?
### 娣囶喗鏁?- `toolbox_life_tools.dart` 婢х偛濮?reverse image part 婢圭増妲戦妴?- `toolbox_life_tools_hub.dart` 鐏?`reverse_image` 鐠侯垳鏁遍幒銉ュ弳閺備即銆夐棃顫礉娑撳秴鍟€鐠ф澘宕版担宥勪繆閹垶銆夐妴?- `modules/toolbox/README.md` 閸氬本顒炵悰銉ュ帠娴犮儱娴橀幖婊冩禈閼宠棄濮忔潏鍦櫕娑撳酣顥撻梽鈺勵嚛閺勫簺鈧?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens reverse image aggregation"`

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剙婀撮崶鐐梾缁鳖澀绶风挧鏍﹀閺冭泛娴樻惔濠冨Ω閸ュ墽澧栨潪顒佸灇閸忣剛缍?URL閿涘奔绗傛导鐘绘懠鐠侯垰銇戠拹銉ょ窗鐎佃壈鍤ч懕姘値婢惰精瑙﹂敍娑樼安闁灝鍘ゆ稉濠佺炊閺佸繑鍔?闂呮劗顫嗛崶鍓у閵?- 閼辨艾鎮庣紒鎾寸亯閺夈儴鍤滅粭顑跨瑏閺傝鎮崇槐銏犵穿閹垮氦绻戦崶鐐恒€夐幗妯款洣閿涘苯褰堢粩娆戝仯閸欏秶鍩囩粵鏍殣閵嗕線銆夐棃銏㈢波閺嬪嫬鎷伴崷鏉垮隘閸欘垵鎻幀褍濂栭崫宥忕礉缁嬪啿鐣鹃幀褌绗夐悽鍗炵安閻劎顏€瑰苯鍙忛幒褍鍩楅妴?
## [Unreleased-PLAN_218-LIFE-GARBAGE-NO-REMOTE-PREVIEW] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴閸ㄥ啫婧囬崚鍡欒缁夊娅庢潻婊呪柤閺佺増宓佹０鍕潔閿涘苯褰ф穱婵堟殌閺屻儴顕楅崗銉ュ經閵?
### 娣囶喗鏁?- 閸ㄥ啫婧囬崚鍡欒缁岀儤鐓＄拠銏㈠Ц閹椒绗夐崘宥呯潔缁€楦跨箼缁嬪鏆熼幑顕€顣╃憴鍫濆灙鐞涱煉绱濋悽銊﹀煕鏉堟挸鍙嗛悧鈺佹惂閸氬秶袨閸氬孩澧犻弰鍓с仛閺屻儴顕楃紒鎾寸亯閵?- 缂佹挻鐏夐崠鐑樼垼妫版ɑ鏁归崣锝勮礋閳ユ粍鐓＄拠銏㈢波閺?/ Results閳ユ繐绱濇稉宥呭晙閺嶈宓佺粚鐑樼叀鐠囥垹鐫嶇粈琛♀偓婊嗙箼缁嬪鏆熼幑顕€顣╃憴鍫氣偓婵勨偓?- 鐠у嘲顫愰棃銏℃緲娑撳秴鍟€鐏炴洜銇氭潻婊呪柤妫板嫯顫嶉幋鏍仛娓氬鍨悰顭掔礉娴犲懍绻氶悾娆愮叀鐠囥垺褰佺粈鍝勬嫲閼垫崘顔嗛崷銊у殠閺屻儴顕楅崗銉ュ經閵?- 閺囧瓨鏌?smoke 濞村鐦敍宀€鈥樼拋銈団敄閺屻儴顕楅悩鑸碘偓浣风瑝閸愬秴鍤悳?`Remote data preview`閵?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_garbage.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_garbage.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens garbage sorting query"`

### 妞嬪酣娅撻崣妯绘纯
- 閸掓繂顫愭い鍏哥瑝閸愬秴鐫嶇粈鐑樼壉娓氬绮ㄩ弸婊愮礉妞ょ敻娼伴弴瀵哥暆濞蹭緤绱遍崣顖炩偓姘崇箖閹兼粎鍌ㄥ鍡樺灗閸︺劎鍤庨崗銉ュ經瀵偓婵鐓＄拠顫偓?
## [Unreleased-PLAN_217-LIFE-POSTAL-CHINAPOST-SOURCE] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴鐏忓棝鍋栫紓鏍ㄧ叀鐠囥垼绻欑粙瀣爱閺€閫涜礋娑擃厼娴楅柇顔芥杺閿涘苯鑻熼幐鍥х暰閺夈儲绨い?`https://www.chinapost.com.cn/html1/folder/181312/9531-1.htm`閵?
### 娣囶喗鏁?- 闁喚绱弻銉嚄閺夈儲绨崗銉ュ經娴犲酣鍋栫紓鏍х氨閸掑洦宕叉稉杞拌厬閸ヤ粙鍋栭弨鎸庡瘹鐎规岸銆夐棃顫偓?- 閺屻儴顕楃拠閿嬬湴閺€閫涜礋娴ｈ法鏁ゆ稉顓炴禇闁喗鏂?iframe 缂冩垹鍋ｉ弻銉嚄閸︽澘娼?`https://iframe.chinapost.com.cn/jsp/type/institutionalsite/SiteSearchJT.jsp`閿涘本瀵滈悽銊﹀煕鏉堟挸鍙嗘担婊€璐熼張宥呭缂冩垹鍋ｉ崥宥囆?閸︽澘娼冮悧鍥唽閺屻儴顕楅妴?- 鐟欙絾鐎介柅鏄忕帆閺€閫涜礋鐠囪褰囨稉顓炴禇闁喗鏂傜純鎴犲仯鐞涖劍鐗告稉顓犳畱閻降鈧礁绔堕妴浣稿箼閵嗕焦婀囬崝锛勭秹閻愮懓鎮曠粔鑸偓渚€鍋栫紓鏍モ偓浣告勾閸р偓閸滃瞼鏁哥拠婵撶礉楠炲墎鎴风紒顓炲涧鐏炴洜銇氶崗鎶芥暛鐎涙顔岄妴?- 闁喚绱弻銉嚄鐠囧瓨妲戦崪灞炬殶閹诡喗娼靛┃鎰瀮濡楀牊鏁兼稉杞拌厬閸ヤ粙鍋栭弨璺ㄧ秹閻愯鐓＄拠銏犲經瀵板嫨鈧?- 閺囧瓨鏌?smoke 濞村鐦?fixture閿涘瞼鈥樻穱婵嬪仏缂傛牗鐓＄拠顫▏閻劋鑵戦崶浠嬪仏閺€璺ㄧ秹閻愮銆冮弽鐓庢惙鎼存棑绱濇稉宥呭晙娓氭繆绂嗛柇顔剧椽鎼?fixture閵?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_postal.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_postal.dart test/ui_smoke_test.dart`閿涘牅绮涢張?`test/ui_smoke_test.dart` 閺冦垺婀?info 缁?`const/final` 閹绘劗銇氶敍?- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens postal lookup query"`

### 妞嬪酣娅撻崣妯绘纯
- 娑擃厼娴楅柇顔芥杺閹稿洤鐣炬い鍨Ц缂冩垹鍋ｉ弻銉嚄妞ょ绱濈紒鎾寸亯闁艾鐖剁€电懓绨查崗铚傜秼闁喗鏂傜純鎴犲仯閿涘奔绗夐崘宥嗘Ц閸╁骸绔?閸栧搫骞欑痪褔鍋栫紓鏍х氨閿涙稖绶崗銉ㄧ箖鐎硅姤妞傞崣顖濆厴鏉╂柨娲栭崥灞芥倳缂冩垹鍋ｉ幋鏍ㄦ￥缂佹挻鐏夐敍宀勫櫢鐟曚線鍋栨禒鏈电矝闂団偓閹稿鐣弫鏉戞勾閸р偓閺嶆悂鐛欓妴?- 娑擃厼娴楅柇顔芥杺妞ょ敻娼伴柅姘崇箖 iframe 閸滃瞼鐝崘鍛板壖閺堫剙濮炴潪鐣岀波閺嬫粣绱濈€涙顔岀紒鎾寸€崣妯哄З閺冭泛褰查懗浠嬫付鐟曚浇鐨熼弫纾嬓掗弸鎰珤閵?
## [Unreleased-PLAN_216-LIFE-POSTAL-LOOKUP-SIMPLIFY] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涢崣宥夘洯闁喚绱弻銉嚄妞ら潧绨茬粻鈧崠鏍电礉娑撳秹娓剁憰浣哥潔缁€楦跨箼缁嬪鐓＄拠銏″絹缁€鐚寸幢妞ょ敻娼伴幗妯款洣閺夈儴鍤滈弶銉︾爱妞ら潧绠嶉崨濠傛嫲鐎佃壈鍩呮穱鈩冧紖閿涘本鎮崇槐銏㈢波閺嬫粌褰ф惔鏃€妯夌粈鍝勭箑鐟曚礁鍙ч柨顔讳繆閹垬鈧?
### 娣囶喗鏁?- 闁喚绱弻銉嚄妞ょ數鏁ら幋宄板讲鐟欎焦鏋冨鍫滅矤閳ユ粏绻欑粙瀣叀鐠団懇鈧繃鏁归崣锝勮礋閺咁噣鈧埃鈧粍鐓＄拠鈶┾偓婵嗗經瀵板嫸绱濋幐澶愭尦閵嗕胶濮搁幀浣稿幢閵嗕胶绮ㄩ弸婊勭垼妫版ê鎷伴幓鎰仛閸栬桨绗夐崘宥呭繁鐠嬪啳绻欑粙瀣嚞濮瑰倻绮忛懞鍌樷偓?- 缁夊娅庨柇顔剧椽閺屻儴顕楃紒鎾寸亯閸栬櫣娈戞い鐢告桨閹芥顩︾仦鏇犮仛閿涘矂浼╅崗宥嗗Ω閺夈儲绨い闈涚畭閸涘鈧礁顕遍懜顏呭灗 SEO 閺傚洦婀伴崨鍫㈠箛缂佹瑧鏁ら幋鏋偓?- 闁喚绱紒鎾寸亯閸椻€冲涧鐏炴洜銇氶崷鏉挎絻閵嗕線鍋栫紓鏍ф嫲韫囧懓顩﹂崠鍝勫娇閿涘奔绗夐崘宥呯潔缁€鍝勫晳闂€鎸庢降濠ф劘顕涢幆鍛摟濞堢偣鈧?- 閺囧瓨鏌?smoke 濞村鐦敍宀€鈥樼拋銈夊仏缂傛牗鐓＄拠銏ゃ€夋稉宥呭晙閸戣櫣骞?`Remote query` / `Remote results` / `Page summary`閿涘苯鑻熸宀冪槈缂佹挻鐏夋禒宥嗘▔缁€鐑樼箒閸﹀厖绗?`518000`閵?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_postal.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_postal.dart test/ui_smoke_test.dart`閿涘牅绮涢張?`test/ui_smoke_test.dart` 閺冦垺婀?info 缁?`const/final` 閹绘劗銇氶敍?- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens postal lookup query"`

### 妞嬪酣娅撻崣妯绘纯
- 妞ょ敻娼伴梾鎰閺夈儲绨幗妯款洣閸氬函绱濋悽銊﹀煕閻鍩岄惃鍕繆閹垱娲块獮鎻掑櫍閿涙稖瀚㈤棁鈧憰浣圭壋妤犲苯甯慨瀣降濠ф劧绱濇禒宥呭讲闁俺绻冩惔鏇㈠劥閺夈儲绨崗銉ュ經閹垫挸绱戦柇顔剧椽鎼存挻鍨ㄦ稉顓炴禇闁喗鏂傛い鐢告桨閵?
## [Unreleased-PLAN_215-LIFE-REMOTE-GARBAGE-POSTAL] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴鐏忓棗浼愰崗椋庮唸閵嗗瞼鏁撳ú璇茬杽閻劊鈧秳鑵戦惃鍕€崷鎯у瀻缁绗岄柇顔剧椽閺屻儴顕楅柈鑺ユ暭娑撹櫣鍤庢稉濠勬畱鏉╂粎鈻奸弻銉嚄閿涘矁顕Ч鍌濈箼缁嬪婀撮崸鈧懢宄板絿缂佹挻鐏夐妴?
### 閺傛澘顤?- 閺傛澘顤?`plans/PLAN_215_閻㈢喐妞跨€圭偟鏁ら崹鍐ㄦ簢閸掑棛琚稉搴ㄥ仏缂傛牞绻欑粙瀣叀鐠?md`閿涘矁顔囪ぐ鏇＄箼缁嬪鏆熼幑顔界爱閵嗕笭TML 鐟欙絾鐎芥潏鍦櫕閸滃瞼缍夌紒婊堫棑闂勨斂鈧?- 娑撹櫣鏁撳ú璇茬杽閻?smoke 濞村鐦弬鏉款杻 `HttpOverrides` 鏉╂粎鈻奸崫宥呯安 fixture閿涘矂鐛欑拠浣哥€崷鎯у瀻缁?JSON 閸旂姾娴囬崪宀勫仏缂傛牕绨辨い鐢告桨鐟欙絾鐎藉ù浣衡柤閿涘奔绗夋笟婵婄閻喎鐤勭純鎴犵捕閵?
### 娣囶喗鏁?- 閸ㄥ啫婧囬崚鍡欒閺屻儴顕楁禒搴㈡拱閸︽媽鐦濇惔鎾存暭娑撻缚顕Ч鍌濆悩鐠?QQ 濞村繗顫嶉崳銊ヤ紣閸忛顔堥崗顒€绱戦崹鍐ㄦ簢閸掑棛琚?JSON閿涘苯濮炴潪钘夋倵閹稿澧块崫浣告倳缁夐绗岄崚鍡欒缁涙盯鈧绻欑粙瀣唶瑜版洏鈧?- 闁喚绱弻銉嚄娴犲孩婀伴崷鏉跨厔鐢?閸栧搫骞欑槐銏犵穿閺€閫涜礋鐠囬攱鐪伴柇顔剧椽鎼存挻鎮崇槐銏ゃ€夐幋鏍纯鏉堥箖銆夐敍宀冃掗弸鎰€冮弽绗衡偓渚€銆夐棃銏＄垼妫版ü绗岄幓蹇氬牚娑擃厾娈戦柇顔剧椽缂佹挻鐏夐妴?- 妞ょ敻娼伴弬鍥攳閵嗕胶濮搁幀浣稿幢閸滃矂鏁婄拠顖涘絹缁€鍝勬倱濮濄儴鐨熼弫缈犺礋鏉╂粎鈻奸弻銉嚄閸欙絽绶為敍灞借嫙娣囨繄鏆€閺夈儲绨い鐢告桨/婢舵牠鍎撮弻銉嚄閸忔粌绨抽崗銉ュ經閵?- 閺囧瓨鏌婂Ο鈥虫健閺傚洦銆傞敍宀冾唶瑜版洖鐎崷鎯у瀻缁绗岄柇顔剧椽閺屻儴顕楅惃鍕箼缁嬪娼靛┃鎰┾偓浣虹秹缂佹粈绶风挧鏍ф嫲缁旀瑧鍋ｇ紒鎾寸€崣妯哄妞嬪酣娅撻妴?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_garbage.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_postal.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_garbage.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_postal.dart test/ui_smoke_test.dart`閿涘牅绮涢張?`test/ui_smoke_test.dart` 閺冦垺婀?info 缁?`const/final` 閹绘劗銇氶敍?- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens garbage sorting query"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens postal lookup query"`

### 妞嬪酣娅撻崣妯绘纯
- 閸ㄥ啫婧囬崚鍡欒娓氭繆绂嗛懙鎹愵唵鏉╂粎鈻?JSON 閸欘垵顔栭梻顔解偓褍鎷伴崚鍡欒缂傛牕褰跨粙鍐茬暰閹嶇幢闁喚绱弻銉嚄娓氭繆绂嗛柇顔剧椽鎼存捇銆夐棃銏㈢波閺嬪嫸绱濋懟銉х彲閻愮顔栭梻顔剧摜閻ｃ儲鍨?HTML 缂佹挻鐎崣妯哄閿涘矂銆夐棃顫窗閺勫墽銇氶柨娆掝嚖楠炶泛绱╃€靛吋澧﹀鈧弶銉︾爱妞ゅ灚鐗虫灞烩偓?- 娑撱倓閲滈弻銉嚄闁粙娓剁憰浣稿讲閻劎缍夌紒婊愮幢瀵京缍夐妴涓廚S 閹存牜顑囨稉澶嬫煙缁旀瑧鍋ｅ鍌氱埗閺冭埖妫ゅ▔鏇氱箽鐠囦胶绮ㄩ弸婊冪杽閺冩儼绻戦崶鐐偓?
## [Unreleased-PLAN_214-LIFE-POSTAL-LOOKUP] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴缂佈呯敾鐞涖儱鍙忓銉ュ徔缁犱究鈧瞼鏁撳ú璇茬杽閻劊鈧秵膩閸ф绱濈€瑰本鍨氳ぐ鎾冲閸欘亝婀侀崷銊у殠闁剧偓甯撮惃鍕┾偓宀勫仏缂傛牗鐓＄拠顫偓宥呯摍濡€虫健閸旂喕鍏橀妴?
### 閺傛澘顤?- 閺傛澘顤?`plans/PLAN_214_閻㈢喐妞跨€圭偟鏁ら柇顔剧椽閺屻儴顕楃€圭偟骞?md`閿涘本妲戠涵顔芥拱鏉烆噣鍋栫紓鏍ㄧ叀鐠囥垻娈戦張顒€婀撮柅鐔哥叀閵嗕礁顦婚柈銊ュ幑鎼存洖鎷扮拠锔剧矎閸︽澘娼冮柇顔剧椽瀹割喖绱撴搴ㄦ珦閵?- 閺傛澘顤冮悽鐔告た鐎圭偟鏁ら柇顔剧椽閺屻儴顕楁い纰夌礉閹绘劒绶电敮鍝ユ暏閸╁骸绔?閸栧搫骞欓柇顔剧椽缁便垹绱╅妴浣稿隘閸╃喓鐡柅澶堚偓浣哥厔鐢?閸栧搫骞?閸忣厺缍呴柇顔剧椽閺屻儴顕楅妴浣哥埗閻劎銇氭笟瀣ㄢ偓渚€鍋栫紓鏍﹀▏閻劍褰佺粈鍝勬嫲娑擃厼娴楅柇顔芥杺/闁喚绱惔鎾愁樆闁劍鐓＄拠銏犲弳閸欙絻鈧?- 閺傛澘顤?`life tools opens postal lookup query` smoke 濞村鐦敍宀冾洬閻╂牜鏁撳ú璇茬杽閻劌鍙嗛崣锝冣偓渚€鍋栫紓鏍ㄧ叀鐠囥垽銆夐棃銏″ⅵ瀵偓閵嗕礁鍙ч柨顔跨槤閺屻儴顕楅崪灞剧箒閸︽娊鍋栫紓鏍波閺嬫粌鐫嶇粈鎭掆偓?
### 娣囶喗鏁?- 閵嗗矂鍋栫紓鏍ㄧ叀鐠囶潿鈧秴鍙嗛崣锝嗘喅鐟曚椒绮犳稉顓炴禇闁喗鏂?闁喚绱惔鎾绘懠閹恒儲藟閹恒儴鐨熼弫缈犺礋鐢摜鏁ら崺搴＄/閸栧搫骞欓柇顔剧椽闁喐鐓￠敍灞借嫙閹恒儱鍙嗛悪顒傜彌閺堫剙婀存い鐢告桨閵?- 閺囧瓨鏌婂Ο鈥虫健閺傚洦銆傞敍宀冾唶瑜版洟鍋栫紓鏍ㄧ叀鐠囥垼鍏橀崝娑滅珶閻ｅ苯鎷扮拠锔剧矎閸︽澘娼冮弽鎼佺崣妞嬪酣娅撻妴?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_postal.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_postal.dart test/ui_smoke_test.dart`閿涘牅绮涢張?`test/ui_smoke_test.dart` 閺冦垺婀?info 缁?`const/final` 閹绘劗銇氶敍?- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens postal lookup query"`

### 妞嬪酣娅撻崣妯绘纯
- 闁喚绱崣顖濆厴缂佸棗瀵查崚鎷岊敎闁挶鈧焦濮囬柅鎺戠湰閹存牕銇囬崹瀣礋娴ｅ稄绱遍張顒€婀寸槐銏犵穿娴犲懍缍旀稉鍝勭厔鐢?閸栧搫骞欑痪褍鐖堕悽銊┾偓鐔哥叀閿涘矂鍣哥憰渚€鍋栨禒韬测偓浣告値閸氬被鈧浇鐦夋禒鍓佺搼閹舵洟鈧帒澧犳禒宥夋付閹稿鐣弫鏉戞勾閸р偓闁俺绻冩稉顓炴禇闁喗鏂傞妴渚€鍋栫紓鏍х氨閹存牗鏁规禒璺哄礋娴ｅ秵鐗虫灞烩偓?
## [Unreleased-PLAN_213-LIFE-GARBAGE-SORTING] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴缂佈呯敾鐞涖儱鍙忓銉ュ徔缁犱究鈧瞼鏁撳ú璇茬杽閻劊鈧秵膩閸ф绱濇导妯哄帥鐏忓棗缍嬮崜宥呭涧閺堝婀痪鍧楁懠閹恒儳娈戦妴灞界€崷鎯у瀻缁粯鐓＄拠顫偓宥呯杽閻滈璐熼崣顖滄暏閸旂喕鍏橀妴?
### 閺傛澘顤?- 閺傛澘顤?`plans/PLAN_213_閻㈢喐妞跨€圭偟鏁ら崹鍐ㄦ簢閸掑棛琚弻銉嚄鐎圭偟骞?md`閿涘本妲戠涵顔芥拱鏉烆喖鐎崷鎯у瀻缁粯鐓＄拠銏㈡畱閺堫剙婀寸€圭偟骞囬妴浣稿幑鎼存洖鍙嗛崣锝呮嫲閸︽澘灏憴鍕灟妞嬪酣娅撻妴?- 閺傛澘顤冮悽鐔告た鐎圭偟鏁ら崹鍐ㄦ簢閸掑棛琚弻銉嚄妞ょ绱濋幓鎰返閺堫剙婀寸敮姝岊潌閻椻晛鎼х拠宥呯氨閵嗕礁鍩嗛崥宥呭爱闁板秲鈧礁鍨庣猾鑽ょ摣闁鈧礁鐖剁憴浣哄⒖閸濅線鈧喐鐓￠妴浣告彥闁喎鍨介弬顓☆潐閸掓瑥鎷伴懙鎹愵唵閸︺劎鍤庨弻銉嚄閸忔粌绨抽崗銉ュ經閵?- 閺傛澘顤?`life tools opens garbage sorting query` smoke 濞村鐦敍宀冾洬閻╂牜鏁撳ú璇茬杽閻劌鍙嗛崣锝冣偓浣哥€崷鎯у瀻缁銆夐棃銏″ⅵ瀵偓閵嗕礁鍙ч柨顔跨槤閺屻儴顕楅崪灞炬箒鐎瑰啿鐎崷鍓х波閺嬫粌鐫嶇粈鎭掆偓?
### 娣囶喗鏁?- 閵嗗苯鐎崷鎯у瀻缁粯鐓＄拠顫偓宥呭弳閸欙絾鎲崇憰浣风矤閼垫崘顔嗛柧鐐复濡椼儲甯寸拫鍐╂殻娑撶儤婀伴崷鎷岀槤鎼存挷绗岄幎鏇熸杹閹绘劗銇氶敍灞借嫙閹恒儱鍙嗛悪顒傜彌閺堫剙婀存い鐢告桨閵?- 閺囧瓨鏌婂Ο鈥虫健閺傚洦銆傞敍宀冾唶瑜版洖鐎崷鎯у瀻缁粯鐓＄拠銏ｅ厴閸旀稖绔熼悾灞芥嫲閸︽澘灏弨璺ㄧ摜瀹割喖绱撴搴ㄦ珦閵?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_garbage.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_garbage.dart test/ui_smoke_test.dart`閿涘牅绮涢張?`test/ui_smoke_test.dart` 閺冦垺婀?info 缁?`const/final` 閹绘劗銇氶敍?- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens garbage sorting query"`

### 妞嬪酣娅撻崣妯绘纯
- 閸ㄥ啫婧囬崚鍡欒閸欙絽绶炵€涙ê婀崺搴＄娑撳海銇為崠鍝勬▕瀵偊绱濋張顒€婀寸拠宥呯氨娴犲懍缍旀稉鐑樻）鐢悂鈧喐鐓￠崪灞惧閺€鐐絹缁€鐚寸幢鐟欏嫬鍨崘鑼崐閺冩湹浜掗幍鈧崷銊ユ勾閺堚偓閺傜増鏂傜粵鏍モ偓浣恒仦閸栧搫鎷伴弨鎯扮箥鐟曚焦鐪版稉鍝勫櫙閵?
## [Unreleased-PLAN_212-LIFE-WALLPAPER-BING-ONLY] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴婢逛胶鐒婇崝鈺傚閸欘亙绻氶悾娆忕箑鎼存梹娼靛┃鎰剁礉閸掔娀娅?Wallhaven閵嗕甫onachan閵嗕竸nime Pictures 缁涘鍙炬禒鏍ㄦ降濠ф劑鈧?
### 娣囶喗鏁?- 婢逛胶鐒婇崝鈺傚閺夈儲绨崚妤勩€冮弨璺哄經娑撹桨绮庢穱婵堟殌 Bing Wallpaper閵?- 閸掔娀娅?Wallhaven閵嗕甫onachan閵嗕竸nime Pictures 閻ㄥ嫭娼靛┃鎰弳閸欙絻鈧焦濮勯崣鏍у瀻閺€顖樷偓涓燭ML 妞ょ敻娼扮憴锝嗙€芥潏鍛И闁槒绶崪宀€鐝悙閫涚瑩閻劏顕Ч鍌氥仈閵?- 閺囧瓨鏌婃竟浣虹剨閸斺晜澧?smoke 濞村鐦敍宀€鈥樼拋銈夈€夐棃顫瑝閸愬秴鐫嶇粈?Wallhaven閵嗕甫onachan閵嗕竸nime Pictures閵?- 閺囧瓨鏌婂Ο鈥虫健閺傚洦銆傞敍灞炬绾喖缍嬮崜宥咁梿缁剧濮幍瀣╃矌娴ｈ法鏁?Bing Wallpaper閵?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper_cache.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens wallpaper helper controls"`

### 妞嬪酣娅撻崣妯绘纯
- 閺冄呯处鐎涙娲拌ぐ鏇氳厬閸欘垵鍏樻禒宥嗙暙閻ｆ瑥宸婚崣鏌ユ姜 Bing 閸ュ墽澧栭弬鍥︽閿涙稒娼靛┃鎰灙鐞涖劌鍑＄粔濠氭珟閿涘奔绗夋导姘晙鐠囬攱鐪伴幋鏍х潔缁€楦跨箹娴滄稒娼靛┃鎰剁礉閸欘垶鈧俺绻冮悳鐗堟箒缂傛挸鐡ㄥ〒鍛倞閸忋儱褰涘〒鍛存珟閺冄勬瀮娴犺翰鈧?
## [Unreleased-PLAN_211-LIFE-WALLPAPER-REAL-SEARCH-PAGES] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涢幐鍥у毉 Wallhaven 瑜版挸澧犵拠閿嬬湴閸︽澘娼冮柨娆掝嚖閿涘苯顥嗙痪绋垮И閹靛绗夋惔鏃傛埛缂侇叀鐨熼悽?`/api/v1/search`閿涘矁鈧苯绨叉担璺ㄦ暏 `https://wallhaven.cc/search?q={query}` 閻喎鐤勯幖婊呭偍妞ょ绱盞onachan 娑?Anime Pictures 娑旂喖娓堕崚鍥ㄥ床閸掓壆婀＄€圭偤銆夐棃銏ｎ嚞濮瑰倸鎷版い鐢告桨閸忓啰绀岀憴锝嗙€介妴?
### 閺傛澘顤?- 閺傛澘顤?`plans/PLAN_211_閻㈢喐妞跨€圭偟鏁ゆ竟浣虹剨閸斺晜澧滈惇鐔风杽閹兼粎鍌ㄦい鍨閸欐牔鎱ㄦ径?md`閿涘本妲戠涵顔芥拱鏉烆喕绮犻惇鐔风杽閹兼粎鍌ㄦい鍏告叏婢跺秳绗佺粩娆愭降濠ф劗娈戦幍褑顢戝銉╊€冮崪宀勵棑闂勨晞绔熼悾灞烩偓?- 閺傛澘顤?`records/record_211_life_wallpaper_real_search_page_diagnosis.md`閿涘矁顔囪ぐ?Wallhaven 鏉╃偞甯寸仦鍌濈Т閺冭翰鈧甫onachan Cloudflare challenge閵嗕竸nime Pictures 閹兼粎鍌ㄦい?HTML/JSON/AVIF 妫板嫯顫嶇紒鎾寸€崪灞藉斧閸?403 鏉堝湱鏅妴?- 婢逛胶鐒婇崝鈺傚閺傛澘顤?HTML 鐟欙絾鐎芥潏鍛И闁槒绶敍宀€鏁ゆ禍搴ば掗弸鎰埂鐎圭偞鎮崇槐銏ゃ€夋稉顓犳畱鐠囷附鍎忛柧鐐复閵嗕胶缂夐悾銉ユ禈閸︽澘娼冮妴浣告槀鐎甸晲淇婇幁顖氭嫲 Anime Pictures 妞ょ敻娼伴崘鍛サ posts 閺佺増宓侀妴?
### 娣囶喗鏁?- Wallhaven 閺夈儲绨禒?`https://wallhaven.cc/api/v1/search` 閺€閫涜礋 `https://wallhaven.cc/search?q={query}` 閹兼粎鍌ㄦい浣冾嚞濮瑰偊绱濋獮鏈电矤閹兼粎鍌ㄧ紒鎾寸亯閸楋紕澧栫憴锝嗙€?`wallhaven.cc/w/{id}` 娑?`th.wallhaven.cc` 缂傗晝鏆愰崶淇扁偓?- Konachan 閺夈儲绨禒?`/post.json` 閺€閫涜礋 `https://konachan.net/post?tags={query}` 妞ょ敻娼扮拠閿嬬湴閿涘奔绻氶悾?`rating:safe` 閺嶅洨顒风痪锔芥将楠炴儼袙閺嬫劕褰茬拋鍧楁６妞ょ敻娼版稉顓犳畱 post 閸掓銆冮崗鍐閵?- Anime Pictures 閺夈儲绨禒?`api.anime-pictures.net/api/v3/posts` 閺€閫涜礋 `https://anime-pictures.net/posts?search_tag={query}` 妞ょ敻娼扮拠閿嬬湴閿涘矁顕伴崣鏍€夐棃銏犲敶瀹?posts 閺佺増宓佹稉?`<picture>` 妫板嫯顫嶉崗鍐閵?- 缁楊兛绗侀弬褰掋€夐棃銏ｎ嚞濮瑰倸銇旈弨閫涜礋閺囧瓨甯存潻鎴炴珮闁碍绁荤憴鍫濇珤閺傚洦銆傜拠閿嬬湴閻?`Accept` / `Referer` / `Sec-Fetch-*` 缂佸嫬鎮庨敍娑樻禈閻?CDN 娴犲秳濞囬悽銊ユ禈閻楀洩顕Ч鍌氥仈閵?
### 娣囶喖顦?- 娣囶喖顦?Wallhaven 娴ｈ法鏁ら柨娆掝嚖 API 閸︽澘娼冪€佃壈鍤ч惃鍕降濠ф劕鐤勯悳鏉夸焊瀹割喓鈧?- 娣囶喖顦?Wallhaven 缁屽搫鍙ч柨顔跨槤閺冨墎鏁撻幋?`?q&...` 閻ㄥ嫰妫舵０姗堢礉姒涙顓绘担璺ㄦ暏 `q=nature` 娣囨繃瀵旈惇鐔风杽閹兼粎鍌ㄦい闈涘棘閺佹澘鐣弫娣偓?- 娣囶喖顦?Anime Pictures 閸欘亙绶风挧?API 閸忓啯鏆熼幑顔衡偓浣圭梾閺堝瀵滈惇鐔风杽閹兼粎鍌ㄦい闈涘帗缁辩姵鐎娲暕鐟欏牊娼靛┃鎰畱闂傤噣顣介妴?- 娣囶喖顦?Konachan HTML/Cloudflare challenge 娑?JSON 閹恒儱褰涘ǎ椋庢暏閺冭泛顔愰弰鎾诡嚖閸掋倛袙閺嬫劕銇戠拹銉ф畱闂傤噣顣介妴?- 閸?Wallhaven 缂冩垹绮舵径杈Е閸?Konachan 缁旀瑧鍋ｆ穱婵囧Б閺冦儱绻旀稉顓∷夐崗?`DNS/TCP`閵嗕梗Cloudflare` 鐠囧﹥鏌囩紒鍡氬Ν閿涘奔绌舵禍搴″隘閸掑棜绻涢幒銉﹁杽閺屾挸鎷版い鐢告桨鐟欙絾鐎介梻顕€顣介妴?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper_cache.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens wallpaper helper controls"`

### 妞嬪酣娅撻崣妯绘纯
- Wallhaven 閸︺劌缍嬮崜宥囩秹缂佹粎骞嗘晶鍐х瑓娴犲秳绱版潻鐐村复 `wallhaven.cc:443` 鐡掑懏妞傞敍娑楀敩閻礁鍑℃穱顔筋劀鐠囬攱鐪伴崷鏉挎絻閿涘奔绲剧€圭偞妞傞崣顖滄暏閹傜矝閸欐牕鍠呮禍搴ｆ暏閹撮缍夌紒婊冩嫲缁旀瑧鍋ｆ潻鐐衡偓姘偓褋鈧?- 閺堫剙婀存径宥嗙ゴ閸欐垹骞?Wallhaven 閻╃鍙ч崺鐔锋倳娴兼俺顫︾憴锝嗙€介崚鏉跨磽鐢婀撮崸鈧▓纰夌礉TCP 443 婢惰精瑙﹂敍娑樼安閻劋鏅堕崣顏囧厴缂傗晝鐓粵澶婄窡閵嗕浇顔囪ぐ鏇＄槚閺傤厼鑻熸担璺ㄦ暏缂傛挸鐡?閺夈儲绨崗銉ュ經閸忔粌绨抽妴?- Konachan 瑜版挸澧犳潻鏂挎礀 Cloudflare challenge閿涘本婀版潪顔煎涧鐠囧棗鍩嗛獮鎯邦唶瑜版洜鐝悙閫涚箽閹躲倧绱濇稉宥囩搏鏉╁洭妲婚幎銈冣偓?- Anime Pictures 閹兼粎鍌ㄦい闈涘彆瀵偓妫板嫯顫嶆稉?AVIF閿涘矂鍎撮崚?Flutter/缁崵绮虹紒鍕値閸欘垵鍏橀弮鐘崇《鐟欙絿鐖滈敍娑樺斧閸ョ偓甯撮崣锝囨纯閹恒儴顕Ч鍌濈箲閸?403閿涘本婀版潪顔荤瑝缂佹洝绻冮幒鍫熸綀閹存牠妲婚惄妤呮懠闂勬劕鍩楅妴?
## [Unreleased-PLAN_210-LIFE-WALLPAPER-SOURCE-DIAGNOSIS] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涢崣宥夘洯婢逛胶鐒婇崝鈺傚闂?Bing 婢舵牭绱漌allhaven閵嗕甫onachan閵嗕竸nime Pictures 閸у洤绱撶敮闀愮瑝閸欘垳鏁ら敍宀冾洣濮瑰倹顥呴弻銉嚞濮瑰倸銇旈妴浣稿冀閻栴剝娅曢崪宀€鐝悙纭呯珶閻ｅ苯鑻熸穱顔碱槻閵?
### 閺傛澘顤?- 閺傛澘顤?`records/record_210_life_wallpaper_source_diagnosis.md`閿涘矁顔囪ぐ?Wallhaven DNS/鏉╃偞甯村鍌氱埗閵嗕甫onachan Cloudflare challenge閵嗕竸nime Pictures API/妫板嫯顫?閸樼喎娴樻潏鍦櫕閻ㄥ嫬鐤勫ù瀣波閺嬫嚎鈧?- Anime Pictures 娴犲海鍑介崗銉ュ經閺夈儲绨崡鍥╅獓娑撳搫鍙曞鈧０鍕潔閺夈儲绨敍宀冾嚢閸?`api.anime-pictures.net/api/v3/posts` 閸忓啯鏆熼幑顕嗙礉楠炴湹濞囬悽銊ュ彆瀵偓妫板嫯顫?CDN 閻㈢喐鍨?AVIF 妫板嫯顫嶉崶淇扁偓?- 婢逛胶鐒婇弶銉︾爱閸旂姾娴囬弬鏉款杻 `toolbox_wallpaper` 鏉╂劘顢戦弮鑸垫）韫囨绱濈拋鏉跨秿閺夈儲绨妴浣解偓妤佹閵嗕胶濮搁幀浣虹垳閵嗕線鏁婄拠顖滆閸掝偄鎷扮紓鎾崇摠閸忔粌绨抽悩鑸碘偓浣碘偓?
### 娣囶喗鏁?- 婢逛胶鐒婇弶銉︾爱閸旂姾娴囬弨閫涜礋楠炶泛褰傞弨鍫曟肠閿涘苯宕熸稉顏呮降濠ф劘绉撮弮韬测偓涓廚S 瀵倸鐖堕幋鏍潶缁旀瑧鍋ｆ穱婵囧Б閹凤附鍩呴弮鏈电瑝閸愬秹妯嗘繅鐐插従娴犳牗娼靛┃鎰波閺嬫嚎鈧?- 婢х偛濮?Cloudflare challenge 鐠囧棗鍩嗛敍灞界殺 `Just a moment` / `cf-mitigated: challenge` 妞ょ敻娼拌ぐ鎺旇娑撹　鈧粎鐝悙纭咁問闂傤喕绻氶幎銈嗗閹搭亖鈧縿鈧?- 閸ュ墽澧栫紓鎾崇摠婢х偛濮?`content-type` 閺嶏繝鐛欓敍宀勪缉閸忓秴鐨?HTML challenge 妞ょ敻娼扮拠顖氬晸娑撳搫娴橀悧鍥╃处鐎涙﹫绱濋獮鎯八夐崗?`avif` 閹碘晛鐫嶉弨顖涘瘮閵?- 閺囧瓨鏌婃竟浣虹剨閸斺晜澧滈弶銉︾爱鐠囧瓨妲戦崪灞灸侀崸妤佹瀮濡楋綇绱濋弰搴ｂ€?Anime Pictures 閸樼喎娴樻稉搴㈠房閺夊啩绮涢棁鈧崶鐐插煂閺夈儲绨い鐢碘€樼拋銈冣偓?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper_cache.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper_cache.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens wallpaper helper controls"`

### 妞嬪酣娅撻崣妯绘纯
- Wallhaven 閸︺劌缍嬮崜宥囩秹缂佹粈绗呯€涙ê婀?DNS/鏉╃偞甯寸仦鍌氱磽鐢潻绱濇惔鏃傛暏閸欘亣鍏樼拋鏉跨秿鐠囧﹥鏌囬妴浣借泲缂傛挸鐡ㄩ崪灞炬降濠ф劕鍙嗛崣锝呭幑鎼存洩绱濋弮鐘崇《閺囧じ鍞悽銊﹀煕缂冩垹绮剁憴锝嗙€介懗钘夊閵?- Konachan 閸?Anime Pictures 闁劌鍨庣粩顖滃仯娴兼俺袝閸?Cloudflare 娣囨繃濮㈤敍娑欐拱鏉烆喕绗夌紒鏇＄箖缁旀瑧鍋ｉ崣宥囧焽閵嗕胶娅ヨぐ鏇樷偓涓唎okie 閹存牗宸块弶鍐閸掕翰鈧?- Anime Pictures 閸忣剙绱戞０鍕潔娑?AVIF閿涘苯閽╅崣鎷屝掗惍浣告嫲鐠佸墽鐤嗙化鑽ょ埠婢逛胶鐒婇懗钘夊閸欐牕鍠呮禍?Flutter/缁崵绮洪弨顖涘瘮閵?
## [Unreleased-PLAN_209-LIFE-WALLPAPER-INIT-ERROR-GUARD] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涢崣宥夘洯婢逛胶鐒婇崝鈺傚妫ｆ牗顐奸崝鐘烘祰閺冭泛鍤悳?`dependOnInheritedWidgetOfExactType<_LocalizationsScope>()` 閻㈢喎鎳￠崨銊︽埂瀵倸鐖堕敍灞借嫙娑?Wallhaven / Konachan 婢惰精瑙﹂崢鐔锋礈鐏炴洜銇氭潻鍥︾艾鎼存洖鐪伴妴?
### 娣囶喖顦?- 娣囶喖顦叉竟浣虹剨閸斺晜澧滈崷?`initState` 閸氼垰濮╅崝鐘烘祰 Future 閺冩儼顔栭梻?`_lifeText(context, ...)` 閻ㄥ嫰妫舵０姗堢礉閸旂姾娴囩仦鍌欑瑝閸愬秳绶风挧?`Localizations`閵?- 鐏忓棙娼靛┃鎰版晩鐠囶垱鏁兼稉铏圭波閺嬪嫬瀵查悩鑸碘偓渚婄礉閸?UI 閺嬪嫬缂撻梼鑸殿唽閸愬秵婀伴崷鏉垮鐏炴洜銇氶妴?- 閺€鑸垫殐 Wallhaven 鐡掑懏妞傞妴涓紀cketException閵嗕甫onachan HTTP 403 缁涘鏁婄拠顖氱潔缁€鐚寸礉闁灝鍘ら惄瀛樺复閺嗘挳婀堕崘妤呮毐鎼存洖鐪板鍌氱埗閵?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_tool_shell.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens wallpaper helper controls"`

### 妞嬪酣娅撻崣妯绘纯
- 閺夈儲绨柨娆掝嚖鐠囷附鍎忛崷銊┿€夐棃顫瑐閸欐ü璐熼惌顓熷絹缁€鐚寸幢婵″倸鎮楃紒顓㈡付鐟曚浇鐦栭弬顓狀儑娑撳鏌熼幒銉ュ經缂佸棜濡敍灞藉讲閸愬秵甯撮崗銉ュ敶闁劍妫╄箛妞尖偓?
## [Unreleased-PLAN_208-LIFE-WALLPAPER-SOURCE-CACHE] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涢崣宥夘洯婢逛胶鐒婇崝鈺傚娑?Wallhaven 娴兼艾鍤悳?12 缁夋帟绉撮弮韬测偓涓nachan 娴兼艾鍤悳?HTTP 403閵嗕竸nime Pictures 闁鑵戦崥搴㈡￥閸欏秴绨查敍灞借嫙鐟曚焦鐪版晶鐐插閸ュ墽澧栫紓鎾崇摠閸滃本绔婚悶鍡氬厴閸旀稏鈧?
### 閺傛澘顤?- 娑撳搫顥嗙痪绋垮И閹靛鏌婃晶鐐存拱閸︽壆绱︾€涙ê鐪伴敍灞肩箽鐎涙ɑ娼靛┃鎰彥閻撗冩嫲閹?URL 閸濆牆绗囬拃鐣屾磸閻ㄥ嫬娴橀悧鍥ㄦ瀮娴犺翰鈧?- 閺傛澘顤冮妴灞芥禈閻楀洨绱︾€涙ǜ鈧秹娼伴弶鍖＄礉鐏炴洜銇氶弶銉︾爱韫囶偆鍙庨弫浼村櫤閵嗕礁娴橀悧鍥ㄦ殶闁插繐鎷扮紓鎾崇摠娴ｆ挾袧閿涘苯鑻熼幓鎰返娑撯偓闁款喗绔婚悶鍡欑处鐎涙ǜ鈧?- 閸ュ墽澧栫純鎴炵壐妫板嫯顫嶉妴浣稿弿鐏炲繘顣╃憴鍫涒偓浣风瑓鏉炶棄鎷扮拋鍓х枂婢逛胶鐒婇柧鎹愮熅閺€閫涜礋娴兼ê鍘涙径宥囨暏閺堫剙婀寸紓鎾崇摠閸ュ墽澧栭妴?- Anime Pictures 閺勫海鈥橀弨璺哄經娑撳搫鍙嗛崣锝呯€烽弶銉︾爱閿涘矂鈧鑵戦崥搴＄潔缁€楦款嚛閺勫簼绗岄幍鎾崇磻閺夈儲绨幐澶愭尦閵?
### 娣囶喗鏁?- Wallhaven 鐠囬攱鐪扮搾鍛娴?12 缁夋帟鐨熼弫缈犺礋 25 缁夋帪绱濋獮璺烘躬鐡掑懏妞傞崥搴ょ箻鐞涘奔绔村▎锛勭叚闁插秷鐦敍娑樸亼鐠愩儲妞傜亸婵婄槸鐠囪褰囬弶銉︾爱缂傛挸鐡ㄩ妴?- Konachan 鐠囬攱鐪扮悰銉ュ帠濡楀矂娼?User-Agent閵嗕竸ccept閵嗕竸ccept-Language 閸?Referer閿涙稑銇戠拹銉︽鐏忔繆鐦拠璇插絿閺夈儲绨紓鎾崇摠閵?- 閺夈儲绨粵娑⑩偓澶婂瀼閹广垺妞傜粩瀣祮閸掗攱鏌婅ぐ鎾冲缂佹挻鐏夐敍瀛塶ime Pictures 缁涘鍙嗛崣锝呯€烽弶銉︾爱鐞氼偊鈧鑵戦崥搴ｆ纯閹恒儲妯夌粈鍝勫弳閸欙綀顕╅弰搴涒偓?- 閺夈儲绨径杈Е娑撳秴鍟€閸︺劍妫ょ紓鎾崇摠閺冨墎娲块幒銉﹀閹存劖鏆ｆい闈涚磽鐢潻绱濋懓灞炬Ц鐏炴洜銇氶崣顖濐嚢闁挎瑨顕ら悩鑸碘偓浣歌嫙娣囨繄鏆€閺夈儲绨崗銉ュ經閵?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper_cache.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_tool_shell.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens wallpaper helper controls"`
- `./gradlew.bat :app:compileDebugKotlin -x checkDebugAarMetadata`

### 妞嬪酣娅撻崣妯绘纯
- 缁楊兛绗侀弬鍦彲閻愮顔栭梻顔剧摜閻ｃ儰绮涢崣顖濆厴閸欐ê瀵查敍娑欐拱鏉烆喕绗夌紒鏇＄箖 Cloudflare 閹存牜鐝悙閫涚箽閹躲倧绱濋崣顏呭絹娓氭稑鍙嗛崣锝冣偓浣虹处鐎涙ê鍘规惔鏇炴嫲闁挎瑨顕ら崣宥夘洯閵?- 缂傛挸鐡ㄦ导姘窗閻劍婀伴崷鏉跨安閻劍鏁幐浣烘窗瑜版洜鈹栭梻杈剧礉瀹稿弶褰佹笟娑氱埠鐠佲€茬瑢濞撳懐鎮婇崗銉ュ經閿涙稒绔婚悶鍡楁倵缁傝崵鍤庨崗婊冪俺閸滃苯鍑＄紓鎾崇摠妫板嫯顫嶆导姘愁潶缁夊娅庨妴?
## [Unreleased-PLAN_207-LIFE-WALLPAPER-HELPER] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴閸忓牆鐣幋鎰紣閸忛顔堥妴宀€鏁撳ú璇茬杽閻劊鈧秳鑵戦惃鍕梿缁剧濮幍瀣剁礉鐏忓棗甯崗鍫濆涧閺堝婀痪鍧楁懠閹恒儳娈戦崡鐘辩秴閸忋儱褰涢崡鍥╅獓娑撳搫褰查懢宄板絿閵嗕焦鎮崇槐顫偓渚€顣╃憴鍫涒偓浣风瑓鏉炶棄鎷扮拋鍓х枂婢逛胶鐒婇惃鍕粵閸氬牆浼愰崗鍑ょ礉楠炲墎些闂勩倕鐡ㄩ崷銊у閺夊啴顥撻梽鈺冩畱閺佸懎顔傛竟浣虹剨閺夈儲绨妴?
### 閺傛澘顤?- 閺傛澘顤冩竟浣虹剨閸斺晜澧滈悪顒傜彌 part 妞ょ敻娼伴敍宀冧粵閸?Bing Wallpaper閵嗕箘allhaven閵嗕甫onachan 娑撳琚潻鎰攽閺冭泛娴橀悧鍥ㄦ降濠ф劧绱濋獮鏈电箽閻?Anime Pictures 娴ｆ粈璐熺紒鐔剁閺夈儲绨崗銉ュ經閵?- 鏉╂稑鍙嗘竟浣虹剨閸斺晜澧滄妯款吇閸旂姾娴?9 瀵娀娈㈤張鍝勵梿缁鹃潻绱濋弨顖涘瘮閸忔娊鏁拠宥嗘偝缁鳖潿鈧焦娼靛┃鎰摣闁鈧礁缍嬮崜宥呯潌楠炴洖鏄傜€?濮ｆ柧绶ラ崠褰掑帳閸滃奔绗夐梽鎰槀鐎靛憡鐓￠惇瀣ㄢ偓?- 閺傛澘顤冩竟浣虹剨妫板嫯顫嶆い纰夌礉閺€顖涘瘮 InteractiveViewer 缂傗晜鏂侀妴渚€鍣哥純顔剧級閺€淇扁偓浣规降濠ф劘鐑︽潪顑锯偓浣风瑓鏉炶棄鍩岄張顒€婀撮崪灞绢攽闂?闁夸礁鐫?娑撱倛鈧懓顔曠純顕€鈧銆嶉妴?- Android 缁旑垰婀?`vocabulary_sleep/life_display` 闁岸浜炬稉濠冩煀婢?`setWallpaper` 閺傝纭堕敍灞煎▏閻劎閮寸紒?`WallpaperManager` best-effort 鐠佸墽鐤嗘竟浣虹剨閵?- 閺傛澘顤?`life tools opens wallpaper helper controls` smoke 濞村鐦敍宀冾洬閻╂牜鏁撳ú璇茬杽閻劌鍙嗛崣锝冣偓浣割梿缁剧濮幍瀣付閸掕泛灏崪宀€些闂勩倝顥撻梽鈺傛降濠ф劑鈧?
### 娣囶喗鏁?- 缁夊娅庢竟浣虹剨閸斺晜澧滈弶銉︾爱閸掓銆冩稉顓犳畱 dpm 閺佸懎顔傛竟浣虹剨闁剧偓甯撮妴?- 娑撳娴囬柧鎹愮熅閸忓牅绻氱€涙ê鍩屾惔鏃傛暏閸愬懘鍎存竟浣虹剨閻╊喖缍嶉悽銊ょ艾缁崵绮虹拋鍓х枂閿涙稓鏁ら幋铚傚瘜閸斻劋绗呮潪鑺ユ閸愬秴鐨剧拠鏇烆嚤閸戝搫鍩岄悽銊﹀煕闁瀚ㄦ担宥囩枂閿涘矂浼╅崗?Android 閸愬懎顔?URI 閺冪姵纭堕惄瀛樺复鐞氼偆閮寸紒鐔奉梿缁炬瓕顔曠純顔款嚢閸欐牓鈧?- 濡€虫健閺傚洦銆傜悰銉ュ帠閻㈢喐妞跨€圭偟鏁ゆ竟浣虹剨閸斺晜澧滈懗钘夊閵嗕焦娼靛┃鎰珶閻ｅ苯鎷伴獮鍐插酱妞嬪酣娅撶拠瀛樻閵?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_wallpaper.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_tool_shell.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens wallpaper helper controls"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens local color helper palettes"`
- `./gradlew.bat :app:compileDebugKotlin -x checkDebugAarMetadata`

### 妞嬪酣娅撻崣妯绘纯
- 缁楊兛绗侀弬瑙勫复閸欙絽鎷伴幒鍫熸綀閺€璺ㄧ摜閸欘垵鍏橀崣妯哄閿涙稒婀版潪顔荤瑝閹垫挸瀵樼粭顑跨瑏閺傜懓顥嗙痪闈╃礉閸欘亣绻嶇悰灞炬閼辨艾鎮庨獮璺虹潔缁€鐑樻降濠ф劑鈧?- Android 鐠佸墽鐤嗘竟浣虹剨娓氭繆绂嗙化鑽ょ埠娑撳骸宸堕崯?ROM 閼宠棄濮忛敍宀勬敚鐏炲繐顥嗙痪绋垮讲閼冲€燁潶閹锋帞绮烽敍娑㈡姜 Android 楠炲啿褰存导姘舵缁狙傝礋娣囨繂鐡ㄩ張顒€婀撮獮鑸靛絹缁€鎭掆偓?- 閸忋劑鍣?Android 缂傛牞鐦цぐ鎾冲娴兼艾鍘涚悮顐ｆ＆閺?CameraX 1.6.0 娑?AGP 8.7.3 閸忓啯鏆熼幑顔款洣濮瑰倷绗夐崠褰掑帳闂冪粯鏌囬敍娑滅儲鏉?AAR metadata 閸?Kotlin 鐎规艾鎮滅紓鏍槯瀹告煡鈧俺绻冮妴?
## [Unreleased-PLAN_206-LIFE-COLOR-HELPER-BACKGROUND-SWITCH-SEMANTICS] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴妞ょ敻娼伴懗灞炬珯鐠佸墽鐤嗛弨閫涜礋閻喐顒滈惃鍕磻閸忕绱濇稉宥夋付鐟曚線鈧鑵戦懝鎻掑幢閸氬孩澧犻崗浣筋啅鐠佸墽鐤嗛敍娑樼磻閸忓啿绱戦崥顖欑稻閺堫亪鈧鑵戦懝鎻掑幢閺冭绱濊ぐ鎾冲妞ょ敻娼版穱婵囧瘮濮濓絽鐖堕崢鐔奉潗閼冲本娅欓妴?
### 娣囶喗鏁?- 鐏忓棝鍘ら懝鎻掑И閹靛鎮崇槐銏犲隘閻ㄥ嫰銆夐棃銏ｅ剹閺咁垰鍙嗛崣锝勭矤缁備胶鏁ゅ蹇斿瘻闁筋喗鏁兼稉鍝勵潗缂佸牆褰查幙宥勭稊閻?Switch閵?- 鐏忓棜澹婇崡陇顕涢幆鍛厬閻ㄥ嫰銆夐棃銏ｅ剹閺咁垰鍙嗛崣锝呮倱濮濄儲鏁兼稉?Switch閿涘苯鎷伴幖婊呭偍閸栧搫鍙￠悽銊ユ倱娑撯偓瀵偓閸忓磭濮搁幀浣碘偓?- 鐠嬪啯鏆ｉ幖婊呭偍閵嗕焦绔荤粚鍝勬嫲閸忔娊妫撮懝鎻掑幢鐠囷附鍎忛弮鍓佹畱閼冲本娅欓悩鑸碘偓浣筋嚔娑斿绱伴崣顏呯闂勩倕缍嬮崜宥夘暕鐟欏牓顤侀懝璇х礉娑撳秴鍟€瀵搫鍩楅崗鎶芥４妞ょ敻娼伴懗灞炬珯瀵偓閸忕偨鈧?- 閺囧瓨鏌婇柊宥堝閸斺晜澧?smoke 濞村鐦敍宀冾洬閻╂牗婀柅澶夎厬閼规彃宕遍弮璺虹磻閸氼垰绱戦崗鍏呯矝娣囨繃瀵旈崢鐔奉潗閼冲本娅欓妴渚€鈧鑵戦懝鎻掑幢閸氬氦鍤滈崝銊ョ安閻劏鍎楅弲顖樷偓浣疯⒈婢跺嫬绱戦崗宕囧Ц閹礁鎮撳銉ｂ偓?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color_widgets.dart test/ui_smoke_test.dart`
- `flutter analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_tool_shell.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens local color helper palettes"`

### 妞嬪酣娅撻崣妯绘纯
- 瀵偓閸忓磭濮搁幀浣哄箛閸︺劌褰叉禒銉ユ躬濞屸剝婀佽ぐ鎾冲閼规彃宕辨０婊嗗閺冩湹绻氶幐浣哥磻閸氼垽绱辨い鐢告桨閼冲本娅欓崣顏勬躬鐎涙ê婀ぐ鎾冲闁鑵戦懝鍙夋鎼存梻鏁ら敍宀勪缉閸忓秶鈹栨０婊嗗閻樿埖鈧線鏁婄拠顖涙暭閸欐﹢銆夐棃銏ｅ剹閺咁垬鈧?
## [Unreleased-PLAN_205-LIFE-COLOR-HELPER-SEARCH-BACKGROUND-TO-TOP] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴鐏忓棝銆夐棃銏ｅ剹閺咁垶顣╃憴鍫ｎ啎缂冾喕绡冩晶鐐插閸掓澘顦婚柈銊︽偝缁便垺顢嬫稉瀣煙閿涘苯鑻熺涵顔荤箽鐎瑰啩绗岄懝鎻掑幢鐠囷附鍎忔稉顓犳畱閼冲本娅欏鈧崗宕囧Ц閹礁鎮撳銉幢閸氬本妞傛稉鍝勭秼閸撳秹鍘ら懝鎻掑И閹靛銆夐棃銏狀杻閸旂姳绔撮柨顔跨箲閸ョ偤銆婇柈銊﹀瘻闁筋喓鈧?
### 閺傛澘顤?- 娑撳搫浼愰崗鐑姐€夋竟铏煀婢х偛褰查柅?`scrollController` 娑?`floatingActionButton` 閸欏倹鏆熼敍宀勭帛鐠併倓绗夎ぐ鍗炴惙閸忔湹绮銉ュ徔妞ょ偣鈧?- 閸︺劑鍘ら懝鎻掑И閹靛鎮崇槐銏☆攱娑撳鏌熼弬鏉款杻閼冲本娅欐０鍕潔閹稿鎸抽敍灞炬弓闁鑵戦懝鎻掑幢閺冨墎顩﹂悽顭掔礉闁鑵戦懝鎻掑幢閸氬骸褰叉稉搴ゎ嚊閹懏瀵滈柦顔兼倱濮濄儱绱戦崗鐐解偓?- 娑撴椽鍘ら懝鎻掑И閹靛鏌婃晶鐐┾偓婊嗙箲閸ョ偤銆婇柈銊⑩偓婵囧亾濞搭喗瀵滈柦顕嗙礉娑撯偓闁款喗绮撮崶鐐茬秼閸撳秹銆夐棃銏ゃ€婇柈銊ｂ偓?
### 娣囶喗鏁?- 闁板秷澹婇崝鈺傚閻ㄥ嫭鎮崇槐銏犲隘閼冲本娅欓幐澶愭尦娑撳氦澹婇崡陇顕涢幆鍛板剹閺咁垱瀵滈柦顔煎彙閻劌鎮撴稉鈧禒?`_pageColorPreviewEnabled` 閻樿埖鈧礁鎷伴崚鍥ㄥ床閸ョ偠鐨熼妴?- 閺囧瓨鏌婇柊宥堝閸斺晜澧?smoke 濞村鐦敍宀冾洬閻╂牗鎮崇槐銏犲隘閼冲本娅欓幐澶愭尦閵嗕浇鍎楅弲顖滃Ц閹礁鎮撳銉ユ嫲鏉╂柨娲栨い鍫曞劥閹稿鎸崇€涙ê婀幀褋鈧?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_tool_shell.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color_widgets.dart test/ui_smoke_test.dart`
- `flutter analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_tool_shell.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens local color helper palettes"`

### 妞嬪酣娅撻崣妯绘纯
- 瀹搞儱鍙挎い闈涳紦閸欏倹鏆熸晶鐐插娴ｅ棗娼庢稉鍝勫讲闁绱卞鍙夋箒瀹搞儱鍙挎い鍏哥瑝娴肩姴鍙嗛弮鍓佹樊閹镐礁甯悰灞艰礋閵?
## [Unreleased-PLAN_204-LIFE-COLOR-HELPER-PAGE-BACKGROUND-PREVIEW] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴閸︺劑鍘ら懝鎻掑И閹靛鑵戞晶鐐插娑撯偓娑擃亞鐣濋崡鏇熷瘻闁筋喖绱戦崗绛圭礉瀵偓閸氼垱妞傛稉瀛樻鐏忓棗缍嬮崜宥夈€夐棃銏ｅ剹閺咁垵澹婄拋鍓х枂娑撶儤澧嶉柅澶庡閸楋繝顤侀懝灞傗偓?
### 閺傛澘顤?- 娑撳搫浼愰崗鐑姐€夋竟铏煀婢х偛褰查柅?`backgroundColor` 閸欏倹鏆熼敍宀勭帛鐠併倓绗夎ぐ鍗炴惙閸忔湹绮銉ュ徔妞ょ偣鈧?- 閸︺劑鍘ら懝鎻掑И閹靛鈧鑵戦懝鎻掑幢閻ㄥ嫭鏆ｇ悰宀冾嚊閹懍鑵戦弬鏉款杻閳ユ粓銆夐棃銏ｅ剹閺?/ 閸忔娊妫撮懗灞炬珯閳ユ繂绱戦崗铏瘻闁筋噯绱濋悽銊ょ艾娑撳瓨妞傛０鍕潔瑜版挸澧犻懝鎻掑幢娴ｆ粈璐熸い鐢告桨閼冲本娅欓妴?
### 娣囶喗鏁?- 闁板秷澹婇崝鈺傚鐠佹澘缍嶈ぐ鎾冲闁鑵戦懝鎻掑幢妫版粏澹婇敍灞界磻閸氼垵鍎楅弲顖烆暕鐟欏牆鎮楁い鐢告桨閼冲本娅欓梾蹇涒偓澶夎厬閼规彃宕遍弴瀛樻煀閵?- 濞撳懐鈹栭幖婊呭偍閵嗕礁鍨忛幑銏℃偝缁便垼鐦濋幋鏍у彠闂傤參鈧鑵戦懝鎻掑幢閺冩儼鍤滈崝銊┾偓鈧崙楦垮剹閺咁垶顣╃憴鍫礉娑撳秴浠涢幐浣风畽閸栨牔绻氱€涙ǜ鈧?- 閺囧瓨鏌婇柊宥堝閸斺晜澧?smoke 濞村鐦敍宀冾洬閻╂牞鍎楅弲顖烆暕鐟欏牊瀵滈柦顔兼嫲 Scaffold 閼冲本娅欓懝鎻掑綁閺囨番鈧?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_tool_shell.dart lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color_widgets.dart test/ui_smoke_test.dart`
- `flutter analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_tool_shell.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens local color helper palettes"`

### 妞嬪酣娅撻崣妯绘纯
- 濞ｈ精澹婇崡鈥茬稊娑撴椽銆夐棃銏ｅ剹閺咁垱妞傛い闈涖仈閺傚洤鐡ч崣顖濆厴闂勫秳缍嗙€佃鐦惔锔肩幢鐠囥儴鍏橀崝娑楃矌娑撹桨澶嶉弮鍫曨暕鐟欏牞绱濋崗鎶芥４閹存牠鍣搁柅澶夌窗閹垹顦叉妯款吇閼冲本娅欓妴?
## [Unreleased-PLAN_203-LIFE-COLOR-HELPER-SAMPLER-FIRST-ROW-DETAIL] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴鐏忓棗娴橀悧鍥у絿閼硅尙些閸斻劌鍩岄柊宥堝閸斺晜澧滃Ο鈥虫健娑撳﹥鏌熼敍灞借嫙娴兼ê瀵查懝鎻掑幢閻愮懓鍤仦鏇炵磻閺傜懓绱￠敍宀勪缉閸忓秴宕熸稉顏勫幢閻楀洤顤冩妯侯嚤閼锋潙鎮撴稉鈧純鎴炵壐鐞涘矁顫﹂幐銈呭竾闁挎瑤缍呴妴?
### 娣囶喗鏁?- 鐏忓棌鈧粏绶熼崝鈺佹禈閻楀洤褰囬懝娴嬧偓婵嬫桨閺夊灝澧犵純顔煎煂闁板秷澹婇崝鈺傚娑撹缍嬫い鍫曞劥閿涘矁鐎洪崥鍫ｅ鎼存挷绗岄幖婊呭偍閸栧搫鐓欐稉瀣╅妴?- 鐏忓棜鐎洪崥鍫ｅ鎼存挾缍夐弽闂寸矤 `Wrap` 閸楁洖宕辩仦鏇炵磻閺€閫涜礋閹稿顢戝〒鍙夌厠閿涘矁澹婇崡鈥茬箽閹镐礁娴愮€规岸鐝惔锔衡偓?- 閻愮懓鍤懝鎻掑幢閸氬骸婀崗鑸靛閸︺劏顢戞稉瀣煙閹绘帒鍙嗛崗銊ヮ啍鐠囷附鍎忛棃銏℃緲閿涘苯鐫嶇粈鍝勬倳缁夎埇鈧焦瀚鹃棅?缂冩鈹堥棅鐐解偓涓燛X/RGB/CMYK閵嗕礁顦查崚鎯板閸婄厧鎷版径宥呭煑閼规彃鎮曢妴?- 閺囧瓨鏌婇柊宥堝閸斺晜澧?smoke 濞村鐦敍宀冾洬閻╂牕娴橀悧鍥у絿閼规彃婀摶宥呮値閼规彃绨辨稉濠冩煙閻ㄥ嫬绔风仦鈧憰浣圭湴閵?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color_widgets.dart test/ui_smoke_test.dart`
- `flutter analyze lib/src/ui/pages/toolbox_life_tools.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens local color helper palettes"`

### 妞嬪酣娅撻崣妯绘纯
- 閼规彃宕辩拠锔藉剰閺€閫涜礋閺佺顢戦幍鎸庡复閸氬函绱濋柅澶夎厬閼硅尪顕涢幆鍛窗閸楃姷鏁ゆ稉鈧弫纾嬵攽鐎硅棄瀹抽敍娑毿╅崝銊ь伂閸欘垵顕伴幀褎娲挎總鏂ょ礉娴ｅ棝鏆遍崚妤勩€冨姘З妤傛ê瀹虫导姘辨殣閺堝顤冮崝鐘偓?
## [Unreleased-PLAN_202-LIFE-COLOR-HELPER-UNIFIED-WILDCARD] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涢崣宥夘洯闁板秷澹婇崝鈺傚娣団剝浼呴棃銏℃緲鏉╁洣绨弶鐐殠閵嗕浇澹婅ぐ鈺傜槷娓氬绗夐弰搴㈡▔閿涘苯鑻熺憰浣圭湴缁夊娅庨弶銉︾爱閹诲繗鍫妴浣割杻閸旂娀鍎撮崚?HEX / 闁岸鍘?HEX 鏉堟挸鍙嗛崠褰掑帳閵嗕胶鍋ｉ崙鏄忓閸椻€冲斧閸︽澘鐫嶅鈧拠锔藉剰閿涘奔浜掗崣濠呯€洪崥鍫滆⒈婵傛澹婇崡鈥茬瑝閸愬秴鍨庣紒鍕┾偓?
### 閺傛澘顤?- 閺傛澘顤冮摶宥呮値閼规彃绨遍幖婊呭偍闂堛垺婢橀敍宀€绮烘稉鈧幍鑳祰閺堫剙婀存稉顓炴禇閼硅弓绗?NIPPON COLORS 閼规彃宕辩紒鎾寸亯閺佷即鍣洪崪灞藉彠闁款喛鐦濇潏鎾冲弳閵?- 閺傛澘顤?`??FF??` 缁鈧岸鍘?HEX 閸栧綊鍘ゆ稉搴㈡珮闁?HEX 閻楀洦顔岄崠褰掑帳閿涘本鏁幐浣烘暏闁劌鍨庨懝鎻掔厵韫囶偊鈧喓鐡柅澶婂斧婵澹婇崡掳鈧?- 閺傛澘顤冪紒鐔剁閼规彃宕辨晶娆戠矋娴犺绱濋悙鐟板毊閼规彃宕遍崥搴℃躬瑜版挸澧犻崡锛勫閸愬懎鐫嶅鈧?HEX/RGB/CMYK閵嗕礁顦查崚鎯板閸婄厧鎷版径宥呭煑閼规彃鎮曢妴?
### 娣囶喗鏁?- 缁夊娅庨柊宥堝閸斺晜澧滈崢鐔告箒閳ユ粈鑵戦崶鍊熷婢?/ NIPPON COLORS閳ユ繃膩瀵繐鍨忛幑銏犳嫲妞ゅ爼鍎寸拠锔藉剰閼哥偛褰撮敍灞炬暭娑撹桨绗夐崚鍡欑矋閻ㄥ嫯鐎洪崥鍫ｅ閸椻剝绁﹂妴?- 閸樺缂夋い鍫曞劥娣団剝浼呴棃銏℃緲閿涘奔绮庢穱婵堟殌閾诲秴鎮庨懝鎻掔氨閺嶅洭顣介妴浣稿爱闁板秵鏆熼柌蹇庣瑢閹兼粎鍌ㄦ潏鎾冲弳閵?- 婢х偛銇囬懝鎻掑幢姒涙顓婚懝鎻掓健閸楃姵鐦敍宀冾唨妫版粏澹婇張顒冮煩閹存劒璐熷ù蹇氼潔娑撴槒顫嬬憴澶堚偓?- 缁夊娅庨懝鎻掑幢閺夈儲绨幓蹇氬牚閵嗕焦娼靛┃鎰瘻闁筋喖鎷板Ο鈥崇€锋稉顓犳畱閺夈儲绨?URL 鐎涙顔岄妴?- 閺囧瓨鏌婇柊宥堝閸斺晜澧?smoke 濞村鐦敍宀冾洬閻╂牞鐎洪崥鍫濆弳閸欙絻鈧線鈧岸鍘?HEX 閹兼粎鍌ㄩ妴浣稿幢閻楀洤鍞寸仦鏇炵磻鐠囷附鍎忔稉搴℃嫲閼瑰弶顥呯槐顫偓?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color_models.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color_widgets.dart test/ui_smoke_test.dart`
- `flutter analyze lib/src/ui/pages/toolbox_life_tools.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens local color helper palettes"`

### 妞嬪酣娅撻崣妯绘纯
- 閸氬牆鑻熼懝鎻掔氨閸氬氦澹婇崡锟犮€庢惔蹇旀暭娑撹櫣绮烘稉鈧懝鑼祲閹烘帒绨敍灞芥嫲娑撳﹣绔撮悧鍫濆瀻濡€崇础濞村繗顫嶉惃鍕斧婵鐝悙褰掋€庢惔蹇庣瑝閸氬矉绱遍弽绋跨妇閺佺増宓侀妴浣规偝缁便垹鎷版径宥呭煑閼宠棄濮忔穱婵囧瘮閺堫剙婀撮崣顖滄暏閵?
## [Unreleased-PLAN_201-LIFE-COLOR-HELPER-REBUILD] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴鐎靛厜鈧粌浼愰崗椋庮唸-閻㈢喐妞跨€圭偟鏁?闁板秷澹婇崝鈺傚閳ユ繀绮犳径鎾櫢閺傛澘鐤勯悳甯礉閺勫海鈥樻稉宥呭棘閼板啫缍嬮崜宥嗚穿娑旇京绮ㄩ弸鍕剁礉楠炴湹浜?`zhongguose.com` 娑?`nipponcolors.com/#aikobicha` 閻ㄥ嫯澹婅ぐ鈺佸幢閻楀洤濮涢懗鎴掕礋閺嶇绺鹃崑姘拱閸︽澘鐤勯悳鑸偓?
### 閺傛澘顤?- 閺傛澘顤冮柊宥堝閸斺晜澧滈張顒€婀撮懝鎻掑幢濡€崇€锋稉搴濈波鎼存挻濯堕崚鍡樻瀮娴犺绱濈紒鐔剁鐠囪褰囬張顒€婀存稉顓炴禇閼硅弓绗?NIPPON COLORS JSON 閺佺増宓侀妴?- 閺傛澘顤冮柊宥堝閸斺晜澧滅仦鏇犮仛缂佸嫪娆㈤幏鍡楀瀻閺傚洣娆㈤敍灞惧鏉炶姤膩瀵繐鍨忛幑顫偓浣藉閸?pill閵嗕椒鑵戦崶鍊熷閼规彃顣鹃妴涓疘PPON COLORS 濞屽韫堥懜鐐插酱閵嗕焦铆閸氭垹鍌ㄥ鏇氱瑢 CMYK/RGB 娣団€冲娇閸ヤ勘鈧?
### 娣囶喗鏁?- 闁插秴鍟撻柊宥堝閸斺晜澧滄い鐢告桨娑撹缍嬮敍灞炬暭娑撹　鈧粈鑵戦崶鍊熷婢ф瑢鈧繂鎷伴垾娣PPON COLORS閳ユ繀琚辨總妤佹拱閸︽壆鐝悙鐟板娴ｆ捇鐛欓妴?- 娑擃厼娴楅懝鍙壞佸蹇庣箽閻ｆ瑨澹婃晶娆愮セ鐟欏牄鈧焦鎮崇槐顫偓渚€鈧鑵戦懝鑼跺灦閸欒埇鈧笭EX/RGB/CMYK 鐏炴洜銇氶妴浣割槻閸掓儼澹婇崐?閼规彃鎮曢崪灞炬降濠ф劘鐑︽潪顑锯偓?- NIPPON COLORS 濡€崇础娣囨繄鏆€閸楁洝澹婂▽澶嬭箞閼哥偛褰撮妴浣稿閸氬骸鍨忛幑顫偓浣圭拨閸斻劌鍨忛幑顫偓浣姑崥鎴犲偍瀵洏鈧浇鐑︽潪顒€鍨悰銊ユ嫲閼规彃鈧厧顦查崚韬测偓?- 閸ュ墽澧栭崣鏍缂佈呯敾娣囨繄鏆€娑撻缚绶熼崝鈺勫厴閸旀冻绱濋獮鏈垫叏濮?`BoxFit.contain` 妫板嫯顫嶆稉瀣絿閺嶅嘲娼楅弽鍥ㄦЁ鐏忓嫸绱濋柆鍨帳闂堢偞寮ч柧鍝勬禈閻楀洤褰囬懝鎻掍焊缁夋眹鈧?- 閺囧瓨鏌婇柊宥堝閸斺晜澧?smoke 濞村鐦敍灞煎▏閸忚泛灏柊宥嗘煀閻?`NIPPON COLORS` 閸掑棙顔岄崗銉ュ經閵?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color_models.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color_widgets.dart test/ui_smoke_test.dart`
- `flutter analyze lib/src/ui/pages/toolbox_life_tools.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens local color helper palettes"`

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘径宥囧箛閺嶇绺惧ù蹇氼潔閸旂喕鍏樻稉搴Ｐ╅崝銊ь伂閸欘垳鏁ゆ担鎾荤崣閿涘本鐥呴張澶愨偓鎰剼缁辩姷鍙庨幖顒傜秹妞ら潧濮╅弫鍫幢閸氬海鐢绘俊鍌滄埛缂侇厾绨挎穱顕嗙礉閸欘垵藟閻喐婧€濠婃艾濮╂稉搴ｇ崕鐏炲繗顫嬬憴澶愮崣閺€韬测偓?
## [Unreleased-PLAN_200-LIFE-TOOLS-COLOR-HELPER-FULL-LOCAL-SITES] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴鐏忓棌鈧粌浼愰崗椋庮唸-閻㈢喐妞跨€圭偟鏁ら垾婵呰厬閻ㄥ嫰鍘ら懝鎻掑И閹靛绮犻張顒€婀寸划楣冣偓澶庡閸椔ょ箻娑撯偓濮濄儱宕岀痪褌璐熼幒銉ㄧ箮閸樼喓鐝惃鍕暚閺佸瓨婀伴崷棰佺秼妤犲矉绱濋獮鑸垫绾喛顩﹀Ч鍌欏▏閻劎婀＄€圭偤顤侀懝鎻掓倳缁夐绗屾０婊嗗閺佺増宓侀敍宀冣偓灞肩瑝閺勵垰浠犻悾娆忔躬閳ユ粈鑵戦崶鍊熷 / NIPPON COLORS閳ユ繄楠囬崚顐ゆ畱缁犫偓閸楁洘娼惄顔衡偓?
### 閺傛澘顤?- 閺傛澘顤?`assets/toolbox/colors/zhongguose_colors.json` 娑?`assets/toolbox/colors/nippon_colors.json` 娑撱倕顨滈張顒€婀撮懝鎻掑幢鐠у嫪楠囬敍灞藉瀻閸掝偅澹欐潪钘夌暚閺佺繝鑵戦崶鎴掔炊缂佺喕澹婃稉?NIPPON COLORS 閸氬秶袨閵嗕焦瀚鹃棅?缂冩鈹堥棅鐐解偓涓燛X閵嗕阜GB閵嗕竼MYK 閺佺増宓侀妴?- 娑撴椽鍘ら懝鎻掑И閹靛鏌婃晶鐐┾偓婊€鑵戦崶鍊熷婢ф瑢鈧繀绗岄垾娣ppon immersive閳ユ繂寮诲ù蹇氼潔濡€崇础閿涘苯鍨庨崚顐㈩槻閸掕崵鎮ｉ崥鍫ｅ婢ф瑦绁荤憴鍫濇嫲閸楁洝澹婂▽澶嬭箞濞村繗顫嶉惃鍕壋韫囧啰鐝悙閫涚秼妤犲被鈧?- 閺傛澘顤冩稉顓炴禇閼规煡鈧鑵戦懝鑼跺灦閸欒埇鈧礁鎷伴懝鑼剁儲鏉烆剙鍨悰銊ｂ偓浣稿閸氬骸鍨忛幑銏ｅ缓闁挶鈧浇澹婇崐闂翠繆閸欏嘲褰茬憴鍡楀娑撳孩娲跨€瑰本鏆ｉ惃鍕拱閸︾増鎮崇槐顫秼妤犲被鈧?
### 娣囶喗鏁?- 鐏忓棝鍘ら懝鎻掑И閹靛銆夐棃銏ゅ櫢閸愭瑤璐熼張顒€婀撮弫鐗堝祦妞瑰崬濮╅惃鍕暚閺佺澹婅ぐ鈺傜セ鐟欏牆娅掗敍宀勩€夐棃銏ゎ€囬弸鎯扮殶閺佺繝璐熼垾婊勭セ鐟欏牊膩瀵?閳?娑撴槒鍨堕崣?閳?鏉堝懎濮崶鍓у閸欐牞澹婇垾婵勨偓?- 鐏忓棔鑵戦崶鍊熷濞村繗顫嶉崡鍥╅獓娑撶儤瀵滈懝鑼祲/閺勫骸瀹崇紒鍕矏閻ㄥ嫬鐣弫纾嬪婢ф瑱绱濋弨顖涘瘮闁鑵戦懝鑼额嚊閹懌鈧礁顦查崚?HEX閵嗕礁顦查崚璺烘倳缁夋澘鎷伴幍鎾崇磻閺夈儲绨い鐢告桨閵?- 鐏?NIPPON COLORS 濞村繗顫嶉崡鍥╅獓娑撶儤鐭囧ù绋跨础閺佹潙鐫嗘稉鏄忓閼哥偛褰撮敍灞炬暜閹镐礁澧犻崥搴″瀼閹诡潿鈧礁鎻╅柅鐔荤儲閼瑰眰鈧礁鎮曠粔棰佺瑢閼规彃鈧壈顕涢幆鍛颁粓閸斻劊鈧?- 鐏忓棙婀伴崷?JSON 鐠囪褰囨禒?`rootBundle.loadString` 鐠嬪啯鏆ｆ稉?`rootBundle.load + utf8.decode`閿涘矂浼╅崗宥呫亣鐠у嫭绨崷?widget test 娑擃參鏆遍張鐔蜂粻閻ｆ瑥婀崝鐘烘祰閹降鈧?- 濞撳懐鎮婇柊宥堝閸斺晜澧滅€?`nippon_colors` 鏉╂劘顢戦弮鏈电贩鐠ф牜娈戦惄瀛樺复娴ｈ法鏁ら敍灞炬暭娑撳搫鐣崗銊ょ贩鐠ф牗婀伴崷鎵瀲缁捐儻绁禍褋鈧?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart test/ui_smoke_test.dart`閿涘牅绮涢張?`test/ui_smoke_test.dart` 閺冦垺婀?info 缁?`const/final` 閹绘劗銇氶敍?- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens local color helper palettes"`

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛張顒€婀撮崠鏍ь槻閸掕绱崗鍫ｎ洬閻╂牗鐗宠箛鍐╃セ鐟欏牓鈧槒绶妴浣蜂繆閹垰鐪伴崪宀冾潒鐟欏濡總蹇ョ礉閺堫亪鈧劕鍎氱槐鐘靛弾閹碱剙甯粩娆愬閺堝缍夋い闈涘З閺佸牞绱遍崥搴ｇ敾婵″倻鎴风紒顓熺箒閸栨牭绱濋棁鈧憰浣告躬閻喐婧€娑撳﹤鍙у▔銊︾泊閸斻劋绗屾潻鍥ㄦ诞閹嗗厴閵?- 閺堫剙婀撮懝鎻掑幢鐠у嫪楠囧鎻掔暚閺佸顬囩痪鍨閿涘苯鎮楃紒顓″閸樼喓鐝弫鐗堝祦閺囧瓨鏌婇敍宀勬付鐟曚焦澧滈崝銊ユ倱濮?JSON 閺佺増宓佸┃鎰┾偓?
## [Unreleased-PLAN_199-LIFE-TOOLS-COLOR-HELPER-LOCAL-PALETTES] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴缂佈呯敾鐞涖儱鍙忛垾婊冧紣閸忛顔?閻㈢喐妞跨€圭偟鏁ら垾婵呰厬閻ㄥ嫰鍘ら懝鎻掑И閹靛绱濋獮鑸垫绾喕浜?`zhongguose.com` 娑?`nipponcolors.com` 閻ㄥ嫯澹婅ぐ鈺佸幢閻楀洣缍嬫灞艰礋閸╄櫣顢呴崑姘拱閸︽澘鐤勯悳甯礉閼板奔绗夐弰顖氫粻閻ｆ瑥婀粻鈧崡鏇炲絿閼?demo閵?
### 閺傛澘顤?- 娑撴椽鍘ら懝鎻掑И閹靛藟閸忓懍鑵戦崶鎴掔炊缂佺喕澹婃稉?NIPPON COLORS 閻ㄥ嫭婀伴崷鎵翱闁澹婇崡鈽呯礉娣囨繄鏆€娑擃厽鏋冮崥?閹峰ジ鐓舵稉搴℃嫲閸?缂冩鈹堥棅鐐解偓?- 閺傛澘顤冮懝鎻掑幢閺夈儲绨幀鏄忣潔閵嗕焦娼靛┃鎰摣闁鈧礁鍙ч柨顔跨槤閹兼粎鍌ㄩ妴浣藉閸椔ゎ嚊閹懎绨抽柈銊╂桨閺夊尅绱濇禒銉ュ挤婢跺秴鍩楅懝鎻掆偓?婢跺秴鍩楅崥宥囆?鐠哄疇娴嗛弶銉︾爱妞ょ敻娼伴懗钘夊閵?- 閺傛澘顤?`life tools opens local color helper palettes` smoke 濞村鐦敍宀冾洬閻╂牜鏁撳ú璇茬杽閻劌鍙嗛崣锝呭煂闁板秷澹婇崝鈺傚妞ょ敻娼伴惃鍕唨閺堫剙褰叉潏鐐偓褋鈧?
### 娣囶喗鏁?- 鐏忓棗甯張顒€褰ч張?6 娑擃亞銇氭笟瀣閸ф娈戦柊宥堝閸斺晜澧滈柌宥呭晸娑撹櫣顬囩痪鑳閸椻剝绁荤憴鍫濇珤閿涘矂銆夐棃顫瘜鐠侯垰绶炵拫鍐╂殻娑撹　鈧粍娼靛┃鎰嚛閺?閳?閼规彃宕卞ù蹇氼潔 閳?閸ュ墽澧栭崣鏍閳ユ縿鈧?- 娣囨繄鏆€閸樼喐婀侀崶鍓у閸欐牞澹婇懗钘夊閿涘苯鑻熺亸鍡楀従娑撳鐭囨稉楦跨窡閸斺晛灏敍灞炬暜閹镐礁顕遍崗銉︽拱閸︽澘娴橀悧鍥ф倵閻愮懓鍤０鍕潔閸栧搫鐓欓崣鏍ㄧ壉楠炶埖鐓￠惇?RGB / HSV / CMYK閵?- 閹恒儱鍙?`nippon_colors` 閺堫剙婀撮懝鎻掆偓鐓庣埗闁插骏绱濋柆鍨帳閺冦儲婀版导鐘电埠閼规彃宕辨笟婵婄閸︺劎鍤庢い鐢告桨閼存碍婀伴幋鏍箥鐞涘本妞傜純鎴犵捕缂佹挻鐎妴?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens local color helper palettes"`

### 妞嬪酣娅撻崣妯绘纯
- 瑜版挸澧犻柌鍥╂暏缁箖鈧婀伴崷鎷屽閸椔も偓宀勬姜娑撯偓濞嗏剝鈧冪暚閺佸瓨鏁硅ぐ鏇炲弿闁劌鍙曞鈧懝鎻掑幢閿涘奔绱悙瑙勬Ц妞ょ敻娼伴弴纾嬩氦閵嗕焦娲跨粙绛圭幢閼汇儱鎮楃紒顓㈡付鐟曚焦澧跨€圭櫢绱濋崣顖氭躬娑撳秵鏁兼禍銈勭鞍妤犮劍鐏﹂惃鍕閹绘劒绗呯紒褏鐢绘潻钘夊閺佺増宓侀妴?- 閼规彃宕遍弶銉︾爱妞ょ敻娼版禒鍛稊娑撻缚顕╅弰搴濈瑢鐠哄疇娴嗛敍灞肩瑝娓氭繆绂嗙粭顑跨瑏閺傚湱鐝悙鐟版躬缁捐法绮ㄩ弸鍕剁礉閸ョ姵顒濈粋鑽ゅ殠閸欘垳鏁ら幀褎娲挎總鏂ょ礉娴ｅ棔绡冮幇蹇撴嚄閻偓閺堫剙婀撮弫鐗堝祦闂団偓鐟曚礁婀崥搴ｇ敾閻楀牊婀版稉顓熷閸斻劎娣幎銈冣偓?
## [Unreleased-PLAN_198-LIFE-TOOLS-RULER-PROTRACTOR-UTILITY] - 2026-05-25

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴娴兼ê鍘涚悰銉ュ弿瀹搞儱鍙跨粻渚库偓宀€鏁撳ú璇茬杽閻劊鈧秳鑵戦惃鍕槀鐎涙劒绗岄柌蹇氼潡閸ｃ劍膩閸ф绱濇担鍨従娑撳秴鍟€閸嬫粎鏆€閸︺劍绱ㄧ粈鐑樷偓渚婄礉楠炶埖妲戠涵顔藉瘹閸戣櫣娲跨亸鍝勫煝鎼达箑绨茬拹纾嬬箮閹靛婧€鐏炲繐绠锋潏鍦喘閼板奔绗夐弰顖滅帛閸掕泛婀稉顓㈡？閵?
### 閺傛澘顤?- 娑撹櫣鏁撳ú璇茬杽閻劍绁撮柌蹇撲紣閸忛攱甯撮崗?`camera` 娓氭繆绂嗛敍宀€鏁ゆ禍搴ㄥ櫤鐟欐帒娅掓い鐢告桨鐠囬攱鐪伴惄鍛婃簚閺夊啴妾洪獮鑸垫▔缁€鍝勭杽閺冩儼鍎楅弲顖樷偓?- 閺傛澘顤冮惄鏉戞槀/闁插繗顫楅崳銊┿€夐棃銏㈡畱閺嶁€冲櫙妫板嫯顫嶉崡掳鈧焦铆鐏炲繗绔熺紓妯兼纯鐏忛缚鍨堕崣鑸偓浣烘祲閺堥缚鍎楅弲顖炲櫤鐟欐帒娅掗懜鐐插酱閸滃瞼娴夐張铏瑰Ц閹焦褰佺粈楦垮厡閸ュ鈧?- 閺傛澘顤?`life tools opens ruler and protractor utility page` smoke 濞村鐦敍宀冾洬閻╂牜鏁撳ú璇茬杽閻劌鍙嗛崣锝呭煂鐏忓搫鐡欏銉ュ徔妞ょ數娈戦崺铏诡攨閸欘垵鎻幀褋鈧?
### 娣囶喗鏁?- 鐏忓棗甯張澶嗏偓婊冩槀鐎涙劏鈧繂宕版担宥夈€夐崡鍥╅獓娑撹　鈧粌鏄傜€涙劕鎷伴柌蹇氼潡閸ｃ劉鈧繂鐤勯悽銊┿€夐敍灞炬暜閹镐焦澧滈崝銊︾墡閸戝棎鈧礁浜曠拫鍐ㄦ嫲闁插秶鐤嗛弽鍥у櫙閵?- 鐏忓棗鍙忕仦蹇曟纯鐏忕儤鏁兼稉鐑樏仦蹇旂焽濞寸绱℃潏鍦喘閸掕瀹冲〒鍙夌厠閿涘苯鍩㈡惔锕佸垱鏉╂垵鐫嗛獮鏇㈡毐鏉堢櫢绱濇笟澶哥艾娴犮儲澧滈張楦跨珶缂傛ü缍旀稉鐑樼ゴ闁插繐鐔€閸戝棎鈧?- 鐏忓棝鍣虹憴鎺戞珤閸忋劌鐫嗘い鍨暭娑撹桨绱崗鍫ｎ嚞濮瑰倸鎮楃純顔炬祲閺堢尨绱濋幋鎰閺冭埖妯夌粈铏规祲閺堟椽顣╃憴鍫礉婢惰精瑙﹂弮鍫曟缁狙傝礋闂堟瑦鈧浇鍎楅弲顖氬閸掕瀹崇仦鍌︾礉娑撳秹妯嗘繅鐐恒€夐棃顫▏閻劊鈧?- 娑?Android 娑?iOS 鐞涖儱鍘栭惄鍛婃簚閺夊啴妾烘竟鐗堟閵?
### 妤犲矁鐦?- `flutter pub add camera`
- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_display.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_display.dart test/ui_smoke_test.dart`閿涘牅绮涢張?`test/ui_smoke_test.dart` 閺冦垺婀?info 缁?`const/final` 閹绘劗銇氶敍?- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens ruler and protractor utility page"`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page opens life tool hub module"`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools exposes deep time screen and barrage controls"`

### 妞嬪酣娅撻崣妯绘纯
- 閻╂潙鏄傛妯款吇閸掕瀹虫禒宥呯唨娴?Flutter 闁槒绶崓蹇曠閸╄櫣鍤庢导鎵暬閿涘奔绗夐崥灞炬簚閸ㄥ妫块崣顖濆厴鐎涙ê婀亸鎴﹀櫤鐠囶垰妯婇敍灞芥礈濮濄倓绻氶悾娆愬閸斻劍鐗庨崙鍡曠稊娑撶儤娓剁紒鍫ｆ儰閻愬箍鈧?- 闁插繗顫楅崳銊ф祲閺堟椽鎽肩捄顖氭躬濡楀矂娼伴妴浣圭ゴ鐠囨洜骞嗘晶鍐╁灗缁崵绮洪幏鎺撴綀閸︾儤娅欐稉瀣╃窗閼奉亜濮╅梽宥囬獓娑撴椽娼ら幀浣藉剹閺咁垰鍩㈡惔锕€鐪伴敍娑氭埂閺堣桨濞囬悽銊ュ娴犲秴缂撶拋顔兼躬 Android/iOS 鐠佹儳顦稉濠備粵娑撯偓濞嗏剝娼堥梽鎰瑢閸欐牗娅欐宀冪槈閵?
## [Unreleased-PLAN_197-LIFE-TOOLS-TIME-FLIP-REFERENCE-FIX] - 2026-05-22

### 閸樼喎娲?- 閻劍鍩涢幓鎰返閸欏倽鈧啫缍嶇仦蹇ョ礉鐢本婀滈弮鍫曟？鐏炲繐绠风紙濠氥€夐崣妯绘纯娑撶儤鏆ｆい鍏哥矤妞ゅ爼鍎撮崥鎴滅瑓 90 鎼达妇鐐曢惄鏍畱閺佸牊鐏夐敍宀勪缉閸忓秵妫弫鏉跨摟娑撳些閸滃奔鑵戠痪鎸庡閸欑姵鍔呴妴?
### 娣囶喗鏁?- 鐏忓棙鏆熺€涙鐐曟い闈涚湴缁狙嗙殶閺佺繝璐熼弮褎鏆熺€涙娼ゅ顫稊娑撳搫绨抽弶鍖＄礉閺傜増鏆熺€涙銆夐棃顫簰娑撳﹨绔熺紓妯硅礋鏉炵繝绮犳潻?90 鎼达妇鐐曟稉瀣嫙鐟曞棛娲婇弮褍鈧鈧?- 娑撹櫣鐐曟い鐢搞€夐悧鍥ь杻閸旂娀娈㈢憴鎺戝閸欐ê瀵查惃鍕彯閸忓鎷伴幎鏇炲閿涘苯宸遍崠鏍у棘閼板啫绱＄紙濠氥€夐惃鍕紕閻╂牕鍙х化姹団偓?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_time_screen_flip.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools exposes deep time screen and barrage controls"`

### 妞嬪酣娅撻崣妯绘纯
- 閺佹挳銆?3D 缂堣濮╂笟婵堝姧娓氭繆绂嗛崡鏇氶嚋鐏炩偓闁劌濮╅悽缁樺付閸掕泛娅掗敍灞芥倵缂侇叀瀚㈢紒褏鐢婚崣鐘插閺囨潙顦块崗澶婂閹存牗鎶ら梹婊愮礉闂団偓鐟曚礁婀惇鐔告簚娑撳﹤鍙у▔銊ょ秵缁旑垵顔曟径鍥ф姎閻滃洢鈧?
## [Unreleased-PLAN_196-LIFE-TOOLS-TIME-FLIP-OPTIMIZATION-2] - 2026-05-21

### Reason
- Refine the time screen flip clock so the update reads as a top-cover page flip, and fully hide the immersive HUD buttons when idle.

### Changed
- Reworked the digit transition into a top-edge covering page-flip, removing the midline split and the old digit drop-down feel.
- Switched the immersive settings cluster to an off-screen slide with pointer blocking so hidden controls are no longer partially visible.

### Validation
- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_time_screen.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_time_screen_flip.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools exposes deep time screen and barrage controls"`

## [Unreleased-PLAN_196-LIFE-TOOLS-TIME-FLIP-OPTIMIZATION] - 2026-05-21

### 閸樼喎娲?- 閻劍鍩涚敮灞炬箿閺冨爼妫跨仦蹇撶閺佹澘鐡ч弴瀛樻煀閺冩湹绮犻垾婊嗕氦瀵邦喛鐑﹂崝銊⑩偓婵嗗磳缁狙傝礋閺囧婀＄€圭偟娈戠紙鑽ゅ妞ら潧濮╅悽浼欑礉楠炴湹绗栭崣顖欎簰闁瀚ㄦ稉宥呮倱閸斻劎鏁炬搴㈢壐閵?
### 閺傛澘顤?- 娑撶儤妞傞梻鏉戠潌楠炴洖顤冮崝鐘电倳閻楀苯濮╅悽濠氼棑閺嶈壈顔曠純顔煎弳閸欙綇绱濋弨顖涘瘮缂佸繐鍚€閵嗕線銆庡鎴欌偓浣戒氦韫囶偂绗佺粔宥夈€夌紙缁樺閹扮喆鈧?
### 娣囶喗鏁?- 鐏忓棙妞傞梻鏉戠潌楠炴洘鏆熺€涙鍨忛幑銏ゅ櫢閸愭瑤璐熸稉濠佺瑓閸楀﹦澧栭崚鍡楃湴缂堣崵澧濋弫鍫熺亯閿涘奔绗夐崘宥呭涧閺勵垱鏆ｉ崸妤勪氦瀵邦喗妫嗘潪顑锯偓?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_time_screen.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_time_screen_flip.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart test/ui_smoke_test.dart`閿涘牅绮涢張?`test/ui_smoke_test.dart` 閺冦垺婀?info 缁?const/final 閹绘劗銇氶敍?- `flutter test test/ui_smoke_test.dart --plain-name "life tools exposes deep time screen and barrage controls"`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page opens life tool hub module"`

### 妞嬪酣娅撻崣妯绘纯
- 閸忋劌鐫嗛弮鍫曟？鐏炲繐绠烽惃鍕殶鐎涙鍨忛幑銏も偓鏄忕帆婢х偛濮炴禍鍡楃湰闁劌濮╅悽缁樺付閸掕泛娅掗敍宀冨閸氬海鐢婚崘宥呭綌閸旂姵娲挎径姘З閹焦鐗卞蹇ョ礉闂団偓鐟曚胶鎴风紒顓炲彠濞夈劑鍣哥紒妯诲灇閺堫兙鈧?
## [Unreleased-PLAN_195-LIFE-TOOLS-CLOCK-BARRAGE-DEEPENING] - 2026-05-21

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴閸忓牆鐣幋鎰紣閸忛顔堥妴宀€鏁撳ú璇茬杽閻劊鈧秳鑵戦惃鍕┾偓灞炬闂傛潙鐫嗛獮鏇樷偓宥呮嫲閵嗗本澧滈幐浣歌剨楠炴洏鈧稄绱濋弴鎸庡床瑜版挸澧犵粻鈧崡?demo 娑撳骸宕愰幋鎰惂閻樿埖鈧降鈧?
### 閺傛澘顤?- 閺傛澘顤冮悽鐔告た瀹搞儱鍙块弰鍓с仛濡椼儲甯撮柅姘朵壕 `vocabulary_sleep/life_display`閿涙ndroid 閺€顖涘瘮濞屽韫堟い闈涚埗娴滎喖鎷拌ぐ鎾冲缁愭褰涙禍顔煎閹绘劕宕岄敍娌琌S 閺€顖涘瘮濞屽韫堟い鐢殿洣濮濄垼鍤滈崝銊╂敚鐏炲繈鈧?- 閺傛澘顤冮悽鐔告た鐎圭偟鏁ら崗鍙橀煩鐠佸墽鐤嗙紒鍕閿涘瞼鏁ゆ禍搴″瀻濞堢敻鈧銆嶉妴浣藉閺夎￥鈧焦绮﹂弶鍡楁嫲妫板嫯顫嶅鍡礉閸氬海鐢婚崥宀€琚銉ュ徔閸欘垰顦查悽銊ｂ偓?- 閺傛澘顤?`life tools exposes deep time screen and barrage controls` smoke 濞村鐦敍宀冾洬閻╂牗妞傞梻鏉戠潌楠炴洖鎷伴幍瀣瘮瀵懓绠烽惃鍕箒鐏炲倽顔曠純顔煎弳閸欙絻鈧?
### 娣囶喗鏁?- 鐏忓棛鏁撳ú璇茬杽閻劌鍙嗛崣锝夈€夐弽鍥暯娴犲簶鈧粎鏁撳ú璇茬杽閻劍膩閸фせ鈧繃鏁归崣锝勮礋閳ユ粎鏁撳ú璇茬杽閻劉鈧縿鈧?- 鐏忓棙妞傞梻鏉戠潌楠炴洘绻侀崠鏍﹁礋濡亜鐫嗗▽澶嬭箞缂堝銆夐弮鍫曟寭閿涙碍鏁幐浣峰瘜妫版ǜ鈧礁鐡ф担鎾活棑閺嶇鈧焦妞傞梻瀛樼壐瀵繈鈧浇鍎楅弲顖樷偓浣规殶鐎涙銇囩亸蹇嬧偓浣稿幢閻楀洤娓剧憴鎺嬧偓浣规）閺堢喎鎷伴弰鐔告埂閺勫墽銇氱拋鍓х枂閿涙稑鍙忕仦蹇涖€夋潪鏄徯曢弰鍓с仛鐠佸墽鐤?闁偓閸戠儤瀵滈柦顕嗙礉3 缁夋帗妫ら幙宥勭稊闂呮劘妫岄妴?- 鐏忓棙澧滈幐浣歌剨楠炴洘绻侀崠鏍﹁礋閸忋劌鐫嗗鐟扮瀹搞儱鍙块敍姘暜閹镐礁鍞寸€瑰箍鈧礁鐡ч崣鏋偓渚€鈧喎瀹抽妴浣姑粩鏍х潌閵嗕礁鐡ф担鎾寸壉瀵繈鈧礁濮炵划妞尖偓浣哥摟娴ｆ捇顤侀懝灞傗偓浣藉剹閺咁垯瀵?鏉堝懓澹婇妴浣哄嚱閼?濞撴劕褰?閼哥偛褰撮崗澶庡剹閺咁垽绱濇禒銉ュ挤闂堟瑦顒涢妴浣圭泊閸斻劊鈧線妫悜浣碘偓浣瑰閸斻劌濮╅幀浣碘偓?- 鐏忓棛鏁撳ú璇茬杽閻劍妯夌粈鍝勪紣閸忛攱濯堕崚鍡曡礋 `time_screen`閵嗕梗barrage`閵嗕梗shared` 缁涘瀚粩?part 閺傚洣娆㈤敍宀勬娴?display 閺傚洣娆㈢紒褏鐢婚懚銊ㄥ剦閻ㄥ嫰顥撻梽鈹库偓?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_display.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_shared.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_time_screen.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_barrage.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart test/ui_smoke_test.dart`閿涘牅绮涢張?`test/ui_smoke_test.dart` 閺冦垺婀?info 缁?const/final 閹绘劗銇氶敍?- `flutter test test/ui_smoke_test.dart --plain-name "life tools exposes deep time screen and barrage controls"`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page opens life tool hub module"`

### 妞嬪酣娅撻崣妯绘纯
- 閸忋劌鐫嗗銉ュ徔鏉╂稑鍙嗛弮鏈电窗娣囶喗鏁肩化鑽ょ埠閺傜懓鎮滈妴浣洪兇缂?UI 娑撳骸鐫嗛獮鏇炵埗娴滎喚濮搁幀渚婄礉闁偓閸戠儤妞傜紒鐔剁閹垹顦查敍娑滃楠炲啿褰撮柅姘朵壕娑撳秴褰查悽銊ょ窗闂堟瑩绮梽宥囬獓閵?- iOS 娓氀勬拱鏉烆喖褰ч崑姘鳖洣濮濄垼鍤滈崝銊╂敚鐏炲骏绱濇稉宥勫瘜閸斻劍鏁奸崗銊ョ湰鐏炲繐绠锋禍顔煎閿涘矂浼╅崗宥夆偓鈧崙鍝勬倵娴滎喖瀹冲▓瀣殌閵?
## [Unreleased-PLAN_194-LIFE-TOOLS-ZH-LOCALIZATION] - 2026-05-21

### Reason
- Localize the new `toolbox.life_tools` module for Chinese UI usage.

### Changed
- Filled the life-tool catalog with Chinese titles and summaries.
- Localized the display, utility, and color helper pages so visible labels, defaults, and color info read naturally in Chinese.

### Validation
- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_display.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_display.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart`

## [Unreleased-PLAN_193-PIANO-MOBILE-TOUCH-CLEANUP] - 2026-05-21

### 閸樼喎娲?- 閻劍鍩涚憰浣圭湴鐎电懓浼愰崗椋庮唸閵嗗矂鎸楅悶娣偓宥喣侀崸妤勭箻娑撯偓濮濄儰绱崠鏍モ偓?- 瑜版挸澧犻柦銏㈡償閸︺劍澧滈張铏诡伂濠婃垵顨旈妴浣瑰瘻闁款噣鐝禍顕€鍣撮弨鎯ф嫲闂婂啿鐓欐０鍕劰鐠侯垰绶炴禒宥嗘箒鏉堝啴鐝惃鍕彯妫版垹濮搁幀浣规纯閺傞绗岄崙鍡楊槵閸樺濮忛妴?
### 娣囶喗鏁?- 闁姐垻鎯斿鎴濐殧婢х偛濮為幐澶嬪瘹闁藉牏娈戞潪濠氬櫤鐟欙箑褰傞懞鍌涚ウ閿涘苯鍣虹亸鎴ｇ箾缂?`PointerMove` 闁姵鍨氶惃鍕箖鐎靛棝鐓舵０鎴Ｐ曢崣鎴滅瑢鐟欏棜顫庨懘澶婂暱閵?- 鐏忓棙瀵滈柨顕€鐝禍顕€鍣撮弨鍙ョ矤濮ｅ繑顐奸崙濠氭暛閸掓稑缂撻悪顒傜彌瀵ゆ儼绻滄禒璇插閿涘本鏁兼稉楦跨箖閺堢喐妞傞梻纾嬨€冮崝鐘插礋娑擃亪鍣撮弨鎯х暰閺冭泛娅掗敍宀勬娴ｅ孩绮︽總蹇旀閻ㄥ嫰鍣稿鍝勫竾閸旀稏鈧?- 闂婂啿鐓欑粣妤€褰涙０鍕劰閺€閫涜礋娴兼ê鍘涢柨顔荤秴妫板嫮鐣婚敍姘喘閸忓牓顣╅悜顓㈩浕/娑?閺堫偆娅ч柨顔衡偓浣峰敩鐞涖劑绮﹂柨顔兼嫲閸у洤瀵戦柌鍥ㄧ壉闁款喕缍呴敍宀勪缉閸忓秶些閸斻劎顏崚鍥╃崶閺冩湹绔村▎鈩冣偓褔顣╅悜顓熸殻缁愭ぜ鈧?- 閹靛婧€閺咁噣鈧岸銆夐崙蹇撶毌妫ｆ牕鐫嗙敮鎼佲敆閹稿洦鐖ｉ敍灞借嫙鐏忓棝鏁惄妯垮灦閸欐澘澧犵純顔煎煂闂婂啿鐓欑粣妤€褰涚紒鍡樺付娑斿澧犻敍宀冾唨閻劍鍩涢弴鏉戞彥鐟欙箒鎻稉缁樼川婵傚繐灏妴?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_sound_tools/piano.dart lib/src/ui/pages/toolbox_sound_tools/piano_state_logic.dart lib/src/ui/pages/toolbox_sound_tools/piano_state_ui.dart lib/src/ui/pages/toolbox_sound_tools/piano_models.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_sound_tools.dart`
- `flutter test test/toolbox_audio_bank_regression_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 閺嬩線鐝柅鐔哥拨婵傚繑妞傞敍灞芥倱娑撯偓閹稿洭鎷￠崷?26ms 閸愬懓娉曟潻鍥╂畱闁劌鍨庢稉顓㈡？鐟欙箑褰傛导姘愁潶閸氬牆鑻熼敍灞绢劀鐢摜鍋ｉ崙姹団偓浣告嫲瀵负鈧線鐓堕崺鐔峰瀼閹广垹鎷伴崗銊ョ潌鐠囶厺绠熸穱婵囧瘮娑撳秴褰夐妴?- 妫板嫮鍎圭粵鏍殣閺囩浜ら敍灞界毌閺佷即娼导妯哄帥闁款喕缍呮＃鏍偧鐟欙箑褰傞崣顖濆厴娴犲秹娓堕崡铏閸掓稑缂撻幘顓熸杹閸ｎ煉绱濇担鍡樻殻娴ｆ挸鍨忕粣妤€甯囬崝娑欐纯娴ｅ簺鈧?
## [Unreleased-PLAN_192-HARP-MOBILE-PERFORMANCE-CLEANUP] - 2026-05-21

### 閸樼喎娲?- 閻劍鍩涢崣宥夘洯瀹搞儱鍙跨粻渚库偓宀€鈹栭悘鐢电彨閻炴番鈧秵澧滈張铏诡伂闂堢偛鐖堕崡鈽呯礉楠炴湹绗栭弲顕€鈧岸銆夐棃顫繆閹垯绗岄幒褍鍩楁い鐟扮垻閸欑姵璐╂稊渚库偓?
### 娣囶喗鏁?- 鐏忓棛鐝悶纾嬪灦閸欎即鐝０鎴濆З閻㈣绮犻弫鎾€?`setState` 闁插秴缂撻弨閫涜礋 `CustomPaint` repaint notifier 妞瑰崬濮╅敍灞藉櫤鐏忔垶澹傚锕€鎷板锔藉盁閸斻劍妞傞惃?widget rebuild閵?- 娑撹櫣鐝悶纾嬪灦閸欐澘顤冮崝?`RepaintBoundary`閿涘苯鑻熺拋?Painter 娴ｈ法鏁ゆ潪濠氬櫤 `shouldRepaint`閿涘矂浼╅崗宥嗘￥瀹割喖鍩嗛崗銊╁櫤闁插秶绮妴?- 閺€鑸垫殐閹殿偄楦￠幏鏍х啲閺佷即鍣洪妴浣烘晸閸涜棄鎳嗛張鐔锋嫲鐟欙箑褰傞梻鎾閿涘瞼些闂勩倝鐝幋鎰拱濡紕纭﹂幏鏍х啲娑撳骸楦℃潏澶婂帨閿涘奔绻氶悾娆愭纯閸忓鍩楅惃鍕瀵箑寮芥＃鍫涒偓?- 鐏忓棙娅橀柅姘躲€夐棃顫厬閻ㄥ嫰鐓堕懝灞傗偓浣界殶瀵繈鈧礁鎷板锔衡偓浣瑰閹扮喓鐡戦梹鑳啎缂冾喖灏稉瀣焽閸掓壆骞囬張澶婄俺闁劏顔曠純顕€娼伴弶鍖＄礉妫ｆ牕鐫嗘穱婵堟殌閻樿埖鈧焦鎲崇憰浣碘偓浣峰瘜閼哥偛褰撮崪宀勭彯妫版垶鎼锋担婧库偓?- 缁旀牜鎯旈棅瀹犲妫板嫮鍎归弨閫涜礋娴兼ê鍘涙０鍕劰閸忔娊鏁锔跨秴娑撳骸缍嬮崜宥呮嫲瀵箑楦℃担宥忕礉闂勫秳缍嗘潻娑樺弳妞ょ敻娼伴崥搴ｆ畱缁夎濮╃粩顖氭倱濮濄儱甯囬崝娑栤偓?
### 妤犲矁鐦?- `dart format lib/src/ui/pages/toolbox_sound_tools/harp.dart lib/src/ui/pages/toolbox_sound_tools/harp_render.dart lib/src/ui/pages/toolbox_sound_tools/harp_config.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_sound_tools.dart`
- `flutter test test/toolbox_audio_bank_regression_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘穱婵堟殌閺冦垺婀侀棅鎶筋暥閹绢厽鏂侀妴浣瑰閸旇儻袝閸欐垯鈧浇鐨熷?閸滃苯楦?妫板嫯顔曠拠顓濈疅閿涙稖顫嬬憴澶庣罚閸忓绗岄幏鏍х啲濮ｆ梹妫悧鍫熸纯閸忓鍩楅妴?- 闂堢偤顩荤仦蹇氼啎缂冾噣銆嶉崗銉ュ經娴犲酣銆夐棃銏ゆ毐閸掓銆冮弨閫涜礋鎼存洟鍎撮棃銏℃緲閿涘瞼鏁ら幋閿嬫惙娴ｆ粏鐭惧鍕纯閻叏绱濇担鍡樻＋妞ょ敻娼伴崘鍛畱閻╁瓨甯撮幒褍鍩楅崠杞扮瑝閸愬秴鐖舵す璇茬潔缁€鎭掆偓?
## [Unreleased-PLAN_191-TOOLBOX-LIFE-TOOLS-PHASE1] - 2026-05-20

### Reason
- Add a new `toolbox.life_tools` submodule in Toolbox.
- Deliver a first-phase implementation for 37 requested practical-life tool entries.

### Added
- Added module registration for `toolbox.life_tools`:
  - `lib/src/core/module_system/module_id.dart`
  - `lib/src/core/module_system/module_registry.dart`
  - `lib/src/ui/module/module_access.dart`
- Added a new Toolbox home card entry:
  - `lib/src/ui/pages/toolbox/toolbox_page_content.dart`
  - `lib/src/ui/theme/toolbox_colors.dart`
- Added the new life tool hub and split page structure:
  - `lib/src/ui/pages/toolbox_life_tools.dart`
  - `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_display.dart`
  - `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart`
  - `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`

### Changed
- Toolbox now includes a dedicated "Life tool hub" entrance and independent routing for 37 life-tool entries.
- Added source attribution links for public/free/open resources referenced by the new life-tool entries.

### Validation
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_display.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_color.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page shows aggregated local tools"`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page opens life tool hub module"`

### Risk Changes
- This is a phase-1 delivery: all 37 tools now have independent entries; only a subset is implemented as local functional MVPs in this round.
- Some modules rely on external websites/resources and may be affected by network, availability, or third-party policy changes.

## [Unreleased-PLAN_190-FOCUS-BEATS-PALE-STAGE-NO-ANIMATION-OPTIONS] - 2026-05-20

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴缁夊娅庢稉鎾存暈閼哄倹濯挎稉顓犳畱閸斻劎鏁鹃柅澶愩€嶇拋鍓х枂閿涘矂浼╅崗宥佲偓婊冨З閻㈢粯鐗卞蹇娾偓婵嗘嫲閳ユ粌濮╅悽濠氱叾閼硅尪浠堥崝銊⑩偓婵堟埛缂侇厼鍏遍幍鐗堢壋韫囧啳濡幏宥勫▏閻劊鈧?
- 瑜版挸澧犻懜鐐插酱鐟欏棜顫庢禒宥呬焊濮楁瑦顥氶崪灞藉繁鐎佃鐦敍宀€鏁ら幋宄扮瑖閺堟稑濮╅悽缁樻殻娴ｆ挻娲垮ǎ锛勬閵嗕浇鍤滈悞韬测偓浣稿礂鐠嬪啩绗栨稉宥囩崐閸忊偓閵?

### 娣囶喗鏁?
- 鐏忓棔绗撳▔銊ㄥΝ閹峰秶娈戞搴㈢壐鐠佸墽鐤嗛崠鐑樻暪閸欙絼璐熼垾婊嗗Ν閹峰秹鐓堕懝娴嬧偓婵撶礉缁夊娅庨崣顖濐潌閻ㄥ嫯鍨堕崣鏉垮З閻㈠鈧瀚ㄩ妴浣稿З閻㈠鐓堕懝鑼朵粓閸斻劌绱戦崗鍐叉嫲娑撶粯甯堕崚璺哄隘閼辨柨濮╅悩鑸碘偓浣瑰絹缁€鎭掆偓?
- 閸氬本顒炵粔璇插З缁旑垯瀵岀拋鍓х枂閸栬桨绗屽▽澶嬭箞閹貉冨煑闂堛垺婢橀弬鍥攳閿涘苯褰х仦鏇犮仛瑜版挸澧犻懞鍌涘闂婂疇澹婇敍灞肩瑝閸愬秴鐫嶇粈鍝勫З閻㈢粯鐗卞蹇旀喅鐟曚降鈧?
- 鐏忓棜鍨堕崣鎷屽剹閺咁垬鈧浇寤洪柆鎾扁偓浣藉Ν閻愬箍鈧礁绐橀弽鍥ф嫲 HUD 閹垫寧澧仦鍌濈殶閺佺繝璐熸担搴ㄣ偙閸滃本娈╅惂鎴掔瑢濞村懘娅犻崷鐔剁秼缁紮绱濆鍗炲姒涙垼澹婇柆顔惧兊閸滃本顭跺Λ鏇㈢彯妤楀崬鎷伴崗澶嬫櫏閵?
- 缂佺喍绔?Painter 閻ㄥ嫬濮╅悽鏄忕殶閼硅绱濇担鍨坊閸欐彃濮╅悽缁樼亣娑撳彞绗夐崘宥呰埌閹存劖妲戦弰鎯ь樆鐟欏倸妯婂鍌︾礉鐟欏棜顫庢稉濠佺箽閹镐椒绔存總妤佺厤閸滃本璐伴惂鐣屾畱閼哄倹濯挎潪銊╀壕閵?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_sound_tools/focus.dart lib/src/ui/pages/toolbox_sound_tools/focus_state_logic.dart lib/src/ui/pages/toolbox_sound_tools/focus_state_stage.dart lib/src/ui/pages/toolbox_sound_tools/focus_state_stage_sections.dart lib/src/ui/pages/toolbox_sound_tools/focus_visualizer.dart lib/src/ui/pages/toolbox_sound_tools/focus_controls.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_sound_tools.dart`

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛崣顏囩殶閺?UI 鐏炴洜銇氶妴浣藉灦閸欑増澹欓幍妯虹湴閸?Painter 鐟欏棜顫庨崣鍌涙殶閿涘奔绗夋穱顔芥暭閼哄倹濯?transport閵嗕線鐓舵０鎴炴尡閺€淇扁偓浣叫曢幇鐔恍曢崣鎴欌偓浣镐焊婵傝姤瀵旀稊鍛閹存牜濮搁幀浣规簚鐠囶厺绠熼妴?
- 閺冄冧焊婵傛垝鑵戞穱婵嗙摠閻ㄥ嫬濮╅悽缁樼壉瀵繋绮涙导姘箽閻ｆ瑥婀崘鍛村劥閻樿埖鈧線鍣烽敍灞肩稻閸ョ姳璐熼崣顖濐潌鐠佸墽鐤嗛崗銉ュ經瀹歌尙些闂勩倓绗?Painter 缂佺喍绔寸憴鍡氼潕鐠囶叀鈻堥敍宀€鏁ら幋铚傛櫠娑撳秴鍟€閹扮喓鐓℃稉鍝勫讲闁濮╅悽缁樼壉瀵繈鈧?

## [Unreleased-PLAN_189-FOCUS-BEATS-AUDIO-VISUAL-SYNC-WARMSTAGE] - 2026-05-20

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯娑撴挻鏁為懞鍌涘閻ㄥ嫬濮╅悽璁崇瑢閹绢厽鏂佹竟浼寸叾娑斿妫块張澶嬫閺勫彞绗栨稉宥堝殰閻掑墎娈戦幇鐔虹叀瀵ゆ儼绻滈妴?
- 瑜版挸澧犻懜鐐插酱閼冲本娅欐禒宥呬焊閸愮柉澹婇敍灞芥嫲娑撴挻鏁為懞鍌涘閻ㄥ嫰鏆遍張鐔峰殞鐟欏棎鈧胶菙鐎规艾鎳犻崥姝屽Ν婵傚繋绗夋径鐔诲垱閸氬牄鈧?

### 娣囶喗鏁?
- 閸︺劋绗撳▔銊ㄥΝ閹?Painter 娑擃厼濮為崗銉х叚鐢呴獓婢规壆鏁鹃崥灞绢劄鐞涖儱浼╅敍宀冾唨鏉炪劑浜鹃幒銊ㄧ箻閵嗕浇濡悙褰掔彯娴滎喖鎷伴崘鎻掑毊閸忓鏅ョ粙宥呮倵闁插﹥鏂侀敍宀冨垱鏉╂垵鐤勯梽鍛儔閸掓壆鍋ｉ崙璇诧紣閻ㄥ嫭妞傞崚姹団偓?
- 鐏忓棜鍨堕崣鎷屽剹閺咁垯绗屾潏鍦櫕閼瑰弶鏆ｆ担鎾圭殶閺佺繝璐熼弳鏍ㄦ濡洏鈧胶鎯€閻濃偓閸滃本娈╅悘棰佺秼缁紮绱濋崙蹇撶毌閸愮柉澹婄粔鎴炲Η閹扮喆鈧?
- 閸氬本顒為弨璺哄經閼哥偛褰存径鏍х湴闂堛垺婢橀妴浣界珶濡楀棔绗岄梼鏉戝閿涘奔濞囨稉鏄忓灦閸欑増娲跨紒鐔剁閸︾増澹欓幍妯垮Ν閹峰秷寤洪柆鎾扁偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_sound_tools/focus_visualizer.dart lib/src/ui/pages/toolbox_sound_tools/focus_state_stage.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_sound_tools.dart`

### 妞嬪酣娅撻崣妯绘纯
- 鏉╂瑦顐奸崣顏呮暭鐏炴洜銇氱仦鍌滄畱閻╅晲缍呯悰銉ヤ缉閸滃矁鍎楅弲顖濆閿涘奔绗夐弨纭呭Ν閹?transport閵嗕線鐓舵０鎴炴尡閺€淇扁偓浣叫曢幇鐔恍曢崣鎴欌偓浣瑰瘮娑斿懎瀵查幋鏍Ц閹焦娼靛┃鎰┾偓?
- 婵″倹鐏夌拋鎯ь槵闂婃娊顣舵潏鎾冲毉缂傛挸鍟块弰鎹愭啿妤傛ü绨惌顓炴姎鐞涖儱浼╅敍灞肩矝閸欘垵鍏橀棁鈧憰浣烘埛缂侇厼浜曠拫鍐夐崑鍧楁毐鎼达讣绱濇担鍡楃秼閸撳秴鐤勯悳鏉垮嚒閹跺﹨顫嬬憴澶嬪鐠烘垵甯囨担搴″煂閺囩鍤滈悞鍓佹畱閼煎啫娲块妴?

## [Unreleased-PLAN_188-FOCUS-BEATS-RHYTHM-STAGE-REDESIGN] - 2026-05-20

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴闁插秵鏌婄拋鎹愵吀瀹搞儱鍙跨粻渚库偓灞肩瑩濞夈劏濡幏宥冣偓宥囨畱閼哄倸顨旂仦鏇犮仛娑撳氦鍨堕崣鏉垮З閻紮绱濈拋鈺勵潒鐟欏绗岄懞鍌涘閸忓疇浠堥弴瀛樻绾噯绱濋獮鏈电瑬娑撳秷顩﹀▽璺ㄦ暏瑜版挸澧犻弫鍫熺亯閵?
- 閸樼喕鍨堕崣鏉垮З閻㈢粯娲块崑蹇擃樋缁夊秵瀚欓悧鈺傛櫏閺嬫粌鑻熼崚妤嬬礉閹峰秶鍋ｉ妴渚€鍣搁幏宥冣偓浣哥摍閹峰秴鎷板顏嗗箚濞堜絻鎯ゆ稊瀣？閻ㄥ嫬鍙х化璁崇瑝婢剁喖娉︽稉顓炲讲鐟欏棗瀵查妴?

### 娣囶喗鏁?
- 闁插秴鍟撴稉鎾存暈閼哄倹濯块懜鐐插酱 Painter閿涙碍鏁兼稉铏圭埠娑撯偓閻ㄥ嫨鈧矁濡幏宥堝缓闁挶鈧秶閮寸紒鐕傜礉娑撶粯濯挎稉楦垮缓闁挸銇囬懞鍌滃仯閵嗕礁鐡欓幏宥勮礋閼哄倻鍋ｉ梻鏉戝煝鎼达负鈧礁缍嬮崜宥嗗閻愯閮ㄩ梻顓犲箚鏉炪劑浜鹃幒銊ㄧ箻閵?
- 鐏忓棝鍣搁幏宥冣偓浣诡唽閽€鍊熸崳閻愬箍鈧焦娅橀柅姘閸滃苯鐡欓幏宥嗘Ё鐏忓嫪璐熸稉宥呮倱瀵搫瀹抽惃鍕帨閺呮洏鈧礁鍩㈡惔锕€鎷版潪銊ㄦ姉閸欏秹顩敍灞藉繁閸栨牑鈧粌鎯夐崚鎵畱閹峰秶鍋ｉ垾婵嗘嫲閳ユ粎婀呴崚鎵畱閹峰秶鍋ｉ垾婵嗘倱濮濄儱鍙х化姹団偓?
- 閺€鑸垫殐缁夎濮╃粩顖欏瘜閼哥偛褰寸憰鍡欐磰鐏炲偊绱濈粔濠氭珟閸掑棙鏆庣憗鍛淬偘閿涘本鏁兼稉楦垮缓闁挾濮搁幀浣碘偓浣峰瘜閹?鐎涙劖濯块弶鈥虫嫲濞堜絻鎯ら弶锛勬畱鏉炲鍣烘穱鈩冧紖鐏炲倶鈧?
- 閺囧瓨鏌婃稉鎾存暈閼哄倹濯块崝銊ф暰閺嶅嘲绱￠崨钘夋倳娑撳氦顕╅弰搴礉娴犲孩妫幏鐔哄⒖閻椻晙娆㈢拠顓濈疅鏉烆兛璐熸潪銊╀壕閵嗕胶骞嗙痪瑁も偓浣瑰皾瑜邦潿鈧礁鍩㈡惔锕€鎷板銉╂█缁涘濡總蹇氥€冩潏淇扁偓?
- 濞撳懐鎮婃稉鎾存暈閼哄倹濯块懜鐐插酱閺傚洣娆㈡稉顓犳畱娑撳秴褰叉潏鐐＋鐏炴洜銇氭禒锝囩垳閿涘奔濞囩拠銉ョ潔缁€鍝勭湴閺傚洣娆㈤崶鐐插煂 1000 鐞涘奔浜掗崘鍛偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_sound_tools/focus_visualizer.dart lib/src/ui/pages/toolbox_sound_tools/focus_state_stage.dart lib/src/ui/pages/toolbox_sound_tools/focus_state_logic.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_sound_tools.dart`

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒鍛扮殶閺?UI閵嗕赋ainter閵嗕焦鐗卞蹇撴嫲鐏炴洜銇氶弬鍥攳閿涘奔绗夋穱顔芥暭閼哄倹濯?transport閵嗕線鐓舵０鎴炴尡閺€淇扁偓浣叫曢幇鐔恍曢崣鎴欌偓浣瑰瘮娑斿懎瀵查崪灞肩瑹閸旓紕濮搁幀浣规降濠ф劑鈧?
- 閼哥偛褰寸憴鍡氼潕鐠囶厺绠熸禒搴☆樋閹风喓澧块崝銊ф暰閺€鑸垫殐娑撹櫣绮烘稉鈧懞鍌涘鏉炪劑浜鹃敍宀€鏁ら幋宄邦嚠閺冄冨З閻㈣鎳￠崥宥囨畱鐠佹澘绻傞悙閫涚窗閸欐ê瀵查敍灞肩稻閼哄倹濯跨拋鍓х枂閸滃矂鐓堕懝鏌モ偓澶嬪閸忋儱褰涙穱婵囧瘮娑撳秴褰夐妴?

## [Unreleased-PLAN_187-HUMAN-TESTS-SETTINGS-FIRST-COLLAPSE-STYLE] - 2026-05-20

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴閸忓牊褰佹禍銈呯秼閸撳秳鍞惍浣割槵娴犳枻绱濋崘宥咁嚠娴滆櫣琚ù瀣槸娑擃厼绺鹃崥鍕摍濡€虫健閸嬫矮绔存潪顔款潐閺佹潙瀵查妴?
- 婢舵矮閲滄禍铏硅濞村鐦€涙劙銆夋禒宥嗗Ω鐠佸墽鐤嗛柅澶愩€嶉弨鎯ф躬娑撴槒鍨堕崣鐗堝灗閹垮秳缍旈崠杞扮瑓閺傜櫢绱濈粔璇插З缁旑垳鏁ら幋鐑芥付鐟曚礁鍘涚搾濠呯箖閼哥偛褰撮幍宥堝厴閹垫儳鍩岄崣鍌涙殶閸忋儱褰涢妴?
- 閸忓彉闊╅幎妯哄綌鐠佸墽鐤嗛崠铏规畱鐏炴洖绱?閺€鎯版崳 affordance 娑撳秴顧勯弰搴㈡▔閿涘苯鎷伴垾婊嗩啎缂冾喖褰查幎妯哄綌閳ユ繄娈戠憴鍡氼潕妫板嫭婀℃稉宥呭爱闁板秲鈧?

### 娣囶喗鏁?
- 瀹告彃鐣幋鎰槵娴犺姤褰佹禍?`df7d5b2 chore: backup current toolbox and human tests work`閵?
- 瀵搫瀵?`_HumanSettingsSection` 閸忓彉闊╅弽宄扮础閿涙碍鏌婃晶鐐额啎缂冾喖娴橀弽鍥ㄥ閹垫ǜ鈧礁鐫嶅鈧幀渚€鐝禍顔跨珶濡楀棎鈧礁娓捐ぐ銏㈩唲婢跺瓨瀵滈柦顔衡偓浣搞仈闁劌绨抽懝鎻掓嫲閺囧菙鐎规氨娈戠仦鏇炵磻閸掑棝娈х仦鍌樷偓?
- 鐏忓棙澧滈柅鐔粹偓浣虹€崙鍡愨偓浣告儔鐟欏鈧礁濮╅幀浣筋潒閸旀稏鈧浇顫嬬憴澶嬫偝缁鳖潿鈧焦瀚嬮幏濮愨偓浣稿蓟娴犺濮熼崚鍥ㄥ床閵嗕礁寮婚幍瀣礂鐠嬪啨鈧浇澹婄憴澶堚偓浣筋潒鐟欏顔囪箛鍡愨偓浣哥碍閸掓顔囪箛鍡愨偓浣规殶鐎涙顔囪箛鍡愨偓浣界槤濮瑰洩顔囪箛鍡愨偓浣瑰ⅵ鐎涙ぜ鈧礁寮芥惔鏂挎嫲婢规澘顒熺€圭偤鐛欑粵澶愩€夐棃顫厬閻ㄥ嫯顔曠純顔煎隘娑撳﹦些閸掗瀵岄懜鐐插酱閸撳秲鈧?
- 婢规澘顒熺€圭偤鐛欓惃鍕櫚閺嶉攱瀵氶崡妤€鎷伴柌鍥肠鐠囧﹥鏌囬崜宥囩枂閸掓澘鐤勯弮璺猴紣鐎涳箒鍨堕崣棰佺瑐閺傜櫢绱濇穱婵囧瘮妤癸箑鍘犳搴ㄥ櫚闂嗗棎鈧浇鐦栭弬顓炵磻閸忓啿鎷伴幎銉ユ啞鐠侊紕鐣婚柅鏄忕帆娑撳秴褰夐妴?
- 閺囧瓨鏌婃禍铏硅濞村鐦?smoke 娑擃厼褰堢拋鍓х枂閸栬桨绗傜粔璇插閸濆秶娈戠€规矮缍呴弬鐟扮础閿涘矂浼╅崗宥囧仯閸掓媽鍨堕崣棰佺瑓閺傝膩瀵繐鍙嗛崣锝嗘鐞氼偅绮撮崝銊ょ秴缂冾喖濂栭崫宥冣偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_*.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_human_tests.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "human tests hub exposes the new visual auditory and coordination modules"`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 鐠佸墽鐤嗛崠杞扮秴缂冾喖褰夐崠鏍︾窗閺€鐟板綁闁劌鍨?widget 濞村鐦惃鍕泊閸斻劏鎯ら悙鐧哥幢閺堫剝鐤嗗鎻掓倱濮濄儴鐨熼弫瀵告窗閺?smoke 閻ㄥ嫭鐓￠幍鐐煙瀵繈鈧?
- 閹舵ê褰旈崡锛勫閺嶅嘲绱℃稉鍝勫彙娴滎偆绮嶆禒璺哄綁閺囪揪绱濇导姘閸濆秵澧嶉張澶夋眽缁粯绁寸拠鏇☆啎缂冾喖灏惃鍕潒鐟欏銆冮悳甯礉娴ｅ棙婀弨鐟板綁閸氬嫰銆夐棃銏㈡畱閻樿埖鈧焦娼靛┃鎰┾偓浣筋吀閺冭翰鈧浇绶崗銉ｂ偓浣瑰Г閸涘﹤鎷版稉姘閸掋倖鏌囬妴?

## [Unreleased-PLAN_186-ACOUSTIC-LAB-CAPTURE-REDESIGN] - 2026-05-20

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯瀹搞儱鍙跨粻?娴滆櫣琚ù瀣槸娑擃厼绺?婢规澘顒熺€圭偤鐛欑€瑰苯鍙忔稉宥呭讲閻㈩煉绱伴幍鎾崇磻妤癸箑鍘犳搴¤嫙閸欐垵锛愰崥搴濈矝閻╂垶绁存稉宥呭煂娴犺缍嶆竟浼寸叾閵?
- 閻滅増婀佹竟鏉款劅鐎圭偤鐛欐い鍨Ω闁插洦鐗辩拠瀛樻閵嗕礁鐤勯弮鑸靛瘹閺嶅洢鈧浇鐦栭弬顓濅繆閹垰鎷伴幎銉ユ啞閸忋儱褰涘ǎ宄版躬閸氬奔绔寸仦鍌滈獓閿涘瞼些閸斻劎顏＃鏍х潌闂呭彞浜掗崚銈嗘焽閻樿埖鈧礁鎷版稉瀣╃濮濄儯鈧?

### 娣囶喗鏁?
- 婢规澘顒熺€圭偤鐛欒ぐ鏇㈢叾闁板秶鐤嗛弨閫涜礋缁嬪啿鐣炬潏鎾冲弳娴兼ê鍘涢敍姘剁帛鐠併倓绮犵化鑽ょ埠閹恒劏宕樻ス锕€鍘犳搴ょ翻閸忋儱绱戞慨瀣剁礉閸愬秴娲栭柅鈧弽鍥у櫙妤癸箑鍘犳搴涒偓浣筋嚔闂婂疇鐦戦崚顐㈠悑鐎硅膩瀵繐鎷伴崢鐔奉潗妤癸箑鍘犳搴涒偓?
- 閸氼垰濮╅柧鎹愮熅閺傛澘顤冮垾婊勬箒閺佸牆锛愰棅鍏呬繆閸欏皝鈧繂鍨界€规熬绱伴弮?PCM 鐢勫灗鏉╃偟鐢婚弫鏉跨摟闂堟瑩鐓堕弮鏈电窗閼奉亜濮╅崚鍥ㄥ床閸掗绗呮稉鈧稉顏囩翻閸忋儲绨敍灞肩瑝閸愬秴浠犻悾娆忔躬閳ユ粌缍嶉棅鍐插嚒閸氼垰濮╂担鍡樼梾閺堝锛愰棅鏂モ偓婵堟畱閸嬪洦鍨氶崝鐔哄Ц閹降鈧?
- 閺傛澘顤?`record` 楠炲懎瀹冲ù浣稿幑鎼存洘妯夌粈鐚寸窗瑜?PCM 鐢呯叚閺嗗倷绗夐崣顖滄暏娴ｅ棛閮寸紒鐔剁矝閼冲€熺箲閸ョ偛绠欐惔锔芥閿涘矂銆夐棃顫矝閸欘垰鐫嶇粈鍝勭杽閺?dBFS閵嗕胶鏁搁獮铏锤缁惧灝鎷伴崺铏诡攨閺嶉攱婀伴妴?
- 婢规澘顒熺€圭偤鐛欐稉璇插幢闁插秴浠涙稉鐑樐佸蹇涒偓澶嬪閵嗕礁鐤勯弮鎯扮翻閸忋儴鍨堕崣鑸偓浣峰瘜閹垮秳缍旈妴浣圭壋韫囧啯瀵氶弽鍥モ偓浣瑰Г閸涘﹥鎲崇憰浣碘偓渚€鍣伴弽閿嬪瘹閸楁鎷伴柌鍥肠鐠囧﹥鏌囬惃鍕瀻鐏炲倻绮ㄩ弸鍕┾偓?
- 闁插洭娉︾拠濠冩焽閺傛澘顤冮垾婊冨悑鐎圭绶崗銉ょ喘閸忓牃鈧繂绱戦崗绛圭礉娓氬じ绨惇鐔告簚娑撳﹣绱崗鍫滃▏閻劏顕㈤棅瀹犵槕閸掝偉绶崗銉х搏鏉╁洩顔曟径鍥叾濠ф劕鍚嬬€瑰綊妫舵０妯糕偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_auditory_lab.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_human_tests.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "human tests hub exposes the new visual auditory and coordination modules"`
- 妫版繂顦荤亸婵婄槸鏉╂劘顢戠€瑰本鏆?`test/toolbox_human_tests_extended_smoke_test.dart`閿涘苯缍嬮崜宥堫潶閺冦垺婀侀崝銊︹偓浣筋潒閸旀稓鏁ゆ笟瀣▎閺傤叏绱癭dynamic vision symbol mode exposes sets paths and report` 閸?`scrollUntilVisible` 闂冭埖顔岄幍鍙ョ瑝閸?scrollable閵?

### 妞嬪酣娅撻崣妯绘纯
- 姒涙顓绘潏鎾冲弳閺囨潙浜搁崣顖滄暏閹嶇礉闁劌鍨庣拋鎯ь槵娑撳﹦娈戦懛顏勫З婢х偟娉崣顖濆厴瑜板崬鎼风紒婵嗩嚠閻㈤潧閽╅崣顖涚槷閹嶇幢閹躲儱鎲℃禒宥呯暰娴ｅ秳璐熼崥宀冾啎婢跺洨绮屾稊鐘偓浣哄箚婢у啳顫囩€电喎鎷伴崜宥呮倵鐎佃鐦敍灞肩瑝娴ｆ粈璐熼崠璇差劅閹存牔绗撴稉姘紣缁狙嗩吀缂佹挻鐏夐妴?
- 閼汇儳閮寸紒鐔洪獓閺夊啴妾洪妴渚€娈ｇ粔浣哥磻閸忕偨鈧線鈧俺鐦?瑜版洖鐫嗛崡鐘垫暏閹存牞鎽戦悧娆掔熅閻㈤亶妯嗛弬顓濈啊閹碘偓閺堝绶崗銉︾爱閿涘矂銆夐棃顫窗閺勫海鈥橀幎銉╂晩楠炶埖褰佺粈鐑橆梾閺屻儳閮寸紒鐔活啎缂冾喓鈧?

## [Unreleased-PLAN_185-PERMISSION-CONSENT-GUARDRAILS] - 2026-05-19

### 閸樼喎娲?
- 娑撴挻鏁?閺€鐐緱瀵板懎濮欓幓鎰板晪娴兼艾婀崥搴″酱閸掓稑缂撶化鑽ょ埠缁狙勫絹闁辨帪绱濇担鍡欏箛閺堝绁︾粙瀣梾閺堝婀＃鏍偧娴ｈ法鏁ら崜宥嗘绾喛顕╅弰搴礉娑旂喓宸辩亸鎴濆讲閸︺劏顔曠純顕€鍣烽崗鎶芥４閻ㄥ嫮绮烘稉鈧鈧崗鐐解偓?
- 娴滆櫣琚ù瀣槸娑擃厼绺炬竟鏉款劅鐎圭偤鐛欐导姘冲殰閸斻劏顕伴崣鏍ц嫙娣囶喗鏁肩化鑽ょ埠婵帊缍嬮棅鎶藉櫤閿涘奔绲鹃悳鐗堟箒濞翠胶鈻煎▽鈩冩箒閸︺劋濞囬悽銊ュ缂佹瑥鍤弰搴ｂ€橀幓鎰仛閿涘奔绡冪紓鍝勭毌缁備胶鏁ら崥搴″晙瀵洖顕辫箛顐ｅ祹瀵偓閸氼垳娈戦崗銉ュ經閵?

### 娣囶喗鏁?
- 閺傛澘顤冮垾婊冪窡閸旂偟閮寸紒鐔稿絹闁辨巻鈧繂鎷伴垾婊冿紣鐎涳附绁寸拠鏇″殰閸斻劏鐨熼弫瀵搁兇缂佺喖鐓堕柌蹇娾偓婵呰⒈妞よ瀵旀稊鍛瀵偓閸忕绱濇妯款吇閸忔娊妫撮妴?
- 娑撴挻鏁炲鍛缂傛牞绶崳銊ユ躬閸忔娊妫寸化鑽ょ埠閹绘劙鍟嬮弮鏈电窗閺勫墽銇氶悪顒傜彌鐠囧瓨妲戦崡鈽呯礉楠炶埖褰佹笟娑樻彥閹瑰嘲绱戦崥顖涘瘻闁筋噯绱卞鈧崥顖氭倵閸愬秶鎴风紒顓¤泲闁氨鐓￠弶鍐/缁墽鈥橀梻褰掓寭閹绘劗銇氶妴?
- 婢规澘顒熷ù瀣槸闂婃娊鍣洪崡鈥虫躬閸忔娊妫撮懛顏勫З鐠嬪啴鐓堕弮鏈电窗閸忓牊妯夌粈楦款嚛閺勫骸宕辨稉搴℃彥閹瑰嘲绱戦崥顖涘瘻闁筋噯绱卞鈧崥顖氭倵閹靛秳绱扮紒褏鐢荤拠璇插絿娑撳氦鍤滈崝銊ㄧ殶閺佸閮寸紒鐔肩叾闁插繈鈧?
- 鐠佸墽鐤嗘稉顓炵妇閺傛澘顤冮垾婊勬綀闂勬劒绗岀化鑽ょ埠閹垮秳缍旈垾婵嗗瀻缂佸嫸绱濋梿鍡曡厬閹貉冨煑娑撱倝銆嶉懗钘夊閻ㄥ嫬鎯庨悽銊ょ瑢缁備胶鏁ら妴?
- `FocusService` 閸︺劍鈧绱戦崗鍐插彠闂傤厽妞傛稉宥呭晙闂堟瑩绮崚娑樼紦閺堫剙婀撮幓鎰板晪閿涘苯鑻熼崷銊ュ彠闂傤厼鎮楀〒鍛倞閺堫剙婀撮幓鎰板晪閸氬本顒為妴?

### 妤犲矁鐦?
- `flutter test test/settings_service_test.dart`
- `flutter test test/focus_service_test.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "human tests hub exposes the new visual auditory and coordination modules"`
- `flutter analyze`閿涘牅绮涢張澶夌波鎼存挻妫﹂張?warning/info閿涙稒婀版潪顔芥煀婢х偟娈戦幎鍊熻杽閹存劕鎲抽柨娆掝嚖瀹歌弓鎱ㄦ径宥忕礉瑜版挸澧犻弮鐘虫煀婢?error閿?

### 妞嬪酣娅撻崣妯绘纯
- 閺傛壆鏁ら幋宄版嫲閸楀洨楠囬悽銊﹀煕姒涙顓婚柈浠嬫付鐟曚礁鍘涢幍瀣З瀵偓閸氼垵绻栨稉銈夈€嶇化鑽ょ埠缁狙嗗厴閸旀冻绱濋弮褏娈戦張顒€婀撮幓鎰板晪娑撳秳绱伴懛顏勫З瀵ゅ墎鐢婚敍灞界潣娴滃孩婀侀幇蹇曟畱閺夊啴妾洪弨璺哄經閵?

## [Unreleased-PLAN_184-TOOLBOX-MOBILE-DRAG-AND-BACK-FIX] - 2026-05-19

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯瀹搞儱鍙跨粻閬嶎浕妞ゅ灚娼惄顔绢吀閻炲棗婀幍瀣簚閻喐婧€娑撳﹣绗?PC 鐞涖劎骞囨稉宥勭閼疯揪绱伴張顏堟毐閹稿妞傚鎴濆З鐏炲繐绠锋稊鐔剁窗鐠囶垵袝閹锋牕濮╅妴浣虹椽鏉堟垶鈧焦婢楅幍瀣倵娴ｅ秶鐤嗘稉宥嚽旂€规哎鈧浇绻戦崶鐐烘暛娴兼氨娲块幒銉┾偓鈧崙鍝勭安閻劏鈧奔绗夐弰顖氬帥闁偓閸戣櫣绱潏鎴災佸蹇嬧偓?

### 娣囶喗鏁?
- 瀹搞儱鍙跨粻閬嶎浕妞ゅ灚娅橀柅姘偓浣烘畱韫囶偅宓庨崗銉ュ經閹锋牗瀚块弨閫涜礋闂€鎸庡瘻鐟欙箑褰傞敍宀勪缉閸忓秵澧滈幐鍥ㄧ泊閸斻劌鍨悰銊︽閹跺﹥娼惄顔炬纯閹恒儲瀚嬬挧鏋偓?
- 瀹搞儱鍙跨粻杈╃椽鏉堟垶鈧胶娈戦幒鎺戠碍閹靛鐒洪弨閫涜礋闂€鎸庡瘻閸氬骸鍟€閹锋牕濮╅敍灞借嫙缁夊娅庨弫鏉戝幢闂€鎸庡瘻閹锋牕鍙嗚箛顐ｅ祹閸忋儱褰涙稉搴ㄥ櫢閹烘帗澧滈崝璺ㄦ畱缁旂偘绨ら敍灞肩喘閸忓牅绻氱拠浣盒╅崝銊ь伂闁插秵甯撶粙鍐茬暰閽€鎴掔秴閵?
- 瀹搞儱鍙跨粻閬嶃€夐幒銉ュ弳 `PopScope`閿涙氨绱潏鎴災佸蹇庣瑓閹稿绻戦崶鐐扮窗閸忓牓鈧偓閸戣櫣绱潏鎴災佸蹇ョ礉閸愬秵浠径宥嗘珮闁岸顩绘い鐐光偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_page.dart lib/src/ui/pages/toolbox/toolbox_page_widgets.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page supports editable home layout"`

### 妞嬪酣娅撻崣妯绘纯
- 缂傛牞绶幀浣风瑝閸愬秵鏁幐浣烘纯閹恒儲瀚嬮弫鏉戠炊閸楋紕澧栭崚鏉挎彥閹瑰嘲鍙嗛崣锝呭隘閿涙稑顩ч棁鈧粻锛勬倞韫囶偅宓庨崗銉ュ經閿涘苯褰查崷銊︽珮闁碍鈧線鏆遍幐澶嬪珛閸忋儻绱濋幋鏍﹀▏閻劑銆婇柈?`Manage` 闂堛垺婢橀妴?

## [Unreleased-PLAN_183-HUMAN-TESTS-ORDER-DYNAMIC-VISION-LINK-MATCH] - 2026-05-19

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿閹跺﹤浼愰崗椋庮唸-娴滆櫣琚ù瀣槸娑擃厼绺鹃惃鍕浕鐏炲繑膩閸ф銆庢惔蹇氱殶閺佹潙绶遍弴纾嬪垱鏉╂垵鐖堕悽銊ょ喘閸忓牏楠囬敍灞藉蓟閸掓绔风仦鈧稉瀣帥閻鍩岄崣宥呯安閵嗕浇顫嬬憴澶庮唶韫囧棎鈧礁濮╅幀浣筋潒閸旀稏鈧焦鎲為弶鍡楀礂鐠嬪啰鐡戦弽绋跨妇濡€虫健閵?
- 閻劍鍩涚敮灞炬箿閸斻劍鈧浇顫嬮崝娑滅箻閸忋儱鎮楁妯款吇閻╁瓨甯寸仦鏇犮仛閳ユ粌鐨悶鍐╂殶闁插繆鈧繃膩瀵骏绱濋懓灞肩瑝閺勵垰鍘涢拃钘夋躬鐎涙顑佺拠鍡楀焼閵?
- 閻劍鍩涢崣宥夘洯鐟欏棜顫庨幖婊呭偍鏉╃偠绻涢惇瀣躬閸戣櫣骞囬惄绋挎倱婢舵牞顫囬崗鍐閺冭绱濇禒宥呭讲閼宠棄娲滄稉鍝勫敶闁劑鍘ょ€靛湱绱崣铚傜瑝閸氬矁鈧苯鍨界€规矮绗夐懗钘夊爱闁板稄绱濇潻娆忔嫲閻溾晛顔嶉惇瀣煂閻ㄥ嫧鈧粌鐣犳禒顒佹閺勫簼绔撮弽灏佲偓婵呯瑝娑撯偓閼锋番鈧?

### 娣囶喗鏁?
- 鐠嬪啯鏆ｆ禍铏硅濞村鐦稉顓炵妇姒涙顓婚崣灞藉灙閸忋儱褰涙い鍝勭碍閿涘苯澧犻幒鎺嶇喘閸忓牆鐫嶇粈鐚寸窗閸欏秴绨查妴浣筋潒鐟欏顔囪箛鍡愨偓浣稿З閹浇顫嬮崝娑栤偓浣规啚閺夊棗宕楃拫鍐︹偓浣瑰閻厧宕楃拫鍐︹偓浣藉鐟欏绁寸拠鏇樷偓浣哥碍閸掓顔囪箛鍡愨偓渚€绮﹂悮鈺冨皰濞村鐦妴浣规焿閻楀綊鐬鹃弲顔衡偓浣稿蓟閹靛宕楃拫鍐︹偓浣界箥濮樻梹绁寸拠鏇樷偓浣规闂傚瓨鍔呴惌銉ｂ偓浣虹€崙鍡欑搼濡€虫健閵?
- 閸斻劍鈧浇顫嬮崝娑㈢帛鐠併倖膩瀵繑鏁兼稉琛♀偓婊冪毈閻炲啯鏆熼柌蹇娾偓婵撶礉鏉╂稑鍙嗘い鐢告桨閸氬酣顩荤仦蹇曟纯閹恒儱鐫嶇粈鍝勵嚠鎼存棁顔曠純顔荤瑢閼哥偛褰寸拠瀛樻閿涙稑鐡х粭锕佺槕閸掝偅膩瀵繋绮涙穱婵堟殌閸樼喐婀侀崝鐔诲厴閸滃苯鍨忛幑銏犲弳閸欙絻鈧?
- 娣囶喖顦茬憴鍡氼潕閹兼粎鍌ㄦ潻鐐剁箾閻鍘ょ€电懓鍨界€规熬绱版禒搴″敶闁?`pairId` 閸栧綊鍘ら弨閫涜礋閸╄桨绨悽銊﹀煕閸欘垵顫嗛惃鍕禈濡楀牅绗屾０婊嗗婢舵牞顫囬崠褰掑帳閿涘矂浼╅崗宥囨祲閸氬苯鍘撶槐鐘叉礈閸愬懘鍎寸紓鏍у娇娑撳秴鎮撻懓宀冾嚖閸掋們鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision.dart lib/src/ui/pages/toolbox_human_tests_visual_search.dart test/toolbox_human_tests_extended_smoke_test.dart test/ui_smoke_test.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "human tests hub exposes the new visual auditory and coordination modules"`
- `flutter test test/ui_smoke_test.dart --plain-name "dynamic vision exposes ball count mode and settings"`

### 妞嬪酣娅撻崣妯绘纯
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃崗銉ュ經閹烘帒绨禒宥嗘Ц妞ょ敻娼伴崘鍛寸帛鐠併倝銆庢惔蹇ョ幢閻劍鍩涢梹鎸庡瘻閹锋牕濮╅崥搴ｆ畱娴兼俺鐦介崘鍛笓鎼村繗顢戞稉杞扮瑝閸欐﹫绱濋柌宥嗘煀鏉╂稑鍙嗘い鐢告桨閸氬簼绮涙导姘礀閸掔増鏌婇惃鍕帛鐠併倝銆庢惔蹇嬧偓?
- 鏉╃偠绻涢惇瀣秼閸撳秵濡搁垾婊冨讲鐟欎礁顦荤憴鍌欑閼风补鈧繆顫嬫稉鍝勬倱缁鍘撶槐鐙呯礉鐟欏嫬鍨弴纾嬪垱鏉╂垹鏁ら幋閿嬪妳閻儻绱遍懟銉ユ倵缂侇厼绱╅崗銉︽纯婢跺秵娼呴惃鍕倱閸ュ彞绗夐崥灞界湴閺堝搫鍩楅敍宀勬付鐟曚礁鎮撳銉ㄋ夐崗鍛煀閻ㄥ嫯顫嬬憴澶婂隘閸掑棜顕㈡稊澶堚偓?

## [Unreleased-PLAN_182-SOUND-LOCATOR-MOBILE-MOVE] - 2026-05-19

### 閸樼喎娲?
- 瀹搞儱鍙跨粻杈╁繁鐏忔垿娼伴崥鎴濐槻閺夊倻骞嗘晶鍐畱婢圭増绨€规矮缍呭銉ュ徔閿涙稓鏁ら幋鐑芥付濮瑰倸瀵橀崥顐㈩樋婢圭増绨涵顔款吇閵嗕胶鐝涙担鎾垛敄闂傚瓨瀵氬鏇炴嫲閸ョ偛鎼烽崷鐑樻珯閿涘瞼娲块幒銉ょ矤闂嗚泛鐤勯悳棰佺瑩娑撴氨楠囬梼闈涘灙鐎规矮缍呮搴ㄦ珦鏉╁洭鐝妴?
- 娴溠冩惂娑撴槒顩︽潻鎰攽閸︺劍澧滈張铏诡伂閿涘矂娓剁憰浣盒╅梽銈傗偓婊冾樆閹恒儱鎮撳銉╁閸忓顥撻梼闈涘灙閳ユ繀璐熼崜宥嗗絹閻ㄥ嫯銆冩潏鎾呯礉閺€閫涜礋闁俺绻冮幍瀣簚閼奉亜鐢ス锕€鍘犳搴℃嫲婢舵矮缍呯純顔拘╅崝銊╁櫚閺嶉鈥樼拋銈咃紣濠ф劕灏崺鐔粹偓?

### 閺傛澘顤?
- 閺傛澘顤冨銉ュ徔缁犳墎鈧粌锛愬┃鎰暰娴ｅ秮鈧繂鍙嗛崣锝冣偓浣鼓侀崸妤佹暈閸愬被鈧焦膩閸ф顓搁悶鍡樼垼缁涙儳鎷伴悪顒傜彌娑撳顣介懝灞傗偓?
- 閺傛澘顤冩竟鐗堢爱鐎规矮缍呴張宥呭鐏炲偊绱濇妯款吇娴ｈ法鏁ら幍瀣簚缁夎濮╃涵顔款吇濡€崇€烽敍灞借嫙妫板嫮鏆€ ODAS tracked source 閸?`azimuth/elevation/confidence/sourceId` 閻ㄥ嫬褰查柅澶婄秺娑撯偓閸栨牕鍙嗛崣锝冣偓?
- 閺傛澘顤冮幍瀣簚缁?PCM 閸掑棙鐎介敍姘蓟婢逛即浜炬潏鎾冲弳娴ｈ法鏁?TDOA 缁鏆愭导鎷岊吀濮樻潙閽╅弬閫涚秴閿涘苯宕熸竟浼翠壕鏉堟挸鍙嗛柅姘崇箖婢舵矮缍呯純顕€鍣伴弽椋庢畱瀵搫瀹抽妴涓糔R 閸滃苯娲栭崫宥夘棑闂勨晠鈧劖顒炵涵顔款吇婢圭増绨崠鍝勭厵閵?
- 閺傛澘顤冩竟鐗堢爱鐎规矮缍呮い鐢告桨閿涘苯瀵橀崥顐″瘜閼哥偛褰寸粚娲？閹稿洤绱╅妴浣烘磧閸氼剚甯堕崚韬测偓浣筋唶瑜版洖缍嬮崜宥勭秴缂冾喓鈧椒绗呮稉鈧銉╅崝銊﹀絹缁€鎭掆偓渚€鍣伴弽椋庡仯閸掓銆冮妴浣割樋婢圭増绨崐娆撯偓澶婂灙鐞涖劌鎷?SNR/閸ョ偛鎼锋搴ㄦ珦閵?

### 娣囶喗鏁?
- 閺囧瓨鏌?toolbox 濡€虫健閺傚洦銆傞崪宀勩€嶉惄顔款嚛閺勫函绱濋弰搴ｂ€橀幍瀣簚閸愬懐鐤嗘ス锕€鍘犳搴ゅ喕婢剁喍缍旀稉娲帛鐠併倕鍙嗛崣锝忕礉娴ｅ棝娓剁憰浣烘暏閹撮些閸斻劑鍣伴梿鍡楊樋娑擃亙缍呯純顕嗙幢ODAS/闂冮潧鍨潏鎾冲毉閸欘亙缍旀稉娲彯缁狙冨讲闁鐦夐幑顔衡偓?
- 瀹搞儱鍙跨粻鍗炲弳閸欙綀浠涢崥鍫熺ゴ鐠囨洝藟閸忓應鈧藩ound locator閳ユ繂褰茬憴浣光偓褍鎷版潻娑樺弳妞ょ敻娼伴惃?smoke 鐟曞棛娲婇妴?

### 妤犲矁鐦?
- `dart format lib/src/services/toolbox_sound_locator_service.dart lib/src/ui/pages/toolbox_sound_locator_tool.dart lib/src/core/module_system/module_id.dart lib/src/core/module_system/module_registry.dart lib/src/ui/theme/toolbox_colors.dart lib/src/ui/module/module_access.dart lib/src/ui/pages/toolbox/toolbox_page_content.dart test/toolbox_sound_locator_service_test.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/services/toolbox_sound_locator_service.dart lib/src/ui/pages/toolbox_sound_locator_tool.dart lib/src/core/module_system/module_id.dart lib/src/core/module_system/module_registry.dart lib/src/ui/theme/toolbox_colors.dart lib/src/ui/module/module_access.dart lib/src/ui/pages/toolbox/toolbox_page_content.dart test/toolbox_sound_locator_service_test.dart test/ui_smoke_test.dart`
- `flutter test test/toolbox_sound_locator_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page shows aggregated local tools"`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page opens sound locator module"`

### 妞嬪酣娅撻崣妯绘纯
- 閹靛婧€闂堟瑦顒涢崡鏇犲仯闁插洦鐗遍弮鐘崇《閸欘垶娼涵顔款吇 3D 閺傞€涚秴閿涙稒婀版潪顔芥暭娑撴椽鈧俺绻冩径姘秴缂冾噣鍣伴弽閿嬫暪閺佹稑锛愬┃鎰隘閸╃噦绱濋獮璺烘躬妞ょ敻娼伴弰鍓с仛缂冾喕淇婃惔锔衡偓渚€鍣伴弽椋庡仯閺佷即鍣洪崪灞肩瑓娑撯偓濮濄儳些閸斻劌缂撶拋顔衡偓?
- 婢舵艾锛愬┃鎰┾偓浣稿繁閸ョ偛鎼烽崪宀€娲伴弽鍥э紣濠ф劒绗夐幐浣虹敾閺冩湹绮涙导姘舵娴ｅ海鈥樼拋銈堝窛闁插骏绱辫ぐ鎾冲缂佹挻鐏夋稉宥勭稊娑撳搫鐣ㄩ梼灞傗偓浣稿鞍閻ゆぜ鈧焦纭跺瀣灗瀹搞儰绗熺€规矮缍呮笟婵囧祦閵?

## [Unreleased-PLAN_180-AUDITORY-LAB-COLLAPSIBLE-SETTINGS] - 2026-05-19

### 閸樼喎娲?
- 婢规澘顒熺€圭偤鐛欐い鐢垫畱鐠佸墽鐤嗛妴浣筋嚛閺勫骸鎷扮拠濠冩焽娣団剝浼呮禒宥囧姧娴犮儱閽╅柧鐑樻煙瀵繐鐖㈤崣鐙呯礉缁夎濮╃粩顖烆浕鐏炲繘娓剁憰浣圭泊閸斻劏绶濇径姘閼崇晫婀呴崚棰佸瘜閹垮秳缍旈崠鐚寸礉娑旂喍绗夌粭锕€鎮庡銉ュ徔缁犻亶銆夐棃銏㈢埠娑撯偓閻ㄥ嫬褰查幎妯哄綌鐠佸墽鐤嗙拠顓熺《閵?

### 閺傛澘顤?
- 婢规澘顒熺€圭偤鐛欐い鍨煀婢х偟绮烘稉鈧幎妯哄綌閸栫尨绱濋崚鍡楀焼閹佃儻娴囬柌鍥ㄧ壉鐠佸墽鐤嗛妴渚€鍣伴梿鍡氱槚閺傤厼鎷版径宥嗙ゴ瀵ら缚顔呴妴?

### 娣囶喗鏁?
- 鐏忓棗甯張顒€鍨庨弫锝呮躬娑撹灏崺鐔烘畱闁插洦鐗辩拠瀛樻閵嗕胶骞嗘晶鍐╁絹缁€鎭掆偓浣割槻濞村缂撶拋顔兼嫲鐠囧﹥鏌囬幐鍥ㄧ垼閺€鑸垫殐閸掓壆绮烘稉鈧惃鍕讲閹舵ê褰旂紒鎾寸€稉顓ㄧ礉娣囨繄鏆€濡€崇础閸掑洦宕查妴浣哥杽閺冭埖瀵氶弽鍥モ偓浣瑰皾瑜般垹鎷版稉缁樻惙娴ｆ粍瀵滈柦顔兼躬閺囨挳娼崜宥囨畱娴ｅ秶鐤嗛妴?

### 娣囶喖顦?
- 娣囶喗顒滄竟鏉款劅鐎圭偤鐛欐い鐢敌╅崝銊ь伂鐠佸墽鐤嗘穱鈩冧紖鏉╁洭鏆遍妴浣哥湴缁狙嗙箖閺侊絿娈戦梻顕€顣介敍灞藉櫤鐏忔垿顩荤仦蹇曟棻閸氭垶瀚㈤幐銈冣偓?

### 妞嬪酣娅撻崣妯绘纯
- 閹舵ê褰旈崠娲帛鐠併倖鏁圭挧宄版倵閿涘矂顩诲▎鈥插▏閻劏鈧懘娓剁憰浣哄仯閸戠粯鐓￠惇瀣窡閸斺晞顕╅弰搴幢娴ｅ棜绻栭幑銏℃降娴滃棙娲垮〒鍛珰閻ㄥ嫰顩荤仦蹇庡瘜閹垮秳缍旈崪灞炬纯娑撯偓閼峰娈?toolbox 妞ょ敻娼扮拠顓熺《閵?

## [Unreleased-PLAN_179-ACOUSTIC-LAB-MOBILE-CAPTURE] - 2026-05-19

### 閸樼喎娲?
- 瀹搞儱鍙跨粻?娴滆櫣琚ù瀣槸娑擃厼绺?婢规澘顒熺€圭偤鐛欐禒宥呬焊閸╄櫣顢呯粈杞扮伐閿涘瞼些閸斻劍澧滈張铏诡伂閸︺劑鍎撮崚鍡氼啎婢跺洣绗傞崣顖濆厴閸氼垰濮╄ぐ鏇㈢叾娴ｅ棙鐥呴張澶嬫暪閸掓澘锛愰棅鍐叉姎閿涘瞼鏁ら幋宄板涧閼崇晫婀呴崚鎷岀箮娴煎ジ娼ら幀浣峰崕鐞涖劊鈧?
- 閺冄勭ウ缁嬪宸辩亸鎴﹀閸忓顥撴潏鎾冲弳閼奉亝顥呴妴渚€顩荤敮褏鐡戝?婢惰精瑙﹂幓鎰仛閵嗕胶骞嗘晶鍐ㄧ俺閸ｎ亜绱╃€电厧鎷伴崣顖滄暏娴滃骸顦插ù瀣灲閺傤厾娈戦柌鍥ㄧ壉鐠愩劍甯堕幐鍥ㄧ垼閵?

### 閺傛澘顤?
- 婢规澘顒熺€圭偤鐛欓弬鏉款杻 PCM 鐎圭偞妞傚ù浣藉厴閸旀稖鍤滃Λ鈧妴浣界翻閸忋儴顔曟径鍥槕閸掝偁鈧線顩荤敮褏婀呴梻銊у珝閸滃瞼绮ㄩ弸鍕闁挎瑨顕ら幓鎰仛閵?
- 瑜版洟鐓堕崥顖氬З閺傛澘顤冩径姘殰缁夎濮╃粩顖氬悑鐎瑰綊鍘ょ純顕嗙窗娴兼ê鍘涙担璺ㄦ暏閸樼喎顫愭ス锕€鍘犳?PCM閿涘苯銇戠拹銉ユ倵閸ョ偤鈧偓閺嶅洤鍣ス锕€鍘犳搴℃嫲鐠囶參鐓剁拠鍡楀焼閸忕厧顔愰柌鍥ㄧ壉閵?
- 妞ょ敻娼伴弬鏉款杻閻滎垰顣ㄦ惔鏇炴珨閸╄櫣鍤庨妴浣瑰腹閼芥劒绗呮稉鈧銉ｂ偓渚€鍣伴弽椋庡芳閵嗕浇绶崗銉︾爱閵嗕礁鐤勯弮鑸电ウ濡€崇础閵嗕線顩荤敮褍娆㈡潻鐔粹偓浣衡敄鐢冩嫲閸氼垰濮╃亸婵婄槸缁涘濮搁幀浣瑰瘹閺嶅洢鈧?
- 婢规澘顒熼幎銉ユ啞閺傛澘顤冮張澶嬫櫏婢规澘宕板В鏂烩偓浣稿З閹浇瀵栭崶娣偓浣稿槻閸у洦鐦妴浣衡敄閻ц棄鎶氬В鏂剧伐閸滃苯鎶氶弫鎵搼鐠愩劍甯堕幐鍥ㄧ垼閵?

### 娣囶喗鏁?
- 婢规澘顒熺€圭偤鐛欓柌鍥ㄧ壉濞翠胶鈻煎鍝勫娑撹　鈧粌鍘涢崳顏勶紣鎼存洩绱濋崘宥勭秵闂?妤傛﹢鐓?閹镐胶鐢婚垾婵堟畱鐎圭偟鏁ら梻顓犲箚閿涘苯鑻熼崷銊︾壉閺堫剙鍟撻崗銉ユ倵閹绘劗銇氱紒褏鐢绘稉瀣╃娑擃亝膩瀵繑鍨ㄦ导妯哄帥婢跺秵绁村閬嶃€嶉妴?
- 瑜版洟鐓堕崙铏瑰箛閺?PCM 鐢勬娑撳秴鍟€闂堟瑩绮崑婊呮殌閸︺劏绻嶇悰宀€濮搁幀渚婄礉閼板本妲搁弰搴ｂ€橀幓鎰仛濡偓閺屻儳閮寸紒鐔煎閸忓顥撻弶鍐閵嗕線娈ｇ粔浣哥磻閸忕偨鈧浇鎽戦悧娆掆偓铏簚鐠侯垳鏁遍妴浣哥秿鐏炲繑鍨ㄩ柅姘崇樈閸楃姷鏁ら妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_auditory_lab.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_human_tests.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "human tests hub exposes the new visual auditory and coordination modules"`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 婢规澘顒熼幎銉ユ啞娴犲秴鐔€娴滃氦顔曟径鍥閸忓顥撻惃鍕祲鐎?dBFS閵嗕焦婀伴崷?PCM 閸掑棙鐎介崪灞界秼閸撳秶骞嗘晶鍐ㄦ珨婢规澘绨抽敍灞肩瑝娴ｆ粈璐熼崠璇差劅閵嗕礁鎯夐崝娑滅槚閺傤厽鍨ㄦ稉鎾茬瑹婢规壆楠囩拋鈩冪垼鐎规氨绮ㄩ弸婧库偓?
- Android/iOS 鐎靛綊瀹抽崗瀣棑闂婃娊顣跺┃鎰┾偓浣芥憫閻楁瑨鐭鹃悽鍗炴嫲闂呮劗顫嗛崡鐘垫暏閻ㄥ嫬顦╅悶鍡楃摠閸︺劏顔曟径鍥ф▕瀵偊绱遍張顒冪枂瀹告彃濮為崗銉ヮ樋闁板秶鐤嗛崶鐐衡偓鈧崪灞炬￥鐢勫絹缁€鐚寸礉娴ｅ棔绮涘楦款唴閻喐婧€鐟曞棛娲婃稉缁樼ウ閺堝搫鐎烽妴?

## [Unreleased-PLAN_178-WINDOWS-AUDIO-PLATFORM-THREAD-FIX] - 2026-05-19

### 閸樼喎娲?
- Windows 缁?`audioplayers` 閸︺劌鐛熸担鎾冲鏉炲鈧礁鐣幋鎰┾偓浣规闂€鎸庢纯閺傛壆鐡戦崶鐐剁殶娑擃厼褰查懗鎴掔矤閸樼喓鏁撻崥搴″酱缁捐法鈻奸惄瀛樺复閸?`xyz.luan/audioplayers/events/...` EventChannel 閸欐垿鈧焦绉烽幁顖ょ礉鐟欙箑褰?Flutter 閻?`non-platform thread` 鐠€锕€鎲￠敍灞借嫙鐎涙ê婀禍瀣╂娑撱垹銇戦幋鏍х┛濠у啴顥撻梽鈹库偓?

### 閺傛澘顤?
- 閺傛澘顤?`third_party/audioplayers_windows` 閺堫剙婀撮幓鎺嶆 fork閿涘瞼澧楅張顑跨箽閹?`4.3.0`閿涘瞼鏁ゆ禍搴㈠鏉?Windows 楠炲啿褰寸痪璺ㄢ柤娣囶喖顦查妴?

### 娣囶喗鏁?
- `pubspec.yaml` 婢х偛濮?`audioplayers_windows` 閺堫剙婀?dependency override閿涘畭pubspec.lock` 閸氬本顒為弨閫涜礋 path source閵?
- Windows 闂婃娊顣堕幓鎺嶆閻?`EventStreamHandler` 閻滄澘婀导姘Ω閸氬骸褰寸痪璺ㄢ柤娴溠呮晸閻?`Success/Error` 闁俺绻冪€瑰じ瀵岀粣妤€褰涘☉鍫熶紖閹舵洟鈧帒娲?Flutter 楠炲啿褰寸痪璺ㄢ柤閸氬骸鍟€鐠嬪啰鏁?`EventSink`閵?
- `.gitignore` 鐞涖儱鍘?`third_party/audioplayers_windows/windows/**` 娓氬顦婚敍宀€鈥樻穱?vendored Windows 閹绘帊娆㈠┃鎰垳鏉╂稑鍙嗛悧鍫熸拱缁狅紕鎮婇妴?

### 妤犲矁鐦?
- `flutter pub get`
- `flutter analyze --no-fatal-infos lib/src/services/audio_player_source_helper.dart lib/src/services/toolbox_audio_players.dart`
- `flutter build windows --debug`
- `flutter test test/audio_player_source_helper_test.dart test/playback_service_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- Windows 閹绘帊娆㈡潻娑樺弳閺堫剙婀?fork 閸氬函绱濋崥搴ｇ敾閸楀洨楠?`audioplayers` 閺冨爼娓剁憰浣告倱濮濄儲顥呴弻銉ょ瑐濞?`audioplayers_windows` 閺勵垰鎯佸韫叏婢跺秴閽╅崣鎵殠缁嬪濮囬柅鎺嬧偓?
- 婵″倹鐏夐幓鎺嶆闁库偓濮ｄ焦鍨ㄧ粣妤€褰涙稉宥呭讲閻劍婀￠梻缈犵矝閺堝鎮楅崣浼寸叾妫版垳绨ㄦ禒鑸靛Х鏉堟拝绱濇导姘丢瀵啳顕氭禍瀣╂閼板奔绗夐弰顖欑矤閸氬骸褰寸痪璺ㄢ柤鐟欙箒鎻?Flutter閿涙稖绻栨导妯哄帥娣囨繆鐦夌痪璺ㄢ柤鐎瑰鍙忛妴?

## [Unreleased-PLAN_177-HUMAN-TESTS-MOBILE-GESTURE-CONTROLS] - 2026-05-19

### 閸樼喎娲?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃惃鍕啚閺夊棗宕楃拫鍐ㄥ弿鐏炲繗顔曠純顔艰剨缁愭鐥呴張澶屾磧閸氼剛濮搁幀浣稿煕閺傚府绱濆鎴濆З閺夆€冲棘閺佹澘鍑￠崣妯哄娴ｅ棜顫嬬憴澶嬬拨閸фぞ绗夋导姘倱濮濄儳些閸斻劊鈧?
- 閸掝喖鍩夋稊鎰┾偓浣规啚閺夊棎鈧焦寮跨痪瑁も偓浣规煙閸氭垶绮﹂崝銊ｂ偓浣衡敄闂傚瓨瀵氶柦鍫涒偓浣虹€崙鍡楁嫲閸欏本澧滈崡蹇氱殶缁涘鎼锋担婊嗗灦閸欐澘婀惇鐔告簚缁愬嫬鐫嗘稉濠傤啇閺勬挷绗屾い鐢告桨缁鹃潧鎮滃姘З閹躲垺澧滈崝瑁も偓?
- 閹镐胶鐢诲▔銊﹀壈閸旀稑鎷伴崥顒冾潕濞村鐦紓鍝勭毌鐎瑰本鏆ｉ惃鍕粻濮?闁插秶鐤嗛幒褍鍩楅崗銉ュ經閿涘矂鍎撮崚鍡樼ゴ鐠囨洘绁︾粙瀣╄厬娑撳秳绌舵稉顓熸焽閹存牠鍣搁弬鏉跨磻婵鈧?

### 閺傛澘顤?
- 閺傛澘顤冩禍铏硅濞村鐦稉顓炵妇閸忓彉闊╅惃鍕箾缂侇叀袝閹芥瓕绔熼悾宀€绮嶆禒璁圭礉閻劋绨拋鈺傛绾喚娈戦幙宥勭稊閼哥偛褰存导妯哄帥閹恒儲鏁归幏鏍уЗ閵嗕礁鍩夐幙锔衡偓浣规啚閺夊棗鎷伴弬鐟版倻濠婃垵濮╅幍瀣◢閵?
- 閹镐胶鐢诲▔銊﹀壈閸旀稒绁寸拠鏇∷夐崗鍛村櫢缂冾喖鍙嗛崣锝忕礉閸氼剝顫庡ù瀣槸鐞涖儱鍘栭崑婊勵剾閸忋儱褰涢妴?
- 鐞涖儱鍘栭幗鍥ㄦ綄閸忋劌鐫嗙拋鍓х枂閸掗攱鏌婇妴浣稿焿閸掝喕绠伴幏鏍уЗ閵嗕焦瀵旂紒顓熸暈閹板繐濮忛柌宥囩枂閸滃苯鎯夌憴澶婁粻濮濄垺瀵滈柦顔炬畱 widget 閸ョ偛缍婇弬顓♀枅閵?
- AGENTS.md 缁夎濮╃粩顖欑秼妤犲矁顫夐懠鍐╂煀婢х偠绻涚紒顓熷閸旀寧膩閸ф娓堕弰鎯х础婢跺嫮鎮婇悥鍓侀獓濠婃艾濮╅崘鑼崐閻ㄥ嫭鏁為幇蹇庣皑妞ゅ箍鈧?

### 娣囶喗鏁?
- 閹藉洦娼岄崡蹇氱殶閸忋劌鐫嗙拋鍓х枂瀵湱鐛ラ弨閫涜礋閻╂垵鎯夐崗鍙橀煩鐟欏棗娴樻穱鈥冲娇閿涘lider 娣囶喗鏁奸崥搴ｇ彌閸楁娊鍣哥紒姗堢幢閼奉亜鐣炬稊澶嬫殶鐎涙绶崗銉╅梽銈嗗閸斻劉鈧粌绨查悽銊⑩偓婵囧瘻闁筋噯绱濋弨閫涜礋閹绘劒姘﹂妴浣哥暚閹存劗绱潏鎴炲灗婢惰京鍔嶉弮鎯板殰閸斻劌绨查悽顭掔礉娣囨繄鏆€闁插秶鐤嗛崗銉ュ經閵?
- 閸掝喖鍩夋稊鎰┾偓浣瑰闁插繑濞婇崡掳鈧胶绨跨紒鍡樺珛閹峰鈧礁鎯夌憴澶屸敄闂傚瓨瀵氶柦鍫涒偓浣稿冀鎼存梹鏌熼崥鎴炵拨閸斻劊鈧焦澧滈惇鑲╂窗閺嶅洩鍨堕崣鑸偓浣规啚閺夊棙甯堕崚韬测偓浣虹€崙鍡氬灦閸欐澘鎷伴崣灞惧閸楀繗鐨熼惄绋垮彠鐠ф盯浜剧紒鐔剁閺€璺哄經鏉╃偟鐢婚幍瀣◢鏉堝湱鏅妴?
- 閸欏本澧滈崡蹇氱殶鐟欙箑灏弨閫涜礋閹稿洭鎷＄痪褏鍋ｉ崙?閹稿缍囬崚銈呯暰閿涘矂浼╅崗宥咁樆鐏炲倹澧滈崝鑳珶閻ｅ本濮犻崡鐘叉倵娑撱垹銇戦悙鐟板毊閵?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_aim.dart lib/src/ui/pages/toolbox_human_tests_auditory.dart lib/src/ui/pages/toolbox_human_tests_bimanual.dart lib/src/ui/pages/toolbox_human_tests_cognition.dart lib/src/ui/pages/toolbox_human_tests_drag_tracking.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_fullscreen.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_settings.dart lib/src/ui/pages/toolbox_human_tests_reaction.dart lib/src/ui/pages/toolbox_human_tests_shared.dart test/toolbox_human_tests_extended_smoke_test.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/pages/toolbox_human_tests.dart test/toolbox_human_tests_extended_smoke_test.dart test/ui_smoke_test.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "joystick fullscreen keeps controls off the center stage"`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "luck and sustained attention expose goals and richer tasks"`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "human tests hub exposes the new visual auditory and coordination modules"`

### 妞嬪酣娅撻崣妯绘纯
- 鏉╃偟鐢婚幍瀣◢鏉堝湱鏅禒鍛瘶鐟佽妲戠涵顔芥惙娴ｆ粏鍨堕崣甯礉鐠佸墽鐤嗛崠鍝勬嫲閺咁噣鈧碍绮撮崝銊ュ隘娴犲秳姘︾紒娆撱€夐棃銏＄泊閸旑煉绱遍崥搴ｇ敾閺傛澘顤冮崚顔芥憹閵嗕焦寮跨痪瑁も偓浣规啚閺夊棙鍨ㄩ幏鏍ㄥ缁粯膩閸ф妞傞棁鈧崥灞绢劄閸旂姴鍙嗙粣鍕潌/閻喐婧€閹靛濞嶉崶鐐茬秺閵?
- 閺佹澘鐡ф潏鎾冲弳閺€閫涜礋閼奉亜濮╂惔鏃傛暏閸氬函绱濋柨娆掝嚖鏉堟挸鍙嗘禒宥勭箽閹镐礁甯崐闂寸瑝閸欐﹫绱遍崥搴ｇ敾閼汇儲鏌婃晶鐐茬杽閺冭埖鐗庢灞惧絹缁€鐚寸礉闂団偓鐟曚線浼╅崗宥嗙槨娑擃亜鐡х粭锕佺翻閸忋儲妞傚鍝勫煑閺€鐟板晸閺傚洦婀伴妴?

## [Unreleased-PLAN_176-TOOLBOX-LAYOUT-RECOVERY-AND-QUICK-ENTRIES] - 2026-05-19

### 閸樼喎娲?
- 瀹搞儱鍙跨粻閬嶎浕妞ら潧婀紓鏍帆鐢啫鐪弮璁圭礉閹锋牗瀚块柌濠冩杹閸氬孩婀侀弮鏈电瑝閼崇晫菙鐎规俺鎯ゆ担宥忕礉闂堢姾绻庨崚妤勩€冩潏鍦喘閺冩湹绡冪紓鍝勭毌閼奉亜濮╁姘З閿涘瞼些閸斻劎顏紓鏍帆娴ｆ捇鐛欐稉宥呯暚閺佹番鈧?
- 妫ｆ牠銆夐垾婊呅╅梽銈傗偓婵嗗弳閸欙絽褰ч梾鎰娴滃棗宕遍悧鍥风礉娴ｅ棙浠径宥堢熅瀵板嫬鎷板Ο鈥虫健缁狅紕鎮婃い鍨梾閺堝鎮撳銉嚛閺勫函绱濈€硅妲楃拋鈺€姹夌拠顖欎簰娑撶儤膩閸ф顫﹀闀愮畽閸掔娀娅庨妴?
- 瀹搞儱鍙跨粻閬嶃€夐棃銏ゅ櫡娴犲秵婀佹稉鈧禍娑樹焊瀵偓閸欐垼顕╅弰搴ｆ畱閹侯亣绶搁敍灞藉弳閸欙絽宕遍悧鍥彯鎼达缚绡冮崶鐘辫礋閸愬懎顔愰梹璺ㄧ叚娑撳秳绔撮懛纾嬧偓灞炬▔瀵版寮顔衡偓?
- 妫ｆ牠銆夌紓鍝勭毌閻劍鍩涢崣顖濆殰鐎规矮绠熼惃鍕埗閻劌鎻╅柅鐔峰弳閸欙絻鈧?

### 閺傛澘顤?
- 瀹搞儱鍙跨粻閬嶎浕妞ゅ灚鏌婃晶鐐┾偓婊冪埗閻劌鎻╅柅鐔峰弳閸欙絺鈧繂灏敍灞炬暜閹镐椒绮犻悳鐗堟箒瀹搞儱鍙挎稉顓炲瑎闁鐖堕悽銊ュ弳閸欙絽鑻熸穱婵嗙摠閵?
- 瀹搞儱鍙跨粻閬嶎浕妞ゅ灚鏁幐浣瑰Ω濡€虫健閸楋紕澧栭惄瀛樺复閹锋牕鍩岄垾婊冪埗閻劌鎻╅柅鐔峰弳閸欙絺鈧繐绱濋弶鐐閸氬氦鍤滈崝銊ュ閸忋儯鈧?
- 瀹搞儱鍙跨粻杈╃椽鏉堟垶膩瀵繋鑵戞稊鐔告▔缁€琛♀偓婊冪埗閻劌鎻╅柅鐔峰弳閸欙絺鈧繐绱濋弨顖涘瘮闂€鎸庡瘻濡€虫健閸楋紕澧栭幏鏍у弳閸氬骸濮為崗銉ョ埗閻劌浼愰崗鏋偓?
- 濡€虫健缁狅紕鎮婃い鍏歌礋瀹搞儱鍙跨粻鍗炰紣閸忕柉藟閸忓應鈧粍浠径宥夘浕妞ら潧鍙嗛崣锝傗偓婵囨惙娴ｆ粣绱濋弬閫涚┒閹跺﹨顫︽＃鏍€夐梾鎰閻ㄥ嫬鍙嗛崣锝夊櫢閺傜増妯夌粈鍝勫毉閺夈儯鈧?

### 娣囶喗鏁?
- 瀹搞儱鍙跨粻杈╃椽鏉堟垶鈧焦鏁兼稉鍝勫讲濠婃艾濮╅惃鍕櫢閹烘帒鍨悰顭掔礉閹锋牗瀚跨紒鎾存将閸氬簼绗夋导姘辩彌閸掑鈧偓閸戣櫣绱潏鎴炩偓渚婄礉缁夎濮╅崚浼淬€婇柈銊﹀灗鎼存洟鍎撮弮璺哄讲閼奉亜濮╁姘З閵?
- 閳ユ粎些闂勩倝顩绘い闈涘弳閸欙絺鈧繄骞囬崷銊ょ窗閸忓牆鑴婇崙铏光€樼拋銈咁嚠鐠囨繃顢嬮敍灞借嫙缂佹瑥鍤幁銏狀槻鐠囧瓨妲戞稉搴℃倵缂侇厼鍙嗛崣锝冣偓?
- 瀹搞儱鍙跨粻鍗炲弳閸欙絽宕遍悧鍥╃埠娑撯偓娑撳搫娴愮€规岸鐝惔锔肩礉閺嶅洭顣介崪宀冾嚛閺勫骸婀粣鍕潌娑撳绱伴懛顏勫З閹搭亝鏌囬敍宀勪缉閸忓秹鐝担搴濈瑝娑撯偓閵?
- 瀹搞儱鍙跨粻杈ㄦ珮闁艾鍙嗛崣锝呭幢閻楀洭鐝惔锔跨瑓鐠嬪喛绱濋崙蹇撶毌閻厽鏋冨鍫濆幢閻楀洤绨抽柈銊ф殌閻ф枻绱辩紓鏍帆閹椒绻氶悾娆掔窛妤傛﹢鐝惔锔夸簰鐎瑰湱鎾奸幏鏍ㄥ閸滃瞼些闂勩倖瀵滈柦顔衡偓?
- 瀹搞儱鍙跨粻閬嶎浕妞ゅ吀绗屽Ο鈥虫健缁狅紕鎮婃い鐢垫畱閺傚洦顢嶉弨瑙勫灇閺囩鍤滈悞鍓佹畱閺冦儱鐖剁悰銊ㄦ彧閿涘本绔婚悶鍡曠啊閸嬪繗顕╅弰搴濆姛閸欙絽鎯㈤惃鍕敶鐎瑰箍鈧?

### 妤犲矁鐦?
- `dart format lib/src/models/settings_dto.dart lib/src/state/app_state.dart lib/src/state/app_state_startup.dart lib/src/ui/pages/toolbox_page.dart lib/src/ui/pages/toolbox/toolbox_page_content.dart lib/src/ui/pages/toolbox/toolbox_page_widgets.dart lib/src/ui/pages/toolbox/toolbox_quick_entries.dart lib/src/ui/pages/toolbox/toolbox_ui_tokens.dart lib/src/ui/pages/module_management_page.dart test/settings_service_test.dart test/ui_smoke_test.dart`
- `flutter analyze --no-fatal-infos lib/src/models/settings_dto.dart lib/src/state/app_state.dart lib/src/state/app_state_startup.dart lib/src/ui/pages/toolbox_page.dart lib/src/ui/pages/toolbox/toolbox_page_content.dart lib/src/ui/pages/toolbox/toolbox_page_widgets.dart lib/src/ui/pages/toolbox/toolbox_quick_entries.dart lib/src/ui/pages/toolbox/toolbox_ui_tokens.dart lib/src/ui/pages/module_management_page.dart test/settings_service_test.dart test/ui_smoke_test.dart`
- `flutter test test/settings_service_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page shows aggregated local tools"`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page supports editable home layout"`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page supports custom quick entries"`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page adds entries by dragging them to quick entries"`
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox edit mode adds entries by dragging them to quick entries"`

### 妞嬪酣娅撻崣妯绘纯
- 韫囶偊鈧喎鍙嗛崣锝勭瑢妫ｆ牠銆夐梾鎰閻樿埖鈧礁鍙℃禍顐㈡倱娑撯偓娴犺棄绔风仦鈧柊宥囩枂閿涘本鏌婃晶鐐村笓鎼村繑鍨ㄩ梾鎰鐟欏嫬鍨弮鍫曟付鐟曚礁鎮撳銉︻梾閺?quick 閸掓銆冮惃鍕秺娑撯偓閸栨牠鈧槒绶妴?
- 缂傛牞绶幀浣规暭娑撹櫣瀚粩瀣泊閸斻劌鎮楅敍宀冨閸氬海鐢婚崘宥堢殶閺佹挳銆夐棃銏ゎ€囬弸璁圭礉闂団偓鐟曚椒绻氶幐?header/footer 娑撳酣鍣搁幒鎺戝灙鐞涖劎娈戞潏鍦櫕濞撳懏娅氶妴?

## [Unreleased-PLAN_175-HUMAN-TESTS-COPY-I18N-CLEANUP] - 2026-05-18

### 閸樼喎娲?
- 娴滆櫣琚ù瀣槸娑擃厼绺炬禒宥嗘箒闁劌鍨庨弬鍥攳閸嬪繐绱戦崣鎴ｎ嚛閺勫簺鈧礁浜搁垾娣嶪/閺堫剙婀寸€圭偟骞囬垾婵嗗經閸氫紮绱濇竟鏉款劅閸滃本濞婇崡锛勭搼妞ょ敻娼版稊鐔告箒鏉╁洨鈥栭惃鍕槚閺?濡剝瀚欓幓鎰仛閵?
- 濡€虫健閸愬懎銇囬柌?`pickUiText` 娴犲懏婀佹稉顓″閺傚浄绱濋崝銊︹偓渚€顣芥惔鎾扁偓渚€顤侀懝鎻掓倳閵嗕礁寮芥＃鍫ｎ嚔閸滃本濮ら崨濠傚弳閸欙絽婀径姘愁嚔鐟封偓閻滎垰顣ㄦ稉瀣╃窗閸ョ偤鈧偓閹存牗妯夌粈杞扮瑝鐎瑰本鏆ｉ妴?

### 閺傛澘顤?
- 娑撹桨姹夌猾缁樼ゴ鐠囨洑鑵戣箛?`pickUiText` 閺傚洦顢嶇悰銉╃秷 ja/de/fr/es/ru 鐎涙顔岄敍宀冾洬閻╂牕鍙嗛崣锝冣偓浣圭ゴ鐠囨洟銆夐妴浣筋啎缂冾噣銆嶉妴浣瑰瘻闁筋喓鈧胶濮搁幀浣碘偓浣瑰Г閸涘鈧礁鑴婄粣妤€鎷伴幓鎰仛閵?
- 娑撻缚鐦濈拠顓☆唶韫囧棜鐦濇惔鎾扁偓渚€顤侀懝鎻掓倳缁夎埇鈧礁鎯夌憴?婢规澘顒熷Ο鈥崇础閵嗕礁寮芥惔鏃堫杹閼瑰眰鈧焦鏆熺€涙顔囪箛鍡樺絹缁€鎭掆偓浣筋潒鐟欏顔囪箛鍡氱殶閼瑰弶婢橀妴浣瑰▕閸楋紕鐡戠痪褍鎷伴崚顔煎焿閸椻€愁殯妞ょ藟閸忓懎顦跨拠顓♀枅鐎涙顔岄妴?
- 閸斻劍鈧礁寮芥＃鍫熸煀婢х偛顦跨拠顓♀枅閺夈儲绨敍灞藉瘶閸氼偄濮╅幀浣筋潒鐟欏鈧焦鏆熺€涙顔囪箛鍡愨偓浣界槤鐠囶叀顔囪箛鍡愨偓浣告儔鐟欏顔囪ぐ鏇炴嫲婢规澘顒熼幎銉ユ啞缁涘绻嶇悰灞炬閺傚洦顢嶉妴?

### 娣囶喗鏁?
- 濞撳懐鎮婇垾娓搊cal / 閺堫剙婀?/ 閸樼喎顫愰弫鐗堝祦 / medical judgment / diagnosis / 娑撴挷绗熼幎銉ユ啞閳ユ繄鐡戦崑蹇撶磻閸欐垶鍨ㄩ崑蹇氱槚閺傤叀銆冩潏鎾呯礉閺€閫涜礋缂佸啩绡勯妴浣筋潎鐎电喆鈧礁顕В鏂挎嫲娑撴挷绗熷Λ鈧弻銉︽禌娴狅綀顕╅弰搴涒偓?
- 婢规澘顒熺€圭偤鐛欓弬鍥攳缂佺喍绔存稉琛♀偓婊冿紣鐎涳附濮ら崨?/ 閸旂姴鍙嗛幎銉ユ啞閳ユ繐绱濋崢缁樺竴鏉╁洤瀹虫稉鎾茬瑹閸栨牕鎷扮拠濠冩焽閸栨牕褰涢崥姹団偓?
- 閹垫挸鐡уù瀣槸鐏忓棌鈧粈鍞惍浣测偓婵堟祲閸忚櫕膩瀵繑鏋冨鍫ｇ殶閺佺繝璐熼弴鎾偓姘箶閻ㄥ嫧鈧粍鐗稿?閺冦儱鐖堕垾婵堢搼鐞涖劏鎻敍灞借嫙娣囶喖顦查張鈧潻鎴犵波閺嬫粎鐡戞径姘愁嚔鐟封偓閺勫墽銇氶妴?
- 閸氬本顒為弴瀛樻煀 smoke test 閺傚洦顢嶉弬顓♀枅閿涘苯灏柊宥嗘煀閻ㄥ嫯鍤滈悞鑸垫瀮濡楀牄鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests*.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter analyze lib/src/ui/pages/toolbox_human_tests.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart`
- 閼奉亜鐣炬稊澶嬪閹诲繒鈥樼拋?`toolbox_human_tests*.dart` 閸?`pickUiText` 閸у洤鎯?zh/en/ja/de/fr/es/ru閵?
- 閼奉亜鐣炬稊澶嬪閹诲繒鈥樼拋銈嗘￥ `????` / `閿熺禇 / 鐢瓕顫?mojibake 濞堝鏆€閵?

### 妞嬪酣娅撻崣妯绘纯
- 婢舵俺顕㈢懛鈧弬鍥攳瀹告煡鈧劕顦╃悰銉╃秷楠炲爼鈧俺绻冮幍顐ｅ伎閿涘奔绲剧亸鎴﹀櫤闂堢偘鑵戦弬鍥嚔鐟封偓娴犲秳浜掗惌顓炲綖閸欘垵顕版稉杞扮喘閸忓牞绱濋崥搴ｇ敾閸欘垯姘︾紒娆愮槤鐠囶厼顓搁弽锛勬埛缂侇厽榧庨懝灞傗偓?
- 濞村鐦稉顓濈贩鐠ф牗妫弬鍥攳閻ㄥ嫭鏌囩懛鈧鍙夋纯閺傚府绱遍懟銉ヮ樆闁劏鍤滈崝銊ュ娑旂喓娲块幒銉ュ爱闁板秵妫弬鍥攳閿涘矂娓剁憰浣告倱濮濄儴鐨熼弫娣偓?

## [Unreleased-PLAN_174-HUMAN-TESTS-DRAG-ACOUSTIC-REPORT] - 2026-05-18

### 閸樼喎娲?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃崣灞藉灙濡€虫健鐠嬪啯鏆ｇ敮鍐ㄧ湰閺冭绱濋弲顕€鈧碍瀚嬮崝銊ょ窗閻╁瓨甯寸憴锕€褰傞幒鎺戠碍閿涘瞼宸辩亸鎴斺偓婊堚偓澶夎厬/閹疯儻鎹ｉ垾婵嗗冀妫ｅ牞绱濈憴鍡氼潕娑撳﹨绶濈粣浣稿帎閵?
- 婢规澘顒熺€圭偤鐛欓搹鐣屽姧瀹稿弶婀佹ス锕€鍘犳搴＄唨绾偓閹稿洦鐖ｉ敍灞肩稻鏉╂宸辩亸鎴炵ゴ鐠囨洖宕楃拋顔衡偓渚€鍣伴弽閿嬬焽濞ｂ偓閸滃奔绗撴稉姘Г閸涘﹪妫撮悳顖樷偓?

### 閺傛澘顤?
- 婢规澘顒熺€圭偤鐛欓弬鏉款杻濡€崇础闁插洦鐗辩拋鏉跨秿閿涘本瀵滄担搴ㄧ叾閵嗕線鐝棅鐐解偓浣瑰瘮缂侇厼鎷伴崳顏勶紣娴狀亙绻氱€涙浠涢崥鍫熺壉閺堫兙鈧?
- 婢规澘顒熺€圭偤鐛欓弬鏉款杻娑撴挷绗熼幎銉ユ啞閸忋儱褰涢敍灞界潔缁€铏规祲鐎?dBFS閵嗕礁鍢查崐绗衡偓渚€鐓舵妯糕偓渚€鐓舵妯诲皾閸斻劊鈧胶娲伴弽鍥ф嚒娑擃厹鈧椒淇婇崳顏呯槷閵嗕礁澧涘▔顫偓浣藉窛闁插繒鐡戠痪褍鎷版径宥嗙ゴ瀵ら缚顔呴妴?
- 婢规澘顒熺€圭偤鐛欓弬鏉款杻閸楀繗顔呴幓鎰仛娑撳孩鐗遍張顒€鍟撻崗銉︾ウ缁嬪绱濋弰搴ｂ€橀崳顏勶紣鎼存洏鈧椒缍嗛棅?妤傛﹢鐓堕崪灞惧瘮缂侇厼褰傛竟鎵畱闁插洦鐗遍弬瑙勭《閵?

### 娣囶喗鏁?
- 娴滆櫣琚ù瀣槸娑擃厼绺惧Ο鈥虫健閹烘帒绨弨閫涜礋闂€鎸庡瘻閸氬骸鍟€閹锋牗瀚块敍宀勬毐閹稿鎮楅崡锛勫閺€鎯с亣閵嗕焦濮崡鍥モ偓浣稿濞ｈ精绔熷鍡楁嫲闂冩潙濂栭敍灞借嫙娣囨繄鏆€韫囶偅宓庨崗銉ュ經閹锋牕鍙嗛懗钘夊閵?
- 婢规澘顒熺€圭偞妞傛禒顏囥€冪悰銉ュ帠閸濆秴瀹虫稉鈧懛瀛樷偓褋鈧浇绻冮梿鍓佸芳閵嗕礁澧涘▔顫偓浣圭壉閺堫剙鎶氶弫鏉挎嫲瀹告彃鍟撻崗銉︾壉閺堫剚鎲崇憰浣碘偓?
- 婢规澘顒熼幎銉ユ啞瀵湱鐛ラ弬鏉款杻閺勬儳绱￠崗鎶芥４閸忋儱褰涢敍宀勬娴ｅ酣鏆辨い鐢告桨濞村鐦稉搴Ｐ╅崝銊ь伂閹垮秳缍旈惃鍕瑝绾喖鐣鹃幀褋鈧?

### 妤犲矁鐦?
- `flutter analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_shared.dart lib/src/ui/pages/toolbox_human_tests_auditory_lab.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "human tests hub exposes the new visual auditory and coordination modules"`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 婢规澘顒熼幎銉ユ啞閸╄桨绨拋鎯ь槵妤癸箑鍘犳搴ｆ畱閻╃顕?dBFS 娑撳孩婀伴崷鎵暬濞夋洩绱濇稉宥勭稊娑撳搫灏扮€涳附鍨ㄧ€圭偤鐛欑€广倖鐖ｇ€规氨绮ㄩ弸婊愮幢閹躲儱鎲℃稉顓炲嚒閸旂姴鍙嗙拠瀛樻娑撳骸顦插ù瀣紦鐠侇喓鈧?
- 闂€鎸庡瘻閹锋牗瀚块弨鐟板綁娴滃棙甯撴惔蹇毿曢崣鎴︽，濡叉冻绱濋悙鐟板毊鏉╂稑鍙嗗ù瀣槸娑撳秴褰堣ぐ鍗炴惙閿涘奔绲鹃悽銊﹀煕闂団偓鐟曚線鏆遍幐澶婃倵閸愬秶些閸斻劍澧犻懗鍊熺殶閺佹潙绔风仦鈧妴?

## [Unreleased-PLAN_173-HUMAN-TESTS-BIMANUAL-TRACE-SETTLEMENT-FIX] - 2026-05-18

### 閸樼喎娲?
- 閻劍鍩涢幋顏勬禈閸欏秹顩悽璇叉禈鐠ф盯浜惧鍙夋▔缁€鐑樻付閸氬氦濡悙纭呯箻鎼达讣绱濇担鍡樼梾閺堝袝閸欐垶鍨氶崝鐔虹波缁犳绱濇稊鐔哥梾閺堝绻橀崗銉ょ瑓娑撯偓鏉烆喓鈧?

### 娣囶喗鏁?
- 閻㈣娴樻潻娑樺閺勫墽銇氶弨閫涜礋瀹告彃鐣幋鎰殠濞堝灚鏆熼敍灞肩瑝閸愬秵濡歌ぐ鎾冲閻╊喗鐖ｉ懞鍌滃仯鐠囶垱妯夌粈杞拌礋瀹告彃鐣幋鎰箻鎼达讣绱濋柆鍨帳 `4/4`閵嗕梗10/10` 鏉╂瑧琚崑鍥ㄥ姬閺嶈偐濮搁幀浣碘偓?
- 閻㈣娴樼捄顖氱窞閹舵洖濂栭弨閫涜礋閸欘亝閮ㄨぐ鎾冲閻╊喗鐖ｇ痪鎸庮唽妞ゅ搫绨幒銊ㄧ箻閿涘苯鑻熼崷銊﹀复鏉╂垹娲伴弽鍥Ν閻愯妞傞崥鎼佹閸掓媽顕氱痪鎸庮唽缂佸牏鍋ｉ敍灞藉櫤鐏忔垳姘﹂崣澶屽殠濞堜絻顕ら幎鏇炲鐎佃壈鍤ч惃鍕波缁犳宕卞姹団偓?
- 閻㈣娴橀崚鎷屾彧閺堚偓閸氬氦濡悙鐟版倵韫囧懎鐣剧拫鍐暏閹存劕濮涚紒鎾剁暬閿涙稒鐗遍張顒佸灗閹诲繒鍤庣捄婵堫瀲娑撳秷鍐婚弮璺哄涧鏉╄棄濮炴径杈嚖閹碉絽鍨庨敍灞肩瑝閸愬秵濡哥挧娑壕閻ｆ瑥婀陇绻樻惔锔芥弓鐎瑰本鍨氶悩鑸碘偓浣碘偓?
- 閹诲繒鍤庨崑蹇曨瀲閸欘亣顔囪ぐ鏇炪亼鐠囶垽绱濇稉宥呭晙娑撹濮╃憴锕€褰傛径杈Е缂佹挾鐣婚敍宀勪缉閸忓秴顦查弶鍌氬殤娴ｆ洖娴樿ぐ顫厬閻厽娈忕拠顖涘瑜拌京娲块幒銉х波閺夌喐婀版潪顔衡偓?

### 妤犲矁鐦?
- `flutter analyze lib/src/ui/pages/toolbox_human_tests_bimanual.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "bimanual trace lane completes from continuous sliding"`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 閻㈣娴樻径杈Е閺囨潙顦挎笟婵婄閺佺鐤嗙搾鍛閹存牕浠犲銏㈢波缁犳绱濋崑蹇曨瀲鐠侯垰绶炴导姘⒏閸掑棔绲炬稉宥囩彌閸楄櫕澧﹂弬顓ㄧ幢鏉╂瑦娲跨粭锕€鎮庣紒鍐х瘎閸︾儤娅欓敍灞肩瘍闁灝鍘ゆ径宥嗘絽閸ョ偓顢嶇拠顖涙絻閵?

## [Unreleased-PLAN_172-HUMAN-TESTS-BIMANUAL-TRACE-REWRITE-PRACTICE] - 2026-05-18

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閸欏本澧滈崡蹇氱殶閻㈣娴橀崷銊︽暭娑撶儤绮﹂崝銊﹀伎缁惧灝鎮楁禒宥嗘￥濞夋洜菙鐎规俺袝閸欐垶鍨氶崝鐕傜礉闂団偓鐟曚礁浜ゆ惔鏇㈠櫢閸嬫氨鏁鹃崶鎯х暚閹存劕鍨界€规哎鈧?
- 瑜版挸澧犳妯款吇瀹革箑褰搁崸鍥﹁礋閻㈣娴樺韫瑝缁楋箑鎮庨張鈧弬鎷岊唲缂佸啫鍙嗛崣锝夘暕閺堢噦绱濋棁鈧憰浣规暭娑撳搫涔忛崣鍐茶剨閻炲啴绮拋銈嗙ゴ鐠囨洩绱濋獮鎯八夐崗鍛礋娓氀呯矊娑旂姵膩瀵繈鈧?

### 閺傛澘顤?
- 閺傛澘顤冩妯款吇閸忔娊妫撮惃鍕礋娓氀呯矊娑旂姴绱戦崗绛圭礉閸欘垶鈧瀚ㄩ崣顏嗙矊瀹革缚鏅堕幋鏍у涧缂佸啫褰告笟褝绱辨导鎴炰紖娓氀傜瑝閸欏倷绗岄崥灞绢劄閸掑棎鈧礁鍣涵顔惧芳閸滃瞼婀＄€圭偛鎳℃稉顓犵埠鐠伮扳偓?

### 娣囶喗鏁?
- 閸欏本澧滈崡蹇氱殶姒涙顓诲锕€褰告禒璇插閺€閫涜礋瀵湱鎮嗛敍宀勵浕妞ゅ灚褰佺粈鍝勬嫲濡€崇础閹芥顩﹂崥灞绢劄閺囧瓨鏌婃稉娲帛鐠併倕鑴婇悶鍐︹偓?
- 閻㈣娴橀崚銈呯暰闁插秴鍟撴稉鐑樻殻閺壜ょ熅瀵板嫯绻涚紒顓＄箻鎼达附膩閸ㄥ绱版禒搴ゆ崳閻愬綊妾潻鎴濈磻婵绱濆鎴濆З閺冭埖瀵滅捄顖氱窞閹舵洖濂栭幒銊ㄧ箻閿涘苯鐣幋鎰閸氬本妞傚Λ鈧弻銉ㄧ熅瀵板嫯绻樻惔锔衡偓浣哥杽闂勫懏寮跨痪鑳獩缁傝鎷版潻鐐电敾閺嶉攱婀伴弫鑸偓?
- 閻㈣娴樼挧娑壕娑撳秴鍟€閸︺劍瀵滄稉瀣閹恒劏绻樼€瑰本鍨氶敍宀€鍋ｉ崙鏄忓Ν閻愯鍨ㄧ捄宕囧仯閺冪姵纭剁捄銊︻唽鐟欙箑褰傞幋鎰閿涙稒绮﹂崝銊﹂儴缁惧灝鐣幋鎰讲缁嬪啿鐣剧紒鎾剁暬閵?

### 妤犲矁鐦?
- `flutter analyze lib/src/ui/pages/toolbox_human_tests_bimanual.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "human tests hub exposes the new visual auditory and coordination modules"`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "bimanual trace lane completes from continuous sliding"`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 閻㈣娴樼憴鍡氼潕閺囪尙鍤庢禒宥勫▏閻劍濮岀痪鑳箮娴肩厧鍨界€规熬绱濇径宥嗘絽閺囪尙鍤庢导姘簰鏉堝啫顔旂€圭鐭惧鍕閸婄厧鎯涢弨璺轰焊瀹割噯绱遍崥搴ｇ敾閸欘垳鎴风紒顓熷瘻閻喐娲哥痪鍧楀櫚閺嶉攱褰侀崡鍥ㄥ閹扮喆鈧?

## [Unreleased-PLAN_171-HUMAN-TESTS-BIMANUAL-TRACE-GEOMETRY-FIX] - 2026-05-18

### 閸樼喎娲?
- 閸欏本澧滈崡蹇氱殶閻㈣娴樼挧娑壕娴犲秴鐡ㄩ崷銊у仯閸戞槒濡悙鐟板祮閸欘垰鐣幋鎰畱濠曞繑绀婇敍灞剧梾閺堝宸遍崚鑸靛瘮缂侇厽绮﹂崝銊﹀伎缁惧尅绱遍崶鐐攳閺堝鏅ョ亸鍝勵嚟閸嬪繐鐨敍灞肩瑬缂傚搫鐨稉宥夋閺堥缚濡悙鍦畱缁犫偓閸楁洖鍤戞担鏇炴禈瑜邦潿鈧?

### 閺傛澘顤?
- 閻㈣娴橀崶鐐攳閺傛澘顤冩稉澶庮潡瑜邦潿鈧焦顒滈弬鐟拌埌閵嗕線鏆遍弬鐟拌埌閵嗕礁娓捐ぐ顫偓浣诡潽瑜邦潿鈧浇褰佃ぐ顫偓浣割樋闂堫澀缍嬬粵澶婃祼鐎规艾鍤戞担鏇熌佸蹇ョ礉閸ュ搫鐣鹃崶鐐攳娑撳秳濞囬悽銊╂閺堥缚濡悙骞库偓?

### 娣囶喗鏁?
- 閸ュ搫鐣鹃崙鐘辩秿閸ョ偓顢嶉幐澶嬫纯婢堆呮畱閺堝鏅ラ懜鐐插酱鐏忓搫顕悽鐔稿灇閿涘矂娈㈤張鍝勬禈濡楀牅绡冮幍鈺併亣娴滃棜鐭惧鍕磹瀵板嫬鎷版潏鍦櫕娴ｈ法鏁ら悳鍥モ偓?
- 閹诲繒鍤庨崚銈呯暰閺傛澘顤冩潻鐐电敾閺嶉攱婀伴弫鑸偓浣瑰伎缂佹绐涚粋璇叉嫲鏉╂稑瀹虫晶鐐烘毐闂傘劍顫犻敍灞剧槨濞堥潧绻€妞ょ粯瀵旂紒顓熺拨閸斻劏鍐绘径鐔荤獩缁傝鎮楅幍宥堝厴鏉╂稑鍙嗘稉瀣╃濞堢绱濋悙鐟板毊缂佸牏鍋ｉ懞鍌滃仯娑撳秴鍟€閼崇晫娲块幒銉ョ暚閹存劑鈧?
- 閻㈣娴樼拋鍓х枂閺傚洦顢嶆禒搴樷偓婊堟閺堥缚濡悙褰掝棑閺嶅皷鈧繆鐨熼弫缈犺礋閳ユ粌娴樺鍫熌佸蹇娾偓婵撶礉閸忕厧顔愰梾蹇旀簚妞嬪孩鐗搁崪灞芥祼鐎规艾鍤戞担鏇熌佸蹇嬧偓?

### 妤犲矁鐦?
- `flutter analyze lib/src/ui/pages/toolbox_human_tests_bimanual.dart test/toolbox_human_tests_extended_smoke_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 閹诲繒鍤庨梻銊︻潬閹绘劙鐝崥搴礉韫囶偊鈧喕鐑﹂悙閫涚窗鐞氼偄鍨芥稉鐑樻￥閺佸牞绱辨稉杞扮啊娣囨繄鏆€閹靛鍔呴敍宀勬，濡叉稑褰х憰浣圭湴鐏忔垿鍣烘潻鐐电敾閺嶉攱婀伴崪宀€瀹虫稉澶婂瀻娑斿绔寸痪鎸庮唽闂€鍨閻ㄥ嫭寮跨紒妯跨獩缁傛眹鈧?

## [Unreleased-PLAN_170-HUMAN-TESTS-BIMANUAL-TRACE-JUMP-IMMERSIVE] - 2026-05-18

### 閸樼喎娲?
- 閸欏本澧滈崡蹇氱殶閻㈣娴樻禒宥呭讲闁俺绻冪憴锕佹彧閼哄倻鍋ｈ箛顐︹偓鐔稿腹鏉╂冻绱濈紓鍝勭毌閻喎鐤勫▽璺ㄥ殠閹诲繑鎳濈憰浣圭湴閿涙稖鐑︽妯挎閺堝些閸斻劌閽╅崣棰佺稻鐠囧棗鍩嗘惔锕€鎷扮亸蹇旂埗閹村繑鍔呮稉宥堝喕閿涙稒鐭囧ù绋跨础濡亜鐫嗘稉顓炰箯閸欏疇绂岄柆鎾寸垼妫版ǜ鈧胶娲伴弽鍥ф嫲鐠囧瓨妲戦崡鐘垫暏缁屾椽妫挎潻鍥ь樋閵?

### 娣囶喗鏁?
- 閻㈣娴橀崚銈呯暰閺€閫涜礋濞屽灝缍嬮崜宥囧殠濞堜絻绻涚紒顓熷腹鏉╂冻绱濋崺杞扮艾閹靛瀵氶崚鎵殠濞堢數娈戠捄婵堫瀲閸滃本濮囪ぐ杈箻鎼达箑鍨界€规熬绱濋悙鐟板毊鏉╂粎顏懞鍌滃仯娑撳秴鍟€閼崇晫娲块幒銉ョ暚閹存劑鈧?
- 閻㈣娴橀懜鐐插酱閺傛澘顤冨鍙夊伎缂佹寤烘潻鐟版嫲瑜版挸澧犵痪鎸庮唽鏉╂稑瀹抽崣宥夘洯閿涘苯鎮撻弮鏈电箽閻ｆ瑤绗呮稉鈧懞鍌滃仯妤傛ü瀵掗崪灞炬煙閸氭垹顔勬径娣偓?
- 鐠烘娊鐝弨閫涜礋闁插﹥鏂侀崥搴ょ箻閸忋儳鐓弳鍌溾敄娑擃厾濮搁幀渚婄礉鐟欐帟澹婂▽鍨К缁惧潡顥ｉ崥鎴濋挬閸欏府绱濋拃钘夋勾閺冭泛鍟€閹稿閽╅崣鏉跨秼閸撳秳缍呯純顔衡偓浣芥惈閸旀稑鎷扮€瑰綊鏁婇崚銈呯暰閹存劕濮涢幋鏍ф浆閽€濮愨偓?
- 鐠烘娊鐝懜鐐插酱瀵搫瀵茬紒鍫㈠仯缁捐￥鈧焦妫楃敮婧库偓浣烘窗閺嶅洤閽╅崣浼寸彯娴滎喓鈧礁閽╅崣浼寸彯閸忓鎷扮憴鎺曞閸ョ偓鐖ｉ敍灞惧絹閸楀洤鐨〒鍛婂灆鐠囧棗鍩嗘惔锔衡偓?
- 濞屽韫堝蹇曟彛閸戞垵鍙忕仦蹇涙閽樺繐涔忛崣瀹犵闁挻鐖ｆ０妯糕偓浣烘窗閺嶅洤鎷扮拠瀛樻閿涘奔绮庢穱婵堟殌韫囧懓顩︽潻娑樺閵嗕胶濮搁幀浣告嫲閹垮秳缍旈懜鐐插酱閵?

### 妤犲矁鐦?
- 瀵板懓绻嶇悰宀嬬窗`flutter analyze lib/src/ui/pages/toolbox_human_tests_bimanual.dart test/toolbox_human_tests_extended_smoke_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 閻㈣娴樺В鏂剧瑐娑撯偓閻楀牊娲垮楦跨殶鏉╃偟鐢婚幙宥勭稊閿涘苯顔愰柨娆庣矝濞岃法鏁ら梾鎯у闂冨牆鈧》绱遍崥搴ｇ敾閸欘垱鐗撮幑顔肩杽闂勫懏澧滈幇鐔烘埛缂侇厼浜曠拫鍐閸婄厧鎷版径杈Е娑撳﹪妾洪妴?

## [Unreleased-PLAN_169-HUMAN-TESTS-BIMANUAL-DIFFICULTY-ENDLESS] - 2026-05-18

### 閸樼喎娲?
- 閸欏本澧滈崡蹇氱殶閻ㄥ嫰姣︽惔锕傤暕鐠佸彞绮涙稉鏄忣洣瑜板崬鎼烽梾鎰閸忣剙绱￠敍灞借剨閻炲啨鈧胶鏁鹃崶鎯ф嫲鐠烘娊鐝紓鍝勭毌閺囨潙顦块崣顖氬爱闁板秹姣︽惔锔炬畱閺勬儳绱￠悳鈺傜《閸欏倹鏆熼敍娑橆槻閺夊倻鏁鹃崶鎹愮熅瀵板嫮娈戦弬鐟版倻閹绘劗銇氭稉宥堝喕閿涘苯鑴婇悶鍐ㄥ礋閻炲啰宸辩亸鎴炲珛鐏忔儳寮芥＃鍫礉娑旂喓宸辩亸鎴濆讲閹镐胶鐢荤紒鍐х瘎閻ㄥ嫭妫ら梽鎰佸蹇嬧偓?

### 閺傛澘顤?
- 閺傛澘顤冮弮鐘绘濡€崇础閿涙碍鍨氶崝鐔稿瘮缂侇厼绶遍崚鍡楄嫙閼奉亜濮╂潻娑樺弳娑撳绔寸紒鍕剁礉婢惰精瑙﹂崣顏堝櫢瀵偓娑撳绔寸紒鍕剁礉娑撳秶鐝涢崡瀹犵箻閸忋儲濮ら崨濠忕幢閹靛濮╅崑婊勵剾閹存牗妞傞梻纾嬧偓妤€鏁栭崥搴ｇ波缁犳ぜ鈧?
- 瀵湱鎮嗛弬鏉款杻绾扮増鎸掗崝鐘烩偓鐔风磻閸忕偨鈧胶鎮嗘径褍鐨妴浣哥毈閻炲啩閲滈弫鎷岊啎缂冾噯绱濋獮鏈佃礋閸楁洜鎮?婢舵氨鎮嗘晶鐐插閹锋牕鐔弫鍫熺亯閵?
- 閻㈣娴橀弬鏉款杻缁炬寧顔岄崙鐘辩秿濡€崇础閿涘牏娲跨痪瑁も偓浣规锤缁捐￥鈧線娈㈤張鐚寸礆閵嗕焦娓剁亸蹇氼潡鎼达箓妾洪崚韬测偓浣稿瀻濞堥潧鍍甸懝鍙夊絹缁€鍝勬嫲閺囧瓨妲戦弰鍓ф畱娑撳绔撮懞鍌滃仯閺傜懓鎮滅粻顓炪仈閵?
- 鐠烘娊鐝弬鏉款杻楠炲啿褰寸€硅棄瀹抽崪灞筋啍鎼达箓娈㈤張鍝勫隘闂傜顔曠純顕嗙礉閸欘垵顔曠純顔昏礋閸ュ搫鐣剧€硅棄瀹抽幋鏍ㄥ瘻閸栨椽妫块梾蹇旀簚閵?

### 娣囶喗鏁?
- 闂呮儳瀹抽崚鍥ㄥ床娴兼艾鎮撳銉ョ安閻劋绔撮弫瀵哥矋妫板嫯顔曢敍宀冨殰閸斻劏鐨熼弫纾嬪Ν閻愯鏆?鐟欐帒瀹抽妴浣歌剨閻炲啴鈧喎瀹?閻炲啯鏆?閻炲啫銇囩亸?閹糕剝婢橀妴浣界儲妤傛ê閽╅崣鏉跨湴閺?鐎硅棄瀹?闁喓宸肩粵澶婂棘閺佽埇鈧?
- 閻㈣娴樼捄顖氱窞閻㈢喐鍨氶弨閫涜礋濮ｅ繋閲滈懞鍌滃仯濞屽潡娈㈤張鐑樻煙閸氭垶甯规潻娑崇礉楠炶泛婀張鈧亸蹇氼潡鎼达箓妾洪崚鏈电瑓閸戝繐鐨潻鍥х毈婢剁顫楃敮锔芥降閻ㄥ嫯鐭惧鍕穿閸欑姰鈧?

### 妤犲矁鐦?
- `flutter analyze lib/src/ui/pages/toolbox_human_tests_bimanual.dart test/toolbox_human_tests_extended_smoke_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 婢舵氨鎮嗛崪宀€顫幘鐐插闁喍绱伴幓鎰扮彯瀵湱鎮嗛幐鎴炲灛瀵搫瀹抽敍宀勭帛鐠併倓绮涙穱婵囧瘮閸楁洜鎮嗘稉鏂垮彠闂傤厾顫幘鐐插闁噦绱遍崶浼存/娑撴挸顔嶆０鍕啎娴兼矮瀵岄崝銊ョ磻閸氼垱娲挎妯哄繁鎼达负鈧?

## [Unreleased-PLAN_168-HUMAN-TESTS-BIMANUAL-PLATFORM-REFINE] - 2026-05-18

### 閸樼喎娲?
- `瀹搞儱鍙跨粻?-> 娴滆櫣琚ù瀣槸娑擃厼绺?-> 閸欏本澧滈崡蹇氱殶` 娑擃厾鏁鹃崶鍙ョ矝閸嬪繐娴愮€规碍膩閺夊尅绱濆鍦倖缂傚搫鐨梾婊咁暡绾扮増鎸掓稉鏃€灏呴弶鎸庢惙娴ｆ粌顔愰弰鎾诡潶閹靛瀵氶柆顔藉皡閿涘矁鐑︽妯圭矝閸嬫粎鏆€閸︺劌褰撮梼?閺嶅繑娼屽Ο鈥崇€烽敍灞肩瑝缁楋箑鎮庡Ο顏勬倻缁夎濮╅獮鍐插酱闁劕鐪伴惂濠氥€婇惃鍕窗閺嶅洨甯哄▔鏇樷偓?

### 閺傛澘顤?
- 閻㈣娴樼挧娑壕閺€閫涜礋鐢妇顫掔€涙劗娈戦梾蹇旀簚閸戠姳缍嶉懞鍌滃仯閻㈢喐鍨氶敍灞肩箽閻ｆ瑦濮岀痪瑁も偓浣瑰皾濞搭亗鈧焦妲﹁ぐ顫偓浣界仾閺冨鈧焦鏌熷鍡愨偓渚€妯佸顖樷偓浣告礀閻滎垳鐡戞搴㈢壐閺冨骏绱濋獮璺烘晼闁插繒鏁撻幋鎰讲鐠囪崵娈戞稉鈧粭鏃傛暰鐠侯垰绶為妴?
- 瀵湱鎮嗙挧娑壕閺傛澘顤冮梾蹇旀簚閸﹀棗鑸伴梾婊咁暡閻椻晛鎷伴崣宥呰剨绾扮増鎸掗敍灞界毈閻炲啫鏄傜€靛憡鏁圭亸蹇ョ礉閹糕剝婢樻稉濠勑╅獮鑸垫煀婢х偛绨抽柈銊﹀付閸掕埖娼?楠炵晫浼掗幐鍥┿仛閿涘矂妾锋担搴㈠閹稿洭浼勯幐掳鈧?
- 鐠烘娊鐝挧娑壕閺傛澘顤冨Ο顏勬倻缁夎濮╅獮鍐插酱閵嗕礁閽╅崣浼粹偓鐔哄芳鐠佸墽鐤嗛妴渚€姣︽惔锕傗攳閸斻劎娈戦拑鍕鐏炲倸鎷伴柅鎰湴閻у銆婇崚銈呯暰閵?

### 娣囶喗鏁?
- 鐠烘娊鐝拋鍓х枂娴犲簶鈧粌褰撮梼鍓佹窗閺?闂呮粎顣茬€靛棗瀹抽垾婵囨暭娑撹　鈧粌閽╅崣鏉跨湴閺?楠炲啿褰撮柅鐔哄芳閳ユ繐绱濋悙鐟板毊閹存牞鎼崝娑樺涧閹恒劏绻樻稉鈧仦鍌︾礉閸涙垝鑵戦獮鍐插酱閹靛秶鎴风紒顓溾偓?
- 瀵湱鎮嗛弬鍥攳娑撳海澧块悶鍡氬Ν婵傚繑鏁兼稉鍝勬纯缂佹洖绨抽柈銊﹀付閸掕泛灏妴渚€娈㈤張娲绾板秴鎷伴弴鏉戠毈閻炲啩缍嬬仦鏇炵磻閵?
- 閻㈣娴樼拋鍓х枂閺傚洦顢嶆禒搴℃祼鐎规俺鐭惧鍕禈濡楀牊鏁兼稉娲閺堥缚濡悙褰掝棑閺嶇》绱濆楦跨殶濮ｅ繐娲栭崥鍫濆殤娴ｆ洝濡悙閫涚窗閸欐ê瀵查妴?

### 妤犲矁鐦?
- `flutter analyze lib/src/ui/pages/toolbox_human_tests_bimanual.dart test/toolbox_human_tests_extended_smoke_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 鐠烘娊鐝崚銈呯暰閻㈠崬娴愮€规俺绻樻惔锔藉腹鏉╂稒鏁兼稉鍝勯挬閸欑増铆閸氭垵鎳℃稉顓燁梾濞村绱濇妯款吇娣囨繄鏆€鏉堝啫顔旂€瑰湱娈戦崨鎴掕厬缁愭褰涢敍娑楃瑩鐎瑰爼姣︽惔锔跨窗閺勫孩妯夐弴缈犵贩鐠ф牗妞傞張鍝勬嫲閽冨嫬濮忛妴?

## [Unreleased-PLAN_167-HUMAN-TESTS-BIMANUAL-FREE-COMBO] - 2026-05-18

### 閸樼喎娲?
- `瀹搞儱鍙跨粻?-> 娴滆櫣琚ù瀣槸娑擃厼绺?-> 閸欏本澧滈崡蹇氱殶` 娴犲秳浜掓稉澶岊潚閸ュ搫鐣惧锕€褰搁柊宥咁嚠娑撹桨瀵岄敍灞炬￥濞夋洝鍤滈悽杈╃矋閸氬牆涔忛崣铏娴犺濮熼敍娑氭暰閸ユ儳娴樺鍫ｇ窛鐏忔埊绱濆鍦倖閸欏倹鏆熸稉宥呭讲鐠嬪啩绗栭幐鈩冩緲閸嬪繐甯ら敍宀冪儲妤?閻у妯侀悳鈺傜《娴犲秴浠犻悾娆忔躬闂嗗繐鑸伴妴?

### 閺傛澘顤?
- 閸欏本澧滈崡蹇氱殶鐠佸墽鐤嗛弬鏉款杻瀹革箑褰搁幍瀣殰閻㈣京绮嶉崥鍫礉瀹革附澧滈崪灞藉礁閹靛鍏橀崣顖滃缁斿鈧瀚ㄩ悽璇叉禈閵嗕礁鑴婇悶鍐╁灗鐠烘娊鐝敍宀勭帛鐠併倕娼庢稉铏规暰閸ヤ勘鈧?
- 閺傛澘顤冪紒鐔剁闂呮儳瀹崇拋鍓х枂閿涘苯鑻熺悰銉ュ帠閻㈣娴橀崶鐐攳閵嗕胶鍤庡▓鍨壉瀵繈鈧浇濡悙瑙勬殶闁插骏绱濆鍦倖闁喓宸?閸ョ偛鑴婇惄顔界垼/閹糕剝婢樼€硅棄瀹?閹糕剝婢橀崢姘閿涘奔浜掗崣濠呯儲妤傛ê褰撮梼鍓佹窗閺?闂呮粎顣茬€靛棗瀹崇拋鍓х枂閵?

### 娣囶喗鏁?
- 閸ョ偛鎮庨悽鐔稿灇娴犲骸娴愮€规矮绗佸Ο鈥崇础闁板秴顕弨閫涜礋鐠囪褰囧锕€褰告禒璇插闁板秶鐤嗛敍灞借嫙鐠佲晠姣︽惔锕€濂栭崫宥呮礀閸氬牊妞傞梹瑁も偓浣烘暰閸ユ儳顔愰柨娆嶁偓浣歌剨閻炲啴鈧喎瀹抽崪宀冪儲妤傛﹢娈扮喊宥呯槕鎼达负鈧?
- 閻㈣娴樼挧娑壕閹碘晛鐫嶆稉鐑樿穿閸氬牄鈧焦濮岀痪瑁も偓浣瑰皾濞搭亗鈧焦妲﹁ぐ顫偓浣界仾閺冨鈧焦鏌熷鍡愨偓渚€妯佸顖樷偓浣告礀閻滎垳鐡戦崶鐐攳閿涘本鏁幐浣哥杽缁捐￥鈧浇娅勭痪瑁も偓浣哄仯缁惧灝鎷扮€硅棄鐢弽宄扮础閵?
- 瀵湱鎮嗛幐鈩冩緲閺€閫涜礋閺囧绮忛惃鍕帛鐠併倕甯ゆ惔锔肩礉楠炶泛鐨㈢亸蹇曟倖闁喎瀹抽妴浣烘窗閺嶅洤娲栧瑙勵偧閺佹澘鎷扮喊鐗堟寬娑撳﹪妾虹痪鍐插弳闁板秶鐤嗛妴?
- 鐠烘娊鐝挧娑壕鐞涖儵缍堥弽蹇旀綄闂呮粎顣查妴浣芥惈閸旀稖鐑︾捄鍐︹偓浣芥硶鐡掑﹦鐡戠痪褍鎷伴悩鑸碘偓浣稿冀妫ｅ牞绱濇稉宥呭晙閸欘亝妲搁弲顕€鈧艾褰撮梼璺哄窗娴ｅ秲鈧?

### 妤犲矁鐦?
- `flutter analyze lib/src/ui/pages/toolbox_human_tests_bimanual.dart`
- `flutter analyze lib/src/ui/pages/toolbox_human_tests_bimanual.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "human tests hub exposes the new visual auditory and coordination modules"`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 閺傛澘顤冮崣鍌涙殶闂嗗棔鑵戦崷銊ュ蓟閹靛宕楃拫鍐╂拱閸︽壆濮搁幀浣疯厬閿涘矁绻嶇悰灞艰厬娴犲秹鏀ｇ€规俺顔曠純顕嗙幢姒涙顓诲锕€褰搁崸鍥﹁礋閻㈣娴橀敍灞芥嫲閺冄呭姒涙顓婚柊宥咁嚠娑撳秴鎮撻敍灞肩稻缁楋箑鎮庨張顒冪枂闂団偓濮瑰倶鈧?

## [Unreleased-PLAN_166-HUMAN-TESTS-BIMANUAL-FULLSCREEN-NARROW-EXIT] - 2026-05-18

### 閸樼喎娲?
- `瀹搞儱鍙跨粻?-> 娴滆櫣琚ù瀣槸娑擃厼绺?-> 閸欏本澧滈崡蹇氱殶` 閻ㄥ嫬鍙忕仦蹇斆仦蹇庣秼妤犲苯婀担搴ㄧ彯鎼达附澧滈張鍝勭潌楠炴洑鑵戞禒宥勭窗鐞氼偊銆婇柈銊﹁癁鐏炲倸鎷扮挧娑壕閸楋紕澧栭幐銈呭竾閿涘矂鈧偓閸戝搫鍙忕仦蹇撳弳閸欙絼绡冪€硅妲楅崪灞炬珮闁岸銆夐懣婊冨礋鐠囶厺绠熷ǎ閿嬬┋閵?

### 娣囶喗鏁?
- 閸欏本澧滈崡蹇氱殶閸忋劌鐫嗘い鍨暭娑?`SafeArea + Column` 閻ㄥ嫬澧挎担娆戔敄闂傛潙绔风仦鈧敍宀勩€婇柈銊﹀付閸掕埖娼稉宥呭晙鐟曞棛娲婃稉鏄忓灦閸欏府绱濈粣鍕仦蹇庣瑓閼奉亜濮╅崥顖滄暏缁毖冨櫨濡€崇础閵?
- 閸忋劌鐫嗙槐褍鍣惧Ο鈥崇础娴兼艾甯囩紓鈺呫€婇柈銊︽喅鐟曚降鈧線娈ｉ挊蹇旑偧缁狙勫Г閸涘﹤娴橀弽鍥モ偓渚€妾锋担搴′箯閸欏疇绂岄柆鎾冲敶鐠烘繐绱濋獮鍫曟閽樺繋缍嗘导妯哄帥缁狙嗩嚛閺勫孩鏋冨鍫礉娣囨繄鏆€瀹革箑褰哥挧娑壕楠炶埖甯撻妴浣圭垼妫版ǜ鈧胶娲伴弽鍥モ偓浣界箻鎼达箑鎷伴崣顖涙惙娴ｆ粌灏崺鐔粹偓?
- 閸忋劌鐫嗛崗鎶芥４閹稿鎸抽妴浣藉綅閸楁洟鈧偓閸戞椽銆嶇紒鐔剁鐠ф澘鎮撴稉鈧柅鈧崙鍝勫毐閺佸府绱遍弲顕€鈧岸銆夐懣婊冨礋娑撳秴鍟€閺勫墽銇氶垾婊堚偓鈧崙鍝勫弿鐏炲繆鈧繐绱濋柆鍨帳鏉╂劘顢戞稉顓☆嚖閹跺﹥娅橀柅姘躲€夋潻鏂挎礀瑜版挻鍨氶崗銊ョ潌闁偓閸戞亽鈧?

### 娣囶喖顦?
- 娣囶喖顦茬粣鍕仦蹇庣瑓瀹革箑褰哥挧娑壕鐞氼偊銆婇柈銊ュ弿鐏炲繑璇炵仦鍌涘皨閸樺鈧礁鍙忕仦?90 鎼达附铆鐏炲繑妫ゅ▔鏇犌旂€规岸鈧倿鍘ら幍瀣簚妤傛ê瀹抽惃鍕６妫版ǜ鈧?
- 娣囶喖顦查崗銊ョ潌闁偓閸戝搫鍙嗛崣锝呮嫲閺咁噣鈧岸銆夐懣婊冨礋鐠囶厺绠熷ǎ铚傝础鐎佃壈鍤ч惃鍕嚖闁偓閸戞椽顥撻梽鈹库偓?

### 妤犲矁鐦?
- `flutter analyze lib/src/ui/pages/toolbox_human_tests_bimanual.dart test/toolbox_human_tests_extended_smoke_test.dart`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --plain-name "human tests hub exposes the new visual auditory and coordination modules"`
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart`

### 妞嬪酣娅撻崣妯绘纯
- 缁毖冨櫨濡亜鐫嗘稉瀣╃窗閸戝繐鐨挧娑壕閸愬懘鍎寸拠瀛樻閺傚洤鐡ч敍宀冾潐閸掓瑧绮忛懞鍌欏瘜鐟曚椒绶风挧鏍ㄧ垼妫版ǜ鈧胶娲伴弽鍥モ偓浣界箻鎼达箑鎷扮拋鍓х枂/閹躲儱鎲＄悰銉ュ帠閿涙稑鎮楃紒顓″缂佈呯敾婢х偛濮炵挧娑壕缁鐎烽敍宀勬付鐟曚礁鎮撳銉р€樼拋銈囨彛閸戞垶膩瀵繋绮涙穱婵堟殌鐡掑啿顧勯崣顖濐嚢娣団剝浼呴妴?

## [Unreleased-PLAN_165-PORTABLE-PATH-DEFAULTS] - 2026-05-18

### 閸樼喎娲?
- 妞ゅ湱娲版担婊€璐熷鈧┃鎰礂娴ｆ粓銆嶉惄顕嗙礉娑撳秴绨叉笟婵婄娑擃亙姹夐張鍝勬珤娑撳﹦娈戦崶鍝勭暰閻╂顑侀妴浣烘暏閹撮娲拌ぐ鏇熷灗婢舵牠鍎寸槐鐘虫綏閻╊喖缍嶉敍娑欐＋閻?fallback 鐠侯垰绶炴导姘愁唨閺傜増鍨氶崨妯诲閸欐牕鎮楅崙铏瑰箛娑撳秴褰叉径宥囧箛閻ㄥ嫭鐎鎭掆偓浣圭ゴ鐠囨洖鎷伴弫鐗堝祦閻㈢喐鍨氱悰灞艰礋閵?
- 閸撳秳绔存潪顔煎嚒娣囶喖顦查弮?CMake 缂傛挸鐡ㄦ潻浣盒╅梻顕€顣介敍灞炬拱鏉烆喚鎴风紒顓熸暪閸欙綀鍓奸張顒€鎷伴弬鍥ㄣ€傛稉顓犳畱娑擃亙姹夌紒婵嗩嚠鐠侯垰绶炴妯款吇閸婄鈧?

### 娣囶喗鏁?
- `scripts/tooling-env.ps1` 缁夊娅?Flutter閵嗕竼Make閵嗕竸ndroid SDK 缁涘閲滄禍鐑樻簚閸ｃ劏鐭惧?fallback閿涘本鏁兼稉铏瑰箚婢у啫褰夐柌蹇嬧偓涓矨TH閵嗕線銆嶉惄顔煎敶 `.fvm` / `.tooling` 閸滃瞼閮寸紒鐔告烦閻㈢喓娲拌ぐ鏇樷偓?
- `scripts/opencode-minimax-m27.ps1` 娑?`scripts/orchestrate-opencode-models.ps1` 缁夊娅庢稉顏冩眽 `C:\Users\...` opencode fallback閿涘本鏁兼稉?`OPENCODE_BIN` 閹?PATH閵?
- 濮ｅ繑妫╅崘宕囩摜閺佺増宓侀悽鐔稿灇/鐎孤ゎ吀閼存碍婀伴惃鍕帛鐠併倛绶崗銉ㄧ翻閸戠儤鏁兼稉娲€嶉惄顔煎敶 `resources/daily_choice/...`閵嗕梗build/generated/daily_choice/...` 閹存牕顕惔鏃傚箚婢у啫褰夐柌蹇氼洬閻╂牓鈧?
- `README.md`閵嗕梗.env.template`閵嗕梗modules/toolbox/README.md`閵嗕梗PROJECT_DOMAIN.md` 鐞涖儱鍘栭崣顖溞╁宥呬紣閸忕兘鎽奸妴浣规殶閹诡喚娲拌ぐ鏇炴嫲閸楀繋缍旂捄顖氱窞缁撅附娼拠瀛樻閵?

### 妤犲矁鐦?
- 鏉╂劘顢戞稉銉︾壐鐠侯垰绶為幍顐ｅ伎閿涙瓪scripts`閵嗕梗README.md`閵嗕梗PROJECT_DOMAIN.md`閵嗕梗modules`閵嗕梗.env.template` 娑擃厽婀崣鎴犲箛鏉╂劘顢戦弮?Windows 閻╂顑佺捄顖氱窞閹?`vocabularySleep-resources` 娓氭繆绂嗛妴?
- PowerShell Parser 鐠囶厽纭跺Λ鈧弻銉┾偓姘崇箖閿涙瓪scripts/tooling-env.ps1`閵嗕梗scripts/build.ps1`閵嗕梗scripts/dev-run.ps1`閵嗕梗scripts/verify-local-analysis.ps1`閵嗕梗scripts/test.ps1`閵嗕梗scripts/opencode-minimax-m27.ps1`閵嗕梗scripts/orchestrate-opencode-models.ps1`閵?
- `python -m py_compile` 闁俺绻冮敍? 娑擃亝鐦￠弮銉ュ枀缁涙牗鏆熼幑顔炬晸閹?鐎孤ゎ吀閼存碍婀伴妴?
- `.\scripts\build.ps1 -Target windows -DryRun -NoPubGet`閵嗕梗.\scripts\test.ps1 -Target test\sanity_test.dart -DryRun -NoPubGet`閵嗕梗.\scripts\test.ps1 -Target test\sanity_test.dart -NoPubGet` 閸у洭鈧俺绻冮妴?
- `git diff --check` 闁俺绻冮妴?

### 妞嬪酣娅撻崣妯绘纯
- 娴犲秳绻氶悾娆戞畱缂佹繂顕捄顖氱窞閸涙垝鑵戞担宥勭艾閸樺棗褰?`changelogs/` 鐠佹澘缍嶉妴浣圭ゴ鐠囨洘鐗辨笟瀣摟缁楋缚瑕嗛崪宀冪槤閸忔瓕顕㈤弬娆欑礉娑撳秴寮稉搴ょ箥鐞涘矁鍓奸張顒勭帛鐠併倛鐭惧鍕掗弸鎰┾偓?
- 瑜版挸澧犻張顒佹簚妤犲矁鐦夋潏鎾冲毉娑擃厾娈?`D:\env\...` 閺夈儴鍤?shell/PATH 閻滎垰顣ㄧ憴锝嗙€介敍灞肩瑝閺勵垯绮ㄦ惔鎾冲敶绾剛绱惍?fallback閵?

## [Unreleased-PLAN_164-ENV-MIGRATION-TOOLING] - 2026-05-18

### 閸樼喎娲?
- 妞ゅ湱娲版禒搴㈡＋閺堝搫娅掗崪灞炬＋ `D:\workspace` 鐠侯垰绶炴径宥呭煑閸掓澘缍嬮崜?`L:\workspace\vocabularySleep-app` 閸氬函绱漌indows / Android CMake 閻㈢喐鍨氱紓鎾崇摠娴犲秳绻氱€涙ɑ妫紒婵嗩嚠鐠侯垰绶為敍灞筋嚤閼?`CMakeCache.txt directory ... is different` 娑?source directory 娑撳秴灏柊宥冣偓?
- 瑜版挸澧犳潻鎰攽閵嗕焦绁寸拠鏇炴嫲閹垫挸瀵橀崗銉ュ經鐎?Flutter閵嗕竼Make閵嗕腐uGet閵嗕竸ndroid SDK 缁涘浼愰崗鐤熅瀵板嫬褰夐崠鏍畱闁倿鍘ら崚鍡樻殠閿涘矁绺肩粔璇叉倵鐎硅妲楅崣妯诲灇閹靛濮╅幒鎺楁閵?

### 閺傛澘顤?
- 閺傛澘顤?`scripts/tooling-env.ps1`閿涘矂娉︽稉顓烆槱閻?Flutter閵嗕笍art閵嗕竼Make閵嗕竸ndroid SDK閵嗕腐uGet 閻ㄥ嫯袙閺嬫劑鈧赋ATH 濞夈劌鍙嗛妴浣规拱閸?tooling 閻滎垰顣ㄩ崪?CMake 缂傛挸鐡ㄦ潻浣盒╁Λ鈧ù瀣ㄢ偓?
- 閺傛澘顤?`scripts/test.ps1`閿涘瞼绮烘稉鈧?`flutter test` 閻?`pub get`閵嗕购eporter閵嗕礁鐣鹃崥鎴炵ゴ鐠囨洏鈧梗-PlainName` / `-Name` 閸?`-ResetBuildCache` 閸忋儱褰涢妴?
- 閺傛澘顤?`plans/PLAN_164_閻滎垰顣ㄦ潻浣盒╅弸鍕紦濞村鐦銉ュ徔闁倿鍘?md`閿涘矁顔囪ぐ鏇熸拱鏉烆喚骞嗘晶鍐讣缁夎鎱ㄦ径宥囨窗閺嶅洢鈧焦顒炴銈勭瑢妞嬪酣娅撴潏鍦櫕閵?

### 娣囶喗鏁?
- `scripts/build.ps1` 婢跺秶鏁ら崗鍙橀煩瀹搞儱鍙块悳顖氼暔闁槒绶敍瀛竔ndows 閺嬪嫬缂撻崜宥堝殰閸斻劏袙閺?CMake 娑?NuGet閿涘瓑ndroid / Windows 閺嬪嫬缂撻崜宥堝殰閸斻劍顥呭ù瀣嫙濞撳懐鎮婇弮褑鐭惧?CMake 缂傛挸鐡ㄩ敍娑欐煀婢?`-ResetBuildCache`閵?
- `scripts/dev-run.ps1` 婢跺秶鏁ら崗鍙橀煩瀹搞儱鍙块悳顖氼暔闁槒绶敍瀛竔ndows 鏉╂劘顢戦崜宥堝殰閸斻劏袙閺?Flutter閵嗕竼Make閵嗕腐uGet閿涘苯鑻熼崷銊ㄧ箥鐞涘苯澧犳穱顔碱槻閺冄嗙熅瀵?CMake 缂傛挸鐡ㄩ敍娑欐煀婢?`-ResetBuildCache`閵?
- `scripts/verify-local-analysis.ps1` 婢跺秶鏁ら崗鍙橀煩 Flutter / Dart / 閺堫剙婀?tooling 閻滎垰顣ㄧ憴锝嗙€介敍灞借嫙閸︺劑鐛欑拠浣稿濡偓閺屻儲妫捄顖氱窞 CMake 缂傛挸鐡ㄩ妴?
- 閺囧瓨鏌?`README.md` 娑?`PROJECT_DOMAIN.md`閿涘矁藟閸忓懐骞嗘晶鍐ㄥ綁闁插繈鈧焦绁寸拠鏇炲弳閸欙絻鈧胶绱︾€涙ü鎱ㄦ径宥呭弳閸欙絽鎷版径宥呭煑妞ゅ湱娲伴崥搴ｆ畱 CMake 閹烘帡娈扮拠瀛樻閵?

### 娣囶喖顦?
- 娣囶喖顦?`build/windows/x64/CMakeCache.txt` 娑擃厽鐣悾?`d:/workspace/vocabularySleep-app` 鐎佃壈鍤?Windows 閹垫挸瀵樻径杈Е閻ㄥ嫰妫舵０姗堢礉閼存碍婀版导姘躬濡偓濞村鍩岀紓鎾崇摠鐠侯垰绶炴稉宥呯潣娴滃骸缍嬮崜宥夈€嶉惄顔芥濞撳懐鎮?`build/windows`閵?
- 娣囶喖顦?Android `.cxx` CMake 缂傛挸鐡ㄦ稉顓熺暙閻ｆ瑦妫銉ょ稊閸栭缚绶崙铏规窗瑜版洜娈戦梻顕€顣介敍宀冨壖閺堫兛绱板〒鍛倞 `build/.cxx` 娑?`build/app/intermediates/cxx`閵?
- 娣囶喖顦?Windows 閹垫挸瀵橀梼鑸殿唽 `flutter_tts` CMakeLists 閹靛彞绗夐崚?`nuget.exe` 閻ㄥ嫮骞嗘晶鍐ㄥ櫙婢跺洨宸遍崣锝冣偓?

### 妤犲矁鐦?
- PowerShell Parser 鐠囶厽纭跺Λ鈧弻銉┾偓姘崇箖閿涙瓪scripts/tooling-env.ps1`閵嗕梗scripts/build.ps1`閵嗕梗scripts/dev-run.ps1`閵嗕梗scripts/verify-local-analysis.ps1`閵嗕梗scripts/test.ps1`閵?
- `.\scripts\test.ps1 -Target test\sanity_test.dart`閿涘牓鈧俺绻冮敍灞剧閻炲棙妫?CMake 缂傛挸鐡ㄩ崥搴ょ箥鐞?1 娑擃亝绁寸拠鏇礆閵?
- `.\scripts\build.ps1 -Target windows -NoPubGet`閿涘牓鈧俺绻冮敍宀€鏁撻幋?`build\windows\x64\runner\Release\xianyushengxi.exe` 楠炶泛顦查崚璺哄煂 `dist\windows`閿涘鈧?
- `.\scripts\build.ps1 -Target windows -DryRun -NoPubGet`閿涘牓鈧俺绻冮敍灞肩瑝閸愬秵濮ら崨濠冩＋ `D:\workspace` CMake 缂傛挸鐡ㄩ敍澶堚偓?

### 妞嬪酣娅撻崣妯绘纯
- 閼奉亜濮╁〒鍛倞娴犲懘妾洪悽鐔稿灇閻╊喖缍嶉敍姝歜uild/windows`閵嗕梗build/.cxx`閵嗕梗build/app/intermediates/cxx`閿涙稐绗夋导姘叏閺€閫涚瑹閸斺€插敩閻焦鍨ㄥ┃鎰瀮娴犺翰鈧?
- `pubspec.lock` 閸︺劍婀版潪顔肩磻婵澧犲鎻掝槱娴?modified 閻樿埖鈧緤绱遍張顒冪枂閺堫亜鐨㈤崗鏈电稊娑撳搫浼愰崗铚傛叏婢跺秷瀵栭崶鏉戭槱閻炲棎鈧?

## [Unreleased-PLAN_163-HUMAN-TESTS-BIMANUAL-IMMERSIVE-FULLSCREEN] - 2026-05-12

### 閸樼喎娲?
- 閸欏本澧滈崡蹇氱殶娴犲簼姹夌猾缁樼ゴ鐠囨洑鑵戣箛鍐箻閸忋儱鎮楁禒宥勭窗閽€钘夊煂閺咁噣鈧岸銆夊蹇曞Ц閹礁鎷伴柨娆庤础鐠佸墽鐤嗙仦鍌︾礉濞屸剝婀侀崓蹇斿閻厧宕楃拫?閹藉洦娼岄幍瀣簜閸楀繗鐨熸稉鈧弽椋庢纯閹恒儴绻橀崗銉ュ讲閻溾晝娈戝Ο顏勭潌濞屽韫堥崗銊ョ潌閵?

### 娣囶喗鏁?
- 閸欏本澧滈崡蹇氱殶閸︺劎婀＄€圭偟些閸斻劎顏潻娑樺弳妞ょ敻娼伴崥搴ゅ殰閸斻劍澧﹀鈧?90 鎼达附铆鐏炲繑鐭囧ù绋垮弿鐏炲骏绱濋獮璺烘躬閸忋劌鐫嗘＃鏍ф姎閼奉亜濮╁鈧慨瀣箯閸欏磭瀚粩瀣壋鐟佸倹瀵幋妯糕偓?
- 閸忋劌鐫嗛幒褍鍩楃仦鍌涙暭娑撹櫣娅ф惔鏇″灦閸欒埇鈧礁宕愰柅蹇旀濞搭喖鐪伴妴浣告禈閺嶅洦瀵滈柦顔衡偓浣哄Ц閹礁鐫嶅鈧棃銏℃緲閸滃矁顔曠純顔艰剨缁愭绱濋弽宄扮础鐎靛綊缍堥幍瀣簜閸楀繗鐨熸稉搴㈡啚閺夊棙澧滈惇鐓庡礂鐠嬪啫鍙忕仦蹇斈佸蹇嬧偓?
- 閸忋劌鐫嗛崘鍛磻婵鈧線鍣哥純顔衡偓浣筋啎缂冾喓鈧焦濮ら崨濞库偓浣虹波閺夌喎鎷伴柅鈧崙鍝勬綆娴犲骸缍嬮崜宥呭弿鐏炲繋绗傛稉瀣瀮鐟欙箑褰傞敍宀勪缉閸忓秵濮ら崨濠冨灗瀵湱鐛ラ拃钘夋礀閺咁噣鈧岸銆夋稉濠佺瑓閺傚洢鈧?

### 娣囶喖顦?
- 娣囶喖顦查崗銊ョ潌鏉╂稑鍙嗛崥搴濈矝閺勫墽銇氶張顏勭磻婵鈧胶鐡戝鍛村帳鐎佃鍨ㄩ弲顕€鈧岸銆夐崡锛勫瀵繗顔曠純顔碱嚤閼峰瓨膩閸фぞ绗夐崣顖滄暏閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦查崗銊ョ潌閻樿埖鈧礁鍩涢弬棰佺贩鐠ф牗瀵旂紒?ticker 閻ㄥ嫰妫舵０姗堢礉閺€閫涜礋閻㈠崬寮婚幍瀣礂鐠嬪啰濮搁幀浣蜂繆閸欑兘鈹嶉崝銊ュ煕閺傚府绱濋梽宥勭秵濞村鐦崪宀冪箥鐞涘本妞傜粚楦挎祮妞嬪酣娅撻妴?
- 閺囧瓨鏌?smoke test閿涘矁顩惄鏍у弿鐏炲繐鍙嗛崣锝冣偓浣藉殰閸斻劌绱戠仦鈧妴浣镐箯閸欏疇鍨堕崣鏉挎倱鐏炲繈鈧浇顔曠純顔艰剨缁愭鎷伴崗銊ョ潌閼挎粌宕熼妴?

### 妞嬪酣娅撻崣妯绘纯
- 閸忋劌鐫嗘稉搴㈡珮闁岸銆夌紒褏鐢婚崗鍙橀煩閸氬奔绔寸仦鈧崘鍛Ц閹緤绱濋崥搴ｇ敾閺傛澘顤冨鍦崶閵嗕焦濮ら崨濠冨灗鐠佲剝妞傞柅鏄忕帆閺冨爼娓剁憰浣烘埛缂侇厺濞囬悽銊ョ秼閸撳秴鍙忕仦蹇庣瑐娑撳鏋冮獮璺烘礀瑜版帡鈧偓閸戣櫣鏁撻崨钘夋噯閺堢喆鈧?
- 閼奉亜濮╂潻娑樺弳閸忋劌鐫嗛崷?Flutter widget test 娑?Web 閻滎垰顣ㄦ稉顓濈箽閻ｆ瑦妯夊蹇撳弳閸欙綇绱濋惇鐔风杽缁夎濮╃粩顖濐攽娑撴椽娓剁紒褏鐢婚柅姘崇箖鐠佹儳顦崶鐐茬秺绾喛顓婚妴?

## [Unreleased-PLAN_162-HUMAN-TESTS-BIMANUAL-FULLSCREEN-DEFAULT] - 2026-05-11

### 閸樼喎娲?
- 閸欏本澧滈崡蹇氱殶閼存垼顥囬梿鍡楁値閸︺劍澧滈張铏圭崕鐏炲繋绗傛禒宥囧姧鏉╁洣绨幏銉﹀皨閿涘矂娓剁憰渚€绮拋銈囨纯閹恒儴绻橀崗?90 鎼达附铆鐏炲繐鍙忕仦蹇ョ礉楠炶埖濡哥拋鍓х枂閵嗕線鍣哥純顔衡偓浣虹波閺夌喓鐡戦幙宥勭稊閺€鎯扮箻閺囩浜ら柌蹇曟畱閸忋儱褰涢妴?
### 閺傛澘顤?
- 閹靛婧€缁旑垵绻橀崗銉ュ蓟閹靛宕楃拫鍐╂姒涙顓绘导妯哄帥閸忋劌鐫嗗Ο顏勭潌閿涙稒娅橀柅姘躲€夋穱婵堟殌娑撯偓娑擃亜鍙忕仦蹇撴儙閸斻劍瀵滈柦顔兼嫲閺囨潙顦块懣婊冨礋閸忋儱褰涢妴?
### 娣囶喗鏁?
- 閸忋劌鐫嗛崘鍛埛缂侇厽閮ㄩ悽銊ヤ箯閸欏磭瀚粩瀣灦閸欓绗岄懣婊冨礋瀵繑甯堕崚璁圭礉楠炶埖鏁归崣锝勮礋閺囨挳鈧倸鎮庨崡鏇熷缁傝绱戦惃鍕氦闁插繑瀵滈柦?瀵懓鍤崗銉ュ經閵?
### 娣囶喖顦?
- 娣囶喖顦?climb 鐠ф盯浜鹃崪?trace 鐠ф盯浜鹃崷銊┾偓鈧崙鍝勬倵閸嬭泛褰傞惃?`setState() called after dispose()` 妞嬪酣娅撻妴?

## [Unreleased-PLAN_161-HUMAN-TESTS-BIMANUAL-TIME-NARROW-FIX] - 2026-05-11

### 閸樼喎娲?
- 閸欏本澧滈崡蹇氱殶閼存垼顥囩亸蹇旂埗閹村繗绻曠紓鍝勭毌閺勬儳绱＄拋鈩冩閺冨爼鏆遍崗銉ュ經閿涘矂绮拋銈勭瘍濞屸剝婀侀幎濠冩￥闂勬劖妞傞梹鍨嫲鏉烆喗鏆熺拋鍓х枂鐠囧瓨绔诲Δ姘剧幢閸氬本妞傜粣鍕潌娑撳涔忛崣瀹犲灦閸欐壆娈戦崣顖濐潒娑撳骸褰查幙宥勭稊閹嗙箷娑撳秴顧勭粙鍐茬暰閿涘苯鑻熺€涙ê婀?trace 鐠ф盯浜鹃崷銊╂敘濮ｄ礁鎮楁禒宥呭讲閼宠姤鏁归崚鐗堝瘹闁藉牆娲栫拫鍐畱妞嬪酣娅撻妴?

### 閺傛澘顤?
- 娑撳搫寮婚幍瀣礂鐠嬪啳鍓崇憗鍌氱毈濞撳憡鍨欑悰銉ょ瑐鐠佲剝妞傞弮鍫曟毐鐠佸墽鐤嗛敍宀勭帛鐠併倕鈧棿璐熼弮鐘绘閺冨爼鏆遍敍灞借嫙閹跺﹨鐤嗛弫棰佺瑐闂勬劖濯洪梹鍨煂閺囨挳鈧倸鎮庨梹鍨湰鐠侇厾绮岄惃鍕瘱閸ユ番鈧?

### 娣囶喗鏁?
- 鐏忓棗寮婚幍瀣礂鐠嬪啳鍓崇憗鍌氱毈濞撳憡鍨欓惃鍕啎缂冾喖灏弨閫涜礋姒涙顓婚幎妯哄綌閿涘矁藟閸忓懓顓搁弮鑸垫闂€瑁も偓浣界枂閺侀绗岃ぐ鎾冲閺冨爼鏆遍惃鍕喅鐟曚礁鐫嶇粈鎭掆偓?
- 鐏忓棛鐛庣仦蹇氬灦閸欑増鏁兼稉鍝勪箯閸欏啿鑻熼幒鎺戞倱鐏炲繐绔风仦鈧敍灞借嫙閸樺缂夌挧娑壕閸楋紕澧栭惃鍕彛閸戞垶鈧礁鏄傜€甸潻绱濋柆鍨帳娑撳﹣绗呴崼鍡楀綌閸氬骸寮婚幍瀣￥濞夋洖鎮撻弮鑸垫惙娴ｆ嚎鈧?

### 娣囶喖顦?
- 娣囶喖顦?trace 鐠ф盯浜鹃崷銊︽＋閹靛濞嶆禍瀣╂鏉╂稑鍙嗗鏌ユ敘濮ｄ胶濮搁幀浣告倵娴犲秴褰查懗鍊熜曢崣?`setState()` 閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦茬拋鈩冩閺冨爼鏆辩拋鍓х枂缂傝桨缍呴妴渚€绮拋銈囩波閺夌喐娼禒鏈电瑝濞撳懏娅氭禒銉ュ挤缁愬嫬鐫嗗锕€褰搁懜鐐插酱閸掑棛顬囬惃鍕６妫版ǜ鈧?

### 妞嬪酣娅撻崣妯绘纯
- 閺傛澘顤冮惃鍕闂€鑳啎缂冾喕绱扮拋鈺傚閹存ɑ娲跨€硅妲楅崙铏瑰箛闂€鍨湰閿涘本澧滈崝銊х波閺夌喐瀵滈柦顔兼嫲閹躲儱鎲￠弨璺哄經闁槒绶棁鈧憰浣瑰瘮缂侇厼娲栬ぐ鎺嬧偓?
- 缁愬嫬鐫嗛獮鑸靛笓鐢啫鐪惃鍕付娴犺泛鐦戞惔锔芥纯妤傛﹫绱濋崥搴ｇ敾婵″倹鐏夌紒褏鐢婚崝鐘绘毐閺傚洦顢嶉幋鏍у閸忋儲娲挎径姘崇闁挷淇婇幁顖ょ礉闂団偓鐟曚胶鎴风紒顓熷付閸掕泛宕遍悧鍥彯鎼达负鈧?

## [Unreleased-PLAN_159-HUMAN-TESTS-BIMANUAL-SPLIT-BRAIN] - 2026-05-11

### 閸樼喎娲?
- 閸欏本澧滈崡蹇氱殶濡€虫健娴犲秴浠犻悾娆忔躬閸╄櫣顢呭锕€褰搁悙鐟板毊鐏炲偊绱濈紓鍝勭毌閻喐顒滃锕€褰搁崚鍡欘瀲閻ㄥ嫯鍓崇憗鍌氱毈濞撳憡鍨欓梿鍡楁値閵嗕浇濡總蹇撳綁閸栨牕鎷伴崣顖氼槻閻娈戠紒鎾剁暬閸欏秹顩妴?

### 閺傛澘顤?
- 鐏忓棎鈧苯浼愰崗椋庮唸 - 娴滆櫣琚ù瀣槸娑擃厼绺?- 閸欏本澧滈崡蹇氱殶閵嗗秹鍣搁崑姘礋瀹革箑褰搁悪顒傜彌閻ㄥ嫯鍓崇憗鍌氱毈濞撳憡鍨欓梿鍡楁値閿涘苯濮為崗銉ф暰閸ヤ勘鈧礁鑴婇悶鍐︹偓浣广偧濮婎垯绗佺猾璁虫崲閸旓繝鍘ょ€电櫢绱濇禒銉ュ挤閺囨挳鐭為弰搴ｆ畱妫ｆ牕鐫嗛懜鐐插酱娑撳骸鍨庨弫鏉垮冀妫ｅ牄鈧?

### 娣囶喗鏁?
- 閺囧瓨鏌婇崣灞惧閸楀繗鐨熸い鐢告桨閻ㄥ嫮濮搁幀浣虹矋缂佸洢鈧胶绮ㄩ弸婊呯波缁犳ぜ鈧焦膩瀵繘鈧瀚ㄩ弬鍥攳娑撳骸涔忛崣宕囧缁斿鎹㈤崝锟犲帳鐎电顕╅弰搴涒偓?
- 閺囧瓨鏌婃禍铏硅濞村鐦稉顓炵妇閸忋儱褰涢幓蹇氬牚閿涘奔濞囩拠銉δ侀崸妤€婀崗銉ュ經鐏炲倸姘ㄩ懗鎴掔炊鏉堢偓娲垮铏规畱濞撳憡鍨欓崠鏍瀵颁降鈧?

### 娣囶喖顦?
- 娣囶喖顦查崣灞惧閸楀繗鐨熸禒鍛稊娑撳搫鎬ラ崡鐘辩秴閼板瞼宸辩亸鎴炲閹存ê鐪板▎锛勬畱闂傤噣顣介妴?

### 妞嬪酣娅撻崣妯绘纯
- 閸欏本澧滅憴锔藉付鐟欏嫬鍨弴鏉戭槻閺夊偊绱濋崣顖濆厴閺囨潙顔愰弰鎾虫嫲妞ょ敻娼板姘З閵嗕浇顕ょ憴锔跨瑢閼哄倸顨旈崚銈呯暰娴溠呮晸鏉堝湱鏅崘鑼崐閿涘苯娲滃銈夋付鐟曚線鎷＄€佃鈧?smoke test 閸ョ偛缍婇妴?

## [Unreleased-PLAN_158-HUMAN-TESTS-AUDITORY-UI-STABILITY] - 2026-05-11

### 閸樼喎娲?
- 閸氼剝顫庡ù瀣槸閸︺劌绱戞慨瀣倵娴犲秳绱伴柅姘崇箖闂冭埖顔岄弬鍥攳閵嗕焦鎸遍弨鐐絹缁€鍝勬嫲缁涘绶熼弽鍥唶閻ㄥ嫭妯夐梾鎰綁閸栨牗姣氶棁鍙夋尡閺€鐐閺堢尨绱濋崥灞炬缁屾椽妫垮ù瀣槸閸忣偄鎮滈棃銏℃緲娴兼碍濡搁垾婊冨閺傚厜鈧繀缍旀稉娲帛鐠併倝鐝禍顕嗙礉瑜板崬鎼烽悙鐟板毊閹靛鍔呴獮鑸电濠曞繒鐡熷鍫㈠Ц閹降鈧?

### 娣囶喗鏁?
- 鐏忓棗鎯夌憴澶嬬ゴ鐠囨洜娈戠粵澶婄窡/閸戝搫锛愰梼鑸殿唽閺€鑸垫殐娑撳搫鎮撴稉鈧總妤€娴愮€规岸鐝惔锔炬畱閻樿埖鈧焦蝎閿涘瞼些闂勩倖鎸遍弨鍙ヨ厬閻ㄥ嫰顣堕悳鍥ㄥ絹缁€鐚寸礉闁灝鍘ら幐澶愭尦閸栧搫鐓欓崶鐘绘▉濞堥潧鍨忛幑顫獓閻㈢喍缍呯粔姹団偓?
- 鐏忓棛鈹栭梻瀛樼ゴ鐠囨洜娈戦弬鐟版倻闁瀚ㄩ弨閫涜礋閺堫亪鈧鑵戦崚婵嗩潗閹緤绱濆鈧慨瀣倵娑撳秴鍟€姒涙顓绘妯瑰瘨閳ユ粌澧犻弬鍏夆偓婵撶礉楠炴儼顔€閹稿洭鎷″Ο鈥崇础閸︺劍婀柅澶夎厬閺冩湹绻氶幐浣疯厬閹勬▔缁€鎭掆偓?

### 娣囶喖顦?
- 娣囶喖顦插鈧慨瀣倵闁俺绻冮悾宀勬桨閸欐ê瀵查幒銊︾ゴ閹绢厽鏂侀弮鑸垫簚閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦茬粚娲？閸忣偄鎮滈棃銏℃緲閸︺劍绁寸拠鏇炵磻婵鎮楁妯款吇闁鑵戦垾婊冨閺傚厜鈧繄娈戦梻顕€顣介妴?

### 妞嬪酣娅撻崣妯绘纯
- 缁屾椽妫垮ù瀣槸閸︺劎鐡戝鍛存▉濞堥潧宓嗛崣顖濈箻鐞涘本鏌熸担宥夘暕闁绱濈憴鍡氼潕閻樿埖鈧焦娲跨粙鍐茬暰閿涘奔绲炬稊鐔峰帒鐠佸憡娲块弮鈺佷粵閸戦缚顕ら幙宥勭稊鐠佹澘缍嶉敍宀€顑侀崥鍫濈秼閸撳秵绁寸拠鏇烆嚠閹舵纭犲蹇曟畱閻╊喗鐖ｉ妴?

## [Unreleased-PLAN_157-HUMAN-TESTS-AUDITORY-WINDOWS-PLAYBACK-STALL] - 2026-05-11

### 閸樼喎娲?
- 閸氼剝顫庡ù瀣槸閸?Windows 娑撳﹣绮涙导姘毉閻滅増妲戦弰鍓ф畱閹绢厽鏂侀崥顖氬З閸楋繝銆戦妴鍌涘笓閺屻儱鎮楃涵顔款吇閿涘苯鎯庨崝銊╂懠鐠侯垶鍣烽崥灞炬鐎涙ê婀?`stop`閵嗕梗seek(Duration.zero)`閵嗕梗resume()` 閸滃奔缍呯純顔跨枂鐠囥垻鈥樼拋銈囩搼閸氬本顒為崢鐔烘晸鐠嬪啰鏁ら敍娑樺従娑?Windows 缁旑垳娈?`getCurrentPosition()` / `resume()` / `pause()` / `stop()` 闁棄褰查懗鐣岀病閻㈠崬甯悽鐔锋倱濮濄儴绔熼悾宀勬▎婵夌偑鈧?

### 娣囶喖顦?
- 閸氼垰濮╅崜宥嗘暭娑撹櫣鐡戝鍛瑐娑撯偓濞嗭繝娼ゆ妯侯槱閻炲棗鐣幋鎰剁礉閸愬秴婀箛鍛邦洣閺冩湹濞囬悽?`pause()` 閼板奔绗夐弰?`stop()` 濞撳懐鎮婅ぐ鎾冲閹绢厽鏂侀敍宀勪缉閸忓秴娲栭梿?seek 閸滃本妫ら幇蹇庣疅閻ㄥ嫬鎮撳銉╁櫢缂冾喓鈧?
- 閸樼粯甯€閹绢厽鏂侀崥顖氬З闂冭埖顔岄惃鍕▔瀵?`seek(Duration.zero)`閿涘矁顔€閺?source 閻╁瓨甯存禒?0 閹绢厽鏂侀妴?
- 鐏?Windows 娑撳娈戦幘顓熸杹閹恒劏绻樼涵顔款吇閺€閫涜礋娴滃娆㈡す鍗炲З閻?`onPositionChanged` / `onPlayerStateChanged` 閺傝顢嶉敍宀勪缉閸忓秴婀悜顓＄熅瀵板嫪绗傜拫鍐暏闂冭顢ｉ崹?`getCurrentPosition()`閵?
- 娑?`setSource`閵嗕梗waitForDuration`閵嗕梗setVolume`閵嗕梗resume()` 閸滃本甯规潻娑氣€樼拋銈埶夐崗鍛矎缁帒瀹抽懓妤佹閺冦儱绻旈敍灞肩┒娴滃骸鎮楃紒顓犳埛缂侇厼鐣炬担宥呭斧閻㈢喎鐪板鍌氱埗閵?
- Windows 濡楀矂娼扮粩顖滅埠娑撯偓娴ｈ法鏁?`ReleaseMode.release`閿涘矂浼╅崗宥呯暚閹存劖鈧浇鍤滈崝銊ユ礀闂嗚泛鐢弶銉ф畱妫版繂顦?seek 閸ｎ亜锛愰妴?

### 妞嬪酣娅撻崣妯绘纯
- 閹绢厽鏂佸鈧慨瀣€樼拋銈呮躬 Windows 娑撳﹣绮犻梼璇差敚鏉烆喛顕楅弨閫涜礋娴滃娆㈢涵顔款吇閿涘矁瀚㈡稉顏勫焼鐠佹儳顦惌顓熸畯濠曞繐褰傛担宥囩枂娴滃娆㈤敍灞肩窗閸ョ偤鈧偓閸掓壆濮搁幀浣圭墡妤犲苯鑻熸穱婵堟殌娑撯偓濞嗭繝鍣哥拠鏇樷偓?

## [Unreleased-PLAN_156-HUMAN-TESTS-AUDITORY-PLAYBACK-PROGRESS-CONFIRM] - 2026-05-11

### 閸樼喎娲?
- 閸氼剝顫庡ù瀣槸閺冦儱绻旈弰鍓с仛閹绢厽鏂侀崳銊ュ嚒鏉╂稑鍙?`playing`閿涘奔绲剧紓鍝勭毌娴ｅ秶鐤嗛幒銊ㄧ箻閺冦儱绻旈敍灞界摠閸︺劉鈧粌浜ｉ幘顓熸杹閳ユ縿鈧胶鈹栭幘顓熷灗鐠х兘鐓舵潻鐔峰煂妞嬪酣娅撻妴?

### 娣囶喖顦?
- 閸氼剝顫庡ù瀣槸閹绢厽鏂侀柧鎹愮熅閺€閫涜礋閸忓牐顔曠純顔芥拱閸?WAV 濠ф劑鈧胶鐡戝鍛讲鐠?duration閿涘苯鍟€ `seek(Duration.zero)` 閸?`resume()`閵?
- 閹绢厽鏂侀崥顖氬З閸氬海鐓潪顔款嚄 `getCurrentPosition()`閿涘瞼鈥樼拋銈勭秴缂冾喚婀″锝嗗腹鏉╂稑鎮楅幍宥堢箻閸忋儰缍旂粵鏃囶吀閺冭翰鈧?
- 閼汇儵顩诲▎?resume 閸氬簼缍呯純顔芥弓閹恒劏绻橀敍灞戒粻濮濄垹鑻熼柌宥嗘煀鐟佸懓娴囬崥灞肩婢逛即鐓跺┃鎰倵闁插秷鐦稉鈧▎鈽呯幢娴犲秴銇戠拹銉︽鐠佹澘缍嶇紒鎾寸€崠鏍晩鐠囶垰鑻熼崶鐐衡偓鈧化鑽ょ埠閹绘劗銇氶棅鐐解偓?
- Windows 濡楀矂娼扮粩顖濈儲鏉╁洣绗夐崣妤佹暜閹镐胶娈?`AudioContext` 鐠佸墽鐤嗛敍灞藉櫤鐏忔垶妫ら弫鍫濋挬閸欑増妫╄箛妤€顕幒鎺楁閻ㄥ嫬鍏遍幍鑸偓?

### 妞嬪酣娅撻崣妯绘纯
- 鐠х兘鐓剁涵顔款吇娴兼艾顤冮崝鐘茬毌闁插繐鎯庨崝銊х搼瀵板拑绱濇担鍡氬厴闁灝鍘よぐ鎾冲鏉烆喗婀€圭偤妾崣鎴濓紣鐏忚精绻橀崗銉ょ稊缁涙梹鍨ㄦ稉瀣╃鏉烆喚娈戦悩鑸碘偓渚€鏁婃担宥冣偓?

## [Unreleased-PLAN_155-HUMAN-TESTS-AUDITORY-ROUNDS-LATE-AUDIO] - 2026-05-11

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閸氼剝顫庡ù瀣槸娴犲秵婀佺亸鎴﹀櫤婢逛即鐓跺鍌氱埗閿涘矁銆冮悳鏉垮剼瑜版挸澧犳潪顔硷紣闂婂疇绻曞▽鈩冩尡閸戝搫姘ㄦ潻娑樺弳娑撳绔存潪顔兼倵閹靛秴鎼烽敍娑樻倱閺冩儼顩﹀Ч鍌涚ゴ鐠囨洝绻樻惔锕佺枂閺佹澘褰查懛顏勭暰娑斿绱濋獮璺虹殺妫版垹宸煎Ο鈥崇础姒涙顓婚弨閫涜礋 10 鏉烆喓鈧?

### 娣囶喗鏁?
- 閸氼剝顫庡ù瀣槸閻ㄥ嫭绁寸拠鏇☆潐濡€茬矤閸ュ搫鐣鹃柅澶愩€嶉弨閫涜礋閸欘垵鐨熸潪顔芥殶濠婃垶娼岄敍宀勵暥閻滃洦膩瀵繘绮拋銈堢枂閺佺増鏁兼稉?10 鏉烆喓鈧?
- 妫版垹宸奸妴浣轰紥閺佸繐瀹抽崪宀€鈹栭梻鏉戠碍閸掓鏁撻幋鎰帒鐠?10 鏉烆喖鎻╅柅鐔虹摣閺屻儻绱濋獮鑸靛瘻濡€崇础闂勬劕鍩楅張鈧径褑鐤嗛弫甯礉闁灝鍘ゆ潻娑樺閺勫墽銇氶崪灞界杽闂勫懎绨崚妤呮毐鎼达缚绗夋稉鈧懛娣偓?

### 娣囶喖顦?
- 閹绢厽鏂侀柧鎹愮熅閸︺劍鐦℃稉顏勭磽濮濄儵妯佸▓鍨梾閺屻儱缍嬮崜宥嗘尡閺€鎯х碍閸掓褰块敍灞借嫙閺€閫涜礋閹绢厽鏂侀崨鎴掓姢閸欐垵鍤崥搴″晙鏉╂稑鍙嗘担婊呯摕鐠佲剝妞傞敍娑毿╅梽銈呮鏉?`seek/resume` 閸忔粌绨抽敍宀勪缉閸忓秷绻滈崚鎷屾崳闂婂疇娉曟潪顔芥尡閺€淇扁偓?
- 鐞涖儱娲栭崥鍫熷灇濞夈垹鑸伴惃鍕翻閸戞椽鐓堕柌蹇曢兇閺佸府绱濇担鎸庢尡閺€鎯ф珤濠婏繝鍣虹粙瀣娴犲秶鏁遍崚鐑樼负閺堫剝闊╅幒褍鍩楁０鎴犲芳閵嗕胶浼掗弫蹇撳閸滃瞼鈹栭梻瀛樐佸蹇曟畱鐎圭偤妾崫宥呭閵?

### 妞嬪酣娅撻崣妯绘纯
- 10 鏉烆噣顣堕悳鍥ㄧゴ鐠囨洘娲块柅鍌氭値韫囶偊鈧喓鐡弻銉礉閹躲儱鎲￠崚鍡欑矋閸欘垵鍏樻潏鍐枅閻ゅ骏绱卞锝呯础鐠囧嫪鍙婃禒宥呯紦鐠侇喗澧滈崝銊﹀絹妤傛鐤嗛弫鑸偓?

## [Unreleased-PLAN_154-HUMAN-TESTS-AUDITORY-PLAYBACK-ANTI-PREDICTION] - 2026-05-11

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯瀹搞儱鍙跨粻?娴滆櫣琚ù瀣槸娑擃厼绺?閸氼剝顫庡ù瀣槸濡€虫健鐎涙ê婀径褔鍣烘竟浼寸叾閺冪姵纭跺锝呯埗閹绢厽鏂侀妴浣规尡閺€鍙ヨ厬妫版垹宸兼稉宥呭讲鐟欎降鈧焦绁寸拠鏇＄箖缁嬪褰查懗鍊燁潶妫板嫬鎯?鐟欏嫬绶ラ幒銊︽焽閿涘奔浜掗崣濠勭搼瀵板懏褰佺粈楦垮Ν婵傚繗绻冩禍搴ゎ潐閸掓瑧娈戦梻顕€顣介妴?

### 閺傛澘顤?
- 閸氼剝顫庡ù瀣槸閸︺劑顣堕悳鍥︾瑢閻忓灚鏅辨惔锔侥佸蹇曟畱閹绢厽鏂侀梼鑸殿唽閺勫墽銇氳ぐ鎾冲婢逛即鐓舵０鎴犲芳閿涘瞼鈹栭梻鏉戠暰娴ｅ秵膩瀵繒鎴风紒顓缉閸忓秵姣氶棁鍙夋煙閸氭垹鐡熷鍫涒偓?
- 缁涘绶熸竟浼寸叾閺冭埖鏌婃晶鐐扮瑝鐟欏嫬鍨粵澶婄窡閺嶅洩顔囬敍灞借嫙閹碘晛銇囬梾蹇旀簚缁涘绶熼崠娲？閿涘矂妾锋担搴ｆ暏閹撮攱瀵滈崶鍝勭暰閼哄倸顨旈悮婊勭ゴ閻ㄥ嫬褰查懗鑺モ偓褋鈧?

### 娣囶喗鏁?
- 閸氼剝顫庡ù瀣槸閻ㄥ嫬鎮庨幋鎰扮叾閺€閫涜礋閹绘劕澧犻悽鐔稿灇楠炲墎绱︾€涙ü澶嶉弮?WAV 閺傚洣娆㈤敍灞藉晙闁俺绻冮張顒€婀撮弬鍥︽濠ф劖鎸遍弨鎾呯礉閺囧じ鍞惄瀛樺复鐎涙濡┃鎰瑢娴ｅ骸娆㈡潻鐔改佸蹇嬧偓?
- 妫版垹宸兼稉搴ｄ紥閺佸繐瀹虫潪顔筋偧閺€閫涜礋闂呭繑婧€妞ゅ搫绨敍灞剧ゴ鐠囨洝绻樼悰灞艰厬缁備胶鏁ゆ０鍕儔/闁插秵鎸遍敍灞借嫙缁夊娅庢潻娑滎攽娑擃厾娈戦梼鍫濃偓鍏煎絹缁€鍝勭磻閸忕偨鈧?
- 妤傛﹢顣堕幋顏咁剾娴兼媽顓搁弨閫涜礋閹躲儱鎲￠梼鑸殿唽閹稿顔囪ぐ鏇☆吀缁犳绱濇稉宥呭晙閸︺劍绁寸拠鏇＄箖缁嬪鑵戠紒瀛樺Б妫板嫭绁撮悩鑸碘偓浣瑰灗閹绘劕澧犵紒鎾存将妤傛﹢顣舵潪顔筋偧閵?
- 閸氼剝顫庨崥鍫熷灇闂婂磭娈戦幘顓熸杹閸ｃ劑鐓堕柌蹇撴祼鐎规矮璐熷锟犲櫤缁嬪绱濇潏鎾冲毉瀵搫鎬ラ崣顏嗘暠閸氬牊鍨氬▔銏犺埌閺堫剝闊╅幒褍鍩楅敍宀勪缉閸忓秵灏濊ぐ銏犳嫲閹绢厽鏂侀崳銊ュ蓟闁插秷鈥滈崙蹇嬧偓?

### 娣囶喖顦?
- 娣囶喖顦查柈銊ュ瀻楠炲啿褰存稉濠傛値閹存劙鐓剁€涙濡┃鎰尡閺€鍙ョ瑝缁嬪啿鐣剧€佃壈鍤ф径褔鍣烘竟浼寸叾閺冪姵纭跺锝呯埗閹绢厽鏂侀惃鍕６妫版ǜ鈧?
- 娣囶喖顦查悘鍨櫛鎼达妇鐡戞担搴ょ翻閸戦缚鐤嗗▎陇顫︽禍灞绢偧闂婃娊鍣虹悰鏉垮櫤閸樺鍩岄幒銉ㄧ箮闂堟瑩鐓堕惃鍕６妫版﹫绱濋獮璺烘躬閹绢厽鏂侀崥顖氬З閸氬骸顤冮崝鐘辩秴缂冾喗甯规潻娑欘梾閺屻儻绱遍懟銉︽尡閺€鎯ф珤鏉╂稑鍙?playing 娴ｅ棔缍呯純顔芥弓閹恒劏绻橀敍灞肩窗閸ョ偛鍩岀挧椋庡仯闁插秷鐦稉鈧▎掳鈧?
- 閸濆秴绨查妴渚€鍣哥純顔藉灗缂佹挻娼弮鏈靛瘜閸斻劌浠犲銏犵秼閸撳秵鎸遍弨鎯ф珤閿涘矂浼╅崗宥呯啲闂婅櫕瀚嬮崗銉ょ瑓娑撯偓鏉烆喓鈧?

### 妞嬪酣娅撻崣妯绘纯
- 娑撳瓨妞傞弬鍥︽閹绢厽鏂佹导姘▏閻劎閮寸紒鐔跺閺冨墎娲拌ぐ鏇犵处鐎涙ê鎮庨幋?WAV閿涙稖瀚㈢拋鎯ь槵娑撳瓨妞傞惄顔肩秿娑撳秴褰查崘娆欑礉娴犲秳绱伴崶鐐衡偓鈧崚鎵兇缂佺喐褰佺粈娲叾楠炶埖妯夌粈鐑樻尡閺€楣冩晩鐠囶垬鈧?

## [Unreleased-PLAN_153-HUMAN-TESTS-ACOUSTIC-EXPERIMENT-ORDER-FIX] - 2026-05-10

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴鐏忓棝瀹抽崗瀣棑婢规澘顒熺€圭偤鐛欓幏鍡楀瀻娑撹桨姹夌猾缁樼ゴ鐠囨洑鑵戣箛鍐ㄥ敶閻ㄥ嫮瀚粩瀣侀崸妞烩偓婊冿紣鐎涳箑鐤勬灞糕偓婵撶礉楠炴湹鎱ㄥ锝勬眽缁粯绁寸拠鏇氳厬韫囧啯膩閸ф瀚嬮崝銊ユ倵閹烘帒绨担宥囩枂娑撳秴鐤勯梽鍛晸閺佸牏娈戦梻顕€顣介妴?

### 閺傛澘顤?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃弬鏉款杻閳ユ粌锛愮€涳箑鐤勬灞糕偓婵堝缁斿鍙嗛崣锝忕礉閹佃儻娴囨ス锕€鍘犳搴濈秵闂婄偨鈧線鐝棅鐐解偓浣瑰瘮缂侇厼鎷伴崳顏勶紣娴狀亜鐤勬灞烩偓?

### 娣囶喗鏁?
- 閸氼剝顫庡ù瀣槸妞ゅ吀绮庢穱婵堟殌闂婃娊鍣洪弽鈥冲櫙娑撳酣顣堕悳鍥モ偓浣轰紥閺佸繐瀹抽妴浣衡敄闂傚瓨绁寸拠鏇熸拱娴ｆ搫绱濇ス锕€鍘犳搴＄杽妤犲奔绗夐崘宥嗚穿閹烘帒鍙炬稉顓溾偓?
- 娴滆櫣琚ù瀣槸娑擃厼绺惧Ο鈥虫健閹锋牕濮╅幒鎺戠碍閺€閫涜礋閸樼喎顫愰幐鍥嫛鏉╁€熼嚋閿涘本瀚嬮崝銊よ厬娴犮儵顣╃憴鍫ャ€庢惔蹇旇閺屾搫绱濋弶鐐閸氬骸鍟撻崗銉ょ窗鐠囨繂绔风仦鈧紓鎾崇摠閿涙稒瀚嬮崗銉⑩偓婊勫灉閻ㄥ嫬浼愰崗灏佲偓婵呯矝閸欘垰濮為崗銉ユ彥閹瑰嘲鍙嗛崣锝冣偓?

### 娣囶喖顦?
- 娣囶喗顒滈幏鏍уЗ娑擃參顣╃憴鍫ャ€庢惔蹇氼潶閺冄呮畱瀹稿弶褰佹禍銈夈€庢惔蹇氼洬閻╂牭绱濈€佃壈鍤ч弶鐐閸氬孩膩閸фぞ绮涢崶鐐插煂閸樼喍缍呯純顔炬畱闂傤噣顣介妴?

### 妞嬪酣娅撻崣妯绘纯
- 閹烘帒绨悩鑸碘偓浣哥秼閸撳秳浜掓导姘崇樈缂傛挸鐡ㄦ稉杞板瘜閿涘奔绮涢張顏呭复閸忋儲娲垮鐑樺瘮娑斿懎瀵茬€涙ê鍋嶉敍娑樺彠闂傤厼绨查悽銊ユ倵娴兼碍浠径宥夌帛鐠併倕绔风仦鈧妴?

## [Unreleased-PLAN_152-HUMAN-TESTS-AUDITORY-MEDICAL-GRADE] - 2026-05-10

### 閸樼喎娲?
- 缂佈呯敾閹跺﹤浼愰崗椋庮唸-娴滆櫣琚ù瀣槸娑擃厼绺鹃惃鍕儔鐟欏膩閸ф鏁归崣锝呭煂閺囩繝绗撴稉姘モ偓浣规纯鐎圭偟鏁ら惃鍕拱閸︽媽鍤滃Λ鈧仦鍌滈獓閿涘苯宸遍崠鏍暥閻滃洢鈧胶浼掗弫蹇撳閵嗕胶鈹栭梻鏉戠暰娴ｅ秲鈧胶閮寸紒鐔肩叾闁插繈鈧線瀹抽崗瀣棑婢规澘顒熼崪灞芥珨闂婂啿鍨庣拹婵婂厴閸旀稏鈧?

### 閺傛澘顤?
- 缁崵绮烘刊鎺嶇秼闂婃娊鍣洪崥顖氬З濡偓閺屻儲鏁幐浣藉殰閸斻劍鐗庨崙鍡礉閺冪姵纭堕懛顏勫З鐠嬪啯鏆ｉ弮鏈电窗閻╁瓨甯撮幓鎰仛閹靛濮╂穱顔筋劀閵?
- 妤癸箑鍘犳搴＄杽妤犲矁藟閸忓懏娲哥痪鍨挬濠婃垵瀹抽妴浣哄箚婢у啳鐦庨崚鍡楁嫲閸ｎ亪鐓堕崚鍡氱閹稿洨銇氶敍灞肩秵闂?妤傛﹢鐓?閹镐胶鐢?閸ｎ亪鐓堕崶娑楅嚋濡€崇础閺囨潙鐣弫娣偓?
- 缁屾椽妫垮ù瀣槸閺€閫涜礋閸忣偄鎮滈幍顒€锛愰崳銊ф磸娑撳骸褰查幏鏍ㄥ閺傜懓鎮滈幐鍥嫛閿涘苯宸辩拫鍐敄闂傚瓨鏌熸担宥呭灲閺傤厺绗岄崑蹇撴▕鐠佹澘缍嶉妴?

### 娣囶喗鏁?
- 妫版垹宸煎ù瀣槸閺€閫涜礋閺囨挳鏆遍惃鍕偓鎺曠箻鎼村繐鍨敍宀勵暥閻滃洢鈧線鐓堕柌蹇撴嫲閼哄倸顨旀径宥嗘絽鎼达箓鈧劖顒為幎顒€宕岄敍灞炬汞濞堢敻浜ｉ崚浼寸彯妫版垼绻涚紒顓熺础濡偓閺冭埖褰侀崜宥嗘暪閸欙絻鈧?
- 閹绢厽鏂侀梼鑸殿唽娑撳秴鍟€閺勫墽銇氶崚鐑樼负妤傛ü瀵掗幋鏍摕濡楀牊褰佺粈鐚寸礉闂勫秳缍嗛崥顒冾潕楠炲弶澹堥崪宀冾潒鐟欏缍斿濠勨敄闂傛番鈧?
- 閻忓灚鏅辨惔锔界ゴ鐠囨洘鏁兼稉鐑樻纯閹恒儴绻庨梼鑸殿潽濞夋洜娈戦柌宥咁槻妤犲矁鐦夌紒鎾寸€敍灞借嫙鏉堟挸鍤梼鍫濃偓闂村強鐠伮扳偓?

### 妞嬪酣娅撻崣妯绘纯
- 缂佹挻鐏夋禒宥呭涧闁倸鎮庢担婊€璐熼張顒€婀撮懛顏呯叀閸欏倽鈧喛绱濇稉宥嗙€幋鎰鞍鐎涳箒鐦栭弬顓ㄧ幢缁屾椽妫跨€规矮缍呮禒宥呯唨娴滃氦顔曟径鍥ㄥ婢规澘娅掗崪灞炬拱閸︽澘鎮庨幋鎰紣缁捐法鍌ㄩ敍灞肩瑝缁涘鎮撴稉鏉戠哎 HRTF 濞村鐦妴?

## [Unreleased-PLAN_150-HUMAN-TESTS-AUDITORY-PRO-LAB-VERIFY] - 2026-05-10

### 閸樼喎娲?
- 缂佈呯敾閺€璺哄經瀹搞儱鍙跨粻?娴滆櫣琚ù瀣槸娑擃厼绺?閸氼剝顫庡ù瀣槸濡€虫健閿涘奔濞囬崗鑸垫纯閹恒儴绻庢稉鎾茬瑹閼奉亝顥呴崪灞炬拱閸︽澘锛愮€涳箑鐤勬灞戒紣閸忔灚鈧?
### 閺傛澘顤?
- 閹绢厽鏂侀崜宥囬兇缂佺喎鐛熸担鎾荤叾闁插繑顥呴弻銉ょ瑢 Android 閼奉亜濮╃拫鍐╂殻濡椼儲甯撮敍瀹∣S 閸滃奔绗夐弨顖涘瘮楠炲啿褰存穱婵堟殌閹靛濮╅弽鈥冲櫙閹绘劗銇氶妴?
- 妤癸箑鍘犳搴★紣鐎涳箑鐤勬灞藉隘閿涘矁顩惄鏍︾秵闂婄偨鈧線鐝棅鐐解偓浣瑰瘮缂侇厼鎷伴崳顏堢叾鐟欏倸鐧傞妴?
### 娣囶喗鏁?
- 妫版垹宸煎ù瀣槸閺€閫涜礋閺囨挳鏆遍惃鍕偓鎺曠箻瀵繐绨崚妤嬬礉楠炶泛骞撻梽銈嗘尡閺€楣冩▉濞堢數娈戞妯瑰瘨/缁涙梹顢嶉幓鎰仛閵?
- 閻忓灚鏅辨惔锔界ゴ鐠囨洘鏁兼稉鐑樻纯閸嶅繘妯佸顖涚《閻ㄥ嫰鈧帟绻樻稉搴ㄥ櫢婢跺秶鈥樼拋銈冣偓?
- 缁屾椽妫垮ù瀣槸閺€閫涜礋 8 閸氭垵鐣炬担宥呭濠婃垵濮╅幐鍥嫛閸忋儱褰涢敍宀冾唶瑜版洘鏌熸担宥呬焊瀹割喓鈧?
### 娣囶喖顦?
- 娣囶喗顒滅粚娲？鏉烆喗顐兼妯款吇缁涙梹顢嶅▔鍕础闂傤噣顣介敍灞借嫙濞撳懐鎮婃稉宥呭讲鏉堝墽娈戦弮褍鐤勯悳鏉垮瀻閺€顖樷偓?
### 妞嬪酣娅撻崣妯绘纯
- 缂佹挻鐏夋禒宥囧姧閺勵垱婀伴崷鎷屽殰閺屻儱寮懓鍐跨礉娑撳秵鐎幋鎰鞍鐎涳箒鐦栭弬顓溾偓?

## [Unreleased-PLAN_150-HUMAN-TESTS-AUDITORY-PRO-LAB] - 2026-05-10

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴鐏忓棗浼愰崗椋庮唸-娴滆櫣琚ù瀣槸娑擃厼绺?閸氼剝顫庡ù瀣槸閹恒劏绻橀崚鐗堟纯娑撴挷绗熼妴浣哥杽閻劊鈧焦婀侀弫鍫㈡畱閺堫剙婀撮懛顏呯叀濮樻潙閽╅敍灞藉繁閸栨牠顣堕悳鍥モ偓浣轰紥閺佸繐瀹抽妴浣衡敄闂傛潙鐣炬担宥冣偓浣筋啎婢跺洭鐓堕柌蹇旑梾閺屻儯鈧線瀹抽崗瀣棑婢规澘顒熼崪灞芥珨闂婂啿鍨庣拹婵婂厴閸旀稏鈧?

### 閺傛澘顤?
- 閺傛澘顤冮幘顓熸杹閸撳秶閮寸紒鐔风崯娴ｆ捇鐓堕柌蹇旑梾閺屻儻绱癆ndroid 闁俺绻?`vocabulary_sleep/system_audio` 鐠囪褰囬獮璺虹毦鐠囨洝鐨熼弫鏉戠崯娴ｆ捇鐓堕柌蹇ョ礉iOS 鐠囪褰囪ぐ鎾冲鏉堟挸鍤棅鎶藉櫤楠炶埖褰佺粈鐑樺閸斻劍鐗庨崙鍡愨偓?
- 閺傛澘顤冩ス锕€鍘犳搴★紣鐎涳箑鐤勬灞藉隘閿涘本鏁幐浣风秵闂婄偨鈧線鐝棅鐐解偓浣瑰瘮缂侇厼褰傛竟鏉挎嫲閸ｎ亪鐓堕崚鍡氱娴狀亷绱濋弰鍓с仛 dBFS閵嗕礁鍢查崐绗衡偓渚€鐓舵妯糕偓浣呵旂€规艾瀹抽崪灞惧瘮缂侇厽鈧勬锤缁捐￥鈧?
- 缁屾椽妫垮ù瀣槸閺傛澘顤冮崗顐㈡倻婢圭増绨棃銏℃緲娑撳孩绮﹂崝銊﹀瘹闁藉牆鐣炬担宥呭弳閸欙綇绱濈拋鏉跨秿閻劍鍩涢柅澶嬪閺傞€涚秴閸滃瞼娲伴弽鍥э紣濠ф劒绠ｉ梻瀵告畱鐟欐帒瀹抽崑蹇撴▕閵?

### 娣囶喗鏁?
- 妫版垹宸煎ù瀣槸閺€閫涜礋閺囨挳鏆遍惃鍕偓鎺曠箻瀵繘顣堕悳?闂婃娊鍣?閼哄倸顨旀惔蹇撳灙閿涘矂鈧劖顒為幓鎰扮彯妫版垹宸奸妴渚€鐓堕柌蹇撴嫲閼哄倸顨旀径宥嗘絽鎼达负鈧?
- 閸氼剝顫庡ù瀣槸閹绢厽鏂侀梼鑸殿唽閸欐牗绉锋妯瑰瘨閼冲本娅欓崪灞界秼閸撳秴鍩″┑鈧幓鎰仛閿涘矂浼╅崗宥囨暏閹寸兘鈧俺绻冪憴鍡氼潕閸欐ê瀵查幋鏍摕濡楀牊褰佺粈杞扮稊瀵鈧?
- 閻忓灚鏅辨惔锔界ゴ鐠囨洘鏁兼稉鐑樻纯缂佸棛娈戦梼鑸殿潽鎼村繐鍨稉搴ㄥ櫢婢跺秹鐛欑拠浣虹波閺嬪嫸绱濋悽銊ょ艾娴兼媽顓搁崣顖氭儔闂冨牆鈧鈧?

### 妞嬪酣娅撻崣妯绘纯
- 瑜版挸澧犻崥顒冾潕缂佹挻鐏夋禒宥勭贩鐠ф牞顔曟径鍥ㄥ婢规澘娅?閼拌櫕婧€閵嗕胶閮寸紒鐔肩叾闁插繈鈧胶骞嗘晶鍐ㄦ珨闂婂啿鎷版ス锕€鍘犳搴ｂ€栨禒璁圭礉娴犲懍缍旀稉鐑樻拱閸︽媽鍤滈弻銉ㄧ窡閸斺晪绱濇稉宥嗙€幋鎰鞍鐎涳箒鐦栭弬顓溾偓?
- 缁屾椽妫跨€规矮缍呮担璺ㄦ暏閸欏苯锛愰柆鎾筹紣閸嶅繐鎷版潪濠氬櫤妫版垹宸奸崣妯哄濡剝瀚欑粚娲？缁捐法鍌ㄩ敍灞肩瑝缁涘鎮撴稉鎾茬瑹 HRTF 閹存牔澶嶆惔濠勨敄闂傛潙鎯夌憴澶庮啎婢跺洢鈧?

## [Unreleased-PLAN_150-HUMAN-TESTS-AUDITORY-TEST] - 2026-05-09

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴鐏忓棗浼愰崗椋庮唸-娴滆櫣琚ù瀣槸娑擃厼绺?閸氼剝顫庢禒搴樷偓婊冩儔鐟欏寮芥惔鏂衡偓婵婄殶閺佺繝璐熼垾婊冩儔鐟欏绁寸拠鏇椻偓婵撶礉楠炶泛鐨㈡０鎴犲芳閵嗕線鐓堕柌蹇嬧偓浣革紣闁挷绗佺猾缁樻＋濡剝瀚欏ù瀣槸闁插秵鐎稉鐑樻纯鐎瑰本鏆ｉ惃鍕儔閹扮喕鐦庢导鑸偓?

### 閺傛澘顤?
- 閸氼剝顫庡ù瀣槸閺傛澘顤冩稉澶岃濡€崇础閿涙岸顣堕悳鍥槑娴艰埇鈧礁鎯夐崝娑氫紥閺佸繐瀹抽妴浣革紣闂婂磭鈹栭梻娣偓?
- 妫版垹宸肩拠鍕強閺€顖涘瘮 10/12/16/20 缂佸嫬鍨庨弸鎰┾偓渚€顣堕悳鍥瘱閸ユ番鈧焦绁寸拠鏇炪亣鐏忓繈鈧線顣堕悳鍥叾闁插繈鈧浇濡總蹇擄紣闁插繐褰夐崠鏍ф嫲閼哄倸顨斿ǎ宄版値鐠佸墽鐤嗛妴?
- 閸氼剙濮忛悘鍨櫛鎼达附鏁幐浣哥唨閸戝棝顣堕悳鍥モ偓渚€鐓堕柌蹇涙▉閺佽埇鈧焦娓舵担?閺堚偓妤傛绶崙鎭掆偓浣割嚠閺佷即妯佸顖氭嫲闂冨牆鈧吋褰佺粈楦款啎缂冾喓鈧?
- 婢逛即鐓剁粚娲？閺€顖涘瘮 8/12/16 娑擃亝鏌熼崥鎴欌偓浣藉殰鐎规矮绠熼弬鐟版倻閵嗕胶鈹栭梻鎾叾闁插繈鈧礁鍨界€规艾顔愬顔衡偓浣圭拨閺夊棗閽╁鎴濇嫲閺傜懓鎮滈弽鍥╊劮鐠佸墽鐤嗛妴?
- 鐎瑰本鍨氶幎銉ユ啞閺傛澘顤冮崚鍡欑矋閺勫海绮忛妴浣稿斧婵顔囪ぐ鏇炵磻閸忕偨鈧線鍣搁幘?鐠囨洖鎯夐幒褍鍩楅崪灞界唨娴滃酣顣堕悳鍥モ偓浣轰紥閺佸繐瀹抽妴浣衡敄闂傜顕ゅ顔炬畱瀵ら缚顔呴弬鍥攳閵?

### 娣囶喗鏁?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃崥顒冾潕閸忋儱褰涢弬鍥攳娴犲簶鈧穾uditory reaction / 閸氼剝顫庨崣宥呯安閳ユ繃鏁归崣锝勮礋閳ユ穾uditory test / 閸氼剝顫庡ù瀣槸閳ユ縿鈧?
- 閺冄€鈧粓鐓堕柌蹇旂ゴ鐠囨洍鈧繃鏁兼稉琛♀偓婊冩儔閸旀稓浼掗弫蹇撳濞村鐦垾婵撶礉閺冄€鈧粌锛愰柆鎾寸ゴ鐠囨洍鈧繃鏁兼稉琛♀偓婊冿紣闂婂磭鈹栭梻瀛樼ゴ鐠囨洍鈧繐绱濋悽銊﹀煕闁俺绻冨鎴炴綄閸ョ偞濮ょ粩瀣╃秼缁屾椽妫挎担宥囩枂閵?
- 閺囧瓨鏌?smoke test 娑撳孩膩閸ф顕╅弰搴礉鐟曞棛娲婇弬鐗埬佸蹇撴嫲閸忔娊鏁懛顏勭暰娑斿顔曠純顕€銆嶉妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒宥勫▏閻劍婀伴崷鏉挎値閹?WAV 娑撳氦顔曟径鍥翻閸戠儤膩閹风噦绱濈紒鎾寸亯娴犲懐鏁ゆ禍搴ゅ殰閹存垼顫囩€电噦绱濇稉宥嗘禌娴狅絼绗撴稉姘儔閸旀稒顥呴弻銉ｂ偓?
- 缁屾椽妫跨€规矮缍呮担璺ㄦ暏瀹革箑褰告竟浼翠壕婢х偟娉潻鎴滄妧閺傞€涚秴閿涘奔绗夊鏇炲弳 HRTF 閹存牔绗撴稉姘扁敄闂傛挳鐓舵０鎴濈穿閹垮簺鈧?

## [Unreleased-PLAN_151-HUMAN-TESTS-DRAG-MOTION-TOOLBOX-EDIT] - 2026-05-09

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯娴滆櫣琚ù瀣槸娑擃厼绺鹃崣灞藉灙鐢啫鐪幏鏍уЗ閺冨墎宸辩亸鎴濆従娴犳牕娴橀弽鍥闂呭繗鐨熼弫瀵告畱閸斻劍鏅ラ敍灞芥倱閺冭泛绗囬張娑樹紣閸忛顔堟＃鏍€夐幏鏍уЗ閺夋儳绱戦崥搴ゅ殰閸斻劑鈧偓閸戣櫣绱潏鎴炩偓渚婄礉娑撳秴鍟€娓氭繆绂嗛崡鏇犲閻愮懓鍤€瑰本鍨氶妴?

### 娣囶喗鏁?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃崗銉ュ經缂冩垶鐗搁弨閫涜礋閸ュ搫鐣惧Σ鎴掔秴閸斻劎鏁剧敮鍐ㄧ湰閿涘本瀚嬮崝銊﹀笓鎼村繑妞傞崗鏈电铂閸忋儱褰涙导姘舵妫板嫯顫嶆い鍝勭碍濠婃垵濮╅幑顫秴閿涘本婢楀鈧崥搴ｇ埠娑撯偓绾喛顓婚幋鏍ф礀濠婃碍瀚嬮崝銊уЦ閹降鈧?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃崗銉ュ經閸楋紕澧栨潻娑楃濮濄儱甯囩紓鈺€璐熸径褍娴橀弽鍥ф儙閸斻劌娅掗弽宄扮础閿涘矂妾锋担搴ㄦ毐閺傚洦顢嶉崡鐘垫暏閿涘奔绻氶悾?tooltip 閸滃奔绨╃痪褔銆夐棃銏犵暚閺佺顕╅弰搴涒偓?
- 瀹搞儱鍙跨粻閬嶎浕妞ょ數绱潏鎴炩偓浣瑰复閸忋儲瀚嬮崝銊ョ磻婵?缂佹挻娼悩鑸碘偓渚婄礉閹锋牕濮╅幒鎺戠碍閺夋儳绱戦崥搴ゅ殰閸斻劑鈧偓閸戣櫣绱潏鎴炩偓渚婄礉楠炶泛鐨㈤弰鎯х础鐎瑰本鍨氶幐澶愭尦閺€閫涜礋闁偓閸戣櫣绱潏鎴ｎ嚔娑斿鈧?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒宥呭涧鐠嬪啯鏆ｇ仦鏇犮仛鐏炲倷绗岄幏鏍уЗ閸欏秹顩敍灞肩瑝閺€鐟板綁瀹搞儱鍙跨粻杈侀崸妤€鎯庨崑婧库偓浣界熅閻究鈧焦瀵旀稊鍛缂佹挻鐎幋鏍у徔娴ｆ挷姹夌猾缁樼ゴ鐠囨洖鐡欐い鐢告桨闁槒绶妴?

## [Unreleased-PLAN_149-HUMAN-TESTS-GRID-POLISH] - 2026-05-09

### 閸樼喎娲?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃弨閫涜礋閸欏苯鍨崥搴礉閸樼喍淇婇幁顖氬幢閻楀洤婀幍瀣簚娑撳﹥妯夊妤佸閹搞倖璐╂稊鎲嬬礉闂団偓鐟曚浇绻樻稉鈧銉︽暪閺佹稐璐熼弴瀛樼閻栫晫娈戠粔璇插З缁旑垰浼愰崗宄板弳閸欙絻鈧?

### 娣囶喗鏁?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃崣灞藉灙閸忋儱褰涢弨閫涜礋婢堆冩禈閺嶅洤鎯庨崝銊ユ珤閺嶅嘲绱￠敍灞煎▏閻劎鐓弽鍥暯閵嗕椒绔寸悰灞藉弿閸氬秴鎷伴崶鍝勭暰妤傛ê瀹抽敍宀€些闂勩倕宕遍悧鍥у敶闂€鑳嚛閺勫簺鈧?
- 妞ゅ爼鍎撮垾婊勫灉閻ㄥ嫬浼愰崗灏佲偓婵嗗隘閸╃喎甯囩紓鈺€璐熼弴纾嬩氦閻ㄥ嫬鎻╅幑宄颁紣閸忛攱鐖敍灞芥彥閹瑰嘲鍙嗛崣锝呮禈閺嶅洦娲跨亸蹇嬧偓渚€娼伴弶鑳珶閻ｅ本娲块崗瀣煑閵?
- 鐠嬪啯鏆ｇ純鎴炵壐闂傜绐涢妴浣瑰珛閸斻劌寮芥＃鍫濐啍鎼达箑鎷板ù瀣槸閺傤叀鈻堢€圭懓妯婇敍灞肩箽閹镐礁甯張澶嬪潑閸旂姰鈧焦瀚嬮崝銊﹀潑閸旂姴鎷伴幒鎺戠碍鐞涘奔璐熸稉宥呭綁閵?

### 妞嬪酣娅撻崣妯绘纯
- 閸忋儱褰涢崡锛勫娑撳秴鍟€閻╁瓨甯寸仦鏇犮仛鐎瑰本鏆ｇ拠瀛樻閿涙稑鐣弫纾嬵嚛閺勫簼绮涙穱婵堟殌閸︺劏绻橀崗銉ュ徔娴ｆ挻绁寸拠鏇€夐崥搴ｆ畱妞ょ敻娼版径鎾劥閸滃本膩閸ф鍞撮柈銊︽瀮濡楀牅鑵戦妴?

## [Unreleased-PLAN_147-HUMAN-TESTS-QUICK-LAYOUT] - 2026-05-09

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴娴兼ê瀵插銉ュ徔缁?娴滆櫣琚ù瀣槸娑擃厼绺鹃崥鍕侀崸妤呫€庢惔蹇ョ礉娴ｅ灝鍙嗛崣锝嗘纯閸氬牏鎮婇敍娑櫮侀崸妤€灏柌鍥╂暏娑撯偓鐞涘苯寮婚崚妤嬬礉楠炶埖鏁幐渚€鏆遍幐澶嬪珛閸斻劍甯撴惔蹇撴嫲閹锋牕濮╁ǎ璇插閸掍即銆婇柈銊ユ彥閹瑰嘲鍙嗛崣锝冣偓?

### 閺傛澘顤?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃弬鏉款杻妞ゅ爼鍎撮垾婊勫灉閻ㄥ嫬浼愰崗灏佲偓婵嗘彥閹瑰嘲鍙嗛崣锝呭隘閿涘本鏁幐浣哄仯閸戠粯鍧婇崝鐘冲瘻闁筋噣鈧瀚ㄥù瀣槸濡€虫健閵?
- 閺€顖涘瘮闂€鎸庡瘻濞村鐦崡锛勫閹锋牕濮╅敍灞界殺濡€虫健閸旂姴鍙嗘い鍫曞劥韫囶偅宓庨崗銉ュ經閿涙稒婢楀鈧崥搴ゅ殰閸斻劑鈧偓閸戠儤瀚嬮崝銊уЦ閹降鈧?

### 娣囶喗鏁?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃崗銉ュ經閺€閫涜礋缁毖冨櫨閸欏苯鍨崡锛勫鐢啫鐪敍灞借嫙閹稿寮芥惔?閹垮秳缍旈妴浣筋唶韫囧棎鈧浇顫嬬憴澶婃儔鐟欏鈧浇顓婚惌銉︽暈閹板繈鈧礁宕楃拫鍐︹偓浣界翻閸忋儱奴娑旀劗娈戠捄顖氱窞闁插秵鏌婇弫瀵告倞姒涙顓绘い鍝勭碍閵?
- 濞村鐦崗銉ュ經閸楋紕澧栨晶鐐插閻厽鐖ｆ０妯烘嫲缁嬪啿鐣?ID閿涘瞼鏁ゆ禍搴℃彥閹瑰嘲鍙嗛崣锝呯潔缁€鎭掆偓浣瑰珛閸斻劍甯撴惔蹇庣瑢濞村鐦憰鍡欐磰閵?
- 閺囧瓨鏌婃禍铏硅濞村鐦稉顓炵妇 smoke test閿涘矁顩惄鏍€婇柈銊ユ彥閹瑰嘲鍙嗛崣锝冣偓?75dp 閸欏苯鍨敮鍐ㄧ湰閸滃瞼鍋ｉ崙缁樺潑閸旂姵绁︾粙瀣ㄢ偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗚箛顐ｅ祹閸忋儱褰涢崪灞惧笓鎼村繋璐熸禍铏硅濞村鐦稉顓炵妇妞ょ敻娼伴崘鍛Ц閹緤绱濋弳鍌欑瑝閸愭瑥鍙嗛崗銊ョ湰 AppState 閹?SettingsService閿涙盯鍣搁弬鎷岀箻閸忋儵銆夐棃銏犳倵閹稿绮拋銈勭喘閸栨牠銆庢惔蹇撶潔缁€鎭掆偓?
- 閹锋牕濮╂禍銈勭鞍娴犲懍缍旈悽銊ょ艾閸忋儱褰涢崡锛勫鐏炲偊绱濇稉宥嗘暭閸欐ü鎹㈡担鏇炲徔娴ｆ挻绁寸拠鏇€夐惃鍕吀閺冭翰鈧胶绮虹拋掳鈧焦濮ら崨濠冨灗閹镐椒绠欓崠鏍偓鏄忕帆閵?

## [Unreleased-PLAN_148-VISUAL-SEARCH-LINK-MATCH] - 2026-05-09

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴閸︺劌浼愰崗椋庮唸-娴滆櫣琚ù瀣槸娑擃厼绺?鐟欏棜顫庨幖婊呭偍濡€虫健娑擃厼顤冮崝鐘虹箾鏉╃偟婀呴惃鍕彯閸涜櫕膩瀵骏绱濋獮鑸垫绾喖缍嬮崜宥咁樆闁劌浼愰崗椋庮唸濡€虫健閸滃苯绔风仦鈧锝呮躬楠炴儼顢戞穱顔芥暭閿涘本婀版潪顔煎涧閼宠姤鏁归崣锝呮躬鐟欏棜顫庨幖婊呭偍鐎涙劖膩閸ф鍞撮柈銊ｂ偓?

### 閺傛澘顤?
- 鐟欏棜顫庨幖婊呭偍閺傛澘顤冮妴宀冪箾鏉╃偟婀?/ Link match閵嗗秵膩瀵骏绱濋崷銊潒鐟欏鎮崇槐銏ゃ€夐崘鍛村劥閹绘劒绶甸崶鐐攳闁板秴顕妴浣界珶閻ｅ矁鐭惧鍕瑢閺堚偓婢舵矮琚卞▎陇娴嗗顖氬灲鐎规哎鈧線鍘ょ€佃鏆熼妴浣稿⒖娴ｆ瑥顕弫鑸偓浣诡劄閺佽埇鈧胶鏁ら弮璺烘嫲鐎瑰本鍨氶幎銉ユ啞閵?
- 閺傛澘顤冩潻鐐剁箾閻顥愰惄?smoke test閿涘矁顩惄鏍佸蹇撳弳閸欙絻鈧礁鏄傜€垫瓕顔曠純顔衡偓浣稿涧閸栧綊鍘ら崶鐐攳瀵偓閸忓啿鎷版稉缁橆棎閻╂ɑ瑕嗛弻鎾扁偓?

### 娣囶喗鏁?
- 鐟欏棜顫庨幖婊呭偍鐠佸墽鐤嗛弬鍥攳閹碘晛鐫嶆稉鐑樻偝缁鳖潿鈧焦澹樻稉宥呮倱閸滃矁绻涙潻鐐垫箙娑撳膩瀵骏绱辨潻鐐剁箾閻濞囬悽銊у缁斿顥愰惄妯烘槀鐎垫瓕顔曠純顕嗙礉娑撳秴濂栭崫宥呭斧閺堝澹橀惄顔界垼閸滃本澹樻稉宥呮倱鏉烆喗顐奸柅鏄忕帆閵?
- 鏉╃偠绻涢惇瀣棎閻╂ü绮犻惄鎼佸仸閹存劕顕弨閫涜礋闂呭繑婧€閸欘垵袙閸掑棗绔烽敍宀冾潒鐟欏绗傛稉宥呭晙閸涘牏骞囬弫鎾秷閹藉棙鏂侀惃鍕笓閸掓鍔呴妴?
- 娣囶喖顦叉潻鐐剁箾閻绱戠仦鈧禒宥咁啇閺勬捇鈧偓閸ョ偟娴夐柇缁樺灇鐎电懓绔风仦鈧惃鍕６妫版﹫绱扮粔濠氭珟閻╂悂鍋﹂崗婊冪俺閿涘本鏁兼稉娲閺堣櫣鏁撻幋鎰喘閸忓牄鈧礁鍨庣仦鍌氬讲鐟欙絽绔风仦鈧崗婊冪俺閿涘苯鑻熼崗浣筋啅鐠侯垰绶為崐鐔峰И濡娲忔径鏍珶閻ｅ被鈧?
- 鏉╃偠绻涢惇瀣仯閸戣崵顑囨禍灞奸嚋閸ョ偓顢嶉崥搴㈡▔缁€楦跨箾閹恒儴鐭剧痪鍖＄幢鐠侯垰绶炵悮顐︽▎閹糕剝妞傞崷銊╂▎閹糕剝鐗搁弰鍓с仛缁俱垼澹婇崣澶婂娇閿涘苯娴樺鍫滅瑝閸栧綊鍘ら弮璺烘躬娑撱倓閲滈崶鐐攳娑撳﹥妯夌粈鍝勫级閸欐灚鈧?
- 鏉╃偠绻涢惇瀣啎缂冾喗鏌婃晶鐐偓灞藉涧閸栧綊鍘ら崶鐐攳閵嗗秴绱戦崗绛圭礉瀵偓閸氼垰鎮楅惄绋挎倱閸ョ偓顢嶉弮鐘绘付鐠侯垰绶炴潻鐐衡偓姘瘍閼宠姤绉烽梽銈忕礉鐠侯垳鍤庢禒鍛稊娑撳搫寮芥＃鍫熸▔缁€鎭掆偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛崣顏冩叏閺€纭咁潒鐟欏鎮崇槐銏犵摍濡€虫健閵嗕礁顕惔鏃€绁寸拠鏇炴嫲閺傚洦銆傞敍灞肩瑝鐟欙妇顫径鏍х湴瀹搞儱鍙跨粻閬嶎浕妞ょ偣鈧礁绔风仦鈧幒鎺戠碍閵嗕焦膩閸ф鐭鹃悽杈ㄥ灗閹镐椒绠欓崠鏍Ц閹降鈧?
- 鏉╃偠绻涢惇瀣熅瀵板嫬鍨界€规艾缍嬮崜宥嗘暜閹镐胶娲跨痪瑁も偓浣诡棎閻╂ê顦绘稉鈧崷鍫濇嫲閺堚偓婢舵矮琚卞▎陇娴嗗顖ょ礉鐏炵偘绨潪濠氬櫤鐡掞絽鎳楀Ο鈥崇础閿涘奔绗夐幍鈺佺潔閸掔増娲挎径宥嗘絽閻ㄥ嫬顦挎潪顒€闆嗙憴鍕灟閵?

## [Unreleased-PLAN_146-TOOLBOX-AUDITORY-SIMULATION] - 2026-05-08

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴鐏忓棜顫嬬憴澶嬫偝缁?閹靛彞绗夐崥灞肩瑢閸氼剝顫庨崣宥呯安/婢逛即鐓舵潏銊ㄧ槕閺嶅洭顣介弨璺哄經閿涘苯鑻熸穱顔碱槻閸氼剝顫庨崣宥呯安閹绢厽鏂佹径杈Е閿涘苯鎮撻弮鑸靛⒖鐏炴洟顣堕悳鍥モ偓渚€鐓堕柌蹇撴嫲婢逛即浜炬稉澶岃濡剝瀚欓崠璇差劅濞村鐦妴?

### 閺傛澘顤?
- 閸氼剝顫庨崣宥呯安閺€閫涜礋閸氬牊鍨氶幓鎰仛闂婂啿鐤勯悳甯礉閺€顖涘瘮閸欏秴绨查妴渚€顣堕悳鍥モ偓渚€鐓堕柌蹇撴嫲婢逛即浜鹃崶娑氼潚濡€崇础閵?
- 閺傛澘顤冩０鎴犲芳鏉堛劌鍩嗛妴渚€鐓堕柌蹇氶哺閸掝偄鎷板锕€褰告竟浼翠壕鏉堛劌鍩嗛惃鍕侀幏鐔哥ゴ鐠囨洟銆嶉敍宀€绮ㄩ弸婊€绮庢担婊€璐熼張顒€婀撮懛顏呯ゴ閸欏秹顩妴?

### 娣囶喗鏁?
- 鐟欏棜顫庨幖婊呭偍閺嶅洭顣介弨璺哄經娑撹　鈧粏顫嬬憴澶嬫偝缁扁懇鈧繐绱濋崥顒冾潕濡€虫健閺嶅洭顣介弨璺哄經娑撹　鈧粌鎯夌憴澶婂冀鎼存柡鈧縿鈧?
- 閺囧瓨鏌婇崥顒冾潕妞?smoke test閵嗕焦膩閸ф顕╅弰搴濈瑢閸忋儱褰涢弬鍥攳閿涘本鏁奸悽銊ユ値閹存劙鐓堕幘顓熸杹鐠侯垰绶為妴?

### 妞嬪酣娅撻崣妯绘纯
- 閸氬牊鍨氶棅鎶筋暥娓氭繆绂嗛獮鍐插酱閹绢厽鏂侀崳銊ユ嫲娑撳瓨妞傞弬鍥︽鐠侯垰绶為敍娑滃楠炲啿褰撮棅鎶筋暥閼宠棄濮忓鍌氱埗閿涘矂銆夐棃顫窗闁偓閸栨牔璐熺化鑽ょ埠閹绘劗銇氶棅鐐解偓?
- 婢逛即浜惧Ο鈩冨珯閸︺劌宕熸竟浼翠壕鐠佹儳顦稉濠冨妳閻儱褰查懗鎴掔瑝閺勫孩妯夐敍灞芥礈濮濄倓绮庢担婊€璐熼張顒€婀村Ο鈩冨珯鐠侇厾绮岄妴?

## [Unreleased-PLAN_145-HUMAN-TESTS-NEW-MODULES] - 2026-05-08

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴閸︺劌浼愰崗椋庮唸-娴滆櫣琚ù瀣槸娑擃厼绺鹃弬鏉款杻鐟欏棜顫庨幖婊呭偍/閹靛彞绗夐崥灞烩偓浣告儔鐟欏寮芥惔?婢逛即鐓舵潏銊ㄧ槕閵嗕礁寮绘禒璇插閸掑洦宕查妴浣虹翱缂佸棙瀚嬮幏鍊熸嫹闊亜鎷伴崣灞惧閸楀繗鐨熸禍鏂鹃嚋鐎涙劖膩閸фぜ鈧?

### 閺傛澘顤?
- 閺傛澘顤?`VisualSearchTestPage`閿涘本鏁幐浣哥槕闂嗗棛缍夐弽鍏煎閻╊喗鐖ｆ稉搴″蓟闂堛垺婢橀幍鍙ョ瑝閸氬奔琚辩粔宥喣佸蹇ョ礉楠炶埖褰佹笟娑滅枂閺佽埇鈧胶缍夐弽鐓庣槕鎼达负鈧礁鍣涵顔惧芳閵嗕礁閽╅崸鍥╂暏閺冭泛鎷伴幎銉ユ啞閵?
- 閺傛澘顤?`AuditoryReactionTestPage`閿涘奔濞囬悽銊у箛閺?roulette 閻參鐓堕弫鍫ｇカ濠ф劖褰佹笟娑樻儔闂婂啿寮芥惔鏂剧瑢婢逛即鐓舵潏銊ㄧ槕娑撱倗顫掑Ο鈥崇础閿涘瞼绮虹拋鈥冲冀鎼存梹妞傞妴浣稿櫙绾喚宸奸妴浣瑰缁涙柨鎷伴崚鍡涚叾閺佸牐銆冮悳鑸偓?
- 閺傛澘顤?`DualTaskSwitchTestPage`閿涘苯婀弫鏉跨摟婵傚洤浼撴稉搴杹閼规彃鍠庨悜顓☆潐閸掓瑤绠ｉ梻鏉戝瀼閹诡澁绱濈紒鐔活吀閸掑洦宕叉潪顔衡偓渚€鍣告径宥堢枂閵嗕礁鍨忛幑顫敩娴犲嘲鎷版潻鐐插毊閵?
- 閺傛澘顤?`FineDragTrackingTestPage`閿涘矂鈧俺绻冪粣鍕缓鏉╄瀚嬮幏鍊熸嫹闊亣顔囪ぐ鏇炰焊缁傛槒绐涚粋姹団偓浣侯瀲鏉炪劍顐奸弫鑸偓浣哥暚閹存劖妞傞梻鏉戞嫲闂呮儳瀹崇拋鍓х枂閵?
- 閺傛澘顤?`BimanualCoordinationTestPage`閿涘本鏁幐浣镐箯閸欒櫕澧滄禍銈嗘禌娑撳骸鎮撳銉ュ蓟閸戣琚辩猾鏄忣唲缂佸喛绱濈拋鏉跨秿閸氬本顒炵粣妤€褰涢妴浣搁挬閸у洨鏁ら弮韬测偓浣告倱濮濄儱妯婇崪灞藉櫙绾喚宸奸妴?

### 娣囶喗鏁?
- 娴滆櫣琚ù瀣槸娑擃厼绺?hub 閺傛澘顤冩禍鏂鹃嚋閸忋儱褰涢崡锛勫閿涘苯鑻熼崥灞绢劄閺囧瓨鏌婂Ο鈥虫健 README 娑?smoke test 鐟曞棛娲婇妴?

### 妞嬪酣娅撻崣妯绘纯
- 閸氼剝顫庡ù瀣槸娓氭繆绂嗛悳鐗堟箒閻參鐓堕弫鍫ｇカ娴溠冩嫲楠炲啿褰撮幘顓熸杹閸ｎ煉绱遍懟銉ラ挬閸欎即鐓舵０鎴滅瑝閸欘垳鏁ら敍宀勩€夐棃顫窗娣囨繃瀵旈崣顖涙惙娴ｆ粈绲鹃棅铏櫏閸欏秹顩崣顖濆厴闁偓閸栨牓鈧?
- 閹锋牗瀚挎潻鍊熼嚋閸滃苯寮婚幍瀣礂鐠嬪啫瀵橀崥顐ｆ煀閻ㄥ嫭澧滈崝鑳灦閸欏府绱濇稉鏄忣洣閹靛濞嶇悮顐︽閸掕泛婀懜鐐插酱閸栧搫鐓欓崘鍜冪礉妞ょ敻娼版径鏍х湴濠婃艾濮╃拠顓濈疅娑撳秴褰夐妴?

## [Unreleased-PLAN_144-SCRATCH-TICKET-REALISM] - 2026-05-08

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴缂佈呯敾鐎瑰本鍨氬銉ュ徔缁犱究鈧奔姹夌猾缁樼ゴ鐠囨洑鑵戣箛?- 鏉╂劖鐨靛ù瀣槸閵嗗秳鑵戦惃鍕焿閸掝喕绠扮€涙劖膩閸ф绱濇担鍨従鏉堟儳鍩岄弴瀛樺复鏉╂垹婀＄€圭偛宓嗗鈧粊銊ф畱妤傛ê瀹冲Ο鈩冨珯閵?

### 閺傛澘顤?
- 閸掝喖鍩夋稊鎰偍闂堛垺鏌婃晶鐐拌厬婵傛牕褰块惍浣稿隘閵嗕焦鍨滈惃鍕娇閻礁灏妴浣恒偍閸欐灚鈧礁瀵橀崣鏋偓浣圭墡妤犲瞼鐖滈妴浣规蒋閻焦鐗卞蹇撳隘閵嗕焦妲﹂弽鍥殰閸斻劋鑵戞總鏍ф嫲閸婂秵鏆熺粭锕€褰块妴?
- 濮ｅ繋閲滈崚顔肩磻閺嶅吋鏌婃晶鐐烘閽樺繐褰块惍浣碘偓浣哥潔缁€鍝勵殯闁叉垯鈧礁鐤勯梽鍛厬婵傛牠鍣炬０婵勨偓浣糕偓宥嗘殶閸滃奔绗佹担宥嗙墡妤犲瞼鐖滈敍灞藉焿瀵偓閸氬孩瀵滈惇鐔风杽缁併劑娼扮紒鎾寸€棁鎻掑毉閸愬懎顔愰妴?
- 閹躲儱鎲″鍦崶閸氬本顒炵仦鏇犮仛娑擃厼顨涢崣椋庣垳閵嗕胶銈ㄩ崣鏋偓浣稿瘶閸欐灚鈧焦鐗庢宀€鐖滈崪灞藉嚒閸掝喖绱戦崣椋庣垳/婵傛牠鍣?閸婂秵鏆熼弰搴ｇ矎閵?

### 娣囶喗鏁?
- 閸掝喖鍩夋稊鎰嚛閺勫簼绮犻崡鏇氱婵傛牜楠囬惄顔界垼閺€閫涜礋閳ユ粈鑵戞總鏍у娇閻?+ 閹存垹娈戦崣椋庣垳 + 婵傛牠鍣?+ 閻楄鐣╃粭锕€褰块垾婵堟畱閻喎鐤勯崡鍐茬磻缁併劎甯哄▔鏇樷偓?
- 閸掝喖鍩夋稊鎰偍闂堛垺鎲崇憰浣稿隘閺€閫涜礋缁併劌銇旈妴浣哄负濞夋洝顕╅弰搴涒偓浣疯厬婵傛牕褰块惍浣碘偓浣割殯缁狙嗐€冮崪宀€銈ㄩ弽瑙勭墡妤犲苯鍨庣仦鍌氱潔缁€鎭掆偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒宥勮礋閺堫剙婀存繛鍙樼濡剝瀚欓敍灞肩瑝閹恒儱鍙嗛惇鐔风杽瑜扳晝銈ㄧ拹顓濇嫳閵嗕礁鍘總鏍ㄥ灗閼辨梻缍夐弽锟犵崣閿涙稒顩ч悳鍥ф嫲缁併劑娼扮紒鎾寸€禒鍛棘閼板啫鐖剁憴?scratch-off 閸楀啿绱戠粊銊х矋閹存劑鈧?

## [Unreleased-PLAN_143-SCRATCH-PRIZE-TABLE-SETTINGS] - 2026-05-08

### 閸樼喎娲?
- 缂佈呯敾閺€璺哄經鏉╂劖鐨靛ù瀣槸娑擃厾娈戦崚顔煎焿娑旀劗甯哄▔鏇礉娴ｅじ鑵戞總鏍窗閺嶅洣绮犻崡鏇氱閺佹澘鐡ч崡鍥╅獓娑撹櫣婀＄€圭偛鍩夐崚顔荤瀵繐顨涚痪褑銆冮敍灞借嫙鐞涖儵缍堢粊銊ょ幆閵嗕焦顩ч悳鍥モ偓浣稿焿瀵偓闂呮儳瀹抽崪灞界潔缁€鐑樐佸蹇氼啎缂冾喓鈧?

### 閺傛澘顤?
- 閸掝喖鍩夋稊鎰煀婢х偛顨涚痪褑銆冨Ο鈥崇€烽敍灞惧瘻閻楀湱鐡戞總鏍モ偓浣风缁涘顨涢妴浣风癌缁涘顨涚粵澶婄湴缁狙呮晸閹存劗娲伴弽鍥櫨妫版繐绱濇姗€顤傛径褍顨涙穱婵堟殌闂呭繑婧€閸栨椽妫块獮鑸靛瘻閻т勘鈧礁宕堥妴浣风缁涘鐭戞惔锕€褰囬弫娣偓?
- 閸掝喖鍩夋稊鎰煀婢х偠顔曠純顔煎隘閿涘本鏁幐浣恒偍娴犳灚鈧礁鍩夊鈧弫浼村櫤閵嗕焦鏆ｆ担鎾茶厬婵傛牗顩ч悳鍥︽叏濮濓絻鈧礁銇囨總鏍洤閻滃洣鎱ㄥ锝冣偓浣稿焿瀵偓闂呮儳瀹抽妴浣规▔缁€娲櫨妫版縿鈧焦妯夌粈杞拌厬婵傛牗鐖ｇ拋鑸偓浣搞亣婵傛牕鍙忕仦蹇斾純閸犳嚎鈧礁宓冮懞杈ㄧ壉瀵繐鎷伴幁銏狀槻姒涙顓荤拋鍓х枂閵?
- 缂佺喕顓告稉搴㈠Г閸涘﹥鏌婃晶鐐电柈鐠伮ゅС鐠愮懓鎷伴崙鈧弨鍓佹抄閿涘矁濮崇拹瑙勫瘻瑜版挸澧犵粊銊ょ幆濡剝瀚欑槐顖濐吀閵?

### 娣囶喗鏁?
- 閸掝喖鍩夋稊鎰扮帛鐠併倖鏁兼稉琛♀偓婊呮暏閹撮攱瀵滄總鏍獓鐞涖劏鍤滅悰灞藉灲閺傤厸鈧繄娈戠粊銊╂桨鐏炴洜銇氶敍灞炬弓瀵偓閸氼垶鍣炬０?娑擃厼顨涢弽鍥唶閺冩湹绗夐惄瀛樺复閹绘劗銇氱紒鎾寸亯閵?
- 閸掝喖顨涚憰鍡楃湴閺€閫涜礋閺堫亜鍩夐崠鍝勭厵鐎瑰苯鍙忔稉宥夆偓蹇旀閿涘苯褰ч柅姘崇箖閹靛瀵氶崚鎺曠箖閻ㄥ嫬鐪柈銊︽憹閻ユ洟鈧繐鍤崘鍛啇閿涘矂浼╅崗宥嗘弓閸掝喖澧犻惇瀣煂闂呮劘妫屾穱鈩冧紖閵?
- 閻楀湱鐡戞總鏍︾瑢娑撯偓缁涘顨涢崨鎴掕厬閺冭泛顤冮崝鐘插讲閸忔娊妫撮惃鍕弿鐏炲繑浼冮崰婊勬櫏閺嬫嚎鈧?

### 妞嬪酣娅撻崣妯绘纯
- 濮掑倻宸兼稉鐑樐侀幏鐔烘埂鐎圭偛鍩夐崚顔荤瑜扳晝銈ㄩ惃鍕箮娴肩厧鍨庣敮鍐跨礉娑撳秶绮︾€规艾鍙挎担鎾虫勾閸栫儤鍨ㄩ崗铚傜秼缁併劎顫掗敍娑㈢彯妫版繂顨涙い閫涚窗閺勫孩妯夋担搴暥娴滃簼缍嗘０婵嗩殯妞ゅ箍鈧?

## [Unreleased-PLAN_142-SCRATCH-REALISM-AND-ERASE] - 2026-05-08

### 閸樼喎娲?
- 缂佈呯敾閹跺﹨绻嶅鏃€绁寸拠鏇㈠櫡閻ㄥ嫬鍩夐崚顔荤鐎涙劖膩閸ф浠涘妤佹纯閸嶅繒婀＄€圭偛鍩夋總鏍偍閿涘苯鎮撻弮鑸靛Ω娑擃厼顨涘鍌滃芳閵嗕線鍣炬０婵嗗瀻鐢啫鎷伴崚顔肩磻閸欏秹顩弨鍓佹彛閸掔増娲块幒銉ㄧ箮鐎圭偘缍嬬粊銊╂桨閵?

### 娣囶喗鏁?
- 閸掝喖鍩夋稊鎰兊缁併劍鐫滈弨閫涜礋閺囨潙浜搁惇鐔风杽缁併劌鐎烽惃鍕綀闁插秴鍨庣敮鍐跨礉娑擃厼顨涙禒銉ョ毈妫版繀璐熸稉姹団偓浣搞亣婵傛牗鐎亸鎴礉闂堢偘鑵戞總鏍ㄧ壐鐎涙劗娈戠仦鏇犮仛闁叉垿顤傛稊鐔告暪閺佹稑鍩岄弴鏉戠埗鐟欎礁灏梻娣偓?
- 閸掝喖绱戠憰鍡欐磰鐏炲倹鏁兼稉娲偓鎰應鐟欙附鎽濋梽銈忕礉娑撳秴鍟€閺佹潙娼″ǎ鈥冲毉閿涙稒鐦″▎鈩冨珛閸斻劌褰ч悾娆庣瑓閸楁洘娼崚顔炬閿涘苯鑻熸穱婵堟殌娑撯偓閻愬綊鍣剧仦鐐寸暙閻ｆ瑥鎷版潏鍦喘绾俱劍宕幇鐔粹偓?
- 閸掝喖鍩夋稊鎰兊缁併劌銇旀稉搴ｇ埠鐠佲€冲隘閺€閫涜礋閺囧菙閻?shrink-wrap 鐢啫鐪敍宀勬娴ｅ海鐛庣仦蹇庣瑓閻ㄥ嫬绨抽柈銊﹀閸戞椽顥撻梽鈹库偓?
- 娑撳搫鍩夐崚顔荤缂冩垶鐗哥悰銉ュ帠閸ョ偛缍?key 娑撳孩瀚嬮崝銊ュ焿瀵偓濞村鐦敍宀冾洬閻╂牜婀＄€圭偞澧滈崝鑳熅瀵板嫨鈧?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒宥呭涧鐠嬪啯鏆ｉ崚顔煎焿娑旀劕鐡欏Ο鈥虫健閻ㄥ嫬鐫嶇粈鎭掆偓浣诡洤閻滃洤鎷板ù瀣槸閿涘奔绗夐弨鐟板綁閸忔湹绮禍铏硅濞村鐦Ο鈥虫健鐠囶厺绠熼妴?

## [Unreleased-PLAN_141-SCRATCH-CARD-POLISH] - 2026-05-08

### 閸樼喎娲?
- 缂佈呯敾閹跺﹨绻嶅鏃€绁寸拠鏇㈠櫡閻ㄥ嫬鍩夐崚顔荤鐎涙劖膩閸ф浠涘妤佹纯閸嶅繒婀＄€圭偛鍩夋總鏍偍閿涘苯鑻熸穱顔碱槻鐏忓繐鐫嗘稉瀣畱鐢啫鐪┃銏犲毉闂傤噣顣介妴?

### 娣囶喗鏁?
- 閸掝喖鍩夋稊鎰兊缁併劑娼伴弨閫涜礋閺囧瓨甯存潻鎴犳埂鐎圭偟銈ㄩ棃銏㈡畱缁惧憡鍔呴妴渚€鍣炬潏骞库偓浣恒偍婢舵潙鎷版稉顓烆殯鐏炴洜銇氱拠顓♀枅閵?
- 閸掝喖绱戠憰鍡欐磰鐏炲倹鏁兼稉娲櫨鐏炵偞绉辩仦鍌濆窛閹扮喍绗岄崚顔芥憹缁惧湱鎮婇敍灞惧絹閸楀洠鈧粌鍩夋總鏍も偓婵嗗冀妫ｅ牏娈戦惇鐔风杽閹扮喆鈧?
- 閸掝喖鍩夋稊鎰兊缁併劌銇旈弨閫涜礋鐏忓繐鐫嗛懛顏堚偓鍌氱安鐢啫鐪敍宀勪缉閸忓秹鏆遍弽鍥暯閹存牔鑵戞總鏍ㄦ殶鐎涙婀粣鍕啍鎼达缚绗呭┃銏犲毉閵?
- 娑撳搫鍩夐崚顔荤濡€虫健鐞涖儱鍘?overflow 閸ョ偛缍婇弬顓♀枅閿涘矂妲诲銏犳倵缂侇叀顫嬬憴澶庣殶閺佹潙鍟€濞嗏剝鎷洪悥鍡楃鐏炩偓閵?

### 妞嬪酣娅撻崣妯绘纯
- 鏉╂瑨鐤嗘禒鍛扮殶閺佹潙鍩夐崚顔荤鐏炴洜銇氱仦鍌氭嫲濞村鐦敍灞肩瑝閺€鐟板綁閹惰棄宕辩紒鐔活吀閵嗕礁顨涚粊銊ф晸閹存劘顫夐崚娆愬灗閸忔湹绮禍铏硅濞村鐦Ο鈥虫健鐠囶厺绠熼妴?

## [Unreleased-PLAN_140-HUMAN-TESTS-CALC-LUCK-TAP-JOYSTICK-FINISH] - 2026-05-08

### 閸樼喎娲?
- 缂佈呯敾閺€璺哄經瀹搞儱鍙跨粻渚库偓灞兼眽缁粯绁寸拠鏇氳厬韫囧啨鈧秶娈戞０妯虹€烽崚鍡楃閵嗕浇绻嶅鏃傚负濞夋洏鈧焦澧滈柅鐔告惙娴ｆ粈绗岄幗鍥ㄦ綄閸忋劌鐫嗛柆顔藉皡闂傤噣顣介敍宀冾唨濡€虫健閺囨潙鍎氱€瑰本鏆ｅù瀣槸瀹搞儱鍙块懓灞肩瑝閺勵垰鐪柈銊﹀閹恒儯鈧?

### 閺傛澘顤?
- 鐠侊紕鐣婚懗钘夊濞村鐦稉顓㈡▉娑旀﹢顣介崹瀣╃矌閸︺劏绻橀梼璺烘嫲娑撴挸顔嶉梾鎯у瀵偓閺€淇扁偓?
- 鏉╂劖鐨靛ù瀣槸閺傛澘顤冮悪顒傜彌閸掝喖鍩夋稊鎰摍濡€虫健閿涘矂鍣伴悽銊よ厬婵傛牗鏆熺€涙ぞ绗屾總鏍櫨闂冪喎鍨惃鍕閸斿灝鍩夊鈧悳鈺傜《閵?
- 閹靛鈧喐绁寸拠鏇氬瘜閹垮秳缍旈崠鐑樻煀婢х偤鍣搁弬鏉跨磻婵瀵滈柦顔衡偓?

### 娣囶喗鏁?
- 鐠侊紕鐣婚懗钘夊濞村鐦惃鍕箻闂冭泛寮锋禒銉ょ瑐濞ｅ嘲鎮庢０妯圭瑢娑撱倖顒炴０姗€娈㈤張鍝勫閸忋儳鐡戝顔衡偓浣虹搼濮ｆ柨鎷伴幐鍥ㄦ殶閸欐ü缍嬮敍灞惧⒖婢堆囩彯闂呮儳瀹虫０妯荤潨閵?
- 鏉╂劖鐨靛ù瀣槸閹峰棗鍨庢稉琛♀偓婊勫▕閸?/ 閸掝喖鍩夋稊鎰ㄢ偓婵呰⒈娑擃亞瀚粩瀣摍濡€虫健閿涘瞼鐐曢崡锛勫閺佸牊鏁兼稉鐑樺▕閸椻€茬瑩閻劌绱戦崗鐐解偓?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌娑撳娈戠亸鍕毊閹稿鎸抽崪灞炬啚閺夊棙鏁兼稉鐑樻纯鏉炶崵娈戦崡濠団偓蹇旀濞搭喖鐪伴弽宄扮础閿涘矂妾锋担搴☆嚠閻╊喗鐖ｉ惃鍕紕閹嘎扳偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒鍛扮殶閺佺繝姹夌猾缁樼ゴ鐠囨洑鑵戣箛鍐€夐棃銏犲敶閻?UI閵嗕線顣芥惔鎾冲瀻鐢啫鎷扮仦鈧柈銊уЦ閹緤绱濇稉宥呭閸?AppState閵嗕焦鏆熼幑顔肩氨閹存牗瀵旀稊鍛鐠囶厺绠熼妴?

## [Unreleased-PLAN_139-HUMAN-TESTS-INTERRUPTED-POLISH] - 2026-05-08

### 閸樼喎娲?
- 閹垫寧甯寸悮顐¤厬閺傤厾娈戞禍铏硅濞村鐦稉顓炵妇娴兼ê瀵查敍姘冀鎼存梹绁寸拠鏇熸煙閸氭垶绮﹂崝銊ょ瑢妞ょ敻娼板姘З閸愯尙鐛婇妴浣瑰ⅵ鐎涙绁寸拠鏇☆啎缂冾喕璐￠惍浣碘偓浣筋吀缁犳绁寸拠鏇㈢彯缁狙囶暯閸ㄥ绗夌搾鐐解偓浣界箥濮樻梹绁寸拠鏇烆樋閹剁晫些閸斻劎顏潻鍥毐閵嗕胶鈻堥張澶屽閺佸牐顩惄鏍モ偓浣风瑓娑撯偓鏉烆喖鍩涢弬鏉垮幢妞よ￥鈧浇绻涚紒顓犵倳閸椻€虫嫲閸掝喖鍩夋稊鎰负濞夋洜宸辨径渚库偓?

### 閺傛澘顤?
- 鐠侊紕鐣婚懗钘夊濞村鐦弬鏉款杻閹稿洦鏆熼妴渚€妯佹稊妯糕偓浣虹搼瀹割喗鏆熼崚妤€鎷扮粵澶嬬槷閺佹澘鍨０妯虹€烽敍灞借嫙缁惧啿鍙嗘姗€姣︽惔锔借穿閸氬牓顣藉Ч鐘偓?
- 鏉╂劖鐨靛ù瀣槸閺傛澘顤冮垾婊冨焿閸掝喕绠伴垾婵囧疆缁€鐑樻煙瀵骏绱濋悽鐔稿灇閸楁洖绱舵總鏍桨閸氬骸褰查柅姘崇箖閹靛瀵氬鎴濆З闁劖顒為崚顔肩磻閵?

### 娣囶喗鏁?
- 閸欏秴绨插ù瀣槸閺傜懓鎮滃Ο鈥崇础閻ㄥ嫪瀵岄懜鐐插酱娑撳簼鑵戣箛?D-pad 閺€閫涜礋鐏炩偓闁劍甯寸粻鈩冨瘹闁藉牊澧滈崝鍖＄礉闁灝鍘ゆ稉濠冪拨/娑撳绮﹂崣宥呯安鐞氼偄顦荤仦鍌炪€夐棃銏＄泊閸斻劍濮犵挧鑸偓?
- 娣囶喖顦查幍鎾崇摟濞村鐦拋鍓х枂閸栬桨鑵戦弬鍥﹁础閻緤绱濋幁銏狀槻閳ユ粍澧︾€涙顔曠純顔光偓婵呯瑢鐠囧瓨妲戦弬鍥攳閵?
- 鏉╂劖鐨靛ù瀣槸婢舵碍濞婇崡锛勫閺€閫涜礋閹靛婧€缁旑垳鎻ｉ崙鎴犵秹閺嶇》绱濋弨顖涘瘮閹靛瀵氬鎴ｇ箖鏉╃偟鐢荤紙璇插幢閿涙稐绨╅崡浣瑰▕娑撳秴鍟€閸ョ姳绔寸悰灞肩矌娑撱倕绱堕崡锛勫鐎佃壈鍤фい鐢告桨鏉╁洭鏆遍妴?
- 鏉╂劖鐨靛ù瀣槸閳ユ粎鎴风紒顓濈瑓娑撯偓鏉烆喒鈧繄鏁撻幋鎰瑓娑撯偓閹电懓宕遍悧鍥ㄦ閸戝繐鐨弫鏉戞健閼哥偛褰撮柌宥呯紦閹扮噦绱濇穱婵堟殌閸氬奔绔撮幍褰掑櫤閼哥偛褰寸紒鎾寸€崑姘挬濠婃垶娴涢幑顫偓?
- 鏉╂劖鐨靛ù瀣槸閸欒尪鐦?娴肩姾顕╃粙鈧張澶屽閺佸牊鏁兼稉娲Е閸掓鎸遍弨鎾呯礉閹靛綊鍣虹紙璇茬磻閺冩湹绶峰▎鈥崇暚閺佸瓨妯夌粈鐚寸礉娑撳秴鍟€娴滄帞娴夌憰鍡欐磰閵?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒宥呭涧瑜板崬鎼锋禍铏硅濞村鐦稉顓炵妇妞ょ敻娼伴崘鍛祮閺冨墎濮搁幀渚婄幢娑撳秴鍟撻崗?AppState閵嗕焦鏆熼幑顔肩氨閹存牕顒熸稊鐘侯唶瑜版洏鈧?
- 閺傜懓鎮滃鎴濆З閹靛濞嶉崣顏勬躬閸欏秴绨插ù瀣槸閺傜懓鎮滃Ο鈥崇础閻ㄥ嫯鍨堕崣棰佺瑢 D-pad 閸栧搫鐓欑仦鈧柈銊﹀复缁犫槄绱濇い鐢告桨閸忚泛鐣犻崠鍝勭厵娣囨繃瀵斿锝呯埗缁鹃潧鎮滃姘З閵?

## [Unreleased-PLAN_138-TOOLBOX-HOME-EDIT-MOBILE-POLISH] - 2026-05-08

### 閸樼喎娲?
- 缂佈呯敾閺€璺哄經瀹搞儱鍙跨粻閬嶎浕妞や絻鍤滅€规矮绠熺敮鍐ㄧ湰娴ｆ捇鐛欓敍灞煎▏缂傛牞绶幀浣告躬缁夎濮╃粩顖涙纯鐎硅妲楃拠鍡楀焼瑜版挸澧犻弰鍓с仛/闂呮劘妫岄悩鑸碘偓渚婄礉楠炲爼妾锋担搴㈠珛閹峰鈧胶些闂勩倕鎷伴幁銏狀槻闂呮劘妫岄崗銉ュ經閻ㄥ嫯顕ら幙宥勭稊閹存劖婀伴妴?

### 娣囶喗鏁?
- 瀹搞儱鍙跨粻閬嶎浕妞ょ數绱潏鎴炩偓渚€銆婇柈銊уЦ閹線娼伴弶鎸庢暭娑撹　鈧粍妯夌粈?/ 闂呮劘妫岄垾婵堝缁?chip閿涘苯鑻熺悰銉ュ帠閳ユ粎些闂勩倕褰ч梾鎰妫ｆ牠銆夐崗銉ュ經閿涘奔绗夋导姘鳖洣閻劍膩閸фせ鈧繄娈戞潏鍦櫕鐠囧瓨妲戦妴?
- 瀹搞儱鍙跨粻鍗炲弳閸欙絽宕遍悧鍥╃椽鏉堟垵濮╂担婊冨灙缂佺喍绔存稉?48dp 鐟欙附甯堕悜顓炲隘閿涘本瀚嬮幏钘夋嫲缁夊娅庨幐澶愭尦閸︺劎些閸斻劎顏弴瀵盖旂€规哎鈧?
- 缁彞鎱ㄦ＃鏍€夌粚铏瑰Ц閹椒绗岄幁銏狀槻闂呮劘妫岄崗銉ュ經鎼存洟鍎村鐟扮湴閿涘本浠径宥呰剨鐏炲倹妲戠涵顔藉絹缁€鐑樐侀崸妤€鎯庨崑婊€绮涢悽杈侀崸妤冾吀閻炲棙甯堕崚韬测偓?
- 鐞涖儱鍘栧銉ュ徔缁犻亶顩绘い鐢电椽鏉?smoke test閿涘矁顩惄鏍椽鏉堟垹濮搁幀?chip閵嗕胶绱潏鎴濆З娴ｆ粎鍎归崠鍝勬嫲閹垹顦插鐟扮湴鐠囧瓨妲戦妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛崣顏囩殶閺佹潙鐫嶇粈鍝勭湴閸滃本绁寸拠鏇礉娑撳秵鏁奸崣?`ToolboxLayoutState`閵嗕梗SettingsService`閵嗕焦膩閸ф鎯庨崑婧库偓浣界熅閻㈣鲸鍨ㄩ幐浣风畽閸栨牞顕㈡稊澶堚偓?

## [Unreleased-PLAN_137-TOOLBOX-CUSTOM-LAYOUT] - 2026-05-07

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿瀹搞儱鍙跨粻鍗炴倗濡€虫健閸欘垯浜掗柅姘崇箖闂€鎸庡瘻閼奉亜鐣炬稊澶屝╅崝銊ョ鐏炩偓娴ｅ秶鐤嗛敍灞借嫙閺€顖涘瘮娴犲骸浼愰崗椋庮唸妫ｆ牠銆夐崚鐘绘珟/閹垹顦查崗銉ュ經閿涘苯鐤勯悳鐗堟纯閻忓灚妞块惃鍕絻閹锋柨绱℃＃鏍€夐妴?

### 閺傛澘顤?
- 閺傛澘顤?`ToolboxLayoutState`閿涘本瀵旀稊鍛瀹搞儱鍙跨粻閬嶎浕妞ゅ灚膩閸ф銆庢惔蹇庣瑢闂呮劘妫岄崗銉ュ經閸掓銆冮妴?
- `SettingsService` 閺傛澘顤冨銉ュ徔缁犲崬绔风仦鈧悩鑸碘偓浣稿鏉炴垝绗屾穱婵嗙摠閼宠棄濮忛妴?
- `AppState` 閺傛澘顤冨銉ュ徔缁犻亶顩绘い鍨笓鎼村繈鈧線娈ｉ挊蹇嬧偓浣逛划婢跺秴鎷伴柌宥囩枂鐢啫鐪幒銉ュ經閵?
- 瀹搞儱鍙跨粻閬嶎浕妞ゅ灚鏌婃晶鐐电椽鏉堟垶膩瀵骏绱伴悙鐟板毊閳ユ粎绱潏鎴濈鐏炩偓閳ユ繃鍨ㄩ梹鎸庡瘻娴犵粯鍓板銉ュ徔閸楋紕澧栨潻娑樺弳閿涙稓绱潏鎴災佸蹇旀暜閹镐焦瀚嬮幏鑺ュ笓鎼村繈鈧椒绮犳＃鏍€夌粔濠氭珟閵嗕焦浠径宥夋閽樺繐鍙嗛崣锝呮嫲闁插秶鐤嗘妯款吇鐢啫鐪妴?
- 閺傛澘顤冨銉ュ徔缁犲崬绔风仦鈧幐浣风畽閸栨牕宕熼崗鍐╃ゴ鐠囨洑绗屾＃鏍€夌紓鏍帆 smoke test閵?

### 娣囶喗鏁?
- 瀹搞儱鍙跨粻閬嶎浕妞ゅ吀绮犻崶鍝勭暰閸掑棛绮嶇仦鏇犮仛閸楀洨楠囨稉琛♀偓婊勫灉閻ㄥ嫬浼愰崗椋庮唸閳ユ繆鍤滅€规矮绠熸い鍝勭碍鐏炴洜銇氶敍灞芥倱閺冩湹绻氶悾娆忓斧婵鍙嗛崣锝呯暰娑斿缍旀稉娲帛鐠併倝銆庢惔蹇旀降濠ф劑鈧?
- 娣囶喗顒滈張顒侇偧鐟欙箑寮烽惃鍕紣閸忛顔堟＃鏍€夐崪灞藉弳閸欙絽鍞寸€归€涜厬閺傚洦鏋冨鍫礉缁夊娅庨弰搴㈡▔娑旇京鐖滅拠瀛樻閵?
- 閺囧瓨鏌?`modules/toolbox/README.md` 娑撳孩鐗?`README.md`閿涘矁藟閸忓懘顩绘い浣冨殰鐎规矮绠熺敮鍐ㄧ湰娑撳骸鍙忕仦鈧Ο鈥虫健閸氼垰浠犻惃鍕珶閻ｅ矁顕╅弰搴涒偓?

### 妞嬪酣娅撻崣妯绘纯
- 妫ｆ牠銆夐垾婊呅╅梽銈傗偓婵嗗涧闂呮劘妫屽銉ュ徔缁犻亶顩绘い闈涘弳閸欙綇绱濇稉宥勭窗缁備胶鏁ゅΟ鈥虫健閺堫剝闊╅敍娑氭埂濮濓絿娈戦崗銊ョ湰閸氼垰浠犳禒宥囨暠濡€虫健缁狅紕鎮婃い闈涙嫲 `ModuleToggleState` 閹貉冨煑閵?
- 鐢啫鐪悩鑸碘偓浣稿涧娣囨繂鐡ㄥΟ鈥虫健 ID閿涘本瑕嗛弻鎾存娴兼碍瀵滆ぐ鎾冲 `ModuleIds.toolboxModules` 瑜版帊绔撮崠鏍电礉鏉╁洦鎶ら張顏嗙叀濡€虫健楠炴儼鍤滈崝銊ㄋ夋鎰煀婢х偞膩閸фぜ鈧?

## [Unreleased-PLAN_136-TOOLBOX-STAGE-COMMIT-DOCS] - 2026-05-07

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴閺佸鎮婅ぐ鎾冲鏉╂稑瀹抽敍宀兯夐崗鍛暚閺佸瓨褰佹禍銈嗘）韫囨鎷?README閿涘苯鑻熺€瑰本鍨氭稉鈧▎鈩冨絹娴溿倖甯归柅浣碘偓?

### 閺傛澘顤?
- 閺?`README.md` 閺傛澘顤?2026-05-07 toolbox 闂冭埖顔屾潻鎴炴埂鏉╂稑鐫嶇拠瀛樻閵?
- 閺傛澘顤?`records/record_135_toolbox_human_tests_and_roulette_stage_commit.md`閿涘矁顔囪ぐ鏇熸拱濞嗭繝妯佸▓鍨絹娴溿倛瀵栭崶娣偓渚€鐛欑拠浣告嚒娴犮倕鎷板鑼叀妞嬪酣娅撻妴?
- 閺傛澘顤?`plans/PLAN_136_toolbox闂冭埖顔屾潻娑樺閺佸鎮婇幓鎰唉閹恒劑鈧?md`閿涘矁顔囪ぐ鏇熸拱濞嗏剝鏆ｉ悶鍡愨偓浣瑰絹娴溿倕鎷伴幒銊┾偓浣圭ウ缁嬪鈧?

### 娣囶喗鏁?
- 濮婂磭鎮?`changelogs/CHANGELOG.md` 閸?`modules/toolbox/README.md`閿涘瞼鈥樻穱婵呮眽缁粯绁寸拠鏇氳厬韫囧啨鈧浇绻嶅鏃€绁寸拠鏇樷偓浣规啚閺夊棗鍙忕仦蹇撴嫲娣囧嫮缍忛弬顖濈枂閻╂﹢妯佸▓浣冪箻鐏炴洖褰叉潻鑺ュ嚱閵?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剚顐兼稉娲▉濞堝灚鏆ｉ崥鍫熷絹娴溿倧绱濋懠鍐ㄦ纯閸栧懎鎯堟径姘崇枂 toolbox 閺€鐟板З閿涙稒褰佹禍銈嗘）韫囨鍑￠弰搴ｂ€樼拋鏉跨秿閼煎啫娲块崪宀勭崣鐠囦胶绮ㄩ弸婧库偓?

## [Unreleased-PLAN_135-LUCK-EFFECTS-AND-JOYSTICK-LANDSCAPE-ZONES] - 2026-05-07

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯鏉╂劖鐨靛ù瀣槸缁嬧偓閺堝澹掗弫鍫滅瑝婢剁喐瀵旀稊鍛弿鐏炲骏绱濇径姘崇箾閹舵垝绗呮稉鈧潪顔煎煕閺傛澘鍙嗛崣锝勭瑝閺勫海鈥橀敍娑欐啚閺夊棙澧滈惇鐓庡礂鐠嬪啯澧滈張鐑樏仦蹇撳弿鐏炲繑妞傞幗鍥ㄦ綄閸滃苯鐨犻崙鏄徯曢崣鎴濆隘閸╃喎绨查崶鍝勭暰閸︺劌涔忛崣鍏呰⒈娓氀佲偓?

### 娣囶喗鏁?
- 鏉╂劖鐨靛ù瀣槸閸欒尪鐦?娴肩姾顕╅悧瑙勬櫏瀵ゅ爼鏆辨稉鐑樻纯閹镐椒绠欓惃鍕弿鐏炲繗顩惄鏍电礉楠炶泛顤冨娲櫨閼?缁鳖偉澹婂ù浣稿З娑撳簼鑵戣箛鍐枅閺堝褰佺粈鎭掆偓?
- 鏉╂劖鐨靛ù瀣槸婢舵俺绻涢幎钘夊弿闁劎鐐曞鈧崥搴礉鐏忓棌鈧粌鍙忛柈銊х倳瀵偓閳ユ繂鍨忛幑顫礋閳ユ粎鎴风紒顓濈瑓娑撯偓鏉烆喒鈧繐绱濋悙鐟板毊閸氬孩绔婚悶鍡楃秼閸撳秵澹掑▎鈥宠嫙閻㈢喐鍨氭稉瀣╃閹电懓宕遍悧鍥モ偓?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌濡亜鐫嗛弮璺虹殺瀹革缚鏅堕崠鍝勭厵娴ｆ粈璐熼幗鍥ㄦ綄閸炪倛鎹ｉ崠鎭掆偓浣稿礁娓氀冨隘閸╃喍缍旀稉鍝勭殸閸戣鏁滅挧宄板隘閿涘奔鑵戦梻缈犵箽閻ｆ瑧绱﹂崘鎻掑隘閿涙稒璇炵仦鍌欑矝闂呭繑澧滈幐鍥曢悙鐟版暅鐠у嘲鎷伴柌宥呯暰娴ｅ秲鈧?

### 妞嬪酣娅撻崣妯绘纯
- 缁嬧偓閺堝澹掗弫鍫滅矝閸欐せ鈧粎鈻堥張澶嬪▕娑擃厾澹掗弫鍫氣偓婵嗙磻閸忚櫕甯堕崚璁圭礉娑撴柧绗夐幏锔藉焻閻愮懓鍤敍娑櫭仦蹇撲箯閸欏磭鍎归崠鍝勫涧瑜板崬鎼烽崗銊ョ潌濡€崇础閿涘本娅橀柅姘躲€夐棃顫瑢缁旀牕鐫嗛柅鏄忕帆娣囨繃瀵旈崢鐔告箒鐞涘奔璐熼妴?

## [Unreleased-PLAN_134-LUCK-DRAW-STAGE-MUTUAL-EXCLUSION] - 2026-05-07

### 閸樼喎娲?
- 娣囶喖顦叉潻鎰毜濞村鐦稉顓炲礋閹?5 瀵姷澧濋崪灞筋樋鏉╃偞濞婇幍褰掑櫤閸楋紕澧栭崥灞炬閺勫墽銇氶敍宀勨偓鐘冲灇娑撱倓閲滅紙璇插幢閻ｅ矂娼伴柌宥呭綌閻ㄥ嫰妫舵０妯糕偓?

### 娣囶喗鏁?
- 鏉╂劖鐨靛ù瀣槸閹惰棄宕遍懜鐐插酱閺€閫涜礋娴滄帗鏋肩仦鏇犮仛閿涙艾宕熼幎鑺ツ佸蹇撳涧閺勫墽銇?5 瀵姴宕熼幎鐣屽閿涘苯顦块幎鑺ツ佸蹇撳涧閺勫墽銇氶幍褰掑櫤閸楋紕澧栭崠鍝勭厵閹存牜鏁撻幋鎰絹缁€鎭掆偓?
- 閸掑洦宕查幎钘夊幢濡€崇础閺冭埖绔婚悶鍡樻弓鐎瑰本鍨氶惃鍕闁插繐鐫嶇粈铏瑰Ц閹緤绱濋柆鍨帳閺冄勫濞嗏剝鐣悾娆忓煂閸楁洘濞婇悾宀勬桨閵?

### 妞嬪酣娅撻崣妯绘纯
- 濡€崇础閸掑洦宕查崣顏呯閻炲棗鐫嶇粈杞拌厬閻ㄥ嫪澶嶉弮鑸靛濞嗏槄绱濇稉宥夊櫢缂冾喖鍑＄拋鏉跨秿閻ㄥ嫭濞婇崡锛勭埠鐠伮扳偓?

## [Unreleased-PLAN_133-HUMAN-TESTS-FEEDBACK-AND-REPORTS] - 2026-05-07

### 閸樼喎娲?
- 缂佈呯敾鐎瑰苯鏉?`瀹搞儱鍙跨粻?- 娴滆櫣琚ù瀣槸娑擃厼绺綻 娑擃厽瀵旂紒顓熸暈閹板繐濮忛妴浣界箥濮樻柣鈧焦妞傞梻瀛樺妳閻儯鈧焦澧滈柅鐔粹偓浣哥碍閸掓顔囪箛鍡愨偓浣规焿閻楀綊鐬鹃弲顔兼嫲閼硅尪顫庨幎銉ユ啞閿涘奔濞囨禍銈勭鞍閸欏秹顩妴浣概稊鎰偓褍鎷扮紒鐔活吀閸欘垵顕伴幀褎娲跨€瑰本鏆ｉ妴?

### 閺傛澘顤?
- 閹镐胶鐢诲▔銊﹀壈閸旀稒绁寸拠鏇熸煀婢х偤绮拋銈呭彠闂傤厾娈戦惄顔界垼閼冲本娅欐妯瑰瘨瀵偓閸忕绱濋獮璺烘躬閸涙垝鑵戦妴浣筋嚖閻愮懓鎷伴柌宥咁槻閻愮懓鍤弮鑸垫▔缁€铏圭叚娣囧啰鍋ｆ稉顓炲冀妫ｅ牄鈧?
- 鏉╂劖鐨靛ù瀣槸閺傛澘顤冩径姘崇箾閹惰棄宕遍悧鍥ㄧ潨閿涘苯宕勬潻?娴滃苯宕勬潻鐐扮窗閻㈢喐鍨氱€电懓绨查弫浼村櫤閻ㄥ嫮婀＄€圭偛宕遍悧鍥风礉閺€顖涘瘮闁劕绱剁紙璇茬磻閹存牔绔撮柨顔煎弿缂堜紮绱遍崣鑼剁槻/娴肩姾顕╅幎鎴掕厬閺冭泛褰查弰鍓с仛閻厽娈忛崗銊ョ潌缁嬧偓閺堝澹掗弫鍫涒偓?
- 鏉╂劖鐨电紒鐔活吀閹躲儱鎲￠弬鏉款杻鐡掞絽鎳楃粔鏉垮娇閿涘苯瀵橀幏顒侇儌閻ㄥ洤婀稉鏍モ偓浣圭毜鏉╂劒绠ｇ€涙劑鈧礁鐨獮姝岀箥閵嗕焦娅橀弲顕€鈧岸鈧哎鈧浇绻嶅鏂剧瑝娴ｅ啿鎷伴棃鐐哄帬缁涘鍨庡锝冣偓?
- 閺冨爼妫块幇鐔虹叀濞村鐦鈧慨瀣閺傛澘顤?3-2-1 婢堆冪潌閸婃帟顓搁弮璁圭礉缁夋帟銆冮崷銊モ偓鎺曨吀閺冨墎绮ㄩ弶鐔锋倵閹靛秴鎯庨崝銊ｂ偓?
- 閹靛鈧喐绁寸拠鏇熸煀婢х偟绮￠崗姝岀箾閻愬箍鈧胶娲伴弽鍥嫹閸戣鎷伴懞鍌氼殧閸涙垝鑵戞稉澶岊潚閻溾晜纭堕敍宀兯夐崗鍛閹存ɑ妞傞梹瑁も偓浣界箾閸戞眹鈧礁鍣涵顔惧芳閸滃苯鐣幋鎰Г閸涘鈧?
- 鎼村繐鍨拋鏉跨箓閺傛澘顤冮悙鐟板毊閸欏秹顩妴浣诡劀绾?闁挎瑨顕ら崶鐐垼閸滃矁绶崗銉ㄧ箻鎼达箑绐橀弽鍥モ偓?
- 閺傤垳澹掓ご浣规珮閺傛澘顤冩稉鈧懛鏉戝灲閺傤厹鈧浇顕╅崙鍝勨叿閼瑰眰鈧浇顕伴崙鍝勭摟娑斿鎷伴崣宥呮倻鐟欏嫬鍨€涙劖膩瀵骏绱濋獮鍓佺埠鐠佲€冲冀鎼存梹妞傛稉搴＄暚閹存劖濮ら崨濞库偓?

### 娣囶喗鏁?
- 閼硅尪顫庡ù瀣槸閹躲儱鎲＄粔濠氭珟娴ｅ骸褰茬拠缁樷偓褏娈戦弴鑼殠/閸婃儳鎮?CustomPaint 閸ユ崘銆冮敍灞炬暭娑撻缚绻庢潪顔垮瀹割喛顔囪ぐ鏇樷偓浣藉閻╃鍨庣紒鍕€冮悳鏉挎嫲瀹割喖绱撶猾璇茬€风悰銊у箛閸掓銆冮妴?

### 妞嬪酣娅撻崣妯绘纯
- 鏉╂劖鐨靛ù瀣槸婢舵俺绻涢幎鑺ユ暭娑撹櫣鐐曞鈧崥搴㈠鐠佲€冲弳缂佺喕顓搁敍宀勪缉閸忓秮鈧粌鍑￠悽鐔稿灇娴ｅ棙婀仦鏇犮仛閳ユ繄娈戦崡锛勫濮光剝鐓嬮幎銉ユ啞閿涙稒婀版い鐢电波閺嬫粈绮涢崣顏冪箽鐎涙ê婀ぐ鎾冲妞ょ敻娼伴崘鍛摠娑擃厹鈧?

## [Unreleased-PLAN_132-HUMAN-TESTS-SIX-MODULES] - 2026-05-07

### 閸樼喎娲?
- 鐎瑰苯鏉?`瀹搞儱鍙跨粻?- 娴滆櫣琚ù瀣槸娑擃厼绺綻 娑擃叀顓哥粻妤勫厴閸旀稏鈧礁濮╅幀浣筋潒閸旀稑鐡х粭锕佺槕閸掝偁鈧焦瀵旂紒顓熸暈閹板繐濮忛妴浣界箥濮樻梹绁寸拠鏇樷偓浣藉鐟欏濮ら崨濠傛禈鐞涖劌鎷版い鐢告桨閺傚洦顢嶉敍灞煎▏閸╄櫣顢呯€圭偟骞囬幓鎰磳娑撳搫褰查柊宥囩枂閵嗕礁褰叉径宥囨磸閻ㄥ嫯顔勭紒鍐┠侀崸妞尖偓?

### 閺傛澘顤?
- 鐠侊紕鐣婚懗钘夊濞村鐦弬鏉款杻鏉炲鍣?閺嶅洤鍣?鏉╂盯妯?娑撴挸顔嶉梾鎯у閵嗕焦璐╅崥?閸旂姴鍣?娑旀ɑ纭?闂勩倖纭?娑撱倖顒炴０?閺堫亞鐓￠弫浼搭暯閸ㄥ鈧礁娴愮€规岸顣介柌?闂勬劖妞傛稉銈囶潚缂佹挻娼弶鈥叉閸滃苯鐣幋鎰Г閸涘鈧?
- 閸斻劍鈧浇顫嬮崝娑樼摟缁楋箒鐦戦崚顐ｆ煀婢х偛鐡х粭锕傛肠閵嗕胶些閸斻劏寤烘潻骞库偓渚€鈧銆嶉弫浼村櫤閵嗕礁鎬ラ獮鍙夊鐎涙顑侀妴浣稿祮閺冭泛寮芥＃鍫濇嫲鐎瑰本鍨氶幎銉ユ啞閿涙稑鐨悶鍐╂殶闁插繘鈧槒绶穱婵囧瘮閻欘剛鐝涢妴?
- 閹镐胶鐢诲▔銊﹀壈閸旀稒绁寸拠鏇熸煀婢х偟娲伴弽鍥╁仯閸戞眹鈧椒缍嗘０鎴犳窗閺嶅洤鎷?n-back 娑撳琚禒璇插閿涘苯鑻熼弨顖涘瘮閸掔儤绺洪弫浼村櫤閵嗕浇濡總蹇嬧偓浣烘窗閺嶅洦鐦笟瀣嫲 n-back 闂傛挳娈х拋鍓х枂閵?
- 鏉╂劖鐨靛ù瀣槸閺傛澘顤冮崡鏇熷▕閵嗕礁宕勬潻鐐偓浣风癌閸椾浇绻涢妴浣稿幢閻楀洦鏆熼柌?楠炴瓕绻嶉幐鍥ㄦ殶/閹惰姤鏆熼惄顔界垼閸滃瞼娲伴弽鍥х暚閹存劖濮ら崨濞库偓?

### 娣囶喗鏁?
- 鏉╂劖鐨靛ù瀣槸楠炴瓕绻嶉崐鍏兼暭娑撶儤瀵滃鍌滃芳閺堢喐婀滅拋锛勭暬楠炴瓕绻嶉幐鍥ㄦ殶閿?00 娴ｆ粈璐熼張鐔告箿閸╄櫣鍤庨妴?
- 閼硅尪顫庨幎銉ユ啞鐏忓棜澹婅ぐ鈺佷焊閸氭垵鎷板顔肩磽缁鐎烽崶鎹愩€冮弨閫涜礋濡亜鎮滅拠鍕瀻閺夆槄绱濋弰鍓с仛閻ф儳鍨庡В鏂剧瑢閸涙垝鑵戦弫浼村櫤閿涘苯鍣虹亸鎴滅秵閺嶉攱婀伴弮璺哄涧閸戣櫣骞囬崡鏇熸蒋缁旀牜鍤庨惃鍕６妫版ǜ鈧?
- 閺囧瓨鏌婃禍铏硅濞村鐦稉顓炵妇閵嗕辜oolbox 閹鍙嗛崣锝呮嫲濡€虫健鐠囧瓨妲戦弬鍥攳閿涘瞼些闂勩倛绻冮張鐔烘畱閸╄櫣顢呴幓蹇氬牚閵?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛弬鏉款杻閻ㄥ嫭濮ら崨濠傛綆閸欘亙濞囬悽銊ョ秼閸撳秹銆夐棃銏犲敶鐎涙绮虹拋鈽呯礉娑撳秴鍟撻崗?AppState閵嗕焦鏆熼幑顔肩氨閹存牕顒熸稊鐘侯唶瑜版洏鈧?

## [Unreleased-PLAN_131-JOYSTICK-FULLSCREEN-SETTINGS-DIALOG] - 2026-05-07

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌濡€崇础婢х偛濮炴稉鈧稉顏勭毈鐠佸墽鐤嗛崗銉ュ經閹稿鎸抽敍宀冾潐閺嶉棿绗屽鈧慨瀣ㄢ偓渚€鍣哥純顔藉瘻闁筋喕绔撮懛杈剧礉閻愮懓鍤崥搴ｆ暏瀵湱鐛ョ仦鏇炵磻鐠佸墽鐤嗛妴?

### 閺傛澘顤?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌妞ゅ爼鍎撮幙宥勭稊閸栫儤鏌婃晶鐐额啎缂冾喖娴橀弽鍥ㄥ瘻闁筋喓鈧?
- 閻愮懓鍤拋鍓х枂閹稿鎸抽崥搴¤剨閸戝搫鍙忕仦蹇氼啎缂冾喖鑴婄粣妤嬬礉婢跺秶鏁ら幗鍥ㄦ綄鐠佸墽鐤嗛妴浣烘窗閺嶅洨些閸斻劏顔曠純顔兼嫲妤傛﹢妯侀獮鍙夊鐠佸墽鐤嗛妴?

### 娣囶喗鏁?
- 閺囧瓨鏌婇幗鍥ㄦ綄閸忋劌鐫?smoke test閿涘矁顩惄鏍啎缂冾喖鍙嗛崣锝冣偓浣歌剨缁愭鐫嶇粈鍝勬嫲閻╊喗鐖ｇ粔璇插З鐠佸墽鐤嗙仦鏇炵磻閵?

### 妞嬪酣娅撻崣妯绘纯
- 鐠佸墽鐤嗗鍦崶婢跺秶鏁ら弲顕€鈧岸銆夐柨浣哥暰鐟欏嫬鍨敍宀冪箥鐞涘奔鑵戦崗鎶芥暛鐠佸墽鐤嗘禒宥囶洣閻㈩煉绱濋柆鍨帳濞村鐦潻鍥┾柤娑擃厾娈戠憴鍕灟閸掑洦宕插ǎ宄板弳瑜版挸澧犻幋鎰摋閵?

## [Unreleased-PLAN_130-JOYSTICK-FULLSCREEN-IMPLICIT-PRACTICE] - 2026-05-07

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌濡€崇础閸︺劍澧滈幐鍥ㄦ弓閹稿绗呴弮鍫曟閽樺繑鎲為弶鍡礉閸樼粯甯€閹藉洦娼屾径鏍х湴閺傜懓鑸版潏瑙勵攱閿涘苯鑻熼崗浣筋啅閺堫亜绱戞慨瀣閸忓牏绮屾稊鐘插櫙閺勭喐甯堕崚韬测偓?

### 娣囶喗鏁?
- 閸忋劌鐫嗛幗鍥ㄦ綄閺€閫涜礋閹稿绗呴崥搴㈠閺勫墽銇氶妴浣瑰М鐠у嘲鎮楅梾鎰閿涘矁鍨堕崣鎵敄闂傚弶妞傛稉宥呭晙鐢悂鈹楀锔跨瑓閹藉洦娼屽ù顔肩湴閵?
- 閸忋劌鐫嗛幗鍥ㄦ綄閸樺娅庢径鏍х湴閺傜懓鑸伴崡濠団偓蹇旀闂堛垺婢橀敍灞藉涧娣囨繄鏆€閸﹀棗鑸伴幗鍥ㄦ綄閺堫兛缍嬮妴?
- 閸忋劌鐫嗛張顏勭磻婵濮搁幀浣风瑓閸忎浇顔忛幏鏍уЗ閸戝棙妲︽潻娑滎攽閹靛鍔呴柅鍌氱安閿涙稖顕氱紒鍐х瘎閹椒绗夌憴锕€褰傞惄顔界垼閸掗攱鏌婇妴浣哥殸閸戞槒顓搁崚鍡樺灗濞村鐦拋鈩冩閵?
- 閺囧瓨鏌婇幗鍥ㄦ綄閸忋劌鐫?smoke test閿涘矁顩惄鏍у灥婵娈ｉ挊蹇嬧偓浣叫曢悙瑙勬▔缁€鎭掆偓浣瑰М鐠х兘娈ｉ挊蹇撴嫲閺堫亜绱戞慨瀣櫙閺勭喓些閸斻劊鈧?

### 妞嬪酣娅撻崣妯绘纯
- 闂呮劕绱￠幗鍥ㄦ綄閸戝繐鐨禍鍡楁祼鐎规俺顫嬬憴澶嬪絹缁€鐚寸礉娴ｅ棜袝閻愮懓宓嗛幗鍥ㄦ綄娑擃厼绺鹃惃鍕惙娴ｆ粍膩閸ㄥ娲块柅鍌氭値閸忋劌鐫嗗▽澶嬭箞鐠侇厾绮岄敍娑欘劀瀵繑绁寸拠鏇氱矝闂団偓閻愮懓鍤鈧慨瀣瘻闁筋喛绻橀崗銉吀閺?鐠佲€冲瀻閵?

## [Unreleased-PLAN_129-JOYSTICK-FULLSCREEN-WHITE-OVERLAY] - 2026-05-07

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌濡€崇础鏉╂稐绔村銉╁櫞閺€鎹愬灦閸欎即娼扮粔顖ょ礉閺€閫涜礋閻у€熷閸忋劌鐫嗛柧娲桨閿涘苯鑻熺拋鈺傛啚閺夊棎鈧礁鐨犻崙鑽ょ搼閹垮秳缍斿ù顔肩湴閼宠姤鐗撮幑顔藉閹稿洦瀵滄稉瀣╃秴缂冾喛鐨熼弫娣偓?

### 娣囶喗鏁?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌閼哥偛褰撮弨閫涜礋閻у€熷閸忋劌鐫嗛柧娲桨閿涘瞼些闂勩倖妫惃鍕箯閸欒櫕甯堕崚鑸电埉閸滃奔鑵戦梻纾嬪灦閸欐澘鍨庨弽蹇嬧偓?
- 閹藉洦娼岄妴浣哥殸閸戞眹鈧線銆婇柈銊уЦ閹礁鎷版导姘崇樈閹稿鎸抽弨閫涜礋閸楀﹪鈧繑妲戝ù顔肩湴閿涘奔绻氶悾娆撯偓鈧崙鎭掆偓浣哥磻婵?缂佹挻娼妴渚€鍣哥純顔兼嫲閹躲儱鎲￠崗銉ュ經閵?
- 鏉╂劘顢戞稉顓炴躬閼哥偛褰撮幐澶夌瑓娴兼碍濡搁幗鍥ㄦ綄濞搭喖鐪扮粔璇插З閸掓媽袝閻愬綊妾潻鎴濊嫙缂佈呯敾閸濆秴绨查幏鏍уЗ閿涙稑褰告稉瀣殸閸戣崵鍎归崠杞扮窗閹稿袝閻愬湱些閸斻劌鐨犻崙缁樿癁鐏炲倸鑻熺憴锕€褰傜亸鍕毊閵?
- 閺囧瓨鏌婇幗鍥ㄦ綄閸忋劌鐫嗗Ο顏勭潌閸滃瞼鐝仦?smoke test閿涘矁顩惄鏍у弿鐏炲繗鍨堕崣鏉挎槀鐎垫悶鈧焦璇炵仦鍌濐洬閻╂牕鎷扮憴锔惧仯闁插秴鐣炬担宥堫攽娑撴亽鈧?

### 妞嬪酣娅撻崣妯绘纯
- 閸忋劌鐫嗛惄顔界垼濞茶濮╅崠鍝勭厵閹碘晛銇囬崥搴礉閻╊喗鐖ｉ弴纾嬪垱鏉╂垹婀＄€圭偛鍙忕仦蹇氼唲缂佸喛绱辨い鍫曞劥閻樿埖鈧礁灏崺鐔剁矝娣囨繄鏆€閺堚偓鐏忓繐鐣ㄩ崗銊ㄧ珶鐠烘繐绱濋柆鍨帳閻╊喗鐖ｆ稉搴″彠闁款喗璇炵仦鍌濈箖鎼达箓鍣搁崣鐘偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_hand_eye_fullscreen.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --name "joystick fullscreen"`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_128-HUMAN-TESTS-REFINE] - 2026-05-07

### 閸樼喎娲?
- 閺€璺哄經 `瀹搞儱鍙跨粻?- 娴滆櫣琚ù瀣槸娑擃厼绺綻 閻?8 婢?UI/閹躲儱鎲￠梻顕€顣介敍宀€绮烘稉鈧悰銉╃秷鐎瑰本鍨氬鍦崶閵嗕浇顔曠純顔藉閸欑姳绗岄崗銊ョ潌鐢啫鐪导妯哄閵?

### 娣囶喗鏁?
- 閺佹澘鐡х拋鏉跨箓娴犲懎婀径杈Е鐎瑰本鍨氭稉鈧潪顔芥瀵懓鍤紒鐔活吀閹躲儱鎲￠妴?
- 閸欏秴绨插ù瀣槸閸︺劌鐣幋鎰缂佸嫬鎮楅懛顏勫З瀵懓鍤紒鐔活吀閸掑棙鐎介幎銉ユ啞閵?
- 閹垫挸鐡уù瀣槸鐏忓棜顔曠純顔煎隘閺€閫涜礋閹舵ê褰旂仦鏇炵磻閿涘苯鑻熸妯款吇閹绘劒绶甸垾婊冨弿闁劉鈧繈顣介弶鎰┾偓?
- 鐟欏棜顫庣拋鏉跨箓婢х偛濮炵€瑰本鍨氶崥搴ｆ畱閹躲儱鎲￠崗銉ュ經閵?
- 閻嫬鍣ù瀣槸缁夊娅庨柌宥咁槻閻ㄥ嫬绱戞慨瀣瘻闁筋喓鈧?
- 閼硅尪顫庡ù瀣槸娣囶喗顒滈幎銉ユ啞鐡掑濞嶉幎妯煎殠閻ㄥ嫮绮崚鎯板瘱閸ョ繝绗岀紓鈺傛杹閵?
- 鎼村繐鍨拋鏉跨箓閹碘晛鐫嶉崶鐐垼閺佷即鍣洪柊宥囩枂閿涘苯鑻熸晶鐐插繁鏉╃偟鐢婚柌宥咁槻閸ョ偓鐖ｉ惃鍕尡閺€鎹愰哺鐠囧棗瀹抽妴?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌鐢啫鐪弨鍓佹彛鏉堢绐涢敍灞惧⒖婢堆嗗灦閸欐澘褰查悽銊╂桨缁夘垬鈧?

### 娣囶喖顦?
- 閺囧瓨鏌婇惄绋垮彠 smoke test閵嗕焦膩閸ф顕╅弰搴濈瑢鐠佲€冲灊閻樿埖鈧緤绱濇穱婵囧瘮 toolbox 閸欐ɑ娲块弨璺哄經娑撯偓閼锋番鈧?

### 妞嬪酣娅撻崣妯绘纯
- 鎼村繐鍨拋鏉跨箓閻ㄥ嫬褰查柅澶婃禈閺嶅洦鏆熸晶鐐插閸氬函绱濇妯款吇娴ｆ捇鐛欓弴缈犺荡鐎靛矉绱濇担鍡氼潒鐟欏顦查弶鍌氬閻ｃ儲婀侀幓鎰磳閵?

## [Unreleased-PLAN_122-CHIMP-SETTINGS-REPORT] - 2026-05-06

### 閸樼喎娲?
- 缂佈呯敾鐎瑰苯鏉介妴灞戒紣閸忛顔?- 娴滆櫣琚ù瀣槸娑擃厼绺?- 姒涙垹灏掗悮鈺傜ゴ鐠囨洏鈧稄绱濇晶鐐插閺堚偓婢堆嗐€冮弽鐓庛亣鐏忓繈鈧焦妯夌粈铏圭摕濡楀牆鎷版妯款吇閸忔娊妫撮惃鍕絹缁€楦跨窡閸斺晪绱濋獮璺烘躬濞村鐦紒鎾存将閸氬骸鑴婇崙铏圭埠鐠佲€冲瀻閺嬫劖濮ら崨濞库偓?

### 閺傛澘顤?
- 姒涙垹灏掗悮鈺傜ゴ鐠囨洘鏌婃晶鐐存付婢堆嗐€冮弽鐓庛亣鐏忓繈鈧焦婀扮紒鍕付婢堆呮窗閺嶅洦鏆熼妴浣规▔缁€铏圭摕濡楀牄鈧椒绗呮稉鈧銉﹀絹缁€鎭掆偓浣风濞嗭繝鏁婄拠顖欑箽閹躲倕鎷扮€瑰本鍨氶崥搴ゅ殰閸斻劍濮ら崨濠咁啎缂冾喓鈧?
- 妞ゅ搫绨弫鏉跨摟娑撳酣顤侀懝鏌ャ€庢惔蹇斈佸蹇庣箽閻ｆ瑦鏆熺€?妫版粏澹婇幘顓熸杹闁喎瀹崇拋鍓х枂閿涘矂顤侀懝鏌ャ€庢惔蹇斈佸蹇庣箽閻ｆ瑩顤侀懝鍙夋殶闁插繗顔曠純顔衡偓?
- 濞村鐦€瑰本鍨氭稉濠囨閹存牕銇戠拹銉ユ倵閺傛澘顤冮妴宀勭拨閻氣晝灏掑ù瀣槸缂佺喕顓搁幎銉ユ啞閵嗗秴鑴婄粣妤嬬礉鐏炴洜銇氬Ο鈥崇础閵嗕浇銆冮弽绗衡偓浣哥暚閹存劘鐤嗗▎掳鈧礁銇戠拹銉ㄧ枂濞喡扳偓浣规付娴ｅ磭娲伴弽鍥モ偓浣稿櫙绾喚宸奸妴渚€鏁婄拠顖涙殶閵嗕礁閽╅崸?閺堚偓韫囶偆鏁ら弮韬测偓浣界窡閸斺晝濮搁幀浣告嫲鐠侇厾绮屽楦款唴閵?
- 閺傛澘顤冪€规艾鎮?smoke test 鐟曞棛娲婄拋鍓х枂閸忋儱褰涢妴浣虹摕濡?閹绘劗銇氭潏鍛И閸滃本濮ら崨濠傝剨缁愭ぜ鈧?

### 娣囶喗鏁?
- 姒涙垹灏掗悮鈺傜ゴ鐠囨洖鍙嗛崣锝堫嚛閺勫骸鎷?toolbox 濡€虫健鐠囧瓨妲戦崥灞绢劄閺囧瓨鏌婃稉楦款啎缂冾喕绗岄幎銉ユ啞閼宠棄濮忛幓蹇氬牚閵?
- 鐠佸墽鐤嗛崣妯绘纯娴兼碍绔婚悶鍡楃秼閸撳秷鐤嗛悩鑸碘偓浣告嫲閺堫剛绮嶇紒鐔活吀閿涘矂浼╅崗宥嗘＋鏉烆喗顐兼稉搴㈡煀鐟欏嫬鍨ǎ椋庢暏閵?

### 妞嬪酣娅撻崣妯绘纯
- 缁涙梹顢嶉弰鍓с仛閵嗕椒绗呮稉鈧銉﹀絹缁€杞扮瑢娑撯偓濞嗭繝鏁婄拠顖欑箽閹躲倕娼庢妯款吇閸忔娊妫撮敍娑樼磻閸氼垰鎮楅幎銉ユ啞娴兼碍鐖ｅ▔銊ㄧ窡閸斺晝濮搁幀渚婄礉闁灝鍘ゆ稉搴ｅ嚱閸戔偓鐠佹澘绻傞幋鎰摋閻╁瓨甯村В鏃囩窛閵?
- 缂佹挻鐏夋禒宥呭涧閸︺劌缍嬮崜宥夈€夐棃銏犲敶鐎涙ü鑵戦崡铏鐏炴洜銇氶敍灞肩瑝閸愭瑥鍙?AppState閵嗕焦鏆熼幑顔肩氨閹存牕顒熸稊鐘侯唶瑜版洏鈧?

### 妤犲矁鐦?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "chimp test exposes assists and completion report" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_127-VERBAL-MEMORY-MULTI-MODE-REPORT] - 2026-05-06

### 閸樼喎娲?
- 鐏忓棗浼愰崗椋庮唸-娴滆櫣琚ù瀣槸娑擃厼绺?鐠囧秵鐪圭拋鏉跨箓閹碘晛鐫嶆稉鐑樻纯鐎瑰本鏆ｉ惃鍕瑩娑撴俺顔勭紒鍐┠侀崸妤嬬礉鐞涖儵缍堢拠宥呯氨閵嗕礁顦垮Ο鈥崇础閵嗕礁褰查懛顏勭暰娑斿鍨堕崣浼寸彯鎼达箑鎷扮紒鎾存将閹躲儱鎲￠妴?

### 閺傛澘顤?
- 鐠囧秵鐪瑰Ο鈥崇础閺€顖涘瘮閸掑棝顣崺鐔荤槤鎼存挸顦块柅澶堚偓?
- 閺傛澘顤冮弫鏉跨摟鎼村繐鍨拋鏉跨箓濡€崇础閿涘本鏁幐渚€娈㈢痪褍鍩嗘晶鐐烘毐閻ㄥ嫰鏆辨惔锔衡偓?
- 閺傛澘顤冪粚娲？缁狀厼銇旂拋鏉跨箓濡€崇础閿涘本鏁幐?4 閸氭垵鎷?8 閸氭垶鏌熼崥鎴︽肠閵?
- 閺傛澘顤冮崣顖濆殰鐎规矮绠熼惃鍕灦閸欎即鐝惔锕傚帳缂冾喓鈧?
- 閺傛澘顤冪紒鎾存将閸氬海娈戠€瑰本鏆ｇ紒鎾寸亯閸掑棙鐎介幎銉ユ啞瀵湱鐛ラ妴?

### 娣囶喗鏁?
- 鐏忓棜鐦濆Ч鍥唶韫囧棙膩閸ф瀵?`models / data / view / widgets` 閺€鑸垫殐閹存劗瀚粩?part 缂佹挻鐎妴?
- 閺囧瓨鏌婂銉ュ徔缁犺鲸膩閸ф鏋冨锝嗘Ё鐏忓嫸绱濈悰銉╃秷閺傛壆娈戠拠宥嗙湽鐠佹澘绻傞幏鍡楀瀻閺傚洣娆㈤妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺傛澘顤冨Ο鈥崇础閸欘亙绻氶悾娆忕秼閸撳秹銆夐棃銏犲敶閻ㄥ嫬鐪柈銊х埠鐠佲槄绱濇稉宥呭晸閸忋儱鍙忕仦鈧悩鑸碘偓浣瑰灗閹镐椒绠欓崠鏍х摠閸屻劊鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_verbal_memory.dart lib/src/ui/pages/toolbox_human_tests_verbal_memory_data.dart lib/src/ui/pages/toolbox_human_tests_verbal_memory_models.dart lib/src/ui/pages/toolbox_human_tests_verbal_memory_view.dart lib/src/ui/pages/toolbox_human_tests_verbal_memory_widgets.dart test/toolbox_verbal_memory_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_verbal_memory.dart lib/src/ui/pages/toolbox_human_tests_verbal_memory_data.dart lib/src/ui/pages/toolbox_human_tests_verbal_memory_models.dart lib/src/ui/pages/toolbox_human_tests_verbal_memory_view.dart lib/src/ui/pages/toolbox_human_tests_verbal_memory_widgets.dart test/toolbox_verbal_memory_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/toolbox_verbal_memory_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_126-COLOR-VISION-MIXED-REPORT] - 2026-05-06

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴缂佈呯敾鐎瑰苯鏉介妴灞戒紣閸忛顔?- 娴滆櫣琚ù瀣槸娑擃厼绺?- 閼硅尪顫庡ù瀣槸閵嗗稄绱濇晶鐐插閺囨潙顦块崣顖濈殶鐠佸墽鐤嗛妴浣硅穿閼规彃灏柊宥囧负濞夋洏鈧焦褰佺粈鐑樺瘻闁筋噯绱濋獮璺烘躬濞村鐦紒鎾存将閺冨墎绮伴崙鍝勫徔娴ｆ挾绮虹拋鈥冲瀻閺嬫劖濮ら崨濠傛嫲閸ユ崘銆冮妴?

### 閺傛澘顤?
- 閼硅尪顫庡ù瀣槸閺傛澘顤冮妴宀€绮￠崗鍛婂娑撳秴鎮?/ 濞ｇ柉澹婇崠褰掑帳閵嗗秴寮诲Ο鈥崇础閿涙稒璐╅懝鎻掑爱闁板秳绱伴崷銊х秹閺嶉棿绗傞弬瑙勫絹缁€铏规窗閺嶅洩澹婇敍宀€鏁ら幋椋庡仯閸戣绗岄惄顔界垼閼规彃鐣崗銊ф祲閸氬瞼娈戦懝鎻掓健閵?
- 閺傛澘顤冮懝鑼兇閹烘帡娅庣拋鍓х枂閿涙艾鐣弫纾嬪缁眹鈧焦甯撻梽銈囧缂佽￥鈧焦甯撻梽銈堟憫姒涘嫨鈧椒缍嗘鍗炴嫲閿涘瞼鏁ゆ禍搴ㄤ缉瀵偓閻楃懓鐣鹃懝鑼额潕閸ヤ即姣﹂弫蹇斿妳閼硅尙绮嶉幋鏍т粵娴ｅ酣銈遍崪宀冾唲缂佸啨鈧?
- 閺傛澘顤冮張鈧径褏鏁撻崨鍊燁啎缂冾噯绱濋弨顖涘瘮 1 濞喡扳偓? 濞喡扳偓? 濞嗏€茬瑢閺冪娀妾洪悽鐔锋嚒閵?
- 閺傛澘顤冮崚婵嗩潗缂冩垶鐗搁妴浣规付婢堆呯秹閺嶇鈧焦璐╅懝鑼窗閺嶅洤鎮撻懝鎻掓健閺佷即鍣洪崪宀€娲伴弽鍥ㄦ殶闁插繘娈㈤張楦款啎缂冾喓鈧?
- 閺傛澘顤冮幓鎰仛閹稿鎸抽敍灞肩窗閸︺劌缍嬮崜宥堢枂濞嗏€茶礋閻╊喗鐖ｉ懝鎻掓健濞ｈ濮炴潏瑙勵攱閸滃苯娴橀弽鍥风礉楠炶泛鐨㈤幓鎰仛濞嗏剝鏆熼崘娆忓弳閺堫剚顐奸幎銉ユ啞閵?
- 濞村鐦紒鎾存将閺傛澘顤冮妴宀冨鐟欏绁寸拠鏇熷Г閸涘鈧秴鑴婄粣妤嬬礉鐏炴洜銇氶張鈧妯肩搼缁狙佲偓浣诡劀绾喚宸奸妴浣界枂濞喡扳偓浣瑰絹缁€鐑橆偧閺佽埇鈧焦鏆ｆ担鎾冲灲閺傤厹鈧浇澹婂顔裤€冮悳鐗堟锤缁捐￥鈧浇澹婅ぐ鈺佷焊閸氭垶娲哥痪瑁も偓浣告€ユい褰掋偧閸ヤ勘鈧焦婀版潪顔款啎缂冾喖鎷扮拋顓犵矊瀵ら缚顔呴妴?
- 閺傛澘顤?`test/toolbox_color_vision_smoke_test.dart`閿涘矁顩惄鏍啎缂冾喖鍙嗛崣锝冣偓浣硅穿閼瑰弶膩瀵繈鈧焦褰佺粈鐑樺瘻闁筋喖鎷伴幎銉ユ啞瀵湱鐛ラ妴?

### 娣囶喗鏁?
- 閼硅尪顫庡ù瀣槸閸忋儱褰涚拠瀛樻娴犲骸宕熸稉鈧幍鍙ョ瑝閸氬本娲块弬棰佽礋閸欏本膩瀵繋绗岄懝鎻掓▕/閼硅尙娴夐崚鍡樼€界拠瀛樻閵?
- 閼硅尪顫庡ù瀣槸 UI 閹峰棗鍤?`toolbox_human_tests_visual_widgets.dart`閿涘奔瀵岄弬鍥︽娣囨繄鏆€閻樿埖鈧焦婧€閵嗕浇澹婇崸妤冩晸閹存劕鎷扮紒鐔活吀闁槒绶妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺傛澘顤冮悳鈺傜《閸滃本濮ら崨濠傛綆閸欘亙濞囬悽銊ョ秼閸撳秹銆夐棃銏犲敶鐎涙绮虹拋鈽呯礉娑撳秴鍟撻崗?AppState閵嗕焦鏆熼幑顔肩氨閹存牕顒熸稊鐘侯唶瑜版洏鈧?
- 閸掑洦宕插Ο鈥崇础閵嗕浇澹婄化姹団偓浣烘晸閸涜棄鎷扮純鎴炵壐鐠佸墽鐤嗘导姘辩彌閸楁娊鍣稿鈧ぐ鎾冲閼硅尪顫庡ù瀣槸閿涘奔浜掗柆鍨帳閺冄嗙枂濞嗏€虫嫲閺傛媽顫夐崚娆愯穿閻劊鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_visual.dart lib/src/ui/pages/toolbox_human_tests_visual_widgets.dart test/toolbox_color_vision_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/toolbox_color_vision_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/toolbox_color_vision_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍娑樻嚒娴犮倖婀￠梻?pub advisories 鐟欙絿鐖滈幍鎾冲祪 warning閿涘奔绲惧ù瀣槸闁偓閸戣櫣鐖滄稉?0閿?

## [Unreleased-PLAN_125-JOYSTICK-HOTZONE-REPORT] - 2026-05-06

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿缂佈呯敾閺€璺哄經閵嗗苯浼愰崗椋庮唸 - 娴滆櫣琚ù瀣槸娑擃厼绺?- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼妴宥呭弿鐏炲骏绱伴梾鎰閹存牗濮岄崣鐘虹箻鎼达妇绮虹拋掳鈧焦濡搁幗鍥ㄦ綄閸滃苯鐨犻崙缁樺瘻闁筋喕绮犵仦蹇撶鏉堝湱绱崘鍛級閹存劖娲块幒銉ㄧ箮濮濓絽绱＄亸鍕毊濞撳憡鍨欓惃鍕閹扮噦绱濋獮鎯八夋鎰波閺嬫粍濮ら崨濠傚弳閸欙絽鎷板鍦崶閵?

### 閺傛澘顤?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌妞ゅ爼鍎寸紒鐔活吀姒涙顓婚幎妯哄綌娑撻缚浜ら柌蹇撳弳閸欙綇绱濋悙鐟板毊閸氬骸褰茬仦鏇炵磻閺屻儳婀呮潻娑樺閵嗕礁鎳℃稉顓炴嫲鐏忓嫮鈹栫紒鐔活吀閵?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌閺傛澘顤冩い鍫曞劥濞搭喖鐪伴幎銉ユ啞閸忋儱褰涢敍灞剧ゴ鐠囨洖鐣幋鎰倵閸欘垰鍟€濞嗏剝澧﹀鈧張顒冪枂缂佹挻鐏夐幎銉ユ啞瀵湱鐛ラ妴?
- 閸忋劌鐫嗙紒鎾寸亯閹躲儱鎲￠弽鍥暯缂佺喍绔存稉鎭掆偓灞炬啚閺夊棙澧滈惇鐓庡礂鐠嬪啰绮ㄩ弸婊勫Г閸涘鈧稄绱濇稉搴⒛侀崸妤€鎳￠崥宥勭箽閹镐椒绔撮懛娣偓?

### 娣囶喗鏁?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌閺€閫涜礋妞ゅ爼鍎村ù顔肩湴閹貉冨煑閺?+ 鎼存洟鍎撮崣灞兼櫠閹垮秳缍旈崠鐚寸窗瀹革缚鏅舵穱婵堟殌閹藉洦娼岄敍灞藉礁娓氀傜箽閻ｆ瑥鐨犻崙浼欑礉瀵偓婵?缂佹挻娼?闁插秶鐤?閹躲儱鎲￠弨閫涜礋妞ゅ爼鍎村ù顔肩湴閹稿鎸抽妴?
- 閸忋劌鐫嗛懜鐐插酱閻ㄥ嫮娲伴弽鍥︾瑢閸嬪洨娲伴弽鍥у煕閺傛媽瀵栭崶瀛樻暭娑撶儤瀵滈崣顖滄暏閼哥偛褰寸€瑰鍙忔潏鍦櫕鐠侊紕鐣婚敍宀勪缉瀵偓妞ゅ爼鍎村ù顔肩湴閸滃苯涔忛崣铏惙娴ｆ粌灏崨銊ㄧ珶閻戭厼灏妴?
- 閹藉洦娼岄崪灞界殸閸戠粯瀵滈柦顔剧埠娑撯偓閸氭垵鐫嗛獮鏇＄珶缂傛ê鍞寸紓鈺嬬礉楠炴儼藟鐡掑啿绨抽柈銊ョ暔閸忋劋缍戦柌蹇ョ礉闁灝鍘ら幍瀣簚鏉堝湱绱崠鍝勭厵鐠囶垵袝閵?
- 閺囧瓨鏌婇幗鍥ㄦ綄閹靛婧傞崡蹇氱殶 smoke test閿涘矁顩惄鏍€婇柈銊х埠鐠佲剝濮岄崣鐘偓浣瑰付閸掕泛灏崘鍛級閵嗕胶娲伴弽鍥х暔閸忋劏绔熼悾灞烩偓浣姑粩鏍х潌閸忋劌鐫嗙敮鍐ㄧ湰閸滃本濮ら崨濠傝剨缁愭鍙嗛崣锝冣偓?

### 妞嬪酣娅撻崣妯绘纯
- 閸忋劌鐫嗛惄顔界垼鐎瑰鍙忔潏鍦櫕閻ｃ儱浜曠紓鈺佺毈娴滃棗褰查崚椋庢窗閺嶅洩瀵栭崶杈剧礉娴ｅ棝浼╅崗宥囨窗閺嶅洣绗岄幙宥勭稊閸栧搫鎷版い鍫曞劥缂佺喕顓稿ù顔肩湴闁插秴褰旈妴?
- 缂佹挻鐏夐幎銉ユ啞閹稿鎸抽弨閫涜礋妞ゅ爼鍎村ù顔肩湴閸ョ偓鐖ｉ崗銉ュ經閸氬函绱濋悽銊﹀煕闂団偓鐟曚椒绶风挧鏍ф禈閺嶅洤鎷伴幓鎰仛閺傚洦婀扮拠鍡楀焼閸旂喕鍏橀妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_hand_eye_fullscreen.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_reports.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_fullscreen.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_reports.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --name "joystick fullscreen keeps controls off the center stage|joystick fullscreen portrait uses left controls and right stage|joystick coordination exposes joystick modes and controls|hand-eye fullscreen entry opens release-ready controls" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_124-AIM-COMBO-SNIPER-REPORT] - 2026-05-06

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿缂佈呯敾鐎瑰苯鏉介妴灞戒紣閸忛顔?- 娴滆櫣琚ù瀣槸娑擃厼绺?- 閻嫬鍣ù瀣槸閵嗗稄绱濈拋鈺呮缁狙勬杹婢堆佲偓浣烘埂閸嬪洤鍏遍幍鏉挎嫲缁夎濮╅棃璺哄讲娴犮儱鑸伴幋鎰纯婢舵艾褰查柅澶岀矋閸氬牞绱濋獮璺侯杻閸旂姳绔存稉顏囨珓閹风喓瀚忛崙缁樺鐡掞絽鎳楅崠鍛邦棅閿涘苯鎮撻弮璺虹暚閹存劕鎮楃紒娆忓毉鐎瑰本鏆ｇ紒鎾寸亯閹躲儱鎲￠妴?

### 閺傛澘顤?
- 閻嫬鍣ù瀣槸閺傛澘顤冮妴宀€些閸斻劍鏂佹径褋鈧秴绱戦崗绛圭礉闂勫秶楠囬弨鎯с亣閻╊喗鐖ｉ崣顖氭躬缁夎濮╂稉顓熷瘮缂侇厽鏂佹径褋鈧?
- 缁夎濮╅棃鑸垫煀婢х偑鈧苯濮為崗銉ф埂閸嬪洤鍏遍幍鑸偓宥呯磻閸忕绱濋弨顖涘瘮缁夎濮╂稉鏂垮叡閹垫壆娈戠紒鍕値鐠侇厾绮岄妴?
- 閻喎浜ｉ獮鍙夊濡€崇础閺傛澘顤冮妴宀€婀￠崑鍥╂窗閺嶅洨些閸斻劊鈧秴绱戦崗绛圭礉閻喓娲伴弽鍥ф嫲閸嬪洨娲伴弽鍥у讲閸忓崬鎮撶粔璇插З閵?
- 闂勫秶楠囬弨鎯с亣閺傛澘顤冮崣顖炩偓澶堚偓宀冩珓閹风喓瀚忛崙缁樺鐎电懓鍠呴妴宥呭瘶鐟佸拑绱伴惄顔界垼閺€鎯с亣閸掔増娓舵径褌绮涢張顏勬嚒娑擃厽妞傜憴锕€褰傞棁鍥уЗ娑撳骸鍙忕仦蹇曞閼规彃銇戠拹銉ヨ剨缁愭绱濋獮鎯邦唶瑜版洜瀚忛崙璇层亼鐠愩儲顐奸弫鑸偓?
- 閻嫬鍣ù瀣槸鐎瑰本鍨氶崥搴㈡煀婢х偛鐣弫瀵哥波閺嬫粍濮ら崨濠忕礉鐏炴洜銇氬Ο鈥崇础缂佸嫬鎮庨妴浣告嚒娑擃厹鈧胶鍋ｇ粚鎭掆偓浣镐海閻╊喗鐖ｉ妴浣界Т閺冭翰鈧胶瀚忛崙璇层亼鐠愩儯鈧礁鍣涵顔惧芳閵嗕礁閽╅崸鍥ф嚒娑擃厹鈧焦娓舵担瀹犵箾閸戞眹鈧焦鈧崵鏁ら弮韬测偓浣界槑缁狙佲偓浣规拱鏉烆喛顔曠純顔兼嫲鐠侇厾绮屽楦款唴閵?

### 娣囶喗鏁?
- 閻嫬鍣ù瀣槸閸愬懘鍎寸亸鍡櫺╅崝銊ｂ偓浣规杹婢堆冩嫲楠炲弶澹堥懗钘夊閺€閫涜礋閸欘垳绮嶉崥鍫濆灲閺傤叏绱濇妯款吇缂佸繐鍚€/闂勫秶楠囬弨鎯с亣/缁夎濮╅棃?閻喎浜ｉ獮鍙夊閸忋儱褰涙禒宥勭箽閹镐礁甯張澶愮帛鐠併倛顕㈡稊澶堚偓?
- 鐎瑰本鍨氶崥搴濈箽閻ｆ瑣鈧本鐓￠惇瀣Г閸涘鈧秵瀵滈柦顕嗙礉閸忎浇顔忛悽銊﹀煕閸ョ偟婀呴張顒冪枂缂佹挻鐏夐妴?

### 娣囶喖顦?
- 閻欐瑥鍤幍瀣亼鐠愩儱鑴婄粣妤€鍤悳鐗堟娴兼碍娈忛崑婊€绗呮稉鈧惄顔界垼鐠佲剝妞傞敍宀€鏁ら幋椋庘€樼拋銈呮倵閸愬秶鎴风紒顓ㄧ礉闁灝鍘ゅ鍦崶閼冲苯鎮楁潻鐐电敾鐟欙箑褰傛径杈Е閵?

### 妞嬪酣娅撻崣妯绘纯
- 閺傛壆绮嶉崥鍫濇嫲閻欐瑥鍤幍瀣嚠閸愬啿娼庢稉娲帛鐠併倕鍙ч梻顓犳畱鐠佸墽鐤嗘い鐧哥幢缂佹挻鐏夋禒宥呭涧閸︺劌缍嬮崜宥夈€夐棃銏犵潔缁€鐚寸礉娑撳秴鍟撻崗?AppState閵嗕焦鏆熼幑顔肩氨閹存牕顒熸稊鐘侯唶瑜版洏鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_aim.dart lib/src/ui/pages/toolbox_human_tests_aim_widgets.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --name "aim test" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_116-VISUAL-MEMORY-REPORT-AND-DECOYS] - 2026-05-06

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴缂佈呯敾娴兼ê瀵查妴宀冾潒鐟欏顔囪箛鍡愨偓宥忕窗楠炲弶澹堥懝鎻掓▕鎼存棃娈㈤梾鎯у閸滃矁绻樻惔锕€褰夊妤佹纯閹恒儴绻庨敍宀€娲伴弽鍥杹閼硅尙鐡戠拠瀛樻鐟曚焦娲垮〒鍛珰閼奉亞鍔ч敍灞借嫙閸︺劍绁寸拠鏇犵波閺夌喐妞傚鐟板毉缂佺喕顓搁崚鍡樼€介幎銉ユ啞閵?

### 閺傛澘顤?
- 鐟欏棜顫庣拋鏉跨箓缂佹挻娼弮鑸垫煀婢х偟绮虹拋鈥冲瀻閺嬫劖濮ら崨濠傝剨缁愭绱濈仦鏇犮仛閺堚偓妤傛鐡戠痪褋鈧礁鐣幋鎰彠閸椔扳偓浣告礀韫囧棛宸奸妴浣哄仯閸戣鍣涵顔惧芳閵嗕浇顕ら悙瑙勬降濠ф劑鈧浇绻庢导鑹板閸樺濮忛崪灞炬付鏉╂垵鍙ч崡鈩冩缂佸棎鈧?
- 瑜扳晞澹婇惄顔界垼閸滃本瀵氱€规岸顤侀懝鍙壞佸蹇旀煀婢х偐鈧粏绻庢导鑹板閸樺濮忛垾婵婎吀缁犳绱濋梾蹇涙鎼达负鈧胶鐡戠痪褋鈧焦膩瀵繐鎷伴獮鍙夊瀵搫瀹抽幓鎰磳閿涘苯鐨㈠鍌濆楠炲弶澹堥柅鎰劄鐠嬪啯鍨氶弴瀛樺复鏉╂垹娲伴弽鍥閵?

### 娣囶喗鏁?
- 娴兼ê瀵茬憴鍡氼潕鐠佹澘绻傛い鐢告桨鐠囧瓨妲戦妴浣烘窗閺嶅洩澹?pill閵嗕浇顫囩€电喖妯佸▓闈涙嫲鏉堟挸鍙嗛梼鑸殿唽閹绘劗銇氶敍灞煎▏閳ユ粍婀版潪顔炬窗閺嶅洩澹婇垾婵嗘嫲閳ユ粌鎽㈡禍娑欑壐鐎涙劗鐣荤拠顖滃仯閳ユ繃娲块惄瀛樺复閵?
- 楠炲弶澹堥弽鑹邦啎缂冾喛顕╅弰搴に夐崗鍛搭杹閼瑰弶膩瀵繋绗呴惃鍕箮娴艰壈澹婇弫鍫熺亯閿涘矂浼╅崗宥囨暏閹撮攱濡搁獮鍙夊瀵搫瀹抽崣顏嗘倞鐟欙絼璐熼悘鎷屽閺嶅吋鏆熼柌蹇嬧偓?

### 妞嬪酣娅撻崣妯绘纯
- 鏉╂垳鎶€閼规彃鍏遍幍鏉垮涧瑜板崬鎼锋０婊嗗濡€崇础閿涙盯绮拋銈勭秴缂冾喛顔囪箛鍡曠矝娣囨繃瀵旂紒蹇撳悁閻溾晜纭堕妴鍌滅波閺夌喐濮ら崨濠佺矌娴ｈ法鏁よぐ鎾冲妞ょ敻娼伴崘鍛摠缂佺喕顓搁敍灞肩瑝閸愭瑥鍙?AppState閵嗕焦鏆熼幑顔肩氨閹存牕顒熸稊鐘侯唶瑜版洏鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_visual_memory.dart lib/src/ui/pages/toolbox_human_tests_visual_memory_widgets.dart test/toolbox_visual_memory_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/toolbox_visual_memory_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/toolbox_visual_memory_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_123-TYPING-PRO-MODULE] - 2026-05-06

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿閵嗗苯浼愰崗椋庮唸 - 娴滆櫣琚ù瀣槸娑擃厼绺?- 閹垫挸鐡уù瀣槸閵嗗秳绮犻崺铏诡攨閸欘垳鏁ら悩鑸碘偓浣瑰⒖鐏炴洑璐熼弴缈犵瑩娑撴艾鐣崰鍕畱閸旂喕鍏樺Ο鈥虫健閿涘矁顩惄鏍у敶鐎瑰箍鈧浇鍙崨铏佸蹇嬧偓浣筋嚔鐟封偓閸滃瞼绮ㄩ弸婊勫Г閸涘鈧?

### 閺傛澘顤?
- 閹垫挸鐡уù瀣槸閺傛澘顤冩稉顓熸瀮閵嗕浇瀚抽弬鍥モ偓浣硅穿閸氬牄鈧焦妫╅弬鍥ф嫲鐟楄儻顕㈢拠顓熸灐閿涘苯鑻熼幐澶夌瑩濞夈劊鈧胶娼惇鐘偓浣瑰Η閺堫垬鈧胶鐓弬鍥モ偓浣界槤濮瑰洤鎷伴弮鍛邦攽娑撳顣介幎钘夊絿閸愬懎顔愰妴?
- 閹垫挸鐡уù瀣槸閺傛澘顤冮惌顓炲綖閵嗕焦鐖ｉ崙鍡楁嫲闂€鎸庮唽娑撳銆傞梹鍨闁瀚ㄩ妴?
- 閹垫挸鐡уù瀣槸閺傛澘顤冪紒蹇撳悁閵嗕礁鍟块崚鎭掆偓浣虹翱閸戝棎鈧胶娲搁幍鎾扁偓浣侯儊閸欐灚鈧胶绫傞柨娆嶁偓浣峰敩閻礁鎷伴弫鏉跨摟閸忣偆顫掔拋顓犵矊濡€崇础閵?
- 閺傛澘顤冪€涙顑佺痪褍鐤勯弮璺哄冀妫ｅ牞绱濋崠鍝勫瀻濮濓絿鈥橀妴渚€鏁婄拠顖樷偓浣哥窡鏉堟挸鍙嗛崪灞界秼閸撳秷绶崗銉ょ秴缂冾喓鈧?
- 閺傛澘顤?WPM閵嗕礁鍣?WPM閵嗕竼PM閵嗕礁鍣涵顔惧芳閵嗕線鏁婄拠顖涙殶閵嗕礁娲栭柅鈧弫鑸偓浣烘暏閺冭翰鈧浇绻樻惔锕€鎷扮粙鍐茬暰閹勫瘹閺嶅洢鈧?
- 鐎瑰本鍨氶崥搴㈡煀婢х偟绮ㄩ弸婊勫Г閸涘绱濈仦鏇犮仛缁涘楠囬妴浣稿槻閸婂ジ鈧喎瀹抽妴渚€鏆遍崑婊堛€戦妴渚€鏁婄拠顖滅波閺嬪嫨鈧線鏁婄拠顖滃劰閸栨亽鈧浇顔勭紒鍐ㄧ紦鐠侇喓鈧礁缂撶拋顔剧矊娑旂姴鍙嗛崣锝冣偓浣鼓佸?鐠囶叀鈻?娑撳顣?闂€鍨閹芥顩﹂崪灞炬拱妞ゅ灚娓舵潻鎴犵波閺嬫嚎鈧?
- 閺傛澘顤冮幍鎾崇摟濞村鐦?smoke test閿涘矁顩惄鏍ㄦ煀婢х偞膩瀵繈鈧浇顕㈢懛鈧妴渚€鏆辨惔锔衡偓浣峰敩閻浇顕㈤弬娆忔嫲鐎瑰本鍨氶幎銉ユ啞閵?

### 娣囶喗鏁?
- 閹垫挸鐡уù瀣槸娴?`toolbox_human_tests_cognition.dart` 閹峰棗鍨庨崚鎵缁?typing part 缂佸嫸绱濋獮鎯扮箻娑撯偓濮濄儲濯堕崚?`copy/data/widgets`閿涘矂妾锋担搴濆瘜閻樿埖鈧焦鏋冩禒鍓佹埛缂侇叀鍟懗鈧搴ㄦ珦閵?
- 閺囧瓨鏌婃禍铏硅濞村鐦稉顓炵妇閹垫挸鐡уù瀣槸閸忋儱褰涚拠瀛樻閸?toolbox 濡€虫健鐠囧瓨妲戦妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺傛澘顤冨Ο鈥崇础閵嗕浇顕㈤弬娆忔嫲闂€鍨閸欘亜濂栭崫宥呯秼閸撳秵澧︾€涙绁寸拠鏇€夐棃銏犲祮閺冩儼顔勭紒鍐跨幢缂佹挻鐏夋禒宥勭瑝閸愭瑥鍙?AppState閵嗕椒瀵岄弫鐗堝祦鎼存挻鍨ㄧ€涳缚绡勭拋鏉跨秿閵?
- 閻╁弶澧﹀Ο鈥崇础閺€閫涜礋閸楁洝顢戦梾鎰鏉堟挸鍙嗛敍宀勪缉閸忓秴顦跨悰宀勬閽樺繑鏋冮張顒冪翻閸忋儱婀?Flutter 娑擃叀袝閸欐垶鏌囩懛鈧妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_typing.dart lib/src/ui/pages/toolbox_human_tests_typing_copy.dart lib/src/ui/pages/toolbox_human_tests_typing_data.dart lib/src/ui/pages/toolbox_human_tests_typing_widgets.dart test/toolbox_typing_test_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/toolbox_typing_test_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/toolbox_typing_test_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍娑樻嚒娴犮倖婀￠梻?pub advisories 鐟欙絿鐖滈幍鎾冲祪 warning閿涘奔绲惧ù瀣槸闁偓閸戣櫣鐖滄稉?0閿?

## [Unreleased-PLAN_121-NUMBER-MEMORY-ROUND-REPORT] - 2026-05-06

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閺佹澘鐡х拋鏉跨箓瑜扳晞澹婇弫鏉跨摟濡€崇础鏉堟挸鍙嗛梼鑸殿唽濞屸剝婀侀弰搴ｂ€橀幓鎰仛鐟曚礁灏柊宥呮憿缁夊秶娲伴弽鍥杹閼硅绱濋崥灞炬鐢本婀滈弬鍥攳閺囩鍤滈悞璁圭礉楠炶泛婀稉鈧潪顔剧波閺夌喎鎮楅崗鍫熺叀閻绮虹拋鈥冲瀻閺嬫劧绱濋柆鍨帳閼奉亜濮╃紒褏鐢婚幋鏍嚖鐟欙箓鍣哥純顔衡偓?

### 閺傛澘顤?
- 閺佹澘鐡х拋鏉跨箓濮ｅ繗鐤嗛幓鎰唉閸氬孩鏌婃晶鐐电波閺嬫粌鑴婄粣妤嬬礉鐏炴洜銇氬Ο鈥崇础閵嗕胶鐡戠痪褋鈧浇顫夊Ο掳鈧胶娲伴弽鍥モ偓浣镐粻閻ｆ瑦妞傞梻娣偓浣诡劀绾喚鐡熷鍫涒偓浣烘暏閹寸柉绶崗銉ｂ偓浣虹柈鐠佲剝顒滅涵顔惧芳閸滃本娓舵總鐣岀搼缁狙佲偓?
- 瑜扳晞澹婇弫鏉跨摟濡€崇础閸︺劌鐫嶇粈鐑樻埂閼哥偛褰撮崘鍛煀婢х偟娲伴弽鍥杹閼硅尪澹婇崸妤佸絹缁€鐚寸礉鏉堟挸鍙嗛張鐔兼閽樺繗鍨堕崣鏉挎嫲鏉堟挸鍙嗛幓鎰仛娑旂喍绻氶悾娆忓徔娴ｆ挾娲伴弽鍥杹閼瑰眰鈧?

### 娣囶喗鏁?
- 閺佹澘鐡х拋鏉跨箓濮濓絿鈥橀幓鎰唉閸氬簼绗夐崘宥堝殰閸斻劌绱戞慨瀣╃瑓娑撯偓鏉烆噯绱濋弨閫涜礋閸︺劌鑴婄粣妞捐厬閻㈣京鏁ら幋鐑解偓澶嬪閳ユ粈绗呮稉鈧潪?/ 閸愬秵娼垫稉鈧潪顔光偓婵囧灗閸忓牆浠犻悾娆嶁偓?
- 闁插秶鐤嗛幐澶愭尦閸︺劌鐫嶇粈鎭掆偓浣界翻閸忋儱鎷扮紒鎾寸亯瀵湱鐛ュù浣衡柤娑擃厾顩﹂悽顭掔礉閸戝繐鐨拠顖澬曞〒鍛敄閵?
- 娴兼ê瀵查弫鏉跨摟鐠佹澘绻傞崗銉ュ經閵嗕焦膩瀵繗顕╅弰搴℃嫲鐠佸墽鐤嗘い瑙勬瀮濡楀牞绱濇担鎸庡伎鏉╃増娲块幒銉ㄧ箮閺冦儱鐖堕惌顓☆嚔閵?

### 娣囶喖顦?
- 娣囶喖顦茶ぐ鈺勫閺佹澘鐡уΟ鈥崇础閸欘亝褰佺粈琛♀偓婊呮窗閺嶅洭顤侀懝娴嬧偓婵呯稻娑撳秷顕╅弰搴″徔娴ｆ捇顤侀懝鑼畱闂傤噣顣介妴?
- 娣囶喗顒滈弫鏉跨摟鐠佹澘绻傞張鈧總鐣岀搼缁狙呯埠鐠佲槄绱濋柆鍨帳濮濓絿鈥橀柅姘崇箖閸氬骸娲滅粵澶岄獓妫板嫬顤冮懓灞炬▔缁€鍝勪焊妤傛ǜ鈧?

### 妞嬪酣娅撻崣妯绘纯
- 閺佹澘鐡х拋鏉跨箓閹绘劒姘﹂崥搴ｆ畱閼哄倸顨旀禒搴ゅ殰閸斻劏绻橀崗銉ょ瑓娑撯偓鏉烆喗鏁兼稉鍝勮剨缁愭鈥樼拋銈忕礉娴溿倓绨伴弴瀵盖旀担鍡涙付鐟曚胶鏁ら幋宄邦樋娑撯偓濞嗭紕鈥樼拋銈冣偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_number_memory.dart lib/src/ui/pages/toolbox_human_tests_number_memory_models.dart lib/src/ui/pages/toolbox_human_tests_number_memory_view.dart lib/src/ui/pages/toolbox_human_tests_number_memory_widgets.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --plain-name "number memory exposes richer modes and millisecond controls" --reporter compact`閿涘牊婀€瑰本鍨氶敍娑樼秼閸撳秵绁寸拠鏇犵椽鐠囨垼顫﹂獮鎯邦攽閺€鐟板З闂冪粯鏌囬敍姝歵oolbox_human_tests_typing.dart` 闁插秴顦?`_buildReport`閿涘畭toolbox_human_tests_memory.dart` 缂傚搫鐨?`_roundTapCount` / `_roundMistakes` 鐎涙顔岄敍?

## [Unreleased-PLAN_120-JOYSTICK-PORTRAIT-LEFT-CONTROLS] - 2026-05-04

### 閸樼喎娲?
- 閻劍鍩涢柅姘崇箖缁€鐑樺壈閸ユ儳鎷伴幋顏勬禈閹稿洤鍤幗鍥ㄦ綄閹靛婧傞崡蹇氱殶閸忋劌鐫嗙粩鏍х潌娴犲秵妲告稉濠佺瑓閸棗褰旈敍灞炬埂閺堟稒鏁兼稉鍝勪箯娓氀呭缁斿甯堕崚鑸电埉閵嗕礁褰告笟褌瀵岄懜鐐插酱閿涙碍鎲為弶鍡楁躬瀹革缚绗傞敍灞界殸閸戣婀锔跨瑓閿涘矁鍨堕崣棰佺瑝鐞氼偆濮搁幀浣告嫲閹稿鎸抽柆顔藉皡閵?

### 閺傛澘顤?
- 閺傛澘顤冪粩鏍х潌閸忋劌鐫?smoke test閿涘矁顩惄鏍т箯娓氀勫付閸掕埖鐖妴浣稿礁娓氀嗗灦閸欒埇鈧焦鎲為弶鍡曠秴娴滃骸鐨犻崙璁崇瑐閺傜櫢绱濇禒銉ュ挤閹貉冨煑閸栬桨绗岄懜鐐插酱娑撳秳姘﹂崣鐘偓?

### 娣囶喗鏁?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熺粩鏍х潌閸忋劌鐫嗛弨閫涜礋瀹革附甯堕崣瀹犲灦閸欐澘绔风仦鈧敍灞藉礁娓氀嗗灦閸欐壆瀚崡鐘插⒖娴ｆ瑧鈹栭梻娣偓?
- 瀹革缚鏅堕幒褍鍩楅弽蹇旀暪缁捐櫕鎲為弶鍡愨偓浣稿彠闂傤厹鈧胶濮搁幀浣碘偓浣哥磻婵?闁插秶鐤嗘稉搴＄殸閸戠粯瀵滈柦顕嗙礉闁灝鍘ゆ禒璁崇秿閹貉冨煑闂堛垺婢樻潻娑樺弳閼哥偛褰撮崠鍝勭厵閵?
- 缁旀牕鐫嗛悩鑸碘偓渚€娼伴弶澶哥瑢瀵偓婵?闁插秶鐤嗛幐澶愭尦閺€閫涜礋缁愬嫭鐖痪闈涙倻缁毖冨櫨閻楀牞绱濋柅鍌炲帳瀹革缚鏅堕幒褍鍩楅崚妞尖偓?

### 妞嬪酣娅撻崣妯绘纯
- 缁旀牕鐫嗛崗銊ョ潌瀹革缚鏅堕幒褍鍩楅弽蹇庣窗閸楃姷鏁ら崶鍝勭暰缁愬嫬鍨€硅棄瀹抽敍宀冨灦閸欐澘顔旀惔锔炬祲鎼存柨鍣虹亸鎴礉娴ｅ棛娲伴弽鍥モ偓浣稿櫙閺勭喎鎷伴幓鎰仛娑撳秴鍟€鐞氼偅甯堕崚璺哄帗缁辩娀浼勯幐掳鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_hand_eye_fullscreen.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --name "joystick fullscreen portrait uses left controls and right stage|joystick fullscreen keeps controls off the center stage|joystick pad drag does not scroll the outer page" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_119-JOYSTICK-HAND-EYE-FULLSCREEN-REDO] - 2026-05-04

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閵嗗苯浼愰崗椋庮唸 - 娴滆櫣琚ù瀣槸娑擃厼绺?- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼妴宥呭弿鐏炲繑膩瀵繐鐡ㄩ崷銊﹀瘻闁?閹绘劗銇氶柆顔藉皡閻╊喗鐖ｉ妴浣稿弿鐏炲繑鎲為弶鍡楁嫲鐏忓嫬鍤幐澶愭尦娴ｅ秶鐤嗘稉宥囶儊閸氬牊铆鐏炲繐寮婚幍瀣惙娴ｆ粣绱濇禒銉ュ挤閺咁噣鈧岸銆夐幗鍥ㄦ綄娑撳﹣绗呴幏鏍уЗ鐎硅妲楃憴锕€褰傛い鐢告桨濠婃艾濮╅惃鍕６妫版ǜ鈧?

### 閺傛澘顤?
- 閺傛澘顤冮幗鍥ㄦ綄閺咁噣鈧岸銆夐幍瀣◢閸愯尙鐛婇崶鐐茬秺濞村鐦敍宀勭崣鐠囦礁婀幗鍥ㄦ綄閸栧搫鐓欐稉濠佺瑓閹锋牕濮╂稉宥勭窗濠婃艾濮╂径鏍х湴妞ょ敻娼伴妴?
- 閺囧瓨鏌婇幗鍥ㄦ綄閸忋劌鐫?smoke test閿涘矁顩惄鏍ㄥ付閸掕埖鐖稉搴濊厬婢额喛鍨堕崣棰佺瑝娴溿倕褰旈妴浣镐箯娓氀冪殸閸戣绗岄崣鍏呮櫠閹藉洦娼岄惃鍕煀閸忋劌鐫嗙敮鍐ㄧ湰閵?

### 娣囶喗鏁?
- 閹藉洦娼岄崗銊ョ潌闁插秵甯撴稉鍝勪箯娓氀冪殸閸戞眹鈧椒鑵戦梻瀵告窗閺嶅洩鍨堕崣鑸偓浣稿礁娓氀勬啚閺夊棛娈戝Ο顏勭潌缂佹挻鐎敍宀勩€婇柈銊х埠鐠佲€茬瑢瀵偓婵?闁插秶鐤嗛幒褍鍩楅悪顒傜彌閺€鎯ф躬娑擃參妫块幒褍鍩楃敮锔衡偓?
- 閸忋劌鐫嗛懜鐐插酱缁夊娅庨崘鍛村劥閻樿埖鈧焦褰佺粈鐑樻瀮鐎涙绱濋柆鍨帳閺傚洤鐡ч棃銏℃緲閹存牗鎼锋担婊勫瘻闁筋噣浼勯幐锛勬窗閺嶅洣绗岄崙鍡樻Е閵?
- 缁旀牕鐫嗛崗銊ョ潌閸氬本鐗遍弨閫涜礋閼哥偛褰撮妴浣风窗鐠囨繃甯堕崚韬测偓浣哥俺闁劋琚辩粩顖涙惙娴ｆ粌灏惃鍕波閺嬪嫸绱濋崙蹇撶毌閸欑姴濮炵仦鍌炰紕閹嘎扳偓?
- 閺咁噣鈧岸銆夐崪灞藉弿鐏炲繑鎲為弶鍡樺付娴犺埖鏁奸悽銊﹀瘹闁藉牏楠囬幏鏍уЗ鐠囧棗鍩嗛敍灞炬啚閺夊棗灏崺鐔剁窗娑撹濮╅幎銏犲窗閹锋牕濮╅幍瀣◢閿涘矂妾锋担搴濈瑢妞ょ敻娼扮痪闈涙倻濠婃艾濮╅崘鑼崐閵?

### 妞嬪酣娅撻崣妯绘纯
- 閹藉洦娼屾稉搴＄殸閸戣婀崗銊ョ潌娑擃厾娈戝锕€褰告担宥囩枂閸欐垹鏁撻崣妯哄閿涙艾鐨犻崙璇叉躬瀹革缚鏅堕敍灞炬啚閺夊棗婀崣鍏呮櫠閿涘瞼顑侀崥鍫㈡暏閹撮攱瀵氱€规氨娈戦垾婊冪殸閸戠粯瀵滈柦顔兼躬閸樼喐鎲為弶鍡曠秴缂冾喓鈧焦鎲為弶鍡楁躬閸忔娊妫撮幐澶愭尦娴ｅ秶鐤嗛垾婵堟畱閸欏本澧滃Ο顏勭潌閹垮秳缍旈張鐔告箿閵?
- 閹靛濞嶉幎銏犲窗娴犲懍缍旈悽銊ょ艾閹藉洦娼岄幒褌娆㈤懛顏囬煩閸栧搫鐓欓敍灞惧付娴犺泛顦绘い鐢告桨濠婃艾濮╃悰灞艰礋娑撳秴褰夐妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_fullscreen.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --name "joystick fullscreen keeps controls off the center stage|joystick pad drag does not scroll the outer page|joystick coordination exposes joystick modes and controls|hand-eye fullscreen entry opens release-ready controls" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_118-AIM-REVEAL-GROWTH] - 2026-05-04

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴鐏忓棎鈧瞼鐎崙鍡樼ゴ鐠囨洏鈧秳鑵戦惃鍕竾閸旀稓缂夐崷鍫熸暭娑撴椽妾风痪褎鏂佹径褝绱伴惄顔界垼娴犲孩鐎亸蹇嬧偓渚€绮拋銈堝€濋惇闂寸瑝閸欘垵顫嗛惃鍕仯瀵偓婵绱濋崷?100-150ms 閸愬懎鎻╅柅鐔告杹婢堆冨煂閸曞宸遍崣顖濐潌閿涘苯鍟€閹镐胶鐢婚弨鎯с亣閿涘苯鑻熼崗浣筋啅闁板秶鐤嗛柅鐔哄芳閺囪尙鍤庨崪宀€娲伴弽鍥ㄦ锤缁捐￥鈧?

### 閺傛澘顤?
- 闂勫秶楠囬弨鎯с亣濡€崇础閺傛澘顤冮崚婵嗩潗閻愮懓绶為妴浣规▔瑜般垺妞傞梻娣偓浣稿讲鐟欎胶鍋ｅ鍕┾偓浣规杹婢堆団偓鐔哄芳閵嗕線鈧喓宸奸弴鑼殠閸滃瞼娲伴弽鍥ㄦ锤缁捐儻顔曠純顔衡偓?
- 闂勫秶楠囬弨鎯с亣閻╊喗鐖ｉ弨閫涜礋閸楁洜鍑介悙鍦Ц閻╊喗鐖ｉ敍灞炬▔缁€铏规纯瀵板嫪绗岄崨鎴掕厬閸楀﹤绶為崥灞绢劄閸欐ê瀵查妴?

### 娣囶喗鏁?
- 閸樼喆鈧瞼缂夐崷鍫濆竾閸?/ Shrinking閵嗗秵膩瀵繑娴涢幑顫礋閵嗗矂妾风痪褎鏂佹径?/ Reveal grow閵嗗稄绱濋惄顔界垼鐏忓搫顕禒搴ㄢ偓鎺戝櫤缂傗晛婀€閺€閫涜礋閸掑棙顔岄弨鎯с亣閵?
- 閺囧瓨鏌婇惉鍕櫙濞村鐦崗銉ュ經鐠囧瓨妲戦妴渚€銆夐棃銏ｎ嚛閺勫簺鈧焦膩閸ф顕╅弰搴℃嫲 smoke test 閺傤叀鈻堥妴?

### 妞嬪酣娅撻崣妯绘纯
- 姒涙顓绘禒宥勭箽閻ｆ瑧绮￠崗鍝ュ仯闂堟湹璐熼崚婵嗩潗濡€崇础閿涙盯妾风痪褎鏂佹径褍褰цぐ鍗炴惙瑜版挸澧犳い鐢告桨閸楄櫕妞傜拋顓犵矊閿涘奔绗夐崘娆忓弳 AppState閵嗕焦鏆熼幑顔肩氨閹存牕顒熸稊鐘侯唶瑜版洏鈧?
- 闂勫秶楠囬弨鎯с亣閸掓繂顫愰悙褰掔帛鐠?0.2dp閿涘苯褰查懗钘夋躬闁劌鍨庣仦蹇撶娑撳﹤鐣崗銊ょ瑝閸欘垵顫嗛敍娑氭暏閹村嘲褰查柅姘崇箖鐠佸墽鐤嗙拫鍐ㄣ亣閸掓繂顫愰悙鐟扮窞閵嗕焦妯夎ぐ銏℃闂傚瓨鍨ㄩ崣顖濐潌閻愮懓绶為妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_aim.dart lib/src/ui/pages/toolbox_human_tests_aim_widgets.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --plain-name "aim test exposes multiple target modes and feedback" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_116-VISUAL-MEMORY-MULTI-MODE] - 2026-05-04

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴娑撴挻鏁炵€瑰苯鏉介妴灞戒紣閸忛顔?- 娴滆櫣琚ù瀣槸娑擃厼绺?- 鐟欏棜顫庣拋鏉跨箓閵嗗秵膩閸ф绱拌ぐ鎾冲娴犲懏婀侀崶鍝勭暰 4x4 閸╄櫣顢呴悳鈺傜《閿涘矂娓剁憰浣哥唨娴滃酣姣︽惔锕€鎷版潻娑樺閹碘晛鐫嶉敍灞借嫙婢х偛濮炴０婊嗗閵嗕焦瀵氱€规岸顤侀懝韫瑢楠炲弶澹堢粵澶庡彯閸涘疇顔曠純顔衡偓?

### 閺傛澘顤?
- 鐟欏棜顫庣拋鏉跨箓閺傛澘顤冩潪濠氬櫤閵嗕焦鐖ｉ崙鍡愨偓浣界箻闂冭泛鎷伴懛顏勭暰娑斿娲撳锝夋▉濮婎垶姣︽惔锔肩礉姒涙顓婚梾蹇曠搼缁狙傜矤 4x4 閹碘晛鐫嶉崚?6x6閿涘苯鑻熼幓鎰扮彯閻╊喗鐖ｉ弽鍏兼殶闁插繈鈧?
- 閺傛澘顤冩担宥囩枂鐠佹澘绻傞妴浣稿兊閼硅尙娲伴弽鍥ф嫲閹稿洤鐣炬０婊嗗娑撳顫掑Ο鈥崇础閿涙稑鍍甸懝鑼窗閺嶅洦鐦℃潪顕€娈㈤張鐑樺瘹鐎规氨娲伴弽鍥杹閼硅绱濋崣顏嗗仯閸戣顕惔鏃堫杹閼瑰弶鏌熼崸妤佸缁犳顒滅涵顕嗙礉閸忔湹绮０婊嗗閺傜懓娼＄拋鈥茶礋鐠囶垳鍋ｉ妴?
- 閺傛澘顤冮弻鏂挎嫲閵嗕線鐭為弰搴℃嫲妤傛ê顕В鏂剧瑏婵傛顤侀懝韫瘜妫版﹫绱濋獮鑸垫暜閹镐浇顔曠純顔煎棘娑撳酣顤侀懝鍙夋殶闁插繈鈧?
- 閺傛澘顤冮崣顖炩偓澶婂叡閹电増鐗搁崪灞藉叡閹垫澘宸辨惔锕侇啎缂冾噯绱濈憴鍌氱檪闂冭埖顔屾０婵嗩樆闂傤亞骞囬悘鎷屽闂堢偟娲伴弽鍥ㄧ壐閵?
- 閺傛澘顤冪憴鍡氼潕鐠佹澘绻?smoke test閿涘矁顩惄鏍啎缂冾喖鐫嶅鈧妴浣稿兊閼硅尙娲伴弽鍥潐閸掓瑦褰佺粈鍝勬嫲瀵偓婵鐤嗗▎掳鈧?

### 娣囶喗鏁?
- 鐏忓棜顫嬬憴澶庮唶韫囧棔绮?`toolbox_human_tests_memory.dart` 閹峰棗鍨庢稉?`toolbox_human_tests_visual_memory.dart` 娑?`toolbox_human_tests_visual_memory_widgets.dart`閿涘矂浼╅崗宥囨埛缂侇厽澧挎径褑顔囪箛鍡涙肠閸氬牊鏋冩禒韬测偓?
- 閺囧瓨鏌婃禍铏硅濞村鐦崗銉ュ經閸滃矁顫嬬憴澶庮唶韫囧棝銆夌拠瀛樻閿涘瞼鐛婇崙鍝勫З閹胶缍夐弽绗衡偓渚€顤侀懝鑼窗閺嶅洤鎷伴獮鍙夊閻溾晜纭堕妴?
- 鐞涖儵缍堟禍铏硅濞村鐦稉璇茬氨娑擃厼鍑￠張澶嬪閸掑棙鏋冩禒鍓佹畱 part 婢圭増妲戦敍宀€鈥樻穱婵嗘倱娑撯偓 library 閸?Flutter 濞村鐦稉顓炲讲鐎瑰本鏆ｇ紓鏍槯閵?

### 妞嬪酣娅撻崣妯绘纯
- 姒涙顓绘禒宥勮礋娴ｅ秶鐤嗙拋鏉跨箓閸滃本鐖ｉ崙鍡涙鎼达讣绱辨０婊嗗濡€崇础閵嗕焦瀵氱€规岸顤侀懝韫瑢楠炲弶澹堥弽鐓庢綆闂団偓閻劍鍩涙稉璇插З瀵偓閸氼垱鍨ㄩ崚鍥ㄥ床閿涘奔绗夐崘娆忓弳 AppState閵嗕焦鏆熼幑顔肩氨閹存牕顒熸稊鐘侯唶瑜版洏鈧?
- 瑜扳晞澹婇惄顔界垼娑撳孩瀵氱€规岸顤侀懝鏌ュ厴娴ｈ法鏁ら惄顔界垼閼规彃鍨界€规熬绱辫ぐ鈺勫閻╊喗鐖ｆ穱婵堟殌鏉堝啳浜ゅ鍌濆楠炲弶澹堥敍灞惧瘹鐎规岸顤侀懝韫箽閻ｆ瑦娲垮鍝勫叡閹垫澘鐦戞惔锔衡偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_visual_memory.dart lib/src/ui/pages/toolbox_human_tests_visual_memory_widgets.dart test/toolbox_visual_memory_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/toolbox_visual_memory_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/toolbox_visual_memory_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_113-HAND-EYE-FULLSCREEN-INTERACTION] - 2026-05-04

### 閸樼喎娲?
- 閹靛婧傞崡蹇氱殶濞村鐦稉搴㈡啚閺夊棙澧滈惇鐓庡礂鐠嬪啫鍙忕仦?route 婢跺秶鏁ら弲顕€鈧岸銆夐悩鑸碘偓浣规閿涘本娅橀柅姘躲€夌悮顐ヮ洬閻╂牕鎮?ticker 閸嬫粍鎲滈敍灞筋嚤閼锋潙鍙忕仦蹇撳敶閻╊喗鐖?閸戝棙妲︽潻鎰З閵嗕浇顔曠純顔兼倱濮濄儱鎷伴幗鍥ㄦ綄娴溿倓绨板鍌氱埗閵?

### 閺傛澘顤?
- 閹靛婧傞崡蹇氱殶閸忋劌鐫嗛弬鏉款杻鐠佸墽鐤嗛幐澶愭尦娑撳氦顔曠純顕€娼伴弶鍖＄礉閸欘垰婀張顏囩箥鐞涘本鍨ㄧ€瑰本鍨氶崥搴ｆ纯閹恒儴鐨熼弫瀵告窗閺嶅洩顔曠純顔荤瑢楠炲弶澹堢拋鍓х枂閵?
- smoke test 鐞涖儱鍘栭幍瀣簜閸忋劌鐫嗙拋鍓х枂闂堛垺婢橀弬顓♀枅閿涘奔浜掗崣濠冩啚閺夊棗鍙忕仦蹇斿珛閸斻劍鎲為弶鍡楁倵閸戝棙妲︾€圭偤妾粔璇插З閻ㄥ嫭鏌囩懛鈧妴?

### 娣囶喗鏁?
- 閹靛婧傞崡蹇氱殶閸忋劌鐫嗛弨鍦暏閸忋劌鐫?route 閼奉亣闊╅惃鍕氦闁插繐鎶氭す鍗炲З閸掗攱鏌婇惄顔界垼娴ｅ秶鐤嗛敍灞炬珮闁岸銆夌拋鍓х枂閸︺劌鍙忕仦蹇撳敶缂佈呯敾閻㈢喐鏅ラ妴?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌鏉╂稑鍙嗛弮鑸靛复缁犫€冲櫙閺?閻╊喗鐖ｆ潻鎰З妞瑰崬濮╅敍宀勨偓鈧崙鍝勬倵閹稿绻嶇悰宀€濮搁幀浣逛划婢跺秵娅橀柅姘躲€夋す鍗炲З閿涘矂浼╅崗宥呭弿鐏炲繐鍞撮幗鍥ㄦ綄閺冪姵纭剁粔璇插З閵?
- 閹藉洦娼岄崗銊ョ潌缁旀牕鐫嗘稊鐔告暭娑撳搫涔忔笟褎鎲為弶鍡愨偓浣稿礁娓氀冪殸閸戣崵娈戞稉銈勬櫠鐢啫鐪敍宀勪缉閸忓秴鐨犻崙璁崇瑢閹藉洦娼屾稉濠佺瑓閸棗褰旈妴?
- 妤傛﹢妯侀獮鍙夊閻╊喗鐖ｉ弨閫涜礋閺囩鍒涙潻鎴犳埂閻╊喗鐖ｉ惃鍕秴缂冾喓鈧線顤侀懝鎻掓嫲閸楀繐鎮撴潻鎰З鏉炪劏鎶楅敍灞惧絹閸楀洦璐╁ǎ鍡氱窡閸斺晛宸辨惔锔肩幢姒涙顓绘禒宥呭彠闂傤厹鈧?
- 娣囶喖顦叉禍铏硅濞村鐦稉顓炵妇閹峰棗鍨?part 閻ㄥ嫮鈹栭幃顒€绱╅悽銊ｂ偓浣规殶鐎涙顔囪箛鍡涱杹閼硅弓绗傞梽鎰嚢閸欐牕鎷扮憴鍡氼潕鐠佹澘绻傞惄顔界垼妫版粏澹?token nullable 閹恒劍鏌囬梻顕€顣介敍宀勪缉閸忓秴鎮撳Ο鈥虫健缂傛牞鐦х悮顐︽▎閺傤厹鈧?

### 妞嬪酣娅撻崣妯绘纯
- 閸忋劌鐫嗛弬鏉款杻閻欘剛鐝涚敮褔鈹嶉崝銊ュ涧閸︺劌顕惔鏂垮弿鐏?route 鐎涙ɑ妞块張鐔兼？鏉╂劘顢戦敍娑欐啚閺夊棗鍙忕仦蹇庣窗閺嗗倸浠犻弲顕€鈧岸銆夋潻鎰З妞瑰崬濮╅敍宀勪缉閸忓秶些閸斻劑鈧喎瀹抽崣鐘插閵?
- 楠炲弶澹堥惄顔界垼婢х偛宸辨禒鍛躬閻劍鍩涘鈧崥顖炵彯闂冭泛鍏遍幍鏉挎倵閻㈢喐鏅ラ敍灞肩瑝閺€鐟板綁姒涙顓诲ù瀣槸闂呮儳瀹抽妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_aim.dart lib/src/ui/pages/toolbox_human_tests_reaction.dart lib/src/ui/pages/toolbox_human_tests_number_memory_view.dart lib/src/ui/pages/toolbox_human_tests_visual_memory.dart lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_fullscreen.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/ui_smoke_test.dart --name "hand-eye coordination exposes target settings|joystick coordination exposes joystick modes and controls|hand-eye fullscreen entry opens release-ready controls|joystick fullscreen uses opposite-side landscape controls" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_117-AIM-MULTI-MODE] - 2026-05-04

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴娑撴挻鏁炵€瑰苯鏉介妴灞戒紣閸忛顔?- 娴滆櫣琚ù瀣槸娑擃厼绺?- 閻嫬鍣ù瀣槸閵嗗稄绱濊ぐ鎾冲濡€虫健閸欘亝婀侀崺铏诡攨閻愬綊婢忛敍宀勬付鐟曚礁顤冮崝鐘虫纯婢舵碍膩瀵繐鎷扮搾锝呮嚄閹佲偓?

### 閺傛澘顤?
- 閻嫬鍣ù瀣槸閺傛澘顤冮崶娑氼潚濡€崇础閿涙氨绮￠崗鍝ュ仯闂堣翰鈧線妾风痪褎鏂佹径褋鈧胶些閸斻劑婢忛崪宀€婀￠崑鍥у叡閹佃埇鈧?
- 閺傛澘顤冮惄顔界垼閹粯鏆熼妴浣烘窗閺嶅洤銇囩亸蹇嬧偓浣规▔瑜般垺鏂佹径褍寮弫鑸偓浣盒╅崝銊┾偓鐔峰閸滃苯浜ｉ惄顔界垼閺佷即鍣虹拋鍓х枂閵?
- 閺傛澘顤冮崨鎴掕厬閵嗕浇顕ら悙骞库偓浣镐海閻╊喗鐖ｉ妴浣界Т閺冭翰鈧礁鍣涵顔惧芳閵嗕礁閽╅崸鍥ф嚒娑擃厹鈧焦娓舵担瀹犵箾閸戣鎷扮拠鍕獓閸欏秹顩妴?
- 閺傛澘顤冮惉鍕櫙濞村鐦?smoke test閿涘矁顩惄鏍佸蹇撳弳閸欙絻鈧浇顔曠純顔肩潔瀵偓閵嗕胶娲伴弽鍥╂晸閹存劕鎷扮拠顖滃仯閸欏秹顩妴?

### 娣囶喗鏁?
- 鐏忓棛鐎崙鍡樼ゴ鐠囨洑绮?`toolbox_human_tests_action.dart` 閹峰棗鍨庢稉?`toolbox_human_tests_aim.dart` 娑?`toolbox_human_tests_aim_widgets.dart`閵?
- 娴滆櫣琚ù瀣槸閸忋儱褰涙稉?toolbox 濡€虫健鐠囧瓨妲戦崥灞绢劄閺囧瓨鏌婇惉鍕櫙濞村鐦懗钘夊閹诲繗鍫妴?

### 妞嬪酣娅撻崣妯绘纯
- 姒涙顓绘禒宥勮礋缂佸繐鍚€閻愬綊婢忓Ο鈥崇础閿涙稒鏌婃晶鐐茨佸蹇庣矌瑜板崬鎼疯ぐ鎾冲妞ょ敻娼伴崡铏鐠侇厾绮岄敍灞肩瑝閸愭瑥鍙?AppState閵嗕焦鏆熼幑顔肩氨閹存牕顒熸稊鐘侯唶瑜版洏鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_aim.dart lib/src/ui/pages/toolbox_human_tests_aim_widgets.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --plain-name "aim test exposes multiple target modes and feedback" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_115-NUMBER-MEMORY-MULTI-MODE] - 2026-05-04

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴娑撴挻鏁炵€瑰苯鏉介妴灞戒紣閸忛顔?- 娴滆櫣琚ù瀣槸娑擃厼绺?- 閺佹澘鐡х拋鏉跨箓閵嗗稄绱濇晶鐐插閺囧绨跨涵顔炬畱濮ｎ偆顫楃拋鍓х枂閵嗕浇澹婅ぐ鈹库偓浣割樋閺佹澘鐡ч崡鏇犳窗閺嶅洢鈧浇顓哥粻妤€绱￠崪宀勬閺堝搫瀵茬粵澶庡厴閸旀冻绱濋獮鍫曚缉閸忓秴濂栭崫宥呭従鐎瑰啫鑻熺悰灞兼叏閺€閫涜厬閻ㄥ嫭膩閸фぜ鈧?

### 閺傛澘顤?
- 閺佹澘鐡х拋鏉跨箓閺傛澘顤冮崶娑氳鐠侇厾绮屽Ο鈥崇础閿涙碍鏆熺€涙ぞ瑕嗛妴浣稿兊閼瑰弶鏆熺€涙ぜ鈧礁顦块弫鏉跨摟閻╊喗鐖ｉ崪宀冾吀缁犳绱￠妴?
- 閺傛澘顤冪划鍓р€樺В顐ゎ潡鏉堟挸鍙嗛敍灞炬▔缁€鍝勪粻閻ｆ瑦鏁幐?50-60000ms 閹靛濮╂惔鏃傛暏閿涙稒绮﹂崝銊︽蒋娣囨繄鏆€ 100-5000ms 韫囶偊鈧喕鐨熼懞鍌樷偓?
- 閺傛澘顤冮梾蹇旀簚閸嬫粎鏆€閺冨爼妫块妴渚€娈㈤張杞扮秴閺佽埇鈧礁鍘戠拋鎼侇浕娴?0閵嗕線浼╅崗宥囨祲闁鍣告径宥囩搼闂呭繑婧€閸栨牔绗屾０姗€娼伴悽鐔稿灇闁銆嶉妴?
- 瑜扳晞澹婇弫鏉跨摟閺€顖涘瘮妫版粏澹婇弫浼村櫤鐠佸墽鐤嗛敍灞筋樋閺佹澘鐡ч惄顔界垼閺€顖涘瘮閸氬本妞傞弰鍓с仛缂佸嫭鏆熺拋鍓х枂閿涘矁顓哥粻妤€绱￠弨顖涘瘮妞よ鏆熼崪灞肩濞夋洖绱戦崗鐐解偓?
- 閺傛澘顤冮弫鏉跨摟鐠佹澘绻?smoke test閿涘矁顩惄鏍ь樋濡€崇础閸忋儱褰涢妴浣虹翱绾喗顕犵粔鎺曠翻閸忋儱鎷扮紒鍡楀瀻鐠佸墽鐤嗘い骞库偓?

### 娣囶喗鏁?
- 鐏忓棙鏆熺€涙顔囪箛鍡曠矤 `toolbox_human_tests_memory.dart` 閹峰棗鍨庢稉杞扮瑩閻?part 缂佸嫸绱伴悩鑸碘偓浣规簚閵嗕焦膩閸ㄥ鈧浇顫嬮崶鐐⒖鐏炴洖鎷扮亸蹇曠矋娴犺泛鍨庨崚顐ｆ暪閸欙絻鈧?
- 娴滆櫣琚ù瀣槸閸忋儱褰涙稉?toolbox 濡€虫健鐠囧瓨妲戦崥灞绢劄閺囧瓨鏌婇弫鏉跨摟鐠佹澘绻傞懗钘夊閹诲繗鍫妴?

### 妞嬪酣娅撻崣妯绘纯
- 姒涙顓诲Ο鈥崇础娴犲秳璐熺紒蹇撳悁閺佹澘鐡ф稉鎻掝槻閻滃府绱遍弬鏉款杻濡€崇础娴犲懎濂栭崫宥呯秼閸撳秵鏆熺€涙顔囪箛鍡涖€夐棃銏犲祮閺冩儼顔勭紒鍐跨礉娑撳秴鍟撻崗?AppState閵嗕焦鏆熼幑顔肩氨閹存牕顒熸稊鐘侯唶瑜版洏鈧?
- 閺佹澘鐡х拋鏉跨箓闂呮劘妫屾０姗€娼扮拋鈩冩閸ｃ劑鈧俺绻?round token 閸滃矂鍣哥純?鐠佸墽鐤嗛崣妯绘纯閸欐牗绉烽柅鏄忕帆閺€璺哄經閿涘矂妾锋担搴㈡＋閸ョ偠鐨熸稉鎻掓簚妞嬪酣娅撻妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_memory.dart lib/src/ui/pages/toolbox_human_tests_number_memory.dart lib/src/ui/pages/toolbox_human_tests_number_memory_models.dart lib/src/ui/pages/toolbox_human_tests_number_memory_view.dart lib/src/ui/pages/toolbox_human_tests_number_memory_widgets.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --plain-name "number memory exposes richer modes and millisecond controls" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_114-REACTION-MULTI-MODE] - 2026-05-04

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴娑撴挻鏁炵€瑰苯鏉介妴灞戒紣閸忛顔?- 娴滆櫣琚ù瀣槸娑擃厼绺?- 閸欏秴绨插ù瀣槸閵嗗稄绱濇晶鐐插閺囨潙顦垮Ο鈥崇础閸滃矁鍙崨铏偓褝绱濋獮鍫曚缉閸忓秴濂栭崫宥呭従鐎瑰啫鑻熺悰灞兼叏閺€閫涜厬閻ㄥ嫭膩閸фぜ鈧?

### 閺傛澘顤?
- 閸欏秴绨插ù瀣槸娣囨繄鏆€缂佸繐鍚€閹稿缍囩粵澶婄窡娣団€冲娇閸氬孩婢楅幍瀣剁礉楠炶埖鏌婃晶鐐存煙閸氭垶绮﹂崝銊ょ瑢妫版粏澹婇崠褰掑帳娑撱倗顫掑Ο鈥崇础閵?
- 閺傛澘顤冩潪顔筋偧閺侀绗屾穱鈥冲娇閼哄倸顨旂拋鍓х枂閿涘本鏁幐?5/8/12 鏉烆喕浜掗崣濠冪垼閸戝棎鈧礁鍟块崚鎭掆偓浣界碃閹垳绗佸锝夋閺堣櫣鐡戝鍛隘闂傛番鈧?
- 閺傛澘顤冮獮鍐叉綆閵嗕焦娓惰箛顐犫偓浣稿櫙绾喚宸奸妴浣界箾閸戞眹鈧浇绉寸搾濠傚隘闂傛潙鎷伴張顒傜矋鏉炪劏鎶楅崣宥夘洯閵?
- 閺傛澘顤冮崣宥呯安濞村鐦?smoke test閿涘矁顩惄鏍︾瑏濡€崇础閸忋儱褰涢妴浣规煙閸?D-pad閵嗕線顤侀懝鍙夊瘻闁筋喖鎷扮拋鍓х枂妞ゅ箍鈧?

### 娣囶喗鏁?
- 鐏忓棗寮芥惔鏃€绁寸拠鏇氱矤 `toolbox_human_tests_action.dart` 閹峰棗鍨庨崚?`toolbox_human_tests_reaction.dart`閿涘奔濞?action 閺傚洣娆㈢紒褏鐢婚崣顏呭鏉炵晫鐎崙鍡樼ゴ鐠囨洖鎷伴幍瀣偓鐔哥ゴ鐠囨洏鈧?
- 娴滆櫣琚ù瀣槸閸忋儱褰涙稉?toolbox 濡€虫健鐠囧瓨妲戦崥灞绢劄閺囧瓨鏌婇崣宥呯安濞村鐦懗钘夊閹诲繗鍫妴?
- 閸掔娀娅庢稉搴ｇ病閸忕寮芥惔鏃堝櫢婢跺秶娈戦悙鐟板毊娣団€冲娇閸?Go/No-Go 濡€崇础閿涘矂浼╅崗宥呭弳閸欙絽鍟戞担娆嶁偓?
- 閺傜懓鎮滈柅澶嬪娴犲孩铆閸氭垶瀵滈柦顔荤喘閸栨牔璐熸稉?瀹?娑?閸?娑?D-pad閿涘苯鑻熼弨顖涘瘮娑擃厼绺鹃幐澶夌秶閸氬骸鎮滈崶娑樻倻濠婃垵濮╅妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛崣顏冩叏閺€鐟板冀鎼存梹绁寸拠鏇€夐棃銏㈠Ц閹焦婧€閵嗕礁鍙嗛崣锝堫嚛閺勫簺鈧焦膩閸ф鏋冨锝勭瑢鐎规艾鎮滃ù瀣槸閿涙稐绗夐崘娆忓弳 AppState閵嗕焦鏆熼幑顔肩氨閹存牕鍙剧€瑰啩姹夌猾缁樼ゴ鐠囨洖鐡欏Ο鈥虫健閵?
- 閸欏秴绨插ù瀣槸闂呭繑婧€鐠佲剝妞傞崳銊┾偓姘崇箖 token 閸滃瞼绮烘稉鈧崣鏍ㄧХ闁槒绶弨璺哄經閿涘矂妾锋担搴″瀼閹广垺膩瀵繈鈧線鍣哥純顔藉灗缁傝绱戞い鐢告桨閸氬海娈戦弮褍娲栫拫鍐ц閸︽椽顥撻梽鈹库偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_reaction.dart lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --plain-name "reaction test exposes focused reaction modes" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_112-HAND-EYE-FULLSCREEN-RELEASE] - 2026-05-04

### 閸樼喎娲?
- 閵嗗本澧滈惇鐓庡礂鐠嬪啯绁寸拠鏇樷偓宥勭瑢閵嗗本鎲為弶鍡樺閻厧宕楃拫鍐︹偓宥呭弿鐏炲繑膩瀵繑顒濋崜宥呮礈鐠佹儳顦崗鐓庮啇閸滃苯绔风仦鈧梻顕€顣界悮顐″閺冨爼娈ｉ挊蹇ョ礉闂団偓鐟曚椒鎱ㄦ径宥呭煂閸欘垰绱戦崥顖氬絺鐢啰娈戠粙瀣閵?

### 閺傛澘顤?
- 閹靛婧傞崡蹇氱殶閸忋劌鐫嗛弬鏉款杻妞ゅ爼鍎存潪濠氬櫤缂佺喕顓搁棃銏℃緲閿涘苯鐫嶇粈楦跨枂濞喡扳偓浣告嚒娑擃厹鈧胶鍋ｇ粚鍝勬嫲楠炲啿娼庨崣宥呯安閿涘苯鑻熺悰銉ュ帠閻欘剛鐝涘鈧慨?闁插秶鐤嗛幒褍鍩?key 娓?smoke test 鐟曞棛娲婇妴?
- 閺傛澘顤冮崗銊ョ潌 smoke test閿涘矁顩惄鏍ㄥ閻厧鍙忕仦蹇撳弳閸欙絽褰叉潻娑樺弳閵嗕焦甯堕崚鑸靛瘻闁筋喛袝閹貉冩槀鐎甸潻绱濇禒銉ュ挤閹藉洦娼屽Ο顏勭潌閸忋劌鐫嗗锕€褰告稉銈囶伂閹貉冨煑鐢啫鐪妴?

### 娣囶喗鏁?
- 閹垹顦查幍瀣簜閸楀繗鐨熷ù瀣槸娑撳孩鎲為弶鍡樺閻厧宕楃拫鍐╂珮闁岸銆夐棃顫厬閻ㄥ嫬鍙忕仦蹇撳弳閸欙絻鈧?
- 閹靛婧傞崡蹇氱殶閸忋劌鐫嗛梾鎰閼哥偛褰撮崘鍛村櫢婢跺秴绱戞慨瀣瘻闁筋噯绱濋弨閫涜礋鎼存洟鍎寸粙鍐茬暰閹貉冨煑閸栫尨绱遍惄顔界垼缂佹ê鍩楅崪灞芥嚒娑擃厽顥呭ù瀣缉瀵偓妞ゅ爼鍎寸紒鐔活吀娑撳骸绨抽柈銊﹀付閸掕泛鐣ㄩ崗銊ュ隘閵?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼崗銊ョ潌闁插秵甯撴稉鐑樏仦蹇撲箯娓氀勬啚閺夊棎鈧椒鑵戦梻纾嬪灦閸欒埇鈧礁褰告笟褍鐨犻崙缁樺瘻闁筋噯绱濆鈧慨?缂佹挻娼?闁插秶鐤嗛悪顒傜彌娴ｅ秳绨惔鏇㈠劥娑擃厼銇庨敍娑氱彨鐏炲繋绻氶悾娆忕俺闁劋琚辩粩顖涘付閸掕泛绔风仦鈧妴?
- 閹藉洦娼岄崗銊ョ潌閼哥偛褰存稉宥呭晙閸欑姴濮為崘鍛村劥瀵偓婵瀵滈柦顕嗙礉闁灝鍘ら崪宀€瀚粩瀣付閸掕泛灏柌宥咁槻閵?
- 鐞涖儱鍘?`PLAN_112_閹靛婧傞崡蹇氱殶閸忋劌鐫嗛崣鎴濈缁狙傛叏婢?md` 楠炶埖娲块弬?toolbox 濡€虫健鐠囧瓨妲戦妴?

### 妞嬪酣娅撻崣妯绘纯
- 閸忋劌鐫?route 娴犲秴顦查悽銊ョ秼閸撳秹銆夐棃銏㈠Ц閹焦婧€閿涘奔绗夐弬鏉款杻閹镐椒绠欓崠鏍ㄦ殶閹诡噯绱卞Ο顏勭潌閺傜懓鎮滈柨浣哥暰缂佈呯敾娴犲懎婀?Android/iOS 閻㈢喐鏅ラ敍灞绢攽闂?Web 閸欘亙濞囬悽銊ョ秼閸?route 鐢啫鐪妴?
- 閹靛婧傞崗銊ョ潌鐎瑰鍙忛惄顔界垼閸栧搫鐓欐导姘辨殣瀵邦喚缂夌亸蹇撳讲閸掗娲伴弽鍥瘱閸ヨ揪绱濇担鍡涗缉閸忓秶娲伴弽鍥潶閻樿埖鈧焦鐖幋鏍ㄦ惙娴ｆ粌灏柆顔藉皡閵?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_fullscreen.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_fullscreen.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --plain-name "hand-eye coordination exposes target settings" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "joystick coordination exposes joystick modes and controls" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "hand-eye fullscreen entry opens release-ready controls" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "joystick fullscreen uses opposite-side landscape controls" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_111-README-DETAILED-UPDATE] - 2026-05-02

### 閸樼喎娲?
- 閺嶅湱娲拌ぐ?README 闂団偓鐟曚椒绮犵粻鈧憰浣风矙缂佸秴宕岀痪褌璐熼棃銏犳倻閺傛澘宕楁担婊嗏偓鍛偓浣烘樊閹躲倛鈧懎鎷伴崣鎴濈閸撳秵顥呴弻銉ф畱鐠囷妇绮忛崗銉ュ經閺傚洦銆傞妴?

### 娣囶喗鏁?
- 闁插秴鍟?`README.md`閿涘矁藟閸忓懘銆嶉惄顔肩暰娴ｅ秲鈧線銆婄仦鍌浤侀崸妞尖偓涔紀olbox 鐎涙劖膩閸фぜ鈧焦濡ч張顖涚垽閵嗕胶娲拌ぐ鏇犵波閺嬪嫨鈧胶骞嗘晶鍐ㄥ櫙婢跺洢鈧浇绻嶇悰灞剧€鎭掆偓渚€鐛欑拠浣圭ゴ鐠囨洏鈧焦鏆熼幑顔跨カ濠ф劑鈧礁娴楅梽鍛閵嗕礁绱戦崣鎴ｎ潐閼煎啨鈧焦鏋冨锝囧偍瀵洏鈧礁鐖剁憴渚€妫舵０妯烘嫲閸楀繋缍斿ù浣衡柤閵?
- 閺勫海鈥?`scripts/build.ps1` 鐎?Web target 閻ㄥ嫮顩﹂悽銊у閺夌噦绱濇禒銉ュ挤 FFI 娓氭繆绂嗘稉?Web 閺嬪嫬缂撻棁鈧憰浣规禌娴狅絽鐤勯悳鏉挎倵閸愬秴鎯庨悽銊ｂ偓?
- 閺傛澘顤?`PLAN_111_README_鐠囷妇绮忛弴瀛樻煀娑撳孩褰佹禍銈嗗腹闁?md`閿涘矁顔囪ぐ鏇熸拱鏉烆喗鏋冨锝嗘纯閺傝埇鈧焦褰佹禍銈呮嫲閹恒劑鈧浇绔熼悾灞烩偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒鍛纯閺傜増鏋冨锝忕礉娑撳秳鎱ㄩ弨鐟扮安閻劑鈧槒绶妴浣界熅閻究鈧胶濮搁幀浣碘偓浣界カ濠ф劖鍨ㄥù瀣槸娴狅絿鐖滈妴?

### 妤犲矁鐦?
- 瀹稿弶顥呴弻?README 閸愬懎顔愭稉?`pubspec.yaml`閵嗕梗scripts/`閵嗕焦膩閸ф鏁為崘宀冦€冮崪宀€骞囬張澶屾窗瑜版洜绮ㄩ弸鍕畱娑撯偓閼峰瓨鈧佲偓?
- 閺堫亣绻嶇悰?Flutter 濞村鐦敍娑欐拱鏉烆喗妫?Dart 娴狅絿鐖滈弨鐟板З閵?

## [Unreleased-PLAN_110-HAND-EYE-FULLSCREEN-ENTRY-HIDDEN] - 2026-04-30

### 閸樼喎娲?
- 瑜版挸澧犻崗銊ョ潌鐠侇厾绮岄崗銉ュ經娴犲秴鐡ㄩ崷銊啎婢跺洤鍚嬬€瑰綊妫舵０姗堢礉娴ｅ棝娓剁憰浣虹彌閸楀啿褰傜敮鍐嚠婢舵牗绁寸拠鏇＄箻鎼达箑瀵橀敍灞芥礈濮濄倕鍘涙稉瀛樻闂呮劘妫岄崗銉ュ經閵?

### 娣囶喗鏁?
- 闁俺绻冩稉瀛樻閸欐垵绔峰鈧崗鎶芥閽樺繑澧滈惇鐓庡礂鐠嬪啯绁寸拠鏇氱瑢閹藉洦娼岄幍瀣簜閸楀繗鐨熼惃鍕珮闁岸銆夐棃銏犲弿鐏炲繑瀵滈柦顕嗙礉楠炶泛婀禒锝囩垳娑擃厺绻氶悾?TODO 濞夈劑鍣撮妴?

### 妞嬪酣娅撻崣妯绘纯
- 閸忋劌鐫?route 娑撳骸鐤勯悳棰佺矝娣囨繄鏆€閿涘奔绮?UI 娑撳秴鍟€鐏炴洜銇氶崗銉ュ經閿涙稐鎱ㄦ径宥呯暚閹存劕鎮楅崣顖涗划婢跺秴绱戦崗鎶藉櫢閺傛澘绱戦弨淇扁偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?

## [Unreleased-PLAN_109-HAND-EYE-FULLSCREEN-INTERFERENCE] - 2026-04-30

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閹靛婧傞崡蹇氱殶濞村鐦稉搴㈡啚閺夊棙澧滈惇鐓庡礂鐠嬪啳绻橀崗銉ュ弿鐏炲繐鎮楅悙鐟板毊瀵偓婵绗夐崚閿嬫煀閸忋劌鐫嗛懜鐐插酱閵嗕線鈧偓閸戝搫鎮楁径鏍劥妞ょ敻娼伴幍宥呮儙閸旑煉绱遍崥灞炬闂団偓鐟曚焦铆鐏炲繑鐭囧ù绋垮弿鐏炲繈鈧焦澧挎径褑顔曠純顔垮瘱閸ユ番鈧浇鍤滅€规矮绠熸潏鎾冲弳閵嗕礁鐣弫鏉戠暚閹存劖濮ら崨濠傛嫲姒涙顓婚崗鎶芥４閻ㄥ嫬顦块惄顔界垼閸嬪洨娲伴弽鍥у叡閹佃埇鈧?

### 閺傛澘顤?
- 閹靛婧傞崡蹇氱殶濞村鐦弬鏉款杻閼奉亜鐣炬稊澶嬫殶閸婅壈绶崗銉窗鏉烆喗鏆熼妴浣规▔缁€鐑樻闂€瑁も偓浣盒╅崝銊ョ畽鎼达负鈧線鈧喎瀹抽妴浣哄仯閸戠粯顐奸弫鏉挎嫲閻╊喗鐖ｆ径褍鐨崸鍥у讲閸︺劍绮﹂崝銊︽蒋婢舵牜娲块幒銉ㄧ翻閸忋儯鈧?
- 閹靛婧傞崡蹇氱殶濞村鐦弬鏉款杻姒涙顓婚崗鎶芥４閻ㄥ嫰鐝梼璺侯樋閻╊喗鐖ｉ惇鐔蜂海楠炲弶澹堥敍灞藉讲鐠佸墽鐤嗛崑鍥╂窗閺嶅洤鍤悳鐗堫洤閻滃洣绗岄張鈧径褎鏆熼柌蹇ョ礉閸嬪洨娲伴弽鍥﹀▏閻劑鏁婄拠顖濆閸栧搫鍨庨獮璺哄礋閻欘剛绮虹拋掳鈧?
- 閹靛婧傞崡蹇氱殶濞村鐦€瑰本鍨氶崥搴¤剨閸戝搫鐣弫瀵哥波閺嬫粍濮ら崨濠忕礉閸栧懎鎯堥幋鎰/濠曞繑甯€/閻愬湱鈹?閸嬪洨娲伴弽鍥モ偓浣搁挬閸?閺堚偓韫囶偄寮芥惔鏂烩偓浣搁挬閸у洤鐣幋鎰闂€鍨嫲闁劘鐤嗛弰搴ｇ矎閵?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼弬鏉款杻閻╊喗鐖ｆ径褍鐨拋鍓х枂閵嗕浇鍤滅€规矮绠熸潏鎾冲弳閵嗕線绮拋銈呭彠闂傤厾娈戦惄顔界垼缁夎濮╃拋鍓х枂閸滃矂绮拋銈呭彠闂傤厾娈戞径姘辨窗閺嶅洤浜ｉ惄顔界垼楠炲弶澹堢拋鍓х枂閵?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熺€瑰本鍨氶崥搴¤剨閸戝搫鐣弫瀛樺Г閸涘绱濋崠鍛儓濡€崇础閵嗕浇绻樻惔锔衡偓浣告嚒娑擃厹鈧礁鐨犵粚鎭掆偓浣稿櫙绾喚宸奸妴浣稿冀鎼存梹妲戠紒鍡愨偓浣镐海閻╊喗鐖ｇ亸鍕毊閵嗕胶娲伴弽鍥с亣鐏忓繐鎷伴惄顔界垼缁夎濮╅悩鑸碘偓浣碘偓?

### 娣囶喗鏁?
- 娣囶喖顦叉稉銈勯嚋閹靛婧傞崡蹇氱殶鐎涙劖膩閸ф鍙忕仦?route 婢跺秶鏁ゆ径鏍х湴閻樿埖鈧焦妞傛稉宥呭煕閺傛壆娈戦梻顕€顣介敍娑樺弿鐏炲繐鍞撮悙鐟板毊瀵偓婵绱扮粩瀣祮閺囧瓨鏌婅ぐ鎾冲閸忋劌鐫嗛懜鐐插酱閵?
- 娑撱倓閲滈崗銊ョ潌閸忋儱褰涢弨閫涜礋缁夎濮╃粩顖浢仦蹇旂焽濞村憡膩瀵骏绱濋柅鈧崙鍝勬倵閹垹顦茬化鑽ょ埠 UI 閸滃本鏌熼崥鎴幢閸忋劌鐫嗙敮鍐ㄧ湰娑撳秴鍟€鐏炴洜銇氶弲顕€鈧岸銆夐棃銏㈢埠鐠佲€蹭繆閹垬鈧?
- 閹藉洦娼岄崗浣筋啅閹锋牕鍤崢鐔奉潗閹藉洦娼岄懠鍐ㄦ纯閿涘苯鑻熺亸鍡氱Т閸戝搫绠欐惔锔炬暏娴滃孩甯堕崚璺哄櫙閺勭喖鈧喓宸奸敍灞煎▏閹靛鍔呴弴瀛樺复鏉╂垶澧滈張鐑樼埗閹村繗娅勯幏鐔告啚閺夊棎鈧?
- 閹靛婧傛稉搴㈡啚閺夊棛娴夐崗瀹狀啎缂冾喚绮嶆禒韬测偓浣瑰Г閸涘﹤鑴婄粣妤€鎷伴幗鍥ㄦ綄閸忋劌鐫嗙敮鍐ㄧ湰缂佈呯敾閹峰棗鍨庨崚鎵缁?part 閺傚洣娆㈤敍宀勪缉閸忓秴宕熼弬鍥︽缂佈呯敾閼躲劏鍎夐妴?
- 鐎瑰本鍨氶幎銉ユ啞瀵湱鐛ラ弨閫涜礋娑撴挾鏁ら張澶愭鐏忓搫顕?`Dialog` 濡楀棙鐏﹂敍宀勪缉閸?`AlertDialog` 閸愬懎顔愰崷銊х崕鐏?姒х姵鐖ｉ崨鎴掕厬濞村鐦梼鑸殿唽閸戣櫣骞囬弮鐘叉槀鐎?RenderBox閵?
- 閹藉洦娼岄崗銊ョ潌閹貉冨煑閸栫儤鏁兼稉鐑樺瘻閸欘垳鏁ょ€硅棄瀹崇拋锛勭暬閹藉洦娼屾稉搴＄殸閸戠粯瀵滈柦顔兼槀鐎甸潻绱濋柆鍨帳 320dp 缁狙呯崕鐏炲繋绗呴崶鍝勭暰鐎硅棄瀹?Row 濠с垹鍤妴?

### 妞嬪酣娅撻崣妯绘纯
- 妤傛﹢妯侀崑鍥╂窗閺嶅洤鍏遍幍鏉挎嫲閹藉洦娼岄惄顔界垼缁夎濮╅崸鍥帛鐠併倕鍙ч梻顓ㄧ礉闁灝鍘ら弨鐟板綁姒涙顓婚幋鎰摋閸氼偂绠熼敍娑樼磻閸氼垰鎮楅梾鎯у娑撳孩濮ら崨濠冨瘹閺嶅洣绱伴弰搴㈡▔閸欐ê瀵查妴?
- 濡亜鐫嗛弬鐟版倻闁夸礁鐣炬禒鍛躬 Android/iOS 閻㈢喐鏅ラ敍灞绢攽闂堛垹鎷?Web 娑撳秴宸辩悰宀勬敚鐎规碍鏌熼崥鎴欌偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_fullscreen.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_reports.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_settings.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_fullscreen.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_reports.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_settings.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娑楃矌 `test/ui_smoke_test.dart` 娣囨繄鏆€閺冦垺婀?const/final info閿?
- `flutter test test/ui_smoke_test.dart --plain-name "hand-eye coordination exposes target settings" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "joystick coordination exposes joystick modes and controls" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "hand-eye completion report fits narrow viewport" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "joystick fullscreen controls fit narrow viewport" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_108-HAND-EYE-FULLSCREEN-TUNING] - 2026-04-30

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閹靛婧傞崡蹇氱殶濞村鐦惃?100% 鏉╂劕濮╅獮鍛閸滃本娓舵姗€鈧喎瀹虫禒宥呬焊瀵唻绱濋惄顔界垼閻愮懓婀幍瀣簚鐏忓繐鐫嗛獮鏇氳厬鏉╁洤銇囬敍灞炬▔缁€鐑樻闂€璺ㄥ繁鐏忔垟鈧粎鍋ｅ鈩冨缂佹挻娼垾婵嚹佸蹇ョ幢閹藉洦娼岄幍瀣簜閸楀繗鐨熼棁鈧憰浣规纯閻喎鐤勯惃鍕啚閺夊棗濮為柅鐔粹偓渚€妾锋担搴ゎ嚖鐟欙妇娈戦幒褍鍩楃敮鍐ㄧ湰閿涘奔浜掗崣濠兠仦蹇撳弿鐏炲繗顔勭紒鍐х秼妤犲被鈧?

### 閺傛澘顤?
- 閹靛婧傞崡蹇氱殶濞村鐦弬鏉款杻閳ユ粎鍋ｅ鈩冨濞戝牆銇戦垾婵囨▔缁€鐑樐佸蹇ョ礉閸欘垰婀€瑰本鍨氶棁鈧憰浣哄仯閸戠粯顐奸弫鏉挎倵閸愬秷绻橀崗銉ょ瑓娑撯偓鏉烆喓鈧?
- 閹靛婧傞崡蹇氱殶濞村鐦弬鏉款杻閻╊喗鐖ｉ悙鐟般亣鐏忓繗顔曠純顕嗙礉閸涙垝鑵戦崡濠傜窞闂呭繗顫嬬憴澶屾窗閺嶅洤鎮撳銉ュ綁閸栨牓鈧?
- 閹靛婧傞崡蹇氱殶濞村鐦弬鏉款杻閸忋劌鐫嗙拋顓犵矊閸忋儱褰涢敍灞藉弿鐏炲繋绮庣仦鏇犮仛閼哥偛褰撮妴浣戒氦闁插繑瀵氶弽鍥ф嫲瀵偓婵?闁插秶鐤?闁偓閸戠儤甯堕崚韬测偓?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼弬鏉款杻閹藉洦娼屾担宥囩枂閸旂娀鈧喕顔曠純顕嗙礉閻劋绨拫鍐╂殻鏉炵粯甯规稉搴ㄥ櫢閹恒劎娈戦崫宥呯安閺囪尙鍤庨妴?
- 閹藉洦娼岄幍瀣簜閸楀繗鐨熼弬鏉款杻閸忋劌鐫嗙拋顓犵矊閸忋儱褰涢敍娑櫭仦蹇旀闁插洨鏁ゅ锔挎櫠閹藉洦娼岄妴浣疯厬闂傜鍨堕崣鑸偓浣稿礁娓氀冪殸閸戣绔风仦鈧妴?

### 娣囶喗鏁?
- 闁插秵鏌婇弽鈥冲櫙閹靛婧傞惄顔界垼鏉╂劕濮╁Ο鈥崇€烽敍宀勭彯楠炲懎瀹?妤傛﹢鈧喎瀹抽弮鍓佹窗閺嶅洩娉曠搾濠呭瘱閸ュ瓨娲挎径褋鈧礁濮╅悽璇叉噯閺堢喐娲块惌顓ㄧ礉閺囨挳鈧倸鎮庤箛顐︹偓鐔盒╅崝銊﹀閻厧宕楃拫鍐╃ゴ鐠囨洏鈧?
- 閹靛婧傞惄顔界垼姒涙顓荤亸鍝勵嚟娴犲骸浜告径褏娈?58dp 鐠嬪啯鏆ｆ稉?42dp閿涘苯鑻熼弨顖涘瘮 22-68dp 閼煎啫娲跨拫鍐Ν閵?
- 閹藉洦娼屽ù瀣槸閺咁噣鈧艾绔风仦鈧弨閫涜礋鐏忓嫬鍤幐澶愭尦閻欘剛鐝涢弨鎯с亣閿涘苯绱戞慨?缂佹挻娼?闁插秶鐤嗛弨鎯ф躬濞嗭紕楠囬幒褍鍩楅崠鐚寸礉闁灝鍘ら崪灞界殸閸戣鑻熼崚妤勵嚖鐟欙负鈧?
- 閹靛婧傛稉搴㈡啚閺夊棜鍨堕崣鐗堝▕閸欐牔璐熼崗鍙橀煩鐏炴洜銇氱紒鍕閿涘奔绻氶幐浣规珮闁岸銆夐崪灞藉弿鐏炲繘銆夋径宥囨暏閸氬奔绔撮悩鑸碘偓浣规簚閵?

### 妞嬪酣娅撻崣妯绘纯
- 妤傛ê宸辨惔锕€绠欐惔?闁喎瀹虫导姘▔閽佹褰佹姗€姣︽惔锔肩幢瀹歌弓绻氶悾娆庣秵闁喆鈧椒缍嗛獮鍛閵嗕胶娲伴弽鍥ф槀鐎电鎷伴悙瑙勫姬閹靛秵绉锋径杈佸蹇庣返閻劍鍩涢懛顏囶攽鐠嬪啳濡妴?
- 閸忋劌鐫嗗Ο鈥崇础婢跺秶鏁よぐ鎾冲妞ょ敻娼伴悩鑸碘偓渚婄礉娑撳秹顤傛径鏍у晸閸忋儲瀵旀稊鍛閺佺増宓侀敍娑⑩偓鈧崙鍝勫弿鐏炲繋绗夋导姘箽鐎涙ɑ鍨ㄩ柌宥呯紦閹存劗鍝楅妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/ui_smoke_test.dart --plain-name "hand-eye coordination exposes target settings" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "joystick coordination exposes joystick modes and controls" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_107-HAND-EYE-COORDINATION] - 2026-04-30

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴鐎瑰苯鏉介妴灞戒紣閸忛顔?- 娴滆櫣琚ù瀣槸娑擃厼绺?- 閹靛婧傞崡蹇氱殶濞村鐦妴宥忕窗閻滅増婀佸Ο鈥虫健鏉╁洣绨粻鈧崡鏇礉闂団偓鐟曚焦鏁兼稉娲閺堝搫鍤悳鑸偓浣盒╅崝銊ｂ偓浣圭Х婢惰京娈戦惄顔界垼閿涘苯鑻熼弬鏉款杻缁鎶€閹靛婧€濞撳憡鍨欓幗鍥ㄦ綄閻嫬鍣亸鍕毊閻ㄥ嫮瀚粩瀣摍濡€虫健閵?

### 閺傛澘顤?
- 閺傛澘顤冮幗鍥ㄦ綄閹靛婧傞崡蹇氱殶濞村鐦崗銉ュ經閿涘奔濞囬悽銊ㄦ珓閹风喐鎲為弶鍡櫺╅崝銊ュ櫙閺勭喎鑻熼悙鐟板毊鐏忓嫬鍤妴?
- 閹藉洦娼屽ù瀣槸閺€顖涘瘮閸楁洑缍呴弮鍫曟？濞村鐦崪宀€娲伴弽鍥ㄢ偓缁樻殶濞村鐦稉銈囶潚閺傝顢嶉妴?
- 閹藉洦娼屽ù瀣槸閺傛澘顤冮崙鍡樻Е閸濆秴绨叉担宥囆╅柅鐔哄芳鐠佸墽鐤嗛敍灞间簰閸欏﹤鎳℃稉顓炴倵缁斿宓嗛崚閿嬫煀/闂呭繑婧€瀵ゆ儼绻滈崚閿嬫煀鐠佸墽鐤嗛妴?
- 閺傛澘顤冮幍瀣簜閸楀繗鐨?smoke test閿涘矁顩惄鏍閺堣櫣娲伴弽鍥啎缂冾喓鈧焦鎲為弶鍡樐佸蹇嬧偓浣哥殸閸戠粯瀵滈柦顔兼嫲濡€崇础閸掑洦宕查妴?

### 娣囶喗鏁?
- 閹靛婧傞崡蹇氱殶濞村鐦悽鍗炴祼鐎规艾绶氭潻鏃傛窗閺嶅洦鏁兼稉娲閺堝搫娆㈡潻鐔峰毉閻滆埇鈧線娈㈤張杞扮秴缂冾喚鏁撻幋鎰┾偓浣瑰瘻鐠佸墽鐤嗛弮鍫曟毐韫囶偊鈧喓些閸斻劌鑻熷☉鍫濄亼閻ㄥ嫮娲伴弽鍥モ偓?
- 閹靛婧傞崡蹇氱殶濞村鐦弬鏉款杻閸欘垱濮岄崣鐘侯啎缂冾噯绱版潪顔芥殶閵嗕焦妯夌粈铏剐╅崝銊︽闂€瑁も偓渚€娈㈤張楦跨箥閸斻劌绠欐惔锔衡偓渚€鈧喎瀹抽妴渚€娓剁憰浣哄仯閸戠粯顐奸弫鑸偓?
- 閹靛婧傞崡蹇氱殶缂佺喕顓搁幍鈺佺潔娑撶儤鍨氶崝鐔粹偓浣圭础閹哄鈧胶鍋ｇ粚鎭掆偓浣搁挬閸у洤寮芥惔鏂挎鏉╃喎鎷伴柅鎰枂閺勫海绮忛妴?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃崗銉ュ經閺囧瓨鏌婃稉?18 娑擃亝婀伴崷鎷屽彯閸涜櫕绁寸拠鏇礉楠炴儼藟閸忓懏鎲為弶鍡樺閻厧宕楃拫鍐ㄥ幢閻楀洢鈧?
- 鐏忓棙妞傞梻瀛樺妳閻儱鎷伴幍瀣簜閸楀繗鐨熼惄绋垮彠鐎圭偟骞囬幏鍡楀瀻娑撹櫣瀚粩?part 閺傚洣娆㈤敍灞炬暪閸?`toolbox_human_tests_action.dart` 閺傚洣娆㈡担鎾诲櫤閵?

### 妞嬪酣娅撻崣妯绘纯
- 閹靛婧傞崡蹇氱殶娑撳孩鎲為弶鍡樼ゴ鐠囨洖娼庨崣顏勬躬瑜版挸澧犳い鐢告桨閸楄櫕妞傜仦鏇犮仛缂佹挻鐏夐敍灞肩瑝閸愭瑥鍙?AppState閵嗕椒瀵岄弫鐗堝祦鎼存挻鍨ㄧ€涳缚绡勭拋鏉跨秿閵?
- 閺傛澘顤冮崝銊ф暰娑撳氦顓搁弮璺烘珤閸у洭鈧俺绻?token閵嗕箑imer 閸欐牗绉烽崪?AnimationController 閸嬫粍顒涢弨璺哄經閿涘矂妾锋担搴ㄥ櫢缂?闁偓閸戝搫鎮楅惃鍕閸︽椽顥撻梽鈹库偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_action.dart lib/src/ui/pages/toolbox_human_tests_time_perception.dart lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_action.dart lib/src/ui/pages/toolbox_human_tests_time_perception.dart lib/src/ui/pages/toolbox_human_tests_hand_eye.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_joystick.dart lib/src/ui/pages/toolbox_human_tests_hand_eye_parts.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娌梩est/ui_smoke_test.dart` 娴犲秵婀侀弮銏℃箒 const/final info閿?
- `flutter test test/ui_smoke_test.dart --plain-name "hand-eye coordination exposes target settings" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "joystick coordination exposes joystick modes and controls" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_106-TIME-PERCEPTION-RANDOM-TARGETS] - 2026-04-30

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閵嗗苯浼愰崗椋庮唸 - 娴滆櫣琚ù瀣槸娑擃厼绺?- 閺冨爼妫块幇鐔虹叀濞村鐦妴宥呯摠閸︺劎鍋ｉ崙鑽ゅЦ閹椒绗屾０婊嗗鐞涖劏鎻崣宥呮倻閵嗕焦瀵滈柦顔剧椽閸欑兘鈧姵鍨氬褌绠熼妴浣烘窗閺嶅洦妞傞梻鏉戞祼鐎规熬绱濇禒銉ュ挤缂傚搫鐨張鈧径褎妞傞梻鏉戞嫲閺堚偓鐏忓繐宕熸担宥堫啎缂冾喚娈戦梻顕€顣介妴?

### 閺傛澘顤?
- 閺冨爼妫块幇鐔虹叀濞村鐦弬鏉款杻閺堚偓婢堆呮窗閺嶅洦妞傞梻纾嬵啎缂冾噯绱濋崣顖氭躬瑜版挸澧犻梾蹇旀簚閸楁洑缍呯痪锔芥将娑撳甯堕崚鍓佹窗閺嶅洦妞傞崚鏄忓瘱閸ユ番鈧?
- 閺冨爼妫块幇鐔虹叀濞村鐦弬鏉款杻閺堚偓鐏忓繘娈㈤張鍝勫礋娴ｅ秷顔曠純顕嗙礉閺€顖涘瘮閸掑棝鎸撻妴浣侯潡閵嗕焦顕犵粔鎺戞嫲瀵邦喚顫楅崶娑欍€傞妴?
- 閺傛澘顤冪€规艾鎮?smoke test閿涘矁顩惄鏍ㄦ闂傚瓨鍔呴惌銉︾ゴ鐠囨洝顔曠純顔衡偓渚€娈㈤張铏规窗閺嶅洦瀵滈柦顔衡偓浣规￥缂傛牕褰块幐澶愭尦閸滃瞼鍋ｉ崙璇叉倵閺勫墽銇氱€圭偤妾弮鍫曟？/鐠囶垰妯婇妴?

### 娣囶喗鏁?
- 閺冨爼妫块幇鐔虹叀濞村鐦妯款吇閺€閫涜礋閸楁洜娲伴弽鍥Ν閻愮櫢绱辨潻鐐电敾閼哄倻鍋ｉ崣妯硅礋閻欘剛鐝涘鈧崗绛圭礉瀵偓閸氼垰鎮楅幍宥嗘▔缁€?2-6 娑擃亣绻涚紒顓″Ν閻愯鏆熼柌蹇氼啎缂冾喓鈧?
- 閺冨爼妫块幇鐔虹叀閻╊喗鐖ｉ悽鍗炴祼鐎规氨鐡戝顔芥闂傚瓨鏁兼稉鐑樼槨鏉烆喖绱戞慨瀣閸︺劏瀵栭崶鏉戝敶闂呭繑婧€閻㈢喐鍨氶敍灞借嫙閹稿妞傞梻缈犵矤閺冣晛鍩岄弲姘笓閸掓ぜ鈧?
- 閺冨爼妫块幐澶愭尦娑撳秴鍟€閺勫墽銇?`#1/#2` 缂傛牕褰块敍灞炬暭娑撴椽鈧俺绻冮惄顔界垼閺冨爼妫块崪灞界秼閸撳秹鐝禍顔惧Ц閹浇銆冩潏楣冦€庢惔蹇嬧偓?
- 閻愮懓鍤崥搴℃倱娑撯偓閹稿鎸抽崘鍛潔缁€铏规窗閺嶅洦妞傞梻娣偓浣哥杽闂勫懐鍋ｉ崙缁樻闂傛潙鎷扮拠顖氭▕閿涘苯鍑￠悙鐟板毊閵嗕礁缍嬮崜宥呯窡閻愬箍鈧礁鈧瑩鈧娲伴弽鍥﹀▏閻劋绗夐崥灞芥禈閺嶅洢鈧浇绔熷鍡楁嫲閼规彃娼￠崠鍝勫瀻閵?
- 閹碘晛鐫嶆い鐢告桨鐠囧瓨妲戦敍灞炬绾喒鈧粍瀵滈柦顔荤瑝閺勫墽銇氱紓鏍у娇閵嗕胶鍋ｉ崙璇叉倵閸︺劍瀵滈柦顔煎敶閺勫墽銇氱紒鎾寸亯閵嗕礁宕熸担宥囨暏娴滃酣娈㈤張铏圭煈鎼达腹鈧繄娈戦幙宥勭稊鐠囶厺绠熼妴?

### 妞嬪酣娅撻崣妯绘纯
- 瀵邦喚顫楃划鎺戝閸欘亜濂栭崫宥囨窗閺嶅洨鏁撻幋鎰煈鎼达讣绱濈粔璇插З缁旑垰鐤勯梽鍛仯閸戣绮涢崣妤勵啎婢跺洤鎷扮化鑽ょ埠娴滃娆㈢划鎯у瑜板崬鎼烽敍娑氱波閺嬫粈浜掔€圭偤妾悙鐟板毊閺冨爼妫块崪宀冾嚖瀹割喖鐫嶇粈鐚寸礉闁灝鍘ら幎濠備簳缁夋帗銆傜拠顖澬掓稉鍝勫讲缁嬪啿鐣炬潏鎯у煂閻ㄥ嫪姹夊銉х翱鎼达负鈧?
- 閺堫剝鐤嗘禒鍛叏閺€瑙勬闂傚瓨鍔呴惌銉︾ゴ鐠囨洖鐪柈銊уЦ閹礁鎷扮仦鏇犮仛閿涘奔绗夐幒銉ュ弳閹镐椒绠欓崠鏍モ偓涓刾pState 閹存牕鍙剧€瑰啩姹夌猾缁樼ゴ鐠囨洖鐡欏Ο鈥虫健閵?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_action.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_action.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍娌梩est/ui_smoke_test.dart` 娴犲秵婀侀弮銏℃箒 const/final info閿?
- `flutter test test/ui_smoke_test.dart --plain-name "time perception randomizes targets and shows tap result" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_105-DYNAMIC-VISION-RESET-CONFIRM] - 2026-04-30

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯鐏忓繒鎮嗛弫浼村櫤濡€崇础缁涙柨顕幓鎰仛娴兼碍姣氶棁韫瑓娑撯偓鏉烆噣姣︽惔锕傛閺堣櫣鐡ラ悾銉幢閸斻劍鈧浇顫嬮崝娑滎啎缂冾喖鑴婄粣妤€婀棃鐐茬秼閸撳秷鐤嗗▎陇绻樼悰灞艰厬娑旂喍绱伴崙铏瑰箛閿涘奔绗栫涵顔款吇閸氬氦鍤滈崝銊ョ磻婵顕遍懛瀛樼槨閺€閫涚妞ゅ綊鍏樼悮顐ユ彥闁插秴绱戦敍娑樼摟缁楋箒鐦戦崚顐Ｄ佸蹇曞繁鐏忔垶妲戠涵顔炬畱闁插秶鐤嗗鈧慨瀣瘻闁筋喓鈧?

### 閺傛澘顤?
- 鐎涙顑佺拠鍡楀焼濡€崇础閺傛澘顤冪敮鎼佲敆閵嗗矂鍣哥純顔肩磻婵鈧秵瀵滈柦顕嗙礉娓氬じ绨崷銊︽弓鐎瑰本鍨氶幋鏍х暚閹存劕鎮楅崶鐐插煂閸掓繂顫愮粵澶婄窡瀵偓婵濮搁幀浣碘偓?

### 娣囶喗鏁?
- 閸斻劍鈧浇顫嬮崝娑滎啎缂冾喚鈥樼拋銈勭矌閸︺劌缍嬮崜宥堢枂濞喡ゎ潎鐎电喐鍨ㄧ粵鏃堫暯闂冭埖顔岄崙铏瑰箛閿涙稑宸婚崣鑼剁枂濞喡扳偓浣稿冀妫ｅ牏绮ㄩ弸婊勫灗缁涘绶熸稉瀣╃鏉烆喚濮搁幀浣风瑓娣囶喗鏁肩拋鍓х枂娴兼氨娲块幒銉ョ安閻劌鑻熼柌宥囩枂閿涘奔绗夐崘宥呰剨缁愭ぜ鈧?
- 鐠佸墽鐤嗙涵顔款吇娑撳氦绻樼悰灞艰厬閸掑洦宕插Ο鈥崇础绾喛顓婚崥搴″涧鎼存梻鏁ょ拋鍓х枂楠炲爼鍣哥純顕嗙礉娑撳秴鍟€閼奉亜濮╁鈧慨瀣剁幢瀵偓婵濮╂担婊冾潗缂佸牏鏁遍悽銊﹀煕閻愮懓鍤憴锕€褰傞妴?
- 鐏忓繒鎮嗛弫浼村櫤濡€崇础缁涙柨顕崣宥夘洯閺€閫涜礋缁犫偓閻厾鈥樼拋銈忕礉缁夊娅庨垾婊€绗呮稉鈧潪顔兼躬缁涘楠囬懠鍐ㄦ纯閸愬懘娈㈤張鐑樺▕閸欐牗鏆熼柌蹇撴嫲闁喎瀹抽垾婵堟畱閹绘劗銇氶妴?

### 妞嬪酣娅撻崣妯绘纯
- 閸欐牗绉烽懛顏勫З瀵偓婵鎮楅敍宀€鏁ら幋鐑芥付鐟曚礁顦块悙閫涚濞嗏€崇磻婵绱辩拠銉攽娑撹櫣顑侀崥鍫氣偓婊冪磻婵顫愮紒鍫㈡暠閻劍鍩涢悙鐟板毊閳ユ繄娈戦弬鎷岀珶閻ｅ矉绱濋獮鍫曚缉閸忓秷顔曠純顔跨殶閺佸瓨妞傛潻鐐电敾瀵湱鐛?閼奉亜濮╅柌宥呯磻閵?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_dynamic_vision.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision_ui.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision_parts.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision_ui.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/ui_smoke_test.dart --plain-name "dynamic vision exposes ball count mode and settings" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "dynamic vision supports custom symbols and restart confirm" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_104-DYNAMIC-VISION-RANDOMIZED-SETTINGS] - 2026-04-30

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閸斻劍鈧浇顫嬮崝娑樼摟缁楋箒鐦戦崚顐︽付鐟曚礁顦跨€涙顑?閼奉亜鐣炬稊澶岀矋閸氬牞绱辩亸蹇曟倖閺佷即鍣哄Ο鈥崇础姒涙顓绘径姘冲娴兼岸妾锋担搴ら哺鐠囧棝姣︽惔锔肩礉鐟欏倸鐧傞弮鍫曟？闂団偓鐟曚礁褰叉潏鎾冲弳閿涙稒鏆熼柌蹇庣瑢闁喎瀹崇痪鎸庘偓褍顤冮梹澶哥窗鐠佲晝鐡熷鍫ｇ箖娴滃孩妲戦弰鎾呯幢濞村鐦潻娑滎攽娑擃叀顔曠純顔荤瑝閸欘垱鏁奸棁鈧憰浣风喘閸栨牔璐熺涵顔款吇閸氬氦鍤滈崝銊╁櫢缂冾喖鑻熷鈧慨瀣ㄢ偓?

### 閺傛澘顤?
- 鐎涙顑佺拠鍡楀焼閺傛澘顤冮妴灞界摟缁楋妇绮嶉崥鍫ユ毐鎼达负鈧秷顔曠純顕嗙礉楠炶埖鏁幐浣藉殰鐎规矮绠熺紒鍕値鏉堟挸鍙嗛敍灞惧瘻闁褰块幋鏍﹁厬閺傚洭鈧褰块崚鍡楀閵?
- 鐏忓繒鎮嗛弫浼村櫤閺傛澘顤冮崥宀冨/婢舵俺澹婄拋鍓х枂閿涘矂绮拋銈呮倱閼瑰眰鈧?
- 鐏忓繒鎮嗛弫浼村櫤閺傛澘顤冪憴鍌氱檪閺冨爼鏆辩粔鎺撴殶鏉堟挸鍙嗗鍡礉濠婃垶娼岄懠鍐ㄦ纯閹碘晛鐫嶉崚?0.8-12 缁夋帇鈧?
- 鏉╂稖顢戞稉顓濇叏閺€鐟板З閹浇顫嬮崝娑滎啎缂冾喗妞傞弬鏉款杻绾喛顓诲鍦崶閿涙稓鈥樼拋銈呮倵娴兼艾褰囧☉鍫熸＋鏉烆喗顐奸妴浣哥安閻劏顔曠純顔衡偓渚€鍣哥純顔艰嫙閼奉亜濮╁鈧慨瀣煀娑撯偓鏉烆喓鈧?

### 娣囶喗鏁?
- 鐏忓繒鎮嗛弫浼村櫤娑撳酣鈧喎瀹抽弨閫涜礋閸╄桨绨粵澶岄獓閼煎啫娲块梾蹇旀簚閹惰姤鐗遍敍灞肩瑝閸愬秶娲块幒銉у殠閹冨彆瀵偓娑撳绔存潪顔剧摕濡楀牄鈧?
- 鐏忓繒鎮嗛弫浼村櫤濡€崇础閹稿洦鐖ｉ弨閫涜礋閺勫墽銇氶弫浼村櫤閼煎啫娲块崪宀勨偓鐔峰閼煎啫娲块敍宀勪缉閸忓秶娲块幒銉︽瘹闂囧弶婀版潪顔肩毈閻炲啯鏆熼柌蹇嬧偓?
- 閸斻劍鈧浇顫嬮崝娑樼杽閻滄壆鎴风紒顓熷閸掑棔璐熼柅鏄忕帆閵嗕胶绮崚?閹貉傛閵嗕箒I 閺嬪嫬缂撴稉澶夐嚋 part 閺傚洣娆㈤敍灞肩箽閹镐礁宕熼弬鍥︽娴ｅ簼绨?1000 鐞涘被鈧?

### 妞嬪酣娅撻崣妯绘纯
- 闂呭繑婧€閸栨牠姣︽惔锕€褰查懗浠嬧偓鐘冲灇閸氬瞼鐡戠痪褌缍嬫灞惧皾閸旑煉绱卞鏌ユ鐎规艾婀粵澶岄獓鐎电懓绨查懠鍐ㄦ纯閸愬懘娈㈤張鐚寸礉闁灝鍘ら弮鐘垫櫕鐠哄啿褰夐妴?
- 閼奉亜鐣炬稊澶婄摟缁楋妇绮嶉崥鍫濈毌娴?2 娑擃亝婀侀弫鍫ャ€嶉弮鏈电窗閸ョ偤鈧偓閸掓澘鍞寸純顔剧矋閸氬牏鏁撻幋鎰剁礉闁灝鍘ら柅澶愩€嶆稉宥堝喕閵?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision_parts.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision_ui.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision_parts.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision_ui.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/ui_smoke_test.dart --plain-name "dynamic vision exposes ball count mode and settings" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "dynamic vision supports custom symbols and restart confirm" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_103-DYNAMIC-VISION-BALL-COUNT-SETTINGS] - 2026-04-30

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴娴兼ê瀵查妴灞戒紣閸忛顔?- 娴滆櫣琚ù瀣槸 - 閸斻劍鈧浇顫嬮崝娑欑ゴ鐠囨洏鈧秴鐡欏Ο鈥虫健閿涙碍鏌婃晶鐐插棘閼板啰缍夋い浣冾潐閸掓瑧娈戠亸蹇曟倖閺佷即鍣哄ù瀣槸濡€崇础閿涘苯鑻熸稉鍝勭秼閸撳秵绁寸拠鏇炴嫲閺傜増膩瀵繗藟姒绘劕褰查幎妯哄綌鐠佸墽鐤嗛妴?

### 閺傛澘顤?
- 閸斻劍鈧浇顫嬮崝娑欑ゴ鐠囨洘鏌婃晶鐐偓灞界毈閻炲啯鏆熼柌蹇嬧偓宥喣佸蹇ョ窗閼哥偛褰撮崘鍛存閺堣櫣鏁撻幋鎰╅崝銊ь潾閹剧偛鐨悶鍐跨礉鐟欏倸鐧傜紒鎾存将閸氬酣鈧瀚ㄩ弫浼村櫤閿涙稓鐡熺€电懓鎮楅幓鎰磳缁涘楠囬敍灞界毈閻炲啯鏆熼柌蹇庣瑢闁喎瀹抽梾蹇擃杻闂€鎸庢锤缁惧潡鈧帒顤冮妴?
- 閺傛澘顤冮崝銊︹偓浣筋潒閸旀稒膩瀵繐鍨忛幑銏犲弳閸欙綇绱濋崣顖氭躬閵嗗苯鐡х粭锕佺槕閸掝偁鈧秴鎷伴妴灞界毈閻炲啯鏆熼柌蹇嬧偓宥勭闂傛潙鍨忛幑顫偓?
- 閺傛澘顤冮崝銊︹偓浣筋潒閸?smoke test閿涘矁顩惄鏍€夐棃銏¤閺屾挶鈧礁鐨悶鍐╂殶闁插繑膩瀵繋绗岀拋鍓х枂闂堛垺婢橀崗銉ュ經閵?

### 娣囶喗鏁?
- 閻滅増婀佺€涙顑佺拠鍡楀焼濞村鐦弬鏉款杻閸欘垱濮岄崣鐘侯啎缂冾噯绱板ù瀣槸鏉烆喗顐奸弫鑸偓浣哥唨绾偓缁夎濮╅柅鐔峰閵嗕椒绗傛稉瀣啘閸斻劌绠欐惔锔跨瑢婢х偤鏆遍弴鑼殠閵?
- 鐏忓繒鎮嗛弫浼村櫤濡€崇础閺傛澘顤冮崣顖涘閸欑姾顔曠純顕嗙窗鐠у嘲顫愰弫浼村櫤閵嗕焦娓舵径褎鏆熼柌蹇嬧偓浣哥唨绾偓缁夎濮╅柅鐔峰閵嗕浇顫囩€电喐妞傞梹澶哥瑢婢х偤鏆遍弴鑼殠閵?
- 鐏忓棗濮╅幀浣筋潒閸旀稒绁寸拠鏇熷閸掑棗鍩岄悪顒傜彌 part 閺傚洣娆㈤敍灞借嫙閹跺﹤鐨悶?Painter 娑撳氦顔曠純顔肩毈缂佸嫪娆㈤幏鍡楀弳鏉堝懎濮?part閿涘矂浼╅崗宥堫潒鐟欏绁寸拠鏇熸瀮娴犲墎鎴风紒顓″暙閼斥偓閵?
- 娴滆櫣琚ù瀣槸閸忋儱褰涙稉顓犳畱閸斻劍鈧浇顫嬮崝娑欏伎鏉╃増娲块弬棰佽礋閸欏本膩瀵繗顕㈡稊澶堚偓?

### 妞嬪酣娅撻崣妯绘纯
- 鐏忓繒鎮嗛弫浼村櫤濡€崇础瀵洖鍙嗛幐浣虹敾閸斻劎鏁鹃敍娑樺嚒闂勬劕鍩楅張鈧径褏鎮嗛弫鏉胯嫙娴ｈ法鏁ら崡鏇氶嚋 `CustomPainter` 缂佹ê鍩楅敍宀勪缉閸忓秶鏁撻幋鎰亣闁?Widget閵?
- 閺堫剝鐤嗘稉宥嗗复閸忋儲鍨氱紒鈺傚瘮娑斿懎瀵查敍灞肩瑝娣囶喗鏁兼稉鏄忕熅閻究鈧礁鍙炬禒鏍︽眽缁粯绁寸拠鏇炵摍濡€虫健閹?AppState 閺佺増宓佸Ο鈥崇€烽妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_visual.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision_parts.dart test/ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_visual.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision.dart lib/src/ui/pages/toolbox_human_tests_dynamic_vision_parts.dart test/ui_smoke_test.dart`閿涘牏娲伴弽鍥уЗ閹浇顫嬮崝娑欐瀮娴犲爼鈧俺绻冮敍娌梩est/ui_smoke_test.dart` 娴犲秵婀侀弮銏℃箒 const/final info閿?
- `flutter test test/ui_smoke_test.dart --plain-name "dynamic vision exposes ball count mode and settings" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page opens human test hub" --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_102-ROULETTE-LOW-METAL-SFX] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯娣囧嫮缍忛弬顖濈枂閻╂绁甸幍铏簚閸滃苯鑴婃禒鎾荤叾閺佸牐绻冩禍搴㈡躬閸掑墎鈹栭懙鏂垮閵嗕浇绻冩禍搴㈢閼村棴绱濈敮灞炬箿閺囧瓨甯存潻鎴滅秵濞屽鍣剧仦鐐存噰閹匡缚绗岄崪鏂挎婢硅埇鈧?

### 娣囶喗鏁?
- 闁插秵鏌婇悽鐔稿灇 `assets/toolbox/games/roulette/revolver_click.wav`閿涙矮绮犻惌顓濈妇濞撳懓鍓㈤悙鐟板毊閺€閫涜礋 240ms 娴ｅ酣顣堕柌鎴濈潣閸欏本顔岄崪鏂挎閿涘苯濮為崗銉х叚閹解晜鎽濈亸楣冪叾閵?
- 闁插秵鏌婇悽鐔稿灇 `assets/toolbox/games/roulette/cylinder_spin.wav`閿涙碍鏁兼稉?980ms 娴ｅ孩鐭囬柌鎴濈潣閹锋牗鎽濋妴浣诡棟鏉烆喖鍨庡▓闈涙嫲閽€鎴掔秴婢硅埇鈧?
- 鐠嬪啩缍嗘潪顔炬磸鐠у奔鑵戦崙鍡楊槵閵嗕礁鍤崣鎴欌偓浣衡敄閼舵稐绗屽閫涚波閺冨娴嗛幘顓熸杹闁喓宸奸敍宀勪缉閸忓秵鎸遍弨鎯у棘閺佺増濡搁柌鎴濈潣闂婂疇澹婇幎顒€绶辨潻鍥﹀瘨閵?

### 妞嬪酣娅撻崣妯绘纯
- 閺備即鐓堕弫鍫熸纯娴ｅ孩鐭囬敍灞惧閺堝搫顦婚弨鍙ョ瑐娴ｅ酣顣舵担鎾村妳娴兼艾鎬ユ禍搴も偓铏簚閿涙稑鍑℃穱婵堟殌娑擃厺缍嗘０鎴﹀櫨鐏炵偞纭鹃棅鍏呬簰婢х偛宸遍崣顖濈槕閸掝偄瀹抽妴?
- 閺堫剝鐤嗘稉宥勬叏閺€鍦负濞夋洟鈧槒绶妴浣告嚒娑擃厼鍨界€规哎鈧浇顫嬬憴澶岀波閺嬪嫨鈧浇鐭鹃悽杈ㄥ灗閹镐椒绠欓崠鏍モ偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_mini_games_roulette.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_mini_games.dart test/toolbox_mini_games_roulette_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/toolbox_mini_games_roulette_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page shows aggregated local tools" --reporter compact`閿涘牓鈧俺绻冮敍? test閿?
- 闂婃娊顣跺Λ鈧弻銉窗`revolver_click.wav` 240ms / 44.1kHz / peak 0.455閿涙矖cylinder_spin.wav` 980ms / 44.1kHz / peak 0.315閵?

## [Unreleased-PLAN_101-ROULETTE-REVOLVER-VISUAL-REFINE] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴娣囧嫮缍忛弬顖濈枂閻╂绁甸懜鐐插酱娑擃厾娈戝锕佺枂閹靛鐏欓弴瀛樺复鏉╂垹婀＄€圭偛涔忔潪顕€鈧姴鐎烽敍灞芥倱閺冩儼鍎楅弲顖欑瑝鐟曚浇绻冩鎴欌偓?

### 娣囶喗鏁?
- 鐠嬪啩瀵掓穱鍕稄閺傤垵鐤嗛惄妯跨サ娑撴槒鍨堕崣鎷屽剹閺咁垽绱濇禒搴ょ箮姒涙垶鐨奸崶瀛樻暭娑撶儤娈╅悘鑸偓渚€鍣剧仦鐐插酱闂堛垹鎷伴弻鏂挎嫲閻戠喖娴樼仦鍌︾礉閹绘劕宕屾＃鏍х潌閸欘垵顕伴幀褋鈧?
- 闁插秶绮锕佺枂缂佸棜濡敍姘乘夐崗鍛仚缁犫€茬瑐閼插鈧礁鍣弰鐔粹偓渚€鈧偓婢硅櫕娼岄妴浣圭仚閸欙絽鐪板▎掳鈧椒鏅堕弶鑳仾娑撴縿鈧礁鑴婂銏犲毈濡插鈧礁鍤柨銈冣偓浣瑰綑閹跺﹥婀痪鐟版嫲闂冨弶绮︾痪骞库偓?
- 娣囨繃瀵斿閫涚波閻樿埖鈧降鈧礁鎳℃稉顓炲灲鐎规哎鈧線鐓堕弫鍫涒偓浣叫曠憴澶婃嫲鐠侯垳鏁遍柅鏄忕帆娑撳秴褰夐敍灞肩矌鐠嬪啯鏆ｇ仦鏇犮仛鐏?Painter 娑撳氦鍨堕崣浼村帳閼瑰眰鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_mini_games_roulette_view.dart lib/src/ui/pages/toolbox_mini_games_roulette_painters.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_mini_games.dart test/toolbox_mini_games_roulette_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/toolbox_mini_games_roulette_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page shows aggregated local tools" --reporter compact`閿涘牓鈧俺绻冮敍? test閿?

## [Unreleased-PLAN_100-ROULETTE-TEXT-SFX-THREAD-FIX] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閵嗗苯浼愰崗椋庮唸 - 濞撳憡鍨欐稉顓炵妇 - 娣囧嫮缍忛弬顖濈枂閻╂绁甸妴宥勭矝鐎涙ê婀稉顓熸瀮娑旇京鐖滈妴浣瑰珯閻喎鎸冮崫?閸滄柨鎸冩竟浼寸叾瀵倸鐖堕妴浣告嚒娑擃厼鍙忕仦蹇氼攨閼规煡妫悜浣风瑢闂囧洤濮╅弫鍫熺亯娑撳秷鍐婚敍灞间簰閸?Android `audioplayers` 娴滃娆㈤柅姘朵壕閸欘垵鍏樻禒搴ㄦ姜楠炲啿褰寸痪璺ㄢ柤閸欐垿鈧焦绉烽幁顖滄畱妞嬪酣娅撻妴?

### 娣囶喗鏁?
- 娣囧嫮缍忛弬顖濈枂閻╂绁甸崨鎴掕厬閸欏秹顩晶鐐插繁娑撴椽銆夐棃銏㈤獓闂囧洤濮?+ root overlay 鐞涒偓閼规煡妫悜渚婄礉娣囨繄鏆€閻厽妞傜悰鏉垮櫤閿涘矂浼╅崗宥嗗瘮缂侇參鐝０鎴︽／閵?
- 鏉烆喚娲忕挧灞藉櫙婢?闁插秶鐤?閸忔娊妫撮棅铏櫏閺冩湹绱伴崑婊勵剾濞堝鏆€閺佸牊鐏夐棅绛圭礉闂勫秳缍嗛悥鍡欏仮婢硅埇鈧焦妫嗘潪顒€锛愰幋鏍ф寖閸濇帒锛愭稉鎻掓簚濮掑倻宸奸妴?
- 鏉烆喚娲忕挧宀勩€夐棃銏ｎ嚛閺勫孩鏋冨鍫熸纯閺傞璐熼幏鐔烘埂閸滄柨鎼?閸滄柨鎸冮張鐑橆潾婢硅埇鈧浇顢呴懝鏌ユ／閻戜降鈧線娓块崝銊ユ嫲閻栧棛鍋㈤棅铏櫏鐠囶厺绠熼妴?
- 鐏忓棜鐤嗛惄妯跨サ娑撹崵濮搁幀浣碘偓浣哥潔缁€鐑樼€鍝勬嫲 Painter 缂佹ê鍩楅幏鍡楀瀻娑?3 娑?part 閺傚洣娆㈤敍灞炬暪閸欙絽宕熼弬鍥︽鐡掑懓绻?1000 鐞涘瞼娈戦梻顕€顣介妴?
- 閺堫剙婀?`audioplayers_android` 鐟曞棛娲婇崠鍛畱 `EventHandler` 閺勫海鈥樻穱婵婄槈 `EventSink` 閸ョ偠鐨熼崷?Android 娑撹崵鍤庣粙瀣⒔鐞涘被鈧?

### 娣囶喖顦?
- 娣囶喖顦叉潪顔炬磸鐠у本甯堕崚璺哄隘閵嗕焦瀵氶弽鍥у隘閸滃矂鐓堕弫鍫ユ晩鐠囶垱褰佺粈杞拌厬閻ㄥ嫪鑵戦弬?`??` / `????` 娑旇京鐖滈妴?
- 閺傛澘顤冩稉顓熸瀮 smoke test閿涘矁顩惄鏍モ偓灞炬鏉烆剙鑴婃禒鎾扁偓宥冣偓灞惧⒏閸斻劍澹嬮張鎭掆偓宥冣偓宀冨灦閸欑増甯堕崚韬测偓宥囩搼閺嶇绺炬稉顓熸瀮閺傚洦顢嶉獮鑸靛閹?`??` 閸ョ偛缍婇妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘稉宥勬叏閺€鐟拌剨娴犳捇娈㈤張鎭掆偓浣告嚒娑擃厼鍨介弬顓溾偓浣哥摍瀵鏆熺憴鍕灟閵嗕浇鐭鹃悽鍗炴嫲閹镐椒绠欓崠鏍偓鏄忕帆閵?
- 閸嬫粍顒涘▓瀣殌闂婅櫕鏅ラ崣顏勫絺閻㈢喎婀柌宥囩枂閵嗕焦鏌婃稉鈧潪顔芥鏉烆剙鎷伴崗鎶芥４闂婅櫕鏅ョ粵澶嬫绾喛绔熼悾灞藉З娴ｆ嚎鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_mini_games.dart lib/src/ui/pages/toolbox_mini_games_roulette.dart test/toolbox_mini_games_roulette_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_mini_games.dart test/toolbox_mini_games_roulette_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/toolbox_mini_games_roulette_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page shows aggregated local tools" --reporter compact`閿涘牓鈧俺绻冮敍? test閿?

## [Unreleased-PLAN_099-ROULETTE-CINEMATIC-REDESIGN] - 2026-04-29

### Why
- The user requested a full redesign of Toolbox > Game Center > Russian Roulette with realistic animation and stronger staged feedback: prep clack, firing-pin snap, hit explosion, full-screen flash, and vibration.

### Added
- Added new explosion SFX asset: `assets/toolbox/games/roulette/explosion_blast.wav`.
- Added root-overlay full-screen flash effect for hit moments.
- Added roulette SFX warm-up chain for spin, click, shot, and explosion with best-effort fallback.

### Changed
- Rewrote `toolbox_mini_games_roulette.dart` end-to-end with a new state flow, new stage composition, new drawing layer, and new control console.
- Re-sequenced firing flow to: prep clack -> cylinder spin -> firing-pin snap -> empty step or hit blast.
- Added recoil, shake, muzzle flash, smoke, and multi-stage haptic feedback.
- Added sound and haptics toggles in the control panel.
- Updated `toolbox_mini_games.dart` import to use `ToolboxAudioService` classes.
- UX round-2: moved primary trigger actions directly under the stage and removed the extra gap between stage visuals and action buttons on mobile.
- UX round-2: converted load/toggle options into a collapsible settings section so direct play actions stay on the same screen as the revolver animation.
- Audio round-2: upgraded click handling to a layered mechanical double-clack with timing and pitch/volume jitter for a more realistic metal "clack-clack".

### Risk
- Stronger hit feedback may be overstimulating for some users; this is mitigated by short single-pulse flash and user toggles.
- Audio playback remains best-effort and will not block gameplay when loading fails.

### Validation
- `dart format lib/src/ui/pages/toolbox_mini_games.dart lib/src/ui/pages/toolbox_mini_games_roulette.dart` (passed)
- `dart analyze lib/src/ui/pages/toolbox_mini_games.dart test/toolbox_mini_games_roulette_smoke_test.dart` (passed, No issues found)
- `flutter test test/toolbox_mini_games_roulette_smoke_test.dart --reporter compact` (passed, 1 test)
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page shows aggregated local tools" --reporter compact` (passed, 1 test)

## [Unreleased-PLAN_098-HUMAN-TESTS-CHIMP-LUCK-SETTINGS-FOLD] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涙潻钘夊娴滆櫣琚ù瀣槸缂佸棗瀵查棁鈧Ч鍌︾窗姒涙垹灏掗悮鈺咁杹閼规煡銆庢惔蹇斈佸蹇旀暭娑撴椽鈧劖顒炵仦鏇犮仛楠炶埖瀵滈惄顔界垼妫版粏澹婇悙鐟板毊閿涙稑鍙忛柈銊ョ摍濡€虫健鐠佸墽鐤嗘い纭咁洣閺€顖涘瘮閹舵ê褰旂仦鏇炵磻閿涙稖绻嶅鏃€绁寸拠鏇㈡付鐟曚胶婀＄€?5 閸椻剝鐗卞蹇嬧偓浣虹倳閻楀苯濮╅悽璁崇瑢缂堣鎮楅懛顏勫З濞叉澧濋妴?

### 閺傛澘顤?
- 閺傛澘顤?`_HumanSettingsSection` 婢跺秶鏁ょ紒鍕閿涘本鏁幐浣筋啎缂冾喖灏紒鐔剁閹舵ê褰?鐏炴洖绱戦妴?
- 鏉╂劖鐨靛ù瀣槸閺傛澘顤?5 瀵姴宕遍悧宀€鐐曟潪顒€濮╅悽缁樼ウ缁嬪绱伴悙鐟板毊缂堣崵澧濋妴浣稿幢闂堛垹鐫嶇粈铏圭波閺嬫嚎鈧胶鐓弳鍌氫粻閻ｆ瑥鎮楅懛顏勫З濞叉澧濇径宥勭秴閵?

### 娣囶喗鏁?
- 姒涙垹灏掗悮鈺咁杹閼规煡銆庢惔蹇斈佸蹇旀暭娑撹　鈧粈绶峰▎鈩冩▔缁€娲杹閼?娴ｅ秶鐤嗛敍鍧?/x2/閳ワ讣绱氶垾婵撶礉楠炶埖鏌婃晶鐐垫窗閺嶅洭顤侀懝鍙夋簚閸掕绱濇禒鍛瘻鐠囥儵顤侀懝鎻掓躬鎼村繐鍨稉顓犳畱娴ｅ秶鐤嗘い鍝勭碍閻愮懓鍤妴?
- 姒涙垹灏掗悮鈺咁杹閼规煡銆庢惔蹇斈佸蹇旂槨鏉烆喕绻氱拠浣烘窗閺嶅洭顤侀懝鑼跺殾鐏忔垵鍤悳?2 濞嗏槄绱濋柆鍨帳闁偓閸栨牔璐熼崡鏇犲仯閻愮懓鍤妴?
- 姒涙垹灏掗悮鈺咁杹閼规煡銆庢惔蹇斈佸蹇旀煀婢х偐鈧粓顤侀懝鍙夋殶闁插繆鈧繂褰茬拫鍐跨礉閻╊喗鐖ｆ０婊嗗閻㈣鲸婀版潪顔肩碍閸掓鍤滈崝銊﹀瘹鐎规哎鈧?
- 閺佹澘鐡х拋鏉跨箓閵嗕線绮﹂悮鈺冨皰閵嗕焦鏌夐悧褰掔灳閺咁喓鈧焦妞傞梻瀛樺妳閻儯鈧浇绻嶅鏃€绁寸拠鏇犳畱鐠佸墽鐤嗘い鍦埠娑撯偓鏉╀胶些閸掓澘褰查幎妯哄綌鐠佸墽鐤嗛棃銏℃緲閵?
- 閺傤垳澹掓ご浣规珮濞村鐦０婊嗗濮圭姵澧跨仦鏇炶嫙閺€顖涘瘮 3-12 閸斻劍鈧浇鐨熼懞鍌樷偓?
- 鏉╂劖鐨靛ù瀣槸閺傚洦顢嶉弴瀛樻煀娑?5 閸椻剝濞婇崣鏍︾瑢濮掑倻宸奸柊宥囩枂鐠囶厺绠熼妴?

### 妞嬪酣娅撻崣妯绘纯
- 姒涙垹灏掗悮鈺€绗屾潻鎰毜濞村鐦柈钘夌穿閸忋儱绱撳銉ュЗ閻㈠妯佸▓纰夌礉瀹告煡鈧俺绻?token/busy 閻樿埖鈧線鏀ｉ梼鍙夘剾娑撴彃婧€閸滃矂鍣告径宥囧仯閸戞眹鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests_shared.dart lib/src/ui/pages/toolbox_human_tests_memory.dart lib/src/ui/pages/toolbox_human_tests_cognition.dart lib/src/ui/pages/toolbox_human_tests_action.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests_shared.dart lib/src/ui/pages/toolbox_human_tests_memory.dart lib/src/ui/pages/toolbox_human_tests_cognition.dart lib/src/ui/pages/toolbox_human_tests_action.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page opens human test hub" --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page shows aggregated local tools" --reporter compact`閿涘牓鈧俺绻冮敍?
## [Unreleased-PLAN_097-HUMAN-TESTS-ROUND2] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴鐎电懓浼愰崗椋庮唸閵嗗奔姹夌猾缁樼ゴ鐠囨洏鈧秵膩閸ф绻樼悰灞肩癌閺堢喎顤冨鐚寸礉闁插秶鍋ｇ憰鍡欐磰閸欏秴绨插ù瀣槸閵嗕焦鏆熺€涙顔囪箛鍡愨偓渚€绮﹂悮鈺冨皰濞村鐦妴浣筋潒鐟欏顔囪箛鍡愨偓浣规焿閻楀綊鐬鹃弲顔衡偓浣界箥濮樻梹绁寸拠鏇炴嫲閺冨爼妫块幇鐔虹叀濞村鐦敍灞借嫙閺勫海鈥橀張顒冪枂鐠哄疇绻冮惉鍕櫙濞村鐦幍鈺佺潔閵?

### 閺傛澘顤?
- 閸欏秴绨插ù瀣槸閺€閫涜礋閵嗗本瀵滄稉瀣磻婵鐡戝鍛偓浣规緱閹靛绮ㄧ粻妞尖偓宥勬唉娴滄帪绱濋獮鑸垫煀婢?5 濞嗏€抽挬閸у洦鍨氱紒鈺侇嚠鎼存梻娈戦崠娲？鐡掑懓绉洪惂鎯у瀻濮ｆ柨寮芥＃鍫涒偓?
- 閺佹澘鐡х拋鏉跨箓閺傛澘顤冮梾鎯у濡楋絼缍呴敍鍫濆灥缁?娑擃厾楠?妤傛楠?閼奉亜鐣炬稊澶涚礆閵嗕浇鍤滅€规矮绠熼崚婵嗩潗娴ｅ秵鏆熼崪灞炬殶鐎涙浠犻悾娆愭闂€鍧楀帳缂冾喓鈧?
- 姒涙垹灏掗悮鈺傜ゴ鐠囨洖婀紒蹇撳悁濡€崇础婢舵牗鏌婃晶鐐偓宀勩€庢惔蹇旀殶鐎涙膩瀵繈鈧秳绗岄妴宀勵杹閼规煡銆庢惔蹇斈佸蹇嬧偓宥忕礉閺€顖涘瘮閺佹澘鐡?妫版粏澹婇崚鍥ㄥ床闁喎瀹虫稉搴杹閼硅尙娲伴弽鍥ㄦ殶闁插繗鐨熼懞鍌樷偓?
- 鏉╂劖鐨靛ù瀣槸閸楀洨楠囨稉?5 瀵姴宕遍悧灞惧▕閸欐牗膩閸ㄥ绱濋獮鑸垫煀婢х偘绗夐崥灞芥惂鐠愩劌宕遍悧灞绢洤閻滃洨娈戦崣顖濐潒閸栨牞鍤滅€规矮绠熷鎴炴綄閵?
- 閺冨爼妫块幇鐔虹叀濞村鐦弬鏉款杻鏉╃偟鐢绘径姘闂傜濡悙瑙勀佸蹇ョ礉閺€顖涘瘮閸︺劌顦挎稉顏嗘窗閺嶅洦妞傞崚缁樺瘻妞ゅ搫绨悙鐟板毊鐎电懓绨查弫鏉跨摟楠炴儼绶崙楦垮Ν閻愮顕ゅ顔衡偓?

### 娣囶喗鏁?
- 鐟欏棜顫庣拋鏉跨箓閸欏倽鈧啰缍夋い浣冨Ν婵傚繘鍣搁弸鍕剁窗濮ｅ繐鍙ч崗浣筋啅鐠囶垳鍋?3 濞嗏槄绱濈搾鍛存閸掓瑩鍣稿鈧ぐ鎾冲閸忓啿鑻熼幍锝夋珟閻㈢喎鎳￠妴?
- 閺傤垳澹掓ご浣规珮濞村鐦弨顖涘瘮妫版粏澹婇弫浼村櫤 3-12 閸斻劍鈧礁褰茬拫鍐跨礉楠炴儼浠堥崝銊╊暯闂堛垺濞婇弽閿嬬潨閵?
- 娴滆櫣琚ù瀣槸娑擃厼绺鹃敍鍦歶b閿涘娴夐崗铏蒋閻╊喗鏋冨鍫濇倱濮濄儲娲块弬甯礉閺勫海鈥橀弬鏉款杻閻溾晜纭舵稉搴ゎ啎缂冾喛鍏橀崝娑栤偓?
- `modules/toolbox/README.md` 閸氬本顒為弴瀛樻煀娴滆櫣琚ù瀣槸瑜版挸澧犻懗钘夊娑撳骸宸婚崣鑼额唶瑜版洏鈧?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒宥勭箽閹镐降鈧奔绮庨張顒€婀撮崡铏缂佹挻鐏夌仦鏇犮仛閵嗗秷绔熼悾宀嬬礉娑撳秴鍟撻崗?AppState閵嗕椒瀵岄弫鐗堝祦鎼存挻鍨ㄧ€涳缚绡勭拋鏉跨秿閵?
- 姒涙垹灏掗悮鈺呫€庢惔?妫版粏澹婂Ο鈥崇础瀵洖鍙嗗鍌涱劄閹绢厽鏂侀悩鑸碘偓浣规簚閿涙稑鍑￠柅姘崇箖 token 閺€璺哄經闁灝鍘ら柌宥咁槻鐟欙箑褰傜€佃壈鍤ч惃鍕閸︽亽鈧?
- 鏉╂劖鐨靛ù瀣槸濮掑倻宸奸懛顏勭暰娑斿鍘戠拋绋垮礋濡楋絾娼堥柌宥勮礋 0閿涙稑缍嬮弶鍐櫢閹鎷版稉?0 閺冩湹绱伴崶鐐衡偓鈧崚浼寸帛鐠併倕褰查幎钘夊絿濡楋絼缍呴敍宀勪缉閸忓秴绌垮┃鍐︹偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_action.dart lib/src/ui/pages/toolbox_human_tests_memory.dart lib/src/ui/pages/toolbox_human_tests_cognition.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart lib/src/ui/pages/toolbox_human_tests_action.dart lib/src/ui/pages/toolbox_human_tests_memory.dart lib/src/ui/pages/toolbox_human_tests_cognition.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page opens human test hub" --reporter compact`閿涘牓鈧俺绻冮敍? test閿?
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page shows aggregated local tools" --reporter compact`閿涘牓鈧俺绻冮敍? test閿?

## [Unreleased-PLAN_096-HUMAN-TESTS-HUB] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿閸︺劌浼愰崗椋庮唸濡€虫健閺傛澘顤冮垾婊€姹夌猾缁樼ゴ鐠囨洍鈧繄琚崹瀣剁礉閸欏倽鈧?`https://aring.cc/human-benchmark/dashboard/` 娑擃厾娈戠搾锝呮嚄濞村鐦弶锛勬窗閿涘本濡搁崣宥呯安閵嗕浇顔囪箛鍡愨偓浣筋潒鐟欏鈧焦澧滈惇鐓庡礂鐠嬪啨鈧浇顓哥粻妤€鎷板▔銊﹀壈閸旀稓琚ù瀣槸缁夌粯顦查崚鏉跨秼閸撳秹銆嶉惄顔衡偓?

### 閺傛澘顤?
- 瀹搞儱鍙跨粻杈ㄦ煀婢х偟瀚粩?`toolbox.human_tests` 濡€虫健 ID閵嗕焦膩閸ф鏁為崘灞烩偓浣鼓侀崸妤冾吀閻炲棙鏋冨鍫濇嫲閸忋儱褰涢崡锛勫閵?
- 閺傛澘顤?`HumanTestsToolPage` 娴滆櫣琚ù瀣槸娑擃厼绺鹃敍宀€些閸斻劎顏导妯哄帥鐏炴洜銇?17 娑擃亝绁寸拠鏇炲弳閸欙綇绱伴崣宥呯安濞村鐦妴浣规殶鐎涙顔囪箛鍡愨偓渚€绮﹂悮鈺冨皰濞村鐦妴浣瑰ⅵ鐎涙绁寸拠鏇樷偓浣筋潒鐟欏顔囪箛鍡愨偓浣虹€崙鍡樼ゴ鐠囨洏鈧浇澹婄憴澶嬬ゴ鐠囨洏鈧焦鏌夐悧褰掔灳閺咁喓鈧浇鐦濆Ч鍥唶韫囧棎鈧礁绨崚妤勵唶韫囧棎鈧浇绻嶅鏃€绁寸拠鏇樷偓浣瑰闁喐绁寸拠鏇樷偓浣规闂傚瓨鍔呴惌銉︾ゴ鐠囨洏鈧焦澧滈惇鐓庡礂鐠嬪啯绁寸拠鏇樷偓浣筋吀缁犳鍏橀崝娑欑ゴ鐠囨洏鈧礁濮╅幀浣筋潒閸旀稒绁寸拠鏇樷偓浣瑰瘮缂侇厽鏁為幇蹇撳濞村鐦妴?
- 閺傛澘顤冮張顒€婀?Flutter 娴溿倓绨扮€圭偟骞囬敍灞惧瘻閸斻劋缍?鐠佲剝妞傞妴浣筋唶韫囧棎鈧浇顫嬬憴澶堚偓浣筋吇閻儲鏁為幇蹇撳閸滃苯鍙℃禍?UI 閹峰棗鍨庨弬鍥︽閿涘矂浼╅崗宥呭礋妞ょ數鎴风紒顓″暙閼斥偓閵?
- 閺傛澘顤冨銉ュ徔缁?smoke 濞村鐦敍宀冾洬閻╂牕浼愰崗椋庮唸閸忋儱褰涢崚妤勩€冪仦鏇犮仛閳ユ窏uman test hub閳ユ繀浜掗崣濠呯箻閸忋儰姹夌猾缁樼ゴ鐠囨洑鑵戣箛鍐ㄦ倵閻ㄥ嫭鐗宠箛鍐╂蒋閻╊喗瑕嗛弻鎾扁偓?

### 娣囶喗鏁?
- `PROJECT_DOMAIN.md` 閸?`modules/toolbox/README.md` 鐞涖儱鍘栨禍铏硅濞村鐦Ο鈥虫健閼煎啫娲块妴浣规瀮娴犳儼绔熼悾灞烩偓浣稿祮閺冨墎绮ㄩ弸婊嗙珶閻ｅ苯鎷伴崥搴ｇ敾閹碘晛鐫嶇捄顖滃殠閵?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒鍛棘閼板啰缍夋い鍨ゴ鐠囨洘娼惄顔衡偓浣哄负濞夋洝顫夐崚娆忔嫲娣団剝浼呯紒鎾寸€敍灞肩瑝婢跺秴鍩楁径鏍彲濠ф劗鐖滈幋鏍ㄧ壉瀵繐鐤勯悳鑸偓?
- 娴滆櫣琚ù瀣槸缂佹挻鐏夋禒鍛躬瑜版挸澧犳い鐢告桨閸楄櫕妞傜仦鏇犮仛閿涘奔绗夋穱婵嗙摠閸?AppState閵嗕椒瀵岄弫鐗堝祦鎼存挶鈧礁顒熸稊鐘侯唶瑜版洘鍨ㄩ崢鍡楀蕉缂佺喕顓搁妴?
- 濞村鐦紒鎾寸亯閸欘亪鈧倸鎮庢担婊€璐熺搾锝呮嚄閸欏秹顩敍灞肩瑝閼虫垝缍旀稉鍝勫鞍鐎涳负鈧礁绺鹃悶鍡愨偓浣戒捍娑撴俺鍏橀崝娑欏灗閺佹瑨鍋涚拠鍕幆娓氭繃宓侀妴?

### 妤犲矁鐦?
- `dart format lib\src\core\module_system\module_id.dart lib\src\core\module_system\module_registry.dart lib\src\ui\module\module_access.dart lib\src\ui\pages\toolbox\toolbox_page_content.dart lib\src\ui\pages\toolbox_human_tests.dart lib\src\ui\pages\toolbox_human_tests_shared.dart lib\src\ui\pages\toolbox_human_tests_action.dart lib\src\ui\pages\toolbox_human_tests_memory.dart lib\src\ui\pages\toolbox_human_tests_visual.dart lib\src\ui\pages\toolbox_human_tests_cognition.dart test\ui_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_human_tests.dart lib\src\ui\pages\toolbox\toolbox_page_content.dart lib\src\core\module_system\module_id.dart lib\src\core\module_system\module_registry.dart lib\src\ui\module\module_access.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test\ui_smoke_test.dart --plain-name "toolbox page opens human test hub" --reporter compact`閿涘牓鈧俺绻冮敍? test閿?
- `flutter test test\ui_smoke_test.dart --plain-name "toolbox page shows aggregated local tools" --reporter compact`閿涘牓鈧俺绻冮敍? test閿?
- `git diff --check`閿涘牓鈧俺绻冮敍灞肩矌閹绘劗銇氳ぐ鎾冲瀹搞儰缍旈弽鎴滆厬閺冦垺婀侀弬鍥︽娑撳顐肩悮?Git 鐟欙妇顫弮?LF 鐏忓棙瀵滈柊宥囩枂閺囨寧宕叉稉?CRLF閿?

## [Unreleased-PLAN_095-ROULETTE-SINGLE-SPIN-AUDIO-CHANNEL-FIX] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯娣囧嫮缍忛弬顖濈枂閻╂绁甸惃鍕剨娴犳挸褰ч棁鈧憰浣告躬瀵偓鐏炩偓閺冭埖妫嗘潪顑跨濞嗏槄绱濋崥搴ｇ敾閹碉絽濮╅幍铏簚娑撳秴绨查柌宥咁槻閺冨娴嗗閫涚波閵?
- Android 鏉╂劘顢戦弮璺哄毉閻?`roulette_spin`閵嗕梗roulette_click`閵嗕梗roulette_shot` 娑撳閲?`audioplayers` 娴滃娆㈤柅姘朵壕娴犲酣娼獮鍐插酱缁捐法鈻奸崣鎴︹偓浣圭Х閹垳娈戠拃锕€鎲￠妴?

### 娣囶喗鏁?
- 娣囧嫮缍忛弬顖濈枂閻╂绁电粔濠氭珟濮ｅ繑顐肩粚楦垮晽閸氬海娈戝閫涚波閺冨娴嗛崝銊ф暰閿涘苯鎮楃紒顓熷⒏閸斻劍澹嬮張杞扮矌閹恒劏绻樿ぐ鎾冲閼舵稐缍呮妯瑰瘨楠炴湹绻氶悾娆戔敄閼舵稒婧€濮婄増濮堥崝銊ュ冀妫ｅ牄鈧?
- 瀵€涚波鐟欏棜顫庨弮瀣祮閸欘亙绻氶悾娆忔躬閵嗗本妫嗘潪顒€鑴婃禒鎾扁偓宥呭櫙婢跺洤绱戠仦鈧梼鑸殿唽閵?
- 娣囧嫮缍忛弬顖濈枂閻╂绁电粔濠氭珟娑撳閲滈悪顒傜彌 `AudioPlayer` 鐎圭偘绶ラ敍灞肩瑝閸愬秴鍨卞?`roulette_spin/click/shot` 娴滃娆㈤柅姘朵壕閿涙稓鐓崣宥夘洯闂婅櫕鏁奸悽?Flutter `SystemSound`閿涘矁袝閹扮喎寮芥＃鍫滅箽閹镐椒绗夐崣妯糕偓?
- 鐠嬪啯鏆ｇ粚楦垮晽鐠囧瓨妲戦弬鍥攳閿涘奔绮犻垾婊冭剨娴犳挸澧犳潻娑掆偓婵囨暭娑撹　鈧粍婧€濮婃媽鎯ゆ担宥呭煂娑撳绔撮懚娑掆偓婵撶礉闁灝鍘ょ拠顖氼嚤娑撴椽鍣告径宥嗘鏉烆剙鑴婃禒鎾扁偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘稉宥勬叏閺€?`_buildSequence`閵嗕礁鐡欏瑙勬殶閵嗕礁鎳℃稉顓炲灲閺傤厼鎷伴幍锝呭З濞翠胶鈻肩拠顓濈疅閿涘苯褰ч弨鑸垫殐閸斻劍鏅ラ崪宀勭叾妫版垵鐤勯悳鐗堟煙瀵繈鈧?
- 娣囧嫮缍忛弬顖濈枂閻╂绁垫稉宥呭晙閹绢厽鏂佹稉澶嬵唽閼奉亜鐣炬稊?wav 鐠у嫪楠囬棅铏櫏閿涘苯鎮楃紒顓″闂団偓鐟曚焦浠径宥堝殰鐎规矮绠熼棅瀹犲閿涘苯缂撶拋顔炬暏閺冪姳绨ㄦ禒鍫曗偓姘朵壕閻ㄥ嫬甯悽鐔虹叚闂婅櫕鏅ョ€圭偟骞囬妴?

### 妤犲矁鐦?
- `dart format lib\src\ui\pages\toolbox_mini_games.dart lib\src\ui\pages\toolbox_mini_games_roulette.dart test\toolbox_mini_games_roulette_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_mini_games.dart test\toolbox_mini_games_roulette_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test\toolbox_mini_games_roulette_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? test閿?
- `flutter test test\ui_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?6 tests閿?

## [Unreleased-PLAN_092-RANDOM-ASSISTANT-REALISTIC-DICE] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿闁插秵鏌婄拋鎹愵吀閵嗗苯浼愰崗椋庮唸 - 濮ｅ繑妫╅崘宕囩摜 - 闂呭繑婧€閸斺晜澧滈妴宥勮厬閻ㄥ嫰顎忕€涙劖鐗卞蹇撴嫲閻楄鏅ラ敍宀冾唨妤犳澘鐡欓弴瀵告埂鐎圭偠鍤滈悞璁圭礉閼板奔绗夐弰顖氬涧閸嶅繐閽╅棃銏犳禈閺嶅洦鍨ㄧ粻鈧崡鏇熸鏉烆剙娼￠妴?

### 娣囶喗鏁?
- 闂呭繑婧€閸斺晜澧滄鏉跨摍閼哥偛褰撮弬鏉款杻閺屾柨鎷板宀勬桨閹垫寧澧妴浣诡攽闂堛垻姹楅悶鍡愨偓浣圭泊閸斻劏寤烘潻鐟板帨閻ユ洖鎷伴拃钘夌暰濮樻稑娲块崗澶涚礉婢х偛宸辨鏉跨摍閹碘偓婢跺嫮骞嗘晶鍐畱閻喎鐤勯幇鐔粹偓?
- 妤犳澘鐡欓崝銊ф暰娴犲骸宕熺痪顖涙鏉烆剝鐨熼弫缈犺礋鐢附婀侀棃鐐靛殠閹勭拨缁夋眹鈧礁鑴婄捄鎶界彯鎼达负鈧焦甯寸憴锕傛Ь瑜颁究鈧胶顫幘鐐插竾缂傗晛鎷伴拃钘夌暰鏉炶浜曢崶鐐存啘閻ㄥ嫮绮嶉崥鍫濆З閺佸牄鈧?
- 妤犳澘鐡欓張顑跨秼缂佹ê鍩楅崡鍥╅獓娑撶儤娲块崷鍡橀紟閻ㄥ嫬顦块棃銏犵杽娴ｆ搫绱版晶鐐插閺嶆垼鍓?鐠烇紕澧拹銊﹀妳閵嗕椒鏅堕棃銏犲袱鎼达负鈧礁娓剧憴鎺曠珶缂傛ǜ鈧礁浜曟０妤冪煈缁惧湱鎮婇妴浣哄箵閻犲啴鐝崗澶婃嫲闁鑵戦幀浣瑰伎鏉堝箍鈧?
- 閻愯鏆熼弨閫涜礋閺囧瓨甯存潻鎴濈サ閸忋儱鈪烽悙鍦畱閸戝綊娅＄拹銊﹀妳閿涘矁绉存潻?6 闂堛垻娈戦弫鏉跨摟闂堛垹顤冮崝鐘插煝閸椾即妲捐ぐ鍗炴嫲妤傛ê鍘滈敍灞肩瑝閺€鐟板綁閸樼喐婀侀棃銏℃殶閸掑棝鍘ら妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛崣顏冩叏閺€?`daily_choice_custom_random_visuals.dart` 閻ㄥ嫬鐫嶇粈鍝勭湴閸滃苯濮╅弫鍫㈢帛閸掕绱濇稉宥勬叏閺€褰掓閺堝搫绱╅幙搴涒偓浣诡洤閻滃洩顓哥粻妞尖偓渚€顎忕€涙劕鍨庣紒鍕灗缂佹挻鐏夐弨璺哄經闁槒绶妴?
- 閺傛澘顤冪紒妯哄煑缂佸棜濡导姘辨殣瀵邦喖顤冮崝鐘活€忕€涙劘鍨堕崣鎵畱 painter 瀹搞儰缍旈柌蹇ョ礉瀹歌弓绻氶幐浣告躬鐏炩偓闁?`RepaintBoundary` 閸愬懎鑻熼柅姘崇箖鐎规艾鎮滃ù瀣槸妤犲矁鐦夐妴?

### 妤犲矁鐦?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_custom_random_visuals.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_custom_random_engine_test.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test\daily_choice_custom_random_engine_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?3 tests閿?

## [Unreleased-PLAN_093-ROULETTE-IMMERSIVE-EFFECTS] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿闁插秵鏌婄拋鎹愵吀閵嗗苯浼愰崗椋庮唸 - 濞撳憡鍨欐稉顓炵妇 - 娣囧嫮缍忛弬顖濈枂閻╂绁甸妴宥喣侀崸妞捐厬閻ㄥ嫬濮╅悽璁崇瑢閻楄鏅ラ敍宀冾唨瀹革箒鐤嗛懜鐐插酱鐏忚棄褰查懗鐣屾埂鐎圭偑鈧焦婀侀張鐑橆潾闁插秹鍣洪崪灞煎閸﹁桨鍞崗銉﹀妳閵?

### 娣囶喗鏁?
- 娣囧嫮缍忛弬顖濈枂閻╂绁甸弬鏉款杻閻滎垰顣ㄩ崨鐓庢儧閵嗕胶鈹栭懚娑欐簚濮婄増濮堥崝銊ユ嫲閸涙垝鑵戦崥搴℃綏娑撳绮嶇憴鍡氼潕閸斻劎鏁鹃幒褍鍩楅崳顭掔礉瀵搫瀵插閫涚波閺冨娴嗛妴浣瑰閺堝搫寮芥＃鍫濇嫲閸戣褰傞惉顒勬？閻ㄥ嫯濡總蹇嬧偓?
- 闁插秶绮锕佺枂閺?`CustomPainter`閿涙艾顤冮崝鐘崇仚缁犫€冲敶閼舵稏鈧礁鑴婃禒鎾斥偓鎺曨潡閵嗕浇鍟楃€涙梹绻佹惔锔衡偓渚€鍣剧仦鐐虹彯閸忓鈧焦婀弻鍕睏閻炲棎鈧浇鐏稉婵勨偓浣规簚濮婃壆绱抽梾娆嶁偓浣圭仚閸欙絿浼€閸忓鎷伴崨鎴掕厬閻戠喖娴橀妴?
- 娑撴槒鍨堕崣鐗堟暭娑撶儤娈崷楦夸粵閸忓绗岄崣浼存桨濮樻稑娲跨仦鍌︾礉閸旂姴鍙嗘担搴″繁鎼达箑鐨圭划鎺嬧偓浣诡攽闂堛垻鍤庨弶掳鈧胶鐓穱鍐ㄥ暱閸戣鍘滈崪宀€菙鐎规氨濮搁幀浣瑰閹垫ê鐪伴敍宀勪缉閸忓秴鍙ч柨顔芥瀮鐎涙鍋撳ù顔兼躬婢跺秵娼呴懗灞炬珯娑撳鈧?
- 妞ゅ爼鍎撮悩鑸碘偓浣稿隘閺€閫涜礋鐟佸懎锝為妴浣衡敄閼舵稏鈧浇鍟楁担宥呮嫲閻樿埖鈧礁娲撴稉顏嗗缁斿鍗庣悰銊ュ幢閿涙稑鍣径鍥у隘閺€鑸垫殐娑撻缚顥婃繅顐ｅ付閸掕泛褰撮敍灞肩箽閻ｆ瑥甯張澶庮棅婵?slider閵嗕焦妫嗘潪顒€鑴婃禒鎾扁偓浣瑰⒏閸斻劍澹嬮張鍝勬嫲闁插秶鐤嗛幙宥勭稊閵?

### 娣囶喖顦?
- 娣囶喖顦?`dart:ui` 婢舵俺澹婂〒鎰綁缂傚搫鐨?`colorStops` 鐎佃壈鍤ф穱鍕稄閺傤垵鐤嗛惄妯垮灦閸欎即顩荤敮褏绮崚璺虹┛濠у啰娈戦梻顕€顣介妴?
- 閺傛澘顤冩穱鍕稄閺傤垵鐤嗛惄妯跨サ妞ょ敻娼?smoke test閿涘矁顩惄鏍ㄧ焽濞存瓕鍨堕崣浼搭浕鐢呯帛閸掕绱濋柆鍨帳閸氬瞼琚?`CustomPainter` 濞撴劕褰夐崣鍌涙殶闂傤噣顣介崶鐐茬秺閵?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛崣顏呮暭娣囧嫮缍忛弬顖濈枂閻╂绁电悰銊у箛鐏炲倶鈧胶绮崚璺虹湴閸滃苯濮╅弫鍫濆棘閺佸府绱濇稉宥勬叏閺€?`_buildSequence`閵嗕礁鐡欏瑙勬殶閵嗕礁鎳℃稉顓炲灲閺傤厹鈧線鐓堕弫鍫ｇカ濠ф劕鎷伴幍锝呭З濞翠胶鈻肩拠顓濈疅閵?
- 閸涙垝鑵戦悧瑙勬櫏閻㈤亶鐝０鎴︽／閻戜焦鏁兼稉铏圭叚娣囧啫鍟块崙璇插帨閵嗕礁鎮楅崸鎰┾偓浣轰紑閸忓鎷伴悜鐔兼禈濞戝牊鏆庨敍宀勬娴ｅ氦顫嬬憴澶屾煂閸旀娊顥撻梽鈹库偓?
- 閺傛澘顤冩径姘嚋鏉炲鍣?`CustomPainter` 缂佹ê鍩楃紒鍡氬Ν閿涘苯鎮楃紒顓炲讲閸︺劎婀￠張杞扮瑐缂佈呯敾鐟欏倸鐧傛担搴ｎ伂鐠佹儳顦敮褏宸奸妴?

### 妤犲矁鐦?
- `dart format lib\src\ui\pages\toolbox_mini_games_roulette.dart`閿涘牓鈧俺绻冮敍?
- `dart format test\toolbox_mini_games_roulette_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_mini_games.dart test\toolbox_mini_games_roulette_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test\toolbox_mini_games_roulette_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? test閿?
- `flutter test test\ui_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?6 tests閿?

## [Unreleased-PLAN_094-RANDOM-WHEEL-REALISTIC-REDESIGN] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿闁插秵鏌婄拋鎹愵吀閵嗗苯浼愰崗椋庮唸 - 濮ｅ繑妫╅崘宕囩摜 - 闂呭繑婧€閸斺晜澧滈妴宥勮厬閻ㄥ嫬銇囨潪顒傛磸閺嶅嘲绱￠崪宀€澹掗弫鍫礉娴ｅ灝鍙剧亸钘夊讲閼宠姤甯存潻鎴犳埂鐎圭偞顢戦棃銏″▕婵傛牞鐤嗛惄妯糕偓?

### 娣囶喗鏁?
- 婢堆嗘祮閻╂鍨堕崣鐗堟煀婢х偞顢戦棃銏″閹垫ǜ鈧椒缍嗘鍗炴嫲閸忓妾块崪灞芥祼鐎规碍瀵氶柦鍫熸暜閺嬭绱濈拋鈺€瀵岄懜鐐插酱閺囨潙鍎氶惇鐔风杽鏉烆喚娲忕憗鍛枂閿涘矁鈧奔绗夐弰顖氶挬闂堛垼澹婇惄妯糕偓?
- 闁插秶绮潪顒傛磸閺堫兛缍嬮敍姘杻閸旂姴甯ゆ惔锔挎櫠婢逛降鈧線鍣剧仦鐐差樆閸﹀牄鈧礁鍞存径鏍ф箑閸掕瀹抽妴浣稿瀻闂呮棃鎼柦澶堚偓浣疯厬韫囧啳閰遍妴浣界仾閺嶆挸鎷伴幍鍥у隘閺夋劘宸濇妯哄帨閵?
- 娑擃厼顨涢崑婊堟浆閺冭泛顤冮崝鐘冲閸栭缚绔熺紓妯哄帨閵嗕浇浜ゅ顔跨枂娴ｆ捁鎹ｆ导蹇嬧偓浣瑰瘹闁藉牆鑴婇悧鍥叧閸斻劌鎷伴幈銏犱粻閸ョ偛鑴婇敍灞藉繁閸栨牜婀＄€圭偞鍎婚幀褌绗岄崑婊堟浆閸欏秹顩妴?
- 鐠嬪啯鏆ｇ粔璇插З缁旑垵鍨堕崣鏉垮磹瀵板嫸绱濋柆鍨帳閸樻艾顦婚崷鍫濇嫲濡楀矂娼伴梼鏉戝閸︺劎鎻ｉ崙鎴︾彯鎼达缚绗呯悮顐ヮ梿閸掑洢鈧?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒鍛叏閺€褰掓閺堝搫濮幍瀣亣鏉烆剛娲忕憴鍡氼潕閸滃苯濮╅弫鍫㈢帛閸掕绱濇稉宥勬叏閺€?`DailyChoiceCustomRandomEngine` 閻ㄥ嫭顩ч悳鍥モ偓浣瑰▕閸欐牓鈧線顎忕€涙劖鍨ㄧ涵顒€绔甸柅鏄忕帆閵?
- 鏉烆剛娲忕紒妯哄煑鐏炲倹鐦稊瀣閺囨潙顦查弶鍌︾礉娴ｅ棔绮涢梽鎰煑閸︺劌宕熸稉?`RepaintBoundary` 閸滃矁浜ら柌?`CustomPainter` 閸愬拑绱濋張顏勭穿閸忋儲鏌婃笟婵婄閹存牕娴橀悧鍥カ娴溠佲偓?

### 妤犲矁鐦?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_custom_random_visuals.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_custom_random_engine_test.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test\daily_choice_custom_random_engine_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?3 tests閿?

## [Unreleased-PLAN_090-DECISION-ACTION-CARD] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿鏉╂稐绔村銉ョ暚閸犲嫨鈧本鐦￠弮銉﹀Ψ閹?- 閸愬磭鐡ラ崝鈺傚閵嗗秶娈戦崗铚傜秼閸旂喕鍏橀拃钘夋勾閼宠棄濮忛敍灞肩瑝濮濄垻绮伴崙鐑樐侀崹瀣瀻閺嬫劧绱濇潻妯款洣鐢喖濮悽銊﹀煕閹跺﹦绮ㄧ拋鍝勫綁閹存劕褰查幍褑顢戦崝銊ょ稊閵?

### 閺傛澘顤?
- 閸愬磭鐡ラ崝鈺傚閺傛澘顤冮妴宀冩儰閸︾増澧界悰灞藉幢閵嗗稄绱伴幍鎸庡复濡€崇€烽幎銉ユ啞缂佹挻鐏夐敍灞界潔缁€鍝勭秼閸撳秴绨查崗鍫Ｋ夋穱鈩冧紖閵嗕焦鏁归崣锝嗗⒔鐞涘矁绻曢弰顖滄埛缂侇厽鐗庨崙鍡愨偓?
- 閺傛澘顤冩稉鈧柨顔炬晸閹存劘鎯ら崷鎷屽磸濡楀牞绱伴懛顏勫З閻㈢喐鍨氭稉瀣╃濮濄儱濮╂担婧库偓浣稿彠闁款噣鐛欑拠浣蜂繆閹垬鈧礁浠犲銏ｎ潐閸掓瑣鈧礁顦查惄妯啃曢崣鎴濇嫲婢惰精瑙︽０鍕川娴滄棃銆嶉崘鍛啇閵?
- 閺傛澘顤冮幍褑顢戦懡澶嬵攳缂傛牞绶崠鐚寸礉閻劍鍩涢崣顖涘瘻閼奉亜绻侀惃鍕埂鐎圭偞鍎忔晶鍐ф叏閺€纭呭殰閸斻劎鏁撻幋鎰敶鐎瑰箍鈧?
- 閺傛澘顤冮妴灞筋槻閸掕埖澧界悰宀€鐣濋幎銉ｂ偓宥堝厴閸旀冻绱濋崣顖氱殺閸愬磭鐡ラ梻顕€顣介妴浣鼓侀崹瀣彙鐠囧棎鈧焦甯归懡鎰侀崹瀣嫲娴滄棃銆嶉拃钘夋勾閼藉顢嶆径宥呭煑閸掓澘澹€鐠愬瓨婢橀妴?

### 娣囶喗鏁?
- 閸愬磭鐡ラ崝鈺傚鏉堟挸鍤柧鎹愮熅娴犲簺鈧矂妫剁粵鏃囩翻閸?閳?濡€崇€烽幎銉ユ啞 閳?濡偓閺屻儲绔婚崡鏇樷偓宥埶夊杞拌礋閵嗗矂妫剁粵鏃囩翻閸?閳?濡€崇€烽幎銉ユ啞 閳?閽€钘夋勾閹笛嗩攽 閳?濡偓閺屻儲绔婚崡鏇樷偓宥忕礉閺囧顑侀崥鍫濆徔娴ｆ挷濞囬悽銊╂４閻滎垬鈧?
- 閽€钘夋勾閸楋繝绮拋銈勭箽閹镐焦鎲崇憰浣哄Ц閹緤绱濋柆鍨帳妞ょ敻娼伴崥顖氬З閺冨爼顤傛径鏍х潔瀵偓婢堆勵唽鐞涖劌宕熼妴?

### 妞嬪酣娅撻崣妯绘纯
- 閼奉亜濮╅悽鐔稿灇閸愬懎顔愭禒鍛稊娑撶儤澧界悰宀冨磸濡楀牞绱濇禒宥夋付閻劍鍩涢弽瑙勫祦閻喎鐤勭痪锔芥将绾喛顓婚崪宀€绱潏鎴幢妤傛﹢顥撻梽鈺佸鞍閻ゆぜ鈧焦纭跺瀣ㄢ偓浣藉偍閸旓紕鐡戞禍瀣€嶆稉宥呯安閸欘亙绶风挧鏍ㄦ拱濡€虫健閹笛嗩攽閵?

### 妤犲矁鐦?
- `dart format .\test\daily_choice_hub_smoke_test.dart .\lib\src\ui\pages\toolbox_daily_choice\daily_choice_hub.dart .\lib\src\ui\pages\toolbox_daily_choice\daily_choice_decision_assistant.dart .\lib\src\ui\pages\toolbox_daily_choice\daily_choice_decision_interaction.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice\daily_choice_hub.dart .\test\daily_choice_decision_engine_test.dart .\test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_decision_engine_test.dart .\test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?8 tests閿?

## [Unreleased-PLAN_089-RANDOM-ASSISTANT-VISUAL-POLISH] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閵嗗苯浼愰崗椋庮唸 - 濮ｅ繑妫╅幎澶嬪 - 闂呭繑婧€閸斺晜澧滈妴宥勮厬閻ㄥ嫬銇囨潪顒傛磸閵嗕線顎忕€涙劒绗岀涵顒€绔甸弽宄扮础閸滃瞼澹掗弫鍫滅矝娑撳秴顧勯悳棰佸敩閼奉亞鍔ч敍灞芥尐閸忓爼顎忕€涙劙娓剁憰浣告啛閻滄澘顦块棃銏㈢彌娴ｆ挾绮ㄩ弸鍕剁礉閼板奔绗夐弰顖滅暆閸楁洖閽╅棃銏犳禈閻楀洢鈧?

### 娣囶喗鏁?
- 闂呭繑婧€閸斺晜澧滈懜鐐插酱鐎圭懓娅掗弨閫涜礋閺囧瓨鐓嶉崪宀€娈戝〒鎰綁閹垫寧澧仦鍌︾礉閸戝繐鐨悽鐔衡€栭惂钘夌俺閹扮噦绱濋獮鏈电箽閻ｆ瑧菙鐎规俺绔熼悾灞间簰娣囨繆鐦夐崣顖濐嚢閹佲偓?
- 婢堆嗘祮閻╂ê顤冮崝鐘虹枂娴ｆ挸甯ゆ惔锔衡偓浣哥俺闁劍澹欓幍姗€妲捐ぐ渚库偓浣稿敶婢舵牕婀€閸掕瀹抽妴浣疯厬韫囧啳閰辨妯哄帨閸滃本娲块弰搴ｂ€橀惃鍕瘹闁藉牆鐪板▎鈽呯礉娑擃厼顨涢幍鍥у隘閸嬫粎鏆€閺冭埖婀侀弴瀛樼閺呮壆娈戞妯哄帨鏉堝湱鏅妴?
- 妤犳澘鐡欐禒搴￠挬闂堛垹娓剧憴鎺撴煙閸ф鏁兼稉?Flutter `CustomPainter` 缂佹ê鍩楅惃鍕讲閸欐﹢娼伴弫鎵彌娴ｆ挸顦块棃顫秼閿涙碍瀵?3 閸?12 闂堛垻绮崚鑸殿劀闂堛垹顦挎潏鐟拌埌閵嗕浇鍎楅棃銏犱焊缁夋眹鈧椒鏅堕棃銏犲瀻閻楀洢鈧焦锛戠痪瑁も偓渚€鐝崗澶堚偓渚€妲捐ぐ鍗炴嫲閽€钘夋勾閸欏秹顩妴?
- 妤犳澘鐡欑紒褏鐢绘穱婵堟殌 D1 / 闂堛垺鏆?/ 瑜版挸澧犻棃銏犫偓鍏兼▔缁€鐚寸幢6 闂堫澀浜掗崘鍛▏閻劎鍋ｉ弫甯礉鐡掑懓绻?6 闂堛垺妯夌粈鐑樻殶鐎涙绱濇稉宥嗘暭閸欐ê甯張澶愭桨閺佹澘鍨庨柊宥呮嫲閹惰棄褰囩紒鎾寸亯閵?
- 绾剙绔电紙鏄忔祮閺€閫涜礋閺嶈宓侀張鈧紒鍫㈢波閺嬫粌鍠呯€规俺鎯ら崷銊︻劀闂堛垺鍨ㄩ崣宥夋桨閿涘苯鑻熸晶鐐插闁叉垵鐫樻潏鍦喘閸樺缂夐妴浣哄箚瑜般垻姹楅悶鍡愨偓浣稿煝鎼达负鈧線妲捐ぐ鍗炴嫲娑擃厼顨涢崑婊呮殌閸忓鍔呴妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛崣顏呮暭闂呭繑婧€閸斺晜澧滅憴鍡氼潕鐏炲倸鎷伴崝銊︽櫏缂佹ê鍩楅敍灞肩瑝娣囶喗鏁?`DailyChoiceCustomRandomEngine` 閻ㄥ嫭顩ч悳鍥モ偓渚€顎忕€涙劕鍨庣紒鍕┾偓浣衡€栫敮浣筋吀閺佹澘鎷扮紒鎾寸亯閺€璺哄經闁槒绶妴?
- 閺傛澘顤冩径姘嚋鏉炲鍣?`CustomPainter`閿涘矁顫嬬憴澶婄湴婢跺秵娼呮惔锔藉絹妤傛﹫绱卞鏌モ偓姘崇箖鐎规艾鎮滈崚鍡樼€介崪灞剧ゴ鐠囨洩绱濋崥搴ｇ敾娴犲秴褰查崷銊ф埂閺堣桨绗傜憴鍌氱檪娴ｅ海顏拋鎯ь槵鐢呭芳閵?

### 妤犲矁鐦?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_custom_random_visuals.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_custom_random_engine_test.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test\daily_choice_custom_random_engine_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?3 tests閿?

## [Unreleased-PLAN_088-MINI-GAMES-INTERACTION-UPGRADE] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯娣囧嫮缍忛弬顖濈枂閻╂绁佃ぐ鎾冲閻ｅ矂娼伴崓蹇涱€忕€涙劧绱濈紓鍝勭毌閻喎鐤勫锕佺枂閺嬵亝膩閹风喆鈧礁鍣径鍥︾瑐閼舵稒绁︾粙瀣ㄢ偓浣藉殰鐎规矮绠熼悧瑙勬櫏娑撳酣鐓堕弫鍫幢娣囧嫮缍忛弬顖涙煙閸ф娓剁憰浣瑰瘻鐏炲繐绠锋妯哄闁倿鍘ら妴浣规暭閻劑浠撮幒褎澧滈弻鍕础閹貉冨煑閵嗕礁顤冮崝鐘绘鎼达缚绗屾径杈Е缂佹挾鐣婚敍娑欏腹缁犲崬鐡欓棁鈧憰渚€姣︽惔锕侇啎缂冾噯绱濋獮鑸垫暜閹镐礁顦挎稉顏嗩唸鐎涙劕鎷版径姘嚋閻╊喗鐖ｉ悙骞库偓?

### 閺傛澘顤?
- 娣囧嫮缍忛弬顖濈枂閻╂绁甸弬鏉款杻閳ユ粌鍣径鍥风窗娑撳﹨鍟楅獮鑸垫鏉烆剙鑴婃禒鎾偓婵囩ウ缁嬪绱濋崙鍡楊槵閺冩湹绱伴柌宥嗙瀵€涚波楠炶埖鎸遍弨鎯ц剨娴犳挻妫嗘潪顒勭叾閺佸牄鈧?
- 娣囧嫮缍忛弬顖濈枂閻╂绁甸弬鏉款杻娑撳顔岄張顒€婀?wav 闂婅櫕鏅ョ挧鍕爱閿涙艾鑴婃禒鎾存鏉烆兙鈧胶鈹栭懚娑㈠櫨鐏炵偛鎸冮崫鎺嬧偓浣稿毊閸欐垹鍨庣憗鍌炵叾閺佸牞绱濋獮鑸靛复閸?`audioplayers` 鐠у嫪楠囬幘顓熸杹閵?
- 娣囧嫮缍忛弬顖濈枂閻╂绁甸弬鏉款杻瀹革箒鐤嗛弸?CustomPainter 閼哥偛褰撮敍灞藉瘶閸氼偅鐏欓煬顐犫偓浣圭仚缁犅扳偓浣歌剨娴犳挶鈧焦澹嬮張鎭掆偓浣稿毊闁裤們鈧礁缍嬮崜宥堝晽娴ｅ秹鐝禍顔衡偓浣瑰⒏閸斻劍澹嬮張鍝勫З閻㈣鎷伴崨鎴掕厬閺嬵亜褰涢悘顐㈠帨閵?
- 娣囧嫮缍忛弬顖涙煙閸ф鏌婃晶鐐烘鎼达附銆傛担宥忕窗閺€鐐緱閵嗕胶绮￠崗鎼炩偓浣虹彽闁噦绱卞В蹇庨嚋濡楋絼缍呴柊宥囩枂娑撳秴鎮撻崚婵嗩潗娑撳妾烽柅鐔峰閵嗕焦鐦＄痪褍濮為柅鐔风畽鎼达箑鎷伴崡鍥╅獓鐞涘本鏆熼妴?
- 娣囧嫮缍忛弬顖涙煙閸ф鏌婃晶鐐层亼鐠愩儳绮ㄧ粻妤€鑴婄粣妤嬬礉閺勫墽銇氬妤€鍨庨妴浣圭Х鐞涘被鈧胶鐡戠痪褍鎷伴梾鎯у閿涘苯鑻熼弨顖涘瘮閻╁瓨甯撮崘宥嗘降娑撯偓鐏炩偓閵?
- 閹恒劎顔堢€涙劖鏌婃晶鐐烘鎼达附銆傛担宥忕窗閸楁洜顔堥妴浣稿蓟缁犱究鈧椒绗佺粻鎲嬬幢閹稿姣︽惔锔炬晸閹存劕顦挎稉顏嗩唸鐎涙劑鈧礁顦挎稉顏嗘窗閺嶅洨鍋ｉ崪灞筋樋閺夆剝顒滅涵顔藉腹閸斻劏鐭剧痪瑁も偓?

### 娣囶喗鏁?
- 娣囧嫮缍忛弬顖涙煙閸ф顥愰惄妯诲瘻鐏炲繐绠锋妯哄閸斻劍鈧線妾洪崚璺烘槀鐎甸潻绱濋柆鍨帳閸ュ搫鐣炬妯哄閸︺劌鐨仦蹇庣瑐鏉╁洭鏆遍妴?
- 娣囧嫮缍忛弬顖涙煙閸ф甯堕崚璺哄隘閺€閫涜礋娴滄棃鏁幍瀣労閿涙矮绗傞柨顔芥畯閸?缂佈呯敾閿涘苯涔?閸欐娊鏁粔璇插З閿涘奔绗呴柨顔胯拫闂勫秳绗栭梹鎸庡瘻绾剟妾烽敍灞艰厬闂傛挳鏁崣妯鸿埌閵?
- 閹恒劎顔堢€涙劖褰佺粈娲偓鏄忕帆閺€閫涜礋閸︺劌顦挎稉顏嗩唸鐎涙劗娈戝锝団€樼捄顖滃殠娑擃厼顕伴幍鍙ョ瑓娑撯偓濮濄儱褰查幒銊ь唸鐎涙劧绱濋獮璺烘躬閺勫墽銇氱捄顖滃殠閺冭泛鐫嶇粈鍝勵樋閺壜ょ熅瀵板嫨鈧?
- `pubspec.yaml` 閺傛澘顤?`assets/toolbox/games/roulette/` 鐠у嫪楠囬惄顔肩秿閵?

### 妞嬪酣娅撻崣妯绘纯
- 娣囧嫮缍忛弬顖濈枂閻╂绁甸崨鎴掕厬閻楄鏅ラ弴瀛樻閺勬拝绱濇禒宥勭箽閹镐胶鏁ら幋铚傚瘜閸斻劍澧搁崝銊﹀閺堝搫鎮楅惌顓熸鐟欙箑褰傞敍宀勪缉閸忓秴鎯婇悳顖炴／閻戜降鈧?
- 閹恒劎顔堢€涙劕顦跨粻鍗炲彠閸楋繝鍣伴悽銊⑩偓婊冨帥閻㈢喐鍨氭径姘蒋閸欘垵袙鐠侯垰绶為敍灞藉晙閺€鍓х枂闂呮粎顣查獮鍫曠崣鐠囦讲鈧繄娈戞潪濠氬櫤閻㈢喐鍨氱粵鏍殣閿涙稑顦查弶鍌溾柤鎼达箓鐝禍搴″礋缁犳唻绱濇担鍡曠矝娑撳秵妲哥€瑰本鏆ｆ稉鎾茬瑹閸忓啿宕辩紓鏍帆閸ｃ劊鈧?

### 妤犲矁鐦?
- `flutter pub get`閿涘牓鈧俺绻冮敍?
- `dart format lib\src\ui\pages\toolbox_mini_games.dart lib\src\ui\pages\toolbox_mini_games_roulette.dart lib\src\ui\pages\toolbox_mini_games_tetris.dart lib\src\ui\pages\toolbox_mini_games_sokoban.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_mini_games.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\ui_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?6 tests閿?
- `git diff --check`閿涘牓鈧俺绻冮敍灞肩矌閹绘劗銇氳ぐ鎾冲瀹搞儰缍旈弽鎴ｅ楠炲弶妫﹂張澶嬫瀮娴犳湹绗呭▎陇顫?Git 鐟欙妇顫弮?LF 娴兼碍瀵滈柊宥囩枂鏉烆兛璐?CRLF閿?

## [Unreleased-PLAN_086-DAILY-CHOICE-UX-COPY-LAYOUT] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯濮ｅ繑妫╅崘宕囩摜瑜版挸澧?UX 缂佹挻鐎崑蹇涙毐閵嗕礁灏崸妤勭珶閻ｅ奔绗夊〒鍛偓浣瑰閸欑姴鍙嗛崣锝勭瑝婢剁喖鍟嬮惄顕嗙礉娑撴棃鍎撮崚鍡涚帛鐠併倖鏋冨鍫濐洤 Option A/B 娑撳秴顧勯張顒€婀撮崠鏍ф嫲娑撴挷绗熼妴?

### 閺傛澘顤?
- 閸愬磭鐡ラ崝鈺傚閺傛澘顤冭ぐ鈺勫閸掑棗灏弽鍥暯娑撳氦绶熼崝鈺冨Ц閹浇澹婇敍灞藉隘閸掑棝妫舵０妯糕偓浣稿讲闁銆嶉妴浣瑰剰婢у啫鍨庨崹瀣ㄢ偓浣圭墡閸戝棗鎷伴幎銉ユ啞閹芥顩﹂妴?
- 閹舵ê褰?鐏炴洖绱戦崗銉ュ經閺傛澘顤冭ぐ鈺勫閸﹀棗鑸伴崶鐐垼閻樿埖鈧緤绱扮仦鏇炵磻閹椒濞囬悽銊ゅ瘜瀵缚鐨熼懝璇х礉閺€鎯版崳閹椒濞囬悽銊ㄧ窡閸斺晜褰侀柋鎺曞閵?
- 閸愬磭鐡ラ幎銉ユ啞閻ㄥ嫬鐣弫瀛樐侀崹瀣嚠閻撗勬暭娑撳搫鑴婄粣妤佺叀閻绱濋崘宕囩摜濡偓閺屻儲绔婚崡鏇氱瘍閺€閫涜礋閹芥顩﹂崡?+ 瀵湱鐛ュ〒鍛礋閵?

### 娣囶喗鏁?
- 姒涙顓婚崣顖炩偓澶愩€嶉弬鍥攳娴?Option A/B/C 鐠嬪啯鏆ｆ稉杞拌厬閺傚洨骞嗘晶鍐х瑓閻ㄥ嫨鈧苯褰查柅澶愩€?A/B/C閵嗗稄绱濋懛顏勭暰娑斿娈㈤張娲帛鐠併倝銆嶉崥灞绢劄鐠嬪啯鏆ｉ妴?
- 閸愬磭鐡ラ崝鈺傚閵嗕浇顓哥粻妤伳侀崹瀣ㄢ偓浣瑰Г閸涘﹤鎷板Λ鈧弻銉ュ隘閺傚洦顢嶇划鍓х暆娑撶儤娲块惌顓犳畱閹绘劗銇氶幀褑銆冩潏淇扁偓?
- 妤傛楠囩拠鍕瀻鐞涖劊鈧線娈㈤張鍝勫И閹靛寮弫鏉垮隘閸滃本膩閸ㄥ顕悡褎濮岄崣鐘插弳閸欙絼濞囬悽銊︽纯濞撳懏娅氶惃鍕杹閼硅尪绔熼悾灞肩瑢閻樿埖鈧焦褰佺粈鎭掆偓?

### 妞嬪酣娅撻崣妯绘纯
- 鐠囷妇绮忓Ο鈥崇€风€靛湱鍙庨崪灞藉枀缁涙牗顥呴弻銉︾閸楁洑绮犳稉濠氥€夐棃顫瑓濞屽鍩屽鍦崶閿涘矂娓剁憰浣烘暏閹村嘲顦块悙鐟板毊娑撯偓濞嗏槄绱辨稉濠氥€夐棃顫箽閻ｆ瑦鎲崇憰浣碘偓浣呵旂€规艾瀹抽妴浣蜂繆閹垯鐜崐鐓庢嫲妤傛﹢顥撻梽鈺傚絹闁辨帇鈧?

### 妤犲矁鐦?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?3 tests閿?
- `git diff --check`閿涘牓鈧俺绻冮敍灞肩矌閹绘劗銇氳ぐ鎾冲瀹搞儰缍旈弽鎴滆厬閺冦垺婀?LF/CRLF 鏉烆剚宕茬拃锕€鎲￠敍?

## [Unreleased-PLAN_088-RANDOM-ASSISTANT-UX-MOTION] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閵嗗矁鍤滅€规矮绠熼梾蹇旀簚閵嗗秴鎳￠崥宥冣偓浣稿棘閺佹壆绱潏鎴滅秴缂冾喖鎷版稉澶岊潚闂呭繑婧€閸斻劎鏁剧拹銊﹀妳娴犲秳绗夋径鐔诲殰閻掕绱伴柅澶愩€嶉崣鍌涙殶閸︺劑銆夐棃銏犵俺闁劌顕遍懛鎾暥缁讳椒绗傛稉瀣拨閸旑煉绱濇潪顒傛磸/妤犳澘鐡?绾剙绔甸崝銊ф暰娑旂喓宸辩亸鎴犳埂鐎圭偠宸濋幇鐔锋嫲閸戝繘鈧?绾扮増鎸?闁叉垵鐫橀弮瀣祮閸欏秹顩妴?

### 娣囶喗鏁?
- 鐏忓棎鈧矁鍤滅€规矮绠熼梾蹇旀簚閵嗗秶绮烘稉鈧弴鏉戞倳娑撴亽鈧矂娈㈤張鍝勫И閹靛鈧稄绱濋崥灞绢劄濮ｅ繑妫╅崘宕囩摜濡€虫健閸忋儱褰涢妴渚€銆夐棃銏＄垼妫版ǜ鈧焦瀵氶崡妤€鎷伴弬鍥ㄣ€傜拠瀛樻閵?
- 闂呭繑婧€閸斺晜澧滄い鐢告桨闁插秵甯撴稉鎭掆偓灞炬煙瀵繘鈧瀚?閳?闁銆嶆稉搴″棘閺?閳?闂呭繑婧€閼哥偛褰撮妴宥忕礉闁銆嶉崣鍌涙殶娑撳孩鏌熷蹇撳棘閺佹澘鎮庨獮鏈佃礋闂呭繑婧€娑撳﹥鏌熼惃鍕讲閹舵ê褰旈棃銏℃緲閵?
- 閸欏倹鏆熼棃銏℃緲閺傛澘顤冮張澶嬫櫏闁銆嶉弫?閹鈧銆嶉弫鐗堟喅鐟曚緤绱濈紓鏍帆閸氬秶袨閵嗕礁顤冮崚鐘烩偓澶愩€嶉妴浣稿瀼閹广垺鏌熷蹇斿灗鐠嬪啯鏆ｆ鏉跨摍/绾剙绔甸崣鍌涙殶閺冭泛鐤勯弮璺哄煕閺傛澘缍嬮崜宥嗘殶闁插繐鎷伴崣顖滄暏缁撅附娼妴?
- 婢堆嗘祮閻╂ɑ鏁兼稉鐑樻纯妤傛宸濋幇鐔烘畱閸掑棗灏懝鑼磸閿涙岸鐝€佃鐦幍鍥у隘閵嗕礁顦婚崷鍫濆煝鎼达负鈧椒鑵戣箛鍐叡閵嗕焦瀵氶柦鍫濇嫲婢舵艾婀€缂傛挻鍙冮崙蹇涒偓鐔蜂粻濮濐潿鈧?
- 妤犳澘鐡欓崝銊ф暰閺€閫涜礋閺囧婀＄€圭偟娈戞浼存桨鐞涖劏鎻敍? 闂堛垹鍞撮弰鍓с仛閻愯鏆熼敍灞姐亣娴?6 闂堛垺妯夌粈鐑樻殶鐎涙绱濋獮璺侯杻閸旂姵妫嗘潪顑锯偓浣歌剨鐠哄啿鎷扮喊鐗堟寬閹扮喆鈧?
- 绾剙绔甸崝銊ф暰閺€閫涜礋闁叉垵鐫樼拹銊﹀妳閸﹀棗绔甸敍灞炬暜閹镐礁鎻╅柅鐔虹倳鏉烆剚妯夌粈鐑橆劀閸欏秳琚遍棃銏犳嫲閺堚偓缂佸牏绮ㄩ弸婧库偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺囩繝璧寸€靛瞼娈戦崝銊ф暰娴犲秳绻氶幐浣戒氦闁?Transform 閸?CustomPainter 鐎圭偟骞囬敍灞肩瑝瀵洖鍙嗛悧鈺冩倞瀵洘鎼搁敍娑楃秵缁旑垵顔曟径鍥у讲閼充粙娓剁憰浣烘埛缂侇叀顫囩€电喎鎶氶悳鍥モ偓?

### 妤犲矁鐦?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_custom_random_engine_test.dart .\test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_custom_random_engine_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test .\test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?3 tests閿?

## [Unreleased-PLAN_086-CUSTOM-RANDOM] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿閸︺劊鈧苯浼愰崗椋庮唸 - 濮ｅ繑妫╅崘宕囩摜閵嗗秳鑵戦崡鏇犲閺傛澘顤冮妴宀勬閺堝搫濮幍瀣ㄢ偓宥呯摍濡€虫健閿涘本鏁幐浣告綆閸栤偓閵嗕礁濮為弶鍐︹偓浣戒粓閸氬牆鍨庣敮鍐樋鏉烆喚鐡戦梾蹇旀簚閺傜懓绱￠敍灞借嫙閹绘劒绶垫潪顒傛磸閵嗕線顎忕€涙劑鈧胶鈥栫敮浣虹搼閸斻劎鏁鹃弫鍫熺亯閵?

### 閺傛澘顤?
- 濮ｅ繑妫╅崘宕囩摜閺傛澘顤冮妴宀勬閺堝搫濮幍瀣ㄢ偓宥呯摍濡€虫健閿涙碍鏁幐浣峰閺冭泛缍嶉崗銉┾偓澶愩€嶉妴浣虹椽鏉堟垶娼堥柌宥呮嫲閺夆€叉濮掑倻宸奸敍灞借嫙閸︺劌娼庨崠鈧?閸旂姵娼?閼辨柨鎮庢径姘崇枂娑斿妫块崚鍥ㄥ床閵?
- 閺傛澘顤冮懛顏勭暰娑斿娈㈤張鍝勭穿閹垮函绱濋梿鍡曡厬婢跺嫮鎮婂鍌滃芳瑜版帊绔撮崠鏍モ偓浣稿閺夊啯濞婇崣鏍モ偓浣戒粓閸氬牆鍨庣敮鍐樋鏉烆喗濞婇崣鏍モ偓渚€顎忕€涙劙娼伴弫鏉垮瀻闁板秴鎷版径姘扁€栫敮浣虹波閺嬫粍鏁归崣锝冣偓?
- 閺傛澘顤冩稉澶岃閸斻劎鏁鹃懜鐐插酱閿涙艾銇囨潪顒傛磸閹稿缍嬮崜宥嗩洤閻滃洦膩閸ㄥ鐫嶇粈鐑樺閸栫尨绱濇鏉跨摍閹稿鈧銆嶉弫鐗堝閸掑棔璐?3 閸?12 闂堛垻娈戞径姘额€忕€涙劧绱濈涵顒€绔甸梽鎰煑娑撹桨琚遍棃銏犳綆閸栤偓楠炶埖鏁幐浣割樋閺嬫氨鈥栫敮浣碘偓?
- 閺傛澘顤冨鏇熸惛閸楁洖鍘撳ù瀣槸閸?hub 閸愭帞鍎ù瀣槸閿涘矁顩惄鏍у閺夊啯顩ч悳鍥モ偓浣戒粓閸氬牊顩ч悳鍥モ偓渚€顎忕€涙劗瀹抽弶鐔粹偓浣衡€栫敮浣哄閺夌喎鎷伴弬鏉跨摍濡€虫健閸忋儱褰涢妴?

### 娣囶喗鏁?
- 濮ｅ繑妫╅崘宕囩摜閸忋儱褰涙禒搴濈安濡€虫健閺囧瓨鏌婃稉鍝勫彋濡€虫健閿涘苯鑻熺亸鍡愨偓宀勬閺堝搫濮幍瀣ㄢ偓宥嗗复閸忋儲膩閸ф鍨忛幑銏犳珤閵?
- 閸氬本顒?`PROJECT_DOMAIN.md` 娑?`modules/toolbox/README.md` 娑擃厾娈戝В蹇旀）閹跺瀚ㄥΟ鈥虫健鏉堝湱鏅拠瀛樻閵?

### 妞嬪酣娅撻崣妯绘纯
- 闂呭繑婧€閸斺晜澧滄禒鍛粹偓鍌氭値娴ｅ酣顥撻梽鈹库偓浣稿讲閸ョ偤鈧偓閵嗕線鈧銆嶅顔肩磽娑撳秴銇囬惃鍕偓澶嬪閿涙盯鐝搴ㄦ珦閸栬崵鏋熼妴浣圭《瀵板鈧浇鍌ㄩ崝鈩冨灗娑撳秴褰查柅鍡楀枀缁涙牔绮涙惔鏂惧▏閻劌鍠呯粵鏍уИ閹靛鍨ㄦ稉鎾茬瑹閹板繗顫嗛妴?
- 妤犳澘鐡欓崝銊ф暰閸︺劏绉存潻?12 娑擃亪鈧銆嶉弮鍫曞櫚閻劌顦挎鏉跨摍閸掑棛绮嶇仦鏇犮仛閿涘本娓剁紒鍫熷▕閸欐牔绮涚€电懓鍙忛柈銊┾偓澶愩€嶆穱婵囧瘮閸у洤瀵戦妴?

### 妤犲矁鐦?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_custom_random_engine_test.dart .\test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_custom_random_engine_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test .\test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?3 tests閿?

## [Unreleased-PLAN_087-MINI-GAMES-EXPANSION] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿閸︺劌浼愰崗椋庮唸-濞撳憡鍨欐稉顓炵妇娑擃叀藟閸忓懍绺跨純妤佹焿鏉烆喚娲忕挧灞烩偓浣风缚缂冩鏌夐弬鐟版健閸滃本甯圭粻鍗炵摍娑撳閲滅亸蹇旂埗閹村骏绱濋獮鎯邦洣濮瑰倽鐤嗛惄妯跨サ閸忓嘲顦棅铏櫏閵嗕線妫悜浣碘偓渚€娓块崝銊ュ冀妫ｅ牞绱濋幒銊ь唸鐎涙劕鍙ч崡陇鍤︾亸鎴滅箽鐠囦焦婀佺憴锝呰嫙閹绘劒绶甸幓鎰仛/濮濓絿鈥樼捄顖滃殠鏉堝懎濮妴?

### 閺傛澘顤?
- 濞撳憡鍨欐稉顓炵妇閺傛澘顤冩穱鍕稄閺傤垵鐤嗛惄妯跨サ閸忋儱褰涙稉搴ㄣ€夐棃顫窗閺€顖涘瘮 1-5 閸欐垵鐡欏纭咁啎缂冾喓鈧線鈧劖顐奸幍锝呭З閹佃櫕婧€閵嗕胶鈹栭懚娑氶兇缂佺喓鍋ｉ崙濠氱叾閵嗕礁鎳℃稉顓炴倵閻ㄥ嫮閮寸紒鐔活劅缁€娲叾閵嗕浇袝閹扮喎寮芥＃鍫濇嫲閻厽妞傞崗銊ョ潌闂傤亞鍎婇弫鍫熺亯閵?
- 濞撳憡鍨欐稉顓炵妇閺傛澘顤冩穱鍕稄閺傤垱鏌熼崸妤€鍙嗛崣锝勭瑢妞ょ敻娼伴敍姘暜閹?10x20 濡娲忛妴浣风缁夊秵鏌熼崸妞尖偓浣规鏉烆兙鈧礁涔忛崣宕囆╅崝銊ｂ偓浣借拫闂勫秲鈧胶鈥栭梽宥冣偓浣圭Х鐞涘苯绶遍崚鍡愨偓浣虹搼缁狙冨闁喆鈧焦娈忛崑婊冩嫲閺傛澘鐪妴?
- 濞撳憡鍨欐稉顓炵妇閺傛澘顤冮幒銊ь唸鐎涙劕鍙嗛崣锝勭瑢妞ょ敻娼伴敍姘帥閻㈢喐鍨氱粻鍗炵摍閻ㄥ嫭顒滅涵顔藉腹閸斻劏鐭惧鍕剁礉閸愬秶鏁撻幋鎰版绾板秴鑻熸宀冪槈鐠侯垰绶為崣顖濇彧閿涙稒鏁幐浣盒╅崝銊ｂ偓浣规寵闁库偓閵嗕焦褰佺粈鎭掆偓浣诡劀绾喛鐭剧痪鎸庢▔缁€鎭掆偓浣规煀閸忓啿宕遍崪灞界唨娴滃孩顒滅涵顔跨熅瀵板嫭顒為弫鎵畱闂呮儳瀹崇仦鏇犮仛閵?

### 娣囶喗鏁?
- 閺囧瓨鏌婂銉ュ徔缁犺鲸鐖堕幋蹇庤厬韫囧啫鍙嗛崣锝堫嚛閺勫簼绗?mini games hub 閺夛紕娲伴敍灞煎▏閺傛澘顤冩稉澶夐嚋鐏忓繑鐖堕幋蹇庣瑢閻滅増婀侀弫鎵閵嗕焦澹傞梿鏋偓浣瑰閸ヤ勘鈧椒绨茬€涙劖顥愰崪?2048/4096 娑撯偓鐠у嘲鐫嶇粈鎭掆偓?
- 閺傛澘顤冪亸蹇旂埗閹村繐娼庨幏鍡楀瀻娑撹櫣瀚粩?`toolbox_mini_games_*.dart` part 閺傚洣娆㈤敍灞肩箽閹?hub 閺傚洣娆㈤崣顏囩鐠愶綁銆夐棃銏犲弳閸欙絼绗岀€佃壈鍩呯紒鍕矏閵?

### 妞嬪酣娅撻崣妯绘纯
- 娣囧嫮缍忛弬顖濈枂閻╂绁甸惃鍕嚒娑擃厾澹掗弫鍫濆瘶閸氼偆鐓弮鍫曟／鐏炲繐鎷伴棁鍥уЗ閿涘苯鍑￠梽鎰煑娑撹櫣鏁ら幋铚傚瘜閸斻劎鍋ｉ崙璇叉倵閻ㄥ嫪缍嗘０鎴犵叚閺冭泛寮芥＃鍫礉娴ｅ棙鏅遍幇鐔烘暏閹磋渹绮涢崣顖濆厴閹扮喎鍩岄崚鐑樼负閵?
- 娣囧嫮缍忛弬顖涙煙閸фぞ绗岄幒銊ь唸鐎涙劙鍣伴悽銊︽拱閸︽媽浜ら柌蹇氼潐閸掓瑥绱╅幙搴礉閺堫亜绱╅崗銉ь儑娑撳鏌熷〒鍛婂灆鎼存搫绱遍崥搴ｇ敾婵″倿娓堕崗鍐插幢閸栧懌鈧焦甯撶悰灞绢渷閵嗕竸I 濮瑰倽袙閸ｃ劍鍨ㄩ弴鏉戠暚閺佺顫夐崚娆欑礉閸欘垰宕熼悪顒冪槑娴肩増鍨氶悢鐔风磻濠ф劕鐤勯悳鑸偓?

### 妤犲矁鐦?
- `dart format lib\src\ui\pages\toolbox_mini_games.dart lib\src\ui\pages\toolbox\toolbox_page_content.dart lib\src\ui\pages\toolbox_mini_games_roulette.dart lib\src\ui\pages\toolbox_mini_games_tetris.dart lib\src\ui\pages\toolbox_mini_games_sokoban.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_mini_games.dart lib\src\ui\pages\toolbox\toolbox_page_content.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\ui_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?6 tests閿?
- `git diff --check`閿涘牓鈧俺绻冮敍灞肩矌閹绘劗銇氳ぐ鎾冲瀹搞儰缍旈弽鎴ｅ楠炲弶妫﹂張澶嬫瀮娴犳湹绗呭▎陇顫?Git 鐟欙妇顫弮?LF 娴兼碍瀵滈柊宥囩枂鏉烆兛璐?CRLF閿?

## [Unreleased-PLAN_084-ACTIVITY-LIBRARY-SETS] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿鐎瑰苯鏉介妴灞戒紣閸忛顔?- 濮ｅ繑妫╅崘宕囩摜 - 楠炶弓绮堟稊鍫涒偓宥呯摍濡€虫健閿涙艾鍎氶崥鍐х矆娑斿牄鈧胶鈹涙禒鈧稊鍫滅閺嶉攱鏁幐浣稿讲缁狅紕鎮婇惃鍕殰鐎规矮绠熸禍瀣╂闂嗗棴绱濋獮鑸靛Ω demo 闂堟瑦鈧浇顢戦崝銊︽殶閹诡喖宕岀痪褌璐熼崣顖欑瑐娴?S3閵嗕竸pp 娑撳娴囬崥搴″晸閸?SQLite 閻ㄥ嫮婀＄€圭偠顢戦崝銊ョ氨閵?
- 閸樼喐婀侀獮韫矆娑斿牊鏆熼幑顔荤矝鐢附婀佹禒搴ゅ綅鐠?demo 婢跺秴鍩楅弶銉ф畱閺夋劖鏋?濮濄儵顎冪拠顓濈疅閿涘矂娓剁憰浣规暭閹存劏鈧粌绱戞慨瀣蒋娴犺翰鈧焦澧界悰灞绢劄妤犮們鈧線鈧偓閸戦缚绔熼悾灞糕偓婵堟畱鐞涘苯濮╃紒鎾寸€敍灞借嫙鐞涖儱鍘栭崗铚傜秼闂傤噣顣界€电厧鎮滈惃鍕攽閸斻劍瀵氶崡妞尖偓?

### 閺傛澘顤?
- 楠炶弓绮堟稊鍫熸煀婢х偟鏁ら幋宄板讲缁狅紕鎮婇惃鍕攽閸斻劑娉﹂敍姘暜閹镐線绮拋銈堫攽閸斻劑娉﹂妴浣藉殰瀵ら缚顢戦崝銊╂肠閵嗕線鍣搁崨钘夋倳閵嗕礁鍨归梽銈冣偓浣割嚤閸忋儱顕遍崙鐚寸礉娴犮儱寮烽崷銊х椽鏉堟垼顢戦崝銊︽閸曢箖鈧澧嶇仦鐐额攽閸斻劑娉﹂妴?
- 閺傛澘顤?`DailyChoiceActivityLibraryStore`閿涙矮绮?`activity_data/daily_choice_activity_library.json` 娑撳娴囨潻婊咁伂 JSON閿涘苯鐣ㄧ憗鍛礋閺堫剙婀?`toolbox_daily_choice_activity.db`閿涘苯鑻熼弨顖涘瘮閹芥顩﹂妴浣筋嚊閹懎鎷伴崚鍡欒/閸︾儤娅欓弻銉嚄閵?
- 閺傛澘顤冮獮韫矆娑斿牊鏆熼幑顔炬晸閹存劘鍓奸張顒婄礉瀹告彃顕遍崙鍝勫煂 `D:\vocabularySleep-resources\楠炶弓绮堟稊?閺佺増宓乣閿涙艾瀵橀崥?JSON閵嗕讣QLite閵嗕梗FORMAT.md` 閸?`GENERATION_SUMMARY.md`閿涘苯缍嬮崜?48 閺壜ゎ攽閸斻劊鈧?
- 閺傛澘顤冪悰灞藉З鎼存挻绁寸拠鏇礉鐟曞棛娲婃潻婊咁伂 JSON 鐎瑰顥?SQLite閵嗕礁銇戠拹銉ょ箽閻ｆ瑦妫惔鎾扁偓浣规￥绾剛绱惍?activity seed閿涙稖鍤滅€规矮绠熼悩鑸碘偓浣圭ゴ鐠囨洝顩惄鏍攽閸斻劑娉﹂幐浣风畽閸栨牓鈧礁鍨归梽銈嗙閻炲棗鎷伴幋鎰喅闁插秴鍟撻妴?

### 娣囶喗鏁?
- 楠炶弓绮堟稊鍫ユ閺堝搫鈧瑩鈧鏁兼稉鍝勭唨娴滃簶鈧粍鏌熼崥?+ 瑜版挸澧犵悰灞藉З闂?+ 闂呮劘妫岄崚妤勩€冮垾婵堟晸閹存劧绱濋張顏勭暔鐟佸懎鍞寸純顔肩氨閺冩湹绻氶悾娆愭绾喕绗呮潪钘夊弳閸欙絽鎷版稉顏冩眽鐞涘苯濮╅崗銉ュ經閵?
- 楠炶弓绮堟稊鍫㈩吀閻炲棝銆夐幒銉ュ弳鐞涘苯濮╅梿鍡欑摣闁鈧礁濮為崗?缁夎鍤悰灞藉З闂嗗棎鈧浇顢戦崝銊╂肠鐎电厧鍙嗙€电厧鍤崪?activity 娑撴挸鐫樼紓鏍帆閺傚洦顢嶉妴?
- 楠炶弓绮堟稊鍫ｎ攽閸斻劏顕涢幆鍛邦嚔娑斿绮犻懣婊嗘皑瀵繆鈧粍娼楅弬?閸掓湹缍旈弬瑙勭《閳ユ繃甯规潻娑楄礋閳ユ粌绱戞慨瀣蒋娴?閹笛嗩攽濮濄儵顎?閸忔娊鏁幓鎰仛閳ユ繐绱濋弫鐗堝祦鐎涙顔岀紒褏鐢绘径宥囨暏 `DailyChoiceOption` 娴犮儵妾锋担搴⒛侀崸妤勨偓锕€鎮庨妴?
- 鐞涘苯濮╅幐鍥у础閸忋儱褰涢崚鍥ㄥ床娑撳搫鍙挎担鎾绘６妫版ɑ膩閸ф绱濈憰鍡欐磰濞夈劍鍓伴崝娑欏彯閺侊絻鈧椒绮堟稊鍫熸閸婃瑥鍤梻銊︽殠濮濄儯鈧椒缍嗛幇蹇撶箶閸旀稑鎯庨崝銊ユ嫲鐞涘苯濮╂潏鍦櫕閵?
- 缁夊娅庨弮褏娈?activity demo seed part 閺傚洣娆㈤敍宀勪缉閸忓秴鍏辨禒鈧稊鍫濆敶缂冾喛顢戦崝銊ф埛缂侇厾鏆€閸︺劎绱拠鎴濆礋閸忓啩鑵戦妴?

### 妞嬪酣娅撻崣妯绘纯
- 妫ｆ牗顐肩€瑰顥婇崜宥呭敶缂冾喛顢戦崝銊よ礋缁岀尨绱濋悽銊﹀煕闂団偓鐟曚礁鍘涙稉瀣祰鐞涘苯濮╂惔鎾村灗閸掓稑缂撴稉顏冩眽鐞涘苯濮╅敍娌€I 瀹告彃婀悩鑸碘偓渚€娼伴弶鍨嫲缁岃櫣濮搁幀浣瑰絹缁€楦跨箹娑撯偓閻愬箍鈧?
- 瑜版挸澧犳潻婊咁伂閺傚洣娆㈢捄顖氱窞閸ュ搫鐣炬稉?`activity_data/daily_choice_activity_library.json`閿涘奔绗傛导?S3 閺冨爼娓剁憰浣风箽閹镐礁鎮撴稉鈧捄顖氱窞閿涘本鍨ㄩ崥搴ｇ敾閸愬秷鐨熼弫?store 閻?`remoteLibraryKey`閵?
- 鐞涘苯濮╁楦款唴閸欘亙缍旀稉鐑樻）鐢瓕顢戦崝銊ュ灲閺傤厼鎷板▔銊﹀壈閸旀稑顦查惄妯诲絹缁€鐚寸礉娑撳秳缍旀稉鍝勫鞍閻ゆぜ鈧礁绺鹃悶鍡樺灗鐎瑰鍙忛崘宕囩摜娓氭繃宓侀妴?

### 妤犲矁鐦?
- `python -X utf8 -m py_compile .\scripts\generate_daily_choice_activity_dataset.py`閿涘牓鈧俺绻冮敍?
- `python -X utf8 .\scripts\generate_daily_choice_activity_dataset.py`閿涘牓鈧俺绻冮敍灞筋嚤閸?48 閺壜ゎ攽閸旑煉绱?
- SQLite `PRAGMA integrity_check = ok`閿涘畭user_version = 1`閿涘本婀侀弫鍫ｎ攽閸?48 閺?
- JSON SHA256 `1E32FBD4937AF940578C6BD0ABEC404895525B6306BBC087A1EC1CA6CED01FA5`
- DB SHA256 `E64DFB24DE244CA350D598F7730DCA43E3E5720ECF47021721E212A22321E022`
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_custom_state_test.dart .\test\daily_choice_activity_library_store_test.dart .\test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_custom_state_test.dart .\test\daily_choice_activity_library_store_test.dart .\test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?5 tests閿?
- `git diff --check`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_085-DECISION-ASSISTANT-GUIDED-REPORT] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閵嗗苯浼愰崗椋庮唸 - 濮ｅ繑妫╅幎澶嬪 - 閸愬磭鐡ラ崝鈺傚閵嗗秴缍嬮崜宥堢箖娴滃海绠掗悶鎰┾偓浣哄闂堫澀绗栭梾鍙ヤ簰閹跺﹥褰欓敍灞界杽闂勫懍濞囬悽銊╂，濡叉稑浜告妯糕偓?
- 閺堫剝鐤嗛崣鍌濃偓?`D:\vocabularySleep-resources\閸愬磭鐡 娑撳绗佹禒钘夊枀缁涙牞绁弬娆欑礉鐏忓棔绱拹銊ュ枀缁涙牕鍙氱憰浣虹閵嗕礁浜稿?閸ｎ亜锛愰幒褍鍩楅妴浣诡洤閻滃洦鐗庨崙鍡楁嫲閹懏娅欓崚鍡樼€介弨鑸垫殐娑撶儤娲块崣顖涙惙娴ｆ粎娈戠粔璇插З缁旑垯姘︽禍鎺嬧偓?

### 閺傛澘顤?
- 閸愬磭鐡ラ崝鈺傚閺傛澘顤冮妴宀勬６缁涙柨绱¤箛顐︹偓鐔峰枀缁涙牓鈧秴鍙嗛崣锝忕窗閺€顖涘瘮婵夘偄鍟撻崘宕囩摜闂傤噣顣介妴浣告彥闁喎鎳￠崥宥嗘煙濡楀牄鈧礁顨滈悽銊ョ埗鐟欏嫭鐦潏?娴ｅ酣顥撻梽鈺佹彥閸?妤傛﹢顥撻梽鈺兦旀俊?娑撳秶鈥樼€规艾鍘涢弻銉ユ磽缁夊秵鍎忔晶鍐暕鐠佷勘鈧?
- 閺傛澘顤冮柅鎰嚋閺傝顢嶉弽鈥冲櫙濞翠胶鈻奸敍姘剁帛鐠併倕褰х仦鏇犮仛閹存劕濮涢悳鍥モ偓浣瑰⒔鐞涘瞼宸奸妴浣规暪閻╁﹤鎷版搴ㄦ珦閸ユ稐閲滄妯哄閸濆秹妫舵０姗堢礉閸欘垱瀵滈棁鈧仦鏇炵磻閹舵洖鍙嗛妴浣稿讲閸ョ偤鈧偓閵嗕焦濡搁幓鈥冲閵嗕礁鎮楅幃鏂挎嫲娣団剝浼呭顔衡偓?
- 閺傛澘顤冮妴宀冩硶濡€崇€烽崘宕囩摜閸掑棙鐎介幎銉ユ啞閵嗗稄绱伴幐澶婂閺夊啫娲滅槐鐘偓浣规埂閺堟稒鏁归惄濞库偓浣戒粓閸氬牊顩ч悳鍥モ偓浣瑰剰閺咁垰鍨庨弸鎰┾偓浣告倵閹柧绗岄張杞扮窗閹存劖婀伴妴浣哥俺缁惧灝鐣ч梻銊ｂ偓浣圭墡閸戝棝顣╁ù瀣嫲闂呭繑婧€濡€崇€烽柅鎰般€嶇拠瀛樻鐠с垹顔嶉妴浣稿瀻瀹割喓鈧線鈧倻鏁ら崷鐑樻珯閵嗕焦瀵氶弽鍥掗柌濠傛嫲妞嬪酣娅撻幓鎰板晪閵?
- 閺傛澘顤?hub smoke 濞村鐦敍宀冾洬閻╂牞绻橀崗?Decision 妞ら潧鎮楅梻顔剧摕濞翠降鈧焦濮ら崨濠囨桨閺夊灝鎷版姗€顥撻梽鈺咁暕鐠佸墽娈戝〒鍙夌厠閵?

### 娣囶喗鏁?
- 閸愬磭鐡ラ崝鈺傚姒涙顓绘＃鏍х潌娴犲骸銇囧▓闈涘棘閺佹媽銆冮弨閫涜礋闂傤喚鐡熷ù?+ 瑜版挸澧犲楦款唴 + 鐠恒劍膩閸ㄥ濮ら崨濠忕幢閸樼喍绡€鐎涙顔岀拠鍕瀻鐞涖劋绗呭▽澶夎礋閵嗗矂鐝痪褑鐦庨崚鍡氥€冮妴宥嗗瘻闂団偓鐏炴洖绱戦敍宀勬娴ｅ骸鎯庨崝銊︾€鍝勬嫲閻劍鍩涢悶鍡毿掗幋鎰拱閵?
- 閺傝顢嶉崥宥囆炴潏鎾冲弳閸忎浇顔忓〒鍛敄楠炲墎鏁卞鏇熸惛閸忔粌绨虫稉鐑樻煙濡?id閿涘矂浼╅崗宥囨暏閹撮攱鏁奸崥宥嗘鐞氼偅妫崐鐓庡繁鐞涘奔绻氶悾娆嶁偓?
- 閹垹顦查張顏呭复閸忋儳娈?activity seed part 閸掑棙鐎介柧鎹愮熅閿涘苯鑻熺€佃婀担璺ㄦ暏閻ㄥ嫭妫棃娆愨偓浣筋攽閸?seed 閸嬫碍鏋冩禒鍓侀獓韫囩晫鏆愰敍灞肩箽鐠?`toolbox_daily_choice` 閻╊喖缍嶉崚鍡樼€介崣顖炩偓姘崇箖閵?
- 娣囶喗顒?activity 濡€虫健閹稿洤宕￠崗銉ュ經閸ョ偤鈧偓娑撹櫣骞囬張?`activityGuideEntries`閿涘矂浼╅崗宥呯穿閻劍婀幒銉у殠閻?guide module 闂冭顢ｉ崚鍡樼€介妴?

### 娣囶喖顦?
- 閹绘劕宕岄崘宕囩摜閸斺晜澧滈梻顔剧摕濞翠焦顒炴銈嗙垼妫版ǜ鈧礁绨崣宄扮獦閺嶅洢鈧浇顕╅弰搴℃健閸滃苯鍞撮懕鏃€褰佺粈鍝勬健閻ㄥ嫭妲戦弳妤€顕В鏃撶礉闁灝鍘ゅù鍛板 accent 娑撳孩绁懗灞炬珯閹恒儴绻庨弮鑸垫瀮鐎涙鐦戦崚顐㈠娑撳秷鍐婚妴?

### 妞嬪酣娅撻崣妯绘纯
- 閸愬磭鐡ラ崝鈺傚閹躲儱鎲℃导姘辩舶閸戠儤膩閸ㄥ缂撶拋顕嗙礉娴ｅ棔绮涢崣顏嗘暏娴滃孩鏆ｉ悶鍡樷偓婵婄熅閿涙盯鐝搴ㄦ珦閸栬崵鏋熼妴浣圭《瀵板鈧浇鍌ㄩ崝鈥冲枀缁涙牔绗夐懗鑺ュΩ閺堫剚膩閸ф缍嬫担婊冨礋娑撯偓娓氭繃宓侀妴?
- 妤傛楠囩拠鍕瀻鐞涖劑绮拋銈嗗閸欑媴绱濋懓浣烘暏閹寸兘娓剁憰浣割樋閻愰€涚濞嗏剝澧犻懗鐣屾箙閸掓澘鐣弫瀵哥叐闂冪绱遍梻顔剧摕濞翠椒鑵戦惃鍕┾偓灞界潔瀵偓鐎瑰本鏆ｉ弽鈥冲櫙閵嗗秴褰茬憰鍡欐磰閸氬奔绔撮幍鐟扮摟濞堢偣鈧?

### 妤犲矁鐦?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_decision_engine_test.dart .\test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_decision_engine_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test .\test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?2 tests閿?
- `git diff --check`閿涘牓鈧俺绻冮敍灞肩矌閹绘劗銇氳ぐ鎾冲瀹搞儰缍旈弽鎴滆厬閼汇儱鍏遍弮銏℃箒閺傚洣娆㈡稉瀣偧鐞?Git 鐟欙妇顫弮?LF 娴兼碍瀵滈柊宥囩枂鏉?CRLF閿?

## [Unreleased-PLAN_083-DAILY-CHOICE-REAL-RECIPE-DATASET] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閳ユ粍鐦￠弮銉ュ枀缁?- 閸氬啩绮堟稊鍫氣偓婵嗙摍濡€虫健閻滅増婀侀弫鐗堝祦娑撳秴褰查悽顭掔礉鐏忋倕鍙鹃崚鏈电稊閺傝纭堕崪灞惧⒔鐞涘本顒炴銈囧繁鐏忔垹婀＄€圭偛褰查幙宥勭稊閹嶇礉闂団偓鐟曚礁鐔€娴滃孩婀伴崷鏉夸粵閼挎粏绁弬娆忔嫲瀵偓濠ф劘褰嶇拫閬嶃€嶉惄顕€鍣稿鍝勫讲娑撳﹣绱?S3 閻ㄥ嫰鐛欑拠浣稿瘶閵?

### 閺傛澘顤?
- 閼挎粏姘ㄩ悽鐔稿灇閸ｃ劍鏌婃晶?`Anduin2017/HowToCook` Markdown 鐟欙絾鐎介敍灞惧瘻閳ユ粌绻€婢跺洤甯弬娆忔嫲瀹搞儱鍙?/ 鐠侊紕鐣?/ 閹垮秳缍?/ 闂勫嫬濮為崘鍛啇閳ユ繃鏆ｉ悶鍡樻綏閺傛瑣鈧椒鍞ら柌蹇嬧偓浣瑰⒔鐞涘本顒炴銈呮嫲閹绘劗銇氶妴?
- 妤犲矁鐦夐崠鍛煀婢?`validation_audit.md`閵嗕梗validation_audit.json`閵嗕梗validation_quality_report.json`閿涘矁顔囪ぐ鏇熸殶閹诡喛顩惄鏍モ偓浣哥摟濞堢敻顥撻梽鈹库偓涓糛Lite 鐎瑰本鏆ｉ幀褍鎷扮拹銊╁櫤閹稿洦鐖ｉ妴?
- 鐎孤ゎ吀閼存碍婀伴弬鏉款杻 `validation_omitted_real_steps.md/json` 鏉堟挸鍤敍灞藉灙閸戣櫣宸辩亸鎴濆讲閹惰棄褰囬惇鐔风杽濮濄儵顎冮惃鍕拱閸︾増鏋冨锝冣偓浣瑰閹?PDF 閸?cook CSV 鐟欏棝顣堕崹瀣蒋閻╊噯绱濋柆鍨帳閻劍膩閺夋寧顒炴銈埶夋鎰┾偓?

### 娣囶喗鏁?
- `YunYouJun/cook` 閻?`recipe.csv` 娑撳秴鍟€姒涙顓婚悽鐔稿灇缂傚搫鐨銉╊€冮惃鍕缁斿褰嶇拫鎲嬬幢閺堫剝鐤嗘禒鍛稊娑撳搫鍘撻弫鐗堝祦閸欏倽鈧喛绱濇稉鍝勫嚒閸栧綊鍘ょ€瑰本鏆ｉ懣婊嗘皑鐞涖儱鍘栭梾鎯у閵嗕礁浼愰崗鏋偓浣规煙濞夋洖鎷?BV 鐎涙顔岄妴?
- 閺堫剙婀?EPUB 閹惰棄褰囬幁銏狀槻閸欏倽鈧啳绁弬娆掝洬閻╂牭绱濋崥灞炬娣囨繄鏆€鐠愩劑鍣洪梻鎼佹，閿涙矮绮庨弨璺虹秿閺夋劖鏋￠崪宀€婀＄€圭偞顒炴銈呮綆閸欘垱濞婇崣鏍畱閺夛紕娲伴敍宀冪箖濠娿倕濮涢弫鍫ｎ嚛閺勫簺鈧胶澧楅弶?Issue 閺傚洦婀伴妴浣界Т闂€鎸庮劄妤犮們鈧焦娼楅弬娆戝繁婢跺崬鎷板銉╊€冪紓鍝勩亼閺夛紕娲伴妴?
- 闁插秵鏌婇悽鐔稿灇 `D:\vocabularySleep-resources\cook_data_plan070_validation`閿涙碍娓剁紒?7,351 閺壜ゅ綅鐠嬫唻绱濋崗鏈佃厬 HowToCook 347 閺壜扳偓浣规拱閸︽媽绁弬?7,004 閺夆槄绱漜ook 閸忓啯鏆熼幑顔煎爱闁?47 閺壜扳偓?

### 妞嬪酣娅撻崣妯绘纯
- 7 娑?EPUB 瑜版挸澧犻張顏呭▕閸欐牕鍩岄崥灞炬閸栧懎鎯堥弶鎰灐閸滃瞼婀＄€圭偞顒炴銈囨畱缂佹挻鐎崠鏍綅鐠嬫唻绱? 娑?PDF 閸?20 妞ゅ灚妫ゅ▔鏇熷▕閸欐牗鏋冮張顒婄礉閻ゆ垳鎶€閹殿偅寮块悧鍫熷灗閸ュ墽澧?PDF閿涙稒婀版潪顔煎灙閸忋儵浠愬蹇斿Г閸涘绱濋崥搴ｇ敾闂団偓 OCR閵嗕椒绗撴い纭呅掗弸鎰灗娴滃搫浼愰弽锟犵崣閸氬骸鍟€閸忋儱绨遍妴?
- `YunYouJun/cook` 娴犲秵婀?558 鐞涘瞼宸辩亸鎴濆讲缁傝崵鍤庢宀冪槈閻ㄥ嫭鏋冪€涙鍩楁担婊勵劄妤犮倧绱濈紒褏鐢婚崣顏冪稊娑撳搫鍘撻弫鐗堝祦閸婃瑩鈧绱濇稉宥囨晸閹存劘娅勯崑鍥劄妤犮們鈧?

### 妤犲矁鐦?
- `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py scripts\audit_daily_choice_recipe_dataset.py`閿涘牓鈧俺绻冮敍?
- 閻㈢喐鍨氭宀冪槈閸栧懎鍩?`D:\vocabularySleep-resources\cook_data_plan070_validation`閿涘牓鈧俺绻冮敍?,351 閺夆槄绱?
- `validation_quality_report.json`閿涙碍娼楅弬娆戔敄閸?0閵嗕焦顒炴銈団敄閸?0閵嗕焦妫ゅ銉╊€冮懣婊嗘皑 0閵嗕浇绉存潻?320 鐎涙顒炴?0閵嗕浇顕╅弰搴㈣杽閺屾挻顒炴?0
- SQLite `PRAGMA integrity_check = ok`閿涘畭user_version = 2`閿涘瓕B SHA256 `3875D2CBBA0A6F40E782331587EF3ECE6C76404F6B5B63806D479B7FF4EDFCBC`

## [Unreleased-PLAN_082-PLACE-MAP-HOT-IP-COARSE] - 2026-04-29

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿鐏?OSM HOT 娴ｆ粈璐熸妯款吇閸︽澘娴樺┃鎰剁礉楠炶埖妲戠涵顔煎従娴犳牕婀撮崶鐐爱闁艾鐖堕棁鈧憰浣告禇闂勫懐缍夌紒婊呭箚婢у啨鈧?
- 閻劍鍩涚敮灞炬箿閸︺劏顔曟径鍥х暰娴?GPS 閺堫亜绱戦崥顖涙閿涘苯绱╃€靛吋澧﹀鈧化鑽ょ埠鐠佸墽鐤嗛妴?
- 閻劍鍩涚敮灞炬箿閺傛澘顤冩稉鈧稉顏冪瑝娓氭繆绂?GPS 閻ㄥ嫭膩缁﹨瀵栭崶鏉戞簚閹碘偓閺屻儴顕楅懗钘夊閿涘奔绮庨柅姘崇箖 IP 缁鏆愭导鎵暬閼煎啫娲块妴?

### 閺傛澘顤?
- 閸涖劏绔熼崷鏉挎禈閺傛澘顤冮妴瀛朠 缁鏆愰懠鍐ㄦ纯閵嗗秵鐓＄拠銏犲弳閸欙綇绱版稉宥堫嚞濮?GPS閿涘矂鈧俺绻冪純鎴犵捕閸戝搫褰?IP 娴兼壆鐣婚崺搴＄缁狙傝厬韫囧啰鍋ｉ敍灞藉晙閹?12km 缁鏆愰懠鍐ㄦ纯閺屻儴顕?OSM 閸︾儤澧嶉妴?
- 閺傛澘顤?IP 缁鐣炬担宥嗘箛閸?`DailyChoiceIpCoarseLocationProvider`閿涘本鏁幐浣叫掗弸?`loc`閵嗕梗lat/lon`閵嗕梗latitude/longitude` 缁涘鐖剁憴浣告綏閺嶅洤鐡у▓鐐光偓?
- 鐠佹儳顦€规矮缍呴張宥呭閺堫亜绱戦崥顖涘灗閺夊啴妾虹悮顐ら兇缂佺喐妗堟稊鍛珕缂佹繃妞傞敍灞借剨閸戦缚顔曠純顔肩穿鐎电》绱濋崣顖濈儲鏉烆剛閮寸紒鐔风暰娴ｅ秷顔曠純顔藉灗 App 鐠佸墽鐤嗘い鐐光偓?

### 娣囶喗鏁?
- 姒涙顓婚崷鏉挎禈濠ф劒绮?OSM France 閸掑洦宕叉稉?OSM HOT閵?
- 閺冄囩帛鐠併倖绨?`carto_voyager` 閸?`osm_france` 闁板秶鐤嗘导姘崇讣缁夎鍩岃ぐ鎾冲姒涙顓?`osm_hot`閵?
- 閸︽澘娴樺┃鎰扳偓澶嬪閸栫儤濯堕崚鍡曡礋姒涙顓诲┃鎰瑢閸忔湹绮径鍥╂暏濠ф劧绱濋獮鎯邦嚛閺勫骸鍙炬禒鏍ь槵閻劍绨柅姘埗闂団偓鐟曚礁娴楅梽鍛秹缂佹粎骞嗘晶鍐︹偓?
- 閸︽澘娴橀悩鑸碘偓浣硅癁鐏炲倹鏌婃晶鐐寸叀鐠囥垺娼靛┃鎰絹缁€鐚寸礉閸栧搫鍨庣拋鎯ь槵鐎规矮缍呮稉?IP 缁鏆愰懠鍐ㄦ纯閵?

### 妞嬪酣娅撻崣妯绘纯
- IP 缁鏆愰懠鍐ㄦ纯閸欘亜寮介弰鐘电秹缂佹粌鍤崣锝嗗灗鏉╂劘鎯€閸熷棗鍤崣锝忕礉閸欘垵鍏樻稉搴ｆ暏閹撮婀＄€圭偘缍呯純顔肩摠閸︺劌鐓勭敮鍌滈獓閸嬪繐妯婇敍娑滅獩缁傜粯甯撴惔蹇庣矌娴ｆ粎鐭栭悾銉ュ棘閼板啨鈧?
- IP 缁鏆愰懠鍐ㄦ纯娓氭繆绂?IPinfo JSON 閹恒儱褰涙稉搴″彆閸?Overpass 閺屻儴顕楅敍娑樻€ョ純鎴欌偓浣峰敩閻?VPN 閹存牕鍙曢崗杈ㄦ箛閸旓紕绠掕箛娆愭娴犲秴褰查懗钘夈亼鐠愩儯鈧?

### 妤犲矁鐦?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_place_map_service_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_place_map_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?0 tests閿?
- `flutter test .\test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?1 tests閿?

## [Unreleased-PLAN_081-PLACE-MAP-RESTRICTED-NETWORK-SOURCES] - 2026-04-28

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯瑜版挸澧犳稉澶夐嚋閸︽澘娴樺┃鎰躬娑擃厼娴楁径褔妾扮粵澶愬劥閸掑棗婀撮崠杞扮瑝閸欘垳鏁ら敍灞界瑖閺堟稒澹橀崚浼存閸掑墎缍夌紒婊€绗呴弴鏉戭啇閺勬捁绻涢柅姘辨畱閺佺増宓佸┃鎰嫙鐠佸彞璐熸妯款吇閿涘本鍨ㄩ惄瀛樺复娴ｈ法鏁?OpenStreetMap閵?

### 閺傛澘顤?
- 閸涖劏绔熼崷鏉挎禈閺傛澘顤?OSM HOT 娑?OpenStreetMap.de 娑撱倓閲?OSM 缁€鎯у隘閻★妇澧栨径鍥╂暏濠ф劑鈧?
- 閸︽澘娴樺┃鎰嚛閺勫孩鏌婃晶?OSM 缁€鎯у隘閸忣剙鍙￠悺锔惧閻ㄥ嫪绻氱€瑰牅濞囬悽銊﹀絹缁€鐚寸窗閹稿顫嬮柌搴″З閹礁濮炴潪濮愨偓浣稿涧缂傛挸鐡ㄩ惇瀣箖閻ㄥ嫮鎽濋悧鍥モ偓渚€浼╅崗宥嗗闁插繘顣╂稉瀣祰閿涘矁绻涢幒銉ょ瑝缁嬪啿鐣鹃弮璺哄讲閸掑洦宕查崗鏈电铂濠ф劑鈧?

### 娣囶喗鏁?
- 姒涙顓婚崷鏉挎禈濠ф劗鏁?CARTO Voyager 閺€閫涜礋 OSM France閿涘奔绮涙担璺ㄦ暏 OpenStreetMap 閺佺増宓佹稉搴ｈ閸氬稄绱濋崷銊╁劥閸掑棗褰堥梽鎰秹缂佹粈绗呮担婊€璐熸导妯哄帥鐏忔繆鐦┃鎰┾偓?
- CARTO Voyager 閺€閫涜礋 `carto_voyager_fallback` 婢跺洨鏁ゅ┃鎰剁幢閺冄呮畱 `carto_voyager` 姒涙顓婚柊宥囩枂娴兼俺绺肩粔璇插煂瑜版挸澧犳妯款吇 OSM France閿涘矂浼╅崗宥堚偓浣烘暏閹撮鎴风紒顓炰粻閻ｆ瑥婀潏鍐╂娑撳秴褰查悽銊ф畱閺冄囩帛鐠併倖绨妴?
- OpenStreetMap 鐎规ɑ鏌熼弽鍥у櫙閻★妇澧栫紒褏鐢绘穱婵堟殌娑撶儤澧滈崝銊ヮ槵閻劍绨敍灞肩瑝閸愬秵鐖ｅ▔銊よ礋閸烆垯绔存径鍥╂暏閵?

### 妞嬪酣娅撻崣妯绘纯
- OSM France / OSM HOT / OpenStreetMap.de 娴犲秵妲哥粈鎯у隘閸忣剙鍙￠悺锔惧鐠у嫭绨敍灞肩瑝閹绘劒绶甸崣顖滄暏閹?SLA閿涙稒婀版潪顕€鈧俺绻冩径姘爱閸掑洦宕查妴浣瑰瘻闂団偓閸旂姾娴囨稉搴㈡拱閸︽壆绱︾€涙﹢妾锋担搴℃€ョ純鎴犳鐏炲繑顩ч悳鍥风礉娴ｅ棙妫ゅ▔鏇氱箽鐠囦焦澧嶉張澶婃勾閸栧搫绻€鏉堜勘鈧?
- 閺嗗倹婀妯款吇閹恒儱鍙嗘径鈺佹勾閸ヤ勘鈧線鐝閿嬪灗閼垫崘顔嗛崷鏉挎禈閻★妇澧栭敍娑滅箹缁粯绨柅姘埗濞戝寮?API Key閵嗕焦宸块弶鍐╂蒋濞嗘儳鎷伴崶钘夊敶閸ф劖鐖ｇ化濠氣偓鍌炲帳閿涘苯鎮楃紒顓烆洤鐟曚焦甯撮崗銉╂付閸楁洜瀚崑姘値鐟欏嫪绗岄崸鎰垼鏉烆剚宕查弬瑙勵攳閵?

### 妤犲矁鐦?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_place_map_service_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_place_map_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test .\test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?1 tests閿?

## [Unreleased-PLAN_080-MAP-LAUNCHER-BUILD-FIX] - 2026-04-28

### 閸樼喎娲?
- 閻劍鍩涢柅姘崇箖 `.\scripts\build.ps1` 閹垫挸瀵?Android 閻喐婧€濞村鐦弮璁圭礉Release 閺嬪嫬缂撻崷?`:app:checkReleaseAarMetadata` 闂冭埖顔屾径杈Е閿涙稒娓堕弬?`url_launcher_android` 娓氭繆绂嗛柧鍙ョ窗瀵洖鍙?`androidx.browser:browser:1.9.0` 娑?`androidx.core:core:1.17.0`閿涘矁顩﹀Ч?Android Gradle Plugin 8.9.1+閿涘矁鈧苯缍嬮崜宥夈€嶉惄顔荤矝娴ｈ法鏁?AGP 8.7.3閵?

### 娣囶喗鏁?
- 娣囨繃瀵?`url_launcher_android` 閺勬儳绱＄痪锔芥将閸?`6.3.17`閿涘矂浼╅崗宥埿掗弸鎰煂瀵洖鍙嗛弴鎾彯 AndroidX 閸忓啯鏆熼幑顔款洣濮瑰倻娈?`6.3.29`閵?
- 鐞涖儱鍘栭獮鑸垫暪鐏?`PLAN_080_閸︽澘娴橀幏澶庢崳娓氭繆绂嗛弸鍕紦娣囶喖顦?md`閿涘矁顔囪ぐ鏇熸拱鏉烆喗鐎鍝勫悑鐎瑰湱鐡ラ悾銉ｂ偓?

### 妞嬪酣娅撻崣妯绘纯
- 鐠囥儳瀹抽弶鐔告Ц閸忕厧顔?AGP 8.7.3 閻ㄥ嫪澶嶉弮鑸电€杞扮箽閹躲倧绱遍張顏呮降閸楀洨楠囬崚?AGP 8.9.1+ 閸氬函绱濋崣顖欎簰闁插秵鏌婄拠鍕強閺勵垰鎯侀弨鎯х磻 `url_launcher_android` 閸掔増娓堕弬鎵閵?

### 妤犲矁鐦?
- `flutter pub get`閿涘牓鈧俺绻冮敍宀冃掗弸鎰煂 `url_launcher_android 6.3.17`閿?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_place_map_service_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_place_map_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `.\scripts\build.ps1 -Target android-apk`閿涘牓鈧俺绻冮敍宀€鏁撻幋?`build\app\outputs\flutter-apk\app-release.apk` 楠炶泛顦查崚璺哄煂 `dist\android-apk\xianyushengxi.apk`閿?

## [Unreleased-PLAN_079-PLACE-MAP-INTERACTION-FIX] - 2026-04-28

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閸涖劏绔熼崷鏉挎禈閻ㄥ嫬鍙忕仦蹇斿瘻闁筋喕绱扮悮顐㈡噯鏉堢懓婧€閹碘偓缂佺喕顓告穱鈩冧紖闁喗灏呴敍灞界瑖閺堟稑顤冮崝鐘茬唨娴滃骸鎳嗘潏鐟版簚閹碘偓閻ㄥ嫰娈㈤張鍝勬勾閻愮懓濮涢懗鏂ょ礉楠炴儼藟閸忓懏濯虹挧椋庢暏閹寸柉顔曟径鍥ф勾閸ユ崘钂嬫禒鍓佹畱閸忋儱褰涢敍灞芥倱閺冭埖鏁归崣锝呯暰娴ｅ秵鐓＄拠銏ｎ嚛閺勫簼鑵戦惃鍕劆娑斿銆冩潻鑸偓?

### 閺傛澘顤?
- 閸涖劏绔熼崷鏉挎禈缂佹挻鐏夐崠鐑樻煀婢х偑鈧矂娈㈤張鍝勬噯鏉堢懓婀撮悙骞库偓宥嗗瘻闁筋噯绱濋崣顖欑矤瑜版挸澧犵粵娑⑩偓澶婃倵閻ㄥ嫬鎳嗘潏鐟版簚閹碘偓娑擃參娈㈤張楦夸粵閻掞缚绔存稉顏勬勾閻愬箍鈧?
- 閸涖劏绔熼崷鐑樺閸掓銆冮弬鏉款杻閵嗗本澧﹀鈧崷鏉挎禈 App閵嗗秴娴橀弽鍥ㄥ瘻闁筋噯绱濇导妯哄帥鐏忔繆鐦拋鎯ь槵閸樼喓鏁?`geo:` 閸︽澘娴橀崡蹇氼唴閿涘苯銇戠拹銉︽娴ｈ法鏁?Apple Maps 娑?OpenStreetMap 缂冩垿銆夐柧鐐复閸忔粌绨抽妴?
- 閺傛澘顤?`url_launcher` 娓氭繆绂嗛敍宀€鏁ゆ禍搴㈠鐠х柉顔曟径鍥ф勾閸ユ崘钂嬫禒鑸靛灗婢舵牠鍎撮崷鏉挎禈缂冩垿銆夐妴?

### 娣囶喗鏁?
- 鐏忓棗婀撮崶鎯у弿鐏炲繑瀵滈柦顔荤矤閸欏厖鏅剁痪闈涙倻閹貉冨煑缂佸嫭濯堕崚鏉夸箯娑撳﹨顫楅敍宀勪缉閸忓秳绗屾惔鏇㈠劥缂佺喕顓稿ù顔肩湴閸︺劌鐨崷鏉挎禈妤傛ê瀹虫稉顓濈鞍閻╂悂浼勯幐掳鈧?
- 闂呮劗顫嗘稉搴㈢叀鐠囥垼顕╅弰搴″箵閹哄鈧粌褰傞柅浣虹舶閸︽澘娴樺┃鎰ㄢ偓婵堟畱濮澭傜疅鐞涖劏鍫敍灞炬暭娑撻缚顕╅弰?App 娑撳秶绮℃稉顓㈡？閺堝秴濮熼崳銊︽暪闂嗗棙鍨ㄩ悾娆忕摠鐎规矮缍呴敍灞藉涧閸︺劎鏁ら幋椋庡仯閸戠粯妞傞悽杈啎婢跺洦瀵滈棁鈧弻銉嚄閵?

### 妞嬪酣娅撻崣妯绘纯
- 娑撳秴鎮撶拋鎯ь槵閸滃矂绮拋銈呮勾閸?App 鐎?`geo:` 閸楀繗顔呴弨顖涘瘮娑撳秴鎮撻敍娑樼秼閸撳秴鐤勯悳鐗堝絹娓氭稑顦跨痪?URI 閸忔粌绨抽敍灞借嫙閸︺劌鍙忛柈銊ャ亼鐠愩儲妞傜紒娆忓毉闁挎瑨顕ら幓鎰仛閵?

### 妤犲矁鐦?
- `flutter pub get`閿涘牓鈧俺绻冮敍?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_place_map_service_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_place_map_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test .\test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?1 tests閿?

## [Unreleased-PLAN_078-PLACE-MAP-UX-RESOURCES] - 2026-04-28

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閵嗗本鐦￠弮銉ュ枀缁?- 閸樿鎽㈤崕?- 閸涖劏绔熼崷鏉挎禈閵嗗秳绮涢崓蹇旀付鐏?demo閿涘奔绗?`flutter_map` 閻╁瓨甯寸拋鍧楁６ `tile.openstreetmap.org` 閺冭泛鍤悳鏉垮彆閸忚京鎽濋悧鍥ㄧ爱鐠€锕€鎲￠崪宀冪Т閺冭绱濋棁鈧憰浣瑰腹鏉╂稑鍩岄弴瀛樺复鏉╂垵褰查拃钘夋勾閻ㄥ嫬婀撮崶鍙ョ秼妤犲被鈧?

### 閺傛澘顤?
- 閸涖劏绔熼崷鏉挎禈閺傛澘顤冮崣顖氬瀼閹广垹婀撮崶鐐爱閿涘矂绮拋銈嗘暭娑?CARTO Voyager閿涘奔绻氶悾?CARTO Light 娑?OSM Standard 婢跺洨鏁ゅ┃鎰剁礉楠炶泛婀?UI 娑擃厽鐖ｅ▔銊ュ彆閸?OSM 閻★妇澧栧┃鎰邦棑闂勨斂鈧?
- 閺傛澘顤冮崷鏉挎禈閻★妇澧栭幐澶愭付閸斻劍鈧礁濮炴潪鎴掔瑢閺堫剙婀寸紓鎾崇摠缁狅紕鎮婇敍姘辩处鐎涙ê绱戦崗鐐解偓浣虹处鐎涙ê銇囩亸蹇撶潔缁€鎭掆偓浣圭缁岃櫣绱︾€涙ê鍙嗛崣锝呮嫲缂傛挸鐡ㄧ挧鍕爱鐠囧瓨妲戦妴?
- 閺傛澘顤冮崷鏉挎禈娴溿倓绨伴敍姘杹婢堆佲偓浣虹級鐏忓繈鈧浇鍒涢崥鍫㈢波閺嬫嚎鈧礁娲栭崚鏉跨暰娴ｅ秳鑵戣箛鍐︹偓浣稿弿鐏炲繑鐓￠惇瀣ㄢ偓浣圭叀鐠囥垹宕愬鍕箑閵嗕胶鎽濋悧鍥у鏉炰粙鏁婄拠顖涱偧閺佺増褰佺粈鍝勬嫲閸︽壆鍋ｉ弽鍥唶闁鑵戦幀浣碘偓?
- 閺傛澘顤冮崷鏉挎禈缂佹挻鐏夋稉搴＄秼閸撳秲鈧苯骞撻崫顏勫姽閵嗗秷绐涚粋?閸︾儤娅欑粵娑⑩偓澶庝粓閸旑煉绱濋弨顖涘瘮閸欘亞婀呰ぐ鎾冲缁涙盯鈧灏柊宥囩波閺嬫粍鍨ㄩ弻銉ф箙閸忋劑鍎撮崨銊ㄧ珶缂佹挻鐏夐妴?

### 娣囶喗鏁?
- `DailyChoicePlaceMapSettings` 閹碘晛鐫嶉幐浣风畽閸栨牕婀撮崶鐐爱閵嗕胶鎽濋悧鍥╃处鐎涙ê绱戦崗鍐叉嫲閼奉亜濮╃拹鏉戞値缂佹挻鐏夊鈧崗绛圭礉閺冄囧帳缂冾喛顕伴崣鏍ㄦ閼奉亜濮╃悰銉╃秷姒涙顓婚崐绗衡偓?
- 閸涖劏绔熼崷鏉挎禈妫板嫯顫嶉柌宥嗙€稉鍝勫讲婢跺秶鏁ら崷鏉挎禈閻㈣绔烽敍灞煎瘜妞ょ敻娼伴崪灞藉弿鐏炲繘銆夐崗杈╂暏閸氬奔绔存總妤冩憹閻楀洢鈧焦鐖ｇ拋鑸偓浣瑰付閸掕埖瀵滈柦顔兼嫲閻樿埖鈧礁寮芥＃鍫涒偓?
- 閸涖劏绔熼崷鐑樺閸掓銆冮弨顖涘瘮閻愮懓鍤懕姘卞妽閸︽澘娴橀弽鍥唶閿涘苯鑻熼弰鍓с仛瑜版挸澧犵粵娑⑩偓澶岀波閺嬫粍鏆熸稉搴⑩偓鑽ょ波閺嬫粍鏆熼妴?

### 娣囶喖顦?
- 娣囶喖顦叉妯款吇閸︽澘娴橀悺锔惧濠ф劗娲块幒銉ゅ▏閻?`tile.openstreetmap.org` 鐎佃壈鍤ч惃?`flutter_map` OSM 閸忣剙鍙￠悺锔惧鐠€锕€鎲℃稉搴ょ窛妤傛绉撮弮鍫曨棑闂勨斂鈧?
- 闂勫秳缍嗛崷鏉挎禈閹锋牕濮?缂傗晜鏂侀弮鍓佹畱妫版繂顦婚悺锔惧鐠囬攱鐪伴柌蹇ョ礉閸氼垳鏁ゆ潻鍥ㄦ埂鐠囬攱鐪版稉顓燁剾閵嗕椒缍嗙紓鎾冲暱閸滃苯褰插〒鍛倞缂傛挸鐡ㄩ妴?

### 妞嬪酣娅撻崣妯绘纯
- CARTO 閻★妇澧栨禒宥勭贩鐠ф牕婀痪璺儑娑撳鏌熼崷鏉挎禈閺堝秴濮熼敍灞芥€ョ純鎴炲灗閺堝秴濮熸稉宥呭讲鏉堢偓妞傞崣顖濆厴閸戣櫣骞囬悺锔惧缁岃櫣娅ч敍娌€I 娴兼碍妯夌粈铏规憹閻楀洭鍣哥拠鏇☆吀閺佸府绱濋獮璺哄讲閸掑洦宕叉径鍥╂暏濠ф劑鈧?
- 閺堫剝鐤嗘稉宥呬粵閸栧搫鐓欓幍褰掑櫤娑撳娴囬敍宀勪缉閸忓秷绻氶崣宥呭彆閸忚京鎽濋悧鍥ㄦ箛閸旓紕鐡ラ悾銉ユ嫲閹碘晛銇囧ù渚€鍣烘搴ㄦ珦閿涙稑缍嬮崜宥呯杽閻滄澘褰х紓鎾崇摠閻劍鍩涚€圭偤妾弻銉ф箙鏉╁洨娈戦悺锔惧閵?

### 妤犲矁鐦?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_place_map_service_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_place_map_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test .\test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?1 tests閿?
- `git diff --check`閿涘牓鈧俺绻冮敍灞肩矌閹绘劗銇?`changelogs/CHANGELOG.md` 閸︺劌缍嬮崜?Git 闁板秶鐤嗘稉瀣╃瑓濞喡ば曠喊棰佺窗娴?LF 鏉烆兛璐?CRLF閿?

## [Unreleased-PLAN_077-PLACE-GPS-OSM-MAP] - 2026-04-28

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿鐏忓棗浼愰崗椋庮唸閵嗗本鐦￠弮銉ュ枀缁?- 閸樿鎽㈤崕瑁も偓宥呬粵瀵版娲挎稉鎾茬瑹鐎圭偟鏁ら敍姘稊娑撳搫褰查柅澶嬪⒖鐏炴洘甯撮崗?GPS 娑?OpenStreetMap 閸涖劏绔熼崷鏉挎禈娣団剝浼呴敍灞芥躬鐠囧瓨妲戠拠锔剧矎 GPS 閻劑鈧柨鎷伴梾鎰潌鏉堝湱鏅崥搴ｆ暠閻劍鍩涢崥灞惧壈閸氼垳鏁ら敍灞借嫙閺€顖涘瘮閹跺﹤婀撮崶鍙ヨ厬閻ㄥ嫮婀＄€圭偛婧€閹碘偓閸旂姴鍙嗛悽銊﹀煕閼奉亜绻侀惃鍕簚閹碘偓濞撳懎宕熼妴?

### 閺傛澘顤?
- 閺傛澘顤?`DailyChoicePlaceMapSettings`閿涘本瀵旀稊鍛閵嗗苯鎳嗘潏鐟版勾閸ヤ勘鈧秴鎮撻幇蹇曞Ц閹降鈧焦膩缁﹣缍呯純顔肩磻閸忓啿鎷伴弻銉嚄閸楀﹤绶為敍娑㈢帛鐠併倕鍙ч梻顓濈瑬姒涙顓绘担璺ㄦ暏濡紕纭︽担宥囩枂閵?
- 閺傛澘顤?`DailyChoicePlaceMapService` 閼宠棄濮忛敍姘愁啎婢跺洤澧犻崣鏉跨暰娴ｅ秷顕伴崣鏍モ偓浣哄 500 缁磭缍夐弽鍏寄佺化濠佺秴缂冾喓鈧副verpass 閸楀﹤绶為弻銉嚄閵嗕副SM 閸︾儤澧嶇憴锝嗙€介妴浣界獩缁傛槒顓哥粻妤€鎷伴崷鐑樺鏉?`DailyChoiceOption`閵?
- 閺傛澘顤冮妴灞藉箵閸濐亜鍔归妴宥呮噯鏉堢懓婀撮崶楣冩桨閺夊尅绱伴梾鎰潌鐠囧瓨妲戞稉搴℃倱閹板繐鎯庨悽銊ｂ偓浣鼓佺化?缁墽鈥樼€规矮缍呴崚鍥ㄥ床閵?00m-5km 閸楀﹤绶為柅澶嬪閵嗕礁婀痪?OSM 閸︽澘娴樻０鍕潔閵嗕礁鎳嗘潏鐟版簚閹碘偓閸掓銆冮崪灞肩闁款喕绻氱€涙ê鍩岄張顒佹簚閸︾儤澧嶅〒鍛礋閵?
- 閺傛澘顤?Android 閸撳秴褰寸€规矮缍呴弶鍐婢圭増妲戦敍灞借嫙閸旂姴鍙?`geolocator`閵嗕梗flutter_map`閵嗕梗latlong2` 娓氭繆绂嗛妴?
- 閺傛澘顤冮崷鏉挎禈閺堝秴濮熼崡鏇熺ゴ閿涘矁顩惄鏍佺化濠傜暰娴ｅ秲鈧副verpass 閺屻儴顕楅弸鍕紦娑撳氦袙閺嬫劑鈧副SM 閸︾儤澧嶆穱婵嗙摠濡€崇€烽崪宀冾啎缂冾喗瀵旀稊鍛閵?

### 娣囶喗鏁?
- 閵嗗苯骞撻崫顏勫姽閵嗗秵膩閸ф婀崘鍛枂閸︽壆鍋ｆ惔鎾茬瑢闂呭繑婧€闂堛垺婢樻稊瀣？婢х偛濮為幎妯哄綌瀵繐鎳嗘潏鐟版勾閸ョ偓澧跨仦鏇礉娑撳秵灏嬮崢瀣帛鐠併倝娈㈤張杞扮秼妤犲被鈧?
- 娣囨繂鐡ㄩ惃?OSM 閸︾儤澧嶆担婊€璐熼悽銊﹀煕閼奉亜鐣炬稊?`go` 閺夛紕娲伴崣鍌欑瑢閻滅増婀侀梾蹇旀簚娑撳海顓搁悶鍡樼ウ缁嬪绱濋獮鏈电箽閻?OSM 閺夛紕娲板鏇犳暏閵嗕礁婀撮崶鐐偝缁便垼鐦濋妴浣告簚閺咁垰鍨庣猾姹団偓浣界獩缁傝鐪扮痪褍鎷伴張顒€婀寸紓鏍帆閼宠棄濮忛妴?
- 闂呮劗顫嗛弬鍥攳閺勫海鈥橀敍姘叀鐠囶澀绱伴幎濠冩拱濞嗏剝鐓＄拠顫厬韫囧啫鎷伴崡濠傜窞閸欐垿鈧胶绮?OpenStreetMap/Overpass閿涙稒婀?App 娑撳秵鏁归梿鍡愨偓浣风瑝娑撳﹣绱堕崚鎷屽殰閺堝婀囬崝掳鈧椒绗夐崙鍝勬暛鐎规矮缍呴弫鐗堝祦閿涘奔绻氱€涙ê婧€閹碘偓閺冩湹绗夋穱婵嗙摠閻劍鍩?GPS 閸ф劖鐖ｉ妴?

### 娣囶喖顦?
- 闁灝鍘ょ亸鍡忊偓婊勫瘻閸栧搫鐓欐稉瀣祰閸︽澘娴橀悺锔惧閳ユ繀缍旀稉娲帛鐠併倖鏌熷鍫ｆ儰閸﹀府绱濋弨閫涜礋闁潧鎯?OSM 閸忣剙鍙￠張宥呭鏉堝湱鏅惃鍕瘻闂団偓閸︺劎鍤庨弻銉嚄閸滃奔姘︽禍鎺戠础閸︽澘娴橀弻銉ф箙閵?

### 妞嬪酣娅撻崣妯绘纯
- 閸涖劏绔熼崷鐑樺閺屻儴顕楁笟婵婄閸忣剙鍙?Overpass 閺堝秴濮熼崪?OSM 缁€鎯у隘閺佺増宓侀敍灞藉讲閼宠棄娲滈崷鏉垮隘閵嗕胶缍夌紒婊勫灗閺堝秴濮熺换浣哥箹鐎佃壈鍤х紒鎾寸亯娑撳秴鐣弫杈剧幢UI 娴兼碍褰佺粈鐑樺⒖婢堆嗗瘱閸ュ瓨鍨ㄧ粙宥呮倵闁插秷鐦妴?
- 娴ｈ法鏁ょ划鍓р€樼€规矮缍呴弮璁圭礉閺屻儴顕楁稉顓炵妇娴兼艾褰傞柅浣虹舶 OpenStreetMap/Overpass閿涙盯绮拋銈勭矝娴ｈ法鏁ゅΟ锛勭ˇ娴ｅ秶鐤嗛敍灞借嫙閻㈣京鏁ら幋铚傚瘜閸斻劌鍨忛幑顫偓?

### 妤犲矁鐦?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_place_map_service_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_place_map_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?
- `flutter test .\test\daily_choice_place_seed_test.dart .\test\daily_choice_place_map_service_test.dart .\test\daily_choice_custom_state_test.dart .\test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?8 tests閿?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_place_seed_test.dart .\test\daily_choice_place_map_service_test.dart .\test\daily_choice_custom_state_test.dart .\test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?

## [Unreleased-PLAN_076-PLACE-DATA-IMPORT] - 2026-04-28

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴娴兼ê瀵查獮璺虹暚閸犲嫬浼愰崗椋庮唸閵嗗本鐦￠弮銉ュ枀缁?- 閸樿鎽㈤崕瑁も偓宥喣侀崸妤嬬礉鐏忓棛娲伴惃鍕勾閺佺増宓侀崗銊╁劥閺€閫涜礋閺佺増宓佺€电厧鍙嗛崝鐘烘祰閿涘奔绗夐崘宥呮躬 App 娴狅絿鐖滄稉顓犫€栫紓鏍垳閻╊喚娈戦崷鐗堟蒋閻╊噯绱濋獮鍓佹晸閹存劖娲跨€瑰本鏆ｉ惃鍕殶閹诡噣娉︾€电厧鍤崚?`D:\vocabularySleep-resources\閸樿鎽㈤崕?閺佺増宓乣閵?

### 閺傛澘顤?
- 閺傛澘顤?`DailyChoicePlaceLibraryStore`閿涘本鏁幐浣稿箵閸濐亜鍔归崘鍛枂閸︽壆鍋ｆ惔鎾跺Ц閹焦顥呴弻銉ｂ偓涓ON 娑撳娴囩€电厧鍙嗛妴浣规拱閸?SQLite 鐎瑰顥婇妴浣规喅鐟曚浇顕伴崣鏍モ偓浣虹摣闁鐓＄拠銏犳嫲鐠囷附鍎忕拠璇插絿閵?
- 閺傛澘顤?`scripts/generate_daily_choice_place_dataset.py`閿涘瞼鏁撻幋鎰箵閸濐亜鍔归惄顔炬畱閸︾増鏌熼崥鎴濈氨 JSON閵嗕讣QLite閵嗕梗FORMAT.md` 閸?`GENERATION_SUMMARY.md`閵?
- 閺傛澘顤?Store 鐎电厧鍙嗛柧鎹愮熅閸楁洘绁撮敍宀冾洬閻╂牗婀伴崷?JSON 鐎瑰顥婇妴涓糛Lite 閹芥顩?鐠囷附鍎忕拠璇插絿閵嗕胶鐡柅澶嬬叀鐠囥垹鎷伴棃娆愨偓?seed 鏉╀胶些鏉堝湱鏅妴?

### 娣囶喗鏁?
- 閸樿鎽㈤崕鎸幠侀崸妤€鈧瑩鈧鐫滈弨閫涜礋娴?`DailyChoicePlaceLibraryStore` 閸旂姾娴囬敍娑㈡饯閹?`daily_choice_place_seed.dart` 娑撳秴鍟€閹绘劒绶?`go` 閻╊喚娈戦崷?option閵?
- 閸樿鎽㈤崕鍧椼€夐棃銏℃煀婢х偛婀撮悙鐟扮氨閻樿埖鈧線娼伴弶鍨嫲娑撳娴囬崗銉ュ經閿涘苯鑻熼崷銊嚊閹懌鈧胶顓搁悶鍡涖€夐弻銉ф箙閵嗕礁鍞寸純顕€銆嶇拫鍐╂殻閵嗕礁褰熺€涙ü璐熼懛顏勭暰娑斿妞傞幐澶愭付鐟欙絾鐎界€瑰本鏆ｇ拠锔藉剰閵?
- 閺佺増宓侀梿鍡樺⒖閸忓懍璐?3 娑擃亣绐涚粋璇茬湴缁?鑴?15 娑擃亜婧€閺?鑴?8 娑擃亞娲伴惃鍕勾缁鐎?鑴?2 閺壜ょ熅缁捐儻顫楁惔锔肩礉閸?720 閺夆槄绱卞В蹇旀蒋閸栧懎鎯堥崷鏉挎禈閹兼粎鍌ㄧ拠宥冣偓浣规闂€瑁も偓渚€顣╃粻妞尖偓浣告倱鐞涘苯缂撶拋顔衡偓浣诡梾閺屻儲顒炴銈冣偓浣割吇閸愬懎顦绘稉搴㈢垼缁涙儳鐫橀幀褋鈧?

### 娣囶喖顦?
- 娣囶喖顦查弮褍顕遍崙楦垮壖閺堫兛绮涙笟婵婄闂堟瑦鈧?`go` seed 閻ㄥ嫰妫舵０姗堢礉閺€鍦暠閻欘剛鐝涢悽鐔稿灇閼存碍婀扮紒鐔剁鐎电厧鍤挧鍕爱閵?
- 娣囶喖顦查崷鎵仯鎼存挸鐣ㄧ憗鍛ウ缁嬪鑵戦崥灞绢劄婢惰精瑙﹂崣顖濆厴閹绘劕澧犻崚鐘绘珟閺冦垺婀侀張顒€婀存惔鎾舵畱妞嬪酣娅撻敍灞炬暭娑撹桨澶嶉弮璺虹氨閺嬪嫬缂撻幋鎰閸氬骸鍟€閺囨寧宕插锝呯础鎼存挶鈧?
- 娣囶喖顦查悽鐔稿灇閺佺増宓佹稉顓＄窡閸斺晛婧€閺?id 閹稿洤鎮滄稉宥呯摠閸︺劎鐡柅澶愩€嶉惃鍕６妫版﹫绱濋獮璺哄閸忋儳鏁撻幋鎰墡妤犲被鈧?

### 妞嬪酣娅撻崣妯绘纯
- 妫ｆ牗顐兼潻娑樺弳閸樿鎽㈤崕澶哥瑬閺堫亜鐣ㄧ憗鍛勾閻愮懓绨遍弮璁圭礉閸愬懐鐤嗛崐娆撯偓澶嬬潨娑撹櫣鈹栭敍娑€夐棃顫箽閻ｆ瑤绗呮潪钘夊弳閸欙絽鎷伴懛顏勭暰娑斿婀撮悙鍦吀閻炲棗鍙嗛崣锝冣偓?
- 閻㈢喐鍨氶弫鐗堝祦閺勵垶鈧氨鏁ら惄顔炬畱閸︽壆琚崹瀣嫲閸︽澘娴橀幖婊呭偍閺傜懓鎮滈敍灞肩瑝閺勵垰娴愮€规氨婀＄€?POI閿涙稓鏁ら幋铚傜矝闂団偓缂佹挸鎮庨幍鈧崷銊ョ厔鐢倶鈧礁銇夊鏂烩偓浣芥儉娑撴碍妞傞梻鏉戞嫲鏉╂梻鈻肩粣妤€褰涢拃钘夋勾閵?

### 妤犲矁鐦?
- `python -X utf8 -m py_compile .\scripts\generate_daily_choice_place_dataset.py`閿涘牓鈧俺绻冮敍?
- `python -X utf8 .\scripts\generate_daily_choice_place_dataset.py`閿涘牓鈧俺绻冮敍灞筋嚤閸?720 閺夆槄绱?
- JSON / SQLite 娴滃本顐奸弽锟犵崣閿涙SON 720 閺壜扳偓涓糛Lite active 720 閺壜扳偓涔RAGMA integrity_check = ok`閵嗕焦娼靛┃鎰摟濞堝灚鏆熼柌?0閿涘牓鈧俺绻冮敍?
- `dart analyze .\lib\src\ui\pages\toolbox_daily_choice .\test\daily_choice_place_seed_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test .\test\daily_choice_place_seed_test.dart --reporter compact`閿涘牓鈧俺绻冮敍? tests閿?

## [Unreleased-PLAN_075-WEAR-REVIEW-CLEANUP] - 2026-04-28

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴鐎电懓浼愰崗椋庮唸閵嗗本鐦￠弮銉ュ枀缁?- 缁屽じ绮堟稊鍫涒偓宥呭晙閸嬫矮绔存潪顔碱吀閺屻儱鎷板〒鍛倞娴兼ê瀵查敍灞界毈闂傤噣顣介惄瀛樺复娣囶喗鏁奸敍娑滃閺冪姴銇囬梻顕€顣介崚娆愬絹娴溿倕鑻熼幒銊┾偓浣碘偓?

### 娣囶喗鏁?
- 缁屽じ绮堟稊鍫濄亯濮樻柨缂撶拋顔惧箛閸︺劋绱版径宥囨暏瀹稿弶婀侀崥顖氬З婢垛晜鐨甸幓鎰板晪韫囶偆鍙庨敍娑樺祮娴ｅ灝鍙忕仦鈧径鈺傜毜濮掑倽顫嶅鈧崗铏弓瀵偓閸氼垽绱濋崣顏囶洣閸氼垰濮╅幓鎰板晪瀹歌尪顕伴崣鏍у煂婢垛晜鐨甸敍灞肩瘍娴兼氨鏁ゆ禍搴㈠腹閼芥劖鐨靛〒鈺傘€傛担宥冣偓?
- 鐞涳絾鐓栭梿鍡楁値瑜版帊绔撮崠鏍у涧閸︺劎鈹涙禒鈧稊鍫ユ肠閸氬牅鑵戦崚閿嬫煀閸愬懐鐤嗛崣鍌濃偓鍐╃垼妫版﹫绱濋崥鍐х矆娑斿牓娉﹂崥鍫滅瑝閸愬秷顕ら弻銉р敍娴犫偓娑斿牆鍞寸純顕€娉﹂崥鍫涒偓?

### 娣囶喖顦?
- 娣囶喖顦查崥顖氬З婢垛晜鐨甸幓鎰板晪瀹告彃褰囧妤€銇夊鏂挎彥閻撗勬閿涘瞼鈹涙禒鈧稊鍫滅矝閸欘垵鍏橀幓鎰仛婢垛晜鐨甸張顏勬儙閻劊鈧焦妫ゅ▔鏇犵舶閸戠儤鐨靛〒鈺佺紦鐠侇喚娈戦梻顕€顣介妴?
- 娣囶喖顦茬粚澶哥矆娑斿牆鍞寸純顕€娉﹂崥鍫熸＋閺嶅洭顣介崣顖濆厴閺冪姵纭堕崷銊╃帛鐠併倝娉﹂崥鍫濈秺娑撯偓閸栨牠妯佸▓鍨暪閺佹稐璐熼妴宀勨偓姘珶 / 閺冦儱鐖?/ 濮濓絽绱￠妴宥囩搼閻厽鐖ｆ０妯兼畱闂傤噣顣介妴?

### 妞嬪酣娅撻崣妯绘纯
- 閼汇儳鏁ら幋宄板彠闂傤厼鍙忕仦鈧径鈺傜毜濮掑倽顫嶆担鍡楁儙閸斻劌銇夊鏃€褰侀柋鎺撳絹娓氭稐绨¤箛顐ゅ弾閿涘瞼鈹涙禒鈧稊鍫滅窗娴ｈ法鏁ょ拠銉ユ彥閻撗呮晸閹存劕缂撶拋顕嗙幢濞屸剝婀佽箛顐ゅ弾閺冩湹绮涙妯款吇閺屻儳婀呴崗銊╁劥濮樻梹淇妴?

### 妤犲矁鐦?
- `flutter test test\daily_choice_wear_seed_test.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_wear_seed_test.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `git diff --check`閿涘牓鈧俺绻冮敍灞肩矌閺?changelog 閹广垼顢戦幓鎰仛閿?
- `flutter analyze`閿涘牊婀柅姘崇箖閿涘奔绮涙稉鐑樻＆閺堝娼В蹇旀）閸愬磭鐡ラ梻顕€顣介敍娑欐拱鏉烆喚鈹涙禒鈧稊鍫㈡祲閸忚櫕鏋冩禒鑸垫￥閺傛澘顤冮崚鍡樼€介梻顕€顣介敍?

## [Unreleased-PLAN_074-WEAR-ADVISOR-LAYOUT-FIX] - 2026-04-28

### 閸樼喎娲?
- 閻劍鍩涢柅姘崇箖閹搭亜娴橀崣宥夘洯閵嗗瞼鈹涙禒鈧稊鍫涒偓宥堢槑娴兼澘缂撶拋顕€銆夌粵鎯ф躬缁夎濮╃粩顖氱潔瀵偓閸氬酣浼勯幐锛勨敍閹碱厼寮懓鍐ㄧ氨閵嗕椒绗呮潪鑺ュ瘻闁筋喓鈧焦鐨靛〒鈺冪摣闁鎷板锝嗘瀮閸愬懎顔愰敍灞炬暪鐠ч攱妞傛稊鐔剁窗閸樺鍩岄崡锛勫閸欏厖鏅堕悩鑸碘偓浣稿隘閸╃喆鈧?

### 娣囶喗鏁?
- 鐏忓棛鈹涙禒鈧稊鍫ｇ槑娴兼澘缂撶拋顔荤矤 `Stack + Positioned` 閹剚璇為幎钘夌溄閺€閫涜礋濮濓絽鐖堕弬鍥ㄣ€傚ù渚€鍣烽惃鍕閸欑姴宕遍悧鍥モ偓?
- 姒涙顓婚弨鎯版崳閺冭埖妯夌粈铏规彛閸戞垯鈧矁鐦庢导鏉跨紦鐠侇喓鈧秴鍙嗛崣锝忕礉鐏炴洖绱戦崥搴濈箽閻ｆ瑨鐦庢导鑸偓渚€顤侀懝灞傗偓浣哥湴缁狙佲偓浣告簚閺咁垰娲撶猾璇蹭紣閸忓嘲鍞寸€圭櫢绱濋獮鎯邦唨閸氬海鐢婚崘鍛啇閼奉亞鍔ф稉瀣╅妴?

### 娣囶喖顦?
- 娣囶喖顦茬拠鍕強瀵ら缚顔呴崷銊╅崝銊ь伂娑撳海鈹涢幖顓炲棘閼板啫绨遍妴浣圭毜濞撯晝鐡柅澶堚偓浣界槑娴兼澘鍞寸€圭鍤滈煬顐㈠絺閻㈢喖鍣搁崣鐘垫畱闂傤噣顣介妴?
- 娣囶喖顦查弨鎯版崳閹礁褰告笟褏鐝崥鎴︺€夌粵楣冧紕閹嘎扳偓灞界毣閺堫亜濮炴潪濮愨偓宥囧Ц閹礁鎷伴崣鍌濃偓鍐ㄧ氨閹垮秳缍旈幐澶愭尦閻ㄥ嫰妫舵０妯糕偓?

### 妞嬪酣娅撻崣妯绘纯
- 鐠囧嫪鍙婂楦款唴娑撳秴鍟€娴犮儲鍋撳ù顔绘櫠鏉堣濞婄仦澶婅埌瀵繗顩惄鏍€夐棃顫礉娓氀嗙珶閹扮喎鍣哄鎲嬬礉娴ｅ棛些閸斻劎顏崣顖濐嚢閹冩嫲閸欘垱鎼锋担婊勨偓褎娲跨粙鍐茬暰閵?

## [Unreleased-PLAN_073-WEAR-UX-FIXES-ADVISOR] - 2026-04-28

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閵嗗瞼鈹涙禒鈧稊鍫涒偓宥勭矝鐎涙ê婀粻锛勬倞閹兼粎鍌ㄩ幓鎰仛濞岃法鏁ら懣婊冩惂閺傚洦顢嶉妴浣搞亯濮樻梹婀崥顖滄暏閺冨爼绮拋銈嗙毜濞撯晙绗夐崥鍫㈡倞閵嗕礁鍞寸純顔裤€傞弻婊冨弳閸欙綀绻冨杞扮瑬閹稿鎸虫潻鍥毐閵嗕胶宸辩亸鎴濈唨娴滃海鈹涚悰锝堫潐閸掓瑧娈戣箛顐︹偓鐔荤槑娴兼澘浼愰崗椋庣搼娴ｆ捇鐛欓梻顕€顣介妴?

### 閺傛澘顤?
- 閺傛澘顤?`plans/PLAN_073_濮ｅ繑妫╅崘宕囩摜缁屽じ绮堟稊鍫滅秼妤犲瞼绮忛懞鍌欐叏婢跺秳绗岀拠鍕強瀹搞儱鍙块幎钘夌溄.md`閿涘矁顔囪ぐ鏇熸拱鏉烆喕缍嬫灞兼叏婢跺秲鈧礁銇夊鏃堢帛鐠併倕鈧鈧浇銆傞弻婊冨弳閸欙絽鐪扮痪褍鎷扮拠鍕強瀹搞儱鍙块懠鍐ㄦ纯閵?
- 閺傛澘顤冪粚澶哥矆娑斿牅绗撶仦鐐版櫠鏉堝箍鈧瞼鈹涢幖顓＄槑娴艰埇鈧秴浼愰崗閿嬪▕鐏炲绱濋崠鍛儓閸戞椽妫崜?30 缁夋帟鐦庢导鑸偓浣稿礋閸濅線顤侀懝鍙夋儗闁板秴缂撶拋顔荤瑢闁潡娴勯妴浣哥埗鐟欎礁鐪扮痪褍鍙曞蹇嬧偓浣告簚閺咁垯绱崗鍫㈤獓閸滃苯鐖剁憴浣搞亼鐠囶垬鈧?

### 娣囶喗鏁?
- 缁狅紕鎮婃い鍨偝缁便垺顢嬮幐澶嬆侀崸妤€灏崚鍡樺絹缁€鐚寸礉缁屽じ绮堟稊鍫熸暭娑撶儤鎮崇槐銏℃儗闁板秲鈧胶婀＄€圭偛宕熼崫浣告嫲閸︾儤娅欓崗鎶芥暛鐠囧稄绱濇稉宥呭晙閺勫墽銇氶懣婊冩惂閸氬秶袨閵?
- 缁屽じ绮堟稊鍫熸弓閸氼垳鏁ゆ径鈺傜毜瀵ら缚顔呴幋鏍ㄦ畯閺冪姴銇夊鏂挎彥閻撗勬姒涙顓绘穱婵囧瘮閵嗗苯鍙忛柈銊︾毜濞撯斂鈧稄绱辨禒鍛躬閸忋劌鐪径鈺傜毜閺佺増宓侀崣顖滄暏閺冩儼鍤滈崝銊﹀腹閼芥劖鐨靛〒鈺傘€傛担宥冣偓?
- 鏉╂稑鍙嗙粚澶哥矆娑斿牊妞傛径宥囨暏閸忋劌鐪径鈺傜毜閸掗攱鏌婇懗钘夊閿涘矂浼╅崗宥堫啎缂冾喖鍑″鈧崥顖欑稻婢垛晜鐨佃箛顐ゅ弾鐏忔碍婀弴瀛樻煀閺冩湹绔撮惄鏉戜粻閻ｆ瑥婀弮鐘虫殶閹诡喚濮搁幀浣碘偓?
- 缁屽じ绮堟稊鍫滃瘜妞ょ敻娼版妯款吇娴兼ê鍘涢柅澶嬪閵嗗本鍨滈惃鍕€傚渚库偓宥忕礉閸愬懐鐤嗛崣鍌濃偓鍐х瑝閸愬秳缍旀稉娲帛鐠併倓瀵岄崗銉ュ經閵?
- 閸愬懐鐤嗙悰锝嗙厲闂嗗棗鎮庨崥宥囆炵紓鈺冪叚娑撴椽鈧艾瀚熼妴浣规）鐢悶鈧焦顒滃蹇嬧偓浣哄娴兼哎鈧浇绻嶉崝銊ｂ偓渚€娲︽径鈺嬬礉楠炶泛婀稉濠氥€夐棃銏ｃ€傞弻婊堚偓澶嬪娑擃參绮拋銈嗗閸欑姴鐫嶇粈鎭掆偓?

### 娣囶喖顦?
- 娣囶喖顦茬粚澶哥矆娑斿牏顓搁悶鍡涖€夐幖婊呭偍鏉堟挸鍙嗗鍡樻瀮濡楀牅绮涢幓鎰仛閵嗗本鎮崇槐銏ｅ綅閸濅礁鎮曠粔鑸偓宥囨畱闂傤噣顣介妴?
- 娣囶喖顦叉径鈺傜毜瀵ら缚顔呮稉宥呭讲閻劍妞傞弬鍥攳閹绘劗銇氭禒搴涒偓灞句刊閸滃被鈧秴绱戞慨瀣ㄢ偓浣风稻閻劍鍩涙０鍕埂鎼存梹鐓￠惇瀣弿闁劍鐨靛〒鈺冩畱闂傤噣顣介妴?
- 娣囶喖顦查崘鍛枂閸欏倽鈧啳銆傞弻?pill 閸︺劎些閸斻劎顏潻鍥毐閵嗕礁顕遍懛鏉戝礋閸掓鐝惔锕佺箖妤傛娈戦梻顕€顣介妴?

### 妞嬪酣娅撻崣妯绘纯
- 姒涙顓绘导妯哄帥娴犲簺鈧本鍨滈惃鍕€傚渚库偓宥嗗▕閸欐牔绱扮拋鈺佺毣閺堫亜缍嶉崗銉ら嚋娴滆櫣鈹涢幖顓犳畱閺傛壆鏁ら幋椋庢箙閸掓壆鈹栭悩鑸碘偓渚婄幢缁岃櫣濮搁幀浣规瀮濡楀牏鎴风紒顓炵穿鐎佃偐鏁ら幋宄扮秿閸忋儳婀＄€圭偞鎯岄柊宥嗗灗鐏炴洖绱戦崘鍛枂閸欏倽鈧啨鈧?
- 娓氀嗙珶鐠囧嫪鍙婂銉ュ徔閸欘亜婀粚澶哥矆娑斿牊膩閸ф鍞撮柈銊ョ杽閻滃府绱濇稉宥呭閸濆秴鎮嗘禒鈧稊鍫涒偓浣稿箵閸濐亜鍔归妴浣镐粵娴犫偓娑斿牏鐡戦崗鏈电铂濮ｅ繑妫╅崘宕囩摜鐎涙劖膩閸фぜ鈧?

## [Unreleased-PLAN_072-WEAR-FILTERS-GUIDE-DATA] - 2026-04-28

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴閸︺劌浼愰崗椋庮唸閵嗗本鐦￠弮銉ュ枀缁?- 缁屽じ绮堟稊鍫涒偓宥勮厬鐞涖儱鍘栭幀褍鍩嗘稉搴″嬀姒嫮鐡柅澶涚礉娴兼ê瀵查弬鍥攳閸滃苯绱╃€电》绱濈粣浣稿毉閳ユ粈绮犻懛顏勭箒閻ㄥ嫮婀＄€圭偠銆傞弻婊冪紦缁斿閲滄禍铏光敍閹碱厸鈧繄娈?UX 娑撹崵鍤庨敍灞借嫙閸╄桨绨?`D:\vocabularySleep-resources\缁屽じ绮堟稊鍧?闁插秵鏌婇悽鐔稿灇閸愬懐鐤嗙悰锝嗙厲閺佺増宓侀妴?

### 閺傛澘顤?
- 閺傛澘顤?`plans/PLAN_072_濮ｅ繑妫╅崘宕囩摜缁屽じ绮堟稊鍫熲偓褍鍩嗛獮鎾窞缁涙盯鈧绗岀悰锝嗙厲閺佺増宓侀柌宥呯紦.md`閿涘矁顔囪ぐ鏇熸拱鏉烆喗鈧冨焼楠炴挳绶炵粵娑⑩偓澶堚偓浣瑰瘹閸楁鏋冨鍫涒偓浣虹椽鏉堟垵绱╃€电厧鎷伴弫鐗堝祦闁插秴缂撻懠鍐ㄦ纯閵?
- 閺傛澘顤冪粚澶哥矆娑?`gender` 娑?`age` 閻楃懓绶涚紒鍕剁礉楠炶埖甯撮崗銉╂閺堟椽銆夋妯奸獓缁涙盯鈧鈧胶顓搁悶鍡涖€夌粵娑⑩偓澶堚偓浣虹椽鏉堟垵娅掗弽鍥╊劮閸栧搫鎷伴崘鍛枂閺佺増宓侀悽鐔稿灇鐏炵偞鈧佲偓?
- 閺傛澘顤?`scripts/generate_daily_choice_wear_dataset.py`閿涘苯褰叉禒搴㈡拱閸︽壆鈹涢幖顓＄カ閺傛瑧鏁撻幋鎰敍娴犫偓娑斿牆鍞寸純顔裤€傞弻?JSON閵嗕讣QLite閵嗕焦鐗稿蹇氼嚛閺勫骸鎷伴悽鐔稿灇閹芥顩﹂妴?
- 閻㈢喐鍨氶弬鎵畱閸愬懐鐤嗙悰锝嗙厲閺佺増宓侀崚?`D:\vocabularySleep-resources\缁屽じ绮堟稊?閺佺増宓乣閿涘苯瀵橀崥?1250 閺夛紕鈹涢幖顓溾偓浣光偓褍鍩嗛崣鍌濃偓鍐х瑢楠炴挳绶為梼鑸殿唽閸掑棗绔烽妴浣圭毜濞?閸︾儤娅欑憰鍡欐磰閹芥顩﹂妴?

### 娣囶喗鏁?
- 闁插秴鍟撶粚鑳€傞幐鍥у础鐏炴洜銇氶弬鍥攳閿涘瞼些闂勩倓淇婇幁顖涚爱閵嗕椒鍔熼崥宥呮嫲閺夈儲绨懗灞煎姛鐞涖劏鎻敍灞炬暭娑撻缚鍤滈悞鍓佹畱缁岃儻銆傞崢鐔峰灟閵嗕礁婧€閺咁垰鍨介弬顓溾偓浣搞亯濮樻梹顥呴弻銉ユ嫲鐞涳絾鈹嶇紒鍐х瘎鐠囧瓨妲戦妴?
- 娴兼ê瀵茬粚澶哥矆娑斿牓娈㈤張娲€夐妴浣侯吀閻炲棝銆夐妴浣姐€傞弻婊堚偓澶嬪閵嗕胶鈹栭悩鑸碘偓浣告嫲閸愬懐鐤嗘惔鎾跺Ц閹焦鏋冨鍫礉閺勫海鈥橀崘鍛枂閺佺増宓佺悰锝嗙厲閺勵垰寮懓鍐┠侀弶鍖＄礉娑擃亙姹夐惇鐔风杽鐞涳絾鐓栭幍宥嗘Ц闂€鎸庢埂闂呭繑婧€娑撹崵鍤庨妴?
- 娴兼ê瀵茬粚鎸庢儗閺傛澘缂?缂傛牞绶悰銊ュ礋閹绘劗銇氶敍灞芥躬閹碱參鍘ら崥宥囆為妴浣告簚閺咁垬鈧胶绮嶉幋鎰┾偓浣诡劄妤犮們鈧礁顦▔銊ユ嫲閺嶅洨顒锋潏鎾冲弳娑擃厽甯撮崗銉р敍鐞涳絽甯崚娆欑礉瀵洖顕遍悽銊﹀煕鐠佹澘缍嶉惇鐔风杽閸楁洖鎼ч妴浣规禌娴狅絾鏌熷鍫涒偓浣逛刊鎼达箒顢戦崝銊ユ嫲濮ｆ柧绶ュΛ鈧弻銉ｂ偓?

### 娣囶喖顦?
- 娣囶喖顦茬粚鑳€傞幐鍥у础娴犲秴褰查懗鑺ユ瘹闂囨彃寮懓鍐╂降濠ф劑鈧礁绱╃挧铚傜挨鐠侇喗鍨ㄨぐ銏″灇鏉╁洤瀹抽懗灞煎姛閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦茬粚澶哥矆娑斿牏顓搁悶鍡曠瑢缁涙盯鈧宸辩亸鎴炩偓褍鍩嗛崣鍌濃偓鍐︹偓浣稿嬀姒嫰妯佸▓鍏歌⒈娑擃亞鏁ら幋宄扮埗閻劎缂夌亸蹇曟樊鎼达妇娈戦梻顕€顣介妴?

### 妞嬪酣娅撻崣妯绘纯
- 閹冨焼閸滃苯鍕炬Λ鍕矌娴ｆ粈璐熼崣鍌濃偓鍐摣闁娣惔锔肩礉娑撳秳缍旀稉铏光€栫憴鍕灟閿涙稒鏋冨鍫滅箽閻ｆ瑢鈧粈绗夐梽鎰暰 / 闁氨鏁ゆ稉宥嗗姒嫧鈧繂鍙嗛崣锝忕礉闂勫秳缍嗛崚缁樻緲閹恒劏宕樻搴ㄦ珦閵?
- 閺傛壆鏁撻幋鎰畱閸愬懐鐤嗛弫鐗堝祦娴犲秴绨茬悮顐ヮ潒娑撳搫寮懓鍐┠侀弶鍖＄礉閻劍鍩涢崣锕€鐡ㄩ獮鑸垫暭閹存劘鍤滃杈╂畱閻喎鐤勯崡鏇炴惂閸氬函绱濋梾蹇旀簚缂佹挻鐏夐幍宥勭窗閺囩鍒涙潻鎴炴）鐢晲濞囬悽銊ｂ偓?

## [Unreleased-PLAN_071-WEAR-WARDROBE] - 2026-04-28

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯瀹搞儱鍙跨粻渚库偓灞剧槨閺冦儱鍠呯粵?- 缁屽じ绮堟稊鍫涒偓宥呯摍濡€虫健瑜版挸澧犳禒锝囩垳閹恒儳鍤庨柨娆庤础閿涘矁顩﹀Ч鍌氱暚閸忋劌寮悡褋鈧苯鎮嗘禒鈧稊鍫涒偓宥囨畱閺佺増宓佸┃鎰┾偓渚€娉﹂崥鍫㈢摣闁鈧浇鍤滅€规矮绠熼梿鍡楁値閸滃瞼顓搁悶鍡涖€夐幀婵婄熅閿涘矁藟姒绘劕鍞寸純顔芥殶閹诡喛銆傞弻婊€绗岄悽銊﹀煕閼奉亜鐣炬稊澶庛€傞弻婧库偓?

### 閺傛澘顤?
- 閺傛澘顤?`plans/PLAN_071_濮ｅ繑妫╅崘宕囩摜缁屽じ绮堟稊鍫濈摍濡€虫健鐞涳絾鐓栭崠鏍х暚閸?md`閿涘矁顔囪ぐ鏇犫敍娴犫偓娑斿牐銆傞弻婊冨閻╊喗鐖ｉ妴浣诡劄妤犮們鈧線顥撻梽鈺佹嫲娓氭繆绂嗛妴?
- 閺傛澘顤?`DailyChoiceWearLibraryStore`閿涘本瀵滈崥鍐х矆娑斿牆鍞寸純顔垮綅鐠嬪崬绨遍幀婵婄熅閺€顖涘瘮缁屾寧鎯岄崘鍛枂鎼存挾濮搁幀浣诡梾閺屻儯鈧浇绻欑粩顖氱暔鐟佸懌鈧讣QLite 閹芥顩︾拠璇插絿閸滃矁顕涢幆鍛櫩閸旂姾娴囬妴?
- 閺傛澘顤冪粚澶哥矆娑斿牓绮拋銈堛€傞弻婊堟肠閸氬牊膩閸ㄥ绱版妯款吇閵嗗本鍨滈惃鍕€傚渚库偓宥冣偓渚€鈧艾瀚?閺冦儱鐖?濮濓絽绱?缁撅缚绱?鏉╂劕濮?闂嗐劌銇夌粵澶婂敶缂冾喗鏆熼幑顔裤€傞弻婊愮礉娴犮儱寮烽悽銊﹀煕閼奉亜鐣炬稊澶庛€傞弻婊呮畱閹镐椒绠欓崠鏍モ偓浣割杻閸掔姵鏁奸妴浣瑰灇閸涙ê鍙х化鑽ゎ吀閻炲棗鎷?JSON 鐎电厧鍙嗙€电厧鍤妴?
- 閺傛澘顤冪粚澶哥矆娑斿牏顓搁悶鍡涖€夐幖婊呭偍閵嗕浇銆傞弻婊堟肠閸氬牓鈧瀚ㄩ妴渚€鍣搁崨钘夋倳閵嗕礁鍨归梽銈冣偓浣割嚤閸忋儱顕遍崙鎭掆偓浣稿閸忋儴銆傞弻婧库偓浣盒╅崙鍝勭秼閸撳秷銆傞弻婧库偓浣稿敶缂冾喗鎯岄柊宥堫嚊閹懌鈧椒閲滄禍楦跨殶閺佹潙鎷伴崣锕€鐡ㄦ稉楦垮殰鐎规矮绠熼惃鍕暚閺佹潙鍙嗛崣锝冣偓?

### 娣囶喗鏁?
- `DailyChoiceHub` 閹恒儱鍙嗙粚鎸庢儗閸愬懐鐤嗘惔鎾村櫩閸旂姾娴囬崪灞界暔鐟佸懐濮搁幀渚婄礉鏉╂稑鍙嗙粚澶哥矆娑斿牊妞傞幐澶愭付鐠囪褰囬崘鍛枂閹芥顩﹂敍灞借嫙閹稿婧€閺咁垰娲栨繅顐㈠敶缂冾喗鏆熼幑顔裤€傞弻婊勫灇閸涙ǜ鈧?
- 缁屽じ绮堟稊鍫ユ閺堟椽銆夐弨閫涜礋閺€顖涘瘮閸忋劑鍎寸悰锝嗙厲閵嗕礁鍞寸純顔芥殶閹诡喛銆傞弻婧库偓浣烘暏閹寸柉鍤滅€规矮绠熺悰锝嗙厲缁涙盯鈧绱濋獮鏈电瑢濞撯晛瀹抽妴浣告簚閺咁垬鈧礁銇夊鏂跨紦鐠侇喖鎷版妯奸獓缁屾寧鎯岄悧鐟扮窙缁涙盯鈧鍙￠崥宀€鏁撻弫鍫涒偓?
- 缁狅紕鎮婃い鍏哥瑢缂傛牞绶崳銊ф畱闂嗗棗鎮庨崣鍌涙殶濞夋稑瀵叉稉鍝勬倱閺冭埖鏁幐浣告倖娴犫偓娑斿牓顥ょ拫閬嶆肠閸滃瞼鈹涙禒鈧稊鍫ｃ€傞弻婊愮礉娣囨繃瀵旀稉銈囪鐎涙劖膩閸ф娈戞穱婵嗙摠閵嗕礁褰熺€涙ê鎷伴幋鎰喅閸忓磭閮撮崘娆忓弳鐠囶厺绠熸稉鈧懛娣偓?
- 缁屽じ绮堟稊鍫熷瘹閸楁ぞ绗岄悧鐟扮窙缁涙盯鈧娴嗘稉铏骨旂€规氨娈戝Ο鈥虫健閸愬懏鏆熼幑顕嗙礉娑撳秴鍟€娓氭繆绂嗛弮褏娈戦棃娆愨偓浣衡敍閹?seed 閺傚洣娆㈤妴?

### 娣囶喖顦?
- 娣囶喖顦茬粚澶哥矆娑斿牓绮拋銈夆偓澶夎厬缁屾亽鈧本鍨滈惃鍕€傚渚库偓宥嗘闂呭繑婧€濮圭姳绮涢崓蹇撳弿闁插繑鐫滃銉ょ稊閻ㄥ嫰鏁婃稊鍙樼秼妤犲被鈧?
- 娣囶喖顦茬粚澶哥矆娑斿牏顓搁悶鍡涖€夐崘鍛枂閹碱參鍘ら妴浣烽嚋娴滅儤鎯岄柊宥呮嫲娑擃亙姹夌拫鍐╂殻濞屸剝婀侀幐澶婄秼閸撳秷銆傞弻婊堟肠閸氬牐绻冨銈囨畱闂傤噣顣介妴?
- 娣囶喖顦茬粚澶哥矆娑斿牓娈㈤張娲€夐崪灞藉敶缂冾喗鏆熼幑顔裤€傞弻婊冩礀婵夘偄褰х拠鍡楀焼娑撹婧€閺咁垬鈧焦绱￠幒澶婎樋閸︾儤娅欑粚鎸庢儗閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦茬粚澶哥矆娑斿牆銇夊鏂跨紦鐠侇喕绗岄幍瀣З濞撯晛瀹抽柅澶嬪娴兼ê鍘涚痪褑銆冩潏鎯х础娑撳秵绔婚弲鎵畱闂傤噣顣介妴?

### 妞嬪酣娅撻崣妯绘纯
- 閸愬懐鐤嗙粚鎸庢儗鎼存挷绶风挧鏍ㄦ拱閸?SQLite 鐎瑰顥婇悩鑸碘偓渚婄幢閺堫亜鐣ㄧ憗鍛灗鐎瑰顥婃径杈Е閺冩湹绻氶悾娆戝Ц閹線娼伴弶澶哥瑢鐎瑰顥婇崗銉ュ經閿涘矁鍤滅€规矮绠熺悰锝嗙厲娴犲秴褰茬紒褏鐢绘担璺ㄦ暏閵?
- `flutter analyze` 娴犲秴褰堥弮銏℃箒闂堢偞鐦￠弮銉ュ枀缁?lint/鐠€锕€鎲¤ぐ鍗炴惙闁偓閸?1閿涘本婀版潪顔炬祲閸?`toolbox_daily_choice` 閺傚洣娆㈤張顏呮煀婢х偛鍨庨弸鎰版６妫版ǜ鈧?

## [Unreleased-PLAN_070-EAT-OVERHAUL-TAKEOVER] - 2026-04-27

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯瀹搞儱鍙跨粻渚库偓灞剧槨閺冦儱鍠呯粵?- 閸氬啩绮堟稊鍫涒偓宥呯摍濡€虫健鐎涙ê婀弫鐗堝祦濠ф劙鏁婃稊渚库偓浣虹摣闁鐡у▓鍏哥瑝閸戝棎鈧椒寮楅柌宥嗏偓褑鍏橀悺鍫曨暛閵嗕線娈㈤張杞扮秼妤犲苯绱撶敮鎼炩偓浣稿鏉炰粙妯嗘繅鐐偓浣侯吀閻?UI 瀵缚浠涢崥鍫涒偓浣稿瀻妞ゅ吀缍嬫灞芥▕閸?`TextEditingController` 閻㈢喎鎳￠崨銊︽埂瀹曗晜绨濈粵澶岄兇缂佺喐鈧囨６妫版ǜ鈧?
- 閻劍鍩涚憰浣圭湴閸忓牆顕ぐ鎾冲瀹搞儰缍旈崠鍝勪粵婢跺洣鍞ゅ蹇斿絹娴溿倧绱濋崘宥呭灡瀵ゅ搫褰查幐浣虹敾閹恒儲澧滈惃鍕暚閺佺繝鎹㈤崝鈥充紣娴ｆ粍绁︽稉搴ゎ吀閸掓帪绱濇笟澶哥艾閸氬海鐢绘导姘崇樈缂佈呯敾閹恒劏绻橀妴?

### 閺傛澘顤?
- 閺傛澘顤?`plans/PLAN_070_濮ｅ繑妫╅崘宕囩摜閸氬啩绮堟稊鍫濈摍濡€虫健閸忋劑娼伴幒銉ь吀娑撳孩鏆熼幑鐢嶪闁插秵鐎?md`閿涘矁顔囪ぐ鏇熷复缁犫€冲瀻閺€顖樷偓浣割槵娴犺姤褰佹禍銈冣偓渚€妯佸▓鍨閸掑棎鈧?3 娑擃亪妫舵０姗€鐛欓弨鑸电垼閸戝棎鈧焦鏆熼幑顕€鍣稿鍝勫斧閸掓瑣鈧够chema 娴兼ê瀵查弬鐟版倻閵嗕箒I 閹峰棗鍨庢潏鍦櫕閸滃苯鎮楃紒顓㈢崣鐠囦胶鐡ラ悾銉ｂ偓?
- 閺傛澘顤?`DailyChoiceHub keeps other modules usable while eat library loads` smoke 濞村鐦敍宀勬敚鐎规艾鎮嗘禒鈧稊鍫熸喅鐟曚礁濮炴潪鑺ユ弓鐎瑰本鍨氶弮鏈电矝閸欘垰鍨忛幑銏犺嫙娴ｈ法鏁ら崗鏈电铂濮ｅ繑妫╅崘宕囩摜濡€虫健閵?
- 閺傛澘顤?`scripts/audit_daily_choice_recipe_dataset.py`閿涘苯顓哥拋鈥崇秼閸?`D:\vocabularySleep-resources\cook_data` JSON/SQLite 娑?YunYouJun/cook `recipe.csv` 閻ㄥ嫬鐡у▓闈涘暱缁愪降鈧焦娼靛┃鎰洬閻╂牓鈧浇褰嶇化?notes 濮光剝鐓嬮妴渚€顥ら弶鎰焼閸氬秷绻冪€硅棄灏柊宥呮嫲閹惰棄褰囨稊杈╃垳閵?
- 閺傛澘顤?`records/record_070_daily_choice_recipe_data_audit.md` 娑?`records/record_070_daily_choice_recipe_data_audit.json`閿涘矁顔囪ぐ鏇㈩浕鏉烆喗鏆熼幑顔界爱鐎孤ゎ吀缂佹挻鐏夐妴?
- 閺傛澘顤?`records/record_070_daily_choice_recipe_data_audit_after_generation.md` 娑?`records/record_070_daily_choice_recipe_data_audit_after_generation.json`閿涘矁顔囪ぐ鏇氭叏濮濓絿鏁撻幋鎰潐閸掓瑥鎮楅惃鍕缁傚鐛欑拠浣稿瘶鐎孤ゎ吀缂佹挻鐏夐妴?
- 閺傛澘顤?`records/record_070_daily_choice_recipe_schema_design.md`閿涘矁顔囪ぐ鏇炴倖娴犫偓娑?v2 閺佺増宓佹惔鎾广€冪拋鎹愵吀閵嗕胶鍌ㄥ鏇犵摜閻ｃ儯鈧礁鍚€閸ㄥ鐓＄拠顫偓浣界讣缁夊銆庢惔蹇撴嫲妤犲本鏁归弽鍥у櫙閵?
- 閺傛澘顤?`scripts/daily_choice_recipe_schema_v2.sql`閿涘奔缍旀稉鍝勬倵缂侇厾鏁撻幋鎰珤娑?Flutter store 鏉╀胶些閻ㄥ嫬褰查幍褑顢?SQLite schema 閼藉顢嶉妴?
- 閺傛澘顤?`decisions/ADR_070_daily_choice_recipe_schema_v2.md`閿涘矁顔囪ぐ?v2 閸掑棗鐪?schema 閻ㄥ嫭濡ч張顖氬枀缁涙牓鈧?
- 閺傛澘顤?`records/record_070_daily_choice_s3_upload_package.md`閿涘矁顔囪ぐ?`cook_data_plan070_validation` 閸樺缂夐崥搴㈡瀮娴犺泛銇囩亸蹇嬧偓浣哥紦鐠?S3 key閵嗕浇绻欑粩顖氱暔鐟佸懓绔熼悾灞芥嫲妤犲矁鐦夐崨鎴掓姢閵?
- 閺傛澘顤?`DailyChoiceEatLibraryStore` 鏉╂粎顏径杈Е鏉堝湱鏅ù瀣槸閿涘矁顩惄鏍も偓婊冨嚒閺?SQLite 鎼存挻妞傞崚閿嬫煀婢惰精瑙︽稉宥堫洬閻╂牗妫惔鎾偓婵嗘嫲閳ユ粓顩诲▎陇绻欑粩顖氥亼鐠愩儰绗夐悽鐔稿灇 bundled JSON fallback閳ユ縿鈧?
- 閺傛澘顤?`scripts/verify_daily_choice_recipe_remote.dart`閿涘瞼鏁ゆ禍搴ㄢ偓姘崇箖 S3 鏉╂粎顏€瑰本鏆ｆ稉瀣祰閸氬啩绮堟稊?SQLite DB閿涘苯鑻熸宀冪槈 v1/v2 鐞涖劏顓搁弫鑸偓涔礶ta 閸?sample detail閵?
- 閺傛澘顤?`records/record_070_daily_choice_remote_db_smoke.md`閿涘矁顔囪ぐ?S3 `/cook_data` 娑撳﹣绱堕崥搴ょ箼缁?key閵嗕焦鏋冩禒璺恒亣鐏忓繈鈧礁鐣弫缈犵瑓鏉?smoke閵嗕沟eta 娑?v2 瑜版挸澧犻悩鑸碘偓浣碘偓?
- 閺傛澘顤冮崥鍐х矆娑?catalog 閸ョ偛缍婂ù瀣槸閿涘矁顩惄鏍も偓婊冨弿闁劑顦靛▓纰樷偓婵嬬帛鐠併倕鈧瑩鈧鐫滈妴浣藉С閻㈢喎娼ラ弸婊呯矋閸氬牆绻夐崣锝忕礉娴犮儱寮?`閹烘帡顎嘸 娑撳秴鍟€闁偓閸栨牗鍨氶柅姘辨暏 `pork` 妞嬬喐娼?token閵?
- 閺傛澘顤?`records/record_070_daily_choice_v2_only_db_package.md`閿涘矁顔囪ぐ鏇熸煀閻?v2-only 娑撳﹣绱?DB 閻ㄥ嫯绶崙楦跨熅瀵板嫨鈧礁銇囩亸蹇嬧偓涓糎A256閵嗕够chema/meta閵嗕浇銆冪拋鈩冩殶閸滃矁绻嶇悰灞炬鏉堝湱鏅妴?
- 閺傛澘顤?`records/record_070_daily_choice_recipe_v2_only_db_audit.md` 娑?JSON 鐎孤ゎ吀缂佹挻鐏夐敍宀冾唶瑜?v2-only DB 娑撳酣鐛欑拠浣稿瘶 JSON 閻ㄥ嫪绔撮懛瀛樷偓褋鈧恭ook CSV 鐟曞棛娲婇崪?10 娑擃亝鏆熼幑顕€妫舵０妯汇€婄紒鎾寸亯閵?
- 閺傛澘顤?`records/record_070_daily_choice_remote_v2_runtime_smoke.md`閿涘矁顔囪ぐ鏇犳暏閹撮攱娲块弬?S3 閸氬海娈戞潻婊咁伂 v2-only DB 鐎瑰本鏆ｆ稉瀣祰 smoke 閸滃矁绻嶇悰灞炬鐠囪褰囨宀冪槈閵?
- 閺傛澘顤?`DailyChoiceEatLibraryStore installs v2-only SQLite and lazy loads details` 閸楁洘绁撮敍宀冾洬閻?v2-only DB 閻ㄥ嫬鐣ㄧ憗鍛偓涔ok/cook 鐠佲剝鏆熼妴浣规喅鐟曚浇浜ら柌蹇氼嚢閸欐牕鎷扮拠锔藉剰閹虫帒濮炴潪濮愨偓?
- 閺傛澘顤?`DailyChoiceEatLibraryQuery` 娑?`DailyChoiceEatLibraryQueryResult`閿涘奔璐熼崥鍐х矆娑?v2 閸愬懐鐤嗘惔鎾村絹娓氭稑鍨庢い鍨喅鐟曚降鈧焦鈧粯鏆熼妴浣哥暚閺佹挳娈㈤張鍝勨偓娆撯偓?id 濮圭姴鎷伴崥搴ｇ敾 random pivot 閹恒儱鍙嗛崣锝冣偓?
- 閺傛澘顤?`records/record_070_daily_choice_v2_sql_query_foundation.md`閿涘矁顔囪ぐ?v2 SQL 閺屻儴顕楅崺铏诡攨閵嗕焦婀版潪顔跨珶閻ｅ被鈧焦绁寸拠鏇☆洬閻╂牕鎷伴崥搴ｇ敾 UI 閹恒儱鍙嗘搴ㄦ珦閵?
- 閺傛澘顤?v2 SQL 閺屻儴顕楅崡鏇熺ゴ閿涘矁顩惄鏍偍瀵洜鐡柅澶堚偓浣稿瀻妞ゅ灚鎲崇憰浣碘偓涔ｉ幒鎺楊€嘸 缁墽鈥樻鐔告綏閸栧綊鍘ら崪宀冨С閻㈢喎娼ラ弸婊呯矋閸氬牆绻夐崣锝冣偓?
- 閺傛澘顤?`DailyChoiceEatLibraryStore.pickBuiltInRandomSummary(...)`閿涘本鏁幐浣瑰瘻 v2 `random_key` pivot 娴犲骸鐣弫鏉戔偓娆撯偓澶嬬潨閹惰棄褰囨潪濠氬櫤閹芥顩﹂妴?
- 閺傛澘顤?`records/record_070_daily_choice_v2_random_pivot.md`閿涘矁顔囪ぐ?store 鐏?random pivot 閼宠棄濮忛妴浣圭ゴ鐠囨洝顩惄鏍ф嫲閸氬海鐢?UI 閹恒儱鍙嗘潏鍦櫕閵?
- 閺傛澘顤?`DailyChoiceRandomPanel` 閸欘垶鈧绱撳銉︽付缂佸牊濞婇崣鏍у弳閸欙綇绱濇笟娑樻倖娴犫偓娑斿牅瀵?UI 閸︺劌浠犲銏ゆ閺堢儤妞傞幒銉ュ弳 store random pivot閵?
- 閺傛澘顤?`records/record_070_daily_choice_ui_random_and_manager_sql_paging.md`閿涘矁顔囪ぐ鏇氬瘜 UI 闂呭繑婧€娑撳海顓搁悶鍡涖€夐崘鍛枂鎼?SQL 閸掑棝銆夐幒銉ュ弳鏉堝湱鏅妴?
- 閺傛澘顤冮梾蹇旀簚闂堛垺婢?widget 閸ョ偛缍婂ù瀣槸閿涘矁顩惄鏍р偓娆撯偓澶嬬潨閸欐ê瀵查崥搴㈡＋瀵倹顒為幎钘夊絿缂佹挻鐏夋稉宥呮礀閸愭瑥缍嬮崜?UI閵?
- 閺傛澘顤?`DailyChoiceEatLibraryQuery.searchText`閿涘奔璐熺粻锛勬倞妞ら潧鎮嗘禒鈧稊鍫濆敶缂冾喖绨遍幖婊呭偍娑撳鐭囬崚?v2 SQLite search table 閹绘劒绶甸弻銉嚄鐎涙顔岄妴?
- 閺傛澘顤?`records/record_070_daily_choice_manager_sql_search.md`閿涘矁顔囪ぐ鏇狀吀閻炲棝銆夐崘鍛枂鎼存挻鎮崇槐顫瑓濞屽瀵栭崶娣偓渚€鐛欑拠浣告嫲閸氬海鐢?FTS/閹峰棝銆夐弬鐟版倻閵?
- 閺傛澘顤冪粻锛勬倞妞?SQL 閸愬懐鐤嗛幗妯款洣鐠囷附鍎忛幊鎺戝鏉炶棄娲栬ぐ鎺撶ゴ鐠囨洩绱濈憰鍡欐磰閸愬懎鐡ㄩ崗銊╁櫤閹芥顩︽稉铏光敄閺冩湹绮涢崣顖欑矤 store 閹垫挸绱戠拠锔藉剰閵?
- 閺傛澘顤?`records/record_070_daily_choice_manager_item_action_states.md`閿涘矁顔囪ぐ鏇狀吀閻炲棝銆夐崘鍛枂閼挎粏姘ㄩ柅鎰般€?loading / disabled / error 閻樿埖鈧胶娈戠€圭偟骞囨潏鍦櫕閸滃矂鐛欑拠浣碘偓?
- 閺傛澘顤冪粻锛勬倞妞ら潧鍞寸純顔垮綅鐠嬮亶鈧劙銆嶉崝銊ょ稊閸ョ偛缍婂ù瀣槸閿涘矁顩惄?detail 閹便垼顕伴崣鏍ㄦ埂闂傜繝绗夐柌宥咁槻鐟欙箑褰傜拠閿嬬湴閿涘奔浜掗崣?detail 婢惰精瑙﹂弮鏈电箽閻ｆ瑥缍嬮崜?sheet 楠炶埖妯夌粈鍝勭湰闁劑鏁婄拠顖樷偓?
- 閺傛澘顤?`records/record_070_daily_choice_manager_auto_paging_and_search_commit.md`閿涘矁顔囪ぐ鏇狀吀閻炲棝銆夐懛顏勫З閸掑棝銆夐妴浣规偝缁便垺褰佹禍銈堢珶閻ｅ苯鎷伴崥搴ｇ敾 FTS/閸婃帗甯撶悰銊╊棑闂勨斂鈧?
- 閺傛澘顤冪粻锛勬倞妞や絻鍤滈崝銊ュ瀻妞ゅ吀绗岄幖婊呭偍閹绘劒姘﹂崶鐐茬秺濞村鐦敍宀冾洬閻╂牗绮撮崝銊ㄐ曟惔鏇″殰閸斻劍澧挎径?SQL 閸掑棝銆?limit閿涘奔浜掗崣濠呯翻閸忋儲鎮崇槐銏ｇ槤閺堢喖妫挎稉宥嗙叀鐠囶潿鈧礁銇戦悞锕€鎮楅幍宥嗗絹娴?`searchText`閵?
- 閺傛澘顤?`records/record_070_daily_choice_random_stop_timeout_and_pivot_guard.md`閿涘矁顔囪ぐ鏇㈡閺堝搫浠犲銏ｇТ閺冭泛鍘规惔鏇樷偓浣搞亣閸婃瑩鈧鐫?SQL guard 閸滃本婀版潪顕€鐛欑拠浣碘偓?
- 閺傛澘顤冮梾蹇旀簚閸嬫粍顒涢崶鐐茬秺濞村鐦敍宀冾洬閻╂牕绱撳銉︽付缂佸牊濞婇崣鏍Т閺冭泛鎮楅柅鈧崙?`Picking`閿涘奔浜掗崣濠囨閽樺繘銆嶇€佃壈鍤ч棁鈧憰浣虹翱绾喖褰茬憴浣圭潨娑撴柨鈧瑩鈧绻冩径褎妞傛稉宥埿曢崣鎴﹀櫢 SQL pivot閵?
- 閺傛澘顤?`records/record_070_daily_choice_stop_local_and_manager_isolate_paging.md`閿涘矁顔囪ぐ鏇炰粻濮濄垽娈㈤張鐑樻拱閸︽媽鎯ら悙骞库偓浣侯吀閻炲棝銆?isolate 閺屻儴顕楅崪宀冃曟惔鏇炲瀻妞ゅ吀鎱ㄦ径宥冣偓?
- 閺傛澘顤冩妯款吇缁岄缚褰嶇拫閬嶆肠閳ユ粍鍨滈崰婊勵偨閻ㄥ嫯褰嶉垾婵撶礉閺冄嗗殰鐎规矮绠熼悩鑸碘偓浣告躬閸旂姾娴囬崪灞肩箽鐎涙ɑ妞傛导姘冲殰閸斻劏藟姒绘劘顕氶梿鍡楁値閿涘奔绗栫粻锛勬倞妞ょ數顩﹀銏犲灩闂勩倛绻栨稉顏堢帛鐠併倝娉﹂崥鍫涒偓?
- 閺傛澘顤冪粻锛勬倞妞ら潧鍞寸純顔垮綅鐠嬫墎鈧粌鏋╁▎?閸旂姴鍙嗛垾婵嗩樋闁鑴婄粣妤嬬窗閻愮懓鍤弮鍫曠帛鐠併倕濮為崗銉⑩偓婊勫灉閸犳粍顐介惃鍕綅閳ユ繐绱濇稊鐔峰讲閸氬本妞傞崝鐘插弳閸忔湹绮稉顏冩眽閼挎粏姘ㄩ梿鍡愨偓?
- 閺傛澘顤冪粻锛勬倞妞ら潧褰告笟褍娴愮€规埃鈧粈绔撮柨顔兼礀閸掍即銆夋＃鏍も偓婵囪癁閸斻劍瀵滈柦顕嗙礉娴犮儱寮锋穱婵嗙摠閵嗕浇鐨熼弫娣偓浣稿閸忋儵娉﹂崥鍫㈢搼閸愭瑥鍙嗛崝銊ょ稊閻ㄥ嫬顦╅悶鍡曡厬闁喚鍍甸崣宥夘洯閵?
- 閺傛澘顤?`records/record_070_daily_choice_collection_favorites_and_risk_cleanup.md`閿涘矁顔囪ぐ鏇熸拱鏉烆噣娉﹂崥鍫濆弳閸欙絻鈧礁鏋╁▎銏ゆ肠閸氬牄鈧線顥撻梽鈺佺摟濞堝灚绔婚悶鍡楁嫲妤犲矁鐦夐崠鍛村櫢瀵よ櫣绮ㄩ弸婧库偓?
- 閺傛澘顤冩鐔绘皑闂?JSON 閸掑棔闊╅崠鍛嚤閸?鐎电厧鍙嗛懗钘夊閿涙氨鏁ら幋宄板讲娑撳搫缍嬮崜宥勯嚋娴滄椽顥ょ拫閬嶆肠闁瀚ㄦ穱婵嗙摠娴ｅ秶鐤嗙€电厧鍤敍灞肩瘍閸欘垯绮犻張顒€婀?JSON 閺傚洣娆㈢€电厧鍙嗘禒鏍︽眽閸掑棔闊╅惃鍕肠閸氬牄鈧浇鍤滅€规矮绠熼懣婊嗘皑閸滃奔閲滄禍楦跨殶閺佹番鈧?
- 閺傛澘顤?`records/record_070_daily_choice_collection_dropdown_import_export.md`閿涘矁顔囪ぐ鏇狀吀閻炲棝銆夐梿鍡楁値閸忋儱褰涢崢濠氬櫢閵嗕線鍣搁崨钘夋倳/閸掔娀娅庢稉瀣閹垮秳缍旈崪宀勵棨鐠嬮亶娉︾€电厧鍙嗙€电厧鍤潏鍦櫕閵?
- 閺傛澘顤冪粵娑⑩偓澶愩€嶇槐褍鍣剧仦鏇犮仛閿涙艾鍨庣猾姹団偓浣告簚閺咁垬鈧礁甯归崗鏋偓渚€鐝痪褏鐡柅澶婃嫲缁狅紕鎮婃い鐢电摣闁鑵戦敍灞炬弓闁鑵戞い閫涚矌閺勫墽銇氶崶鐐垼閿涘矂鈧鑵戞い瑙勬▔缁€娲偓澶愩€嶉崥宥冣偓?
- 閺傛澘顤?`records/record_070_daily_choice_compact_filter_controls.md`閿涘矁顔囪ぐ鏇犵摣闁銆嶇槐褍鍣剧仦鏇犮仛閸滃苯鐫嶅鈧崗銉ュ經婢х偛宸遍妴?
- 閺傛澘顤冪粻锛勬倞妞ょ數绮ㄩ弸鍕閸?part閿涙碍鐓＄拠?helper閵嗕够ection widgets閵嗕線娉﹂崥鍫濐嚤閸忋儱顕遍崙鎭掆偓浣衡€樼拋銈呰剨缁愭ぞ绮犳稉?`daily_choice_manager_sheet.dart` 缁夎鍤妴?
- 閺傛澘顤?`records/record_070_daily_choice_p1_p4_closure.md`閿涘矁顔囪ぐ?PLAN_070 P1-P4 閺€璺虹啲閵嗕礁鍨庢い浣冩嫹閸旂姵膩閸ㄥ鈧浇顓搁崚鎺斿Ц閹焦鐗庨崙鍡楁嫲妤犲矁鐦夌紒鎾寸亯閵?
- 閺傛澘顤?`records/record_070_daily_choice_copy_cleanup_and_main_merge.md`閿涘矁顔囪ぐ鏇熺槨閺冦儱鍠呯粵鏍ㄦ瀮濡楀牊鏁归崣锝冣偓浣哥磻閸欐垼顕╅弰搴″灩闂勩們鈧焦娼靛┃鎰潔缁€娲閽樺繐鎷伴崥鍫濇礀娑撹鍨庨弨顖濈珶閻ｅ被鈧?
- 閺傛澘顤冮崥鍐х矆娑斿牐鍤滅€规矮绠熼懣婊嗘皑缂傛牞绶崳銊⑩偓婊€绻氱€涙ê鍩屾鐔绘皑闂嗗棌鈧繂顦块柅澶婂隘閿涘本鏌婃晶鐐偓浣虹椽鏉堟垵鎷伴崣锕€鐡ㄦ稉顏冩眽閼挎粏姘ㄩ弮璺哄讲閸氬本顒為柅澶嬪婢舵矮閲滄稉顏冩眽妞嬬喕姘ㄩ梿鍡愨偓?
- 閺傛澘顤?`records/record_070_daily_choice_custom_recipe_collection_editor.md`閿涘矁顔囪ぐ鏇″殰鐎规矮绠熼懣婊嗘皑缂傛牞绶弮鍓佹畱妞嬬喕姘ㄩ梿鍡楊樋闁鍙嗛崣锝冣偓浣瑰灇閸涙ê鍙х化濠氬櫢閸愭瑨顕㈡稊澶婃嫲妤犲矁鐦夌紒鎾寸亯閵?

### 娣囶喗鏁?
- 鐏忓棗鎮楃紒顓炰紣娴ｆ粍绁﹂弰搴ｂ€樻稉鐚寸窗濮ｅ繗鐤嗛崗鍫熸纯閺傛媽顓搁崚鎺曠珶閻ｅ矉绱濋崘宥呯杽閺傝姤鏁奸崝顭掔礉鐎瑰本鍨氶崥搴㈡纯閺?changelog 娑撳氦顓搁崚鎺曠箻鎼达讣绱濋獮鑸靛瘻闂冭埖顔岄幓鎰唉閵?
- 閺勫海鈥樻稉瀣╃鏉烆喕绱崗鍫濐槱閻?P0 缁嬪啿鐣鹃幀褝绱板В蹇旀）閸愬磭鐡ラ崗銉ュ經娑撳秷顫﹂崥鍐х矆娑斿牐褰嶇拫鍗炵氨閸旂姾娴囬梼璇差敚閵嗕胶顓搁悶?sheet controller 閻㈢喎鎳￠崨銊︽埂瀹曗晜绨濋妴渚€娈㈤張娲桨閺夊灝浠犲銏″瘻闁筋喕缍呯純顔跨儲閸斻劌鎷伴弰搴㈡▔閸楋繝銆戦崗銉ュ經閵?
- `DailyChoiceHub` 閸掓繂顫愰崠鏍︾瑝閸愬秶鐡戝鍛倖娴犫偓娑斿牐褰嶇拫鍗炵氨閹芥顩﹂崝鐘烘祰鐎瑰本鍨氶敍娑㈩浕鐏炲繐褰х粵澶婄窡鏉炲鍣洪懛顏勭暰娑斿濮搁幀渚婄礉閸氬啩绮堟稊鍫ｅ綅鐠嬪崬绨遍崷銊ㄧ箻閸忋儱鎮嗘禒鈧稊鍫熌侀崸妤€鎮楅崥搴″酱鐠囪褰囬妴?
- 閸氬啩绮堟稊鍫ｇカ濠ф劗濮搁幀渚€娼伴弶鍨隘閸掑棗鎮楅崣鎷岊嚢閸欐牕鎷扮€瑰顥婇崝鐘烘祰閿涘矁顕伴崣鏍ㄦ埂闂傛潙褰цぐ鍗炴惙閸氬啩绮堟稊鍫熌侀崸妤勫殰闊偓绱濇稉宥夋▎婵夌偟鈹涙禒鈧稊鍫涒偓浣稿箵閸濐亜鍔归妴浣稿叡娴犫偓娑斿牆鎷伴崘宕囩摜閸斺晜澧滈妴?
- 闂呭繑婧€闂堛垺婢橀崐娆撯偓澶庡灦閸欐澘娴愮€规岸鐝惔锔肩礉闂呭繑婧€閺冨爼妾洪崚鑸电垼妫版ǜ鈧胶鐣濇禒瀣嫲閺嶅洨顒风悰灞炬殶閿涘矁顔€閸嬫粍顒涢幐澶愭尦娴ｅ秶鐤嗘穱婵囧瘮缁嬪啿鐣鹃妴?
- 鐏?`PLAN_070` 闂冭埖顔?2 閺嶅洩顔囨稉楦跨箻鐞涘奔鑵戦敍灞借嫙閸愭瑥鍙嗘＃鏍枂閺佺増宓佺€孤ゎ吀閸欐垹骞囬敍姝歷egetarian` 娑撳氦鍊濈猾?濞寸兘鐭為崘鑼崐 530 閺夆槄绱漙vegan_friendly` 娑撳骸濮╅悧鈺傗偓褔顥ら弶鎰暱缁?496 閺夆槄绱濋懣婊呴兇閺嶅洨顒峰ǎ宄板弳 notes 2221 閺夆槄绱漙濞撳懐婀￠崣瀣偨` 鐟欏嫬鍨拠瀛樻濞ｅ嘲鍙?notes 3416 閺夆槄绱漜ook CSV 599 鐞涘奔鑵?569 鐞涘本婀崷銊ョ秼閸撳秴绨遍弽鍥暯缁墽鈥橀崨鎴掕厬閵?
- `scripts/generate_daily_choice_recipe_dataset.py` 閸嬫粎鏁ら懛顏勫З閻㈢喐鍨?`halal_friendly`閵嗕梗vegan_friendly`閵嗕梗vegetarian_friendly` diet 閺嶅洨顒烽敍宀勪缉閸忓秵妫ゆ笟婵囧祦妤楊噣顥ら崣瀣偨閺嶅洨顒风紒褏鐢绘潻娑樺弳缁涙盯鈧鎷扮仦鏇犮仛閵?
- 閼挎粏姘ㄩ悽鐔稿灇閸ｃ劋绗夐崘宥嗗Ω閼挎粎閮撮弽鍥╊劮閹存牗绔婚惇鐔活嚛閺勫骸鍟撻崗?notes閿涘苯鑻熺紒鐔剁濞撳懐鎮?`??`閵嗕焦娴涢幑銏㈩儊缁涘濞婇崣鏍﹁础閻降鈧?
- 妞嬬喐娼楅幎钘夊絿閺€鍓佹彛妤傛﹢顥撻梽鈺佸焼閸氬稄绱癭閾斿獖 娑撳秴鍟€娴ｆ粈璐熸ウ陇娉茬憗姝岀槤閸栧綊鍘ら敍瀹嶅ú瀣嚂` 娑撳秴鍟€鐠囶垳鍌ㄥ鏇氳礋 `閽佺浗閿涘畭閹烘帡顎嘸閵嗕梗閻氼亪鍣烽懘濂伴妴涔ｉ悮顏呰ˉ`閵嗕梗閻氼亣鍊絗閵嗕梗閻氼亣绠榒 缁涘鍙挎担鎾跺皳閼插銆嶆稉宥呭晙閹舵ê褰旈幋鎰扳偓姘辨暏 `閻氼亣鍊漙閵?
- 閸斻劎澧块幀褔顥撻梽鈺佸灲閺傤叀藟閸忓懎鍘伴懖澶堚偓渚€绶归懖澶堚偓浣烘暢妤哥鈧線闄勯妴渚€绠ゆィ鎴欌偓渚€绠欓懖澶堚偓浣烘暞妤β扳偓浣哄閾旀瑣鈧胶澧堕摂搴涒偓浣芥础閵嗕浇娈炵粵澶庣槤閿涘畭profile:vegetarian` 閸欘亜婀崢鐔奉潗閺傚洦婀伴張顏勬嚒娑擃叀鍊濈猾?濮樼繝楠囨搴ㄦ珦閺冭泛鍟撻崗銉ｂ偓?
- 鐏?YunYouJun/cook `recipe.csv` 鐎电厧鍙嗛悽鐔稿灇閸ｃ劋缍旀稉?`cook_csv` 閺佺増宓侀弶銉︾爱閿涘奔绻氶悾?difficulty閵嗕辜ags閵嗕沟ethods閵嗕辜ools閵嗕攻v閵嗕够tuff 閸掓壆绮ㄩ弸鍕 attributes閿涘苯鑻熼柆鍨帳閸愭瑥鍙嗛悽銊﹀煕閸欘垵顫?sourceLabel閵嗕够ourceUrl 閸?references閵?
- SQLite 鐎电厧鍤?meta 閻滄澘婀崘娆忓弳閻喎鐤?`bookRecipeCount` 娑?`cookRecipeCount`閿涘奔绌舵禍搴℃倵缂侇叀褰嶇拫閬嶆肠閸掑棜銆冮崪宀€顓搁悶鍡涖€夌仦鏇犮仛閵?
- 鐏?`PLAN_070` 闂冭埖顔?3 閺嶅洩顔囨稉楦跨箻鐞涘奔鑵戦敍灞借嫙閺勫海鈥橀張顒冪枂鏉堝湱鏅稉鐑樻殶閹诡喖绨辨稉搴ｅ偍瀵洝顔曠拋鈽呯礉娑撳秶娲块幒銉ㄧ讣缁?Flutter 鐠囪褰囬柅鏄忕帆閵?
- v2 schema 鐠佹崘顓告稉?14 瀵姾銆冮妴?8 娑擃亞鍌ㄥ鏇窗閼挎粏姘ㄩ梿鍡愨偓浣哥唨绾偓缁便垹绱╅妴浣规喅鐟曚降鈧浇顕涢幆鍛偓浣规綏閺?濮濄儵顎冪悰宀冦€冮妴渚€鈧氨鏁ょ粵娑⑩偓澶屽偍瀵洏鈧線顥ら弶鎰瑩閻劎鍌ㄥ鏇樷偓浣规偝缁便垺鏋冮張顑锯偓浣规拱閸︽壆鏁ら幋椋庡Ц閹礁鎷伴梿鍡楁値閹存劕鎲崇悰銊ｂ偓?
- 妞嬬喐娼楅崠褰掑帳缁便垹绱╅幏鍡曡礋 `raw`閵嗕梗canonical`閵嗕梗family` 娑撳鐪伴敍灞借嫙婢х偛濮?`idx_dcr_ingredient_value_lookup` 娣囨繈娈版妯款吇 raw/canonical 閺屻儴顕楅妴?
- 鐏?`D:\vocabularySleep-resources\cook_data_plan070_validation` 娑擃厺绗佹禒?JSON 閸樺缂夋稉杞扮瑐娴肩姴澧犻悧鍫熸拱閿涙瓪daily_choice_recipe_library.json` 19,614,095 bytes閵嗕梗daily_choice_recipe_library_summary.json` 4,918,383 bytes閵嗕梗recipe_library_asset.json` 19,614,095 bytes閵?
- `DailyChoiceEatLibraryStore.installLibrary()` 閺€閫涜礋鏉╂粎顏?SQLite 閸婃瑩鈧鏋冩禒璺虹暔鐟佸拑绱伴崗鍫滅瑓鏉炶棄鍩?`.remote` 閸婃瑩鈧?DB閿涘矁顫夐懠?meta 楠炶埖鐗庢宀冨綅鐠嬭鲸鏆熼敍宀勨偓姘崇箖閸氬孩澧犻弴鎸庡床瑜版挸澧犵€瑰顥婃惔鎾扁偓?
- `inspectStatus()` 閸︺劍婀€瑰顥?SQLite 閺傚洣娆㈤弮璺哄涧鏉╂柨娲栫粚铏瑰Ц閹緤绱濇稉宥呭晙娑撹桨绨″Λ鈧弻銉уЦ閹礁鍨卞铏光敄閺佺増宓佹惔鎾存瀮娴犺翰鈧?
- 瀹告煡鐛欑拠浣烘暏閹磋渹绗傛导鐘插煂 S3 `/cook_data` 閻ㄥ嫯绻欑粩顖氬瘶閿涙俺绻嶇悰灞炬姒涙顓?key `cook_data/daily_choice_recipe_library.db` 閸?HEAD閵嗕购ange 閸滃苯鐣弫缈犵瑓鏉炴枻绱濇稉瀣祰閸?v1 summary/detail 閸у洣璐?7,772 鐞涘被鈧?
- `scripts/generate_daily_choice_recipe_dataset.py` 閻?SQLite 鐎电厧鍤弨閫涜礋 v1/v2 閸欏苯鍟撻敍姘箽閻ｆ瑧骞囬張?v1 runtime 鐞涱煉绱濋崥灞炬閸愭瑥鍙嗛懣婊嗘皑闂嗗棎鈧箍2 閸╄櫣顢呯槐銏犵穿閵嗕焦鎲崇憰浣碘偓浣筋嚊閹懌鈧焦娼楅弬?濮濄儵顎冮妴浣虹摣闁鍌ㄥ鏇樷偓渚€顥ら弶?raw/canonical/family 缁便垹绱╅妴浣规偝缁便垺鏋冮張顒€鎷伴梿鍡楁値缂佺喕顓哥悰銊ｂ偓?
- 閸氬啩绮堟稊鍫ヮ樀濞堢敻绮拋銈嗘暭娑撹　鈧粌鍙忛柈銊⑩偓婵撶礉catalog 閸?`mealId == 'all'` 閺冭泛鐔€娴滃骸鐣弫鏉戔偓娆撯偓澶嬬潨缁涙盯鈧绱濇稉宥呭晙閹稿缍嬮崜宥嗘闂傚瓨鍨ㄩ崡鍫ヮ樀姒涙顓婚弨鍓佺崕閵?
- 韫囧苯褰涙０鍕啎缁墽鐣濇稉娲浘閼挎嚎鈧焦鎹ｆご婧库偓浣藉С閻㈢喎娼ラ弸婧库偓渚€鍘划淇扁偓浣借崋濡炴帪绱遍懞杈╂晸閸ф碍鐏夐崷銊х摣闁鐪扮仦鏇炵磻娑?`peanut` + `nut`閿涘奔绻氶幐?UI 缁犫偓濞蹭椒绲炬稉宥勬丢鏉╁洦鎶ょ拠顓濈疅閵?
- 妞嬬喐娼楅崠褰掑帳缂佈呯敾閺€鍓佹彛閿涙瓪閹烘帡顎嘸閵嗕胶灏撻煫鍕┾偓浣哄皳閼叉縿鈧胶灏撻懖姘モ偓浣哄皳濞屽箍鈧胶浼€閼佃￥鈧礁鐓块弽骞库偓浣藉帪閼插鈧浇鍘為懖鐘电搼閸忚渹缍嬮悮顏囧€濇い閫涚瑝閸愬秳缍旀稉娲帛鐠?`pork` 妞嬬喐娼楅崥灞肩疅鐠囧稄绱濋崣顏勬躬 v2 family index 閸?contains 閹烘帡娅庨柌灞炬▔瀵繐缍婇崗銉у皳閼插銇囩猾姹団偓?
- `scripts/generate_daily_choice_recipe_dataset.py` 閻?SQLite 鐎电厧鍤妯款吇閺€閫涜礋 v2-only閿涙盯娓剁憰浣稿悑鐎硅妫?runtime 閺冭泛褰查弰鎯х础娴ｈ法鏁?`--sqlite-mode v1-v2`閵?
- v2 SQLite 鐎电厧鍤崘娆忓弳 `PRAGMA user_version=2`閿涘奔绌舵禍搴濈瑐娴肩姴鎮楄箛顐︹偓鐔荤槕閸?schema 閻楀牊婀伴妴?
- `scripts/audit_daily_choice_recipe_dataset.py` 閺€顖涘瘮閼奉亜濮╃拠鍡楀焼 v2-only DB閿涘奔绗夐崘宥呭繁娓氭繆绂?v1 summary/detail 鐞涖劊鈧?
- `scripts/verify_daily_choice_recipe_remote.dart` 閺€顖涘瘮 v1閵嗕箍2 閹?v1/v2 閸欏苯鍟?DB 閻ㄥ嫯绻欑粩?smoke 妤犲矁鐦夐妴?
- 瀹告煡鐛欑拠浣烘暏閹撮攱娲块弬鏉挎倵閻?S3 `cook_data/daily_choice_recipe_library.db` 娑?v2-only DB閿涙俺绻欑粩顖氥亣鐏?142,467,072 bytes閿涘畭user_version=2`閿涘瘉2 recipes/summaries/details 閸у洣璐?7,772 鐞涘被鈧?
- `DailyChoiceEatLibraryStore` 婢х偛濮?schema 閼奉亜濮╃拠鍡楀焼閿涘奔绱崗鍫ｎ嚢閸?v2 鐞涱煉绱濋崥灞炬娣囨繄鏆€ v1 閺冄冪氨鐠囪褰囬懗钘夊閵?
- `DailyChoiceEatLibraryStore` 閻ㄥ嫯绻欑粩?DB 鐎瑰顥婅ぐ鎺嶇閸栨牗瀵?schema 閸愭瑥鍙?meta閿涙2 閸愭瑥鍙?`daily_choice_recipe_schema_meta`閿涘瘉1 缂佈呯敾閸愭瑥鍙?`daily_choice_eat_recipe_meta`閵?
- 閸氬啩绮堟稊鍫濆敶缂冾喛褰嶇拫杈ㄦ喅鐟曚浇顕伴崣鏍ㄦ煀婢?v2 閺屻儴顕楃捄顖氱窞閿涙矮绮?`daily_choice_recipes` + `daily_choice_recipe_summaries` 鐠囪褰囨潪濠氬櫤閹芥顩﹂敍宀冾嚊閹懌鈧焦娼楅弬娆嶁偓浣诡劄妤犮倗鎴风紒顓熷瘻闂団偓娴?`daily_choice_recipe_details` 閹虫帒濮炴潪濮愨偓?
- `DailyChoiceEatLibraryStore.queryBuiltInSummaries()` 閸?v2 DB 娑擃厺濞囬悽?`daily_choice_recipe_filter_index` 婢跺嫮鎮婃鎰唽閵嗕礁甯归崗宄版嫲 trait 缁涙盯鈧绱濋獮鏈靛▏閻?`daily_choice_recipe_ingredient_index` 閻?raw/canonical 鐏炲倸顦╅悶鍡楃箟閸欙絾甯撻梽銈呮嫲瀹稿弶婀佹鐔告綏娴兼ê鍘涢崠褰掑帳閵?
- legacy v1 鎼存挸鎷扮紓鍝勭毌 v2 缁涙盯鈧鍌ㄥ鏇犳畱鎼存挾鎴风紒顓炴礀闁偓閸掓澘鍞寸€?`DailyChoiceEatCatalog` 鏉╁洦鎶ら敍宀勪缉閸忓秵鐓＄拠銏犲弳閸欙絽濂栭崫宥呭嚒閺堝婀伴崷鏉跨氨閸欘垵顕伴幀褋鈧?
- v2 闂呭繑婧€閸婃瑩鈧?id 閺屻儴顕楅幐?`random_key` 閹烘帒绨獮璺哄箵闁插稄绱濋柆鍨帳 raw/canonical 閸氬本妞傞崨鎴掕厬閺冩儼顔€閸氬奔绔撮懣婊嗘皑閸︺劑娈㈤張鐑樼潨娑擃參鍣告径宥呭毉閻滆埇鈧?
- v2 random pivot 婢跺秶鏁?`DailyChoiceEatLibraryQuery` 閺夆€叉閿涘苯鑻熼崷?pivot 閸氬骸宕愬▓鍨￥閸涙垝鑵戦弮璺烘礀缂佹洖鍩岄崐娆撯偓澶嬬潨瀵偓婢惰揪绱遍梾蹇旀簚閹惰棄褰囨稉宥堫嚢閸欐牞顕涢幆鍛摟濞堢偣鈧?
- 閸氬啩绮堟稊鍫滃瘜 UI 閸︺劑娈㈤張鐑樼潨閸忋劋璐熼崣顖濐潌閸愬懐鐤嗛懣婊嗘皑閺冭绱濋崑婊勵剾闂呭繑婧€娴兼俺鐨熼悽?`pickBuiltInRandomSummary(...)` 娴ｆ粈璐熼張鈧紒鍫モ偓澶夎厬閺夈儲绨敍娑㈡閺堢儤鐫滃ǎ宄板弳閺堫剙婀撮懛顏勭暰娑斿妞傜紒褏鐢绘担璺ㄦ暏閸愬懎鐡ㄧ紒鎾寸亯閵?
- 闂呭繑婧€闂堛垺婢橀崷銊モ偓娆撯偓澶嬬潨閸欐ê瀵查弮鏈电窗鐠佲晙绮涢崷銊ㄧ箻鐞涘瞼娈戝鍌涱劄閺堚偓缂佸牊濞婇崣鏍с亼閺佸牞绱濋柆鍨帳閺冄呯摣闁绮ㄩ弸婊冩礀閸愭瑥鍩岄弬鎵摣闁鈧瑩鈧鐫滈妴?
- 缁狅紕鎮婃い闈涙倖娴犫偓娑斿牆鍞寸純顔肩氨娴ｈ法鏁?`queryBuiltInSummaries(...)` 閸掑棝銆夌拠璇插絿閿涙稒鎮崇槐銏ｇ槤闂堢偟鈹栭弮璺烘倱濮濄儰绱剁紒?store閿涘苯鑻熸导妯哄帥娴ｈ法鏁?v2 `daily_choice_recipe_search_text` 閺屻儴顕楅妴?
- 缁狅紕鎮婃い闈涚磽濮?SQL 閺屻儴顕楅崷?sheet 閸忔娊妫撮崥搴濈瑝閸愬秷鐨熼悽?`setSheetState`閿涘奔绗栨径杈Е閺冩儼顔囪ぐ鏇炵秼閸撳秵鐓＄拠?key閿涘矂妾锋担搴″彠闂?鏉╂柨娲栭崪灞姐亼鐠愩儵鍣哥拠鏇犳畱閻㈢喎鎳￠崨銊︽埂妞嬪酣娅撻妴?
- 閸氬啩绮堟稊鍫ｎ嚊閹?娑擃亙姹夌拫鍐╂殻/閸欙箑鐡ㄩ崗銉ュ經閻ㄥ嫬鍞寸純顔垮綅鐠嬪崬鍨介弬顓熸暭娑撳搫鐔€娴滃孩膩閸фぜ鈧礁鐣ㄧ憗鍛Ц閹礁鎷版潪濠氬櫤閹芥顩﹂崘鍛啇閿涘奔绗夐崘宥堫洣濮瑰倸缍嬮崜宥呭敶鐎?`builtInOptions` 閸忋劑鍣洪崚妤勩€冮崠鍛儓鐠?id閵?
- 缁狅紕鎮婃い闈涙倖娴犫偓娑斿牆鍞寸純顔垮綅鐠嬭京娈戠拠锔藉剰閵嗕椒閲滄禍楦跨殶閺佹番鈧礁褰熺€涙ê鍙嗛崣锝囩埠娑撯偓閹恒儱鍙嗛弶锛勬窗缁狙冪磽濮濄儱濮╂担婊呭Ц閹緤绱遍崝銊ょ稊鏉╂稖顢戞稉顓濈窗缁備胶鏁ら崥灞肩閺夛紕娲伴惃?detail/edit/copy 閸忋儱褰涢敍灞借嫙閸︺劍娼惄顔煎敶鐏炴洜銇?loading 閹存牠鏁婄拠顖氬冀妫ｅ牄鈧?
- 閸氬啩绮堟稊鍫㈩吀閻炲棝銆夐崘鍛靶曢崣鎴ｎ嚊閹懓顕伴崣鏍ㄦ閻?manager sheet 閹垫寧甯寸仦鈧柈銊╂晩鐠囶垽绱辨稉?UI 閻ㄥ嫯顕涢幆鍛瘻闁筋喕绮涘▽璺ㄦ暏 SnackBar 闁挎瑨顕ら崣宥夘洯閵?
- 缁狅紕鎮婃い闈涙倖娴犫偓娑斿牆鍞寸純顔肩氨缁夊娅庨垾婊呮埛缂侇厼濮炴潪瑙ｂ偓婵囧瘻闁筋噯绱濋弨閫涜礋濠婃艾濮╅幒銉ㄧ箮鎼存洟鍎撮弮鎯板殰閸斻劑鈧帒顤?SQL 閺屻儴顕?limit閿涘苯鑻熼崷銊ュ鏉炴垝绗呮稉鈧い鍨娣囨繄鏆€瑜版挸澧犲鍙夋▔缁€鐑樻喅鐟曚降鈧?
- 缁狅紕鎮婃い鍨偝缁便垺顢嬮弨閫涜礋缂佸嫪娆㈢痪?`TextEditingController` / `FocusNode` 缁狅紕鎮婇敍娑滅翻閸忋儱褰ч弴瀛樻煀 draft閿涘瞼顬囧鈧潏鎾冲弳濡楀棙鍨ㄩ幓鎰唉閹兼粎鍌ㄩ崥搴㈠閸掗攱鏌?SQL 閹兼粎鍌ㄧ拠宥冣偓?
- 閸氬啩绮堟稊鍫滃瘜 UI 閸嬫粍顒涢梾蹇旀簚閺冭绱濋弮鐘绘閽?娑擃亙姹夌拫鍐╂殻/妞嬬喕姘ㄩ梿鍡欏閺夌喓娈戦崘鍛枂閸婃瑩鈧鐫滄稉宥呭晙閹跺﹤鍙忛柌?id 閸掓銆冩导鐘电舶 `pickBuiltInRandomSummary(...)`閿涘本鏁兼稉铏规纯閹恒儱顦查悽銊ョ秼閸?SQL 缁涙盯鈧娼禒韬测偓?
- 闂団偓鐟曚胶绨跨涵顔煎讲鐟欎焦鐫滈惃鍕閺堝搫浠犲銏犳簚閺咁垵瀚㈤崐娆撯偓?id 鐡掑懓绻?300 娑擃亷绱濇导姘崇儲鏉?store random pivot 楠炴湹绻氶悾娆忕秼閸撳秹鏀ｇ€规艾鈧瑩鈧绱濋柆鍨帳閺嬪嫰鈧姴銇?`IN (...)` 閺屻儴顕楅妴?
- 閸氬啩绮堟稊鍫滃瘜 UI 閸嬫粍顒涢梾蹇旀簚閺€閫涜礋缁绢垱婀伴崷浼存敚鐎规艾缍嬮崜宥呪偓娆撯偓澶涚礉娑撳秴鍟€鐟欙箑褰?`pickBuiltInRandomSummary(...)`閿涙硞tore random pivot 娣囨繄鏆€娑撳搫绨崇仦鍌濆厴閸旀冻绱濇担鍡曠瑝閸愬秳缍呮禍搴′粻濮濄垺瀵滈柦顔煎彠闁款喕姘︽禍鎺楁懠鐠侯垬鈧?
- `DailyChoiceEatLibraryStore.queryBuiltInSummaries(...)` 娴兼ê鍘涢柅姘崇箖 `Isolate.run` 閸︺劌鎮楅崣?isolate 闁插秵鏌婇幍鎾崇磻 SQLite 閺傚洣娆㈤幍褑顢戦崚鍡涖€?閹兼粎鍌ㄩ弻銉嚄閿涘苯銇戠拹銉︽閸ョ偤鈧偓閺冄冩倱濮濄儴鐭惧鍕┾偓?
- 缁狅紕鎮婃い闈涘敶缂冾喖绨遍懛顏勫З閸掑棝銆夐梽銈囨磧閸氼剚绮撮崝銊┾偓姘辩叀婢舵牭绱濇导姘躬 SQL 鏉╂柨娲栭崥搴ｆ畱娑撳绔寸敮褎顥呴弻銉ョ秼閸撳秵绮撮崝銊ょ秴缂冾噯绱濇穱顔碱槻瀹歌尙绮￠崑婊冩躬鎼存洟鍎撮弮鑸电梾閺堝鏌婂姘З娴滃娆㈢€佃壈鍤ф稉宥囨埛缂侇厼濮炴潪鐣屾畱闂傤噣顣介妴?
- 閸氬啩绮堟稊鍫濐樆鐏炲倿娈㈤張鍝勫弳閸欙絿骞囬崷銊ф纯閹恒儱鐫嶇粈楦垮綅鐠嬮亶娉﹂柅澶嬪閿涘瞼鏁ら幋宄扮磻婵娈㈤張鍝勫閸楀啿褰查柅澶嬪閳ユ粌鍞寸純顔垮綅鐠嬫墎鈧繃鍨ㄦ稉顏冩眽閼挎粏姘ㄩ梿鍡礉闁灝鍘ゆ妯款吇閹粯妲搁崷銊ョ暚閺佹潙銇囨惔鎾茶厬闂呭繑婧€閵?
- 姒涙顓婚崘鍛枂鎼存挸褰涘鍕劀瀵繒绮烘稉鈧稉琛♀偓婊冨敶缂冾喛褰嶇拫鎵佲偓婵撶礉缁狅紕鎮婃い闈涙嫲婢舵牕鐪伴崗銉ュ經娑撳秴鍟€娴ｈ法鏁ら垾婊勫閺堝褰嶇拫?/ 閸忋劑鍎撮懣婊嗘皑閳ユ繀缍旀稉鍝勫敶缂冾喖绨遍崥宥囆為妴?
- 缁狅紕鎮婃い纰樷偓婊€绗夐崰婊勵偨閳ユ繈娈ｉ挊蹇撳З娴ｆ粌顤冮崝鐘碘€樼拋銈呰剨缁愭绱濋柆鍨帳鐠囶垵袝閿涙盯娈ｉ挊蹇斿灗閹垹顦查崥搴濈箽閻ｆ瑥缍嬮崜?sheet閵嗕焦鎮崇槐銏犳嫲閸掑棝銆夋稉濠佺瑓閺傚洢鈧?
- 閹兼粎鍌ㄦ潏鎾冲弳濡楀棝鐝惔锔芥暪缁毖傝礋娑撳孩姊烘潏瑙勫瘻闁筋喗娲块幒銉ㄧ箮閿涘苯鍣虹亸鎴狀吀閻炲棝銆夋い鍫曞劥瀹搞儱鍙块崠铏规畱鐟欏棜顫庨柨娆庣秴閵?
- 閸氬啩绮堟稊?UI 缁夊娅庢顕€顥ら崣瀣偨閻ㄥ嫯绶熼崝鈺冪摣闁鍙嗛崣锝忕礉閸嬫俺褰嶉幐鍥у础娑撳秴鍟€鐏炴洜銇氬〒鍛埂缁涘娓剁憰浣烘暏閹寸柉鍤滅悰灞藉灲閺傤厾娈戦崗鎶芥暛閹绘劗銇氶妴?
- 閻㈢喐鍨氶崳銊ユ嫲 v2 schema 缁夊娅庨懣婊嗘皑鐠ч攱绨崷鏉跨摟濞堢绱濇宀冪槈閸?JSON/SQLite 娑撳秴鍟€閸愭瑥鍙?`origin` 閹?`diet` 鐎涙顔岄敍娑橆吀鐠伮ゅ壖閺堫剛鎴风紒顓濈箽閻ｆ瑩顥撻梽鈺傤梾閺屻儲銆婇悽銊ょ艾绾喛顓绘潻娆庣昂鐎涙顔屽▽鈩冩箒閸ョ偞绁﹂妴?
- 缁狅紕鎮婃い纰樷偓婊勫灉閻ㄥ嫰顥ょ拫閬嶆肠閳ユ繀绗夐崘宥呮倱閺冭泛鐫嶇粈娲偓澶嬪 chip 閸滃矂娉﹂崥鍫濆幢閻楀浄绱濋弨閫涜礋閸楁洑绔存稉瀣濡楀棝鈧瀚ㄨぐ鎾冲閼煎啫娲块敍娑㈠櫢閸涜棄鎮曢妴浣稿灩闂勩倖瀵滈柦顔兼祼鐎规艾婀稉瀣濡楀棙姊烘潏骞库偓?
- 姒涙顓婚垾婊勫灉閸犳粍顐介惃鍕綅閳ユ繈娉﹂崥鍫㈡埛缂侇厼褰堟穱婵囧Б閿涘奔绗夐懗浠嬧偓姘崇箖缁狅紕鎮婃い鐢稿櫢閸涜棄鎮曢幋鏍у灩闂勩倧绱遍崗鏈电铂娑擃亙姹夐梿鍡楁値閸欘垰婀稉瀣濡楀棙姊洪幍褑顢戦柌宥呮嚒閸氬秴鎷伴崚鐘绘珟閵?
- 妞嬬喕姘ㄩ梿鍡楊嚤閸戝搫瀵橀崠鍛儓闂嗗棗鎮庨崗鍐╂殶閹诡喓鈧線娉﹂崥鍫濆敶閺堫剙婀撮懛顏勭暰娑斿褰嶇拫渚库偓浣烽嚋娴滈缚鐨熼弫纾嬪綅鐠嬪崬鎷伴崘鍛枂閼挎粏姘?id 瀵洜鏁ら敍娑橆嚤閸忋儲妞傞悽鐔稿灇閺傛壆娈戦梿鍡楁値 id閿涘矂浼╅崗宥堫洬閻╂牕鍑￠張澶愭肠閸氬牄鈧?
- 妞嬬喕姘ㄩ梿鍡楊嚤閸忋儰绱伴弽锟犵崣閸掑棔闊╅崠鍛壐瀵繒澧楅張顒婄礉閺傚洣娆㈤崘鍛啇閺冪姵纭剁拠璇插絿閺冩湹绱伴弰鍓с仛鐎电厧鍙嗘径杈Е閹绘劗銇氶敍灞肩瑝閸愬秹娼ゆ妯绘￥閸濆秴绨查妴?
- `ToolboxSelectablePill` 閺€顖涘瘮闂呮劘妫岄弬鍥х摟閺嶅洨顒烽獮鏈电箽閻?tooltip/鐠囶厺绠熼弽鍥╊劮閿涘奔绌舵禍搴Ｐ╅崝銊ь伂閹跺﹦鐡柅澶愩€嶇亸浠嬪櫤閸樺婀稉鈧悰灞藉敶閵?
- 閸氬啩绮堟稊鍫ｇカ濠ф劕鍣径鍥モ偓渚€鐝痪褑顔曠純顔兼嫲缁狅紕鎮婃い闈涘讲鐏炴洖绱戦崠铏规畱鐏炴洖绱?閺€鎯版崳閹稿鎸虫晶鐐插濞村懓澹婇懗灞炬珯閵嗕浇绔熷鍡楁嫲 accent 閼硅绱濋幓鎰磳閸欘垳鍋ｉ崙鏄忕槕閸掝偄瀹抽妴?
- 缁狅紕鎮婃い闈涘敶缂冾喛褰嶇拫?SQL 閸掑棝銆夋禒搴樷偓婊勫⒖婢?limit 闁插秴褰囬崜宥呯碍閹芥顩﹂垾婵囨暭娑?`offset + pageSize` 鏉╄棄濮炴い纰夌礉鐟欙箑绨抽崝鐘烘祰娑撳绔存い鍨閸欘亣顕Ч鍌涙煀婢х偟鐛ラ崣锝冣偓?
- PLAN_070 闂冭埖顔屾潻娑樺閸?13 妞ゅ綊鐛欓弨鎯般€冨鍙夊瘻瑜版挸澧犵€圭偟骞囬弽鈥冲櫙閿涘本妲戠涵顔诲瘜 UI 閸嬫粍顒涢梾蹇旀簚娴犮儱鎼锋惔鏃€鈧傜喘閸忓牞绱濈捄顖滄暠缁狙勫妞ら潧鎷伴張鈧潻?3 娑擃亣鍤滅€规矮绠熻箛灞藉經娑撳搫鎮楃紒顓烆杻瀵亽鈧?
- PLAN_070 闂冭埖顔?7 瀹告彃鐣幋鎰拱鏉烆喗鏁圭亸楣冪崣鐠囦緤绱遍崗銊╁櫤 `flutter analyze` 娴犲秳绻氶悾娆愭拱鏉烆喖顦婚弮銏℃箒 lint 閸婄尨绱滱ndroid release APK 閺嬪嫬缂撻柅姘崇箖閵?
- 濮ｅ繑妫╅崘宕囩摜濡€虫健閺傚洦顢嶇€瑰本鍨氭稉鈧潪顔婚獓閸濅礁瀵查弨璺哄經閿涙艾鎮嗘禒鈧稊鍫ｇカ濠ф劗濮搁幀浣规暭娑撻缚褰嶇拫鍗炵氨閸戝棗顦幓鎰仛閿涘苯骞撻崫顏勫姽閵嗕胶鈹涙禒鈧稊鍫涒偓浣镐粵閼挎粍瀵氶崡妤€鎷伴崘宕囩摜閸斺晜澧滅粔濠氭珟閳ユ粍婀版潪?/ 閸氬海鐢?/ 閹碘晛鐫嶆潏鍦櫕 / 鐠у嫭鏋￠弶銉︾爱閳ユ繄琚鈧崣鎴ｎ嚛閺勫簺鈧?
- 鐠囷附鍎忔い鍏哥瑝閸愬秵瑕嗛弻?sourceLabel閵嗕够ourceUrl 閹?references 閺夈儲绨崸妤嬬礉娣囨繄鏆€閼挎粌鎼ч悽璇插剼閵嗕焦娼楅弬?閺夆€叉閵嗕焦顒炴銈冣偓浣稿彠闁款喗褰佺粈鍝勬嫲閸︽澘娴橀幖婊呭偍鐠囧秴顦查崚鍓佺搼閻劍鍩涢惄瀛樺复闂団偓鐟曚胶娈戦崘鍛啇閵?
- 閸氬啩绮堟稊鍫㈩吀閻炲棝銆夐弬鏉款杻/缂傛牞绶稉顏冩眽閼挎粏姘ㄩ妴浣稿綗鐎涙ê鍞寸純顔垮綅鐠嬪彉璐熸稉顏冩眽閼挎粏姘ㄩ弮璁圭礉娴兼碍濡哥紓鏍帆閸ｃ劏绻戦崶鐐垫畱妞嬬喕姘ㄩ梿鍡涒偓澶嬪缁墽鈥橀崘娆忔礀闂嗗棗鎮庨幋鎰喅閸忓磭閮撮敍娑楃瑝閸曢箖鈧鎹㈡担鏇㈡肠閸氬牊妞傛禒鍛箽鐎涙ü璐熸稉顏冩眽閼挎粏姘ㄩ妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛崣顏勭紦缁斿甯寸粻陇顓搁崚鎺炵礉娑撳秶娲块幒銉ゆ叏閺€閫涚瑹閸旓繝鈧槒绶崪宀冪箼缁?閺堫剙婀撮懣婊嗘皑閺佺増宓侀敍娑樼杽闂勫懏鏆熼幑顔界濞叉ぜ鈧够chema 鏉╀胶些閸?UI 閹峰棗鍨庣亸鍡楁躬閸氬海鐢婚梼鑸殿唽閸掑棙澹掗拃钘夋勾閵?
- `plans/` 閻╊喖缍嶉崷銊ョ秼閸撳秳绮ㄦ惔?`.gitignore` 娑擃參绮拋銈呮嫹閻ｃ儻绱濋張顒冾吀閸掓帡娓剁憰浣风稊娑撶儤婀板▎鈩冨复缁犫€冲殶閹诡喖宸遍崚鍓佹捈閸忋儲褰佹禍銈冣偓?
- 閸氬啩绮堟稊鍫熸喅鐟曚礁濮炴潪鑺ユ暭娑撶儤膩閸ф楠囬崥搴″酱娴犺濮熼崥搴礉閹芥顩﹂張顏勭暚閹存劕澧犻崥鍐х矆娑斿牆鈧瑩鈧鐫滄导姘箽閹镐椒璐熺粚鍝勮嫙閺勫墽銇氱挧鍕爱閸戝棗顦悩鑸碘偓渚婄幢鏉╂瑦妲搁張澶嬪壈闂勫秶楠囬敍宀€鏁ら弶銉﹀床閸欐牗鐦￠弮銉ュ枀缁涙牕鍙炬禒鏍侀崸妞剧瑝鐞氼偊妯嗘繅鐐偓?
- 閺堫剝鐤嗛悽鐔稿灇閻ㄥ嫰鐛欑拠浣稿瘶娴ｅ秳绨?`D:\vocabularySleep-resources\cook_data_plan070_validation`閿涘苯鐨婚張顏囶洬閻?`D:\vocabularySleep-resources\cook_data`閿涙稑鎮楃紒顓犫€樼拋銈呮倵閸愬秵澧界悰灞炬禌閹广垺鍨ㄦ稉濠佺炊閵?
- cook CSV 閸樼喎顫?599 鐞涘奔鑵戦幐澶嬬垼妫?閸樸劌鍙块崢濠氬櫢鐎电厧鍙?593 閺壜ゅ綅鐠嬫唻绱濇担鍡楊吀鐠佲剝瀵滈弽鍥暯绾喛顓?599 鐞涘苯鍙忛柈銊ュ讲閸︺劍鏌婃惔鎾茶厬閸涙垝鑵戦妴?
- v2 schema 瀹稿弶甯撮崗?app 鏉╂劘顢戦弮鍓佹畱鐎瑰顥婇妴浣哄Ц閹降鈧焦鎲崇憰浣告嫲鐠囷附鍎忕拠璇插絿鐠侯垰绶為敍娑樻倵缂侇厺绮涢棁鈧憰浣瑰Ω閸掑棝銆夐妴浣虹摣闁鍌ㄥ鏇熺叀鐠囥垹鎷?random pivot 娑撳鐭囬崚?v2 SQL閵?
- SQLite 娴犲秹娓剁憰浣风瑓鏉炶棄鍩屾惔鏃傛暏閺€顖涘瘮閻╊喖缍嶉崥搴㈠閼宠姤鐓＄拠顫幢閺堫剝鐤嗛垾婊€绗夋穱婵堟殌閺堫剙婀撮垾婵囨暪閸欙絼璐熸稉宥呭晙娣囨繄鏆€閹存牜鏁撻幋?JSON 閸忔粌绨崇紓鎾崇摠閿涘矁鈧奔绗夐弰顖涚ウ瀵繑鐓＄拠銏ｇ箼缁?SQLite閵?
- 閸氬啩绮堟稊鍫ｇ箼缁旑垶顩荤憗鍛亼鐠愩儰绗栭弮鐘虫＋鎼存挻妞傛导姘崇箲閸ョ偤鏁婄拠顖滃Ц閹礁鎷扮粚鍝勨偓娆撯偓澶嬬潨閿涘奔绗夐崘宥夋饯姒涙鏁撻幋?fallback 閼挎粏姘ㄦ惔鎿勭幢鏉╂瑦妲搁張澶嬪壈鐠佲晜鏆熼幑顔煎讲娣団€冲娴兼ê鍘涙禍搴ｎ瀲缁惧灝鍘规惔鏇樷偓?
- 瑜版挸澧犲韫瑐娴肩姾绻欑粩?DB 瀹告彃鍨忛幑顫礋 v2-only閿涘奔绗夐崘宥呭瘶閸?v1 閸忕厧顔愮悰顭掔幢閺冄呭閺?app 閼汇儱褰ч弨顖涘瘮 v1 鐞涖劌鐨㈤弮鐘崇《鐠囪褰囬弬鎵鏉╂粎顏崠鍛偓?
- `scripts/verify_daily_choice_recipe_remote.dart` 娑撹櫣鍑?Dart S3 smoke 瀹搞儱鍙块敍宀勬付鐟曚線鈧俺绻冮悳顖氼暔閸欐﹢鍣洪幋鏍ф嚒娴犮倛顢戦崣鍌涙殶閹绘劒绶?S3 闁板秶鐤嗛敍娑欐拱鏉烆噣鐛欑拠浣规闁板秶鐤嗘禒搴ｅ箛閺?`CstCloudS3CompatClient` 姒涙顓婚崐鑹邦嚢閸欐牕鎮楀▔銊ュ弳閻滎垰顣ㄩ崣姗€鍣洪妴?
- 閺堫剝鐤嗛柌宥嗘煀閻㈢喐鍨氶惃?`D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db` 娑?v2-only DB閿涘苯鍑＄粔濠氭珟 `origin` 閸掓鎷版姗€顥撻梽?`diet` 鐎涙顔岄敍娑樼秼閸撳秴銇囩亸?142,233,600 bytes閿涘HA256 娑?`418B40F934925FEB4AA1054A0A74442C2BEA063730EB727F20BE586ABD71C7B3`閵?
- 閺堫剝鐤嗛張顏囶洬閻?`D:\vocabularySleep-resources\cook_data` 閸樼喎顫愰弫鐗堝祦閿涙奔3 鏉╂粎顏?DB 瀹歌尙鏁遍悽銊﹀煕閺囧瓨鏌婇敍灞炬拱鏉烆喕绮庨崑姘崇箼缁?smoke 閸滃矁绻嶇悰灞炬鐠囪褰囨穱顔碱槻閵?
- 瑜版挸澧?UI 娴犲秳绻氶悾娆忓敶鐎?catalog 娴ｆ粈璐熼張顒€婀撮懛顏勭暰娑斿鈧椒閲滄禍楦跨殶閺佹潙鎷伴弮褍绨遍崶鐐衡偓鈧捄顖氱窞閿涙稑鎮嗘禒鈧稊鍫濆敶缂冾喖绨遍梾蹇旀簚閵嗕胶顓搁悶鍡涖€夊ù蹇氼潔閸滃苯鍞寸純顔肩氨閹兼粎鍌ㄥ鏌モ偓鎰劄閹恒儱鍙?store 閺屻儴顕楅妴?
- 瀹稿弶婀佹鐔告綏娴兼ê鍘涢惃?SQL 閻楀牊婀伴崗鍫ュ櫚閻?raw/canonical 娴犺绔撮崨鎴掕厬閺€璺哄經閿涘苯鐨婚張顏勭暚閺佹潙顦查崚璇插敶鐎?catalog 閻?exact/strong/broad 閸掑棗鐪伴幍鈺傜潨缁涙牜鏆愰妴?
- random pivot 閸︺劋瀵?UI 娑擃厼褰х憰鍡欐磰闂呭繑婧€濮圭姴鍙忔稉鍝勫讲鐟欎礁鍞寸純顔垮綅鐠嬭京娈戦崷鐑樻珯閿涙泊egacy v1 fallback 娴ｈ法鏁ら崐娆撯偓?id 閸掓銆冮崣鏍侀幎钘夊絿閿涘奔绗夐崗宄邦槵 v2 `random_key` 閻ㄥ嫮菙鐎规艾鍙忕仦鈧崚鍡楃閵?
- 閼奉亜鐣炬稊澶庡綅鐠嬪彉绻氱€涙ɑ妞傞惃鍕棨鐠嬮亶娉﹂柅澶嬪闁插洨鏁ょ划鍓р€橀柌宥呭晸鐠囶厺绠熼敍姘絿濞戝牊鐓囨稉顏堟肠閸氬牆瀣€闁绱伴幎濠咁嚉閼挎粈绮犵€电懓绨查梿鍡楁値缁夊娅庨敍宀冪箹閺勵垯璐熸禍鍡氼唨缂傛牞绶崳銊уЦ閹椒绗屾穱婵嗙摠缂佹挻鐏夋稉鈧懛娣偓?
- 缁狅紕鎮婃い闈涙倖娴犫偓娑斿牆鍞寸純顔肩氨閹兼粎鍌ㄥ鍙夊复閸?SQLite `daily_choice_recipe_search_text`閿涙稒婀伴崷鎷屽殰鐎规矮绠熼崪灞奸嚋娴滈缚鐨熼弫瀛樻偝缁鳖澀绮涚挧鏉垮敶鐎涙绻冨銈忕礉閸氬海鐢婚懟銉洣缂佺喍绔寸拠顓濈疅闂団偓閸楁洜瀚径鍕倞 overlay 閹兼粎鍌ㄩ妴?
- 瑜版挸澧犻幖婊呭偍娴犲秵妲?`instr`/substring 閺屻儴顕楅敍灞肩瑝閺?FTS閿涙稒瀚鹃棅鐐解偓浣稿瀻鐠囧秲鈧礁顦块崗鎶芥暛鐠囧秶娴夐崗铏偓褎甯撴惔蹇涙付閸氬海鐢婚崡鏇犲瀵洖鍙?FTS5 閹存牕鈧帗甯撶悰銊ｂ偓?
- 婢堆冣偓娆撯偓澶嬬潨娑撴柨鐡ㄩ崷銊╂閽?娑擃亙姹夌拫鍐╂殻/妞嬬喕姘ㄩ梿鍡欏閺夌喐妞傞敍灞炬付缂佸牓娈㈤張鍝勫瀻鐢啩绱伴崶鐐衡偓鈧崚鏉跨秼閸?UI 闂呭繑婧€鏉╁洨鈻奸柨浣哥暰閻ㄥ嫬鈧瑩鈧绱辨潻娆愭Ц娑撴椽浼╅崗宥呬粻濮濄垺瀵滈柦顔剧搼瀵板懘鍣?SQL 閻ㄥ嫭鈧嗗厴閸忔粌绨抽妴?
- 缁狅紕鎮婃い闈涘瀻妞ゅ灚鐓＄拠銏㈠箛閸︺劋绱版０婵嗩樆閹垫挸绱戦崥搴″酱 SQLite 鏉╃偞甯撮敍娑滃楠炲啿褰?isolate 閺屻儴顕楁稉宥呭讲閻劋绱伴懛顏勫З閸ョ偤鈧偓閸氬本顒炵捄顖氱窞閿涘苯鎮楃紒顓烆洤鐟曚浇绻樻稉鈧銉ュ竾娴ｅ孩鐓＄拠銏″灇閺堫剨绱濇惔鏃€甯规潻娑氭埂濮濓絿娈戦梹鍧椻敆閺屻儴顕?worker 閹?keyset/offset 鏉╄棄濮為崚鍡涖€夐妴?

### 娣囶喖顦?
- 娣囶喖顦插В蹇旀）閸愬磭鐡ラ崗銉ュ經鐞氼偄鎮嗘禒鈧稊鍫ｅ綅鐠嬪崬绨遍幗妯款洣閸旂姾娴囬幏鏍︾秶閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦茬粻锛勬倞 sheet 閺傛澘缂撴鐔绘皑闂嗗棜绶崗銉︻攱閸ョ姴鍤遍弫鎵獓 `TextEditingController` 閸︺劌鍙ч梻?闁插秴缂撻弮鎯邦潶闁插﹥鏂侀崥搴ｆ埛缂侇厼寮稉?TextField 閺嬪嫬缂撻惃鍕┛濠у啴顥撻梽鈹库偓?
- 娣囶喖顦查梾蹇旀簚鏉╁洨鈻兼稉顓″綅閸濅礁鍞寸€硅宕茬悰灞筋嚤閼锋潙浠犲銏″瘻闁筋喕绗傛稉瀣儲閸斻劊鈧線姣︽禒銉у仯閸戣崵娈戦梻顕€顣介妴?
- 娣囶喖顦茶ぐ鎾冲閻㈢喐鍨氶弫鐗堝祦娑擃厾绀屾?缁绢垳绀岄崘鑼崐閵嗕焦绔婚惇鐔活嚛閺勫孩钖勯弻?notes閵嗕浇褰嶇化缁樼垼缁涚偓钖勯弻?notes閵嗕焦纾遍拋杈嚖缁便垹绱╅拋渚库偓浣稿徔娴ｆ挾灏撻懖澶愩€嶉幎妯哄綌娑撴椽鈧氨鏁ら悮顏囧€濋崪灞惧▕閸欐牔璐￠惍浣虹搼鐎孤ゎ吀闂傤噣顣介妴?
- 娣囶喖顦叉潻婊咁伂 DB 鐎瑰顥婃径杈Е閺冭泛褰查懗钘夋礀闁偓閸?bundled JSON / cached CSV / fallback seed 楠炶泛鍟撻崗銉︽拱閸?JSON cache 閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦叉潻婊咁伂閸掗攱鏌婃径杈Е閺冭泛褰查懗鐣屾纯閹恒儴顩惄鏍箛閺?SQLite 鎼存挾娈戞搴ㄦ珦閿涙稓骞囬崷銊モ偓娆撯偓?DB 閺嶏繝鐛欓柅姘崇箖閸氬孩澧犻弴鎸庡床閺冄冪氨閵?
- 娣囶喖顦查崥鍐х矆娑斿牓绮拋銈夘樀濞堜絻绻冮弮鈺傛暪缁愬嫬鈧瑩鈧鐫滈惃鍕６妫版﹫绱辨妯款吇閻滄澘婀禒搴″弿闁劑顦靛▓闈涒偓娆撯偓澶夎厬闂呭繑婧€閵?
- 娣囶喖顦?`閹烘帡顎嘸 缁涘鍙挎担鎾活棨閺夋劕婀潻鎰攽閺冨爼顥ら弶鎰爱闁板秳鑵戠悮顐ュ殰閸斻劍濮岄崣鐘辫礋闁氨鏁ら悮顏囧€?token閿涘苯顕遍懛纾嬬翻閸忋儲甯撴銊ュ讲閼宠姤澧挎径褍鍩岄崗銊у皳閼插褰嶇拫杈╂畱闂傤噣顣介妴?
- 娣囶喖顦查弬鎵 v2-only 鏉╂粎顏?DB 閸?`PRAGMA user_version=2` 鐞氼偄缍嬮崜?store 閸掋倕鐣炬稉杞扮瑝閺€顖涘瘮閺?schema閿涘苯顕遍懛鏉戠暔鐟佸懏鍨ㄧ拠璇插絿婢惰精瑙﹂惃鍕６妫版ǜ鈧?
- 娣囶喖顦?v2-only DB 缂傚搫鐨?v1 summary/detail 鐞涖劍妞傞敍灞芥倖娴犫偓娑斿牊鎲崇憰浣告嫲鐠囷附鍎忕拠璇插絿 SQL 娴犲秴娴愮€规碍鐓＄拠?v1 鐞涖劎娈戦梻顕€顣介妴?
- 娣囶喖顦?v2 閺屻儴顕楅崐娆撯偓?id 閸?raw/canonical 閸氬本妞傞崨鎴掕厬閺冭泛褰查懗浠嬪櫢婢跺秷绻戦崶鐐叉倱娑撯偓閼挎粏姘ㄩ敍灞筋嚤閼锋挳娈㈤張鐑樻綀闁插秷顫﹂幇蹇擃樆閺€鎯с亣閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦查崥搴ｇ敾閸掑棝銆夐幒銉ュ弳閺冨爼娈㈤張鍝勫讲閼宠棄褰ч拃钘夋躬瑜版挸澧犻崚鍡涖€夌粣妤€褰涢惃鍕６妫版ê鐔€绾偓閿涙tore 鐏?random pivot 閻滄澘婀箛鐣屾殣 `limit` / `offset`閿涘苯顫愮紒鍫熷瘻鐎瑰本鏆ｉ崐娆撯偓澶嬬潨閹惰棄褰囬妴?
- 娣囶喖顦茬粻锛勬倞妞ら潧鍞寸純顔肩氨濞村繗顫嶉崪灞炬偝缁鳖澀绮涢崥灞绢劄鏉╁洦鎶ょ€瑰本鏆ｉ崥鍐х矆娑斿牆鍞寸純顔煎灙鐞涖劎娈戦幀褑鍏樼捄顖氱窞閿涘本鏁兼稉鐑樺瘻瑜版挸澧犵粵娑⑩偓澶夌瑢閹兼粎鍌ㄧ拠宥呭瀻妞ゅ灚鐓＄拠?SQLite閵?
- 娣囶喖顦茬粻锛勬倞妞?SQL 閸掑棝銆夋潻鏂挎礀閻ㄥ嫬鍞寸純顔芥喅鐟曚礁婀崘鍛摠閸忋劑鍣洪幗妯款洣缂傚搫銇戦弮鑸垫￥濞夋洘瀵滈棁鈧拠璇插絿鐎瑰本鏆ｇ拠锔藉剰閻ㄥ嫰娈ｉ幀褌绶风挧鏍モ偓?
- 娣囶喖顦茬粻锛勬倞妞ら潧鍞寸純顔垮綅鐠嬭精顕涢幆?娑擃亙姹夌拫鍐╂殻/閸欙箑鐡ㄩ崣顖炲櫢婢跺秶鍋ｉ崙璇差嚤閼锋挳鍣告径?detail 鐠囪褰囬惃鍕６妫版ǜ鈧?
- 娣囶喖顦茬粻锛勬倞妞ら潧鍞寸純顔垮綅鐠?detail 鐠囪褰囨径杈Е閺冭泛褰ч懗鍊熻泲閸忋劌鐪幓鎰仛閵嗕胶宸辩亸鎴炴蒋閻╊喚楠囬柨娆掝嚖閸欏秹顩惃鍕６妫版﹫绱遍悳鏉挎躬婢惰精瑙︽稉宥勭窗閸忔娊妫寸粻锛勬倞 sheet 閹存牗绔荤粚鍝勭秼閸撳秵鎮崇槐?閸掑棝銆夐悩鑸碘偓浣碘偓?
- 娣囶喖顦茬粻锛勬倞妞ゅ灚鎮崇槐銏☆攱濮ｅ繑顐兼潏鎾冲弳鐎涙顑侀柈鍊熜曢崣?SQL 閺屻儴顕楅惃鍕６妫版﹫绱遍悳鏉挎躬閸欘亜婀径杈╁妽閹存牗褰佹禍銈嗘鐟欙箑褰傞幖婊呭偍閵?
- 娣囶喖顦查梾蹇旀簚閸嬫粍顒涢崥搴℃礈閺堚偓缂佸牊濞婇崣鏍偓妤佹鏉╁洭鏆遍崣顖濆厴闂€鎸庢闂傛潙宕遍崷銊⑩偓婊堚偓澶夎厬娑?/ Picking閳ユ繐绱濇稉鏃€妫ゅ▔鏇犌旂€规碍妯夌粈鐑樻付缂佸牐褰嶇拫杈╂畱闂傤噣顣介妴?
- 娣囶喖顦叉稉?UI 閸嬫粍顒涢梾蹇旀簚閺冭泛顕径褍鈧瑩鈧鐫滄导鐘插弳閸忋劑鍣?`allowedOptionIds`閿涘苯顕遍懛?v2 SQL random pivot 閺嬪嫰鈧姴銇?`IN (...)` 閺屻儴顕楅獮鑸靛珛閹鳖澀姘︽禍鎺旀畱闂傤噣顣介妴?
- 娣囶喖顦叉稉?UI 閸嬫粍顒涢梾蹇旀簚娴犲秴褰查懗钘夋礈閸氬本顒?SQLite random pivot 閸楃姷鏁?UI isolate閿涘苯顕遍懛瀵糕柤鎼村繑甯存潻鎴炴￥閸濆秴绨查惃鍕６妫版ǜ鈧?
- 娣囶喖顦茬粻锛勬倞妞ら潧鍞寸純顔肩氨濠婃垵鍩屾惔鏇㈠劥閸氬函绱濋懟?SQL 缂佹挻鐏夋潻鏂挎礀閺冨墎鏁ら幋宄板嚒閸嬫粌婀惔鏇㈠劥閿涘苯鎮楃紒顓€夋稉宥勭窗閼奉亜濮╅崝鐘烘祰閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦叉稉顏冩眽鐠嬪啯鏆ｆ穱婵嗙摠閸?smoke 濞村鐦潻鍥ㄦ－閻愮懓鍤禒宥呮躬闁偓閸戝搫濮╅悽璇叉倵閻?sheet 閸愬懎顔愮€佃壈鍤ч惃鍕嚖閸掋倧绱卞ù瀣槸閻滄澘婀粵澶婄窡娣囨繂鐡ㄩ崶鐐插晸閸?modal 閸斻劎鏁剧€瑰本鍨氶崥搴″晙缂佈呯敾閻愮懓鍤拠锔藉剰閵?
- 娣囶喖顦茬粻锛勬倞妞ら潧鍞寸純顔肩氨閳ユ粌鏋╁▎?閸旂姴鍙嗛垾婵嗗涧閼充粙娈ｅ蹇旀惙娴ｆ粌宕熸稉鈧梿鍡楁値閵嗕胶宸辩亸鎴濐樋闂嗗棗鎮庨柅澶嬪閸忋儱褰涢惃鍕６妫版ǜ鈧?
- 娣囶喖顦茬粻锛勬倞妞ょ敻顥ょ拫閬嶆肠闁瀚ㄩ崗銉ュ經闁插秴顦茬€佃壈鍤ч崥灞肩闂嗗棗鎮庨弮銏犳躬 chip 閸欏牆婀崡锛勫娑擃厼鍤悳鎵畱闂傤噣顣介妴?
- 娣囶喖顦叉鐔绘皑闂嗗棗顕遍崗銉ユ躬閺傚洣娆㈤柅澶嬪閸ｃ劍婀潻鏂挎礀閸愬懎顔愰弮璺哄讲閼宠姤鐥呴張澶夋崲娴ｆ洖寮芥＃鍫㈡畱闂傤噣顣介妴?
- 娣囶喖顦茬粻锛勬倞妞や絻袝鎼存洖濮炴潪鎴掔瑓娑撯偓妞ゅ灚妞傞柌宥咁槻閺屻儴顕楀鍙夋▔缁€鍝勫敶缂冾喛褰嶇拫杈ㄦ喅鐟曚胶娈戦梻顕€顣介妴?

### 妤犲矁鐦?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_decision_assistant.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_decision_content.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_detail_sheets.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_place_seed.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_seed_data.dart test\daily_choice_cooking_guide_test.dart test\daily_choice_decision_engine_test.dart test\daily_choice_place_seed_test.dart test\daily_choice_wear_seed_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_cooking_guide_test.dart test\daily_choice_decision_engine_test.dart test\daily_choice_place_seed_test.dart test\daily_choice_wear_seed_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_custom_state_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_cooking_guide_test.dart test\daily_choice_decision_engine_test.dart test\daily_choice_place_seed_test.dart test\daily_choice_wear_seed_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart format lib\src\ui\pages\toolbox\toolbox_ui_components.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_widgets.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_modules.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_wear_module.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox\toolbox_ui_components.dart lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_custom_state_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_query_helpers.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_section_widgets.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_collection_io.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_dialogs.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_widgets.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_custom_state_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter analyze`閿涘牊婀柅姘崇箖閿涘奔绮庨崜鈺傛拱鏉烆喖顦婚弮銏℃箒 harp/woodfish/pubspec/test lint閿?
- `powershell -ExecutionPolicy Bypass -File scripts\build.ps1 -Target android-apk`閿涘牓鈧俺绻冮敍瀹篹lease APK 閺嬪嫬缂撻幋鎰閿?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_widgets.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_custom_state_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_models.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_catalog.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_support.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_hub.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_editor_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_seed_data.dart test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_custom_state_test.dart`閿涘牓鈧俺绻冮敍?
- `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py scripts\audit_daily_choice_recipe_dataset.py`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `python -X utf8` 濡偓閺?`D:\vocabularySleep-resources\cook_data_plan070_validation`閿涘牓鈧俺绻冮敍瀹篹cipes=7772閿涘瘈ser_version=2閿涘ntegrity=ok閿涘瘉2 recipes/summaries/details 閸у洣璐?7,772閿涘畭hasOriginColumn=False`閿涘瓰SON `diet/origin` 娑?0閿涘瓕B 妞嬪酣娅?diet terms 娑?0閿涘瓕B SHA256=`418B40F934925FEB4AA1054A0A74442C2BEA063730EB727F20BE586ABD71C7B3`閿?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `git switch -c codex/daily-choice-overhaul`閿涘牓鈧俺绻冮敍?
- `git commit -m "chore: backup current workspace before daily choice overhaul"`閿涘牓鈧俺绻冮敍灞筋槵娴犺姤褰佹禍?`735b95a`閿?
- `dart analyze lib/src/ui/pages/toolbox_daily_choice test/daily_choice_hub_smoke_test.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart test/daily_choice_eat_library_store_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart test/daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `python -X utf8 scripts\audit_daily_choice_recipe_dataset.py --cook-csv .tmp_recipe_csv_head.txt`閿涘牓鈧俺绻冮敍?
- `python -m py_compile scripts\audit_daily_choice_recipe_dataset.py`閿涘牓鈧俺绻冮敍?
- `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py scripts\audit_daily_choice_recipe_dataset.py`閿涘牓鈧俺绻冮敍?
- `python -X utf8 scripts\generate_daily_choice_recipe_dataset.py --cook-csv .tmp_plan070_recipe.csv --output D:\vocabularySleep-resources\cook_data_plan070_validation\recipe_library_asset.json --export-dir D:\vocabularySleep-resources\cook_data_plan070_validation`閿涘牓鈧俺绻冮敍?
- `python -X utf8 scripts\audit_daily_choice_recipe_dataset.py --library-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.json --summary-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library_summary.json --sqlite-db D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db --cook-csv .tmp_plan070_recipe.csv --output-md records\record_070_daily_choice_recipe_data_audit_after_generation.md --output-json records\record_070_daily_choice_recipe_data_audit_after_generation.json`閿涘牓鈧俺绻冮敍?0 娑擃亜顓哥拋锟犳６妫版ɑ銆婇崸鍥﹁礋 0閿?
- `python -X utf8` 閸愬懎鐡?SQLite 閹笛嗩攽 `scripts\daily_choice_recipe_schema_v2.sql`閿涘牓鈧俺绻冮敍灞藉灡瀵?14 瀵姾銆冮崪?18 娑擃亞鍌ㄥ鏇礆
- `EXPLAIN QUERY PLAN` 妤犲矁鐦?v2 閹芥顩﹂崚鍡涖€夐妴渚€鈧氨鏁ょ粵娑⑩偓澶堚偓渚€顥ら弶鎰爱闁板秴鎷伴梾蹇旀簚 pivot 閺屻儴顕楅敍鍫モ偓姘崇箖閿涘苯鎳℃稉顓犳窗閺嶅洨鍌ㄥ鏇礆
- `python -X utf8` 鐟欙絾鐎?`D:\vocabularySleep-resources\cook_data_plan070_validation` 娑擃厺绗佹禒钘夊竾缂?JSON閿涘牓鈧俺绻冮敍灞肩瑏娴?JSON 閸у洣璐?7,772 閺壜ゅ綅鐠嬫唻绱?
- `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_library_store.dart test/daily_choice_eat_library_store_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart run scripts/s3_resource_probe.dart --op list --prefix cook_data/ --max-keys 20`閿涘牓鈧俺绻冮敍?
- `dart run scripts/s3_resource_probe.dart --op head --key cook_data/daily_choice_recipe_library.db`閿涘牓鈧俺绻冮敍?7,915,008 bytes閿?
- `dart run scripts/s3_resource_probe.dart --op get-range --key cook_data/daily_choice_recipe_library.db`閿涘牓鈧俺绻冮敍瀛睶Lite 閺傚洣娆㈡径杈剧礆
- `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py`閿涘牓鈧俺绻冮敍?
- `dart run scripts/verify_daily_choice_recipe_remote.dart --key cook_data/daily_choice_recipe_library.db --expected-count 7772`閿涘牓鈧俺绻冮敍?
- `python -X utf8` 閺堚偓鐏忓繑鏆熼幑顕€娉︾拫鍐暏 `write_sqlite_export(...)` 妤犲矁鐦?v1/v2 閸欏苯鍟撻敍鍫モ偓姘崇箖閿?
- `dart analyze scripts/verify_daily_choice_recipe_remote.dart lib/src/ui/pages/toolbox_daily_choice test/daily_choice_eat_catalog_test.dart test/daily_choice_eat_library_store_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_eat_catalog_test.dart test/daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py scripts\audit_daily_choice_recipe_dataset.py`閿涘牓鈧俺绻冮敍?
- `dart format scripts\verify_daily_choice_recipe_remote.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze scripts\verify_daily_choice_recipe_remote.dart`閿涘牓鈧俺绻冮敍?
- `python -X utf8` 娴犲酣鐛欑拠浣稿瘶 JSON 鐠嬪啰鏁?`write_sqlite_export(..., sqlite_mode='v2')` 闁插秴鍟?`D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db`閿涘牓鈧俺绻冮敍?,772 閺夆槄绱?
- `python -X utf8` 濡偓閺?v2-only DB閿涙瓪PRAGMA integrity_check=ok`閵嗕梗user_version=2`閵嗕箍1 summary/detail 鐞涖劋绗夌€涙ê婀妴涔? recipes/summaries/details 閸у洣璐?7,772 鐞涘矉绱欓柅姘崇箖閿?
- `python -X utf8 scripts\audit_daily_choice_recipe_dataset.py --library-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.json --summary-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library_summary.json --sqlite-db D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db --cook-csv build\_external\cook\app\data\recipe.csv --output-md records\record_070_daily_choice_recipe_v2_only_db_audit.md --output-json records\record_070_daily_choice_recipe_v2_only_db_audit.json`閿涘牓鈧俺绻冮敍?0 娑擃亜顓哥拋锟犳６妫版ɑ銆婇崸鍥﹁礋 0閿涘畱ook CSV 599 鐞涘苯鍙忛柈銊︾垼妫版ê鎳℃稉顓ㄧ礆
- `dart run scripts/verify_daily_choice_recipe_remote.dart --key cook_data/daily_choice_recipe_library.db --expected-count 7772`閿涘牓鈧俺绻冮敍灞界暚閺佺繝绗呮潪鐣屾暏閹撮攱娲块弬鏉挎倵閻ㄥ嫯绻欑粩?v2-only DB閿涘瘉2 recipes/summaries/details 閸у洣璐?7,772 鐞涘矉绱?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart test\daily_choice_eat_library_store_test.dart scripts\verify_daily_choice_recipe_remote.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`閿涘牓鈧俺绻冮敍宀€顓搁悶鍡涖€夐崘鍛枂鎼存挻鎮崇槐顫瑓濞屽鎮楅弮鐘绘饯閹線妫舵０姗堢礆
- `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍宀冾洬閻?v2 search table 閺屻儴顕楅敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍宀冾洬閻╂牜顓搁悶鍡涖€夐幖婊呭偍鐠囧秳绱堕崗?store 閺屻儴顕楅獮璺哄涧鐏炴洜銇氶崨鎴掕厬閸愬懐鐤嗛懣婊愮礆
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`閿涘牓鈧俺绻冮敍宀€顓搁悶鍡涖€?SQL 閹芥顩?detail 鐟欙綀鈧箑鎮楅弮鐘绘饯閹線妫舵０姗堢礆
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍宀冾洬閻╂牕鍞寸€涙ɑ鎲崇憰浣疯礋缁岀儤妞傜粻锛勬倞妞?SQL 閹芥顩︽禒宥呭讲閹垫挸绱戠拠锔藉剰閿涘奔浜掗崣濠侀嚋娴滈缚鐨熼弫鏉戝 detail 閹虫帒濮炴潪鏂ょ礆
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart test\daily_choice_eat_library_store_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍宀冾洬閻?v2 SQL 缁涙盯鈧鈧礁鍨庢い鐐光偓渚€顥ら弶鎰翱绾喖灏柊宥呮嫲缂佸嫬鎮庤箛灞藉經閿?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart test\daily_choice_eat_library_store_test.dart`閿涘牓鈧俺绻冮敍灞炬煀婢?random pivot API 閸氬孩妫ら棃娆愨偓渚€妫舵０姗堢礆
- `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍宀冾洬閻?pivot 閸涙垝鑵戦妴浣告礀缂佹洖鎷伴崚鍡涖€夌粣妤€褰涙径鏍р偓娆撯偓澶嬪▕閸欐牭绱?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍宀冾洬閻╂牕浠犲銏ゆ閺堥缚袝閸?store pivot閵嗕胶顓搁悶鍡涖€夌仦鏇炵磻閸愬懐鐤嗘惔鎾剐曢崣?SQL 閺屻儴顕楅妴浣糕偓娆撯偓澶嬬潨閸欐ê瀵查崥搴㈡＋瀵倹顒為幎钘夊絿娑撳秴娲栭崘娆欑礆
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_widgets.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍宀冾洬閻╂牠娈㈤張鍝勪粻濮濄垼绉撮弮璺哄幑鎼存洖鎷版径褍褰茬憴浣圭潨閺堫剙婀?fallback閿?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍宀冾洬閻╂牕浠犲銏ゆ閺堣桨绗夌憴锕€褰?store random pivot閵嗕胶顓搁悶鍡涖€夌憴锕€绨抽懛顏勫З閸掑棝銆夐敍?
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_069-BUILD-DISABLE-WEB] - 2026-04-26

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯 `.\scripts\build.ps1` 閹?Web 閸栧懏妞傛径杈Е閿涘矂鏁婄拠顖涙降閼?`sherpa_onnx`閵嗕梗sqlite3`閵嗕梗ffi` 缁?`dart:ffi` 娓氭繆绂嗛崷?Flutter Web / Dart2JS 娑撳妫ゅ▔鏇犵椽鐠囨垯鈧?
- 瑜版挸澧犳い鍦窗娑撴槒顩﹂惄顔界垼娑撳秵妲?Web閿涘本娈忔稉宥嗗閸?Web 娑撴挾鏁ょ€圭偟骞囬幋鏍ㄦ蒋娴犺泛顕遍崗銉╁櫢閺嬪嫨鈧?

### 娣囶喗鏁?
- `scripts/build.ps1` 閻ㄥ嫰绮拋?`all` 閻╊喗鐖ｆ稉宥呭晙閸栧懎鎯?`web`閿涘indows / macOS / Linux 鐎瑰じ瀵岄獮鍐插酱閸у洤褰ф穱婵堟殌瑜版挸澧犻崣顖滄暏閻?Android 娑撳孩顢戦棃銏＄€铏规窗閺嶅洢鈧?
- 缁夊娅庨懘姘拱娑擃厾娈?Web 閺嬪嫬缂撻崚鍡樻暜閿涘矂浼╅崗宥夌帛鐠併倖澧﹂崠鍛扮獓閸?`flutter build web` 閸氬氦绶崙鍝勩亣闁?FFI 缂傛牞鐦ч柨娆掝嚖閵?
- 閺勬儳绱℃导鐘插弳 `-Target web` 閺冭绱濋懘姘拱娴兼艾婀惄顔界垼鐟欙絾鐎介梼鑸殿唽閻╁瓨甯撮幓鎰仛閿涙艾缍嬮崜宥呮礈 `sherpa_onnx`閵嗕梗sqlite3`閵嗕梗ffi` 缁?FFI 娓氭繆绂嗙粋浣烘暏 Web閿涘矂娓剁憰?Web 娑撴挾鏁ょ€圭偟骞囬崥搴″晙闁插秵鏌婇崥顖滄暏閵?

### 娣囶喖顦?
- 娣囶喖顦?`.\scripts\build.ps1` 姒涙顓婚崗銊╁櫤閹垫挸瀵橀弮鎯邦潶 Web 閻╊喗鐖ｉ幏鏍с亼鐠愩儳娈戦梻顕€顣介妴?

### 妞嬪酣娅撻崣妯绘纯
- `web` 娑撳秴鍟€閺勵垵鍓奸張顒佹暜閹镐胶娲伴弽鍥风幢閸氬海鐢婚懟銉╂付鐟曚焦浠径?Web 閸栧拑绱濋棁鈧憰浣稿帥婢跺嫮鎮?FFI 娓氭繆绂嗛惃?Web 閺囧じ鍞€圭偟骞囬幋鏍ㄦ蒋娴犺泛顕遍崗銉╂缁傛眹鈧?

### 妤犲矁鐦?
- `.\scripts\build.ps1 -DryRun -NoPubGet`閿涘牓鈧俺绻冮敍宀冪翻閸?Android APK / Android AppBundle / Windows閿涘奔绗夐崘宥呭瘶閸?Web閿?
- `.\scripts\build.ps1 -Target web -DryRun -NoPubGet`閿涘牊瀵滄０鍕埂婢惰精瑙﹂敍灞借嫙鏉堟挸鍤?FFI 娓氭繆绂嗙€佃壈鍤?Web 缁備胶鏁ら惃鍕绾喗褰佺粈鐚寸礆
- `.\scripts\build.ps1 -Target android-apk -NoPubGet`閿涘牓鈧俺绻冮敍灞奸獓閻椻晞绶崙鍝勫煂 `dist/android-apk/xianyushengxi.apk`閿?

## [Unreleased-PLAN_068-EAT-COOKING-GUIDE-PERF] - 2026-04-26

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴閵嗗本鐦￠弮銉﹀Ψ閹?- 閸氬啩绮堟稊鍫涒偓宥勮厬閻ㄥ嫬浠涢懣婊勫瘹閸楁鏁奸幋鎰垼閸戝棎鈧線鈧氨鏁ら妴浣稿讲闂€鎸庢埂閹碘晛鐫嶉惃鍕粵閼挎粌鐔€閸戝棙澧滈崘宀嬬礉缁夊娅庡ǎ閿嬫絽閻ㄥ嫰銆嶉惄?/ 缁嬪绨敮顔煎И閸愬懎顔愰妴?
- 閻劍鍩涚憰浣圭湴閸欏倽鈧?YunYouJun/cook 娑撳孩婀伴崷?`D:\vocabularySleep-resources\閸嬫俺褰峘 鐠у嫭鏋℃稉顓犳畱闁氨鏁ら悜褰掋偑閹垛偓瀹秆佲偓浣筋潐閼煎啩绗岀€瑰鍙忔潏鍦櫕閵?
- 閻劍鍩涚憰浣圭湴閹跺鈧矂鐝痪褑顔曠純顔衡偓宥勭瑐缁変紮绱濋獮鍓佹埛缂侇厺绱崠鏍暩閼存垹顏崪灞惧閺堣櫣顏柈鍊熷厴閹扮喓鐓￠崚鎵畱閸楋繝銆戦妴?

### 閺傛澘顤?
- 閺傛澘顤?`test/daily_choice_cooking_guide_test.dart`閿涘矁顩惄鏍т粵閼挎粍瀵氶崡妞剧瑝閸愬秴鍤悳?`recipe.csv`閵嗕梗SQLite`閵嗕礁鐣ㄧ憗鍛偓浣界箼缁旑垬鈧焦鏆熼幑顔界爱缁涘銆嶉惄顔煎簻閸斺晞顕㈤敍灞借嫙绾喛顓婚幐鍥у础閸栧懎鎯堥崗銉ュ腹閵嗕線鍣扮拹顓溾偓浣圭濞叉ぜ鈧礁鍨佸銉ｂ偓浣轰紑閸婃瑥鎷扮紙鏄忔簠閹烘帗鐓＄粵澶婄唨閸戝棛鐝烽懞鍌樷偓?

### 娣囶喗鏁?
- 闁插秴鍟撻崥鍐х矆娑斿牆浠涢懣婊勫瘹閸楁ぞ璐熼柅姘辨暏閻戝綊銈幍瀣斀缂佹挻鐎敍宀冾洬閻╂牕鍙嗛崢銊ュ閸掋倖鏌囬妴渚€鍣扮拹顓㈢崣閺€韬测偓浣圭濞叉骞撳Ч掳鈧礁鍨佸銉ュ瀼闁板秲鈧礁顦弬娆撱€庢惔蹇嬧偓浣界殶閸涘啿鐔€閸戝棎鈧胶浼€閸婃瑩鏀ㄩ崗鏋偓浣哥唨绾偓婢跺嫮鎮婇幎鈧▔鏇樷偓浣哥埗閻劎鍏愮拫鍐╃《閵嗕胶鑳岄棃銏㈠劋閻掓瑣鈧椒绻氱€涙ê顦查悜顓炴嫲缂堟槒婧呴幒鎺撶叀閵?
- 閸嬫俺褰嶉幐鍥у础閸欏倽鈧啯娼靛┃鎰暭娑撴亽鈧苯寮懓鍐х瑢瀵ゆ湹鍑犻梼鍛邦嚢閵嗗秹妾ぐ鏇炲經閸氫紮绱濋崣顏冪箽閻ｆ瑨绁弬娆愮垼妫版ê鎷伴幗妯款洣鐠囧瓨妲戦敍灞肩瑝閸愬秷袙闁插﹪銆嶉惄顔肩摟濞堢偣鈧線銆夐棃銏ｎ攽娑撶儤鍨ㄩ幒銉ュ弳鏉堝湱鏅妴?
- 閸氬啩绮堟稊鍫ャ€夐棃銏犵殺閵嗗矂鐝痪褑顔曠純顔衡偓宥呭缂冾喖鍩岄梾蹇旀簚娑撴槒鍨堕崣棰佺閸撳稄绱濈拋鈺冩暏閹村嘲鍘涢弨璺哄經瀹稿弶婀侀弶鎰灐閵嗕礁绻夐崣锝冣偓浣藉吹缁?/ 濞撳懐婀＄粵澶嬫蒋娴犺绱濋崘宥呯磻婵娈㈤張鎭掆偓?
- 闂呭繑婧€闂堛垺婢樻潻鎰攽娑擃厺绗夐崘宥嗙槨 120ms 鐟欙箑褰傞弫鏉戞健 `AnimatedSwitcher` 閸掑洦宕查崝銊ф暰閿涘苯褰ч弴瀛樻煀閸氬奔绔存稉顏勨偓娆撯偓澶庡灦閸欏府绱遍崑婊勵剾闁鑵戦弮鏈电箽閻ｆ瑦顒滅敮姝岀箖濞撯槄绱濋梽宥勭秵闂呭繑婧€鏉╁洨鈻兼稉顓犳畱闁插秴缂撴稉搴℃値閹存劕甯囬崝娑栤偓?
- 閼挎粏姘ㄦ惔鎾存喅鐟曚礁濮炴潪鑺ユ暭娑撳搫鎮楅崣?isolate 閹垫挸绱?SQLite 楠炴儼袙閺嬫劖鎲崇憰渚婄礉婢惰精瑙﹂弮璺烘礀闁偓娑?isolate 鐠囪褰囬敍灞藉櫤鐏忔垼绻橀崗銉ユ倖娴犫偓娑斿牏鏅棃銏℃娑撹崵鍤庣粙瀣倱濮濄儴袙閻礁甯囬崝娑栤偓?
- 缁狅紕鎮婃い闈涘敶缂冾喛褰嶇拫杈╃摣闁顤冮崝鐘电处鐎涙﹢鏁敍灞界潔瀵偓閸愬懐鐤嗘惔鎾虫倵閹舵ê褰?/ 鐏炴洖绱戦崗鏈电铂閸栧搫鐓欐稉宥呭晙闁插秴顦叉潻鍥ㄦ姢閸忋劑鍣洪崘鍛枂閼挎粏姘ㄩ妴?

### 娣囶喖顦?
- 娣囶喖顦查崑姘冲綅閹稿洤宕℃稉顓熻穿閸?`recipe.csv`閵嗕胶鐡柅澶婄摟濞堢偣鈧線銆夐棃銏犲爱闁板秹鈧槒绶妴浣规弓閹恒儱鍙嗙挧鍕灐缁涘銆嶉惄顔煎簻閸斺晞顕╅弰搴ｆ畱闂傤噣顣介妴?
- 娣囶喖顦查梾蹇旀簚濠婃艾濮╅弮璺烘礈妤傛﹢顣堕崚鍥ㄥ床閸斻劎鏁剧€佃壈鍤ч惃鍕閺勬儳宕辨い鍧楊棑闂勨斂鈧?
- 娣囶喖顦茬粻锛勬倞妞ら潧鐫嶅鈧崘鍛枂鎼存挸鎮楁潪濠氬櫤 UI 閻樿埖鈧礁褰夐崠鏍︾矝閸欏秴顦查幍顐ｅ伎鐎瑰本鏆ｉ懣婊嗘皑鎼存挾娈戦幀褑鍏樺ù顏囧瀭閵?

### 妞嬪酣娅撻崣妯绘纯
- 閹芥顩﹂崥搴″酱 isolate 鐠囪褰囨笟婵婄 SQLite 閺傚洣娆㈤崣顖濐潶缁楊兛绨╂潻鐐村复楠炶泛褰傞崣顏囶嚢閹垫挸绱戦敍娑滃閻╊喗鐖ｉ獮鍐插酱 isolate 鐠囪褰囨径杈Е閿涘奔绱伴懛顏勫З閸ョ偤鈧偓閺冦垺婀佹稉鑽ゅ殠缁嬪顕伴崣鏍熅瀵板嫨鈧?
- 閸嬫俺褰嶉幐鍥у础閸愬懎顔愰弰搴㈡▔閸欐ü璧寸€靛矉绱濇担鍡曠矝閸欘亜婀幐鍥у础瀵湱鐛ラ崘鍛瘻濡€虫健闁瀚ㄥ〒鍙夌厠閿涘奔绗夌敮鎼佲敆娑撳銆夐棃顫偓?
- 缁狅紕鎮婃い鐢电摣闁绱︾€涙ü绮涢崺杞扮艾閺堫剙婀撮幗妯款洣閸忋劑娉﹂敍娑滃閼挎粏姘ㄩ柌蹇曟埛缂侇厼顤冮梹鍨煂閺佹澘宕勬稉鍥╅獓閿涘苯鎮楃紒顓炵安閹跺﹦顓搁悶鍡樻偝缁便垻鎴风紒顓濈瑓濞屽鍩?SQLite 閸婃帗甯?/ FTS 閺屻儴顕楅妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_library_store.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart test/daily_choice_cooking_guide_test.dart test/daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter analyze lib/src/ui/pages/toolbox_daily_choice test/daily_choice_cooking_guide_test.dart test/daily_choice_hub_smoke_test.dart test/daily_choice_eat_library_store_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_cooking_guide_test.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_eat_library_store_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `.\scripts\build.ps1 -Target android-apk -NoPubGet`閿涘牓鈧俺绻冮敍灞奸獓閻椻晞绶崙鍝勫煂 `dist/android-apk/xianyushengxi.apk`閿?

## [Unreleased-PLAN_067-EAT-FREEZE-BUILD] - 2026-04-26

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯瀹搞儱鍙跨粻渚库偓灞剧槨閺冦儲濡烽幏?- 閸氬啩绮堟稊鍫涒偓宥堢箻閸忋儵銆夐棃銏″复鏉╂垵宕卞浼欑礉缁狅紕鎮婃い浣冧氦闁插繑濮岄崣鐘辨唉娴滄帊绡冩导姘閺勬儳宕辨い瑁も偓?
- 閻劍鍩涢崣宥夘洯閺傛澘顤冮懣婊嗘皑閺?`DropdownButtonFormField` 閸?`all` 娑撳﹣绗呴弬鍥櫢婢跺秴鎷伴崐鐓庡暱缁愪胶娲块幒銉︽焽鐟封偓閹躲儵鏁婇妴?
- 閻劍鍩涢崣宥夘洯闁俺绻?`.\scripts\build.ps1` release 閹垫挸瀵橀弮?Gradle 閸?Flutter plugin loader 闂冭埖顔岄崶鐘辩波鎼存挾鐡ラ悾銉ュ暱缁愪礁銇戠拹銉ｂ偓?

### 娣囶喗鏁?
- `DailyChoiceEditorSheet` 閸愬懘鍎寸紒鐔剁鐎电懓鍨庣猾?/ 娑撳﹣绗呴弬鍥р偓娆撯偓澶婂箵闁插稄绱濋獮璺烘躬缂傛牞绶幀浣稿ⅶ闂?`all` 鏉╂瑧琚粵娑⑩偓澶婃憼閸忕敻銆嶉敍宀勪缉閸忓秳绗夐崥灞藉弳閸欙絼绱堕崗銉╁櫢婢跺秳绗傛稉瀣瀮閺冩儼袝閸欐垳绗呴幏澶嬫焽鐟封偓閵?
- 閸氬啩绮堟稊鍫滃瘜妞ょ敻娼伴崷銊ュ涧閸欐ɑ娲挎鐔绘皑闂嗗棙鏆熼幑顔荤瑬瑜版挸澧犻張顏堚偓澶夎厬妞嬬喕姘ㄩ梿鍡樻閿涘奔绗夐崘宥夊櫢缁犳缍嬮崜宥夋閺堢儤鐫滈敍灞藉櫤鐏忔垹顓搁悶鍡涖€夐梿鍡楁値閹垮秳缍旂€电懓绨崇仦鍌炪€夐棃銏㈡畱閸氬本顒為崢瀣閵?
- `scripts/build.ps1` 閸?Android 閺嬪嫬缂撻梼鑸殿唽娴ｈ法鏁ゆい鍦窗閸愬懘娈х粋鑽ゆ畱 `GRADLE_USER_HOME`閿涘矂浼╅崗宥堫嚢閸欐牜鏁ら幋宄板弿鐏炩偓 `~/.gradle/init.gradle` 閸氬骸鎮?Flutter included build 濞夈劌鍙嗘い鍦窗缁?Maven 娴犳挸绨遍妴?
- Android Gradle 闁板秶鐤嗙粔濠氭珟 settings / project 娑撱倕鐪伴懛顏勭暰娑?Maven 闂€婊冨剼娑撳骸鍙忕仦鈧?library `BuildConfig` 姒涙顓诲鈧崗绛圭礉閸掑棗鍩嗘穱顔碱槻 settings 娴犳挸绨辩粵鏍殣閸愯尙鐛婇崪?`sherpa_onnx` 婢?ABI 鐎涙劕瀵?release R8 闁插秴顦茬猾濠氭６妫版ǜ鈧?

### 娣囶喖顦?
- 娣囶喖顦查弬鏉款杻 / 鐠嬪啯鏆?/ 閸欙箑鐡ㄩ崥鍐х矆娑斿牐褰嶇拫杈ㄦ娑撳﹣绗呴弬鍥у灥婵鈧棿璐?`all` 閹存牔绗傛稉瀣瀮閸掓銆冮崠鍛儓闁插秴顦?`all` 鐎佃壈鍤ч惃?`DropdownButton` 瀹曗晜绨濋妴?
- 娣囶喖顦茬粻锛勬倞妞ら潧婀棃鐐茬箑鐟曚礁婧€閺咁垯绗呴崶鐘活棨鐠嬮亶娉﹂悩鑸碘偓浣稿綁閸栨牜澹嶉崝銊ユ倖娴犫偓娑斿牓娈㈤張鐑樼潨闁插秶鐣婚惃鍕偓褑鍏樺ù顏囧瀭閵?
- 娣囶喖顦?`.\scripts\build.ps1 -Target android-apk` 閻?Android release APK 閺嬪嫬缂撻柧鎹愮熅閵?

### 妞嬪酣娅撻崣妯绘纯
- Android 閺嬪嫬缂撻懘姘拱娴兼艾婀?`android/.gradle-user-home/` 娑撳缂撶粩瀣€嶉惄顔芥拱閸?Gradle 閻劍鍩涢惄顔肩秿閿涘矂顩诲▎鈩冪€娲付鐟曚線鍣搁弬棰佺瑓鏉?Gradle / AGP 娓氭繆绂嗛敍娑滎嚉閻╊喖缍嶅鎻掑閸?`.gitignore`閵?
- 缁夊娅庨崗銊ョ湰 library `BuildConfig` 姒涙顓诲鈧崗鍐叉倵閿涘奔绶风挧鏍х氨閸ョ偛鍩?AGP 姒涙顓荤悰灞艰礋閿涙稑顩ч弸婊勬弓閺夈儲鐓囨稉顏呮＋ Android library 濠ф劗鐖滈惄瀛樺复瀵洜鏁ら懛顏囬煩 `BuildConfig`閿涘矂娓剁憰浣筋嚉鎼存捁鍤滅悰灞界磻閸?`buildFeatures.buildConfig`閵?
- 閺堫剚婧€ Android SDK 閻?`ndk;28.2.13676358` 閺囨儳顦╂禍搴″磹鐎瑰顥婇悩鑸碘偓渚婄礉閺堫剝鐤嗗鏌モ偓姘崇箖 sdkmanager 闁插秵鏌婄€瑰顥婇敍娑滅箹閺勵垱鐎铏瑰箚婢у啩鎱ㄦ径宥忕礉娑撳秴鐫樻禍搴濈波鎼存挻绨惍浣稿綁閺囨番鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart test/daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_daily_choice test/daily_choice_hub_smoke_test.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `.\scripts\build.ps1 -Target android-apk -NoPubGet`閿涘牓鈧俺绻冮敍灞奸獓閻椻晞绶崙鍝勫煂 `dist/android-apk/xianyushengxi.apk`閿?

## [Unreleased-PLAN_066-EAT-PERFORMANCE-SETS] - 2026-04-26

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯瀹搞儱鍙跨粻渚库偓灞剧槨閺冦儲濡烽幏?- 閸氬啩绮堟稊鍫涒偓宥夘浕鐏炲繐鐫嶇粈楦垮櫑閼插尅绱濋妴灞藉帥鐠佲晠鈧瀚ㄩ崝銊ㄦ崳閺夈儯鈧秴鎷扮敮鎼佲敆閼挎粏姘ㄦ惔鎾诡嚛閺勫海宸辨稊蹇撶杽闂勫懍鐜崐绗衡偓?
- 閻劍鍩涢崣宥夘洯閵嗗苯鍑￠張澶嬫綏閺傛瑤绱崗鍫濆爱闁板秲鈧秴鐡ㄩ崷銊ャ亼閺佸牆婧€閺咁垽绱濇潻鐐电敾妞嬬喐娼楅惌顓☆嚔閺冪姵纭剁粙鍐茬暰閹峰棗鍤径姘嚋閸欘垰灏柊?token閵?
- 閻劍鍩涢崣宥夘洯閻愮懓鍤粻锛勬倞妞ゅ吀绱伴崡鈩冾劥閿涘矂娓剁憰渚€鎷＄€?7000+ 閼挎粏姘ㄧ憴鍕佺拋鎹愵吀閺囧瓨鐎懛瀵告畱閹嗗厴鐠侯垰绶為妴?
- 閻劍鍩涢棁鈧憰浣稿讲閼奉亜鐣炬稊澶屾畱妞嬬喕姘ㄩ弬瑙勵攳閿涙碍濡搁懣婊嗘皑閸旂姴鍙嗘稉顏冩眽闂嗗棗鎮庨敍灞借嫙閼宠棄婀梿鍡楁値閸愬懐鐡柅澶堚偓渚€娈㈤張鎭掆偓浣侯吀閻炲棎鈧?
- 閻劍鍩涢棁鈧憰浣稿敶缂冾喛褰嶇拫杈ㄦ暜閹镐浇顩惄鏍х础娑擃亙姹夌拫鍐╂殻閿涘奔绡冮弨顖涘瘮閸欙箑鐡ㄦ稉铏瑰缁斿閲滄禍楦垮綅鐠嬩究鈧?

### 閺傛澘顤?
- `DailyChoiceEatCollection` 娑?`DailyChoiceCustomState.eatCollections`閿涘本鏁幐浣规拱閸︾増瀵旀稊鍛閸氬啩绮堟稊鍫滅瑩鐏炵偤顥ょ拫閬嶆肠閵?
- 妞嬬喕姘ㄩ梿鍡樻惙娴ｆ粏鍏橀崝娑崇窗閸掓稑缂撻梿鍡楁値閵嗕礁鍨归梽銈夋肠閸氬牄鈧礁濮為崗銉ㄥ綅鐠嬩究鈧胶些閸戦缚褰嶇拫渚库偓浣稿灩闂勩倛鍤滅€规矮绠熼懣婊勬閼奉亜濮╂禒搴ㄦ肠閸氬牅鑵戝〒鍛倞閵?
- 閸氬啩绮堟稊鍫滃瘜妞ょ敻娼伴弬鏉款杻妞嬬喕姘ㄩ梿鍡欑摣闁鍙嗛崣锝忕幢闁瀚ㄩ梿鍡楁値閸氬函绱濋梾蹇旀簚濮圭姴鎷版妯奸獓缁涙盯鈧褰ч崷銊ョ秼閸撳秹娉﹂崥鍫濆敶瀹搞儰缍旈妴?
- 缁狅紕鎮婃い鍨煀婢х偑鈧本鍨滈惃鍕棨鐠嬮亶娉﹂妴宥呭隘閸╃噦绱濋崣顖氬灡瀵ゆ椽娉﹂崥鍫涒偓浣瑰瘻闂嗗棗鎮庨崣顏嗘箙閵嗕礁鍨归梽銈夋肠閸氬牞绱濋獮鏈电矤閸愬懐鐤?/ 鐠嬪啯鏆?/ 閼奉亜鐣炬稊澶庡綅鐠嬪崬宕遍悧鍥у閸忋儲鍨ㄧ粔璇插毉闂嗗棗鎮庨妴?
- 閸愬懐鐤嗛懣婊冩嫲娑擃亙姹夌拫鍐╂殻閺傛澘顤冮妴灞藉綗鐎涙ǜ鈧秴濮╂担婊愮礉閸欘垱濡搁懣婊嗘皑婢跺秴鍩楅幋鎰缁斿閲滄禍娲棨鐠嬭京鎴风紒顓犵椽鏉堟垯鈧?
- 閺傛澘顤?`test/daily_choice_custom_state_test.dart`閿涘矁顩惄鏍棨鐠嬮亶娉︽惔蹇撳灙閸栨牕鎷伴崚鐘绘珟閼奉亜鐣炬稊澶庡綅閺冨墎娈戦梿鍡楁値濞撳懐鎮婇妴?

### 娣囶喗鏁?
- 濮ｅ繑妫╅幎澶嬪妞ょ數些闂勩倝顩荤仦蹇撱亣閸楋紕澧栭妴灞藉帥鐠佲晠鈧瀚ㄩ崝銊ㄦ崳閺夈儯鈧稄绱濈拋鈺偰侀崸妤€鍨忛幑顫瑢瑜版挸澧犲銉ュ徔閸愬懎顔愰弴鏉戞彥鏉╂稑鍙嗘＃鏍х潌閵?
- 閸氬啩绮堟稊鍫ャ€夐棃顫瑝閸愬秴鐖舵す璇茬潔缁€楦垮綅鐠嬪崬绨辩拠瀛樻閸椻槄绱辨禒鍛躬閺堫亜鐣ㄧ憗鍛偓浣稿鏉炴垝鑵戦幋鏍х磽鐢憡妞傞弰鍓с仛鐠у嫭绨崙鍡楊槵閻樿埖鈧降鈧?
- 閸氬啩绮堟稊鍫ャ€夐棃銏ゃ€庢惔蹇氱殶閺佺繝璐熸鎰唽 / 閸樸劌鍙?/ 妞嬬喕姘ㄩ梿?-> 闂呭繑婧€娑撴槒鍨堕崣?-> 妤傛楠囩粵娑⑩偓澶涚礉閸戝繐鐨潻娑樺弳妞ょ敻娼伴崥搴ｆ畱鐟欏棜顫庣拹鐔稿閵?
- 缁狅紕鎮婃い闈涘敶缂冾喛褰嶇拫鍗炲灙鐞涖劍鏁兼稉鍝勫瀻妞ら潧鐫嶇粈鐚寸礉姒涙顓婚崣顏呯€娲浕閹佃娼惄顕嗙礉缂佈呯敾閸旂姾娴囬弮璺哄晙鏉╄棄濮炴稉瀣╃妞ょ绱濋柆鍨帳閹垫挸绱戠粻锛勬倞妞ゅ吀绔村▎鈩冣偓褎鐎鍝勫弿闁插繐宕遍悧鍥モ偓?
- 缁狅紕鎮婃い鍨偝缁鳖潿鈧線顦靛▓鐐光偓浣稿腹閸忔灚鈧焦鐖ｇ粵鎯ф嫲闂嗗棗鎮庣粵娑⑩偓澶婂綁閺囧瓨妞傛导姘跺櫢缂冾喖鍨庢い鐢电崶閸欙綇绱濋幖婊呭偍娴犲秷顩惄鏍х暚閺佺褰嶇拫鍗炵氨閵?
- 妞嬬喐娼楄ぐ鎺嶇閸栨牕顤冨杞拌礋閸欘垯绮犻妴宀€鏆橀懠鍕诞閾斿鐪撮懙鎰牎閵嗗秷绻栫猾鏄忕箾缂侇厾鐓拠顓濊厬閹绘劕褰囨径姘嚋鐟欏嫯瀵?token閿涘苯鑻熺€?`鐠炲棜鍘?/ 閻楁稑銈?/ 妤βゆ巢` 缁涘鍣搁崣鐘插焼閸氬秹鍣伴悽銊︽纯閸忚渹缍嬫い閫涚喘閸忓牞绱濋柆鍨帳閸栧綊鍘ら崚鍡樻殶閾忔岸鐝妴?

### 娣囶喖顦?
- 娣囶喖顦插鍙夋箒閺夋劖鏋℃导妯哄帥閸栧綊鍘ら崷銊ф彛閸戞垼绶崗銉﹀灗缁毖冨櫨閼挎粌鎮曟稉顓炲涧閸涙垝鑵戠粭顑跨娑擃亪顥ら弶鎰畱闂傤噣顣介妴?
- 娣囶喖顦茬粻锛勬倞妞ゅ灚澧﹀鈧弮璺烘礈娑撯偓濞嗏剝鈧勭€鐑樻殶閸楀啩閲滈崘鍛枂閼挎粏姘ㄩ崡锛勫鐎佃壈鍤ч崡鈩冾劥閻ㄥ嫭鐗宠箛鍐懕妫板牄鈧?

### 妞嬪酣娅撻崣妯绘纯
- 妞嬬喐娼楅惌顓☆嚔閹峰棜鐦濇导姘愁唨闁劌鍨庨懣婊嗘皑閼惧嘲绶遍弴鏉戠暚閺佸娈戞鐔告綏 token閿涘矂娈㈤張鐑樼潨閻╃鍙ч幀褌绱伴幓鎰磳閿涘奔绲炬稉顏勫焼濞夋稑瀵查弽鍥╊劮閸涙垝鑵戦懠鍐ㄦ纯娑旂喎褰查懗钘夊綁閸栨牓鈧?
- 妞嬬喕姘ㄩ梿鍡楃秼閸撳秳绮涙穱婵嗙摠閸︺劍婀伴張?`toolbox_daily_choice_v1.json`閿涘苯鐨婚張顏呭复閸忋儴澶勯崣宄版倱濮濄儯鈧礁顦禒钘夘嚤閸忋儱顕遍崙鐑樺灗娴滄垹顏径姘鳖伂閸氬牆鑻熼妴?
- 缁狅紕鎮婃い闈涘瀻妞ゅ吀绮庨梽鎰煑 UI 閺嬪嫬缂撻弫浼村櫤閿涘本鎮崇槐銏犳嫲缁涙盯鈧绮涢崺杞扮艾閺堫剙婀撮幗妯款洣閸忋劑娉﹂敍娑滃閺堫亝娼甸懣婊嗘皑闁插繒鎴风紒顓熷⒖婢堆冨煂閺佹澘宕勬稉鍥╅獓閿涘苯绨叉潻娑楃濮濄儲濡哥粻锛勬倞閹兼粎鍌ㄦ潻浣盒╅崚?SQLite 缁便垹绱╅弻銉嚄閵?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_catalog.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_support.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_catalog.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_support.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_065-EAT-S3] - 2026-04-25

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴鐏忓棌鈧粌鎮嗘禒鈧稊鍫氣偓婵婂綅鐠嬪崬绨遍崚鍥ㄥ床閸掓媽绻欑粩?S3 `/cook_data` 鐠у嫭绨敍宀€些闂勩倕鐣ㄧ憗鍛瘶閸愬懏婀伴崷鎷屽綅鐠嬭精绁┃鎰剁礉闁灝鍘ょ紒褏鐢绘晶鐐层亣閸栧懍缍嬮獮鑸靛珛閹便垻些閸斻劎顏＃鏍х磻閵?
- 閻劍鍩涚敮灞炬箿妞ょ敻娼版い鍫曞劥鏉╂稐绔村銉︽暪閸欙綇绱濋崣顏冪箽閻ｆ瑦鈧粯娼弫棰佺瑢瑜版挸澧犵粵娑⑩偓澶嬬潨閺夆剝鏆熼敍灞借嫙閺€顖涘瘮閹舵ê褰旈妴?
- 閻劍鍩涚憰浣圭湴缁狅紕鎮婃い闈涙躬閳ユ粈绗夐崰婊勵偨閳ユ繀绠ｆ径鏍ㄦ煀婢х偐鈧粈閲滄禍楦跨殶閺佺补鈧繆鍏橀崝娑崇礉閸忎浇顔忛崺杞扮艾閸愬懐鐤嗛懣婊嗘皑娣囨繂鐡ㄦ稉顏冩眽閸欙絽鎳楅悧鍫熸拱閿涘苯鑻熺憰浣圭湴缁狅紕鎮婇悾宀勬桨閺囨挳鈧倸鎮庨幍瀣簚缁旑垱濮岄崣鐘崇セ鐟欏牄鈧?

### 閺傛澘顤?
- `DailyChoiceCustomState` 閺傛澘顤?`adjustedBuiltInOptions` 閹镐椒绠欓崠鏍х摟濞堢绱濋弨顖涘瘮娣囨繂鐡ㄩ崘鍛枂閼挎粏姘ㄩ惃鍕嚋娴滈缚鐨熼弫瀵稿閺堫剨绱濋獮鑸靛絹娓?`upsertAdjustedBuiltIn / restoreAdjustedBuiltIn / adjustedBuiltInById` 閹垮秳缍旈妴?
- `daily_choice_manager_sheet.dart` 娑撳搫鎮嗘禒鈧稊鍫熸煀婢х偐鈧粍鍨滈惃鍕殶閺佺补鈧繂鍨庨崠鐚寸礉閺€顖涘瘮缂佈呯敾鐠嬪啯鏆ｉ妴浣逛划婢跺秴甯崨绛圭礉楠炶埖濡搁崘鍛枂閼挎粈绗屾稉顏冩眽鐠嬪啯鏆ｇ紒鐔剁缁惧啿鍙嗛崣顖涙偝缁鳖潿鈧礁褰查悙鐟板毊閺屻儳婀呯拠锔藉剰閻ㄥ嫮些閸斻劎顏幎妯哄綌缁狅紕鎮婇悾宀勬桨閵?

### 娣囶喗鏁?
- `daily_choice_eat_library_store.dart` 閹恒儱鍙?S3 鏉╂粎顏惔鎾插瘜闁炬崘鐭鹃敍宀勵浕濞嗭紕鍋ｉ崙缁樻娴兼ê鍘涙稉瀣祰 `cook_data/daily_choice_recipe_library.db` 閸掓澘绨查悽銊︽暜閹镐胶娲拌ぐ鏇礉閺堫剙婀存穱婵堟殌閺嶅洤鍣?SQLite `summary / detail / index / meta` 鐞涖劎绮ㄩ弸鍕嫙婢跺秶鏁ら弮銏℃箒 S3 閸忕厧顔愮€广垺鍩涚粩顖樷偓?
- `daily_choice_eat_library_store.dart` 鐎瑰顥婇幋鎰閸氬簼绱板〒鍛倞閺冄呮畱 `toolbox_daily_choice_recipe_library.json` 閸?`toolbox_daily_choice_cook_recipe.csv` 闁鏆€缂傛挸鐡ㄩ敍娑滃鏉╂粎顏€瑰顥婃径杈Е娑撴梹婀伴崷鏉垮嚒閺堝绨遍敍灞藉灟缂佈呯敾閸ョ偤鈧偓娴ｈ法鏁ゅ鍙夋箒鎼存挶鈧?
- `daily_choice_hub.dart` 娑?`daily_choice_eat_module.dart` 閺€閫涜礋閸氬本妞傛穱婵堟殌閳ユ粌甯慨瀣敶缂冾喛褰嶇拫鎵佲偓婵嗘嫲閳ユ粌绨查悽銊ら嚋娴滈缚鐨熼弫鏉戞倵閻ㄥ嫬鍞寸純顔垮綅鐠嬫墎鈧繐绱濈涵顔荤箽缁狅紕鎮婃い闈涘讲娴犮儲顒滅涵顔藉⒔鐞涘备鈧粍浠径宥呭斧閸涙枼鈧繐绱濋獮鍫曚缉閸忓秵濡哥拫鍐╂殻閸氬海娈戣箛顐ゅ弾闁挎瑨顕よぐ鎾茬稊閸樼喎顫愰崺铏瑰殠閵?
- `daily_choice_eat_module.dart` 濞撳懐鎮婇柆妤冩殌閺冄呭Ц閹礁宕辨禒锝囩垳閿涘矂銆夐棃銏ゃ€婇柈銊ㄥ綅鐠嬪崬绨辨穱鈩冧紖閸椻剝鏁归崣锝勮礋閹舵ê褰斿蹇曟彛閸戞垵宕遍悧鍥风礉閸欘亙绻氶悾娆欑窗
  - 閹绨遍弶鈩冩殶
  - 瑜版挸澧犵粵娑⑩偓澶嬬潨閺夆剝鏆?
  - 閸旂姾娴?/ 闁挎瑨顕ら悩鑸碘偓?
- `daily_choice_manager_sheet.dart` 闁插秵鐎稉鐑樻纯闁倸鎮庨幍瀣簚缁旑垳娈戦幎妯哄綌缂佹挻鐎敍?
  - 閹兼粎鍌ㄦ穱婵囧瘮鐢悂鈹?
  - 缁涙盯鈧娼禒鑸靛閸?
  - 閹存垹娈戦懛顏勭暰娑?/ 閹存垹娈戠拫鍐╂殻 / 閸愬懐鐤嗛弶锛勬窗閹舵ê褰?
  - 閸愬懐鐤嗛懣婊勬暜閹镐讲鈧粈閲滄禍楦跨殶閺?/ 閹垹顦查崢鐔锋嚄 / 娑撳秴鏋╁▎鈶┾偓?
- `test/daily_choice_eat_library_store_test.dart` 閺€閫涜礋鐟曞棛娲婃潻婊咁伂 SQLite 鐎瑰顥婇柧鎹愮熅閿涘奔绗夐崘宥勭贩鐠ф牜缍夌紒婊€绗呮潪鑺ュ灗 bundled 鐠у嫭绨妴?
- `test/daily_choice_hub_smoke_test.dart` 閸氬本顒炴宀冪槈 S3 妞嬪孩鐗搁崝鐘烘祰閹稿鎸抽弬鍥攳閵嗕胶顓搁悶鍡涖€夋稉顏冩眽鐠嬪啯鏆ｉ崗銉ュ經閿涘奔浜掗崣濞锯偓婊勪划婢跺秴甯崨鏂モ偓婵嗗З娴ｆ粌婀禍銈勭鞍鐏炲倻娈戦崣顖濇彧閹佲偓?
- 閸氬啩绮堟稊鍫ｅ綅鐠?asset 瀹歌弓绮犳惔鏃傛暏閹垫挸瀵橀柊宥囩枂娑擃厾些闂勩倧绱濇稉宥呭晙缂佈呯敾闂呭繐鐣ㄧ憗鍛瘶閹煎搫鐢?`assets/toolbox/daily_choice/recipe_library.json`閵?

### 妞嬪酣娅撻崣妯绘纯
- 瑜版挸澧犳潻婊咁伂鐎瑰顥婃禒宥勭箽閻ｆ瑢鈧粌鍑￠張澶嬫拱閸︽澘绨辨导妯哄帥缂佈呯敾閸欘垳鏁ら垾婵堟畱閸忔粌绨崇粵鏍殣閿涘奔绲炬＃鏍偧鐎瑰顥婇懟?S3 鐠佸潡妫舵径杈Е閿涘瞼鏁ら幋铚傜矝闂団偓鐟曚胶鈼㈤崥搴ㄥ櫢鐠囨洘澧犻懗鑺ュ瑏閸掓澘鐣弫纾嬪綅鐠嬪崬绨遍妴?
- `daily_choice_cook_service.dart` 娑擃厾娈?bundled 鐟欙絾鐎界捄顖氱窞閺嗗倹婀€瑰苯鍙忛崚鐘绘珟閿涘苯褰ф担婊€璐熼崗鐓庮啇閸忔粌绨抽柅鏄忕帆娣囨繄鏆€閿涙稖绻嶇悰灞炬娑撴槒鐭惧鍕嚒缂佸繐鍨忛崚?S3 閺堫剙婀寸紓鎾崇摠鎼存挶鈧?
- 閺堫剝鐤嗛張顏勭暚閹存劒绮ㄦ惔鎾冲弿闁?`dart analyze`閿涙艾缍嬮崜宥嗩攽闂堛垻骞嗘晶鍐ㄦ儙閸斻劌鍨庨弸鎰箛閸斺剝妞傞柆顓海 `dartaotruntime.exe` 閹锋帞绮风拋鍧楁６閿涘矂娓剁憰浣告倵缂侇厼婀張顒佹簚閺夊啴妾洪悳顖氼暔娑撳藟鐠烘垯鈧?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart test/daily_choice_eat_library_store_test.dart test/daily_choice_hub_smoke_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_064-EAT] - 2026-04-25

### 閸樼喎娲?
- 閻劍鍩涚紒褏鐢荤憰浣圭湴鐎瑰苯鏉藉銉ュ徔缁犳墎鈧粍鐦￠弮銉﹀Ψ閹封斁鈧繀鑵戦惃鍕ㄢ偓婊冩倖娴犫偓娑斿牃鈧繂鐡欏Ο鈥虫健閿涘苯鑻熼弰搴ｂ€橀幐鍥у毉瑜版挸澧犻懣婊嗘皑闁插繒楠囨潻婊嗙箼娑撳秴顧勯敍宀勬付鐟曚焦甯撮崗銉︽纯婢堆呮畱閺堫剙婀撮懣婊嗘皑鎼存挶鈧?
- 闂団偓鐟曚焦濡?`D:\vocabularySleep-resources\閸嬫俺褰峘 娑擃厼褰茬粙鍐茬暰閹惰棄褰囬惃鍕暚閺佺褰嶇拫鍗炲箵闁插秴鎮楅幒銉ュ弳妞ょ敻娼伴敍灞芥倱閺冩儼藟姒绘劕鍑￠張澶嬫綏閺傛瑤绱崗鍫涒偓渚€鐝痪褏鐡柅澶堚偓浣侯吀閻炲棙鎮崇槐顫偓浣瑰瘹閸楁鏆ｉ崥鍫濇嫲娑擃亙姹夋鐔绘皑閼宠棄濮忛妴?
- 閻劍鍩涙０婵嗩樆鐟曚焦鐪扮€电懓褰滅猾宥堢カ閺傛瑤绻氶幐浣稿帬閸掕绱伴崣顏呮箒閸︺劏鐦戦崚顐ュ窛闁插繐褰查棃鐘虫閹靛秴宕熼悪顒佸复閸忋儮鈧粓顥ら悿妞剧瑢缁備礁绻夐垾婵嗙摍妞ょ绱濇稉宥堝厴娑撹桨绨＄憰鍡欐磰閻滃洤宸辩悰宀冪槕閸掝偁鈧?
- 閻劍鍩涢崷銊ф埛缂侇厺缍嬫灞炬閸欏秹顩垾婊冩倖娴犫偓娑斿牃鈧繈銆夐棃銏ゎ浕瀵偓闂堢偛鐖堕崡掳鈧礁鍑￠張澶嬫綏閺傛瑤绱崗鍫濆殤娑斿骸褰ч崜鈺€绔寸粔宥忕礉鐟曚焦鐪伴幎濠冣偓褑鍏橀妴浣稿爱闁板秶鐣诲▔鏇樷偓浣割樋妞嬬喐娼楃紓鏍帆閸滃矁鍤滅€规矮绠熻箛灞藉經娑撯偓鐠ч攱鏁归崣锝呭煂閸欘垳鏁ら悩鑸碘偓浣碘偓?

### 閺傛澘顤?
- 閺傛澘顤冪粋鑽ゅ殠閹惰棄褰囬懘姘拱 `scripts/generate_daily_choice_recipe_dataset.py`閿涘瞼鏁ゆ禍搴濈矤 `D:\vocabularySleep-resources\閸嬫俺褰峘 閹绘劕褰囩€瑰本鏆ｉ懣婊嗘皑楠炲墎鏁撻幋鎰般€嶉惄顔煎敶缂佹挻鐎崠鏍ㄦ殶閹诡噣娉﹂妴?
- 閺傛澘顤冮幍鎾冲瘶鐠у嫭绨?`assets/toolbox/daily_choice/recipe_library.json`閿涘苯缍嬮崜宥呭瘶閸?`7179` 閺夆€冲箵闁插秴鎮楅惃鍕拱閸︽媽褰嶇拫鎲嬬礉楠炲爼妾敮锔剧埠娑撯偓閸欏倽鈧啩鍔熼惄顔煎帗閺佺増宓侀妴?
- 閺傛澘顤冮張顒€婀寸€电厧鍤惄顔肩秿 `D:\vocabularySleep-resources\cook_data`閿涘苯鎮撳銉ф晸閹存劧绱?
  - `daily_choice_recipe_library.json`
  - `daily_choice_recipe_library_summary.json`
  - `daily_choice_recipe_library.db`
- 閺傛澘顤?`daily_choice_eat_library_store.dart`閿涘苯鐨?bundled / cached / remote 閼挎粏姘ㄧ挧鍕爱閺佸鎮婄€电厧鍙嗛悪顒傜彌 SQLite閿涘本婀伴崷鎵樊閹?`summary / detail / index / meta` 閸ユ稓琚弽鍥у櫙鐞涖劋绗岀粵娑⑩偓澶屽偍瀵洏鈧?
- 閺佺増宓侀弫瀵告倞閼存碍婀伴弬鏉款杻婢舵俺袙閺嬫劕娅掔粻锛勫殠閿涘矁藟姒?`The Italian Pantry`閵嗕梗Nourishing Recipes for Elderly`閵嗕梗妞嬬喕鍙敍姘儌閺傚洨娈戦弮鐘叉禇閻ｅ苯鍨遍幇蹇撳腹閹寸笡 缁涘鏌婇悧鍫濈础 EPUB 閻ㄥ嫬鐣弫纾嬪綅鐠嬭鲸褰侀崣鏍电礉楠炶泛顕担搴ゅ窛闁插繐褰滅猾?/ 閹殿偅寮跨挧鍕灐娣囨繃瀵旂捄瀹犵箖缁涙牜鏆愰妴?
- 閺傛澘顤冮弽鍥у櫙閸栨牞褰嶇拫鍗炵氨妞よ泛鐪扮€涙顔岄敍姝歭ibraryId / libraryVersion / schemaId / schemaVersion`閿涘奔璐熼崥搴ｇ敾鏉╂粎顏崚鍡楀絺閹?S3 閹垫顓告穱婵堟殌缂佺喍绔寸€电钖勯弽鐓庣础閵?
- `daily_choice_eat_support.dart` 娑撳搫鎮嗘禒鈧稊鍫熸煀婢х偟绮ㄩ弸鍕鐏炵偞鈧勬暜閹镐緤绱?
  - `meal / type / profile / diet / contains / ingredient / tool`
  - 妞嬬喐娼楄ぐ鎺嶇閸栨牔绗屾径姘降濠ф劕鐫橀幀褑藟姒?
  - 瀹稿弶婀侀弶鎰灐閸栧綊鍘ょ拋鈩冩殶閵嗕礁灏柊宥嗙槷娓氬鎷伴張鈧导妯衡偓娆撯偓澶嬫暪閸?
  - 婢舵碍娼靛┃鎰綅鐠嬪崬鎮庨獮璺哄箵闁?
- 閺傛澘顤?`daily_choice_eat_module.dart`閿涘本鏁归幏銏犳倖娴犫偓娑斿牅绗撻悽銊┿€夐棃銏㈢波閺嬪嫨鈧線鐝痪褑顔曠純顔煎隘閸滃本瀵氶崡妤€鍙嗛崣锝冣偓?
- 閹碘晛鍘?`buildCookingGuideModules(...)`閿涘本鏌婃晶鐐┾偓婊冪唨绾偓閹垛偓閼宠В鈧績鈧粓顥ら弶鎰爱闁板秳绗岀粵娑⑩偓澶庮嚛閺勫簶鈧績鈧粌寮懓鍐у姛閻╊喒鈧繀绗佹稉顏呭瘹閸楁膩閸фぜ鈧?
- 閹碘晛鍘?`test/daily_choice_cook_service_test.dart`閿涘矁顩惄鏍电窗
  - `cook` CSV 鐟欙絾鐎介崥搴ｆ畱妞佹劖顔?閸樸劌鍙块弰鐘茬殸
  - 閸楀牓顦?閺呮岸顦甸柌宥呭綌鐞涘奔璐?
  - bundled 閼挎粏姘ㄦ惔鎾诲櫢婢跺秷顕伴崣鏍ㄦ閻ㄥ嫬鐤勬笟瀣敶鐟欙絾鐎界紓鎾崇摠
  - 婢舵碍娼靛┃鎰綅鐠嬪崬鎮庨獮璺哄箵闁?
- 閺傛澘顤?`test/daily_choice_eat_catalog_test.dart` 娑?`test/daily_choice_hub_smoke_test.dart`閿涘苯鍨庨崚顐ヮ洬閻╂牠鐝痪褏鐡柅?婢舵岸顥ら弶鎰版閺堢儤鐫滅粵鏍殣閿涘奔浜掗崣濠囥€夐棃銏ｇ箻閸忋儯鈧礁鐫嶅鈧妯奸獓鐠佸墽鐤嗛妴浣瑰潑閸旂娀顥ら弶?chip閵嗕焦鍧婇崝鐘哄殰鐎规矮绠熻箛灞藉經楠炶泛鐣幋鎰版閺堝搫浠犲銏㈡畱閻戠喖娴橀柧鎹愮熅閵?

### 娣囶喗鏁?
- `pubspec.yaml` 閹恒儱鍙?`assets/toolbox/daily_choice/` 鐠у嫭绨惄顔肩秿閿涘奔绻氱拠浣侯瀲缁捐儻褰嶇拫鍗炵氨闂呭繐绨查悽銊﹀ⅵ閸栧懌鈧?
- `daily_choice_cook_service.dart` 閺€閫涜礋閹稿鈧粍婀伴崷鏉跨氨 -> 閺堫剙婀寸紓鎾崇摠 -> 鏉╂粎顏崚閿嬫煀 -> 閸忔粌绨崇粔宥呯摍閳ユ繈銆庢惔蹇撳鏉炴枻绱濋獮璺烘躬閺堫剙婀存惔鎾茬瑢 `cook` 閺佺増宓佹稊瀣？閸嬫氨绮ㄩ弸鍕閸氬牆鑻熼崢濠氬櫢閵?
- `daily_choice_cook_service.dart` 娑?bundled 婢堆嗗綅鐠嬪崬绨辨晶鐐插鐠恒劌鐤勬笟瀣掗弸鎰处鐎涙ǜ鈧梗12h` 鏉╂粎顏崚閿嬫煀 TTL閿涘苯鑻熼柆鍨帳閸︺劍鐥呴張澶岀处鐎涙ɑ鏋冩禒鑸垫閺冪姵鍓版稊澶庮嚢閸欐牗鏆ｆ禒钘夈亣 bundle閵?
- `daily_choice_hub.dart` 鐏忓棗鎮嗘禒鈧稊鍫濆灥婵瀵插ù浣衡柤閺€閫涜礋楠炶泛褰傞崝鐘烘祰閼奉亜鐣炬稊澶屽Ц閹礁鎷伴懣婊嗘皑閺佺増宓侀敍灞借嫙绾喕绻氶崥鍐х矆娑斿牆鈧瑩鈧婀潻娑樺弳妞ょ敻娼伴崜宥囩埠娑撯偓鐞涖儵缍堢紒鎾寸€崠鏍х潣閹嶇幢妫ｆ牗顐兼潻娑樺弳閼汇儱鐨婚張顏勭暔鐟佸懓褰嶇拫鍗炵氨閿涘苯鍨弰搴ｂ€橀幓鎰仛閻劍鍩涢悙鐟板毊鐎电厧鍙嗛張顒€婀?SQLite閵?
- `daily_choice_hub.dart` 閸︺劑銆夐棃銏犵湴閸欘亝瀵旈張澶夌濞嗏€崇秼閸撳秴褰茬憴浣藉綅鐠嬭京鍌ㄥ鏇礉鏉╂稑鍙嗘い鐢告桨閸滃苯鍨忛幑銏㈢摣闁妞傛稉宥呭晙閸欏秴顦茬€?6000+ 閼挎粏姘ㄩ崑姘弿闁插繐鐫橀幀褎甯归弬顓濈瑢閹殿偅寮块妴?
- `daily_choice_eat_catalog.dart` 閺傛澘顤冩０鍕紦缁便垹绱╂潻鍥ㄦ姢鐠侯垰绶為敍宀€菙鐎规碍鏁幐浣割樋妞佹劖顔岄柌宥呭綌閵嗕礁甯归崗椋庣摣闁鈧浇宕电槐?閸欏銈介弽鍥╊劮閵嗕礁鐖剁憴浣哥箟閸欙絻鈧浇鍤滅€规矮绠熻箛灞藉經閸滃苯顦挎鐔告綏娴兼ê鍘涢崠褰掑帳閵?
- `daily_choice_eat_support.dart` 鐏忓棌鈧粌鍑￠張澶嬫綏閺傛瑤绱崗鍫氣偓婵囨暭娑?`exact -> strong -> broad` 娑撳妯佸▓鐢告閺堢儤鐫滅粵鏍殣閿涘苯鑻熼崷銊ユ嚒娑擃厼銇婄亸鎴炴閼奉亜濮╃悰銉ュ弳妤傛娴夐崗鍐测偓娆撯偓澶涚礉闁灝鍘ら梾蹇旀簚缂佹挻鐏夐梹鎸庢埂閸欘亜澧?1 闁捁褰嶉妴?
- `daily_choice_seed_data.dart` 閹跺﹤浠涢懣婊勫瘹閸楁宕岀痪褌璐熺紒鐔剁閸欏倽鈧啩鍔熼惄顔惧閺堫剨绱濋弫鏉戞値 `cook` 閳ユ粌浠涢懣婊€绠ｉ崜宥佲偓婵呯瑢閺堫剙婀撮崺铏诡攨閹垛偓閼虫枻绱濋獮鎯八夐崗鍛偓婊勭閼挎粌骞撳▓瀣殌閳ユ繂鎷伴垾婊呭劋閻掓瑥鍘涚粔浼村櫤閳ユ繀琚遍弶鈥崇俺鐏炲倹鎼锋担婊勫瘹閸楁绱遍妴濠囶棨閻椻晞绶憰浣碘偓瀣埛缂侇厽妲戠涵顔界垼鐠侀璐熼弳鍌欑瑝閹恒儱鍙嗛妴?
- `daily_choice_manager_sheet.dart` 娑撳搫鎮嗘禒鈧稊鍫熸煀婢х偠褰嶉崥宥嗘偝缁鳖潿鈧線顦靛▓鐢稿櫢閸欑姷鐡柅澶堚偓浣稿腹閸忛鐡柅澶婃嫲閺嶅洨顒风粵娑⑩偓澶堚偓?
- `daily_choice_eat_module.dart` 閻ㄥ嫰鐝痪褑顔曠純顔芥暭娑撶儤鏁幐浣割樋妞嬬喐娼楀ǎ璇插/閸掔娀娅庨妴浣割樋閼奉亜鐣炬稊澶婄箟閸?chip 缂傛牞绶敍灞借嫙鐞涖儵缍堟＃娆掑綅閵嗕浇濮抽悽鐔粹偓浣哄婵傝翰鈧線濂旈懙銉ㄥ磸缁涘鐖剁憴浣界殶閺?妞嬬喐娼楄箛灞藉經閸忋儱褰涢妴?
- `daily_choice_editor_sheet.dart` 娑撹桨閲滄禍娲棨鐠嬪彉绻氱€涙﹢鈧槒绶悰銉╃秷閼奉亜濮?attributes 閹恒劍鏌囬妴浣圭垼缁涙崘藟姒绘劕鎷版妯款吇鐠囷附鍎忛崗婊冪俺閵?
- `daily_choice_detail_sheets.dart` 鐎电懓鎮嗘禒鈧稊鍫ｎ嚊閹懘銆夐梾鎰闁劖娼弶銉︾爱鐠囧瓨妲戦敍灞炬暭娑撳搫鐫嶇粈铏圭波閺嬪嫬瀵查弽鍥╊劮閹芥顩﹂妴浣哥暚閺佸瓨顒炴銈勭瑢閸忔娊鏁幓鎰仛閿涙稓顓搁悶鍡涖€夐悙鐟板毊閼挎粌鎮曢弮璺烘倱閺嶉攱瀵滈懣婊嗘皑 ID 鐠囪褰囩€瑰本鏆ｇ拠锔藉剰閵?
- `daily_choice_modules.dart` 濞撳懐鎮婇弮褏娈戦崥鍐х矆娑斿牆鐤勯悳甯礉娴犲懍绻氶悾?`go / activity` 閸忣剙鍙″Ο鈥虫健閿涘矂浼╅崗宥嗘＋闁槒绶紒褏鐢绘稉搴㈡煀閸氬啩绮堟稊鍫ャ€夐棃銏犺嫙鐎涙ǜ鈧?
- `modules/toolbox/README.md` 閸氬本顒炵拋鏉跨秿閸氬啩绮堟稊鍫㈩瀲缁惧灝銇囨惔鎾扁偓浣虹摣闁鍏橀崝娑栤偓浣瑰瘹閸楁鏆ｉ崥鍫濇嫲閸欍倗鐫勭捄瀹犵箖鏉堝湱鏅妴?

### 妞嬪酣娅撻崣妯绘纯
- 濞撳懐婀￠崣瀣偨閵嗕胶绀屾鐔峰几婵傚鈧礁鐖剁憴浣哥箟閸欙絼绗屾潻鍥ㄦ櫛閸樼喓鐡柅澶婃綆鐏炵偘绨崥顖氬絺瀵繗绶熼崝鈺傜垼缁涙拝绱濇稉宥囩搼娴犺渹绨€规鏆€閵嗕礁灏扮€涳附鍨ㄦ稉鎾茬瑹閽€銉ュ悋鐠併倛鐦夐妴?
- 閺堫剙婀撮懣婊嗘皑鎼存挷缍嬮柌蹇撳嚒閹绘劕宕岄崚鎵 `26.7 MB` JSON / `47.4 MB` SQLite 鐎电厧鍤敍娑樼秼閸撳秹鈧俺绻冩０鍕紦缁便垹绱╅妴浣告閸氬氦绻欑粩顖氬煕閺傝埇鈧胶绱︾€涙ê顦查悽銊ょ瑢缁涙盯鈧鏁归崣锝嗗付閸掑爼顩荤仦蹇撳竾閸旀冻绱濋崥搴ｇ敾閼汇儳鎴风紒顓熷⒖鎼存搫绱濇导妯哄帥瀵ら缚顔呯挧?`summary manifest + detail/SQLite` 鏉╂粎顏幐澶愭付閸旂姾娴囬妴?
- 閵嗗﹪顥ら悧鈺勭帆鐟曚降鈧鐫樻禍搴ｇ彨閹烘帒褰滄担鎾圭カ閺傛瑱绱濋張顒冪枂閺勫海鈥樻稉宥呭繁鐞涘本甯撮崗銉⑩偓婊堫棨閻ゆぞ绗岀粋浣哥箟閳ユ繂鐡欐い纰夌礉閸氬海鐢婚崣顏勬躬鐠囧棗鍩嗙拹銊╁櫤缁嬪啿鐣鹃弮璺哄晙閸楁洜瀚拃钘夋勾閵?
- 閼奉亜鐣炬稊澶夐嚋娴滄椽顥ょ拫鍙樼瑢闂呮劘妫岄崘鍛枂妞ら€涚矝娣囨繂鐡ㄩ崷銊︽拱閸?`toolbox_daily_choice_v1.json`閿涘苯缍嬮崜宥勭瑝閹恒儱鍙嗙拹锕€褰块崥灞绢劄閹存牞娉曠粩顖氼槵娴犲鈧?

### 妤犲矁鐦?
- `python scripts\\generate_daily_choice_recipe_dataset.py`閿涘牓鈧俺绻冮敍宀勫櫢閺傛壆鏁撻幋?`7179` 閺夆€冲箵闁插秷褰嶇拫鎲嬬礉閸樼喎顫愰幎钘夊絿 `7364` 閺夆槄绱濋獮璺烘倱濮濄儱顕遍崙?full JSON / summary JSON / SQLite閿?
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_cook_service.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_catalog.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_support.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_recipe_library.dart test/daily_choice_cook_service_test.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_hub_smoke_test.dart test/daily_choice_recipe_library_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_daily_choice test`閿涘牓鈧俺绻冮敍娑楃矝閺堝鍙忔禒鎾存￥閸?`info`閿涘奔绗夐弰顖涙拱鏉烆喖绱╅崗銉礆
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_eat_library_store_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `flutter test test/daily_choice_recipe_library_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_061-WEAR-2] - 2026-04-25

### 閸樼喎娲?
- 閻劍鍩涚紒褏鐢荤憰浣圭湴娑撴挻鏁炲銉ュ徔缁犳墎鈧粍鐦￠弮銉﹀Ψ閹封斁鈧繀鑵戦惃鍕ㄢ偓婊呪敍娴犫偓娑斿牃鈧繂鐡欏Ο鈥虫健閿涘苯鑻熼幐鍥у毉瑜版挸澧犻弫鐗堝祦闁插繋绮涙稉宥堝喕娴犮儲鏁幘鎴炴纯缂佸棛娈戠粵娑⑩偓澶夌瑢缁狅紕鎮婇棁鈧Ч鍌樷偓?
- 闂団偓鐟曚礁鐔€娴滃孩鏌婃晶鐐垫畱閺堫剙婀寸粚鎸庢儗閸欏倽鈧啳绁弬娆戞埛缂侇厽澧块崗鍛儗闁板秴绨遍妴浣瑰Ω缁屾寧鎯岄幐鍥у础鐠佹彃绶遍弴鏉戠暚閺佽揪绱濋獮璺虹殺娑擃亙姹夌悰锝嗏攳缁狅紕鎮婇崡鍥╅獓娑撳搫鐢張澶愵棑閺嶉棿绗岄弽宄扮础瀵洖顕遍惃鍕閻楀牄鈧?

### 閺傛澘顤?
- 娑?`DailyChoiceOption` 閺傛澘顤冪紒鎾寸€崠?`attributes` 鐎涙顔岄敍宀€鏁ゆ禍搴㈠鏉炵晫鈹涢幖顓犲瀵颁礁鑻熼幐浣风畽閸栨牕鍩?`toolbox_daily_choice_v1.json`閵?
- 閸?`daily_choice_seed_data.dart` 娑擃厽鏌婃晶鐐碘敍娴犫偓娑斿牏娈戠紒鎾寸€崠鏍瀵颁礁鐣炬稊澶涚窗
  - `妞嬪孩鐗竊
  - `閻楀牆鐎穈
  - `閺嶅嘲绱＄猾璇茬€穈
  - `闂堛垺鏋℃稉搴ば曢幇鐒?
  - `娴滎喚鍋
- 閺傛澘顤冨Ο鈥虫健閸栨牜鈹涢幖顓熷瘹閸?`wearGuideModules`閿涘本瀵滄禒銉ょ瑓 8 娑擃亞鐝烽懞鍌滅矋缂佸浄绱?
  - `閸╄櫣顢呮稉搴棑閺嶇钞
  - `閻楀牆鐎锋稉搴㈢槷娓氬獖
  - `閸﹀搫鎮庢稉搴や捍閸︾
  - `閼规彃鍍垫稉搴㈡綏鐠愨暅
  - `鐎涳綀濡稉搴°亯濮樻摽
  - `闂夊楗辨稉搴ㄥ帳妤楃櫗
  - `鐞涳絾鈹嶉弫瀵告倞娑撳海绮屾稊鐕?
  - `閹碘晛鐫嶆潏鍦櫕`
- 閺傛澘顤?`test/daily_choice_wear_seed_test.dart`閿涘矂鐛欑拠渚婄窗
  - 缁屽じ绮堟稊鍫熸蒋閻╊喗鈧鍣烘潏鎯у煂閸欐垵绔风痪褑顩惄?
  - 濮ｅ繋閲?`濮樻梹淇?鑴?閸︾儤娅檂 缂佸嫬鎮庨懛鍐茬毌閺堝琚遍弶鈥斥偓娆撯偓?
  - 濮ｅ繑娼崘鍛枂閹碱參鍘ら柈钘夊徔婢跺洦鐗宠箛鍐波閺嬪嫬瀵查悧鐟扮窙

### 娣囶喗鏁?
- `daily_choice_wear_seed.dart`
  - 鐏忓棛鈹涙禒鈧稊鍫濆敶缂冾喗鎯岄柊宥嗗⒖閸忓懎鍩?`87` 閺?
  - 娑撳搫甯張澶夌瑢閺傛澘顤冮幖顓㈠帳鐞涖儵缍堥懛顏勫З閹恒劍鏌囬惃鍕波閺嬪嫬瀵查悧鐟扮窙
  - 鐏忓棛鈹涢幖顓炲棘閼板啯娼靛┃鎰⒖鐏炴洖鍩岄弴鏉戭樋閺堫剙婀寸挧鍕灐閿涘苯瀵橀幏?`娑撳﹦褰粚澶哥矆娑斿潉閵嗕梗閹碱參鍘ら崗璺虹杽瀵板牆銈介悳?`閵嗕梗妞嬪孩鐗搁惃鍕矊娑旂嚮閵嗕梗缁岃儻銆傞惃鍕唨閺堢悺閵嗕梗缂佸懎锛嬮弮璺虹毣` 缁?
- `daily_choice_editor_sheet.dart`
  - 閼奉亜鐣炬稊澶屸敍閹碱厾绱潏鎴︺€夐弬鏉款杻娴滄梻绮嶅鏇烆嚤瀵?trait 闁瀚?
  - 缁屾寧鎯岀€涙顔岄弬鍥攳閸楀洨楠囨稉鐑樻纯鐠愭潙鎮庣悰锝嗏攳缁狅紕鎮婇惃鍕€冩潏?
  - 娣囨繂鐡ㄩ弮鏈电窗閼奉亜濮╅幎濠勭波閺嬪嫬瀵查悧鐟扮窙楠炶泛鍙嗛弽鍥╊劮娑撳酣绮拋銈堫嚊閹?
- `daily_choice_manager_sheet.dart`
  - 缁屽じ绮堟稊鍫㈩吀閻炲棝銆夐弬鏉款杻 `妞嬪孩鐗?/ 閻楀牆鐎?/ 閺嶅嘲绱＄猾璇茬€穈 娑撳绮嶇粵娑⑩偓?
  - 閼奉亜鐣炬稊澶婃嫲閸愬懐鐤嗛弶锛勬窗閸楋紕澧栭弨閫涜礋閺勫墽銇氱紒鎾寸€崠鏍瀵?chip
  - 鐞涳絾鈹嶇粻锛勬倞閺傚洦顢嶉崡鍥╅獓娑撶儤娲块弰搴ｂ€橀惃鍕嚋娴滈缚銆傚杈嚔娑?
- `daily_choice_detail_sheets.dart` 娑撹櫣鈹涙禒鈧稊鍫ｎ嚊閹懓藟閸忓應鈧粓顥撻弽鑲╂暰閸嶅繆鈧繃膩閸ф绱濈仦鏇犮仛缂佹挻鐎崠鏍瀵颁焦鎲崇憰浣碘偓?
- `daily_choice_wear_module.dart` 閻ㄥ嫭瀵氶崡妤€鍙嗛崣锝嗘暭娑撶儤濯虹挧閿嬫煀閻ㄥ嫭膩閸ф瀵茬粚鎸庢儗閹稿洤宕￠妴?
- `daily_choice_modules.dart` 閸嬫碍娓剁亸蹇撶箑鐟曚胶绱拠鎴滄叏鐞涖儻绱版稉鍝勬倖娴犫偓娑斿牊鏆熼幑顔芥降濠ф劗濮搁幀浣剿夋?`bundle` 閸掑棙鏁敍宀勪缉閸?UI smoke 婢惰精瑙﹂妴?
- `PROJECT_DOMAIN.md` 娑?`modules/toolbox/README.md` 閸氬本顒炵悰銉ュ帠缁屽じ绮堟稊鍫㈡畱缂佹挻鐎崠鏍€傚杈厴閸旀稏鈧?7 閺夆€斥偓娆撯偓澶庮洬閻╂牕鎷扮拠锔剧矎閹稿洤宕＄拠瀛樻閵?

### 妞嬪酣娅撻崣妯绘纯
- 缁屽じ绮堟稊鍫滅矝閹绘劒绶甸惃鍕Ц閸欘垵袙闁插鈧礁褰茬紓鏍帆閻ㄥ嫬缂撶拋顔肩湴閿涘奔绗夐弴澶稿敩娑擃亙缍嬫担鎾瑰窛瀹割喖绱撻妴浣稿煑閺堝秷顩﹀Ч鍌樷偓浣圭€粩顖氥亯濮樻柨鐣ㄩ崗銊ュ灲閺傤厽鍨ㄦ稉鎾茬瑹瑜般垼钖勬い楣冩６閵?
- 缂佹挻鐎崠鏍瀵颁胶娲伴崜宥囨暏娴滃孩婀伴崷鎵摣闁鈧礁鐫嶇粈鍝勬嫲閸氬海鐢婚幍鈺佺潔鏉堝湱鏅敍灞肩瑝娴狅綀銆冨鑼病閹恒儱鍙嗛崶鍓у鐠囧棗鍩嗛妴涓処 鐠囨洜鈹涢幋鏍枠閻椻晛閽╅崣鑸偓?
- 閺堫剝鐤嗛張顏呮暭閸斻劌鍙炬禒鏍ㄧ槨閺冦儲濡烽幏鈺佺摍濡€虫健閻ㄥ嫪绗熼崝锟犫偓鏄忕帆閿涘苯褰ч崑姘啊娑撯偓娑擃亙绗岄崥鍐х矆娑斿牏绱拠鎴︹偓姘崇箖閻╃鍙ч惃鍕付鐏忓繐鍨庨弨顖澦夋鎰┾偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_seed.dart test/daily_choice_wear_seed_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_seed.dart test/daily_choice_wear_seed_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/daily_choice_wear_seed_test.dart --reporter compact`閿涘牓鈧俺绻冮敍瀛塴l tests passed閿?
- `flutter test test/ui_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍瀛塴l tests passed閿?
- `git diff --check -- lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_seed.dart test/daily_choice_wear_seed_test.dart`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_062-GO] - 2026-04-25

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴閸欘亝甯规潻娑樹紣閸忛顔堥垾婊勭槨閺冦儲濡烽幏鈹锯偓婵呰厬閻ㄥ嫧鈧粌鍩岄崫顏勫姽閸樼儵鈧繂鐡欏Ο鈥虫健閿涘苯鑻熺亸鍡楀従娴犲骸宕版担宥囬獓闂呭繑婧€閸︽壆鍋ｉ崡鍥╅獓閸掓澘褰查崣鎴濈閽€钘夋勾閻ㄥ嫪绔撮悧鍫涒偓?
- 瑜版挸澧犻垾婊冨箵閸濐亜鍔归垾婵嗗涧閺堝鐎亸鎴﹀櫤闂堟瑦鈧礁婀撮悙鐧哥礉缂傚搫鐨搾鍐差檮娑撴澘鐦滈惃鍕簚閺咁垰鍨庣猾姹団偓浣告勾閻愮顩惄鏍モ偓浣筋嚊閹懓顕╅弰搴℃嫲閸欘垱瀵旂紒顓熷⒖鐏炴洝绔熼悾灞烩偓?

### 閺傛澘顤?
- 閺傛澘顤?`daily_choice_place_seed.dart`閿涘苯鐨㈤垾婊冨箵閸濐亜鍔归垾婵嗘勾閻愬湱顫掔€涙劒绮犲ú璇插З閺佺増宓佹稉顓犲缁斿濯堕崙鐚寸礉闁灝鍘?`go` 娑?`activity` 缂佈呯敾閼帮箑鎮庨崷銊ユ倱娑撯偓娴?seed 閸愬懌鈧?
- 閺傛澘顤?15 娑擃亖鈧粌骞撻崫顏勫姽閳ユ繂婧€閺咁垰鍨庣猾浼欑窗
  - `妤楊噣顥?/ 婵炲彉绠?/ 鏉╂劕濮?/ 閺傚洤瀵?/ 閸樺棗褰?/ 閼奉亞鍔?/ 鐎涳缚绡?/ 鐠愵厾澧?/ 缁€鍙ユ唉 / 娴滄彃鐡?/ 婢舵粎鏁撳ú?/ 閺€鐐緱 / 閸戣櫣澧?/ 閻楃澹婇崠鍝勭厵 / 缁绢亜搴穈
- 閸╄桨绨?`3 娑擃亣绐涚粋璇茬湴缁?鑴?15 娑擃亜婧€閺?鑴?8 娑?archetype` 閻㈢喐鍨?360 閺夆檧鈧粌骞撻崫顏勫姽閳ユ繂鍞寸純顔兼勾閻愯娼惄顕嗙礉鐟曞棛娲婇敍?
  - 閸忣剙娲妴浣鸿雹闁挶鈧焦绠嶉崷鑸偓浣稿寳閺嬫顒為柆鎾扁偓浣筋潎閺咁垰褰?
  - 娴ｆ捁鍋涙稉顓炵妇閵嗕礁浠撮煬顐ｅ煣閵嗕焦鐖跺▔鎶筋洬閵嗕胶鎮嗘＃鍡愨偓浣规敘瀹€鈺咁洬
  - 妞佹劙顩妴浣告寘閸燂紕鏁庨崫浣哥暗閵嗕礁鐨崥鍐敎閵嗕礁顧佺€归潧灏妴浣规珯鐟欏倿顦甸崢?
  - 闁版帒鎯傞妴浣虹翱闁板灝鎯傞妴涓﹊vehouse閵嗕甫TV閵嗕胶缍夐崥?/ 閻㈢數鐝垫＃?
  - 閸楁氨澧挎＃鍡愨偓浣虹法閺堫垶顩妴浣侯潠閹垛偓妫ｅ棎鈧礁澧介梽顫偓浣告禈娑旓箓顩妴浣峰姛鎼?
  - 閼颁浇顢滈崠鎭掆偓浣稿綔闂€鍥モ偓浣镐紣娑撴岸浠愰崸鈧妴浣洪偗韫囩敻顩妴浣圭墡閸欐煡顩妴浣哥厔鐢倽顔囪箛鍡涱洬缁?
- 閺傛澘顤冪紒鎾寸€崠鏍も偓婊冨毉鐞涘本瀵氶崡妞烩偓婵嚹侀崸妤冪矋閿涘本瀵滈垾婊冨帥鐎规俺瀵栭崶?/ 閹稿婧€閺咁垰灏柊?/ 閸︽澘娴樻稉搴㈩梾缁?/ 婢垛晜鐨垫０鍕暬鐎瑰鍙?/ 閺堚偓鐏忓繐鍣径鍥у瘶 / 閸氬海鐢婚幍鈺佺潔鏉堝湱鏅垾婵嗙潔缁€鎭掆偓?
- 閺傛澘顤?`test/daily_choice_place_seed_test.dart`閿涘矂鐛欑拠浣测偓婊冨箵閸濐亜鍔归垾婵囨蒋閻╊喗鏆熼柌蹇嬧偓浣稿瀻缁槒顩惄鏍モ偓浣告勾閸ョ偓鎮崇槐銏ｇ槤娑撳骸绱╅悽銊ョ摟濞堥潧鐣弫瀛樷偓褋鈧?

### 娣囶喗鏁?
- `daily_choice_seed_data.dart` 娑撹　鈧粌骞撻崫顏勫姽閳ユ繆藟姒?`placeSceneCategories` 娑?`allPlaceSceneCategory`閿涘苯鑻熺亸鍡楀斧閺堫剛鐣濋梽瀣畱閸戦缚顢戦幐鍥у础閸楀洨楠囨稉鐑樐侀崸妤€瀵查幐鍥у础閵?
- `daily_choice_modules.dart` 娑擃厾娈戦垾婊冨箵閸濐亜鍔归垾婵嬨€夐棃銏℃暭娑撶尨绱?
  - 鐠烘繄顬?+ 閸︾儤娅欓崣宀€娣粵娑⑩偓?
  - 瑜版挸澧犵捄婵堫瀲鐏炲倻楠囬崷鎵仯閺?/ 瑜版挸澧犻崐娆撯偓澶嬫殶 / 鐟曞棛娲婇崷鐑樻珯閺佹壆濮搁幀渚€娼伴弶?
  - 閺囧瓨绔婚弲鎵畱缁岃櫣濮搁幀浣告嫲缁夎濮╃粩顖烆浕鐏炲繋淇婇幁?
  - 缁狅紕鎮婃い鍨暜閹镐焦瀵滅捄婵堫瀲閸滃苯婧€閺咁垳鐡柅澶庡殰鐎规矮绠熼崷鎵仯
- `daily_choice_detail_sheets.dart` 鐎靛厜鈧粌骞撻崫顏勫姽閳ユ繆顕涢幆鍛淬€夌悰銉╃秷閸︽澘娴橀幖婊呭偍鐠囧秵褰侀崣鏍偓鏄忕帆閿涘苯顦查崚鑸靛瘻闁筋喕绱崗鍫濐槻閸掑墎绮ㄩ弸鍕閸︽澘娴樺Λ鈧槐銏ｇ槤閿涘矁鈧奔绗夐崘宥嗘簚濮婃澘顦查崚鑸电垼妫版ǜ鈧?
- `daily_choice_activity_place_seed.dart` 缁夊娅庨弮褏娈戦垾婊冨箵閸濐亜鍔归垾婵嗗窗娴ｅ秵鏆熼幑顕嗙礉娴犲懍绻氶悾娆屸偓婊冨叡娴犫偓娑斿牃鈧繄娴夐崗?seed閵?
- `modules/toolbox/README.md` 鐞涖儱鍘栭垾婊冨箵閸濐亜鍔归垾婵嗙摍濡€虫健閻ㄥ嫬寮荤紒瀵哥摣闁鈧?60 閺夆€虫勾閻愮顩惄鏍ф嫲閸︽澘娴橀幍鈺佺潔鏉堝湱鏅拠瀛樻閵?

### 妞嬪酣娅撻崣妯绘纯
- 瑜版挸澧犻垾婊冨箵閸濐亜鍔归垾婵呯矝鐏炵偘绨紒鎾寸€崠鏍ф勾閻愮懓缂撶拋顔荤瑢閹兼粎鍌ㄧ拠宥堢窡閸斺晪绱濇稉宥嗗复閸忋儳婀＄€圭偛鐣炬担宥冣偓浣洪兇缂佺喎婀撮崶鐐鐠у嘲鎷伴崷銊у殠 POI 閸斻劍鈧焦顥呯槐顫偓?
- 閸愬懐鐤嗛崷鎵仯閺佺増宓侀弰顖涘瘻鐢瓕顫嗛崷鐑樺 archetype 閻㈢喐鍨氶惃鍕偓姘辨暏閸婃瑩鈧绱濇稉宥勫敩鐞涖劎婀＄€圭偠鎯€娑撴氨濮搁幀浣碘偓浣哥杽閺冩儼鐦庨崚鍡樺灗鐎圭偞妞傚鈧弨鍙ヤ繆閹垽绱遍崙鍝勫絺閸撳秳绮涢棁鈧惇瀣勾閸ユ儳鎷伴拃銉ょ瑹閺冨爼妫块妴?
- 缁鏆愮€规矮缍呴妴浣哥磻閺€鎯ф勾閻炲棙鏆熼幑顔衡偓浣洪兇缂佺喎婀撮崶鍙ョ瑢鐠侯垳鍤庣憴鍕灊娴犲秳绻氶悾娆庤礋閸氬海鐢婚悪顒傜彌閹碘晛鐫嶉敍灞肩瑝閸︺劍婀版潪顔借穿閸忋儲娼堥梽鎰瑢楠炲啿褰村顔肩磽婢跺嫮鎮婇妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_activity_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart test/daily_choice_place_seed_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_activity_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart test/daily_choice_place_seed_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/daily_choice_place_seed_test.dart --reporter compact`閿涘牓鈧俺绻冮敍瀛塴l tests passed閿?
- `git diff --check -- lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_activity_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart test/daily_choice_place_seed_test.dart plans/PLAN_062_濮ｅ繑妫╅幎澶嬪閸樿鎽㈤崕鍨摍濡€虫健閸欐垵绔风痪褍鐣崰?md`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_062] - 2026-04-25

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴娑撴挻鏁炵€瑰苯鏉?`瀹搞儱鍙跨粻?-> 濮ｅ繑妫╅崘宕囩摜 -> 閸愬磭鐡ラ崝鈺傚` 鐎涙劖膩閸ф绱濋崺杞扮艾閺堫剙婀?`D:\vocabularySleep-resources\閸愬磭鐡 鐠у嫭鏋￠敍灞惧Ω閸樼喎鍘涢惃鍕氦闁插繐宕版担宥堫吀缁犳娅掗崡鍥╅獓娑撳搫褰查崣鎴濈閻ㄥ嫮鎮婇幀褍鍠呯粵鏍窡閸斺晛浼愭担婊冨酱閵?
- 闂団偓鐟曚浇藟姒绘劒绔存總妤€鐤勯悽銊ょ瑬缁夋垵顒熼惃鍕枀缁涙牜鐡ラ悾銉ょ秼缁紮绱濋崥灞炬婢х偛濮炴稉鈧稉顏呭絹閸欐牗鏆ｉ悶鍡楁倵閻ㄥ嫧鈧粎鎮婇幀褍鍠呯粵鏍翱鐟曚焦瀵氶崡妞烩偓婵囧鐠х兘銆夐敍灞借嫙娑撴柧绗夋笟闈涘弳閸忔湹绮獮鎯邦攽瀵偓閸欐垳鑵戦惃鍕槨閺冦儲濡烽幏鈺佺摍濡€虫健閵?

### 閺傛澘顤?
- 閺傛澘顤?`daily_choice_decision_engine.dart`閿?
  - 閹剁晫顬囬崘宕囩摜閸斺晜澧滈惃鍕壋韫囧啳顓哥粻妤€鐪?
  - 閹绘劒绶?`閸у洤瀵戦梾蹇旀簚 / 閸旂姵娼堥崶鐘电 / 閺堢喐婀滈弨鍓佹抄 / 閼辨柨鎮庡鍌滃芳 / 閹懏娅欓崚鍡樼€?/ 閸氬孩鍊叉稉搴㈡簚娴兼碍鍨氶張?/ 鎼存洜鍤庣€瑰牓妫?/ 閺嶁€冲櫙妫板嫭绁碻 閸忣偆琚粵鏍殣
  - 婢х偛濮炵捄銊х摜閻ｃ儱鍙＄拠鍡愨偓浣蜂繆閹垯鐜崐闂翠繆閸欒渹绗岀€瑰牓妫痪鍧楀帳缂?
- 閺傛澘顤?`daily_choice_decision_content.dart`閿?
  - 鐎规矮绠熼崥鍕枀缁涙牜鐡ラ悾銉ф畱鐠囧瓨妲戦妴浣稿彆瀵繋绗屾担璺ㄦ暏鏉堝湱鏅?
  - 婢х偛濮炲Ο鈥虫健閸栨牜娈?`閻炲棙鈧冨枀缁涙牜绨跨憰浣瑰瘹閸楁
  - 閺嶈宓佽ぐ鎾冲閸愬磭鐡ラ幆鍛暔閻㈢喐鍨氶垾婊冨枀缁涙牕宕奸悽鐔割梾閺屻儮鈧繃娼惄?
- 閺傛澘顤冨ù瀣槸 `test/daily_choice_decision_engine_test.dart`閿涘矁顩惄鏍电窗
  - 妤傛﹢顥撻梽鈺呯彯娑撳秶鈥樼€规碍鍎忔晶鍐х瑓閻ㄥ嫭鏌熷▔鏇熷腹閼?
  - 鎼存洜鍤庣€瑰牓妫导妯哄帥娣囨繃濮㈡搴ㄦ珦娑撳妾?
  - 閺嶁€冲櫙妫板嫭绁存导姘Ω娴ｅ孩濡搁幓鈩冪€粩顖氣偓鍏煎閸ョ偛娼庨崐?
  - 娣団剝浼呮禒宄扳偓濂哥彯閺冭泛缂撶拋顔兼閸氬骸鍠呯粵鏍ц嫙娴兼ê鍘涚悰銉や繆閹?
- 閺傛澘顤冪挧鍕灐閺佸鎮婄拋鏉跨秿 `records/record_062_閸愬磭鐡ラ崣鍌濃偓鍐カ閺傛瑦鏆ｉ悶鍡曠瑢娴溠冩惂閺勭姴鐨?md`
- 閺傛澘顤冪拋鈥冲灊閺傚洦銆?`plans/PLAN_062_濮ｅ繑妫╅崘宕囩摜閸愬磭鐡ラ崝鈺傚鐎瑰苯鏉?md`

### 娣囶喗鏁?
- 闁插秴鍟?`daily_choice_decision_assistant.dart`閿涘苯鐨㈤崢鐔告降閻ㄥ嫬宕熸い浣冧氦闁插繑甯撴惔蹇撴珤閸楀洨楠囨稉鍝勭暚閺佹潙浼愭担婊冨酱閿?
  - 閺傛澘顤冮垾婊堫棑闂勨晝楠囬崚?/ 娑撳秶鈥樼€规碍鈧?/ 閸忋劌鐪崣顖氭礀婢跺瓨鈧?/ 閺冨爼妫块崢瀣閳ユ繂鍠呯粵鏍ㄥ剰婢у啫鍨庨崹?
  - 閺傛澘顤冮幒銊ㄥ礃闂€婊冦仈閹绘劗銇氶妴浣规煙濞夋洖鍨忛幑顫瑢闁繑妲戠紒鎾寸亯闂堛垺婢?
  - 閺傛澘顤冪捄銊х摜閻ｃ儱鍙＄拠鍡愨偓浣哥暓闂傘劎鍤庨柅姘崇箖閺佽埇鈧椒淇婇幁顖欑幆閸婂吋褰佺粈?
  - 閹碘晛鍘栧В蹇庨嚋闁銆嶉惃鍕翻閸忋儳娣惔锔胯礋閿涙碍鍨氶崝鐔割洤閻滃洢鈧焦澧界悰灞绢洤閻滃洢鈧焦鏁归惄濞库偓渚€顥撻梽鈹库偓浣瑰閸忋儯鈧礁褰查崶鐐衡偓鈧妴浣瑰Ω閹宦扳偓浣告倵閹柣鈧椒淇婇幁顖氭▕
  - 婢х偛濮為垾婊冨枀缁涙牕宕奸悽鐔割梾閺屻儮鈧繂灏敍灞藉簻閸斺晝鏁ら幋宄版躬閺堚偓缂佸牊濯块弶鍨閸嬫艾浜稿顔荤瑢閸ｎ亜锛愰弽鈩冾劀
- `daily_choice_hub.dart` 閹恒儱鍙嗛弬鎵畱閸愬磭鐡ラ崘鍛啇鐏炲倷绗屽鏇熸惛鐏炲倶鈧?
- `daily_choice_modules.dart` 閸嬫碍娓剁亸蹇撶箑鐟曚胶绱拠鎴滄叏鐞涖儻绱癭閸樿鎽㈤崕绺?鐎涙劖膩閸ф娈戦幐鍥у础閸忋儱褰涙禒搴㈡＋閻?`placeGuideEntries` 鐎靛綊缍堥崚鎵箛閺?`placeGuideModules`閿涘奔绗夐弨鐟板綁閸忔湹绗熼崝陇顕㈡稊澶堚偓?

### 妞嬪酣娅撻崣妯绘纯
- 瑜版挸澧犻崘宕囩摜閸斺晜澧滈幓鎰返閻ㄥ嫭妲搁垾婊呯波閺嬪嫬瀵叉潏鍛И閸愬磭鐡ラ垾婵撶礉娑撳秵妲搁崠鑽ゆ灍閵嗕焦纭跺瀣ㄢ偓浣藉偍閸旓紕鐡戞姗€顥撻梽鈺€绗撴稉姘灲閺傤厾娈戦弴澶稿敩閸濅降鈧?
- 閹懏娅欓崚鍡樼€介妴浣告倵閹梹娼堢悰鈥茬瑢閸旂姵娼堥崶鐘电娓氭繃妫仦鐐扮艾鐟欙綁鍣撮崹瀣侀崹瀣剁礉閺嶇绺炬禒宄扳偓鍏兼Ц鐢喖濮悽銊﹀煕閺勬儳绱￠崠鏍т海鐠佷勘鈧焦甯撴惔蹇撴礈缁辩姴鎷伴弨璺哄經鐞涘苯濮╅敍宀冣偓灞肩瑝閺勵垰鍩楅柅鐘烘珓閸嬪洨娈戠涵顔肩暰閹佲偓?
- 閺堫剝鐤嗗▽鈩冩箒閹恒儱鍙嗛崢鍡楀蕉閸愬磭鐡ラ弮銉ョ箶閿涘苯娲滃銈傗偓婊勭墡閸戝棝顣╁ù瀣р偓婵囨Ц閸╄桨绨ぐ鎾冲闁銆嶉梿鍡楁値閻ㄥ嫬娼庨崐鐓庢礀閹峰绱濇稉宥嗘Ц閸╄桨绨梹鎸庢埂閺嶉攱婀扮拋顓犵矊閸戣櫣娈戦惇鐔风杽閸ョ偛缍婂Ο鈥崇€烽妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_engine.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_content.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_assistant.dart test/daily_choice_decision_engine_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_engine.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_content.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_assistant.dart test/daily_choice_decision_engine_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/daily_choice_decision_engine_test.dart --reporter compact`閿涘牓鈧俺绻冮敍瀛塴l tests passed閿?
- `flutter test test/ui_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍瀛塴l tests passed閿?

## [Unreleased-PLAN_061] - 2026-04-25

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴闁插秶鍋ｇ€瑰苯鏉藉銉ュ徔缁犳墎鈧粍鐦￠弮銉﹀Ψ閹封斁鈧繀鑵戦惃鍕ㄢ偓婊冩倖娴犫偓娑斿牃鈧繂鐡欏Ο鈥虫健閿涘奔绗夐崘宥呬粻閻ｆ瑥婀划鍓х暆缁傝崵鍤庣粔宥呯摍閿涘矁鈧本妲搁幒銉ュ弳 YunYouJun/cook 閺佺増宓侀獮鑸靛Ω闂呭繑婧€閵嗕浇顕涢幆鍛偓浣镐粵閼挎粍瀵氶崡妤€鎷版稉顏冩眽妞嬬喕姘ㄧ粻锛勬倞閸嬫碍鍨氶崣顖氱杽闂勫懍濞囬悽銊ф畱娑撯偓閻楀牄鈧?
- 妞ょ敻娼伴棁鈧憰浣告躬缁夎濮╃粩顖欑箽閹镐線顩荤仦蹇旂閺呭府绱濋崥灞炬閺€顖涘瘮閳ユ粎鍋ｉ崙璇插腹閸忓嘲娴橀弽鍥ф倵闂呭繑婧€閺勫墽銇氶懣婊冩惂閵嗕礁浠犲銏犳倵闁夸礁鐣捐ぐ鎾冲缂佹挻鐏夐妴浣哄仯閸戞槒褰嶉崫浣圭叀閻鐣弫缈犵矙缂佸秴鎷伴崚鏈电稊閺傝纭堕垾婵堟畱鐎瑰本鏆ｉ柧鎹愮熅閵?

### 閺傛澘顤?
- 閺傛澘顤?`daily_choice_cook_service.dart`閿?
  - 鏉╂粎顏拠璇插絿 `https://raw.githubusercontent.com/YunYouJun/cook/main/app/data/recipe.csv`
  - 鐟欙絾鐎?CSV 娑撳搫鎮嗘禒鈧稊鍫滅瑩閻劍娼惄?
  - 鐏?cook 閺佺増宓侀崘娆忓弳鎼存梻鏁ら弨顖涘瘮閻╊喖缍嶇紓鎾崇摠
  - 鏉╂粎顏径杈Е閺冩儼鍤滈崝銊ユ礀闁偓閸掓壆绱︾€涙﹫绱濋崘宥呫亼鐠愩儲妞傞崶鐐衡偓鈧崚鏉垮敶缂冾喖鎮嗘禒鈧稊鍫㈩潚鐎?
- 閺傛澘顤冮崥鍐х矆娑斿牊膩閸ф娈戦崢銊ュ徔閸ョ偓鐖ｇ粵娑⑩偓澶涚窗`閸忋劑鍎撮崢銊ュ徔 / 娑撯偓閸欙絽銇囬柨?/ 閻㈢敻銈悡?/ 瀵邦喗灏濋悙?/ 缁岀儤鐨甸悙鎼佹敤 / 閻戙倗顔坄閵?
- 閺傛澘顤冪紒鎾寸€崠鏍も偓婊冧粵閼挎粈绠ｉ崜宥佲偓婵囧瘹閸楁宕辩紒鍕剁礉閹稿鈧粎娲忛悙褰掝棨閺夋劑鈧胶鐡€涙顔岄妴浣割槵閼挎嚎鈧胶浼€閸婃瑨鐨熼崨鐐解偓浣风箽鐎涙ü绗岀€瑰鍙忛妴渚€鏆遍張鐔活潐閸掓巻鈧繂鍙氭稉顏吥侀崸妤€鐫嶇粈楦款嚊缂佸棜顕╅弰搴涒偓?
- 閺傛澘顤冮崥鍐х矆娑斿牐袙閺嬫劕鐪板ù瀣槸 `test/daily_choice_cook_service_test.dart`閿涘矁顩惄?cook CSV 閸掓媽褰嶉崫浣规蒋閻╊喚娈戞鎰唽/閸樸劌鍙块弰鐘茬殸閸滃苯绱╅悽銊ф晸閹存劑鈧?

### 娣囶喗鏁?
- `DailyDecisionToolPage` 娣囶喖顦叉稉顓熸瀮閺嶅洭顣介崪灞藉閺嶅洭顣芥稊杈╃垳閵?
- 閸氬啩绮堟稊鍫熌侀崸妤佹暭娑撶尨绱?
  - 姒涙顓绘担璺ㄦ暏閻滅増婀侀崘鍛枂閼挎粏姘ㄩ崗婊冪俺閿涘苯鎮楅崣鏉挎倱濮?cook 閺佺増宓侀崥搴￠挬濠婃垶娴涢幑?
  - 閹稿顦靛▓闈涙嫲閸樸劌鍙跨粵娑⑩偓澶婄秼閸撳秴鈧瑩鈧绱濋崘宥堢箻閸忋儮鈧粌绱戞慨瀣閺?/ 閸嬫粍顒涢獮鍫曗偓澶夎厬閳ユ繀瀵岄懜鐐插酱
  - 妞ょ敻娼扮仦鏇犮仛瑜版挸澧犻弫鐗堝祦閺夈儲绨悩鑸碘偓浣碘偓浣糕偓娆撯偓澶嬫殶闁插繈鈧礁鎮撳銉︽闂傛潙鎷伴崥灞绢劄婢惰精瑙﹂崶鐐衡偓鈧幓鎰仛
- 閼挎粌鎼х拠锔藉剰瀵懓鐪伴崡鍥╅獓娑撶儤妯夌粈鐚寸窗
  - 缂佹挻鐎崠鏍嚊缂佸棔绮欑紒?
  - 閺囨潙鐣弫瀵告畱妞嬬喐娼楀〒鍛礋
  - 閺囨潙鐣弫瀵告畱閸掓湹缍斿銉╊€?
  - 閸忔娊鏁幓鎰仛
  - cook 閺佺増宓佸┃?/ B 缁旀瑦鏆€缁嬪鐡戦崣鍌濃偓鍐懠閹恒儰绗屾径宥呭煑閹垮秳缍?
- 閼奉亜鐣炬稊澶岊吀閻炲棗宕岀痪褌璐熼幐澶婄秼閸撳秴鍨庣猾璁崇瑢娑撳﹣绗呴弬鍥╃摣闁绱濋柆鍨帳閸忋劑鍣?cook 閺佺増宓侀幒銉ュ弳閸氬海顓搁悶鍡涖€夋潻鍥祰閵?
- 閼奉亜鐣炬稊澶岀椽鏉堟垼銆冮崡鏇㈡嫛鐎电懓鎮嗘禒鈧稊鍫Ｋ夋鎰纯闁倸鎮庢稉顏冩眽妞嬬喕姘ㄩ惃鍕摟濞堢绱版鎰唽閵嗕礁甯归崗鏋偓浣藉綅閸氬秲鈧椒绮欑紒宥冣偓渚€顥ら弶鎰┾偓浣诡劄妤犮們鈧焦濡у褍顦▔銊ユ嫲閺嶅洨顒烽妴?
- `modules/toolbox/README.md` 鐞涖儱鍘栭崥鍐х矆娑斿牏娈戦弫鐗堝祦鐠囪褰囬妴浣虹处鐎涙鐡ラ悾銉ユ嫲閸楀洨楠囬崥搴ｆ畱閼宠棄濮忔潏鍦櫕閵?

### 妞嬪酣娅撻崣妯绘纯
- cook 鐎规ɑ鏌?`recipe.csv` 閸欘亝褰佹笟娑滃綅閸氬秲鈧線顥ら弶鎰┾偓渚€姣︽惔锔衡偓浣圭垼缁涗勘鈧礁浠涘▔鏇炴嫲閸樸劌鍙块敍灞肩瑝閹绘劒绶甸柅鎰摟闁劖顒為崢鐔告瀮閼挎粏姘ㄩ敍娑欐拱妞や絻顕涢幆鍛厬閻ㄥ嫧鈧粌鐣弫纾嬵嚊缂佸棗浠涘▔鏇椻偓婵嗙潣娴滃骸鐔€娴滃骸鍘撻弫鐗堝祦閻ㄥ嫮绮ㄩ弸鍕閹碘晛鍟撻敍灞借嫙娣囨繄鏆€閸樼喎顫愰弶銉︾爱闁剧偓甯撮妴?
- 瑜版挸澧?`PROJECT_DOMAIN.md` 瀹搞儰缍旈弽鎴﹀櫡娴犲秴鐡ㄩ崷銊х椽閻礁绱撶敮闈╃礉閺堫剝鐤嗛張顏呭⒖婢堆冾嚠鐠囥儲鏋冨锝囨畱娣囶喗鏁奸懠鍐ㄦ纯閿涘矂浼╅崗宥嗗Ω娑旇京鐖滈梻顕€顣介崪灞藉閼宠姤鏁奸崝銊﹁穿閸︺劋绔寸挧鏋偓?
- 閼奉亜鐣炬稊澶夐嚋娴滄椽顥ょ拫鍙樼矝娣囨繂鐡ㄩ崷?`toolbox_daily_choice_v1.json`閿涘本娈忔稉宥嗗复閸忋儰瀵岄弫鐗堝祦鎼存挶鈧浇澶勯崣宄版倱濮濄儲鍨ㄧ€电厧鍙嗙€电厧鍤妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_daily_choice_tool.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_cook_service.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart test/daily_choice_cook_service_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_daily_choice_tool.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_cook_service.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart test/daily_choice_cook_service_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/daily_choice_cook_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍瀛塴l tests passed閿?

## [Unreleased-PLAN_061-WEAR] - 2026-04-25

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴閸欘亝甯规潻娑樹紣閸忛顔堥垾婊勭槨閺冦儲濡烽幏鈹锯偓婵呰厬閻ㄥ嫧鈧粎鈹涙禒鈧稊鍫氣偓婵嗙摍濡€虫健閿涘奔绗夎ぐ鍗炴惙閸忔湹绮獮鎯邦攽瀵偓閸欐垳鑵戦惃鍕摍濡€虫健閵?
- 瑜版挸澧犵粚澶哥矆娑斿牅绮涢崑蹇撳窗娴ｅ稄绱濈紓鍝勭毌鐠у嫭鏋￠弫瀵告倞閵嗕礁銇夊鏃堚攳閸斻劑绮拋銈嗗腹閼芥劕鎷扮搾鍐差檮娑撴澘鐦滈惃鍕讲閸欐垵绔风痪褏鈹涢幖顓熸殶閹诡喓鈧?

### 閺傛澘顤?
- 閺傛澘顤?`daily_choice_wear_module.dart`閿涘本鏁归幏銏⑩敍娴犫偓娑斿牏娈戞径鈺傜毜瀵ら缚顔呴妴渚€绮拋銈嗐€傛担宥呮嫲閸︾儤娅欒箛顐ｅ祹闁槒绶妴?
- 閸╄桨绨?`D:\\vocabularySleep-resources\\缁屽じ绮堟稊鍧?娑擃厾娈戦張顒€婀?EPUB 鐠у嫭鏋￠弫瀵告倞閸戣櫣鈹涢幖顓炲斧閸掓瑱绱濋獮鎯八夐崗鍛煂缁屾寧鎯岄幐鍥у础閸楋紕绮嶉妴?
- 閹碘晛鍘栫粚澶哥矆娑斿牏顫掔€涙劖鏆熼幑顕嗙礉鐟曞棛娲婃稉銉ョ槰閸掍即鍙块弳鎴欌偓渚€鈧艾瀚熼崚浼存处婢垛晝娈?50+ 婵傛鐔€绾偓缁屾寧鎯岄弶锛勬窗閵?

### 娣囶喗鏁?
- `DailyChoiceHub` 閹恒儱鍙嗚ぐ鎾冲婢垛晜鐨甸悩鑸碘偓渚婄礉楠炶泛褰ч崥鎴犫敍娴犫偓娑斿牆鐡欏Ο鈥虫健娴肩娀鈧帒銇夊鏃€鏆熼幑顔衡偓?
- 缁屽じ绮堟稊鍫ョ帛鐠併倖鐗撮幑?`AppState.weatherSnapshot` 閻ㄥ嫪缍嬮幇鐔镐刊鎼达箒鍤滈崝銊┾偓澶夎厬瀵ら缚顔呭锝勭秴閿涘苯鎮撻弮鏈电箽閻ｆ瑦澧滈崝銊洬閻╂牔绗岄垾婊勪划婢跺秴銇夊鏃€甯归懡鎰ㄢ偓婵嗗弳閸欙絻鈧?
- 瑜版挸缍嬮崜宥呫亯濮樻柨鐡ㄩ崷銊╂濮樺瓨妞傞敍宀勩€夐棃顫窗缂佹瑥鍤垾婊冨瀼閸掍即娲︽径鈺佹簚閺咁垪鈧繄娈戣箛顐ｅ祹瀵ら缚顔呴敍灞肩稻娑撳秳绱板鍝勫煑閺€鐟板晸閻劍鍩涢崷鐑樻珯闁瀚ㄩ妴?
- 瑜版挻鐓囨稉顏呬刊鎼?+ 閸︾儤娅欑划鍓р€橀弶锛勬窗鏉╁洤鐨弮璁圭礉闂呭繑婧€缂佹挻鐏夋导姘冲殰閸斻劍璐╅崗銉ユ倱濞撯晛瀹崇粙鍐参曟径鍥偓澶涚礉闁灝鍘ら梾蹇旀簚娴ｆ捇鐛欓崓鍨劥閵?
- `daily_choice_seed_data.dart` 閻ㄥ嫮鈹涢幖顓熷瘹閸楁宕岀痪褌璐熼垾婊冪唨绾偓濞嗗彞绱崗鍫涒偓浣告値闊偄鍘涙禍搴㈢ウ鐞涘被鈧礁婧€閺咁垰鍘涚悰灞烩偓浣藉窛閼虫粈绨柌蹇嬧偓浣搞亯濮樻梹鏁圭亸鐐梾閺屻儮鈧繄鐡戦弴鏉戝讲閹笛嗩攽閻ㄥ嫯顫夐崚娆掝嚛閺勫簺鈧?
- `PROJECT_DOMAIN.md` 娑?`modules/toolbox/README.md` 鐞涖儱鍘栫粚澶哥矆娑斿牏娈戠挧鍕灐閺夈儲绨妴浣搞亯濮樻柨缂撶拋顔兼嫲閸欐垵绔锋潏鍦櫕鐠囧瓨妲戦妴?

### 妞嬪酣娅撻崣妯绘纯
- 缁屽じ绮堟稊鍫㈡畱閸愬懐鐤嗛幖顓㈠帳娴犲秴鐫樻禍搴″讲鐟欙綁鍣村楦款唴閿涘奔绗夐弴澶稿敩娑擃亙缍嬫担鎾瑰窛瀹割喖绱撻妴浣峰紬閺?dress code 閹存牗鐎粩顖氥亯濮樻柨鐣ㄩ崗銊ュ灲閺傤厹鈧?
- 瑜版挸澧犳径鈺傜毜瀵ら缚顔呮笟婵婄瀹稿弶婀佹径鈺傜毜閹恒儱褰涙稉搴ょ箮娴肩厧鐣炬担宥忕幢婢垛晜鐨垫稉宥呭讲閻劍妞傛导姘礀闁偓閸掍即绮拋銈嗐€傛担宥呰嫙閸忎浇顔忛悽銊﹀煕閹靛濮╃拫鍐╂殻閵?
- AI 閺佹澘鐡ф禍楦跨槸缁岃￥鈧浇銆傚杈槕閸掝偂绗岀拹顓犲⒖缂冩垹鐝幒銉ュ弳娴犲秴褰ф穱婵堟殌閹碘晛鐫嶆潏鍦櫕閿涘奔绗夐崷銊︽拱鏉烆喖鐤勯悳鑸偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_seed.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_daily_choice_tool.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/ui_smoke_test.dart --reporter compact`閿涘牓鈧俺绻冮敍瀛塴l tests passed閿?

## [Unreleased-PLAN_060] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴娑撴挻鏁炲銉ュ徔缁犳墎鈧粍鐦￠弮銉﹀Ψ閹封斁鈧繃膩閸ф绱濈亸鍡楃秼閸撳秴宕版担宥呯摍濡€虫健閹碘晛鐫嶆稉琛♀偓婊冩倖娴犫偓娑斿牄鈧胶鈹涙禒鈧稊鍫涒偓浣稿箵閸濐亜鍔归妴浣稿叡娴犫偓娑斿牄鈧礁鍠呯粵鏍уИ閹靛鈧繀绨叉稉顏勩亣鐎涙劖膩閸фぜ鈧?
- 閺傜増膩閸ф娓剁憰浣盒╅崝銊ь伂妫ｆ牕鐫嗗〒鍛珰閵嗕焦鏁幐渚€娈㈤張娲偓澶嬪閵嗕浇顕涢幆?閹稿洤宕￠妴浣藉殰鐎规矮绠熸晶鐐插灩閺€鐧哥礉楠炴湹璐?cook 閺佺増宓侀妴浣告勾閸ヤ勘鈧竸I 鐠囨洜鈹涢妴浣藉枠閻椻晜甯撮崗銉ユ嫲閺佹澘顒熷鐑樐佹０鍕殌閹碘晛鐫嶆潏鍦櫕閵?

### 閺傛澘顤?
- 濮ｅ繑妫╅幎澶嬪閺傛澘顤冩禍鏃€膩閸ф鐔€绾偓閻楀牞绱?
  - `閸氬啩绮堟稊鍧? 閹稿妫顓溾偓浣稿磵妞佹劑鈧焦娅勬鎰┾偓浣风瑓閸楀牐灏妴浣割唽婢舵粓娈㈤張楦垮綅閸濅緤绱濈拠锔藉剰閺勫墽銇氶弶鎰灐閵嗕椒绮欑紒宥冣偓浣虹暆閸栨牕鍩楁担婊勵劄妤犮倕鎷伴弶銉︾爱閵?
  - `缁屽じ绮堟稊鍧? 閹稿寮楃€垫帇鈧礁鐦ㄩ崘鏋偓浣稿櫝閻栧鈧焦淇崪灞烩偓浣镐簳閻戭厹鈧胶鍊ら悜顓溾偓渚€鍙块弳鎴滅瑢闁艾瀚熼妴浣规）鐢悶鈧焦顒滃蹇嬧偓浣哄娴兼哎鈧浇绻嶉崝銊ｂ偓渚€娲︽径鈺佹簚閺咁垶娈㈤張鐑樻儗闁板秲鈧?
  - `閸樿鎽㈤崕绺? 閹稿鍤梻銊ｂ偓浣告噯鏉堝箍鈧浇绻欑悰宀勬閺堝搫鐖剁憴浣烘窗閻ㄥ嫬婀撮敍灞借嫙閸欘垰顦查崚璺烘勾閸ョ偓鎮崇槐銏ｇ槤閵?
  - `楠炶弓绮堟稊鍧? 閹稿绻嶉崝銊ｂ偓浣割劅娑旂姰鈧礁鍤悰灞烩偓浣规殻閻炲棎鈧焦鏂侀弶淇扁偓浣稿灡娴ｆ嚎鈧胶銇炴禍銈夋閺堥缚顢戦崝顭掔礉娑旂喐鏁幐渚€娈㈤張鐑樻煙閸氭垯鈧?
  - `閸愬磭鐡ラ崝鈺傚`: 閹绘劒绶甸崸鍥у瘧闂呭繑婧€閵嗕焦婀￠張娑樺閺夊啨鈧礁娲滅€涙劘鐦庨崚鍡楁嫲閼辨柨鎮庡鍌滃芳閸ユ稓琚柅蹇旀鐠侊紕鐣婚妴?
- 閺傛澘顤?`toolbox_daily_choice/` 鐎涙劗娲拌ぐ鏇礉閹峰棗鍨庡Ο鈥崇€烽妴浣侯潚鐎涙劖鏆熼幑顔衡偓浣规拱閸?JSON 鐎涙ê鍋嶉妴浣稿彙娴滎偆绮嶆禒璺烘嫲妞ょ敻娼扮紓鏍ㄥ笓閵?
- 閺傛澘顤冮張顒€婀撮懛顏勭暰娑斿顓搁悶鍡窗閸欘垶娈ｉ挊蹇撳敶缂冾噣銆嶉敍灞炬煀婢?缂傛牞绶?閸掔娀娅庨懛顏勭暰娑斿褰嶉崫浣碘偓浣规儗闁板秲鈧礁婀撮悙鐟版嫲鐞涘苯濮╅妴?
- 閺傛澘顤冮崥鍐х矆娑斿牄鈧胶鈹涙禒鈧稊鍫涒偓浣稿箵閸濐亜鍔归妴浣稿叡娴犫偓娑斿牆鎷伴崘宕囩摜閸斺晜澧滈惃鍕唨绾偓閹稿洤宕″鐟扮湴閵?

### 娣囶喗鏁?
- `DailyDecisionToolPage` 娴犲孩妫潪顒傛磸閸楃姳缍呴弨閫涜礋娴滄梹膩閸ф鍙嗛崣锝呮嫲缂佺喍绔存潪濠氬櫤闂呭繑婧€娴溿倓绨伴妴?
- `modules/toolbox/README.md` 鐞涖儱鍘栧В蹇旀）閹跺瀚ㄩ弫鐗堝祦閺夈儲绨妴浣哥摠閸屻劏绔熼悾灞烩偓渚€顥撻梽鈺佹嫲閸氬海鐢婚幍鈺佺潔鐠侯垳鍤庨妴?
- `PROJECT_DOMAIN.md` 閺囧瓨鏌婇崚?v0.0.7閿涘矁藟閸忓懏鐦￠弮銉﹀Ψ閹封晙绨插Ο鈥虫健閸╄櫣顢呴悧鍫ｎ嚛閺勫簺鈧?

### 妞嬪酣娅撻崣妯绘纯
- 閸氬啩绮堟稊鍫㈩儑娑撯偓閻楀牆褰ф担璺ㄦ暏閸欏倽鈧?YunYouJun/cook `recipe.csv` 閻ㄥ嫮顬囩痪璺潚鐎涙劕鐡欓梿鍡礉楠炴湹濞囬悽銊︽拱閸︽壆鐣濋崠鏍劄妤犮倧绱濇稉宥呬粵鏉╂粎顏€圭偞妞傞崥灞绢劄閵?
- 閺堫剙婀?`D:\vocabularySleep-resources\缁屽じ绮堟稊鍧?娑?EPUB 娑撳秵鎲宠ぐ鏇炲斧閺傚浄绱辩粚鎸庢儗閺佺増宓佹担璺ㄦ暏闁氨鏁ら崢鐔峰灟閸滃瞼鏁撻幋鎰础缁夊秴鐡欓弫鐗堝祦閵?
- 閼奉亜鐣炬稊澶愩€嶇€涙ê鍋嶉崷銊ョ安閻劍鏁幐浣烘窗瑜?JSON 閺傚洣娆㈡稉顓ㄧ礉閺嗗倷绗夐幒銉ュ弳娑撶粯鏆熼幑顔肩氨閵嗕浇澶勯崣宄版倱濮濄儲鍨ㄦ径鍥﹀敜閹垹顦查妴?
- 閸愬磭鐡ラ崝鈺傚娴犲懐鏁ゆ禍搴ょ窡閸斺晜甯撴惔蹇撴嫲闁繑妲戠拋锛勭暬閿涘奔绗夋担婊€璐熼崠鑽ゆ灍閵嗕焦纭跺瀣ㄢ偓浣藉偍閸旓紕鐡戞姗€顥撻梽鈺佸枀缁涙牔绶烽幑顔衡偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_daily_choice_tool.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_storage.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_daily_choice_tool.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_storage.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?

## [Unreleased-PLAN_059] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴缂佈呯敾鐎瑰本鍨氶崜宥夋桨瀵ら缚顔呮稉顓犳畱閸忔湹绮€圭偟鏁ゆい鐧哥礉鐠佲晝娼惇鐘插И閹靛婀惈鈥冲閵嗕礁顧侀柋鎺嬧偓渚€鍟嬮弶銉ユ嫲鐠恒劌浼愰崗閿嬫杹閺夊彞绠ｉ梻鏉戣埌閹存劖娲跨€瑰本鏆ｉ惃鍕秵闂冭濮忕捄顖氱窞閵?
- 鏉╂瑤绨洪崝鐔诲厴鎼存梻鎴风紒顓濈箽閹镐焦澧滈張铏诡伂閸樺缂夐敍灞肩瑝閹跺﹪顩绘い鐢稿櫢閺傜増濯洪梹鍖＄礉娑旂喍绗夌紒鏇＄箖濡€虫健閸氼垰浠犳潏鍦櫕閵?

### 閺傛澘顤?
- 閻紕婀㈡＃鏍€夐弬鏉款杻閳ユ粎娼崜宥勭闁款喖婧€閺咁垪鈧繄鈥樼拋銈嗗▕鐏炲绱濇稉鈧▎锛勨€樼拋銈呮倵閹垫挸绱戦惈锛勬耿閺嗘澹婂Ο鈥崇础楠炶泛鎯庨崝銊︽付娴ｅ氦鍏橀柌蹇旂ウ缁嬪鈧?
- 閺呫劑妫挎稉澶嬪瘻闁筋喖鎻╃拋鐗堟煀婢х偞甯归弬顓熷絹缁€鐚寸礉閸欘垰鐫嶇粈鐑樻付鏉╂垵顧侀柋鎺曨唶瑜版洏鈧焦娓舵担搴ゅ厴闁插繑绁︾粙瀣嫲閺呮岸妫块惇瀣潌缁捐法鍌ㄩ敍灞借嫙娣囨繄鏆€閳ユ粏藟鐠囷妇绮忛弮銉ョ箶閳ユ繂鍙嗛崣锝冣偓?
- 閸忓秷绶崗銉ユ簚閺咁垰鎯庨崝銊╂桨閺夋寧鏌婃晶鐐差檨闁辨帒鍨庨弨?chip閿涘苯褰查惄瀛樺复鏉╂稑鍙嗛垾婊冪暚閸忋劍绔婚柋鎺嬧偓浣光偓婵堝崕閸嬫粈绗夋稉瀣降閵嗕浇闊╂担鎾炽亰閸忔潙顨愰垾婵堢搼婢舵粓鍟嬮弫鎴炲胶閻樿埖鈧降鈧?
- 閺囨潙顦块崗銉ュ經閹舵ê褰旈崠鐑樻煀婢х偠娉?toolbox 閺€鐐緱閸忋儱褰涢敍姘嚑閸氭瓕顔勭紒鍐︹偓浣藉灊缂傛捇鐓舵稊鎰┾偓浣烘灍閹板牓鐓堕柦闈涙嫲缁傚懏鍓板▽娆戞磸閵?

### 娣囶喗鏁?
- `SleepNightRescuePage` 閺傛澘顤冮崣顖炩偓?`initialMode` 閸欏倹鏆熼敍宀€鏁ゆ禍搴濈矤妫ｆ牠銆夐崚鍡樻暜閻╁瓨甯存潻娑樺弳鐎电懓绨叉径婊堝晪閻樿埖鈧緤绱遍弮銏℃箒閸氼垰濮╅妴浣风箽鐎涙ê鎷扮紒鎾存将闁槒绶稉宥呭綁閵?
- 閻€冲娑撯偓闁款喖婧€閺咁垰褰ч懛顏勫З婢跺嫮鎮婇惈锛勬耿閺嗘澹婃稉搴㈡付娴ｅ氦鍏橀柌蹇旂ウ缁嬪绱濋懗灞炬珯闂婂啿鎷伴崗鏈电铂瀹搞儱鍙挎禒宥囨暠閻劍鍩涙稉璇插З闁瀚ㄩ敍宀勪缉閸忓秴顧侀梻纾嬵嚖閹绢厽鏂侀妴?
- 鐠?toolbox 閸忋儱褰涚紒鐔剁娴ｈ法鏁?`pushModuleRoute` 娑撳海娲伴弽?moduleId閿涘奔绻氶幐浣鼓侀崸妤€鍙ч梻顓熸閻ㄥ嫯顔栭梻顔肩暓閸楊偁鈧?
- `modules/sleep/README.md` 鐞涖儱鍘栭張顒冪枂閻€冲娑撯偓闁款喖婧€閺咁垬鈧焦娅掗梻瀛樺腹閺傤厹鈧礁顧侀柋鎺戝瀻閺€顖氭嫲鐠恒劌浼愰崗鐤粓閸斻劏顕╅弰搴涒偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘稉宥嗘煀婢х偟娼惇鐘冲瘮娑斿懎瀵茬€涙顔岄敍灞肩瑝閺€鐟板綁婢舵粓鍟嬫禍瀣╂閵嗕焦妫╄箛妞剧箽鐎涙ɑ鍨ㄥù浣衡柤閹笛嗩攽閻樿埖鈧焦婧€閵?
- 閻€冲娑撯偓闁款喖婧€閺咁垯绱版稉璇插З閹垫挸绱戦惈锛勬耿閸斺晜澧滈弳妤勫濡€崇础閿涙稖绻栭弰顖涙绾喚鈥樼拋銈呮倵閻ㄥ嫭膩閸ф鍞撮崑蹇撱偨閺囧瓨鏌婇妴?
- 鐠?toolbox 闁剧偓甯撮崣顏呭絹娓氭稑鍙嗛崣锝忕礉娑撳秵甯寸粻鈥冲従娴犳牕浼愰崗椋庢畱閹绢厽鏂侀悩鑸碘偓浣瑰灗閸嬪繐銈介妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart lib/src/ui/pages/sleep_night_rescue_page.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart lib/src/ui/pages/sleep_night_rescue_page.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/sleep_repository_test.dart --reporter compact`閿涘牓鈧俺绻冮敍瀛塴l tests passed閿?
- `git diff --check -- changelogs/CHANGELOG.md lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart lib/src/ui/pages/sleep_night_rescue_page.dart`閿涘牓鈧俺绻冮敍灞肩矌閹绘劗銇?changelog 閸欐婀伴張?Git 閹广垼顢戠拋鍓х枂瑜板崬鎼烽敍?

## [Unreleased-PLAN_058] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涚敮灞炬箿閹稿鍙庢担搴㈠壈韫囨濮忔担鎾荤崣閺傝顢嶇紒褏鐢荤€瑰苯鏉介惈锛勬耿閸斺晜澧滈敍宀勫櫢閻愮袙閸愬磭娼惇鐘辩瑝鐡掔偨鈧胶鍎查煬浣碘偓浣割啇閺勬挷鑵戦弬顓濈瘎閹垱妞傞惃鍕攳閸斻劌濮忔稉宥堝喕閵?
- 妫ｆ牠銆夐棁鈧憰浣稿閸忋儱鍙块張澶愮处閸斾究鈧焦濮庨幈鏉挎嫲閺€顖涘瘮閹呮畱閻╊喗鐖ｉ弬鍥攳閿涘奔绲炬禒宥堫洣娣囨繃瀵旈幍瀣簚缁旑垳鎻ｉ崙鎴礉娑撳秴鍟€閸棝鏆辨い鐢告桨閵?

### 閺傛澘顤?
- 閺傛澘顤?`sleep_low_effort_widgets.dart`閿涘本澹欐潪鐣屾蒋閻娀顩绘い鐢垫畱娴ｅ孩鍓拌箛妤€濮忕紒鍕閿涙碍鏁幐浣光偓褏娲伴弽鍥ㄥ絹缁€鎭掆偓浣烘煂閹偅膩瀵繑濞婄仦澶婃嫲閺呫劑妫挎稉澶嬪瘻闁筋喖鎻╃拋鑸偓?
- 閻紕婀㈡＃鏍€夋稉鏄忓灦閸欑増鏌婃晶鐐┾偓婊€绮栭弲姘辨窗閺嶅洠鈧繃褰佺粈鐑樻蒋閿涘本鏋冨鍫濆繁鐠嬪啩绗夋潻鑺ョ湴鐎瑰瞼绶ㄩ惈锛勬耿閿涘苯褰ч崗鍫濈暚閹存劒绔存稉顏勭毈閸斻劋缍旈敍宀勬娴ｅ氦鍤滅拹锝呮嫲闁瀚ㄧ拹鐔稿閵?
- 閻紕婀㈡＃鏍€夐弬鏉款杻閳ユ粍娲块惌顓犲閺?/ 閹存垹骞囬崷銊ョ发缁鳖垪鈧繂鍙嗛崣锝忕礉閹峰鎹ｉ悿鍙夊劮濡€崇础鎼存洟鍎撮幎钘夌溄閿涘瞼娲块幒銉﹀絹娓氭稖鐨熼弳妤冧紖閸忓鈧焦鏂佹潻婊勫閺堟亽鈧礁浠犻弨鐐韫囧啩绗佸銉礉楠炴湹绻氶悾?8 閸掑棝鎸撳ù浣衡柤閵嗕浇鍎楅弲顖炵叾閸滃苯顧侀柋鎺撴櫝閹绘番鈧?
- 閺冣晜娅掗弮鑸殿唽閺傛澘顤冮垾婊堝晪閺夈儱褰ч悙閫涚娑撳鈧繀绗侀幐澶愭尦韫囶偉顔囬敍灞藉讲閻劉鈧粌妯婃稉宥咁樋 / 閺囨潙妯?/ 閺囨潙銈介垾婵婎唶瑜版洘娅掗梻瀵哥翱缁佺偑鈧胶娅ф径鈺佹炊閸婏箑鎷拌箛鍛邦洣婢跺洦鏁為妴?

### 娣囶喗鏁?
- 鐏忓棙鏁幐浣光偓褎鏋冨鍫熸暪鏉╂稐瀵岄懜鐐插酱閸愬懘鍎撮幓鎰仛閺夆槄绱濋懓灞肩瑝閺勵垶顤傛径鏍ㄦ煀婢х偤鏆遍崡锛勫閿涘苯鍣虹亸鎴炲閺堣櫣顏＃鏍х潌闂€鍨婢х偤鏆遍妴?
- 閸忓秷绶崗銉ユ簚閺咁垰鎯庨崝銊╂桨閺夊灝顤冮崝鐘偓婊勫灉閻滄澘婀鍫㈢柈閳ユ繈鐝导妯哄帥缁狙勫瘻闁筋噯绱濈拋鈺冩煂閹偆鏁ら幋铚傜瑝韫囧懎鍘涢悶鍡毿掗崶娑楅嚋閸︾儤娅欓幐澶愭尦閵?
- 閺呫劑妫胯箛顐ヮ唶婢跺秶鏁?`SleepDailyLog` 閸?`AppState.saveSleepDailyLog`閿涘奔绗夐弬鏉款杻娴犳挸绨辩€涙顔岄幋鏍ㄥ瘮娑斿懎瀵茬紒鎾寸€妴?
- `modules/sleep/README.md` 鐞涖儱鍘栨担搴㈠壈韫囨濮忔担鎾荤崣閵嗕胶鏌岄幆顐Ｄ佸蹇斿▕鐏炲鎷伴弲銊╂？娑撳瀵滈柦顔兼彥鐠佹媽顕╅弰搴涒偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺呫劑妫胯箛顐ヮ唶娴兼碍娲块弬鏉跨秼婢垛晜妫╄箛妤冩畱閺呫劑妫跨划鍓ь殻閸滃瞼娅ф径鈺佹炊閸婏讣绱卞鍙夋箒閻紕婀㈤弮鍫曟毐閵嗕焦妞傞梻纾嬮叡閵嗕胶骞嗘晶鍐ㄦ礈鐎涙劗鐡戠拠锔剧矎鐎涙顔屾导姘箽閻ｆ瑣鈧?
- 閻ゅ弶鍎峰Ο鈥崇础閹惰棄鐪介崣顏勵槻閻劍妫﹂張澶嬬ウ缁嬪鈧胶娅ч崳顏堢叾閸滃苯顧侀柋鎺撴櫝閹绘潙鍙嗛崣锝忕礉娑撳秵鏁奸崣妯兼蒋閸撳秵绁︾粙瀣Ц閹焦婧€閵?
- 閺堫剝鐤嗙紒褏鐢荤亸鍡樻煀娴溿倓绨伴梽鎰煑閸︺劎娼惇鐘插И閹靛顩绘い闈涚潔缁€杞扮瑢鏉炲鍣洪弮銉ョ箶娣囨繂鐡ㄧ仦鍌︾礉娑撳秵鏌婃晶鐐插鞍閻ゆ鍨介弬顓熷灗鐠囧﹥鏌囬幍鑳嚡閵?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/sleep_repository_test.dart --reporter compact`閿涘牓鈧俺绻冮敍瀛塴l tests passed閿?
- `git diff --check -- changelogs/CHANGELOG.md lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart`閿涘牓鈧俺绻冮敍灞肩矌閹绘劗銇?changelog 閸欐婀伴張?Git 閹广垼顢戠拋鍓х枂瑜板崬鎼烽敍?

## [Unreleased-PLAN_057] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閻紕婀㈤崝鈺傚妫ｆ牠銆夋禒宥囧姧閸嬪繘鏆遍敍宀勬付鐟曚礁婀幍瀣簚缁旑垳鏁ら幎妯哄綌閹惰棄鐪介妴浣风瑓閹峰鎷扮€涙劙銆夐棃銏犲竾缂傗晙淇婇幁顖氱槕鎼达负鈧?
- 閻劍鍩涚憰浣圭湴閺傛澘顤冮垾婊咁潠鐎涳妇娼惇鐘偓婵嗙摍濡€虫健閿涘苯寮懓?`D:\vocabularySleep-resources\閻紕婀㈤崣鍌濃偓鍍?娑擃厾娈戠挧鍕灐閿涘本褰侀悙濂哥彯鎼达箑鐤勯悽銊ф畱缁墽鐣濋幍瀣斀閵?
- 閻紕婀㈤弳妤勫濡€崇础娑撳顩绘い鍏哥瑐闁劍褰佺粈鐑樻瀮鐎涙ぞ绮涢崣顖濆厴閸涘牓绮﹂懝璇х礉瑜板崬鎼烽崣顖濐嚢閹佲偓?

### 閺傛澘顤?
- 閺傛澘顤?`SleepSciencePage` 缁夋垵顒熼惈锛勬耿妞ょ绱濇担婊€璐熼惈锛勬耿閸斺晜澧滅€涙劙銆夐棃銏犲弳閸欙絻鈧?
- 缁夋垵顒熼惈锛勬耿妞ゅ灚鏌婃晶鐐扮閸掑棝鎸撻崢鐔峰灟閵嗕線顥撻梽鈺€绱崗鍫涒偓浣烘婢垛晠鏁嬮悙骞库偓浣烘蒋閸撳秵鏁归崣锝冣偓浣割檨闁辨帒顦╅悶鍡愨偓浣规鐠囶垳鏁ょ憴鍕灟閸滃苯寮懓鍐カ閺傛瑧鍌ㄥ鏇礉閸忋劑鍎存担璺ㄦ暏閹舵ê褰旈弽鍥暯缂佸嫮绮愰妴?
- 閻紕婀㈡＃鏍€夐弬鏉款杻閳ユ粌鎻╅柅鐔风暰娴ｅ秮鈧繃濞婄仦澶涚礉閸欘垳娲块幒銉ㄧ儲閸掓澘缍嬮崜宥勫瘜缁捐￥鈧線妫撮悳顖濈熅缁捐￥鈧焦娲挎径姘弳閸欙絻鈧胶娲块幒銉ョ紦鐠侇喓鈧? 婢垛晞绉奸崝鍖＄礉閹存牗澧﹀鈧粔鎴濐劅閻紕婀㈡い鐐光偓?

### 娣囶喗鏁?
- 閻紕婀㈡＃鏍€夋潻娑楃濮濄儱甯囩紓鈺傚閺堣櫣顏梹鍨閿涙氨些闂勩倝鍣告径宥囨畱閳ユ粈缍嗛懗浠嬪櫤韫囶偊鈧喎绱戞慨瀣р偓婵嗙潔瀵偓閸栫尨绱濈亸鍡樻纯婢舵艾鍙嗛崣锝勭瑢閸楄櫕妞傚銉ュ徔閸氬牆鑻熸稉鐑樺閸欑娀娼伴弶瑁も偓?
- 瑜版挸澧犳稉鑽ゅ殠閵嗕胶娼惇鐘绘４閻滎垵鐭剧痪瑁も偓浣规纯婢舵艾鍙嗛崣锝冣偓浣烘纯閹恒儱缂撶拋顔衡偓浣界箮 7 婢垛晞绉奸崝鍨綆閺€閫涜礋閹舵ê褰斿蹇涙桨閺夊尅绱濇＃鏍х潌娣囨繄鏆€娑撳绔村銉ｂ偓浣稿帳鏉堟挸鍙嗛崷鐑樻珯閸氼垰濮╅妴浣瑰瘹閺嶅洣绗岀€规矮缍呴崗銉ュ經閵?
- `sleepModuleTheme` 閺€閫涜礋閺勬儳绱＄憰鍡欐磰 headline/title/body/label 閸忋劑鍎撮弬鍥х摟鐏炲倻楠囬敍灞兼叏婢跺秵娈懝鍙壞佸蹇庣瑓妞ゅ爼鍎撮幓鎰仛閺傚洤鐡ф禒宥呭讲閼充粙绮︾€涙ぞ绗夐崣顖濐潌閻ㄥ嫰妫舵０妯糕偓?
- 閻紕婀㈡＃鏍€夐幍鎾诲妞嬪酣娅撻幓鎰仛閸椻剝鏁兼稉铏瑰缁斿绮嶆禒璁圭礉閸︺劍娈懝韫瘜妫版ê鍞撮柈銊嚢閸?`errorContainer/onErrorContainer` 楠炶埖妯夊蹇氼啎缂冾喗顒滈弬鍥杹閼硅绱濋柆鍨帳濞村懓澹婇懗灞炬珯闁板秵绁懝鍙夋瀮鐎涙ぜ鈧?
- `modules/sleep/README.md` 鐞涖儱鍘栫粔璇插З缁旑垰甯囩紓鈺咁浕妞ら潧鎷扮粔鎴濐劅閻紕婀㈡い浣冨厴閸旀稖顕╅弰搴涒偓?

### 妞嬪酣娅撻崣妯绘纯
- 缁夋垵顒熼惈锛勬耿妞ゅ灚妲搁崑銉ユ倣閺佹瑨鍋涢崪宀冾攽娑撻缚绶熼崝鈺嬬礉娑撳秵娴涙禒锝呭鞍閻ゆ鐦栭弬顓ㄧ幢妞嬪酣娅撴穱鈥冲娇娴犲秴宕熼悪顒佸絹缁€杞扮瑩娑撴俺鐦庢导鑸偓?
- 閺堫剝鐤嗘稉宥嗘暭閻紕婀㈤悩鑸碘偓浣规簚閵嗕椒绮ㄦ惔鎾村瘮娑斿懎瀵茬紒鎾寸€幋鏍ㄧウ缁嬪澧界悰宀冾嚔娑斿鈧?
- `plans/` 娑?`modules/sleep/` 瑜版挸澧犵悮?`.gitignore` 韫囩晫鏆愰敍灞炬拱鏉烆喗鏋冨锝勭矝閹稿銆嶉惄顔款潐閼煎啫婀張顒€婀撮弴瀛樻煀閵?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_science_page.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_science_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/sleep_night_rescue_page.dart lib/src/ui/pages/sleep_day_rhythm_page.dart lib/src/ui/pages/sleep_report_page.dart lib/src/ui/pages/sleep_assessment_page.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `dart analyze lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_science_page.dart`閿涘牐藟閸忓懘鐛欑拠渚€鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/sleep_repository_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_056] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴缂佈呯敾閼辨氨鍔嶅銉ュ徔缁犺京娼惇鐘插И閹靛绱濇穱顔碱槻閻紕婀㈤弳妤勫濡€崇础閺佸牊鐏夐敍灞借嫙闂勫秳缍嗛悿鍙夊劮閻樿埖鈧椒绗呴惃鍕儙閸斻劑妯嗛崝娑栤偓?
- 瑜版挸澧犻惈锛勬耿閸斺晜澧滃鍙夋箒鐠囧嫪鍙婇妴浣规）韫囨ぜ鈧椒绮栭弲姘ウ缁嬪鈧礁顧侀柋鎺撴櫝閹绘番鈧胶娅ф径鈺勫Ν瀵板鎷伴崨銊﹀Г閿涘奔绲炬＃鏍€夋禒宥夋付鐟曚焦娲块弰搴ｂ€橀惃鍕簚閺咁垰瀵查崗銉ュ經閸滃矂妫撮悳顖欒閼辨柣鈧?

### 閺傛澘顤?
- 閻紕婀㈡＃鏍€夐弬鏉款杻閳ユ粌鍘ゆ潏鎾冲弳閸︾儤娅欓崥顖氬З閳ユ繈娼伴弶鍖＄礉閹绘劒绶甸垾婊呭箛閸︺劌姘ㄩ惈掳鈧礁宕愭径婊堝晪娴滃棎鈧焦鏂侀懗灞炬珯闂婄偨鈧焦妲戦弮鈺勊夌拋鎵斥偓婵嗘磽娑擃亙缍嗛幗鈺傛憹閸忋儱褰涢妴?
- 閻紕婀㈡＃鏍€夐弬鏉款杻閳ユ粎娼惇鐘绘４閻滎垵鐭剧痪搴撯偓婵撶礉閹跺﹨鐦庢导鑸偓浣风矕閺呮碍绁︾粙瀣ㄢ偓浣割檨闁辨帗鏅抽幓娣偓浣烘婢垛晞濡瀣ㄢ偓浣规付鐏忓繑妫╄箛妤€鎷伴崨銊﹀Г婢跺秶娲忔稉鍙夊灇閸欘垳鍋ｉ崙鏄忕熅瀵板嫨鈧?

### 娣囶喗鏁?
- 瀵搫瀵?`sleepModuleTheme` 閺嗘澹婃稉濠氼暯閿涘矁顩惄?Scaffold閵嗕竸ppBar閵嗕竼ard閵嗕竼hip閵嗕俯istTile閵嗕浇绶崗銉︻攱閵嗕焦瀵滈柦顔衡偓涓卭ttomSheet閵嗕讣nackBar 閸?TimePicker 缁涘鐖剁憴浣虹矋娴犺翰鈧?
- 鐏忓棛娼惇鐘虫閼硅弓瀵屾０妯诲⒖鐏炴洖鍩岄惈锛勬耿鐠囧嫪鍙婇妴浣割檨闁辨帗鏅抽幓娣偓浣烘婢垛晞濡瀣ㄢ偓浣烘蒋閻姴鎳嗛幎銉ユ嫲濞翠胶鈻肩紓鏍帆閸ｎ煉绱濋獮鎯八夋鎰彥闁喎浼愰崗宄拌剨鐏炲倷绗岄惍鏃傗敀鐠囧瓨妲戝鐟扮湴閻ㄥ嫭娈懝韫瘜妫版ǜ鈧?
- 閻紕婀㈤崶鎹愩€冮崷銊︽閼瑰弶膩瀵繋绗呮导姘絹閸?accent 鐎佃鐦敍灞借嫙閺嶈宓佹禍顔芥閻滎垰顣ㄧ拫鍐╂殻閹舵鍤庨悙鐟板敶闁劑顤侀懝灞傗偓?
- `modules/sleep/README.md` 鐠佹澘缍嶉張顒冪枂閸忓秷绶崗銉ュ弳閸欙絻鈧線妫撮悳顖濈熅缁惧尅绱濇禒銉ュ挤閸氬海鐢婚垾婊堟祩鏉堟挸鍙嗛弲銊╂？鐞涖儴顔囬妴浣烘蒋閸撳秳绔撮柨顔兼簚閺咁垬鈧礁顧侀柋鎺戝瀻閺€顖濆壖閺堫兙鈧浇娉?toolbox 閼辨柨濮╅垾婵堢搼鐎圭偟鏁ら崝鐔诲厴鐠佹崘顓搁妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗗▽鈩冩箒閺傛澘顤冮惈锛勬耿閺佺増宓佸Ο鈥崇€烽敍灞肩瘍濞屸剝婀侀弨鐟板綁 `SleepRepository` 閻ㄥ嫭瀵旀稊鍛缂佹挻鐎妴?
- 閺傛澘婧€閺咁垰鍙嗛崣锝勭矌婢跺秶鏁ら弮銏℃箒鐠侯垳鏁遍妴涔ttom sheet 娑?`startSleepRoutine()`閿涘奔绗夐弨鐟板綁閻€冲濞翠胶鈻奸悩鑸碘偓浣规簚閵?
- `plans/` 娑?`modules/sleep/` 瑜版挸澧犵悮?`.gitignore` 韫囩晫鏆愰敍灞炬拱鏉烆喗鏋冨锝勭矝閹稿銆嶉惄顔款潐閼煎啫婀張顒€婀撮弴瀛樻煀閵?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_chart_widgets.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_assessment_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_day_rhythm_page.dart lib/src/ui/pages/sleep_night_rescue_page.dart lib/src/ui/pages/sleep_report_page.dart lib/src/ui/pages/sleep_routine_editor_page.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_chart_widgets.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_assessment_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_day_rhythm_page.dart lib/src/ui/pages/sleep_night_rescue_page.dart lib/src/ui/pages/sleep_report_page.dart lib/src/ui/pages/sleep_routine_editor_page.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/sleep_repository_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `git diff --check -- changelogs/CHANGELOG.md plans/PLAN_056_閻紕婀㈤崝鈺傚閺嗘澹婂Ο鈥崇础娑撳骸婧€閺咁垶妫撮悳顖滅翱娣?md modules/sleep/README.md lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_chart_widgets.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_assessment_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_day_rhythm_page.dart lib/src/ui/pages/sleep_night_rescue_page.dart lib/src/ui/pages/sleep_report_page.dart lib/src/ui/pages/sleep_routine_editor_page.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart`閿涘牓鈧俺绻冮敍灞肩矌閹绘劗銇?changelog 閸欐婀伴張?Git 閹广垼顢戠拋鍓х枂瑜板崬鎼烽敍?

## [Unreleased-PLAN_055] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯瑜版挸澧犻惈锛勬耿濡€虫健娴犲秳绶风挧鏍с亣闁插繋姹夊銉ㄧ翻閸忋儻绱濋悿鍙夊劮閻樿埖鈧椒绗呴崥顖氬З闂冭濮忔妯糕偓?
- 濡€虫健閸愬懏绁︾粙瀣╄閼辨柧绗夌搾绛圭礉娴犲﹥娅勫ù浣衡柤闁鑵戝Ο鈩冩緲閸氬海宸辩亸鎴濆讲閸曢箖鈧鈧礁褰茬涵顔款吇閻ㄥ嫯绻樻稉鈧銉ゆ唉娴滄帇鈧?
- 闂団偓鐟曚礁顤冮崝鐘衬侀崸妤€鍞撮惈锛勬耿閺嗘澹婂Ο鈥崇础閿涘苯鑻熸导妯哄帥婢跺秶鏁ら悳鐗堟箒缁崵绮洪柅姘辩叀/闂傚綊鎸撻懕鏂垮З閼宠棄濮忛妴?

### 閺傛澘顤?
- 鏉╃偟鐢婚惈锛勬耿閺冦儱绻旀い鍨煀婢х偐鈧?0 缁夋帗娓剁亸蹇旀）韫囨せ鈧繈顣╃拋鎾呯礉閸欘垯绔撮柨顔硷綖閸忋儱鐖剁憴浣烘蒋閻姵妞傞梹瑁も偓浣稿弳閻剝缍旀导蹇旀埂閵嗕礁顧侀柋鎺嬧偓浣虹翱缁?閸ユ澘鈧箑鎷伴崢瀣鐠愮喕宓庨妴?
- 閺冦儱绻旀い鍨殶閸婄厧鐡у▓鍨煀婢х偛鐖剁憴渚€鈧銆?chips閿涘苯顦▔銊︽煀婢х偛鐖剁憴浣圭垼缁涙拝绱濇穱婵堟殌閼奉亜鐣炬稊澶庣翻閸忋儯鈧?
- 娴犲﹥娅勫ù浣衡柤妞ゅ灚鏌婃晶鐐搭劄妤犮倖绔婚崡鏇礉瑜版挸澧犲銉╊€冮崟楣冣偓澶婃倵娴兼氨娲块幒銉﹀腹鏉╂稑鍩屾稉瀣╃濮濄儯鈧?
- 閻紕婀㈡＃鏍€夐弬鏉款杻閳ユ粎娼惇鐘虫閼瑰弶膩瀵繆鈧繂绱戦崗绛圭礉楠炶泛婀惈锛勬耿妫ｆ牠銆夐妴浣界箾缂侇厽妫╄箛妞尖偓浣风矕閺呮碍绁︾粙瀣敶鐏炩偓闁劌绨查悽銊︽閼硅弓瀵屾０妯糕偓?
- 娴犲﹥娅勫ù浣衡柤妞ゅ灚鏌婃晶鐐垫蒋閸撳秵褰侀柋鎺戞嫲鐠у嘲绨ラ梻褰掓寭閸忋儱褰涢敍灞筋槻閻劎骞囬張澶婄窡閸旂偞褰侀柋鎺嶇瑢缁崵绮洪弮銉ュ坊/闂傚綊鎸撶€涙顔岄妴?

### 娣囶喗鏁?
- `SleepDashboardState` 婢х偛濮?`sleepDarkModeEnabled` 閹镐椒绠欓崠鏍х摟濞堢绱濋弮褎鏆熼幑顕€绮拋銈呭彠闂傤厹鈧?
- 閻紕婀㈡禒鎾崇氨濞村鐦晶鐐插 dashboard 閺嗘澹婂Ο鈥崇础閹镐椒绠欓崠鏍ㄦ焽鐟封偓閵?

### 妞嬪酣娅撻崣妯绘纯
- 韫囶偊鈧喎锝為崗鍛涧閸︺劎鏁ら幋椋庡仯閸戝顣╃拋鐐灗 chips 閺冨墎鏁撻弫鍫礉娑撳秷鍤滈崝銊洬閻╂牞绶崗銉ｂ偓?
- 濮濄儵顎冨〒鍛礋閸欘亜顦查悽銊︽＆閺?`advanceSleepRoutine()` 閹恒劏绻樿ぐ鎾冲濮濄儵顎冮敍灞肩瑝閺傛澘顤冮悪顒傜彌濞翠胶鈻奸悩鑸碘偓浣规簚閵?
- 缁崵绮洪幓鎰板晪閼辨柨濮╂笟婵婄閺冦垺婀佸鍛閹绘劙鍟嬮崪灞介挬閸欐媽鍏橀崝娑崇礉娑撳秵鏌婃晶鐐存煀閻ㄥ嫬閽╅崣鐗堝絻娴犺翰鈧?

### 妤犲矁鐦?
- `dart format lib/src/models/sleep_plan.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_wind_down_page.dart test/sleep_repository_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/models/sleep_plan.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_wind_down_page.dart test/sleep_repository_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/sleep_repository_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_054] - 2026-04-24

### 閸樼喎娲?
- 鏉╂稑鍙嗛惈锛勬耿鏉╃偟鐢婚弮銉ョ箶妞ゅ灚妞傞敍瀹峉leepDailyLogPage.initState()` 閸氬本顒炵拫鍐暏 `_loadDate()`閿涘矁鈧?`_loadDate()` 娴兼碍娲块弬?`AppState.sleepDashboardState` 楠炴儼袝閸?provider 闁氨鐓￠妴?
- Riverpod 娑撳秴鍘戠拋绋挎躬 widget tree 閺嬪嫬缂?閹稿倽娴囬張鐔兼？娣囶喗鏁?provider閿涘苯娲滃銈嗗Г闁?閳ユ翻ried to modify a provider while the widget tree was building閳ユ縿鈧?

### 娣囶喖顦?
- 鐏忓棛娼惇鐘虫）韫囨銆夐惃鍕）閺堢喎鐡у▓闈涘鏉炴垝绗?dashboard 闁鑵戦弮銉︽埂閸氬本顒為幏鍡楃磻閵?
- 閸掓繂顫愰崠鏍ㄦ閸忓牆濮炴潪浠嬨€夐棃銏℃拱閸︽媽銆冮崡鏇炵摟濞堢绱濇＃鏍ф姎缂佹挻娼崥搴″晙閸氬本顒?`selectedLogDateKey`閵?
- 閻劍鍩涢柅姘崇箖閺冦儲婀￠柅澶嬪閸ｃ劌鍨忛幑銏℃）韫囨妫╅張鐔告娴犲秳绻氶幐浣稿祮閺冭泛鎮撳?dashboard 閻樿埖鈧降鈧?

### 妞嬪酣娅撻崣妯绘纯
- 妫ｆ牕鎶氶張鐔兼？ dashboard 閻ㄥ嫰鈧鑵戦弮銉︽埂閸欘垵鍏橀惌顓熸畯娣囨繃瀵旈弮褍鈧》绱濇担鍡涖€夐棃銏℃拱閸︾増妫╅張鐔锋嫲鐞涖劌宕熺€涙顔岀粩瀣祮閸欘垳鏁ら敍娑㈩浕鐢冩倵娴兼俺藟姒绘劕鎮撳銉ｂ偓?
- 閺堫剝鐤嗛崣顏囩殶閺佸娼惇鐘虫）韫囨銆夐崚婵嗩潗閸栨牠鈧氨鐓￠弮鑸垫簚閿涘奔绗夐弨鐟板綁閺冦儱绻旀穱婵嗙摠閵嗕礁鐡у▓闈涙儓娑斿鈧椒绮ㄦ惔鎾村瘮娑斿懎瀵查幋鏍浕妞ゅ灚甯归懡鎰扳偓鏄忕帆閵?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/sleep_daily_log_page.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/sleep_daily_log_page.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/sleep_repository_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `git diff --check -- changelogs/CHANGELOG.md lib/src/ui/pages/sleep_daily_log_page.dart`閿涘牓鈧俺绻冮敍灞肩矌閹绘劗銇?changelog 閸欐婀伴張?Git 閹广垼顢戠拋鍓х枂瑜板崬鎼烽敍?

## [Unreleased-PLAN_053] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴缂佈呯敾閹恒劏绻?toolbox 閻紕婀㈤崝鈺傚濡€虫健閿涘苯鐨㈣ぐ鎾冲閸楀﹤鐣幋鎰仛娓氬澧跨仦鏇氳礋鐎瑰本鏆ｉ妴浣哥杽閻劊鈧胶顫栫€涳缚绗栨担搴℃儙閸斻劍鍨氶張顒傛畱閻紕婀㈡潏鍛И闂傤厾骞嗛妴?
- 閺堫剝鐤嗛崣鍌濃偓?`D:\vocabularySleep-resources\閻紕婀㈤崣鍌濃偓鍍?娑擃厾娈?CBT-I閵嗕胶娼惇鐘虫）韫囨ぜ鈧阜90/90 閸掑棝鎸撻崨銊︽埂閵嗕焦娅掗崗澶庡Ν瀵板鈧礁鎸呴崯鈥虫礈閵嗕礁顧侀柋鎺戞嫲閻紕婀㈤崠璇差劅妞嬪酣娅撴潏鍦櫕鐠у嫭鏋￠敍灞界殺閸忔湹楠囬崫浣稿娑撳搫褰查惄瀛樺复閹笛嗩攽閻ㄥ嫬浼愰崗鏋偓?

### 閺傛澘顤?
- 閺傛澘顤冮惈锛勬耿閸斺晜澧滄＃鏍€夐垾婊冪秼閸撳秳绔村銉⑩偓婵呭瘜閼哥偛褰撮敍灞剧壌閹诡喖缍嬮崜宥嗘闂傛番鈧浇鐦庢导鑸偓浣规）韫囨ぜ鈧焦娅掗崗澶堚偓浣告寘閸熲€虫礈閸滃本绁︾粙瀣箥鐞涘瞼濮搁幀浣瑰腹閼芥劖娓堕崐鐓庣繁閸嬫氨娈戞稉鈧銉ｂ偓?
- 閺傛澘顤冮垾婊€缍嗛懗浠嬪櫤韫囶偊鈧喎绱戞慨瀣р偓婵嗕紣閸忓嘲灏敍宀勬肠娑擃厾娼崜宥冣偓浣割檨闁辨帇鈧焦娅掗崗澶堚偓浣告寘閸熲€虫礈閸?90 閸掑棝鎸撻崨銊︽埂閸忋儱褰涢妴?
- 閺傛澘顤?8 閸掑棝鎸撻崘鍛枂 `minimum_energy_shutdown` 閺堚偓娴ｅ氦鍏橀柌蹇曟蒋閸撳秵绁︾粙瀣剁礉楠炶泛婀＃鏍€夋稉鈧柨顕€鈧鑵戦崪灞芥儙閸斻劊鈧?
- 閺傛澘顤?90 閸掑棝鎸撻惈锛勬耿閸涖劍婀＄憴鍕灊閸ｎ煉绱濋弨顖涘瘮閸欏秵甯规禒濠冩珓閸忓磭浼呴弮鍫曟？娑撳簶鈧粎骞囬崷銊ユ皑閻檧鈧繄娈戦崣鍌濃偓鍐晪閺夈儲妞傞梻娣偓?
- 閺傛澘顤冮惈锛勬耿閺冦儱绻?閻紕婀㈤弫鍫㈠芳閵?0 閸掑棝鎸撻崨銊︽埂/R90 娑撱倗琚惍鏃傗敀鐠囧瓨妲戦敍灞借嫙閹恒儱鍙嗛張鈧亸蹇旀）韫囨ぞ绱崗鍫濈紦鐠侇喓鈧?

### 娣囶喗鏁?
- 鐠囪褰囬惈鈥冲濞翠胶鈻煎Ο鈩冩緲閺冩湹绱伴崥鍫濊嫙缂傚搫銇戦惃鍕敶缂冾噣绮拋銈喣侀弶鍖＄礉鐠佲晛鍑￠張澶屾暏閹磋渹绡冮懗鍊熷箯瀵版鏌婃晶鐐存付娴ｅ氦鍏橀柌蹇旂ウ缁嬪鈧?
- 閻€冲濞翠胶鈻兼い闈涱嚠閸愬懐鐤嗗Ο鈩冩緲閸滃本鏌婃晶鐐搭劄妤犮倕顤冮崝鐘虫拱閸︽澘瀵查弰鍓с仛閸氬稄绱濋梽宥勭秵娑擃厽鏋冮悾宀勬桨娑擃厾娈戦懟杈ㄦ瀮濞翠胶鈻奸崥宥嗘瘹闂囧眰鈧?
- 濡€虫健閺傚洦銆傜悰銉ュ帠瑜版挸澧犻惈锛勬耿闂傤厾骞嗛懗钘夊閵嗕礁鐤勯悽銊ㄧ珶閻ｅ苯鎷伴弴瀛樻煀閸樺棗褰堕妴?

### 妞嬪酣娅撻崣妯绘纯
- 閻紕婀㈠楦款唴缂佈呯敾娣囨繃瀵旂悰灞艰礋鏉堝懎濮妴浣筋唶瑜版洖鎷版搴ㄦ珦閹绘劗銇氱€规矮缍呴敍灞肩瑝閺囧じ鍞崠鑽ゆ灍鐠囧﹥鏌囬敍娑欏ⅵ姒т勘鈧焦鍞婚柋鎺戞嫲娑撱儵鍣搁惂钘夈亯閸℃粎娼粵澶夌矝閸欘亝褰佺粈楦跨箻娑撯偓濮濄儴鐦庢导鑸偓?
- 90 閸掑棝鎸撻崨銊︽埂瀹搞儱鍙挎禒鍛稊娑撻缚顫夐崚鎺曠窡閸斺晪绱濋弬鍥攳闁灝鍘ら弳妤冦仛韫囧懘銆忕划鍓р€橀崡锛勫仯閵?
- 閺堫剝鐤嗘径宥囨暏閺冦垺婀?`AppState`閵嗕梗SleepRepository`閵嗕線銆夐棃銏ｇ熅閻㈠崬鎷板Ο鈥虫健瀵偓閸忕绱濇稉宥嗘煀婢х偟瀚粩瀣繁娓氶潧鍙嗗蹇曞Ц閹焦婧€閵?

### 妤犲矁鐦?
- `dart format lib/src/models/sleep_routine_template.dart lib/src/state/app_state_sleep.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_quick_tools_sheets.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart test/sleep_repository_test.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/models/sleep_routine_template.dart lib/src/state/app_state_sleep.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_quick_tools_sheets.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart test/sleep_repository_test.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `flutter test test/sleep_repository_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `git diff --check -- plans/PLAN_053_閻紕婀㈤崝鈺傚鐎圭偟鏁ら梻顓犲箚鐎瑰苯鏉?md modules/sleep/README.md changelogs/CHANGELOG.md lib/src/models/sleep_routine_template.dart lib/src/state/app_state_sleep.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_quick_tools_sheets.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart test/sleep_repository_test.dart`閿涘牓鈧俺绻冮敍灞肩矌閹绘劗銇?changelog 閸欐婀伴張?Git 閹广垼顢戠拋鍓х枂瑜板崬鎼烽敍?

## [Unreleased-PLAN_052] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涚涵顔款吇 `ASR/sherpa-onnx-whisper-small.en.tar.bz2` 缁?ASR 鐠у嫭绨稉宥嗘Ц妞ゅ湱娲拌箛鍛淬€忛崘鍛啇閿涘矁顩﹀Ч鍌涙殻閻?`.gitignore`閿涘本绔婚梽銈勭瑢妞ゅ湱娲版禒锝囩垳閺冪姴鍙ч惃鍕嚒鐠虹喕閲滈弬鍥︽閿涘苯鑻熸穱婵堟殌閺堚偓鐏忓繑褰佹禍銈冣偓?
- GitHub 閹恒劑鈧礁鍑＄悮顐¤⒈娑擃亣绉存潻?100MB 閻?ASR 閸樺缂夐崠鍛珕缂佹繐绱濋棁鈧憰浣风矤閺堫剙婀撮張顏呭腹闁礁宸婚崣韫厬瑜拌绨崇粔濠氭珟閵?

### 娣囶喗鏁?
- 娴?`origin/main..main` 閻ㄥ嫭婀伴崷鐗堟弓閹恒劑鈧礁宸婚崣韫厬缁夊娅?`ASR/` 婢堆勀侀崹瀣竾缂傗晛瀵橀崪?`third_party/flutter_tts/example/` 缁楊兛绗侀弬鍦仛娓氬浼愮粙瀣ㄢ偓?
- 閺囧瓨鏌?`.gitignore`閿涘苯鎷烽悾?ASR 閺堫剙婀寸挧鍕爱閵嗕胶顑囨稉澶嬫煙缁€杞扮伐瀹搞儳鈻奸妴浣哥埗鐟欎焦膩閸ㄥ鏋冩禒璺烘嫲閸樺缂夐崠鍛獓閻椻晪绱濋柆鍨帳閸愬秵顐肩拠顖氬閸忋儳澧楅張顒€绨遍妴?
- 娣囨繄鏆€ `assets/branding/`閵嗕梗assets/en_zh_15000_wordbook.json`閵嗕梗assets/toolbox/` 缁涘銆嶉惄顔跨箥鐞涘矁绁禍褌绗夐崣妯糕偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛柌宥呭晸娴滃棙婀伴崷鏉跨毣閺堫亝甯归柅浣烘畱 45 娑擃亝褰佹禍銈呮惐鐢矉绱辨潻婊咁伂 `origin/main` 閺堫亝鏁奸崘娆欑礉瑜版挸澧?`main` 娴犲秳浜掓潻婊咁伂閸掑棙鏁稉铏诡殯閸忓牄鈧?
- 閺堫剝鐤嗘禒鍛閻炲棝娼箛鍛存付鐠у嫭绨稉搴℃嫹閻ｃ儴顫夐崚娆欑礉娑撳秵鏁奸崝?Flutter 鏉╂劘顢戞禒锝囩垳閸滃本鐭欓惄妯哄閼充粙鈧槒绶妴?

### 妤犲矁鐦?
- `git merge-base --is-ancestor origin/main main`閿涘牓鈧俺绻冮敍?
- `git filter-branch --force --index-filter "git rm -r --cached --ignore-unmatch ASR third_party/flutter_tts/example" --prune-empty --tag-name-filter cat -- origin/main..main`閿涘牓鈧俺绻冮敍?
- `git ls-files ASR third_party/flutter_tts/example`閿涘牓鈧俺绻冮敍灞炬￥鏉堟挸鍤敍?
- `git rev-list --objects main | Select-String -Pattern "sherpa-onnx-whisper|third_party/flutter_tts/example"`閿涘牓鈧俺绻冮敍灞炬￥鏉堟挸鍤敍?

## [Unreleased-PLAN_051] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涚憰浣圭湴鐎瑰本鍨氬▽娆戞磸濡€虫健閺堚偓閸氬簼绔存潪顔芥暪鐏忔拝绱扮亸鍡忊偓婊€绔撮柨顔藉Ы楠炴枼鈧繂濮為崗銉┿€夐棃銏犵俺闁劏褰嶉崡鏇熺埉閿涘苯鑻熼幓鎰唉閹恒劑鈧降鈧?
- 閺€璺虹啲鐎光剝鐗虫稉顓炲絺閻滅増鐭囧ù鍛娔佸蹇斿閸欑姾褰嶉崡鏇氱瘍鎼存棁藟姒绘劕鎮撴稉鈧幙宥勭稊閿涘奔绗栨い鐢告桨娑擃厼鐡ㄩ崷銊ょ缂佸嫭婀担璺ㄦ暏 setter warning閵?

### 娣囶喗鏁?
- 鐏忓棌鈧粈绔撮柨顔藉Ы楠炴枼鈧繂濮為崗銉ョ俺闁劏褰嶉崡鏇熺埉閻ㄥ嫭濮岄崣鐘偓浣烘彛閸戞垵鎷扮敮姝岊潐娑撳顫掕ぐ銏♀偓渚婄礉婢跺秶鏁ら悳鐗堟箒濡亜鎮滃姘З缂佹挻鐎敍灞肩瑝婢х偛濮炴惔鏇㈠劥閺嶅繘鐝惔锔衡偓?
- 鐏忓棛鏁剧敮鍐ㄦ彥閹归攱娼弬鍥攳缂佺喍绔存稉琛♀偓婊€绔撮柨顔藉Ы楠炴枼鈧繐绱濋獮璺侯槻閻?`_canSmoothAll` 缁備胶鏁ら崚銈嗘焽閵?
- 閸︺劍鐭囧ù鍛娔佸蹇斿閸欑姾褰嶉崡鏇氳厬鐞涖儵缍堥垾婊€绔撮柨顔藉Ы楠炴枼鈧繐绱濋柆鍨帳閸忋劌鐫嗛悩鑸碘偓浣风瑓韫囧懘銆忛柅鈧崙鐑樺閼宠棄鐣幋鎰Ы楠炵偨鈧?
- 閹剁懓閽╅幋鎰閸氬骸顤冮崝鐘轰氦闁插繑褰佺粈鐚寸礉閺勫海鈥橀崣宥夘洯缁楁棁袝瀹歌尪顫﹂幎鐟伴挬閵?
- 濞撳懐鎮婂▽娆戞磸妞ょ敻娼版稉顓熸弓娴ｈ法鏁ら惃鍕潌閺?setter閿涘本绉烽梽銈嗙煓閻╂娴夐崗?`unused_element` 閸掑棙鐎界拃锕€鎲￠妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘稉宥嗘暭閸?`_smoothAll()` 閻ㄥ嫭鏆熼幑顔款嚔娑斿绱版禒宥囧姧閸欘亝绔婚梽銈囩應鐟欙箑鑻熸穱婵堟殌閺咁垳鐓堕妴?
- 鎼存洟鍎撮懣婊冨礋閺傛澘顤冮幐澶愭尦娴兼艾顤冮崝鐘趁崥鎴炵泊閸斻劌鍞寸€圭櫢绱濇担鍡欐埛缂侇厼顦查悽?48dp 鐟欙附甯堕幐澶愭尦閸滃瞼骞囬張澶嬬泊閸斻劌顔愰崳銊ｂ偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_zen_sand_tool.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_zen_sand_tool.dart lib/src/ui/pages/toolbox_zen_sand_tool_config.dart lib/src/ui/pages/toolbox_zen_sand_tool_render.dart lib/src/ui/pages/toolbox_zen_sand_tool_state.dart lib/src/ui/pages/toolbox_zen_sand_tool_widgets.dart`閿涘牓鈧俺绻冮敍瀛╫ issues found閿?
- `git diff --check -- lib/src/ui/pages/toolbox_zen_sand_tool.dart changelogs/CHANGELOG.md plans/PLAN_051_閸掓稒鍓板▽娆戞磸鎼存洟鍎撮幎鐟伴挬閸忋儱褰涙稉搴㈡暪鐏忔儳顓搁弽?md`閿涘牓鈧俺绻冮敍?
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_050] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閸掓稒鍓板▽娆戞磸閳ユ粏鍒涢崥鍫Ｐ曢悙鍏夆偓婵嚹佸蹇庣瑓閿涘本澧滈幐鍥曢悙閫涚瑢鐎圭偤妾悽璇插毉閻ㄥ嫭鐭欓惀鏇氱秴缂冾喕绮涢張澶愭晩娴ｅ稄绱濋棁鈧憰浣烘埂鐎圭偠鍒涢崥鍫涒偓?
- 瑜版挸澧犻崗銊ョ潌濞屽韫堝Ο鈥崇础娴犲秳绻氶悾娆撱€婇柈銊﹀瘻闁筋喖鎷版惔鏇㈠劥 dock閿涘本澧滈張鐑樏仦蹇旀閻㈣绔风粚娲？濞屸剝婀佺悮顐㈠帠閸掑棝鍣撮弨淇扁偓?

### 娣囶喗鏁?
- 娣囶喗顒滃▽娆戞磸閻㈣绔烽幍瀣◢閸ф劖鐖ｉ崺鍝勫櫙閿?
  - 閸樼喎鍘涙担璺ㄦ暏婢舵牕鐪扮€圭懓娅掔亸鍝勵嚟鐠侊紕鐣婚拃鐣岀應娴ｅ秶鐤嗛敍灞筋啇閺勬捁顫?padding閵嗕胶鏁剧敮鍐╃垼妫版ɑ娼崪灞芥彥閹归攱鎼锋担婊勬蒋瑜板崬鎼烽妴?
  - 閺€閫涜礋閸︺劎婀＄€圭偟绮崚璺哄隘閸╃喎鍞撮柈銊ф暏 `LayoutBuilder` 閼惧嘲褰囬悽璇茬鐏忓搫顕敍灞借嫙鐏忓棙澧滈崝瑁も偓浣哥秺娑撯偓閸栨牓鈧胶缂夐弨?楠炲磭些閸欏秴褰夐幑銏㈢埠娑撯偓閸掓澘鎮撴稉鈧亸鍝勵嚟閸╁搫鍣妴?
- 闁插秵鐎▽澶嬭箞濡€崇础閿?
  - 濞屽韫堥幀渚€娈ｉ挊蹇曟暰鐢啯鐖ｆ０妯糕偓浣告彥閹?action strip閵嗕礁绨抽柈?dock 閸滃苯鐖舵す缁樺絹缁€鐚寸礉鐠佲晜鐭欓惄妯兼暰鐢啰娲块幒銉╂懙濠娾€崇潌楠炴洏鈧?
  - 娴犲懍绻氶悾娆庣娑?52dp 濞搭喖濮╅懣婊冨礋閹稿鎸抽敍宀冨綅閸楁洑鑵戦幎妯哄綌閹绘劒绶甸柅鈧崙鍝勫弿鐏炲繈鈧礁婧€閺咁垬鈧礁浼愰崗鏋偓渚€顣╃拋淇扁偓浣规寵闁库偓閵嗕線鍣搁崑姘モ偓渚€鍣哥純顔款潒鐟欐帒鎷板〒鍛敄濞屾瑧娲忛妴?
  - 閹靛婧€鐏忓搫顕潻娑樺弳濞屽韫堝Ο鈥崇础閺冭泛鐨剧拠鏇炲瀼閹广垹鍩屽Ο顏勭潌閺傜懓鎮滈敍灞借嫙閸︺劑鈧偓閸戠儤鍨ㄩ柨鈧В渚€銆夐棃銏℃閹垹顦茬化鑽ょ埠 UI 娑撳孩鏌熼崥鎴濅焊婵傚鈧?

### 娣囶喖顦?
- 娣囶喖顦查垾婊嗗垱閸氬牐袝閻愬厜鈧繂绱戦崥顖氭倵娴犲秴娲滄径鏍х湴鐏忓搫顕稉搴ｆ埂鐎圭偟绮崚鍫曟桨娑撳秳绔撮懛鏉戭嚤閼峰娈戦拃鐣岀應閸嬪繒些閵?
- 娣囶喖顦插▽澶嬭箞濡€崇础閹貉傛閸楃姳缍呮潻鍥ь樋閵嗕焦澧滈張鐑樏仦蹇庣瑝婢剁喐鐭囧ù鍝ユ畱闂傤噣顣介妴?

### 妞嬪酣娅撻崣妯绘纯
- 閸ф劖鐖ｉ柧鎹愮熅閸欘亙鎱ㄥ锝囨暰鐢啫鏄傜€靛憡娼靛┃鎰剁礉娑撳秵鏁奸崣妯煎箛閺?viewport 缂傗晜鏂?楠炲磭些閸忣剙绱￠妴?
- 濞屽韫堝Ο鈥崇础娴兼艾婀幍瀣簚鐏忓搫顕稉瀣嚞濮瑰倹铆鐏炲繑鏌熼崥鎴礉闁偓閸戠儤鐭囧ù鍛婂灗缁傝绱戞い鐢告桨閺冭埖浠径宥冣偓?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_zen_sand_tool.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_zen_sand_tool.dart`閿涘牅绮涢張澶嬫＆閺?6 閺?`unused_element` warning閿?
- `git diff --check -- lib/src/ui/pages/toolbox_zen_sand_tool.dart changelogs/CHANGELOG.md`閿涘牓鈧俺绻冮敍?
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_049] - 2026-04-24

### 閸樼喎娲?
- 瑜版挸澧犲▽娆戞磸闂婅櫕鏅ュ鍙夊复鏉╂垹婀＄€圭偞鐭欏▽娆忥紣閿涘奔绲炬禒宥夋付鐟曚浇绻樻稉鈧銉ㄤ氦閺屾柨瀵查敍灞借嫙娑撴棃娓剁憰渚€娈㈠鎴濆З閼哄倸顨旈崣妯哄閿涙艾濮為柅鐔哥拨閸斻劎鏆愭晶鐐插繁閵嗕礁瀵戦柅鐔哥拨閸斻劎菙鐎规哎鈧椒绗夐崝銊︽鎼存梹妫ゆ竟鑸偓?

### 娣囶喗鏁?
- 閸?`toolbox_zen_sand_sound_service.dart` 娑擃參鍣搁崘娆忔儕閻滎垰锛愰柌蹇旀Ё鐏忓嫸绱?
  - `intensity <= 0.01` 閺冩儼绻戦崶?0 闂婃娊鍣洪敍宀€鈥樻穱婵囧瘻娴ｅ繋绗夐崝銊﹀灗閸嬫粈缍囬弮鍓佹埂濮濓綁娼ら棅鐐解偓?
  - 閺佺繝缍嬮崺铏诡攨闂婃娊鍣洪崪灞肩瑐闂勬劒绗呯拫鍐跨礉娴ｆ寧鐭欐竟鐗堟纯鏉炴眹鈧焦娲跨拹纾嬬箮閼冲本娅欑憴锔藉妳閵?
  - 閺傛澘顤冩潻鎰З瀵搫瀹崇拋锛勭暬閿涙碍鐗撮幑顔荤秴缁夋眹鈧焦妞傞梻鎾？闂呮柣鈧礁閽╁鎴︹偓鐔峰閸滃本顒滈崥鎴濆闁喎瀹崇拋锛勭暬 loop intensity閵?
- 閸?`toolbox_zen_sand_tool.dart` 娑擃厽甯撮崗銉ㄧ箥閸斻劏浠堥崝顭掔窗
  - 鐠ч鐟崣顏堫暕閻戭厼鑻熸禒?0 闂婃娊鍣洪崥顖氬З loop閿涘奔绗夐崘宥埿曢幗绋垮祮閸濆秲鈧?
  - 濠婃垵濮╅弴瀛樻煀閺冭埖瀵滈柅鐔峰/閸旂娀鈧喎瀹虫す鍗炲З濞屾瑥锛愬鍝勫閵?
  - 閸嬫粍顒涚粔璇插З缁?`130ms` 閸氬孩璐伴崚?0閿涘瞼鎴风紒顓熺拨閸斻劍妞傝箛顐︹偓鐔镐划婢跺秲鈧?
  - 濮樼鎶楅梹鎸庡瘻閹碘晜鏆庢稉宥呭晙濡剝瀚欏鎴濆З闂婄绱濋柆鍨帳閳ユ粍鐥呴崝銊ょ瘍閺堝锛愰垾婵勨偓?
- 閸︺劍鐭欓惄姗€鐓堕弫鍫熺ゴ鐠囨洑鑵戦弬鏉款杻鏉╂劕濮╅懕鏂垮З閺傤叀鈻堥敍宀冾洬閻╂牠娼ゅ顫礋 0閵嗕礁濮為柅鐔峰繁娴滃骸瀵戦柅鐔粹偓浣稿槻閸婇棿绻氶幐浣戒氦閺屾柣鈧?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛崣顏呮暭閸欐﹢鐓堕弫鍫濆繁鎼达附妲х亸鍕瑢閹靛濞嶆潻鎰З閸掍即鐓堕柌蹇曟畱閼辨柨濮╅敍灞肩瑝閺€鐟板綁缂佹ê鍩楅妴浣芥儰閻偨鈧焦瀵旀稊鍛閹存牞鐭鹃悽杈嚔娑斿鈧?

### 妤犲矁鐦?
- `dart format lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart test/toolbox_zen_sand_sound_service_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart test/toolbox_zen_sand_sound_service_test.dart`閿涘牅绮涢張?`toolbox_zen_sand_tool.dart` 閺冦垺婀?6 閺?unused_element warning閿?

## [Unreleased-PLAN_048] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涙潻娑楃濮濄儲妲戠涵顕嗙窗閸掓稒鍓板▽娆戞磸闂婅櫕鏅ラ弽绋跨妇鎼存梹膩閹风喐澧滈幐鍥ф躬濞屾瑩娼板鎴濆З閺冭埖鐭欓惍鎯у絺閸戣櫣娈戠紒鍡楃槕閳ユ粍鍊濆▽娆忥紣閳ユ繐绱濋悽銊ょ艾鐟欙絽甯囬弨鐐緱閿涘矁鈧奔绗夐弰顖涚【閻ц棄娅旀竟鐗堝灗閻㈤潧鐡欓崳顏堢叾閵?
- 閸欏倽鈧啰缍夋い?`https://www.ppbzy.com/tools/zen/` 閻ㄥ嫭鐭欓惄妯虹杽閻滀即鍣伴悽銊ラ挬濠婃垿娈㈤張鍝勬珨婢硅埇鈧胶瀹?800Hz 娑擃參顣剁敮锕傗偓姘嫲閹锋牕濮╅柅鐔峰閹貉冨煑闂婃娊鍣洪惃鍕偓婵婄熅閿涘本鏌熼崥鎴炴纯閹恒儴绻庨惇鐔风杽閻倿娼伴幗鈺傛憹閵?

### 娣囶喗鏁?
- 闁插秴鍟?`toolbox_zen_sand_sound_service.dart` 閻ㄥ嫮骞囨禒锝呮儕閻滎垰绨抽崳顏嗘晸閹存劕娅掗敍?
  - 閸樺娅庡锝呴浮 partial 閸棗褰旈敍宀勪缉閸忓秴鎯夐幇鐔峰毉閻滄澘娴愮€规岸鐓舵妯诲灗閻㈤潧鐡欑拫鍐ㄥ煑閹扮喆鈧?
  - 閺€閫涜礋绾喖鐣鹃幀褎婀侀懝鏌ヮ暭缁帒娅旀竟甯窗娑擃參顣堕幗鈺傛憹鐢箒绀嬬拹锝傗偓婊勫€濆▽娆屸偓婵撶礉缂佸棛鐭戦懘澶婂暱鐠愮喕鐭楅惍鍌滅煈閹扮噦绱濋幈銏犲竾閸旀稒绱撶粔鏄忕鐠愶綁娈㈤幍瀣瘹缁夎濮╅惃鍕殰閻掓儼鎹ｆ导蹇嬧偓?
  - 娑撶儤婀懓娆嶁偓浣瑰瘹鐏忔牓鈧焦鎸夋潻骞库偓浣圭煓闁惧眰鈧焦鐭欓惍淇扁偓浣瑰楠炲厖绻氶悾娆庣瑝閸氬本娼楃拹銊ュ棘閺佸府绱濇担鍡欑埠娑撯偓閺€璺哄經閸掓壋鈧粏鍒涢惈鈧▽娆撴桨鏉炴槒浜ゅ鎴濆З閳ユ繄娈戞竟浼寸叾閺傜懓鎮滈妴?
  - 鐎电懓鎯婇悳顖烆浕鐏忔儳浠涢惌顓＄€洪崥鍫礉楠炶埖瀵滈惄顔界垼瀹勬澘鈧厧缍婃稉鈧崠鏍电礉闂勫秳缍嗛幏鍏煎复閻愮懓鍤竟鏉挎嫲閸掗缚鈧啿鍢查崐绗衡偓?

### 娣囶喖顦?
- 娣囶喖顦叉稉濠佺閻楀牆鎯婇悳顖氱俺閸ｎ亙绮涢崑蹇娾偓婊冩値閹存劕娅旀竟?閻㈤潧鐡欓崳顏勶紣閳ユ繄娈戦崥顒佸妳闂傤噣顣介敍灞煎▏濠婃垵濮╂竟鐗堟纯閹恒儴绻庨惇鐔风杽濞屾瑧鐗奸幗鈺傛憹閵?

### 妞嬪酣娅撻崣妯绘纯
- 闂婂疇澹婃稉鏄忣潎閸氼剚鍔呴崣妯哄鏉堝啯妲戦弰鎾呯礉娴ｅ棔绮庨弨鐟板З鏉╂劘顢戦弮璺烘値閹存劙鐓堕懝璇х礉娑撳秵鏁奸崣妯诲閸旇儻顕㈡稊澶堚偓浣规尡閺€?API閵嗕焦瀵旀稊鍛缂佹挻鐎幋?UI 鐞涘奔璐熼妴?

### 妤犲矁鐦?
- `dart format lib/src/services/toolbox_zen_sand_sound_service.dart test/toolbox_zen_sand_sound_service_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_047] - 2026-04-24

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯閸掓稒鍓板▽娆戞磸濠婃垵濮╅弮鍫曠叾閺佸牆宕辨い澶稿紬闁插稄绱濋崥顒佸妳閸欘亝婀佹稉鈧竟鑸偓浣风瑝閹镐胶鐢婚幘顓熸杹閿涘本婀￠張娑滅箾缂侇厽绮﹂崝銊︽閺堝绗夐崑婊堛€戦妴浣规￥缁岃櫣娅ч惃鍕煓濞屾瑥锛愰妴?
- 閸氬本妞傜憰浣圭湴闂堛垹鎮滈幍瀣簚鐏忓繐鐫嗛柌宥嗘煀娴兼ê瀵叉稉鈧悧?UX/UI閿涘奔绱崗鍫滅箽閻ｆ瑧鏁剧敮鍐敄闂傛番鈧礁缍嬮崜宥囧Ц閹礁鎷版稉缁樻惙娴ｆ粎鍎归崠鎭掆偓?

### 閺傛澘顤?
- 閺傛澘顤?`plans/PLAN_047_閸掓稒鍓板▽娆戞磸鏉╃偟鐢婚棅铏櫏娑撳海些閸斻劎顏琔X娴兼ê瀵?md`閿涘本澹欓幒銉︽拱鏉烆噣鐓堕弫鍫ｇ箾缂侇厽鈧傜瑢缁夎濮╃粩?UX/UI 娴兼ê瀵查妴?
- 閸?`toolbox_zen_sand_sound_service.dart` 娑擃叀藟姒绘劗骞囨禒锝呮儕閻滎垱鐭欏▽娆忥紣 PCM 閻㈢喐鍨氶崳顭掔礉娑撶儤婀懓娆嶁偓浣瑰瘹鐏忔牓鈧焦鎸夋潻骞库偓浣圭煓闁惧眰鈧焦鐭欓惍淇扁偓浣瑰楠炲磭鐡戞潻鐐电敾瀹搞儱鍙块幓鎰返 4.8s 閸涖劍婀℃惔鏇炴珨閵?
- 閸︺劑鐓堕弫鍫濇礀瑜版帗绁寸拠鏇氳厬閺傛澘顤冨顏嗗箚婢圭増妞傞梹瑁も偓浣规付鐏忓繒鐛ラ崣?RMS 閸滃苯濮╅幀浣呵旂€规碍鈧勬焽鐟封偓閿涘矂妲诲銏犳倵缂侇厼鍟€濞嗏€冲毉閻滀即顩荤亸鍓р敄閻ц姤鍨ㄦ稉顓燁唽閹哄鐓堕妴?

### 娣囶喗鏁?
- 鐠嬪啯鏆ｅ顏嗗箚閹绢厽鏂侀崳銊ㄦ崳閹绢厼鍨界€规熬绱伴幘顓熸杹閸ｃ劏绻橀崗?`PlayerState.playing` 閸楀啿褰茬憴鍡曡礋瀹告彃鎯庨崝顭掔礉娑撳秴鍟€瀵桨绶风挧?position 缁斿鍩㈤崜宥堢箻閿涘矂浼╅崗宥夊劥閸掑棗閽╅崣?position 閸ョ偞濮ら幈銏℃鐞氼偉顕ら崚銈呫亼鐠愩儱鑻熼崣宥咁槻闁插秴鎯庨妴?
- 鐏忓棗鎯婇悳?source ready 缁涘绶熸禒搴ㄦ毐鐡掑懏妞傞弨鑸垫殐娑?`420ms` 閻厾鐡戝鍜冪幢濠ф劘顔曠純顔肩暚閹存劕鎮楁导妯哄帥韫囶偊鈧喎鐨剧拠?`resume()`閿涘苯鍣虹亸鎴︻浕濞嗏剝绮﹂崝銊р敄閻у鈧?
- 鏉╃偟鐢婚崹瀣紣閸忛鎴风紒顓㈠櫚閻?loop 娑撹顕辩粵鏍殣閿涘苯鍣虹亸鎴炵拨閸斻劏绻冪粙瀣╄厬閻厺绺?impact 閸欏秴顦查崚鍥ㄧ爱闁姵鍨氶惃鍕幢妞ゆ寧鍔呴妴?
- 缁愬嫬鐫嗘稉瀣竾缂傗晠銆婇柈銊︾垼妫版ê灏敍姘箽閻ｆ瑨绻戦崶鐐偓浣圭垼妫版ǜ鈧礁婧€閺咁垰鎷板銉ュ徔閸忋儱褰涢敍宀冾嚛閺勫孩鏋冨鍫熸暪閺佹稐璐熸稉鈧悰宀嬬礉閸戝繐鐨＃鏍х潌妤傛ê瀹抽崡鐘垫暏閵?
- 缁愬嫬鐫嗛悩鑸碘偓浣稿隘閻㈣鲸铆閸氭垶绮撮崝?badge 閺€閫涜礋閸欘垱宕茬悰宀€鐓?pill閿涘奔绱崗鍫濈潔缁€鍝勬簚閺咁垬鈧礁浼愰崗鏋偓渚€鐓堕弫鍫濇嫲缁楁棁袝閿涘矂浼╅崗?375dp 閹靛婧€娑撳﹥铆閸氭垶绮﹂崝銊ｂ偓?
- 鎼存洟鍎?Dock 閹稿鎸虫晶鐐插閺堚偓鐏?`48dp` 鐟欙附甯剁痪锔芥将閿涘苯鑻熼梽鎰煑閹稿鎸抽弬鍥ㄦ拱閸楁洝顢戦惇浣烘殣閿涘本褰侀崡鍥ㄥ閺堣櫣顏粙鍐茬暰閹佲偓?

### 娣囶喖顦?
- 娣囶喖顦茶ぐ鎾冲娴狅絿鐖滄稉?`_tryBuildModernZenSandLoopPcm(...)` 鐞氼偉鐨熼悽銊ょ稻閺堫亜鐣炬稊澶婎嚤閼锋潙鍨庨弸鎰亼鐠愩儳娈戠紓鍝勫經閵?
- 娣囶喖顦插鎴濆З闂婅櫕鏅ラ崣顖濆厴閸ョ姵鎸遍弨鎹愮箻鎼达箑娲栭幎銉﹀弮閼板矁绻橀崗銉⑩偓婊冩儙閸?鐠囶垰鍨芥径杈Е-閸愬秵顐奸崥顖氬З閳ユ繄娈戝顏嗗箚閿涘矂妾锋担搴″涧閺堝顩绘竟鑸偓浣告倵缂侇厼褰傜粚铏规畱濮掑倻宸奸妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛棅铏櫏閺€鐟板З闂嗗棔鑵戦崷銊ユ値閹存劕鎯婇悳顖氾紣娑撳孩鎸遍弨鎯ф珤閸氼垰濮╅崚銈呯暰閿涘奔绗夐弨鐟板綁瀹搞儱鍙跨拠顓濈疅閵嗕焦澧滈崝鑳嚔娑斿鈧焦瀵旀稊鍛缂佹挻鐎崪宀冪熅閻㈣精顢戞稉鎭掆偓?
- 鐏忓繐鐫?UI 鐠嬪啯鏆ｆ禒鍛暭閸欐ê鐫嶇粈鍝勭槕鎼达缚绗岄幒褌娆㈢敮鍐ㄧ湰閿涘矁绶熼崝鈺勵啎缂冾喕绮涢柅姘崇箖閸︾儤娅?瀹搞儱鍙挎稉搴㈠付閸掑爼娼伴弶鑳箻閸忋儯鈧?

### 妤犲矁鐦?
- `dart format lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart lib/src/ui/pages/toolbox_zen_sand_tool_widgets.dart test/toolbox_zen_sand_sound_service_test.dart`
- `dart analyze lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart lib/src/ui/pages/toolbox_zen_sand_tool_widgets.dart test/toolbox_zen_sand_sound_service_test.dart`閿涘牅绮涢張?`toolbox_zen_sand_tool.dart` 閺冦垺婀?6 閺?unused_element warning閿?
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_046] - 2026-04-23

- Follow-up: hardened the Zen Sand loop startup path so it now waits for the loop source to become ready before `resume()`, tracks in-flight startup state, and retries once if playback position does not advance after resume.
- Follow-up: switched the Zen Sand sustained loop from in-memory `BytesSource` playback to cached temp-file `DeviceFileSource` playback, matching the project's already-stable loop controller path on device.
- Follow-up verification: `dart analyze lib/src/services/toolbox_zen_sand_sound_service.dart` returned `No issues found`.

### 閸樼喎娲?
- 閻劍鍩涢崣宥夘洯缁傚懏鍓板▽娆戞磸瑜版挸澧犻棅铏櫏閸︺劏鎹ｉ幘顓炴嫲閸嬫粌鎮楅崘宥嗘尡閺冭泛鐡ㄩ崷銊︽閺勫墽鈹栭惂鎴掔瑢瀵ゆ儼绻滈敍灞芥儔閹扮喎鍎氶垾婊冨帥閸戣桨绔存竟甯礉闂呭繐鎮楅崣鎴犫敄閳ユ繐绱濋棁鈧憰浣衡€樼拋銈夋６妫版ɑ娼甸懛顏堢叾妫版垶婀版担鎾圭箷閺勵垱鎸遍弨楣冩懠鐠侯垬鈧?
- 缂佸繋鍞惍浣瑰笓閺屻儻绱濈粋鍛壈濞屾瑧娲忛棅铏櫏楠炲爼娼棃娆愨偓?`assets` 閺傚洣娆㈤敍宀冣偓灞炬Ц `toolbox_zen_sand_sound_service.dart` 鏉╂劘顢戦弮璺烘値閹存劗娈?WAV閿涙稑娲滃銈夋付鐟曚礁鎮撻弮鑸殿梾閺屻儱鎮庨幋鎰皾瑜邦澀绗岄幘顓熸杹閸ｃ劌鍨忓┃?妫板嫮鍎圭粵鏍殣閵?

### 娣囶喗鏁?
- 閸?`toolbox_zen_sand_sound_service.dart` 娑擃厽鏌婃晶?`prewarm(...)` 妫板嫮鍎归崗銉ュ經閿?
  - 瑜版挸澧犲銉ュ徔閸掑洦宕查妴浣虹應鐟欙箑銇囩亸蹇撳綁閸栨牓鈧礁浜告總鑺ヤ划婢跺秲鈧線鐓堕弫鍫ュ櫢閺傛澘绱戦崥顖氭倵閿涘奔绱伴幓鎰閸戝棗顦顏嗗箚鎼存洖娅?source閿涘苯鍣虹亸鎴︻浕濞?`setSource` 閻ㄥ嫮鐡戝鍛敄閻у鈧?
  - 閸氬本妞傛０鍕劰瑜版挸澧犲銉ュ徔妫ｆ牔閲滅敮鍝ユ暏閸戣褰傞棅?source閿涘苯鑻熼幎?impact player 濞撳憡鐖ｉ柌宥囩枂閸掓澘鍑℃０鍕劰閹绢厽鏂侀崳顭掔礉闂勫秳缍嗘＃鏍ф惙瀵ゆ儼绻滈妴?
- 娴兼ê瀵?impact 閹绢厽鏂侀柧鎹愮熅閿?
  - 娑?3 娑?impact player 婢х偛濮炲鎻掑鏉?`cacheKey` 鐠虹喕閲滈妴?
  - 瑜版挸鎮撻崣鍌涙殶閸戣褰傞棅鍐插晙濞喡ば曢崣鎴炴閿涘奔绱崗?`seek(Duration.zero) + resume()` 婢跺秶鏁ゅ鎻掑鏉?source閿涘矁鈧奔绗夐弰顖涚槨濞嗭繝鍣搁弬鏉垮瀼濠ф劑鈧?
- 閺嶈宓侀悽銊﹀煕鐎圭偞婧€閺冦儱绻旀潻娑楃濮濄儲鏁归崣锝勮礋閳ユ笓oop 娑撹顕遍垾婵堟畱鏉╃偟鐢诲▽娆忥紣缁涙牜鏆愰敍?
  - 鏉╃偟鐢婚崹瀣煓閻╂ê浼愰崗宄版躬缂佹ê鍩楁潻鍥┾柤娑擃厺绗夐崘宥夌彯妫版垶褰冮崗?`zen_sand_sfx_impact`閿涘矂浼╅崗?100ms 缁狙呯叚閸戣褰傞棅铏Ω閸氼剚鍔呴崚鍥ㄥ灇閳ユ粌宕辨竟鏂モ偓婵堝濞堢偣鈧?
  - 閹绘劕宕?`zen_sand_sfx_loop` 閸╄櫣顢呴棅鎶藉櫤娑撳骸濮╅幀浣藉瘱閸ヨ揪绱濋獮璺虹殺闂堢偟鐝涢崡鍐蹭粻閹绢厾绱﹂崘韫矤 `240ms` 瀵ゅ爼鏆遍崚?`420ms`閿涘苯鍣虹亸鎴犵叚閹额剚澧滈崪宀冃曢悙瑙勫閸斻劑鈧姵鍨氶惃鍕焽缂侇厽鍔呴妴?
  - 娑撳鐨熼棃鐐电叾鐎涙劗琚?impact 闂婃娊鍣洪敍灞煎▏娣囨繄鏆€閻ㄥ嫭鎼锋担婊冨冀妫ｅ牅绗夐崘宥呭竾鏉╁洦瀵旂紒顓炵俺閸ｎ亗鈧?
- 閸?`toolbox_zen_sand_tool.dart` 娑擃厽甯撮崗銉ョ秼閸撳秴浼愰崗鐑界叾妫版垿顣╅悜顓ㄧ窗
  - `restore prefs`
  - `select tool`
  - `set brush size`
  - `toggle sound(true)`
  - `apply ritual preset`

### 娣囶喖顦?
- 娣囶喖顦茬粋鍛壈濞屾瑧娲忓顏嗗箚鎼存洖娅旀＃鏍偧鐠ч攱鎸辩€硅妲楅拃钘夋躬 impact 婢归绠ｉ崥搴涒偓浣割嚤閼风补鈧粌褰ч張澶夌婢逛即娈㈤崥搴″絺缁岃　鈧繄娈戦梻顕€顣介妴?
- 娣囶喖顦查惄绋挎倱瀹搞儱鍙?閸欏倹鏆熸潻鐐电敾缂佹ê鍩楅弮璺哄冀婢跺秴鍨忓┃鎰敨閺夈儳娈戦柌宥咁槻瀵ゆ儼绻滈敍灞惧絹閸楀洤浠犻崥搴″晙閹绢厼鎷伴惌顓㈡？闂呮棁绻涢悽鑽ゆ畱鏉╃偟鐢婚幀褋鈧?
- 閺傛澘顤冨▔銏犺埌閸ョ偛缍婂Λ鈧弻銉礉绾喛顓昏ぐ鎾冲閸氬牊鍨氶棅鎶筋暥娑撳秴鐡ㄩ崷銊⑩偓婊冦亣濞堥潧澧犵€佃偐鈹栭惂瑙ｂ偓婵撶窗
  - 瀵邦亞骞嗘竟?`leadingQuietMs = 0ms`閿涘畭longestQuietMs = 0-20ms`
  - 閸戣褰傛竟?`leadingQuietMs = 0ms`

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗙拫鍐╂殻闂嗗棔鑵戦崷銊︽尡閺€鎯ф珤妫板嫮鍎规稉?source 婢跺秶鏁ょ粵鏍殣閿涘奔绗夐弨鐟板綁閹靛濞嶇拠顓濈疅閵嗕礁浼愰崗鐤嚔娑斿鈧焦瀵旀稊鍛缂佹挻鐎崪宀勩€夐棃顫瑹閸旓繝鈧槒绶妴?
- 妫板嫮鍎规导姘愁唨缁屾椽妫介悩鑸碘偓浣风瑓婢舵矮绻氶悾娆忕毌闁插繐鍑￠悽鐔稿灇 WAV/瀹告彃濮炴潪?source閿涙稖瀵栭崶缈犵矌闂勬劕缍嬮崜宥呬紣閸忓嘲鐖堕悽?bucket閿涘矂顥撻梽鈺佸讲閹貉佲偓?

### 妤犲矁鐦?
- `dart format lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart test/toolbox_zen_sand_sound_service_test.dart`閿涘牓鈧俺绻冮敍?
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`閿涘牓鈧俺绻冮敍?

## [Unreleased-PLAN_045] - 2026-04-23

### 閸樼喎娲?
- 缁岃櫣浼掗棅鎶芥尲閿涘牏鏋熼幇鍫ョ叾闁界绱氬Ο鈥虫健閸楁洘鏋冩禒?2255 鐞涘奔寮楅柌宥堢箽閸?500 鐞涘瞼鈥栨い璁圭幢鐟欏棜顫庢稉濠佺閼村鐤嗛棁鎾规瑜扳晞娅ｉ懝韫瑢 toolbox閵嗗本鐓嶉崪灞烩偓浣稿帬閸掕翰鈧浇鍨濈紓鎾扁偓宥呯唨缁惧じ绗夋稉鈧懛杈剧幢缁夎濮╃粩顖氱俺闁?188dp 鐢悂鈹楅幎钘夌溄閹搞倕甯囨稉鏄忓灦閸欏府绱濋棅鎶芥尲婢跺崬骞撴＃鏍х潌鐟欏棜顫庨悞锔惧仯閵?

### 閺傛澘顤?
- `lib/src/ui/pages/toolbox_singing_bowls_tool_specs.dart`閿涙岸顣堕悳?闂婂疇澹?spec + 11 缂佸嫯鍤滈悞鎯板 palette閵?
- `lib/src/ui/pages/toolbox_singing_bowls_tool_painters.dart`閿涙矮绗佺紒?CustomPainter閿涘牐鍎楅弲?/ 闂婃娊鎸?/ 娴ｆ瑦灏熼幍鈺傛殠閿涘鈧?
- `lib/src/ui/pages/toolbox_singing_bowls_tool_stage.dart`閿涙岸鐓堕柦鍏稿瘜閼哥偛褰撮敍鍧刡owlSize` 娑撳﹪妾?296閳?60閿涘本鏌婇懛顏嗗姧閼硅尪浜ょ憴锔藉絹缁€?pill閿涘鈧?
- `lib/src/ui/pages/toolbox_singing_bowls_tool_layout.dart`閿涙氨些閸斻劎顏?Header(48dp) + Stage + SummaryBar(60dp) 娑撳顔岀紒鎾寸€敍娑欐喅鐟曚焦娼崡铏Ω閹靛绱濋悙鐟板毊閹垫挸绱戞稉濠冨 Sheet閵?
- `lib/src/ui/pages/toolbox_singing_bowls_tool_wide.dart` + `_wide_tiles.dart`閿涙艾顔旂仦?閳?760dp 鐢啫鐪穱婵堟殌閸樼喖顎囬弸璁圭礉閹诡澀璐熼弬鎷屽殰閻掓儼澹婇妴?
- `lib/src/ui/pages/toolbox_singing_bowls_tool_sheet.dart` + `_sheet_controls.dart`閿涙瓪DraggableScrollableSheet` 娑撳﹥濯洪幎钘夌溄閿涘本澹欐潪浠嬵暥閻滃洩褰嶉崡鏇礄chakra/resonance 閸掑棛绮嶉敍? 闂婂疇澹?2鑴? 缂冩垶鐗?+ 閼奉亜濮╅幘顓熸杹 slider + 鐟欙附鍔?switch + 閸嬫粍顒涙担娆愬盁閹稿鎸抽妴?
- `plans/PLAN_045_缁岃櫣浼掗棅鎶芥尲閼奉亞鍔ч懜鎺椻偓鍌溞╅崝銊ь伂缁彞鎱?md`閿涙碍婀版潪顔款吀閸掓帗鏋冨锝冣偓?

### 娣囶喗鏁?
- `lib/src/ui/pages/toolbox_singing_bowls_tool.dart`閿涙矮绮?2255 鐞涘本鏁圭紓鈺佸煂 373 鐞涘矉绱濇禒鍛箽閻?`SingingBowlsToolPage` / `SingingBowlsPracticeCard` / `_SingingBowlsPracticeCardState` 閻?lifecycle 娑撳簼绨ㄦ禒鑸垫煙濞夋洩绱濋崗鏈电稇闁俺绻?`part` 閸掑棛澧栭妴?
- 11 缂佸嫯鍓︽潪?閸忚鲸灏熸０鎴犲芳閻?`accent / glow / gradient` 闁插秴鍟撴稉楦垮殰閻掓湹缍嗘鍗炴嫲閼硅尙閮撮敍鍫ユ珷閸?/ 閼绘棁妫?/ 閺呫劑娴?/ 濡锯偓鐟?/ 閽栨媽銆傞悘鎵紶 缁涘绱氶敍灞肩箽閻?`id / note / frequency / 閺傚洦顢峘 鐠囶厺绠熸稉宥呭綁閵?
- 閼冲本娅欑痪鎸庘偓褏姹楅悶?alpha 娴?0.026 闂勫秴鍩?0.018閿涘矁鍎楅弲顖濈罚閸忓浜ゆ惔锔界厤閸栨牭绱濈粭锕€鎮?閼奉亞鍔ч懜鎺椻偓?濮樻棁宸濋妴?
- 缁夎濮╃粩顖氥仈闁劌鍨归梽銈呭晳闂€鍨閺嶅洭顣?妫版垹宸奸妴渚€鐓堕懝韫瑢缁屾椽妫跨亸楣冪吂閻ㄥ嫮些閸斻劎顏柌宥嗙€?閿涘牊鏋冨鍫濆嚒鏉╀礁鍙?Sheet 閸愬拑绱氶妴?

### 妞嬪酣娅撻崣妯绘纯
- 娑撱儲鐗搁柆闈涚暓閵嗗苯褰ч崝?UI閵嗕椒绗夐崝銊┾偓鏄忕帆閵嗗秷绔熼悾宀嬬窗閹碘偓閺?`ToolboxSingingBowlsPrefsService` 鐠嬪啰鏁ら妴涔oolboxAudioBank.singingBowlTone` 鐠嬪啰鏁ら弬鐟扮础閵嗕梗_frequencyId/_voiceId/_autoPlayIntervalMs` 姒涙顓婚崐闂寸瑢閹镐椒绠欓崠鏍波閺嬪嫨鈧椒绨ㄦ禒鎯靶曢崣鎴ｎ嚔娑斿娼庨張顏呮暭閸斻劊鈧?
- `part of` 閹峰棗鍨庨崥搴㈠閺堝甯粔浣规箒缁紮绱檂_SingingBowlFrequencySpec` / `_SingingBowlPainter` 缁涘绱氱紒褏鐢婚弬鍥︽缁変焦婀侀敍娑欐煀婢?`setPressing(bool)` 閸忣剙绱戦弬瑙勭《娴犮儲鏁幐?stage extension 鐟欙箑褰?setState閿涘本婀弳鎾苟閸愬懘鍎寸€涙顔岄妴?

### 妤犲矁鐦?
- `dart format lib/src/ui/pages/toolbox_singing_bowls_tool*.dart`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/ui/pages/toolbox_singing_bowls_tool*.dart`閿涘湤o issues found閿?
- 閹碘偓閺?9 娑擃亜鐡欓弬鍥︽ 閳?500 鐞涘瞼鈥栨い璁圭窗娑?373 / specs 309 / painters 364 / stage 164 / layout 263 / wide 385 / wide_tiles 189 / sheet 267 / sheet_controls 324閵?

## [Unreleased-PLAN_044] - 2026-04-23

### 閸樼喎娲?
- 瑜版挸澧犵粙瀣碍閸欘垵绻嶇悰宀嬬礉娴ｅ棛顩幇蹇旂煓閻╂ê鐡ㄩ崷銊よ⒈缁缍嬫宀勬６妫版﹫绱伴崡鏇熷瘹缂佹ê鍩楅崑璺哄絺鐠囶垵袝缂傗晜鏂侀妴浣藉剹閺咁垱鏅ラ弸婊堢叾閸︺劋绔寸粭鏃傜帛閸掓儼绻冪粙瀣╄厬闂傚瓨鐡忛幀?閹哄绔存稉?閿涘牆鎯夐幇鐔告焽閺傤厾鐢荤紒顓ㄧ礆閵?
- 閻劍鍩涢崣宥夘洯濮濄倕澧犻惃?PLAN_044 閺€鐟板З閸欘亙鎱ㄩ崚棰佺閸楀﹥婀幓鎰唉閿涙稒婀板▎鈥虫躬閸氬奔绔?PLAN 娑撳鐢荤悰銉ｂ偓?

### 娣囶喗鏁?
- 閸?`toolbox_zen_sand_tool.dart` 娑擃厽鏁圭槐褏缂夐弨鎯у灲鐎规熬绱?
  - 閸楁洘瀵氱紒妯哄煑閻樿埖鈧椒绗呰箛鐣屾殣 `|details.scale - 1| <= 0.02` 閻ㄥ嫬浜曢幎鏍уЗ閿涘奔绗夐崘宥堫嚖閸掑洦宕查崚?transform 濡€崇础閵?
- 閸?`toolbox_zen_sand_tool.dart` 娑擃厼浠涚粔璇插З缁旑垳鐛庣仦蹇斿閸忓绱欑痪?UI閿涘绱?
  - 閸?<390dp 缁愬嫬鐫嗘稉瀣暪缂?padding閵嗕焦褰侀崡?headerGap/sectionGap 閸樺缂夐妴浣告躬 <380dp 鐏?Header 閹舵ê褰旀稉杞扮瑐娑撳琚辩悰宀嬬礄鏉╂柨娲?閺嶅洭顣?/ 閹诲繗鍫?/ 韫囶偅宓庨崗銉ュ經 chip 鐞涘矉绱氶妴?
  - 娑撱倓閲滈幎钘夌溄閸楋紕澧栭敍鍫濇簚閺?/ 瀹搞儱鍙挎稉搴㈠付閸掕绱氶崷銊ュ讲閻劌顔旀惔?<360dp 閺冭埖鏁兼稉鍝勫礋閸掓绱?60-420 閸椻€愁啍閺€閫涜礋 170-360 閺囧鎻ｉ懛娣偓?
  - 鎼存洟鍎?dock 閹舵ê褰旈幀浣稿灩闂?鎼存洟鍎撮懣婊冨礋瀹稿弶濮岄崣?閸愭ぞ缍戦崜顖涚垼妫版﹫绱濋懙鎯у毉鐎硅棄瀹崇紒娆庡瘜閹垮秳缍旈幐澶愭尦閿涙矞ompact 閹礁顦荤仦鍌氬晳娴?`SingleChildScrollView` 閺€閫涜礋 `Padding`閿涘瞼些闂勩倕绁垫總妤冩棻閸氭垶绮撮崝銊ｂ偓?
- 閸?`toolbox_zen_sand_sound_service.dart` 娑擃厼浜ゆ惔鏇氭叏婢跺秴鎯婇悳顖氱俺閸?娑撯偓缁楁柧鑵戠粚娲叾"閿?
  - **閺嶇懓娲?*閿涙碍顒濋崜宥呮値閹存劖璐╅悽銊ょ啊 `phase`閿?閳? 瀵邦亞骞嗛敍澶夌瑢 `t`閿涘牏绮风€靛湱顫楅敍澶夎⒈婵傛鍤滈崣姗€鍣洪敍灞芥躬 phase=1 婢跺嫪浜?`t` 妞瑰崬濮╅惃鍕皾瑜邦澀绗夋导姘舵４閸氬牞绱濋崣鐘插閻?`loopWindow = 0.92 + 0.08 sin(2锜?phase) sin(4锜?phase)` 閸?phase=0/0.25/0.5/0.75 閸欏牆鎳嗛張鐔糕偓褍甯?8% 閹割垰绠欓敍宀冾潶娴滈缚鈧櫕鍔呴惌銉よ礋"娑撯偓缁楁梻鏁鹃悽濠氭娑撯偓娴兼艾鍔圭亸杈ㄥ竴娑撯偓娑?閵?
  - **娣囶喖顦?*閿涙瓪_buildLoopWav` 閹碘偓閺堝鍨庨柌蹇涘櫢閸愭瑤璐熺痪?`phase` 閸╂亽鈧焦鏆ｉ弫浼搭暥閻滃洤鈧秵鏆熼敍鍧剅ustle/low/shimmer/motion/wash`閿涘绱濇担鎸庡皾瑜般垹婀?phase 0閳? 婢跺嫪寮楅弽濂告４閸氬牞绱遍崢濠氭珟 `loopWindow`閿? 1.0閿涘绱濆☉鍫ユ珟閸愬懘鍎撮崨銊︽埂閹冨毈闂勫嚖绱盽_seamBlendLoopPcm` 娣囨繄鏆€娑撹桨绻氶梽鈺佺敨閿涘牅绮?96ms 闂勫秴鍩?48ms閿涘鈧?
  - 瀵邦亞骞嗘惔鏇炴珨闂€鍨娴?`880ms` 瀵ゅ爼鏆遍崚?`3200ms`閿涙盯娼粩瀣祮閸嬫粍顒涘鑸垫娴?`140ms` 鐠嬪啯鏆ｉ崚?`240ms`閿涘苯鍣虹亸鎴犵叚閹额剚澧滈柅鐘冲灇閻ㄥ嫭鏌囩紒顓熷妳閵?

### 娣囶喖顦?
- 娣囶喖顦茬粋鍛壈濞屾瑧娲忛崡鏇熷瘹缂佹ê鍩楅弮璺轰紦閸?閻ｅ矂娼扮拠顖氬灲娑撹櫣缂夐弨?楠炲磭些"閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦茬粋鍛壈濞屾瑧娲忛懗灞炬珯閺佸牊鐏夐棅?娑撯偓缁楁梻绮崚鎯扮箖缁嬪鑵戦梻鎾娑撯偓娴兼艾鍔圭亸杈ㄥ竴娑撯偓娑?閻ㄥ嫭鐗撮崶鐙呯礄閻╅晲缍呮稉宥夋４閸?+ loopWindow 閸涖劍婀￠幀褍甯囬獮鍜冪礆閵?
- 閹绘劕宕?375dp/iPhone SE 缁涘鐛庣仦蹇庣瑓 Header閵嗕龚ock閵嗕焦濞婄仦澶婂幢閻楀洨娈戠憴锕佹彧娑撳酣妲勭拠鏄忓灊闁倸瀹抽妴?

### 妞嬪酣娅撻崣妯绘纯
- 闂婃娊顣堕崥鍫熷灇閸掑棝鍣洪弫鏉款劅鐞涖劏鎻崣妯哄閿涘奔绱伴弨鐟板綁鎼存洖娅旈惃鍕睏閻炲棛绮忛懞鍌︾礄娴犲秴婀崥灞肩閸氼剚鍔呯€硅埖妫岄崘鍜冪礆閿涙稒婀弨鐟板綁閺堝秴濮?API/娴滃娆㈢拠顓濈疅/閹镐椒绠欓崠鏍モ偓?
- 閹碘偓閺?UI 閺€鐟板З娑撱儲鐗搁柆闈涚暓"閸欘亜濮?UI閵嗕椒绗夐崝銊┾偓鏄忕帆"鏉堝湱鏅妴?

### 妤犲矁鐦?
- `dart format`閿涘牓鈧俺绻冮敍?
- `dart analyze lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart`閿涘牅绮庨弮銏℃箒 6 閺?unused_element warning閿涘本妫ら弬鏉款杻閿?
- `flutter build windows --debug`閿涘牓鈧俺绻冮敍?
- `flutter test --reporter compact`閿涘湏ll 231 tests passed閿?

## [Unreleased-PLAN_043-MERGE-READY] - 2026-04-21

### Reason
- Finalize branch `codex/plan024-backup` for merge readiness after AppState ownership split and large toolbox page decoupling.

### Changed
- AppState practice/playback domain state now reads/writes directly through `PracticeStore` and `PlaybackStore` ownership boundaries, removing bridge-style private alias indirection.
- Harp settings sheet large UI block was extracted from `toolbox_sound_tools/harp.dart` into `toolbox_sound_tools/harp_settings_sheet.dart`, keeping page-layer file focused on lifecycle and UI entry orchestration.
- `toolbox_sound_tools.dart` part registry updated for the new harp settings sheet part file.

### Verification
- Full regression passed with `flutter.bat test --reporter compact` (all tests passed).
- Regression rerun after fixing a temporary refactor replacement issue to ensure stable merge gate.

### Residual Risks
- `app_state.dart` and some toolbox page files are still above preferred file-size targets; next iteration should continue domain-by-domain extraction for sleep/wordbook/export ownership boundaries.

## [Unreleased-PLAN_043] - 2026-04-21

### 閸樼喎娲?
- 闂団偓鐟曚礁鍘涢梽宥勭秵 ASR 濞村鐦懘鍡楁€ラ幀褋鈧線鐓舵０鎴犵处鐎涙ê鍞寸€涙﹢顥撻梽鈺€绗?AppState 閻樿埖鈧焦鐏戠痪鍊熲偓锕€鎮庨敍灞藉晙閹恒劏绻樻径褔銆夐棃銏㈩儑娑撳鐤嗛崚鍡楃湴閵?

### 娣囶喗鏁?
- 閺傛澘顤?`AsrServiceContract` 閹跺€熻杽閹恒儱褰涢敍瀹岮srService` 閺€閫涜礋閺勬儳绱＄€圭偟骞囬崗顒€鍙?API閿涘苯鑻熺亸?extension 閺嗘挳婀堕懗钘夊閺€璺哄經娑撳搫鍞撮柈銊ョ杽閻滅増鏌熷▔鏇樷偓?
- `AppDependencies` 娑?`AppState` 閻?ASR 娓氭繆绂嗛弨閫涜礋闂堛垹鎮?`AsrServiceContract`閿涘本绁寸拠?double 閺€閫涜礋閹恒儱褰涚€圭偟骞囬妴?
- `ToolboxAudioBank` 瀵洖鍙嗛崣顖炲帳缂冾喕绗傞梽?LRU 缂傛挸鐡ㄧ€圭懓娅掗敍灞炬煀婢?`configureCache`閵嗕梗clearCache`閵嗕梗clearDomainCache`閵嗕胶绱︾€涙ê顔愰柌?閺夛紕娲?娴兼壆鐣荤€涙濡憴鍌涚ゴ閹恒儱褰涢妴?
- 閺傛澘顤?`WeatherStore` 閻欘剛鐝?notifier/store 楠炶埖甯撮崗?`AppState`閿涘苯銇夊鏂跨厵閻樿埖鈧焦瀚㈤張澶嬫綀娴?`AppState` 閸愬懘鍎寸€涙顔屾潻浣盒╅崚?store閵?
- 闁夸礁鐣?`zen_sand / woodfish / harp` 缁楊兛绗佹潪顔剧波閺嬪嫭濯堕崚鍡窗閺傛澘顤冮柊宥囩枂鐏炲倹鏋冩禒鏈电瑢濞撳弶鐓嬬仦鍌氬弳閸欙絾鏋冩禒璁圭礉娑撶粯鏋冩禒鏈电箽閻ｆ瑧濮搁幀浣虹椽閹烘帊绗屾禍銈勭鞍鐠囶厺绠熼妴?

### 娣囶喖顦?
- 娣囶喖顦?`WeatherStore` 閸?`AppState` 閺嬪嫰鈧娀妯佸▓浣冪箖閺冣晞顕伴崣鏍啎缂冾喖顕遍懛瀛樻殶閹诡喖绨遍張顏勫灥婵瀵查崷鐑樻珯娑撳袝閸?`LateInitializationError` 閻ㄥ嫰妫舵０妯糕偓?
- 閺傛澘顤?`ToolboxAudioBank` 閸ョ偛缍婂ù瀣槸閿涘矁顩惄?LRU 濞ｆɑ鍗戞稉?`clearDomainCache` 閸╃喓楠囧〒鍛倞鐠囶厺绠熼妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤?`woodfish/harp` 濞撳弶鐓嬬仦鍌氬帥鐎瑰本鍨氶崗銉ュ經閺傚洣娆㈤拃鎴掔秴娑撳酣鍘ょ純顔肩湴閹剁晫顬囬敍灞界暚閺?painter 鏉╀胶些鐏忓棗婀崥搴ｇ敾鏉╊厺鍞紒褏鐢婚幒銊ㄧ箻閵?

### Continuation (2026-04-21)
- AppState ownership split continues with a dedicated `TestModeStore`, including constructor injection, listener lifecycle wiring, and startup/reload sync integration.
- `app_state_startup.dart` test-mode mutation paths now delegate to `TestModeStore` (`setEnabled/toggleReveal/toggleHint/resetProgress`) to avoid cross-domain private-state writes.
- Added `test/test_mode_store_test.dart` to lock persistence and guard behavior of the new store.
- Zen Sand round-3 layering advanced: `_ZenSurfacePainter` and `_ZenSandPainter` moved from `toolbox_zen_sand_tool.dart` into `toolbox_zen_sand_tool_render.dart`, keeping main file focused on orchestration/state.

## [Unreleased] - 2026-04-13

### 閸樼喎娲?
- 闂団偓鐟曚線妾锋担?`database_service.dart` 娑?`_applySchemaMigrations()` 閻ㄥ嫰鍣告径宥呭瀻閺€顖氼槻閺夊倸瀹抽敍灞藉櫤鐏忔垵鎮楃紒顓熸煀婢?schema 閻楀牊婀伴弮鍓佹畱缂佸瓨濮㈤幋鎰拱娑撳孩绱￠弨褰掝棑闂勨斂鈧?
- 閹稿缍嬮崜宥囧閺堫剙鐔€缁炬寧绔婚悶鍡樻殶閹诡喖绨遍崢鍡楀蕉鏉╀胶些閸愭ぞ缍戞禒锝囩垳閿涘苯鍣虹亸鎴犳樊閹躲倛绀嬮幏鍛嫙閺€鑸垫殐閸掓繂顫愰崠鏍熅瀵板嫬顦查弶鍌氬閵?
- `database_service.dart` 闂€鎸庢埂缁鳖垵顓搁崚鐗堟殶閸楀啳顢戦敍灞藉礋閺傚洣娆㈢紒瀛樺Б閹存劖婀版潻鍥彯閿涘矂娓堕幐澶婂閼宠姤膩閸ф濯堕崚鍡曚簰闂勫秳缍嗛懓锕€鎮庨崪灞炬暭閸斻劑顥撻梽鈹库偓?
- 缁楊兛绔存潪顔侥侀崸妤佸閸掑棗鎮楅敍灞煎瘜閺傚洣娆㈡禒宥嗗鏉炶姤鐗宠箛鍐ㄧ杽閻滄壆绮忛懞鍌︾礉闂団偓缂佈呯敾閹峰棗鍤?core/schema 娴犮儴绻樻稉鈧銉╂娴ｅ骸鍙嗛崣锝嗘瀮娴犺泛顦查弶鍌氬閵?
- 娣囶喖顦叉径褑鐦濋張顒佹尡閺€鐐閸欘亝鎸遍崡鏇＄槤閺堫剝闊╅妴渚€鍣存稊澶夌瑢閹碘晛鐫嶇€涙顔岄張顏嗘埛缂侇厽鎸遍弨鍓ф畱闂傤噣顣介妴?
- 娣囶喖顦查崢鍡楀蕉閹绢厽鏂侀柊宥囩枂娑擃厾娈戠€涙顔岀粋浣烘暏閺嶅洩顔囨稉搴＄秼閸撳秹鍣告径宥嗩偧閺佹媽顔曠純顔煎暱缁愪緤绱濈€佃壈鍤х€涳缚绡勯幘顓熸杹閸欘亝鎸遍崡鏇＄槤閺堫剝闊╅惃鍕６妫版ǜ鈧?
- 娣囶喖顦?Windows 閺堫剙婀?TTS 閸︺劏鍤滈崝銊嚔鐟封偓濡€崇础娑撳妫ゅ▔鏇㈡鐎涙顔岄崘鍛啇閸掑洦宕查棅瀹犲閿涘苯顕遍懛鏉戭劅娑旂姵鎸遍弨鍙ヨ厬閸氬海鐢绘稉顓熸瀮闁插﹣绠熺粵澶婄摟濞堥潧鎯夐幇鐔剁瑐閸嶅繆鈧粍鐥呴張澶屾埛缂侇厽鎸遍弨閿偓婵堟畱闂傤噣顣介妴?
- 娣囶喖顦?Windows 閺堫剙婀?TTS 閸︺劌宕熺拠宥嗘尡鐎瑰苯鎮楅崶鐘茬暚閹存劕娲栫拫鍐╂弓濮濓絿鈥橀崶鐐插煂楠炲啿褰寸痪璺ㄢ柤閵嗕梗isSpeaking` 閻樿埖鈧焦绮搁悾娆掆偓宀勬毐閺冨爼妫块崑婊堛€戦獮鑸垫付缂佸牐绉撮弮鍓佹畱闂傤噣顣介妴?
- 娣囶喗顒滈幘顓熸杹妞ら潧銇囩拠宥嗘拱閸忋儱褰涢垾婊冨鏉炶棄鑻熼幘顓熸杹閳ユ繀绱伴崷銊ュ鏉炶棄鐣幋鎰倵閻╁瓨甯村鈧幘顓ㄧ礉娑撳秶顑侀崥鍫濆帥閸旂姾娴囬崘宥囨暠閻劍鍩涢崘鍐茬暰閺勵垰鎯佸鈧慨瀣尡閺€鍓ф畱娴溿倓绨版０鍕埂閵?
- 閺€鑸垫殐鏉炲鍣虹拠宥嗘蒋鐠囶厺绠熷鍌溞╂稉搴㈢ゴ鐠囨洖鐔€缁捐儻鈧礁瀵查梻顕€顣介敍宀勪缉閸忓秴顒熸稊鐘虫尡閺€鍙ユ叏婢跺秴寮介崥鎴炴杹婢堆冦亣鐠囧秵婀伴崝鐘烘祰閸愬懎鐡ㄩ妴浣稿幢妞ゅ灝鎷扮捄銊δ侀崸?UI 閸ョ偛缍婃径杈ㄦ櫏閵?
- 娣囶喖顦茬紒鍐х瘎濡€虫健鏉╃偟鐢荤粵鏃堫暯閺?Windows 濡楀矂娼扮粩?`accessibility_bridge.cc` / `ui::AXTree` 閹躲儵鏁婃潻鐐插煕閿涘苯鑻熸导鎾閺勫孩妯夐崡锟犮€戦惃鍕６妫版ǜ鈧?
- 娣囶喖顦茬紒鍐х瘎娴兼俺鐦介崷銊ュ瀼閹诡澀绗呮稉鈧０妯绘娴犲秴鐡ㄩ崷銊︽閺勬儳宕辨い鍖＄礉娑撴棁鐦濇稊澶愨偓澶嬪妫版﹢鏁婄拠顖欑稊缁涙梹妞傞崣顖濆厴鐞氼偉顕ら崚銈勮礋濮濓絿鈥橀惃鍕６妫版ǜ鈧?
- 娑撳搫鎮庨獮璺哄閺€璺虹啲閸愬秴甯囩紓鈺冪矊娑旂姳绱扮拠婵嗗瀼妫版ɑ妞傞惃鍕倱濮濄儴顓哥粻妞剧瑢闂勫嫬濮為崘娆忓弳缁旂偘绨ら敍宀勬娴ｅ海些閸斻劎顏崪灞绢攽闂堛垻顏潻鐐电敾缂佸啩绡勯弮鍓佹畱閸撯晙缍戦幎鏍уЗ閵?
- 閹恒劏绻?`PLAN_024` 闂冭埖顔岄崠鏍櫢閺嬪嫸绱濇禒搴樷偓婊勀侀崸妤€鍙嗛崣锝呭讲閹绘帗瀚堥垾婵婄箻娑撯偓濮濄儴鎯ら崚鎵斥偓婊嗙箥鐞涘本妞傞崣顖氫粻閻?+ 閺佺増宓佺仦鍌欑波鎼存挸鍨庨崺鐔测偓婵勨偓?
- 閸?`PLAN_024` 婢跺洣鍞ら幓鎰唉閸氬海鎴风紒顓炵暚閹存劏鈧粈绗呮稉鈧?1/2/3閳ユ繐绱濋幒銊ㄧ箻 Riverpod 妫ｆ牗澹掓潻浣盒╅妴浣风波鎼存挸鍨庣仦鍌滅敾閹峰棔绗岀€涳缚绡勫Ο鈥虫健閸嬫粎鏁ょ拠顓濈疅閹碘晛鐫嶉妴?
- 缂佈呯敾閹恒劏绻?`PLAN_024` 闂冭埖顔?2/3/4閿涙俺藟姒?sleep 閸╃喍绮ㄦ惔鎾圭珶閻ｅ被鈧胶绮烘稉鈧Ο鈥虫健鐠侯垳鏁辩€瑰牆宕奸獮璺虹殺濡剝婢橀幍鈺佺潔閸?focus/toolbox/sleep 閺傚洦銆傞崺鐔粹偓?
- 缂佈呯敾閹恒劏绻?`PLAN_024` 闂冭埖顔?1閿涙艾鐨?`app_root` 娑撳簼瀵岄柧鎹愮熅妞ょ敻娼伴幍瑙勵偧 2閿涘湣ore/Library/Play閿涘绺肩粔璇插煂 Riverpod 鐠囪褰囬柧鎹愮熅閵?
- 缂佈呯敾閹恒劏绻?`PLAN_024` 闂冭埖顔?1閿涙艾鐨㈢拋鍓х枂娑撳骸顦查惄姗€銆夐棃銏″濞?3閿涘潤anguage/data/appearance/wordbook/practice review/recognition/voice閿涘绺肩粔璇插煂 Riverpod 鐠囪褰囬柧鎹愮熅閵?
- 鐎?`PLAN_024` 閹笛嗩攽闂冭埖顔岄梻銊ㄧ槑娴煎府绱濈涵顔款吇鐠愩劑鍣洪崺铏瑰殠娑撳氦绺肩粔璇差杻闁插繐褰茬粙鍐茬暰鏉╂稑鍙嗘稉瀣╃闂冭埖顔岄妴?
- 閸氼垰濮?`PLAN_025`閿涘牓妯佸▓?5A閿涘绱伴崷銊ㄧ儲鏉?sleep 鐎涙劙銆夐棃銏㈡畱閸撳秵褰佹稉瀣剁礉娴兼ê鍘涢幒銊ㄧ箻婢堆勬瀮娴犲墎绮ㄩ弸鍕閸掑棔绗岄棃?sleep 閻?Riverpod 閺€璺虹啲閵?
- 缂佈呯敾閹恒劏绻?`PLAN_026`閿涘牓妯佸▓?5B閿涘绱扮亸?`AppState/wordbook_state` 閻ㄥ嫬澧挎担娆愭殶閹诡喖绨遍惄纾嬬箾閼宠棄濮忔稉瀣焽閸掗绮ㄦ惔鎾崇湴閹跺€熻杽閵?

### 娣囶喗鏁?
- 鐏?`_applySchemaMigrations()` 闁插秵鐎稉琛♀偓婊嗙讣缁夌粯顒炴銈堛€?+ 缂佺喍绔存い鍝勭碍閹笛嗩攽閳ユ繄绱幒鎺炵礉娣囨繄鏆€闁劖顒炴潻浣盒╅崥搴ｇ彌閸楀啿鍟撻崗?`PRAGMA user_version` 閻ㄥ嫭妫﹂張澶庮嚔娑斿鈧?
- 鐏忓棙鏆熼幑顔肩氨 schema 鏉╀胶些缁涙牜鏆愰弨鑸垫殐娑撹　鈧粈绮庣€靛綊缍堣ぐ鎾冲閻楀牊婀伴崣鍑ょ礄v9閿涘鈧繐绱濋獮璺哄灩闂勩倓绮庨張宥呭閺冄呭閸楀洨楠囬柧鎹愮熅閻?`_migrate*` 閸樺棗褰堕崘妞剧稇鐎圭偟骞囬妴?
- 鐏?`database_service.dart` 閹峰棗鍨庢稉?`part` 缂佹挻鐎敍姝歞atabase_service_maintenance.dart`閵嗕梗database_service_wordbook_query.dart`閵嗕梗database_service_wordbook_import.dart`閵嗕梗database_service_tasks.dart`閿涘奔瀵岄弬鍥︽娣囨繄鏆€閺嶇绺炬銊︾仸娑撳骸鐔€绾偓閼宠棄濮忛妴?
- 缂佈呯敾閹峰棗鍨?`database_service` 閺嶇绺剧仦鍌︾窗閺傛澘顤?`database_service_core.dart` 娑?`database_service_schema.dart`閿涘苯鐨㈠楦裤€?schema 鐎靛綊缍堟稉搴＄俺鐏炲倹鏆熼幑顔肩氨 helper 娴犲簼瀵岄弬鍥︽鏉╀礁鍤敍灞煎瘜閺傚洣娆㈤弨鑸垫殐閸掓壆琚崹瀣暰娑斿绗岄崚婵嗩潗閸栨牕鍙嗛崣锝冣偓?
- 閸︺劍鎸遍弨楣冩懠鐠侯垯鑵戦崝鐘插弳闁劘鐦?hydrate 鐟欙絾鐎介敍灞肩箽閹镐礁銇囩拠宥嗘拱閸掓銆冩潪濠氬櫤閸旂姾娴囬惃鍕倱閺冭绱濈涵顔荤箽鐎圭偤妾幘顓熸杹閸撳秵瀣侀崚鏉跨暚閺佹潙鐡у▓鐐光偓?
- 鐠嬪啯鏆ｇ€涙顔岄幘顓熸杹闁板秶鐤嗙憴锝嗙€介柅鏄忕帆閿涙艾缍嬮柌宥咁槻濞嗏剝鏆熸径褌绨?`0` 閺冭绱濇导妯哄帥鐟欏棔璐熻ぐ鎾冲鐎涙顔屾惔鏂垮棘娑撳孩鎸遍弨鎾呯礉楠炲墎绮烘稉鈧幐澶庮潐閼煎啫瀵茬€涙顔岄柨顔款嚢閸欐牠鍘ょ純顔界垼缁涘彞绗岄柌宥咁槻濞嗏剝鏆熼妴?
- 娑?Windows 閺堫剙婀?TTS 婢х偛濮為崣顖滅处鐎涙娈戦張顒€婀撮棅瀹犲鐟欙絾鐎芥稉搴㈠瘻閺傚洦婀扮拠顓♀枅閼奉亜濮╅崠褰掑帳闁槒绶敍灞炬弓閺勬儳绱￠柅澶嬪閺堫剙婀撮棅瀹犲閺冭泛褰查崷銊ㄥ閺傚洣绗屾稉顓熸瀮鐎涙顔屾稊瀣？閼奉亜濮╅崚鍥ㄥ床閸氬牓鈧?voice閵?
- 娑?Windows 閺堫剙婀?TTS 鐞涖儱鍘?`setVoice` 婢惰精瑙﹂崥搴ｆ畱 `setLanguage` 閸ョ偤鈧偓鐠侯垰绶為敍灞借嫙鐠佹澘缍嶇€圭偤妾拠顓㈢叾闁瀚ㄩ弮銉ョ箶閿涘本鏌熸笟鍨倵缂侇叀鎷烽煪顏傗偓?
- 鐏?Windows 閺堫剙婀?TTS 閻ㄥ嫮鐡戝鍛摜閻ｃ儲鏁兼稉琛♀偓婊冪暚閹存劕娲栫拫鍐х喘閸忓牄鈧胶濮搁幀浣界枂鐠囥垹鍘规惔鏇椻偓婵撶礉娑撳秴鍟€閹?`isSpeaking` 鏉烆喛顕楁担婊€璐熼崬顖欑鐎瑰本鍨氭笟婵囧祦閵?
- 娣囶喗顒?`flutter_tts` Windows 濡楀矂娼伴幓鎺嶆閻ㄥ嫬娲栫拫鍐╁闁帞鍤庣粙瀣╃瑢缁愭褰涢崣銉︾労娴ｈ法鏁ら弬鐟扮础閿涘瞼鈥樻穱?`MediaEnded` / `speak.onComplete` 閼崇晫婀″锝呮礀閸掍即銆婄仦鍌滅崶閸欙絿鍤庣粙瀣⒔鐞涘被鈧?
- 鐏?`flutter_tts` Windows 濡楀矂娼伴幓鎺嶆閻?`isSpeaking` 閺屻儴顕楅弨閫涜礋娴兼ê鍘涚拠璇插絿鐎圭偤妾幘顓熸杹閻樿埖鈧緤绱濋柆鍨帳閸愬懘鍎寸敮鍐ㄧ毜閸婄厧宕卞璇差嚤閼风鐤嗙拠銏犲幑鎼存洖銇戦弫鍫涒偓?
- 鐏忓棗顒熸稊鐘虫尡閺€鍓ф畱婢堆嗙槤閺堫剙娆㈡潻鐔峰鏉炶棄鍙嗛崣锝嗘暭娑撹　鈧粌鍘涢崝鐘烘祰鐠囧秵婀伴敍灞藉晙閹靛濮╁鈧慨瀣尡閺€閿偓婵撶礉闁灝鍘ゆ＃鏍偧閻愮懓鍤崡瀹犲殰閸斻劌绱戦幘顓溾偓?
- 鐞涖儱宸?`PlaybackService` 妫板嫬濮炴潪鎴掔窗鐠囨繄濮搁幀浣侯吀閻炲棴绱濋崑婊勵剾閹存牕鍨忛幑銏犲煂閻╁瓨甯撮幘顓熸杹閺冩湹绱板〒鍛倞閺?prepared session閿涘苯鑻熸穱婵嗙摠鐟欙絾鐎介崥搴ｆ畱鐠囧秵娼箛顐ゅ弾闁灝鍘ら崥搴ｇ敾閸ョ偠鐨熼幏鍨煂鏉炲鍣虹€电钖勯妴?
- 鐏?`getWordsLite()` / `searchWordsLite()` 閹垹顦叉稉铏规埂濮?lite 閺屻儴顕楅敍灞藉涧鐠囪褰囬張鈧亸蹇撶箑鐟曚礁鍨敍灞借嫙娴?`primary_gloss/meaning` 娴ｆ粈璐熸潪濠氬櫤閹芥顩﹂崗婊冪俺閵?
- 閺勫海鈥橀張顒冪枂娑撳秵甯撮崣?richer-lite 鐠囶厺绠熼幍鈺佺炊閿涘瞼鎴风紒顓⑩偓姘崇箖 `hydrateWordEntry()` / 閹绢厽鏂侀崜宥嗗瘻闂団偓鐞涖儱鍙忓陇鍐荤€涳缚绡勯幘顓熸杹鐎涙顔岄棁鈧Ч鍌樷偓?
- 娑?UI smoke 閸嬪洨濮搁幀浣剿夐崗鍛旂€规氨娈戦崷銊у殠閻滎垰顣ㄩ棅宕囨窗瑜版洘鐗辨笟瀣剁礉闁灝鍘ゆ笟婵婄瑜版挸澧犵痪澶哥瑐 fallback 娑撹櫣鈹栫€佃壈鍤ч惄顔肩秿閹垮秳缍旈崶鐐茬秺婢惰京婀￠妴?
- 閸氬本顒為弴瀛樻煀閸氼垰濮╅幀浣风瑢閸掓繂顫愰崠鏍ㄧゴ鐠囨洜娈?tracking key / lite 鐎涙顔岄弬顓♀枅閿涘奔濞囩紒鍐х瘎閵嗕椒鎹㈤崝鈩冩拱娑撳骸顒熸稊鐘衬侀崸妤€鍙￠悽銊ф畱閻樿埖鈧焦婀￠張娑楃箽閹镐椒绔撮懛娣偓?
- 鐏?Windows 缂佸啩绡勬导姘崇樈娑擃厾娈戦柅鎰邦暯缁涙棃顣介崣宥夘洯娴犲酣鐝０?`showDialog` 鐠侯垳鏁遍崚鍥ㄥ床娑撴椽銆夐崘鍛冀妫ｅ牆宕遍敍灞肩箽閻ｆ瑩鏁婃０妯绘拱瀵偓閸忕偨鈧礁鎬ラ崶鐘崇垼缁涙儳鎷扮紒褏鐢绘稉瀣╃妫版ɑ鎼锋担婊愮礉娴ｅ棗鍣虹亸鎴ｇ箾缂侇厾鐡熸０妯绘閻ㄥ嫯顕㈡稊澶嬬埐闁插秴缂撻妴?
- 娑撹櫣绮屾稊鐘虹箻鎼达附娼晶鐐插缁嬪啿鐣剧拠顓濈疅閹诲繗鍫敍灞借嫙鐏忓棗宕熺拠宥呭幢閺嶅洭顣介弨閫涜礋缁嬪啿鐣剧拠顓濈疅閺嶅洨顒?+ 閹烘帡娅庣憗鍛淬偘閸斻劎鏁剧拠顓濈疅閻ㄥ嫮绮嶉崥鍫礉闂勫秳缍?AXTree 閹舵牕濮╅妴?
- 鐏忓棛绮屾稊鐘烘嫹闊亜鎻╅悡褎鏁归弫娑楄礋鏉炲鍣洪幐浣风畽閸栨牜绮ㄩ弸鍕剁礉闁劙顣芥穱婵嗙摠閺冩湹绗夐崘宥嗘儭鐢箑鐣弫?`fields`閿涘苯鑻熸禒鍛躬闊偂鍞ら崗婊冪俺绾喗婀侀棁鈧憰浣规娣囨繄鏆€ `rawContent`閵?
- 鐠嬪啯鏆ｇ紒鍐х瘎缂傛挸鐡ㄧ拠宥嗘蒋閻ㄥ嫪绱崗鍫㈤獓娑撳孩鐎柅鐘虫煙瀵骏绱伴崘鍛摠娑擃厺绱崗鍫㈢处鐎涙浜ら柌蹇氱槤閺夆槄绱濈€圭偤妾憴锝嗙€界拠宥嗘蒋閺冨墎鏁辫ぐ鎾冲娴ｆ粎鏁ら崺?瀹告彃濮炴潪鍊熺槤閺壜ゎ洬閻╂牞浜ら柌蹇撴彥閻撗嶇礉閸忓ジ銆愰幀褑鍏樻稉搴＄潔缁€鍝勭暚閺佹潙瀹抽妴?
- 鐏忓棛绮屾稊鐘汇€夌€?`AppState` 閻ㄥ嫭鏆ｆい鐢垫磧閸氼剚鏁圭粣鍕煂 `uiLanguage`閿涘苯鑻熼幎濠呭殰閸斻劌褰傞棅瀹犘曢崣鎴滅矤 `build()` 閹割亜鍩岄崚鍥暯閸戝棗顦梼鑸殿唽閿涘苯鍣虹亸鎴滅瑓娑撯偓妫版﹢妯佸▓鐢垫畱閺冪姴鍙?rebuild 閸滃苯澹囨担婊呮暏閵?
- 娑撹櫣绮屾稊鐘电摕妫版濮搁幀浣稿晸閸忋儰绗岄崚鍥暯鏉╁洨鈻兼晶鐐插閹便垼鐭惧鍕）韫囨绱濇笟澶哥艾缂佈呯敾鏉╁€熼嚋鐠佹儳顦笟褎鈧嗗厴瀵倸鐖堕妴?
- 鐏忓棛绮屾稊鐘辩窗鐠囨繄娈戠拠宥勭疅閸婃瑩鈧鐫滈弨閫涜礋閹稿鐤嗗▎锟狀暕鐠侊紕鐣荤紓鎾崇摠閿涘矂浼╅崗宥嗙槨濞嗏€冲瀼妫版﹢鍏橀柌宥嗘煀闁秴宸婚弫纾嬬枂閸楁洝鐦濋獮鍫曞櫢婢跺秴缍婃稉鈧崠鏍槤娑斿鈧?
- 鐏忓棝鏁婃０妯垮殰閸斻劌濮為崗銉ゆ崲閸斺剝婀伴惃鍕閸旂姴鍟撻崗銉︽暭娑撴椽顩荤敮褎瑕嗛弻鎾虫倵閸愬秷袝閸欐埊绱濋梽宥勭秵閸滃备鈧粈绗呮稉鈧０妯封偓婵堟櫕闂堛垹鍨忛幑顫挨閹额澀瀵岀痪璺ㄢ柤閻ㄥ嫭顩ч悳鍥モ偓?
- 閺傛澘顤?`repositories` 閸掑棗鐪伴獮鑸靛复閸忋儰绶风挧鏍ㄦ暈閸忋儻绱癭PracticeRepository` 娑?`WordbookRepository` 娴ｆ粈璐熼弫鐗堝祦鎼存捁顔栭梻顔跨珶閻ｅ被鈧?
- 鐏忓棛绮屾稊鐘茬厵閸忔娊鏁弫鐗堝祦鐠侯垰绶為敍鍫ｎ唶韫囧棜绻樻惔锔衡偓浣虹矊娑旂姳绨ㄦ禒韬测偓浣割嚤閸戝搫鍟撻崗銉礆閺€鍦暠 `PracticeRepository` 閹垫寧甯撮敍灞藉櫤鐏?`AppState` 鐎佃鏆熼幑顔肩氨鐎圭偟骞囩紒鍡氬Ν閻ㄥ嫮娲挎潻鐐偓?
- 鐏忓棜鐦濋張顒€鐓欓崗鎶芥暛閺佺増宓佺捄顖氱窞閿涘牐鐦濋張?鐠囧秵娼?CRUD閵嗕焦鎮崇槐銏ｇ儲鏉烆兙鈧礁顕遍崗銉ヮ嚤閸戞亽鈧礁娆㈡潻鐔峰敶缂冾喛鐦濋張顒€濮炴潪鏂ょ礆閺€鍦暠 `WordbookRepository` 閹垫寧甯撮妴?
- 濡€虫健瀵偓閸忚櫕鏌婃晶鐐剁箥鐞涘本妞傞懕鏂垮З閿涙艾浠犻悽?`focus` 閺冩湹瀵岄崝銊ヤ粻濮濐澀绱扮拠婵撶幢閸嬫粎鏁ら幍鈧張澶夌贩鐠ф牜骞嗘晶鍐叾濡€虫健閺冭泛浠犻幘顓炶嫙閸嬫粎鏁?ambient閿涙稒浠径宥呮儙閻劍妞傞幐澶愭付闁插秴缂撻崚婵嗩潗閸栨牠鎽肩捄顖樷偓?
- 鐞涖儱鍘栧Ο鈥虫健閻╃鎻€瑰牆宕奸敍姝歅racticePage` 娑?`FocusPage` 閸︺劍膩閸ф浠犻悽銊︽鐏炴洜銇氶幁銏狀槻閹稿洤绱╅敍宀勪缉閸忓秹娈ｉ挊蹇撳弳閸欙絽鎮楁禒宥呭讲闁俺绻冮崢鍡楀蕉鐠侯垰绶炴潻娑樺弳婢惰鲸鏅ラ崝鐔诲厴閵?
- 閺傛澘顤?`app_state_provider` 楠炶泛婀惔鏃傛暏閸氼垰濮╅柧鎹愮熅閹恒儱鍙?Riverpod overrides閿涘苯鑸伴幋?`AppState` 閸欏本鐖ゅ▔銊ュ弳鏉╁洦娴仦鍌︾礄Riverpod + provider閿涘鈧?
- 妫ｆ牗澹掓い鐢告桨鐠囪褰囨潻浣盒╅崚?Riverpod閿涙瓪AppShell`閵嗕梗SettingsHomePage`閵嗕梗PracticePage`閵?
- 閺傛澘顤冮獮鑸靛复閸?`SettingsStoreRepository`閵嗕梗FocusRepository`閵嗕梗AmbientRepository`閿涘苯鐨㈢拋鍓х枂閵嗕椒绗撳▔銊ょ瑢閻滎垰顣ㄩ棅宕囨祲閸忓疇鐭惧鍕埛缂侇厺绮犻崡鏇氱秼閺佺増宓佹惔鎾存箛閸斺€茶厬閸撱儳顬囬妴?
- 閸氬本顒為弴瀛樻煀 `ui_smoke_test` 閻?`ProviderScope` 娑?provider override 閸栧懓顥婇敍宀€鈥樻穱婵婄讣缁夊妯佸▓鍨ゴ鐠囨洜菙鐎规哎鈧?
- 閺傛澘顤冮獮鑸靛复閸?`SleepRepository`閿涘潉SettingsStoreSleepRepository`閿涘绱濈亸?sleep 閸╃喐瀵旀稊鍛娴?`SettingsService` 閻╃绻涙潻浣盒╅崚棰佺波鎼存捁绔熼悾灞烩偓?
- `AppState` 閸氼垰濮╁ù浣衡柤閺傛澘顤?sleep assistant 妫板嫬濮炴潪鐣屾閸氬秴宕熼敍灞肩矌閸︺劍膩閸ф鎯庨悽銊︽閸旂姾娴?sleep 閺佺増宓侀妴?
- 閺傛澘顤冪紒鐔剁濡€虫健鐎瑰牆宕肩仦?`ui/module/module_access.dart`閿涘苯顦查悽銊δ侀崸妤冾洣閻劍鏋冨鍫滅瑢鐠侯垳鏁遍梼缁樻焽闁槒绶妴?
- 鐏忓棙膩閸ф鐣ч崡顐ｅ复閸?`StudyPage`閵嗕梗PracticePage`閵嗕梗FocusPage`閵嗕梗ToolboxPage`閵嗕梗ToolboxSleepAssistantPage`閿涘苯鑻熺憰鍡欐磰 toolbox 閸楋紕澧栭崗銉ュ經閵嗕够oothing mini player 閸忋儱褰涢妴涔竢actice 娴兼俺鐦介崗銉ュ經閵?
- 閺囧瓨鏌?`modules/` 濡€虫健閺傚洦銆傚Ο鈩冩緲閿涘苯鑻熼弬鏉款杻 `focus`/`toolbox`/`sleep` 濡€虫健閺傚洦銆傞敍灞剧焽濞ｂ偓閳ユ粎濮搁幀浣哄缁?+ 娴犳挸绨遍悪顒傜彌 + 濞夈劌鍞芥す鍗炲З + 閸氼垰浠犵€瑰牆宕奸垾婵嗘磽娴犺泛顨滈妴?
- 鐏?`VocabularySleepApp` 鏉╀胶些娑?`ConsumerWidget`閿涘苯绨查悽銊︾壌閻樿埖鈧浇顕伴崣鏍ㄦ暭娑?`ref.watch(appStateProvider)`閵?
- 鐏?`MorePage`閵嗕梗LibraryPage`閵嗕梗PlayPage` 鏉╀胶些閸?Riverpod閿涘潉ConsumerWidget/ConsumerStatefulWidget`閿涘绱濋崙蹇撶毌娑撳鎽肩捄?UI 鐎?`provider` 閻ㄥ嫮娲块幒銉ょ贩鐠ф牓鈧?
- 娣囨繃瀵旀潻浣盒╅張鐔峰蓟閺嶅牊鏁為崗銉ュ悑鐎圭櫢绱橰iverpod + provider閿涘绱濈涵顔荤箽 UI smoke 娑撳骸鍙忛柌蹇旂ゴ鐠囨洘妫ょ悰灞艰礋閸ョ偛缍婇妴?
- 鐏?`LanguageSettingsPage`閵嗕梗DataManagementPage`閵嗕梗AppearanceStudioPage`閵嗕梗WordbookManagementPage` 鏉╀胶些閸?`ConsumerWidget`閿涘瞼濮搁幀浣筋嚢閸欐牜绮烘稉鈧弨閫涜礋 `ref.watch(appStateProvider)`閵?
- 鐏?`PracticeReviewPage`閵嗕梗RecognitionSettingsPage`閵嗕梗VoiceSettingsPage` 鏉╀胶些閸?`ConsumerStatefulWidget`閿涘奔姘︽禍鎺楁懠鐠侯垯鑵戦惃鍕Ц閹浇顕伴崘娆戠埠娑撯偓閺€閫涜礋 `ref.read/watch(appStateProvider)`閵?
- 閺傛澘顤冮梼鑸殿唽鐠囧嫪鍙婄拋鏉跨秿 `record_024_闂冭埖顔岄梻銊ㄧ槑娴奸绗岄梼鑸殿唽5閸氼垰濮?md`閿涘苯鑻熼崷?`PLAN_024` 閺勫海鈥橀梼鑸殿唽 5 閸氼垰濮╅懠鍐ㄦ纯娑撳酣鈧偓閸戠儤鐖ｉ崙鍡愨偓?
- 閺傛澘顤?`PLAN_025`閿涘本妲戠涵顕€妯佸▓?5A 閻ㄥ嫭澧界悰宀冪珶閻ｅ矉绱欑捄瀹犵箖 sleep 鐎涙劙銆夐棃顫礆娑撳酣鐛欓弨鑸电垼閸戝棎鈧?
- 鐏?`play_page.dart` 閹峰棗鍨庢稉?`play_page_navigation.dart` 娑?`play_page_weather.dart` 娑撱倓閲?part 閺傚洣娆㈤敍灞煎瘜妞ょ敻娼版穱婵堟殌缂傛牗甯撻柅鏄忕帆閵?
- 鐏?`practice_page.dart` 閻ㄥ嫬銇囧▓闈涘隘閸ф鐎鍝勫毐閺佺増濯堕崚鍡楀煂 `practice_page_sections.dart`閿涘矂妾锋担搴濆瘜閺傚洣娆㈡担鎾诲櫤閸滃矁鈧箑鎮庢惔锔衡偓?
- 鐏?`online_ambient_sheet.dart` 鏉╀胶些閸?Riverpod閿涘潉ConsumerStatefulWidget + ref.read/watch(appStateProvider)`閿涘鈧?
- 鐏?`focus_lock_overlay.dart` 鏉╀胶些閸?Riverpod閿涘潉ConsumerStatefulWidget + ref.read/watch(appStateProvider)`閿涘鈧?
- 閺傛澘顤?`MaintenanceRepository`閿涘潉DatabaseMaintenanceRepository`閿涘澹欓幒銉︽殶閹诡喖绨辨潻鎰樊閼宠棄濮忛敍姝歩nit/reset/backup/restore/export-dir/dispose`閵?
- 鐏?`AppState` 娑?`app_state_startup.dart` 閻ㄥ嫭鏆熼幑顔肩氨鏉╂劗娣拫鍐暏鏉╀胶些閸?`MaintenanceRepository`閵?
- 閹碘晛鐫?`WordbookRepository` 閹恒儱褰涢獮璺虹暚閹存劖鏆熼幑顔肩氨闁倿鍘ら敍姘煀婢?`databasePath`閵嗕梗ensureSpecialWordbooks()`閵嗕梗importWordbook(...)`閵嗕梗importWordbookAsync(...)`閵?
- 鐏?`wordbook_state.dart` 閺€閫涜礋娴犲懍绶风挧?`WordbookRepository`閿涘瞼些闂勩倕顕?`AppDatabaseService` 閻ㄥ嫮娲块幒銉ょ贩鐠ф牓鈧?

### 娣囶喖顦?
- 娣囶喖顦叉径褑鐦濋張顒冧氦闁插繗鐦濋弶鈥冲棘娑撳孩鎸遍弨鐐闂冪喎鍨崣顏勫瘶閸?`word` 閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦查弮褏澧?`fieldSettings.enabled = false` 闁鏆€闁板秶鐤嗘导姘閹搭亪鍣存稊澶岀搼鐎涙顔岄幘顓熸杹閻ㄥ嫰妫舵０妯糕偓?
- 娣囶喖顦?Windows 閺堫剙婀?TTS 閸欘亝閮ㄩ悽銊ч兇缂佺喖绮拋銈咃紣缁炬寧鎸遍幎銉﹁穿閸氬牆鐡у▓闈涘敶鐎圭櫢绱濈€佃壈鍤ч柌濠佺疅缁涘鑵戦弬鍥х摟濞堢數婀呮导鍏兼弓缂佈呯敾閹绢厽鏂侀惃鍕６妫版ǜ鈧?
- 娣囶喖顦?Windows 閺堫剙婀?TTS 閸︺劌宕熺拠宥嗘尡鐎瑰苯鎮楅崡鈩冾劥閸︺劎鐡戝鍛暚閹存劗濮搁幀浣碘偓浣割嚤閼锋挳鍣存稊澶岀搼閸氬海鐢婚幘顓熸杹閸楁洖鍘撴潻鐔荤箿娑撳秴绱戞慨瀣畱闂傤噣顣介妴?
- 閺傛澘顤冮崶鐐茬秺濞村鐦敍宀冾洬閻╂牞浜ら柌蹇氱槤閺壜に夐崗銊ユ倵鎼存梻鎴风紒顓熸尡閺€楣冨櫞娑斿娈戦崷鐑樻珯閵?
- 閺傛澘顤冮崶鐐茬秺濞村鐦敍宀冾洬閻╂牠鍣告径宥嗩偧閺佹澘鍑″鈧崥顖欑稻閺冄冪摟濞堢數顩﹂悽銊︾垼鐠侀绮涚€涙ê婀弮鍓佹畱鐎涳缚绡勯幘顓熸杹閸︾儤娅欓妴?
- 閺傛澘顤冮崶鐐茬秺濞村鐦敍宀冾洬閻?Windows 閺堫剙婀?TTS 閸︺劏绻涚紒顓″閺?娑擃厽鏋冮幘顓熷Г閺冨墎娈戦懛顏勫З婢规壆鍤庨崚鍥ㄥ床娑撳骸娲栭柅鈧悰灞艰礋閵?
- 閺傛澘顤冮崶鐐茬秺濞村鐦敍宀冾洬閻?Windows 閺堫剙婀?TTS 閳ユ粌鐣幋鎰礀鐠嬪啫鍑￠崚棰佺稻 `isSpeaking` 娴犲秴宕辨担蹇娾偓?娑?閳ユ粌鐣幋鎰礀鐠嬪啰宸辨径杈ㄦ閻㈣精鐤嗙拠銏犲幑鎼存洖鐣幋鎰ㄢ偓?娑撱倗琚梼璇差敚閸︾儤娅欓妴?
- 閺傛澘顤冮崶鐐茬秺濞村鐦敍宀冾洬閻╂牕銇囩拠宥嗘拱瀵ゆ儼绻滈崝鐘烘祰閸︾儤娅欐稉瀣浕濞嗭紕鍋ｉ崙璇插涧閸旂姾娴囬妴浣侯儑娴滃本顐奸悙鐟板毊閹靛秵顒滃蹇旀尡閺€鍓ф畱閻樿埖鈧浇鐭惧鍕┾偓?
- 娣囶喖顦?`ui_smoke_test` 娑擃厼婀痪璺ㄥ箚婢у啴鐓堕惄顔肩秿閸ョ偛缍婃笟婵婄缁?catalog 閸嬪洦鏆熼幑顔衡偓浣瑰瘻闁筋喗鐓￠幍鎹愬墷瀵崬顕遍懛瀵告畱鐠囶垰銇戠拹銉ｂ偓?
- 娣囶喖顦?`app_state_startup_test` 鐎?remembered/weak tracking key 閻ㄥ嫭妫張鐔告箿閵?
- 娣囶喖顦?`app_state_init_test` 鐎?lite 鐠囧秵娼€涙顔岄梿鍡楁値鏉╁洤顔旈惃鍕＋閺傤叀鈻堥妴?
- 娣囶喖顦茬紒鍐х瘎娴兼俺鐦介崷?Windows 鏉╃偟鐢荤粵鏃堫暯閺冭泛寮芥径宥嗗ⅵ瀵偓/閸忔娊妫撮崣宥夘洯瀵湱鐛ュ鏇炲絺閻?AXTree 閺囧瓨鏌婂鍌氱埗娑撳骸宕辨い瑁も偓?
- 閺傛澘顤冮崶鐐茬秺濞村鐦敍宀冾洬閻?Windows 缂佸啩绡勬导姘崇樈缁涙棃顣介崥搴＄安鐠т即銆夐崘鍛冀妫ｅ牆宕遍懓灞肩瑝閺?`AlertDialog` 閻ㄥ嫮濮搁幀浣界熅瀵板嫨鈧?
- 娣囶喖顦茬紒鍐х瘎娴兼俺鐦介柅鎰邦暯閽€鐣屾磸閺冭埖濡哥€瑰本鏆ｇ€涙顔岄崹瀣槤閺夆€虫彥閻撗傜楠炶泛绨崚妤€瀵查敍灞筋嚤閼锋潙鍨忛幑顫瑓娑撯偓妫版ɑ妲戦弰鎯у幢妞よ法娈戦梻顕€顣介妴?
- 娣囶喖顦茬拠宥勭疅闁瀚ㄦ０妯烘躬闁挎瑨顕ら柅澶愩€嶆稉搴㈩劀绾噣鍣存稊澶婄秺娑撯偓閸栨牜顫幘鐐存閿涘奔绮涢崣顖濆厴閺勫墽銇氶垾婊冩礀缁涙梹顒滅涵顔光偓婵堟畱閸掋倝顣?閺傚洦顢嶅鍌氱埗閵?
- 閺傛澘顤冮崶鐐茬秺濞村鐦敍宀冾洬閻╂牜绮屾稊鐘烘嫹闊亜鎻╅悡褍绨叉穱婵囧瘮鏉炲鍣洪崠鏍电礉娴犮儱寮风拠宥勭疅闁瀚ㄦ０姗€鏁婄拠顖欑稊缁涙梹妞傝箛鍛淬€忛弰鍓с仛缁剧姵顒滈崣宥夘洯閻ㄥ嫮濮搁幀浣界熅瀵板嫨鈧?
- 娣囶喖顦茬紒鍐х瘎鐠囧秳绠熸０妯烘躬鏉╃偟鐢绘导姘崇樈娑擃厼寮芥径宥夊櫢瀵ゅ搫鍏遍幍浼淬€嶅Ч鐘垫畱闁插秴顦茬拋锛勭暬瀵偓闁库偓閿涘矁绻樻稉鈧銉х級閻厺绗呮稉鈧０妯哄櫙婢跺洭妯佸▓鐐光偓?
- 娣囶喖顦查柨娆擃暯閼奉亜濮╅崝鐘插弳娴犺濮熼張顑跨窗娑撳骸鍨忔０妯烘倱閺冨墎鐝垫禍澶嬪⒔鐞涘瞼娈戦梻顕€顣介敍灞肩喘閸忓牅绻氱拠浣风窗鐠囨繂鍨忔０妯荤ウ閻ｅ懏鈧佲偓?
- 娣囶喖顦插Ο鈥虫健閸忔娊妫撮崥搴℃儙閸斻劑銆夐崣顖濆厴娴犲秵瀵氶崥鎴濆嚒閸嬫粎鏁ゅΟ鈥虫健閻ㄥ嫰妫舵０姗堢礉濡€虫健閸掑洦宕查崥搴濈窗閼奉亜濮╅崶鐐衡偓鈧獮鑸靛瘮娑斿懎瀵查崚鏉垮讲閻劌鍙嗛崣锝冣偓?
- 娣囶喖顦茬€涳缚绡勫Ο鈥虫健閸忔娊妫撮崥搴濈矝閸欘垳绮￠惄纾嬫彧妞ょ敻娼扮拋鍧楁６鐎涳缚绡勭憴鍡楁禈閻ㄥ嫰妫舵０姗堢礉楠炶泛婀潻鎰攽閺冭泛鍙ч梻顓烆劅娑旂姵膩閸ф妞傛稉璇插З閸嬫粍顒涚€涳缚绡勯幘顓熸杹閵?
- 娣囶喖顦茬粋浣烘暏 `toolbox.sleep_assistant` 閸氬簼绮涢崣顖濆厴缂佈呯敾閹笛嗩攽瀹告彃鎯庨崝?sleep routine 閻ㄥ嫰妫舵０姗堢礉濡€虫健閸忔娊妫撮弮鏈电窗缁斿宓嗛崑婊勬簚閵?
- 娣囶喖顦?sleep assistant 鐎涙劙銆夐棃銏犲讲闁俺绻冮崢鍡楀蕉鐠侯垳鏁辩紒鏇＄箖濡€虫健瀵偓閸忓磭娈戦梻顕€顣介敍灞灸侀崸妤冾洣閻劌鎮楃紒鐔剁闂冪粯鏌囩捄瀹犳祮閵?
- 閺傛澘顤冮崶鐐茬秺濞村鐦敍姝歴leep_repository_test` 娑?`app_state_init_test` 娑擃厾娈?sleep assistant 閸氼垰浠犵悰灞艰礋妤犲矁鐦夐妴?
- 娣囶喖顦查棃?sleep 閼煎啫娲块崘鍛暙閻ｆ瑧娈?`provider` 閻╃顕?`AppState` 鐠侯垰绶為敍宀€绮烘稉鈧崶鐐存暪閼?Riverpod 鐠囪褰囬柧鎹愮熅閵?
- 娣囶喖顦?`AppState` 娑撳骸宸婚崣?`wordbook_state` 鐎佃鏆熼幑顔肩氨鐎圭偟骞囩紒鍡氬Ν閼帮箑鎮庢潻鍥ㄧ箒閻ㄥ嫰妫舵０姗堢礉閺€閫涜礋缂佸繋绮ㄦ惔鎾圭珶閻ｅ矁顔栭梻顔芥殶閹诡喖绨辨潻鎰樊娑撳氦鐦濋張顒€顕遍崗銉ㄥ厴閸旀稏鈧?

### 娣囶喗鏁奸敍鍫ユ▉濞?5C 鐞涖儱鍘栭敍?
- 閹稿娼?sleep 娴兼ê鍘涙い鍝勭碍鐎瑰本鍨氱亸蹇旂埗閹村繑膩閸ф銇囬弬鍥︽閹峰棗鍨庨敍姝歵oolbox_mini_games.dart` 閹峰棗鍨庢稉?5 娑?`part` 鐎涙劖鏋冩禒璁圭礄閺佹壆瀚?閹殿偊娴?閹风厧娴?娴滄柨鐡欏Λ?2048閿涘鈧?
- 娑撶粯鏋冩禒鏈电箽閻ｆ瑥鍙嗛崣锝勭瑢閸忓彉闊╃紒鎾寸€敍宀勩€夐棃銏㈤獓濡€虫健閼卞矁鐭楁潻娑楃濮濄儲绔婚弲鏉垮閿涘矂妾锋担搴″礋閺傚洣娆㈤懓锕€鎮庢稉搴ｆ樊閹躲倖鍨氶張顑锯偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒鍛粵缂佹挻鐎幏鍡楀瀻閿涘奔绗夊☉澶婂挤 sleep 鐎涙劙銆夐棃顫瑢娑撴艾濮熼柅鏄忕帆鐠囶厺绠熼妴?

### 娣囶喗鏁奸敍鍫ユ▉濞?5D 鐞涖儱鍘栭敍?
- 鐎靛綊娼?sleep 閻?`focus_page.dart` 鏉╂稖顢戠紒鎾寸€幏鍡楀瀻閿涙矮瀵岄弬鍥︽閺€鑸垫殐娑撳搫鍙嗛崣锝囩椽閹烘帊绗岄悽鐔锋嚒閸涖劍婀￠敍宀冾吀閺冭泛鐓欐稉搴′紣娴ｆ粌鐓欓幏鍡楀瀻閸?`focus_page_timer.dart`閵嗕梗focus_page_workspace.dart`閵?
- 閺傛澘顤?`_setViewState(...)` 閻樿埖鈧焦娲块弬鐗埶夐幒銉礉閺囧じ鍞幍鈺佺潔閺傝纭堕崘鍛纯閹?`setState(...)`閿涘瞼鈥樻穱婵囧閸掑棗鎮?analyze 鐟欏嫬鍨穱婵囧瘮閸忋劎璞㈤妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒宥勫紬閺嶈壈鐑︽潻?`sleep_*.dart`閿涘本婀穱顔芥暭 sleep 鐎涙劙銆夐棃銏も偓鏄忕帆閵?

### 娣囶喗鏁奸敍鍫ユ▉濞?5D 鐞涖儱鍘?缁楊兛绨╁銉礆
- 鐎?`focus_page_workspace.dart` 缂佈呯敾鏉╂稖顢戦棃?sleep 缂佹挻鐎幏鍡楀瀻閿涘奔瀵岄弬鍥︽閺€鑸垫殐娑撳搫浼愭担婊冨隘閸忋儱褰涚紓鏍ㄥ笓閵?
- 閺傛澘顤?`focus_page_workspace_todo.dart`閵嗕梗focus_page_workspace_notes.dart`閵嗕梗focus_page_workspace_editor.dart`閿涘本瀵?`todo / notes / editor` 閹峰棗鍨庡銉ょ稊閸栧搫鐤勯悳鑸偓?
- 娣囨繃瀵?Focus 瀹搞儰缍旈崠杞扮瑹閸斅ゎ嚔娑斿绗屾禍銈勭鞍濞翠胶鈻兼稉宥呭綁閿涘奔绌舵禍搴℃倵缂侇厽瀵滅€涙劕鐓欓悪顒傜彌缂佸瓨濮㈤妴?

### 娣囶喗鏁奸敍鍫ユ▉濞?5E 鐞涖儱鍘栭敍?
- 鐎?`toolbox_sound_tools/focus.dart` 鏉╂稖顢戠粭顑跨濮濄儲膩閸ф濯堕崚鍡窗閹貉冨煑缂佸嫪娆㈤妴浣虹椽閹烘帞绱潏鎴濇珤閵嗕勾egacy painter閵嗕焦鏌婇悧?painter 閸掑棛顬囨稉铏瑰缁?part 閺傚洣娆㈤妴?
- `toolbox_sound_tools.dart` 閺傛澘顤?`focus_controls.dart`閵嗕梗focus_arrangement_editor.dart`閵嗕梗focus_visualizer_legacy.dart`閵嗕梗focus_visualizer.dart` 閻?`part` 婢圭増妲戦妴?
- `focus.dart` 閺傚洣娆㈡担鎾诲櫤娴?8290 鐞涘本鏁归弫娑滃殾 3787 鐞涘矉绱濋崥搴ｇ敾閸欘垳鎴风紒顓熷閸掑棛濮搁幀浣虹椽閹烘帒鐓欓妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒宥勫紬閺嶈壈鐑︽潻?`sleep_*.dart` 鐎涙劙銆夐棃顫礉娴犲懓绻樼悰宀勬姜 sleep 閻ㄥ嫮绮ㄩ弸鍕偓褔鍣搁弸鍕┾偓?

### 娣囶喗鏁奸敍鍫ユ▉濞?5E 鐞涖儱鍘?缁楊兛绨╁銉礆
- 鐏?`toolbox_sound_tools/focus.dart` 娑?`_FocusBeatsToolState` 閻ㄥ嫯绻嶇悰宀勨偓鏄忕帆娑撳氦鍨堕崣鐗堢€鐑樻煙濞夋洘濯堕崚鍡楀煂 `focus_state_logic.dart`閵嗕梗focus_state_stage.dart` 娑撱倓閲滈弬?part 閺傚洣娆㈤妴?
- `toolbox_sound_tools.dart` 閺傛澘顤?`focus_state_logic.dart` 娑?`focus_state_stage.dart` 閻?`part` 婢圭増妲戦敍灞肩箽閹镐焦膩閸ф绱╅悽銊ョ暚閺佹番鈧?
- `focus.dart` 娴?3787 鐞涘矁绻樻稉鈧銉︽暪閺佹稑鍩?745 鐞涘矉绱濇稉缁樻瀮娴犳儼浠涢悞锔惧Ц閹礁鐡у▓鐐光偓浣烘晸閸涜棄鎳嗛張鐔剁瑢 build 閸忋儱褰涢妴?
- 閺傛澘顤?`_setViewState(...)` 娴ｆ粈璐熺猾璇插敶閻樿埖鈧焦娲块弬鐗埶夐幒銉礉濞戝牓娅庨幍鈺佺潔閸愬懐娲块幒?`setState(...)` 閻?analyze 閸涘﹨顒熼妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒宥勫紬閺嶈壈鐑︽潻?`sleep_*.dart` 鐎涙劙銆夐棃顫礉娴犲懓绻樼悰宀勬姜 sleep 閻ㄥ嫮绮ㄩ弸鍕閹峰棗鍨庨妴?

### 娣囶喗鏁奸敍鍫ユ▉濞?5F 鐞涖儱鍘?缁楊兛绨╁銉窗Toolbox Audio Bank 娴滃苯鐪伴崺鐔稿閸掑棴绱?
- 鐏?`toolbox_audio_bank.dart` 娴犲骸宕熼弬鍥︽缁変焦婀佺€圭偟骞囩紒褏鐢婚幏鍡楀瀻娑撴椽鐓堕懝?娑旀劕娅掗崺鐔剁癌鐏炲倻绮ㄩ弸鍕剁窗`loops / harp_piano / guitar_guqin / flute / strings / drums / clicks / prayer_bead / singing_bowl / woodfish / shared`閵?
- `ToolboxAudioBank` 娑撶粯鏋冩禒鑸垫暪閺佹稐璐熺紓鎾崇摠娑撳骸顕径鏍饯閹?API閿涘瞼顫嗛張澶婃値閹存劕鐤勯悳鎷岀讣缁夎鍩岄悪顒傜彌 `part` 閺傚洣娆㈤敍宀勬娴ｅ骸鎮楃紒顓犳樊閹躲倗娈戦梼鍛邦嚢娑撳孩鏁奸崝銊﹀灇閺堫兙鈧?
- `toolbox_audio_service.dart` 閸氬本顒為弬鏉款杻娴滃苯鐪?`part` 婢圭増妲戦敍宀€鈥樻穱婵嗙氨缁狙咁潌閺堝鍤遍弫鏉垮讲鐟欎焦鈧傜瑢鐠嬪啰鏁ら柧鍙ョ箽閹镐椒绔撮懛娣偓?
- 閸?`flute/strings` 閸╃喐濯堕崚鍡毸夋鎰版▉濞堢敻鍣伴悽銊ユ倱閹恒儱褰涚€圭偟骞囬柌宥呯紦閿涘奔绻氶幐浣稿棘閺佹媽绔熼悾灞烩偓浣虹处鐎涙﹢鏁拠顓濈疅娑?WAV 鏉堟挸鍤弽鐓庣础娑撳秴褰夐妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗛弽绋跨妇閻╊喗鐖ｆ稉铏圭波閺嬪嫭濯堕崚鍡曠瑢閼卞矁鐭楅弨鑸垫殐閿涙矖flute/strings` 閸╃喎娲滅悰銉╃秷鐎圭偟骞囩€涙ê婀崥顒佸妳娓氀呯矎瀵邦喖妯婂鍌烆棑闂勨晪绱濆鏌モ偓姘崇箖鐎规艾鎮?analyze 娑撳海娴夐崗铏ゴ鐠囨洩绱濆楦款唴閸氬海鐢荤悰銉ょ鏉烆喖鎯夐幇鐔锋礀瑜版帡鐛欓弨韬测偓?

### 娣囶喗鏁奸敍鍫ユ▉濞?5F 鐞涖儱鍘?缁楊兛绗佸銉窗閸氼剚鍔呴崶鐐茬秺娑撳骸鐣ㄩ崗銊ㄧ殶娴兼﹫绱?
- 鐎?`toolbox_audio_bank_flute.dart` 鏉╂稖顢戞穱婵嗙暓鐠嬪啴鐓堕敍姘叏婢跺秳瀵岄棅鍐插瘶缂佹粌绱撶敮鎼炩偓浣割杻瀵儤鐨甸崳顏勵敄瑜邦澀绗岄弨璇插毊閻剚鈧焦甯堕崚璁圭礉楠炶泛濮為崗銉ㄤ氦闁插繐閽╁鎴滅瑢鐏忕偓顔岀悰鏉垮櫤閺€璺哄經閵?
- 鐎?`toolbox_audio_bank_strings.dart`閿涘澊iolin閿涘绻樼悰灞肩箽鐎瑰牐鐨熼棅绛圭窗鐞涖儱鍘栧鎾虫珨閸斻劍鈧浇绻冨銈冣偓渚€鈪抽棅铏瑤閸忋儯鈧焦鍙冮柅鐔哥磽缁夎绗岀亸鐐唽閹貉冨煑閿涘本褰佹妯跨箾鐠愵垱鈧傜瑢閼奉亞鍔ф惔锔衡偓?
- 閸?`toolbox_audio_bank_shared.dart` 閺傛澘顤冪仦鈧柈銊ュ讲婢跺秶鏁?DSP 瀹搞儱鍙块敍鍧刜applyOnePoleLowPass`閵嗕梗_applyDcBlock`閿涘绱濇禒鍛暏娴滃孩婀版潪顔跨殶娴兼鐭惧鍕旂€规艾瀵查妴?
- 閺傛澘顤?`test/toolbox_audio_bank_regression_test.dart`閿涘矁顩惄?WAV 缂佹挻鐎崥鍫熺《閹佲偓渚€娼棃娆撶叾闂冨牆鈧鈧礁鐔▓浣冣€滈崙蹇嬧偓浣稿綁娴ｆ挸妯婂鍌欑瑢閸氬苯寮弫鎵€樼€规碍鈧佲偓?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗙拫鍐х喘娣囨繃瀵?public API 娑撳海绱︾€涙﹢鏁稉宥呭綁閿涘矂顥撻梽鈺呮肠娑擃厼婀崥顒佸妳缂佸棗浜曢崣妯哄閿涙稑鍑￠柅姘崇箖鐎规艾鎮?analyze + 閸ョ偛缍婂ù瀣槸閺€鑸垫殐閸旂喕鍏橀幀褍娲栬ぐ鎺楊棑闂勨晪绱濆楦款唴鐞涖儰绔存潪顔绘眽瀹搞儱鎯夐幇鐔肩崣閺€韬测偓?

### 娣囶喗鏁奸敍鍫ユ▉濞?5F 鐞涖儱鍘栭敍娆癝R 娑?Toolbox Audio閿?
- 鐎?`asr_service.dart` 鐎瑰本鍨氶幐澶婂閼宠棄鐓欓幏鍡楀瀻閿涙矮瀵岄弬鍥︽娴犲懍绻氶悾娆戣閸ㄥ鐣炬稊澶夌瑢閸忓彉闊╅悩鑸碘偓渚婄礉鐠囧棗鍩嗗ù浣衡柤閹峰棗鍨庨崚?`core / api / audio / offline / models` 娴滄柧閲?`part` 閺傚洣娆㈤妴?
- 鐎?`toolbox_audio_service.dart` 鐎瑰本鍨氶幐澶庝捍鐠愶絾濯堕崚鍡窗娑撶粯鏋冩禒鏈电矌娣囨繄鏆€鎼存挸锛愰弰搴礉閹绢厽鏂侀崳銊︾潨娑撳酣鐓堕懝鎻掓値閹存劘鍏橀崝娑樺瀻閸掝偉绺肩粔璇插煂 `toolbox_audio_players.dart` 娑?`toolbox_audio_bank.dart`閵?
- 濞撳懐鎮婇崡鏇熸瀮娴犺泛鐖㈤崣鐘茬础閸樺棗褰剁紒鎾寸€敍宀€绮烘稉鈧?`part of` 缂佸嫮绮愰獮鑸垫暪閺佹盯娼ら幀浣瑰灇閸涙顔栭梻顔跨熅瀵板嫸绱濇穱婵囧瘮閺冦垺婀?API 鐠囶厺绠熸稉搴ょ殶閻劍鏌熷蹇庣瑝閸欐ǜ鈧?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘稉铏圭波閺嬪嫭鈧囧櫢閺嬪嫸绱濇稉宥堢殶閺?ASR 娑撳酣鐓舵０鎴濇値閹存劗鐣诲▔鏇☆嚔娑斿绱遍崶鐐茬秺妞嬪酣娅撴稉鏄忣洣闂嗗棔鑵戦崷銊︽瀮娴犳儼绔熼悾宀冪讣缁変紮绱濆鏌モ偓姘崇箖鐎规艾鎮?analyze + 濞村鐦宀冪槈閺€鑸垫殐閵?

### 娣囶喗鏁奸敍鍫ユ▉濞?5E 鐞涖儱鍘?缁楊兛绗佸銉礆
- 鐎?`focus_state_stage.dart` 鏉╂稖顢戦懕宀冪煑閹峰棗鍨庨敍姘愁潒鐟欏鍨堕崣鐗堢€杞扮箽閻ｆ瑥婀崢鐔告瀮娴犺绱濋幒褍鍩楅崠?section 閺嬪嫬缂撴潻浣盒╅懛?`focus_state_stage_sections.dart`閵?
- `toolbox_sound_tools.dart` 閺傛澘顤?`focus_state_stage_sections.dart` 閻?`part` 婢圭増妲戦敍灞肩箽閹镐焦膩閸ф绱╅悽銊ョ暚閺佹番鈧?
- 娣囶喖顦查幏鍡楀瀻鏉╁洨鈻兼稉顓犳畱鐏忕偓顔岄幋顏呮焽閿涘苯鑻熷〒鍛倞 `_buildPrimaryControls` 閸?`return` 閸氬簼绗夐崣顖濇彧閻ㄥ嫰鍣告径宥勫敩閻礁娼￠敍鍫滅矌缂佹挻鐎〒鍛倞閿涘矁顢戞稉杞扮瑝閸欐﹫绱氶妴?

### 妞嬪酣娅撻崣妯绘纯
- 閺堫剝鐤嗘禒宥勫紬閺嶈壈鐑︽潻?`sleep_*.dart` 鐎涙劙銆夐棃顫礉娴犲懓绻樼悰宀勬姜 sleep 閻ㄥ嫮绮ㄩ弸鍕閹峰棗鍨庨妴?

### 娣囶喗鏁奸敍?026-04-20 / PLAN_041閿?
- 鐎电懓銇囬弬鍥︽閹峰棗鍨庣紒鎾寸亯閸嬫艾鐣ㄩ崗銊ょ秼濡偓閿涙矮鎱ㄦ径?`tts_service_api.dart` 閻?extension 闂堟瑦鈧焦鍨氶崨姗€妾虹€规艾绱╅悽銊╂６妫版﹫绱濋獮璺虹暚閹?`tts_service` 閸掑棗鐪伴弬鍥︽閻ㄥ嫭鐗稿蹇撳娑撳骸鐣鹃崥?analyze 妤犲矁鐦夐妴?
- 閸ョ偞绮撮幑鐔锋綎閻?`piano` 閹峰棗鍨庣紒鎾寸亯閿涘本浠径?`toolbox_sound_tools/piano.dart` 閸掓澘褰茬紓鏍槯閻樿埖鈧緤绱濋柆鍨帳缂傛牜鐖?鐎涙顑佹稉鍙夊疮閸у繒鎴风紒顓熷⒖閺侊絻鈧?
- 鐎?`toolbox_sound_tools/drum_pad.dart` 閸嬫氨顑囨稉鈧仦鍌澬掗懓锔肩窗閺傛澘顤?`drum_pad_state_logic.dart`閿涘牏濮搁幀浣风瑢闂婃娊顣堕柅鏄忕帆閿涘绗?`drum_pad_painter.dart`閿涘牆鍘滈弶鐔虹帛閸掕泛娅掗敍澶涚礉娑撶粯鏋冩禒鑸垫暪閺佹稐璐?UI 缂傛牗甯撻崗銉ュ經閵?
- 閸掔娀娅庨崢鍡楀蕉閸愭ぞ缍戦弬鍥︽ `lib/src/ui/pages/toolbox_sound_tools/drum_pad.dart.bak`閿涘牊妫ゅ鏇犳暏婢跺洣鍞ら弬鍥︽閿涘鈧?

### 妞嬪酣娅撻崣妯绘纯閿?026-04-20 / PLAN_041閿?
- 閺堫剝鐤嗛懕姘卞妽缂佹挻鐎憴锝堚偓锔跨瑢缁嬪啿鐣鹃幀褌鎱ㄦ径宥忕礉娑撳秵鏁奸崝銊ょ瑹閸斅ゎ嚔娑斿绱辩€靛湱绱惍渚€顥撻梽鈺傛瀮娴犲爼鍣伴崣鏍ф礀濠婃俺鈧矂娼紒褏鐢婚崣鐘插閺€鐟板З閵?

### 娣囶喗鏁奸敍?026-04-21 / PLAN_042閿?
- 鐎?`toolbox_soothing_music_v2_page.dart` 鏉╂稖顢戝Ο鈥虫健閸栨牗濯堕崚鍡窗
  - 閺傛澘顤?`toolbox_soothing_music_v2_playback.dart`閿涘本澹欓幒銉︽尡閺€淇扁偓浣稿瀼閺囧眰鈧焦膩瀵繐濮炴潪濮愨偓浣界カ濠ф劕濮炴潪鎴掔瑢閹绢厽鏂侀悩鑸碘偓浣圭ウ閵?
  - 閺傛澘顤?`toolbox_soothing_music_v2_stage.dart`閿涘本澹欓幒銉ㄥ灦閸欐澘灏妴浣规锤閻╊喗鐖稉搴＄俺闁劍甯堕崚璺哄隘 UI 缂佸嫬鎮庨妴?
- 閺傛澘顤?`_playbackIntent` 娑?`_playbackVisualActive` 閻樿埖鈧浇顕㈡稊澶涚礉娣囶喖顦查幘顓熸杹閹稿鎸抽崷銊ュ瀼閺囨彃濮炴潪鍊熺箖濞撯剝婀￠惃鍕▔缁€杞扮瑝娑撯偓閼锋番鈧?
- 娣囶喖顦查崚鍥ㄥ床娑撳绔撮弴鍙夋閸嬭泛褰傛稉宥囩彌閸楀疇鍤滈崝銊︽尡閺€鎾呯窗閸掑洦绨柧鎹愮熅缂佺喍绔存稉鑼额攽閸栨牭绱濋崚鍥ㄧ爱閸?`stop()`閿涘本浠径宥嗘尡閺€鎯у `seek(Duration.zero)` + `resume()`閵?
- 娴兼ê瀵查幍瀣簚缁旑垵鍨堕崣鐗堟櫏閺嬫粌褰茬憴浣光偓褝绱扮槐褍鍣剧敮鍐ㄧ湰閹绘劕宕岄悧瑙勬櫏婢х偟娉敍灞借嫙婢х偛宸辨０鎴ｆ皑 painter 閻ㄥ嫭灏熼獮鍛偓浣瑰皾鐢缚绗岄幓蹇氱珶瀵搫瀹抽妴?

### 娣囶喖顦查敍?026-04-21 / PLAN_042閿?
- 娣囶喖顦查幘顓熸杹閹稿鎸抽弰鍓с仛閻樿埖鈧椒绗岀€圭偤妾幘顓熸杹闁炬崘鐭鹃崑璺哄絺娑撳秴鎮撳銉ф畱闂傤噣顣介妴?
- 娣囶喖顦插Ο鈥崇础/閺囪尙娲伴崚鍥ㄥ床閸︾儤娅欐稉瀣殰閸斻劍鎸遍弨鐐壈閸ユ儳婀惉顒佹 stop 娴滃娆㈡稉顓☆潶鐠囶垱绔荤粚鍝勵嚤閼峰娈戦弬顓熸尡闂傤噣顣介妴?
- 娣囶喖顦查幍瀣簚缁旑垵鍨堕崣鏉垮讲鐟欏棗寮芥＃鍫ｇ箖瀵究鈧礁濮╅幀浣哥摠閸︺劍鍔呮稉宥堝喕閻ㄥ嫰妫舵０妯糕偓?

### 妞嬪酣娅撻崣妯绘纯閿?026-04-21 / PLAN_042閿?
- 閺堫剝鐤嗛弨鐟板З閼辨氨鍔嶆い鐢告桨閹峰棗鍨庢稉搴㈡尡閺€楣冩懠鐠侯垳菙鐎规碍鈧傛叏鐞涖儻绱濇稉宥嗘暭閸欐ê顕径鏍︾瑹閸斅ゎ嚔娑斿绗岄幘顓熸杹闁板秶鐤嗛幐浣风畽閸栨牕宕楃拋顔衡偓?


## [Unreleased-PLAN_221-LIFE-IMAGE-COMPRESSION-ALGORITHMS] - 2026-05-26

### 鍘熷洜
- 鐢ㄦ埛瑕佹眰鍦ㄥ浘鐗囧帇缂╁瓙妯″潡澧炲姞鏇村鍘嬬缉绠楁硶鍙€夐」锛屽苟杩芥眰鏈€澶у帇缂╂晥鐜囥€?
### 鏂板
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_compress.dart`
  - 鏂板鍘嬬缉绠楁硶閫夐」锛歚Auto best`銆乣JPEG balanced`銆乣JPEG aggressive`銆乣PNG lossless`銆乣GIF indexed`銆?  - 鏂板 `auto best` 绛栫暐锛氬悓涓€缂╂斁缁撴灉涓嬪苟琛屽€欓€夌紪鐮侊紝鑷姩閫夊彇浣撶Н鏈€灏忕粨鏋溿€?  - 鏂板绠楁硶缁撴灉淇℃伅灞曠ず锛歚Algorithm` 涓?`Encoding detail`銆?  - 瀵煎嚭缁撴灉鏂囦欢鎵╁睍鍚嶆敼涓鸿窡闅忓疄闄呯紪鐮佹牸寮忥紙`.jpg/.png/.gif`锛夈€?
### 淇敼
- `test/ui_smoke_test.dart`
  - 鎵╁睍 `life tools opens image compression controls` 鏂█锛岃鐩栨柊澧炵畻娉曢€夐」鍙鎬с€?
### 椋庨櫓鍙樻洿
- `auto best` 浼氳繘琛屽杞紪鐮侊紝瓒呭ぇ鍥惧湪浣庣璁惧鍙兘澧炲姞绛夊緟鏃堕棿銆?- `GIF indexed` 涓洪珮鍘嬬缉鏈夋崯鏂规锛?56 鑹诧級锛岀敾璐ㄦ崯澶卞彲鑳借緝鏄庢樉銆?
### 楠岃瘉
- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_compress.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_compress.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens image compression controls"`锛堣鏃犲叧鏂囦欢 `toolbox_life_tools_relatives.dart` 鐜版湁缂栬瘧閿欒闃绘柇锛?


## [Unreleased-PLAN_222-LIFE-RELATIVES-CLICK-CALCULATOR] - 2026-05-26

### 原因
- 用户要求把亲戚关系计算器改为更形象、实用、便捷的“关系点击叠加计算器”样式，不再依赖手动输入关系链。

### 新增
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_relatives.dart`
  - 新增关系按钮面板（常用称谓 token 点选叠加）。
  - 新增链路舞台（当前关系链展示）及撤销、清空、示例填充动作。
  - 新增拓扑导图展示（`CustomPainter`）：从“我”到关系链终点的可视化路径。
  - 保留计算参数：`sex`、`reverse`、`optimal`。

### 修改
- `test/ui_smoke_test.dart`
  - 用例更新为 `life tools opens relatives calculator and builds chain`。
  - 覆盖关系按钮点击、链路文本更新、计算动作与撤销动作。

### 风险变更
- 拓扑横向滚动与页面纵向滚动叠加，真机窄屏下需持续做手势回归。
- 预置按钮覆盖的是高频关系，不等于完整自然语言称谓全集。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_relatives.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_relatives.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens relatives calculator and builds chain"`
## [Unreleased-PLAN_243-LIFE-IMAGE-UPSCALE] - 2026-05-27

### 原因
- 用户要求在工具箱「生活实用」中新增一个放在「图片压缩」下面的「图片扩大」模块，用于把较小图片转成指定更大像素尺寸，并提供常见高清化/扩边补像素处理。

### 新增
- `plans/PLAN_243_生活实用图片扩大高清化模块.md`
  - 记录图片扩大子模块的目标、风险边界、移动端约束与验证项。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_upscale.dart`
  - 新增本地图片扩大页面，支持选图、按倍率放大、按目标宽高放大、画布补像素扩展、结果预览与导出。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 注册 `toolbox_life_tools_image_upscale.dart` part，并新增 `image_upscale` 工具入口，放在 `image_compress` 下方。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 将 `image_upscale` 接入生活实用工具页路由分发。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 将 `image_upscale` 映射到独立 `_ImageUpscalePage`。
- `test/ui_smoke_test.dart`
  - 新增 `life tools opens image upscale controls`，覆盖入口可达与核心控件可见。
- `modules/toolbox/README.md`
  - 补充图片扩大模块能力边界、插值算法、补像素扩展模式与导出说明。
- `PROJECT_DOMAIN.md`
  - 同步记录 `image_upscale` 子模块能力与版本索引。

### 风险变更
- 当前“图片扩大”仅执行本地插值放大与画布扩展，不是生成式 AI 超分辨率，不能凭空恢复真实缺失细节。
- 目标尺寸较大时会显著增加输出体积与内存/编码耗时；本次通过滑杆范围和错误提示做最佳努力约束。
- 模块可作为后续隐写前的图像尺寸准备工具，但本身不承担隐写写入逻辑。

### 验证
- `dart format lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_upscale.dart test/ui_smoke_test.dart`
- `dart analyze lib/src/ui/pages/toolbox_life_tools.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_upscale.dart test/ui_smoke_test.dart`
- `flutter test test/ui_smoke_test.dart --plain-name "life tools opens image upscale controls"`
## [Unreleased-PLAN_245-LIFE-IMAGE-TRANSFORM-MERGE-PERF] - 2026-05-27

### 原因
- 用户希望解决图片扩大流程中 CPU 负担明显偏高的问题，并将图片压缩与图片扩大合并为一个统一工具入口，支持双页签快速切换。

### 新增
- `plans/PLAN_245_生活实用图片压缩扩大合并与性能优化.md`
  - 记录统一图片工具收口、低 CPU 扩大路径、自定义倍率与验证项。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_transform.dart`
  - 新增统一“图片压缩/扩大”页面，内置 `Compress / Upscale` 双页签，并保持两个工作区独立切换。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 将 life tools 图片入口从 `image_compress` + `image_upscale` 收口为统一 `image_transform`。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 更新统一图片工具路由分发。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 将 utility 分发改为统一 `_ImageTransformPage`。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_compress.dart`
  - 为压缩页增加可嵌入模式，供统一页签复用。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_image_upscale.dart`
  - 为扩大页增加可嵌入模式、自定义倍率输入、`Fast duplicate` 低 CPU 算法，并将透明/纯色画布扩展切换为 `image.copyExpandCanvas` 优先路径。
- `test/ui_smoke_test.dart`
  - 将原本分离的图片压缩/扩大 smoke 用例合并为统一入口与双页签切换验证。
- `modules/toolbox/README.md`
  - 同步记录统一图片工具与扩大性能优化说明。
- `PROJECT_DOMAIN.md`
  - 同步更新 life tools 图片工具域模型说明。

### 风险变更
- `Fast duplicate` 以更低 CPU 占用优先，视觉质量会弱于 `Linear / Cubic` 等更重算法。
- 画布扩展中的 `Edge / Mirror` 仍需逐像素采样填充，大尺寸边缘补像素场景下仍可能存在耗时，但透明/纯色路径已明显减轻负担。
## [Unreleased-PLAN_252-LIFE-DEVICE-FRAME-UNIT-BMI] - 2026-05-27

### 原因
- 用户要求专注完善工具箱 - 生活实用中的 `带壳截图`、`全能单位换算`、`BMI 计算器` 三个模块；它们此前分别处于说明页或极简 demo 状态，缺少真正可用的本地工具体验。

### 新增
- `plans/PLAN_252_生活实用带壳截图单位换算BMI实现优化.md`
  - 记录三个模块的目标、实现步骤、风险边界与验证路径。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_device_frame.dart`
  - 新增 `device_frame` 独立页面，支持本地截图导入、通用手机壳样式、背景切换、状态栏覆盖和 PNG 导出。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_unit_converter.dart`
  - 新增独立单位换算页，支持长度、重量、温度、面积、体积、速度、数据、时间多类别换算，以及源值/目标值双向输入。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_bmi.dart`
  - 新增独立 BMI 页面，支持公制/英制输入、BMI 分类、健康体重区间和回到中位参考值的差量提示。
- `test/ui_smoke_test.dart`
  - 新增 life tools smoke 用例，覆盖带壳截图入口、单位换算默认链路与 BMI 分类实时变化。

### 修改
- `lib/src/ui/pages/toolbox_life_tools.dart`
  - 注册三个新页面 `part`，并清理一个未使用的 `toolbox_life_notify_service` 导入。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_hub.dart`
  - 将 `device_frame` 从占位说明页切换为真实页面路由。
- `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_utilities.dart`
  - 将 `unit_converter` 与 `bmi` 的 utility 分发改为新的独立页面实现。
- `modules/toolbox/README.md`
  - 同步三个 life tools 子模块的能力范围、导出/换算边界与移动端定位。
- `PROJECT_DOMAIN.md`
  - 同步生活实用中带壳截图、单位换算与 BMI 工具的产品边界，并更新版本记录。

### 风险变更
- `带壳截图` 当前使用 Flutter 本地绘制的通用手机壳样式，不对应真实 OEM 机模，更适合社交分享和展示卡片，而不是严格设备营销图复刻。
- `全能单位换算` 当前完全依赖本地静态单位表；温度走开尔文中间基准，数据类同时保留十进制与二进制口径，结果适合日常估算而非专业校准。
- `BMI 计算器` 使用成年人常见参考阈值，仅做自查辅助；儿童、孕期、健身增肌和特殊病史场景不应把该结果当作唯一判断。
- 当前 `flutter test test/ui_smoke_test.dart` 仍被项目内既有的 `toolbox_life_tools_text_transform.dart` 编译错误阻塞，本轮新增 smoke 已写入但无法在该阻塞修复前完成执行。
