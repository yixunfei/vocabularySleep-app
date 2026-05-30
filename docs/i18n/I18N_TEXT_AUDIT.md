# i18n 全量文本梳理报告

- 生成日期: 2026-05-29
- 基线提交: `c38e2fee4f8b5df079d0398745fe82e9b6077ff9`
- 执行边界: 本轮只新增 i18n 资源与审计文档，未修改 Dart/Kotlin/Gradle/YAML 运行时代码。

## 2026-05-30 运行时接入补充

- `PLAN_292_i18n_runtime_full_wiring` 已将旧 `pickUiText(...)` 入口接入 JSON catalog 运行时反查。
- 中文与英文继续以当前代码源文本为准；日语、德语、法语、西语、俄语优先读取集中 catalog，避免旧内联写法继续回退英文。
- registry 中 4076 条 `inline_pick_ui_text` 已可通过 source-pair 命中，其中 397 条动态文本通过模板匹配保留运行时变量。
- 首批直接硬编码 UI 文本已收口到本地化入口：禅沙小工具按钮、小游戏数独指标/按钮/SnackBar、生活实用外链错误提示、声音工具 Deck 快捷提示与当前乐器状态。
- 剩余 `dart_string_literal_candidate` 仍需按上下文人工判断，包含大量内容数据、资源路径、单位/乐理/数值、存储 key、日志和测试文本，不应批量强制替换。

## 2026-05-30 直接 UI literal 二次收口

- `PLAN_293_i18n_direct_ui_literal_followup` 已完成 Focus 编排编辑器的弹窗、SnackBar、输入框、按钮、模板预设、状态 chip 与节拍摘要接入。
- 追加收口声音工具 Deck 全屏快速启动 tooltip、单词行“当前/文本已隐藏”、生活实用以图搜图 Google Lens 手动降级提示和结果摘要。
- 每日抉择周边地图的定位/IP 粗略定位服务诊断已在面板展示层映射为运行时多语言；service 层英文诊断原文保留为内部状态来源。
- 本轮新增/登记 18 个运行时 key，并复查 PLAN_293 涉及的 57 个 key 在 zh/en/ja/de/fr/es/ru 中均无缺失、无占位符不一致、无 `???` 可疑文本。
- 收尾直接 UI literal 扫描仍会命中数值、温度、序号、文件名 hint、项目符号、服务诊断原文和已包含 `i18n.t(...)` 的拼接误报；这些已按非固定 UI 文案或展示层已映射候选处理。

## 2026-05-30 工具模块标题与设置项补漏

- `PLAN_294_i18n_toolbox_module_titles_settings_followup` 已针对用户点名的音钵、舒缓轻音、木鱼、舒尔特方格、呼吸训练、禅意沙盘和生活实用入口继续收口。
- 旧版舒缓轻音预设、按钮、预设区标题说明和音量文案已改为 `AppI18n.t(...)`；舒缓轻音 v2 的 `SoothingMusicCopy.text(...)` 已接入 JSON catalog，9 种模式类型、37 个曲目名、筛选/定时/错误/继续播放设置不再使用独立英文兜底。
- 木鱼 `_uiText(...)`、禅意沙盘 `_text(...)`/spec/widget、音钵 spec 与布局调用已统一通过 `pickUiText(...)` 或 catalog 反查；呼吸训练、舒尔特和生活实用 hub 的标题、说明、设置项、弹窗和动态提示 source-pair 已登记。
- 本轮新增/登记 485 个 key：woodfish 67、breathing 100、life_hub 25、zen_sand 134、singing_bowls 40、soothing semantic 11、soothing v2 108。
- 校验结果：485 个 key 七语言缺失 0、占位符不一致 0、registry missing 0、非预期英文回退 0；点名模块 479 处 helper source-pair 命中缺失 0。

## 2026-05-30 PLAN_296 单一 catalog 收口

- Life Tools 服务层新增 `ToolboxI18nTextRef` 协议，AI Interview、City Compare、Offer Select 等服务不再返回用户可见中文/英文句子，而是返回 catalog key 与参数。
- `pickUiText(...)`、`_lifeText(...)`、`_lifeCatalogPairText(...)`、`_uiText(...)`、`pickSleepText(...)`、`lookupBySourcePair(...)`、`contextLabelZh/contextLabelEn` 在 `lib/test` Dart 代码中已无残留引用。
- 本轮补齐 321 个 `life.*` runtime key，覆盖 AI Interview、City Compare、Offer Select、Work Worth、ID Photo、Compass、Date Calculator、Time Screen、Mind Map、Number Marks。
- 七语言 JSON catalog 与 registry 已同步；ja/de/fr/es/ru 通过已验证可用的本地 OpenAI-compatible API 批量生成，311 个 key 机器翻译、10 个罗盘方向/连接符/原样参数人工固定，翻译占位符回退 0。
- 校验结果：321 个 Life Tools key 七语言缺失 0、registry missing 0、占位符不一致 0；`app_i18n_catalog_test` 与相关 Life Tools 服务测试通过。

## 资源产物

