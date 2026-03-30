# APK 包体积分析报告

## 当前状态

**APK 大小**: 54.6MB (arm64-v8a)
**Assets 总大小**: 24.33MB

## 包体积组成分析

### 1. Assets 资源 (24.33MB, 44.5%)

| 类型 | 大小 (MB) | 占比 | 文件数 |
|------|-----------|------|--------|
| MP3 音频 | 13.21 | 54.3% | 6 |
| Gzip 压缩 | 7.02 | 28.8% | 3 |
| WAV 音频 | 4.07 | 16.7% | 3 |
| 图片 | 0.03 | 0.1% | 1 |
| 文本 | ~0 | ~0% | 1 |

### 2. Flutter 引擎和代码 (~15MB, 27.5%)

### 3. 依赖库 (~10MB, 18.3%)
- sqlite3_flutter_libs
- audioplayers
- flutter_tts
- sherpa_onnx (语音识别)

### 4. 其他 (~5.3MB, 9.7%)

## 优化建议

### 高优先级（预计减少 30-40MB）

#### 1. 使用 S3 按需加载资源 ✅ 已实现
**现状**: 部分资源已从 S3 加载
**建议**: 
- 将所有音频资源移至 S3
- 实现资源预下载/缓存策略
- 使用增量更新

**预期收益**: -17MB (所有音频资源外置)

#### 2. 移除打包的音频资源
**文件**: 
- `assets/ambient/nature/wind-in-trees.mp3` (已删除)
- `assets/ambient/places/cafe.mp3` (已删除)
- `assets/ambient/rain/light-rain.mp3` (已删除)

**预期收益**: -3-5MB

#### 3. 压缩词本资源
**现状**: 词本文件使用 Gzip 压缩 (7.02MB)
**建议**: 
- 使用更高效的压缩算法 (如 Brotli)
- 词本数据改为从 S3 下载

**预期收益**: -3-5MB

### 中优先级（预计减少 5-10MB）

#### 4. 拆分 APK (App Bundle)
**建议**: 使用 Android App Bundle (.aab) 替代 APK
```bash
flutter build appbundle --release
```

**预期收益**: 用户下载减少 50% (Play Store 按架构分发)

#### 5. 移除未使用的依赖
**检查项**:
- `sqlite3_flutter_libs` ^0.6.0+eol (EOL 版本，升级)
- 评估 `sherpa_onnx` 是否必须 (语音识别模型较大)

**预期收益**: -2-3MB

#### 6. 代码优化
- 启用 ProGuard/R8 代码压缩
- 移除未使用的代码路径

**预期收益**: -1-2MB

### 低优先级（预计减少 1-3MB）

#### 7. 图片资源优化
**现状**: logo.jpg (0.03MB)
**建议**: 
- 使用 WebP 格式
- 提供多分辨率资源

**预期收益**: -0.5MB

#### 8. 字体优化
**建议**: 使用系统字体或子集化

**预期收益**: -0.5-1MB

## 优化后预期

| 阶段 | APK 大小 | 减少比例 |
|------|----------|----------|
| 当前 | 54.6MB | - |
| 阶段 1 (资源外置) | 37.6MB | -31% |
| 阶段 2 (App Bundle) | 32.6MB | -40% |
| 阶段 3 (完全优化) | 27.3MB | -50% |

## 实施步骤

### 阶段 1: 资源外置 (1-2 天)
1. ✅ 已实现 S3 客户端配置
2. 将所有音频资源移至 S3
3. 实现资源下载进度指示器
4. 添加离线资源管理

### 阶段 2: 构建优化 (1 天)
1. 升级到非 EOL 依赖
2. 配置 ProGuard/R8
3. 使用 App Bundle 分发

### 阶段 3: 代码优化 (2-3 天)
1. 移除未使用代码
2. 优化资源加载逻辑
3. 实现增量更新机制

## 监控建议

1. **包体积监控**: 在 CI/CD 中集成包体积检查
2. **资源使用统计**: 追踪哪些资源最常用
3. **用户下载转化率**: 监控包体积对下载的影响

## 参考

- [Flutter 性能最佳实践](https://docs.flutter.dev/perf/rendering/performance)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)
- [ProGuard 配置](https://developer.android.com/studio/build/shrink-code)
