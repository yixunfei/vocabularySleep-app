# 记录 070: P1-P4 收尾推进

## 基本信息
- **日期**: 2026-04-27
- **分支**: `codex/daily-choice-overhaul`
- **范围**: 工具箱 - 每日决策 - 吃什么管理页、分页体验、计划归档和回归验证

## P1 管理页拆分
- 将 `daily_choice_manager_sheet.dart` 末尾的支撑代码拆为独立 part：
  - `daily_choice_manager_query_helpers.dart`
  - `daily_choice_manager_section_widgets.dart`
  - `daily_choice_manager_collection_io.dart`
  - `daily_choice_manager_dialogs.dart`
- 主 sheet 保留状态编排、发布/保存语义和滚动管理，section widgets、查询 helper、导入导出和确认弹窗移出主文件。
- 本轮不改变 bottom sheet 交互形态；路由级子页面仍可作为后续 UI 深化，但已先降低单文件维护压力。

## P2 分页追加
- 管理页内置菜谱浏览从“扩大 SQL limit 并重新取回前序摘要”改为 `offset + pageSize` 追加页。
- 首页请求保持 `offset=0, limit=80`；触底后请求 `offset>=80, limit=80`。
- 追加时按 id 去重合并，筛选、搜索、集合范围变化时重置分页上下文。

## P3 计划校准
- 将 PLAN_070 阶段 2、3、4、6 标记为已完成，阶段 5 标记为“已完成（首轮结构拆分）”。
- 13 项验收增加当前结论，明确：
  - store 层保留完整候选 random pivot；
  - 主 UI 停止随机优先本地锁定，以响应性优先；
  - “最近 3 个自定义忌口”和路由级拆页为后续低风险增强。

## P4 验证
- 已执行 `dart format`、定向 `dart analyze` 和 `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`。
- `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact` 通过。
- `flutter analyze` 已执行但未通过；失败项均为本轮外既有 lint，包括 `toolbox_sound_tools/harp.dart`、`toolbox_sound_tools/woodfish.dart`、`pubspec.yaml` 和历史测试文件。
- `powershell -ExecutionPolicy Bypass -File scripts\build.ps1 -Target android-apk` 通过，release APK 构建成功，输出约 168.3MB。
