# 计划 021: 练习模块语义树卡顿修复

## 基本信息
- **创建日期**: 2026-04-13
- **状态**: 已完成
- **负责人**: Codex

## 目标
1. 定位练习模块连续答题时 Windows 桌面端反复出现 `accessibility_bridge.cc` / `ui::AXTree` 报错并伴随卡顿的根因。
2. 修复练习会话中的高频语义树抖动，降低连续答题时的无障碍树重建压力，同时保留必要的操作可达性。
3. 验证修复后不会破坏练习流程、错题本入口、任务本联动和现有 UI smoke 回归。

## 详细步骤
1. 复核 `PracticeSessionPage`、`WordCard`、练习反馈弹窗与相关状态更新路径，确认是否存在高频路由弹出/关闭或不稳定语义节点。
2. 将 Windows 练习会话中的逐题反馈从高频路由弹窗改为页内轻量反馈面板，避免连续答题时反复创建/销毁弹窗语义树。
3. 对练习卡片中纯展示型文本动画与进度展示补充稳定语义包装，避免装饰动画直接参与 AXTree 更新。
4. 运行练习相关 smoke / 状态测试，并同步更新 `changelogs/CHANGELOG.md` 与本计划执行记录。

## 风险评估
- **风险 1**: 将反馈弹窗改为页内面板后，练习交互路径可能与旧测试断言不一致。
- **缓解措施**: 优先保持原有文案与操作语义一致，只替换承载方式，并补跑练习相关 UI smoke。
- **风险 2**: 只修日志不修根因，可能仍然在自动发音、提示展开或错因选择时持续卡顿。
- **缓解措施**: 同步收紧练习卡片与进度组件的语义暴露，减少持续重建节点。
- **风险 3**: Windows 定向修复若边界判断不稳，可能影响其他平台体验。
- **缓解措施**: 将页内反馈优先限定在 Windows 桌面语义桥问题路径，其他平台保持原有弹窗行为。

## 依赖项
- `lib/src/ui/pages/practice_session_page.dart`
- `lib/src/ui/widgets/word_card.dart`
- `test/ui_smoke_test.dart`
- `changelogs/CHANGELOG.md`

## 执行结果
1. 已定位练习模块卡顿的高风险路径：`PracticeSessionPage` 在 Windows 桌面端连续答题时会反复触发逐题 `showDialog` 路由开关，叠加答题反馈内容中的 `SwitchListTile` / `FilterChip` 语义更新，容易把 `accessibility_bridge` 的 AXTree 更新打乱并放大卡顿。
2. 已将 Windows 练习会话的逐题反馈改为页内反馈卡，保留原有 `Back` / `Next word` / `Finish round` 操作语义与错题本/弱因选择逻辑，但避免每题都创建和销毁弹窗语义树。
3. 已为练习进度条补充稳定语义包装，并将单词卡标题动画改为“稳定语义标签 + 排除装饰语义”的形式，减少练习过程中的无障碍树抖动。
4. 已新增 Windows 定向 UI smoke 回归，确保练习答题后使用页内反馈卡而不是 `AlertDialog`。
5. 已完成验证：
   - `flutter test test/app_state_practice_test.dart`
   - `flutter test test/ui_smoke_test.dart`
