---
title: "Vercel AI Gateway（Vercel AI Gateway 閘道）"
summary: "Vercel AI Gateway 設定（認證 + 模型選擇）"
read_when:
  - 你想使用 Vercel AI Gateway 與 OpenClaw
  - 你需要 API 鑰匙環境變數或 CLI 認證選項
---

# Vercel AI Gateway

[Vercel AI Gateway](https://vercel.com/ai-gateway) 提供一個統一的 API 來透過單一端點存取數百個模型。

- 提供者：`vercel-ai-gateway`
- 認證：`AI_GATEWAY_API_KEY`
- API：Anthropic Messages 相容

## 快速開始

1. 設定 API 鑰匙（推薦：為 Gateway 儲存）：

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

## 環境注意

若 Gateway 以 daemon（launchd/systemd）執行，確保 `AI_GATEWAY_API_KEY`
對該程序可用（例如，在 `~/.openclaw/.env` 中或透過
`env.shellEnv`）。
