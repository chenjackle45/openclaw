---
summary: "使用 SGLang（OpenAI 相容的自託管伺服器）執行 OpenClaw"
read_when:
  - You want to run OpenClaw against a local SGLang server
  - You want OpenAI-compatible /v1 endpoints with your own models
title: "SGLang"
---

# SGLang

SGLang 可以透過 **OpenAI 相容的** HTTP API 提供開源模型。OpenClaw 可以使用 `openai-completions` API 連線到 SGLang。

OpenClaw 也可以**自動發現** SGLang 提供的可用模型，當你使用 `SGLANG_API_KEY` 選擇加入（如果你的伺服器不強制認證，任何值都有效）並且你未定義明確的 `models.providers.sglang` 條目時。

## 快速開始

1. 啟動 SGLang 並使用 OpenAI 相容伺服器。

你的基礎 URL 應公開 `/v1` 端點（例如 `/v1/models`、`/v1/chat/completions`）。SGLang 通常在以下位置執行：

- `http://127.0.0.1:30000/v1`

2. 選擇加入（如果未配置認證，任何值都有效）：

```bash
export SGLANG_API_KEY="sglang-local"
```

3. 執行入門並選擇 `SGLang`，或直接設定模型：

```bash
openclaw onboard
```

```json5
{
  agents: {
    defaults: {
      model: { primary: "sglang/your-model-id" },
    },
  },
}
```

## 模型發現（隱式提供者）

當設定 `SGLANG_API_KEY`（或存在認證設定檔）且你**未**定義 `models.providers.sglang` 時，OpenClaw 將查詢：

- `GET http://127.0.0.1:30000/v1/models`

並將返回的 ID 轉換為模型條目。

如果你明確設定 `models.providers.sglang`，自動發現將被跳過，你必須手動定義模型。

## 明確設定（手動模型）

在以下情況下使用明確設定：

- SGLang 在不同的主機/連接埠執行。
- 你想釘選 `contextWindow`/`maxTokens` 值。
- 你的伺服器需要真正的 API 金鑰（或你想控制標頭）。

```json5
{
  models: {
    providers: {
      sglang: {
        baseUrl: "http://127.0.0.1:30000/v1",
        apiKey: "${SGLANG_API_KEY}",
        api: "openai-completions",
        models: [
          {
            id: "your-model-id",
            name: "Local SGLang Model",
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

## 疑難排除

- 檢查伺服器是否可到達：

```bash
curl http://127.0.0.1:30000/v1/models
```

- 如果請求因認證錯誤而失敗，設定與伺服器設定相符的真正 `SGLANG_API_KEY`，或在 `models.providers.sglang` 下明確設定提供者。
