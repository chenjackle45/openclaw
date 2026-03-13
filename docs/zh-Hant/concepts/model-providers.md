---
title: "Model Providers（模型提供商）"
summary: "模型提供商概覽與組態範例 + CLI 流程"
read_when:
  - 您需要逐個提供商的模型組態參考
  - 您想要模型提供商的組態範例或 CLI 引導指令
---

# Model providers（模型提供商）

此頁面涵蓋 **LLM/模型提供商**（非 WhatsApp/Telegram 等聊天頻道）。
如需模型選擇規則，見 [/concepts/models](/zh-Hant/concepts/models)。

## 快速規則

- 模型參考使用 `provider/model`（例：`opencode/claude-opus-4-6`）。
- 若你設定了 `agents.defaults.models`，它會成為 allowlist。
- CLI 助手：`openclaw onboard`、`openclaw models list`、`openclaw models set <provider/model>`。

## API key 輪換

- 支援部分供應商的通用 provider 輪換。
- 透過以下方式設定多個 key：
  - `OPENCLAW_LIVE_<PROVIDER>_KEY`（單一即時覆蓋，最高優先級）
  - `<PROVIDER>_API_KEYS`（逗號或分號分隔的列表）
  - `<PROVIDER>_API_KEY`（主要 key）
  - `<PROVIDER>_API_KEY_*`（編號列表，例如 `<PROVIDER>_API_KEY_1`）
- 對於 Google 供應商，`GOOGLE_API_KEY` 也作為備用。
- Key 選擇順序保留優先級並去除重複值。
- 請求僅在遭遇速率限制回應時（例如 `429`、`rate_limit`、`quota`、`resource exhausted`）使用下一個 key 重試。
- 非速率限制的失敗會立即失敗，不嘗試 key 輪換。
- 當所有候選 key 都失敗時，返回最後一次嘗試的最終錯誤。

## 內建供應商（pi-ai catalog）

OpenClaw 內建 pi-ai catalog。這些供應商**不需要**
`models.providers` 設定；只需設定驗證並選擇模型即可。

### OpenAI

- 供應商：`openai`
- 驗證：`OPENAI_API_KEY`
- 選用輪換：`OPENAI_API_KEYS`、`OPENAI_API_KEY_1`、`OPENAI_API_KEY_2`，以及 `OPENCLAW_LIVE_OPENAI_KEY`（單一覆蓋）
- 範例模型：`openai/gpt-5.4`、`openai/gpt-5.4-pro`
- CLI：`openclaw onboard --auth-choice openai-api-key`
- 預設傳輸方式為 `auto`（WebSocket 優先，SSE 備用）
- 透過 `agents.defaults.models["openai/<model>"].params.transport` 按模型覆蓋（`"sse"`、`"websocket"` 或 `"auto"`）
- OpenAI Responses WebSocket 暖機預設透過 `params.openaiWsWarmup` 啟用（`true`/`false`）
- 可透過 `agents.defaults.models["openai/<model>"].params.serviceTier` 啟用 OpenAI 優先處理

```json5
{
  agents: { defaults: { model: { primary: "openai/gpt-5.4" } } },
}
```

### Anthropic

- 供應商：`anthropic`
- 驗證：`ANTHROPIC_API_KEY` 或 `claude setup-token`
- 選用輪換：`ANTHROPIC_API_KEYS`、`ANTHROPIC_API_KEY_1`、`ANTHROPIC_API_KEY_2`，以及 `OPENCLAW_LIVE_ANTHROPIC_KEY`（單一覆蓋）
- 範例模型：`anthropic/claude-opus-4-6`
- CLI：`openclaw onboard --auth-choice token`（貼上 setup-token）或 `openclaw models auth paste-token --provider anthropic`
- 政策說明：setup-token 支援屬於技術相容性；Anthropic 過去曾封鎖部分在 Claude Code 以外的訂閱使用。請確認當前 Anthropic 條款並根據您的風險承受度決定。
- 建議：Anthropic API key 驗證是比訂閱 setup-token 驗證更安全的推薦方式。

```json5
{
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } },
}
```

### OpenAI Code（Codex）

- 供應商：`openai-codex`
- 驗證：OAuth（ChatGPT）
- 範例模型：`openai-codex/gpt-5.4`
- CLI：`openclaw onboard --auth-choice openai-codex` 或 `openclaw models auth login --provider openai-codex`
- 預設傳輸方式為 `auto`（WebSocket 優先，SSE 備用）
- 透過 `agents.defaults.models["openai-codex/<model>"].params.transport` 按模型覆蓋（`"sse"`、`"websocket"` 或 `"auto"`）
- 政策說明：OpenAI Codex OAuth 明確支援 OpenClaw 等外部工具/工作流程。

```json5
{
  agents: { defaults: { model: { primary: "openai-codex/gpt-5.4" } } },
}
```

