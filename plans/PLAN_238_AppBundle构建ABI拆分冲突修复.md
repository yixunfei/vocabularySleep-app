# 计划 238: App Bundle 构建 ABI 拆分冲突修复

## 基本信息
- **创建日期**: 2026-05-26
- **状态**: 已完成
- **负责人**: Codex

## 目标
修复 `flutter build appbundle --release` 在 `:app:buildReleasePreBundle` 阶段失败的问题，同时保留 APK release 构建的 ABI 拆分能力。

## 详细步骤
1. [x] 通过 `--stacktrace` 确认失败来源为 AGP `PerModuleBundleTask.getResourcesFile`。
2. [x] 检查 `build/app/intermediates`，确认 release ABI splits 生成了多份 processed resources。
3. [x] 将 `splits.abi` 调整为仅在非 bundle 构建任务中启用。
4. [x] 执行 `flutter build appbundle --release` 验证 AAB 构建。
5. [x] 执行 `flutter build apk --release` 回归验证 APK 构建。
6. [x] 更新 changelog 并复查本轮变更范围。

## 风险评估
- **风险 1**: 条件判断过宽可能影响 APK 多 ABI 输出。
- **缓解措施**: 使用 Gradle 请求任务名判断 bundle 构建，并同时验证 APK 构建。
- **风险 2**: App Bundle 本身已有 ABI 动态交付拆分，继续启用 APK splits 会造成 AGP 资源包匹配冲突。
- **缓解措施**: bundle 构建禁用 APK splits，交由 AAB 标准机制处理 ABI。

## 依赖项
- Android Gradle Plugin 8.9.1
- Gradle Wrapper 8.14
- Flutter 3.41.6

## 执行记录
- 2026-05-26: 确认 `buildReleasePreBundle` 因 ABI splits 生成多份 release resources 失败。
- 2026-05-26: 已将 `splits.abi.isEnable` 调整为 bundle 构建时关闭、APK 构建时开启。
- 2026-05-26: `flutter build appbundle --release` 已通过，生成 `build/app/outputs/bundle/release/app-release.aab`。
- 2026-05-26: `flutter build apk --release` 已通过，生成 `build/app/outputs/flutter-apk/app-release.apk`。
