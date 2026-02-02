---
summary: "LINE Messaging API plugin setup, config, and usage"
read_when:
  - You want to connect OpenClaw to LINE
  - You need LINE webhook + credential setup
  - You want LINE-specific message options
title: LINE
---

# LINE (plugin)

LINE 透過 LINE Messaging API 連接至 OpenClaw。此外掛在 Gateway 上作為 Webhook 接收器執行，並使用您的頻道存取令牌 + 頻道密鑰進行驗證。

狀態：透過外掛支援。支援直接訊息、群組聊天、媒體、位置、Flex 訊息、範本訊息和快速回覆。不支援反應和執行緒。

## 需要外掛

安裝 LINE 外掛：

```bash
openclaw plugins install @openclaw/line
```

本地簽出（從 git repo 執行時）：

```bash
openclaw plugins install ./extensions/line
```

## 設定

1. 建立 LINE 開發人員帳號並開啟主控台：
   https://developers.line.biz/console/
2. 建立（或選擇）提供商並新增 **Messaging API** 頻道。
3. 從頻道設定複製 **Channel access token** 和 **Channel secret**。
4. 在 Messaging API 設定中啟用 **Use webhook**。
5. 將 Webhook URL 設定為您的 Gateway 端點（需要 HTTPS）：

```
https://gateway-host/line/webhook
```

Gateway 回應 LINE 的 Webhook 驗證 (GET) 和入站事件 (POST)。
如果您需要自訂路徑，設定 `channels.line.webhookPath` 或
`channels.line.accounts.<id>.webhookPath` 並相應更新 URL。

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

環境變數（僅限預設帳號）：

- `LINE_CHANNEL_ACCESS_TOKEN`
- `LINE_CHANNEL_SECRET`

令牌/密鑰檔案：

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

多個帳號：

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

直接訊息預設使用配對。未知發送者獲得配對碼，其訊息在批准前被忽略。

```bash
openclaw pairing list line
openclaw pairing approve line <CODE>
```

允許清單和政策：

- `channels.line.dmPolicy`：`pairing | allowlist | open | disabled`
- `channels.line.allowFrom`：DM 的允許清單 LINE 使用者 ID
- `channels.line.groupPolicy`：`allowlist | open | disabled`
- `channels.line.groupAllowFrom`：群組的允許清單 LINE 使用者 ID
- 每群組覆蓋：`channels.line.groups.<groupId>.allowFrom`

LINE ID 區分大小寫。有效 ID 看起來像：

- 使用者：`U` + 32 個十六進位字元
- 群組：`C` + 32 個十六進位字元
- 聊天室：`R` + 32 個十六進位字元

## 訊息行為

- 文字在 5000 字元處分塊。
- Markdown 格式被去除；程式碼區塊和表格在可能時轉換為 Flex 卡片。
- 串流回應被緩衝；LINE 在代理工作時接收完整分塊，帶有載入動畫。
- 媒體下載由 `channels.line.mediaMaxMb`（預設 10）上限。

## 頻道資料（豐富訊息）

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

LINE 外掛也附帶了 `/card` 命令用於 Flex 訊息預設：

```
/card info "Welcome" "Thanks for joining!"
```

## 故障排除

- **Webhook 驗證失敗：** 確保 Webhook URL 是 HTTPS 且
  `channelSecret` 與 LINE 主控台相符。
- **無入站事件：** 確認 Webhook 路徑與 `channels.line.webhookPath` 相符
  且 Gateway 可從 LINE 到達。
- **媒體下載錯誤：** 如果媒體超過預設限制，提高 `channels.line.mediaMaxMb`。
