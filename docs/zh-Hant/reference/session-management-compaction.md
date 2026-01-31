---
title: "Session management compaction(Session 管理與壓縮)"
summary: "深入探討：Session Store + Transcripts、Lifecycle 和 (Auto)Compaction 內部"
read_when:
  - 您需要除錯 Session IDs、Transcript JSONL 或 sessions.json 欄位
  - 您正在變更 Auto-compaction 行為或新增「Pre-compaction」Housekeeping
  - 您想實作 Memory Flushes 或 Silent System Turns
---
# Session 管理與壓縮（深入探討）

本文件說明 OpenClaw 如何端對端管理 Sessions：

- **Session Routing**（Inbound 訊息如何對應至 `sessionKey`）
- **Session Store**（`sessions.json`）及其追蹤的內容
- **Transcript Persistence**（`*.jsonl`）及其結構
- **Transcript Hygiene**（執行前的 Provider-specific 修正）
- **Context Limits**（Context Window vs Tracked Tokens）
- **Compaction**（手動 + Auto-compaction）以及在哪裡 Hook Pre-compaction 工作
- **Silent Housekeeping**（例如不應產生使用者可見輸出的 Memory Writes）

如果您想先了解更高層次的概覽，請從以下開始：
- [/zh-Hant/concepts/session](/zh-Hant/concepts/session)
- [/zh-Hant/concepts/compaction](/zh-Hant/concepts/compaction)
- [/zh-Hant/concepts/session-pruning](/zh-Hant/concepts/session-pruning)
- [/zh-Hant/reference/transcript-hygiene](/zh-Hant/reference/transcript-hygiene)

---

## 真相來源：Gateway

OpenClaw 圍繞單一 **Gateway Process** 設計，擁有 Session 狀態。

- UIs（macOS App、Web Control UI、TUI）應查詢 Gateway 取得 Session 清單和 Token 計數。
- 在 Remote Mode 中，Session 檔案在 Remote Host 上；「檢查您的 Local Mac 檔案」不會反映 Gateway 正在使用的內容。

---

## 兩個持久化層

OpenClaw 以兩層持久化 Sessions：

1) **Session Store（`sessions.json`）**
   - Key/Value Map：`sessionKey -> SessionEntry`
   - 小型、可變、可安全編輯（或刪除 Entries）
   - 追蹤 Session Metadata（目前 Session ID、最後活動、Toggles、Token Counters 等）

2) **Transcript（`<sessionId>.jsonl`）**
   - Append-only Transcript，具有 Tree 結構（Entries 有 `id` + `parentId`）
   - 儲存實際對話 + Tool Calls + Compaction 摘要
   - 用於重建未來 Turns 的 Model Context

---

## 磁碟位置

每個 Agent，在 Gateway Host 上：

- Store：`~/.openclaw/agents/<agentId>/sessions/sessions.json`
- Transcripts：`~/.openclaw/agents/<agentId>/sessions/<sessionId>.jsonl`
  - Telegram Topic Sessions：`.../<sessionId>-topic-<threadId>.jsonl`

OpenClaw 透過 `src/config/sessions.ts` 解析這些。

---

## Session Keys（`sessionKey`）

`sessionKey` 識別*您在哪個對話 Bucket*（Routing + Isolation）。

常見模式：

- Main/Direct Chat（每個 Agent）：`agent:<agentId>:<mainKey>`（預設 `main`）
- Group：`agent:<agentId>:<channel>:group:<id>`
- Room/Channel（Discord/Slack）：`agent:<agentId>:<channel>:channel:<id>` 或 `...:room:<id>`
- Cron：`cron:<job.id>`
- Webhook：`hook:<uuid>`（除非被覆寫）

標準規則記錄於 [/zh-Hant/concepts/session](/zh-Hant/concepts/session)。

---

## Session IDs（`sessionId`）

每個 `sessionKey` 指向目前的 `sessionId`（繼續對話的 Transcript 檔案）。

經驗法則：
- **Reset**（`/new`、`/reset`）為該 `sessionKey` 建立新的 `sessionId`。
- **Daily Reset**（Gateway Host 上本地時間預設凌晨 4:00）在 Reset Boundary 後的下一則訊息建立新的 `sessionId`。
- **Idle Expiry**（`session.reset.idleMinutes` 或 Legacy `session.idleMinutes`）在 Idle Window 後收到訊息時建立新的 `sessionId`。當同時設定 Daily + Idle 時，先到期的獲勝。

