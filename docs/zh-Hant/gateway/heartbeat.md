---
summary: "Heartbeat 輪詢訊息與通知規則"
read_when:
  - 調整 Heartbeat 節奏或訊息時
  - 決定在排程任務上使用 Heartbeat 或 Cron 時
title: "Heartbeat（心跳偵測）"
---

# Heartbeat（Gateway）

> **Heartbeat 對比 Cron？** 請參閱 [Cron vs Heartbeat](/zh-Hant/automation/cron-vs-heartbeat) 了解各自適用情境的指引。

Heartbeat 在主 session 中執行**定期 Agent 輪次**，讓模型可以主動回報需要注意的事項，而不會對您造成困擾。

故障排除：[/automation/troubleshooting](/zh-Hant/automation/troubleshooting)

## 快速開始（初學者）

1. 保持 heartbeat 啟用（預設為 `30m`，或 Anthropic OAuth/setup-token 時為 `1h`），或設定您自己的節奏。
2. 在 Agent 工作空間建立一個小型的 `HEARTBEAT.md` 清單（選用但建議）。
3. 決定 heartbeat 訊息應發送至何處（`target: "none"` 是預設值；設定 `target: "last"` 可路由到最後一個聯絡人）。
4. 選用：啟用 heartbeat reasoning 傳遞以提高透明度。
5. 選用：若 heartbeat 執行只需要 `HEARTBEAT.md`，使用輕量化的 bootstrap context。
6. 選用：將 heartbeat 限制在活躍時段（本地時間）。

設定範例：

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",
        target: "last", // 明確傳送至最後一個聯絡人（預設為 "none"）
        directPolicy: "allow", // 預設：允許 direct/DM 目標；設定 "block" 可抑制
        lightContext: true, // 選用：僅從 bootstrap 檔案注入 HEARTBEAT.md
        // activeHours: { start: "08:00", end: "24:00" },
        // includeReasoning: true, // 選用：也傳送獨立的 `Reasoning:` 訊息
      },
    },
  },
}
```

## 預設值

- 間隔：`30m`（偵測到 Anthropic OAuth/setup-token 認證模式時為 `1h`）。設定 `agents.defaults.heartbeat.every` 或每 agent 的 `agents.list[].heartbeat.every`；使用 `0m` 停用。
- Prompt 內容（可透過 `agents.defaults.heartbeat.prompt` 設定）：
  `Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.`
- Heartbeat prompt 以**逐字**方式作為使用者訊息傳送。系統 prompt 包含「Heartbeat」段落，且執行在內部標記。
- 活躍時段（`heartbeat.activeHours`）在設定的時區中檢查。時段外的 heartbeat 會被跳過，直到時段內的下一個 tick。

## Heartbeat prompt 的用途

預設 prompt 刻意廣泛：

- **背景任務**：「考慮未完成的任務」促使 Agent 審查待辦事項（收件匣、行事曆、提醒、排隊的工作）並浮出任何緊急事項。
- **人類關心**：「在白天有時關心您的人類」促使偶爾的輕量「有什麼需要嗎？」訊息，但透過使用您設定的本地時區（參閱 [/concepts/timezone](/zh-Hant/concepts/timezone)）避免夜間騷擾。

若您希望 heartbeat 做非常具體的事（例如「檢查 Gmail PubSub 統計」或「驗證 gateway 健康」），設定 `agents.defaults.heartbeat.prompt`（或 `agents.list[].heartbeat.prompt`）為自訂內容（逐字傳送）。

## 回應規約

- 若無需關注事項，以 **`HEARTBEAT_OK`** 回覆。
- 在 heartbeat 執行期間，OpenClaw 在 `HEARTBEAT_OK` 出現在回覆的**開頭或結尾**時視為確認。若剩餘內容 **≤ `ackMaxChars`**（預設：300），Token 會被移除且回覆被捨棄。
- 若 `HEARTBEAT_OK` 出現在回覆**中間**，不會特殊處理。
- 若有警示，**不要**包含 `HEARTBEAT_OK`；只回傳警示文字。

在 heartbeat 之外，訊息開頭/結尾的 `HEARTBEAT_OK` 會被移除並記錄；只有 `HEARTBEAT_OK` 的訊息會被捨棄。

## 設定

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m", // 預設：30m（0m 停用）
        model: "anthropic/claude-opus-4-6",
        includeReasoning: false, // 預設：false（可用時也傳送獨立的 Reasoning: 訊息）
        lightContext: false, // 預設：false；true 保留 heartbeat 執行的輕量 bootstrap context，只從工作空間 bootstrap 檔案保留 HEARTBEAT.md
        target: "last", // 預設：none | 選項：last | none | <channel id>（核心或 plugin，例如 "bluebubbles"）
        to: "+15551234567", // 選用的頻道特定覆蓋
        accountId: "ops-bot", // 選用的多帳號頻道 id
        prompt: "Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.",
        ackMaxChars: 300, // HEARTBEAT_OK 後允許的最大字元數
      },
    },
  },
}
```

