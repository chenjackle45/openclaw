---
summary: "透過 Ollama 執行 OpenClaw（雲端與本機模型）"
read_when:
  - 你想透過 Ollama 執行 OpenClaw 的雲端或本機模型
  - 你需要 Ollama 設定與設定指南
title: "Ollama"
---

# Ollama

Ollama 是一個本機 LLM 執行時，可輕鬆在機器上執行開源模型。OpenClaw 與 Ollama 原生 API（\`/api/chat\`）整合，支援串流與工具呼叫，並可在你選擇使用 \`OLLAMA_API_KEY\`（或驗證組態檔）且未定義明確 \`models.providers.ollama\` 項目時自動探索本機 Ollama 模型。

<Warning>
**遠端 Ollama 使用者**：不要使用 OpenClaw 的 \`/v1\` OpenAI 相容 URL（\`http://host:11434/v1\`）。這會破壞工具呼叫，模型可能會輸出原始工具 JSON 作為純文字。改用原生 Ollama API URL：\`baseUrl: "http://host:11434"\`（無 \`/v1\`）。
</Warning>

## 快速開始

### 上線精靈（推薦）

設定 Ollama 最快的方式是透過上線精靈：

\`\`\`bash
openclaw onboard
\`\`\`

從提供者清單中選擇 **Ollama**。精靈將：

1. 詢問可以存取你的執行個體的 Ollama 基底 URL（預設 \`http://127.0.0.1:11434\`）。
2. 讓你選擇 **Cloud + Local**（雲端與本機模型）或 **Local**（僅本機模型）。
3. 如果你選擇 **Cloud + Local** 且未登入 ollama.com，則開啟瀏覽器登入流程。
4. 探索可用模型並建議預設值。
5. 如果選定的模型在本機上無法使用，自動拉取它。

也支援非互動式模式：

\`\`\`bash
openclaw onboard --non-interactive \\
--auth-choice ollama \\
--accept-risk
\`\`\`

選擇性地指定自訂基底 URL 或模型：

\`\`\`bash
openclaw onboard --non-interactive \\
--auth-choice ollama \\
--custom-base-url "http://ollama-host:11434" \\
--custom-model-id "qwen3.5:27b" \\
--accept-risk
\`\`\`

### 手動設定

1. 安裝 Ollama：[https://ollama.com/download](https://ollama.com/download)

2. 如果想要本機推論，請拉取本機模型：

\`\`\`bash
ollama pull glm-4.7-flash

# 或

ollama pull gpt-oss:20b

# 或

ollama pull llama3.3
\`\`\`

3. 如果你也想要雲端模型，請登入：

\`\`\`bash
ollama signin
\`\`\`

4. 執行上線並選擇 \`Ollama\`：

\`\`\`bash
openclaw onboard
\`\`\`

- \`Local\`：僅本機模型
- \`Cloud + Local\`：本機模型加雲端模型
- 雲端模型，例如 \`kimi-k2.5:cloud\`、\`minimax-m2.5:cloud\` 與 \`glm-5:cloud\`，**不**需要本機 \`ollama pull\`

OpenClaw 目前建議：

- 本機預設：\`glm-4.7-flash\`
- 雲端預設：\`kimi-k2.5:cloud\`、\`minimax-m2.5:cloud\`、\`glm-5:cloud\`

5. 如果你偏好手動設定，直接為 OpenClaw 啟用 Ollama（任何值都適用；Ollama 不需要真正的密鑰）：

\`\`\`bash

# 設定環境變數

export OLLAMA_API_KEY="ollama-local"

# 或在設定檔中設定

openclaw config set models.providers.ollama.apiKey "ollama-local"
\`\`\`

6. 檢查或切換模型：

\`\`\`bash
openclaw models list
openclaw models set ollama/glm-4.7-flash
\`\`\`

7. 或在設定中設定預設值：

\`\`\`json5
{
agents: {
defaults: {
model: { primary: "ollama/glm-4.7-flash" },
},
},
}
\`\`\`

## 模型探索（隱含提供者）

當你設定 \`OLLAMA_API_KEY\`（或驗證組態檔）且**未**定義 \`models.providers.ollama\` 時，OpenClaw 從 \`http://127.0.0.1:11434\` 的本機 Ollama 執行個體探索模型：

- 查詢 \`/api/tags\`
- 使用最佳力度 \`/api/show\` 查閱以讀取可用的 \`contextWindow\`
- 使用模型名稱啟發法（\`r1\`、\`reasoning\`、\`think\`）標記 \`reasoning\`
- 將 \`maxTokens\` 設定為 OpenClaw 使用的預設 Ollama 最大令牌上限
- 將所有成本設定為 \`0\`

這避免了手動模型項目，同時保持目錄與本機 Ollama 執行個體的對齊。

要查看可用的模型：

\`\`\`bash
ollama list
openclaw models list
\`\`\`

要新增新模型，只需用 Ollama 拉取它：

\`\`\`bash
ollama pull mistral
\`\`\`

新模型會自動被探索並可供使用。

如果你明確設定 \`models.providers.ollama\`，自動探索會被跳過，你必須手動定義模型（見下文）。

## 設定

### 基本設定（隱含探索）

啟用 Ollama 的最簡單方式是透過環境變數：

\`\`\`bash
export OLLAMA_API_KEY="ollama-local"
\`\`\`

### 明確設定（手動模型）

在以下情況使用明確設定：

- Ollama 在另一個主機/埠執行。
- 你想要強制特定的上下文視窗或模型清單。
- 你想要完全手動模型定義。

\`\`\`json5
{
models: {
providers: {
ollama: {
baseUrl: "http://ollama-host:11434",
apiKey: "ollama-local",
api: "ollama",
models: [
{
id: "gpt-oss:20b",
name: "GPT-OSS 20B",
reasoning: false,
input: ["text"],
cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
contextWindow: 8192,
maxTokens: 8192 \* 10
}
]
}
}
}
}
\`\`\`

如果設定了 \`OLLAMA_API_KEY\`，你可以在提供者項目中省略 \`apiKey\`，OpenClaw 將填充它以進行可用性檢查。

### 自訂基底 URL（明確設定）

如果 Ollama 在不同的主機或埠執行（明確設定停用自動探索，因此手動定義模型）：

\`\`\`json5
{
models: {
providers: {
ollama: {
apiKey: "ollama-local",
baseUrl: "http://ollama-host:11434", // 無 /v1 - 使用原生 Ollama API URL
api: "ollama", // 明確設定以保證原生工具呼叫行為
},
},
},
}
\`\`\`

<Warning>
不要將 \`/v1\` 新增到 URL。\`/v1\` 路徑使用 OpenAI 相容模式，其中工具呼叫不可靠。使用沒有路徑尾碼的基底 Ollama URL。
</Warning>

### 模型選擇

設定後，所有 Ollama 模型都可用：

\`\`\`json5
{
agents: {
defaults: {
model: {
primary: "ollama/gpt-oss:20b",
fallbacks: ["ollama/llama3.3", "ollama/qwen2.5-coder:32b"],
},
},
},
}
\`\`\`

## 雲端模型

雲端模型讓你執行雲端託管模型（例如 \`kimi-k2.5:cloud\`、\`minimax-m2.5:cloud\`、\`glm-5:cloud\`）與本機模型一起執行。

要使用雲端模型，在上線期間選擇 **Cloud + Local** 模式。精靈檢查你是否已登入，並在需要時開啟瀏覽器登入流程。如果驗證無法驗證，精靈會容錯轉移到本機模型預設值。

你也可以直接在 [ollama.com/signin](https://ollama.com/signin) 登入。

## 進階

### 推理模型

OpenClaw 預設將名稱例如 \`deepseek-r1\`、\`reasoning\` 或 \`think\` 的模型視為具有推理能力：

\`\`\`bash
ollama pull deepseek-r1:32b
\`\`\`

### 模型成本

Ollama 是免費的且本機執行，因此所有模型成本設定為 $0。

### 串流設定

OpenClaw 的 Ollama 整合預設使用**原生 Ollama API**（\`/api/chat\`），完全支援同時進行串流與工具呼叫。無需特殊設定。

#### 舊版 OpenAI 相容模式

<Warning>
**工具呼叫在 OpenAI 相容模式中不可靠。** 僅在需要 OpenAI 格式來用於 Proxy 且不依賴原生工具呼叫行為時使用此模式。
</Warning>

如果需要改用 OpenAI 相容端點（例如，在僅支援 OpenAI 格式的 Proxy 後面），明確設定 \`api: "openai-completions"\`：

\`\`\`json5
{
models: {
providers: {
ollama: {
baseUrl: "http://ollama-host:11434/v1",
api: "openai-completions",
injectNumCtxForOpenAICompat: true, // 預設：true
apiKey: "ollama-local",
models: [...]
}
}
}
}
\`\`\`

此模式可能不支援同時進行串流與工具呼叫。你可能需要在模型設定中用 \`params: { streaming: false }\` 停用串流。

當 \`api: "openai-completions"\` 與 Ollama 一起使用時，OpenClaw 預設注入 \`options.num_ctx\`，使 Ollama 不會無聲地容錯轉移到 4096 上下文視窗。如果你的 Proxy/上游拒絕未知的 \`options\` 欄位，停用此行為：

\`\`\`json5
{
models: {
providers: {
ollama: {
baseUrl: "http://ollama-host:11434/v1",
api: "openai-completions",
injectNumCtxForOpenAICompat: false,
apiKey: "ollama-local",
models: [...]
}
}
}
}
\`\`\`

### 上下文視窗

對於自動探索的模型，OpenClaw 使用 Ollama 報告的上下文視窗（如可用），否則容錯轉移到 OpenClaw 使用的預設 Ollama 上下文視窗。你可以在明確提供者設定中覆蓋 \`contextWindow\` 與 \`maxTokens\`。

## 疑難解除

### 未偵測到 Ollama

確保 Ollama 正在執行且你設定了 \`OLLAMA_API_KEY\`（或驗證組態檔），且你**未**定義明確的 \`models.providers.ollama\` 項目：

\`\`\`bash
ollama serve
\`\`\`

且 API 可存取：

\`\`\`bash
curl http://localhost:11434/api/tags
\`\`\`

### 沒有可用模型

如果你的模型未列出，可以：

- 本機拉取模型，或
- 在 \`models.providers.ollama\` 中明確定義模型。

要新增模型：

\`\`\`bash
ollama list # 查看已安裝的內容
ollama pull glm-4.7-flash
ollama pull gpt-oss:20b
ollama pull llama3.3 # 或另一個模型
\`\`\`

### 連線被拒絕

檢查 Ollama 在正確的埠執行：

\`\`\`bash

# 檢查 Ollama 是否執行

ps aux | grep ollama

# 或重新啟動 Ollama

ollama serve
\`\`\`

## 另見

- [Model Providers](/zh-Hant/concepts/model-providers) - 所有提供者的概覽
- [Model Selection](/zh-Hant/concepts/models) - 如何選擇模型
- [Configuration](/zh-Hant/gateway/configuration) - 完整設定參考
