# 计划 449：v1.0.1 文档、分支整理与发布

## 基本信息
- 创建日期：2026-09-15
- 状态：进行中（已合并、推送，Release 产物上传中）
- 负责人：Codex
- 用户已确认：v1.0.1+2；Android ARM64 / ARMv7 APK、AAB 与 Windows ZIP；提交当前工作区、合并 main、推送远端并发布 GitHub Release。
- 用户已批准新 Android 证书，接受备份后卸载重装。

## 目标与步骤
1. 核对当前分支代码和验证记录，保留用户现有工作。
2. 基于模块注册表、平台入口与实际构建重写 README，同步版本和项目说明。
3. 按代码修复、文档与发布工程分批提交，排除凭据、缓存和临时工具。
4. 验证测试、静态分析、i18n、签名和产物完整性。
5. 合并 main，推送 v1.0.1 标签，上传产物和 SHA256SUMS.txt，发布 Release。

## 风险与边界
- 原签名密码未能恢复；原 JKS 保留。新配置、JKS 与备份仅在本机，均不进入 Git。
- 新证书 SHA256：1e86ad982cd3e0a1a9662f382d4bace1348dc90c488eecf138a135bc7865bf6b。
- 旧证书 SHA256：828f1b5f621787444ecc47b688850333af0841b5a8a11a1e1854b88e8f759808。
- README / changelog / Release 说明 Android 不能覆盖升级，卸载前必须备份。
- 默认 S3 使用已获用户批准的内置只读凭据与 SigV4，用户无需环境变量。
- Web 是受限入口，数据仅在会话内存，ASR unavailable，不作为完整应用发行。
- 不清理既有 info lint / catalog 历史债务，不重构无关 UI。
- 保留临时菜谱脚本于 dist/local-work；不运行它。新出现的 tool/list_s3_wordbooks.dart 不纳入发布提交。

## 完成记录
- 代码修复独立提交：ab924baf；S3 默认鉴权提交：08557a5b。
- README 已按当前功能重写，加入 Windows 工具箱实机截图；PROJECT_DOMAIN / pubspec 同步 1.0.1+2。
- Windows runner 和 file_picker Windows 源文件恢复版本控制；MSVC /utf-8 修复中文标题。
- Android FJS bindgen 显式使用当前 NDK 标准头文件；构建脚本对最终归档执行必需原生库检查，避免假成功。
- 原生库缺失的第一批产物已被成功重建的产物替换，未发布。

## 验证结果
- flutter test --no-pub --reporter expanded：923 tests 通过。
- flutter analyze --no-pub：0 error / warning，120 条既有 info。
- S3 默认真实 LIST / HEAD / Range 验证通过。
- i18n audit：16,312 keys、1,047 placeholder keys；缺失 / 不匹配 / 缺少参数均 0。
- i18n maintenance：3,505 个未引用候选、417 条旧来源、0 活动退休项；本次新增 / 退休 key 均 0，不清理历史项。
- 旧 helper 与 catalog Dart 插值扫描无匹配。
- 菜谱结构：7,051 条记录 ID 完整，已有改动仅涉及 923 条 attributes。
- Windows release 构建成功；exe 版本 1.0.1+2；窗口标题和工具箱实机检查通过。
- ARM64 / ARMv7 APK、AAB 构建成功；apksigner / jarsigner 签名有效且证书一致。AAB 自签名 / 无时间戳提示属于 Android 本地发行签名的预期输出。
- APK versionName 1.0.1，分包 versionCode 为 2002 / 1002，最低 API 24；AAB 基础 build 2。
- APK / AAB 各 ABI 均包含 libapp.so / libflutter.so / libfjs.so；全部归档 CRC 通过。
- Windows ZIP 包含构建目录完整的 87 个文件；无签名私钥 / key.properties / .env。
- PowerShell 解析通过；环境变量恢复检查通过；README 本地链接有效。

## 产物
本机目录：dist/release-1.0.1/。
- xianyushengxi-1.0.1-arm64-v8a.apk：108,052,009 bytes。
- xianyushengxi-1.0.1-armeabi-v7a.apk：100,038,823 bytes。
- xianyushengxi-1.0.1.aab：193,981,139 bytes。
- xianyushengxi-windows-1.0.1.zip：57,790,328 bytes。
- SHA256SUMS.txt：四个发布产物的 SHA256。

## 发布结果
- 发布工程提交：789fba414999829efaa890488130df4d3b826bb1。
- 已通过 fast-forward 将工作分支合入 main；main、工作分支和带注释 v1.0.1 标签已原子推送。
- 远端 main 与 v1.0.1 解引用均核对为上述发布提交。
- GitHub Release 草稿已创建，产物上传中；发布完成后补充 URL 与校验结果。
