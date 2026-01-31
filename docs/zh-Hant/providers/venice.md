---
title: "venice(Venice AI)"
summary: "在 OpenClaw 中使用 Venice AI (隱私優先模型)"
read_when:
  - 想要在 OpenClaw 中進行重視隱私的推論時
  - 想要 Venice AI 設定指南時
---

# Venice AI (Venice 重點介紹)

**Venice** 是我們推薦的隱私優先推論設置，並提供對專有模型的匿名存取選項。

Venice AI 提供注重隱私的 AI 推論服務，支援無審查模型，並透過其匿名代理存取主要的專有模型。所有推論預設皆為私密的——不會使用您的資料進行訓練，也不會記錄日誌。

## 為何在 OpenClaw 中使用 Venice

- **私密推論**：針對開源模型（無日誌）。
- **無審查模型**：當您需要時可使用。
- **匿名存取**：針對重視品質的專有模型 (Opus/GPT/Gemini)。
- OpenAI 相容的 `/v1` 端點。

## 隱私模式

Venice 提供兩種隱私級別——了解這點對於選擇模型至關重要：

| 模式 | 描述 | 模型 |
|------|-------------|--------|
| **私密 (Private)** | 完全私密。提示/回覆**從不被儲存或記錄**。短暫存在。 | Llama, Qwen, DeepSeek, Venice Uncensored 等 |
| **匿名 (Anonymized)** | 透過 Venice 代理並剝離元數據。底層供應商 (OpenAI, Anthropic) 看到的是匿名請求。 | Claude, GPT, Gemini, Grok, Kimi, MiniMax |

## 特色

- **隱私優先**：選擇「私密」（完全私密）或「匿名」（代理）模式
- **無審查模型**：存取無內容限制的模型
- **主要模型存取**：透過 Venice 的匿名代理使用 Claude, GPT-5.2, Gemini, Grok
- **OpenAI 相容 API**：標準 `/v1` 端點，易於整合
- **串流**：✅ 所有模型皆支援
- **Function calling**：✅ 支援部分模型（請檢查模型能力）
- **視覺**：✅ 支援具備視覺能力的模型
- **無硬性速率限制**：極端使用量可能適用公平使用限流

## 設定方式

### 1. 取得 API 金鑰

