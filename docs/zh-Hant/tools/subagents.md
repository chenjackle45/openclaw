---
summary: "子代理：生成獨立 agent 執行，將結果公告回要求者聊天頻道"
read_when:
  - 你想透過 agent 進行背景/平行工作
  - 你正在變更 sessions_spawn 或子代理工具政策
  - 你正在實作或疑難排解執行緒綁定的子代理 sessions
title: "Sub-Agents（子代理）"
---

# Sub-agents

子代理是從現有 agent 執行中生成的背景 agent 執行。它們在自己的 session（`agent:<agentId>:subagent:<uuid>`）中執行，完成後**公告**其結果回要求者聊天頻道。

## 斜線命令

使用 `/subagents` 檢查或控制**當前 session** 的子代理執行：

- `/subagents list`
- `/subagents kill <id|#|all>`
- `/subagents log <id|#> [limit] [tools]`
- `/subagents info <id|#>`
- `/subagents send <id|#> <message>`
- `/subagents steer <id|#> <message>`
- `/subagents spawn <agentId> <task> [--model <model>] [--thinking <level>]`

執行緒綁定控制：

這些命令在支援持久執行緒綁定的頻道上有效。請參閱下方的**支援執行緒的頻道**。

- `/focus <subagent-label|session-key|session-id|session-label>`
- `/unfocus`
- `/agents`
- `/session idle <duration|off>`
- `/session max-age <duration|off>`

`/subagents info` 顯示執行中繼資料（狀態、時間戳記、session id、轉錄路徑、清理）。

### 生成行為

`/subagents spawn` 以使用者命令（而非內部中繼）啟動背景子代理，並在執行完成時發送一個最終完成更新回要求者聊天。

- 生成命令是非阻塞的；它立即回傳一個執行 id。
- 完成後，子代理向要求者聊天頻道公告摘要/結果訊息。
- 對於手動生成，傳遞是有韌性的：
  - OpenClaw 首先以穩定的冪等性鍵嘗試直接 `agent` 傳遞。
  - 若直接傳遞失敗，則退而使用佇列路由。
  - 若佇列路由仍不可用，公告會以短指數退避重試，最終放棄。
- 向要求者 session 的完成交接是執行期生成的內部 context（非使用者撰寫的文字），包含：
  - `Result`（`assistant` 回覆文字，若 assistant 回覆為空則為最新的 `toolResult`）
  - `Status`（`completed successfully` / `failed` / `timed out` / `unknown`）
  - 緊湊的執行期/token 統計
  - 告知要求者 agent 以正常 assistant 語氣改寫的傳遞說明（不要轉發原始內部元資料）
- `--model` 和 `--thinking` 覆寫該特定執行的預設值。
- 完成後使用 `info`/`log` 檢查詳細資訊和輸出。
- `/subagents spawn` 是單次模式（`mode: "run"`）。對於持久的執行緒綁定 sessions，請使用帶有 `thread: true` 和 `mode: "session"` 的 `sessions_spawn`。
- 對於 ACP 工具 sessions（Codex、Claude Code、Gemini CLI），請使用帶有 `runtime: "acp"` 的 `sessions_spawn`，並參閱 [ACP Agents](/zh-Hant/tools/acp-agents)。

主要目標：

- 在不阻塞主執行的情況下，並行化「研究/長任務/慢工具」工作。
- 預設隔離子代理（session 隔離 + 可選的沙箱化）。
- 保持工具介面難以誤用：子代理**預設不獲得** session 工具。
- 支援可設定的巢狀深度，用於 orchestrator 模式。

成本注意事項：每個子代理有其**自己的** context 和 token 用量。對於繁重或重複性任務，為子代理設定較便宜的模型，讓主 agent 保持使用高品質模型。你可以透過 `agents.defaults.subagents.model` 或每個 agent 的覆寫來設定。

## 工具

使用 `sessions_spawn`：

