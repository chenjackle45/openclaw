---
summary: "使用 vLLM（OpenAI 相容本機伺服器）執行 OpenClaw"
read_when:
  - You want to run OpenClaw against a local vLLM server
  - You want OpenAI-compatible /v1 endpoints with your own models
title: "vLLM（vLLM）"
---

# vLLM

vLLM 可以透過**OpenAI 相容** HTTP API 提供開源（和一些自訂）模型。OpenClaw 可以使用 `openai-completions` API 連線到 vLLM。

OpenClaw 也可以**自動探索**來自 vLLM 的可用模型，當您選擇加入 `VLLM_API_KEY`（如果伺服器未強制認證，任何值都可行），並且您未定義明確的 `models.providers.vllm` 項目時。

## 快速開始

1. 使用 OpenAI 相容伺服器啟動 vLLM。

您的基底 URL 應公開 `/v1` 端點（例如 `/v1/models`、`/v1/chat/completions`）。vLLM 通常執行在：

- `http://127.0.0.1:8000/v1`

2. 選擇加入（如果未設定認證，任何值都可行）：

```bash
export VLLM_API_KEY="vllm-local"
```

3. 選擇模型（以 vLLM 模型 ID 之一替換）：

```json5
{
  agents: {
    defaults: {
      model: { primary: "vllm/your-model-id" },
    },
  },
}
```

## 模型探索（隱含提供者）

當設定 `VLLM_API_KEY`（或認證設定檔存在）並且您**不**定義 `models.providers.vllm` 時，OpenClaw 將查詢：

- `GET http://127.0.0.1:8000/v1/models`

…並將返回的 ID 轉換為模型項目。

如果您明確設定 `models.providers.vllm`，自動探索會被跳過，您必須手動定義模型。

## 明確設定（手動模型）

在以下情況下使用明確設定：

- vLLM 在不同的主機 / 連接埠上執行。
- 您想固定 `contextWindow`/`maxTokens` 值。
- 您的伺服器需要真實 API 鑰（或您想控制標題）。

```json5
{
  models: {
    providers: {
      vllm: {
        baseUrl: "http://127.0.0.1:8000/v1",
        apiKey: "${VLLM_API_KEY}",
        api: "openai-completions",
        models: [
          {
            id: "your-model-id",
            name: "Local vLLM Model",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 128000,
            maxTokens: 8192,
          },
        ],
      },
    },
  },
}
```

## 疑難排解

- 檢查伺服器是否可達：

```bash
curl http://127.0.0.1:8000/v1/models
```

- 如果請求失敗並出現認證錯誤，設定符合伺服器設定的真實 `VLLM_API_KEY`，或明確在 `models.providers.vllm` 下設定提供者。
