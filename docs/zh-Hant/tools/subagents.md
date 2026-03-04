---
summary: "子代理：生成公佈結果回要求者聊天的隔離代理執行"
read_when:
  - 你希望通過代理進行後台/並行工作
  - 你正在改變 sessions_spawn 或子代理工具原則
  - 你正在實作或故障排查線程綁定子代理會話
title: "Sub-Agents（子代理）"
---

# 子代理

子代理是從現有代理執行生成的後台代理執行。它們在自己的會話（`agent:<agentId>:subagent:<uuid>`）中執行，並在完成時，**公佈** 它們的結果回要求者聊天頻道。

## 斜杠命令

使用 `/subagents` 檢查或控制 **當前會話** 的子代理執行：

- `/subagents list`
- `/subagents kill <id|#|all>`
- `/subagents log <id|#> [limit] [tools]`
- `/subagents info <id|#>`
- `/subagents send <id|#> <message>`
- `/subagents steer <id|#> <message>`
- `/subagents spawn <agentId> <task> [--model <model>] [--thinking <level>]`

線程綁定控制：

這些命令在支援持續線程綁定的頻道上有效。查看下面的 **線程支援頻道**。

- `/focus <subagent-label|session-key|session-id|session-label>`
- `/unfocus`
- `/agents`
- `/session idle <duration|off>`
- `/session max-age <duration|off>`

`/subagents info` 顯示執行元數據（狀態、時間戳、會話 id、文字稿路徑、清理）。

### 生成行為

`/subagents spawn` 作為用戶命令啟動後台子代理，而不是內部中繼，並且在執行完成時向要求者聊天傳送一個最終完成更新。

- spawn 命令是非阻止的；它立即返回執行 id。
- 在完成時，子代理向要求者聊天頻道公佈摘要/結果訊息。
- 對於手動 spawn，傳遞是可復原的：
  - OpenClaw 首先使用穩定冪等性金鑰嘗試直接 `agent` 傳遞。
  - 如果直接傳遞失敗，它降級到隊列路由。
  - 如果隊列路由仍不可用，公佈使用短指數退避重試，然後最終放棄。
- 對要求者會話的完成交接是執行時生成的內部上下文（不是用戶作者文本），並包括：
  - `Result`（`assistant` 回覆文本，或最新 `toolResult`，如果助手回覆為空）
  - `Status`（`completed successfully` / `failed` / `timed out` / `unknown`）
  - 緊湊執行時/token 統計
  - 告訴要求者代理以正常助手語氣重寫的傳遞指示（不轉發原始內部元數據）
- `--model` 和 `--thinking` 覆蓋該特定執行的預設值。
- 使用 `info`/`log` 在完成後檢查詳細資訊和輸出。
- `/subagents spawn` 是一次性模式（`mode: "run"`）。對於持續線程綁定會話，使用 `sessions_spawn` 帶 `thread: true` 和 `mode: "session"`。
- 對於 ACP 線束會話（Codex、Claude Code、Gemini CLI），使用 `sessions_spawn` 帶 `runtime: "acp"`，查看 [ACP 代理](/zh-Hant/tools/acp-agents)。

主要目標：

- 平行化「研究 / 長任務 / 緩慢工具」工作，無需阻止主執行。
- 預設情況下保持子代理隔離（會話分離加可選沙盒）。
- 保持工具表面難以濫用：子代理 **預設不** 獲得會話工具。
- 支援可配置的嵌套深度用於協調器模式。

成本注意：每個子代理有其 **自己的** 上下文和 token 使用量。對於繁重或重複任務，為子代理設定更便宜的模型，為主代理保持更高品質模型。
你可以通過 `agents.defaults.subagents.model` 或按代理覆蓋配置這個。

## 工具

使用 `sessions_spawn`：

- 啟動子代理執行（`deliver: false`、全域通道：`subagent`）
- 然後執行公佈步驟並將公佈回覆貼文到要求者聊天頻道
- 預設模型：繼承呼叫者，除非你設定 `agents.defaults.subagents.model`（或按代理 `agents.list[].subagents.model`）；顯式 `sessions_spawn.model` 仍然獲勝。
- 預設思考：繼承呼叫者，除非你設定 `agents.defaults.subagents.thinking`（或按代理 `agents.list[].subagents.thinking`）；顯式 `sessions_spawn.thinking` 仍然獲勝。
- 預設執行超時：如果省略 `sessions_spawn.runTimeoutSeconds`，OpenClaw 在設定時使用 `agents.defaults.subagents.runTimeoutSeconds`；否則它降級到 `0`（無超時）。

工具參數：

- `task`（必需）
- `label?`（可選）
- `agentId?`（可選；如果允許，在另一個代理 id 下生成）
- `model?`（可選；覆蓋子代理模型；無效值被跳過，子代理以預設模型執行，工具結果中帶警告）
- `thinking?`（可選；覆蓋子代理執行的思考層級）
- `runTimeoutSeconds?`（預設為設定時的 `agents.defaults.subagents.runTimeoutSeconds`，否則 `0`；設定時，子代理執行在 N 秒後中止）
- `thread?`（預設 `false`；當 `true` 時，為此子代理會話請求頻道線程綁定）
- `mode?`（`run|session`）
  - 預設是 `run`
  - 如果 `thread: true` 且 `mode` 省略，預設變為 `session`
  - `mode: "session"` 需要 `thread: true`
