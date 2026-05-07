# Record 137: Toolbox 首页自定义布局与插拔

## 日期
- 2026-05-07

## 范围
- 新增工具箱首页布局状态 `ToolboxLayoutState`。
- 新增 `SettingsService` 持久化接口。
- 新增 `AppState` 排序、隐藏、恢复和重置布局接口。
- 改造 `ToolboxPage` 支持长按进入编辑、拖拽排序、首页隐藏、恢复隐藏入口和重置默认。
- 修正本次触及的工具箱首页中文文案。
- 更新 `README.md`、`modules/toolbox/README.md` 和 `changelogs/CHANGELOG.md`。

## 关键决策
- “从首页移除”只写入工具箱首页隐藏列表，不调用 `setModuleEnabled`。
- 全局模块启停仍由模块管理页、`ModuleToggleState` 和 `ModuleRuntimeGuard` 负责。
- 布局状态只保存模块 ID，避免序列化 UI、路由或 Widget 构建函数。
- 渲染和保存前按 `ModuleIds.toolboxModules` 归一化，兼容未来新增或删除子模块。

## 验证
- `dart analyze lib/src/models/settings_dto.dart lib/src/services/settings_service.dart lib/src/state/app_state.dart lib/src/ui/pages/toolbox_page.dart lib/src/ui/pages/toolbox/toolbox_page_content.dart lib/src/ui/pages/toolbox/toolbox_page_widgets.dart test/settings_service_test.dart test/ui_smoke_test.dart`
  - 通过；仅保留 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示。
- `flutter test test/settings_service_test.dart --plain-name "toolbox layout state persists through SettingsService"`
  - 通过。
- `flutter test test/ui_smoke_test.dart --plain-name "toolbox page supports editable home layout"`
  - 通过。

## 已知风险
- `README.md` 和部分旧文档历史内容仍有编码乱码；本轮只修正和新增本次功能相关段落。
- 编辑模式当前使用单列拖拽列表，普通模式使用“我的工具箱”卡片网格；后续如需按用户自定义分组，可在 `ToolboxLayoutState` 增加分组字段。
