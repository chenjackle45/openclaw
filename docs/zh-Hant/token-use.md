---
title: "Token use(Token 使用與成本)"
summary: "OpenClaw 如何建構提示詞上下文並報告 token 使用量 + 成本"
read_when:
  - 解釋 token 使用量、成本或上下文視窗
  - 除錯上下文成長或壓縮行為
---
# Token use & costs(Token 使用與成本)

OpenClaw 追蹤 **tokens**，而非字元。Tokens 是模型特定的，但大多數
OpenAI 風格的模型對於英文文字平均每個 token 約 4 個字元。

## 系統提示詞如何建構

OpenClaw 在每次執行時組裝自己的系統提示詞。它包括：

- 工具清單 + 簡短描述
- Skills 清單（僅metadata；指令按需使用 `read` 載入）
- 自我更新指令
- 工作區 + bootstrap 檔案（`AGENTS.md`、`SOUL.md`、`TOOLS.md`、`IDENTITY.md`、`USER.md`、`HEARTBEAT.md`、新的時候有 `BOOTSTRAP.md`）。大型檔案由 `agents.defaults.bootstrapMaxChars` 截斷（預設：20000）。
- 時間（UTC + 使用者時區）
- 回覆標籤 + heartbeat 行為
- 執行時 metadata（host/OS/model/thinking）

請參閱 [System Prompt](/concepts/system-prompt) 中的完整細分。

## 上下文視窗中計算什麼

模型接收的所有內容都計入上下文限制：

- 系統提示詞（上面列出的所有部分）
- 對話歷史（使用者 + 助理訊息）
- 工具呼叫和工具結果
- 附件/轉錄（圖片、音訊、檔案）
- 壓縮摘要和修剪工件
- 供應商包裝器或安全標頭（不可見，但仍計算）

對於實際細分（每個注入的檔案、工具、skills 和系統提示詞大小），使用 `/context list` 或 `/context detail`。請參閱 [Context](/concepts/context)。

## 如何查看當前 token 使用量

在聊天中使用這些：

- `/status` → **豐富的狀態卡**，包含會話模型、上下文使用量、最後回應輸入/輸出 tokens 和**估計成本**（僅限 API 金鑰）。
- `/usage off|tokens|full` → 在每個回覆中附加**每個回應的使用量頁腳**。
  - 按會話持久化（儲存為 `responseUsage`）。
  - OAuth 認證**隱藏成本**（僅 tokens）。
- `/usage cost` → 顯示來自 OpenClaw 會話日誌的本地成本摘要。

其他介面：

- **TUI/Web TUI：** `/status` + `/usage` 受支援。
- **CLI：** `openclaw status --usage` 和 `openclaw channels list` 顯示供應商配額視窗（不是每個回應的成本）。

## 成本估算（顯示時）

成本從您的模型定價設定估算：

```
models.providers.<provider>.models[].cost
```

這些是 `input`、`output`、`cacheRead` 和 `cacheWrite` 的**每 1M tokens 的 USD**。如果缺少定價，OpenClaw 僅顯示 tokens。OAuth tokens 永遠不會顯示美元成本。

## 快取 TTL 和修剪影響

供應商提示詞快取僅在快取 TTL 視窗內適用。OpenClaw 可以選擇性地執行**快取 TTL 修剪**：一旦快取 TTL 過期，它會修剪會話，然後重設快取視窗，以便後續請求可以重新使用剛剛快取的上下文，而不是重新快取完整歷史。當會話在 TTL 之後閒置時，這可以保持較低的快取寫入成本。

在 [Gateway configuration](/gateway/configuration) 中設定它，並在 [Session pruning](/concepts/session-pruning) 中查看行為詳情。

Heartbeat 可以在閒置間隙之間保持快取**溫暖**。如果您的模型快取 TTL 是 `1h`，將 heartbeat 間隔設定為略低於該值（例如 `55m`）可以避免重新快取完整提示詞，從而降低快取寫入成本。

對於 Anthropic API 定價，快取讀取比輸入 tokens 便宜得多，而快取寫入以更高的倍數計費。請參閱 Anthropic 的提示詞快取定價以取得最新費率和 TTL 倍數：
https://docs.anthropic.com/docs/build-with-claude/prompt-caching

### 範例：使用 heartbeat 保持 1h 快取溫暖

```yaml
agents:
  defaults:
    model:
      primary: "anthropic/claude-opus-4-5"
    models:
      "anthropic/claude-opus-4-5":
        params:
          cacheControlTtl: "1h"
    heartbeat:
      every: "55m"
```

## 減少 token 壓力的技巧

- 使用 `/compact` 來摘要長會話。
- 在工作流程中修剪大型工具輸出。
- 保持 skill 描述簡短（skill 清單注入到提示詞中）。
- 對於詳細的、探索性的工作，優先使用較小的模型。

請參閱 [Skills](/tools/skills) 以取得確切的 skill 清單開銷公式。
