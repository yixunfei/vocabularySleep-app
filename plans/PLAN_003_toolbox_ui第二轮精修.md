# 计划 003: toolbox UI 第二轮精修

## 基本信息
- **创建日期**: 2026-04-09
- **状态**: 进行中
- **负责人**: Codex

## 目标
延续 `PLAN_002` 的边界，在不改动业务逻辑、状态流和功能行为的前提下，对 `疗愈音钵` 与 `呼吸训练` 两个工具页进行第二轮 UI 精修，重点提升移动端触控体验、信息层次和代码结构可维护性。

## 范围边界
- **包含**：
  - `toolbox_singing_bowls_tool.dart` 中频率选择器、抽屉卡片和展示层样式精修
  - `toolbox_breathing_tool.dart` 与 `toolbox_breathing_ui_parts.dart` 中场景选择器、信息卡、设置卡的样式统一和组件拆分
  - 与上述 UI 精修直接相关的常量、辅助组件和命名优化
- **不包含**：
  - 音频播放逻辑、计时逻辑、阶段流转逻辑、手势处理逻辑
  - 数据持久化字段、业务判断、场景切换规则和安全提示内容

## 详细步骤
1. 依据 `docs/toolbox_design/TOOLBOX_DESIGN_REVIEW.md` 中针对疗愈音钵与呼吸训练的反馈，筛选仅属于视觉与布局层的优化项。
2. 精修疗愈音钵页面：
   - 提升频率选择器的非选中态触控宽度
   - 加入更平滑的选中态缩放和层次反馈
   - 调整移动端抽屉信息块的视觉节奏
3. 精修呼吸训练页面：
   - 重做场景选择器的视觉表达和窄屏排布
   - 抽取统一的信息卡/设置卡展示组件
   - 强化概览卡、设置卡和摘要卡之间的一致性
4. 更新 `CHANGELOG`，记录本轮仅涉及 UI 壳与结构组织的第二轮精修。

## 风险评估
- **风险 1**: 样式组件抽取时影响原有交互可点击区域
- **缓解措施**: 保持原有 `onTap/onSelected` 与状态来源不变，仅替换展示容器

- **风险 2**: 视觉强化过多导致信息密度下降
- **缓解措施**: 以移动端单手浏览为基准，只增强层次，不增加冗余装饰

- **风险 3**: 文件内局部重构引入布局回归
- **缓解措施**: 优先改造独立 widget，保持 build 链路和入参稳定

## 依赖项
- `docs/toolbox_design/TOOLBOX_DESIGN_REVIEW.md`
- `lib/src/ui/pages/toolbox_singing_bowls_tool.dart`
- `lib/src/ui/pages/toolbox_breathing_tool.dart`
- `lib/src/ui/pages/toolbox_breathing_ui_parts.dart`
