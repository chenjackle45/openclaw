---
title: "排程任務 (Cron Jobs)"
summary: "Gateway 排程器的任務排程與喚醒機制"
read_when:
  - 安排背景任務或喚醒時
  - 設定應隨同心跳執行的自動化流程時
  - 決定何時使用心跳或排程任務時
---

# 排程任務 (Gateway 排程器)

> **Cron 還是心跳？** 見 [Cron vs Heartbeat](/automation/cron-vs-heartbeat) 瞭解何時使用各自。

Cron 是 Gateway 的內建排程器。它持久化任務，在正確的時間喚醒 Agent，並可選擇將輸出傳回聊天。

若您想要「每天早上執行這個」或「20 分鐘後戳一下 Agent」，Cron 就是機制。

## 核心重點 (TL;DR)

- Cron 在 **Gateway 內部**執行（不在模型內）。
- 任務存放在 `~/.openclaw/cron/` 下，重啟不會遺失排程。
- 兩種執行風格：
  - **主會話**：加入系統事件，在下次心跳時執行。
  - **隔離**：在 `cron:<jobId>` 中執行專屬 Agent 輪次，可選擇投遞輸出。
- 喚醒是一等公民：任務可要求「立即喚醒」或「下次心跳」。

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
openclaw cron run <job-id> --force
openclaw cron runs --id <job-id>
```

排程一個有投遞的定期隔離任務：

```bash
openclaw cron add \
  --name "Morning brief" \
  --cron "0 7 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Summarize overnight updates." \
  --deliver \
  --channel slack \
  --to "channel:C1234567890"