### 範圍與優先順序

- `agents.defaults.heartbeat` 設定全域 heartbeat 行為。
- `agents.list[].heartbeat` 疊加在上面；若任何 agent 有 `heartbeat` 區塊，**只有那些 agents** 執行 heartbeat。
- `channels.defaults.heartbeat` 為所有頻道設定可見性預設值。
- `channels.<channel>.heartbeat` 覆蓋頻道預設值。
- `channels.<channel>.accounts.<id>.heartbeat`（多帳號頻道）覆蓋每頻道設定。

### 每 Agent Heartbeat

若任何 `agents.list[]` 項目包含 `heartbeat` 區塊，**只有那些 agents** 執行 heartbeat。每 agent 區塊疊加在 `agents.defaults.heartbeat` 之上（因此您可以設定一次共享預設值，然後每 agent 覆蓋）。

範例：兩個 agents，只有第二個 agent 執行 heartbeat。

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",
        target: "last", // 明確傳送至最後一個聯絡人（預設為 "none"）
      },
    },
    list: [
      { id: "main", default: true },
      {
        id: "ops",
        heartbeat: {
          every: "1h",
          target: "whatsapp",
          to: "+15551234567",
          prompt: "Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.",
        },
      },
    ],
  },
}
```

### 活躍時段範例

將 heartbeat 限制在特定時區的工作時間：

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",
        target: "last", // 明確傳送至最後一個聯絡人（預設為 "none"）
        activeHours: {
          start: "09:00",
          end: "22:00",
          timezone: "America/New_York", // 選用；若設定了 userTimezone 則使用它，否則使用主機時區
        },
      },
    },
  },
}
```

在此時段外（東部時間早上 9 點前或晚上 10 點後），heartbeat 會被跳過。時段內的下一個排程 tick 將正常執行。

### 全天候設定

若您希望 heartbeat 全天執行，使用以下其中一種模式：

- 完全省略 `activeHours`（無時段限制；這是預設行為）。
- 設定全天時段：`activeHours: { start: "00:00", end: "24:00" }`。

不要設定相同的 `start` 和 `end` 時間（例如 `08:00` 到 `08:00`）。這會被視為零寬度時段，因此 heartbeat 永遠被跳過。

### 多帳號範例

使用 `accountId` 針對 Telegram 等多帳號頻道中的特定帳號：

```json5
{
  agents: {
    list: [
      {
        id: "ops",
        heartbeat: {
          every: "1h",
          target: "telegram",
          to: "12345678:topic:42", // 選用：路由到特定 topic/thread
          accountId: "ops-bot",
        },
      },
    ],
  },
  channels: {
    telegram: {
      accounts: {
        "ops-bot": { botToken: "YOUR_TELEGRAM_BOT_TOKEN" },
      },
    },
  },
}
```

### 欄位說明

- `every`：heartbeat 間隔（持續時間字串；預設單位 = 分鐘）。
- `model`：heartbeat 執行的選用模型覆蓋（`provider/model`）。
- `includeReasoning`：啟用時，在可用時也傳送獨立的 `Reasoning:` 訊息（與 `/reasoning on` 相同格式）。
- `lightContext`：為 true 時，heartbeat 執行使用輕量化 bootstrap context，只從工作空間 bootstrap 檔案保留 `HEARTBEAT.md`。
- `session`：heartbeat 執行的選用 session 鍵。
  - `main`（預設）：Agent 主 session。
  - 明確的 session 鍵（從 `openclaw sessions --json` 或 [sessions CLI](/zh-Hant/cli/sessions) 複製）。
  - Session 鍵格式：參閱 [Sessions](/zh-Hant/concepts/session) 和 [Groups](/zh-Hant/channels/groups)。
