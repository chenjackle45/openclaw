---
title: "API Usage and Costs（API 使用量和成本）"
summary: "稽核哪些功能可能調用付費 API、使用哪些金鑰以及如何檢視使用量"
read_when:
  - 您想了解哪些功能可能呼叫付費 API
  - 您需要稽核金鑰、成本和使用可見性
  - 您在解釋 /status 或 /usage 成本報告
---

# API 使用量與成本

此文件列出 **可以叫用 API 金鑰的功能**及其成本顯示的位置。它專注於可以產生提供者使用量或付費 API 呼叫的 OpenClaw 功能。

## 成本顯示位置（聊天 + CLI）

**每個工作階段的成本快照**

- `/status` 顯示目前的工作階段模型、內容使用量和上次回應令牌。
- 如果模型使用 **API 金鑰驗證**，`/status` 也會顯示上次回覆的 **估計成本**。

**每則訊息的成本頁腳**

- `/usage full` 將使用量頁腳附加到每個回覆，包括 **估計成本**（僅限 API 金鑰）。
- `/usage tokens` 僅顯示令牌；OAuth 流程隱藏美元成本。

**CLI 使用量視窗（提供者配額）**

- `openclaw status --usage` 和 `openclaw channels list` 顯示提供者 **使用量視窗**（配額快照，不是每則訊息的成本）。

參見 [令牌使用和成本](/zh-Hant/reference/token-use) 以取得詳細資料和範例。

## 如何發現金鑰

OpenClaw 可以從以下位置選取認證：

- **驗證設定檔**（每個代理，存儲在 `auth-profiles.json`）。
- **環境變數**（例如 `OPENAI_API_KEY`、`BRAVE_API_KEY`、`FIRECRAWL_API_KEY`）。
- **設定**（`models.providers.*.apiKey`、`tools.web.search.*`、`tools.web.fetch.firecrawl.*`、`memorySearch.*`、`talk.apiKey`）。
- **技能**（`skills.entries.<name>.apiKey`），可能會將金鑰匯出到技能程序環境。

## 可支出金鑰的功能

### 1) 核心模型回應（聊天 + 工具）

每個回覆或工具呼叫使用 **目前的模型提供者**（OpenAI、Anthropic 等）。這是使用量和成本的主要來源。

參見 [模型](/zh-Hant/providers/models) 以取得定價設定，[令牌使用和成本](/zh-Hant/reference/token-use) 以取得顯示。

### 2) 媒體理解（音訊／影像／影片）

入站媒體可在回覆執行前進行摘要／轉錄。這使用模型／提供者 API。

- 音訊：OpenAI／Groq／Deepgram（現在在金鑰存在時 **自動啟用**）。
- 影像：OpenAI／Anthropic／Google。
- 影片：Google。

參見 [媒體理解](/zh-Hant/nodes/media-understanding)。

### 3) 記憶嵌入 + 語義搜尋

語義記憶搜尋在配置為遠端提供者時使用 **嵌入 API**：

- `memorySearch.provider = "openai"` → OpenAI 嵌入
- `memorySearch.provider = "gemini"` → Gemini 嵌入
- `memorySearch.provider = "voyage"` → Voyage 嵌入
- `memorySearch.provider = "mistral"` → Mistral 嵌入
- `memorySearch.provider = "ollama"` → Ollama 嵌入（本地／自託管；通常無託管 API 計費）
- 可選的回退到遠端提供者，如果本地嵌入失敗

您可以透過 `memorySearch.provider = "local"`（無 API 使用）保持它本地。

參見 [記憶](/zh-Hant/concepts/memory)。

### 4) Web 搜尋工具

`web_search` 使用 API 金鑰，根據您的提供者可能會產生使用費用：

- **Brave Search API**：`BRAVE_API_KEY` 或 `tools.web.search.apiKey`
- **Gemini（Google 搜尋）**：`GEMINI_API_KEY` 或 `tools.web.search.gemini.apiKey`
- **Grok（xAI）**：`XAI_API_KEY` 或 `tools.web.search.grok.apiKey`
- **Kimi（Moonshot）**：`KIMI_API_KEY`、`MOONSHOT_API_KEY` 或 `tools.web.search.kimi.apiKey`
- **Perplexity Search API**：`PERPLEXITY_API_KEY`、`OPENROUTER_API_KEY` 或 `tools.web.search.perplexity.apiKey`

**Brave Search 免費額度**：每個 Brave 計畫都包含 $5／月的可更新免費額度。搜尋計畫費用為 $5 / 1000 個要求，所以額度可免費涵蓋 1,000 個要求／月。在 Brave 儀表板中設定您的使用量限制以避免意外費用。

參見 [Web 工具](/zh-Hant/tools/web)。

### 5) Web 擷取工具（Firecrawl）

`web_fetch` 在存在 API 金鑰時可以呼叫 **Firecrawl**：

- `FIRECRAWL_API_KEY` 或 `tools.web.fetch.firecrawl.apiKey`

如果未設定 Firecrawl，該工具會回退到直接擷取 + 可讀性（無付費 API）。

參見 [Web 工具](/zh-Hant/tools/web)。

### 6) 提供者使用量快照（狀態／健康）

某些狀態命令呼叫 **提供者使用量端點**以顯示配額視窗或驗證健康。這些通常是低量呼叫，但仍然會叫用提供者 API：

- `openclaw status --usage`
- `openclaw models status --json`

參見 [模型 CLI](/zh-Hant/cli/models)。

### 7) 壓縮保護摘要

壓縮保護可以使用 **目前的模型**摘要工作階段歷史記錄，該模型在執行時叫用提供者 API。

參見 [工作階段管理 + 壓縮](/zh-Hant/reference/session-management-compaction)。

### 8) 模型掃描／探測

`openclaw models scan` 可以探測 OpenRouter 模型，並在啟用探測時使用 `OPENROUTER_API_KEY`。

參見 [模型 CLI](/zh-Hant/cli/models)。

### 9) 談話（語音）

在配置時，談話模式可以叫用 **ElevenLabs**：

- `ELEVENLABS_API_KEY` 或 `talk.apiKey`

參見 [談話模式](/zh-Hant/nodes/talk)。

### 10) 技能（第三方 API）

技能可以將 `apiKey` 儲存在 `skills.entries.<name>.apiKey`。如果技能將該金鑰用於外部 API，根據技能的提供者可能會產生成本。

參見 [技能](/zh-Hant/tools/skills)。