- 啟動子代理執行（`deliver: false`，全域通道：`subagent`）
- 然後執行公告步驟，並將公告回覆發布至要求者聊天頻道
- 預設模型：繼承呼叫者，除非你設定 `agents.defaults.subagents.model`（或每個 agent 的 `agents.list[].subagents.model`）；明確的 `sessions_spawn.model` 仍然優先。
- 預設 thinking：繼承呼叫者，除非你設定 `agents.defaults.subagents.thinking`（或每個 agent 的 `agents.list[].subagents.thinking`）；明確的 `sessions_spawn.thinking` 仍然優先。
- 預設執行逾時：若省略 `sessions_spawn.runTimeoutSeconds`，OpenClaw 在設定時使用 `agents.defaults.subagents.runTimeoutSeconds`；否則退而使用 `0`（無逾時）。

工具參數：

- `task`（必填）
- `label?`（可選）
- `agentId?`（可選；若允許，在另一個 agent id 下生成）
- `model?`（可選；覆寫子代理模型；無效值被跳過，子代理以預設模型執行並在工具結果中發出警告）
- `thinking?`（可選；覆寫子代理執行的 thinking 等級）
- `runTimeoutSeconds?`（設定時預設為 `agents.defaults.subagents.runTimeoutSeconds`，否則為 `0`；設定時，子代理執行在 N 秒後中止）
- `thread?`（預設 `false`；當為 `true` 時，為此子代理 session 請求頻道執行緒綁定）
- `mode?`（`run|session`）
  - 預設為 `run`
  - 若 `thread: true` 且省略 `mode`，預設變為 `session`
  - `mode: "session"` 需要 `thread: true`
- `cleanup?`（`delete|keep`，預設 `keep`）
- `sandbox?`（`inherit|require`，預設 `inherit`；`require` 除非目標子執行期已沙箱化，否則拒絕生成）
- `sessions_spawn` **不**接受頻道傳遞參數（`target`、`channel`、`to`、`threadId`、`replyTo`、`transport`）。對於傳遞，請從生成的執行使用 `message`/`sessions_send`。

## 執行緒綁定 sessions

為頻道啟用執行緒綁定後，子代理可以保持綁定到執行緒，使該執行緒中的後續使用者訊息繼續路由到同一子代理 session。

### 支援執行緒的頻道

- Discord（目前唯一支援的頻道）：支援持久執行緒綁定子代理 sessions（`sessions_spawn` 帶 `thread: true`）、手動執行緒控制（`/focus`、`/unfocus`、`/agents`、`/session idle`、`/session max-age`），以及適配器鍵 `channels.discord.threadBindings.enabled`、`channels.discord.threadBindings.idleHours`、`channels.discord.threadBindings.maxAgeHours` 和 `channels.discord.threadBindings.spawnSubagentSessions`。

快速流程：

1. 使用 `sessions_spawn` 帶 `thread: true`（可選地帶 `mode: "session"`）生成。
2. OpenClaw 在活躍頻道中建立或綁定執行緒至該 session 目標。
3. 該執行緒中的回覆和後續訊息路由到已綁定的 session。
4. 使用 `/session idle` 檢查/更新不活躍自動取消焦點，使用 `/session max-age` 控制硬性上限。
5. 使用 `/unfocus` 手動分離。

手動控制：

- `/focus <target>` 將當前執行緒（或建立一個）綁定至子代理/session 目標。
- `/unfocus` 移除當前已綁定執行緒的綁定。
- `/agents` 列出活躍執行和綁定狀態（`thread:<id>` 或 `unbound`）。
- `/session idle` 和 `/session max-age` 僅對已聚焦的已綁定執行緒有效。

設定開關：

- 全域預設：`session.threadBindings.enabled`、`session.threadBindings.idleHours`、`session.threadBindings.maxAgeHours`
- 頻道覆寫和生成自動綁定鍵是適配器特定的。請參閱上方**支援執行緒的頻道**。

請參閱 [Configuration Reference](/zh-Hant/gateway/configuration-reference) 和 [Slash commands](/zh-Hant/tools/slash-commands) 了解目前的適配器詳細資訊。

允許清單：

