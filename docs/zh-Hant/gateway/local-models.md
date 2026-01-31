---
title: "local-models(Local models)"
summary: "在本地 LLMs (LM Studio, vLLM, LiteLLM, custom OpenAI endpoints) 上運行 OpenClaw"
read_when:
  - 想要從自己的 GPU 機器服務模型時
  - 正在串接 LM Studio 或 OpenAI 相容的 Proxy 時
  - 需要最安全的本地模型指引時
---

# 本地模型 (Local Models)

本地運行是可行的，但 OpenClaw 預期有大 Context + 對 Prompt Injection 的強大防禦。小型 Cards 會截斷 Context 並洩漏安全性。目標定高一點：**≥2 台 maxed-out Mac Studios 或同等級的 GPU Rig (~$30k+)**。單張 **24 GB** GPU 僅適用於較輕的 Prompts 且延遲較高。請使用 **您能運行的最大 / 全尺寸模型變體**；過度量化或“小型” Checkpoints 會增加 Prompt-injection 風險 (參閱 [Security](/gateway/security))。

## 推薦: LM Studio + MiniMax M2.1 (Responses API, 全尺寸)

目前最佳的本地 Stack。在 LM Studio 中載入 MiniMax M2.1，啟用 Local Server (預設 `http://127.0.0.1:1234`)，並使用 Responses API 將推理 (Reasoning) 與最終文字分開。

```json5
{
  agents: {
    defaults: {
      model: { primary: "lmstudio/minimax-m2.1-gs32" },
      models: {
        "anthropic/claude-opus-4-5": { alias: "Opus" },
        "lmstudio/minimax-m2.1-gs32": { alias: "Minimax" }
      }
    }
  },
  models: {
    mode: "merge",
    providers: {
      lmstudio: {
        baseUrl: "http://127.0.0.1:1234/v1",
        apiKey: "lmstudio",
        api: "openai-responses",
        models: [
          {
            id: "minimax-m2.1-gs32",
            name: "MiniMax M2.1 GS32",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 196608,
            maxTokens: 8192
          }
        ]
      }
    }
  }
}
```

**設定檢查清單**
- 安裝 LM Studio: https://lmstudio.ai
- 在 LM Studio 中，下載 **可用的最大 MiniMax M2.1 build** (避免 “small”/heavily quantized 變體)，啟動伺服器，確認 `http://127.0.0.1:1234/v1/models` 有列出它。
- 保持模型載入；冷載入 (Cold-load) 會增加啟動延遲。
- 若您的 LM Studio build 不同，調整 `contextWindow`/`maxTokens`。
- 對於 WhatsApp，堅持使用 Responses API 以便僅發送最終文字。

即使在本地運行，仍保持 Hosted Models 設定；使用 `models.mode: "merge"` 讓 Fallbacks 保持可用。

### 混合設定: Hosted as Primary, Local as Fallback

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-sonnet-4-5",
        fallbacks: ["lmstudio/minimax-m2.1-gs32", "anthropic/claude-opus-4-5"]
      },
      models: {
        "anthropic/claude-sonnet-4-5": { alias: "Sonnet" },
        "lmstudio/minimax-m2.1-gs32": { alias: "MiniMax Local" },
        "anthropic/claude-opus-4-5": { alias: "Opus" }
      }
    }
  },
  models: {
    mode: "merge",
    providers: {
      lmstudio: {
        baseUrl: "http://127.0.0.1:1234/v1",
        apiKey: "lmstudio",
        api: "openai-responses",
        models: [
          {
            id: "minimax-m2.1-gs32",
            name: "MiniMax M2.1 GS32",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 196608,
            maxTokens: 8192
          }
        ]
      }
    }
  }
}
```

### Local-first with Hosted Safety Net

交換 Primary 與 Fallback 順序；保持相同的 Providers區塊與 `models.mode: "merge"`，以便您可以在本地機器當機時 Fall back 至 Sonnet 或 Opus。

### 區域託管 / 資料路由 (Regional Hosting / Data Routing)

- OpenRouter 上也存在 Hosted MiniMax/Kimi/GLM 變體，並帶有區域鎖定的 Endpoints (例如 US-hosted)。在那裡選擇區域變體以將流量保持在您選擇的管轄區，同時仍使用 `models.mode: "merge"` 進行 Anthropic/OpenAI fallbacks。
- Local-only 仍是強大的隱私路徑；當您需要 Provider 功能但想要控制資料流向時，Hosted Regional Routing 是折衷方案。

## 其他 OpenAI 相容的 Local Proxies

若 vLLM, LiteLLM, OAI-proxy, 或自訂 Gateway 暴露 OpenAI 風格的 `/v1` Endpoint，它們皆可運作。將上述 Provider 區塊替換為您的 Endpoint 與 Model ID：

```json5
{
  models: {
    mode: "merge",
    providers: {
      local: {
        baseUrl: "http://127.0.0.1:8000/v1",
        apiKey: "sk-local",
        api: "openai-responses",
        models: [
          {
            id: "my-local-model",
            name: "Local Model",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 120000,
            maxTokens: 8192
          }
        ]
      }
    }
  }
}
```

保持 `models.mode: "merge"` 以便 Hosted Models 作為 Fallbacks 保持可用。

## 故障排除
- Gateway 能連線到 Proxy 嗎？ `curl http://127.0.0.1:1234/v1/models`。
- LM Studio 模型已卸載？重新載入；冷啟動是常見的“卡住”原因。
- Context Errors? 降低 `contextWindow` 或提高您的伺服器限制。
- 安全性: 本地模型跳過 Provider 端的過濾器；保持 Agents 範圍狹窄並開啟 Compaction 以限制 Prompt Injection 的爆炸半徑。
