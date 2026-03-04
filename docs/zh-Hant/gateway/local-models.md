---
title: "Local Models（本機模型）"
summary: “在本地 LLMs (LM Studio, vLLM, LiteLLM、自訂 OpenAI 端點) 上執行 OpenClaw”
read_when:
  - 想要從自己的 GPU 機器提供模型時
  - 正在設定 LM Studio 或 OpenAI 相容的 Proxy 時
  - 需要最安全的本地模型指引時
---

# 本地模型

本地執行是可行的，但 OpenClaw 預期大型 Context 和對 Prompt Injection 的強大防禦。小型 GPU 卡會截斷 Context 並降低安全性。目標訂高一點：**≥2 台 maxed-out Mac Studios 或同等級的 GPU Rig (~$30k+)**。單張 **24 GB** GPU 僅適用於較輕的 Prompts 且延遲較高。請使用**您能執行的最大／完整尺寸模型變體**；過度量化或「小型」Checkpoints 會增加 Prompt Injection 風險（參閱 [Security](/zh-Hant/gateway/security)）。

## 推薦：LM Studio + MiniMax M2.5 (Responses API，完整尺寸)

目前最佳的本地堆疊。在 LM Studio 中載入 MiniMax M2.5，啟用本地伺服器（預設 `http://127.0.0.1:1234`），並使用 Responses API 將推理與最終文字分開。

```json5
{
  agents: {
    defaults: {
      model: { primary: “lmstudio/minimax-m2.5-gs32” },
      models: {
        “anthropic/claude-opus-4-6”: { alias: “Opus” },
        “lmstudio/minimax-m2.5-gs32”: { alias: “Minimax” },
      },
    },
  },
  models: {
    mode: “merge”,
    providers: {
      lmstudio: {
        baseUrl: “http://127.0.0.1:1234/v1”,
        apiKey: “lmstudio”,
        api: “openai-responses”,
        models: [
          {
            id: “minimax-m2.5-gs32”,
            name: “MiniMax M2.5 GS32”,
            reasoning: false,
            input: [“text”],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 196608,
            maxTokens: 8192,
          },
        ],
      },
    },
  },
}
```

**設定檢查清單**

- 安裝 LM Studio：[https://lmstudio.ai](https://lmstudio.ai)
- 在 LM Studio 中下載**可用的最大 MiniMax M2.5 build**（避免「small」／重度量化變體），啟動伺服器，確認 `http://127.0.0.1:1234/v1/models` 有列出它。
- 保持模型載入；冷啟動會增加啟動延遲。
- 若您的 LM Studio build 不同，調整 `contextWindow`／`maxTokens`。
- 對於 WhatsApp，堅持使用 Responses API 以便只發送最終文字。

即使在本地執行，仍要保持託管模型設定；使用 `models.mode: “merge”` 讓 Fallbacks 保持可用。

### 混合設定：託管為主要，本地為備援

```json5
{
  agents: {
    defaults: {
      model: {
        primary: “anthropic/claude-sonnet-4-5”,
        fallbacks: [“lmstudio/minimax-m2.5-gs32”, “anthropic/claude-opus-4-6”],
      },
      models: {
        “anthropic/claude-sonnet-4-5”: { alias: “Sonnet” },
        “lmstudio/minimax-m2.5-gs32”: { alias: “MiniMax Local” },
        “anthropic/claude-opus-4-6”: { alias: “Opus” },
      },
    },
  },
  models: {
    mode: “merge”,
    providers: {
      lmstudio: {
        baseUrl: “http://127.0.0.1:1234/v1”,
        apiKey: “lmstudio”,
        api: “openai-responses”,
        models: [
          {
            id: “minimax-m2.5-gs32”,
            name: “MiniMax M2.5 GS32”,
            reasoning: false,
            input: [“text”],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 196608,
            maxTokens: 8192,
          },
        ],
      },
    },
  },
}
```

### 本地優先搭配託管安全網

交換主要和備援的順序；保持相同的 providers 區塊和 `models.mode: “merge”`，以便在本地機器當機時可以回落至 Sonnet 或 Opus。

### 區域託管／資料路由

- OpenRouter 上也有託管的 MiniMax／Kimi／GLM 變體，附帶區域鎖定的端點（例如 US 託管）。選擇該區域的變體以在您選擇的管轄區內保持流量，同時仍使用 `models.mode: “merge”` 進行 Anthropic／OpenAI 備援。
- 本地限定仍是最強的隱私路徑；當您需要提供商功能但想要控制資料流時，託管區域路由是折衷方案。

## 其他 OpenAI 相容的本地 Proxies

vLLM、LiteLLM、OAI-proxy 或自訂閘道只要暴露 OpenAI 風格的 `/v1` 端點就能運作。將上述 provider 區塊替換為您的端點和模型 ID：

```json5
{
  models: {
    mode: “merge”,
    providers: {
      local: {
        baseUrl: “http://127.0.0.1:8000/v1”,
        apiKey: “sk-local”,
        api: “openai-responses”,
        models: [
          {
            id: “my-local-model”,
            name: “Local Model”,
            reasoning: false,
            input: [“text”],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 120000,
            maxTokens: 8192,
          },
        ],
      },
    },
  },
}
```

保持 `models.mode: “merge”` 以便託管模型作為備援保持可用。

## 故障排除

- Gateway 能連線到 proxy 嗎？`curl http://127.0.0.1:1234/v1/models`。
- LM Studio 模型已卸載？重新載入；冷啟動是常見的「卡住」原因。
- Context 錯誤？降低 `contextWindow` 或提高伺服器限制。
- 安全性：本地模型略過提供商端的篩選；保持 Agents 範圍狹窄並開啟 Compaction 以限制 Prompt Injection 的爆炸半徑。