- `agents.list[].subagents.allowAgents`：可透過 `agentId` 指定的 agent id 列表（`["*"]` 允許任何）。預設：僅要求者 agent。
- 沙箱繼承護欄：若要求者 session 已沙箱化，`sessions_spawn` 拒絕將以未沙箱化方式執行的目標。

探索：

- 使用 `agents_list` 查看目前哪些 agent id 允許用於 `sessions_spawn`。

自動歸檔：

- 子代理 sessions 在 `agents.defaults.subagents.archiveAfterMinutes`（預設：60）後自動歸檔。
- 歸檔使用 `sessions.delete` 並將轉錄重新命名為 `*.deleted.<timestamp>`（同一資料夾）。
- `cleanup: "delete"` 在公告後立即歸檔（仍透過重新命名保留轉錄）。
- 自動歸檔是盡力而為；待處理計時器在 gateway 重啟時丟失。
- `runTimeoutSeconds` **不**自動歸檔；它只停止執行。Session 保持直到自動歸檔。
- 自動歸檔同樣適用於深度 1 和深度 2 的 sessions。

## 巢狀子代理

預設情況下，子代理無法生成自己的子代理（`maxSpawnDepth: 1`）。你可以透過設定 `maxSpawnDepth: 2` 啟用一層巢狀，這允許 **orchestrator 模式**：主 → orchestrator 子代理 → 工作者子子代理。

### 如何啟用

```json5
{
  agents: {
    defaults: {
      subagents: {
        maxSpawnDepth: 2, // allow sub-agents to spawn children (default: 1)
        maxChildrenPerAgent: 5, // max active children per agent session (default: 5)
        maxConcurrent: 8, // global concurrency lane cap (default: 8)
        runTimeoutSeconds: 900, // default timeout for sessions_spawn when omitted (0 = no timeout)
      },
    },
  },
}
```

### 深度層級

| 深度 | Session key 形狀                             | 角色                                   | 可以生成？                   |
| ---- | -------------------------------------------- | -------------------------------------- | ---------------------------- |
| 0    | `agent:<id>:main`                            | 主 agent                               | 始終                         |
| 1    | `agent:<id>:subagent:<uuid>`                 | 子代理（深度 2 允許時為 orchestrator） | 僅當 `maxSpawnDepth >= 2` 時 |
| 2    | `agent:<id>:subagent:<uuid>:subagent:<uuid>` | 子子代理（葉工作者）                   | 從不                         |

### 公告鏈

結果沿鏈向上流動：

1. 深度 2 工作者完成 → 公告給其父（深度 1 orchestrator）
2. 深度 1 orchestrator 接收公告，綜合結果，完成 → 公告給主
3. 主 agent 接收公告並傳遞給使用者

每個層級只看到來自其直接子代的公告。

### 按深度的工具政策

- **深度 1（orchestrator，當 `maxSpawnDepth >= 2` 時）**：獲得 `sessions_spawn`、`subagents`、`sessions_list`、`sessions_history`，以便管理其子代。其他 session/系統工具仍然被拒絕。
- **深度 1（葉，當 `maxSpawnDepth == 1` 時）**：無 session 工具（目前的預設行為）。
- **深度 2（葉工作者）**：無 session 工具 — `sessions_spawn` 在深度 2 始終被拒絕。無法生成進一步的子代。

### 每個 agent 的生成限制

每個 agent session（任何深度）一次最多可以有 `maxChildrenPerAgent`（預設：5）個活躍子代。這可防止單一 orchestrator 的失控扇出。

### 級聯停止

停止深度 1 orchestrator 會自動停止其所有深度 2 子代：

- 在主聊天中的 `/stop` 停止所有深度 1 agent 並級聯到其深度 2 子代。
- `/subagents kill <id>` 停止特定子代理並級聯到其子代。
- `/subagents kill all` 停止要求者的所有子代理並級聯。

## 認證

子代理認證由 **agent id** 解析，而非 session 類型：

- 子代理 session key 為 `agent:<agentId>:subagent:<uuid>`。
- 認證存儲從該 agent 的 `agentDir` 載入。
- 主 agent 的認證設定檔作為**備用**合併；agent 設定檔在衝突時覆寫主設定檔。

