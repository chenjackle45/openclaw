---
summary: "Web 搜尋 + 抓取工具（Brave Search API、Perplexity 直接/OpenRouter）"
read_when:
  - 你想啟用 web_search 或 web_fetch
  - 你需要 Brave Search API 鑰匙設定
  - 你想使用 Perplexity Sonar 進行網路搜尋
title: "Web Tools（Web 工具）"
---

# Web 工具

OpenClaw 提供兩個輕量級 web 工具：

- `web_search` — 透過 Brave Search API（預設）或 Perplexity Sonar（直接或透過 OpenRouter）搜尋 web。
- `web_fetch` — HTTP 抓取 + 可讀性提取（HTML → markdown/文字）。

這些**不是**瀏覽器自動化。對於 JS 繁重的網站或登入，使用
[瀏覽器工具](/zh-Hant/tools/browser)。

## 運作方式

- `web_search` 呼叫你配置的提供者並返回結果。
  - **Brave**（預設）：返回結構化結果（標題、URL、摘要）。
  - **Perplexity**：返回 AI 合成的回答，包含真實時間 web 搜尋的引用。
- 結果按查詢快取 15 分鐘（可配置）。
- `web_fetch` 執行純 HTTP GET 並提取可讀內容
  （HTML → markdown/文字）。它**不**執行 JavaScript。
- `web_fetch` 預設啟用（除非明確停用）。

## 選擇搜尋提供者

| 提供者            | 優勢                     | 劣勢                               | API 鑰匙                                     |
| ----------------- | ------------------------ | ---------------------------------- | -------------------------------------------- |
| **Brave**（預設） | 快速、結構化結果、免費層 | 傳統搜尋結果                       | `BRAVE_API_KEY`                              |
| **Perplexity**    | AI 合成回答、引用、即時  | 需要 Perplexity 或 OpenRouter 存取 | `OPENROUTER_API_KEY` 或 `PERPLEXITY_API_KEY` |

見 [Brave Search 設定](/zh-Hant/brave-search) 和 [Perplexity Sonar](/zh-Hant/perplexity) 瞭解提供者特定詳情。

在配置中設定提供者：

```json5
{
  tools: {
    web: {
      search: {
        provider: "brave", // 或 "perplexity"
      },
    },
  },
}
```

範例：切換到 Perplexity Sonar（直接 API）：

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

## 取得 Brave API 鑰匙

