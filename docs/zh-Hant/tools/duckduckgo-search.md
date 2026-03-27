---
summary: "DuckDuckGo 網路搜尋 — 無需金鑰的備用提供者（實驗性、基於 HTML）"
read_when:
  - 你想要不需要 API 金鑰的網路搜尋提供者
  - 你想使用 DuckDuckGo 作為 web_search
  - 你需要零設定搜尋備用方案
title: "DuckDuckGo Search（DuckDuckGo 搜尋）"
---

# DuckDuckGo 搜尋

OpenClaw 支援 DuckDuckGo 作為**無需金鑰** `web_search` 提供者。不需要 API 金鑰或帳戶。

<Warning>
  DuckDuckGo 是**實驗性的、非官方**整合，從 DuckDuckGo 的非 JavaScript 搜尋頁面拉取結果 — 不是官方 API。預期偶爾會因為機器人挑戰頁面或 HTML 變更而中斷。
</Warning>

## 設定

無需 API 金鑰 — 只需將 DuckDuckGo 設為你的提供者：

<Steps>
  <Step title="設定">
    ```bash
    openclaw configure --section web
    # 選擇 "duckduckgo" 作為提供者
    ```
  </Step>
</Steps>

## 設定

```json5
{
  tools: {
    web: {
      search: {
        provider: "duckduckgo",
      },
    },
  },
}
```

地區和安全搜尋的選用外掛層級設定：

```json5
{
  plugins: {
    entries: {
      duckduckgo: {
        config: {
          webSearch: {
            region: "us-en", // DuckDuckGo 地區代碼
            safeSearch: "moderate", // "strict"、"moderate" 或 "off"
          },
        },
      },
    },
  },
}
```

## 工具參數

| 參數         | 說明                                                  |
| ------------ | ----------------------------------------------------- |
| `query`      | 搜尋查詢（必填）                                      |
| `count`      | 要返回的結果（1-10，預設值：5）                       |
| `region`     | DuckDuckGo 地區代碼（例如 `us-en`、`uk-en`、`de-de`） |
| `safeSearch` | 安全搜尋層級：`strict`、`moderate`（預設）或 `off`    |

地區和安全搜尋也可在外掛設定中設定（見上方） — 工具參數會覆寫每個查詢的設定值。

## 附註

- **無需 API 金鑰** — 開箱即用，零設定
- **實驗性** — 從 DuckDuckGo 的非 JavaScript HTML 搜尋頁面蒐集結果，不是官方 API 或 SDK
- **機器人挑戰風險** — DuckDuckGo 可能在大量或自動使用下提供 CAPTCHA 或封鎖請求
- **HTML 解析** — 結果取決於頁面結構，可能無預警變更
- **自動偵測順序** — DuckDuckGo 在自動偵測中最後檢查（順序 100），所以任何有金鑰的 API 支援提供者優先
- **安全搜尋預設為 moderate** 未設定時

<Tip>
  對於生產環境使用，考慮 [Brave Search](/zh-Hant/tools/brave-search)（提供免費層級）或其他 API 支援提供者。
</Tip>

## 相關

- [網路搜尋概觀](/zh-Hant/tools/web) — 所有提供者和自動偵測
- [Brave Search](/zh-Hant/tools/brave-search) — 結構化結果與免費層級
- [Exa 搜尋](/zh-Hant/tools/exa-search) — 神經搜尋與內容擷取
