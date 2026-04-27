# PLAN_070 吃什么随机停止超时与 pivot guard 记录

## 日期
- 2026-04-27

## 背景
- 用户反馈当前关联加载菜谱卡顿，随机时点击“停止并选中”后可能长时间卡在“选中中”，且无法稳定显示选中的菜谱。
- 现有主 UI 在随机池全为内置菜谱时，会调用 `pickBuiltInRandomSummary(...)` 做最终 random pivot；当候选池很大且传入全量 `allowedOptionIds` 时，会构造大 `IN (...)` 查询并拖慢停止交互。

## 本轮改动
- `DailyChoiceRandomPanel` 为异步最终抽取增加 1200ms 超时；超时、失败或返回空结果时，保留停止瞬间锁定的当前候选并解除按钮禁用。
- `_EatChoiceModule` 在无隐藏、个人调整、食谱集约束时，不再把完整随机池 id 列表传给 store random pivot，而是直接复用当前 SQL 筛选条件。
- 当存在隐藏、个人调整或食谱集约束，且精确可见池超过 300 个 id 时，跳过 store random pivot，回退到 UI 已锁定候选，避免重 SQL 阻塞。
- 回写 store 抽取结果前校验 picked id 仍属于当前随机池；若不属于，则同样回退到 UI 锁定候选。

## 风险与后续
- 大候选池且需要精确可见池时，最终随机分布由 UI 运行时滚动候选决定，不再强制走 store `random_key` pivot；这是为了优先保证停止操作即时完成。
- 若后续要在“隐藏/个人调整/大型食谱集”场景也保留完整 SQL random pivot，应把本地 overlay 状态下沉到 SQLite 临时表或用户状态表，而不是继续拼接大 id 列表。

## 验证
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_widgets.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
