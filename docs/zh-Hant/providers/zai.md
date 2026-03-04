---
summary: "在 OpenClaw 中使用 Z.AI（GLM 模型）"
read_when:
  - You want Z.AI / GLM models in OpenClaw
  - You need a simple ZAI_API_KEY setup
title: "Z.AI（Z.AI）"
---

# Z.AI

Z.AI 是 **GLM** 模型的 API 平台。它為 GLM 提供 REST API，並使用 API 鑰進行認證。在 Z.AI 主控台建立 API 鑰。OpenClaw 使用 `zai` 提供者搭配 Z.AI API 鑰。

## CLI 設定

```bash
openclaw onboard --auth-choice zai-api-key
# 或非互動
openclaw onboard --zai-api-key "$ZAI_API_KEY"
```

## 設定片段

```json5
{
  env: { ZAI_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "zai/glm-5" } } },
}
```

## 註記

- GLM 模型可用為 `zai/<model>`（範例：`zai/glm-5`）。
- `tool_stream` 預設為 Z.AI 工具呼叫串流啟用。設定
  `agents.defaults.models["zai/<model>"].params.tool_stream` 為 `false` 停用。
- 見 [/providers/glm](/zh-Hant/providers/glm) 以了解模型族概述。
- Z.AI 使用 Bearer 認證搭配 API 鑰。
