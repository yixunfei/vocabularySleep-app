# 计划 241: 隐写文件选择内存与旧加密格式收口

## 基本信息
- **创建日期**: 2026-05-27
- **状态**: 已完成
- **负责人**: Codex

## 目标
收口生活实用隐写模块的文件选择内存压力和未发布旧 crypto envelope 兼容：选择媒体、keyfile 和普通文件时先检查 `PlatformFile.size`，避免移动端 `withData: true` 预读大文件；同时删除 `ToolboxCryptoService` 对 v2/v3 crypto envelope 的读取兼容。

## 详细步骤
1. 文件选择入口改为 `withReadStream`/路径优先，Web 场景才保留必要字节回退。
2. 读取前按用途检查大小上限：图片/音视频载体、普通文件、keyfile 分别使用服务层上限。
3. 使用分段流式读取将文件装入业务所需字节，避免 file_picker 插件先复制整文件到内存。
4. 移除 crypto envelope v2/v3 读取分支和公开 `plainSha256` / `keyFileSha256` 兼容逻辑。
5. 更新测试、changelog 和项目说明，运行格式化、分析和目标测试。

## 风险评估
- **风险 1**: 某些平台不提供本地路径或 read stream。
- **缓解措施**: Web 使用 file_picker 字节回退；原生平台优先 read stream，其次路径读取，仍不可用时给出明确错误。
- **风险 2**: 移除旧 crypto envelope 兼容会拒绝此前本地试验文件。
- **缓解措施**: 模块尚未正式发布，以 v4 为唯一 crypto envelope 格式；changelog 明确记录。
- **风险 3**: 服务仍需要最终业务字节参与隐写/加密。
- **缓解措施**: 本轮先消除选择阶段的额外内存副本，并在读取前拒绝超限；后续若要更大文件需另做流式加密/分块隐写格式。

## 依赖项
- `file_picker` 的 `PlatformFile.size` 与 `readStream`。
- `ToolboxCryptoService` 与 `ToolboxSteganographyService` 的公开大小上限。
- 生活实用隐写 UI 与现有 crypto/stego 测试。
