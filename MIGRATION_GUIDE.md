# 升级与迁移指南

如果你是从旧版本升级到当前版本，建议先阅读本说明，尤其是在以下场景：

- 包名从旧的 `com.example...` 迁移到了 `group.zn.xianyushengxi`
- 应用显示名已统一为 `咸鱼声息`
- 本地配置、数据库、日志目录可能同时存在新旧两套

## 什么时候需要清理旧数据

如果出现以下情况，建议先清理本地应用数据后再启动：

- 启动后直接报配置或类型错误
- 设置项明显与当前版本不兼容
- 本地缓存状态异常，且重复重启无法恢复
- 切换新旧构建后数据目录冲突

## 快速处理方式

### Windows

优先使用开发脚本清理当前应用目录：

```powershell
.\scripts\dev-run.ps1 -ResetAppState -NoRun
```

如果仍然异常，再手动检查并清理以下目录中残留的旧数据：

```text
%APPDATA%\group.zn\xianyushengxi\
%LOCALAPPDATA%\group.zn\xianyushengxi\
%LOCALAPPDATA%\vocabulary_sleep_app\
```

### macOS

```bash
rm -rf ~/Library/Application\ Support/group.zn.xianyushengxi/
rm -rf ~/Library/Application\ Support/vocabulary_sleep_app/
```

### Linux

```bash
rm -rf ~/.local/share/group.zn.xianyushengxi/
rm -rf ~/.local/share/vocabulary_sleep_app/
```

## 构建前的推荐操作

如果升级后遇到构建异常，可以按下面顺序尝试：

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

然后再执行：

```bash
flutter run
```

或者使用：

```powershell
.\scripts\dev-run.ps1 -Clean
```

## 品牌与包名变更摘要

| 项目 | 旧值 | 新值 |
| --- | --- | --- |
| 组织标识 | `com.example` | `group.zn` |
| 桌面/包名主标识 | `flutter_app` / `vocabulary_sleep_app` | `xianyushengxi` |
| 显示名称 | 历史值不统一 | `咸鱼声息` |

## 不建议删除的内容

清理问题时，请不要删除以下项目仓库内容：

- `assets/`
- `dict/`
- `docs/`
- `test/`

这些属于源码或随项目交付的资源，不是缓存目录。
