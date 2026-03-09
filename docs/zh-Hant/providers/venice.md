---
summary: "在 OpenClaw 中使用 Venice AI 隱私優先模型"
read_when:
  - 你想在 OpenClaw 中進行隱私優先推論
  - 你需要 Venice AI 設定指南
title: "Venice AI"
---

# Venice AI (Venice highlight)

**Venice** 是我們重點推薦的 Venice 設定，用於隱私優先推論，可選擇性地匿名存取專有模型。

Venice AI 提供隱私優先的 AI 推論，支援未審查模型，並透過其匿名代理存取主要的專有模型。所有推論預設為私密——不使用你的資料進行訓練，不記錄日誌。

## 為什麼在 OpenClaw 中使用 Venice

- 開源模型的**私密推論**（無日誌）。
- 需要時的**未審查模型**。
- 在品質重要時**匿名存取**專有模型（Opus/GPT/Gemini）。
- OpenAI 相容的 `/v1` 端點。

## 隱私模式

Venice 提供兩個隱私級別——理解這點是選擇模型的關鍵：

| 模式           | 描述                                                                                       | 模型                                                         |
| -------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------ |
| **Private**    | 完全私密。提示/回應**永不儲存或記錄**。暫時性。                                            | Llama、Qwen、DeepSeek、Kimi、MiniMax、Venice Uncensored 等。 |
| **Anonymized** | 透過 Venice 代理，元資料已去除。底層提供者（OpenAI、Anthropic、Google、xAI）看到匿名請求。 | Claude、GPT、Gemini、Grok                                    |

## 功能

- **隱私優先**：在「private」（完全私密）和「anonymized」（代理）模式之間選擇
- **未審查模型**：存取無內容限制的模型
- **主要模型存取**：透過 Venice 的匿名代理使用 Claude、GPT、Gemini 和 Grok
- **OpenAI 相容 API**：標準 `/v1` 端點，易於整合
- **串流**：✅ 所有模型均支援
- **函式呼叫**：✅ 部分模型支援（查看模型功能）
- **視覺**：✅ 具有視覺功能的模型支援
- **無硬性速率限制**：極端使用可能適用公平使用節流

## 設定

### 1. 取得 API 金鑰

