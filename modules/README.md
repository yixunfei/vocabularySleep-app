# 模块文档说明

本目录用于存放各模块专属的详细文档。

---

## 目录结构

```
modules/
├── auth/              # 认证模块
│   └── README.md
├── network/           # 网络模块
│   └── README.md
├── storage/           # 存储模块
│   └── README.md
└── ui/                # UI组件模块
    └── README.md
```

---

## 命名规范

每个模块的文档应遵循以下结构：

```
{module_name}/
├── README.md              # 模块说明（必须）
├── API.md                 # API接口文档（如适用）
├── MODULE_CHANGELOG.md    # 模块变更日志
└── assets/                # 模块相关资源
    └── diagrams/          # 架构图等
```

---

## 模块文档要求

每个模块的 README.md 应包含：

1. **模块概述**: 职责和范围
2. **架构设计**: 核心组件和关系
3. **使用指南**: 如何使用该模块
4. **注意事项**: 潜在风险和注意点
5. **更新历史**: MODULE_CHANGELOG

---

## 已创建的模块

- `module_system`：模块注册、开关状态、运行时守卫。
- `practice`：练习会话与统计域（阶段 2 优先试点，已接入 `PracticeRepository`）。

---

## 维护指南

- 模块文档应与代码同步更新
- 每次模块重大变更后更新 MODULE_CHANGELOG
- 保持文档简洁，链接到代码中的详细注释
