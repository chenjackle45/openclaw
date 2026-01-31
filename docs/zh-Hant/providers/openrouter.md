---
title: "openrouter(OpenRouter)"
summary: "在 OpenClaw 中使用 OpenRouter 統一 API 存取多種模型"
read_when:
  - 想要使用單一 API 金鑰存取多個 LLM 時
  - 想要在 OpenClaw 中透過 OpenRouter 運行模型時
---

# OpenRouter

OpenRouter 提供了一個**統一 API**，透過單一端點與 API 金鑰轉發請求至多種模型。它與 OpenAI 相容，因此大多數 OpenAI SDK 僅需切換 Base URL 即可運作。

## CLI 設定方式

```bash
openclaw onboard --auth-choice apiKey --token-provider openrouter --token "$OPENROUTER_API_KEY"
```

## 配置範例

```json5
{
  env: { OPENROUTER_API_KEY: "sk-or-..." },
  agents: {
    defaults: {
      model: { primary: "openrouter/anthropic/claude-sonnet-4-5" }
    }
  }
}
```

## 注意事項

- 模型引用格式為 `openrouter/<供應商>/<模型>`。
- 更多模型/供應商選項請參閱 [/concepts/model-providers](/concepts/model-providers)。
- OpenRouter 底層使用帶有您 API 金鑰的 Bearer Token 進行認證。
