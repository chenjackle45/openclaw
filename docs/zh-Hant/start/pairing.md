---
summary: "配對概述：批准誰可以 DM 您 + 哪些節點可以加入"
read_when:
  - 設定 DM 存取控制
  - 配對新的 iOS/Android 節點
  - 檢查 OpenClaw 安全狀態
title: "Pairing（配對）"
---

# 配對

「配對」是 OpenClaw 的明確**擁有者批准**步驟。
它用於兩個地方：

1. **DM 配對**（誰被允許與 bot 交談）
2. **節點配對**（哪些裝置/節點被允許加入 Gateway 網路）

安全上下文：[安全性](/zh-Hant/gateway/security)

## 1) DM 配對（傳入聊天存取）

當頻道配置為 DM 政策 `pairing` 時，未知傳送者獲得簡短代碼，其訊息**未被處理**，直到您批准。

預設 DM 政策記錄在：[安全性](/zh-Hant/gateway/security)

配對代碼：

- 8 個字元，大寫，無模稜兩可字元（`0O1I`）。
- **在 1 小時後過期**。bot 僅在建立新請求時傳送配對訊息（大約每個傳送者每小時一次）。
- 待機 DM 配對請求上限為**每個頻道 3 個**（預設）；額外請求被忽略，直到一個過期或被批准。

### 批准傳送者

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

支援的頻道：`telegram`、`whatsapp`、`signal`、`imessage`、`discord`、`slack`、`feishu`。

### 狀態存放在哪裡

儲存在 `~/.openclaw/credentials/` 下：

- 待機請求：`<channel>-pairing.json`
- 已批准的允許清單儲存：
  - 預設帳戶：`<channel>-allowFrom.json`
  - 非預設帳戶：`<channel>-<accountId>-allowFrom.json`

帳戶範圍行為：

- 非預設帳戶僅讀取/寫入其範圍內的允許清單檔案。
- 預設帳戶使用頻道範圍的無範圍允許清單檔案。

將這些視為敏感（它們控制對您助手的存取）。

## 2) 節點裝置配對（iOS/Android/macOS/無頭節點）

節點作為**裝置**與 Gateway 連接，其 `role: node`。Gateway
建立一個必須被批准的裝置配對請求。

### 透過 Telegram 配對（建議用於 iOS）

如果您使用 `device-pair` 外掛程式，您可以完全從 Telegram 進行首次裝置配對：

1. 在 Telegram 中，訊息您的 bot：`/pair`
2. bot 回覆兩條訊息：一條指令訊息和一條單獨的**設定代碼**訊息（易於在 Telegram 中複製/貼上）。
3. 在您的電話上，開啟 OpenClaw iOS 應用 → 設定 → Gateway。
4. 貼上設定代碼並連接。
5. 回到 Telegram：`/pair approve`

設定代碼是 base64 編碼的 JSON 負載，包含：

- `url`：Gateway WebSocket URL（`ws://...` 或 `wss://...`）
- `token`：短期配對 Token

當設定代碼有效時，將其視為密碼。

### 批准節點裝置

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw devices reject <requestId>
```

### 節點配對狀態儲存

儲存在 `~/.openclaw/devices/` 下：

- `pending.json`（短期；待機請求過期）
- `paired.json`（配對裝置 + Token）

### 註

- 舊版 `node.pair.*` API（CLI：`openclaw nodes pending/approve`）是一個
  單獨的 Gateway 擁有的配對儲存。WS 節點仍然需要裝置配對。

## 相關文件

- 安全模型 + 提示注入：[安全性](/zh-Hant/gateway/security)
- 安全更新（執行醫生）：[更新](/zh-Hant/install/updating)
- 頻道設定：
  - Telegram：[Telegram](/zh-Hant/channels/telegram)
  - WhatsApp：[WhatsApp](/zh-Hant/channels/whatsapp)
  - Signal：[Signal](/zh-Hant/channels/signal)
  - BlueBubbles (iMessage)：[BlueBubbles](/zh-Hant/channels/bluebubbles)
  - iMessage (legacy)：[iMessage](/zh-Hant/channels/imessage)
  - Discord：[Discord](/zh-Hant/channels/discord)
  - Slack：[Slack](/zh-Hant/channels/slack)