1. 在 [https://brave.com/search/api/](https://brave.com/search/api/) 建立 Brave Search API 帳號
2. 在儀表盤中，選擇**Data for Search** 計畫（不是 "Data for AI"）並產生 API 鑰匙。
3. 執行 `openclaw configure --section web` 在配置中儲存鑰匙（推薦），或在環境中設定 `BRAVE_API_KEY`。

Brave 提供免費層加上付費計畫；檢查 Brave API 入口以瞭解
目前限制和定價。

### 設定鑰匙的位置（推薦）

**推薦：** 執行 `openclaw configure --section web`。它在
`~/.openclaw/openclaw.json` 下的 `tools.web.search.apiKey` 儲存鑰匙。

**環境替代：** 在 Gateway 程序
環境中設定 `BRAVE_API_KEY`。對於 gateway 安裝，放在 `~/.openclaw/.env`（或你的
服務環境）。見 [環境變數](/zh-Hant/help/faq#how-does-openclaw-load-environment-variables)。

## 使用 Perplexity（直接或透過 OpenRouter）

Perplexity Sonar 模型具有內建 web 搜尋能力並返回 AI 合成的
回答，包含引用。你可以透過 OpenRouter 使用它們（無需信用卡 - 支援
密碼學/預付）。

### 取得 OpenRouter API 鑰匙

1. 在 [https://openrouter.ai/](https://openrouter.ai/) 建立帳號
2. 加入額度（支援密碼學、預付或信用卡）
3. 在帳號設定中產生 API 鑰匙

### 設定 Perplexity 搜尋

```json5
{
  tools: {
    web: {
      search: {
        enabled: true,
        provider: "perplexity",
        perplexity: {
          // API 鑰匙（若設定 OPENROUTER_API_KEY 或 PERPLEXITY_API_KEY 則可選）
          apiKey: "sk-or-v1-...",
          // 基礎 URL（若省略則使用鑰匙感知預設）
          baseUrl: "https://openrouter.ai/api/v1",
          // 模型（預設為 perplexity/sonar-pro）
          model: "perplexity/sonar-pro",
        },
      },
    },
  },
}
```

**環境替代：** 在 Gateway
環境中設定 `OPENROUTER_API_KEY` 或 `PERPLEXITY_API_KEY`。對於 gateway 安裝，放在 `~/.openclaw/.env`。

若未設定基礎 URL，OpenClaw 根據 API 鑰匙來源選擇預設：

- `PERPLEXITY_API_KEY` 或 `pplx-...` → `https://api.perplexity.ai`
- `OPENROUTER_API_KEY` 或 `sk-or-...` → `https://openrouter.ai/api/v1`
- 未知鑰匙格式 → OpenRouter（安全後備）

### 可用的 Perplexity 模型

| 模型                             | 描述                    | 最適用於 |
| -------------------------------- | ----------------------- | -------- |
| `perplexity/sonar`               | 快速問答，包含 web 搜尋 | 快速查詢 |
| `perplexity/sonar-pro`（預設）   | 多步推理，包含 web 搜尋 | 複雜問題 |
| `perplexity/sonar-reasoning-pro` | 思維鏈分析              | 深度研究 |

## web_search

使用你配置的提供者搜尋 web。

### 需求

- `tools.web.search.enabled` 不得為 `false`（預設：啟用）
- 你選擇提供者的 API 鑰匙：
  - **Brave**：`BRAVE_API_KEY` 或 `tools.web.search.apiKey`
  - **Perplexity**：`OPENROUTER_API_KEY`、`PERPLEXITY_API_KEY` 或 `tools.web.search.perplexity.apiKey`

### 配置

```json5
{
  tools: {
    web: {
      search: {
        enabled: true,
        apiKey: "BRAVE_API_KEY_HERE", // 若設定 BRAVE_API_KEY 則可選
        maxResults: 5,
        timeoutSeconds: 30,
        cacheTtlMinutes: 15,
      },
    },
  },
}
```

### 工具參數

- `query`（必須）
- `count`（1–10；配置預設）
- `country`（可選）：2 字母國家代碼用於地區特定結果（例如 "DE"、"US"、"ALL"）。若省略，Brave 選擇其預設地區。
- `search_lang`（可選）：ISO 語言代碼用於搜尋結果（例如 "de"、"en"、"fr"）
- `ui_lang`（可選）：UI 元素的 ISO 語言代碼
- `freshness`（可選，僅 Brave）：按發現時間篩選（`pd`、`pw`、`pm`、`py` 或 `YYYY-MM-DDtoYYYY-MM-DD`）

**範例：**

```javascript
// 德國特定搜尋
await web_search({
  query: "TV online schauen",
  count: 10,
  country: "DE",
  search_lang: "de",
});

// 法文搜尋，法文 UI
await web_search({
  query: "actualités",
  country: "FR",
  search_lang: "fr",
  ui_lang: "fr",
});

// 近期結果（過去一週）
await web_search({
  query: "TMBG interview",
  freshness: "pw",
});
```

## web_fetch

抓取 URL 並提取可讀內容。

### web_fetch 需求

- `tools.web.fetch.enabled` 不得為 `false`（預設：啟用）
- 可選 Firecrawl 後備：設定 `tools.web.fetch.firecrawl.apiKey` 或 `FIRECRAWL_API_KEY`。

### web_fetch 配置

```json5
{
  tools: {
    web: {
      fetch: {
        enabled: true,
        maxChars: 50000,
        maxCharsCap: 50000,
        timeoutSeconds: 30,
        cacheTtlMinutes: 15,
        maxRedirects: 3,
        userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
        readability: true,
        firecrawl: {
          enabled: true,
          apiKey: "FIRECRAWL_API_KEY_HERE", // 若設定 FIRECRAWL_API_KEY 則可選
          baseUrl: "https://api.firecrawl.dev",
          onlyMainContent: true,
          maxAgeMs: 86400000, // ms (1 天)
          timeoutSeconds: 60,
        },
      },
    },
  },
}
```

### web_fetch 工具參數

- `url`（必須，http/https 只）
- `extractMode`（`markdown` | `text`）
- `maxChars`（截斷長頁面）

注意：

- `web_fetch` 首先使用 Readability（主內容提取），然後 Firecrawl（若配置）。若兩者都失敗，工具返回錯誤。
- Firecrawl 請求預設使用機器人規避模式並快取結果。
- `web_fetch` 預設傳送 Chrome 類 User-Agent 和 `Accept-Language`；若需要，覆蓋 `userAgent`。
- `web_fetch` 阻塊私有/內部主機名並重新檢查重定向（使用 `maxRedirects` 限制）。
- `maxChars` 被限制到 `tools.web.fetch.maxCharsCap`。
- `web_fetch` 是盡力而為的提取；某些網站需要瀏覽器工具。
- 見 [Firecrawl](/zh-Hant/tools/firecrawl) 以瞭解鑰匙設定和服務詳情。
- 回應被快取（預設 15 分鐘）以減少重複抓取。
- 若你使用工具設定檔/允許清單，加上 `web_search`/`web_fetch` 或 `group:web`。
- 若缺少 Brave 鑰匙，`web_search` 返回短設定提示，包含文件連結。