實作細節：決定發生在 `src/auto-reply/reply/session.ts` 的 `initSessionState()` 中。

---

## Session Store Schema（`sessions.json`）

Store 的值類型是 `src/config/sessions.ts` 中的 `SessionEntry`。

主要欄位（非詳盡）：

- `sessionId`：目前 Transcript ID（檔名從此衍生，除非設定 `sessionFile`）
- `updatedAt`：最後活動時間戳記
- `sessionFile`：選用的明確 Transcript 路徑覆寫
- `chatType`：`direct | group | room`（幫助 UIs 和 Send Policy）
- `provider`、`subject`、`room`、`space`、`displayName`：Group/Channel 標籤的 Metadata
- Toggles：
  - `thinkingLevel`、`verboseLevel`、`reasoningLevel`、`elevatedLevel`
  - `sendPolicy`（Per-session 覆寫）
- Model 選擇：
  - `providerOverride`、`modelOverride`、`authProfileOverride`
- Token Counters（盡力而為 / Provider-dependent）：
  - `inputTokens`、`outputTokens`、`totalTokens`、`contextTokens`
- `compactionCount`：此 Session Key 完成 Auto-compaction 的次數
- `memoryFlushAt`：最後 Pre-compaction Memory Flush 的時間戳記
- `memoryFlushCompactionCount`：最後 Flush 執行時的 Compaction Count

Store 可安全編輯，但 Gateway 是權威：它可能在 Sessions 執行時重寫或 Rehydrate Entries。

---

## Transcript 結構（`*.jsonl`）

Transcripts 由 `@mariozechner/pi-coding-agent` 的 `SessionManager` 管理。

檔案是 JSONL：
- 第一行：Session Header（`type: "session"`，包含 `id`、`cwd`、`timestamp`、選用的 `parentSession`）
- 然後：具有 `id` + `parentId` 的 Session Entries（Tree）

值得注意的 Entry 類型：
- `message`：User/Assistant/ToolResult 訊息
- `custom_message`：Extension-injected 訊息，*會*進入 Model Context（可從 UI 隱藏）
- `custom`：*不會*進入 Model Context 的 Extension 狀態
- `compaction`：持久化的 Compaction 摘要，具有 `firstKeptEntryId` 和 `tokensBefore`
- `branch_summary`：導航 Tree Branch 時持久化的摘要

OpenClaw 故意**不**「修正」Transcripts；Gateway 使用 `SessionManager` 來讀寫它們。

---

## Context Windows vs Tracked Tokens

兩個不同的概念很重要：

1) **Model Context Window**：每個 Model 的硬上限（Model 可見的 Tokens）
2) **Session Store Counters**：寫入 `sessions.json` 的滾動統計（用於 /status 和 Dashboards）

如果您在調整 Limits：
- Context Window 來自 Model Catalog（可透過 Config 覆寫）。
- Store 中的 `contextTokens` 是 Runtime 估計/報告值；不要將其視為嚴格保證。

更多資訊請見 [/zh-Hant/token-use](/zh-Hant/token-use)。

---

## Compaction：是什麼

Compaction 將較舊的對話摘要為 Transcript 中持久化的 `compaction` Entry，並保持最近的訊息完整。

Compaction 後，未來的 Turns 會看到：
- Compaction 摘要
- `firstKeptEntryId` 之後的訊息

Compaction 是**持久的**（不像 Session Pruning）。請見 [/zh-Hant/concepts/session-pruning](/zh-Hant/concepts/session-pruning)。

---

## Auto-compaction 何時發生（Pi Runtime）

在 Embedded Pi Agent 中，Auto-compaction 在兩種情況下觸發：

1) **Overflow Recovery**：Model 回傳 Context Overflow 錯誤 → Compact → 重試。
2) **Threshold Maintenance**：成功的 Turn 後，當：

`contextTokens > contextWindow - reserveTokens`

其中：
- `contextWindow` 是 Model 的 Context Window
- `reserveTokens` 是為 Prompts + 下一個 Model 輸出保留的餘量

這些是 Pi Runtime 語意（OpenClaw 消費 Events，但 Pi 決定何時 Compact）。

