---
title: "Perplexity(Perplexity Sonar)"
summary: "為 web_search 設定 Perplexity Sonar"
read_when:
  - 您想要使用 Perplexity Sonar 進行網頁搜尋
  - 您需要 PERPLEXITY_API_KEY 或 OpenRouter 設定
---

# Perplexity Sonar

OpenClaw 可以使用 Perplexity Sonar 作為 `web_search` 工具。您可以透過
Perplexity 的直連 API 或經由 OpenRouter 連線。

## API 選項

### Perplexity（直連）

- Base URL: https://api.perplexity.ai
- 環境變數：`PERPLEXITY_API_KEY`

### OpenRouter（替代方案）

- Base URL: https://openrouter.ai/api/v1
- 環境變數：`OPENROUTER_API_KEY`
- 支援預付/加密貨幣點數。

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
          model: "perplexity/sonar-pro"
        }
      }
    }
  }
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
          baseUrl: "https://api.perplexity.ai"
        }
      }
    }
  }
}
```

如果 `PERPLEXITY_API_KEY` 和 `OPENROUTER_API_KEY` 都已設定，請設定
`tools.web.search.perplexity.baseUrl`（或 `tools.web.search.perplexity.apiKey`）
來消除歧義。

如果未設定 base URL，OpenClaw 會根據 API 金鑰來源選擇預設值：

- `PERPLEXITY_API_KEY` 或 `pplx-...` → 直連 Perplexity (`https://api.perplexity.ai`)
- `OPENROUTER_API_KEY` 或 `sk-or-...` → OpenRouter (`https://openrouter.ai/api/v1`)
- 未知的金鑰格式 → OpenRouter（安全回退）

## 模型

- `perplexity/sonar` — 快速 Q&A 與網頁搜尋
- `perplexity/sonar-pro`（預設）— 多步驟推理 + 網頁搜尋
- `perplexity/sonar-reasoning-pro` — 深度研究

請參閱 [Web tools](/tools/web) 以取得完整的 web_search 設定。
