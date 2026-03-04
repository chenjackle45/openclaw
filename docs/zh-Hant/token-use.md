---
summary: "OpenClaw 如何構建提示詞上下文並報告 Token 使用量和成本"
read_when:
  - 解釋 Token 使用量、成本或上下文視窗
  - 調試上下文增長或壓縮行為
title: "Token Use and Costs（Token 使用與成本）"
---

# Token 使用與成本

OpenClaw 追蹤 **Token**，而不是字符。Token 是模型特定的，但大多數 OpenAI 風格的模型平均約每 token 4 個英文字符。

## 系統提示詞如何構建

OpenClaw 在每次運行時自己組裝系統提示詞。它包括：

- 工具列表加簡短描述
- 技能列表（僅元數據；指示通過 `read` 按需加載）
- 自我更新指示
- 工作區加啟動檔案（`AGENTS.md`、`SOUL.md`、`TOOLS.md`、`IDENTITY.md`、`USER.md`、`HEARTBEAT.md`、`BOOTSTRAP.md`（新時）、加 `MEMORY.md` 和/或 `memory.md`（存在時））。大檔案由 `agents.defaults.bootstrapMaxChars`（預設：20000）截斷，總啟動注入由 `agents.defaults.bootstrapTotalMaxChars`（預設：150000）限制。`memory/*.md` 檔案通過記憶體工具按需提供，不自動注入。
- 時間（UTC 加用戶時區）
- 回覆標籤加心跳行為
- 運行時元數據（主機/作業系統/模型/思考）

查看 [系統提示詞](/zh-Hant/concepts/system-prompt) 中的完整分解。

## 上下文視窗中計算什麼

模型接收的所有內容都計入上下文限制：

- 系統提示詞（上述所有部分）
- 對話歷史（用戶加助手消息）
- 工具呼叫和工具結果
- 附件/文字稿（影像、音訊、檔案）
- 壓縮摘要和修剪人工製品
- 提供商包裝器或安全標頭（不可見，但仍計算）

對於影像，OpenClaw 在提供商呼叫前縮小文字稿/工具影像負載。
使用 `agents.defaults.imageMaxDimensionPx`（預設：`1200`）調整：

- 較低的值通常減少視覺 token 使用量和負載大小。
- 較高的值為 OCR/UI 繁重的屏幕截圖保留更多視覺細節。

如需實用分解（每個注入檔案、工具、技能和系統提示詞大小），使用 `/context list` 或 `/context detail`。查看 [上下文](/zh-Hant/concepts/context)。

## 如何查看當前 Token 使用量

在聊天中使用這些：

- `/status` → **表情符號豐富的狀態卡** 帶有會話模型、上下文使用量、上次回應輸入/輸出 token 和 **估計成本**（僅限 API 金鑰）。
- `/usage off|tokens|full` → 附加 **每個回應使用頁腳** 到每個回覆。
  - 按會話持續（存儲為 `responseUsage`）。
  - OAuth 認證 **隱藏成本**（僅限 token）。
- `/usage cost` → 顯示來自 OpenClaw 會話日誌的本地成本摘要。

其他表面：

- **TUI/Web TUI：** `/status` 加 `/usage` 受支援。
- **CLI：** `openclaw status --usage` 和 `openclaw channels list` 顯示提供商配額視窗（非每個回應成本）。

## 成本估計（如顯示）

成本是根據你的模型定價配置估計的：

```
models.providers.<provider>.models[].cost
```

這些是 `input`、`output`、`cacheRead` 和 `cacheWrite` 的 **美元每 1M token**。如果定價遺失，OpenClaw 只顯示 token。OAuth token 永遠不顯示美元成本。

## 快取 TTL 和修剪影響

提供商提示詞快取僅適用於快取 TTL 視窗內。OpenClaw 可以選擇性地運行 **快取 TTL 修剪**：它在快取 TTL 過期後修剪會話，然後重置快取視窗，以便後續請求可以重新使用新鮮快取的上下文，而不是重新快取完整歷史。這在會話超過 TTL 閒置時保持快取寫入成本較低。

在 [網關配置](/zh-Hant/gateway/configuration) 中配置它，並在 [會話修剪](/zh-Hant/concepts/session-pruning) 中查看行為詳細資訊。

心跳可以在空閒間隙中保持快取 **溫暖**。如果你的模型快取 TTL 是 `1h`，設定心跳間隔在其下方（例如 `55m`）可以避免重新快取完整提示詞，減少快取寫入成本。

在多代理設定中，你可以保持一個共享模型配置，並使用 `agents.list[].params.cacheRetention` 調整每個代理的快取行為。

如需完整的按鈕指南，請查看 [提示詞快取](/zh-Hant/reference/prompt-caching)。

對於 Anthropic API 定價，快取讀取明顯便宜於輸入 token，而快取寫入按更高的乘數計費。查看 Anthropic 的提示詞快取定價以獲取最新費率和 TTL 乘數：
[https://docs.anthropic.com/docs/build-with-claude/prompt-caching](https://docs.anthropic.com/docs/build-with-claude/prompt-caching)

### 範例：使用心跳保持 1h 快取溫暖

```yaml
agents:
  defaults:
    model:
      primary: "anthropic/claude-opus-4-6"
    models:
      "anthropic/claude-opus-4-6":
        params:
          cacheRetention: "long"
    heartbeat:
      every: "55m"
```

### 範例：混合流量與每個代理快取策略

```yaml
agents:
  defaults:
    model:
      primary: "anthropic/claude-opus-4-6"
    models:
      "anthropic/claude-opus-4-6":
        params:
          cacheRetention: "long" # 大多數代理的預設基線
  list:
    - id: "research"
      default: true
      heartbeat:
        every: "55m" # 為深度會話保持長快取溫暖
    - id: "alerts"
      params:
        cacheRetention: "none" # 避免爆發性通知的快取寫入
```

`agents.list[].params` 在選定模型的 `params` 上合併，所以你只能覆蓋 `cacheRetention` 並繼承其他模型預設值不變。

### 範例：啟用 Anthropic 1M 上下文 Beta 標頭

Anthropic 的 1M 上下文視窗目前是 beta 閘控。OpenClaw 在支援的 Opus 或 Sonnet 模型上啟用 `context1m` 時可以注入必需的 `anthropic-beta` 值。

```yaml
agents:
  defaults:
    models:
      "anthropic/claude-opus-4-6":
        params:
          context1m: true
```

這映射到 Anthropic 的 `context-1m-2025-08-07` beta 標頭。

這僅在該模型項目上設定 `context1m: true` 時適用。

需求：憑證必須符合長上下文使用的資格（API 金鑰計費，或啟用額外使用的訂閱）。如果沒有，Anthropic 會回應 `HTTP 429: rate_limit_error: Extra usage is required for long context requests`。

如果你使用 OAuth/訂閱 token（`sk-ant-oat-*`）認證 Anthropic，OpenClaw 會跳過 `context-1m-*` beta 標頭，因為 Anthropic 目前拒絕該組合，返回 HTTP 401。

## 減少 Token 壓力的提示

- 使用 `/compact` 總結長會話。
- 在工作流中修剪大型工具輸出。
- 對於屏幕截圖密集的會話，降低 `agents.defaults.imageMaxDimensionPx`。
- 保持技能描述簡短（技能列表被注入到提示詞中）。
- 對於詳細的探索性工作，傾向於較小的模型。

查看 [技能](/zh-Hant/tools/skills) 以獲得確切的技能列表開銷公式。
