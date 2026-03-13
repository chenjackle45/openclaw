---
title: "Session Management（會話）"
summary: "聊天的會話管理規則、鑰匙和持久性"
read_when:
  - 修改會話處理或儲存
---

# Session Management（會話管理）

OpenClaw 將**每代理一個直接聊天會話**視為主要。直接聊天折疊到 `agent:<agentId>:<mainKey>`（預設 `main`），而群組/頻道聊天獲得自己的鑰匙。`session.mainKey` 被遵守。

使用 `session.dmScope` 控制**直接訊息**如何分組：

- `main`（預設）：所有 DM 共享主會話以保持連續性。
- `per-peer`：跨頻道按傳送者 ID 隔離。
- `per-channel-peer`：按頻道 + 傳送者隔離（建議用於多使用者收件匣）。
- `per-account-channel-peer`：按帳戶 + 頻道 + 傳送者隔離（建議用於多帳戶收件匣）。
  使用 `session.identityLinks` 將提供商前綴的對等 ID 對應到規範身份，以便在使用 `per-peer`、`per-channel-peer` 或 `per-account-channel-peer` 時，同一人跨頻道共享 DM 會話。

## Secure DM mode（推薦用於多使用者設定）

> **Security Warning（安全警告）：** 若你的 agent 可接收來自**多人**的 DM，強烈建議啟用 secure DM mode。無此，所有使用者共享相同會話上下文，可能洩漏使用者間私人資訊。

**預設設定的問題範例：**

- Alice（`<SENDER_A>`）就私人主題（例如醫療預約）傳訊你的 agent
- Bob（`<SENDER_B>`）傳訊你的 agent 詢問「我們在談什麼？」
- 因為兩 DM 共享相同會話，模型可能用 Alice 的先前上下文回答 Bob。

**修復：** 設定 `dmScope` 以按使用者隔離會話：

```json5
// ~/.openclaw/openclaw.json
{
  session: {
    // Secure DM mode: isolate DM context per channel + sender.
    dmScope: "per-channel-peer",
  },
}
```

**何時啟用：**

- 你有多個傳送者的配對核准
- 你使用多個條目的 DM allowlist
- 你設定 `dmPolicy: "open"`
- 多個電話號碼或帳戶可傳訊你的 agent

注意：

- 預設為 `dmScope: "main"`，持續性（所有 DM 共享主會話）。這對單使用者設定不錯。
- 本地 CLI 引導預設在未設定時寫 `session.dmScope: "per-channel-peer"`（現有明確值被保留）。
- 多帳戶同頻道收件匣，偏好 `per-account-channel-peer`。
- 若同一人在多頻道聯絡你，使用 `session.identityLinks` 將他們的 DM 會話折疊成單一規範身份。
- 你可用 `openclaw security audit` 驗證你的 DM 設定（見 [security](/zh-Hant/cli/security)）。

## Gateway is the source of truth（Gateway 是真實來源）

所有會話狀態**由 Gateway 擁有**（「主」OpenClaw）。UI 客戶端（macOS 應用、WebChat 等）必須查詢 Gateway 獲取會話列表和 token 計數，而不是讀取本地檔案。

- 在**遠端模式**下，你關心的會話儲存位於遠端 Gateway 主機上，不在你的 Mac。
- UI 中顯示的 token 計數來自 Gateway 的儲存欄位（`inputTokens`、`outputTokens`、`totalTokens`、`contextTokens`）。客戶端不解析 JSONL 轉錄來「修復」總數。

## Where state lives（狀態存放位置）

- 在 **Gateway 主機**上：
  - Store file（儲存檔案）：`~/.openclaw/agents/<agentId>/sessions/sessions.json`（每代理）。
- Transcripts（轉錄）：`~/.openclaw/agents/<agentId>/sessions/<SessionId>.jsonl`（Telegram 主題會話使用 `.../<SessionId>-topic-<threadId>.jsonl`）。
- Store 是 `sessionKey -> { sessionId, updatedAt, ... }` 的映射。刪除條目是安全的；它們會按需重新建立。
- Group entries（群組條目）可能包含 `displayName`、`channel`、`subject`、`room` 和 `space` 以在 UI 中標記會話。
- Session entries（會話條目）包含 `origin` 元資料（標籤 + 路由提示），以便 UI 可解釋會話來自哪裡。
- OpenClaw **不**讀取舊版 Pi/Tau 會話資料夾。

