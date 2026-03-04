---
summary: "審計什麼可以花錢、使用哪些金鑰以及如何查看使用情況"
read_when:
  - 想了解哪些功能可能呼叫付費 API 時
  - 需要審計金鑰、成本和使用可見性時
  - 解釋 /status 或 /usage 成本報告時
title: "API Usage and Costs（API 使用和成本）"
---

# API 使用和成本

本文件列出**可以呼叫 API 金鑰的功能**以及它們的成本在哪裡顯示。它聚焦於可以產生提供商使用或付費 API 呼叫的 OpenClaw 功能。

## 成本顯示的位置（聊天 + CLI）

**每個工作階段成本快照**

- `/status` 顯示當前工作階段模型、上下文使用情況和最後一個回應令牌。
- 如果模型使用 **API 金鑰認證**，`/status` 也會顯示最後一個回應的**預估成本**。

**每個訊息成本頁尾**

- `/usage full` 為每個回應附加使用頁尾，包括**預估成本**（僅限 API 金鑰）。
- `/usage tokens` 僅顯示令牌；OAuth 流隱藏美元成本。

**CLI 使用視窗（提供商配額）**

- `openclaw status --usage` 和 `openclaw channels list` 顯示提供商**使用視窗**（配額快照，不是每個訊息成本）。

詳細資訊和範例參閱[令牌使用和成本](/zh-Hant/reference/token-use)。

## 如何發現金鑰

OpenClaw 可以從以下位置取得認證：

- **認證設定檔**（每個 Agent，儲存在 `auth-profiles.json`）。
- **環境變數**（例如 `OPENAI_API_KEY`、`BRAVE_API_KEY`、`FIRECRAWL_API_KEY`）。
- **設定**（`models.providers.*.apiKey`、`tools.web.search.*`、`tools.web.fetch.firecrawl.*`、`memorySearch.*`、`talk.apiKey`）。
- **Skills**（`skills.entries.<name>.apiKey`），可能將金鑰匯出到技能進程環境。

## 可以花費金鑰的功能

### 1) 核心模型回應（聊天 + 工具）

每個回應或工具呼叫都使用**當前模型提供商**（OpenAI、Anthropic 等）。這是使用和成本的主要來源。

詳見[模型](/zh-Hant/providers/models)以了解定價設定和[令牌使用和成本](/zh-Hant/reference/token-use)以了解顯示。

### 2) 媒體理解（音訊／影像／視訊）

入站媒體可在回應執行前進行總結／轉錄。這使用模型／提供商 API。

- 音訊：OpenAI／Groq／Deepgram（現在**在存在金鑰時自動啟用**）。
- 影像：OpenAI／Anthropic／Google。
- 視訊：Google。

詳見[媒體理解](/zh-Hant/nodes/media-understanding)。

### 3) 記憶嵌入 + 語義搜尋

語義記憶搜尋在為遠端提供商配置時使用**嵌入 API**：

- `memorySearch.provider = "openai"` → OpenAI 嵌入
- `memorySearch.provider = "gemini"` → Gemini 嵌入
- `memorySearch.provider = "voyage"` → Voyage 嵌入
- `memorySearch.provider = "mistral"` → Mistral 嵌入
- `memorySearch.provider = "ollama"` → Ollama 嵌入（本地／自託管；通常無託管 API 計費）
- 如果本地嵌入失敗，可選擇回落至遠端提供商

你可以使用 `memorySearch.provider = "local"` 將其保持在本地（無 API 使用）。

詳見[記憶](/zh-Hant/concepts/memory)。

### 4) Web 搜尋工具（Brave／透過 OpenRouter 的 Perplexity）

`web_search` 使用 API 金鑰，可能會產生使用費用：

- **Brave Search API**：`BRAVE_API_KEY` 或 `tools.web.search.apiKey`
- **Perplexity**（透過 OpenRouter）：`PERPLEXITY_API_KEY` 或 `OPENROUTER_API_KEY`

**Brave 免費級別（大方）：**

- **2,000 個請求／月**
- **1 個請求／秒**
- **驗證需要信用卡**（除非升級否則無費用）

詳見 [Web 工具](/zh-Hant/tools/web)。

### 5) Web 擷取工具（Firecrawl）

當存在 API 金鑰時，`web_fetch` 可以呼叫 **Firecrawl**：

- `FIRECRAWL_API_KEY` 或 `tools.web.fetch.firecrawl.apiKey`

如果未設定 Firecrawl，工具會回落至直接擷取 + 可讀性（無付費 API）。

詳見 [Web 工具](/zh-Hant/tools/web)。

### 6) 提供商使用快照（狀態／健康）

某些狀態命令呼叫**提供商使用端點**以顯示配額視窗或認證健康。這些通常是低量呼叫但仍然觸擊提供商 API：

- `openclaw status --usage`
- `openclaw models status --json`

詳見[模型 CLI](/zh-Hant/cli/models)。

### 7) 壓縮保障總結

壓縮保障可以使用**當前模型**總結工作階段歷史，在執行時呼叫提供商 API。

詳見[工作階段管理 + 壓縮](/zh-Hant/reference/session-management-compaction)。

### 8) 模型掃描／探測

`openclaw models scan` 可以探測 OpenRouter 模型，並在啟用探測時使用 `OPENROUTER_API_KEY`。

詳見[模型 CLI](/zh-Hant/cli/models)。

### 9) Talk（語音）

Talk 模式在配置時可以呼叫 **ElevenLabs**：

- `ELEVENLABS_API_KEY` 或 `talk.apiKey`

詳見 [Talk 模式](/zh-Hant/nodes/talk)。

### 10) Skills（第三方 API）

Skills 可以在 `skills.entries.<name>.apiKey` 中儲存 `apiKey`。如果技能為外部 API 使用該金鑰，可能會根據技能的提供商產生成本。

詳見 [Skills](/zh-Hant/tools/skills)。