### OpenCode Zen

- 供應商：`opencode`
- 驗證：`OPENCODE_API_KEY`（或 `OPENCODE_ZEN_API_KEY`）
- 範例模型：`opencode/claude-opus-4-6`
- CLI：`openclaw onboard --auth-choice opencode-zen`

```json5
{
  agents: { defaults: { model: { primary: "opencode/claude-opus-4-6" } } },
}
```

### Google Gemini（API key）

- 供應商：`google`
- 驗證：`GEMINI_API_KEY`
- 選用輪換：`GEMINI_API_KEYS`、`GEMINI_API_KEY_1`、`GEMINI_API_KEY_2`、`GOOGLE_API_KEY` 備用，以及 `OPENCLAW_LIVE_GEMINI_KEY`（單一覆蓋）
- 範例模型：`google/gemini-3.1-pro-preview`、`google/gemini-3-flash-preview`、`google/gemini-3.1-flash-lite-preview`
- 相容性：舊版 OpenClaw 設定中使用 `google/gemini-3.1-flash-preview` 會正規化為 `google/gemini-3-flash-preview`，裸用 `google/gemini-3.1-flash-lite` 會正規化為 `google/gemini-3.1-flash-lite-preview`
- CLI：`openclaw onboard --auth-choice gemini-api-key`

### Google Vertex、Antigravity 和 Gemini CLI

- 供應商：`google-vertex`、`google-antigravity`、`google-gemini-cli`
- 驗證：Vertex 使用 gcloud ADC；Antigravity/Gemini CLI 使用各自的驗證流程
- 注意：OpenClaw 中的 Antigravity 和 Gemini CLI OAuth 是非官方整合。部分用戶回報使用第三方客戶端後遭到 Google 帳號限制。請審查 Google 條款，若選擇繼續請使用非重要帳號。
- Antigravity OAuth 以捆綁外掛程式形式發布（`google-antigravity-auth`，預設停用）。
  - 啟用：`openclaw plugins enable google-antigravity-auth`
  - 登入：`openclaw models auth login --provider google-antigravity --set-default`
- Gemini CLI OAuth 以捆綁外掛程式形式發布（`google-gemini-cli-auth`，預設停用）。
  - 啟用：`openclaw plugins enable google-gemini-cli-auth`
  - 登入：`openclaw models auth login --provider google-gemini-cli --set-default`
  - 注意：**不**需要將 client id 或 secret 貼入 `openclaw.json`。CLI 登入流程會將 token 儲存在 Gateway 主機的驗證設定檔中。

### Z.AI（GLM）

- 供應商：`zai`
- 驗證：`ZAI_API_KEY`
- 範例模型：`zai/glm-5`
- CLI：`openclaw onboard --auth-choice zai-api-key`
  - 別名：`z.ai/*` 和 `z-ai/*` 會正規化為 `zai/*`

### Vercel AI Gateway

- 供應商：`vercel-ai-gateway`
- 驗證：`AI_GATEWAY_API_KEY`
- 範例模型：`vercel-ai-gateway/anthropic/claude-opus-4.6`
- CLI：`openclaw onboard --auth-choice ai-gateway-api-key`

### Kilo Gateway

- 供應商：`kilocode`
- 驗證：`KILOCODE_API_KEY`
- 範例模型：`kilocode/anthropic/claude-opus-4.6`
- CLI：`openclaw onboard --kilocode-api-key <key>`
- Base URL：`https://api.kilo.ai/api/gateway/`
- 擴展的內建 catalog 包含 GLM-5 Free、MiniMax M2.5 Free、GPT-5.2、Gemini 3 Pro Preview、Gemini 3 Flash Preview、Grok Code Fast 1 和 Kimi K2.5。

詳見 [/providers/kilocode](/zh-Hant/providers/kilocode)。

### 其他內建供應商

- OpenRouter：`openrouter`（`OPENROUTER_API_KEY`）
- 範例模型：`openrouter/anthropic/claude-sonnet-4-5`
- Kilo Gateway：`kilocode`（`KILOCODE_API_KEY`）
- 範例模型：`kilocode/anthropic/claude-opus-4.6`
- xAI：`xai`（`XAI_API_KEY`）
- Mistral：`mistral`（`MISTRAL_API_KEY`）
- 範例模型：`mistral/mistral-large-latest`
- CLI：`openclaw onboard --auth-choice mistral-api-key`
- Groq：`groq`（`GROQ_API_KEY`）
- Cerebras：`cerebras`（`CEREBRAS_API_KEY`）
  - Cerebras 上的 GLM 模型使用 id `zai-glm-4.7` 和 `zai-glm-4.6`。
  - OpenAI 相容 base URL：`https://api.cerebras.ai/v1`。
