---
title: "Perplexity Search (legacy path)（Perplexity 搜尋）"
summary: "Perplexity Search API 和 Sonar/OpenRouter 相容於 web_search"
read_when:
  - 您想要使用 Perplexity Search 進行 web 搜尋
  - 您需要 PERPLEXITY_API_KEY 或 OPENROUTER_API_KEY 設定
---

# Perplexity Search API

OpenClaw 支援 Perplexity Search API 作為 `web_search` 提供者。
它傳回結構化結果，包含 `title`、`url` 和 `snippet` 欄位。

為了相容性，OpenClaw 也支援舊版 Perplexity Sonar/OpenRouter 設定。
如果您使用 `OPENROUTER_API_KEY`、`tools.web.search.perplexity.apiKey` 中的 `sk-or-...` 金鑰，或設定 `tools.web.search.perplexity.baseUrl` / `model`，提供者會切換到聊天完成路徑並傳回 AI 合成的回答（附帶引用）而不是結構化的搜尋 API 結果。

## 取得 Perplexity API 金鑰

1. 在 <https://www.perplexity.ai/settings/api> 建立 Perplexity 帳戶
2. 在儀表板中產生 API 金鑰
3. 在設定中儲存金鑰或在 Gateway 環境中設定 `PERPLEXITY_API_KEY`。

## OpenRouter 相容性

如果您已經為 Perplexity Sonar 使用 OpenRouter，保持 `provider: "perplexity"` 並在 Gateway 環境中設定 `OPENROUTER_API_KEY`，或儲存 `sk-or-...` 金鑰在 `tools.web.search.perplexity.apiKey` 中。

選擇性舊版控制：

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

## 在哪裡設定金鑰

**透過設定**：執行 `openclaw configure --section web`。它在 `~/.openclaw/openclaw.json` 下的 `tools.web.search.perplexity.apiKey` 中儲存金鑰。
該欄位也接受 SecretRef 物件。

**透過環境**：在 Gateway 程序環境中設定 `PERPLEXITY_API_KEY` 或 `OPENROUTER_API_KEY`。對於 gateway 安裝，將其放在 `~/.openclaw/.env`（或您的服務環境）中。參閱 [環境變數](/zh-Hant/help/faq#how-does-openclaw-load-environment-variables)。

如果設定了 `provider: "perplexity"` 且 Perplexity 金鑰 SecretRef 未解析且無環境回退，啟動／重新載入會快速失敗。

## 工具參數

這些參數適用於原生 Perplexity Search API 路徑。

| 參數                  | 說明                                                  |
| --------------------- | ----------------------------------------------------- |
| `query`               | 搜尋查詢（必要）                                      |
| `count`               | 要傳回的結果數（1-10，預設：5）                       |
| `country`             | 2 個字母的 ISO 國家代碼（例如「US」、「DE」）         |
| `language`            | ISO 639-1 語言代碼（例如「en」、「de」、「fr」）      |
| `freshness`           | 時間篩選：`day`（24 小時）、`week`、`month` 或 `year` |
| `date_after`          | 僅限在此日期後發佈的結果（YYYY-MM-DD）                |
| `date_before`         | 僅限在此日期前發佈的結果（YYYY-MM-DD）                |
| `domain_filter`       | 網域允許清單／拒絕清單陣列（最多 20）                 |
| `max_tokens`          | 總內容預算（預設：25000，最多：1000000）              |
| `max_tokens_per_page` | 每頁令牌限制（預設：2048）                            |

對於舊版 Sonar/OpenRouter 相容性路徑，僅支援 `query` 和 `freshness`。
搜尋 API 專用篩選，如 `country`、`language`、`date_after`、`date_before`、`domain_filter`、`max_tokens` 和 `max_tokens_per_page`，傳回明確錯誤。

**範例：**

```javascript
// 特定國家和語言搜尋
await web_search({
  query: "renewable energy",
  country: "DE",
  language: "de",
});

// 最近的結果（過去一週）
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

// 網域篩選（允許清單）
await web_search({
  query: "climate research",
  domain_filter: ["nature.com", "science.org", ".edu"],
});

// 網域篩選（拒絕清單 - 前綴使用 -）
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

### 網域篩選規則

- 每個篩選最多 20 個網域
- 無法在同一個要求中混合允許清單和拒絕清單
- 使用 `-` 前綴進行拒絕清單條目（例如 `["-reddit.com"]`）

## 備註

- Perplexity Search API 傳回結構化 web 搜尋結果（`title`、`url`、`snippet`）
- OpenRouter 或明確 `baseUrl` / `model` 為相容性將 Perplexity 切換回 Sonar 聊天完成
- 結果預設快取 15 分鐘（可透過 `cacheTtlMinutes` 設定）

參閱 [Web 工具](/zh-Hant/tools/web) 以取得完整的 web_search 設定。
參閱 [Perplexity Search API 文件](https://docs.perplexity.ai/docs/search/quickstart) 以取得更多詳細資料。
