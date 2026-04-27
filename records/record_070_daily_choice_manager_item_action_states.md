# PLAN_070 记录：管理页内置菜谱逐项动作状态

## 基本信息
- 日期：2026-04-27
- 仓库：`D:\workspace\vocabularySleep-app`
- 分支：`codex/daily-choice-overhaul`
- 范围：吃什么管理页内置菜谱详情、个人调整、另存动作状态

## 本轮目标
- 为管理页 SQL 返回的内置菜谱条目增加逐项 loading / disabled / error 状态。
- 打开详情、个人调整、另存时避免重复点击导致重复 detail 读取。
- detail 读取失败时保留当前管理 sheet、搜索和分页状态，并在对应条目内显示局部错误。

## 已完成
- 管理 sheet 新增条目级异步动作状态表，按 `inspect / adjust / save_as + optionId` 跟踪忙碌状态。
- 内置菜谱详情、个人调整、另存统一经过安全动作执行器，动作进行中禁用同一条目的 detail/edit/copy 入口。
- `_ManagerTile` 增加局部状态提示块，loading 使用轻量进度指示，失败使用错误色独立反馈。
- 吃什么管理页调用详情时改为由 manager sheet 承接错误；主 UI 详情按钮仍保留 SnackBar 错误反馈。
- hub smoke 增加慢 detail 与失败 detail 回归：慢读取期间不会重复请求，失败时管理 sheet 保持打开并显示局部错误。

## 风险与后续
- 本轮仍在既有 bottom sheet 内收口交互状态，没有拆出“我的调整 / 我的自定义 / 食谱集管理 / 内置菜谱浏览”子页面。
- 集合加入/移出、隐藏/恢复仍是即时本地状态更新；后续拆页时可进一步统一操作禁用策略。
- 自动滚动分页尚未接入，本轮保持 SQL 分页和“继续加载”按钮。

## 验证
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
