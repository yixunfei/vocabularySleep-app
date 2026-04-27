# 记录 070: 吃什么集合入口、喜欢集合与风险字段清理

## 基本信息
- **日期**: 2026-04-27
- **分支**: `codex/daily-choice-overhaul`
- **范围**: 工具箱 - 每日决策 - 吃什么

## 本轮目标
1. 将随机前的菜谱集选择放在吃什么外层入口，避免默认从完整大库随机。
2. 将默认内置库正式命名为“内置菜谱”，不再使用“所有菜谱 / 全部菜谱”作为内置库名称。
3. 增加默认空集合“我喜欢的菜”，并把管理页内置菜谱动作改为“喜欢/加入”多选加入集合。
4. 为“不喜欢”、保存调整、加入集合和页面长列表导航补齐更明确的交互反馈。
5. 清理验证包中的起源地与饮食友好字段，避免争议性或不严谨信息进入 UI 和数据包。

## 实现记录
- `DailyChoiceCustomState` 增加 `dailyChoiceFavoriteEatCollectionId` 与默认集合“我喜欢的菜”，并在加载、保存和集合操作时通过 `withDefaultEatCollections()` 保持默认集合存在。
- 吃什么外层随机页继续展示菜谱集选择，默认全集入口文案统一为“内置菜谱”。
- 管理页“加入集合”改为“喜欢/加入”，点击后默认勾选“我喜欢的菜”，并允许多选其他个人菜谱集。
- “不喜欢”隐藏动作增加确认弹窗；保存、调整、另存和加入集合时显示处理中反馈，减少保存卡顿带来的无响应感知。
- 管理页新增右侧固定回到页首按钮，并修正搜索输入框高度略高于旁边按钮的问题。
- 吃什么 UI 移除饮食友好的辅助筛选入口；生成器不再写入 `diet` 字段，v2 schema 移除 `origin` 列。

## 验证包
- 输出目录: `D:\vocabularySleep-resources\cook_data_plan070_validation`
- DB: `daily_choice_recipe_library.db`
- DB 大小: 142,233,600 bytes
- SHA256: `418B40F934925FEB4AA1054A0A74442C2BEA063730EB727F20BE586ABD71C7B3`
- `PRAGMA user_version`: 2
- `PRAGMA integrity_check`: ok
- v2 recipes / summaries / details: 7,772 / 7,772 / 7,772
- `origin` 列: 不存在
- JSON `diet` 字段: 0
- JSON `origin` 字段: 0
- DB 高风险 diet 词: 0

## 验证
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_custom_state_test.dart`（通过）
- `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py scripts\audit_daily_choice_recipe_dataset.py`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `python -X utf8` 检查 `D:\vocabularySleep-resources\cook_data_plan070_validation`（通过）

## 风险与后续
- 当前搜索仍为 substring 查询，不引入 FTS5、拼音或倒排表；若后续需要多关键词相关性排序，应另起 schema 设计和迁移记录。
- “我喜欢的菜”当前保存在本机自定义状态中，尚未接入账户同步或跨端合并。
- 验证包已覆盖 `D:\vocabularySleep-resources\cook_data_plan070_validation`，未覆盖 `D:\vocabularySleep-resources\cook_data` 原始数据。
