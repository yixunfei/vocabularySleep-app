# PLAN_070 记录：管理页内置库搜索下沉到 SQLite

## 基本信息
- 日期：2026-04-27
- 仓库：`D:\workspace\vocabularySleep-app`
- 分支：`codex/daily-choice-overhaul`
- 范围：吃什么管理页内置菜谱搜索、v2 store 查询入口

## 本轮目标
- 让管理页吃什么内置库在搜索词非空时继续使用 `queryBuiltInSummaries(...)`。
- 让 v2 store 通过 `daily_choice_recipe_search_text` 完成搜索过滤，避免回退到内存扫描完整内置库。
- 保持本地自定义、个人调整和非吃什么模块的现有搜索语义不变。

## 已完成
- `DailyChoiceEatLibraryQuery` 增加 `searchText` 字段。
- v2 SQL 查询在 `searchText` 非空时增加 `daily_choice_recipe_search_text` 子查询过滤，并复用同一筛选条件计算 total、分页结果和随机候选 id 池。
- legacy v1 或缺少 v2 search table 的库继续回退到内存摘要过滤，保证旧库可读。
- 管理页吃什么内置库不再因搜索词非空退回内存路径，而是把搜索词传入 `queryBuiltInSummaries(...)`。
- hub smoke fake store 同步支持 searchText，覆盖管理页搜索触发 store 查询并只展示命中项。

## 风险与后续
- 当前搜索下沉只覆盖内置库摘要搜索；本地自定义和个人调整仍走内存过滤。
- v2 search table 当前使用普通 `instr`/substring 匹配，不是 FTS5。若后续需要拼音、分词或多关键词相关性排序，应单独引入 FTS 或倒排表。
- 管理页仍是单个 bottom sheet；搜索下沉后仍需继续推进内置库浏览拆页和详情编辑懒加载。

## 验证
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
