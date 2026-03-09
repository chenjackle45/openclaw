---
summary: "Cron 工作 + 喚醒 Gateway 排程器"
read_when:
  - 安排背景任務或喚醒時
  - 設定應隨同心跳執行的自動化流程時
  - 決定何時使用心跳或排程任務時
title: "Cron Jobs（Cron 排程工作）"
---

# Cron 排程工作 (Gateway 排程器)

> **Cron 還是心跳？** 見 [Cron vs Heartbeat](/zh-Hant/automation/cron-vs-heartbeat) 瞭解何時使用各自。

Cron 是 Gateway 的內建排程器。它持久化任務，在正確的時間喚醒 Agent，並可選擇將輸出傳回聊天。

若您想要「每天早上執行這個」或「20 分鐘後戳一下 Agent」，Cron 就是機制。

疑難排解：[/automation/troubleshooting](/zh-Hant/automation/troubleshooting)

## 核心重點 (TL;DR)

- Cron 在 **Gateway 內部**執行（不在模型內）。
- 任務存放在 `~/.openclaw/cron/` 下，重啟不會遺失排程。
- 兩種執行風格：
  - **主會話**：加入系統事件，在下次心跳時執行。
  - **隔離**：在 `cron:<jobId>` 中執行專屬 Agent 輪次，可選擇投遞輸出（預設公告）。
- 喚醒是一等公民：任務可要求「立即喚醒」或「下次心跳」。
- Webhook 投遞是每個任務透過 `delivery.mode = "webhook"` + `delivery.to = "<url>"` 設定的。
- 舊版相容性：已儲存且設有 `notify: true` 的任務在 `cron.webhook` 設定時仍會投遞，請將那些任務遷移到 webhook 投遞模式。

## 快速開始（可執行）

建立一次性提醒、驗證存在，並立即執行：

```bash
openclaw cron add \
  --name "Reminder" \
  --at "2026-02-01T16:00:00Z" \
  --session main \
  --system-event "Reminder: check the cron docs draft" \
  --wake now \
  --delete-after-run

openclaw cron list
openclaw cron run <job-id>
openclaw cron runs --id <job-id>
```

排程重複隔離任務並指定投遞目標：

```bash
openclaw cron add \
  --name "Morning brief" \
  --cron "0 7 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Summarize overnight updates." \
  --announce \
  --channel slack \
  --to "channel:C1234567890"
```

## 工具呼叫等效形式 (Gateway cron 工具)

