---
summary: "LINE Messaging API 外掛安裝、設定與用法"
read_when:
  - 想將 OpenClaw 連接到 LINE
  - 需要 LINE webhook 和憑證設定
  - 想使用 LINE 特有的訊息選項
title: "LINE（LINE Messaging API 外掛）"
---

# LINE（外掛）

LINE 透過 LINE Messaging API 連接至 OpenClaw。此外掛在 Gateway 上作為 Webhook 接收器執行，並使用頻道存取 token 和頻道 secret 進行驗證。

狀態：透過外掛支援。支援私訊、群組聊天、媒體、位置、Flex 訊息、範本訊息和快速回覆。不支援 Reactions 和 Threads。

## 需要外掛

安裝 LINE 外掛：

```bash
openclaw plugins install @openclaw/line
```

本地 checkout（從 git repo 執行時）：

```bash
openclaw plugins install ./extensions/line
```

## 設定

1. 建立 LINE 開發者帳號並開啟主控台：
   [https://developers.line.biz/console/](https://developers.line.biz/console/)
2. 建立（或選擇）提供者並新增 **Messaging API** 頻道。
3. 從頻道設定複製 **Channel access token** 和 **Channel secret**。
4. 在 Messaging API 設定中啟用 **Use webhook**。
5. 將 Webhook URL 設定為你的 Gateway 端點（需要 HTTPS）：

```
https://gateway-host/line/webhook
```

Gateway 回應 LINE 的 Webhook 驗證（GET）和入站事件（POST）。
若需要自訂路徑，設定 `channels.line.webhookPath` 或
`channels.line.accounts.<id>.webhookPath` 並相應更新 URL。

安全說明：

- LINE 簽章驗證依賴請求主體（對原始主體進行 HMAC），因此 OpenClaw 在驗證前對嚴格的預先驗證主體大小和逾時套用限制。

## 設定

最小設定：

```json5
{
  channels: {
    line: {
      enabled: true,
      channelAccessToken: "LINE_CHANNEL_ACCESS_TOKEN",
      channelSecret: "LINE_CHANNEL_SECRET",
      dmPolicy: "pairing",
    },
  },
}
```

環境變數（僅預設帳號）：

- `LINE_CHANNEL_ACCESS_TOKEN`
- `LINE_CHANNEL_SECRET`

Token/secret 檔案：

```json5
{
  channels: {
    line: {
      tokenFile: "/path/to/line-token.txt",
      secretFile: "/path/to/line-secret.txt",
    },
  },
}
```

`tokenFile` 和 `secretFile` 必須指向一般檔案。符號連結不被接受。

多帳號：

```json5
{
  channels: {
    line: {
      accounts: {
        marketing: {
          channelAccessToken: "...",
          channelSecret: "...",
          webhookPath: "/line/marketing",
        },
      },
    },
  },
}
```

## 存取控制

私訊預設使用配對模式。未知發送者收到配對碼，其訊息在核准前被忽略。

```bash
openclaw pairing list line
openclaw pairing approve line <CODE>
```

Allowlist 和政策：

- `channels.line.dmPolicy`：`pairing | allowlist | open | disabled`
- `channels.line.allowFrom`：DM 的允許清單 LINE 用戶 ID
- `channels.line.groupPolicy`：`allowlist | open | disabled`
- `channels.line.groupAllowFrom`：群組的允許清單 LINE 用戶 ID
- 每群組覆蓋：`channels.line.groups.<groupId>.allowFrom`
- 執行時注意：若 `channels.line` 完全缺失，執行時退回到 `groupPolicy="allowlist"` 進行群組檢查（即使設定了 `channels.defaults.groupPolicy`）。

LINE ID 區分大小寫。有效 ID 看起來像：

- 用戶：`U` + 32 個十六進位字元
- 群組：`C` + 32 個十六進位字元
- 聊天室：`R` + 32 個十六進位字元

## 訊息行為

- 文字在 5000 字元處分塊。
- Markdown 格式被去除；程式碼區塊和表格在可能時轉換為 Flex 卡片。
- 串流回覆被緩衝；LINE 在 Agent 工作時接收完整分塊，並帶有載入動畫。
- 媒體下載受 `channels.line.mediaMaxMb` 限制（預設 10）。

## 頻道資料（富訊息）

使用 `channelData.line` 傳送快速回覆、位置、Flex 卡片或範本訊息。

```json5
{
  text: "Here you go",
  channelData: {
    line: {
      quickReplies: ["Status", "Help"],
      location: {
        title: "Office",
        address: "123 Main St",
        latitude: 35.681236,
        longitude: 139.767125,
      },
      flexMessage: {
        altText: "Status card",
        contents: {
          /* Flex payload */
        },
      },
      templateMessage: {
        type: "confirm",
        text: "Proceed?",
        confirmLabel: "Yes",
        confirmData: "yes",
        cancelLabel: "No",
        cancelData: "no",
      },
    },
  },
}
```

LINE 外掛也附帶 `/card` 指令用於 Flex 訊息預設：

```
/card info "Welcome" "Thanks for joining!"
```

## 疑難排解

- **Webhook 驗證失敗：** 確保 Webhook URL 為 HTTPS，且 `channelSecret` 與 LINE 主控台中的一致。
- **無入站事件：** 確認 Webhook 路徑符合 `channels.line.webhookPath`，且 Gateway 可從 LINE 連接。
- **媒體下載錯誤：** 若媒體超過預設限制，提高 `channels.line.mediaMaxMb`。
