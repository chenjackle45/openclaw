---
title: "Model providers(模型供應商)"
summary: "模型供應商概覽與設定範例 + CLI 流程"
read_when:
  - 您需要逐個供應商的模型設定參考
  - 您想要了解模型供應商的設定範例或 CLI 引導命令
---
# Model providers（模型供應商）

本頁面涵蓋 **LLM/模型供應商**（不是像 WhatsApp/Telegram 這樣的聊天頻道）。
有關模型選擇規則，請參閱 [/concepts/models](/concepts/models)。

## 快速規則

- 模型引用使用 `provider/model` 格式（範例：`opencode/claude-opus-4-5`）。
- 如果您設定了 `agents.defaults.models`，它將成為允許清單 (allowlist)。
- CLI 輔助工具：`openclaw onboard`、`openclaw models list`、`openclaw models set <provider/model>`。

## 內建供應商 (pi-ai 目錄)

OpenClaw 內建了 pi‑ai 目錄。這些供應商**不需要**設定 `models.providers`；只需設定認證並挑選模型即可。

### OpenAI

- 供應商：`openai`
- 認證：`OPENAI_API_KEY`
- 範例模型：`openai/gpt-5.2`
- CLI：`openclaw onboard --auth-choice openai-api-key`

```json5
{
  agents: { defaults: { model: { primary: "openai/gpt-5.2" } } }
}
```

### Anthropic

- 供應商：`anthropic`
- 認證：`ANTHROPIC_API_KEY` 或 `claude setup-token`
- 範例模型：`anthropic/claude-opus-4-5`
- CLI：`openclaw onboard --auth-choice token`（貼上 setup-token）或 `openclaw models auth paste-token --provider anthropic`

```json5
{
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-5" } } }
}
```

### OpenAI Code (Codex)

- 供應商：`openai-codex`
- 認證：OAuth (ChatGPT)
- 範例模型：`openai-codex/gpt-5.2`
- CLI：`openclaw onboard --auth-choice openai-codex` 或 `openclaw models auth login --provider openai-codex`

```json5
{
  agents: { defaults: { model: { primary: "openai-codex/gpt-5.2" } } }
}
```

### OpenCode Zen

- 供應商：`opencode`
- 認證：`OPENCODE_API_KEY`（或 `OPENCODE_ZEN_API_KEY`）
- 範例模型：`opencode/claude-opus-4-5`
- CLI：`openclaw onboard --auth-choice opencode-zen`

```json5
{
  agents: { defaults: { model: { primary: "opencode/claude-opus-4-5" } } }
}
```

### Google Gemini (API key)

- 供應商：`google`
- 認證：`GEMINI_API_KEY`
- 範例模型：`google/gemini-3-pro-preview`
- CLI：`openclaw onboard --auth-choice gemini-api-key`

### Google Vertex / Antigravity / Gemini CLI

- 供應商：`google-vertex`、`google-antigravity`、`google-gemini-cli`
- 認證：Vertex 使用 gcloud ADC；Antigravity/Gemini CLI 使用各自的認證流程
- Antigravity OAuth 以綁定外掛形式提供 (`google-antigravity-auth`)。
  - 啟用：`openclaw plugins enable google-antigravity-auth`
  - 登入：`openclaw models auth login --provider google-antigravity --set-default`
- Gemini CLI OAuth 以綁定外掛形式提供 (`google-gemini-cli-auth`)。
  - 啟用：`openclaw plugins enable google-gemini-cli-auth`
  - 登入：`openclaw models auth login --provider google-gemini-cli --set-default`

### Z.AI (GLM)

- 供應商：`zai`
- 認證：`ZAI_API_KEY`
- 範例模型：`zai/glm-4.7`
- CLI：`openclaw onboard --auth-choice zai-api-key`

### Vercel AI Gateway

- 供應商：`vercel-ai-gateway`
- 認證：`AI_GATEWAY_API_KEY`
- 範例模型：`vercel-ai-gateway/anthropic/claude-opus-4.5`
- CLI：`openclaw onboard --auth-choice ai-gateway-api-key`

## 其他內建供應商

- OpenRouter：`openrouter` (`OPENROUTER_API_KEY`)
- xAI：`xai` (`XAI_API_KEY`)
- Groq：`groq` (`GROQ_API_KEY`)
- Cerebras：`cerebras` (`CEREBRAS_API_KEY`)
- Mistral：`mistral` (`MISTRAL_API_KEY`)
- GitHub Copilot：`github-copilot` (`COPILOT_GITHUB_TOKEN`)

## 透過 `models.providers` 的供應商（自訂/基礎 URL）

使用 `models.providers`（或 `models.json`）新增**自訂**供應商或相容 OpenAI/Anthropic 的代理。

### Moonshot AI (Kimi)

Moonshot 使用相容 OpenAI 的端點：

- 供應商：`moonshot`
- 認證：`MOONSHOT_API_KEY`
- 範例模型：`moonshot/kimi-k2.5`

```json5
{
  agents: {
    defaults: { model: { primary: "moonshot/kimi-k2.5" } }
  },
  models: {
    mode: "merge",
    providers: {
      moonshot: {
        baseUrl: "https://api.moonshot.ai/v1",
        apiKey: "${MOONSHOT_API_KEY}",
        api: "openai-completions",
        models: [{ id: "kimi-k2.5", name: "Kimi K2.5" }]
      }
    }
  }
}
```

### Kimi Code

Kimi Code 使用專用的端點和金鑰：

- 供應商：`kimi-code`
- 認證：`KIMICODE_API_KEY`
- 範例模型：`kimi-code/kimi-for-coding`

### Qwen OAuth（免費層級）

Qwen 透過裝置代碼流程提供對 Qwen Coder + Vision 的 OAuth 存取。啟用外掛後登入：

```bash
openclaw plugins enable qwen-portal-auth
openclaw models auth login --provider qwen-portal --set-default
```

### Synthetic

Synthetic 提供相容 Anthropic 的模型：

- 供應商：`synthetic`
- 認證：`SYNTHETIC_API_KEY`
- 範例模型：`synthetic/hf:MiniMaxAI/MiniMax-M2.1`

### MiniMax

MiniMax 需要自訂端點：

- 供應商：`minimax`
- 認證：`MINIMAX_API_KEY`

詳情請參閱 [/providers/minimax](/providers/minimax)。

### Ollama

Ollama 是本地執行環境：

- 供應商：`ollama`
- 認證：無（本地伺服器）
- 範例模型：`ollama/llama3.3`

### 本地代理 (LM Studio, vLLM, LiteLLM 等)

範例（相容 OpenAI）：

```json5
{
  agents: {
    defaults: {
      model: { primary: "lmstudio/minimax-m2.1-gs32" }
    }
  },
  models: {
    providers: {
      lmstudio: {
        baseUrl: "http://localhost:1234/v1",
        apiKey: "LMSTUDIO_KEY",
        api: "openai-completions",
        models: [
          {
            id: "minimax-m2.1-gs32",
            name: "MiniMax M2.1",
            contextWindow: 200000,
            maxTokens: 8192
          }
        ]
      }
    }
  }
}
```

## CLI 範例

```bash
openclaw onboard --auth-choice opencode-zen
openclaw models set opencode/claude-opus-4-5
openclaw models list
```

另請參閱：[/gateway/configuration](/gateway/configuration) 以獲取完整配置範例。
