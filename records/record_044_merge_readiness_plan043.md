# 记录 044：PLAN_043 分支收尾与合并准备

## 基本信息
- 日期：2026-04-21
- 分支：`codex/plan024-backup`
- 目标：完成当前分支的合并前收尾，形成可回归、可审阅、可执行的合并候选。

## 本轮已完成
1. AppState 域状态拥有权收口（第二轮）
- practice/playback 域从桥接别名访问收口为直接 store 访问。
- 移除 AppState 内 practice/playback 私有 bridge alias 代码层。
- 保持外部行为与调用语义不变（通过全量回归门禁验证）。

2. Harp 大文件分层收口
- 将设置面板重型 UI 构建从 `harp.dart` 抽离到 `harp_settings_sheet.dart`。
- 页面层保留生命周期、入口和交互触发，减少主文件复杂度。

3. 候选提交与回归
- 候选提交 1：`ef849dd`
  - `refactor: direct-store appstate ownership and split harp settings sheet`
- 全量回归：
  - 命令：`flutter.bat test --reporter compact`
  - 结果：All tests passed（含修复中间机械替换副作用后的复跑通过）。

## 关键验证结论
- 结构风险下降：
  - practice/playback 状态边界更清晰，跨域私有状态误写风险下降。
  - harp 页面主文件显著收敛，后续继续按“状态-渲染-配置”分层更容易推进。
- 行为风险可控：
  - 全量测试通过，未发现新增回归。

## 仍需关注的余项（不阻塞本次合并）
1. `app_state.dart` 仍偏大，应继续做 sleep/wordbook/export 域拥有权拆分。
2. `woodfish/zen_sand/harp` 仍有进一步收敛空间，可继续抽离 controller/store 边界与渲染层。
3. 工作区存在较多未跟踪文档文件（`plans/records/modules/.claude`），当前不影响已提交候选，但合并操作需避免 `git add .`。

## 合并建议（执行顺序）
1. 以当前提交链为基础做 PR/合并评审（建议重点评审 `ef849dd` 与 `f766204`）。
2. 合并前在 CI 或本地再跑一次全量 `flutter test` 作为最终门禁。
3. 合并完成后立刻开启下一轮 AppState 域拆分（sleep/wordbook/export），避免主干继续累积体量风险。

