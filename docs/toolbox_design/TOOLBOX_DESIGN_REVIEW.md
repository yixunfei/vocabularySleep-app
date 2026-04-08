# 工具箱模块 UI/UX 设计评估与优化方案

## 文档版本

| 版本 | 日期 | 状态 | 作者 |
|------|------|------|------|
| v1.0.0 | 2026-04-08 | 初稿 | AI Design Review |

---

## 目录

1. [执行摘要](#执行摘要)
2. [模块概览与评分矩阵](#模块概览与评分矩阵)
3. [视觉设计分析](#视觉设计分析)
4. [动画特效深度评估](#动画特效深度评估)
5. [色彩系统审计](#色彩系统审计)
6. [交互设计评估](#交互设计评估)
7. [具体优化建议](#具体优化建议)
8. [实现路线图](#实现路线图)
9. [附录：设计规范参考](#附录设计规范参考)

---

## 执行摘要

### 核心发现

本次评估覆盖工具箱（Toolbox）模块的 **10 个核心功能页面**，涵盖从视觉设计、动效编排到交互体验的全链路分析。

**关键结论：**

1. **禅意沙盘（Zen Sand Tray）** 是全场最佳实现，其视听触三感合一的设计堪称模块典范
2. **疗愈音钵（Singing Bowls）** 的视觉层次丰富，但频率选择器存在触控问题
3. **呼吸训练（Breathing Practice）** 动效基础扎实但缺乏记忆点
4. **工具箱入口（Toolbox Page）** 设计过于功能性，缺乏现代 App 的精致感
5. **舒缓音乐（Soothing Music）** 的 Blob 动画过于刻意，沉浸感不足

### 艺术风格归类

| 模块 | 主导风格 | 辅调风格 |
|------|---------|---------|
| 禅意沙盘 | 日式侘寂（Wabi-sabi）| 极简主义（Minimalism）|
| 疗愈音钵 | 新世纪（New Age）| 渐变极简 |
| 呼吸训练 | 几何抽象（Geometric Abstract）| 慢视觉（Slow Vision）|
| 舒缓音乐 | 暗色 Lo-fi 美学 | 赛博渐变 |
| 电子木鱼 | 赛博朋克玄学 | 像素复古 |
| 静心念珠 | 冥想流（Meditative Flow）| 触觉反馈美学 |

---

## 模块概览与评分矩阵

### 评分维度定义

| 维度 | 权重 | 评分标准 |
|------|------|---------|
| **视觉美感**（Visual）| 25% | 色彩搭配、构图、层次感 |
| **动效质量**（Motion）| 25% | 流畅度、缓动函数、节奏感 |
| **交互体验**（Interaction）| 20% | 触控区域、反馈及时性、状态清晰度 |
| **现代感**（Contemporary）| 15% | 设计趋势符合度 |
| **品牌一致性**（Branding）| 15% | 与整体设计语言统一程度 |

### 评分矩阵

| 模块 | 视觉 | 动效 | 交互 | 现代感 | 一致性 | **综合** |
|------|------|------|------|--------|--------|---------|
| 禅意沙盘 | 9.5 | 9.0 | 9.5 | 8.0 | 8.5 | **9.0** |
| 疗愈音钵 | 8.5 | 8.0 | 7.5 | 7.5 | 7.0 | **7.9** |
| 呼吸训练 | 7.5 | 7.0 | 8.5 | 6.5 | 7.5 | **7.4** |
| 舒缓音乐 | 7.0 | 6.5 | 7.5 | 7.0 | 7.0 | **7.0** |
| 电子木鱼 | 6.5 | 6.0 | 7.0 | 7.5 | 6.5 | **6.8** |
| 静心念珠 | 6.5 | 5.5 | 7.0 | 6.0 | 6.5 | **6.3** |
| 舒尔特方格 | 6.0 | 5.0 | 7.5 | 5.5 | 6.0 | **6.0** |
| 专注节拍 | 6.0 | 6.5 | 7.0 | 6.5 | 6.5 | **6.5** |
| 每日决策 | 6.5 | 7.0 | 6.5 | 6.5 | 6.0 | **6.5** |
| 工具箱入口 | 5.5 | 4.0 | 6.5 | 5.0 | 6.0 | **5.5** |

---

## 视觉设计分析

### 1. 工具箱入口页面（Toolbox Page）

**文件位置：** `lib/src/ui/pages/toolbox_page.dart`

#### 当前设计问题

```dart
// 问题代码示例 - 卡片样式
Ink(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(24),  // ❌ 24px 圆角已过时
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    border: Border.all(
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  ),
)
```

**具体问题：**

| 问题 | 严重程度 | 说明 |
|------|---------|------|
| 圆角过大 | 高 | 24px 圆角属于 2010 年代设计语言，2020 年代主流为 12-16px |
| 缺少阴影层次 | 中 | 纯色边框卡片在现代 UI 中显得单薄 |
| 悬停/按压无状态反馈 | 高 | 缺少 active 态的视觉变化 |
| 图标容器无渐变 | 低 | 纯色背景缺乏深度 |

#### 优化方向

```
当前设计：
┌─────────────────────────────┐
│  ┌───┐                     │
│  │ ☆ │  标题文字            │
│  └───┘  副标题文字    →     │
└─────────────────────────────┘

优化方向（加入层次与反馈）：
┌─────────────────────────────┐
│  ┌───┐                     │
│  │ ☆ │  标题文字            │
│  └───┘  副标题文字    →     │
│  ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  ← 按压时底部高光消失
└─────────────────────────────┘
```

### 2. 禅意沙盘（Zen Sand Tray）

**文件位置：** `lib/src/ui/pages/toolbox_zen_sand_tool.dart`

#### 设计亮点

1. **色彩体系完整**：4 种场景背景（暖金沙、潮汐浅滩、月灰石庭、暮色陶砂）各有独特的情绪表达
2. **工具系统专业**：木耙、指尖、涂料、水迹、波纹、沙铲、沙砾、抚平、景石 9 种工具
3. **触觉反馈精细**：`_accentStrideFor()` 和 `_accentGapFor()` 实现的音频节流逻辑
4. **仪式预设系统**：呼吸潮纹、平衡石庭、沁润溪路、专注耙纹 4 种起手预设

#### 动效亮点分析

```dart
// 笔触跟随延迟优化 - 极具匠心
double get _accentStrideFor(ZenSandSoundKind kind) {
  final brushFactor = ((_brushSize - 14.0) / 82.0).clamp(0.0, 1.0);
  final base = switch (kind) {
    ZenSandSoundKind.rake => 14.0,
    ZenSandSoundKind.finger => 18.0,
    ZenSandSoundKind.water => 22.0,
    ZenSandSoundKind.shovel => 16.0,
    ZenSandSoundKind.gravel => 12.0,
    ZenSandSoundKind.smooth => 20.0,
    ZenSandSoundKind.stone => 999.0,
  };
  return base + brushFactor * 8.0;  // 根据笔刷大小动态调整音效节流
}
```

**评价：** 这种精细的音频-视觉同步逻辑在业界属于一流实现。

### 3. 疗愈音钵（Singing Bowls）

**文件位置：** `lib/src/ui/pages/toolbox_singing_bowls_tool.dart`

#### 当前设计问题

**频率选择器触控区域分析：**

```dart
// 当前实现 - 横向滚动列表
width: selected ? 82 : 62,  // ❌ 非选中态仅 62px，触控困难
```

**问题：**
- 最小触控区域应 ≥ 48dp（Google Material Design 标准）
- 82dp 的选中态与 62dp 非选中态差距不够明显
- 缺少选中态的放大动画过渡

#### 波纹动画分析

```dart
// 波纹扩散动画 - 核心实现
class _SingingBowlBackdropPainter extends CustomPainter {
  // ambientController: 18秒周期环境脉动
  // strikeController: 1400ms 敲击动画周期
}
```

**问题：**
- 1400ms 的敲击动画周期过长，在连续快速敲击时显得迟钝
- 建议降至 800-1000ms 以提升响应感

---

## 动画特效深度评估

### 动效分类框架

```
动画特效
├── 时间维度
│   ├── 即时反馈（< 100ms）      - 触控点按、悬停
│   ├── 短时动画（100-400ms）   - 状态切换、过渡
│   ├── 中时动画（400-1000ms）  - 场景切换、加载
│   └── 长时动画（> 1000ms）    - 背景氛围、循环
│
├── 空间维度
│   ├── 微观（控件级）          - 按钮、图标
│   ├── 中观（组件级）          - 卡片、列表项
│   └── 宏观（页面级）          - 全屏过渡、背景
│
└── 感官维度
    ├── 视觉动画                - 位移、缩放、旋转、渐变
    ├── 音频同步                - 音效触发与视觉节拍
    └── 触觉反馈                - 振动反馈与视觉节奏
```

### 各模块动效评估

#### A. 禅意沙盘

| 动效类型 | 实现质量 | 评分 | 说明 |
|---------|---------|------|------|
| 笔触绘制 | 卓越 | 9.5 | 延迟补偿、压力敏感（笔刷大小）|
| 音效同步 | 卓越 | 9.5 | 节流算法精细，8种工具各有节奏 |
| 触觉反馈 | 优秀 | 9.0 | 落石冲击感强，抚平操作轻柔 |
| 背景纹理 | 优秀 | 8.5 | 平行、潮汐、环形、等高线四种模式 |
| 缩放/平移 | 良好 | 8.0 | 双指缩放流畅，边界处理恰当 |

**关键代码片段：**

```dart
// 水迹工具的持续绘制逻辑 - 精品实现
void _startWaterHoldPainter() {
  _waterHoldTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
    // 55ms 刷新间隔，约 18fps，对于水迹扩散效果足够
    final point = _normalize(_lastResolvedInputPoint!, canvasSize);
    setState(() {
      _workingStroke = <Offset>[..._workingStroke, point];
    });
    _updateSandLoop(gestureDistance: _brushSize * 0.18);
    _waterHoldTicks += 1;
    if (_waterHoldTicks % 4 == 0) {
      _playSandAccent(gestureDistance: _brushSize * 0.32, intensityBias: 0.08);
    }
  });
}
```

#### B. 疗愈音钵

| 动效类型 | 实现质量 | 评分 | 问题/建议 |
|---------|---------|------|----------|
| 敲击动画 | 良好 | 7.5 | 1400ms 周期过长，建议 800ms |
| 波纹扩散 | 优秀 | 8.5 | 物理模拟自然，渐变优美 |
| 呼吸脉动 | 良好 | 7.0 | 18秒周期偏慢 |
| 频率切换 | 中等 | 6.5 | 缺少过渡动画，直接跳变 |
| 色彩渐变 | 优秀 | 9.0 | 7种脉轮色彩系统完整 |

**核心动画代码：**

```dart
// 敲击时的碗体动画
final strike = Curves.easeOutCubic.transform(_strikeController.value);
final pulse = 0.5 + 0.5 * math.sin(_ambientController.value * math.pi * 2);
final scale = 1 - strike * 0.042 - (_pressing ? 0.02 : 0) + pulse * 0.004;
final yOffset = strike * 8.5;  // 垂直位移模拟敲击下压

return Transform.translate(
  offset: Offset(0, yOffset),
  child: Transform.scale(scale: scale, child: child),
);
```

**优化建议：**
```dart
// 优化方案：缩短动画周期，增加弹性
static const Duration _strikeMotionDuration = Duration(milliseconds: 800);  // 从 1400 降至 800
static const Duration _ambientMotionDuration = Duration(seconds: 8);  // 从 18 降至 8

// 增加弹性曲线
final scale = 1 - Curves.elasticOut.transform(strike) * 0.05 - (_pressing ? 0.02 : 0);
```

#### C. 呼吸训练

| 动效类型 | 实现质量 | 评分 | 说明 |
|---------|---------|------|------|
| 球体呼吸动画 | 优秀 | 8.5 | easeOutCubic 曲线自然 |
| 阶段进度环 | 良好 | 7.0 | 缺少阶段切换时的弹性效果 |
| 倒计时数字 | 良好 | 7.5 | 数字跳动缺少变化 |
| BOLT 测试 | 良好 | 7.0 | 秒表视觉吸引力不足 |

**呼吸球缩放算法：**

```dart
double _orbScale(double progress) {
  return switch (_stage.kind) {
    BreathingStageKind.inhale =>
      0.72 + Curves.easeOutCubic.transform(progress) * 0.38,
    BreathingStageKind.hold => 1.1,
    BreathingStageKind.exhale =>
      1.1 - Curves.easeInCubic.transform(progress) * 0.38,
    BreathingStageKind.rest => 0.72,
  };
}
```

**评价：** 曲线设计合理，但缺少：
1. 阶段切换时的"弹跳"效果
2. 不同呼吸模式（4-2-6-2 vs 4-7-8）的视觉差异表达

#### D. 舒缓音乐

| 动效类型 | 实现质量 | 评分 | 问题/建议 |
|---------|---------|------|----------|
| Blob 背景动画 | 中等 | 6.0 | 过于对称和机械，缺乏自然感 |
| 频谱可视化 | 良好 | 7.5 | 6频段分析合理 |
| 轨道切换 | 良好 | 7.0 | 缺少视差效果 |
| 播放控制 | 优秀 | 8.5 | 状态切换清晰 |

**Blob 动画问题分析：**

```dart
// 当前 blob 动画 - 过于对称和机械
blobA: Color(0xFF2C3E8F),
blobB: Color(0xFF5A2B86),
// 问题：两个 blob 的运动轨迹过于规律，缺少自然流体的随机性
```

**优化方向：**
- 引入柏林噪声（Perlin Noise）驱动的轨迹
- 增加运动惯性，使 blob 移动更有质量感

### 缓动函数规范

当前项目缓动函数使用混乱，建议统一：

```dart
// 建议的缓动函数规范
class AppEasing {
  // 快速响应 - 按钮点击、切换
  static const Curve snappy = Curves.easeOutCubic;
  
  // 标准过渡 - 卡片展开、页面切换
  static const Curve standard = Curves.easeInOutCubic;
  
  // 缓慢从容 - 呼吸球、氛围动画
  static const Curve gentle = Curves.easeInOutQuad;
  
  // 弹性效果 - 掉落、弹跳
  static const Curve spring = Curves.elasticOut;
  
  // 弹性但收敛 - 敲击反馈
  static const Curve bounce = Curves.easeOutBack;
}
```

### 动画性能优化建议

| 模块 | 问题 | 优化方案 |
|------|------|---------|
| 禅意沙盘 | 笔触重绘频繁 | 使用 `RepaintBoundary` 隔离画布区域 |
| 疗愈音钵 | 波纹 painter 全屏重绘 | 只在碗体区域重绘 |
| 舒缓音乐 | Blob 动画帧率不稳 | 使用 `AnimatedBuilder` 替代 `setState` |

---

## 色彩系统审计

### 当前色彩使用问题

#### 1. 硬编码颜色泛滥

```dart
// 问题示例 - 工具箱入口页面
accent: const Color(0xFF547A95),  // 睡眠支持 - 蓝灰
accent: const Color(0xFF5B86C5),  // 小游戏 - 宝蓝
accent: const Color(0xFF6E9BC3),  // 舒缓音乐 - 雾蓝
accent: const Color(0xFF8A84D6),  // 空灵竖琴 - 薰衣草紫
accent: const Color(0xFF6D8E7A),  // 疗愈音钵 - 苔绿
accent: const Color(0xFF61A78A),  // 专注节拍 - 青绿
accent: const Color(0xFFB36E3D),  // 电子木鱼 - 赭石
accent: const Color(0xFF5B88D6),  // 舒尔特方格 - 天蓝
accent: const Color(0xFF4A9FA8),  // 呼吸训练 - 薄荷蓝
accent: const Color(0xFF8570B5),  // 静心念珠 - 紫藤
accent: const Color(0xFFC6A96A),  // 禅意沙盘 - 流沙金
accent: const Color(0xFFE08B58),  // 每日决策 - 珊瑚橙
```

**问题：**
- 12 种功能色彩未接入全局主题系统
- 缺少中性色系，界面层次表达不清晰

#### 2. 疗愈音钵色彩体系

| 频率 | 名称 | Accent | Glow | 语义 |
|------|------|--------|------|------|
| 396 Hz | 安定 | `#EF4444` | `#F7A89D` | 根轮 - 红 |
| 417 Hz | 活力 | `#F97316` | `#F7C089` | 脐轮 - 橙 |
| 528 Hz | 自信 | `#EAB308` | `#F0D989` | 太阳轮 - 黄 |
| 639 Hz | 和谐 | `#10B981` | `#9FD9BC` | 心轮 - 绿 |
| 741 Hz | 表达 | `#06B6D4` | `#99DCE6` | 喉轮 - 青 |
| 852 Hz | 洞察 | `#6366F1` | `#BAC0F5` | 眉心轮 - 靛 |
| 963 Hz | 升华 | `#A855F7` | `#D5B8F6` | 顶轮 - 紫 |

**评价：** 色彩语义清晰，但应考虑色盲用户的辨识度问题。

#### 3. 禅意沙盘场景色彩

| 场景 | Start Color | End Color | 情绪关键词 |
|------|-------------|-----------|-----------|
| 暖金沙 | `#F9E6BE` | `#E6C98A` | 温暖、治愈、午后 |
| 潮汐浅滩 | `#F4E8D7` | `#D8D1C6` | 清凉、潮湿、海岸 |
| 月灰石庭 | `#E6E1DD` | `#BDB5AF` | 冷静、极简、冥想 |
| 暮色陶砂 | `#F2D7CA` | `#D2AC97` | 温柔、柔和、日落 |

### 色彩系统重构建议

#### 分层色彩架构

```
色彩系统
├── 基础层（Baseline Colors）
│   ├── 原色系（Primary）
│   ├── 辅助色系（Secondary）
│   └── 中性色系（Neutral）
│
├── 功能层（Functional Colors）
│   ├── 成功（Success）
│   ├── 警告（Warning）
│   ├── 错误（Error）
│   └── 信息（Info）
│
├── 品牌层（Brand Colors）
│   ├── 主强调色（Primary Accent）
│   ├── 次强调色（Secondary Accent）
│   └── 品牌渐变（Brand Gradient）
│
└── 模块层（Module Colors）
    ├── 睡眠模块（Sleep Module）
    ├── 专注模块（Focus Module）
    └── 放松模块（Relax Module）
```

---

## 交互设计评估

### 触控区域问题

| 模块 | 组件 | 当前尺寸 | 推荐尺寸 | 问题 |
|------|------|---------|---------|------|
| 疗愈音钵 | 频率选择器 | 62-82dp | 56-72dp | 非选中态过小 |
| 呼吸训练 | 场景选择 Chip | 动态 | ≥ 48dp | 已达标 |
| 禅意沙盘 | 工具按钮 | 56dp | 48dp | 已达标 |
| 工具箱入口 | 入口卡片 | 全宽 | 最小高度 72dp | 已达标 |

### 手势冲突问题

**禅意沙盘多手势分析：**

```dart
// 当前手势判断逻辑
void _handlePointerDown(PointerDownEvent event) {
  _activePointers.add(event.pointer);
  if (_activePointers.length >= 2 && _gestureMode == _ZenGestureMode.draw) {
    _handlePanCancel();  // ❌ 绘制中双指会取消当前笔画
  }
  // ...
}
```

**问题：** 用户在绘制长笔画时容易误触发缩放/平移

**优化建议：**
- 增加手势冲突消解延迟（200-300ms）
- 在双指识别时显示轻微的视觉提示

### 状态反馈问题

#### 工具箱入口卡片状态

```dart
// 当前 - 缺少按压状态
Material(
  color: Colors.transparent,
  child: InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: () { /* 导航 */ },
    child: Ink(
      // 只有默认状态
    ),
  ),
)
```

**建议增加的状态：**
1. **按压态**：轻微缩放（scale: 0.98）+ 阴影加深
2. **禁用态**：降低透明度（opacity: 0.5）
3. **加载态**：骨架屏或脉动效果

---

## 具体优化建议

### 优先级 P0 - 立即修复

#### 1. 工具箱入口卡片重设计

```dart
// 优化方案：现代卡片设计
Widget _ToolboxEntryCard({required _ToolboxEntry entry}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),  // 缩小圆角
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          entry.accent.withValues(alpha: 0.08),
          entry.accent.withValues(alpha: 0.02),
        ],
      ),
      border: Border.all(
        color: entry.accent.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: entry.accent.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(...),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 图标容器增加渐变
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      entry.accent.withValues(alpha: 0.2),
                      entry.accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(entry.icon, color: entry.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, ...),
                    Text(entry.subtitle, ...),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ],
          ),
        ),
      ),
    ),
  );
}
```

#### 2. 疗愈音钵动画周期优化

```dart
// 文件：toolbox_singing_bowls_tool.dart

// 修改前
static const Duration _strikeMotionDuration = Duration(milliseconds: 1400);
static const Duration _ambientMotionDuration = Duration(seconds: 18);

// 修改后
static const Duration _strikeMotionDuration = Duration(milliseconds: 800);
static const Duration _ambientMotionDuration = Duration(seconds: 8);

// 修改敲击动画曲线
final scale = 1 - Curves.elasticOut.transform(strike) * 0.06 - (_pressing ? 0.025 : 0);
```

### 优先级 P1 - 近期优化

#### 3. 建立统一的缓动函数库

```dart
// lib/src/ui/motion/app_easing.dart

import 'package:flutter/animation.dart';

abstract class AppEasing {
  // 快速响应 - 用于按钮点击、开关切换
  static const Curve snappy = Curves.easeOutCubic;
  
  // 标准过渡 - 用于卡片展开、列表项动画
  static const Curve standard = Curves.easeInOutCubic;
  
  // 缓慢从容 - 用于呼吸动画、背景氛围
  static const Curve gentle = Curves.easeInOutQuad;
  
  // 弹性回弹 - 用于敲击反馈、掉落效果
  static const Curve bounce = Curves.elasticOut;
  
  // 快速弹性 - 用于选中态切换
  static const Curve quickBounce = Curves.easeOutBack;
  
  // 特殊缓动
  static const Curve smoothStart = Curves.fastOutSlowIn;
  static const Curve sharpStart = Curves.slowOutFastIn;
}
```

#### 4. 频率选择器重新设计

```dart
// 优化方案：更大的触控区域 + 平滑过渡

Widget _buildFrequencyStrip() {
  return SizedBox(
    height: 80,  // 增加高度
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: _bowlFrequencySpecs.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final spec = _bowlFrequencySpecs[index];
        final selected = spec.id == _frequencyId;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: AppEasing.quickBounce,
          width: selected ? 88 : 68,  // 增大非选中态
          child: AnimatedScale(
            scale: selected ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 150),
            child: _FrequencyChip(
              spec: spec,
              selected: selected,
              onTap: () => _setFrequency(spec.id),
            ),
          ),
        );
      },
    ),
  );
}
```

### 优先级 P2 - 规划中

#### 5. 舒缓音乐 Blob 动画升级

```dart
// 引入噪声驱动的自然运动

class _BlobMotionController {
  late final List<_Blob> _blobs;
  double _time = 0;
  
  void update(double deltaTime) {
    _time += deltaTime;
    for (final blob in _blobs) {
      // 使用简化的柏林噪声近似
      blob.x = _noise(blob.seedX, _time * blob.speedX);
      blob.y = _noise(blob.seedY, _time * blob.speedY);
      blob.radius = blob.baseRadius + _noise(blob.seedR, _time * 0.5) * 10;
    }
  }
  
  double _noise(double seed, double t) {
    return math.sin(seed * 12.9898 + t * 78.233) * 43758.5453;
  }
}
```

#### 6. 全局色彩变量重构

```dart
// lib/src/ui/theme/toolbox_colors.dart

abstract class ToolboxColors {
  // 模块主色
  static const sleepAccent = Color(0xFF547A95);
  static const gamesAccent = Color(0xFF5B86C5);
  static const soundAccent = Color(0xFF6E9BC3);
  static const harpAccent = Color(0xFF8A84D6);
  static const bowlsAccent = Color(0xFF6D8E7A);
  static const beatsAccent = Color(0xFF61A78A);
  static const woodfishAccent = Color(0xFFB36E3D);
  static const schulteAccent = Color(0xFF5B88D6);
  static const breathingAccent = Color(0xFF4A9FA8);
  static const prayerAccent = Color(0xFF8570B5);
  static const zenAccent = Color(0xFFC6A96A);
  static const decisionAccent = Color(0xFFE08B58);
  
  // 渐变色系
  static const Collection<Color> sleepGradient = [
    Color(0xFF2A384B),
    Color(0xFF101823),
  ];
  
  // ... 其他
}
```

---

## 实现路线图

### 阶段一：基础优化（P0）
**预计工时：** 3-4 天

| 任务 | 描述 | 优先级 |
|------|------|--------|
| T1.1 | 工具箱入口卡片重设计 | P0 |
| T1.2 | 疗愈音钵动画周期优化 | P0 |
| T1.3 | 建立 AppEasing 缓动库 | P0 |
| T1.4 | 频率选择器触控优化 | P0 |

### 阶段二：体验提升（P1）
**预计工时：** 5-7 天

| 任务 | 描述 | 优先级 |
|------|------|--------|
| T2.1 | 呼吸训练阶段切换动效 | P1 |
| T2.2 | 舒缓音乐 Blob 动画升级 | P1 |
| T2.3 | 全局色彩变量重构 | P1 |
| T2.4 | 触觉反馈系统规范化 | P1 |

### 阶段三：品牌统一（P2）
**预计工时：** 7-10 天

| 任务 | 描述 | 优先级 |
|------|------|--------|
| T3.1 | 统一设计令牌系统 | P2 |
| T3.2 | 模块间转场动画标准化 | P2 |
| T3.3 | 深色/浅色模式一致性 | P2 |
| T3.4 | 无障碍设计审核 | P2 |

---

## 附录：设计规范参考

### Google Material Design 3 关键指标

| 元素 | 最小值 | 推荐值 |
|------|--------|--------|
| 触控区域 | 48 × 48 dp | 48 × 48 dp |
| 按钮高度 | 40 dp | 48 dp |
| 卡片圆角 | 12 dp | 16-24 dp |
| 图标尺寸 | 24 dp | 24 dp |
| 列表项高度 | 48 dp | 56 dp |

### Apple Human Interface Guidelines 参考

| 元素 | 值 |
|------|-----|
| 触控目标最小 | 44 × 44 pt |
| 圆角半径 | 高度 × 0.1-0.2 |
| 动画时长 | 200-400 ms（交互）/ 300-500 ms（转场）|

### 动画性能指标

| 指标 | 目标值 |
|------|--------|
| 帧率 | ≥ 60 fps |
| 丢帧率 | < 5% |
| 首帧时间 | < 100 ms |
| 动画启动延迟 | < 16 ms |

---

## 更新记录

| 日期 | 版本 | 更新内容 |
|------|------|---------|
| 2026-04-08 | v1.0.0 | 初稿完成 |

---

## 参考文件

- 工具箱入口：`lib/src/ui/pages/toolbox_page.dart`
- 禅意沙盘：`lib/src/ui/pages/toolbox_zen_sand_tool.dart`
- 疗愈音钵：`lib/src/ui/pages/toolbox_singing_bowls_tool.dart`
- 呼吸训练：`lib/src/ui/pages/toolbox_breathing_tool.dart`
- 舒缓音乐：`lib/src/ui/pages/toolbox_soothing_music_v2_page.dart`
- 主题配置：`lib/src/ui/theme/app_theme.dart`
