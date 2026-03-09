---
summary: "在 OpenClaw 中透過 API 金鑰或 Codex 訂閱使用 OpenAI"
read_when:
  - 你想在 OpenClaw 中使用 OpenAI 模型
  - 你想使用 Codex 訂閱認證而非 API 金鑰
title: "OpenAI"
---

# OpenAI

OpenAI 為 GPT 模型提供開發者 API。Codex 支援 **ChatGPT 登入**以進行訂閱存取，或支援 **API 金鑰**登入以進行用量計費存取。Codex cloud 需要 ChatGPT 登入。OpenAI 明確支援在 OpenClaw 等外部工具/工作流中使用訂閱 OAuth。

## 選項 A：OpenAI API 金鑰（OpenAI Platform）

**最適合：** 直接 API 存取和用量計費。
從 OpenAI 儀表板取得你的 API 金鑰。

### CLI 設定

```bash
openclaw onboard --auth-choice openai-api-key
# or non-interactive
openclaw onboard --openai-api-key "$OPENAI_API_KEY"
```

### 設定片段

```json5
{
  env: { OPENAI_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "openai/gpt-5.4" } } },
}
```

OpenAI 目前的 API 模型文件列出 `gpt-5.4` 和 `gpt-5.4-pro` 用於直接 OpenAI API 使用。OpenClaw 透過 `openai/*` Responses 路徑轉發兩者。

## 選項 B：OpenAI Code（Codex）訂閱

**最適合：** 使用 ChatGPT/Codex 訂閱存取而非 API 金鑰。
Codex cloud 需要 ChatGPT 登入，而 Codex CLI 支援 ChatGPT 或 API 金鑰登入。

### CLI 設定（Codex OAuth）

```bash
# Run Codex OAuth in the wizard
openclaw onboard --auth-choice openai-codex

# Or run OAuth directly
openclaw models auth login --provider openai-codex
```

### 設定片段（Codex 訂閱）

```json5
{
  agents: { defaults: { model: { primary: "openai-codex/gpt-5.4" } } },
}
```

OpenAI 目前的 Codex 文件列出 `gpt-5.4` 作為目前的 Codex 模型。OpenClaw 將其映射為 `openai-codex/gpt-5.4` 用於 ChatGPT/Codex OAuth 使用。

### 傳輸預設值

OpenClaw 使用 `pi-ai` 進行模型串流。對於 `openai/*` 和 `openai-codex/*`，預設傳輸為 `"auto"`（WebSocket 優先，然後 SSE 備用）。

你可以設定 `agents.defaults.models.<provider/model>.params.transport`：

- `"sse"`：強制 SSE
- `"websocket"`：強制 WebSocket
- `"auto"`：嘗試 WebSocket，然後備用至 SSE

對於 `openai/*`（Responses API），OpenClaw 在使用 WebSocket 傳輸時預設啟用 WebSocket 暖機（`openaiWsWarmup: true`）。

相關 OpenAI 文件：

- [Realtime API with WebSocket](https://platform.openai.com/docs/guides/realtime-websocket)
- [Streaming API responses (SSE)](https://platform.openai.com/docs/guides/streaming-responses)

```json5
{
  agents: {
    defaults: {
      model: { primary: "openai-codex/gpt-5.4" },
      models: {
        "openai-codex/gpt-5.4": {
          params: {
            transport: "auto",
          },
        },
      },
    },
  },
}
```

### OpenAI WebSocket 暖機

OpenAI 文件將暖機描述為可選。OpenClaw 為 `openai/*` 預設啟用它，以減少使用 WebSocket 傳輸時的第一輪延遲。

### 停用暖機

```json5
{
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.4": {
          params: {
            openaiWsWarmup: false,
          },
        },
      },
    },
  },
}
```

### 明確啟用暖機

```json5
{
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.4": {
          params: {
            openaiWsWarmup: true,
          },
        },
      },
    },
  },
}
```

### OpenAI 優先處理

OpenAI 的 API 透過 `service_tier=priority` 公開優先處理。在 OpenClaw 中，將 `agents.defaults.models["openai/<model>"].params.serviceTier` 設定為在直接 `openai/*` Responses 請求上傳遞該欄位。

```json5
{
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.4": {
          params: {
            serviceTier: "priority",
          },
        },
      },
    },
  },
}
```

支援的值為 `auto`、`default`、`flex` 和 `priority`。

### OpenAI Responses 伺服器端壓縮

對於直接 OpenAI Responses 模型（使用 `api.openai.com` 上的 `baseUrl` 的 `api: "openai-responses"` 的 `openai/*`），OpenClaw 現在自動啟用 OpenAI 伺服器端壓縮 payload 提示：

- 強制 `store: true`（除非模型相容性設定 `supportsStore: false`）
- 注入 `context_management: [{ type: "compaction", compact_threshold: ... }]`

預設情況下，`compact_threshold` 為模型 `contextWindow` 的 `70%`（或不可用時為 `80000`）。

### 明確啟用伺服器端壓縮

當你想在相容的 Responses 模型上強制 `context_management` 注入時使用此設定（例如 Azure OpenAI Responses）：

```json5
{
  agents: {
    defaults: {
      models: {
        "azure-openai-responses/gpt-5.4": {
          params: {
            responsesServerCompaction: true,
          },
        },
      },
    },
  },
}
```

### 使用自訂閾值啟用

```json5
{
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.4": {
          params: {
            responsesServerCompaction: true,
            responsesCompactThreshold: 120000,
          },
        },
      },
    },
  },
}
```

### 停用伺服器端壓縮

```json5
{
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.4": {
          params: {
            responsesServerCompaction: false,
          },
        },
      },
    },
  },
}
```

`responsesServerCompaction` 只控制 `context_management` 注入。直接 OpenAI Responses 模型仍然強制 `store: true`，除非相容性設定 `supportsStore: false`。

## 注意事項

- 模型 ref 始終使用 `provider/model`（請參閱 [/concepts/models](/zh-Hant/concepts/models)）。
- 認證詳細資訊 + 重用規則在 [/concepts/oauth](/zh-Hant/concepts/oauth) 中。
