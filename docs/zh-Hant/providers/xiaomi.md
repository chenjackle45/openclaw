---
title: "xiaomi(Xiaomi MiMo)"
summary: "在 OpenClaw 中使用 Xiaomi MiMo (mimo-v2-flash)"
read_when:
  - 想要在 OpenClaw 中使用 Xiaomi MiMo 模型時
  - 需要 XIAOMI_API_KEY 設定教學時
---

# Xiaomi MiMo

Xiaomi MiMo 是 **MiMo** 模型的 API 平台。它提供與 OpenAI 和 Anthropic 格式相容的 REST API，並使用 API 金鑰進行認證。請在 [Xiaomi MiMo console](https://platform.xiaomimimo.com/#/console/api-keys) 建立您的 API 金鑰。OpenClaw 透過 `xiaomi` 供應商搭配 Xiaomi MiMo API 金鑰使用。

## 模型概覽

- **mimo-v2-flash**: 262144-token 上下文視窗，相容 Anthropic Messages API。
- Base URL: `https://api.xiaomimimo.com/anthropic`
- 授權: `Bearer $XIAOMI_API_KEY`

## CLI 設定方式

```bash
openclaw onboard --auth-choice xiaomi-api-key
# 或非互動模式
openclaw onboard --auth-choice xiaomi-api-key --xiaomi-api-key "$XIAOMI_API_KEY"
```

## 配置範例

```json5
{
  env: { XIAOMI_API_KEY: "your-key" },
  agents: { defaults: { model: { primary: "xiaomi/mimo-v2-flash" } } },
  models: {
    mode: "merge",
    providers: {
      xiaomi: {
        baseUrl: "https://api.xiaomimimo.com/anthropic",
        api: "anthropic-messages",
        apiKey: "XIAOMI_API_KEY",
        models: [
          {
            id: "mimo-v2-flash",
            name: "Xiaomi MiMo V2 Flash",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 262144,
            maxTokens: 8192
          }
        ]
      }
    }
  }
}
```

## 注意事項

- 模型引用：`xiaomi/mimo-v2-flash`。
- 當設定了 `XIAOMI_API_KEY`（或存在認證設定檔）時，供應商會自動注入。
- 更多供應商規則請參閱 [/concepts/model-providers](/concepts/model-providers)。
