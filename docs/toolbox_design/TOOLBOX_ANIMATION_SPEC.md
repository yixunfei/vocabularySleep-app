# 工具箱模块动画特效设计规范

## 文档版本

| 版本 | 日期 | 状态 | 作者 |
|------|------|------|------|
| v1.0.0 | 2026-04-08 | 初稿 | AI Design Review |

---

## 目录

1. [概述](#概述)
2. [缓动函数规范](#缓动函数规范)
3. [时序规范](#时序规范)
4. [模块动画详解](#模块动画详解)
5. [音频触觉同步](#音频触觉同步)
6. [性能优化准则](#性能优化准则)
7. [实现代码模板](#实现代码模板)

---

## 概述

### 动画特效设计原则

本规范旨在为工具箱模块建立统一、专业的动画特效语言，确保各模块在视觉体验上保持一致性和高品质。

**核心原则：**

1. **自然流畅** - 动画应模拟物理世界的运动规律，避免机械、突兀的跳变
2. **语义明确** - 动画应传达功能含义，如反馈、状态变化、空间关系
3. **性能优先** - 在保证视觉效果的前提下，优先考虑渲染性能
4. **触感沉浸** - 视觉动画应与音频、触觉反馈协同，营造沉浸体验

### 动画分类体系

```
工具箱动画
├── 反馈动画（Feedback）
│   ├── 按压动画（Press）
│   ├── 切换动画（Toggle）
│   └── 手势反馈（Gesture）
│
├── 过渡动画（Transition）
│   ├── 展开/收起（Expand/Collapse）
│   ├── 页面转场（Page Transition）
│   └── 模式切换（Mode Switch）
│
├── 氛围动画（Ambient）
│   ├── 呼吸动画（Breathing）
│   ├── 脉流动画（Pulsing）
│   └── 循环动画（Looping）
│
├── 互动动画（Interactive）
│   ├── 绘制动画（Drawing）
│   ├── 拖拽动画（Dragging）
│   └── 敲击动画（Striking）
│
└── 装饰动画（Decorative）
    ├── 粒子效果（Particles）
    ├── 波纹扩散（Ripple）
    └── 渐变流动（Gradient Flow）
```

---

## 缓动函数规范

### Flutter 内置缓动函数应用场景

| 缓动函数 | 特征曲线 | 推荐应用场景 | 禁用场景 |
|---------|---------|-------------|---------|
| `Curves.easeOutCubic` | 快速启动，缓慢收尾 | 按钮按压、元素出现 | 需要匀速的运动 |
| `Curves.easeInOutCubic` | 对称平滑 | 展开/收起、页面转场 | 快速重复的动画 |
| `Curves.easeInQuad` | 慢启动 | 元素消失 | 需要快速响应的反馈 |
| `Curves.easeOutQuad` | 慢收尾 | 加载完成、状态确认 | 需要匀速的运动 |
| `Curves.elasticOut` | 弹簧振荡 | 敲击反馈、掉落弹跳 | 长时间循环动画 |
| `Curves.easeOutBack` | 先回弹再停止 | 选中态展开、弹窗出现 | 频繁重复的元素 |
| `Curves.fastOutSlowIn` | 牛顿力学风格 | 拖拽跟随、物理模拟 | 简单状态切换 |
| `Curves.linear` | 匀速运动 | 进度指示、音频可视化 | 需要情感表达的场景 |

### 自定义缓动函数

```dart
// lib/src/ui/motion/app_easing.dart

import 'package:flutter/animation.dart';
import 'dart:math' as math;

abstract class AppEasing {
  // ========== 标准缓动 ==========

  /// 快速响应 - 用于按钮点击、开关切换
  /// 特点：快速启动，立即响应，优雅收尾
  static const Curve snappy = Curves.easeOutCubic;

  /// 标准过渡 - 用于卡片展开、列表项动画
  /// 特点：对称平滑，节奏舒适
  static const Curve standard = Curves.easeInOutCubic;

  /// 缓慢从容 - 用于呼吸动画、背景氛围
  /// 特点：慢启动慢停止，如流水般自然
  static const Curve gentle = Curves.easeInOutQuad;

  // ========== 弹性缓动 ==========

  /// 弹性回弹 - 用于敲击反馈、掉落效果
  /// 特点：超调后回弹，最终稳定
  /// 适用：物理冲击、碰撞反馈
  static const Curve bounce = Curves.elasticOut;

  /// 快速弹性 - 用于选中态切换、弹窗出现
  /// 特点：轻微回弹，响应迅速
  /// 注意：duration 应在 200-400ms
  static const Curve quickBounce = Curves.easeOutBack;

  /// 夸张弹性 - 用于强调、庆祝效果
  /// 特点：多次振荡，夸张但可控
  static const Curve wobbly = Curves.elasticInOut;

  // ========== 特殊缓动 ==========

  /// 平稳启动 - 牛顿力学风格
  /// 适用：拖拽跟随、真实物理模拟
  static const Curve physicsBased = Curves.fastOutSlowIn;

  /// 渐入效果 - 元素淡入主场景
  /// 特点：0.5s 延迟后快速展开
  static const Curve reveal = Curves.easeOutQuart;

  /// 渐出效果 - 元素离开主场景
  /// 特点：快速启动，缓慢消失
  static const Curve conceal = Curves.easeInQuart;

  /// 突现效果 - 用于空状态、重要提示
  /// 特点：轻微过冲，立即吸引注意
  static const Curve pop = Curves.easeOutBack;

  // ========== 呼吸专用 ==========

  /// 吸气曲线 - 4-2-6-2 呼吸法的吸气质感
  /// 建议时长：4s
  static const Curve inhale = Curves.easeInOutSine;

  /// 屏息曲线 - 保持阶段的视觉平稳
  /// 特点：轻微脉动，表示生命存在
  static const Curve hold = Curves.easeInOutQuad;

  /// 呼气曲线 - 呼出阶段的自然衰减
  /// 建议时长：6s
  static const Curve exhale = Curves.easeInOutSine;

  /// 恢复曲线 - 休息阶段的完全放松
  /// 特点：极其平缓，呼吸末期的自然停顿
  static const Curve rest = Curves.easeOutQuad;

  // ========== 工具函数 ==========

  /// 根据动画阶段选择缓动
  static Curve forPhase(AnimationPhase phase) {
    return switch (phase) {
      AnimationPhase.enter => reveal,
      AnimationPhase.exit => conceal,
      AnimationPhase.idle => gentle,
      AnimationPhase.interactive => snappy,
    };
  }

  /// 创建带弹性的缩放动画
  static double springScale(double t, {double intensity = 1.0}) {
    return 1.0 + (Curves.elasticOut.transform(t) - 1.0) * intensity;
  }

  /// 创建带惯性的位置动画
  static double withInertia(double t, {double damping = 0.7}) {
    return Curves.easeOutCubic.transform(t) * damping +
        (1 - damping) * t;
  }
}

/// 动画阶段枚举
enum AnimationPhase {
  /// 进入动画
  enter,

  /// 退出动画
  exit,

  /// 空闲/循环动画
  idle,

  /// 交互反馈动画
  interactive,
}
```

### 缓动函数选择决策树

```
动画场景
│
├─ 触控反馈？
│   ├─ 按钮按压 → easeOutCubic
│   ├─ 开关切换 → easeOutBack
│   └─ 手势拖拽 → fastOutSlowIn
│
├─ 展开/收起？
│   ├─ 卡片展开 → easeInOutCubic
│   ├─ 下拉菜单 → easeOutQuart
│   └─ 抽屉滑出 → easeOutCubic
│
├─ 循环动画？
│   ├─ 呼吸球体 → easeInOutSine
│   ├─ 背景氛围 → easeInOutQuad
│   └─ 加载旋转 → linear
│
└─ 敲击反馈？
    ├─ 轻柔反馈 → easeOutCubic (200ms)
    ├─ 强劲冲击 → elasticOut (600ms)
    └─ 快速点按 → easeOutBack (150ms)
```

---

## 时序规范

### 动画时长层级

```dart
abstract class AppDurations {
  // ========== 即时反馈 ==========
  // 用于微小、无意识的反馈
  // 用户不应意识到动画的存在

  /// 极快反馈 - 用于触控点按、选择
  /// 典型值：50-100ms
  /// 缓动：easeOutCubic
  static const Duration instant = Duration(milliseconds: 80);

  /// 快速反馈 - 用于状态切换、开关变化
  /// 典型值：100-150ms
  /// 缓动：easeOutCubic
  static const Duration quick = Duration(milliseconds: 120);

  // ========== 标准交互 ==========
  // 用于用户主动触发的状态变化

  /// 标准切换 - 用于按钮状态、选中态
  /// 典型值：200-300ms
  /// 缓动：easeInOutCubic
  static const Duration standard = Duration(milliseconds: 250);

  /// 展开动画 - 用于卡片展开、列表项展开
  /// 典型值：300-400ms
  /// 缓动：easeInOutCubic
  static const Duration expand = Duration(milliseconds: 350);

  /// 页面转场 - 用于页面切换
  /// 典型值：300-500ms
  /// 缓动：easeInOutCubic
  static const Duration pageTransition = Duration(milliseconds: 400);

  // ========== 强调动画 ==========
  // 用于吸引用户注意的重要变化

  /// 强调出现 - 用于弹窗、重要提示
  /// 典型值：350-500ms
  /// 缓动：easeOutBack
  static const Duration emphasize = Duration(milliseconds: 450);

  /// 庆祝效果 - 用于成就、解锁
  /// 典型值：600-1000ms
  /// 缓动：elasticOut
  static const Duration celebrate = Duration(milliseconds: 800);

  // ========== 氛围动画 ==========
  // 用于长时间运行的装饰性动画

  /// 缓慢脉动 - 用于呼吸球、背景光效
  /// 典型值：1000-2000ms（单次循环）
  static const Duration slowPulse = Duration(milliseconds: 1500);

  /// 快速循环 - 用于加载指示、忙碌状态
  /// 典型值：800-1200ms（单次循环）
  static const Duration loop = Duration(milliseconds: 1000);

  /// 极慢渐变 - 用于背景色彩变化
  /// 典型值：3000-10000ms（单次循环）
  static const Duration ambient = Duration(milliseconds: 5000);

  // ========== 物理模拟 ==========

  /// 敲击反馈 - 疗愈音钵
  /// 典型值：600-800ms
  /// 缓动：elasticOut
  static const Duration strike = Duration(milliseconds: 700);

  /// 掉落弹跳 - 卡片掉落效果
  /// 典型值：500-800ms
  /// 缓动：bounceOut
  static const Duration drop = Duration(milliseconds: 600);

  /// 抖动效果 - 用于错误提示
  /// 典型值：400-600ms
  static const Duration shake = Duration(milliseconds: 500);

  // ========== 手势动画 ==========

  /// 拖拽跟随 - 位置跟随延迟
  /// 典型值：0-100ms（无延迟）
  /// 缓动：无（直接跟随）
  static const Duration drag = Duration.zero;

  /// 惯性滑行 - 拖拽释放后的滑动
  /// 典型值：300-500ms
  /// 缓动：fastOutSlowIn
  static const Duration fling = Duration(milliseconds: 400);

  /// 缩放跟随 - 双指缩放
  /// 典型值：0-50ms
  /// 缓动：无（直接跟随）
  static const Duration scale = Duration.zero;
}
```

### 各模块动画时长对照表

| 模块 | 动画类型 | 当前时长 | 推荐时长 | 缓动函数 | 优先级 |
|------|---------|---------|---------|---------|--------|
| **疗愈音钵** | 敲击动画 | 1400ms | 700-800ms | elasticOut | P0 |
| **疗愈音钵** | 环境脉动 | 18000ms | 6000-8000ms | easeInOutSine | P1 |
| **疗愈音钵** | 频率切换 | 0ms | 300ms | easeOutCubic | P0 |
| **呼吸训练** | 吸气动画 | 4000ms | 4000ms | easeInOutSine | - |
| **呼吸训练** | 屏息动画 | 2000ms | 2000ms | easeInOutQuad | - |
| **呼吸训练** | 呼气动画 | 6000ms | 6000ms | easeInOutSine | - |
| **呼吸训练** | 阶段切换 | 0ms | 200ms | bounce | P1 |
| **禅意沙盘** | 笔触绘制 | 实时 | 实时 | - | - |
| **禅意沙盘** | 水迹扩散 | 55ms/帧 | 55ms/帧 | - | - |
| **禅意沙盘** | 景石落水 | 300ms | 300ms | easeOutCubic | - |
| **舒缓音乐** | Blob 动画 | 循环 | 循环 | 自定义噪声 | P1 |
| **舒缓音乐** | 播放按钮 | 200ms | 200ms | easeOutCubic | - |
| **工具箱入口** | 卡片按压 | 0ms | 100ms | easeOutCubic | P0 |
| **工具箱入口** | 页面转场 | 300ms | 350ms | easeInOutCubic | P1 |

---

## 模块动画详解

### 1. 疗愈音钵（Singing Bowls）

#### 1.1 敲击动效

**当前问题：**
- 1400ms 动画周期过长，连续敲击时显得迟钝
- 缓动函数过于简单，缺少物理真实感

**优化方案：**

```dart
class _SingingBowlAnimationSpec {
  // 敲击动画 - 核心参数
  static const Duration strikeDuration = Duration(milliseconds: 700);
  static const Curve strikeCurve = Curves.elasticOut;

  // 环境脉动 - 核心参数
  static const Duration ambientDuration = Duration(milliseconds: 7000);
  static const Curve ambientCurve = Curves.easeInOutSine;

  // 敲击动画的相位分解
  static const double strikePeakDelay = 0.1;  // 10% 时间到达峰值
  static const double strikeOscillationCount = 2.5;  // 2.5 次阻尼振荡

  // 下压与回弹参数
  static const double maxYOffset = 8.5;  // 垂直位移峰值 (dp)
  static const double maxScaleDown = 0.958;  // 缩放最小值
  static const double pressExtraScale = 0.02;  // 按压时额外缩放

  // 波纹扩散参数
  static const int maxRippleCount = 4;
  static const Duration rippleFadeDuration = Duration(milliseconds: 2000);
  static const double rippleMaxRadius = 280.0;  // 最大扩散半径 (dp)

  // 敲击时的碗体动画计算
  static BowlAnimationState computeStrikeState(
    double t,  // 0.0 - 1.0
    bool isPressing,
  ) {
    final elasticT = strikeCurve.transform(t);

    // 缩放动画：快速下压，弹性回弹
    final scaleDown = maxScaleDown + (1.0 - maxScaleDown) * (1.0 - elasticT);
    final pressOffset = isPressing ? pressExtraScale : 0.0;
    final scale = scaleDown - pressOffset;

    // 垂直位移：模拟物理下压与回弹
    final yOffset = maxYOffset * math.sin(t * math.pi * strikeOscillationCount) * (1.0 - t);

    // 旋转微动：增加有机感
    final rotation = math.sin(t * math.pi * 4) * 0.02 * (1.0 - t);

    return BowlAnimationState(
      scale: scale,
      yOffset: yOffset,
      rotation: rotation,
    );
  }

  // 环境脉动计算
  static double computeAmbientPulse(double t) {
    return 0.5 + 0.5 * ambientCurve.transform(t);
  }
}
```

**波纹扩散动画：**

```dart
class RippleAnimation {
  final double startTime;
  final Offset center;
  final Color color;

  double radius(double elapsed) {
    final t = elapsed / rippleFadeDuration.inMilliseconds;
    // 快速扩散，然后缓慢消失
    final expandT = Curves.easeOutCubic.transform(t.clamp(0.0, 0.3));
    final fadeT = 1.0 - Curves.easeInQuad.transform(t.clamp(0.3, 1.0));
    return expandT * rippleMaxRadius * fadeT;
  }

  double opacity(double elapsed) {
    final t = elapsed / rippleFadeDuration.inMilliseconds;
    if (t < 0.2) return 1.0;
    return 1.0 - Curves.easeInQuad.transform((t - 0.2) / 0.8);
  }
}
```

#### 1.2 频率切换过渡

**当前问题：**
- 频率切换时直接跳变，缺少过渡动画

**优化方案：**

```dart
// 频率切换动画
class FrequencyTransition {
  static Widget build(
    Widget currentBowl,
    _SingingBowlFrequencySpec newSpec,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curvedValue = Curves.easeInOutCubic.transform(animation.value);

        return Stack(
          children: [
            // 旧碗体淡出并缩小
            Opacity(
              opacity: 1.0 - curvedValue,
              child: Transform.scale(
                scale: 1.0 - curvedValue * 0.1,
                child: currentBowl,
              ),
            ),

            // 新碗体淡入并放大
            Opacity(
              opacity: curvedValue,
              child: Transform.scale(
                scale: 0.95 + curvedValue * 0.05,
                child: child,
              ),
            ),
          ],
        );
      },
      child: currentBowl,
    );
  }
}
```

### 2. 呼吸训练（Breathing Practice）

#### 2.1 呼吸球动画

**当前状态：**
- 基础曲线实现良好
- 缺少阶段切换的弹性效果

**优化方案：**

```dart
class BreathingOrbAnimation {
  // 各阶段时长配置
  static const Duration inhaleDuration = Duration(milliseconds: 4000);
  static const Duration holdDuration = Duration(milliseconds: 2000);
  static const Duration exhaleDuration = Duration(milliseconds: 6000);
  static const Duration restDuration = Duration(milliseconds: 2000);

  // 球体缩放范围
  static const double minScale = 0.72;
  static const double maxScale = 1.1;
  static const double holdScale = 1.08;
  static const double restScale = 0.72;

  // 缩放计算
  static double computeScale(BreathingStageKind stage, double progress) {
    switch (stage) {
      case BreathingStageKind.inhale:
        // 吸气：平滑放大，带轻微过冲
        final t = Curves.easeInOutSine.transform(progress);
        final overshoot = progress > 0.9
            ? (progress - 0.9) / 0.1 * 0.03  // 最后 10% 轻微过冲
            : 0.0;
        return minScale + (maxScale - minScale) * t + overshoot;

      case BreathingStageKind.hold:
        // 屏息：保持在峰值，伴随意微脉动
        final pulse = math.sin(progress * math.pi * 2) * 0.015;
        return holdScale + pulse;

      case BreathingStageKind.exhale:
        // 呼气：平滑缩小
        final t = Curves.easeInOutSine.transform(progress);
        return maxScale - (maxScale - minScale) * t;

      case BreathingStageKind.rest:
        // 休息：保持在最小值，意微起伏
        final subtleWave = math.sin(progress * math.pi * 1.5) * 0.01;
        return restScale + subtleWave;
    }
  }

  // 阶段切换动画
  static double stageTransitionScale(
    double fromScale,
    double toScale,
    double t,
  ) {
    // 使用弹性曲线实现平滑过渡
    final curved = Curves.easeOutBack.transform(t);
    return fromScale + (toScale - fromScale) * curved;
  }

  // 光晕强度计算
  static Color glowIntensity(BreathingStageKind stage, double progress) {
    switch (stage) {
      case BreathingStageKind.inhale:
        // 吸气时光晕渐强
        return Color.lerp(
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.3),
          progress,
        )!;

      case BreathingStageKind.hold:
        // 屏息时光晕稳定，伴随意闪烁
        final flicker = math.sin(progress * math.pi * 4) * 0.05;
        return Colors.white.withValues(alpha: 0.25 + flicker);

      case BreathingStageKind.exhale:
        // 呼气时光晕渐弱
        return Color.lerp(
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.1),
          progress,
        )!;

      case BreathingStageKind.rest:
        // 休息时光晕微弱
        return Colors.white.withValues(alpha: 0.08);
    }
  }
}
```

#### 2.2 阶段指示器动画

```dart
class BreathingStageIndicator {
  // 阶段进度条动画
  static Widget buildStageProgress({
    required List<BreathingStagePlan> stages,
    required int currentStageIndex,
    required double stageProgress,
    required Color accentColor,
  }) {
    return Row(
      children: List.generate(stages.length, (index) {
        final isActive = index == currentStageIndex;
        final isPast = index < currentStageIndex;
        final stage = stages[index];

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                // 阶段图标
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 32 : 24,
                  height: isActive ? 32 : 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPast
                        ? accentColor
                        : isActive
                            ? accentColor.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                    border: isActive
                        ? Border.all(color: accentColor, width: 2)
                        : null,
                  ),
                  child: isActive
                      ? _buildPulseAnimation(stage.kind, accentColor)
                      : null,
                ),
                const SizedBox(height: 4),
                // 阶段名称
                Text(
                  stage.label.resolve(i18n),
                  style: TextStyle(
                    fontSize: isActive ? 12 : 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? accentColor : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // 活跃阶段的脉动动画
  static Widget _buildPulseAnimation(
    BreathingStageKind kind,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: Duration(
        milliseconds: _durationForKind(kind).inMilliseconds ~/ 2,
      ),
      curve: Curves.easeInOutSine,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.5 * value),
            ),
          ),
        );
      },
    );
  }
}
```

### 3. 禅意沙盘（Zen Sand Tray）

#### 3.1 笔触绘制动效

**当前亮点：** 音效同步逻辑精细，55ms 水迹刷新间隔合理

**优化建议：**

```dart
class ZenStrokeRendering {
  // 笔触渲染优化
  static void renderStroke({
    required Canvas canvas,
    required List<ZenSandPoint> points,
    required ZenToolSpec tool,
    required double brushSize,
    required Color? color,
    required _ZenBackgroundSpec background,
  }) {
    if (points.length < 2) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 根据工具类型选择渲染模式
    switch (tool.id) {
      case 'rake':
        _renderRakeStroke(canvas, points, paint, background);
        break;
      case 'finger':
        _renderFingerStroke(canvas, points, paint, background);
        break;
      case 'water':
        _renderWaterStroke(canvas, points, paint, background);
        break;
      // ... 其他工具
    }
  }

  // 木耙多齿渲染
  static void _renderRakeStroke(
    Canvas canvas,
    List<ZenSandPoint> points,
    Paint paint,
    _ZenBackgroundSpec background,
  ) {
    final teethCount = 5;
    final teethSpacing = brushSize / teethCount;

    for (int i = 0; i < teethCount; i++) {
      final offset = (i - teethCount / 2) * teethSpacing;
      final teethPaint = Paint()
        ..color = background.grooveDark.withValues(alpha: 0.6)
        ..strokeWidth = brushSize * 0.15
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      for (int j = 0; j < points.length; j++) {
        final point = points[j];
        final offsetPoint = Offset(
          point.x + offset * math.cos(point.angle ?? 0),
          point.y + offset * math.sin(point.angle ?? 0),
        );
        if (j == 0) {
          path.moveTo(offsetPoint.dx, offsetPoint.dy);
        } else {
          path.lineTo(offsetPoint.dx, offsetPoint.dy);
        }
      }
      canvas.drawPath(path, teethPaint);
    }
  }

  // 水迹扩散渲染
  static void _renderWaterStroke(
    Canvas canvas,
    List<ZenSandPoint> points,
    Paint paint,
    _ZenBackgroundSpec background,
  ) {
    // 水迹使用半透明渐变
    for (int i = 0; i < points.length - 1; i++) {
      final t = i / points.length;
      final opacity = 0.3 * (1 - t * 0.5);

      paint.color = background.accent.withValues(alpha: opacity);

      final p1 = points[i];
      final p2 = points[i + 1];

      canvas.drawLine(
        Offset(p1.x, p1.y),
        Offset(p2.x, p2.y),
        paint..strokeWidth = brushSize * (1 - t * 0.3),
      );
    }
  }
}
```

### 4. 舒缓音乐（Soothing Music）

#### 4.1 Blob 动画优化

**当前问题：** Blob 运动过于对称和机械

**优化方案 - 引入噪声驱动：**

```dart
// lib/src/ui/motion/perlin_noise.dart

import 'dart:math' as math;

/// 简化版柏林噪声实现
class PerlinNoise {
  final List<int> _permutation;

  PerlinNoise({int seed = 0}) : _permutation = _generatePermutation(seed);

  static List<int> _generatePermutation(int seed) {
    final random = math.Random(seed);
    return List.generate(256, (_) => random.nextInt(256));
  }

  double noise2D(double x, double y) {
    final xi = x.floor() & 255;
    final yi = y.floor() & 255;
    final xf = x - x.floor();
    final yf = y - y.floor();

    final u = _fade(xf);
    final v = _fade(yf);

    final aa = _permutation[_permutation[xi] + yi];
    final ab = _permutation[_permutation[xi] + yi + 1];
    final ba = _permutation[_permutation[xi + 1] + yi];
    final bb = _permutation[_permutation[xi + 1] + yi + 1];

    final x1 = _lerp(_grad(aa, xf, yf), _grad(ba, xf - 1, yf), u);
    final x2 = _lerp(_grad(ab, xf, yf - 1), _grad(bb, xf - 1, yf - 1), u);

    return _lerp(x1, x2, v);
  }

  static double _fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);
  static double _lerp(double a, double b, double t) => a + t * (b - a);
  static double _grad(int hash, double x, double y) {
    final h = hash & 3;
    final u = h < 2 ? x : y;
    final v = h < 2 ? y : x;
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
  }
}

/// Blob 运动控制器
class BlobMotionController {
  final PerlinNoise _noise = PerlinNoise(seed: 42);
  final List<_BlobSpec> _blobs;
  double _time = 0;

  BlobMotionController({
    required List<Color> blobColors,
    required List<double> baseRadii,
    required Offset canvasSize,
  }) : _blobs = List.generate(
          blobColors.length,
          (i) => _BlobSpec(
            color: blobColors[i],
            baseRadius: baseRadii[i],
            baseX: canvasSize.dx * (0.3 + 0.4 * (i / blobColors.length)),
            baseY: canvasSize.dy * (0.3 + 0.4 * (i / blobColors.length)),
            noiseOffsetX: i * 137.5,
            noiseOffsetY: i * 251.3,
            speedX: 0.3 + 0.2 * (i % 3),
            speedY: 0.25 + 0.15 * (i % 4),
          ),
        );

  void update(double deltaTime) {
    _time += deltaTime;
    for (final blob in _blobs) {
      // 使用噪声驱动 X 坐标
      blob.currentX = blob.baseX +
          _noise.noise2D(
            _time * blob.speedX + blob.noiseOffsetX,
            0,
          ) *
              80;

      // 使用噪声驱动 Y 坐标
      blob.currentY = blob.baseY +
          _noise.noise2D(
            _time * blob.speedY + blob.noiseOffsetY,
            100,
          ) *
              60;

      // 半径轻微变化
      blob.currentRadius =
          blob.baseRadius + _noise.noise2D(_time * 0.5, 200) * 15;
    }
  }

  List<_BlobSpec> get blobs => _blobs;
}

class _BlobSpec {
  final Color color;
  final double baseRadius;
  final double baseX;
  final double baseY;
  final double noiseOffsetX;
  final double noiseOffsetY;
  final double speedX;
  final double speedY;

  double currentX;
  double currentY;
  double currentRadius;

  _BlobSpec({
    required this.color,
    required this.baseRadius,
    required this.baseX,
    required this.baseY,
    required this.noiseOffsetX,
    required this.noiseOffsetY,
    required this.speedX,
    required this.speedY,
  })  : currentX = baseX,
        currentY = baseY,
        currentRadius = baseRadius;
}
```

#### 4.2 频谱可视化

```dart
class SpectrumVisualizer {
  static const int bandCount = 6;
  static const List<double> defaultBands = [0.18, 0.22, 0.26, 0.24, 0.18, 0.14];

  // 频谱条动画
  static Widget buildSpectrumBar({
    required double value,
    required Color color,
    required double height,
    required bool isAnimated,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: Duration(milliseconds: isAnimated ? 100 : 0),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Container(
          width: 4,
          height: height * animatedValue.clamp(0.05, 1.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                color.withValues(alpha: 0.6),
                color,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4 * animatedValue,
                spreadRadius: 1 * animatedValue,
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 音频触觉同步

### 音效同步原则

```
音频同步层级
│
├─ 实时同步（< 16ms）
│   └─ 用于触感反馈、视觉与音频的紧密配合
│
├─ 节奏同步（< 50ms）
│   └─ 用于呼吸引导、节拍器
│
├─ 事件同步（< 100ms）
│   └─ 用于敲击反馈、点击音效
│
└─ 氛围同步（< 500ms）
    └─ 用于背景音乐、可选音效
```

### 触觉反馈规范

```dart
abstract class HapticFeedbackSpec {
  // 触感反馈类型与对应 Flutter API

  /// 轻柔反馈 - 用于选择、切换
  /// Flutter: HapticFeedback.selectionClick()
  /// 强度：轻微
  /// 适用：列表项选择、开关切换
  static const String light = 'selectionClick';

  /// 中等反馈 - 用于按钮点击
  /// Flutter: HapticFeedback.lightImpact()
  /// 强度：中等
  /// 适用：主要按钮点击、工具切换
  static const String medium = 'lightImpact';

  /// 强反馈 - 用于敲击、放下
  /// Flutter: HapticFeedback.mediumImpact()
  /// 强度：较强
  /// 适用：疗愈音钵敲击、景石落下
  static const String heavy = 'mediumImpact';

  /// 强调反馈 - 用于重要操作
  /// Flutter: HapticFeedback.heavyImpact()
  /// 强度：强
  /// 适用：成就解锁、重大状态变化

  /// 震动反馈 - 用于错误提示
  /// Flutter: HapticFeedback.vibrate()
  /// 强度：振动
  /// 适用：表单错误、操作失败
}

/// 各模块触感配置
class ModuleHaptics {
  // 疗愈音钵
  static const lightImpact = Duration(milliseconds: 50);
  static const strikeImpact = Duration(milliseconds: 100);

  // 禅意沙盘
  static const toolSwitch = Duration(milliseconds: 30);
  static const stoneDrop = Duration(milliseconds: 80);
  static const strokeEnd = Duration(milliseconds: 40);

  // 呼吸训练
  static const stageChange = Duration(milliseconds: 60);
  static const sessionComplete = Duration(milliseconds: 200);

  // 工具箱入口
  static const cardTap = Duration(milliseconds: 30);
}
```

### 音频-视觉-触觉三元协同

```dart
// 疗愈音钵敲击的三元协同
class SingingBowlStrikeSync {
  final AudioPlayer _audioPlayer;
  final HapticFeedback _haptics;
  final AnimationController _strikeController;

  Future<void> triggerStrike() async {
    // 1. 立即触发触觉反馈（0ms）
    _haptics.mediumImpact();

    // 2. 同步启动视觉动画（0ms）
    _strikeController.forward(from: 0);

    // 3. 启动音效（0-10ms 延迟内）
    await _audioPlayer.play();

    // 4. 添加后续触觉层次（100ms）
    await Future.delayed(Duration(milliseconds: 100));
    _haptics.lightImpact();
  }
}

// 禅意沙盘笔触的三元协同
class ZenStrokeSync {
  final ToolboxZenSandSoundService _soundService;

  void onStrokeUpdate({
    required double gestureDistance,
    required double brushSize,
    required ZenSandSoundKind kind,
  }) {
    // 视觉：立即更新画布（setState 在下一帧渲染）
    // 触感：根据距离累积触发
    if (gestureDistance > _accentStrideFor(kind)) {
      _soundService.tap(kind, brushSize: brushSize);
    }
    // 音频：根据节流逻辑播放音效
  }
}
```

---

## 性能优化准则

### 动画性能红黄绿指标

| 指标 | 红（需立即优化）| 黄（需关注）| 绿（达标）|
|------|---------------|------------|---------|
| 帧率 | < 30 fps | 30-50 fps | ≥ 60 fps |
| 丢帧率 | > 15% | 5-15% | < 5% |
| GPU 使用 | > 50% | 30-50% | < 30% |
| 动画启动延迟 | > 100ms | 50-100ms | < 50ms |

### 性能优化技术清单

#### 1. 避免在动画中调用 setState

```dart
// ❌ 错误：每帧都调用 setState
class BadAnimation extends StatefulWidget {
  @override
  State<BadAnimation> createState() => _BadAnimationState();
}

class _BadAnimationState extends State<BadAnimation> {
  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});  // ❌ 每帧重绘整个 widget
    });
  }
}

// ✅ 正确：使用 AnimatedBuilder 隔离重建
class GoodAnimation extends StatefulWidget {
  @override
  State<GoodAnimation> createState() => _GoodAnimationState();
}

class _GoodAnimationState extends State<GoodAnimation> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 只有这里会重建
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: ExpensiveWidget(),  // 这个不会被重建
    );
  }
}
```

#### 2. 使用 RepaintBoundary 隔离重绘区域

```dart
// 为画布添加 RepaintBoundary
class ZenSandCanvas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ZenSandPainter(),
        size: Size.infinite,
      ),
    );
  }
}

