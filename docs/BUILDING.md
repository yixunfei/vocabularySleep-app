# 构建说明

本文档说明 `咸鱼声息` Flutter 工程的多平台打包方式、脚本参数和当前限制。

## 可用脚本

- Windows / PowerShell: `.\scripts\build.ps1`
- macOS / Linux / Bash: `./scripts/build.sh`

两个脚本都负责：

- 可选执行 `flutter clean`
- 可选执行 `flutter pub get`
- 调用 `flutter build <target>`
- 将最终产物复制到根目录 `dist/`

## 主机支持矩阵

| 当前主机 | 支持目标 |
| --- | --- |
| Windows | `android-apk`, `android-appbundle`, `windows`, `web` |
| macOS | `android-apk`, `android-appbundle`, `ios`, `macos`, `web` |
| Linux | `android-apk`, `android-appbundle`, `linux`, `web` |

说明：

- `all` 只会展开为当前主机能构建的目标。
- `ios` 与 `macos` 只能在 macOS 主机上构建。
- `windows` 只能在 Windows 主机上构建。
- `linux` 只能在 Linux 主机上构建。

## PowerShell 用法

```powershell
.\scripts\build.ps1 -Target android-apk
.\scripts\build.ps1 -Target android-apk,android-appbundle,windows
.\scripts\build.ps1 -Target windows -Clean
.\scripts\build.ps1 -Target android-apk -BuildName 1.2.0 -BuildNumber 12
.\scripts\build.ps1 -Target all -DryRun
```

参数说明：

- `-Target`: 目标平台，可重复传入，也支持逗号分隔
- `-Clean`: 构建前执行 `flutter clean`
- `-NoPubGet`: 跳过 `flutter pub get`
- `-BuildName`: 传给 Flutter 的 `--build-name`
- `-BuildNumber`: 传给 Flutter 的 `--build-number`
- `-DryRun`: 只打印命令和复制目标，不实际执行

## Bash 用法

```bash
./scripts/build.sh --target android-apk
./scripts/build.sh --target android-appbundle --target linux
./scripts/build.sh --target macos --build-name 1.2.0 --build-number 12
./scripts/build.sh --target all --dry-run
```

参数说明：

- `--target <name>`: 目标平台，可重复传入
- `--clean`: 构建前执行 `flutter clean`
- `--no-pub-get`: 跳过 `flutter pub get`
- `--build-name <value>`: 传给 Flutter 的 `--build-name`
- `--build-number <value>`: 传给 Flutter 的 `--build-number`
- `--dry-run`: 只打印命令，不实际执行

## 产物位置

| 目标 | 复制到 `dist/` 的路径 |
| --- | --- |
| `android-apk` | `dist/android-apk/xianyushengxi.apk` |
| `android-appbundle` | `dist/android-appbundle/xianyushengxi.aab` |
| `ios` | `dist/ios/Runner.app` |
| `macos` | `dist/xianyushengxi-macos.app` |
| `windows` | `dist/windows/` |
| `linux` | `dist/linux/` |
| `web` | `dist/web/` |

## 已知限制

### Web 当前无法成功编译

当前项目直接依赖了 `sqlite3` 与 `sherpa_onnx`，它们会引入 `dart:ffi`。因此执行 `flutter build web` 时会报错，属于项目现状限制，不是打包脚本问题。

如果需要真正支持 Web，需要后续完成以下改造之一：

- 将 FFI 能力改为平台隔离实现
- 为 Web 提供单独的存储与语音能力替代层
- 在入口层按平台拆分依赖注入

### iOS 产物未签名

脚本使用的是：

```bash
flutter build ios --release --no-codesign
```

因此脚本适合生成调试或 CI 产物，不负责最终签名、证书和上架流程。
