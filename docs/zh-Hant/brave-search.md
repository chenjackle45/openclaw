---
summary: "Brave Search API 設定用於 web_search"
read_when:
  - 想使用 Brave Search 進行 web_search
  - 需要 BRAVE_API_KEY 或方案詳情
title: "Brave Search（Brave 搜尋）"
---

# Brave Search API

OpenClaw 支援 Brave Search API 作為 `web_search` 提供商。

## 取得 API 金鑰

1. 在 [https://brave.com/search/api/](https://brave.com/search/api/) 建立 Brave Search API 帳號
2. 在儀表板中選擇 **Search** 方案並產生 API 金鑰。
3. 將金鑰儲存在設定中，或在 Gateway 環境中設定 `BRAVE_API_KEY`。

## 設定範例

```json5
{
  tools: {
    web: {
      search: {
        provider: "brave",
        apiKey: "BRAVE_API_KEY_HERE",
        maxResults: 5,
        timeoutSeconds: 30,
      },
    },
  },
}
```

## 工具參數

| 參數          | 說明                                                        |
| ------------- | ----------------------------------------------------------- |
| `query`       | 搜尋查詢（必填）                                            |
| `count`       | 返回的結果數量（1-10，預設：5）                             |
| `country`     | 2 字母 ISO 國家代碼（例如「US」、「DE」）                   |
| `language`    | 搜尋結果的 ISO 639-1 語言代碼（例如「en」、「de」、「fr」） |
| `ui_lang`     | UI 元素的 ISO 語言代碼                                      |
| `freshness`   | 時間過濾：`day`（24小時）、`week`、`month` 或 `year`        |
| `date_after`  | 僅返回此日期後發布的結果（YYYY-MM-DD）                      |
| `date_before` | 僅返回此日期前發布的結果（YYYY-MM-DD）                      |

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
```

## 注意事項

- OpenClaw 使用 Brave **Search** 方案。若你有舊版訂閱（例如原本每月 2,000 次查詢的免費方案），仍然有效，但不包含 LLM Context 或更高速率限制等新功能。
- 每個 Brave 方案包含 **$5/月免費額度**（每月重置）。Search 方案費率為每 1,000 次 $5 美元，因此免費額度涵蓋每月 1,000 次查詢。請在 Brave 儀表板設定用量上限，以避免意外收費。詳見 [Brave API 入口](https://brave.com/search/api/) 的目前方案說明。
- Search 方案包含 LLM Context 端點和 AI 推理權利。將結果儲存用於訓練或微調模型需要具備明確儲存權利的方案。請見 Brave [服務條款](https://api-dashboard.search.brave.com/terms-of-service)。
- 結果預設快取 15 分鐘（可透過 `cacheTtlMinutes` 設定）。

完整的 web_search 設定請見 [網路工具](/zh-Hant/tools/web)。
