---
summary: "配對概述：核准誰可以傳私訊給你 + 哪些節點可以加入 Gateway 網路"
read_when:
  - 設定私訊存取控制
  - 配對新的 iOS/Android 節點
  - 檢視 OpenClaw 安全設定
title: "配對（Pairing）"
---

# Pairing

「配對」是 OpenClaw 的明確**擁有者核准**步驟。
它用在兩個地方：

1. **私訊配對**（哪些人可以與 Bot 對話）
2. **節點配對**（哪些裝置/節點可以加入 Gateway 網路）

安全情境說明：[安全性](/zh-Hant/gateway/security)

## 1) 私訊配對（收入聊天存取）

當頻道設定私訊政策為 `pairing` 時，未知發送者會收到一組短碼，其訊息**不會被處理**，直到你核准為止。

預設私訊政策說明請見：[安全性](/zh-Hant/gateway/security)

配對碼規格：

- 8 個字元，大寫，無易混淆字元（`0O1I`）。
- **1 小時後過期**。Bot 只在建立新請求時傳送配對訊息（大約每位發送者每小時一次）。
- 等待核准的私訊配對請求每頻道預設上限為 **3 個**；超過的請求會被忽略，直到其中一個過期或被核准。

### 核准發送者

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

支援的頻道：`telegram`、`whatsapp`、`signal`、`imessage`、`discord`、`slack`、`feishu`。

### 狀態儲存位置

儲存於 `~/.openclaw/credentials/`：

- 等待核准的請求：`<channel>-pairing.json`
- 已核准的白名單儲存：
  - 預設帳號：`<channel>-allowFrom.json`
  - 非預設帳號：`<channel>-<accountId>-allowFrom.json`

帳號範圍行為：

- 非預設帳號只讀寫其自己範圍的白名單檔案。
- 預設帳號使用未附帳號 ID 的頻道範圍白名單檔案。

請將這些檔案視為敏感資料（它們控制對你的 AI 助理的存取）。

## 2) 節點裝置配對（iOS/Android/macOS/無頭節點）

節點以 `role: node` 的**裝置**身份連接至 Gateway。Gateway 會建立一個裝置配對請求，必須由擁有者核准。

### 透過 Telegram 配對（iOS 推薦方式）

如果你安裝了 `device-pair` 插件，可以完全透過 Telegram 完成首次裝置配對：

1. 在 Telegram 中傳訊息給你的 Bot：`/pair`
2. Bot 會回覆兩則訊息：一則說明訊息和一則獨立的**設定碼**訊息（在 Telegram 中容易複製貼上）。
3. 在你的手機上，開啟 OpenClaw iOS 應用程式 → 設定 → Gateway。
4. 貼上設定碼並連接。
5. 回到 Telegram：`/pair approve`

設定碼是 base64 編碼的 JSON 載荷，包含：

- `url`：Gateway WebSocket URL（`ws://...` 或 `wss://...`）
- `bootstrapToken`：用於初始配對握手的短期單次裝置 Bootstrap Token

在有效期間，請將設定碼視同密碼處理。

### 核准節點裝置

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw devices reject <requestId>
```

### 節點配對狀態儲存

儲存於 `~/.openclaw/devices/`：

- `pending.json`（短期存在；等待請求會過期）
- `paired.json`（已配對的裝置與 Token）

### 注意事項

- 舊版 `node.pair.*` API（CLI：`openclaw nodes pending/approve`）是獨立的 Gateway 管理配對儲存。WS 節點仍需要裝置配對。

## 相關文件

- 安全模型與提示注入：[安全性](/zh-Hant/gateway/security)
- 安全更新（執行 doctor）：[更新](/zh-Hant/install/updating)
- 頻道設定：
  - Telegram：[Telegram](/zh-Hant/channels/telegram)
  - WhatsApp：[WhatsApp](/zh-Hant/channels/whatsapp)
  - Signal：[Signal](/zh-Hant/channels/signal)
  - BlueBubbles (iMessage)：[BlueBubbles](/zh-Hant/channels/bluebubbles)
  - iMessage（舊版）：[iMessage](/zh-Hant/channels/imessage)
  - Discord：[Discord](/zh-Hant/channels/discord)
  - Slack：[Slack](/zh-Hant/channels/slack)
