---
summary: "Grok 網路搜尋透過 xAI 網路接地回應"
read_when:
  - 你想使用 Grok 作為 web_search
  - 你需要 XAI_API_KEY 進行網路搜尋
title: "Grok Search（Grok 搜尋）"
---

# Grok 搜尋

OpenClaw 支援 Grok 作為 `web_search` 提供者，使用 xAI 網路接地回應產生由即時搜尋結果支援的 AI 合成答案及引用。

## 取得 API 金鑰

<Steps>
  <Step title="建立金鑰">
    從 [xAI](https://console.x.ai/) 取得 API 金鑰。
  </Step>
  <Step title="儲存金鑰">
    在 Gateway 環境中設定 `XAI_API_KEY`，或透過以下方式設定：

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
      xai: {
        config: {
          webSearch: {
            apiKey: "xai-...", // 如果設定了 XAI_API_KEY 則選用
          },
        },
      },
    },
  },
  tools: {
    web: {
      search: {
        provider: "grok",
      },
    },
  },
}
```

**環境替代方案：** 在 Gateway 環境中設定 `XAI_API_KEY`。對於 gateway 安裝，將其放在 `~/.openclaw/.env` 中。

## 其運作原理

Grok 使用 xAI 網路接地回應合成具有內嵌引用的答案，類似於 Gemini 的 Google Search 接地方式。

## 支援的參數

Grok 搜尋支援標準的 `query` 和 `count` 參數。目前不支援提供者特定篩選器。

## 相關

- [網路搜尋概觀](/zh-Hant/tools/web) — 所有提供者和自動偵測
- [Gemini 搜尋](/zh-Hant/tools/gemini-search) — 透過 Google 接地的 AI 合成答案