- `target`：
  - `last`：傳送至最後使用的外部頻道。
  - 明確頻道：`whatsapp` / `telegram` / `discord` / `googlechat` / `slack` / `msteams` / `signal` / `imessage`。
  - `none`（預設）：執行 heartbeat 但**不對外傳遞**。
- `directPolicy`：控制 direct/DM 傳遞行為：
  - `allow`（預設）：允許 direct/DM heartbeat 傳遞。
  - `block`：抑制 direct/DM 傳遞（`reason=dm-blocked`）。
- `to`：選用的收件人覆蓋（頻道特定 id，例如 WhatsApp 的 E.164 或 Telegram chat id）。對於 Telegram topics/threads，使用 `<chatId>:topic:<messageThreadId>`。
- `accountId`：多帳號頻道的選用帳號 id。當 `target: "last"` 時，帳號 id 適用於已解析的最後頻道（若支援帳號）；否則忽略。若帳號 id 與已解析頻道的設定帳號不符，傳遞會被跳過。
- `prompt`：覆蓋預設 prompt 內容（非合併）。
- `ackMaxChars`：傳遞前 `HEARTBEAT_OK` 後允許的最大字元數。
- `suppressToolErrorWarnings`：為 true 時，在 heartbeat 執行期間抑制工具錯誤警告酬載。
- `activeHours`：將 heartbeat 執行限制在時段內。包含 `start`（HH:MM，含；`00:00` 表示日開始）、`end`（HH:MM，不含；`24:00` 允許表示日結束）和選用 `timezone` 的物件。
  - 省略或 `"user"`：使用您的 `agents.defaults.userTimezone`（若設定），否則 fallback 到主機系統時區。
  - `"local"`：永遠使用主機系統時區。
  - 任何 IANA 識別符（例如 `America/New_York`）：直接使用；若無效，fallback 到上述 `"user"` 行為。
  - `start` 和 `end` 不得相等才能有活躍時段；相等值被視為零寬度（永遠在時段外）。
  - 在活躍時段外，heartbeat 被跳過直到時段內的下一個 tick。

## 傳遞行為

- Heartbeat 預設在 Agent 主 session 中執行（`agent:<id>:<mainKey>`），或 `session.scope = "global"` 時為 `global`。設定 `session` 覆蓋到特定頻道 session（Discord/WhatsApp 等）。
- `session` 只影響執行上下文；傳遞由 `target` 和 `to` 控制。
- 若要傳送至特定頻道/收件人，設定 `target` + `to`。使用 `target: "last"` 時，傳遞使用該 session 的最後外部頻道。
- Heartbeat 傳遞預設允許 direct/DM 目標。設定 `directPolicy: "block"` 可在仍執行 heartbeat 輪次的同時抑制 direct 目標傳送。
- 若主佇列忙碌，heartbeat 被跳過並稍後重試。
- 若 `target` 解析不到外部目的地，執行仍然發生但不傳送外部訊息。
- 僅 heartbeat 的回覆**不會**讓 session 保持活躍；`updatedAt` 會被恢復，讓閒置過期正常運作。

## 可見性控制

預設情況下，`HEARTBEAT_OK` 確認被抑制，而警示內容會被傳遞。您可以按頻道或帳號調整：

```yaml
channels:
  defaults:
    heartbeat:
      showOk: false # 隱藏 HEARTBEAT_OK（預設）
      showAlerts: true # 顯示警示訊息（預設）
      useIndicator: true # 發送指示器事件（預設）
  telegram:
    heartbeat:
      showOk: true # 在 Telegram 上顯示 OK 確認
  whatsapp:
    accounts:
      work:
        heartbeat:
          showAlerts: false # 為此帳號抑制警示傳遞
```

優先順序：每帳號 → 每頻道 → 頻道預設 → 內建預設。

### 每個 flag 的功能

