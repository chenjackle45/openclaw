---
title: "zai(Z.AI)"
summary: "在 OpenClaw 中使用 Z.AI (GLM 模型)"
read_when:
  - 想要在 OpenClaw 中使用 Z.AI / GLM 模型時
  - 需要簡單的 ZAI_API_KEY 設定教學時
---

# Z.AI

Z.AI 是 **GLM** 模型的 API 平台。它為 GLM 提供 REST API，並使用 API 金鑰進行認證。請在 Z.AI 控制台建立您的 API 金鑰。OpenClaw 透過 `zai` 供應商搭配 Z.AI API 金鑰使用。

## CLI 設定方式

```bash
openclaw onboard --auth-choice zai-api-key
# 或非互動模式
openclaw onboard --zai-api-key "$ZAI_API_KEY"
```

## 配置範例

```json5
{
  env: { ZAI_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "zai/glm-4.7" } } }
}
```

## 注意事項

- GLM 模型透過 `zai/<model>` 存取（例如：`zai/glm-4.7`）。
- 有關模型系列的概覽，請參閱 [/providers/glm](/providers/glm)。
- Z.AI 使用帶有您 API 金鑰的 Bearer 認證。
