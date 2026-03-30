# 图片资源 WebP 化优化指南

## 当前状态

**图片资源**: `assets/branding/logo.jpg`
- 大小：30.6 KB
- 格式：JPEG
- 位置：`assets/branding/logo.jpg`

## WebP 优势

| 指标 | JPEG | WebP | 节省 |
|------|------|------|------|
| 文件大小 | 30.6 KB | ~12 KB | ~60% |
| 透明度 | ❌ | ✅ | - |
| 动画 | ❌ | ✅ | - |
| 无损压缩 | ❌ | ✅ | - |

## 转换方法

### 方法 1: 使用 Flutter WebP 工具

```bash
# 安装转换工具
flutter pub add flutter_webp

# 或者使用全局命令
flutter pub global activate webp_converter
```

### 方法 2: 使用 cwebp (推荐)

```bash
# Windows - 下载 WebP 工具包
# https://developers.google.com/speed/webp/docs/precompiled

# 转换图片
cwebp -q 85 assets/branding/logo.jpg -o assets/branding/logo.webp

# 批量转换
for file in assets/**/*.jpg; do
  cwebp -q 85 "$file" -o "${file%.jpg}.webp"
done
```

### 方法 3: 在线转换工具

- [Squoosh](https://squoosh.app/)
- [CloudConvert](https://cloudconvert.com/jpg-to-webp)

## 转换后配置

### pubspec.yaml 更新

```yaml
flutter:
  assets:
    - assets/branding/logo.webp
```

### 代码中使用

```dart
// 无需修改代码，Flutter 自动支持 WebP
Image.asset('assets/branding/logo.webp')
```

## 预期收益

| 资源 | 原始大小 | WebP 大小 | 节省 |
|------|----------|-----------|------|
| logo.jpg | 30.6 KB | ~12 KB | 18.6 KB |
| **总计** | **30.6 KB** | **~12 KB** | **~60%** |

## 注意事项

1. **兼容性**: WebP 支持 Flutter 所有目标平台
2. **质量**: 建议使用 `-q 80` 到 `-q 90` 之间
3. **透明背景**: 使用无损 WebP 或高质量有损压缩

## 执行步骤

1. 安装 cwebp 工具
2. 转换图片：`cwebp -q 85 assets/branding/logo.jpg -o assets/branding/logo.webp`
3. 更新 pubspec.yaml
4. 删除原 JPEG 文件
5. 重新构建：`flutter clean && flutter build apk`

## 参考

- [Flutter WebP 支持](https://docs.flutter.dev/ui/assets/assets-and-images#webp)
- [WebP 官方文档](https://developers.google.com/speed/webp)