// 为频谱可视化添加 RepaintBoundary
class SpectrumVisualizer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(bandCount, (index) {
          return AnimatedBuilder(
            animation: _spectrumController,
            builder: (context, child) {
              return _buildBar(_spectrumController.value[index]);
            },
          );
        }),
      ),
    );
  }
}
```

#### 3. 优化 CustomPainter

```dart
// ❌ 错误：在 paint 中创建对象
class BadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.red;  // ❌ 每帧创建
    canvas.drawCircle(Offset.zero, 10, paint);
  }
}

// ✅ 正确：预创建 Paint 对象
class GoodPainter extends CustomPainter {
  final Paint _circlePaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset.zero, 10, _circlePaint);
  }
}

// ✅ 正确：使用 shouldRepaint 优化
class OptimizedPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  OptimizedPainter({required this.points, required this.color});

  @override
  bool shouldRepaint(covariant OptimizedPainter oldDelegate) {
    // 只有实际变化时才重绘
    return oldDelegate.points != points || oldDelegate.color != color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, paint);
  }
}
```

#### 4. 使用 Flutter DevTools 性能分析

```
性能分析检查清单：
□ DevTools > Performance > Rendering FPS
□ 检查是否有掉帧（红色标记）
□ 检查 rasterizer time 是否过高
□ 检查 widget rebuild 数量
□ 使用 RepaintBoundary 测试改善效果
□ 使用 timeline 追踪动画调用链
```

---

## 实现代码模板

### 通用动画组件模板

```dart
// lib/src/ui/widgets/animations/app_animations.dart

import 'package:flutter/material.dart';

/// 标准淡入动画
class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Delay? delay;

  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.delay,
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.delay != null) {
      Future.delayed(widget.delay!.duration, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

/// 缩放淡入动画
class ScaleIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double beginScale;
  final double endScale;

  const ScaleIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutBack,
    this.beginScale = 0.8,
    this.endScale = 1.0,
  });

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.5),
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 按压动画包装器
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration pressDuration;
  final double pressScale;
  final Curve pressCurve;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressDuration = const Duration(milliseconds: 100),
    this.pressScale = 0.97,
    this.pressCurve = Curves.easeOutCubic,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.pressCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 弹性出现动画
class BouncyIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Delay? delay;

  const BouncyIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay,
  });

  @override
  State<BouncyIn> createState() => _BouncyInState();
}

class _BouncyInState extends State<BouncyIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 0.9),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.05),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0),
        weight: 15,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3),
    ));

    if (widget.delay != null) {
      Future.delayed(widget.delay!.duration, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }
}
```

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
