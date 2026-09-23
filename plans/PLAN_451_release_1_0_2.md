# 计划 451：v1.0.2 源码整理、合并与发布

## 基本信息
- 创建日期：2026-09-23
- 状态：发布基线已就绪（本地构建与校验完成；远端状态以 Release 为准）
- 负责人：Codex
- 用户授权：提交、合并 main、推送远端、发布新版本；确认 v1.0.2（build 3），Android ARM64/ARMv7 APK、AAB、Windows ZIP，沿用现有证书；同步 README。

## 目标与执行步骤
1. 核对 origin/main、当前修复提交及 v1.0.1 发布基线。
2. 核实引用，将未使用的独立 dict、根目录参考图片、tool/r2_* 和 tool/r3_* 一次性翻译中间物移出 Git 跟踪并加入忽略规则；本地文件保留。
3. 保留源码、构建配置、测试、实际运行资源、原生依赖与必要开发文档；安装包仅存 dist 与 GitHub Release 附件。
4. 更新 pubspec、README、PROJECT_DOMAIN、changelog 到 1.0.2+3；不升级依赖。
5. 构建 Windows、双 ABI APK 与 AAB，核对版本、签名、归档 CRC、原生库、Windows 完整目录及 SHA256。
6. 完成提交并合并 main，推送 main 和 v1.0.2 标签；创建 Release 并上传、核对附件。

## 计划审查与风险
- 本次为修复版；保留 v1.0.1 的 Android 签名身份，核对证书指纹以支持覆盖升级。
- 不重写历史、不强推、不修改旧标签。fetch --tags 遇到既有 0.1/0.2/0.3 本地/远端冲突后，改用 fetch main --no-tags；历史标签不属于本次发布。
- 构建按平台顺序执行，避免 Flutter/Gradle 缓存与构建目录竞争。
- 用户未跟踪词书工作区不纳入提交；使用明确路径暂存。
- 本次代码逻辑测试复用 PLAN_450 的 940 tests 与定向回归结果；版本/文档/跟踪清理后验证构建与仓库内容，不新增镜像实现的测试。
- 已完成 1.0.1 发布的功能说明作为依据；README 明确 Web 仍非完整发行平台。

## 验证结果
- Windows、双 ABI APK、AAB 顺序构建全部成功；命令：`scripts/build.ps1 -Target windows,android-apk,android-appbundle -BuildName 1.0.2 -BuildNumber 3 -NoPubGet`。
- Windows FileVersion/ProductVersion 为 1.0.2+3；ZIP 与 dist/windows 的 86 个文件逐一 SHA256 对照，CRC 通过。
- APK versionName 1.0.2，ARM64/ARMv7 versionCode 为 2003/1003；AAB 合并 manifest 为 build 3；最低 API 24、target 36。
- apksigner/jarsigner 签名校验通过，三个 Android 包证书一致且与 v1.0.1 一致；指纹 `1e86ad982cd3e0a1a9662f382d4bace1348dc90c488eecf138a135bc7865bf6b`。
- Android 各 ABI 必需原生库与全部归档 CRC 检查通过；包内无 .bak、.env、密钥库或 key.properties。
- 63 个非运行文件仅移出索引，121,053,956 bytes 原文件本地保留；另将资源目录的菜谱备份移至 dist/local-work/release-1.0.2-input-backups，避免被目录资源声明打入安装包。
- README 链接与正式 Flutter asset 跟踪检查通过；未纳入用户原有未跟踪词书脚本和数据。
- 本轮新增/退休 i18n key 均为 0，没有 UI/catalog 调整；复用 PLAN_450 审计结果（占位符错误 0，3,505 个未引用候选/417 条旧 source 保留）。

## 产物
本机目录：`dist/release-1.0.2/`；Release 上传以下四个产物和 SHA256SUMS.txt，不上传发布脚本与本地日志。
- xianyushengxi-1.0.2-arm64-v8a.apk：105,316,026 bytes。
- xianyushengxi-1.0.2-armeabi-v7a.apk：97,319,224 bytes。
- xianyushengxi-1.0.2.aab：191,257,782 bytes。
- xianyushengxi-windows-1.0.2.zip：54,207,524 bytes。

## 发布核验入口
- 目标分支：main；目标带注释标签：v1.0.2；使用本发布准备提交作为基线。
- Release：<https://github.com/yixunfei/vocabularySleep-app/releases/tag/v1.0.2>。
- 发布流程先上传 draft、核对附件大小与 GitHub SHA256，再公开发布为 latest；远端执行结果保存在本地 dist/release-1.0.2/release-state.json，并通过最终回复报告。
- 不强推、不覆盖历史标签、不推送安装包到 Git 源码树；版本之外没有新增平台兼容工作。