注意：合併是加法式的，因此主設定檔始終作為備用可用。尚不支援每個 agent 的完全隔離認證。

## 公告

子代理透過公告步驟回報：

- 公告步驟在子代理 session 內執行（不在要求者 session 內）。
- 若子代理回覆恰好是 `ANNOUNCE_SKIP`，則不發布任何內容。
- 否則傳遞取決於要求者深度：
  - 頂層要求者 sessions 使用帶有外部傳遞的後續 `agent` 呼叫（`deliver=true`）
  - 巢狀要求者子代理 sessions 接收內部後續注入（`deliver=false`），使 orchestrator 可以在 session 內綜合子代結果
  - 若巢狀要求者子代理 session 已消失，OpenClaw 退而使用該 session 的要求者（若可用）
- 子代完成聚合的範圍限定於建構巢狀完成發現時的當前要求者執行，防止過時的先前執行子輸出洩漏到當前公告中。
- 公告回覆在頻道適配器可用時保留執行緒/主題路由。
- 公告 context 被標準化為穩定的內部事件區塊：
  - 來源（`subagent` 或 `cron`）
  - 子 session key/id
  - 公告類型 + 任務標籤
  - 從執行期結果衍生的狀態行（`success`、`error`、`timeout` 或 `unknown`）
  - 公告步驟的結果內容（或若缺少則為 `(no output)`）
  - 描述何時回覆 vs 保持靜默的後續說明
- `Status` 不從模型輸出推斷；它來自執行期結果信號。

公告 payload 在結尾包含統計行（即使已包裝）：

- 執行期（例如，`runtime 5m12s`）
- Token 用量（輸入/輸出/總計）
- 設定模型定價時的估計成本（`models.providers.*.models[].cost`）
- `sessionKey`、`sessionId` 和轉錄路徑（使主 agent 可以透過 `sessions_history` 取得歷史記錄或在磁碟上檢查檔案）
- 內部元資料僅用於 orchestration；面向使用者的回覆應以正常 assistant 語氣改寫。

## 工具政策（子代理工具）

預設情況下，子代理獲得**除 session 工具和系統工具以外的所有工具**：

- `sessions_list`
- `sessions_history`
- `sessions_send`
- `sessions_spawn`

當 `maxSpawnDepth >= 2` 時，深度 1 orchestrator 子代理額外獲得 `sessions_spawn`、`subagents`、`sessions_list` 和 `sessions_history`，以便管理其子代。

透過設定覆寫：

```json5
{
  agents: {
    defaults: {
      subagents: {
        maxConcurrent: 1,
      },
    },
  },
  tools: {
    subagents: {
      tools: {
        // deny wins
        deny: ["gateway", "cron"],
        // if allow is set, it becomes allow-only (deny still wins)
        // allow: ["read", "exec", "process"]
      },
    },
  },
}
```

## 並行性

子代理使用專用的行程內佇列通道：

- 通道名稱：`subagent`
- 並行性：`agents.defaults.subagents.maxConcurrent`（預設 `8`）

## 停止

- 在要求者聊天中發送 `/stop` 會中止要求者 session 並停止從其生成的任何活躍子代理執行，並級聯到巢狀子代。
- `/subagents kill <id>` 停止特定子代理並級聯到其子代。

## 限制

- 子代理公告是**盡力而為**。若 gateway 重啟，待處理的「公告回報」工作會丟失。
- 子代理仍共用相同的 gateway 行程資源；將 `maxConcurrent` 視為安全閥。
- `sessions_spawn` 始終是非阻塞的：它立即回傳 `{ status: "accepted", runId, childSessionKey }`。
- 子代理 context 只注入 `AGENTS.md` + `TOOLS.md`（無 `SOUL.md`、`IDENTITY.md`、`USER.md`、`HEARTBEAT.md` 或 `BOOTSTRAP.md`）。
- 最大巢狀深度為 5（`maxSpawnDepth` 範圍：1–5）。大多數使用案例建議深度 2。
- `maxChildrenPerAgent` 限制每個 session 的活躍子代（預設：5，範圍：1–20）。
