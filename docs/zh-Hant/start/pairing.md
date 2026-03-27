---
summary: "配對概述：核准誰可以傳 DM 給你 + 哪些節點可加入"
read_when:
  - 設置 DM 存取控制
  - 配對新的 iOS／Android 節點
  - 檢查 OpenClaw 安全狀態
title: "Pairing（配對）"
sidebarTitle: "配對"
---

# 配對

「配對」是 OpenClaw 的明確**擁有者核准**步驟。
它用於兩個地方：

1. **DM 配對**（誰可允許與 bot 交談）
2. **節點配對**（哪些裝置／節點可允許加入 gateway 網路）

安全上下文：[安全](/zh-Hant/gateway/security)

## 1) DM 配對（傳入聊天存取）

當頻道配置為 DM 原則 `pairing` 時，未知寄件者取得簡短代碼，其訊息**不會被處理**直到你核准。

預設 DM 原則記錄在：[安全](/zh-Hant/gateway/security)

配對碼：

- 8 個字元、大寫、無模稜兩可的字元（`0O1I`）。
- **在 1 小時後過期**。Bot 僅在建立新請求時傳送配對訊息（大約每小時每個寄件者一次）。
- 待決 DM 配對請求預設上限為**每個頻道 3 個**；額外請求被忽略，直到一個過期或被核准。

### 核准寄件者

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

支援的頻道：`bluebubbles`、`discord`、`feishu`、`googlechat`、`imessage`、`irc`、`line`、`matrix`、`mattermost`、`msteams`、`nextcloud-talk`、`nostr`、`signal`、`slack`、`synology-chat`、`telegram`、`twitch`、`whatsapp`、`zalo`、`zalouser`。

### 狀態儲存位置

儲存在 `~/.openclaw/credentials/` 下：

- 待決請求：`<channel>-pairing.json`
- 已核准允許清單存儲：
  - 預設帳戶：`<channel>-allowFrom.json`
  - 非預設帳戶：`<channel>-<accountId>-allowFrom.json`

帳戶範圍行為：

- 非預設帳戶僅讀寫其範圍內的允許清單檔案。
- 預設帳戶使用頻道範圍的無範圍允許清單檔案。

將這些視為敏感（它們控制對你助手的存取）。

## 2) 節點裝置配對（iOS／Android／macOS／無頭節點）

節點以**裝置**的身份連接到 Gateway，具有 `role: node`。Gateway
建立必須被核准的裝置配對請求。

### 透過 Telegram 配對（iOS 推薦）

如果你使用 `device-pair` 外掛程式，你可以完全從 Telegram 進行首次裝置配對：

1. 在 Telegram 中，訊息你的 bot：`/pair`
2. Bot 回覆兩條訊息：指示訊息和單獨的**設置代碼**訊息（易於在 Telegram 中複製／貼上）。
3. 在你的手機上，開啟 OpenClaw iOS 應用 → 設定 → Gateway。
4. 貼上設置代碼並連接。
5. 回到 Telegram：`/pair pending`（檢查請求 ID、角色和範圍），然後核准。

設置代碼是一個 base64 編碼的 JSON 酬載，包含：

- `url`：Gateway WebSocket URL（`ws://...` 或 `wss://...`）
- `bootstrapToken`：用於初始配對握手的短暫單裝置引導令杖

在有效期間將設置代碼視為密碼。

### 核准節點裝置

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw devices reject <requestId>
```

如果相同裝置以不同的驗證詳情重試（例如不同的角色／範圍／公鑰），前一個待決請求被取代，並建立新的
`requestId`。

### 節點配對狀態儲存

儲存在 `~/.openclaw/devices/` 下：

- `pending.json`（短暫的；待決請求過期）
- `paired.json`（配對的裝置 + 令杖）

### 備註

- 舊版 `node.pair.*` API（CLI：`openclaw nodes pending/approve`）是
  單獨的 gateway 擁有的配對存儲。WS 節點仍需要裝置配對。

## 相關文件

- 安全模型 + 提示注入：[安全](/zh-Hant/gateway/security)
- 安全更新（執行 doctor）：[更新](/zh-Hant/install/updating)
- 頻道設定：
  - Telegram：[Telegram](/zh-Hant/channels/telegram)
  - WhatsApp：[WhatsApp](/zh-Hant/channels/whatsapp)
  - Signal：[Signal](/zh-Hant/channels/signal)
  - BlueBubbles (iMessage)：[BlueBubbles](/zh-Hant/channels/bluebubbles)
  - iMessage（舊版）：[iMessage](/zh-Hant/channels/imessage)
  - Discord：[Discord](/zh-Hant/channels/discord)
  - Slack：[Slack](/zh-Hant/channels/slack)
