---
summary: "Gateway 排程器的 Cron 工作和喚醒"
read_when:
  - Scheduling background jobs or wakeups
  - Wiring automation that should run with or alongside heartbeats
  - Deciding between heartbeat and cron for scheduled tasks
title: "Cron Jobs（Cron 排程工作）"
---

# Cron jobs (Gateway scheduler)

> **Cron vs Heartbeat?** See [Cron vs Heartbeat](/zh-Hant/automation/cron-vs-heartbeat) for guidance on when to use each.

Cron 是 Gateway 的內建排程器。它保留工作、在正確的時間喚醒代理程式，並可選擇性地將輸出傳回聊天。

如果您想要「每天早上執行」或「20 分鐘後提醒代理程式」，
cron 就是所需的機制。

疑難排解：[/automation/troubleshooting](/zh-Hant/automation/troubleshooting)

## TL;DR

- Cron 在 **Gateway 內執行**（不在模型內）。
- 工作在 `~/.openclaw/cron/` 下保留，因此重新啟動不會遺失排程。
- 兩種執行樣式：
  - **Main session**：加入系統事件，然後在下次 heartbeat 上執行。
  - **Isolated**：在 `cron:<jobId>` 或自訂 session 中執行專用代理程式回合，具有傳遞方式（預設宣告或無）。
  - **Current session**：繫結至建立 cron 的 session（`sessionTarget: "current"`）。
  - **Custom session**：在持久具名 session 中執行（`sessionTarget: "session:custom-id"`）。
- Wakeups 是一流的：工作可以要求「立即喚醒」或「下次 heartbeat」。
- Webhook 發佈是按工作進行的，經由 `delivery.mode = "webhook"` + `delivery.to = "<url>"`。
- 當 `cron.webhook` 設定時，舊版回退仍保留具有 `notify: true` 的儲存工作，將這些工作遷移至 webhook 傳遞模式。
- 若要升級，`openclaw doctor --fix` 可在排程器接觸之前正規化舊版 cron 存放區欄位。

## Quick start (actionable)

建立一次性提醒、驗證其存在，然後立即執行：

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

排程具有傳遞的循環隔離工作：

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

## Tool-call equivalents (Gateway cron tool)

