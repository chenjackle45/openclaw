---
summary: "稽核可能花費金錢的功能、使用了哪些金鑰，以及如何查看用量"
read_when:
  - 想了解哪些功能可能呼叫付費 API
  - 需要稽核金鑰、費用與用量可見性
  - 正在說明 /status 或 /usage 費用回報
title: "API Usage and Costs（API 用量與費用）"
---

# API 用量與費用

本文列出**可能呼叫 API 金鑰的功能**，以及費用顯示在哪裡。重點說明 OpenClaw 中可能產生提供商用量或付費 API 呼叫的功能。

## 費用顯示位置（聊天 + CLI）

**每個 session 的費用快照**

- `/status` 顯示目前 session 的模型、上下文用量，以及上一則回應的 token 數。
- 若模型使用 **API 金鑰驗證**，`/status` 也會顯示上一則回應的**預估費用**。

**每則訊息的費用頁尾**

- `/usage full` 在每則回應後附上用量頁尾，包含**預估費用**（僅限 API 金鑰）。
- `/usage tokens` 僅顯示 token 數；OAuth 流程隱藏金額。

**CLI 用量視窗（提供商配額）**

- `openclaw status --usage` 和 `openclaw channels list` 顯示提供商的**用量視窗**（配額快照，非每則訊息費用）。

詳細說明與範例請見 [Token 用量與費用](/zh-Hant/reference/token-use)。

## 金鑰的發現方式

OpenClaw 可從以下來源取得憑證：

- **Auth profiles**（每個 agent，儲存於 `auth-profiles.json`）。
- **環境變數**（例如 `OPENAI_API_KEY`、`BRAVE_API_KEY`、`FIRECRAWL_API_KEY`）。
- **Config**（`models.providers.*.apiKey`、`tools.web.search.*`、`tools.web.fetch.firecrawl.*`、`memorySearch.*`、`talk.apiKey`）。
- **Skills**（`skills.entries.<name>.apiKey`），可將金鑰匯出至 skill 程序的環境變數。

## 可能花費金鑰的功能

### 1）核心模型回應（聊天 + 工具）

每次回應或工具呼叫都會使用**目前的模型提供商**（OpenAI、Anthropic 等）。這是用量與費用的主要來源。

定價設定請見 [Models](/zh-Hant/providers/models)，顯示方式請見 [Token 用量與費用](/zh-Hant/reference/token-use)。

### 2）媒體理解（音訊／影像／影片）

收到的媒體在回應流程執行前可先進行摘要／轉錄。這會使用模型／提供商的 API。

- 音訊：OpenAI / Groq / Deepgram（金鑰存在時現已**自動啟用**）。
- 影像：OpenAI / Anthropic / Google。
- 影片：Google。

請見 [媒體理解](/zh-Hant/nodes/media-understanding)。

### 3）記憶嵌入 + 語意搜尋

當設定為遠端提供商時，語意記憶搜尋會使用 **Embedding API**：

- `memorySearch.provider = "openai"` → OpenAI embeddings
- `memorySearch.provider = "gemini"` → Gemini embeddings
- `memorySearch.provider = "voyage"` → Voyage embeddings
- `memorySearch.provider = "mistral"` → Mistral embeddings
- `memorySearch.provider = "ollama"` → Ollama embeddings（本地／自行託管；通常不計費）
- 可選擇在本地 embeddings 失敗時退回至遠端提供商

使用 `memorySearch.provider = "local"` 可保持本地運作（不使用 API）。

請見 [記憶](/zh-Hant/concepts/memory)。

### 4）網路搜尋工具

`web_search` 使用 API 金鑰，依提供商不同可能產生用量費用：

- **Brave Search API**：`BRAVE_API_KEY` 或 `tools.web.search.apiKey`
- **Gemini（Google 搜尋）**：`GEMINI_API_KEY`
- **Grok（xAI）**：`XAI_API_KEY`
- **Kimi（Moonshot）**：`KIMI_API_KEY` 或 `MOONSHOT_API_KEY`
- **Perplexity Search API**：`PERPLEXITY_API_KEY`

**Brave Search 免費額度：** 每個 Brave 方案每月附贈 $5 美元免費額度（每月重置）。Search 方案費率為每 1,000 次 $5 美元，因此免費額度涵蓋每月 1,000 次查詢。請在 Brave 儀表板設定用量上限，以避免意外收費。

請見 [網路工具](/zh-Hant/tools/web)。

### 5）網頁擷取工具（Firecrawl）

`web_fetch` 在有 API 金鑰時可呼叫 **Firecrawl**：

- `FIRECRAWL_API_KEY` 或 `tools.web.fetch.firecrawl.apiKey`

若未設定 Firecrawl，該工具會退回至直接擷取 + readability（無付費 API）。

請見 [網路工具](/zh-Hant/tools/web)。

### 6）提供商用量快照（status/health）

部分 status 指令會呼叫**提供商用量端點**以顯示配額視窗或驗證健康狀態。這些通常是低頻呼叫，但仍會使用提供商 API：

- `openclaw status --usage`
- `openclaw models status --json`

請見 [Models CLI](/zh-Hant/cli/models)。

### 7）壓縮保護摘要

壓縮保護功能可使用**目前模型**對 session 歷程進行摘要，執行時會呼叫提供商 API。

請見 [Session 管理 + 壓縮](/zh-Hant/reference/session-management-compaction)。

### 8）模型掃描／探測

`openclaw models scan` 可探測 OpenRouter 模型，啟用探測時會使用 `OPENROUTER_API_KEY`。

請見 [Models CLI](/zh-Hant/cli/models)。

### 9）Talk（語音）

Talk 模式在設定後可呼叫 **ElevenLabs**：

- `ELEVENLABS_API_KEY` 或 `talk.apiKey`

請見 [Talk 模式](/zh-Hant/nodes/talk)。

### 10）Skills（第三方 API）

Skills 可在 `skills.entries.<name>.apiKey` 中儲存 `apiKey`。若某個 skill 使用該金鑰呼叫外部 API，將依該 skill 的提供商計費。

請見 [Skills](/zh-Hant/tools/skills)。
