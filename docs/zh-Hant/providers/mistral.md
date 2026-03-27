---
summary: "在 OpenClaw 中使用 Mistral 模型和 Voxtral 轉錄"
read_when:
  - You want to use Mistral models in OpenClaw
  - You need Mistral API key onboarding and model refs
title: "Mistral"
---

# Mistral

OpenClaw 同時支援 Mistral 用於文字 / 影像模型路由（`mistral/...`）和
透過 Voxtral 在媒體理解中進行音訊轉錄。
Mistral 也可用於記憶體嵌入（`memorySearch.provider = "mistral"`）。

## CLI 設定

```bash
openclaw onboard --auth-choice mistral-api-key
# 或非互動
openclaw onboard --mistral-api-key "$MISTRAL_API_KEY"
```

## 設定片段（LLM 提供者）

```json5
{
  env: { MISTRAL_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "mistral/mistral-large-latest" } } },
}
```

## 設定片段（使用 Voxtral 的音訊轉錄）

```json5
{
  tools: {
    media: {
      audio: {
        enabled: true,
        models: [{ provider: "mistral", model: "voxtral-mini-latest" }],
      },
    },
  },
}
```

## 註記

- Mistral 認證使用 `MISTRAL_API_KEY`。
- 提供者基底 URL 預設為 `https://api.mistral.ai/v1`。
- 上線預設模型是 `mistral/mistral-large-latest`。
- 媒體理解預設 Mistral 音訊模型是 `voxtral-mini-latest`。
- 媒體轉錄路徑使用 `/v1/audio/transcriptions`。
- 記憶體嵌入路徑使用 `/v1/embeddings`（預設模型：`mistral-embed`）。
