---
summary: "web_fetch 工具 — HTTP 擷取與可讀內容擷取"
read_when:
  - 你想擷取 URL 並擷取可讀內容
  - 你需要設定 web_fetch 或其 Firecrawl 備用方案
  - 你想瞭解 web_fetch 限制和快取
title: "Web Fetch（Web Fetch）"
sidebarTitle: "Web Fetch"
---

# Web Fetch

`web_fetch` 工具執行純 HTTP GET 並擷取可讀內容（HTML 轉 markdown 或文字）。它**不會**執行 JavaScript。

對於 JS 重型網站或受登入保護的頁面，改為使用 [Web Browser](/zh-Hant/tools/browser)。

## 快速入門

`web_fetch` **預設啟用** — 不需要設定。代理可以立即呼叫它：

```javascript
await web_fetch({ url: "https://example.com/article" });
```

## 工具參數

| 參數          | 型別     | 說明                                  |
| ------------- | -------- | ------------------------------------- |
| `url`         | `string` | 要擷取的 URL（必填，http/https 僅限） |
| `extractMode` | `string` | `"markdown"`（預設值）或 `"text"`     |
| `maxChars`    | `number` | 將輸出截斷為這麼多字元                |

## 其運作原理

<Steps>
  <Step title="擷取">
    使用類似 Chrome 的 User-Agent 和 `Accept-Language` 標頭傳送 HTTP GET。封鎖私人/內部主機名稱並重新檢查重新導向。
  </Step>
  <Step title="擷取">
    在 HTML 回應上執行 Readability（主內容擷取）。
  </Step>
  <Step title="備用（選用）">
    如果 Readability 失敗且 Firecrawl 已設定，透過 Firecrawl API 與機器人規避模式重試。
  </Step>
  <Step title="快取">
    結果快取 15 分鐘（可設定）以減少相同 URL 的重複擷取。
  </Step>
</Steps>

## 設定

```json5
{
  tools: {
    web: {
      fetch: {
        enabled: true, // 預設值：true
        maxChars: 50000, // 最大輸出字元
        maxCharsCap: 50000, // maxChars 參數的硬上限
        maxResponseBytes: 2000000, // 截斷前的最大下載大小
        timeoutSeconds: 30,
        cacheTtlMinutes: 15,
        maxRedirects: 3,
        readability: true, // 使用 Readability 擷取
        userAgent: "Mozilla/5.0 ...", // 覆寫 User-Agent
      },
    },
  },
}
```

## Firecrawl 備用

如果 Readability 擷取失敗，`web_fetch` 可以備用到 [Firecrawl](/zh-Hant/tools/firecrawl) 進行機器人規避和更好的擷取：

```json5
{
  tools: {
    web: {
      fetch: {
        firecrawl: {
          enabled: true,
          apiKey: "fc-...", // 如果設定了 FIRECRAWL_API_KEY 則選用
          baseUrl: "https://api.firecrawl.dev",
          onlyMainContent: true,
          maxAgeMs: 86400000, // 快取持續時間（1 天）
          timeoutSeconds: 60,
        },
      },
    },
  },
}
```

`tools.web.fetch.firecrawl.apiKey` 支援 SecretRef 物件。

<Note>
  如果 Firecrawl 已啟用且其 SecretRef 未解析且無 `FIRECRAWL_API_KEY` 環境備用，gateway 啟動會快速失敗。
</Note>

## 限制和安全

- `maxChars` 被限制為 `tools.web.fetch.maxCharsCap`
- 回應主體在解析前被限制於 `maxResponseBytes`；超大回應會被截斷並警告
- 私人/內部主機名稱會被封鎖
- 重新導向會被檢查並由 `maxRedirects` 限制
- `web_fetch` 是盡力而為 — 某些網站需要 [Web Browser](/zh-Hant/tools/browser)

## 工具設定檔

如果你使用工具設定檔或允許清單，新增 `web_fetch` 或 `group:web`：

```json5
{
  tools: {
    allow: ["web_fetch"],
    // 或：allow: ["group:web"]  （包括 web_fetch 和 web_search）
  },
}
```

## 相關

- [網路搜尋](/zh-Hant/tools/web) — 用多個提供者搜尋網路
- [Web Browser](/zh-Hant/tools/browser) — JS 重型網站的完整瀏覽器自動化
- [Firecrawl](/zh-Hant/tools/firecrawl) — Firecrawl 搜尋和抓取工具
