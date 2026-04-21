# 模块文档说明

本目录用于维护 `PLAN_024` 的模块化推进记录。当前文档按“模块模板四件套”统一描述：

1. 状态独立（state boundary）
2. 仓库独立（repository boundary）
3. 注册驱动（registry-driven entry）
4. 启停守卫（runtime guard）

---

## 当前目录结构

```text
modules/
├── module_system/
│   └── README.md
├── practice/
│   └── README.md
├── focus/
│   └── README.md
├── toolbox/
│   └── README.md
└── sleep/
    └── README.md
```

---

## 模块 README 最小模板

每个模块文档至少包含以下章节：

1. 模块概述（职责边界）
2. 四件套落地状态（状态/仓库/注册/守卫）
3. 当前依赖与入口
4. 风险与后续拆分路线
5. 更新历史

---

## 维护规则

- 模块行为或边界调整后，同步更新对应 `modules/<module>/README.md`。
- 跨模块共享能力（例如模块守卫、注册表、共享仓库接口）变更时，先更新 `modules/module_system/README.md`。
- 阶段化推进遵循“先可验证再扩面”：先补测试和验收记录，再标记模块状态为“完成”。
