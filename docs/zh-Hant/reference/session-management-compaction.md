---
summary: "深入：會話存儲 + 文字記錄、生命週期和（自動）壓縮內部"
read_when:
  - 你需要調試會話 ID、文字記錄 JSONL 或 sessions.json 欄位
  - 你正在更改自動壓縮行為或新增「預壓縮」清理
  - 你想實現記憶體刷新或靜默系統轉換
title: "Session Management Deep Dive（會話管理深入探討）"
---

# 會話管理和壓縮（深入探討）

本文件說明 OpenClaw 如何端對端管理會話：

- **會話路由**（入站訊息如何對應至 `sessionKey`）
- **會話存儲**（`sessions.json`）及其追蹤的內容
- **文字記錄持久化**（`*.jsonl`）及其結構
- **文字記錄衛生**（執行前特定提供者修正）
- **內容限制**（內容視窗與追蹤的標記）
- **壓縮**（手動 + 自動壓縮）及在哪裡掛接預壓縮工作
- **靜默清理**（例如不應產生使用者可見輸出的記憶體寫入）

如果你先想要更高級別的概述，請從以下開始：

- [/concepts/session](/zh-Hant/concepts/session)
- [/concepts/compaction](/zh-Hant/concepts/compaction)
- [/concepts/session-pruning](/zh-Hant/concepts/session-pruning)
- [/reference/transcript-hygiene](/zh-Hant/reference/transcript-hygiene)

---

## 事實來源：Gateway

OpenClaw 圍繞單個**Gateway 進程**設計，該進程擁有會話狀態。

- UI（macOS App、Web Control UI、TUI）應向 Gateway 查詢會話清單和標記計數。
- 在遠端模式中，會話檔案在遠端主機上；「檢查你的本機 Mac 檔案」不會反映 Gateway 正在使用的內容。

---

## 兩個持久化層

OpenClaw 在兩個層中持久化會話：

1. **會話存儲（`sessions.json`）**
   - 鍵/值對映：`sessionKey -> SessionEntry`
   - 小、可變、編輯（或刪除條目）安全
   - 追蹤會話中繼資料（目前會話 ID、最後活動、切換、標記計數器等）

2. **文字記錄（`<sessionId>.jsonl`）**
   - 具有樹結構的僅附加文字記錄（條目有 `id` + `parentId`）
   - 儲存實際交談 + 工具呼叫 + 壓縮摘要
   - 用於為未來轉換重新建置模型上下文

---

## 磁碟位置

每個 Agent，在 Gateway 主機上：

- 存儲：`~/.openclaw/agents/<agentId>/sessions/sessions.json`
- 文字記錄：`~/.openclaw/agents/<agentId>/sessions/<sessionId>.jsonl`
  - Telegram 主題會話：`.../<sessionId>-topic-<threadId>.jsonl`

OpenClaw 透過 `src/config/sessions.ts` 解析這些。

---

## 會話金鑰（`sessionKey`）

`sessionKey` 識別*你在哪個交談桶中*（路由 + 隔離）。

常見模式：

- 主/直接聊天（每個 Agent）：`agent:<agentId>:<mainKey>`（預設 `main`）
- 群組：`agent:<agentId>:<channel>:group:<id>`
- 房間/頻道（Discord/Slack）：`agent:<agentId>:<channel>:channel:<id>` 或 `...:room:<id>`
- Cron：`cron:<job.id>`
- Webhook：`hook:<uuid>`（除非被覆蓋）

規範規則記載於[/concepts/session](/zh-Hant/concepts/session)。

---

## 會話 ID（`sessionId`）

每個 `sessionKey` 指向目前 `sessionId`（繼續交談的文字記錄檔案）。

經驗法則：

- **重設**（`/new`、`/reset`）為該 `sessionKey` 建立新的 `sessionId`。
- **每日重設**（預設本地時間上午 4:00 在 Gateway 主機上）在重設邊界後的下一個訊息上為該 `sessionKey` 建立新的 `sessionId`。
- **閒置過期**（`session.reset.idleMinutes` 或舊版 `session.idleMinutes`）當訊息在閒置視窗後抵達時為該 `sessionKey` 建立新的 `sessionId`。當同時設定每日和閒置時，先期滿的獲勝。