## Maintenance（維護）

OpenClaw 應用會話儲存維護以保持 `sessions.json` 和轉錄工件隨時間有限。

### Defaults（預設）

- `session.maintenance.mode`：`warn`
- `session.maintenance.pruneAfter`：`30d`
- `session.maintenance.maxEntries`：`500`
- `session.maintenance.rotateBytes`：`10mb`
- `session.maintenance.resetArchiveRetention`：預設為 `pruneAfter`（`30d`）
- `session.maintenance.maxDiskBytes`：未設定（停用）
- `session.maintenance.highWaterBytes`：預設為 `maxDiskBytes` 的 `80%`（啟用預算時）

### How it works（運作方式）

維護在會話儲存寫入期間執行，你可用 `openclaw sessions cleanup` 按需觸發。

- `mode: "warn"`：報告會被逐出的內容，但不改變條目/轉錄。
- `mode: "enforce"`：按此順序應用清理：
  1. prune 早於 `pruneAfter` 的陳舊條目
  2. cap entry count 至 `maxEntries`（最舊優先）
  3. 歸檔已移除、不再被參考的條目的轉錄檔案
  4. purge 舊 `*.deleted.<timestamp>` 和 `*.reset.<timestamp>` 歸檔按保留原則
  5. rotate `sessions.json` 當超過 `rotateBytes` 時
  6. 若設定 `maxDiskBytes`，執行磁碟預算至 `highWaterBytes`（最舊工件優先，然後最舊會話）

### Performance caveat for large stores（大型儲存的效能警告）

大型會話儲存在高量設定中常見。維護工作是寫入路徑工作，很大的儲存可增加寫入延遲。

增加成本最多的：

- 非常高的 `session.maintenance.maxEntries` 值
- 長 `pruneAfter` 視窗，保持陳舊條目
- 許多轉錄/歸檔工件在 `~/.openclaw/agents/<agentId>/sessions/`
- 啟用磁碟預算（`maxDiskBytes`）無合理修剪/上限

該做什麼：

- 在生產中使用 `mode: "enforce"`，以便增長自動有界
- 同時設定時間和計數限制（`pruneAfter` + `maxEntries`），不只一個
- 對大型部署設定 `maxDiskBytes` + `highWaterBytes` 以取得硬上限
- 保持 `highWaterBytes` 有意義低於 `maxDiskBytes`（預設 80%）
- 配置改變後執行 `openclaw sessions cleanup --dry-run --json` 驗證預期影響再執行
- 對頻繁活躍會話，執行手動清理時傳遞 `--active-key`

### Customize examples（自訂範例）

使用保守執行原則：

```json5
{
  session: {
    maintenance: {
      mode: "enforce",
      pruneAfter: "45d",
      maxEntries: 800,
      rotateBytes: "20mb",
      resetArchiveRetention: "14d",
    },
  },
}
```

對會話目錄啟用硬磁碟預算：

```json5
{
  session: {
    maintenance: {
      mode: "enforce",
      maxDiskBytes: "1gb",
      highWaterBytes: "800mb",
    },
  },
}
```

為更大的安裝調整（範例）：

```json5
{
  session: {
    maintenance: {
      mode: "enforce",
      pruneAfter: "14d",
      maxEntries: 2000,
      rotateBytes: "25mb",
      maxDiskBytes: "2gb",
      highWaterBytes: "1.6gb",
    },
  },
}
```

從 CLI 預覽或強制維護：

```bash
openclaw sessions cleanup --dry-run
openclaw sessions cleanup --enforce
```

## Session pruning（會話修剪）

OpenClaw 在 LLM 呼叫前預設從記憶體上下文中修剪**舊工具結果**。
這**不會**重寫 JSONL 歷史。見 [/concepts/session-pruning](/zh-Hant/concepts/session-pruning)。

