---
title: "WhatsApp"
summary: "WhatsApp（網頁頻道）整合：登入、收件匣、回覆、媒體和操作"
read_when:
  - 處理 WhatsApp/網頁頻道行為或收件匣路由
---
# WhatsApp（網頁頻道）


狀態：僅支援透過 Baileys 的 WhatsApp Web。Gateway 擁有會話。

## 快速設定（初學者）
1) 如果可能，使用**獨立電話號碼**（建議）。
2) 在 `~/.openclaw/openclaw.json` 中設定 WhatsApp。
3) 執行 `openclaw channels login` 掃描 QR 碼（已連結裝置）。
4) 啟動 Gateway。

最小設定：
```json5
{
  channels: {
    whatsapp: {
      dmPolicy: "allowlist",
      allowFrom: ["+15551234567"]
    }
  }
}
```

## 目標
- 單一 Gateway 程序中的多個 WhatsApp 帳戶（多帳戶）。
- 確定性路由：回覆返回 WhatsApp，無模型路由。
- 模型看到足夠的上下文以理解引用回覆。

## 設定寫入
預設情況下，WhatsApp 允許寫入由 `/config set|unset` 觸發的設定更新（需要 `commands.config: true`）。

使用以下方式停用：
```json5
{
  channels: { whatsapp: { configWrites: false } }
}
```

## 架構（誰擁有什麼）
- **Gateway** 擁有 Baileys socket 和收件匣循環。
- **CLI / macOS 應用程式**與 Gateway 通訊；不直接使用 Baileys。
- 外發傳送需要**活躍的監聽器**；否則傳送會快速失敗。

## 取得電話號碼（兩種模式）

WhatsApp 需要真實的手機號碼進行驗證。VoIP 和虛擬號碼通常會被阻止。有兩種支援的方式在 WhatsApp 上運行 OpenClaw：

### 專用號碼（建議）
為 OpenClaw 使用**獨立電話號碼**。最佳使用者體驗，乾淨的路由，沒有自聊怪異問題。理想設定：**備用/舊 Android 手機 + eSIM**。保持在 Wi-Fi 和電源上，並透過 QR 連結。

**WhatsApp Business：** 您可以在同一裝置上使用不同號碼的 WhatsApp Business。非常適合將您的個人 WhatsApp 分開 — 安裝 WhatsApp Business 並在那裡註冊 OpenClaw 號碼。

**範例設定（專用號碼，單用戶允許清單）：**
```json5
{
  channels: {
    whatsapp: {
      dmPolicy: "allowlist",
      allowFrom: ["+15551234567"]
    }
  }
}
```

**配對模式（可選）：**
如果您想使用配對而不是允許清單，將 `channels.whatsapp.dmPolicy` 設為 `pairing`。未知發送者會收到配對碼；使用以下命令批准：
`openclaw pairing approve whatsapp <code>`

### 個人號碼（備選）
快速備選：在**您自己的號碼**上運行 OpenClaw。給自己發訊息（WhatsApp「給自己發訊息」）進行測試，這樣您就不會打擾聯絡人。預期在設定和實驗期間會在您的主手機上讀取驗證碼。**必須啟用自聊模式。**
當精靈詢問您的個人 WhatsApp 號碼時，輸入您將發送訊息的電話（所有者/發送者），而不是助理號碼。

**範例設定（個人號碼，自聊）：**
```json
{
  "whatsapp": {
    "selfChatMode": true,
    "dmPolicy": "allowlist",
    "allowFrom": ["+15551234567"]
  }
}
```

當設定時，自聊回覆預設為 `[{identity.name}]`（否則為 `[openclaw]`），
如果 `messages.responsePrefix` 未設定。明確設定它以自訂或停用
前綴（使用 `""` 移除它）。

