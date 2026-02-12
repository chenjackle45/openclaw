---
summary: "Perplexity Sonar 設定用於 web_search"
read_when:
  - 你想使用 Perplexity Sonar 進行 web 搜尋
  - 你需要 PERPLEXITY_API_KEY 或 OpenRouter 設定
title: "Perplexity Sonar（Perplexity Sonar）"
---

# Perplexity Sonar

OpenClaw 可以使用 Perplexity Sonar 進行 `web_search` 工具。你可以直接透過 Perplexity API 或透過 OpenRouter 連接。

## API 選項

### Perplexity（直接）

- 基礎 URL：[https://api.perplexity.ai](https://api.perplexity.ai)
- 環境變數：`PERPLEXITY_API_KEY`

### OpenRouter（替代方案）

- 基礎 URL：[https://openrouter.ai/api/v1](https://openrouter.ai/api/v1)
- 環境變數：`OPENROUTER_API_KEY`
- 支援預付/加密貨幣積分。

## 設定範例

```json5
{
  tools: {
    web: {
      search: {
        provider: "perplexity",
        perplexity: {
          apiKey: "pplx-...",
          baseUrl: "https://api.perplexity.ai",
          model: "perplexity/sonar-pro",
        },
      },
    },
  },
}
```

## 從 Brave 切換

```json5
{
  tools: {
    web: {
      search: {
        provider: "perplexity",
        perplexity: {
          apiKey: "pplx-...",
          baseUrl: "https://api.perplexity.ai",
        },
      },
    },
  },
}
```

如果同時設定了 `PERPLEXITY_API_KEY` 和 `OPENROUTER_API_KEY`，請設定
`tools.web.search.perplexity.baseUrl`（或 `tools.web.search.perplexity.apiKey`）以消除歧義。

如果未設定基礎 URL，OpenClaw 會根據 API 金鑰來源選擇預設值：

- `PERPLEXITY_API_KEY` 或 `pplx-...` → 直接 Perplexity（`https://api.perplexity.ai`）
- `OPENROUTER_API_KEY` 或 `sk-or-...` → OpenRouter（`https://openrouter.ai/api/v1`）
- 未知金鑰格式 → OpenRouter（安全後備）

## 模型

- `perplexity/sonar` — 快速問答並進行 web 搜尋
- `perplexity/sonar-pro`（預設）— 多步推理 + web 搜尋
- `perplexity/sonar-reasoning-pro` — 深度研究

詳見[Web 工具](/zh-Hant/tools/web)了解完整的 web_search 設定。
