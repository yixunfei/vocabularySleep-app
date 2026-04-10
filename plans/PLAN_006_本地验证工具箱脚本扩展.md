# 计划 006: 本地验证工具箱脚本扩展

## 基本信息
- **创建日期**: 2026-04-09
- **状态**: 已完成
- **负责人**: Codex

## 目标
将现有的本地 analyze 验证脚本扩展为更完整的“本地验证工具箱”脚本，统一处理工作区内临时配置目录、格式检查/格式化、`dart analyze` 和 `flutter analyze` 等高频验证动作。

## 范围边界
- **包含**：
  - 扩展 `scripts/verify-local-analysis.ps1` 参数与执行流
  - 支持格式检查、应用格式化、`dart analyze`、`flutter analyze`
  - 保留工作区内临时环境目录重定向能力
  - 对脚本进行实际运行验证
- **不包含**：
  - 修改业务代码逻辑
  - 引入 CI 配置变更

## 详细步骤
1. 将现有脚本从“单一 analyze 执行器”升级为多任务本地验证工具箱。
2. 设计可读的任务参数，支持单独运行或组合运行格式与 analyze。
3. 保持 Flutter/Dart 命令解析和本地环境目录初始化逻辑不变，避免回归。
4. 使用具体文件目标执行脚本验证。
5. 更新 `CHANGELOG` 记录脚本能力扩展。

## 风险评估
- **风险 1**: 参数增多后使用方式变复杂
- **缓解措施**: 提供清晰默认值和可扫描的任务命名

- **风险 2**: 格式检查与应用格式化行为混淆
- **缓解措施**: 默认仅检查，显式使用参数才写回文件

## 依赖项
- `scripts/verify-local-analysis.ps1`
- 当前机器上的 Flutter/Dart 工具链

## 完成情况
1. 已将 `scripts/verify-local-analysis.ps1` 扩展为本地验证工具箱脚本，支持 `format-check`、`format-write`、`dart-analyze`、`flutter-analyze`、`analyze`、`all`。
2. 已保留并固化工作区内 `.tooling/` 临时配置目录重定向，显式接管 `APPDATA`、`LOCALAPPDATA`、`PUB_CACHE`、`HOME`、`USERPROFILE`。
3. 已补充 PowerShell 目标的语法校验分流，避免对 `.ps1` 文件误用 `dart format`。
4. 已完成实际验证：
   - `powershell -ExecutionPolicy Bypass -File scripts\verify-local-analysis.ps1 -Task format-check -Target scripts\verify-local-analysis.ps1`
   - `powershell -ExecutionPolicy Bypass -File scripts\verify-local-analysis.ps1 -Task all -Target lib\src\ui\pages\toolbox_soothing_music_v2_page.dart`
