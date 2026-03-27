---
summary: "Brave Search API 設定用於 web_search"
read_when:
  - You want to use Brave Search for web_search
  - You need a BRAVE_API_KEY or plan details
title: "Brave Search（Brave Search）"
---

# Brave Search API

OpenClaw 支援 Brave Search API 作為 `web_search` 提供者。

## 取得 API 金鑰

1. 在 [https://brave.com/search/api/](https://brave.com/search/api/) 建立 Brave Search API 帳戶。
2. 在儀表板中，選擇 **搜尋** 計畫並產生 API 金鑰。
3. 在設定中儲存金鑰或在閘道環境中設定 `BRAVE_API_KEY`。

## 設定範例

```json5
{
  plugins: {
    entries: {
      brave: {
        config: {
          webSearch: {
            apiKey: "BRAVE_API_KEY_HERE",
          },
        },
      },
    },
  },
  tools: {
    web: {
      search: {
        provider: "brave",
        maxResults: 5,
        timeoutSeconds: 30,
      },
    },
  },
}
```

Brave 搜尋的提供者特定設定現在位於 `plugins.entries.brave.config.webSearch.*` 下。舊版 `tools.web.search.apiKey` 仍然透過相容性墊片載入，但它不再是標準配置路徑。

## 工具參數

| 參數          | 說明                                                   |
| ------------- | ------------------------------------------------------ |
| `query`       | 搜尋查詢（必要）                                       |
| `count`       | 傳回的結果數 (1-10，預設：5)                           |
| `country`     | 2 字母 ISO 國家代碼（例如 "US"、"DE"）                 |
| `language`    | 搜尋結果的 ISO 639-1 語言代碼（例如 "en"、"de"、"fr"） |
| `ui_lang`     | UI 元素的 ISO 語言代碼                                 |
| `freshness`   | 時間篩選：`day`（24h）、`week`、`month` 或 `year`      |
| `date_after`  | 僅在此日期之後發佈的結果 (YYYY-MM-DD)                  |
| `date_before` | 僅在此日期之前發佈的結果 (YYYY-MM-DD)                  |

**範例：**

```javascript
// 特定國家和語言的搜尋
await web_search({
  query: "renewable energy",
  country: "DE",
  language: "de",
});

// 最近的結果（過去一周）
await web_search({
  query: "AI news",
  freshness: "week",
});

// 日期範圍搜尋
await web_search({
  query: "AI developments",
```
