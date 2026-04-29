# 计划 096: 工具箱人类测试模块

## 基本信息
- **创建日期**: 2026-04-29
- **状态**: 已完成
- **负责人**: Codex

## 目标
在当前项目工具箱模块中新增独立的“人类测试”类型，参考 `https://aring.cc/human-benchmark/dashboard/` 的测试条目组织，提供反应、记忆、视觉、手眼协调、计算、注意力等趣味测试入口与轻量本地玩法。

## 详细步骤
1. 分析 aring.cc human-benchmark 仪表盘与测试条目，收敛为本项目可维护的 Flutter 本地实现。
2. 新增 `toolbox.human_tests` 模块 ID、模块注册、模块管理文案和工具箱入口。
3. 新增人类测试 hub 页面，移动端优先展示 17 个测试卡片。
4. 为每个测试补充本地交互页：
   - 反应测试
   - 数字记忆
   - 黑猩猩测试
   - 打字测试
   - 视觉记忆
   - 瞄准测试
   - 色觉测试
   - 斯特鲁普
   - 词汇记忆
   - 序列记忆
   - 运气测试
   - 手速测试
   - 时间感知测试
   - 手眼协调测试
   - 计算能力测试
   - 动态视力测试
   - 持续注意力测试
5. 补充模块文档、主项目说明和 changelog。
6. 运行 `dart format`、定向 `dart analyze` 与相关 widget smoke 测试。

## 风险评估
- **风险 1**: 一次新增 17 个测试，单文件过大或状态耦合。
- **缓解措施**: 拆分 hub、记忆类、视觉类、动作类、认知类和共享组件文件，保持入口与玩法状态各自独立。
- **风险 2**: 外站参考项目可能存在许可证和实现差异。
- **缓解措施**: 仅参考测试条目、规则和信息结构，不复制网页源码或样式实现。
- **风险 3**: 趣味测试涉及计时和快速点击，可能与页面滚动或移动端触控冲突。
- **缓解措施**: 主测试舞台使用固定比例区域与明确按钮，快速点击类测试避免内嵌可滚动手势冲突。

## 依赖项
- `docs/toolbox_design/TOOLBOX_DESIGN_REVIEW.md`
- `docs/toolbox_design/TOOLBOX_ANIMATION_SPEC.md`
- `docs/toolbox_design/TOOLBOX_UI_STYLE_GUIDE.md`
- `lib/src/ui/pages/toolbox/toolbox_page_content.dart`
- `lib/src/core/module_system/module_id.dart`
- `lib/src/core/module_system/module_registry.dart`
