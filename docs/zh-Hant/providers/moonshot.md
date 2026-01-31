---
title: "moonshot(Moonshot AI)"
summary: "配置 Moonshot K2 與 Kimi Code（分離的供應商與金鑰）"
read_when:
  - 想要設定 Moonshot K2 (Moonshot 開放平台) 或 Kimi Code 時
  - 需要了解分離的端點、金鑰與模型引用時
  - 想要複製/貼上任一供應商的配置時
---

# Moonshot AI (Kimi)

Moonshot 提供與 OpenAI 相容的 Kimi API。設定此供應商並將預設模型設為 `moonshot/kimi-k2.5`，或是使用 Kimi Code 的 `kimi-code/kimi-for-coding`。

目前的 Kimi K2 模型 ID：
{/* moonshot-kimi-k2-ids:start */}
- `kimi-k2.5`
- `kimi-k2-0905-preview`
- `kimi-k2-turbo-preview`
- `kimi-k2-thinking`
- `kimi-k2-thinking-turbo`
{/* moonshot-kimi-k2-ids:end */}

```bash
openclaw onboard --auth-choice moonshot-api-key
```

Kimi Code：

```bash
openclaw onboard --auth-choice kimi-code-api-key
```

注意：Moonshot 與 Kimi Code 是不同的供應商。金鑰不可互通，端點不同，模型引用也不同（Moonshot 使用 `moonshot/...`，Kimi Code 使用 `kimi-code/...`）。

## 配置範例 (Moonshot API)

```json5
{
  env: { MOONSHOT_API_KEY: "sk-..." },
  agents: {
    defaults: {
      model: { primary: "moonshot/kimi-k2.5" },
      models: {
        // moonshot-kimi-k2-aliases:start
        "moonshot/kimi-k2.5": { alias: "Kimi K2.5" },
        "moonshot/kimi-k2-0905-preview": { alias: "Kimi K2" },
        "moonshot/kimi-k2-turbo-preview": { alias: "Kimi K2 Turbo" },
        "moonshot/kimi-k2-thinking": { alias: "Kimi K2 Thinking" },
        "moonshot/kimi-k2-thinking-turbo": { alias: "Kimi K2 Thinking Turbo" }
        // moonshot-kimi-k2-aliases:end
      }
    }
  },
  models: {
    mode: "merge",
    providers: {
      moonshot: {
        baseUrl: "https://api.moonshot.ai/v1",
        apiKey: "${MOONSHOT_API_KEY}",
        api: "openai-completions",
        models: [
          // moonshot-kimi-k2-models:start
          {
            id: "kimi-k2.5",
            name: "Kimi K2.5",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 256000,
            maxTokens: 8192
          },
          {
            id: "kimi-k2-0905-preview",
            name: "Kimi K2 0905 Preview",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 256000,
            maxTokens: 8192
          },
          {
            id: "kimi-k2-turbo-preview",
            name: "Kimi K2 Turbo",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 256000,
            maxTokens: 8192
          },
          {
            id: "kimi-k2-thinking",
            name: "Kimi K2 Thinking",
            reasoning: true,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 256000,
            maxTokens: 8192
          },
          {
            id: "kimi-k2-thinking-turbo",
            name: "Kimi K2 Thinking Turbo",
            reasoning: true,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 256000,
            maxTokens: 8192
          }
          // moonshot-kimi-k2-models:end
        ]
      }
    }
  }
}
```

## Kimi Code

```json5
{
  env: { KIMICODE_API_KEY: "sk-..." },
  agents: {
    defaults: {
      model: { primary: "kimi-code/kimi-for-coding" },
      models: {
        "kimi-code/kimi-for-coding": { alias: "Kimi Code" }
      }
    }
  },
  models: {
    mode: "merge",
    providers: {
      "kimi-code": {
        baseUrl: "https://api.kimi.com/coding/v1",
        apiKey: "${KIMICODE_API_KEY}",
        api: "openai-completions",
        models: [
          {
            id: "kimi-for-coding",
            name: "Kimi For Coding",
            reasoning: true,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 262144,
            maxTokens: 32768,
            headers: { "User-Agent": "KimiCLI/0.77" },
            compat: { supportsDeveloperRole: false }
          }
        ]
      }
    }
  }
}
```

## 注意事項

- Moonshot 模型引用使用 `moonshot/<modelId>`。Kimi Code 模型引用使用 `kimi-code/<modelId>`。
- 若有需要，可在 `models.providers` 中覆寫價格與上下文元數據。
- 若 Moonshot 發佈了不同模型的上下文限制，請相應調整 `contextWindow`。
- 若需要使用中國端點，請使用 `https://api.moonshot.cn/v1`。