- `showOk`：當模型返回僅 OK 的回覆時傳送 `HEARTBEAT_OK` 確認。
- `showAlerts`：當模型返回非 OK 的回覆時傳送警示內容。
- `useIndicator`：為 UI 狀態介面發送指示器事件。

若**三個都**為 false，OpenClaw 完全跳過 heartbeat 執行（不呼叫模型）。

### 每頻道對比每帳號範例

```yaml
channels:
  defaults:
    heartbeat:
      showOk: false
      showAlerts: true
      useIndicator: true
  slack:
    heartbeat:
      showOk: true # 所有 Slack 帳號
    accounts:
      ops:
        heartbeat:
          showAlerts: false # 僅抑制 ops 帳號的警示
  telegram:
    heartbeat:
      showOk: true
```

### 常見模式

| 目標                          | 設定                                                                                     |
| ----------------------------- | ---------------------------------------------------------------------------------------- |
| 預設行為（靜默 OK，警示開啟） | _（不需設定）_                                                                           |
| 完全靜默（無訊息，無指示器）  | `channels.defaults.heartbeat: { showOk: false, showAlerts: false, useIndicator: false }` |
| 僅指示器（無訊息）            | `channels.defaults.heartbeat: { showOk: false, showAlerts: false, useIndicator: true }`  |
| 只在一個頻道顯示 OK           | `channels.telegram.heartbeat: { showOk: true }`                                          |

## HEARTBEAT.md（選用）

若工作空間中存在 `HEARTBEAT.md` 檔案，預設 prompt 會告訴 Agent 讀取它。把它當作您的「heartbeat 清單」：精簡、穩定，且每 30 分鐘包含一次也安全。

若 `HEARTBEAT.md` 存在但實際上為空（只有空行和 `# Heading` 等 markdown 標題），OpenClaw 會跳過 heartbeat 執行以節省 API 呼叫。若檔案遺失，heartbeat 仍會執行，模型自行決定要做什麼。

保持精簡（短清單或提醒）以避免 prompt 膨脹。

`HEARTBEAT.md` 範例：

```md
# Heartbeat checklist

- Quick scan: anything urgent in inboxes?
- If it's daytime, do a lightweight check-in if nothing else is pending.
- If a task is blocked, write down _what is missing_ and ask Peter next time.
```

### Agent 可以更新 HEARTBEAT.md 嗎？

可以——若您要求它這樣做。

`HEARTBEAT.md` 只是 Agent 工作空間中的一個普通檔案，您可以在普通聊天中告訴 Agent：

- 「更新 `HEARTBEAT.md` 以新增每日行事曆檢查。」
- 「重寫 `HEARTBEAT.md` 使其更短且專注於收件匣待辦事項。」

若您希望這主動發生，您也可以在 heartbeat prompt 中包含明確的一行：「若清單變得過時，用更好的清單更新 HEARTBEAT.md。」

安全提示：不要將機密（API keys、電話號碼、私人 token）放入 `HEARTBEAT.md`——它會成為 prompt context 的一部分。

## 手動喚醒（按需執行）

您可以將系統事件加入佇列並觸發即時 heartbeat：

```bash
openclaw system event --text "Check for urgent follow-ups" --mode now
```

若多個 agents 設定了 `heartbeat`，手動喚醒會立即執行每個 agent 的 heartbeat。

使用 `--mode next-heartbeat` 等待下一個排程的 tick。

## Reasoning 傳遞（選用）

預設情況下，heartbeat 只傳遞最終的「答案」酬載。

若您想要透明度，啟用：

- `agents.defaults.heartbeat.includeReasoning: true`

啟用時，heartbeat 也會傳遞一個以 `Reasoning:` 為前綴的獨立訊息（與 `/reasoning on` 格式相同）。當 Agent 管理多個 sessions/codex 且您想了解它決定通知您的原因時，這可能很有用——但它也可能洩露超出您期望的內部細節。建議在群組聊天中保持關閉。

## 費用意識

Heartbeat 執行完整的 Agent 輪次。較短的間隔消耗更多 Token。保持 `HEARTBEAT.md` 精簡，若您只需要內部狀態更新，可以考慮使用更便宜的 `model` 或 `target: "none"`。
