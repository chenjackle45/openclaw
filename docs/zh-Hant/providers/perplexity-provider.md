---
title: "Perplexity (Provider)（Perplexity (Provider)）"
summary: "Perplexity 網頁搜尋提供者設定 (API 金鑰、搜尋模式、篩選)"
read_when:
  - You want to configure Perplexity as a web search provider
  - You need the Perplexity API key or OpenRouter proxy setup
---

# Perplexity (Web Search Provider)

Perplexity 外掛透過 Perplexity Search API 或透過 OpenRouter 的 Perplexity Sonar 提供網頁搜尋功能。

<Note>
此頁面涵蓋 Perplexity **提供者**設定。有關 Perplexity **工具**（代理程式如何使用它），請參閱 [Perplexity 工具](/zh-Hant/tools/perplexity-search)。
</Note>

- 類型：網頁搜尋提供者（不是模型提供者）
- 驗證：`PERPLEXITY_API_KEY`（直接）或 `OPENROUTER_API_KEY`（透過 OpenRouter）
- 設定路徑：`plugins.entries.perplexity.config.webSearch.apiKey`

## 快速開始

1. 設定 API 金鑰：

```bash
openclaw configure --section web
```

或直接設定：

```bash
openclaw config set plugins.entries.perplexity.config.webSearch.apiKey "pplx-xxxxxxxxxxxx"
```

2. 設定後，代理程式將自動使用 Perplexity 進行網頁搜尋。

## 搜尋模式

外掛根據 API 金鑰前綴自動選擇傳輸：

| 金鑰前綴 | 傳輸                       | 特性                               |
| -------- | -------------------------- | ---------------------------------- |
| `pplx-`  | 本機 Perplexity Search API | 結構化結果、域名 / 語言 / 日期篩選 |
| `sk-or-` | OpenRouter (Sonar)         | AI 合成的答案，帶引用              |

## 本機 API 篩選

使用本機 Perplexity API（`pplx-` 金鑰）時，搜尋支援：

- **國家**：2 字母國家代碼
- **語言**：ISO 639-1 語言代碼
- **日期範圍**：日、周、月、年
- **域名篩選**：允許清單 / 拒絕清單（最多 20 個域名）
- **內容預算**：`max_tokens`、`max_tokens_per_page`

## 環境注意

如果閘道作為守護程式執行 (launchd/systemd)，請確保
