---
summary: "Perplexity Search API 和 Sonar/OpenRouter 相容性，用於 web_search"
read_when:
  - 你想使用 Perplexity Search 進行網路搜尋
  - 你需要 PERPLEXITY_API_KEY 或 OPENROUTER_API_KEY 設定
title: "Perplexity Search（Perplexity 搜尋）"
---

# Perplexity Search API

OpenClaw 支援 Perplexity Search API 作為 `web_search` 提供者。它返回具有 `title`、`url` 和 `snippet` 欄位的結構化結果。

為了相容性，OpenClaw 也支援舊版 Perplexity Sonar/OpenRouter 設定。如果你使用 `OPENROUTER_API_KEY`、`plugins.entries.perplexity.config.webSearch.apiKey` 中的 `sk-or-...` 金鑰，或設定 `plugins.entries.perplexity.config.webSearch.baseUrl` / `model`，提供者會切換到聊天完成路徑，並返回帶有引用的 AI 合成答案，而非結構化 Search API 結果。

## 取得 Perplexity API 金鑰

1. 在 [perplexity.ai/settings/api](https://www.perplexity.ai/settings/api) 建立 Perplexity 帳戶
2. 在儀表板中產生 API 金鑰
3. 在設定中儲存金鑰或在 Gateway 環境中設定 `PERPLEXITY_API_KEY`。

## OpenRouter 相容性

如果你已在使用 OpenRouter 進行 Perplexity Sonar，請保持 `provider: "perplexity"` 並在 Gateway 環境中設定 `OPENROUTER_API_KEY`，或在 `plugins.entries.perplexity.config.webSearch.apiKey` 中儲存 `sk-or-...` 金鑰。

選用相容性控制：

- `plugins.entries.perplexity.config.webSearch.baseUrl`
- `plugins.entries.perplexity.config.webSearch.model`

## 設定範例

### 原生 Perplexity Search API

```json5
{
  plugins: {
    entries: {
      perplexity: {
        config: {
          webSearch: {
            apiKey: "pplx-...",
          },
        },
      },
    },
  },
  tools: {
    web: {
      search: {
        provider: "perplexity",
      },
    },
  },
}
```

### OpenRouter / Sonar 相容性

```json5
{
  plugins: {
    entries: {
      perplexity: {
        config: {
          webSearch: {
            apiKey: "<openrouter-api-key>",
            baseUrl: "https://openrouter.ai/api/v1",
            model: "perplexity/sonar-pro",
          },
        },
      },
    },
  },
  tools: {
    web: {
      search: {
        provider: "perplexity",
      },
    },
  },
}
```

## 金鑰位置設定

**透過設定：** 執行 `openclaw configure --section web`。它在 `~/.openclaw/openclaw.json` 中的 `plugins.entries.perplexity.config.webSearch.apiKey` 下儲存金鑰。該欄位也接受 SecretRef 物件。

**透過環境：** 在 Gateway 程序環境中設定 `PERPLEXITY_API_KEY` 或 `OPENROUTER_API_KEY`。對於 gateway 安裝，將其放在 `~/.openclaw/.env`（或你的服務環境）中。見 [環境變數](/zh-Hant/help/faq#env-vars-and-env-loading)。

如果 `provider: "perplexity"` 已設定，且 Perplexity 金鑰 SecretRef 未解析且無環境備用，啟動/重新載入會快速失敗。

## 工具參數

這些參數適用於原生 Perplexity Search API 路徑。

| 參數                  | 說明                                                    |
| --------------------- | ------------------------------------------------------- |
| `query`               | 搜尋查詢（必填）                                        |
| `count`               | 要返回的結果數（1-10，預設值：5）                       |
| `country`             | 2 字母 ISO 國家代碼（例如 "US"、"DE"）                  |
| `language`            | ISO 639-1 語言代碼（例如 "en"、"de"、"fr"）             |
| `freshness`           | 時間篩選器：`day`（24 小時）、`week`、`month` 或 `year` |
| `date_after`          | 只有在此日期之後發佈的結果（YYYY-MM-DD）                |
| `date_before`         | 只有在此日期之前發佈的結果（YYYY-MM-DD）                |
| `domain_filter`       | 領域允許清單/拒絕清單陣列（最多 20 個）                 |
| `max_tokens`          | 總內容預算（預設值：25000，最大值：1000000）            |
| `max_tokens_per_page` | 每頁語彙單元限制（預設值：2048）                        |

對於舊版 Sonar/OpenRouter 相容性路徑，只支援 `query` 和 `freshness`。Search API 專用篩選器如 `country`、`language`、`date_after`、`date_before`、`domain_filter`、`max_tokens` 和 `max_tokens_per_page` 會返回明確錯誤。

**範例：**

```javascript
// 特定國家和語言搜尋
await web_search({
  query: "renewable energy",
  country: "DE",
  language: "de",
});

// 最近結果（過去一週）
await web_search({
  query: "AI news",
  freshness: "week",
});

// 日期範圍搜尋
await web_search({
  query: "AI developments",
  date_after: "2024-01-01",
  date_before: "2024-06-30",
});

// 領域篩選（允許清單）
await web_search({
  query: "climate research",
  domain_filter: ["nature.com", "science.org", ".edu"],
});

// 領域篩選（拒絕清單 - 前綴為 -）
await web_search({
  query: "product reviews",
  domain_filter: ["-reddit.com", "-pinterest.com"],
});

// 更多內容擷取
await web_search({
  query: "detailed AI research",
  max_tokens: 50000,
  max_tokens_per_page: 4096,
});
```

### 領域篩選規則

- 每個篩選器最多 20 個領域
- 不能在同一請求中混合允許清單和拒絕清單
- 對拒絕清單項目使用 `-` 前綴（例如 `["-reddit.com"]`）

## 附註

- Perplexity Search API 返回結構化網路搜尋結果（`title`、`url`、`snippet`）
- OpenRouter 或明確的 `plugins.entries.perplexity.config.webSearch.baseUrl` / `model` 將 Perplexity 切回 Sonar 聊天完成以用於相容性
- 結果預設快取 15 分鐘（可透過 `cacheTtlMinutes` 設定）

## 相關

- [網路搜尋概觀](/zh-Hant/tools/web) — 所有提供者和自動偵測
- [Perplexity Search API 文件](https://docs.perplexity.ai/docs/search/quickstart) — 官方 Perplexity 文件
- [Brave Search](/zh-Hant/tools/brave-search) — 含國家/語言篩選器的結構化結果
- [Exa 搜尋](/zh-Hant/tools/exa-search) — 神經搜尋與內容擷取