## Pre-compaction memory flush（壓縮前記憶體刷新）

當會話接近自動壓縮時，OpenClaw 可執行**靜默記憶體刷新**輪次，提醒模型將持久筆記寫入磁碟。這僅在工作區可寫時執行。見 [Memory](/zh-Hant/concepts/memory) 和 [Compaction](/zh-Hant/concepts/compaction)。

## Mapping transports → session keys（映射傳輸 → 會話鑰匙）

- Direct chats（直接聊天）遵循 `session.dmScope`（預設 `main`）。
  - `main`：`agent:<agentId>:<mainKey>`（跨設備/頻道的連續性）。
    - 多個電話號碼和頻道可對應到同一代理主鑰匙；它們作為傳輸進入一個對話。
  - `per-peer`：`agent:<agentId>:dm:<peerId>`。
  - `per-channel-peer`：`agent:<agentId>:<channel>:dm:<peerId>`。
  - `per-account-channel-peer`：`agent:<agentId>:<channel>:<accountId>:dm:<peerId>`（accountId 預設為 `default`）。
  - 若 `session.identityLinks` 匹配提供商前綴的對等 ID（例如 `telegram:123`），規範鑰匙替換 `<peerId>`，以便同一人跨頻道共享會話。
- Group chats（群組聊天）隔離狀態：`agent:<agentId>:<channel>:group:<id>`（房間/頻道使用 `agent:<agentId>:<channel>:channel:<id>`）。
  - Telegram 論壇主題附加 `:topic:<threadId>` 至群組 ID 以進行隔離。
  - 舊版 `group:<id>` 鑰匙仍被識別以進行遷移。
- Inbound contexts（入站上下文）可能仍使用 `group:<id>`；頻道從 `Provider` 推斷並正規化為規範 `agent:<agentId>:<channel>:group:<id>` 形式。
- Other sources（其他來源）：
  - Cron jobs：`cron:<job.id>`
  - Webhooks：`hook:<uuid>`（除非由 hook 明確設定）
  - Node runs：`node-<nodeId>`

## Lifecycle（生命週期）

- Reset policy（重設原則）：會話被重用直到過期，過期在下一個入站訊息時評估。
- Daily reset（每日重設）：預設為 **Gateway 主機本地時間上午 4:00**。當會話的最後更新早於最近的每日重設時間時，會話變陳舊。
- Idle reset（閒置重設）（可選）：`idleMinutes` 新增滑動閒置視窗。當同時設定每日和閒置重設時，**先過期的**強制新會話。
- Legacy idle-only（舊版僅閒置）：若設定 `session.idleMinutes` 而沒有任何 `session.reset`/`resetByType` 組態，OpenClaw 為了向後相容保持僅閒置模式。
- Per-type overrides（按類型覆寫）（可選）：`resetByType` 讓你覆寫 `direct`、`group` 和 `thread` 會話的原則（thread = Slack/Discord 討論串、Telegram 主題、Matrix 討論串當連接器提供時）。
- Per-channel overrides（按頻道覆寫）（可選）：`resetByChannel` 覆寫頻道的重設原則（適用於該頻道的所有會話類型，優先於 `reset`/`resetByType`）。
- Reset triggers（重設觸發器）：精確的 `/new` 或 `/reset`（加上 `resetTriggers` 中的任何額外項）開始新會話 id 並傳遞訊息的其餘部分。`/new <model>` 接受模型別名、`provider/model` 或提供商名稱（模糊匹配）以設定新會話模型。若單獨發送 `/new` 或 `/reset`，OpenClaw 執行短暫的「hello」問候輪次以確認重設。
- Manual reset（手動重設）：從儲存刪除特定鑰匙或移除 JSONL 轉錄；下一條訊息重新建立它們。
- Isolated cron jobs（隔離 cron 工作）始終為每次執行鑄造新 `sessionId`（無閒置重用）。

## Send policy（可選）

在不列出個別 ID 的情況下阻止特定會話類型的交付。

