# module_system 模块说明

## 模块概述
`module_system` 负责统一管理模块 ID、模块描述、模块开关状态和运行时访问判定。

## 架构设计
- `ModuleIds`: 模块 ID 常量定义。
- `ModuleDescriptor`: 模块元信息（分组、父子关系、默认启用、可否禁用）。
- `ModuleRegistry`: 模块注册中心，集中维护模块清单。
- `ModuleToggleState`: 模块开关状态与序列化格式（用于持久化）。
- `ModuleRuntimeGuard`: 运行时可访问性判断（含父子模块联动）。
- `AppState` 启停联动：模块状态变化会同步到启动页回退、focus/ambient 运行时行为。

## 使用指南
1. 新增模块时，先在 `ModuleIds` 声明 ID。
2. 再在 `ModuleRegistry.descriptors` 注册描述。
3. 入口层（导航、toolbox 等）使用 `AppState.isModuleEnabled()` 做可见性判定。
4. 设置页通过 `AppState.setModuleEnabled()` 写入开关并持久化。

## 注意事项
- 关闭父模块时应同步停用子模块，避免出现孤儿入口。
- `more` 模块作为兜底配置入口，默认不可关闭。

## 更新历史
- 2026-04-13：初始化模块系统基线，接入导航与 toolbox 入口。
- 2026-04-13：补充运行时停用语义（focus 会话停止、ambient 停播与重启恢复）。
