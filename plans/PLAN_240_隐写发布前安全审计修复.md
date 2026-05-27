# 计划 240: 隐写发布前安全审计修复

## 基本信息
- **创建日期**: 2026-05-27
- **状态**: 已完成
- **负责人**: Codex

## 目标
按安全审计反馈修复发布前阻断项和高风险项：release 签名、Android 备份、恶意输入资源上限、签名语义、次数限制边界、公开指纹泄漏和 secret 生命周期。

## 详细步骤
1. Android release 构建改用独立 release keystore 配置，缺少发布签名参数时拒绝 release 构建。
2. 禁用或严格配置 Android 系统备份，排除 `life_tools/keys` 与 `life_tools/steganography`。
3. 为 crypto envelope 与图片隐写输入增加硬上限：KDF 参数、stage 数、ciphertext/base64 长度、输入文件大小和图片像素数。
4. 升级 crypto envelope 格式，移除公开 `plainSha256` 与 `keyFileSha256`，并将 keyfile 匹配交给 MAC/AEAD。
5. 收口 RSA/ECDSA 签名层 UI/文档描述，避免“来源证明”承诺。
6. 将错误次数/成功次数/公开策略头文案降级为本机当前文件清理提示。
7. 重置、切换和退出时清空所有 secret controller，避免口令残留。
8. 更新 changelog/PROJECT_DOMAIN，补充测试并运行格式化、分析和目标测试。

## 风险评估
- **风险 1**: release 构建在没有 keystore 配置时会失败。
- **缓解措施**: 这是发布安全要求；debug 构建不受影响，并在 Gradle 中提示所需属性/环境变量。
- **风险 2**: 移除公开指纹会改变未发布 envelope 格式。
- **缓解措施**: 模块未正式发布，以新格式为准；保留读取旧版本必要兼容。
- **风险 3**: 资源上限可能拒绝超大载体或极端配置。
- **缓解措施**: 上限采用移动端安全边界，错误提示明确为文件过大或参数超限。

## 依赖项
- Android Gradle 配置、Manifest 备份规则。
- `ToolboxCryptoService` 与 `ToolboxSteganographyService`。
- 生活实用隐写 UI 和现有测试。