---

## Compaction 設定（`reserveTokens`、`keepRecentTokens`）

Pi 的 Compaction 設定位於 Pi Settings 中：

```json5
{
  compaction: {
    enabled: true,
    reserveTokens: 16384,
    keepRecentTokens: 20000
  }
}
```

OpenClaw 也對 Embedded Runs 強制執行安全底線：

- 如果 `compaction.reserveTokens < reserveTokensFloor`，OpenClaw 會提高它。
- 預設 Floor 是 `20000` Tokens。
- 設定 `agents.defaults.compaction.reserveTokensFloor: 0` 以停用 Floor。
- 如果它已經更高，OpenClaw 會保持不變。

為什麼：在 Compaction 變得無法避免之前，為多 Turn「Housekeeping」（如 Memory Writes）留下足夠餘量。

實作：`src/agents/pi-settings.ts` 中的 `ensurePiCompactionReserveTokens()`
（從 `src/agents/pi-embedded-runner.ts` 呼叫）。

---

## 使用者可見的表面

您可以透過以下觀察 Compaction 和 Session 狀態：

- `/status`（在任何 Chat Session 中）
- `openclaw status`（CLI）
- `openclaw sessions` / `sessions --json`
- Verbose Mode：`🧹 Auto-compaction complete` + Compaction Count

---

## Silent Housekeeping（`NO_REPLY`）

OpenClaw 支援用於背景任務的「Silent」Turns，使用者不應看到中間輸出。

慣例：
- Assistant 以 `NO_REPLY` 開始輸出，表示「不要向使用者傳遞回覆」。
- OpenClaw 在傳遞層剝離/抑制此項。

自 `2026.1.10` 起，OpenClaw 也會在部分 Chunk 以 `NO_REPLY` 開始時抑制 **Draft/Typing Streaming**，讓 Silent 操作不會在 Turn 中途洩漏部分輸出。

---

## Pre-compaction「Memory Flush」（已實作）

目標：在 Auto-compaction 發生之前，執行一個 Silent Agentic Turn，將持久狀態寫入磁碟（例如 Agent Workspace 中的 `memory/YYYY-MM-DD.md`），這樣 Compaction 就不會抹除關鍵 Context。

OpenClaw 使用 **Pre-threshold Flush** 方法：

1) 監控 Session Context 使用量。
2) 當它越過「Soft Threshold」（低於 Pi 的 Compaction Threshold）時，執行 Silent「立即寫入 Memory」指令給 Agent。
3) 使用 `NO_REPLY` 讓使用者看不到任何內容。

Config（`agents.defaults.compaction.memoryFlush`）：
- `enabled`（預設：`true`）
- `softThresholdTokens`（預設：`4000`）
- `prompt`（Flush Turn 的 User Message）
- `systemPrompt`（Flush Turn 附加的額外 System Prompt）

注意事項：
- 預設 Prompt/System Prompt 包含 `NO_REPLY` 提示以抑制傳遞。
- Flush 每個 Compaction Cycle 執行一次（在 `sessions.json` 中追蹤）。
- Flush 僅對 Embedded Pi Sessions 執行（CLI Backends 略過）。
- 當 Session Workspace 是唯讀（`workspaceAccess: "ro"` 或 `"none"`）時略過 Flush。
- 請見 [Memory](/zh-Hant/concepts/memory) 了解 Workspace 檔案佈局和寫入模式。

Pi 也在 Extension API 中公開 `session_before_compact` Hook，但 OpenClaw 的 Flush 邏輯目前位於 Gateway 端。

---

## 疑難排解檢查清單

- Session Key 錯誤？從 [/zh-Hant/concepts/session](/zh-Hant/concepts/session) 開始，並確認 `/status` 中的 `sessionKey`。
- Store vs Transcript 不符？確認 Gateway Host 和來自 `openclaw status` 的 Store 路徑。
- Compaction 垃圾訊息？檢查：
  - Model Context Window（太小）
  - Compaction 設定（`reserveTokens` 對 Model Window 來說太高可能導致更早 Compaction）
  - Tool-result 膨脹：啟用/調整 Session Pruning
- Silent Turns 洩漏？確認回覆以 `NO_REPLY` 開始（確切 Token）且您使用包含 Streaming 抑制修正的 Build。
