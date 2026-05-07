# 计划 137: Toolbox 模块布局自定义与插拔

## 基本信息
- **创建日期**: 2026-05-07
- **状态**: 已完成
- **负责人**: Codex

## 目标
为工具箱首页增加模块级自定义布局能力，支持长按进入编辑、拖拽排序、从首页隐藏模块、恢复隐藏模块和重置默认布局。该能力只影响工具箱首页展示，不改变已有模块管理页的全局启停语义。

## 详细步骤
1. 新增 `ToolboxLayoutState`，持久化模块顺序与首页隐藏列表。
2. 在 `SettingsService` 和 `AppState` 中增加加载、保存、排序、隐藏、恢复、重置接口。
3. 改造 `ToolboxPage` 和工具箱卡片组件，提供编辑模式、拖拽排序、删除/恢复入口。
4. 补充持久化与 UI smoke 测试。
5. 更新 changelog 与 toolbox 模块 README。

## 风险评估
- **风险 1**: 首页隐藏与全局禁用语义混淆。
- **缓解措施**: 隐藏仅写入 toolbox layout state；全局禁用仍走 `ModuleToggleState` 和模块管理页。
- **风险 2**: 未来新增或删除 toolbox 子模块后旧布局状态失效。
- **缓解措施**: 每次渲染和保存前按当前模块 ID 归一化，过滤未知 ID 并补齐新模块。
- **风险 3**: 拖拽列表在移动端与外层滚动冲突。
- **缓解措施**: 编辑模式使用独立 `ReorderableListView.shrinkWrap`，普通模式保留原卡片网格。

## 依赖项
- `ModuleIds.toolboxModules`
- `SettingsService`
- `AppState`
- `ToolboxPage` / `ToolboxEntryCard`