- GitHub Copilot：`github-copilot`（`COPILOT_GITHUB_TOKEN` / `GH_TOKEN` / `GITHUB_TOKEN`）
- Hugging Face Inference：`huggingface`（`HUGGINGFACE_HUB_TOKEN` 或 `HF_TOKEN`）— OpenAI 相容路由器；範例模型：`huggingface/deepseek-ai/DeepSeek-R1`；CLI：`openclaw onboard --auth-choice huggingface-api-key`。見 [Hugging Face (Inference)](/zh-Hant/providers/huggingface)。

## 透過 `models.providers` 設定供應商（自訂/base URL）

使用 `models.providers`（或 `models.json`）新增**自訂**供應商或
OpenAI/Anthropic 相容代理。

### Moonshot AI（Kimi）

Moonshot 使用 OpenAI 相容端點，因此將其設定為自訂供應商：

- 供應商：`moonshot`
- 驗證：`MOONSHOT_API_KEY`
- 範例模型：`moonshot/kimi-k2.5`

Kimi K2 模型 ID：

<!-- markdownlint-disable MD037 -->

{/_ moonshot-kimi-k2-model-refs:start _/ && null}

<!-- markdownlint-enable MD037 -->

- `moonshot/kimi-k2.5`
- `moonshot/kimi-k2-0905-preview`
- `moonshot/kimi-k2-turbo-preview`
- `moonshot/kimi-k2-thinking`
- `moonshot/kimi-k2-thinking-turbo`
  <!-- markdownlint-disable MD037 -->
  {/_ moonshot-kimi-k2-model-refs:end _/ && null}
  <!-- markdownlint-enable MD037 -->

```json5
{
  agents: {
    defaults: { model: { primary: "moonshot/kimi-k2.5" } },
  },
  models: {
    mode: "merge",
    providers: {
      moonshot: {
        baseUrl: "https://api.moonshot.ai/v1",
        apiKey: "${MOONSHOT_API_KEY}",
        api: "openai-completions",
        models: [{ id: "kimi-k2.5", name: "Kimi K2.5" }],
      },
    },
  },
}
```

### Kimi Coding

Kimi Coding 使用 Moonshot AI 的 Anthropic 相容端點：

- 供應商：`kimi-coding`
- 驗證：`KIMI_API_KEY`
- 範例模型：`kimi-coding/k2p5`

```json5
{
  env: { KIMI_API_KEY: "sk-..." },
  agents: {
    defaults: { model: { primary: "kimi-coding/k2p5" } },
  },
}
```

### Qwen OAuth（免費方案）

Qwen 透過 device-code 流程提供對 Qwen Coder + Vision 的 OAuth 存取。
啟用捆綁外掛程式後登入：

```bash
openclaw plugins enable qwen-portal-auth
openclaw models auth login --provider qwen-portal --set-default
```

模型參考：

- `qwen-portal/coder-model`
- `qwen-portal/vision-model`

詳見 [/providers/qwen](/zh-Hant/providers/qwen)。

### Volcano Engine（Doubao）

Volcano Engine（火山引擎）在中國提供對 Doubao 和其他模型的存取。

- 供應商：`volcengine`（coding：`volcengine-plan`）
- 驗證：`VOLCANO_ENGINE_API_KEY`
- 範例模型：`volcengine/doubao-seed-1-8-251228`
- CLI：`openclaw onboard --auth-choice volcengine-api-key`

```json5
{
  agents: {
    defaults: { model: { primary: "volcengine/doubao-seed-1-8-251228" } },
  },
}
```

可用模型：

- `volcengine/doubao-seed-1-8-251228`（Doubao Seed 1.8）
- `volcengine/doubao-seed-code-preview-251028`
- `volcengine/kimi-k2-5-260127`（Kimi K2.5）
- `volcengine/glm-4-7-251222`（GLM 4.7）
- `volcengine/deepseek-v3-2-251201`（DeepSeek V3.2 128K）

Coding 模型（`volcengine-plan`）：

- `volcengine-plan/ark-code-latest`
- `volcengine-plan/doubao-seed-code`
- `volcengine-plan/kimi-k2.5`
- `volcengine-plan/kimi-k2-thinking`
- `volcengine-plan/glm-4.7`

### BytePlus（國際版）

BytePlus ARK 為國際用戶提供與 Volcano Engine 相同模型的存取。

- 供應商：`byteplus`（coding：`byteplus-plan`）
- 驗證：`BYTEPLUS_API_KEY`
- 範例模型：`byteplus/seed-1-8-251228`
- CLI：`openclaw onboard --auth-choice byteplus-api-key`

```json5
{
  agents: {
    defaults: { model: { primary: "byteplus/seed-1-8-251228" } },
  },
}
```

可用模型：

- `byteplus/seed-1-8-251228`（Seed 1.8）
- `byteplus/kimi-k2-5-260127`（Kimi K2.5）
- `byteplus/glm-4-7-251222`（GLM 4.7）