實作細節：決定發生在 `src/auto-reply/reply/session.ts` 中的 `initSessionState()`。

---

## 會話存儲結構描述（`sessions.json`）

存儲的值類型是 `src/config/sessions.ts` 中的 `SessionEntry`。

主要欄位（不是詳盡）：

- `sessionId`：目前文字記錄 ID（檔名從此衍生，除非設定 `sessionFile`）
- `updatedAt`：最後活動時間戳記
- `sessionFile`：選擇性明確文字記錄路徑覆蓋
- `chatType`：`direct | group | room`（幫助 UI 和傳送原則）
- `provider`、`subject`、`room`、`space`、`displayName`：群組/頻道標籤化的中繼資料
- 切換：
  - `thinkingLevel`、`verboseLevel`、`reasoningLevel`、`elevatedLevel`
  - `sendPolicy`（每個會話覆蓋）
- 模型選擇：
  - `providerOverride`、`modelOverride`、`authProfileOverride`
- 標記計數器（盡力/提供者相依）：
  - `inputTokens`、`outputTokens`、`totalTokens`、`contextTokens`
- `compactionCount`：此會話金鑰的自動壓縮完成次數
- `memoryFlushAt`：最後預壓縮記憶體刷新的時間戳記
- `memoryFlushCompactionCount`：最後刷新執行時的壓縮計數

存儲是編輯安全的，但 Gateway 是權威：它可能在會話執行時重寫或補充條目。

---

## 文字記錄結構（`*.jsonl`）

文字記錄由 `@mariozechner/pi-coding-agent` 的 `SessionManager` 管理。

檔案是 JSONL：

- 第一行：會話標頭（`type: "session"`，包括 `id`、`cwd`、`timestamp`、可選 `parentSession`）
- 然後：具有 `id` + `parentId`（樹）的會話條目

顯著的條目類型：

- `message`：使用者/助手/工具結果訊息
- `custom_message`：擴充套件注入的訊息，*進入*模型上下文（可從 UI 隱藏）
- `custom`：不進入模型上下文的擴充套件狀態
- `compaction`：帶有 `firstKeptEntryId` 和 `tokensBefore` 的持久壓縮摘要
- `branch_summary`：導航樹分支時的持久摘要

OpenClaw 有意**不**「修正」文字記錄；Gateway 使用 `SessionManager` 來讀取/寫入它們。

---

## 內容視窗與追蹤的標記

兩個不同的概念很重要：

1. **模型內容視窗**：每個模型的硬上限（對模型可見的標記）
2. **會話存儲計數器**：寫入 `sessions.json` 的滾動統計（用於 /status 和儀表板）

如果你正在調整限制：

- 內容視窗來自模型目錄（可透過設定覆蓋）。
- 存儲中的 `contextTokens` 是執行時估計/報告值；不要將其視為嚴格保證。

詳見[/token-use](/zh-Hant/reference/token-use)。

---

## 壓縮：它是什麼

壓縮將較舊交談摘要為文字記錄中的持久 `compaction` 條目，並保持最近的訊息完整。

壓縮後，未來的轉換會看到：

- 壓縮摘要
- `firstKeptEntryId` 之後的訊息

壓縮是**持久的**（不同於會話修剪）。詳見[/concepts/session-pruning](/zh-Hant/concepts/session-pruning)。

---

## 何時自動壓縮發生（Pi 執行時期間）

在嵌入式 Pi Agent 中，自動壓縮在兩種情況下觸發：

1. **溢位恢復**：模型傳回內容溢位錯誤 → 壓縮 → 重試。
2. **閾值維護**：成功轉換後，當：

`contextTokens > contextWindow - reserveTokens`

其中：

- `contextWindow` 是模型的內容視窗
- `reserveTokens` 是為提示 + 下一個模型輸出保留的空間

這些是 Pi 執行時語義（OpenClaw 使用事件，但 Pi 決定何時壓縮）。

