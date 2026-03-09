---
summary: "Web 搜尋 + 抓取工具（Brave、Gemini、Grok、Kimi 和 Perplexity 提供者）"
read_when:
  - 你想啟用 web_search 或 web_fetch
  - 你需要設定 Brave 或 Perplexity Search API 金鑰
  - 你想使用帶有 Google Search grounding 的 Gemini
title: "Web Tools（Web 工具）"
---

# Web tools

OpenClaw 附帶兩個輕量級 web 工具：

- `web_search` — 使用 Brave Search API、帶有 Google Search grounding 的 Gemini、Grok、Kimi 或 Perplexity Search API 搜尋 Web。
- `web_fetch` — HTTP 抓取 + 可讀性萃取（HTML → markdown/text）。

這些**不是**瀏覽器自動化。對於 JS 密集的網站或需要登入的網站，請使用 [Browser 工具](/zh-Hant/tools/browser)。

## 運作方式

- `web_search` 呼叫你設定的提供者並回傳結果。
- 結果按查詢快取 15 分鐘（可設定）。
- `web_fetch` 執行普通的 HTTP GET 並萃取可讀內容（HTML → markdown/text）。它**不**執行 JavaScript。
- `web_fetch` 預設啟用（除非明確停用）。

請參閱 [Brave Search 設定](/zh-Hant/brave-search) 和 [Perplexity Search 設定](/zh-Hant/perplexity) 了解提供者特定詳細資訊。

## 選擇搜尋提供者

| 提供者                    | 結果形狀             | 提供者特定篩選                               | 備注                                             | API 金鑰                                    |
| ------------------------- | -------------------- | -------------------------------------------- | ------------------------------------------------ | ------------------------------------------- |
| **Brave Search API**      | 帶有摘要的結構化結果 | `country`、`language`、`ui_lang`、時間       | 支援 Brave `llm-context` 模式                    | `BRAVE_API_KEY`                             |
| **Gemini**                | AI 綜合答案 + 引用   | —                                            | 使用 Google Search grounding                     | `GEMINI_API_KEY`                            |
| **Grok**                  | AI 綜合答案 + 引用   | —                                            | 使用 xAI web-grounded 回應                       | `XAI_API_KEY`                               |
| **Kimi**                  | AI 綜合答案 + 引用   | —                                            | 使用 Moonshot web search                         | `KIMI_API_KEY` / `MOONSHOT_API_KEY`         |
| **Perplexity Search API** | 帶有摘要的結構化結果 | `country`、`language`、時間、`domain_filter` | 支援內容萃取控制；OpenRouter 使用 Sonar 相容路徑 | `PERPLEXITY_API_KEY` / `OPENROUTER_API_KEY` |

### 自動偵測

上表按字母順序排列。若未明確設定 `provider`，執行期自動偵測按以下順序檢查提供者：

1. **Brave** — `BRAVE_API_KEY` env var 或 `tools.web.search.apiKey` 設定
2. **Gemini** — `GEMINI_API_KEY` env var 或 `tools.web.search.gemini.apiKey` 設定
3. **Grok** — `XAI_API_KEY` env var 或 `tools.web.search.grok.apiKey` 設定
4. **Kimi** — `KIMI_API_KEY` / `MOONSHOT_API_KEY` env var 或 `tools.web.search.kimi.apiKey` 設定
5. **Perplexity** — `PERPLEXITY_API_KEY`、`OPENROUTER_API_KEY` 或 `tools.web.search.perplexity.apiKey` 設定

若未找到任何金鑰，則退而使用 Brave（你會收到缺少金鑰的錯誤，提示你設定一個）。

## 設定 web search

使用 `openclaw configure --section web` 設定你的 API 金鑰並選擇提供者。

### Brave Search

