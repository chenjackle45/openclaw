---
summary: "Tavily 搜尋和擷取工具"
read_when:
  - 你想要 Tavily 支援的網路搜尋
  - 你需要 Tavily API 金鑰
  - 你想要 Tavily 作為 web_search 提供者
  - 你想從 URL 進行內容擷取
title: "Tavily"
---

# Tavily

OpenClaw 可以用**兩種方式**使用 Tavily：

- 作為 `web_search` 提供者
- 作為明確外掛工具：`tavily_search` 和 `tavily_extract`

Tavily 是為 AI 應用程式設計的搜尋 API，返回為 LLM 消費最佳化的結構化結果。它支援可設定搜尋深度、主題篩選、領域篩選、AI 產生的答案摘要和 URL 內容擷取（包括 JavaScript 呈現的頁面）。

## 取得 API 金鑰

1. 在 [tavily.com](https://tavily.com/) 建立 Tavily 帳戶。
2. 在儀表板中產生 API 金鑰。
3. 在設定中儲存它或在 gateway 環境中設定 `TAVILY_API_KEY`。

## 設定 Tavily 搜尋

```json5
{
  plugins: {
    entries: {
      tavily: {
        enabled: true,
        config: {
          webSearch: {
            apiKey: "tvly-...", // 如果設定了 TAVILY_API_KEY 則選用
            baseUrl: "https://api.tavily.com",
          },
        },
      },
    },
  },
  tools: {
    web: {
      search: {
        provider: "tavily",
      },
    },
  },
}
```

附註：

- 在入職中選擇 Tavily 或 `openclaw configure --section web` 會自動啟用捆綁的 Tavily 外掛。
- 在 `plugins.entries.tavily.config.webSearch.*` 下儲存 Tavily 設定。
- `web_search` 與 Tavily 支援 `query` 和 `count`（最多 20 個結果）。
- 對於 Tavily 特定控制如 `search_depth`、`topic`、`include_answer` 或領域篩選，請使用 `tavily_search`。

## Tavily 外掛工具

### `tavily_search`

當你想要 Tavily 特定搜尋控制而非通用 `web_search` 時使用此工具。

| 參數              | 說明                                                     |
| ----------------- | -------------------------------------------------------- |
| `query`           | 搜尋查詢字串（保持在 400 字元以下）                      |
| `search_depth`    | `basic`（預設值，平衡）或 `advanced`（最高相關性，較慢） |
| `topic`           | `general`（預設值）、`news`（實時更新）或 `finance`      |
| `max_results`     | 結果數，1-20（預設值：5）                                |
| `include_answer`  | 包含 AI 產生的答案摘要（預設值：false）                  |
| `time_range`      | 按新近度篩選：`day`、`week`、`month` 或 `year`           |
| `include_domains` | 限制結果的領域陣列                                       |
| `exclude_domains` | 從結果中排除的領域陣列                                   |

**搜尋深度：**

| 深度       | 速度 | 相關性 | 最佳用途               |
| ---------- | ---- | ------ | ---------------------- |
| `basic`    | 較快 | 高     | 通用查詢（預設值）     |
| `advanced` | 較慢 | 最高   | 精確性、特定事實、研究 |

### `tavily_extract`

使用此工具從一個或多個 URL 擷取清潔內容。處理 JavaScript 呈現的頁面，並支援查詢焦點分塊以進行有針對性的擷取。

| 參數                | 說明                                                       |
| ------------------- | ---------------------------------------------------------- |
| `urls`              | 要擷取的 URL 陣列（每個請求 1-20 個）                      |
| `query`             | 按此查詢的相關性重新排序擷取的分塊                         |
| `extract_depth`     | `basic`（預設值，快速）或 `advanced`（適用於 JS 重型頁面） |
| `chunks_per_source` | 每個 URL 的分塊，1-5（需要 `query`）                       |
| `include_images`    | 在結果中包含圖像 URL（預設值：false）                      |

**擷取深度：**

| 深度       | 何時使用                      |
| ---------- | ----------------------------- |
| `basic`    | 簡單頁面 - 先試試這個         |
| `advanced` | JS 呈現的 SPA、動態內容、表格 |

提示：

- 每個請求最多 20 個 URL。將較大清單分成多個呼叫。
- 使用 `query` + `chunks_per_source` 只取得相關內容，而非完整頁面。
- 先試試 `basic`；如果內容遺失或不完整，則改為 `advanced`。

## 選擇正確的工具

| 需要                        | 工具             |
| --------------------------- | ---------------- |
| 快速網路搜尋，無特殊選項    | `web_search`     |
| 帶深度、主題、AI 答案的搜尋 | `tavily_search`  |
| 從特定 URL 擷取內容         | `tavily_extract` |

## 相關

- [網路搜尋概觀](/zh-Hant/tools/web) — 所有提供者和自動偵測
- [Firecrawl](/zh-Hant/tools/firecrawl) — 搜尋 + 抓取與內容擷取
- [Exa 搜尋](/zh-Hant/tools/exa-search) — 神經搜尋與內容擷取
