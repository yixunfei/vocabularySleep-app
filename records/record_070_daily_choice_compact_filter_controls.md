# 记录 070: 筛选项紧凑展示与展开入口增强

## 基本信息
- **日期**: 2026-04-27
- **分支**: `codex/daily-choice-overhaul`
- **范围**: 工具箱 - 每日决策筛选控件与管理页折叠区

## 背景
筛选项在移动端容易因为文字标签过多而换成多行，影响首屏密度和快速扫视。用户希望未选中项尽量只显示简单图标，选中项再显示选项名；同时可展开区域需要更明显的展开入口。

## 实现
- `ToolboxSelectablePill` 新增隐藏标签能力：未选中时可以只显示图标，选中时继续显示图标和名称。
- 图标化筛选项保留 tooltip 和语义标签，避免文字隐藏后完全不可识别。
- `DailyChoiceCategorySelector` 支持紧凑模式，并接入吃什么、穿什么、去哪儿、干什么以及管理页分类/场景筛选。
- 吃什么高级筛选和管理页 trait 筛选改为未选中显示图标、选中显示名称。
- 吃什么资源准备、高级设置和管理页折叠分区的展开/收起入口增加浅色背景、边框和 accent 色提示。

## 边界
- 本轮只调整展示密度和可点击视觉提示，不改变筛选状态、搜索触发、SQL 分页或随机逻辑。
- 菜谱集选择仍保留文字标签，避免多个个人集合使用相同图标时变得难以区分。

## 验证
- `dart format lib\src\ui\pages\toolbox\toolbox_ui_components.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_widgets.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_modules.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_wear_module.dart`（通过）
- `dart analyze lib\src\ui\pages\toolbox\toolbox_ui_components.dart lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_custom_state_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