Coding 模型（`byteplus-plan`）：

- `byteplus-plan/ark-code-latest`
- `byteplus-plan/doubao-seed-code`
- `byteplus-plan/kimi-k2.5`
- `byteplus-plan/kimi-k2-thinking`
- `byteplus-plan/glm-4.7`

### Synthetic

Synthetic 在 `synthetic` 供應商後提供 Anthropic 相容模型：

- 供應商：`synthetic`
- 驗證：`SYNTHETIC_API_KEY`
- 範例模型：`synthetic/hf:MiniMaxAI/MiniMax-M2.5`
- CLI：`openclaw onboard --auth-choice synthetic-api-key`

```json5
{
  agents: {
    defaults: { model: { primary: "synthetic/hf:MiniMaxAI/MiniMax-M2.5" } },
  },
  models: {
    mode: "merge",
    providers: {
      synthetic: {
        baseUrl: "https://api.synthetic.new/anthropic",
        apiKey: "${SYNTHETIC_API_KEY}",
        api: "anthropic-messages",
        models: [{ id: "hf:MiniMaxAI/MiniMax-M2.5", name: "MiniMax M2.5" }],
      },
    },
  },
}
```

### MiniMax

MiniMax 透過 `models.providers` 設定，因為它使用自訂端點：

- MiniMax（Anthropic 相容）：`--auth-choice minimax-api`
- 驗證：`MINIMAX_API_KEY`

詳見 [/providers/minimax](/zh-Hant/providers/minimax)。

### Ollama

Ollama 是提供 OpenAI 相容 API 的本地 LLM 執行時：

- 供應商：`ollama`
- 驗證：不需要（本地伺服器）
- 範例模型：`ollama/llama3.3`
- 安裝：[https://ollama.ai](https://ollama.ai)

```bash
# 安裝 Ollama 後拉取模型：
ollama pull llama3.3
```

```json5
{
  agents: {
    defaults: { model: { primary: "ollama/llama3.3" } },
  },
}
```

Ollama 在本地 `http://127.0.0.1:11434/v1` 執行時自動偵測。詳見 [/providers/ollama](/zh-Hant/providers/ollama)。

### vLLM

vLLM 是本地（或自架）的 OpenAI 相容伺服器：

- 供應商：`vllm`
- 驗證：選用（取決於你的伺服器）
- 預設 base URL：`http://127.0.0.1:8000/v1`

在本地選擇自動探索（若伺服器不強制驗證，任何值均可）：

```bash
export VLLM_API_KEY="vllm-local"
```

然後設定模型（以 `/v1/models` 回傳的 ID 之一替換）：

```json5
{
  agents: {
    defaults: { model: { primary: "vllm/your-model-id" } },
  },
}
```

詳見 [/providers/vllm](/zh-Hant/providers/vllm)。

### 本地代理（LM Studio、vLLM、LiteLLM 等）

範例（OpenAI 相容）：

```json5
{
  agents: {
    defaults: {
      model: { primary: "lmstudio/minimax-m2.5-gs32" },
      models: { "lmstudio/minimax-m2.5-gs32": { alias: "Minimax" } },
    },
  },
  models: {
    providers: {
      lmstudio: {
        baseUrl: "http://localhost:1234/v1",
        apiKey: "LMSTUDIO_KEY",
        api: "openai-completions",
        models: [
          {
            id: "minimax-m2.5-gs32",
            name: "MiniMax M2.5",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 200000,
            maxTokens: 8192,
          },
        ],
      },
    },
  },
}
```

注意：

- 對於自訂供應商，`reasoning`、`input`、`cost`、`contextWindow` 和 `maxTokens` 為選用。
  省略時，OpenClaw 預設值為：
  - `reasoning: false`
  - `input: ["text"]`
  - `cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }`
  - `contextWindow: 200000`
  - `maxTokens: 8192`
- 建議：設定與代理/模型限制相符的明確值。
- 對於非原生端點（任何 `baseUrl` 主機不是 `api.openai.com`）上的 `api: "openai-completions"`，OpenClaw 強制 `compat.supportsDeveloperRole: false` 以避免供應商對不支援的 `developer` 角色回傳 400 錯誤。
- 若 `baseUrl` 為空/省略，OpenClaw 保持預設 OpenAI 行為（解析為 `api.openai.com`）。
- 為安全起見，在非原生 `openai-completions` 端點上，明確的 `compat.supportsDeveloperRole: true` 仍然被覆蓋。

## CLI 範例

```bash
openclaw onboard --auth-choice opencode-zen
openclaw models set opencode/claude-opus-4-6
openclaw models list
```

另見：[/gateway/configuration](/zh-Hant/gateway/configuration) 以獲取完整設定範例。