- `cleanup?`（`delete|keep`，預設 `keep`）
- `sandbox?`（`inherit|require`，預設 `inherit`；`require` 拒絕 spawn，除非目標子執行時被沙盒化）
- `sessions_spawn` **不** 接受頻道傳遞參數（`target`、`channel`、`to`、`threadId`、`replyTo`、`transport`）。對於傳遞，使用 `message`/`sessions_send` 從生成的執行。

## 線程綁定會話

當為頻道啟用線程綁定時，子代理可以保持綁定到線程，所以該線程中的後續用戶訊息保持路由到相同的子代理會話。

### 線程支援頻道

- Discord（目前唯一支援的頻道）：支援持續線程綁定子代理會話（`sessions_spawn` 帶 `thread: true`）、手動線程控制（`/focus`、`/unfocus`、`/agents`、`/session idle`、`/session max-age`）和適配器金鑰 `channels.discord.threadBindings.enabled`、`channels.discord.threadBindings.idleHours`、`channels.discord.threadBindings.maxAgeHours` 和 `channels.discord.threadBindings.spawnSubagentSessions`。

快速流：

1. 使用 `sessions_spawn` 用 `thread: true` 生成（並可選 `mode: "session"`）。
2. OpenClaw 在活躍頻道中為該會話目標建立或綁定線程。
3. 該線程中的回覆和後續訊息路由到綁定會話。
4. 使用 `/session idle` 檢查/更新非活動自動取消聚焦，使用 `/session max-age` 控制硬上限。
5. 使用 `/unfocus` 手動分離。

手動控制：

- `/focus <target>` 綁定當前線程（或建立一個）到子代理/會話目標。
- `/unfocus` 移除當前綁定線程的綁定。
- `/agents` 列出活躍執行和綁定狀態（`thread:<id>` 或 `unbound`）。
- `/session idle` 和 `/session max-age` 僅對聚焦綁定線程有效。

配置開關：

- 全域預設：`session.threadBindings.enabled`、`session.threadBindings.idleHours`、`session.threadBindings.maxAgeHours`
- 頻道覆蓋和 spawn 自動綁定金鑰是適配器特定的。查看上面的 **線程支援頻道**。

查看 [設定參考](/zh-Hant/gateway/configuration-reference) 和 [斜杠命令](/zh-Hant/tools/slash-commands) 用於當前適配器詳細資訊。

許可清單：

- `agents.list[].subagents.allowAgents`：可以通過 `agentId` 目標的代理 id 清單（`["*"]` 允許任何）。預設：僅請求代理。
- 沙盒繼承守衛：如果要求者會話被沙盒化，`sessions_spawn` 拒絕會執行未沙盒化目標。

發現：

- 使用 `agents_list` 查看哪些代理 id 目前允許 `sessions_spawn`。

自動封存：

- 子代理會話在 `agents.defaults.subagents.archiveAfterMinutes`（預設：60）後自動封存。
- 封存使用 `sessions.delete` 並將文字稿重新命名為 `*.deleted.<timestamp>`（相同資料夾）。
- `cleanup: "delete"` 公佈後立即封存（仍通過重新命名保持文字稿）。
- 自動封存是最盡力；待處理計時器在網關重啟時丟失。
- `runTimeoutSeconds` **不** 自動封存；它僅停止執行。會話保留到自動封存。
- 自動封存均等適用於深度 1 和深度 2 會話。

## 嵌套子代理

預設情況下，子代理無法生成自己的子代理（`maxSpawnDepth: 1`）。你可以通過設定 `maxSpawnDepth: 2` 啟用一個嵌套層級，它允許 **協調器模式**：主 → 協調器子代理 → 工作者子-子代理。

### 如何啟用

```json5
{
  agents: {
    defaults: {
      subagents: {
        maxSpawnDepth: 2, // 允許子代理生成子代理（預設：1）
        maxChildrenPerAgent: 5, // 每個代理會話的最大活躍子代理（預設：5）
        maxConcurrent: 8, // 全域並行通道上限（預設：8）
        runTimeoutSeconds: 900, // 省略 sessions_spawn 時的預設超時（0 = 無超時）
      },
    },
  },
}
```

### 深度層級

| 深度 | 會話金鑰形狀                                 | 角色                              | 可生成？                  |
| ---- | -------------------------------------------- | --------------------------------- | ------------------------- |
| 0    | `agent:<id>:main`                            | 主代理                            | 總是                      |
| 1    | `agent:<id>:subagent:<uuid>`                 | 子代理（當深度 2 允許時的協調器） | 僅當 `maxSpawnDepth >= 2` |
| 2    | `agent:<id>:subagent:<uuid>:subagent:<uuid>` | 子-子代理（葉工作者）             | 從不                      |

### 公佈鏈

結果流回鏈：

