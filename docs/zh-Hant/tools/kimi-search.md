---
summary: "Kimi 網路搜尋透過 Moonshot 網路搜尋"
read_when:
  - 你想使用 Kimi 作為 web_search
  - 你需要 KIMI_API_KEY 或 MOONSHOT_API_KEY
title: "Kimi Search（Kimi 搜尋）"
---

# Kimi 搜尋

OpenClaw 支援 Kimi 作為 `web_search` 提供者，使用 Moonshot 網路搜尋產生帶有引用的 AI 合成答案。

## 取得 API 金鑰

<Steps>
  <Step title="建立金鑰">
    從 [Moonshot AI](https://platform.moonshot.cn/) 取得 API 金鑰。
  </Step>
  <Step title="儲存金鑰">
    在 Gateway 環境中設定 `KIMI_API_KEY` 或 `MOONSHOT_API_KEY`，或透過以下方式設定：

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
      moonshot: {
        config: {
          webSearch: {
            apiKey: "sk-...", // 如果設定了 KIMI_API_KEY 或 MOONSHOT_API_KEY 則選用
          },
        },
      },
    },
  },
  tools: {
    web: {
      search: {
        provider: "kimi",
      },
    },
  },
}
```

**環境替代方案：** 在 Gateway 環境中設定 `KIMI_API_KEY` 或 `MOONSHOT_API_KEY`。對於 gateway 安裝，將其放在 `~/.openclaw/.env` 中。

## 其運作原理

Kimi 使用 Moonshot 網路搜尋合成帶有內嵌引用的答案，類似於 Gemini 和 Grok 的接地回應方式。

## 支援的參數

Kimi 搜尋支援標準的 `query` 和 `count` 參數。不支援提供者特定篩選器。

## 相關

- [網路搜尋概觀](/zh-Hant/tools/web) — 所有提供者和自動偵測
- [Gemini 搜尋](/zh-Hant/tools/gemini-search) — 透過 Google 接地的 AI 合成答案
- [Grok 搜尋](/zh-Hant/tools/grok-search) — 透過 xAI 接地的 AI 合成答案
