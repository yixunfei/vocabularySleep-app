# PLAN_070 每日决策文案收口与合回主分支记录

## 本轮范围
- 按用户要求对 `toolbox_daily_choice` 模块做一轮用户可见文案清理。
- 删除或改写“本轮 / 后续 / 扩展边界 / 资料来源 / source”这类偏开发说明的展示文本。
- 不改动菜谱 SQLite 分页、随机、集合、导入导出和验证包数据生成逻辑。
- 完成验证后将 `codex/daily-choice-overhaul` 合并回 `main`。

## 文案调整
- 吃什么资源面板从“资源准备 / Recipe resources”改为“菜谱库 / Recipe library”，展开说明改为用户能理解的准备与详情提示。
- 去哪儿详情和 notes 移除路线图描述，改为复制地图搜索词后的营业时间、路线和替代点检查。
- 做菜指南不再追加“参考与延伸阅读”来源模块。
- 穿什么与去哪儿指南删除扩展边界模块，避免把后续能力规划作为用户说明展示。
- 决策助手指南删除资料来源模块，首页说明去掉“本地决策资料”表述。
- 详情页隐藏所有非必要来源块，不再展示 references / sourceLabel / sourceUrl。

## 回归约束
- 新增/更新 cooking guide、place seed、wear seed、decision guide 文案断言，锁定开发说明不会重新出现在用户指南中。
- 保持 `pickUiText(...)` 双语文案路径，不新增硬编码单语 UI 入口。

## 验证记录
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_decision_assistant.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_decision_content.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_detail_sheets.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_place_seed.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_seed_data.dart test\daily_choice_cooking_guide_test.dart test\daily_choice_decision_engine_test.dart test\daily_choice_place_seed_test.dart test\daily_choice_wear_seed_test.dart`（通过）。
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_cooking_guide_test.dart test\daily_choice_decision_engine_test.dart test\daily_choice_place_seed_test.dart test\daily_choice_wear_seed_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_custom_state_test.dart`（通过）。
- `flutter test test\daily_choice_cooking_guide_test.dart test\daily_choice_decision_engine_test.dart test\daily_choice_place_seed_test.dart test\daily_choice_wear_seed_test.dart --reporter compact`（通过）。
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）。
- `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
