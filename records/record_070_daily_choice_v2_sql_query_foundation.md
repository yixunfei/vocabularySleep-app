# PLAN_070 记录：吃什么 v2 SQL 查询基础

## 基本信息
- 日期：2026-04-27
- 仓库：`D:\workspace\vocabularySleep-app`
- 分支：`codex/daily-choice-overhaul`
- 范围：`DailyChoiceEatLibraryStore` v2 索引查询基础

## 本轮目标
- 在不拆管理 UI、不改变远端 DB 包的前提下，先建立运行时可复用的 v2 SQL 查询入口。
- 查询语义对齐当前内存 `DailyChoiceEatCatalog.filter(...)`：餐段/厨具、trait 组、忌口、用户自定义忌口、已有食材优先和食谱集候选范围。
- 食材匹配默认限定 raw/canonical 索引，不启用 family 扩展，避免 `排骨` 退化为通用 `pork`。

## 已完成
- 新增 `DailyChoiceEatLibraryQuery` 和 `DailyChoiceEatLibraryQueryResult`，支持摘要分页、总数、候选随机 id 池和 `hasMore`。
- v2 DB 查询使用 `daily_choice_recipe_filter_index` 处理餐段、厨具和 trait 过滤。
- v2 DB 查询使用 `daily_choice_recipe_ingredient_index` 的 raw/canonical 层处理食材匹配和忌口排除。
- 远端 v2 表缺少筛选/食材索引时，查询入口回退到内存 catalog 过滤；legacy v1 库继续走内存 catalog fallback。
- 候选 id 查询按 `random_key` 排序并去重，避免 raw/canonical 同时命中时放大随机权重。
- 扩展 store 单测用 v2 filter/ingredient index 覆盖：
  - 汤类 + 素食 + 香菜自定义忌口只返回 `mushroom_soup`。
  - 摘要分页只返回轻量摘要，不加载详情字段。
  - `排骨` 已有食材优先只命中 `ribs`，不命中通用 `pork`。
  - `peanut_nut` 忌口同时排除花生和坚果菜谱。

## 风险与后续
- 当前 UI 仍使用内存 catalog；本轮只是建立 store 查询基础。后续可逐步把内置库浏览、分页和随机接入该查询入口。
- 已有食材优先的 SQL 版本先采用“有任一 raw/canonical 命中则收口”的基础语义，尚未完整复刻内存 catalog 的 exact/strong/broad 分层扩池策略。
- 随机 pivot 尚未接入 UI；本轮仅输出按 `random_key` 排序的完整候选 id 池，供下一步实现 pivot 抽取。

## 验证
- `dart analyze lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart test\daily_choice_eat_library_store_test.dart`（通过）
- `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
