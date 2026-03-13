---
summary: "在 OpenClaw 中透過 API 金鑰或 Codex 訂閱使用 OpenAI"
read_when:
  - You want to use OpenAI models in OpenClaw
  - You want Codex subscription auth instead of API keys
title: "OpenAI"
---

# OpenAI

OpenAI 提供 GPT 模型的開發者 API。Codex 支援 **ChatGPT 登入**以獲得訂閱存取，或 **API 金鑰**登入以取得按使用量計費。Codex 雲端需要 ChatGPT 登入。OpenAI 明確支援在 OpenClaw 等外部工具/工作流程中使用訂閱 OAuth。

## 選項 A：OpenAI API 金鑰（OpenAI Platform）

**最適合：**直接 API 存取和按使用量計費。
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

OpenAI 的目前 API 模型文件列出 `gpt-5.4` 和 `gpt-5.4-pro` 用於直接 OpenAI API 使用。OpenClaw 透過 `openai/*` Responses 路徑轉發兩者。OpenClaw 刻意隱藏過時的 `openai/gpt-5.3-codex-spark` 列，因為直接 OpenAI API 呼叫在實時流量中拒絕它。

OpenClaw **不**在直接 OpenAI API 路徑上公開 `openai/gpt-5.3-codex-spark`。`pi-ai` 仍然為該模型提供內建列，但實時 OpenAI API 請求目前拒絕它。Spark 在 OpenClaw 中被視為僅限 Codex。

## 選項 B：OpenAI Code（Codex）訂閱

**最適合：**使用 ChatGPT/Codex 訂閱存取而非 API 金鑰。
Codex 雲端需要 ChatGPT 登入，而 Codex CLI 支援 ChatGPT 或 API 金鑰登入。

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

OpenAI 的目前 Codex 文件列出 `gpt-5.4` 作為目前的 Codex 模型。OpenClaw 將其對應至 `openai-codex/gpt-5.4` 以供 ChatGPT/Codex OAuth 使用。

如果你的 Codex 帳戶有 Codex Spark 的授權，OpenClaw 也支援：

- `openai-codex/gpt-5.3-codex-spark`

OpenClaw 將 Codex Spark 視為僅限 Codex。它不公開直接的 `openai/gpt-5.3-codex-spark` API 金鑰路徑。

OpenClaw 也在 `pi-ai` 發現時保留 `openai-codex/gpt-5.3-codex-spark`。將其視為取決於授權且實驗性的：Codex Spark 與 GPT-5.4 `/fast` 分開，可用性取決於已登入的 Codex/ChatGPT 帳戶。

### 傳輸預設

OpenClaw 使用 `pi-ai` 進行模型串流。對於 `openai/*` 和 `openai-codex/*`，預設傳輸是 `"auto"`（WebSocket 優先，然後 SSE 備用）。

你可以設定 `agents.defaults.models.<provider/model>.params.transport`：

- `"sse"`：強制使用 SSE
- `"websocket"`：強制使用 WebSocket
- `"auto"`：嘗試 WebSocket，然後改為 SSE

對於 `openai/*`（Responses API），OpenClaw 在預設情況下也會啟用 WebSocket 預熱（`openaiWsWarmup: true`）（使用 WebSocket 傳輸時）。

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

### OpenAI WebSocket 預熱

OpenAI 文件將預熱描述為選擇性。OpenClaw 在預設情況下為 `openai/*` 啟用它，以在使用 WebSocket 傳輸時減少首輪延遲。

### 停用預熱

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

### 明確啟用預熱

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

### OpenAI 優先級處理

OpenAI 的 API 透過 `service_tier=priority` 公開優先級處理。在 OpenClaw 中，設定 `agents.defaults.models["openai/<model>"].params.serviceTier` 以在直接 `openai/*` Responses 請求上傳遞該欄位。

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

### OpenAI 快速模式

OpenClaw 為 `openai/*` 和 `openai-codex/*` 工作階段公開共享的快速模式切換：

- Chat/UI：`/fast status|on|off`
- 設定：`agents.defaults.models["<provider>/<model>"].params.fastMode`

啟用快速模式時，OpenClaw 應用低延遲 OpenAI 設定檔：

- 當酬載未指定推理時，`reasoning.effort = "low"`
- 當酬載未指定詳細程度時，`text.verbosity = "low"`
- 對於直接 `openai/*` Responses 呼叫至 `api.openai.com`，`service_tier = "priority"`

範例：

```json5
{
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.4": {
          params: {
            fastMode: true,
          },
        },
        "openai-codex/gpt-5.4": {
          params: {
            fastMode: true,
          },
        },
      },
    },
  },
}
```

工作階段覆蓋優先於設定。在工作階段 UI 中清除工作階段覆蓋會將工作階段返回配置預設值。

### OpenAI Responses 伺服器端壓縮

對於直接 OpenAI Responses 模型（`openai/*` 使用 `api: "openai-responses"` 且 `baseUrl` 在 `api.openai.com` 上），OpenClaw 現在自動啟用 OpenAI 伺服器端壓縮酬載提示：

- 強制 `store: true`（除非模型相容性設定 `supportsStore: false`）
- 注入 `context_management: [{ type: "compaction", compact_threshold: ... }]`

預設情況下，`compact_threshold` 是模型 `contextWindow` 的 `70%`（或在不可用時為 `80000`）。

### 明確啟用伺服器端壓縮

在你想要在相容 Responses 模型（例如 Azure OpenAI Responses）上強制 `context_management` 注入時使用此選項：

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

`responsesServerCompaction` 只控制 `context_management` 注入。直接 OpenAI Responses 模型仍會強制 `store: true`，除非相容性設定 `supportsStore: false`。

## 備註

- 模型引用始終使用 `provider/model`（見 [/concepts/models](/zh-Hant/concepts/models)）。
- 認證詳情和重複使用規則在 [/concepts/oauth](/zh-Hant/concepts/oauth)。
