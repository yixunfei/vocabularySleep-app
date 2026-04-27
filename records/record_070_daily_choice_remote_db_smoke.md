# PLAN_070 吃什么远端 DB smoke 与 v2 双写记录

## 基本信息
- **日期**: 2026-04-27
- **远端路径**: `cook_data/daily_choice_recipe_library.db`
- **本地原始数据保护**: 本轮未覆盖 `D:\vocabularySleep-resources\cook_data`。

## S3 验证结果
- `cook_data/` 前缀可列出，包含上传后的 4 个目标文件与目录占位对象。
- `cook_data/daily_choice_recipe_library.db` 可 HEAD，大小为 `47,915,008 bytes`。
- 远端 DB range 前 32 字节为 SQLite 文件头。
- 完整下载后 SQLite smoke 通过：
  - v1 summary 行数: `7,772`
  - v1 detail 行数: `7,772`
  - `library_id`: `toolbox_daily_choice_recipe_library`
  - `library_version`: `2026-04-25`
  - `schema_version`: `1`
  - `book_recipe_count`: `7,179`
  - `cook_recipe_count`: `593`
  - sample: `cook_csv_焦糖吐司布丁_air_fryer / 焦糖吐司布丁`

## v2 状态
- 当前已上传远端 DB 仍为 v1 兼容库，`daily_choice_recipes` 等 v2 表暂未存在。
- 本轮已让生成器后续导出的 SQLite 双写 v1/v2 表；下一次重新生成并上传后，远端 smoke 脚本会输出 `v2 detected: true` 及 v2 行数。
- 运行时当前仍读取 v1 summary/detail 表，避免直接破坏已上传远端库。

## 新增验证工具
- 新增 `scripts/verify_daily_choice_recipe_remote.dart`。
- 脚本只依赖纯 Dart S3 probe 与 `sqlite3`，通过 `S3_ENDPOINT`、`S3_BUCKET`、`S3_ACCESS_KEY_ID`、`S3_SECRET_ACCESS_KEY`、`S3_REGION`、`S3_USER_AGENT` 环境变量或同名命令行参数运行。
- 验证内容包括 HEAD、完整下载、v1 表计数、meta、sample detail，以及可选 v2 表计数。

## 验证命令
- `dart run scripts/verify_daily_choice_recipe_remote.dart --key cook_data/daily_choice_recipe_library.db --expected-count 7772`（通过）
- `python -X utf8` 最小数据集调用 `write_sqlite_export(...)`，验证 v1/v2 表、`排骨` canonical 与 `猪肉` family index（通过）
- `dart analyze scripts/verify_daily_choice_recipe_remote.dart lib/src/ui/pages/toolbox_daily_choice test/daily_choice_eat_catalog_test.dart test/daily_choice_eat_library_store_test.dart`（通过）
- `flutter test test/daily_choice_eat_catalog_test.dart test/daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`（通过）
