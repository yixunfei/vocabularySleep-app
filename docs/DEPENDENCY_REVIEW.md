# 依赖包审查报告

**日期**: 2026-03-30  
**总依赖数**: 26 个直接依赖

---

## 依赖包清单

### 核心依赖

| 包名 | 版本 | 状态 | 说明 |
|------|------|------|------|
| flutter | sdk | ✅ | Flutter 框架 |
| flutter_localizations | sdk | ✅ | 国际化支持 |
| cupertino_icons | ^1.0.9 | ✅ | iOS 风格图标 |

### 数据存储

| 包名 | 版本 | 状态 | 说明 |
|------|------|------|------|
| sqlite3_flutter_libs | ^0.6.0+eol | ⚠️ | **EOL 版本**，建议升级 |
| sqlite3 | ^2.9.4 | ✅ | SQLite 数据库 |
| path_provider | ^2.1.5 | ✅ | 路径提供 |
| path | ^1.9.1 | ✅ | 路径工具 |

### 文件处理

| 包名 | 版本 | 状态 | 说明 |
|------|------|------|------|
| csv | ^8.0.0 | ✅ | CSV 解析 |
| file_picker | ^10.3.10 | ✅ | 文件选择器 |
| archive | ^4.0.9 | ✅ | 压缩/解压 |
| crypto | ^3.0.6 | ✅ | 加密哈希 |

### 音频/语音

| 包名 | 版本 | 状态 | 说明 |
|------|------|------|------|
| audioplayers | ^6.6.0 | ✅ | 音频播放 |
| audioplayers_platform_interface | ^7.1.1 | ✅ | 音频平台接口 |
| flutter_tts | ^4.2.5 | ✅ | TTS 文本转语音 |
| record | ^6.2.0 | ✅ | 录音 |
| sherpa_onnx | ^1.12.34 | ⚠️ | **体积较大** (~10MB) |

### 状态管理

| 包名 | 版本 | 状态 | 说明 |
|------|------|------|------|
| provider | ^6.1.5+1 | ✅ | 状态管理 |

### 网络

| 包名 | 版本 | 状态 | 说明 |
|------|------|------|------|
| http | ^1.6.0 | ✅ | HTTP 客户端 |

### 工具

| 包名 | 版本 | 状态 | 说明 |
|------|------|------|------|
| uuid | ^4.5.3 | ✅ | UUID 生成 |
| dict_reader | ^1.6.0 | ⚠️ | 自定义词典读取 |
| flutter_dotenv | ^5.2.1 | ✅ | 环境变量 |

### 开发依赖

| 包名 | 版本 | 状态 | 说明 |
|------|------|------|------|
| flutter_test | sdk | ✅ | 测试框架 |
| flutter_lints | ^6.0.0 | ✅ | Lint 规则 |
| flutter_launcher_icons | ^0.14.3 | ✅ | 应用图标 |
| fake_async | ^1.3.3 | ✅ | 异步测试 |
| path_provider_platform_interface | ^2.1.2 | ✅ | 平台接口 |
| plugin_platform_interface | ^2.1.8 | ✅ | 插件接口 |

---

## 问题依赖分析

### 1. sqlite3_flutter_libs (^0.6.0+eol) ⚠️

**问题**: EOL (End of Life) 版本

**建议**:
- 升级到 `^0.6.1` 或更高版本
- 或迁移到 `sqflite_common_ffi` 作为替代

**影响**: 低 - 功能正常，但无法获得更新

---

### 2. sherpa_onnx (^1.12.34) ⚠️

**问题**: 包体积过大 (~10MB)

**建议**:
- 评估是否所有功能都需要
- 考虑按需加载模型
- 或提供精简版/完整版选择

**影响**: 高 - 显著增加 APK 体积

**替代方案**:
- 使用系统 TTS 进行语音识别
- 或仅在线语音识别（依赖网络）

---

### 3. dict_reader (^1.6.0) ⚠️

**问题**: 自定义包，维护成本高

**建议**:
- 考虑使用标准 CSV/JSON 解析
- 或开源到 pub.dev 便于维护

**影响**: 低 - 功能正常

---

## 可移除的依赖

### 潜在可移除项

1. **audioplayers_platform_interface**
   - 可能已被 `audioplayers` 自动包含
   - 检查是否直接使用

2. **path_provider_platform_interface**
   - 可能已被 `path_provider` 自动包含
   - 通常不需要单独添加

3. **plugin_platform_interface**
   - 仅开发插件时需要
   - 应用层可能不需要

---

## 依赖优化建议

### 高优先级

| 操作 | 预期收益 |
|------|----------|
| 移除未使用的平台接口包 | -0.5MB |
| 优化 sherpa_onnx 使用 | -5MB |
| 升级 sqlite3_flutter_libs | 获得安全更新 |

### 中优先级

| 操作 | 预期收益 |
|------|----------|
| 审查 dict_reader 使用 | 代码简化 |
| 添加依赖版本锁定 | 构建稳定性 |

---

## 依赖版本锁定

### 建议配置 pubspec.lock

```yaml
# 在 pubspec.yaml 中明确版本
dependencies:
  provider: 6.1.5+1  # 精确版本而非范围
```

---

## 安全检查

运行以下命令检查安全漏洞：

```bash
dart pub outdated
dart pub global activate dart_audit
dart pub global run dart_audit
```

---

## 总结

### 健康度评分

| 指标 | 评分 | 说明 |
|------|------|------|
| 版本更新 | 8/10 | 大部分包较新 |
| 安全性 | 9/10 | 无明显漏洞 |
| 体积优化 | 6/10 | sherpa_onnx 过大 |
| 维护性 | 8/10 | 依赖合理 |
| **综合** | **8/10** | 良好 |

### 待办事项

- [ ] 升级 `sqlite3_flutter_libs` 到非 EOL 版本
- [ ] 审查 `audioplayers_platform_interface` 是否必需
- [ ] 审查 `path_provider_platform_interface` 是否必需
- [ ] 评估 `sherpa_onnx` 优化方案
- [ ] 考虑移除 `plugin_platform_interface`（如果未开发插件）

---

*报告生成时间：2026-03-30*