1. 在 [brave.com/search/api](https://brave.com/search/api/) 建立 Brave Search API 帳戶
2. 在儀表板中，選擇 **Search** 方案並生成 API 金鑰。
3. 執行 `openclaw configure --section web` 將金鑰儲存到設定中，或在你的環境中設定 `BRAVE_API_KEY`。

每個 Brave 方案包含**每月 $5 的免費額度**（更新）。Search 方案每 1,000 個請求收費 $5，因此額度涵蓋每月 1,000 次查詢。在 Brave 儀表板中設定你的使用限制以避免意外費用。請參閱 [Brave API portal](https://brave.com/search/api/) 了解目前的方案和定價。

### Perplexity Search

1. 在 [perplexity.ai/settings/api](https://www.perplexity.ai/settings/api) 建立 Perplexity 帳戶
2. 在儀表板中生成 API 金鑰
3. 執行 `openclaw configure --section web` 將金鑰儲存到設定中，或在你的環境中設定 `PERPLEXITY_API_KEY`。

對於舊版 Sonar/OpenRouter 相容性，請改為設定 `OPENROUTER_API_KEY`，或使用 `sk-or-...` 金鑰設定 `tools.web.search.perplexity.apiKey`。設定 `tools.web.search.perplexity.baseUrl` 或 `model` 也會讓 Perplexity 退回到 chat-completions 相容路徑。

請參閱 [Perplexity Search API Docs](https://docs.perplexity.ai/guides/search-quickstart) 了解更多詳細資訊。

### 儲存金鑰的位置

**透過設定：** 執行 `openclaw configure --section web`。它根據提供者將金鑰儲存在 `tools.web.search.apiKey` 或 `tools.web.search.perplexity.apiKey` 下。

**透過環境：** 在 Gateway 行程環境中設定 `PERPLEXITY_API_KEY`、`OPENROUTER_API_KEY` 或 `BRAVE_API_KEY`。對於 gateway 安裝，將其放在 `~/.openclaw/.env`（或你的服務環境）中。請參閱 [Env vars](/zh-Hant/help/faq#how-does-openclaw-load-environment-variables)。

### 設定範例

**Brave Search：**

```json5
{
  tools: {
    web: {
      search: {
        enabled: true,
        provider: "brave",
        apiKey: "YOUR_BRAVE_API_KEY", // optional if BRAVE_API_KEY is set // pragma: allowlist secret
      },
    },
  },
}
```

**Brave LLM Context 模式：**

```json5
{
  tools: {
    web: {
      search: {
        enabled: true,
        provider: "brave",
        apiKey: "YOUR_BRAVE_API_KEY", // optional if BRAVE_API_KEY is set // pragma: allowlist secret
        brave: {
          mode: "llm-context",
        },
      },
    },
  },
}
```

`llm-context` 回傳萃取的頁面片段用於 grounding，而非標準 Brave 摘要。
在此模式下，`country` 和 `language` / `search_lang` 仍然有效，但 `ui_lang`、`freshness`、`date_after` 和 `date_before` 會被拒絕。

**Perplexity Search：**

```json5
{
  tools: {
    web: {
      search: {
        enabled: true,
        provider: "perplexity",
        perplexity: {
          apiKey: "pplx-...", // optional if PERPLEXITY_API_KEY is set
        },
      },
    },
  },
}
```

**Perplexity 透過 OpenRouter / Sonar 相容性：**

```json5
{
  tools: {
    web: {
      search: {
        enabled: true,
        provider: "perplexity",
        perplexity: {
          apiKey: "<openrouter-api-key>", // optional if OPENROUTER_API_KEY is set
          baseUrl: "https://openrouter.ai/api/v1",
          model: "perplexity/sonar-pro",
        },
      },
    },
  },
}
```

## 使用 Gemini（Google Search grounding）

Gemini 模型支援內建的 [Google Search grounding](https://ai.google.dev/gemini-api/docs/grounding)，回傳由即時 Google Search 結果支援的 AI 綜合答案和引用。

### 取得 Gemini API 金鑰

1. 前往 [Google AI Studio](https://aistudio.google.com/apikey)
2. 建立 API 金鑰
3. 在 Gateway 環境中設定 `GEMINI_API_KEY`，或設定 `tools.web.search.gemini.apiKey`

### 設定 Gemini search

```json5
{
  tools: {
    web: {
      search: {
        provider: "gemini",
        gemini: {
          // API key (optional if GEMINI_API_KEY is set)
          apiKey: "AIza...",
          // Model (defaults to "gemini-2.5-flash")
          model: "gemini-2.5-flash",
        },
      },
    },
  },
}
```

**環境替代方案：** 在 Gateway 環境中設定 `GEMINI_API_KEY`。對於 gateway 安裝，將其放在 `~/.openclaw/.env` 中。

### 注意事項

- Gemini grounding 的引用 URL 會自動從 Google 的重定向 URL 解析為直接 URL。
- 重定向解析使用 SSRF 防護路徑（HEAD + 重定向檢查 + http/https 驗證）後再回傳最終引用 URL。
- 重定向解析使用嚴格的 SSRF 預設值，因此重定向到私有/內部目標的請求會被封鎖。
- 預設模型（`gemini-2.5-flash`）快速且具成本效益。任何支援 grounding 的 Gemini 模型都可以使用。

## web_search

使用你設定的提供者搜尋 Web。

### 需求

- `tools.web.search.enabled` 不得為 `false`（預設：啟用）
- 你選擇的提供者的 API 金鑰：
  - **Brave**：`BRAVE_API_KEY` 或 `tools.web.search.apiKey`
  - **Gemini**：`GEMINI_API_KEY` 或 `tools.web.search.gemini.apiKey`
  - **Grok**：`XAI_API_KEY` 或 `tools.web.search.grok.apiKey`
  - **Kimi**：`KIMI_API_KEY`、`MOONSHOT_API_KEY` 或 `tools.web.search.kimi.apiKey`
  - **Perplexity**：`PERPLEXITY_API_KEY`、`OPENROUTER_API_KEY` 或 `tools.web.search.perplexity.apiKey`

### 設定

```json5
{
  tools: {
    web: {
      search: {
        enabled: true,
        apiKey: "BRAVE_API_KEY_HERE", // optional if BRAVE_API_KEY is set
        maxResults: 5,
        timeoutSeconds: 30,
        cacheTtlMinutes: 15,
      },
    },
  },
}
```

### 工具參數

所有參數對 Brave 和原生 Perplexity Search API 均有效，除非另有說明。

Perplexity 的 OpenRouter / Sonar 相容路徑僅支援 `query` 和 `freshness`。
若你設定 `tools.web.search.perplexity.baseUrl` / `model`、使用 `OPENROUTER_API_KEY` 或設定 `sk-or-...` 金鑰，Search API 專用篩選會回傳明確錯誤。

| 參數                  | 描述                                          |
| --------------------- | --------------------------------------------- |
| `query`               | 搜尋查詢（必填）                              |
| `count`               | 回傳結果數量（1-10，預設：5）                 |
| `country`             | 2 字母 ISO 國家代碼（例如，"US"、"DE"）       |
| `language`            | ISO 639-1 語言代碼（例如，"en"、"de"）        |
| `freshness`           | 時間篩選：`day`、`week`、`month` 或 `year`    |
| `date_after`          | 此日期後的結果（YYYY-MM-DD）                  |
| `date_before`         | 此日期前的結果（YYYY-MM-DD）                  |
| `ui_lang`             | UI 語言代碼（僅限 Brave）                     |
| `domain_filter`       | 域名允許清單/拒絕清單陣列（僅限 Perplexity）  |
| `max_tokens`          | 總內容預算，預設 25000（僅限 Perplexity）     |
| `max_tokens_per_page` | 每頁 token 限制，預設 2048（僅限 Perplexity） |

**範例：**

```javascript
// German-specific search
await web_search({
  query: "TV online schauen",
  country: "DE",
  language: "de",
});

// Recent results (past week)
await web_search({
  query: "TMBG interview",
  freshness: "week",
});

// Date range search
await web_search({
  query: "AI developments",
  date_after: "2024-01-01",
  date_before: "2024-06-30",
});

// Domain filtering (Perplexity only)
await web_search({
  query: "climate research",
  domain_filter: ["nature.com", "science.org", ".edu"],
});

// Exclude domains (Perplexity only)
await web_search({
  query: "product reviews",
  domain_filter: ["-reddit.com", "-pinterest.com"],
});

// More content extraction (Perplexity only)
await web_search({
  query: "detailed AI research",
  max_tokens: 50000,
  max_tokens_per_page: 4096,
});
```

啟用 Brave `llm-context` 模式時，不支援 `ui_lang`、`freshness`、`date_after` 和 `date_before`。請使用 Brave `web` 模式搭配這些篩選。

## web_fetch

抓取 URL 並萃取可讀內容。

### web_fetch 需求

- `tools.web.fetch.enabled` 不得為 `false`（預設：啟用）
- 可選的 Firecrawl 備用：設定 `tools.web.fetch.firecrawl.apiKey` 或 `FIRECRAWL_API_KEY`。

### web_fetch 設定

```json5
{
  tools: {
    web: {
      fetch: {
        enabled: true,
        maxChars: 50000,
        maxCharsCap: 50000,
        maxResponseBytes: 2000000,
        timeoutSeconds: 30,
        cacheTtlMinutes: 15,
        maxRedirects: 3,
        userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
        readability: true,
        firecrawl: {
          enabled: true,
          apiKey: "FIRECRAWL_API_KEY_HERE", // optional if FIRECRAWL_API_KEY is set
          baseUrl: "https://api.firecrawl.dev",
          onlyMainContent: true,
          maxAgeMs: 86400000, // ms (1 day)
          timeoutSeconds: 60,
        },
      },
    },
  },
}
```

### web_fetch 工具參數

- `url`（必填，僅限 http/https）
- `extractMode`（`markdown` | `text`）
- `maxChars`（截斷長頁面）

注意事項：

- `web_fetch` 先使用 Readability（主要內容萃取），然後使用 Firecrawl（若已設定）。若兩者都失敗，工具回傳錯誤。
- Firecrawl 請求使用機器人繞過模式並預設快取結果。
- `web_fetch` 預設發送類 Chrome 的 User-Agent 和 `Accept-Language`；若需要請覆寫 `userAgent`。
- `web_fetch` 封鎖私有/內部主機名，並重新檢查重定向（使用 `maxRedirects` 限制）。
- `maxChars` 被限制為 `tools.web.fetch.maxCharsCap`。
- `web_fetch` 在解析前將下載的回應主體大小限制為 `tools.web.fetch.maxResponseBytes`；超大回應會被截斷並包含警告。
- `web_fetch` 是盡力萃取；某些網站將需要瀏覽器工具。
- 請參閱 [Firecrawl](/zh-Hant/tools/firecrawl) 了解金鑰設定和服務詳細資訊。
- 回應被快取（預設 15 分鐘）以減少重複抓取。
- 若你使用工具設定檔/允許清單，請新增 `web_search`/`web_fetch` 或 `group:web`。
- 若 API 金鑰缺失，`web_search` 回傳帶有文件連結的簡短設定提示。
