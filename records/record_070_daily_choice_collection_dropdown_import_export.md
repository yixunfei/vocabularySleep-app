# 记录 070: 食谱集下拉选择与导入导出

## 基本信息
- **日期**: 2026-04-27
- **分支**: `codex/daily-choice-overhaul`
- **范围**: 工具箱 - 每日决策 - 吃什么管理页

## 背景
用户反馈管理页“我的食谱集”区域同时有集合 chip 和集合卡片，选择入口重复，尤其在移动端会显得拥挤且难以判断当前生效范围。同时希望个人食谱集可以导入/导出，便于用户分享自己的菜谱集合和“独门绝技”。

## 实现
- 将“我的食谱集”的当前范围选择收敛为单个 `DropdownButtonFormField`。
- 下拉选项包含“内置菜谱”和所有个人食谱集，选中后继续影响管理页浏览/筛选范围。
- 下拉框旁提供重命名和删除按钮；默认“我喜欢的菜”集合保持保护，不允许重命名或删除。
- 删除个人食谱集时仍只删除集合关系，不删除集合里的本地自定义菜谱或内置菜谱。
- 增加“导出当前”按钮，导出当前个人食谱集为 JSON 分享包，并让用户选择保存位置。
- 增加“导入分享包”按钮，从用户选择的 JSON 文件导入食谱集。

## 分享包格式
- `format`: `vocabulary_sleep_daily_choice_eat_collection`
- `formatVersion`: `1`
- `collections`: 食谱集元数据和成员 id。
- `customOptions`: 集合内本地自定义菜谱完整数据。
- `adjustedBuiltInOptions`: 集合内个人调整过的内置菜谱数据。
- 内置菜谱只通过 id 引用，导入端继续依赖本地/远端内置菜谱库提供详情。
- 导入端会校验 `format` 与 `formatVersion`，避免未来格式升级后被旧逻辑误读。

## 合并策略
- 导入时为食谱集生成新的集合 id，避免覆盖用户已有集合。
- 导入的本地自定义菜谱若 id 与本机已有自定义菜谱冲突，会生成新的自定义 id 并同步重映射集合成员。
- 个人调整菜谱按内置菜谱 id 合并；同一内置菜谱只能保留一份个人调整。
- 如果文件选择器未返回可读取内容，导入会显示失败提示，而不是静默返回。

## 验证
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_widgets.dart`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_custom_state_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）

## 风险
- 当前导入/导出仅覆盖本地自定义状态和内置菜谱 id 引用，不复制内置 SQLite 菜谱库。
- 分享包格式为 v1 JSON，后续如果加入图片、附件或云同步，需要单独提升格式版本。
- `file_picker` 的保存/读取对不同平台的系统文件选择器表现可能略有差异；当前先保持 JSON 文件方式，避免引入账号同步或云端分享复杂度。
