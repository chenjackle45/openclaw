---
summary: "透過 LiteLLM Proxy 執行 OpenClaw 以實現統一模型存取和成本追蹤"
read_when:
  - You want to route OpenClaw through a LiteLLM proxy
  - You need cost tracking, logging, or model routing through LiteLLM
title: "LiteLLM"
---

# LiteLLM

[LiteLLM](https://litellm.ai) 是一個開源 LLM Gateway，提供統一 API 至 100+ 個模型提供者。透過 LiteLLM 路由 OpenClaw 以取得集中式成本追蹤、日誌記錄，以及不改變 OpenClaw 設定即可切換後端的靈活性。

## 為什麼用 LiteLLM 搭配 OpenClaw？

- **成本追蹤** — 準確查看 OpenClaw 在所有模型上的支出
- **模型路由** — 在 Claude、GPT-4、Gemini、Bedrock 之間切換，無需設定變更
- **虛擬鑰** — 為 OpenClaw 建立具有支出限制的鑰
- **日誌記錄** — 完整請求 / 回應日誌用於除錯
- **備選方案** — 如果主要提供者停機，自動容錯移轉

## 快速開始

### 透過上線

```bash
openclaw onboard --auth-choice litellm-api-key
```

### 手動設定

1. 啟動 LiteLLM Proxy：

```bash
pip install 'litellm[proxy]'
litellm --model claude-opus-4-6
```

2. 將 OpenClaw 指向 LiteLLM：

```bash
export LITELLM_API_KEY="your-litellm-key"

openclaw
```

就這樣。OpenClaw 現在透過 LiteLLM 路由。

## 設定

### 環境變數

```bash
export LITELLM_API_KEY="sk-litellm-key"
```

### 設定檔

```json5
{
  models: {
    providers: {
      litellm: {
        baseUrl: "http://localhost:4000",
        apiKey: "${LITELLM_API_KEY}",
        api: "openai-completions",
        models: [
          {
            id: "claude-opus-4-6",
            name: "Claude Opus 4.6",
            reasoning: true,
            input: ["text", "image"],
            contextWindow: 200000,
            maxTokens: 64000,
          },
          {
            id: "gpt-4o",
            name: "GPT-4o",
            reasoning: false,
            input: ["text", "image"],
            contextWindow: 128000,
            maxTokens: 8192,
          },
        ],
      },
    },
  },
  agents: {
    defaults: {
      model: { primary: "litellm/claude-opus-4-6" },
    },
  },
}
```

## 虛擬鑰

為 OpenClaw 建立具有支出限制的專用鑰：

```bash
curl -X POST "http://localhost:4000/key/generate" \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"key_alias": "openclaw", "max_budget": 50.00, "budget_duration": "monthly"}'
```

使用生成的鑰作為 `LITELLM_API_KEY`。

## 模型路由

LiteLLM 可以將模型請求路由到不同的後端。在 LiteLLM `config.yaml` 中設定：

```yaml
model_list:
  - model_name: claude-opus-4-6
    litellm_params:
      model: claude-opus-4-6
      api_key: os.environ/ANTHROPIC_API_KEY

  - model_name: gpt-4o
    litellm_params:
      model: gpt-4o
      api_key: os.environ/OPENAI_API_KEY
```

OpenClaw 保持要求 `claude-opus-4-6` — LiteLLM 處理路由。

## 檢視使用情況

檢查 LiteLLM 儀表板或 API：

```bash
# 鑰資訊
curl "http://localhost:4000/key/info" \
  -H "Authorization: Bearer sk-litellm-key"

# 支出日誌
curl "http://localhost:4000/spend/logs" \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY"
```

## 註記

- LiteLLM 預設在 `http://localhost:4000` 執行
- OpenClaw 透過 OpenAI 相容 `/v1/chat/completions` 端點連線
- 所有 OpenClaw 功能透過 LiteLLM 運作 — 無限制

## 另見

- [LiteLLM 文件](https://docs.litellm.ai)
- [模型提供者](/zh-Hant/concepts/model-providers)
