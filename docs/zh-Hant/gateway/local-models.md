---
summary: "在本地 LLM 上執行 OpenClaw（LM Studio、vLLM、LiteLLM、自訂 OpenAI 端點）"
read_when:
  - You want to serve models from your own GPU box
  - You are wiring LM Studio or an OpenAI-compatible proxy
  - You need the safest local model guidance
title: "Local Models（本地模型）"
---

# 本地模型

本地可行，但 OpenClaw 預期大型上下文 + 強大的提示注入防禦。小型卡片會截斷上下文並洩露安全性。目標高：**≥2 台最大化 Mac Studio 或等效 GPU 設備（~$30k+）**。單個 **24 GB** GPU 僅適用於較輕提示且較高延遲。使用 **最大/完整大小模型變體** 你能執行的；主動量化或「小」檢查點提高提示注入風險（見 [Security](/zh-Hant/gateway/security)）。

如果想最低阻力本地設定，從 [Ollama](/zh-Hant/providers/ollama) 和 `openclaw onboard` 開始。此頁面是較高端本地堆疊和自訂 OpenAI 相容本地伺服器的有見解指南。

## 推薦：LM Studio + MiniMax M2.5（Responses API、完整大小）

目前最佳本地堆疊。在 LM Studio 中載入 MiniMax M2.5、啟用本地伺服器（預設 `http://127.0.0.1:1234`），並使用 Responses API 以保持推理與最終文字分離。

```json5
{
  agents: {
    defaults: {
      model: { primary: "lmstudio/minimax-m2.5-gs32" },
      models: {
        "anthropic/claude-opus-4-6": { alias: "Opus" },
        "lmstudio/minimax-m2.5-gs32": { alias: "Minimax" },
      },
    },
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
            id: "minimax-m2.5-gs32",
            name: "MiniMax M2.5 GS32",
            reasoning: false,
            input: ["text"],
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
- 在 LM Studio 中，下載 **最大的 MiniMax M2.5 建置** 可用（避免「小」/重量量化變體），啟動伺服器，確認 `http://127.0.0.1:1234/v1/models` 列出它。
- 保持模型載入；冷載加入啟動延遲。
- 如果你的 LM Studio 建置不同，調整 `contextWindow`/`maxTokens`。
- 對於 WhatsApp，堅持 Responses API，只有最終文字被發送。

即使執行本地時也保持已設定託管模型；使用 `models.mode: "merge"` 以讓回退保持可用。

### 混合設定：託管主要、本地回退

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-sonnet-4-5",
        fallbacks: ["lmstudio/minimax-m2.5-gs32", "anthropic/claude-opus-4-6"],
      },
      models: {
        "anthropic/claude-sonnet-4-5": { alias: "Sonnet" },
        "lmstudio/minimax-m2.5-gs32": { alias: "MiniMax Local" },
        "anthropic/claude-opus-4-6": { alias: "Opus" },
      },
    },
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
            id: "minimax-m2.5-gs32",
            name: "MiniMax M2.5 GS32",
            reasoning: false,
            input: ["text"],
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

### 本地優先與託管安全網路

交換主要和回退順序；保持相同提供者區塊和 `models.mode: "merge"` 當本地箱宕機時可回退到 Sonnet 或 Opus。

### 區域主機 / 資料路由

- 託管 MiniMax/Kimi/GLM 變體也存在於 OpenRouter，具有區域固定端點（例如美國主機）。在那裡挑選區域變體以在使用 `models.mode: "merge"` 進行 Anthropic/OpenAI 回退時將流量保持在你選擇的司法管轄區中。
- 本地專用保持最強隱私路徑；託管區域路由是中間路徑，當你需要提供者功能但想控制資料流時。

## 其他 OpenAI 相容本地代理

vLLM、LiteLLM、OAI-proxy 或自訂閘道工作，如果它們暴露 OpenAI 風格的 `/v1` 端點。使用你的端點和模型 ID 取代上方提供者區塊：

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
            maxTokens: 8192,
          },
        ],
      },
    },
  },
}
```

保持 `models.mode: "merge"` 以讓託管模型保持作為回退可用。

## 疑難排解

- Gateway 可到達代理？`curl http://127.0.0.1:1234/v1/models`。
- LM Studio 模型卸載？重新載入；冷啟動是常見「懸掛」原因。
- 上下文錯誤？降低 `contextWindow` 或提高伺服器限制。
- 安全：本地模型跳過提供者端過濾；保持代理窄縮且壓縮開啟以限制提示注入爆炸半徑。
