# PLAN_070 自定义菜谱编辑食谱集选择记录

## 本轮范围
- 按用户补充要求，在吃什么自定义菜谱编辑器中增加“保存到食谱集”的多选入口。
- 覆盖新增自定义菜谱、编辑已有自定义菜谱、另存内置菜谱为个人菜谱三条入口。
- 保持 SQL 分页、随机、远端 v2 DB、验证包数据和导入导出格式不变。

## 实现记录
- `showDailyChoiceEditorSheet(...)` 返回 `DailyChoiceEditorResult`，同时携带保存后的 `DailyChoiceOption` 与选中的食谱集 id。
- 吃什么编辑器在收到个人食谱集列表时展示多选区；默认可带入“我喜欢的菜”或当前管理范围对应集合。
- `DailyChoiceCustomState.setOptionEatCollections(...)` 使用精确重写语义：选中的集合加入该菜，未选中的集合移除该菜。
- 管理页的新增、编辑、另存链路统一消费编辑器返回结果，保存个人菜谱后同步更新集合成员关系。

## 回归约束
- 未选择任何食谱集时，只保存为个人菜谱，不自动加入集合。
- 已在某集合中的自定义菜谱，编辑时会回显当前成员关系；取消勾选后保存即从该集合移除。
- 另存内置菜谱时默认带入“我喜欢的菜”，仍允许用户同时选择其他个人食谱集。

## 验证记录
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_editor_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_models.dart test\daily_choice_custom_state_test.dart test\daily_choice_hub_smoke_test.dart`（通过）。
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_custom_state_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart`（通过）。
- `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）。
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
