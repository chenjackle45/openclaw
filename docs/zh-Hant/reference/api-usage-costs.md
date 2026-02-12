---
summary: "審計哪些功能可能花費費用、使用了哪些金鑰，以及如何查看使用情況"
read_when:
  - 你想了解哪些功能可能呼叫付費 API
  - 你需要審計金鑰、成本和使用情況可見性
  - 你正在說明 /status 或 /usage 成本報告
title: "API Usage and Costs（API 使用和成本）"
---

# API 使用和成本

本文件列出**可能會呼叫 API 金鑰的功能**，以及它們的成本顯示在哪裡。它重點關注可以產生提供者使用或付費 API 呼叫的 OpenClaw 功能。

## 成本顯示的位置（聊天 + CLI）

**每個會話成本快照**

- `/status` 顯示目前會話模型、內容使用情況和最後回應標記。
- 如果模型使用**API 金鑰驗證**，`/status` 也會顯示最後回覆的**估計成本**。

**每個訊息成本頁腳**

- `/usage full` 在每個回覆中附加使用情況頁腳，包括**估計成本**（僅限 API 金鑰）。
- `/usage tokens` 僅顯示標記；OAuth 流程隱藏美元成本。

**CLI 使用情況視窗（提供者配額）**

- `openclaw status --usage` 和 `openclaw channels list` 顯示提供者**使用情況視窗**
  （配額快照，不是每個訊息成本）。

詳見[標記使用和成本](/zh-Hant/reference/token-use)了解詳情和範例。

## 金鑰如何被發現

OpenClaw 可以從以下位置擷取認證：

- **驗證設定檔**（每個 Agent，儲存在 `auth-profiles.json` 中）。
- **環境變數**（例如 `OPENAI_API_KEY`、`BRAVE_API_KEY`、`FIRECRAWL_API_KEY`）。
- **設定**（`models.providers.*.apiKey`、`tools.web.search.*`、`tools.web.fetch.firecrawl.*`、
  `memorySearch.*`、`talk.apiKey`）。
- **技能**（`skills.entries.<name>.apiKey`）可能會將金鑰匯出到技能進程環境。

## 可能花費金鑰的功能

### 1) 核心模型回覆（聊天 + 工具）

每個回覆或工具呼叫都使用**目前的模型提供者**（OpenAI、Anthropic 等）。這是使用和成本的主要來源。

詳見[模型](/zh-Hant/providers/models)了解定價設定和[標記使用和成本](/zh-Hant/reference/token-use)了解顯示。

### 2) 媒體理解（音訊/影像/影片）

入站媒體可在回覆執行前進行摘要/轉錄。這使用模型/提供者 API。

- 音訊：OpenAI / Groq / Deepgram（現在**自動啟用**當金鑰存在時）。
- 影像：OpenAI / Anthropic / Google。
- 影片：Google。

詳見[媒體理解](/zh-Hant/nodes/media-understanding)。

### 3) 記憶嵌入 + 語意搜尋

語意記憶搜尋在為遠端提供者設定時使用**嵌入 API**：

- `memorySearch.provider = "openai"` → OpenAI 嵌入
- `memorySearch.provider = "gemini"` → Gemini 嵌入
- `memorySearch.provider = "voyage"` → Voyage 嵌入
- 可選的後備至遠端提供者（如果本機嵌入失敗）

你可以使用 `memorySearch.provider = "local"` 保持本機（無 API 使用）。

詳見[記憶](/zh-Hant/concepts/memory)。

### 4) Web 搜尋工具（Brave / Perplexity via OpenRouter）

`web_search` 使用 API 金鑰，可能會產生使用費用：

- **Brave Search API**：`BRAVE_API_KEY` 或 `tools.web.search.apiKey`
- **Perplexity**（透過 OpenRouter）：`PERPLEXITY_API_KEY` 或 `OPENROUTER_API_KEY`

**Brave 免費層（慷慨）：**

- **2,000 次請求/月**
- **1 次請求/秒**
- **需要信用卡驗證**（除非升級，否則不收費）

詳見 [Web 工具](/zh-Hant/tools/web)。

### 5) Web 擷取工具（Firecrawl）

`web_fetch` 可在存在 API 金鑰時呼叫 **Firecrawl**：

- `FIRECRAWL_API_KEY` 或 `tools.web.fetch.firecrawl.apiKey`

如果未設定 Firecrawl，工具會回退到直接擷取 + 可讀性（無付費 API）。

詳見 [Web 工具](/zh-Hant/tools/web)。

### 6) 提供者使用情況快照（狀態/健康）

某些狀態命令呼叫**提供者使用情況端點**以顯示配額視窗或驗證健康。
這些通常是低容量呼叫，但仍會進行提供者 API：

- `openclaw status --usage`
- `openclaw models status --json`

詳見[模型 CLI](/zh-Hant/cli/models)。

### 7) 壓縮保護摘要

壓縮保護可以使用**目前模型**摘要會話歷史記錄，這在執行時會呼叫提供者 API。

詳見[會話管理 + 壓縮](/zh-Hant/reference/session-management-compaction)。

### 8) 模型掃描 / 探查

`openclaw models scan` 可以探查 OpenRouter 模型，並在啟用探查時使用 `OPENROUTER_API_KEY`。

詳見[模型 CLI](/zh-Hant/cli/models)。

### 9) Talk（語音）

Talk 模式可在設定時呼叫 **ElevenLabs**：

- `ELEVENLABS_API_KEY` 或 `talk.apiKey`

詳見 [Talk 模式](/zh-Hant/nodes/talk)。

### 10) 技能（第三方 API）

技能可以在 `skills.entries.<name>.apiKey` 中儲存 `apiKey`。如果技能對外部 API 使用該金鑰，可能會根據技能的提供者產生成本。

詳見[技能](/zh-Hant/tools/skills)。