- `lib/l10n/catalog/app_text_registry.json`: 全量机器可读文案总账。
- `lib/l10n/catalog/app_texts_zh.json` 至 `app_texts_ru.json`: 按语言拆分的集中替换表。
- `docs/i18n/I18N_PAGE_TEXT_COVERAGE.md`: 页面级覆盖表。

## 统计概览

| 项目 | 数量 |
| --- | ---: |
| 总条目 | 43288 |
| AppI18n 现有 key | 2062 |
| ARB 文件 | 6 |
| 扫描 Dart 文件 | 474 |
| 页面/展示层文件 | 292 |
| 页面内联 pickUiText | 3961 |
| 页面 i18n.t 引用 | 1986 |
| 页面疑似可见 literal | 19453 |

## 类型分布

- dart_string_literal_candidate: 34968
- existing_app_i18n_key: 2062
- existing_arb_key: 198
- i18n_runtime_reference: 1792
- inline_pick_ui_text: 4076
- platform_metadata_string: 192

## 可见性分布

- candidate_literal: 6959
- n/a: 8128
- platform_candidate: 192
- service_state_candidate: 4358
- technical_or_data: 10046
- ui_candidate: 13605

## 页面高密度区域

| 文件 | pickUiText | i18n.t | 疑似可见 literal | 技术/数据 literal |
| --- | ---: | ---: | ---: | ---: |
| `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_text_transform.dart` | 0 | 0 | 1045 | 111 |
| `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_data.dart` | 0 | 0 | 854 | 444 |
| `lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart` | 6 | 0 | 841 | 172 |
| `lib/src/ui/pages/toolbox_crypto_security/toolbox_crypto_security_steganography.dart` | 0 | 0 | 746 | 51 |
| `lib/src/ui/pages/toolbox_human_tests_cognition.dart` | 270 | 0 | 316 | 17 |
| `lib/src/ui/pages/toolbox_human_tests_verbal_memory_data.dart` | 0 | 0 | 569 | 266 |
| `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_data.dart` | 0 | 0 | 476 | 205 |
| `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_premodern_data.dart` | 0 | 0 | 399 | 172 |
| `lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_support.dart` | 0 | 0 | 398 | 197 |
| `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_unit_converter.dart` | 0 | 0 | 386 | 177 |
| `lib/src/ui/pages/voice_settings_page.dart` | 0 | 14 | 367 | 115 |
| `lib/src/ui/pages/toolbox_zen_sand_tool.dart` | 0 | 0 | 366 | 53 |
| `lib/src/ui/pages/toolbox_soothing_music_v2_copy.dart` | 0 | 0 | 353 | 406 |
| `lib/src/ui/pages/toolbox_daily_choice/daily_choice_food_seed.dart` | 0 | 0 | 340 | 40 |
| `lib/src/ui/pages/toolbox_human_tests_bimanual.dart` | 241 | 0 | 85 | 16 |
| `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_modern_data.dart` | 0 | 0 | 322 | 139 |
| `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_reverse_image.dart` | 0 | 0 | 316 | 242 |
| `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_offer_select.dart` | 0 | 0 | 281 | 34 |
| `lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_module.dart` | 47 | 0 | 232 | 58 |
| `lib/src/ui/pages/toolbox_human_tests_auditory_lab.dart` | 151 | 0 | 124 | 87 |
| `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_qr.dart` | 0 | 0 | 268 | 22 |
| `lib/src/ui/ui_copy.dart` | 35 | 37 | 194 | 25 |
| `lib/src/ui/pages/toolbox_human_tests_visual_memory.dart` | 46 | 0 | 208 | 1 |
| `lib/src/ui/pages/toolbox_human_tests_auditory.dart` | 98 | 0 | 154 | 74 |
| `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_relatives.dart` | 0 | 0 | 239 | 22 |
| `lib/src/ui/pages/toolbox_daily_choice/daily_choice_cook_service.dart` | 0 | 0 | 212 | 28 |
| `lib/src/ui/pages/toolbox_mind_tools_schulte.dart` | 0 | 0 | 211 | 12 |
| `lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_city_compare.dart` | 0 | 0 | 209 | 20 |
| `lib/src/ui/pages/toolbox_life_tools.dart` | 0 | 0 | 207 | 136 |
| `lib/src/ui/pages/toolbox_sound_tools/woodfish.dart` | 0 | 0 | 201 | 9 |

## 后续接入建议

1. 先复用 `existing_app_i18n_key` 和 `matchesExistingKeys`，避免重复造 key。
2. 对 `inline_pick_ui_text` 按页面分批迁移到 `AppI18n.t`，每批只动一个模块，降低视觉回归范围。
3. 对 `dart_string_literal_candidate` 先看 `visibility` 和上下文，确认确实用户可见后再迁移。
4. 若后续决定切换 Flutter gen-l10n，可将 registry 转换为 ARB；当前项目运行时仍以自定义 `AppI18n` 为主。

## 风险说明

- 服务、状态和数据层字符串中混有存储 key、SQL、资源路径、日志与调试文本，本轮保留为候选，不直接判定为 UI 文案。
- 大型词典、每日抉择数据集、测试断言和第三方依赖未纳入 UI 文案迁移范围；它们属于内容/测试/外部包资源。
