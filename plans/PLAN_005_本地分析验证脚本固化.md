# 计划 005: 本地分析验证脚本固化

## 基本信息
- **创建日期**: 2026-04-09
- **状态**: 进行中
- **负责人**: Codex

## 目标
将“工作区内临时 Dart/Flutter 配置目录 + analyze 验证”的做法整理为仓库内可复用的本地 PowerShell 脚本，方便后续在当前机器环境下稳定执行 `dart analyze` 与 `flutter analyze`。

## 范围边界
- **包含**：
  - 在 `scripts/` 下新增本地验证脚本
  - 将 `APPDATA`、`LOCALAPPDATA`、`PUB_CACHE`、`HOME`、`USERPROFILE` 显式重定向到工作区内临时目录
  - 支持运行 `dart analyze`、`flutter analyze` 或两者一起运行
  - 对脚本进行一次实际验证
- **不包含**：
  - 修改 Flutter/Dart 安装目录
  - 修改业务代码逻辑

## 详细步骤
1. 审查现有 `scripts/*.ps1` 风格，保持脚本参数、错误处理和路径解析方式一致。
2. 新增本地分析验证脚本，封装工作区内临时环境目录创建与环境变量重定向逻辑。
3. 提供可选参数以便只跑 `dart analyze`、只跑 `flutter analyze` 或两者一起执行。
4. 用当前已验证过的 UI 文件执行脚本，确认结果可复现。
5. 更新 `CHANGELOG` 记录本轮脚本固化。

## 风险评估
- **风险 1**: 脚本依赖本机 Flutter/Dart 安装路径，跨机器兼容性不足
- **缓解措施**: 优先通过 `Get-Command` 和 Flutter 自带 Dart SDK 自动解析路径，减少硬编码

- **风险 2**: 临时目录长期积累缓存文件
- **缓解措施**: 将所有临时目录集中到工作区统一前缀下，便于后续手动清理或脚本扩展清理参数

## 依赖项
- `scripts/`
- 当前机器上的 Flutter/Dart 工具链