如需規範的 JSON 形狀和範例，請參閱[工具呼叫的 JSON 架構](/zh-Hant/automation/cron-jobs#json-schema-for-tool-calls)。

## Where cron jobs are stored

Cron 工作預設在 `~/.openclaw/cron/jobs.json` 的 Gateway 主機上持久保存。
Gateway 會將檔案載入記憶體，並在變更時將其寫回，因此手動編輯
只有在 Gateway 停止時才安全。偏好使用 `openclaw cron add/edit` 或 cron
工具呼叫 API 進行變更。

## Beginner-friendly overview

將 cron 工作視為：**何時**執行 + **執行什麼**。

1. **選擇排程**
   - 一次性提醒 → `schedule.kind = "at"`（CLI：`--at`）
   - 重複工作 → `schedule.kind = "every"` 或 `schedule.kind = "cron"`
   - 如果您的 ISO 時間戳記省略了時區，它將被視為 **UTC**。

2. **選擇執行位置**
   - `sessionTarget: "main"` → 在下次 heartbeat 期間以 main 內容執行。
   - `sessionTarget: "isolated"` → 在 `cron:<jobId>` 中執行專用代理程式回合。
   - `sessionTarget: "current"` → 繫結至目前 session（在建立時解析為 `session:<sessionKey>`）。
   - `sessionTarget: "session:custom-id"` → 在持久具名 session 中執行，跨回合維持內容。

   預設行為（未變更）：
   - `systemEvent` 承載預設為 `main`
   - `agentTurn` 承載預設為 `isolated`

   若要使用目前 session 繫結，明確設定 `sessionTarget: "current"`。

3. **選擇承載**
   - Main session → `payload.kind = "systemEvent"`
   - Isolated session → `payload.kind = "agentTurn"`

選用：一次性工作（`schedule.kind = "at"`）預設在成功後刪除。設定
`deleteAfterRun: false` 來保留它們（它們會在成功後停用）。

## Concepts

### Jobs

Cron 工作是具有以下內容的儲存記錄：

- 一個 **schedule**（何時應該執行），
- 一個 **payload**（應該執行什麼），
- 選用的 **delivery mode**（`announce`、`webhook` 或 `none`）。
- 選用的 **agent binding**（`agentId`）：在特定代理程式下執行工作；如果
  缺失或未知，gateway 會回退至預設代理程式。

工作由穩定的 `jobId` 識別（用於 CLI/Gateway API）。
在代理程式工具呼叫中，`jobId` 是規範的；舊版 `id` 可接受以相容。
一次性工作預設在成功後自動刪除；設定 `deleteAfterRun: false` 來保留它們。

### Schedules

Cron 支援三種排程類型：

- `at`：經由 `schedule.at`（ISO 8601）的一次性時間戳記。
- `every`：固定間隔（毫秒）。
- `cron`：5 欄位 cron 運算式（或帶秒數的 6 欄位）搭配選用的 IANA 時區。

Cron 運算式使用 `croner`。如果省略了時區，Gateway 主機的
本地時區將被使用。

為了減少許多 gateway 之間的整點時間尖峰負載，OpenClaw 會應用
確定性的按工作錯開視窗（最多 5 分鐘）用於循環
整點運算式（例如 `0 * * * *`、`0 */2 * * *`）。固定小時
運算式（如 `0 7 * * *`）保持精確。

對於任何 cron 排程，您可以使用 `schedule.staggerMs` 設定明確的錯開視窗
（`0` 保持精確時間）。CLI 快速鍵：

- `--stagger 30s`（或 `1m`、`5m`）來設定明確的錯開視窗。
- `--exact` 來強制 `staggerMs = 0`。

### Main vs isolated execution

#### Main session jobs (system events)

Main 工作加入系統事件並選用性地喚醒 heartbeat 執行器。
它們必須使用 `payload.kind = "systemEvent"`。

- `wakeMode: "now"`（預設）：事件觸發立即 heartbeat 執行。
- `wakeMode: "next-heartbeat"`：事件等待下次排定的 heartbeat。

當您想要正常 heartbeat 提示 + main-session 內容時，這是最佳選擇。
請參閱 [Heartbeat](/zh-Hant/gateway/heartbeat)。

#### Isolated jobs (dedicated cron sessions)

隔離的工作在 session `cron:<jobId>` 或自訂 session 中執行專用代理程式回合。

主要行為：

- 提示的字首為 `[cron:<jobId> <job name>]` 以供追蹤。
- 每次執行都開始一個**新的 session id**（沒有先前的交談進行），除非使用自訂 session。
- 自訂 session（`session:xxx`）跨執行保留內容，啟用如每日站立會議等工作流程，該工作流程建立在先前的摘要之上。
- 預設行為：如果省略了 `delivery`，隔離工作會宣告摘要（`delivery.mode = "announce"`）。
- `delivery.mode` 選擇會發生什麼：
  - `announce`：將摘要傳遞至目標頻道，並發佈簡短摘要至 main session。
  - `webhook`：完成事件時將完成事件承載 POST 至 `delivery.to`（當完成事件包含摘要時）。
  - `none`：僅限內部（無傳遞、無 main-session 摘要）。
- `wakeMode` 控制 main-session 摘要何時發佈：
  - `now`：立即 heartbeat。
  - `next-heartbeat`：等待下次排定的 heartbeat。

使用隔離工作進行嘈雜、頻繁或「後台雜務」，不應洩漏
您的 main 聊天記錄。

### Payload shapes (what runs)

支援兩種承載類型：

- `systemEvent`：僅 main-session，經由 heartbeat 提示路由。
- `agentTurn`：僅隔離 session，執行專用代理程式回合。

常見的 `agentTurn` 欄位：

- `message`：必要的文字提示。
- `model` / `thinking`：選用的覆蓋（請參閱下方）。
- `timeoutSeconds`：選用的逾時覆蓋。
- `lightContext`：選用的輕量級啟動程序模式，用於不需要工作區啟動程序檔案注入的工作。

傳遞設定：

- `delivery.mode`：`none` | `announce` | `webhook`。
- `delivery.channel`：`last` 或特定頻道。
- `delivery.to`：特定頻道目標（宣告）或 webhook URL（webhook 模式）。
- `delivery.bestEffort`：如果宣告傳遞失敗，避免工作失敗。

宣告傳遞會禁止該執行的傳訊工具傳送；改為使用 `delivery.channel`/`delivery.to`
來設定目標聊天。當 `delivery.mode = "none"` 時，沒有摘要發佈至 main session。

如果為隔離工作省略了 `delivery`，OpenClaw 預設為 `announce`。

#### Announce delivery flow

當 `delivery.mode = "announce"` 時，cron 直接經由出站頻道配接器傳遞。
不會啟動 main 代理程式來製作或轉發訊息。

行為詳細資料：

- 內容：傳遞使用隔離執行的出站承載（文字/媒體），搭配正常分段和
  頻道格式設定。
- Heartbeat 唯一的回應（`HEARTBEAT_OK` 沒有實際內容）不會傳遞。
- 如果隔離執行已透過訊息工具傳送訊息至相同目標，傳遞會
  跳過以避免重複。
- 缺失或無效的傳遞目標會使工作失敗，除非 `delivery.bestEffort = true`。
- 簡短摘要只有在 `delivery.mode = "announce"` 時才會發佈至 main session。
- main-session 摘要遵重 `wakeMode`：`now` 觸發立即 heartbeat，
  `next-heartbeat` 等待下次排定的 heartbeat。

#### Webhook delivery flow

當 `delivery.mode = "webhook"` 時，cron 在完成事件包含摘要時將完成事件承載發佈至 `delivery.to`。

行為詳細資料：

- 端點必須是有效的 HTTP(S) URL。
- 在 webhook 模式中不會嘗試進行頻道傳遞。
- 在 webhook 模式中不會將 main-session 摘要發佈。
- 如果設定了 `cron.webhookToken`，授權標頭為 `Authorization: Bearer <cron.webhookToken>`。
- 已棄用的回退：具有 `notify: true` 的儲存舊版工作仍會發佈至 `cron.webhook`（如已設定），並發出警告以便您可以遷移至 `delivery.mode = "webhook"`。

### Model and thinking overrides

隔離工作（`agentTurn`）可以覆蓋模型和思考層級：

- `model`：提供者/模型字串（例如，`anthropic/claude-sonnet-4-20250514`）或別名（例如，`opus`）
- `thinking`：思考層級（`off`、`minimal`、`low`、`medium`、`high`、`xhigh`；僅限 GPT-5.2 + Codex 模型）

注意：您也可以在 main-session 工作上設定 `model`，但它會變更共用 main
session 模型。我們建議模型覆蓋只用於隔離工作，以避免
非預期的內容轉變。

解析優先順序：

1. 工作承載覆蓋（最高）
2. Hook 特定預設值（例如，`hooks.gmail.model`）
3. 代理程式設定預設

### Lightweight bootstrap context

隔離工作（`agentTurn`）可以設定 `lightContext: true` 來使用輕量級啟動程序內容執行。

- 用於不需要工作區啟動程序檔案注入的排定雜務。
- 實際上，嵌入式執行時會使用 `bootstrapContextMode: "lightweight"` 執行，目的上會讓 cron 啟動程序內容保持為空。
- CLI 對應項：`openclaw cron add --light-context ...` 和 `openclaw cron edit --light-context`。

### Delivery (channel + target)

隔離工作可以經由頂層 `delivery` 設定將輸出傳遞至頻道：

- `delivery.mode`：`announce`（頻道傳遞）、`webhook`（HTTP POST）或 `none`。
- `delivery.channel`：`whatsapp` / `telegram` / `discord` / `slack` / `signal` / `imessage` / `irc` / `googlechat` / `line` / `last`，加上擴充頻道如 `msteams` / `mattermost`（外掛程式）。
- `delivery.to`：特定頻道收件者目標。

`announce` 傳遞只對隔離工作有效（`sessionTarget: "isolated"`）。
`webhook` 傳遞對 main 和隔離工作都有效。

如果省略了 `delivery.channel` 或 `delivery.to`，cron 可以回退至 main session 的
「最後路由」（代理程式最後回覆的地方）。

目標格式提醒：

- Slack/Discord/Mattermost（外掛程式）目標應使用明確的字首（例如 `channel:<id>`、`user:<id>`）以避免歧義。
  Mattermost 純 26 字元 ID 會解析為**使用者優先**（如果使用者存在則為 DM，否則為頻道）— 使用 `user:<id>` 或 `channel:<id>` 以進行確定性路由。
- Telegram 主題應使用 `:topic:` 形式（請參閱下方）。

#### Telegram delivery targets (topics / forum threads)

Telegram 支援經由 `message_thread_id` 的論壇主題。若要進行 cron 傳遞，您可以將
主題/執行緒編碼至 `to` 欄位：

- `-1001234567890`（僅聊天 id）
- `-1001234567890:topic:123`（偏好：明確主題標記）
- `-1001234567890:123`（速記：數值後綴）

前綴目標如 `telegram:...` / `telegram:group:...` 也可接受：

- `telegram:group:-1001234567890:topic:123`

## JSON schema for tool calls

在直接呼叫 Gateway `cron.*` 工具時使用這些形狀（代理程式工具呼叫或 RPC）。
CLI 旗標接受人類持續時間，如 `20m`，但工具呼叫應對 `schedule.at` 使用 ISO 8601 字串
且對 `schedule.everyMs` 使用毫秒。

### cron.add params

一次性、main session 工作（系統事件）：

\`\`\`json
{
"name": "Reminder",
"schedule": { "kind": "at", "at": "2026-02-01T16:00:00Z" },
"sessionTarget": "main",
"wakeMode": "now",
"payload": { "kind": "systemEvent", "text": "Reminder text" },
"deleteAfterRun": true
}
\`\`\`

循環、隔離工作搭配傳遞：

\`\`\`json
{
"name": "Morning brief",
"schedule": { "kind": "cron", "expr": "0 7 \* \* \*", "tz": "America/Los_Angeles" },
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
\`\`\`

循環工作繫結至目前 session（在建立時自動解析）：

\`\`\`json
{
"name": "Daily standup",
"schedule": { "kind": "cron", "expr": "0 9 \* \* \*" },
"sessionTarget": "current",
"payload": {
"kind": "agentTurn",
"message": "Summarize yesterday's progress."
}
}
\`\`\`

循環工作在自訂持久 session 中：

\`\`\`json
{
"name": "Project monitor",
"schedule": { "kind": "every", "everyMs": 300000 },
"sessionTarget": "session:project-alpha-monitor",
"payload": {
"kind": "agentTurn",
"message": "Check project status and update the running log."
}
}
\`\`\`

備註：

- \`schedule.kind\`：\`at\`（\`at\`）、\`every\`（\`everyMs\`）或 \`cron\`（\`expr\`、選用 \`tz\`）。
- \`schedule.at\` 接受 ISO 8601。沒有時區的工具/API 值被視為 UTC；CLI 也接受 \`openclaw cron add|edit --at "<offset-less-iso>" --tz <iana>\` 用於本地掛鐘一次性時間。
- \`everyMs\` 是毫秒。
- \`sessionTarget\`：\`"main"\`、\`"isolated"\`、\`"current"\` 或 \`"session:<custom-id>"\`。
- \`"current"\` 在建立時解析為 \`"session:<sessionKey>"\`。
- 自訂 session（\`session:xxx\`）跨執行維持持久內容。
- 選用欄位：\`agentId\`、\`description\`、\`enabled\`、\`deleteAfterRun\`（對 \`at\` 預設為 true），
  \`delivery\`。
- \`wakeMode\` 省略時預設為 \`"now"\`。

### cron.update params

\`\`\`json
{
"jobId": "job-123",
"patch": {
"enabled": false,
"schedule": { "kind": "every", "everyMs": 3600000 }
}
}
\`\`\`

備註：

- \`jobId\` 是規範的；\`id\` 可接受以相容。
- 在修補程式中使用 \`agentId: null\` 來清除代理程式繫結。

### cron.run and cron.remove params

\`\`\`json
{ "jobId": "job-123", "mode": "force" }
\`\`\`

\`\`\`json
{ "jobId": "job-123" }
\`\`\`

## Storage & history

- 工作存放區：\`~/.openclaw/cron/jobs.json\`（Gateway 管理的 JSON）。
- 執行歷記錄：\`~/.openclaw/cron/runs/<jobId>.jsonl\`（JSONL、按大小和行數自動修剪）。
- \`sessions.json\` 中的隔離 cron 執行 session 會由 \`cron.sessionRetention\` 修剪（預設 \`24h\`；設定 \`false\` 以停用）。
- 覆蓋存放區路徑：config 中的 \`cron.store\`。

## Retry policy

工作失敗時，OpenClaw 會將錯誤分類為**暫時性**（可重試）或**永久性**（立即停用）。

### Transient errors (retried)

- 速率限制（429、要求太多、資源已用盡）
- 提供者超載（例如 Anthropic \`529 overloaded_error\`、超載回退摘要）
- 網路錯誤（逾時、ECONNRESET、提取失敗、通訊端）
- 伺服器錯誤（5xx）
- Cloudflare 相關錯誤

### Permanent errors (no retry)

- 驗證失敗（無效 API 金鑰、未授權）
- Config 或驗證錯誤
- 其他非暫時性錯誤

### Default behavior (no config)

**一次性工作（\`schedule.kind: "at"\`）：**

- 暫時性錯誤時：重試最多 3 次搭配指數反退時間（30s → 1m → 5m）。
- 永久性錯誤時：立即停用。
- 成功或略過時：停用（或如果 \`deleteAfterRun: true\` 則刪除）。

**循環工作（\`cron\` / \`every\`）：**

- 任何錯誤時：在下次排定執行之前應用指數反退時間（30s → 1m → 5m → 15m → 60m）。
- 工作保持啟用；反退時間在下次成功執行後重置。

設定 \`cron.retry\` 來覆蓋這些預設值（請參閱[設定](/zh-Hant/automation/cron-jobs#configuration)）。

## Configuration

\`\`\`json5
{
cron: {
enabled: true, // default true
store: "~/.openclaw/cron/jobs.json",
maxConcurrentRuns: 1, // default 1
// Optional: override retry policy for one-shot jobs
retry: {
maxAttempts: 3,
backoffMs: [60000, 120000, 300000],
retryOn: ["rate_limit", "overloaded", "network", "server_error"],
},
webhook: "https://example.invalid/legacy", // deprecated fallback for stored notify:true jobs
webhookToken: "replace-with-dedicated-webhook-token", // optional bearer token for webhook mode
sessionRetention: "24h", // duration string or false
runLog: {
maxBytes: "2mb", // default 2_000_000 bytes
keepLines: 2000, // default 2000
},
},
}
\`\`\`

執行日誌修剪行為：

- \`cron.runLog.maxBytes\`：執行日誌檔案大小上限，超過後修剪。
- \`cron.runLog.keepLines\`：修剪時，僅保留最新的 N 行。
- 兩者都適用於 \`cron/runs/<jobId>.jsonl\` 檔案。

Webhook 行為：

- 偏好：為每個工作設定 \`delivery.mode: "webhook"\` 搭配 \`delivery.to: "https://..."\`。
- Webhook URL 必須是有效的 \`http://\` 或 \`https://\` URL。
- 發佈時，承載是 cron 完成事件 JSON。
- 如果設定了 \`cron.webhookToken\`，授權標頭為 \`Authorization: Bearer <cron.webhookToken>\`。
- 如果未設定 \`cron.webhookToken\`，不會傳送 \`Authorization\` 標頭。
- 已棄用的回退：具有 \`notify: true\` 的儲存舊版工作仍在存在時使用 \`cron.webhook\`。

完全停用 cron：

- \`cron.enabled: false\`（config）
- \`OPENCLAW_SKIP_CRON=1\`（env）

## Maintenance

Cron 有兩個內建的維護路徑：隔離執行 session 保留和執行日誌修剪。

### Defaults

- \`cron.sessionRetention\`：\`24h\`（設定 \`false\` 以停用執行 session 修剪）
- \`cron.runLog.maxBytes\`：\`2_000_000\` 位元組
- \`cron.runLog.keepLines\`：\`2000\`

### How it works

- 隔離執行會建立 session 項目（\`...:cron:<jobId>:run:<uuid>\`）和文字記錄檔。
- 清除程式會移除舊於 \`cron.sessionRetention\` 的過期執行 session 項目。
- 對於不再由 session 存放區參考的已移除執行 session，OpenClaw 會封存文字記錄檔並清除舊已刪除封存（於相同保留視窗上）。
- 每次執行附加後，\`cron/runs/<jobId>.jsonl\` 會進行大小檢查：
  - 如果檔案大小超過 \`runLog.maxBytes\`，它會修剪至最新的 \`runLog.keepLines\` 行。

### Performance caveat for high volume schedulers

高頻率 cron 設定會產生大型執行 session 和執行日誌佔用。維護是內建的，但鬆散的限制仍可以建立可避免的 IO 和清理工作。

注意：

- 有許多隔離執行的長 \`cron.sessionRetention\` 視窗
- 高 \`cron.runLog.keepLines\` 結合大型 \`runLog.maxBytes\`
- 許多寫入相同 \`cron/runs/<jobId>.jsonl\` 的嘈雜循環工作

要做的：

- 保持 \`cron.sessionRetention\` 儘可能短以滿足您的偵錯/稽核需要
- 使用適度的 \`runLog.maxBytes\` 和 \`runLog.keepLines\` 保持執行日誌有界限
- 將嘈雜的背景工作移至隔離模式，搭配避免不必要雜務的傳遞規則
- 使用 \`openclaw cron runs\` 定期檢查增長並在日誌變大之前調整保留

### Customize examples

保留執行 session 一週並允許更大型的執行日誌：

\`\`\`json5
{
cron: {
sessionRetention: "7d",
runLog: {
maxBytes: "10mb",
keepLines: 5000,
},
},
}
\`\`\`

停用隔離執行 session 修剪，但保留執行日誌修剪：

\`\`\`json5
{
cron: {
sessionRetention: false,
runLog: {
maxBytes: "5mb",
keepLines: 3000,
},
},
}
\`\`\`

針對高容量 cron 使用進行調整（範例）：

\`\`\`json5
{
cron: {
sessionRetention: "12h",
runLog: {
maxBytes: "3mb",
keepLines: 1500,
},
},
}
\`\`\`

## CLI quickstart

一次性提醒（UTC ISO、成功後自動刪除）：

\`\`\`bash
openclaw cron add \
 --name "Send reminder" \
 --at "2026-01-12T18:00:00Z" \
 --session main \
 --system-event "Reminder: submit expense report." \
 --wake now \
 --delete-after-run
\`\`\`

一次性提醒（main session、立即喚醒）：

\`\`\`bash
openclaw cron add \
 --name "Calendar check" \
 --at "20m" \
 --session main \
 --system-event "Next heartbeat: check calendar." \
 --wake now
\`\`\`

循環隔離工作（宣告至 WhatsApp）：

\`\`\`bash
openclaw cron add \
 --name "Morning status" \
 --cron "0 7 \* \* \*" \
 --tz "America/Los_Angeles" \
 --session isolated \
 --message "Summarize inbox + calendar for today." \
 --announce \
 --channel whatsapp \
 --to "+15551234567"
\`\`\`

具有明確 30 秒錯開的循環 cron 工作：

\`\`\`bash
openclaw cron add \
 --name "Minute watcher" \
 --cron "0 \* \* \* \* \*" \
 --tz "UTC" \
 --stagger 30s \
 --session isolated \
 --message "Run minute watcher checks." \
 --announce
\`\`\`

循環隔離工作（傳遞至 Telegram 主題）：

\`\`\`bash
openclaw cron add \
 --name "Nightly summary (topic)" \
 --cron "0 22 \* \* \*" \
 --tz "America/Los_Angeles" \
 --session isolated \
 --message "Summarize today; send to the nightly topic." \
 --announce \
 --channel telegram \
 --to "-1001234567890:topic:123"
\`\`\`

隔離工作搭配模型和思考覆蓋：

\`\`\`bash
openclaw cron add \
 --name "Deep analysis" \
 --cron "0 6 \* \* 1" \
 --tz "America/Los_Angeles" \
 --session isolated \
 --message "Weekly deep analysis of project progress." \
 --model "opus" \
 --thinking high \
 --announce \
 --channel whatsapp \
 --to "+15551234567"
\`\`\`

代理程式選擇（多代理程式設定）：

\`\`\`bash

# Pin a job to agent "ops" (falls back to default if that agent is missing)

openclaw cron add --name "Ops sweep" --cron "0 6 \* \* \*" --session isolated --message "Check ops queue" --agent ops

# Switch or clear the agent on an existing job

openclaw cron edit <jobId> --agent ops
openclaw cron edit <jobId> --clear-agent
\`\`\`

手動執行（強制是預設值，使用 \`--due\` 只在到期時執行）：

\`\`\`bash
openclaw cron run <jobId>
openclaw cron run <jobId> --due
\`\`\`

\`cron.run\` 現在在手動執行加入佇列時確認，不是在工作完成後。成功的佇列回應看起來像 \`{ ok: true, enqueued: true, runId }\`。如果工作已在執行或 \`--due\` 找不到應到期的項目，回應保持 \`{ ok: true, ran: false, reason }\`。使用 \`openclaw cron runs --id <jobId>\` 或 \`cron.runs\` gateway 方法來檢查最終完成的項目。

編輯現有工作（修補欄位）：

\`\`\`bash
openclaw cron edit <jobId> \
 --message "Updated prompt" \
 --model "opus" \
 --thinking low
\`\`\`

強制現有 cron 工作在排定時間上正確執行（無錯開）：

\`\`\`bash
openclaw cron edit <jobId> --exact
\`\`\`

執行歷記錄：

\`\`\`bash
openclaw cron runs --id <jobId> --limit 50
\`\`\`

立即系統事件，無需建立工作：

\`\`\`bash
openclaw system event --mode now --text "Next heartbeat: check battery."
\`\`\`

## Gateway API surface

- \`cron.list\`、\`cron.status\`、\`cron.add\`、\`cron.update\`、\`cron.remove\`
- \`cron.run\`（強制或到期）、\`cron.runs\`
  若要進行立即系統事件，無需工作，請使用 [\`openclaw system event\`](/zh-Hant/cli/system)。

## Troubleshooting

### "Nothing runs"

- 檢查 cron 已啟用：\`cron.enabled\` 和 \`OPENCLAW_SKIP_CRON\`。
- 檢查 Gateway 連續執行（cron 在 Gateway 程序內執行）。
- 對於 \`cron\` 排程：確認時區（\`--tz\`）對比主機時區。

### A recurring job keeps delaying after failures

- OpenClaw 在連續錯誤後對循環工作應用指數重試反退：
  30s、1m、5m、15m，然後 60m 在重試之間。
- 反退時間在下次成功執行後自動重置。
- 一次性（\`at\`）工作重試暫時性錯誤（速率限制、超載、網路、server_error）最多 3 次搭配反退；永久性錯誤立即停用。請參閱[重試原則](/zh-Hant/automation/cron-jobs#retry-policy)。

### Telegram delivers to the wrong place

- 對於論壇主題，使用 \`-100…:topic:<id>\` 以便明確且不明確。
- 如果您在日誌或儲存「最後路由」目標中看到 \`telegram:...\` 字首，那是正常的；
  cron 傳遞接受它們，並且仍可正確解析主題 ID。

### Subagent announce delivery retries

- 子代理程式執行完成時，gateway 會宣告結果至要求者 session。
- 如果宣告流程傳回 \`false\`（例如要求者 session 繁忙），gateway 會使用 \`announceRetryCount\` 的追蹤重試最多 3 次。
- 宣告舊於 5 分鐘經過 \`endedAt\` 會被強制過期，以防止舊項目無限迴圈。
- 如果您在日誌中看到重複宣告傳遞，檢查子代理程式登錄以取得具有高 \`announceRetryCount\` 值的項目。
