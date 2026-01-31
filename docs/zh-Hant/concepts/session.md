---
title: "Session(會話)"
summary: "聊天的會話管理規則、鍵和持久性"
read_when:
  - 修改會話處理或儲存
---
# Session Management（會話管理）

OpenClaw 將**每代理一個直接聊天會話**視為主要。直接聊天折疊到 `agent:<agentId>:<mainKey>`（預設 `main`），而群組/頻道聊天獲得自己的鍵。`session.mainKey` 被遵守。

使用 `session.dmScope` 控制**直接訊息**如何分組：
- `main`（預設）：所有 DM 共享主會話以保持連續性。
- `per-peer`：跨頻道按發送者 ID 隔離。
- `per-channel-peer`：按頻道 + 發送者隔離（建議用於多使用者收件匣）。
- `per-account-channel-peer`：按帳戶 + 頻道 + 發送者隔離（建議用於多帳戶收件匣）。
使用 `session.identityLinks` 將供應商前綴的對等 ID 映射到規範身份，以便在使用 `per-peer`、`per-channel-peer` 或 `per-account-channel-peer` 時，同一人跨頻道共享 DM 會話。

## Gateway 是真實來源
所有會話狀態**由 Gateway 擁有**（「主」OpenClaw）。UI 客戶端（macOS 應用程式、WebChat 等）必須查詢 Gateway 獲取會話列表和 token 計數，而不是讀取本地檔案。

- 在**遠端模式**下，您關心的會話儲存位於遠端 Gateway 主機上，而不是您的 Mac。
- UI 中顯示的 token 計數來自 Gateway 的儲存欄位（`inputTokens`、`outputTokens`、`totalTokens`、`contextTokens`）。客戶端不解析 JSONL 轉錄來「修復」總數。

## 狀態存放位置
- 在 **Gateway 主機**上：
  - 儲存檔案：`~/.openclaw/agents/<agentId>/sessions/sessions.json`（每代理）。
- 轉錄：`~/.openclaw/agents/<agentId>/sessions/<SessionId>.jsonl`（Telegram 主題會話使用 `.../<SessionId>-topic-<threadId>.jsonl`）。
- 儲存是 `sessionKey -> { sessionId, updatedAt, ... }` 的映射。刪除條目是安全的；它們會按需重新建立。
- 群組條目可能包含 `displayName`、`channel`、`subject`、`room` 和 `space` 以在 UI 中標記會話。
- 會話條目包含 `origin` 元資料（標籤 + 路由提示），以便 UI 可以解釋會話來自哪裡。
- OpenClaw **不**讀取舊版 Pi/Tau 會話資料夾。

## 會話修剪
OpenClaw 預設在 LLM 呼叫之前從記憶體上下文中修剪**舊工具結果**。
這**不會**重寫 JSONL 歷史。請參閱 [/concepts/session-pruning](/concepts/session-pruning)。

## 壓縮前記憶體刷新
當會話接近自動壓縮時，OpenClaw 可以運行**靜默記憶體刷新**輪次，提醒模型將持久備註寫入磁碟。這僅在工作區可寫時運行。請參閱 [記憶體](/concepts/memory) 和 [壓縮](/concepts/compaction)。

## 傳輸映射 → 會話鍵
- 直接聊天遵循 `session.dmScope`（預設 `main`）。
  - `main`：`agent:<agentId>:<mainKey>`（跨設備/頻道的連續性）。
    - 多個電話號碼和頻道可以映射到同一代理主鍵；它們作為傳輸進入一個對話。
  - `per-peer`：`agent:<agentId>:dm:<peerId>`。
  - `per-channel-peer`：`agent:<agentId>:<channel>:dm:<peerId>`。
  - `per-account-channel-peer`：`agent:<agentId>:<channel>:<accountId>:dm:<peerId>`（accountId 預設為 `default`）。
  - 如果 `session.identityLinks` 匹配供應商前綴的對等 ID（例如 `telegram:123`），規範鍵會替換 `<peerId>`，以便同一人跨頻道共享會話。
- 群組聊天隔離狀態：`agent:<agentId>:<channel>:group:<id>`（房間/頻道使用 `agent:<agentId>:<channel>:channel:<id>`）。
  - Telegram 論壇主題將 `:topic:<threadId>` 附加到群組 ID 以進行隔離。
  - 舊版 `group:<id>` 鍵仍然被識別以進行遷移。
- 入站上下文可能仍然使用 `group:<id>`；頻道從 `Provider` 推斷並正規化為規範的 `agent:<agentId>:<channel>:group:<id>` 形式。
- 其他來源：
  - Cron 工作：`cron:<job.id>`
  - Webhooks：`hook:<uuid>`（除非由 hook 明確設定）
  - 節點運行：`node-<nodeId>`