### 號碼來源提示
- **您所在國家行動電信商的本地 eSIM**（最可靠）
  - 奧地利：[hot.at](https://www.hot.at)
  - 英國：[giffgaff](https://www.giffgaff.com) — 免費 SIM 卡，無合約
- **預付 SIM 卡** — 便宜，只需要接收一條驗證簡訊

**避免：** TextNow、Google Voice、大多數「免費簡訊」服務 — WhatsApp 會積極阻止這些。

**提示：** 號碼只需要接收一條驗證簡訊。之後，WhatsApp Web 會話透過 `creds.json` 持續存在。

## 為什麼不用 Twilio？
- 早期 OpenClaw 版本支援 Twilio 的 WhatsApp Business 整合。
- WhatsApp Business 號碼不適合個人助理。
- Meta 強制執行 24 小時回覆視窗；如果您在過去 24 小時內沒有回應，商業號碼無法發起新訊息。
- 高容量或「聊天式」使用會觸發積極的阻止，因為商業帳戶不適合發送數十條個人助理訊息。
- 結果：交付不可靠且頻繁被阻止，因此移除了支援。

## 登入 + 憑證
- 登入命令：`openclaw channels login`（透過已連結裝置的 QR）。
- 多帳戶登入：`openclaw channels login --account <id>`（`<id>` = `accountId`）。
- 預設帳戶（省略 `--account` 時）：如果存在則為 `default`，否則為第一個設定的帳戶 ID（已排序）。
- 憑證儲存在 `~/.openclaw/credentials/whatsapp/<accountId>/creds.json`。
- 備份副本在 `creds.json.bak`（損壞時恢復）。
- 舊版相容性：較舊的安裝直接在 `~/.openclaw/credentials/` 中儲存 Baileys 檔案。
- 登出：`openclaw channels logout`（或 `--account <id>`）刪除 WhatsApp 認證狀態（但保留共享的 `oauth.json`）。
- 已登出的 socket => 錯誤指示重新連結。

## 入站流程（私訊 + 群組）
- WhatsApp 事件來自 `messages.upsert`（Baileys）。
- 收件匣監聽器在關閉時分離，以避免在測試/重啟時累積事件處理器。
- 狀態/廣播聊天被忽略。
- 直接聊天使用 E.164；群組使用群組 JID。
- **私訊策略**：`channels.whatsapp.dmPolicy` 控制直接聊天存取（預設：`pairing`）。
  - 配對：未知發送者收到配對碼（透過 `openclaw pairing approve whatsapp <code>` 批准；代碼在 1 小時後過期）。
  - 開放：需要 `channels.whatsapp.allowFrom` 包含 `"*"`。
  - 您連結的 WhatsApp 號碼隱式受信任，因此自身訊息跳過 `channels.whatsapp.dmPolicy` 和 `channels.whatsapp.allowFrom` 檢查。

### 個人號碼模式（備選）
如果您在**個人 WhatsApp 號碼**上運行 OpenClaw，啟用 `channels.whatsapp.selfChatMode`（請參閱上面的範例）。

行為：
- 外發私訊永遠不會觸發配對回覆（防止打擾聯絡人）。
- 入站未知發送者仍然遵循 `channels.whatsapp.dmPolicy`。
- 自聊模式（allowFrom 包含您的號碼）避免自動已讀回執並忽略提及 JID。
- 為非自聊私訊發送已讀回執。

## 已讀回執
預設情況下，Gateway 會將入站 WhatsApp 訊息標記為已讀（藍勾）一旦被接受。

全域停用：
```json5
{
  channels: { whatsapp: { sendReadReceipts: false } }
}
```

按帳戶停用：
```json5
{
  channels: {
    whatsapp: {
      accounts: {
        personal: { sendReadReceipts: false }
      }
    }
  }
}
```

備註：
- 自聊模式始終跳過已讀回執。

## WhatsApp 常見問題：發送訊息 + 配對

**當我連結 WhatsApp 時，OpenClaw 會給隨機聯絡人發訊息嗎？**
不會。預設私訊策略是**配對**，因此未知發送者只會收到配對碼，他們的訊息**不會被處理**。OpenClaw 只回覆它收到的聊天，或您明確觸發的傳送（代理/CLI）。

**WhatsApp 上的配對如何運作？**
配對是未知發送者的私訊閘門：
- 來自新發送者的第一條私訊返回一個短代碼（訊息不被處理）。
- 使用以下命令批准：`openclaw pairing approve whatsapp <code>`（使用 `openclaw pairing list whatsapp` 列出）。
- 代碼在 1 小時後過期；每個頻道的待處理請求上限為 3 個。

**多人可以在一個 WhatsApp 號碼上使用不同的 OpenClaw 實例嗎？**
是的，透過 `bindings` 將每個發送者路由到不同的代理（peer `kind: "dm"`，sender E.164 如 `+15551234567`）。回覆仍然來自**同一個 WhatsApp 帳戶**，直接聊天會歸納到每個代理的主會話，因此使用**每人一個代理**。私訊存取控制（`dmPolicy`/`allowFrom`）是每個 WhatsApp 帳戶全域的。請參閱 [多代理路由](/concepts/multi-agent)。

**為什麼精靈會詢問我的電話號碼？**
精靈使用它來設定您的**允許清單/所有者**，以便您自己的私訊被允許。它不用於自動發送。如果您在個人 WhatsApp 號碼上運行，使用相同的號碼並啟用 `channels.whatsapp.selfChatMode`。

## 訊息正規化（模型看到什麼）
- `Body` 是帶有信封的當前訊息正文。
- 引用回覆上下文**始終附加**：
  ```
  [Replying to +1555 id:ABC123]
  <quoted text or <media:...>>
  [/Replying]
  ```
- 回覆元資料也設定：
  - `ReplyToId` = stanzaId
  - `ReplyToBody` = 引用正文或媒體佔位符
  - `ReplyToSender` = 已知時為 E.164
- 僅媒體的入站訊息使用佔位符：
  - `<media:image|video|audio|document|sticker>`

## 群組
- 群組對應到 `agent:<agentId>:whatsapp:group:<jid>` 會話。
- 群組策略：`channels.whatsapp.groupPolicy = open|disabled|allowlist`（預設 `allowlist`）。
- 啟動模式：
  - `mention`（預設）：需要 @提及或正則表達式匹配。
  - `always`：始終觸發。
- `/activation mention|always` 是僅限所有者的，必須作為獨立訊息發送。
- 所有者 = `channels.whatsapp.allowFrom`（如果未設定則為自身 E.164）。
- **歷史注入**（僅待處理）：
  - 最近*未處理*的訊息（預設 50）插入在：
    `[Chat messages since your last reply - for context]`（已在會話中的訊息不會重新注入）
  - 當前訊息在：
    `[Current message - respond to this]`
  - 附加發送者後綴：`[from: Name (+E164)]`
- 群組元資料快取 5 分鐘（主題 + 參與者）。

## 回覆交付（串連）
- WhatsApp Web 發送標準訊息（當前 Gateway 中沒有引用回覆串連）。
- 此頻道忽略回覆標籤。

## 確認反應（收到時自動反應）

WhatsApp 可以在收到入站訊息時立即自動發送表情符號反應，在機器人生成回覆之前。這為用戶提供即時反饋，表明他們的訊息已被接收。

**設定：**
```json
{
  "whatsapp": {
    "ackReaction": {
      "emoji": "👀",
      "direct": true,
      "group": "mentions"
    }
  }
}
```

**選項：**
- `emoji`（字串）：用於確認的表情符號（例如「👀」、「✅」、「📨」）。空或省略 = 功能停用。
- `direct`（布林，預設：`true`）：在直接/私訊聊天中發送反應。
- `group`（字串，預設：`"mentions"`）：群組聊天行為：
  - `"always"`：對所有群組訊息反應（即使沒有 @提及）
  - `"mentions"`：僅在機器人被 @提及時反應
  - `"never"`：永遠不在群組中反應

**按帳戶覆寫：**
```json
{
  "whatsapp": {
    "accounts": {
      "work": {
        "ackReaction": {
          "emoji": "✅",
          "direct": false,
          "group": "always"
        }
      }
    }
  }
}
```

**行為備註：**
- 反應在訊息收到時**立即**發送，在輸入指示器或機器人回覆之前。
- 在 `requireMention: false`（啟動：always）的群組中，`group: "mentions"` 將對所有訊息反應（不僅是 @提及）。
- 發送後不管：反應失敗會被記錄但不會阻止機器人回覆。
- 參與者 JID 會自動包含在群組反應中。
- WhatsApp 忽略 `messages.ackReaction`；請改用 `channels.whatsapp.ackReaction`。

## 代理工具（反應）
- 工具：`whatsapp` 帶有 `react` 動作（`chatJid`、`messageId`、`emoji`、可選 `remove`）。
- 可選：`participant`（群組發送者）、`fromMe`（對您自己的訊息反應）、`accountId`（多帳戶）。
- 反應移除語意：請參閱 [/tools/reactions](/tools/reactions)。
- 工具閘門：`channels.whatsapp.actions.reactions`（預設：啟用）。

## 限制
- 外發文字分塊至 `channels.whatsapp.textChunkLimit`（預設 4000）。
- 可選的換行分塊：設定 `channels.whatsapp.chunkMode="newline"` 在長度分塊前在空白行（段落邊界）分割。
- 入站媒體儲存上限為 `channels.whatsapp.mediaMaxMb`（預設 50 MB）。
- 外發媒體項目上限為 `agents.defaults.mediaMaxMb`（預設 5 MB）。

## 外發傳送（文字 + 媒體）
- 使用活躍的網頁監聽器；如果 Gateway 未運行則錯誤。
- 文字分塊：每條訊息最大 4k（可透過 `channels.whatsapp.textChunkLimit`、可選 `channels.whatsapp.chunkMode` 設定）。
- 媒體：
  - 支援圖片/影片/音訊/文件。
  - 音訊以 PTT 發送；`audio/ogg` => `audio/ogg; codecs=opus`。
  - 說明文字僅在第一個媒體項目上。
  - 媒體獲取支援 HTTP(S) 和本地路徑。
  - 動畫 GIF：WhatsApp 預期帶有 `gifPlayback: true` 的 MP4 以進行內聯循環。
    - CLI：`openclaw message send --media <mp4> --gif-playback`
    - Gateway：`send` 參數包含 `gifPlayback: true`

## 語音訊息（PTT 音訊）
WhatsApp 將音訊作為**語音訊息**（PTT 氣泡）發送。
- 最佳效果：OGG/Opus。OpenClaw 將 `audio/ogg` 重寫為 `audio/ogg; codecs=opus`。
- WhatsApp 忽略 `[[audio_as_voice]]`（音訊已作為語音訊息發送）。

## 媒體限制 + 優化
- 預設外發上限：5 MB（每個媒體項目）。
- 覆寫：`agents.defaults.mediaMaxMb`。
- 圖片在上限內自動優化為 JPEG（調整大小 + 品質掃描）。
- 超大媒體 => 錯誤；媒體回覆回退到文字警告。

## 心跳
- **Gateway 心跳**記錄連線健康（`web.heartbeatSeconds`，預設 60 秒）。
- **代理心跳**可以按代理設定（`agents.list[].heartbeat`）或全域
  透過 `agents.defaults.heartbeat`（未設定按代理條目時的備選）。
  - 使用設定的心跳提示（預設：`Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.`）+ `HEARTBEAT_OK` 跳過行為。
  - 交付預設為最後使用的頻道（或設定的目標）。

## 重新連線行為
- 退避策略：`web.reconnect`：
  - `initialMs`、`maxMs`、`factor`、`jitter`、`maxAttempts`。
- 如果達到 maxAttempts，網頁監控停止（降級）。
- 已登出 => 停止並需要重新連結。

## 設定快速對照
- `channels.whatsapp.dmPolicy`（私訊策略：pairing/allowlist/open/disabled）。
- `channels.whatsapp.selfChatMode`（同電話設定；機器人使用您的個人 WhatsApp 號碼）。
- `channels.whatsapp.allowFrom`（私訊允許清單）。WhatsApp 使用 E.164 電話號碼（無用戶名）。
- `channels.whatsapp.mediaMaxMb`（入站媒體儲存上限）。
- `channels.whatsapp.ackReaction`（訊息收到時的自動反應：`{emoji, direct, group}`）。
- `channels.whatsapp.accounts.<accountId>.*`（按帳戶設定 + 可選 `authDir`）。
- `channels.whatsapp.accounts.<accountId>.mediaMaxMb`（按帳戶入站媒體上限）。
- `channels.whatsapp.accounts.<accountId>.ackReaction`（按帳戶確認反應覆寫）。
- `channels.whatsapp.groupAllowFrom`（群組發送者允許清單）。
- `channels.whatsapp.groupPolicy`（群組策略）。
- `channels.whatsapp.historyLimit` / `channels.whatsapp.accounts.<accountId>.historyLimit`（群組歷史上下文；`0` 停用）。
- `channels.whatsapp.dmHistoryLimit`（用戶輪次中的私訊歷史限制）。按用戶覆寫：`channels.whatsapp.dms["<phone>"].historyLimit`。
- `channels.whatsapp.groups`（群組允許清單 + 提及閘門預設；使用 `"*"` 允許全部）
- `channels.whatsapp.actions.reactions`（WhatsApp 工具反應閘門）。
- `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）
- `messages.groupChat.historyLimit`
- `channels.whatsapp.messagePrefix`（入站前綴；按帳戶：`channels.whatsapp.accounts.<accountId>.messagePrefix`；已棄用：`messages.messagePrefix`）
- `messages.responsePrefix`（外發前綴）
- `agents.defaults.mediaMaxMb`
- `agents.defaults.heartbeat.every`
- `agents.defaults.heartbeat.model`（可選覆寫）
- `agents.defaults.heartbeat.target`
- `agents.defaults.heartbeat.to`
- `agents.defaults.heartbeat.session`
- `agents.list[].heartbeat.*`（按代理覆寫）
- `session.*`（scope、idle、store、mainKey）
- `web.enabled`（為 false 時停用頻道啟動）
- `web.heartbeatSeconds`
- `web.reconnect.*`

## 日誌 + 疑難排解
- 子系統：`whatsapp/inbound`、`whatsapp/outbound`、`web-heartbeat`、`web-reconnect`。
- 日誌檔案：`/tmp/openclaw/openclaw-YYYY-MM-DD.log`（可設定）。
- 疑難排解指南：[Gateway 疑難排解](/gateway/troubleshooting)。

## 疑難排解（快速）

**未連結 / 需要 QR 登入**
- 症狀：`channels status` 顯示 `linked: false` 或警告「Not linked」。
- 修復：在 Gateway 主機上執行 `openclaw channels login` 並掃描 QR（WhatsApp → 設定 → 已連結裝置）。

**已連結但斷開連線 / 重新連線循環**
- 症狀：`channels status` 顯示 `running, disconnected` 或警告「Linked but disconnected」。
- 修復：`openclaw doctor`（或重啟 Gateway）。如果持續發生，透過 `channels login` 重新連結並檢查 `openclaw logs --follow`。

**Bun 運行時**
- **不建議**使用 Bun。WhatsApp（Baileys）和 Telegram 在 Bun 上不可靠。
  使用 **Node** 運行 Gateway。（請參閱入門運行時備註。）
