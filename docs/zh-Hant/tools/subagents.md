---
title: "Subagents(Sub-agents)"
summary: "Sub-agents：生成隔離的 Agent Run 並將結果公告回請求者 Chat"
read_when:
  - 您想透過 Agent 進行背景/平行工作
  - 您正在變更 sessions_spawn 或 Sub-agent Tool Policy
---

# Sub-agents

Sub-agents 是從現有 Agent Run 生成的背景 Agent Run。它們在自己的 Session（`agent:<agentId>:subagent:<uuid>`）中執行，完成後會將結果**公告**回請求者 Chat Channel。

## Slash 指令

使用 `/subagents` 可檢視或控制**目前 Session** 的 Sub-agent Run：
- `/subagents list`
- `/subagents stop <id|#|all>`
- `/subagents log <id|#> [limit] [tools]`
- `/subagents info <id|#>`
- `/subagents send <id|#> <message>`

`/subagents info` 會顯示 Run Metadata（狀態、時間戳記、Session ID、Transcript 路徑、Cleanup）。

主要目標：
- 平行化「研究/長時間任務/慢速 Tool」工作，而不阻塞主要 Run。
- 預設保持 Sub-agents 隔離（Session 分離 + 選用 Sandboxing）。
- 保持 Tool 表面難以誤用：Sub-agents 預設**不**取得 Session Tools。
- 避免巢狀擴散：Sub-agents 無法生成 Sub-agents。

成本注意：每個 Sub-agent 有其**專屬** Context 和 Token 使用量。對於繁重或重複的任務，可為 Sub-agents 設定較便宜的模型，主要 Agent 使用較高品質的模型。可透過 `agents.defaults.subagents.model` 或 Per-agent 覆寫進行設定。

## Tool

使用 `sessions_spawn`：
- 啟動 Sub-agent Run（`deliver: false`，Global Lane：`subagent`）
- 然後執行公告步驟，並將公告回覆張貼至請求者 Chat Channel
- 預設模型：繼承呼叫者，除非設定 `agents.defaults.subagents.model`（或 Per-agent `agents.list[].subagents.model`）；明確的 `sessions_spawn.model` 仍優先。

Tool 參數：
- `task`（必填）
- `label?`（選填）
- `agentId?`（選填；如允許則在另一個 Agent ID 下生成）
- `model?`（選填；覆寫 Sub-agent 模型；無效值會被略過，Sub-agent 會以預設模型執行並在 Tool Result 中顯示警告）
- `thinking?`（選填；覆寫 Sub-agent Run 的 Thinking 層級）
- `runTimeoutSeconds?`（預設 `0`；設定後，Sub-agent Run 會在 N 秒後中止）
- `cleanup?`（`delete|keep`，預設 `keep`）

Allowlist：
- `agents.list[].subagents.allowAgents`：可透過 `agentId` 指定的 Agent ID 清單（`["*"]` 允許任何）。預設：僅請求者 Agent。

探索：
- 使用 `agents_list` 查看目前 `sessions_spawn` 允許的 Agent ID。

自動封存：
- Sub-agent Sessions 會在 `agents.defaults.subagents.archiveAfterMinutes` 後自動封存（預設：60）。
- 封存使用 `sessions.delete` 並將 Transcript 重新命名為 `*.deleted.<timestamp>`（相同資料夾）。
- `cleanup: "delete"` 會在公告後立即封存（仍透過重新命名保留 Transcript）。
- 自動封存是盡力而為；如果 Gateway 重新啟動，待處理的計時器會遺失。
- `runTimeoutSeconds` **不會**自動封存；它只會停止 Run。Session 會保留直到自動封存。

## 身份驗證

Sub-agent Auth 是依 **Agent ID** 解析，而非 Session 類型：
- Sub-agent Session Key 是 `agent:<agentId>:subagent:<uuid>`。
- Auth Store 從該 Agent 的 `agentDir` 載入。
- 主要 Agent 的 Auth Profiles 會作為 **Fallback** 合併；Agent Profiles 在衝突時覆寫主要 Profiles。

注意：合併是加性的，所以主要 Profiles 始終作為 Fallbacks 可用。尚不支援完全隔離的 Per-agent Auth。

## 公告

Sub-agents 透過公告步驟回報：
- 公告步驟在 Sub-agent Session 內執行（非請求者 Session）。
- 如果 Sub-agent 回覆正好是 `ANNOUNCE_SKIP`，則不會張貼任何內容。
- 否則公告回覆會透過後續 `agent` 呼叫（`deliver=true`）張貼至請求者 Chat Channel。
- 公告回覆會保留 Thread/Topic 路由（如有：Slack Threads、Telegram Topics、Matrix Threads）。
- 公告訊息會正規化為穩定模板：
  - `Status:` 衍生自 Run 結果（`success`、`error`、`timeout` 或 `unknown`）。
  - `Result:` 公告步驟的摘要內容（如缺少則為 `(not available)`）。
  - `Notes:` 錯誤詳情及其他有用上下文。
- `Status` 不是從模型輸出推斷的；它來自 Runtime 結果訊號。

公告 Payloads 在結尾包含統計行（即使 Wrapped）：
- Runtime（例如 `runtime 5m12s`）
- Token 使用量（Input/Output/Total）
- 設定模型定價時的預估成本（`models.providers.*.models[].cost`）
- `sessionKey`、`sessionId` 和 Transcript 路徑（讓主要 Agent 可透過 `sessions_history` 取得歷史或檢查磁碟上的檔案）

## Tool Policy（Sub-agent Tools）

預設情況下，Sub-agents 取得**除 Session Tools 以外的所有 Tools**：
- `sessions_list`
- `sessions_history`
- `sessions_send`
- `sessions_spawn`

透過 Config 覆寫：

```json5
{
  agents: {
    defaults: {
      subagents: {
        maxConcurrent: 1
      }
    }
  },
  tools: {
    subagents: {
      tools: {
        // deny 優先
        deny: ["gateway", "cron"],
        // 如果設定 allow，則變為 allow-only（deny 仍優先）
        // allow: ["read", "exec", "process"]
      }
    }
  }
}
```

## 並行

Sub-agents 使用專用的 In-process Queue Lane：
- Lane 名稱：`subagent`
- 並行數：`agents.defaults.subagents.maxConcurrent`（預設 `8`）

## 停止

- 在請求者 Chat 中傳送 `/stop` 會中止請求者 Session 並停止從其生成的任何活躍 Sub-agent Run。

## 限制

- Sub-agent 公告是**盡力而為**。如果 Gateway 重新啟動，待處理的「公告回報」工作會遺失。
- Sub-agents 仍共享相同的 Gateway Process 資源；將 `maxConcurrent` 視為安全閥。
- `sessions_spawn` 始終是非阻塞的：它會立即回傳 `{ status: "accepted", runId, childSessionKey }`。
- Sub-agent Context 僅注入 `AGENTS.md` + `TOOLS.md`（無 `SOUL.md`、`IDENTITY.md`、`USER.md`、`HEARTBEAT.md` 或 `BOOTSTRAP.md`）。