1. 在 [venice.ai](https://venice.ai) 註冊
2. 前往 **Settings → API Keys → Create new key**
3. 複製你的 API 金鑰（格式：`vapi_xxxxxxxxxxxx`）

### 2. 設定 OpenClaw

**選項 A：環境變數**

```bash
export VENICE_API_KEY="vapi_xxxxxxxxxxxx"
```

**選項 B：互動式設定（推薦）**

```bash
openclaw onboard --auth-choice venice-api-key
```

這將：

1. 提示輸入你的 API 金鑰（或使用現有的 `VENICE_API_KEY`）
2. 顯示所有可用的 Venice 模型
3. 讓你選擇預設模型
4. 自動設定提供者

**選項 C：非互動式**

```bash
openclaw onboard --non-interactive \
  --auth-choice venice-api-key \
  --venice-api-key "vapi_xxxxxxxxxxxx"
```

### 3. 驗證設定

```bash
openclaw agent --model venice/kimi-k2-5 --message "Hello, are you working?"
```

## 模型選擇

設定後，OpenClaw 顯示所有可用的 Venice 模型。根據你的需求選擇：

- **預設模型**：`venice/kimi-k2-5` 用於強大的私密推論加視覺。
- **高能力選項**：`venice/claude-opus-4-6` 用於最強的匿名 Venice 路徑。
- **隱私**：選擇「private」模型進行完全私密推論。
- **能力**：選擇「anonymized」模型透過 Venice 的代理存取 Claude、GPT、Gemini。

隨時變更你的預設模型：

```bash
openclaw models set venice/kimi-k2-5
openclaw models set venice/claude-opus-4-6
```

列出所有可用模型：

```bash
openclaw models list | grep venice
```

## 透過 `openclaw configure` 設定

1. 執行 `openclaw configure`
2. 選擇 **Model/auth**
3. 選擇 **Venice AI**

## 我應該使用哪個模型？

| 使用案例             | 推薦模型                         | 原因                              |
| -------------------- | -------------------------------- | --------------------------------- |
| **一般聊天（預設）** | `kimi-k2-5`                      | 強大的私密推論加視覺              |
| **最佳整體品質**     | `claude-opus-4-6`                | 最強的匿名 Venice 選項            |
| **隱私 + 程式碼**    | `qwen3-coder-480b-a35b-instruct` | 具有大型 context 的私密程式碼模型 |
| **私密視覺**         | `kimi-k2-5`                      | 視覺支援，不離開私密模式          |
| **快速 + 便宜**      | `qwen3-4b`                       | 輕量推論模型                      |
| **複雜私密任務**     | `deepseek-v3.2`                  | 強大推論，但無 Venice 工具支援    |
| **未審查**           | `venice-uncensored`              | 無內容限制                        |

## 可用模型（共 41 個）

### Private 模型（26 個）— 完全私密，無日誌

| 模型 ID                                | 名稱                                | Context | 功能             |
| -------------------------------------- | ----------------------------------- | ------- | ---------------- |
| `kimi-k2-5`                            | Kimi K2.5                           | 256k    | 預設、推論、視覺 |
| `kimi-k2-thinking`                     | Kimi K2 Thinking                    | 256k    | 推論             |
| `llama-3.3-70b`                        | Llama 3.3 70B                       | 128k    | 一般             |
| `llama-3.2-3b`                         | Llama 3.2 3B                        | 128k    | 一般             |
| `hermes-3-llama-3.1-405b`              | Hermes 3 Llama 3.1 405B             | 128k    | 一般，工具停用   |
| `qwen3-235b-a22b-thinking-2507`        | Qwen3 235B Thinking                 | 128k    | 推論             |
| `qwen3-235b-a22b-instruct-2507`        | Qwen3 235B Instruct                 | 128k    | 一般             |
| `qwen3-coder-480b-a35b-instruct`       | Qwen3 Coder 480B                    | 256k    | 程式碼           |
| `qwen3-coder-480b-a35b-instruct-turbo` | Qwen3 Coder 480B Turbo              | 256k    | 程式碼           |
| `qwen3-5-35b-a3b`                      | Qwen3.5 35B A3B                     | 256k    | 推論、視覺       |
| `qwen3-next-80b`                       | Qwen3 Next 80B                      | 256k    | 一般             |
| `qwen3-vl-235b-a22b`                   | Qwen3 VL 235B（視覺）               | 256k    | 視覺             |
| `qwen3-4b`                             | Venice Small（Qwen3 4B）            | 32k     | 快速、推論       |
| `deepseek-v3.2`                        | DeepSeek V3.2                       | 160k    | 推論，工具停用   |
| `venice-uncensored`                    | Venice Uncensored (Dolphin-Mistral) | 32k     | 未審查，工具停用 |
| `mistral-31-24b`                       | Venice Medium (Mistral)             | 128k    | 視覺             |
| `google-gemma-3-27b-it`                | Google Gemma 3 27B Instruct         | 198k    | 視覺             |
| `openai-gpt-oss-120b`                  | OpenAI GPT OSS 120B                 | 128k    | 一般             |
| `nvidia-nemotron-3-nano-30b-a3b`       | NVIDIA Nemotron 3 Nano 30B          | 128k    | 一般             |
| `olafangensan-glm-4.7-flash-heretic`   | GLM 4.7 Flash Heretic               | 128k    | 推論             |
| `zai-org-glm-4.6`                      | GLM 4.6                             | 198k    | 一般             |
| `zai-org-glm-4.7`                      | GLM 4.7                             | 198k    | 推論             |
| `zai-org-glm-4.7-flash`                | GLM 4.7 Flash                       | 128k    | 推論             |
| `zai-org-glm-5`                        | GLM 5                               | 198k    | 推論             |
| `minimax-m21`                          | MiniMax M2.1                        | 198k    | 推論             |
| `minimax-m25`                          | MiniMax M2.5                        | 198k    | 推論             |

### Anonymized 模型（15 個）— 透過 Venice 代理

| 模型 ID                         | 名稱                           | Context | 功能               |
| ------------------------------- | ------------------------------ | ------- | ------------------ |
| `claude-opus-4-6`               | Claude Opus 4.6 (via Venice)   | 1M      | 推論、視覺         |
| `claude-opus-4-5`               | Claude Opus 4.5 (via Venice)   | 198k    | 推論、視覺         |
| `claude-sonnet-4-6`             | Claude Sonnet 4.6 (via Venice) | 1M      | 推論、視覺         |
| `claude-sonnet-4-5`             | Claude Sonnet 4.5 (via Venice) | 198k    | 推論、視覺         |
| `openai-gpt-54`                 | GPT-5.4 (via Venice)           | 1M      | 推論、視覺         |
| `openai-gpt-53-codex`           | GPT-5.3 Codex (via Venice)     | 400k    | 推論、視覺、程式碼 |
| `openai-gpt-52`                 | GPT-5.2 (via Venice)           | 256k    | 推論               |
| `openai-gpt-52-codex`           | GPT-5.2 Codex (via Venice)     | 256k    | 推論、視覺、程式碼 |
| `openai-gpt-4o-2024-11-20`      | GPT-4o (via Venice)            | 128k    | 視覺               |
| `openai-gpt-4o-mini-2024-07-18` | GPT-4o Mini (via Venice)       | 128k    | 視覺               |
| `gemini-3-1-pro-preview`        | Gemini 3.1 Pro (via Venice)    | 1M      | 推論、視覺         |
| `gemini-3-pro-preview`          | Gemini 3 Pro (via Venice)      | 198k    | 推論、視覺         |
| `gemini-3-flash-preview`        | Gemini 3 Flash (via Venice)    | 256k    | 推論、視覺         |
| `grok-41-fast`                  | Grok 4.1 Fast (via Venice)     | 1M      | 推論、視覺         |
| `grok-code-fast-1`              | Grok Code Fast 1 (via Venice)  | 256k    | 推論、程式碼       |

## 模型探索

設定 `VENICE_API_KEY` 後，OpenClaw 會自動從 Venice API 探索模型。若 API 無法存取，則退而使用靜態目錄。

`/models` 端點是公開的（列出不需要認證），但推論需要有效的 API 金鑰。

## 串流與工具支援

| 功能          | 支援                                                     |
| ------------- | -------------------------------------------------------- |
| **串流**      | ✅ 所有模型                                              |
| **函式呼叫**  | ✅ 大多數模型（查看 API 中的 `supportsFunctionCalling`） |
| **視覺/圖片** | ✅ 標記為「Vision」功能的模型                            |
| **JSON 模式** | ✅ 透過 `response_format` 支援                           |

## 定價

Venice 使用積分系統。請查看 [venice.ai/pricing](https://venice.ai/pricing) 了解目前費率：

- **Private 模型**：通常成本較低
- **Anonymized 模型**：類似直接 API 定價 + 少量 Venice 費用

## 比較：Venice vs 直接 API

| 面向     | Venice（Anonymized）   | 直接 API     |
| -------- | ---------------------- | ------------ |
| **隱私** | 元資料已去除，已匿名化 | 你的帳戶連結 |
| **延遲** | +10-50ms（代理）       | 直接         |
| **功能** | 大多數功能受支援       | 完整功能     |
| **計費** | Venice 積分            | 提供者計費   |

## 使用範例

```bash
# Use the default private model
openclaw agent --model venice/kimi-k2-5 --message "Quick health check"

# Use Claude Opus via Venice (anonymized)
openclaw agent --model venice/claude-opus-4-6 --message "Summarize this task"

# Use uncensored model
openclaw agent --model venice/venice-uncensored --message "Draft options"

# Use vision model with image
openclaw agent --model venice/qwen3-vl-235b-a22b --message "Review attached image"

# Use coding model
openclaw agent --model venice/qwen3-coder-480b-a35b-instruct --message "Refactor this function"
```

## 疑難排解

### API 金鑰未被識別

```bash
echo $VENICE_API_KEY
openclaw models list | grep venice
```

確保金鑰以 `vapi_` 開頭。

### 模型不可用

Venice 模型目錄動態更新。執行 `openclaw models list` 查看目前可用的模型。某些模型可能暫時離線。

### 連線問題

Venice API 位於 `https://api.venice.ai/api/v1`。確保你的網路允許 HTTPS 連線。

## 設定檔範例

```json5
{
  env: { VENICE_API_KEY: "vapi_..." },
  agents: { defaults: { model: { primary: "venice/kimi-k2-5" } } },
  models: {
    mode: "merge",
    providers: {
      venice: {
        baseUrl: "https://api.venice.ai/api/v1",
        apiKey: "${VENICE_API_KEY}",
        api: "openai-completions",
        models: [
          {
            id: "kimi-k2-5",
            name: "Kimi K2.5",
            reasoning: true,
            input: ["text", "image"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 256000,
            maxTokens: 65536,
          },
        ],
      },
    },
  },
}
```

## 連結

- [Venice AI](https://venice.ai)
- [API Documentation](https://docs.venice.ai)
- [Pricing](https://venice.ai/pricing)
- [Status](https://status.venice.ai)