正式的 JSON 格式與範例，請見 [工具呼叫的 JSON Schema](/zh-Hant/automation/cron-jobs#json-schema-for-tool-calls)。

## Cron 工作的儲存位置

Cron 工作預設持久化存放於 Gateway 主機的 `~/.openclaw/cron/jobs.json`。
Gateway 將檔案載入記憶體，並在變更時寫回，因此只有在 Gateway 停止時才能安全地手動編輯。
建議使用 `openclaw cron add/edit` 或 cron 工具呼叫 API 進行變更。

## 初學者友善概述

可將 Cron 工作想成：**何時**執行 + **做什麼**。

1. **選擇排程**
   - 一次性提醒 → `schedule.kind = "at"`（CLI：`--at`）
   - 重複工作 → `schedule.kind = "every"` 或 `schedule.kind = "cron"`
   - 若 ISO 時間戳記省略時區，將視為 **UTC**。

2. **選擇執行位置**
   - `sessionTarget: "main"` → 在下次心跳時搭配主上下文執行。
   - `sessionTarget: "isolated"` → 在 `cron:<jobId>` 中執行專屬 Agent 輪次。

3. **選擇酬載**
   - 主會話 → `payload.kind = "systemEvent"`
   - 隔離會話 → `payload.kind = "agentTurn"`

選填：一次性工作（`schedule.kind = "at"`）成功後預設自動刪除。設定
`deleteAfterRun: false` 可保留它們（成功後將停用）。

## 概念

### 工作

Cron 工作是一筆儲存的記錄，包含：

- **排程**（何時應執行），
- **酬載**（應做什麼），
- 選填的**投遞模式**（`announce`、`webhook` 或 `none`）。
- 選填的 **Agent 綁定**（`agentId`）：在特定 Agent 下執行工作；若缺少或未知，Gateway 會回退到預設 Agent。

工作以穩定的 `jobId` 識別（供 CLI/Gateway API 使用）。
在 Agent 工具呼叫中，`jobId` 是正式欄位；接受舊版 `id` 以維持相容性。
一次性工作成功後預設自動刪除；設定 `deleteAfterRun: false` 可保留它們。

### 排程

Cron 支援三種排程類型：

- `at`：透過 `schedule.at`（ISO 8601）設定的一次性時間戳記。
- `every`：固定間隔（毫秒）。
- `cron`：5 欄位 cron 表達式（或含秒的 6 欄位），可選擇 IANA 時區。

Cron 表達式使用 `croner`。若省略時區，將使用 Gateway 主機的本地時區。

為減少多個 Gateway 的整點負載峰值，OpenClaw 對重複的整點表達式（例如 `0 * * * *`、`0 */2 * * *`）
套用最多 5 分鐘的確定性每工作錯開視窗。固定小時表達式（例如 `0 7 * * *`）保持精確。

對任何 cron 排程，可用 `schedule.staggerMs` 設定明確的錯開視窗
（`0` 保持精確時間）。CLI 快捷鍵：

- `--stagger 30s`（或 `1m`、`5m`）設定明確的錯開視窗。
- `--exact` 強制 `staggerMs = 0`。

### 主會話與隔離執行

#### 主會話工作（系統事件）

主會話工作加入系統事件，並可選擇喚醒心跳執行器。
必須使用 `payload.kind = "systemEvent"`。

- `wakeMode: "now"`（預設）：事件觸發立即心跳執行。
- `wakeMode: "next-heartbeat"`：事件等待下次排程心跳。

最適合想要正常心跳提示 + 主會話上下文的情況。
見 [Heartbeat](/zh-Hant/gateway/heartbeat)。

#### 隔離工作（專屬 Cron 會話）

隔離工作在會話 `cron:<jobId>` 中執行專屬 Agent 輪次。

主要行為：

- 提示以 `[cron:<jobId> <job name>]` 為前綴以便追蹤。
- 每次執行開始一個**全新的會話 id**（不攜帶之前的對話記錄）。
- 預設行為：若省略 `delivery`，隔離工作會公告摘要（`delivery.mode = "announce"`）。
- `delivery.mode` 決定後續行為：
  - `announce`：將摘要投遞到目標頻道，並在主會話中發布簡短摘要。
  - `webhook`：當完成事件包含摘要時，將完成事件酬載 POST 到 `delivery.to`。
  - `none`：僅內部（無投遞，無主會話摘要）。
- `wakeMode` 控制主會話摘要的發布時機：
  - `now`：立即心跳。
  - `next-heartbeat`：等待下次排程心跳。

對於嘈雜、頻繁或不應干擾主聊天記錄的「背景雜務」，使用隔離工作。

### 酬載形狀（執行內容）

支援兩種酬載類型：

- `systemEvent`：僅限主會話，透過心跳提示路由。
- `agentTurn`：僅限隔離會話，執行專屬 Agent 輪次。

常見的 `agentTurn` 欄位：

- `message`：必填的文字提示。
- `model` / `thinking`：選填的覆寫（見下文）。
- `timeoutSeconds`：選填的逾時覆寫。
- `lightContext`：選填的輕量 bootstrap 模式，用於不需要工作區 bootstrap 檔案注入的工作。

投遞設定：

- `delivery.mode`：`none` | `announce` | `webhook`。
- `delivery.channel`：`last` 或特定頻道。
- `delivery.to`：頻道特定目標（公告）或 webhook URL（webhook 模式）。
- `delivery.bestEffort`：若公告投遞失敗則避免工作失敗。

公告投遞會抑制執行期間的訊息工具傳送；使用 `delivery.channel`/`delivery.to`
改為指定聊天目標。當 `delivery.mode = "none"` 時，不會在主會話中發布摘要。

若隔離工作省略 `delivery`，OpenClaw 預設使用 `announce`。

#### 公告投遞流程

當 `delivery.mode = "announce"` 時，cron 直接透過出站頻道介面卡投遞。
主 Agent 不會被啟動來撰寫或轉發訊息。

行為詳情：

- 內容：投遞使用隔離執行的出站酬載（文字/媒體），搭配正常分塊與頻道格式化。
- 僅含心跳回應（`HEARTBEAT_OK` 無實際內容）不會投遞。
- 若隔離執行已透過訊息工具向相同目標傳送訊息，投遞會跳過以避免重複。
- 缺少或無效的投遞目標會使工作失敗，除非 `delivery.bestEffort = true`。
- 只有當 `delivery.mode = "announce"` 時，才會在主會話中發布簡短摘要。
- 主會話摘要遵循 `wakeMode`：`now` 觸發立即心跳，`next-heartbeat` 等待下次排程心跳。

#### Webhook 投遞流程

當 `delivery.mode = "webhook"` 時，cron 在完成事件包含摘要時，將完成事件酬載 POST 到 `delivery.to`。

行為詳情：

- 端點必須是有效的 HTTP(S) URL。
- Webhook 模式不嘗試頻道投遞。
- Webhook 模式不在主會話中發布摘要。
- 若設定了 `cron.webhookToken`，auth header 為 `Authorization: Bearer <cron.webhookToken>`。
- 舊版相容性：設有 `notify: true` 的已儲存舊版工作仍會（若已設定）發布到 `cron.webhook`，並顯示警告以便您遷移到 `delivery.mode = "webhook"`。

### 模型與思考覆寫

隔離工作（`agentTurn`）可覆寫模型和思考層級：

- `model`：提供者/模型字串（例如 `anthropic/claude-sonnet-4-20250514`）或別名（例如 `opus`）
- `thinking`：思考層級（`off`、`minimal`、`low`、`medium`、`high`、`xhigh`；僅限 GPT-5.2 + Codex 模型）

注意：也可以在主會話工作上設定 `model`，但這會改變共享的主會話模型。
建議僅對隔離工作使用模型覆寫，以避免意外的上下文切換。

解析優先順序：

1. 工作酬載覆寫（最高）
2. Hook 特定預設值（例如 `hooks.gmail.model`）
3. Agent 設定預設值

### 輕量 Bootstrap 上下文

隔離工作（`agentTurn`）可設定 `lightContext: true` 以使用輕量 bootstrap 上下文執行。

- 適用於不需要工作區 bootstrap 檔案注入的排程雜務。
- 實際上，嵌入式執行環境以 `bootstrapContextMode: "lightweight"` 執行，故意保持 cron bootstrap 上下文為空。
- CLI 等效：`openclaw cron add --light-context ...` 和 `openclaw cron edit --light-context`。

### 投遞（頻道 + 目標）

隔離工作可透過頂層 `delivery` 設定將輸出投遞到頻道：

- `delivery.mode`：`announce`（頻道投遞）、`webhook`（HTTP POST）或 `none`。
- `delivery.channel`：`whatsapp` / `telegram` / `discord` / `slack` / `mattermost`（插件）/ `signal` / `imessage` / `last`。
- `delivery.to`：頻道特定的收件人目標。

`announce` 投遞僅適用於隔離工作（`sessionTarget: "isolated"`）。
`webhook` 投遞對主會話和隔離工作均有效。

若省略 `delivery.channel` 或 `delivery.to`，cron 可回退到主會話的
「最後路由」（Agent 最後回覆的地方）。

目標格式提醒：

- Slack/Discord/Mattermost（插件）目標應使用明確前綴（例如 `channel:<id>`、`user:<id>`）以避免歧義。
- Telegram 話題應使用 `:topic:` 形式（見下文）。

#### Telegram 投遞目標（話題／論壇串）

Telegram 透過 `message_thread_id` 支援論壇話題。對於 cron 投遞，可在 `to` 欄位中編碼話題／串：

- `-1001234567890`（僅聊天 id）
- `-1001234567890:topic:123`（建議：明確的話題標記）
- `-1001234567890:123`（簡寫：數字後綴）

也接受帶前綴的目標，例如 `telegram:...` / `telegram:group:...`：

- `telegram:group:-1001234567890:topic:123`

## 工具呼叫的 JSON Schema

在直接呼叫 Gateway `cron.*` 工具時（Agent 工具呼叫或 RPC）使用這些格式。
CLI 旗標接受人類可讀的時間（如 `20m`），但工具呼叫的 `schedule.at` 應使用 ISO 8601 字串，`schedule.everyMs` 應使用毫秒。

### cron.add 參數

一次性主會話工作（系統事件）：

```json
{
  "name": "Reminder",
  "schedule": { "kind": "at", "at": "2026-02-01T16:00:00Z" },
  "sessionTarget": "main",
  "wakeMode": "now",
  "payload": { "kind": "systemEvent", "text": "Reminder text" },
  "deleteAfterRun": true
}
```

重複隔離工作含投遞設定：

```json
{
  "name": "Morning brief",
  "schedule": { "kind": "cron", "expr": "0 7 * * *", "tz": "America/Los_Angeles" },
  "sessionTarget": "isolated",
  "wakeMode": "next-heartbeat",
  "payload": {
    "kind": "agentTurn",
    "message": "Summarize overnight updates.",
    "lightContext": true
  },
  "delivery": {
    "mode": "announce",
    "channel": "slack",
    "to": "channel:C1234567890",
    "bestEffort": true
  }
}
```

注意：

- `schedule.kind`：`at`（`at`）、`every`（`everyMs`）或 `cron`（`expr`，選填 `tz`）。
- `schedule.at` 接受 ISO 8601（時區可選；省略時視為 UTC）。
- `everyMs` 為毫秒。
- `sessionTarget` 必須為 `"main"` 或 `"isolated"`，且必須與 `payload.kind` 對應。
- 選填欄位：`agentId`、`description`、`enabled`、`deleteAfterRun`（`at` 預設為 true）、`delivery`。
- `wakeMode` 省略時預設為 `"now"`。

### cron.update 參數

```json
{
  "jobId": "job-123",
  "patch": {
    "enabled": false,
    "schedule": { "kind": "every", "everyMs": 3600000 }
  }
}
```

注意：

- `jobId` 是正式欄位；接受 `id` 以維持相容性。
- 在 patch 中使用 `agentId: null` 可清除 Agent 綁定。

### cron.run 和 cron.remove 參數

```json
{ "jobId": "job-123", "mode": "force" }
```

```json
{ "jobId": "job-123" }
```

## 儲存與歷史

- 工作儲存：`~/.openclaw/cron/jobs.json`（Gateway 管理的 JSON）。
- 執行歷史：`~/.openclaw/cron/runs/<jobId>.jsonl`（JSONL，依大小和行數自動修剪）。
- `sessions.json` 中的隔離 cron 執行會話由 `cron.sessionRetention` 修剪（預設 `24h`；設為 `false` 停用）。
- 覆寫儲存路徑：設定中的 `cron.store`。

## 重試策略

當工作失敗時，OpenClaw 將錯誤分類為**暫時性**（可重試）或**永久性**（立即停用）。

### 暫時性錯誤（重試）

- 速率限制（429、too many requests、resource exhausted）
- 提供者過載（例如 Anthropic `529 overloaded_error`、過載回退摘要）
- 網路錯誤（逾時、ECONNRESET、fetch failed、socket）
- 伺服器錯誤（5xx）
- Cloudflare 相關錯誤

### 永久性錯誤（不重試）

- 驗證失敗（無效的 API 金鑰、未授權）
- 設定或驗證錯誤
- 其他非暫時性錯誤

### 預設行為（無設定）

**一次性工作（`schedule.kind: "at"`）：**

- 暫時性錯誤：以指數退避最多重試 3 次（30s → 1m → 5m）。
- 永久性錯誤：立即停用。
- 成功或跳過：停用（若 `deleteAfterRun: true` 則刪除）。

**重複工作（`cron` / `every`）：**

- 任何錯誤：在下次排程執行前套用指數退避（30s → 1m → 5m → 15m → 60m）。
- 工作保持啟用；下次成功執行後退避重置。

設定 `cron.retry` 可覆寫這些預設值（見 [設定](/zh-Hant/automation/cron-jobs#configuration)）。

## 設定

```json5
{
  cron: {
    enabled: true, // 預設 true
    store: "~/.openclaw/cron/jobs.json",
    maxConcurrentRuns: 1, // 預設 1
    // 選填：覆寫一次性工作的重試策略
    retry: {
      maxAttempts: 3,
      backoffMs: [60000, 120000, 300000],
      retryOn: ["rate_limit", "overloaded", "network", "server_error"],
    },
    webhook: "https://example.invalid/legacy", // 舊版相容的 notify:true 工作回退
    webhookToken: "replace-with-dedicated-webhook-token", // webhook 模式的選填 Bearer Token
    sessionRetention: "24h", // 時間字串或 false
    runLog: {
      maxBytes: "2mb", // 預設 2_000_000 bytes
      keepLines: 2000, // 預設 2000
    },
  },
}
```

執行日誌修剪行為：

- `cron.runLog.maxBytes`：修剪前的最大執行日誌檔案大小。
- `cron.runLog.keepLines`：修剪時只保留最新的 N 行。
- 兩者都適用於 `cron/runs/<jobId>.jsonl` 檔案。

Webhook 行為：

- 建議做法：每個工作設定 `delivery.mode: "webhook"` 和 `delivery.to: "https://..."`。
- Webhook URL 必須是有效的 `http://` 或 `https://` URL。
- 發布時，酬載為 cron 完成事件 JSON。
- 若設定了 `cron.webhookToken`，auth header 為 `Authorization: Bearer <cron.webhookToken>`。
- 若未設定 `cron.webhookToken`，則不傳送 `Authorization` header。
- 舊版相容性：設有 `notify: true` 的已儲存舊版工作在 `cron.webhook` 存在時仍使用它。

完全停用 cron：

- `cron.enabled: false`（設定）
- `OPENCLAW_SKIP_CRON=1`（環境變數）

## 維護

Cron 有兩個內建維護路徑：隔離執行會話保留和執行日誌修剪。

### 預設值

- `cron.sessionRetention`：`24h`（設為 `false` 停用執行會話修剪）
- `cron.runLog.maxBytes`：`2_000_000` bytes
- `cron.runLog.keepLines`：`2000`

### 運作方式

- 隔離執行建立會話記錄（`...:cron:<jobId>:run:<uuid>`）和逐字稿檔案。
- 清理器刪除早於 `cron.sessionRetention` 的過期執行會話記錄。
- 對已不再被會話儲存引用的已刪除執行會話，OpenClaw 歸檔逐字稿檔案，並在相同保留視窗下清除舊的已刪除歸檔。
- 每次執行追加後，`cron/runs/<jobId>.jsonl` 會進行大小檢查：
  - 若檔案大小超過 `runLog.maxBytes`，則修剪到最新的 `runLog.keepLines` 行。

### 高容量排程器的效能注意事項

高頻 cron 設定可能產生大量執行會話和執行日誌。雖然維護是內建的，但寬鬆的限制仍可能造成不必要的 IO 和清理工作。

需注意：

- 較長的 `cron.sessionRetention` 視窗搭配大量隔離執行
- 較高的 `cron.runLog.keepLines` 結合較大的 `runLog.maxBytes`
- 許多嘈雜的重複工作寫入同一個 `cron/runs/<jobId>.jsonl`

建議做法：

- 依偵錯/稽核需求盡量縮短 `cron.sessionRetention`
- 使用適中的 `runLog.maxBytes` 和 `runLog.keepLines` 限制執行日誌大小
- 將嘈雜的背景工作移到隔離模式，並設定投遞規則以避免不必要的干擾
- 定期使用 `openclaw cron runs` 檢視增長情況，並在日誌變大前調整保留設定

### 自訂範例

保留執行會話一週並允許較大的執行日誌：

```json5
{
  cron: {
    sessionRetention: "7d",
    runLog: {
      maxBytes: "10mb",
      keepLines: 5000,
    },
  },
}
```

停用隔離執行會話修剪但保留執行日誌修剪：

```json5
{
  cron: {
    sessionRetention: false,
    runLog: {
      maxBytes: "5mb",
      keepLines: 3000,
    },
  },
}
```

針對高容量 cron 使用的調整（範例）：

```json5
{
  cron: {
    sessionRetention: "12h",
    runLog: {
      maxBytes: "3mb",
      keepLines: 1500,
    },
  },
}
```

## CLI 快速指南

一次性提醒（UTC ISO，成功後自動刪除）：

```bash
openclaw cron add \
  --name "Send reminder" \
  --at "2026-01-12T18:00:00Z" \
  --session main \
  --system-event "Reminder: submit expense report." \
  --wake now \
  --delete-after-run
```

一次性提醒（主會話，立即喚醒）：

```bash
openclaw cron add \
  --name "Calendar check" \
  --at "20m" \
  --session main \
  --system-event "Next heartbeat: check calendar." \
  --wake now
```

重複隔離工作（公告到 WhatsApp）：

```bash
openclaw cron add \
  --name "Morning status" \
  --cron "0 7 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Summarize inbox + calendar for today." \
  --announce \
  --channel whatsapp \
  --to "+15551234567"
```

重複 cron 工作含明確 30 秒錯開：

```bash
openclaw cron add \
  --name "Minute watcher" \
  --cron "0 * * * * *" \
  --tz "UTC" \
  --stagger 30s \
  --session isolated \
  --message "Run minute watcher checks." \
  --announce
```

重複隔離工作（投遞到 Telegram 話題）：

```bash
openclaw cron add \
  --name "Nightly summary (topic)" \
  --cron "0 22 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Summarize today; send to the nightly topic." \
  --announce \
  --channel telegram \
  --to "-1001234567890:topic:123"
```

隔離工作含模型和思考覆寫：

```bash
openclaw cron add \
  --name "Deep analysis" \
  --cron "0 6 * * 1" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Weekly deep analysis of project progress." \
  --model "opus" \
  --thinking high \
  --announce \
  --channel whatsapp \
  --to "+15551234567"
```

Agent 選擇（多 Agent 設定）：

```bash
# 將工作固定到 "ops" Agent（若該 Agent 不存在則回退到預設）
openclaw cron add --name "Ops sweep" --cron "0 6 * * *" --session isolated --message "Check ops queue" --agent ops

# 切換或清除現有工作的 Agent
openclaw cron edit <jobId> --agent ops
openclaw cron edit <jobId> --clear-agent
```

手動執行（預設強制執行，使用 `--due` 只在到期時執行）：

```bash
openclaw cron run <jobId>
openclaw cron run <jobId> --due
```

`cron.run` 現在在手動執行排入佇列後立即確認，而非等工作完成。成功的佇列回應看起來像 `{ ok: true, enqueued: true, runId }`。若工作已在執行中或 `--due` 未找到到期工作，回應保持 `{ ok: true, ran: false, reason }`。使用 `openclaw cron runs --id <jobId>` 或 `cron.runs` Gateway 方法查看最終完成記錄。

編輯現有工作（修補欄位）：

```bash
openclaw cron edit <jobId> \
  --message "Updated prompt" \
  --model "opus" \
  --thinking low
```

強制現有 cron 工作按排程精確執行（無錯開）：

```bash
openclaw cron edit <jobId> --exact
```

執行歷史：

```bash
openclaw cron runs --id <jobId> --limit 50
```

不建立工作的立即系統事件：

```bash
openclaw system event --mode now --text "Next heartbeat: check battery."
```

## Gateway API 介面

- `cron.list`、`cron.status`、`cron.add`、`cron.update`、`cron.remove`
- `cron.run`（強制或到期）、`cron.runs`
  對於不需要工作的立即系統事件，使用 [`openclaw system event`](/zh-Hant/cli/system)。

## 疑難排解

### 「什麼都沒執行」

- 確認 cron 已啟用：`cron.enabled` 和 `OPENCLAW_SKIP_CRON`。
- 確認 Gateway 持續執行（cron 在 Gateway 程序內執行）。
- 對於 `cron` 排程：確認時區（`--tz`）與主機時區的設定。

### 重複工作在失敗後持續延遲

- OpenClaw 對重複工作在連續錯誤後套用指數重試退避：
  30s、1m、5m、15m，然後每次重試之間 60m。
- 退避在下次成功執行後自動重置。
- 一次性（`at`）工作對暫時性錯誤（速率限制、過載、網路、server_error）最多重試 3 次並退避；永久性錯誤立即停用。見 [重試策略](/zh-Hant/automation/cron-jobs#retry-policy)。

### Telegram 投遞到錯誤的地方

- 對於論壇話題，使用 `-100…:topic:<id>` 以明確且無歧義。
- 若在日誌或已儲存的「最後路由」目標中看到 `telegram:...` 前綴，這是正常的；
  cron 投遞接受它們，並仍能正確解析話題 ID。

### 子 Agent 公告投遞重試

- 當子 Agent 執行完成時，Gateway 向請求者會話公告結果。
- 若公告流程回傳 `false`（例如請求者會話繁忙），Gateway 透過 `announceRetryCount` 追蹤，最多重試 3 次。
- 早於 `endedAt` 超過 5 分鐘的公告會被強制到期，以防止過期記錄無限循環。
- 若在日誌中看到重複的公告投遞，請查看子 Agent 登錄檔中 `announceRetryCount` 值較高的記錄。
