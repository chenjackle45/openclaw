---
summary: "在 OpenClaw 中使用 Synthetic 的 Anthropic 相容 API"
read_when:
  - You want to use Synthetic as a model provider
  - You need a Synthetic API key or base URL setup
title: "Synthetic（Synthetic）"
---

# Synthetic

Synthetic 公開 Anthropic 相容端點。OpenClaw 將其登記為 `synthetic` 提供者並使用 Anthropic Messages API。

## 快速設定

1. 設定 `SYNTHETIC_API_KEY`（或執行下面的精靈）。
2. 執行上線：

```bash
openclaw onboard --auth-choice synthetic-api-key
```

預設模型設定為：

```
synthetic/hf:MiniMaxAI/MiniMax-M2.5
```

## 設定範例

```json5
{
  env: { SYNTHETIC_API_KEY: "sk-..." },
  agents: {
    defaults: {
      model: { primary: "synthetic/hf:MiniMaxAI/MiniMax-M2.5" },
      models: { "synthetic/hf:MiniMaxAI/MiniMax-M2.5": { alias: "MiniMax M2.5" } },
    },
  },
  models: {
    mode: "merge",
    providers: {
      synthetic: {
        baseUrl: "https://api.synthetic.new/anthropic",
        apiKey: "${SYNTHETIC_API_KEY}",
        api: "anthropic-messages",
        models: [
          {
            id: "hf:MiniMaxAI/MiniMax-M2.5",
            name: "MiniMax M2.5",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 192000,
            maxTokens: 65536,
          },
        ],
      },
    },
  },
}
```

註記：OpenClaw 的 Anthropic 用戶端將 `/v1` 附加到基底 URL，所以使用 `https://api.synthetic.new/anthropic`（不是 `/anthropic/v1`）。如果 Synthetic 改變其基底 URL，覆蓋 `models.providers.synthetic.baseUrl`。
