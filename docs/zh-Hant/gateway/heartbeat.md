---
title: "heartbeat(Heartbeat)"
summary: "Heartbeat 輪詢訊息與通知規則"
read_when:
  - 調整 Heartbeat 節奏或訊息時
  - 決定在排程任務上使用 Heartbeat 或 Cron 時
---

# Heartbeat (Gateway)

> **Heartbeat vs Cron?** 請參閱 [Cron vs Heartbeat](/automation/cron-vs-heartbeat) 以取得使用時機指引。

Heartbeat 在 Main Session 中執行 **週期性的 Agent Turns**，讓模型能呈現任何需要注意的事項，而不會發送垃圾訊息給您。

## 快速開始 (新手)

1. 保持 Heartbeats 啟用 (預設為 `30m`，或在 Anthropic OAuth/setup-token 下為 `1h`) 或設定您自己的節奏。
2. 在 Agent Workspace 中建立一個小型的 `HEARTBEAT.md` Checklist (選用但推薦)。
3. 決定 Heartbeat 訊息應發送到哪裡 (`target: "last"` 為預設值)。
4. 選用: 啟用 Heartbeat Reasoning Delivery 以獲得透明度。
5. 選用: 將 Heartbeats 限制在活動時間內 (本地時間)。

設定範例:

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",
        target: "last",
        // activeHours: { start: "08:00", end: "24:00" },
        // includeReasoning: true, // optional: send separate `Reasoning:` message too
      }
    }
  }
}
```

## 預設值

- 間隔: `30m` (或當偵測到 Anthropic OAuth/setup-token 認證模式時為 `1h`)。設定 `agents.defaults.heartbeat.every` 或 Per-agent `agents.list[].heartbeat.every`；使用 `0m` 停用。
- Prompt Body (可透過 `agents.defaults.heartbeat.prompt` 設定):
  `Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.`
- Heartbeat Prompt 會 **逐字 (Verbatim)** 作為 User Message 發送。System Prompt 包含一個 “Heartbeat” 章節，且該次執行會在內部被標記。
- 活動時間 (`heartbeat.activeHours`) 依據設定的時區檢查。在視窗外，Heartbeats 會被跳過直到下一個在視窗內的 Tick。

## Heartbeat Prompt 的用途

預設 Prompt 刻意設計得較為廣泛：
- **背景任務**: “Consider outstanding tasks” 輕推 Agent 檢閱後續 (Inbox, Calendar, Reminders, Queued work) 並呈現任何緊急事項。
- **人類簽到**: “Checkup sometimes on your human during day time” 輕推偶爾的輕量級 “需要幫忙嗎?” 訊息，但透過使用您設定的本地時區避免夜間干擾 (參閱 [/concepts/timezone](/concepts/timezone))。

若您希望 Heartbeat 做非常具體的事 (例如 “檢查 Gmail PubSub 統計” 或 “驗證 Gateway 健康”)，將 `agents.defaults.heartbeat.prompt` (或 `agents.list[].heartbeat.prompt`) 設定為自訂 Body (逐字發送)。

## 回覆合約 (Response Contract)

- 若無須注意，回覆 **`HEARTBEAT_OK`**。
- 在 Heartbeat 執行期間，當 `HEARTBEAT_OK` 出現在回覆的 **開頭或結尾** 時，OpenClaw 將其視為 Ack。Token 會被移除，且若剩餘內容 **≤ `ackMaxChars`** (預設: 300) 則該回覆會被丟棄 (Dropped)。
- 若 `HEARTBEAT_OK` 出現在回覆的 **中間**，則不會被特別處理。
- 對於警報 (Alerts)，**不要** 包含 `HEARTBEAT_OK`；僅回傳警報文字。

在 Heartbeats 之外，訊息開頭/結尾的零星 `HEARTBEAT_OK` 會被移除並記錄；若訊息僅包含 `HEARTBEAT_OK` 則會被丟棄。

## 設定

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",           // default: 30m (0m disables)
        model: "anthropic/claude-opus-4-5",
        includeReasoning: false, // default: false (deliver separate Reasoning: message when available)
        target: "last",         // last | none | <channel id> (core or plugin, e.g. "bluebubbles")
        to: "+15551234567",     // optional channel-specific override
        prompt: "Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.",
        ackMaxChars: 300         // max chars allowed after HEARTBEAT_OK
      }
    }
  }
}
```

