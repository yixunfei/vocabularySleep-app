# PLAN_070 记录：主 UI 随机与管理页内置库 SQL 接入

## 基本信息
- 日期：2026-04-27
- 仓库：`D:\workspace\vocabularySleep-app`
- 分支：`codex/daily-choice-overhaul`
- 范围：吃什么主 UI 内置库随机、管理页内置库浏览/分页

## 本轮目标
- 将主 UI 的吃什么内置库随机逐步接到 `DailyChoiceEatLibraryStore.pickBuiltInRandomSummary(...)`。
- 将管理页吃什么内置库浏览/分页接到 `DailyChoiceEatLibraryStore.queryBuiltInSummaries(...)`。
- 保持本地自定义、个人调整、隐藏/恢复和食谱集操作的现有行为稳定。

## 已完成
- `DailyChoiceRandomPanel` 新增可选异步最终抽取入口；停止随机时先锁定当前候选，再允许调用方用 store 结果替换最终选中项。
- 随机面板在候选池变化时会让仍在进行的异步最终抽取失效，避免旧筛选结果回写到新筛选候选池。
- 吃什么主 UI 在当前随机池全部为可见内置菜谱时调用 `pickBuiltInRandomSummary(...)`；如果候选池包含本地自定义或 store 无结果，则回退现有内存随机结果。
- 主 UI 调用 store random pivot 时传入当前餐段、厨具、trait、忌口、自定义忌口、已有食材优先和当前候选 id，避免抽到隐藏项或当前筛选外菜谱。
- 管理页吃什么内置库在未输入搜索词时使用 `queryBuiltInSummaries(...)` 分页读取；继续加载时只扩大 limit，不再同步筛完整内置列表。
- 管理页搜索词非空时继续走旧内存过滤路径，避免本轮在 store 查询尚未支持 search text 时破坏搜索语义。
- 管理页异步 SQL 查询在 sheet 关闭后不再调用 `setSheetState`，降低关闭/返回时的生命周期风险。
- 管理页 SQL 查询失败时记录当前查询 key，避免同一筛选条件在 build 循环中反复重试。
- hub smoke fake store 扩展了 random/query 调用记录，覆盖主 UI 停止随机触发 pivot、管理页展开内置库触发 SQL 查询，并补充候选池变化后旧异步抽取不回写的 widget 回归测试。

## 风险与后续
- 主 UI 当前只在“随机池全为内置菜谱”时使用 store pivot；混入本地自定义菜谱时仍走内存随机，避免改变自定义候选权重。
- 管理页搜索尚未下沉到 SQLite search table；后续应在 `DailyChoiceEatLibraryQuery` 增加搜索字段，并接入 `daily_choice_recipe_search_text`。
- 管理页仍是单个 bottom sheet，本轮只替换内置库浏览的数据入口；后续仍需拆成子页面/子窗口。

## 验证
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
