---
title: "Groq"
summary: "Groq 設定 (驗證 + 模型選擇)"
read_when:
  - You want to use Groq with OpenClaw
  - You need the API key env var or CLI auth choice
---

# Groq

[Groq](https://groq.com) 在自訂 LPU 硬體上為開源模型 (Llama、Gemma、Mistral 等) 提供超快速推論。OpenClaw 透過其 OpenAI 相容 API 連接到 Groq。

- 提供者：`groq`
- 驗證：`GROQ_API_KEY`
- API：OpenAI 相容

## 快速開始

1. 從 [console.groq.com/keys](https://console.groq.com/keys) 取得 API 金鑰。

2. 設定 API 金鑰：

```bash
export GROQ_API_KEY="gsk_..."
```

3. 設定預設模型：

```json5
{
  agents: {
    defaults: {
      model: { primary: "groq/llama-3.3-70b-versatile" },
    },
  },
}
```

## 設定檔案範例

```json5
{
  env: { GROQ_API_KEY: "gsk_..." },
  agents: {
    defaults: {
      model: { primary: "groq/llama-3.3-70b-versatile" },
    },
  },
}
```

## 音訊轉錄

Groq 也提供快速的基於 Whisper 的音訊轉錄。當設定為媒體理解提供者時，OpenClaw 使用 Groq 的 `whisper-large-v3-turbo` 模型來轉錄語音訊息。

```json5
{
  media: {
    understanding: {
      audio: {
        models: [{ provider: "groq" }],
      },
    },
  },
}
```

## 環境注意

如果閘道作為守護程式執行 (launchd/systemd)，請確保 `GROQ_API_KEY` 對該程式可用（例如，在 `~/.openclaw/.env` 或透過 `env.shellEnv`）。

## 可用的模型

Groq 的模型目錄經常變化。執行 `openclaw models list | grep groq`