```

## 工具呼叫等價物 (Gateway cron tool)

對於規範的 JSON 形狀和範例，見 [JSON schema for tool calls](/automation/cron-jobs#json-schema-for-tool-calls)。

## Cron 任務的存儲位置

Cron 任務預設持久化在 Gateway 主機上的 `~/.openclaw/cron/jobs.json`。Gateway 將檔案載入記憶體並在更改時寫回，因此手動編輯僅在 Gateway 停止時安全。優先使用 `openclaw cron add/edit` 或 cron 工具呼叫 API 進行變更。

## 初學者友善的概述

將 Cron 任務想像為：**何時**執行 + **要做什麼**。

1. **選擇排程**
   - 一次性提醒 → `schedule.kind = "at"` (CLI：`--at`)
   - 定期任務 → `schedule.kind = "every"` 或 `schedule.kind = "cron"`
   - 若您的 ISO 時間戳記省略時區，會視為 **UTC**。

2. **選擇執行位置**
   - `sessionTarget: "main"` → 在下次心跳期間使用主語境執行。
   - `sessionTarget: "isolated"` → 在 `cron:<jobId>` 中執行專屬 Agent 輪次。

3. **選擇酬載**
   - 主會話 → `payload.kind = "systemEvent"`
   - 隔離會話 → `payload.kind = "agentTurn"`

選用：`deleteAfterRun: true` 在成功的一次性任務後從存儲中移除。

## 概念

### 任務

Cron 任務是一個存儲的記錄，包含：

- 一個**排程**（何時執行），
- 一個**酬載**（要做什麼），
- 選用的**投遞**（輸出應傳送到哪裡）。
- 選用的 **Agent 綁定**（`agentId`）：在特定 Agent 下執行任務；若缺失或未知，Gateway 回退到預設 Agent。

任務由穩定的 `jobId` 識別（由 CLI/Gateway API 使用）。在 Agent 工具呼叫中，`jobId` 是規範；舊版 `id` 為相容性而接受。任務可透過 `deleteAfterRun: true` 在成功的一次性執行後自動刪除。

### 排程

Cron 支援三種排程種類：

- `at`：一次性時間戳記（ms 自 epoch）。Gateway 接受 ISO 8601 並強制轉換為 UTC。
- `every`：固定間隔（ms）。
- `cron`：5 欄位 Cron 表達式，可選 IANA 時區。

Cron 表達式使用 `croner`。若省略時區，使用 Gateway 主機的本地時區。

### 主會話 vs 隔離執行

#### 主會話任務（系統事件）

主任務加入系統事件並可選擇喚醒心跳執行器。它們必須使用 `payload.kind = "systemEvent"`。

- `wakeMode: "next-heartbeat"` (預設)：事件等待下次排程的心跳。
- `wakeMode: "now"`：事件觸發立即心跳執行。

這是您想要常規心跳提示 + 主會話語境時的最佳選擇。見 [Heartbeat](/gateway/heartbeat)。

#### 隔離任務（專屬 Cron 會話）

隔離任務在會話 `cron:<jobId>` 中執行專屬 Agent 輪次。

關鍵行為：

- 提示加上 `[cron:<jobId> <job name>]` 前綴以供追蹤。
- 每次執行啟動**新會話 id**（無先前對話遺留）。
- 摘要發佈到主會話（前綴 `Cron`，可配置）。
- `wakeMode: "now"` 在發佈摘要後觸發立即心跳。
- 若 `payload.deliver: true`，輸出投遞到頻道；否則保持內部。

對於嘈雜、頻繁或「背景雜務」不應充斥主聊天歷史的任務，使用隔離任務。

### 酬載形狀（要執行什麼）

支援兩種酬載種類：

- `systemEvent`：僅限主會話，透過心跳提示路由。
- `agentTurn`：僅限隔離會話，執行專屬 Agent 輪次。

常見的 `agentTurn` 欄位：

- `message`：必要的文字提示。
- `model` / `thinking`：選用覆寫（見下方）。
- `timeoutSeconds`：選用的逾時覆寫。
- `deliver`：`true` 將輸出傳送到頻道目標。
- `channel`：`last` 或特定頻道。
- `to`：頻道特定目標（電話/聊天/頻道 ID）。
- `bestEffortDeliver`：若投遞失敗時避免任務失敗。

隔離選項（僅限 `session=isolated`）：

- `postToMainPrefix` (CLI：`--post-prefix`)：主會話中系統事件的前綴。
- `postToMainMode`：`summary` (預設) 或 `full`。
- `postToMainMaxChars`：`postToMainMode=full` 時的最大字元（預設 8000）。

### 模型和思考覆寫

隔離任務（`agentTurn`）可覆寫模型和思考等級：

- `model`：提供者/模型字串（例如 `anthropic/claude-sonnet-4-20250514`）或別名（例如 `opus`）
- `thinking`：思考等級（`off`、`minimal`、`low`、`medium`、`high`、`xhigh`；僅 GPT-5.2 + Codex 模型）

註：您也可以在主會話任務上設定 `model`，但會改變共享主會話模型。我們建議模型覆寫僅用於隔離任務，以避免意外的語境轉變。

解析優先順序：

1. 任務酬載覆寫（最高）
2. Hook 特定預設（例如 `hooks.gmail.model`）
3. Agent 配置預設

### 投遞（頻道 + 目標）

隔離任務可投遞輸出到頻道。任務酬載可指定：

- `channel`：`whatsapp` / `telegram` / `discord` / `slack` / `mattermost` (plugin) / `signal` / `imessage` / `last`
- `to`：頻道特定收件者目標

若 `channel` 或 `to` 省略，Cron 可回退到主會話的「最後路由」（Agent 最後回覆的位置）。

投遞筆記：

- 若設定 `to`，Cron 自動投遞 Agent 的最終輸出，即使 `deliver` 省略。
- 當您想要最後路由投遞而無明確 `to` 時，使用 `deliver: true`。
- 即使有 `to` 存在，使用 `deliver: false` 保持輸出內部。

目標格式提醒：

- Slack/Discord/Mattermost (plugin) 目標應使用明確前綴（例如 `channel:<id>`、`user:<id>`）以避免歧義。
- Telegram 話題應使用 `:topic:` 形式（見下方）。

#### Telegram 投遞目標（話題 / 論壇執行緒）

Telegram 透過 `message_thread_id` 支援論壇話題。對於 Cron 投遞，您可以將話題/執行緒編碼到 `to` 欄位：

- `-1001234567890` (聊天 ID 僅)
- `-1001234567890:topic:123` (優先：明確話題標記)
- `-1001234567890:123` (捷徑：數字後綴)

前綴目標如 `telegram:...` / `telegram:group:...` 也被接受：

- `telegram:group:-1001234567890:topic:123`

## 工具呼叫的 JSON Schema

在直接呼叫 Gateway `cron.*` 工具時使用這些形狀（Agent 工具呼叫或 RPC）。CLI 標記接受人類持續時間如 `20m`，但工具呼叫對 `atMs` 和 `everyMs` 使用 epoch 毫秒（`at` 時間接受 ISO 時間戳記）。

### cron.add 參數

一次性、主會話任務（系統事件）：

```json
{
  "name": "Reminder",
  "schedule": { "kind": "at", "atMs": 1738262400000 },
  "sessionTarget": "main",
  "wakeMode": "now",
  "payload": { "kind": "systemEvent", "text": "Reminder text" },
  "deleteAfterRun": true
}
```

定期、隔離任務，有投遞：

```json
{
  "name": "Morning brief",
  "schedule": { "kind": "cron", "expr": "0 7 * * *", "tz": "America/Los_Angeles" },
  "sessionTarget": "isolated",
  "wakeMode": "next-heartbeat",
  "payload": {
    "kind": "agentTurn",
    "message": "Summarize overnight updates.",
    "deliver": true,
    "channel": "slack",
    "to": "channel:C1234567890",
    "bestEffortDeliver": true
  },
  "isolation": { "postToMainPrefix": "Cron", "postToMainMode": "summary" }
}
```

筆記：

- `schedule.kind`：`at` (`atMs`)、`every` (`everyMs`) 或 `cron` (`expr`、選用 `tz`)。
- `atMs` 和 `everyMs` 是 epoch 毫秒。
- `sessionTarget` 必須是 `"main"` 或 `"isolated"` 且必須符合 `payload.kind`。
- 選用欄位：`agentId`、`description`、`enabled`、`deleteAfterRun`、`isolation`。
- `wakeMode` 省略時預設為 `"next-heartbeat"`。

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

筆記：

- `jobId` 是規範；`id` 為相容性而接受。
- 在修補程式中使用 `agentId: null` 以清除 Agent 綁定。

### cron.run 和 cron.remove 參數

```json
{ "jobId": "job-123", "mode": "force" }
```

```json
{ "jobId": "job-123" }
```

## 存儲和歷史

- 任務存儲：`~/.openclaw/cron/jobs.json` (Gateway 管理的 JSON)。
- 執行歷史：`~/.openclaw/cron/runs/<jobId>.jsonl` (JSONL，自動修剪)。
- 覆寫存儲路徑：`cron.store` 在配置中。

## 配置

```json5
{
  cron: {
    enabled: true, // default true
    store: "~/.openclaw/cron/jobs.json",
    maxConcurrentRuns: 1, // default 1
  },
}
```

完全禁用 Cron：

- `cron.enabled: false` (配置)
- `OPENCLAW_SKIP_CRON=1` (env)

## CLI 快速啟動

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

定期隔離任務（投遞到 WhatsApp）：

```bash
openclaw cron add \
  --name "Morning status" \
  --cron "0 7 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Summarize inbox + calendar for today." \
  --deliver \
  --channel whatsapp \
  --to "+15551234567"
