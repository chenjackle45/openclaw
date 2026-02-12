---
title: "Cloudflare AI Gateway（Cloudflare AI Gateway）"
summary: "Cloudflare AI Gateway 設定（認證＋模型選擇）"
read_when:
  - You want to use Cloudflare AI Gateway with OpenClaw
  - You need the account ID, gateway ID, or API key env var
---

# Cloudflare AI Gateway

Cloudflare AI Gateway 坐在提供者 API 前並讓你新增分析、快取及控制。針對 Anthropic，OpenClaw 透過 Gateway 端點使用 Anthropic Messages API。

- 提供者：`cloudflare-ai-gateway`
- 基礎 URL：`https://gateway.ai.cloudflare.com/v1/<account_id>/<gateway_id>/anthropic`
- 預設模型：`cloudflare-ai-gateway/claude-sonnet-4-5`
- API 鑰：`CLOUDFLARE_AI_GATEWAY_API_KEY`（透過 Gateway 請求的提供者 API 鑰）

針對 Anthropic 模型，使用 Anthropic API 鑰。

## 快速開始

1. 設定提供者 API 鑰及 Gateway 詳情：

```bash
openclaw onboard --auth-choice cloudflare-ai-gateway-api-key
```

2. 設定預設模型：

```json5
{
  agents: {
    defaults: {
      model: { primary: "cloudflare-ai-gateway/claude-sonnet-4-5" },
    },
  },
}
```

## 非互動例子

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice cloudflare-ai-gateway-api-key \
  --cloudflare-ai-gateway-account-id "your-account-id" \
  --cloudflare-ai-gateway-gateway-id "your-gateway-id" \
  --cloudflare-ai-gateway-api-key "$CLOUDFLARE_AI_GATEWAY_API_KEY"
```

## 已認證的 gateway

如在 Cloudflare 中啟用 Gateway 認證，新增 `cf-aig-authorization` 標題（除提供者 API 鑰外）。

```json5
{
  models: {
    providers: {
      "cloudflare-ai-gateway": {
        headers: {
          "cf-aig-authorization": "Bearer <cloudflare-ai-gateway-token>",
        },
      },
    },
  },
}
```

## 環境注

如 Gateway 作為守護程序執行（launchd/systemd），確保 `CLOUDFLARE_AI_GATEWAY_API_KEY` 對該程序可用（例如在 `~/.openclaw/.env` 或透過 `env.shellEnv`）。
