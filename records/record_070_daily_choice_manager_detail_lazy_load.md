# PLAN_070 记录：管理页内置摘要详情按需加载解耦

## 基本信息
- 日期：2026-04-27
- 仓库：`D:\workspace\vocabularySleep-app`
- 分支：`codex/daily-choice-overhaul`
- 范围：吃什么管理页 SQL 内置摘要、详情/编辑按需加载

## 本轮目标
- 让管理页从 `queryBuiltInSummaries(...)` 拿到的轻量摘要可以直接进入详情、个人调整和另存流程。
- 解除详情解析对内存 `builtInOptions` 全量摘要列表的隐性依赖。
- 保持本地自定义和已有个人调整对象不重复读取远端 SQLite detail。

## 已完成
- 吃什么详情解析在对象已经带有详情、材料或步骤时继续直接使用本地对象。
- 对吃什么非自定义轻量摘要，只要本地已安装菜谱库，即通过 `DailyChoiceEatLibraryStore.loadBuiltInDetail(...)` 按需读取完整 detail。
- hub smoke 增加“内存摘要为空但管理页 SQL 返回内置摘要”的回归场景，覆盖从管理页打开详情时仍会读取 store detail。
- hub smoke 同步覆盖管理页“个人调整”动作会在打开编辑器前读取内置菜谱完整 detail。

## 风险与后续
- 本轮只解耦 detail 入口，不拆分管理 sheet；编辑 sheet 仍作为 bottom sheet 叠加打开。
- detail 读取失败仍沿用现有 SnackBar/空对象降级，后续可在管理页动作按钮上增加逐项 loading/disabled 状态。

## 验证
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
