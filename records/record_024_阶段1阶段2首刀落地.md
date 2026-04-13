# 记录 024：阶段 1 / 阶段 2 首刀落地

## 时间
- 2026-04-13

## 背景
在阶段 0（基线校准）已完成后，需要继续推进 `PLAN_024` 的结构解耦目标：
- 从“入口可插拔”推进到“运行时语义可停用”。
- 从“单体 `DatabaseService` 直连状态层”推进到“仓库接口分域”。

## 动作
1. 新增仓库分层接口与数据库适配实现：
   - `lib/src/repositories/practice_repository.dart`
   - `lib/src/repositories/wordbook_repository.dart`
   - `lib/src/repositories/repositories.dart`
2. 在 `AppDependencies` 中注入仓库实现，并交由 `AppState` 使用。
3. 将练习域数据库调用迁移到 `PracticeRepository`：
   - 记忆进度缓存读写
   - 练习事件写入
   - 练习导出文件写入
4. 将词本域数据库调用迁移到 `WordbookRepository`：
   - 词本列表、词条查询、搜索与跳转
   - 词本 CRUD、导入导出与合并
   - 延迟内置词本加载与词条 hydrate
5. 模块停用语义补强：
   - 关闭 `focus` 时停止会话并清空待处理提醒。
   - 关闭所有依赖环境音的模块时停用并停止环境音运行。
   - 重新启用模块时恢复对应初始化链路。
   - 启动页若对应模块被关闭，自动回退并持久化可用启动页。
6. 直接访问守卫补充：
   - `PracticePage`、`FocusPage` 在模块被禁用时展示恢复提示。

## 结果
- `AppState` 在练习域与词本域路径上已不再直接依赖 `DatabaseService` 细节实现。
- 模块停用行为从“入口隐藏”扩展到“运行时服务联动”。
- 为后续阶段继续拆分 `settings/focus/sleep/ambient` 仓库奠定统一注入模式。

## 验证
- `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` 通过。
- `flutter test` 全量通过。
