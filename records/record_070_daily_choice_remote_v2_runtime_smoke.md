# 记录 070: 每日决策吃什么远端 v2 DB 运行时读取验证

## 基本信息
- **验证日期**: 2026-04-27
- **远端 key**: `cook_data/daily_choice_recipe_library.db`
- **阶段目标**: 验证用户上传后的 S3 v2-only DB，并让运行时 store 支持 v2-only 安装、状态读取、摘要读取和详情懒加载。

## 远端 DB Smoke
- `Content-Length`: 142,467,072 bytes
- `Last-Modified`: 2026-04-27 02:54:32 UTC
- `PRAGMA user_version`: 2
- `daily_choice_recipes`: 7,772
- `daily_choice_recipe_summaries`: 7,772
- `daily_choice_recipe_details`: 7,772
- `daily_choice_recipe_sets`: 2
- `daily_choice_recipe_filter_index`: 122,825
- `daily_choice_recipe_ingredient_index`: 118,882
- `schema_id`: `vocabulary_sleep.daily_choice.recipe_library.v2`
- `schema_version`: 2
- `library_id`: `toolbox_daily_choice_recipe_library`
- `library_version`: `2026-04-25`
- 示例记录: `cook_csv_焦糖吐司布丁_air_fryer / 焦糖吐司布丁`

## 运行时改动
- `DailyChoiceEatLibraryStore` 增加 schema 自动识别：优先识别 v2 表，旧 v1 表继续保留读取能力。
- v2 安装校验不再调用 v1 `_ensureSchema()` 重建表，也不再把 `user_version=2` 误判为过新的不支持 schema。
- v2 状态读取从 `daily_choice_recipe_schema_meta`、`daily_choice_recipe_sets` 和 `daily_choice_recipes` 汇总。
- v2 摘要读取从 `daily_choice_recipes` + `daily_choice_recipe_summaries` 查询，保持详情、材料、步骤懒加载。
- v2 详情读取从 `daily_choice_recipe_details` 查询，按需恢复材料、步骤、notes、标签和 attributes。
- 安装归一化会向 v2 meta 写入 `install_source`、`installed_at`、`updated_at`、`error_message`，不破坏 v2 数据表。

## 验证命令
- `dart run scripts/verify_daily_choice_recipe_remote.dart --key cook_data/daily_choice_recipe_library.db --expected-count 7772`（通过，完整下载远端 v2-only DB）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）

## 后续边界
- 当前仍是“安装后把 SQLite 保存在应用支持目录再查询”，不是远端流式 SQL 查询。
- 随机与筛选本轮仍基于加载后的摘要集合，下一轮再把分页、筛选索引查询和 random pivot 下沉到 v2 SQL。