```

定期隔離任務（投遞到 Telegram 話題）：

```bash
openclaw cron add \
  --name "Nightly summary (topic)" \
  --cron "0 22 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Summarize today; send to the nightly topic." \
  --deliver \
  --channel telegram \
  --to "-1001234567890:topic:123"
```

隔離任務，有模型和思考覆寫：

```bash
openclaw cron add \
  --name "Deep analysis" \
  --cron "0 6 * * 1" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Weekly deep analysis of project progress." \
  --model "opus" \
  --thinking high \
  --deliver \
  --channel whatsapp \
  --to "+15551234567"
```

Agent 選擇（多 Agent 設定）：

```bash
# 將任務固定到 Agent "ops"（若缺失則回退到預設）
openclaw cron add --name "Ops sweep" --cron "0 6 * * *" --session isolated --message "Check ops queue" --agent ops

# 在現有任務上切換或清除 Agent
openclaw cron edit <jobId> --agent ops
openclaw cron edit <jobId> --clear-agent
```

手動執行（除錯）：

```bash
openclaw cron run <jobId> --force
```

編輯現有任務（修補欄位）：

```bash
openclaw cron edit <jobId> \
  --message "Updated prompt" \
  --model "opus" \
  --thinking low
```

執行歷史：

```bash
openclaw cron runs --id <jobId> --limit 50
```

立即系統事件而不建立任務：

```bash
openclaw system event --mode now --text "Next heartbeat: check battery."
```

## Gateway API 表面

- `cron.list`、`cron.status`、`cron.add`、`cron.update`、`cron.remove`
- `cron.run` (force 或 due)、`cron.runs`
  對於立即系統事件而不建立任務，使用 [`openclaw system event`](/cli/system)。

## 故障排除

### 「沒有任何執行」

- 檢查 Cron 已啟用：`cron.enabled` 和 `OPENCLAW_SKIP_CRON`。
- 檢查 Gateway 持續執行中（Cron 在 Gateway 進程內執行）。
- 對於 `cron` 排程：確認時區（`--tz`）vs 主機時區。

### Telegram 投遞到錯誤位置

- 對於論壇話題，使用 `-100…:topic:<id>` 使其明確且無歧義。
- 若您在日誌或存儲的「最後路由」目標中看到 `telegram:...` 前綴，那是正常的；Cron 投遞接受它們並仍然正確解析話題 ID。
