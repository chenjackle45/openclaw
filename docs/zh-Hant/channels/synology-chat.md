---
summary: "Synology Chat webhook 設定和 OpenClaw 設定"
read_when:
  - 使用 OpenClaw 設定 Synology Chat
  - 偵錯 Synology Chat webhook 路由
title: "Synology Chat"
---

# Synology Chat（外掛程式）

狀態：透過外掛程式支援，作為使用 Synology Chat webhook 的直接訊息頻道。
外掛程式接受來自 Synology Chat 傳出 webhook 的傳入訊息，並透過 Synology Chat 傳入 webhook 傳送回覆。

## 需要外掛程式

Synology Chat 是外掛程式式的，不是預設核心頻道安裝的一部分。

從本機簽出安裝：

```bash
openclaw plugins install ./extensions/synology-chat
```

詳細資訊：[Plugins](/zh-Hant/tools/plugin)

## 快速設定

1. 安裝並啟用 Synology Chat 外掛程式。
2. 在 Synology Chat 整合中：
   - 建立傳入 webhook 並複製其 URL。
   - 建立帶有您密鑰的傳出 webhook。
3. 指向傳出 webhook URL 到您的 OpenClaw Gateway：
   - 預設為 `https://gateway-host/webhook/synology`。
   - 或您的自訂 `channels.synology-chat.webhookPath`。
4. 在 OpenClaw 中設定 `channels.synology-chat`。
5. 重新啟動 Gateway 並向 Synology Chat bot 傳送 DM。

最小設定：

```json5
{
  channels: {
    "synology-chat": {
      enabled: true,
      token: "synology-outgoing-token",
      incomingUrl: "https://nas.example.com/webapi/entry.cgi?api=SYNO.Chat.External&method=incoming&version=2&token=...",
      webhookPath: "/webhook/synology",
      dmPolicy: "allowlist",
      allowedUserIds: ["123456"],
      rateLimitPerMinute: 30,
      allowInsecureSsl: false,
    },
  },
}
```

## 環境變數

對於預設帳戶，您可以使用環境變數：

- `SYNOLOGY_CHAT_TOKEN`
- `SYNOLOGY_CHAT_INCOMING_URL`
- `SYNOLOGY_NAS_HOST`
- `SYNOLOGY_ALLOWED_USER_IDS`（逗號分隔）
- `SYNOLOGY_RATE_LIMIT`
- `OPENCLAW_BOT_NAME`

設定值覆蓋環境變數。

## DM 政策和存取控制

- `dmPolicy: "allowlist"` 是建議的預設。
- `allowedUserIds` 接受清單（或逗號分隔字串）的 Synology 使用者 ID。
- 在 `allowlist` 模式中，空 `allowedUserIds` 清單被視為誤配置，webhook 路由將不會啟動（使用 `dmPolicy: "open"` 用於允許所有）。
- `dmPolicy: "open"` 允許任何傳送者。
- `dmPolicy: "disabled"` 阻止 DM。
- 配對批准適用於：
  - `openclaw pairing list synology-chat`
  - `openclaw pairing approve synology-chat <CODE>`

## 傳出傳遞

使用數字 Synology Chat 使用者 ID 作為目標。

範例：

```bash
openclaw message send --channel synology-chat --target 123456 --text "Hello from OpenClaw"
openclaw message send --channel synology-chat --target synology-chat:123456 --text "Hello again"
```

媒體傳送由基於 URL 的檔案傳遞支援。

## 多帳戶

多個 Synology Chat 帳戶在 `channels.synology-chat.accounts` 下支援。
每個帳戶可以覆蓋 Token、傳入 URL、webhook 路徑、DM 政策和限制。

```json5
{
  channels: {
    "synology-chat": {
      enabled: true,
      accounts: {
        default: {
          token: "token-a",
          incomingUrl: "https://nas-a.example.com/...token=...",
        },
        alerts: {
          token: "token-b",
          incomingUrl: "https://nas-b.example.com/...token=...",
          webhookPath: "/webhook/synology-alerts",
          dmPolicy: "allowlist",
          allowedUserIds: ["987654"],
        },
      },
    },
  },
}
```

## 安全注

- 保持 `token` 機密並在洩露時輪換它。
- 保持 `allowInsecureSsl: false`，除非您明確信任自簽名本機 NAS 證書。
- 傳入 webhook 請求經過 Token 驗證和每個傳送者速率限制。
- 生產環境偏好 `dmPolicy: "allowlist"`。
