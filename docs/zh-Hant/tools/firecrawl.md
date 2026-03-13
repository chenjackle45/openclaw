---
summary: "Firecrawl 為 web_fetch 提供的後備（反機器人 + 快取擷取）"
read_when:
  - 你想要 Firecrawl 支援的網路擷取
  - 你需要 Firecrawl API 金鑰
  - 你想要針對 web_fetch 的反機器人擷取
title: "Firecrawl"
---

# Firecrawl

OpenClaw 可以使用 **Firecrawl** 作為 `web_fetch` 的後備提取器。它是一個託管 content 擷取服務，支援機器人規避和快取，這對 JS 密集網站或封鎖純 HTTP 擷取的頁面有幫助。

## 取得 API 金鑰

1. 建立 Firecrawl 帳戶並產生 API 金鑰。
2. 在配置中儲存它或在 gateway environment 中設定 `FIRECRAWL_API_KEY`。

## 配置 Firecrawl

```json5
{
  tools: {
    web: {
      fetch: {
        firecrawl: {
          apiKey: "FIRECRAWL_API_KEY_HERE",
          baseUrl: "https://api.firecrawl.dev",
          onlyMainContent: true,
          maxAgeMs: 172800000,
          timeoutSeconds: 60,
        },
      },
    },
  },
}
```

注意：

- `firecrawl.enabled` 預設為 `true`，除非明確設定為 `false`。
- Firecrawl 後備嘗試僅在 API 金鑰可用時執行（`tools.web.fetch.firecrawl.apiKey` 或 `FIRECRAWL_API_KEY`）。
- `maxAgeMs` 控制快取結果可以多舊（毫秒）。預設為 2 天。

## 隱身／機器人規避

Firecrawl 公開 **proxy mode** 參數用於機器人規避（`basic`、`stealth` 或 `auto`）。
OpenClaw 始終對 Firecrawl 請求使用 `proxy: "auto"` 加上 `storeInCache: true`。
如果 proxy 被省略，Firecrawl 預設為 `auto`。`auto` 在基本嘗試失敗時使用隱身代理重試，這可能比僅基本爬取使用更多信用。

## `web_fetch` 如何使用 Firecrawl

`web_fetch` 擷取順序：

1. Readability（本機）
2. Firecrawl（如果配置）
3. 基本 HTML 清理（最後後備）

見 [Web tools](/zh-Hant/tools/web) 以了解完整的 web 工具設定。
