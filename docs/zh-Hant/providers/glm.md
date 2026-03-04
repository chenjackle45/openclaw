---
summary: "GLM 模型族概述 + 如何在 OpenClaw 中使用它"
read_when:
  - You want GLM models in OpenClaw
  - You need the model naming convention and setup
title: "GLM Models（GLM Models）"
---

# GLM 模型

GLM 是一個**模型族**（不是公司），可透過 Z.AI 平台使用。在 OpenClaw 中，GLM
模型透過 `zai` 提供者和模型 ID（例如 `zai/glm-5`）存取。

## CLI 設定

```bash
openclaw onboard --auth-choice zai-api-key
```

## 設定片段

```json5
{
  env: { ZAI_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "zai/glm-5" } } },
}
```

## 註記

- GLM 版本和可用性可能變更；檢查 Z.AI 文件以了解最新情況。
- 範例模型 ID 包括 `glm-5`、`glm-4.7` 和 `glm-4.6`。
- 如需提供者詳情，見 [/providers/zai](/zh-Hant/providers/zai)。