1. 在 [venice.ai](https://venice.ai) 註冊
2. 前往 **Settings → API Keys → Create new key**
3. 複製您的 API 金鑰（格式：`vapi_xxxxxxxxxxxx`）

### 2. 配置 OpenClaw

**選項 A：環境變數**

```bash
export VENICE_API_KEY="vapi_xxxxxxxxxxxx"
```

**選項 B：互動式設定（推薦）**

```bash
openclaw onboard --auth-choice venice-api-key
```

這將會：
1. 提示輸入您的 API 金鑰（或使用現有的 `VENICE_API_KEY`）
2. 顯示所有可用的 Venice 模型
3. 讓您選擇預設模型
4. 自動配置供應商

**選項 C：非互動模式**

```bash
openclaw onboard --non-interactive \
  --auth-choice venice-api-key \
  --venice-api-key "vapi_xxxxxxxxxxxx"
```

### 3. 驗證設定

```bash
openclaw chat --model venice/llama-3.3-70b "Hello, are you working?"
```

## 模型選擇

設定完成後，OpenClaw 會顯示所有可用的 Venice 模型。請根據需求選擇：

- **預設（我們的選擇）**：`venice/llama-3.3-70b` 用於私密且平衡的效能。
- **最佳整體品質**：`venice/claude-opus-45` 用於困難任務（Opus 依然是最強大的）。
- **隱私**：選擇「私密」模型以進行完全私密的推論。
- **能力**：選擇「匿名」模型以透過 Venice 代理存取 Claude, GPT, Gemini。

隨時變更您的預設模型：

```bash
openclaw models set venice/claude-opus-45
openclaw models set venice/llama-3.3-70b
```

列出所有可用模型：

```bash
openclaw models list | grep venice
```

## 透過 `openclaw configure` 配置

1. 執行 `openclaw configure`
2. 選擇 **Model/auth**
3. 選擇 **Venice AI**

## 我該使用哪個模型？

| 使用情境 | 推薦模型 | 原因 |
|----------|-------------------|-----|
| **一般聊天** | `llama-3.3-70b` | 全能型，完全私密 |
| **最佳整體品質** | `claude-opus-45` | Opus 對於困難任務依然最強 |
| **隱私 + Claude 品質** | `claude-opus-45` | 透過匿名代理的最佳推理能力 |
| **程式碼編寫** | `qwen3-coder-480b-a35b-instruct` | 程式碼優化，262k 上下文 |
| **視覺任務** | `qwen3-vl-235b-a22b` | 最佳私密視覺模型 |
| **無審查** | `venice-uncensored` | 無內容限制 |
| **快速 + 便宜** | `qwen3-4b` | 輕量級，依然能幹 |
| **複雜推理** | `deepseek-v3.2` | 強大的推理能力，私密 |

## 可用模型（共 25 個）

### 私密模型 (15) — 完全私密，無日誌

| 模型 ID | 名稱 | 上下文 (Token) | 特色 |
|----------|------|------------------|----------|
| `llama-3.3-70b` | Llama 3.3 70B | 131k | 通用 |
| `llama-3.2-3b` | Llama 3.2 3B | 131k | 快速，輕量 |
| `hermes-3-llama-3.1-405b` | Hermes 3 Llama 3.1 405B | 131k | 複雜任務 |
| `qwen3-235b-a22b-thinking-2507` | Qwen3 235B Thinking | 131k | 推理 |
| `qwen3-235b-a22b-instruct-2507` | Qwen3 235B Instruct | 131k | 通用 |
| `qwen3-coder-480b-a35b-instruct` | Qwen3 Coder 480B | 262k | 程式碼 |
| `qwen3-next-80b` | Qwen3 Next 80B | 262k | 通用 |
| `qwen3-vl-235b-a22b` | Qwen3 VL 235B | 262k | 視覺 |
| `qwen3-4b` | Venice Small (Qwen3 4B) | 32k | 快速，推理 |
| `deepseek-v3.2` | DeepSeek V3.2 | 163k | 推理 |
| `venice-uncensored` | Venice Uncensored | 32k | 無審查 |
| `mistral-31-24b` | Venice Medium (Mistral) | 131k | 視覺 |
| `google-gemma-3-27b-it` | Gemma 3 27B Instruct | 202k | 視覺 |
| `openai-gpt-oss-120b` | OpenAI GPT OSS 120B | 131k | 通用 |
| `zai-org-glm-4.7` | GLM 4.7 | 202k | 推理，多語言 |

### 匿名模型 (10) — 透過 Venice 代理

| 模型 ID | 原始模型 | 上下文 (Token) | 特色 |
|----------|----------|------------------|----------|
| `claude-opus-45` | Claude Opus 4.5 | 202k | 推理，視覺 |
| `claude-sonnet-45` | Claude Sonnet 4.5 | 202k | 推理，視覺 |
| `openai-gpt-52` | GPT-5.2 | 262k | 推理 |
| `openai-gpt-52-codex` | GPT-5.2 Codex | 262k | 推理，視覺 |
| `gemini-3-pro-preview` | Gemini 3 Pro | 202k | 推理，視覺 |
| `gemini-3-flash-preview` | Gemini 3 Flash | 262k | 推理，視覺 |
| `grok-41-fast` | Grok 4.1 Fast | 262k | 推理，視覺 |
| `grok-code-fast-1` | Grok Code Fast 1 | 262k | 推理，程式碼 |
| `kimi-k2-thinking` | Kimi K2 Thinking | 262k | 推理 |
| `minimax-m21` | MiniMax M2.1 | 202k | 推理 |

## 模型探索

當設定了 `VENICE_API_KEY` 時，OpenClaw 會自動從 Venice API 探索模型。若 API 無法連線，則回退至靜態目錄。

`/models` 端點是公開的（列表無需認證），但推論需要有效的 API 金鑰。

## 串流與工具支援

| 功能 | 支援 |
|---------|---------|
| **串流 (Streaming)** | ✅ 所有模型 |
| **Function calling** | ✅ 大多數模型（檢查 API 中的 `supportsFunctionCalling`） |
| **視覺/圖片** | ✅ 標記為「視覺」功能的模型 |
| **JSON 模式** | ✅ 透過 `response_format` 支援 |

## 定價

Venice 使用信用點數系統。請查看 [venice.ai/pricing](https://venice.ai/pricing) 以獲取目前費率：

- **私密模型**：通常成本較低
- **匿名模型**：類似於直接 API 定價 + 小額 Venice 費用

## 比較：Venice vs 直接 API

| 面向 | Venice (匿名) | 直接 API |
|--------|---------------------|------------|
| **隱私** | 元數據剝離，匿名化 | 您的帳戶被連結 |
| **延遲** | +10-50ms (代理) | 直接 |
| **特色** | 支援大多數特色 | 完整特色 |
| **計費** | Venice 信用點數 | 供應商計費 |

## 使用範例

```bash
# 使用預設私密模型
openclaw chat --model venice/llama-3.3-70b

# 透過 Venice 使用 Claude（匿名）
openclaw chat --model venice/claude-opus-45

# 使用無審查模型
openclaw chat --model venice/venice-uncensored

# 使用視覺模型處理圖片
openclaw chat --model venice/qwen3-vl-235b-a22b

# 使用編碼模型
openclaw chat --model venice/qwen3-coder-480b-a35b-instruct
```

## 故障排除

### API 金鑰無法辨識

```bash
echo $VENICE_API_KEY
openclaw models list | grep venice
```

確保金鑰以 `vapi_` 開頭。

### 模型不可用

Venice 模型目錄會動態更新。執行 `openclaw models list` 查看目前可用的模型。部分模型可能暫時離線。

### 連線問題

Venice API 位於 `https://api.venice.ai/api/v1`。請確保您的網路允許 HTTPS 連線。

## 設定檔範例

```json5
{
  env: { VENICE_API_KEY: "vapi_..." },
  agents: { defaults: { model: { primary: "venice/llama-3.3-70b" } } },
  models: {
    mode: "merge",
    providers: {
      venice: {
        baseUrl: "https://api.venice.ai/api/v1",
        apiKey: "${VENICE_API_KEY}",
        api: "openai-completions",
        models: [
          {
            id: "llama-3.3-70b",
            name: "Llama 3.3 70B",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 131072,
            maxTokens: 8192
          }
        ]
      }
    }
  }
}
```

## 連結

- [Venice AI](https://venice.ai)
- [API 文件](https://docs.venice.ai)
- [定價](https://venice.ai/pricing)
- [狀態](https://status.venice.ai)
