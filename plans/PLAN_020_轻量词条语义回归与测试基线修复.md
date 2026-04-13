# 计划 020: 轻量词条语义回归与测试基线修复

## 基本信息
- **创建日期**: 2026-04-13
- **状态**: 已完成
- **负责人**: Codex

## 目标
1. 明确 `getWordsLite()` / `searchWordsLite()` 的语义边界，恢复大词本与按需加载场景所需的真正轻量查询，避免学习播放修复反向放大内存与卡顿问题。
2. 评估“导入/加载时自动过滤空字段”的收益与风险，并仅在低风险位置补强字段瘦身，避免误删有效内容。
3. 修复 `ui_smoke_test` 的假状态对象与过期引用，恢复跨模块 UI 回归基线。
4. 同步修正 `app_state_startup_test` 对 remembered key 的旧期望，保证测试与当前 practice 跟踪键语义一致。

## 详细步骤
1. 复核 `database_service.dart` 中 lite 查询、词条 hydration 和字段存储路径，确认当前性能热点与语义漂移点。
2. 将 lite 查询恢复为只取最小必要列，并继续通过 `hydrateWordEntry()` / 播放前按需补全来满足学习播放字段续播。
3. 在字段写入或导入的安全路径中检查空字段过滤是否还有遗漏，仅补充低风险瘦身逻辑，不改变非空字段语义。
4. 修复 `test/ui_smoke_test.dart` 中 `_FakeAppState` 的接口缺口、签名漂移和已废弃引用，恢复编译与回归执行。
5. 修正 `test/app_state_startup_test.dart` 的 remembered key 期望，并运行相关测试确认练习、任务本、多语言词本、学习播放之间无新增回归。
6. 更新 `changelogs/CHANGELOG.md` 与本计划执行结果。

## 风险评估
- **风险 1**: 直接回退 lite 查询可能让学习播放再次拿不到完整字段，导致续播问题回归。
- **缓解措施**: 保留并验证现有 `hydrateWordEntry()` + 播放前按需解析路径，用回归测试锁定大词本学习播放行为。
- **风险 2**: 空字段过滤若过于激进，可能误删只有媒体/标签或结构化值的字段。
- **缓解措施**: 优先依赖已有 `normalizeFieldValue` / `mergeFieldItems` 语义，只在确认低风险的位置补充过滤，不扩大规则范围。
- **风险 3**: `ui_smoke_test` 可能存在不止一个过期接口，修复过程中容易扩散为大面积测试基线调整。
- **缓解措施**: 仅对当前编译失败项逐一对齐接口与现行实现，避免顺手改动无关 UI 断言。

## 依赖项
- `lib/src/services/database_service.dart`
- `lib/src/state/app_state.dart`
- `lib/src/state/app_state_playback.dart`
- `lib/src/models/word_entry.dart`
- `test/database_service_test.dart`
- `test/ui_smoke_test.dart`
- `test/app_state_startup_test.dart`
- `changelogs/CHANGELOG.md`

## 执行结果
1. 已将 `getWordsLite()` / `searchWordsLite()` 恢复为真正 lite 语义，只读取最小必要列，并保留 `primary_gloss/meaning` 兜底，避免大词本列表加载再次携带整条字段数据。
2. 已确认学习播放仍通过 `hydrateWordEntry()` / 播放前补全路径获取完整字段，因此不接受 richer-lite 语义扩张，性能收益主要来自查询列裁剪与轻量构造恢复。
3. 已评估“导入/加载时自动过滤空字段”方案，当前未新增全局激进裁剪规则；原因是现有 `normalizeFieldValue()` / `mergeFieldItems()` 已覆盖部分空值瘦身，而继续扩大过滤范围存在误删媒体型/结构化字段的风险。
4. 已修复 `ui_smoke_test.dart` 中过期假状态对象与脆弱交互：补齐当前 `AppState` 接口、为在线环境音目录提供稳定测试样本，并改用按钮本体交互恢复跨模块 UI 回归可用性。
5. 已同步修正 `app_state_startup_test.dart` 与 `app_state_init_test.dart` 的旧期望，使 remembered/weak tracking key 与 lite 字段断言和当前实现一致。
6. 已完成回归验证：
   - `flutter test test/database_service_test.dart`
   - `flutter test test/app_state_init_test.dart`
   - `flutter test test/app_state_startup_test.dart`
   - `flutter test test/playback_service_test.dart`
   - `flutter test test/ui_smoke_test.dart`
