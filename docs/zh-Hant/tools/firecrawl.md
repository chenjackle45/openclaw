---
title: "Firecrawl(Firecrawl 選項)"
summary: "Firecrawl 作為 `web_fetch` 的備援擷取器（防機器人檢測 + 快取擷取）"
read_when:
  - 想要使用 Firecrawl 進行網頁擷取時
  - 需要設定 Firecrawl API 金鑰時
  - 想要提升 `web_fetch` 規避機器人檢測的能力時
---

# Firecrawl

OpenClaw 可以將 **Firecrawl** 作為 `web_fetch` 的備援擷取器。這是一項託管式內容擷取服務，支援規避機器人檢測與快取，有助於處理大量使用 JavaScript 或封鎖一般 HTTP 存取的頁面。

## 獲取 API 金鑰
1. 在 [Firecrawl](https://www.firecrawl.dev/) 註冊帳號並產生 API 金鑰。
2. 將其存入配置檔中，或在 Gateway 環境變數中設定 `FIRECRAWL_API_KEY`。

## 配置 Firecrawl
```json5
{
  tools: {
    web: {
      fetch: {
        firecrawl: {
          apiKey: "您的金鑰",
          baseUrl: "https://api.firecrawl.dev",
          onlyMainContent: true,    // 僅擷取主要內容
          maxAgeMs: 172800000,      // 快取有效時間（預設 2 天）
          timeoutSeconds: 60
        }
      }
    }
  }
}
```

## 隱身與規避行為 (Stealth / Anti-bot)
OpenClaw 在發送指令時預掛載了 `proxy: "auto"` 與 `storeInCache: true`。`auto` 模式會在基礎下載失敗時自動切換至隱身代理程式，這可能會消耗較多點數，但能大幅提升擷取成功率。

## `web_fetch` 的執行順序
當 Agent 呼叫 `web_fetch` 時，系統會依序嘗試：
1. **Readability (本地)**：最快、無成本。
2. **Firecrawl**：若具備金鑰，則發起遠端擷取。
3. **基礎 HTML 若清理**：最後的保底手段。

更多網頁工具設定請參閱 [網頁工具指南](/tools/web)。
