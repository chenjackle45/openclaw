---
title: "Vercel AI Gateway（Vercel AI Gateway）"
summary: "Vercel AI Gateway 設定（認證 + 模型選擇）"
read_when:
  - You want to use Vercel AI Gateway with OpenClaw
  - You need the API key env var or CLI auth choice
---

# Vercel AI Gateway

[Vercel AI Gateway](https://vercel.com/ai-gateway) 提供統一 API 以透過單一端點存取數百個模型。

- 提供者：`vercel-ai-gateway`
- 認證：`AI_GATEWAY_API_KEY`
- API：Anthropic Messages 相容

## 快速開始

1. 設定 API 鑰（建議：為 Gateway 儲存）：

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

## 非互動範例

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice ai-gateway-api-key \
  --ai-gateway-api-key "$AI_GATEWAY_API_KEY"
```

## 環境註記

如果 Gateway 作為守護程式執行（launchd / systemd），確保 `AI_GATEWAY_API_KEY`
對該程序可用（例如，在 `~/.openclaw/.env` 或透過 `env.shellEnv`）。

## 模型 ID 速寫

OpenClaw 接受 Vercel Claude 速寫模型參考並在執行時規範化：

- `vercel-ai-gateway/claude-opus-4.6` -> `vercel-ai-gateway/anthropic/claude-opus-4.6`
- `vercel-ai-gateway/opus-4.6` -> `vercel-ai-gateway/anthropic/claude-opus-4-6`
