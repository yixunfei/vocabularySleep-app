# 计划 236: Android 构建 AGP 兼容修复

## 基本信息
- **创建日期**: 2026-05-26
- **状态**: 已完成
- **负责人**: Codex

## 目标
修复 `flutter build apk --release` 在 `:app:checkReleaseAarMetadata` 阶段失败的问题，使 Android release APK 能通过构建。

## 详细步骤
1. [x] 确认失败来源：CameraX 1.6.0 AAR metadata 要求 Android Gradle Plugin 8.9.1 或更高版本。
2. [x] 检查当前 Gradle Wrapper、JDK 与 Flutter 版本，确认升级 AGP 的环境边界。
3. [x] 将项目 Android Gradle Plugin 从 8.7.3 升级到 8.9.1。
4. [x] 执行 release APK 构建验证。
5. [x] 更新 changelog 并复查本轮变更范围。

## 风险评估
- **风险 1**: AGP 升级可能暴露 Android 构建脚本或插件兼容问题。
- **缓解措施**: 只做最小版本升级，不改业务代码、不改相机调用逻辑，并使用 release APK 构建验证。
- **风险 2**: 工作区已有未提交改动，文档或业务代码可能包含用户正在进行的改动。
- **缓解措施**: 本轮仅新增计划文档、修改 Android AGP 版本、追加 changelog，不回退或重写已有改动。

## 依赖项
- Flutter 3.41.6
- JDK 17
- Gradle Wrapper 8.14
- `camera_android_camerax` 0.7.2 / CameraX 1.6.0

## 执行记录
- 2026-05-26: 已将 `android/settings.gradle.kts` 中 Android Gradle Plugin 升级到 8.9.1。
- 2026-05-26: `flutter build apk --release` 已通过，生成 `build/app/outputs/flutter-apk/app-release.apk`。
