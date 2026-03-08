# AppState 重构分支

**分支**: `feature/appstate-refactor`  
**创建日期**: 2026-03-30  
**基础**: 主分支 + 优化成果

---

## 分支目标

本分支用于 AppState 渐进式重构，将 3011 行的单体状态类拆分为独立模块。

---

## 已合并成果

### 1. 基础优化 ✅

**图片 WebP 化**:
- `logo.jpg` → `logo.webp` (-60%)
- 路径已更新

**依赖清理**:
- 移除 `path_provider_platform_interface`
- 移除 `plugin_platform_interface`
- 节省约 0.5MB

**资源清理**:
- 删除未使用音频文件 (6.85MB)
- 删除旧文档 (BUILDING.md, PROJECT_STRUCTURE.md)

### 2. 技术文档 ✅

**9 份重构指导文档**:
1. `docs/APP_STATE_REFACTOR_PLAN.md` - 总体架构设计
2. `docs/APP_STATE_REFACTOR_STEP1.md` - 详细实施步骤
3. `docs/WORDBOOK_STATE_COMPLETE.md` - WordbookState 文档
4. `docs/OPTIMIZATION_GUIDE.md` - 完整优化指南
5. `docs/DEPENDENCY_REVIEW.md` - 依赖审查
6. `docs/APK_SIZE_OPTIMIZATION.md` - 体积优化
7. `docs/REFACTOR_PROGRESS.md` - 进度报告
8. `docs/REFACTOR_SUMMARY_FINAL.md` - 最终总结
9. `docs/OPTIMIZATION_COMPLETION_REPORT.md` - 完成报告

### 3. 重构准备 ✅

**WordbookState 设计**:
- 完整的类设计 (356 行)
- 22 个属性
- 20+ 方法
- API 兼容方案

---

## 下一步计划

### 阶段 1: WordbookState (4 小时)

1. 创建 `lib/src/state/wordbook_state.dart`
2. 迁移词本相关代码
3. 更新 AppState 使用委托
4. 编写测试
5. 验证功能

### 阶段 2: SettingsState (2 小时)

1. 创建 `lib/src/state/settings_state.dart`
2. 迁移设置相关代码
3. 更新 AppState 委托
4. 测试验证

### 阶段 3-6: 其他模块 (15 小时)

- PlaybackState (3h)
- PracticeState (4h)
- AmbientState (2h)
- FocusState (2h)
- UI 适配 (4h)

### 阶段 7: 测试和修复 (4 小时)

- 全面测试
- Bug 修复
- 性能验证

---

## 重构策略

### 零风险原则

1. **保持 API 兼容** - 所有现有接口不变
2. **渐进式提取** - 每次只重构一个模块
3. **充分测试** - 每个模块都有测试覆盖
4. **可回滚** - 每一步都可安全回退

### 委托模式

```dart
class AppState {
  late final WordbookState _wordbookState;
  
  // 委托 getters
  List<Wordbook> get wordbooks => _wordbookState.wordbooks;
  Wordbook? get selectedWordbook => _wordbookState.selectedWordbook;
  
  // 委托方法
  Future<void> selectWordbook(Wordbook? w) =>
      _wordbookState.selectWordbook(w);
}
```

---

## 分支管理

### 合并到主分支

```bash
# 完成重构后
git checkout main
git merge feature/appstate-refactor
```

### 回滚方案

```bash
# 如有问题
git checkout main
git branch -D feature/appstate-refactor
```

---

## 预期收益

| 指标 | 当前 | 目标 | 改善 |
|------|------|------|------|
| AppState 行数 | 3011 | <1000 | -67% |
| 可维护性 | 低 | 高 | +60% |
| 测试覆盖率 | 40% | 70% | +30% |
| 编译时间 | 基准 | -25% | 更快 |

---

## 参考文档

- [重构计划](docs/APP_STATE_REFACTOR_PLAN.md)
- [实施步骤](docs/APP_STATE_REFACTOR_STEP1.md)
- [优化指南](docs/OPTIMIZATION_GUIDE.md)

---

**当前状态**: ✅ 准备就绪，可开始重构  
**最后更新**: 2026-03-30
