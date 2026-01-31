---
title: "Web(網頁工具)"
summary: "網頁搜尋與擷取工具（Brave Search API、Perplexity 直連或經由 OpenRouter）"
read_when:
  - 想要啟用 web_search 或 web_fetch 時
  - 需要設定 Brave Search API 金鑰時
  - 想要使用 Perplexity Sonar 進行網頁搜尋時
---

# 網頁工具 (Web Tools)

OpenClaw 提供兩款輕量化的網頁工具：

- `web_search` — 透過 Brave Search API（預設）或 Perplexity Sonar 全球即時搜尋。
- `web_fetch` — HTTP 內容擷取並轉化為具可讀性的文字（HTML → Markdown/純文字）。

注意：這些工具**不等於**瀏覽器。若遇到需要執行 JavaScript 或處理登入的網站，請改用 [瀏覽器工具 (Browser tool)](/tools/browser)。

## 選用搜尋供應商

| 供應商 | 優點 | 缺點 | API 金鑰 |
|----------|------|------|---------|
| **Brave** (預設) | 速度快、結構化結果、提供免費額度 | 傳統的搜尋結果格式 | `BRAVE_API_KEY` |
| **Perplexity** | AI 彙整、具備引用來源、即時性強 | 需要 Perplexity 或 OpenRouter 權限 | `PERPLEXITY_API_KEY` |

## Brave Search 設定
1. 在 [Brave Search API](https://brave.com/search/api/) 註冊帳號。
2. 產生 API 金鑰（請選用 **Data for Search** 方案）。
3. 執行 `openclaw configure --section web` 將金鑰存入配置。

## Perplexity 設定 (直連或經由 OpenRouter)
Perplexity Sonar 模型具備原生的網頁搜尋能力。您可以直接使用其 API，或透過 OpenRouter（支援儲值/虛擬貨幣支付）接入。

配置範例：
```json5
{
  tools: {
    web: {
      search: {
        provider: "perplexity",
        perplexity: {
          apiKey: "sk-or-v1-...",
          baseUrl: "https://openrouter.ai/api/v1",
          model: "perplexity/sonar-pro"
        }
      }
    }
  }
}
```

## `web_search` 參數說明
- `query`：搜尋關鍵字（必要）。
- `count`：搜尋結果數量 (1–10)。
- `country`：地區代碼（如 "TW", "US"）。
- `freshness`：時間過濾（如 `pd` 表示過去 24 小時，`pw` 表示過去一週）。

## `web_fetch` 內容擷取
`web_fetch` 預設啟用，它會先嘗試使用 Readability (內容分析) 進行擷取，若失敗則會套用 Firecrawl (如果已配置)。
- **不執行 JavaScript**：僅用於快速讀取靜態內容。
- **快取機制**：預設快取 15 分鐘以減少重複抓取。
- **Firecrawl 備援**：支援規避機器人檢測。

```bash
# 修改配置範例
openclaw config set tools.web.fetch.firecrawl.apiKey "您的金鑰"
```
