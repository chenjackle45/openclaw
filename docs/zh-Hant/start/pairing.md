---
summary: "配對概覽：核准誰可以傳 DM 給您 + 哪些節點可以加入"
read_when:
  - 設定 DM 存取控制時
  - 配對新的 iOS/Android 節點時
  - 檢視 OpenClaw 安全態勢時
title: "配對"
---

# 配對

「配對」是 OpenClaw 的明確**擁有者核准**步驟。
用於兩個地方：

1. **DM 配對**（誰可以與機器人通話）
2. **節點配對**（哪些裝置/節點可以加入 Gateway 網路）

安全語境：[安全性](/gateway/security)

## 1) DM 配對（入站聊天存取）

當頻道配置為 DM 政策 `pairing` 時，未知的傳送者會取得短碼，其訊息在您核准前**不會被處理**。

預設 DM 政策記載於：[安全性](/gateway/security)

配對碼：

- 8 個字元，大寫，無模稜兩可的字元（`0O1I`）。
- **1 小時後過期**。機器人僅在建立新請求時傳送配對訊息（大約每小時每個傳送者一次）。
- 每個頻道待決配對請求上限**3 個**預設；額外請求被忽略直到一個過期或被核准。

### 核准傳送者

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

支援頻道：`telegram`、`whatsapp`、`signal`、`imessage`、`discord`、`slack`。

### 狀態位置

儲存在 `~/.openclaw/credentials/` 下：

- 待決請求：`<channel>-pairing.json`
- 已核准允許清單儲存：`<channel>-allowFrom.json`

視這些為敏感（它們守護對您助理的存取）。

## 2) 節點裝置配對（iOS/Android/macOS/無頭節點）

節點以 `role: node` 的**裝置**身份連接到 Gateway。Gateway
建立必須被核准的裝置配對請求。

### 核准節點裝置

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw devices reject <requestId>
```

### 狀態位置

儲存在 `~/.openclaw/devices/` 下：

- `pending.json`（短期；待決請求過期）
- `paired.json`（已配對裝置 + 令牌）

### 備註

- 舊版 `node.pair.*` API（CLI：`openclaw nodes pending/approve`）是
  個別 Gateway 擁有的配對儲存。WS 節點仍需要裝置配對。

## 相關文件

- 安全模型 + 提示注入：[安全性](/gateway/security)
- 安全更新（執行 doctor）：[更新](/install/updating)
- 頻道配置：
  - Telegram：[Telegram](/channels/telegram)
  - WhatsApp：[WhatsApp](/channels/whatsapp)
  - Signal：[Signal](/channels/signal)
  - iMessage：[iMessage](/channels/imessage)
  - Discord：[Discord](/channels/discord)
  - Slack：[Slack](/channels/slack)