### 範圍與優先權 (Scope & Precedence)

- `agents.defaults.heartbeat` 設定全域 Heartbeat 行為。
- `agents.list[].heartbeat` 覆蓋於其上；若任何 Agent 有 `heartbeat` 區塊，**僅那些 Agents** 運行 Heartbeats。
- `channels.defaults.heartbeat` 設定所有 Channels 的可見性預設值。
- `channels.<channel>.heartbeat` 覆蓋 Channel 預設值。
- `channels.<channel>.accounts.<id>.heartbeat` (Multi-account Channels) 覆蓋 Per-channel 設定。

### Per-agent Heartbeats

若任何 `agents.list[]` 項目包含 `heartbeat` 區塊，**僅那些 Agents** 運行 Heartbeats。Per-agent 區塊合併於 `agents.defaults.heartbeat` 之上 (因此您可以設定一次共用預設值並依 Agent 覆蓋)。

範例: 兩個 Agents，僅第二個 Agent 運行 Heartbeats。

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",
        target: "last"
      }
    },
    list: [
      { id: "main", default: true },
      {
        id: "ops",
        heartbeat: {
          every: "1h",
          target: "whatsapp",
          to: "+15551234567",
          prompt: "Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK."
        }
      }
    ]
  }
}
```

### 現場筆記 (Field Notes)

- `every`: Heartbeat 間隔 (Duration String; 預設單位 = 分鐘)。
- `model`: Heartbeat 執行的選用模型覆蓋 (`provider/model`)。
- `includeReasoning`: 啟用時，若可用亦傳送分開的 `Reasoning:` 訊息 (與 `/reasoning on` 形狀相同)。
- `session`: Heartbeat 執行的選用 Session Key。
  - `main` (預設): Agent Main Session。
  - 顯式 Session Key (從 `openclaw sessions --json` 或 [sessions CLI](/cli/sessions) 複製)。
  - Session Key 格式: 參閱 [Sessions](/concepts/session) 與 [Groups](/concepts/groups)。
- `target`:
  - `last` (預設): 傳送至該 Session 最後使用的外部 Channel。
  - 顯式 Channel: `whatsapp` / `telegram` / `discord` / `googlechat` / `slack` / `msteams` / `signal` / `imessage`。
  - `none`: 運行 Heartbeat 但 **不傳送** 至外部。
- `to`: 選用的接收者覆蓋 (Channel-specific ID, 例如 WhatsApp 的 E.164 或 Telegram Chat ID)。
- `prompt`: 覆蓋預設 Prompt Body (不合併)。
- `ackMaxChars`: 在 `HEARTBEAT_OK` 後允許的最大字元數，超過則傳送。

## 傳送行為

- Heartbeats 預設在 Agent 的 Main Session (`agent:<id>:<mainKey>`) 中運行，或當 `session.scope = "global"` 時在 `global` 中運行。設定 `session` 以覆蓋至特定 Channel Session (Discord/WhatsApp/etc.)。
- `session` 僅影響執行 Context；傳送由 `target` 與 `to` 控制。
- 要傳送至特定 Channel/接收者，設定 `target` + `to`。使用 `target: "last"` 時，傳送使用該 Session 最後的外部 Channel。
- 若 Main Queue 忙碌，Heartbeat 會被跳過並稍後重試。
- 若 `target` 解析不到外部目的地，執行仍會發生但不會發送 Outbound 訊息。
- 僅 Heartbeat 的回覆 **不** 保持 Session 存活 (Keep Alive)；最後的 `updatedAt` 會被還原，因此閒置過期行為正常運作。

## 可見性控制 (Visibility Controls)

預設情況下，`HEARTBEAT_OK` 確認會被抑制，而 Alert內容會被傳送。您可以依 Channel 或依 Account 調整此行為：

```yaml
channels:
  defaults:
    heartbeat:
      showOk: false      # 隱藏 HEARTBEAT_OK (預設)
      showAlerts: true   # 顯示警報訊息 (預設)
      useIndicator: true # 發出 Indicator Events (預設)
  telegram:
    heartbeat:
      showOk: true       # 在 Telegram 上顯示 OK 確認
  whatsapp:
    accounts:
      work:
        heartbeat:
          showAlerts: false # 僅針對此 Account 抑制警報傳送
