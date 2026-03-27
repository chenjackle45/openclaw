---
summary: "Gemini 網路搜尋與 Google Search 接地"
read_when:
  - 你想使用 Gemini 作為 web_search
  - 你需要 GEMINI_API_KEY
  - 你想要 Google Search 接地
title: "Gemini Search（Gemini 搜尋）"
---

# Gemini 搜尋

OpenClaw 支援 Gemini 模型與內置的 [Google Search 接地](https://ai.google.dev/gemini-api/docs/grounding)，它返回由即時 Google Search 結果支援的 AI 合成答案及引用。

## 取得 API 金鑰

<Steps>
  <Step title="建立金鑰">
    前往 [Google AI Studio](https://aistudio.google.com/apikey) 並建立 API 金鑰。
  </Step>
  <Step title="儲存金鑰">
    在 Gateway 環境中設定 `GEMINI_API_KEY`，或透過以下方式設定：

    ```bash
    openclaw configure --section web
    ```

  </Step>
</Steps>

## 設定

```json5
{
  plugins: {
    entries: {
      google: {
        config: {
          webSearch: {
            apiKey: "AIza...", // 如果設定了 GEMINI_API_KEY 則選用
            model: "gemini-2.5-flash", // 預設值
          },
        },
      },
    },
  },
  tools: {
    web: {
      search: {
        provider: "gemini",
      },
    },
  },
}
```

**環境替代方案：** 在 Gateway 環境中設定 `GEMINI_API_KEY`。對於 gateway 安裝，將其放在 `~/.openclaw/.env` 中。

## 其運作原理

與傳統搜尋提供者不同，後者返回連結和摘錄清單，Gemini 使用 Google Search 接地產生具有內嵌引用的 AI 合成答案。結果包含合成答案和來源 URL。

- 來自 Gemini 接地的引用 URL 會自動從 Google 重新導向 URL 解析為直接 URL。
- 重新導向解析使用 SSRF 防護路徑（HEAD + 重新導向檢查 + http/https 驗證）後才返回最終引用 URL。
- 重新導向解析使用嚴格的 SSRF 預設值，所以重新導向到私人/內部目標會被封鎖。

## 支援的參數

Gemini 搜尋支援標準的 `query` 和 `count` 參數。不支援提供者特定篩選器如 `country`、`language`、`freshness` 和 `domain_filter`。

## 模型選擇

預設模型是 `gemini-2.5-flash`（快速且具成本效益）。任何支援接地的 Gemini 模型都可透過 `plugins.entries.google.config.webSearch.model` 使用。

## 相關

- [網路搜尋概觀](/zh-Hant/tools/web) — 所有提供者和自動偵測
- [Brave Search](/zh-Hant/tools/brave-search) — 含摘錄的結構化結果
- [Perplexity 搜尋](/zh-Hant/tools/perplexity-search) — 結構化結果 + 內容擷取