## 生命週期
- 重設策略：會話被重用直到過期，過期在下一個入站訊息時評估。
- 每日重設：預設為 **Gateway 主機本地時間上午 4:00**。當會話的最後更新早於最近的每日重設時間時，會話變陳舊。
- 閒置重設（可選）：`idleMinutes` 新增滑動閒置視窗。當同時設定每日和閒置重設時，**先過期的**強制新會話。
- 舊版僅閒置：如果您設定 `session.idleMinutes` 而沒有任何 `session.reset`/`resetByType` 設定，OpenClaw 為了向後相容性保持僅閒置模式。
- 按類型覆寫（可選）：`resetByType` 讓您覆寫 `dm`、`group` 和 `thread` 會話的策略（thread = Slack/Discord 討論串、Telegram 主題、連接器提供時的 Matrix 討論串）。
- 按頻道覆寫（可選）：`resetByChannel` 覆寫頻道的重設策略（適用於該頻道的所有會話類型，優先於 `reset`/`resetByType`）。
- 重設觸發器：精確的 `/new` 或 `/reset`（加上 `resetTriggers` 中的任何額外項目）開始新會話 ID 並將訊息的剩餘部分透過。`/new <model>` 接受模型別名、`provider/model` 或供應商名稱（模糊匹配）以設定新會話模型。如果單獨發送 `/new` 或 `/reset`，OpenClaw 運行短暫的「hello」問候輪次以確認重設。
- 手動重設：從儲存中刪除特定鍵或移除 JSONL 轉錄；下一條訊息會重新建立它們。
- 隔離的 cron 工作始終為每次運行鑄造新 `sessionId`（無閒置重用）。

## 發送策略（可選）
在不列出個別 ID 的情況下阻止特定會話類型的交付。

```json5
{
  session: {
    sendPolicy: {
      rules: [
        { action: "deny", match: { channel: "discord", chatType: "group" } },
        { action: "deny", match: { keyPrefix: "cron:" } }
      ],
      default: "allow"
    }
  }
}
```

運行時覆寫（僅限擁有者）：
- `/send on` → 對此會話允許
- `/send off` → 對此會話拒絕
- `/send inherit` → 清除覆寫並使用設定規則
將這些作為獨立訊息發送以便註冊。

## 設定（可選重命名範例）
```json5
// ~/.openclaw/openclaw.json
{
  session: {
    scope: "per-sender",      // 保持群組鍵分開
    dmScope: "main",          // DM 連續性（對共享收件匣設定 per-channel-peer/per-account-channel-peer）
    identityLinks: {
      alice: ["telegram:123456789", "discord:987654321012345678"]
    },
    reset: {
      // 預設：mode=daily, atHour=4（Gateway 主機本地時間）。
      // 如果您也設定 idleMinutes，先過期的優先。
      mode: "daily",
      atHour: 4,
      idleMinutes: 120
    },
    resetByType: {
      thread: { mode: "daily", atHour: 4 },
      dm: { mode: "idle", idleMinutes: 240 },
      group: { mode: "idle", idleMinutes: 120 }
    },
    resetByChannel: {
      discord: { mode: "idle", idleMinutes: 10080 }
    },
    resetTriggers: ["/new", "/reset"],
    store: "~/.openclaw/agents/{agentId}/sessions/sessions.json",
    mainKey: "main",
  }
}
```

## 檢查
- `openclaw status` — 顯示儲存路徑和最近的會話。
- `openclaw sessions --json` — 傾印每個條目（使用 `--active <minutes>` 過濾）。
- `openclaw gateway call sessions.list --params '{}'` — 從運行中的 Gateway 獲取會話（使用 `--url`/`--token` 進行遠端 Gateway 存取）。
- 在聊天中作為獨立訊息發送 `/status` 以查看代理是否可達、會話上下文使用了多少、當前 thinking/verbose 切換，以及您的 WhatsApp web 憑證最後刷新的時間（幫助發現重新連結需求）。
- 發送 `/context list` 或 `/context detail` 以查看系統提示和注入的工作區檔案中有什麼（以及最大的上下文貢獻者）。
- 作為獨立訊息發送 `/stop` 以中止當前運行、清除該會話的排隊後續行動，並停止從它生成的任何子代理運行（回覆包含停止計數）。
- 作為獨立訊息發送 `/compact`（可選說明）以摘要較舊的上下文並釋放視窗空間。請參閱 [/concepts/compaction](/concepts/compaction)。
- JSONL 轉錄可以直接開啟以檢視完整輪次。

## 提示
- 將主鍵專用於 1:1 流量；讓群組保持自己的鍵。
- 自動化清理時，刪除個別鍵而不是整個儲存以保留其他地方的上下文。

## 會話來源元資料
每個會話條目在 `origin` 中記錄它來自哪裡（盡力而為）：
- `label`：人類標籤（從對話標籤 + 群組主題/頻道解析）
- `provider`：正規化的頻道 ID（包括擴展）
- `from`/`to`：入站信封的原始路由 ID
- `accountId`：供應商帳戶 ID（當多帳戶時）
- `threadId`：當頻道支援時的討論串/主題 ID
來源欄位為直接訊息、頻道和群組填充。如果連接器只更新交付路由（例如，保持 DM 主會話新鮮），它仍應提供入站上下文，以便會話保持其解釋元資料。擴展可以透過在入站上下文中發送 `ConversationLabel`、`GroupSubject`、`GroupChannel`、`GroupSpace` 和 `SenderName` 並呼叫 `recordSessionMetaFromInbound`（或將相同上下文傳遞給 `updateLastRoute`）來做到這一點。
