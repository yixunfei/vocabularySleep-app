# 计划 008: opencode 多模型协作工具化

## 基本信息
- **创建日期**: 2026-04-10
- **状态**: 已完成
- **负责人**: Codex

## 目标
在仓库内固化一套可复用的外部模型协作工具，支持：
1. 通过 `opencode` 快速固定调用 `MiniMax-M2.7`
2. 将同一提示并行分发给多个模型做 fan-out 对比
3. 为 Codex 提供一份可自动触发的 SKILL，用于在“低风险、可并行、非核心业务”任务上借助外部模型辅助

## 范围边界
- **包含**：
  - 新增固定 `MiniMax-M2.7` 调用模板脚本
  - 新增多模型调度脚本与模型 profile 配置
  - 在用户技能目录创建 `opencode-orchestrator` 技能
  - 对脚本进行实际命令验证
  - 更新 `PROJECT_DOMAIN.md` 与 `CHANGELOG.md`
- **不包含**：
  - 引入第三方云端编排平台
  - 修改 Flutter 业务逻辑
  - 自动将外部模型输出直接写回业务代码

## 详细步骤
1. 梳理 `opencode` 当前可用模型 ID 与非交互命令格式。
2. 设计固定模板脚本，降低单模型调用成本。
3. 设计 profile 驱动的 fan-out 调度脚本，支持并行批次执行、结果落盘与文本提取。
4. 将“何时调用、如何控边界、如何验证输出”的策略写入独立 SKILL。
5. 执行真实测试命令并记录验证结果。
6. 更新项目文档与变更日志。

## 风险评估
- **风险 1**: 外部模型输出与仓库真实上下文不一致
- **缓解措施**: 在 SKILL 中明确要求将外部模型视为辅助意见，最终决策与代码整合仍由 Codex 本地完成

- **风险 2**: 并行调度可能将敏感信息暴露给外部模型
- **缓解措施**: 在 SKILL 中限制仅发送最小必要上下文，默认不发送无关文件、密钥或完整大段源码

- **风险 3**: `opencode` provider/model ID 未来变更导致脚本失效
- **缓解措施**: 将模型映射集中到独立 profile 配置文件，便于后续单点调整

## 依赖项
- 本机已安装且可调用的 `opencode`
- 当前可用的 `opencode` provider 与模型列表
- `C:\Users\yixun\.codex\skills` 技能目录

## 完成情况
1. 已新增 `scripts/opencode-minimax-m27.ps1`，固化 `MiniMax-M2.7` 的固定调用入口。
2. 已新增 `scripts/orchestrate-opencode-models.ps1`，支持按 profile 并行 fan-out 到多个模型并将结果落盘至 `.tmp_model_runs/`。
3. 已新增 `scripts/opencode-model-profiles.json`，集中维护推荐模型别名与实际 `provider/model` 映射。
4. 已在 `C:\Users\yixun\.codex\skills\opencode-orchestrator` 创建技能，约束何时借助外部模型、何时仍由 Codex 自主处理。
5. 已完成脚本实测，包括单模型固定模板与多模型 fan-out 调用。

## 验证记录
1. `powershell -ExecutionPolicy Bypass -File scripts\opencode-minimax-m27.ps1 "请只回复：MiniMax M2.7 模板验证成功"`
2. `powershell -ExecutionPolicy Bypass -File scripts\orchestrate-opencode-models.ps1 -Prompt "请用一句话说明你是谁，并只输出一句话。" -Profile minimax_m27,qwen3_coder_plus -Throttle 2`
