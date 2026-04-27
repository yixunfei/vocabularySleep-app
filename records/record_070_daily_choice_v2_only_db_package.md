# 记录 070: 每日决策吃什么 v2-only DB 上传包

## 基本信息
- **生成日期**: 2026-04-27
- **输出目录**: `D:\vocabularySleep-resources\cook_data_plan070_validation`
- **输出文件**: `daily_choice_recipe_library.db`
- **生成方式**: 使用已审计的 `daily_choice_recipe_library.json` 重写 SQLite，`sqlite_mode=v2`
- **原始数据保护**: 未覆盖 `D:\vocabularySleep-resources\cook_data`

## 文件信息
- **大小**: 142,467,072 bytes
- **SHA256**: `9B769482EEA198E233263EB41E8FA01ECAA3C058E25F68377ED8E468F62C6FFE`
- **建议 S3 key**: `cook_data/daily_choice_recipe_library.db`

## Schema 验证
- `PRAGMA integrity_check`: `ok`
- `PRAGMA user_version`: `2`
- v1 兼容表：不存在 `daily_choice_eat_recipe_summaries` / `daily_choice_eat_recipe_details`
- v2 表数量：14 张表
- v2 meta:
  - `schema_id`: `vocabulary_sleep.daily_choice.recipe_library.v2`
  - `schema_version`: `2`
  - `library_id`: `toolbox_daily_choice_recipe_library`
  - `library_version`: `2026-04-25`

## 数据计数
- `daily_choice_recipes`: 7,772
- `daily_choice_recipe_summaries`: 7,772
- `daily_choice_recipe_details`: 7,772
- `daily_choice_recipe_sets`: 2
- `daily_choice_recipe_filter_index`: 122,825
- `daily_choice_recipe_ingredient_index`: 118,882
- `daily_choice_recipe_materials`: 63,970
- `daily_choice_recipe_steps`: 23,043
- `daily_choice_recipe_search_text`: 7,772
- `book_library`: 7,179
- `cook_csv`: 593

## 审计结果
- 审计记录: `records/record_070_daily_choice_recipe_v2_only_db_audit.md`
- 审计 JSON: `records/record_070_daily_choice_recipe_v2_only_db_audit.json`
- `YunYouJun/cook recipe.csv`: 599 行，标题精确命中 599 行，未命中 0 行
- 10 个数据问题桶均为 0
- 摘要 sourceLabel/sourceUrl: 0
- 摘要 references: 0

## 运行时边界
- 本 DB 为 v2-only，不再包含当前 v1 store 直接读取的兼容表。
- 上传到 S3 后，当前 app 仍需先接入 PLAN_070 后续 v2 查询层，才能把远端安装链路切到此包。
- 远端安装策略仍应保持候选 DB 下载、schema/meta 校验通过后再替换本地 DB。
