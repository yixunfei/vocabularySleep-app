# PLAN_070 吃什么停止随机本地落点与管理页并发分页记录

## 日期
- 2026-04-27

## 背景
- 用户继续反馈随机开始后点击停止会接近卡死，操作无响应时容易被系统视为失去响应。
- 用户反馈管理页内置菜谱滑到底部没有自动加载后续，加载仍然卡慢，要求考虑多线程并发优化。

## 本轮改动
- 吃什么主 UI 的 `DailyChoiceRandomPanel` 不再接入 `onPickRandomOption`，停止随机只锁定当前 UI 候选，不触发 `pickBuiltInRandomSummary(...)` 或任何 SQLite 查询。
- `DailyChoiceEatLibraryStore.queryBuiltInSummaries(...)` 优先通过 `Isolate.run` 在后台 isolate 重新打开 SQLite 文件执行分页/搜索查询；如果 isolate 查询失败，则回退到原同步查询路径。
- 管理页内置库自动分页从“仅依赖滚动通知”改为“滚动通知 + 下一帧位置检查”，当 SQL 结果返回后用户已经停在底部时，也能继续递增分页 limit。

## 风险与后续
- 停止随机现在完全采用 UI 随机过程中的当前候选作为最终结果；store random pivot 保留为底层能力，但不再放在停止按钮关键路径。
- `Isolate.run` 是按次查询创建后台 isolate，能避免 UI isolate 被同步 SQLite 占住，但不是长驻 worker；若后续要更接近无感滚动，应继续评估长驻查询 isolate、分页追加模型或 keyset 分页。
- 当前管理页仍按递增 limit 重新查询前 N 条；下一轮可把 SQL 分页从 limit 递增改为 offset/keyset 追加，减少重复读取。

## 验证
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_hub_smoke_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
