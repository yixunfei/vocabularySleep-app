# PLAN_070 记录：吃什么 v2 random pivot 查询

## 基本信息
- 日期：2026-04-27
- 仓库：`D:\workspace\vocabularySleep-app`
- 分支：`codex/daily-choice-overhaul`
- 范围：`DailyChoiceEatLibraryStore` v2 random pivot 查询

## 本轮目标
- 在上一轮 v2 SQL 查询基础上，新增可直接按 `random_key` pivot 抽取内置菜谱摘要的 store 能力。
- 随机抽取复用同一套筛选条件，避免分页窗口或列表展示顺序影响随机结果。
- 保持本轮边界收敛：不拆管理 UI，不改远端 DB，不把主 UI 随机面板一次性切到新路径。

## 已完成
- 新增 `DailyChoiceEatLibraryStore.pickBuiltInRandomSummary(...)`。
- v2 DB 使用 `random_key >= pivot` 查询第一条候选；若 pivot 后无候选，则回绕到候选池开头。
- random pivot 复用 `DailyChoiceEatLibraryQuery` 条件，覆盖餐段、厨具、trait、忌口、自定义忌口和 raw/canonical 食材优先。
- random pivot 忽略 `limit` / `offset`，始终基于完整候选池抽取。
- v2 筛选索引缺失或 legacy v1 库时，继续回退到内存 catalog 候选池。
- 新增测试覆盖：
  - pivot 命中当前分页窗口之外的候选，证明随机不受分页限制。
  - pivot 超过尾部后回绕到候选池开头。
  - `排骨` 食材优先下只在精确 raw/canonical 候选中抽取。

## 风险与后续
- 当前只是 store 层能力，主 UI `DailyChoiceRandomPanel` 仍使用内存候选池；下一轮可增加 UI 适配层，把内置库随机逐步切到 `pickBuiltInRandomSummary(...)`。
- legacy v1 fallback 使用候选 id 列表的取模抽取，不具备 v2 `random_key` 的稳定全局分布；这是为了保留旧库可用性。
- 管理页内置菜谱浏览仍未接入 SQL 分页查询，后续需要单独处理 sheet 状态和分页加载边界。

## 验证
- `dart analyze lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart test\daily_choice_eat_library_store_test.dart`（通过）
- `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
