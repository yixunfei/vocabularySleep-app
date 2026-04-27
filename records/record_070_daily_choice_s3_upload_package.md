# PLAN_070 吃什么 S3 上传数据包压缩记录

## 基本信息
- **日期**: 2026-04-27
- **数据目录**: `D:\vocabularySleep-resources\cook_data_plan070_validation`
- **用途**: 上传到 S3 远端，供「每日决策 - 吃什么」首次安装远端 SQLite 菜谱库使用。

## 压缩结果
| 文件 | 当前大小 | 菜谱数 | 建议 S3 key | 说明 |
|------|----------|--------|-------------|------|
| `daily_choice_recipe_library.db` | 47,915,008 bytes | SQLite | `cook_data/daily_choice_recipe_library.db` | 运行时主入口，未做 JSON 压缩 |
| `daily_choice_recipe_library.json` | 19,614,095 bytes | 7,772 | `cook_data/daily_choice_recipe_library.json` | 已压缩 JSON，仅保留兼容或人工审计用途 |
| `daily_choice_recipe_library_summary.json` | 4,918,383 bytes | 7,772 | `cook_data/daily_choice_recipe_library_summary.json` | 已压缩 JSON，仅保留兼容或人工审计用途 |
| `recipe_library_asset.json` | 19,614,095 bytes | 7,772 | `cook_data/recipe_library_asset.json` | 已压缩 JSON，仅保留兼容或人工审计用途 |

## 运行时接入决策
- App 首次安装吃什么菜谱库时只安装远端 SQLite DB，不再从 bundled JSON、cook CSV cache 或 fallback seed 生成本地菜谱库。
- 远端 DB 下载到候选文件并校验通过后，才替换当前安装库；远端失败时已有 SQLite 库继续保留。
- 首次远端失败且无旧库时，返回错误状态并清理候选 DB、空 DB、旧 JSON cache 和旧 cook CSV cache。
- SQLite 仍必须下载到应用支持目录后查询；这里的“不保留本地”指不再保留或生成 JSON 兜底缓存，不指流式查询远端 SQLite。

## 验证
- `python -X utf8` 解析三份 JSON：均可正常解析，菜谱数均为 7,772。
- `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_library_store.dart test/daily_choice_eat_library_store_test.dart`（通过）
- `flutter test test/daily_choice_eat_library_store_test.dart --reporter compact`（通过）
