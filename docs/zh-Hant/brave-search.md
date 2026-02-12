---
summary: "Brave Search API 設定用於 web_search"
read_when:
  - 你想使用 Brave Search 進行 web_search
  - 你需要 BRAVE_API_KEY 或計畫詳情
title: "Brave Search（Brave Search）"
---

# Brave Search API

OpenClaw 使用 Brave Search 作為 `web_search` 的預設提供者。

## 取得 API 金鑰

1. 在 [https://brave.com/search/api/](https://brave.com/search/api/) 建立 Brave Search API 帳戶
2. 在儀表板中選擇 **Data for Search** 計畫並產生 API 金鑰。
3. 將金鑰儲存在設定中（建議）或在 Gateway 環境中設定 `BRAVE_API_KEY`。

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

## 注意事項

- Data for AI 計畫**不**相容於 `web_search`。
- Brave 提供免費層加上付費計畫；檢查 Brave API 入口以取得目前限制。

詳見 [Web 工具](/zh-Hant/tools/web)了解完整的 web_search 設定。