```json5
{
  session: {
    sendPolicy: {
      rules: [
        { action: "deny", match: { channel: "discord", chatType: "group" } },
        { action: "deny", match: { keyPrefix: "cron:" } },
        // Match the raw session key (including the `agent:<id>:` prefix).
        { action: "deny", match: { rawKeyPrefix: "agent:main:discord:" } },
      ],
      default: "allow",
    },
  },
}
```

Runtime override（執行時覆寫）（owner only）：

- `/send on` → 對此會話允許
- `/send off` → 對此會話拒絕
- `/send inherit` → 清除覆寫並使用組態規則
  將這些作為獨立訊息發送以便註冊。

## Configuration（可選重命名範例）

```json5
// ~/.openclaw/openclaw.json
{
  session: {
    scope: "per-sender", // keep group keys separate
    dmScope: "main", // DM continuity (set per-channel-peer/per-account-channel-peer for shared inboxes)
    identityLinks: {
      alice: ["telegram:123456789", "discord:987654321012345678"],
    },
    reset: {
      // Defaults: mode=daily, atHour=4 (gateway host local time).
      // If you also set idleMinutes, whichever expires first wins.
      mode: "daily",
      atHour: 4,
      idleMinutes: 120,
    },
    resetByType: {
      thread: { mode: "daily", atHour: 4 },
      direct: { mode: "idle", idleMinutes: 240 },
      group: { mode: "idle", idleMinutes: 120 },
    },
    resetByChannel: {
      discord: { mode: "idle", idleMinutes: 10080 },
    },
    resetTriggers: ["/new", "/reset"],
    store: "~/.openclaw/agents/{agentId}/sessions/sessions.json",
    mainKey: "main",
  },
}
```

## Inspecting（檢查）

- `openclaw status` — 顯示儲存路徑和最近的會話。
- `openclaw sessions --json` — 傾印每個條目（使用 `--active <minutes>` 過濾）。
- `openclaw gateway call sessions.list --params '{}'` — 從執行中的 Gateway 獲取會話（使用 `--url`/`--token` 進行遠端 Gateway 存取）。
- 在聊天中作為獨立訊息發送 `/status` 以查看 agent 是否可達、會話上下文使用多少、當前 thinking/fast/verbose 切換，以及你的 WhatsApp web 憑證最後刷新的時間（幫助發現重新連結需求）。
- 發送 `/context list` 或 `/context detail` 以查看系統提示和注入的工作區檔案中有什麼（以及最大的上下文貢獻者）。
- 作為獨立訊息發送 `/stop`（或獨立中止片語如 `stop`、`stop action`、`stop run`、`stop openclaw`）以中止當前執行、清除該會話的排隊後續，並停止從它生成的任何子 agent 執行（回覆包含停止計數）。
- 作為獨立訊息發送 `/compact`（可選說明）以摘要較舊的上下文並釋放視窗空間。見 [/concepts/compaction](/zh-Hant/concepts/compaction)。
- JSONL 轉錄可直接開啟以檢視完整輪次。

## Tips（提示）

- 保持主鑰匙專用於 1:1 流量；讓群組保持自己的鑰匙。
- 自動化清理時，刪除個別鑰匙而非整個儲存以保留其他地方的上下文。

## Session origin metadata（會話來源元資料）

每個會話條目在 `origin` 中記錄它來自哪裡（盡力而為）：

- `label`：人類標籤（從對話標籤 + 群組主題/頻道解析）
- `provider`：正規化的頻道 ID（包括擴展）
- `from`/`to`：入站信封的原始路由 ID
- `accountId`：提供商帳戶 ID（當多帳戶時）
- `threadId`：當頻道支援時的討論串/主題 ID
  來源欄位為直接訊息、頻道和群組填充。若連接器僅更新交付路由（例如保持 DM 主會話新鮮），它仍應提供入站上下文，以便會話保持其解釋元資料。擴展可透過在入站上下文中發送 `ConversationLabel`、`GroupSubject`、`GroupChannel`、`GroupSpace` 和 `SenderName` 並呼叫 `recordSessionMetaFromInbound`（或將相同上下文傳遞給 `updateLastRoute`）來做到這一點。