1. 深度 2 工作者完成 → 公佈到其父級（深度 1 協調器）
2. 深度 1 協調器接收公佈、綜合結果、完成 → 公佈到主
3. 主代理接收公佈並傳遞到用戶

每個層級僅看到來自其直接子代理的公佈。

### 按深度的工具原則

- **深度 1（協調器，當 `maxSpawnDepth >= 2` 時）**：獲得 `sessions_spawn`、`subagents`、`sessions_list`、`sessions_history` 以便管理其子代理。其他會話/系統工具保持拒絕。
- **深度 1（葉，當 `maxSpawnDepth == 1` 時）**：無會話工具（當前預設行為）。
- **深度 2（葉工作者）**：無會話工具 — `sessions_spawn` 在深度 2 總是被拒絕。無法進一步生成子代理。

### 按代理生成限制

每個代理會話（任何深度）最多可以有 `maxChildrenPerAgent`（預設：5）活躍子代理。這防止來自單個協調器的無節制扇出。

### 級聯停止

停止深度 1 協調器自動停止其所有深度 2 子代理：

- 主聊天中的 `/stop` 停止所有深度 1 代理並級聯到其深度 2 子代理。
- `/subagents kill <id>` 停止特定子代理並級聯到其子代理。
- `/subagents kill all` 停止要求者的所有子代理並級聯。

## 認證

子代理認證由 **代理 id** 解析，不是會話類型：

- 子代理會話金鑰是 `agent:<agentId>:subagent:<uuid>`。
- 認證儲存從該代理的 `agentDir` 加載。
- 主代理的認證檔案被合併為 **降級**；代理檔案在衝突時覆蓋主檔案。

注意：合併是附加的，所以主檔案總是可用作降級。每個代理的完全隔離認證目前不受支援。

## 公佈

子代理通過公佈步驟報告回：

- 公佈步驟在子代理會話內部執行（不是要求者會話）。
- 如果子代理回覆完全 `ANNOUNCE_SKIP`，不貼文任何內容。
- 否則公佈回覆通過後續 `agent` 呼叫（`deliver=true`）貼文到要求者聊天頻道。
- 公佈回覆在頻道適配器可用時保留線程/主題路由。
- 公佈上下文被規範化為穩定內部事件塊：
  - source（`subagent` 或 `cron`）
  - 子會話金鑰/id
  - 公佈類型加任務標籤
  - 來自執行時結果的狀態行（`success`、`error`、`timeout` 或 `unknown`）
  - 來自公佈步驟的結果內容（或 `(no output)`，如果遺失）
  - 描述何時回覆 vs 保持無聲的後續指示
- `Status` 不從模型輸出推斷；它來自執行時結果信號。

公佈負載在末尾包括統計行（即使包裝）：

- 執行時（例如 `runtime 5m12s`）
- Token 使用量（輸入/輸出/總計）
- 當模型定價被配置時的估計成本（`models.providers.*.models[].cost`）
- `sessionKey`、`sessionId` 和文字稿路徑（所以主代理可以通過 `sessions_history` 獲取歷史或檢查磁碟上的檔案）
- 內部元數據僅用於協調；面向用戶的回覆應在正常助手語氣中重寫。

## 工具原則（子代理工具）

預設情況下，子代理獲得 **所有工具除了會話工具** 和系統工具：

- `sessions_list`
- `sessions_history`
- `sessions_send`
- `sessions_spawn`

當 `maxSpawnDepth >= 2` 時，深度 1 協調器子代理另外接收 `sessions_spawn`、`subagents`、`sessions_list` 和 `sessions_history`，所以它們可以管理其子代理。

通過配置覆蓋：

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
        // deny 獲勝
        deny: ["gateway", "cron"],
        // 如果設定 allow，它變為僅允許（deny 仍獲勝）
        // allow: ["read", "exec", "process"]
      },
    },
  },
}
```

## 並行

子代理使用專用進程內隊列通道：

- 通道名稱：`subagent`
- 並行：`agents.defaults.subagents.maxConcurrent`（預設 `8`）

## 停止

- 在要求者聊天中傳送 `/stop` 中止要求者會話並停止從它生成的任何活躍子代理執行，級聯到嵌套子代理。
- `/subagents kill <id>` 停止特定子代理並級聯到其子代理。

## 限制

- 子代理公佈是 **最盡力**。如果網關重啟，待處理「公佈回」工作丟失。
- 子代理仍然共享相同的網關進程資源；將 `maxConcurrent` 視為安全閥。
- `sessions_spawn` 總是非阻止的：它立即返回 `{ status: "accepted", runId, childSessionKey }`。
- 子代理上下文僅注入 `AGENTS.md` 加 `TOOLS.md`（無 `SOUL.md`、`IDENTITY.md`、`USER.md`、`HEARTBEAT.md` 或 `BOOTSTRAP.md`）。
- 最大嵌套深度是 5（`maxSpawnDepth` 範圍：1–5）。深度 2 對大多數使用情況推薦。
- `maxChildrenPerAgent` 上限活躍子代理每個會話（預設：5，範圍：1–20）。
