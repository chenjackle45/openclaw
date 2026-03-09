---
summary: "Perplexity Search API 以及 Sonar/OpenRouter 相容性用於 web_search"
read_when:
  - 想使用 Perplexity Search 進行網路搜尋
  - 需要 PERPLEXITY_API_KEY 或 OPENROUTER_API_KEY 設定
title: "Perplexity Search（Perplexity 搜尋）"
---

# Perplexity Search API

OpenClaw 支援 Perplexity Search API 作為 `web_search` 提供商。
它返回含有 `title`、`url` 和 `snippet` 欄位的結構化結果。

為了相容性，OpenClaw 也支援舊版 Perplexity Sonar/OpenRouter 設定。
若你使用 `OPENROUTER_API_KEY`、`tools.web.search.perplexity.apiKey` 中的 `sk-or-...` 金鑰，或設定了 `tools.web.search.perplexity.baseUrl` / `model`，提供商會切換至 chat completions 路徑，並返回帶有引用的 AI 合成答案，而非結構化的 Search API 結果。

## 取得 Perplexity API 金鑰

1. 在 <https://www.perplexity.ai/settings/api> 建立 Perplexity 帳號
2. 在儀表板中產生 API 金鑰
3. 將金鑰儲存在設定中，或在 Gateway 環境中設定 `PERPLEXITY_API_KEY`。

## OpenRouter 相容性

若你已在使用 OpenRouter 進行 Perplexity Sonar，保留 `provider: "perplexity"` 並在 Gateway 環境中設定 `OPENROUTER_API_KEY`，或在 `tools.web.search.perplexity.apiKey` 中儲存 `sk-or-...` 金鑰。

可選的舊版控制：

- `tools.web.search.perplexity.baseUrl`
- `tools.web.search.perplexity.model`

## 設定範例

### 原生 Perplexity Search API

```json5
{
  tools: {
    web: {
      search: {
        provider: "perplexity",
        perplexity: {
          apiKey: "pplx-...",
        },
      },
    },
  },
}
```

### OpenRouter / Sonar 相容性

```json5
{
  tools: {
    web: {
      search: {
        provider: "perplexity",
        perplexity: {
          apiKey: "<openrouter-api-key>",
          baseUrl: "https://openrouter.ai/api/v1",
          model: "perplexity/sonar-pro",
        },
      },
    },
  },
}
```

## 金鑰設定位置

**透過設定：** 執行 `openclaw configure --section web`。金鑰儲存在 `~/.openclaw/openclaw.json` 的 `tools.web.search.perplexity.apiKey` 下。

**透過環境變數：** 在 Gateway 程序環境中設定 `PERPLEXITY_API_KEY` 或 `OPENROUTER_API_KEY`。對於 gateway 安裝，放入 `~/.openclaw/.env`（或你的服務環境）。請見 [環境變數](/zh-Hant/help/faq#how-does-openclaw-load-environment-variables)。

## 工具參數

以下參數適用於原生 Perplexity Search API 路徑。

| 參數                  | 說明                                                 |
| --------------------- | ---------------------------------------------------- |
| `query`               | 搜尋查詢（必填）                                     |
| `count`               | 返回的結果數量（1-10，預設：5）                      |
| `country`             | 2 字母 ISO 國家代碼（例如「US」、「DE」）            |
| `language`            | ISO 639-1 語言代碼（例如「en」、「de」、「fr」）     |
| `freshness`           | 時間過濾：`day`（24小時）、`week`、`month` 或 `year` |
| `date_after`          | 僅返回此日期後發布的結果（YYYY-MM-DD）               |
| `date_before`         | 僅返回此日期前發布的結果（YYYY-MM-DD）               |
| `domain_filter`       | 網域允許清單/拒絕清單陣列（最多 20 個）              |
| `max_tokens`          | 總內容預算（預設：25000，最大：1000000）             |
| `max_tokens_per_page` | 每頁 token 限制（預設：2048）                        |

對於舊版 Sonar/OpenRouter 相容性路徑，僅支援 `query` 和 `freshness`。
僅限 Search API 的過濾器如 `country`、`language`、`date_after`、`date_before`、`domain_filter`、`max_tokens` 和 `max_tokens_per_page` 會返回明確的錯誤。

**範例：**

```javascript
// 依國家和語言搜尋
await web_search({
  query: "renewable energy",
  country: "DE",
  language: "de",
});

// 近期結果（過去一週）
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

// 網域過濾（允許清單）
await web_search({
  query: "climate research",
  domain_filter: ["nature.com", "science.org", ".edu"],
});

// 網域過濾（拒絕清單 - 前綴 -）
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

### 網域過濾規則

- 每個過濾器最多 20 個網域
- 同一個請求不能混用允許清單和拒絕清單
- 拒絕清單條目使用 `-` 前綴（例如 `["-reddit.com"]`）

## 注意事項

- Perplexity Search API 返回結構化的網路搜尋結果（`title`、`url`、`snippet`）
- OpenRouter 或明確的 `baseUrl` / `model` 會讓 Perplexity 切換回 Sonar chat completions 以確保相容性
- 結果預設快取 15 分鐘（可透過 `cacheTtlMinutes` 設定）

完整的 web_search 設定請見 [網路工具](/zh-Hant/tools/web)。
詳情請見 [Perplexity Search API 文件](https://docs.perplexity.ai/docs/search/quickstart)。
