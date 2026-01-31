---
title: "vercel-ai-gateway(Vercel AI Gateway)"
summary: "Vercel AI Gateway 設定指南（認證 + 模型選擇）"
read_when:
  - 想要在 OpenClaw 中使用 Vercel AI Gateway 時
  - 需要 API 金鑰環境變數或 CLI 認證選項時
---

# Vercel AI Gateway

[Vercel AI Gateway](https://vercel.com/ai-gateway) 提供統一的 API，透過單一端點存取數百種模型。

- 供應商：`vercel-ai-gateway`
- 認證：`AI_GATEWAY_API_KEY`
- API：相容 Anthropic Messages API

## 快速開始

1) 設定 API 金鑰（建議：為 Gateway 儲存該金鑰）：

```bash
openclaw onboard --auth-choice ai-gateway-api-key
```

2) 設定預設模型：

```json5
{
  agents: {
    defaults: {
      model: { primary: "vercel-ai-gateway/anthropic/claude-opus-4.5" }
    }
  }
}
```

## 非互動模式範例

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice ai-gateway-api-key \
  --ai-gateway-api-key "$AI_GATEWAY_API_KEY"
```

## 環境變數注意事項

若 Gateway 以守護進程 (daemon, 如 launchd/systemd) 運行，請確保 `AI_GATEWAY_API_KEY` 對該行程可用（例如設定於 `~/.openclaw/.env` 或透過 `env.shellEnv`）。