---

## 壓縮設定（`reserveTokens`、`keepRecentTokens`）

Pi 的壓縮設定存在於 Pi 設定中：

```json5
{
  compaction: {
    enabled: true,
    reserveTokens: 16384,
    keepRecentTokens: 20000,
  },
}
```

OpenClaw 也為嵌入式執行強制安全下限：

- 如果 `compaction.reserveTokens < reserveTokensFloor`，OpenClaw 會提升它。
- 預設下限為 `20000` 標記。
- 設定 `agents.defaults.compaction.reserveTokensFloor: 0` 以停用下限。
- 如果已更高，OpenClaw 保持不變。

為什麼：在壓縮變得不可避免前，為多轉換「清理」（如記憶體寫入）留下足夠空間。

實作：`src/agents/pi-settings.ts` 中的 `ensurePiCompactionReserveTokens()`
（從 `src/agents/pi-embedded-runner.ts` 呼叫）。

---

## 使用者可見的介面

你可以透過以下方式觀察壓縮和會話狀態：

- `/status`（在任何聊天會話中）
- `openclaw status`（CLI）
- `openclaw sessions` / `sessions --json`
- 詳細模式：`🧹 自動壓縮完成` + 壓縮計數

---

## 靜默清理（`NO_REPLY`）

OpenClaw 支援背景工作的「靜默」轉換，使用者不應看到中間輸出。

慣例：

- 助手以 `NO_REPLY` 開始其輸出以指示「不要向使用者傳遞回覆」。
- OpenClaw 在傳遞層中剝離/隱藏這一點。

自 `2026.1.10` 起，OpenClaw 也會在部分塊以 `NO_REPLY` 開始時抑制**草稿/輸入流**，因此靜默操作不會在轉換中途洩漏部分輸出。

---

## 預壓縮「記憶體刷新」（已實作）

目標：在自動壓縮發生前，執行靜默 Agent 轉換，將持久狀態寫入磁碟（例如 Agent 工作區中的 `memory/YYYY-MM-DD.md`），以便壓縮無法清除關鍵上下文。

OpenClaw 使用**預閾值刷新**方法：

1. 監視會話內容使用情況。
2. 當它跨過「軟閾值」（低於 Pi 的壓縮閾值）時，向 Agent 執行靜默「立即寫入記憶體」指令。
3. 使用 `NO_REPLY` 以使使用者看不到任何東西。

設定（`agents.defaults.compaction.memoryFlush`）：

- `enabled`（預設：`true`）
- `softThresholdTokens`（預設：`4000`）
- `prompt`（刷新轉換的使用者訊息）
- `systemPrompt`（為刷新轉換附加的額外系統提示）

注意事項：

- 預設提示/系統提示包括 `NO_REPLY` 提示以抑制傳遞。
- 刷新每個壓縮循環執行一次（在 `sessions.json` 中追蹤）。
- 刷新僅針對嵌入式 Pi 會話執行（CLI 後端跳過）。
- 當會話工作區是唯讀時（`workspaceAccess: "ro"` 或 `"none"`），刷新被跳過。
- 詳見[記憶體](/zh-Hant/concepts/memory)了解工作區檔案配置和寫入模式。

Pi 也在擴充套件 API 中公開 `session_before_compact` 掛接，但 OpenClaw 的刷新邏輯今天存在於 Gateway 側。

---

## 疑難排解檢查清單

- 會話金鑰錯誤？ 從[/concepts/session](/zh-Hant/concepts/session)開始並確認 `/status` 中的 `sessionKey`。
- 存儲與文字記錄不匹配？ 確認 Gateway 主機和來自 `openclaw status` 的存儲路徑。
- 壓縮垃圾郵件？ 檢查：
  - 模型內容視窗（太小）
  - 壓縮設定（`reserveTokens` 對於模型視窗太高會導致更早壓縮）
  - 工具結果膨脹：啟用/調整會話修剪
- 靜默轉換洩漏？ 確認回覆以 `NO_REPLY`（確切標記）開始，你在包含串流抑制修正的建置上。
