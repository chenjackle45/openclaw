---
summary: "Exa AI 搜尋 — 神經和關鍵字搜尋與內容擷取"
read_when:
  - 你想使用 Exa 作為 web_search
  - 你需要 EXA_API_KEY
  - 你想要神經搜尋或內容擷取
title: "Exa Search（Exa 搜尋）"
---

# Exa 搜尋

OpenClaw 支援 [Exa AI](https://exa.ai/) 作為 `web_search` 提供者。Exa 提供神經、關鍵字和混合搜尋模式，具有內置內容擷取（重點、文字、摘要）。

## 取得 API 金鑰

<Steps>
  <Step title="建立帳戶">
    在 [exa.ai](https://exa.ai/) 上註冊並從你的儀表板產生 API 金鑰。
  </Step>
  <Step title="儲存金鑰">
    在 Gateway 環境中設定 `EXA_API_KEY`，或透過以下方式設定：

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
      exa: {
        config: {
          webSearch: {
            apiKey: "exa-...", // 如果設定了 EXA_API_KEY 則選用
          },
        },
      },
    },
  },
  tools: {
    web: {
      search: {
        provider: "exa",
      },
    },
  },
}
```

**環境替代方案：** 在 Gateway 環境中設定 `EXA_API_KEY`。對於 gateway 安裝，將其放在 `~/.openclaw/.env` 中。

## 工具參數

| 參數          | 說明                                                                      |
| ------------- | ------------------------------------------------------------------------- |
| `query`       | 搜尋查詢（必填）                                                          |
| `count`       | 要返回的結果（1-100）                                                     |
| `type`        | 搜尋模式：`auto`、`neural`、`fast`、`deep`、`deep-reasoning` 或 `instant` |
| `freshness`   | 時間篩選器：`day`、`week`、`month` 或 `year`                              |
| `date_after`  | 此日期之後的結果（YYYY-MM-DD）                                            |
| `date_before` | 此日期之前的結果（YYYY-MM-DD）                                            |
| `contents`    | 內容擷取選項（見下方）                                                    |

### 內容擷取

Exa 可以連同搜尋結果一起返回擷取的內容。傳遞 `contents` 物件以啟用：

```javascript
await web_search({
  query: "transformer architecture explained",
  type: "neural",
  contents: {
    text: true, // 完整頁面文字
    highlights: { numSentences: 3 }, // 關鍵句子
    summary: true, // AI 摘要
  },
});
```

| 內容選項     | 類型                                                                  | 說明             |
| ------------ | --------------------------------------------------------------------- | ---------------- |
| `text`       | `boolean \| { maxCharacters }`                                        | 擷取完整頁面文字 |
| `highlights` | `boolean \| { maxCharacters, query, numSentences, highlightsPerUrl }` | 擷取關鍵句子     |
| `summary`    | `boolean \| { query }`                                                | AI 生成的摘要    |

### 搜尋模式

| 模式             | 說明                     |
| ---------------- | ------------------------ |
| `auto`           | Exa 選擇最佳模式（預設） |
| `neural`         | 語義/意義搜尋            |
| `fast`           | 快速關鍵字搜尋           |
| `deep`           | 徹底的深入搜尋           |
| `deep-reasoning` | 深入搜尋含推理           |
| `instant`        | 最快結果                 |

## 附註

- 如果未提供 `contents` 選項，Exa 預設為 `{ highlights: true }`，所以結果包含關鍵句子摘錄
- 結果在可用時保留來自 Exa API 回應的 `highlightScores` 和 `summary` 欄位
- 結果說明從重點優先解析，然後是摘要，然後是完整文字 — 無論哪個可用
- `freshness` 和 `date_after`/`date_before` 無法合併 — 使用一種時間篩選模式
- 每個查詢最多可返回 100 個結果（受 Exa 搜尋類型限制）
- 結果預設快取 15 分鐘（可透過 `cacheTtlMinutes` 設定）
- Exa 是具有結構化 JSON 回應的官方 API 整合

## 相關

- [網路搜尋概觀](/zh-Hant/tools/web) — 所有提供者和自動偵測
- [Brave Search](/zh-Hant/tools/brave-search) — 含國家/語言篩選器的結構化結果
- [Perplexity 搜尋](/zh-Hant/tools/perplexity-search) — 結構化結果與內容擷取
