# 计划 022: 练习会话性能与判题修复

## 基本信息
- **创建日期**: 2026-04-13
- **状态**: 已完成
- **负责人**: Codex

## 目标
定位并修复练习会话在切换下一题时的明显卡顿问题，优先收敛移动端与桌面端共用的同步阻塞点；同时修复词义选择题在错误作答场景下仍可能显示为正确的判题/文案异常。

## 详细步骤
1. 梳理练习会话答题到下一题的同步路径，确认是否存在高频 JSON 序列化、数据库写入、全局状态重建或自动发音触发造成的主线程阻塞。
2. 收敛 practice dashboard 的持久化负载，避免逐题保存完整字段型快照，并补充慢路径日志用于后续复盘。
3. 优化练习页状态订阅与切题触发点，减少非必要 rebuild 与 build 阶段副作用。
4. 修复词义选择题的判题依据，确保错误选项不会因宽松归一化比较被误判为正确。
5. 运行针对性测试并更新 changelog。

## 风险评估
- **风险 1**: 练习模块依赖持久化快照恢复错题本与记忆轨道，如果快照字段裁剪过度，可能影响旧数据恢复。
- **缓解措施**: 保留恢复所需的最小身份字段与释义摘要，并兼容读取旧版富快照数据。
- **风险 2**: 调整练习页监听方式可能影响语言切换或会话内设置的即时反馈。
- **缓解措施**: 保留对 `uiLanguage` 的选择性监听，并继续通过局部状态驱动练习会话交互。
- **风险 3**: 判题规则收紧后，可能改变少量依赖宽松比较的旧体验。
- **缓解措施**: 仅对词义选择题改为按选项本身判定，保留拼写题的归一化容错。

## 依赖项
- `lib/src/state/app_state.dart`
- `lib/src/state/app_state_practice.dart`
- `lib/src/models/settings_dto.dart`
- `lib/src/ui/pages/practice_session_page.dart`
- `test/app_state_practice_test.dart`
- `test/ui_smoke_test.dart`

## 执行结果
1. 已确认练习会话切题卡顿的主要同步热点不是单一 UI 动画，而是逐题答题时 practice dashboard 的整包 JSON 落盘负载过重：`trackedEntries` 会把完整字段型词条快照一起持久化，导致每题都重复序列化大对象。
2. 已将练习追踪快照收敛为真正轻量的最小恢复集：默认仅保留 `word/id/entryUid/primaryGloss/meaning`，仅在身份兜底确有需要时保留 `rawContent`，并避免继续把完整 `fields` 带入逐题持久化。
3. 已调整练习状态解析优先级，让当前作用域/已加载词条优先覆盖练习缓存中的轻量快照，避免为了持久化优化而反向降低现有页面可展示信息。
4. 已将练习页从整页 `context.watch<AppState>()` 改为只监听 `uiLanguage`，同时把自动发音触发从 `build()` 中挪回切题准备阶段，减少练习会话中的无关 rebuild 与 build 副作用。
5. 已为练习状态写入与练习答题切题链路补充慢路径日志，后续若仍有设备出现卡顿，可直接从日志中看到 `recordPracticeAnswer` / dashboard persist / 切题准备的耗时分布。
6. 已修复词义选择题的判题依据，改为按选中的可见选项本身判断，不再使用适合拼写题的宽松归一化比较，避免“看起来答错却被判正确”的异常。
7. 已补充回归测试并完成验证：
   - `flutter test test/app_state_practice_test.dart`
   - `flutter test test/ui_smoke_test.dart`
   - `flutter test test/app_state_init_test.dart`
   - `flutter test test/app_state_startup_test.dart`