```

優先權: Per-account → Per-channel → Channel Defaults → Built-in Defaults。

### 各 Flag 的作用

- `showOk`: 當模型回傳 OK-only 回覆時發送 `HEARTBEAT_OK` 確認。
- `showAlerts`: 當模型回傳 Non-OK 回覆時發送 Alert 內容。
- `useIndicator`: 為 UI Status Surfaces 發出 Indicator Events (例如 macOS App 狀態燈)。

若 **三者皆為** False，OpenClaw 完全跳過 Heartbeat 執行 (無 Model Call)。

### Per-channel vs Per-account 範例

```yaml
channels:
  defaults:
    heartbeat:
      showOk: false
      showAlerts: true
      useIndicator: true
  slack:
    heartbeat:
      showOk: true # all Slack accounts
    accounts:
      ops:
        heartbeat:
          showAlerts: false # suppress alerts for the ops account only
  telegram:
    heartbeat:
      showOk: true
```

### 常見模式

| 目標 | Config |
| --- | --- |
| 預設行為 (OKs 靜音, Alerts 開啟) | *(無需 Config)* |
| 完全靜音 (無訊息, 無 Indicator) | `channels.defaults.heartbeat: { showOk: false, showAlerts: false, useIndicator: false }` |
| 僅 Indicator (無訊息) | `channels.defaults.heartbeat: { showOk: false, showAlerts: false, useIndicator: true }` |
| 僅在一個 Channel 顯示 OKs | `channels.telegram.heartbeat: { showOk: true }` |

## HEARTBEAT.md (選用)

若 Workspace 中存在 `HEARTBEAT.md` 檔案，預設 Prompt 會告訴 Agent 去讀取它。將其視為您的 “Heartbeat Checklist”：小型、穩定且每 30 分鐘包含一次是安全的。

若 `HEARTBEAT.md` 存在但實際上是空的 (僅有空白行與 Markdown Headers 如 `# Heading`)，OpenClaw 跳過 Heartbeat 執行以節省 API Calls。若檔案遺失，Heartbeat 仍會運行並由模型決定做什麼。

保持它微型 (簡短 Checklist 或提醒) 以避免 Prompt Bloat。

`HEARTBEAT.md` 範例:

```md
# Heartbeat checklist

- Quick scan: anything urgent in inboxes?
- If it’s daytime, do a lightweight check-in if nothing else is pending.
- If a task is blocked, write down *what is missing* and ask Peter next time.
```

### Agent 可以更新 HEARTBEAT.md 嗎？

可以 — 若您要求它。

`HEARTBEAT.md` 只是 Agent Workspace 中的普通檔案，所以您可以 (在一般聊天中) 告訴 Agent 類似：
- “更新 `HEARTBEAT.md` 以新增每日行事曆檢查。”
- “重寫 `HEARTBEAT.md` 讓它更短並專注於 Inbox Follow-ups。”

若您希望這主動發生，您也可以在 Heartbeat Prompt 中包含明確的一行，如：“If the checklist becomes stale, update HEARTBEAT.md with a better one.”

安全註記: 不要將機密 (API keys, phone numbers, private tokens) 放進 `HEARTBEAT.md` — 它會成為 Prompt Context 的一部份。

## 手動喚醒 (On-demand)

您可以透過以下指令將 System Event 排入佇列並觸發立即的 Heartbeat：

```bash
openclaw system event --text "Check for urgent follow-ups" --mode now
```

若設定了多個 Agents 有 `heartbeat`，手動喚醒會立即運行每個 Agent 的 Heartbeat。

使用 `--mode next-heartbeat` 以等待下一個排程 Tick。

## Reasoning Delivery (選用)

預設情況下，Heartbeats 僅傳送最終的 “Answer” Payload。

若您想要透明度，啟用：
- `agents.defaults.heartbeat.includeReasoning: true`

啟用時，Heartbeats 亦會傳送以 `Reasoning:` 為前綴的分開訊息 (與 `/reasoning on` 形狀相同)。當 Agent 管理多個 Sessions/Codexes 且您想看它為何決定 Ping 您時很有用 — 但這也可能洩漏比您想要的更多內部細節。建議在群組聊天中保持關閉。

## 成本意識

Heartbeats 運行完整的 Agent Turns。較短的間隔消耗更多 Tokens。若您僅想要內部狀態更新，保持 `HEARTBEAT.md` 小型並考慮較便宜的 `model` 或 `target: "none"`。
