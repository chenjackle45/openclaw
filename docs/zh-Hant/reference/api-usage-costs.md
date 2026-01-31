---
title: "Api usage costs(API 使用與成本)"
summary: "稽核什麼可以花費金錢、使用哪些 Keys，以及如何查看使用量"
read_when:
  - 您想了解哪些功能可能呼叫付費 APIs
  - 您需要稽核 Keys、成本和使用量可見性
  - 您正在說明 /status 或 /usage 成本報告
---
# API 使用與成本

本文件列出**可以呼叫 API Keys 的功能**以及其成本顯示的位置。它專注於可以產生 Provider 使用量或付費 API 呼叫的 OpenClaw 功能。

## 成本顯示位置（Chat + CLI）

**Per-session 成本快照**
- `/status` 顯示目前 Session Model、Context 使用量和最後回應 Tokens。
- 如果 Model 使用**API-key Auth**，`/status` 也會顯示最後回覆的**預估成本**。

**Per-message 成本頁尾**
- `/usage full` 在每個回覆附加 Usage 頁尾，包括**預估成本**（僅限 API-key）。
- `/usage tokens` 僅顯示 Tokens；OAuth 流程隱藏美元成本。

**CLI 使用量視窗（Provider Quotas）**
- `openclaw status --usage` 和 `openclaw channels list` 顯示 Provider **Usage Windows**（Quota 快照，非 Per-message 成本）。

請見 [Token use & costs](/zh-Hant/token-use) 了解詳情和範例。

## 如何探索 Keys

OpenClaw 可以從以下取得憑證：
- **Auth Profiles**（Per-agent，儲存在 `auth-profiles.json`）。
- **環境變數**（例如 `OPENAI_API_KEY`、`BRAVE_API_KEY`、`FIRECRAWL_API_KEY`）。
- **Config**（`models.providers.*.apiKey`、`tools.web.search.*`、`tools.web.fetch.firecrawl.*`、`memorySearch.*`、`talk.apiKey`）。
- **Skills**（`skills.entries.<name>.apiKey`）可能將 Keys 匯出到 Skill Process Env。

## 可能花費 Keys 的功能

### 1) 核心 Model 回應（Chat + Tools）
每個回覆或 Tool Call 使用**目前的 Model Provider**（OpenAI、Anthropic 等）。這是使用量和成本的主要來源。

請見 [Models](/zh-Hant/providers/models) 了解定價 Config 和 [Token use & costs](/zh-Hant/token-use) 了解顯示。

### 2) 媒體理解（Audio/Image/Video）
Inbound 媒體可以在回覆執行前被摘要/轉錄。這使用 Model/Provider APIs。

- Audio：OpenAI / Groq / Deepgram（現在當 Keys 存在時**自動啟用**）。
- Image：OpenAI / Anthropic / Google。
- Video：Google。

請見 [Media understanding](/zh-Hant/nodes/media-understanding)。

### 3) Memory Embeddings + Semantic Search
Semantic Memory Search 在設定為 Remote Providers 時使用**Embedding APIs**：
- `memorySearch.provider = "openai"` → OpenAI Embeddings
- `memorySearch.provider = "gemini"` → Gemini Embeddings
- 如果 Local Embeddings 失敗，選用 Fallback 到 OpenAI

您可以使用 `memorySearch.provider = "local"` 保持在本機（無 API 使用量）。

請見 [Memory](/zh-Hant/concepts/memory)。

### 4) Web Search Tool（Brave / Perplexity via OpenRouter）
`web_search` 使用 API Keys 並可能產生使用費用：

- **Brave Search API**：`BRAVE_API_KEY` 或 `tools.web.search.apiKey`
- **Perplexity**（via OpenRouter）：`PERPLEXITY_API_KEY` 或 `OPENROUTER_API_KEY`

**Brave 免費方案（慷慨）：**
- **每月 2,000 次請求**
- **每秒 1 次請求**
- **需要信用卡**驗證（除非升級否則不收費）

請見 [Web tools](/zh-Hant/tools/web)。

### 5) Web Fetch Tool（Firecrawl）
`web_fetch` 當有 API Key 時可以呼叫 **Firecrawl**：
- `FIRECRAWL_API_KEY` 或 `tools.web.fetch.firecrawl.apiKey`

如果未設定 Firecrawl，Tool 會回退到 Direct Fetch + Readability（無付費 API）。

請見 [Web tools](/zh-Hant/tools/web)。

### 6) Provider 使用量快照（Status/Health）
部分狀態指令會呼叫 **Provider 使用量端點**以顯示 Quota Windows 或 Auth 健康狀況。這些通常是低量呼叫但仍會呼叫 Provider APIs：
- `openclaw status --usage`
- `openclaw models status --json`

請見 [Models CLI](/zh-Hant/cli/models)。

### 7) Compaction Safeguard 摘要
Compaction Safeguard 可以使用**目前的 Model** 摘要 Session 歷史，這會在執行時呼叫 Provider APIs。

請見 [Session management + compaction](/zh-Hant/reference/session-management-compaction)。

### 8) Model Scan / Probe
`openclaw models scan` 可以 Probe OpenRouter Models，並在啟用 Probing 時使用 `OPENROUTER_API_KEY`。

請見 [Models CLI](/zh-Hant/cli/models)。

### 9) Talk（Speech）
Talk Mode 在設定時可以呼叫 **ElevenLabs**：
- `ELEVENLABS_API_KEY` 或 `talk.apiKey`

請見 [Talk mode](/zh-Hant/nodes/talk)。

### 10) Skills（Third-party APIs）
Skills 可以在 `skills.entries.<name>.apiKey` 中儲存 `apiKey`。如果 Skill 使用該 Key 呼叫外部 APIs，它會根據 Skill 的 Provider 產生成本。

請見 [Skills](/zh-Hant/tools/skills)。
