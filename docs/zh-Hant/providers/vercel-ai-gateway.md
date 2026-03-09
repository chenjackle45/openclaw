---
title: "Vercel AI Gateway（Vercel AI Gateway）"
summary: "Vercel AI Gateway 設定（認證 + 模型選擇）"
read_when:
  - 你想在 OpenClaw 中使用 Vercel AI Gateway
  - 你需要 API 金鑰 env var 或 CLI 認證選擇
---

# Vercel AI Gateway

[Vercel AI Gateway](https://vercel.com/ai-gateway) 提供統一 API，透過單一端點存取數百個模型。

- 提供者：`vercel-ai-gateway`
- 認證：`AI_GATEWAY_API_KEY`
- API：Anthropic Messages 相容
- OpenClaw 自動探索 Gateway `/v1/models` 目錄，因此 `/models vercel-ai-gateway` 包含當前的模型 ref，例如 `vercel-ai-gateway/openai/gpt-5.4`。

## 快速開始

1. 設定 API 金鑰（推薦：為 Gateway 儲存）：

```bash
openclaw onboard --auth-choice ai-gateway-api-key
```

2. 設定預設模型：

```json5
{
  agents: {
    defaults: {
      model: { primary: "vercel-ai-gateway/anthropic/claude-opus-4.6" },
    },
  },
}
```

## 非互動式範例

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice ai-gateway-api-key \
  --ai-gateway-api-key "$AI_GATEWAY_API_KEY"
```

## 環境注意事項

若 Gateway 以常駐程式（launchd/systemd）執行，確保 `AI_GATEWAY_API_KEY` 對該行程可用（例如，在 `~/.openclaw/.env` 中或透過 `env.shellEnv`）。

## 模型 ID 簡寫

OpenClaw 接受 Vercel Claude 簡寫模型 ref，並在執行期將其標準化：

- `vercel-ai-gateway/claude-opus-4.6` -> `vercel-ai-gateway/anthropic/claude-opus-4.6`
- `vercel-ai-gateway/opus-4.6` -> `vercel-ai-gateway/anthropic/claude-opus-4-6`
