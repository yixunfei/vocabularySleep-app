# 计划 024：模块化解耦与可插拔重构（阶段化）

## 基本信息
- **创建日期**: 2026-04-13
- **状态**: 进行中
- **负责人**: Codex

## 目标
1. 建立“模块注册 + 模块开关 + 运行时守卫”基础设施，支持入口级与访问级的功能启停。
2. 收敛重构前基线红灯（`ambient_service_test` 失败与 analyze warning），建立可持续迭代的验证基线。
3. 以低侵入方式先接入可插拔能力，再逐步推进 Riverpod 与仓库分层深改。

## 本轮范围（阶段 0 + 阶段 1 + 阶段 2 首刀）
1. **阶段 0 基线校准**
   - 修复 `test/ambient_service_test.dart` 的两个失败场景。
   - 修复 `analyze` 阻断项并将 `flutter analyze` 与 `dart analyze` 收敛到无问题。
   - 重新跑通全量 `flutter test`。
2. **阶段 1 首批基础设施**
   - 新增 `core/module_system`：
     - `ModuleId`
     - `ModuleDescriptor`
     - `ModuleRegistry`
     - `ModuleRuntimeGuard`
     - `ModuleToggleState`
   - 将模块开关持久化接入 `SettingsService`（`module_toggles_v1`）。
   - 将模块开关状态接入 `AppState` 初始化与运行时读写。
   - 将底部导航改为受模块开关驱动的可见列表。
   - 为 `Toolbox` 入口与子工具接入模块开关过滤。
   - 新增“设置中心 -> 模块管理”页面，支持用户可见启停。
   - 在启动入口接入 `ProviderScope`（Riverpod 容器），为后续状态迁移预埋。
3. **阶段 2 首刀（练习域 + 数据层拆分起步）**
   - 新增 `repositories/`：
     - `PracticeRepository`
     - `WordbookRepository`
   - 在 `AppDependencies` 中显式注入仓库实现（数据库适配层）。
   - 将练习域数据库读写从 `AppState._database` 迁移到 `PracticeRepository`：
     - 记忆进度查询/写入
     - 练习事件写入
     - 练习导出写入
   - 将词本域核心读写从 `AppState._database` 迁移到 `WordbookRepository`：
     - 词本/词条 CRUD
     - 搜索/跳转查询
     - 词本导入/导出/合并
     - 延迟内置词本加载
4. **阶段 3 语义预落地（运行时停用补强）**
   - 模块切换时新增运行时联动：
     - 关闭 `focus` 时停止专注会话并清空 pending reminder。
     - 关闭 `study+focus+toolbox` 全部入口时关闭并停止环境音服务。
     - 重新启用相关模块时按需恢复 `focus/ambient` 初始化链路。
   - 当启动页对应模块被关闭时，自动回退到可用启动页并持久化。
   - `PracticePage` / `FocusPage` 增加直接访问守卫文案，避免绕过导航时进入失效模块。

## 风险评估
- **风险 1**: 模块关闭后历史入口索引失效导致导航异常。
  - **缓解措施**: `AppShell` 采用动态 tab 列表和安全索引回退。
- **风险 2**: 测试桩未同步新接口导致 smoke test 编译失败。
  - **缓解措施**: 同步 `_FakeAppState` 的模块接口实现。
- **风险 3**: 仅做模块入口层启停，尚未完成全服务懒初始化。
  - **缓解措施**: 已补充 focus/ambient 运行时启停联动；后续继续覆盖更多服务域。
- **风险 4**: 仓库层当前是数据库适配器，尚未完成“数据库核心完全抽象”。
  - **缓解措施**: 保持接口稳定，后续把 repository 与 database core 进一步解耦。

## 验证结果（本轮）
- `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
- `flutter test` ✅

## 下一步（阶段 1 深化 / 阶段 2 起步）
1. 推进 `provider -> Riverpod` 真正迁移（先从 `AppShell / Settings / Practice` 页面读写开始）。
2. 继续拆分 `DatabaseService` 非词本域能力（settings/ambient/focus/sleep）到分域仓库。
3. 扩展“关闭模块彻底停用”到更多入口链路与后台服务初始化路径。
