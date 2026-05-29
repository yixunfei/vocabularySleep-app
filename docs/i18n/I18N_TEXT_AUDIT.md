# i18n 全量文本梳理报告

- 生成日期: 2026-05-29
- 基线提交: `c38e2fee4f8b5df079d0398745fe82e9b6077ff9`
- 执行边界: 本轮只新增 i18n 资源与审计文档，未修改 Dart/Kotlin/Gradle/YAML 运行时代码。

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
