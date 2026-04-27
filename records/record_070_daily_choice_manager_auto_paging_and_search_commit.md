# PLAN_070 记录：管理页自动分页与搜索提交边界

## 基本信息
- 日期：2026-04-27
- 仓库：`D:\workspace\vocabularySleep-app`
- 分支：`codex/daily-choice-overhaul`
- 范围：吃什么管理页内置库分页与搜索触发

## 本轮目标
- 将吃什么管理页内置库的“继续加载”逐步改为滚动接近底部自动加载。
- 保持内置库浏览继续使用 `queryBuiltInSummaries(...)` SQL 分页，不回退全量内存扫描。
- 搜索输入不在用户每次敲字时触发 SQL 查询，改为离开输入框或提交搜索时刷新。

## 已完成
- 管理页列表外层增加 `NotificationListener<ScrollNotification>`，当内置库展开且滚动余量接近底部时自动扩大分页 limit。
- 内置库分页加载下一页时保留当前已显示摘要，不因新 SQL 请求短暂清空列表。
- 移除“继续加载”按钮，底部改为轻量状态提示；加载仍通过 SQL limit 递进完成。
- 搜索框拆为 `_ManagerSearchField`，由组件生命周期持有 `TextEditingController` 与 `FocusNode`。
- 搜索框输入只更新 draft；失焦或键盘 search 提交后才 commit 到 `searchQuery` 并触发 `queryBuiltInSummaries(...)`。
- hub smoke 增加自动分页回归，并更新搜索测试，覆盖输入中不触发查询、失焦后才传入 `searchText`。

## 风险与后续
- 当前分页仍采用扩大 SQL `limit` 的递进方式，会重新取回已显示摘要；后续可改为 keyset/offset 追加列表，进一步减少传输和重建。
- 搜索仍使用 v2 search table 的 `instr`/substring 查询，不包含拼音、分词、多关键词相关性排序。
- 若后续需要更强搜索语义，应单独设计 FTS5 或倒排表，不在本轮混入。

## 验证
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_hub_smoke_test.dart`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
