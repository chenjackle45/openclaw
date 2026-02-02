---
title: "Slack"
summary: "Slack socket 或 HTTP webhook 模式設定"
read_when: "設定 Slack 或除錯 Slack socket/HTTP 模式"
---

# Slack

## Socket 模式（預設）

### 快速設定（初學者）

1. 建立 Slack 應用程式並啟用 **Socket Mode**。
2. 建立 **App Token**（`xapp-...`）和 **Bot Token**（`xoxb-...`）。
3. 為 OpenClaw 設定令牌並啟動 Gateway。

最小設定：

```json5
{
  channels: {
    slack: {
      enabled: true,
      appToken: "xapp-...",
      botToken: "xoxb-...",
    },
  },
}
```

### 設定

1. 在 https://api.slack.com/apps 建立 Slack 應用程式（從頭建立）。
2. **Socket Mode** → 切換開啟。然後前往 **Basic Information** → **App-Level Tokens** → **Generate Token and Scopes**，範圍為 `connections:write`。複製 **App Token**（`xapp-...`）。
3. **OAuth & Permissions** → 新增機器人令牌範圍（使用下面的 manifest）。點擊 **Install to Workspace**。複製 **Bot User OAuth Token**（`xoxb-...`）。
4. 可選：**OAuth & Permissions** → 新增 **User Token Scopes**。重新安裝應用程式並複製 **User OAuth Token**（`xoxp-...`）。
5. **Event Subscriptions** → 啟用事件並訂閱：
   - `message.*`（包含編輯/刪除/討論串廣播）
   - `app_mention`
   - `reaction_added`、`reaction_removed`
   - `member_joined_channel`、`member_left_channel`
   - `channel_rename`
   - `pin_added`、`pin_removed`
6. 邀請機器人到您想要它讀取的頻道。
7. Slash Commands → 如果您使用 `channels.slack.slashCommand`，建立 `/openclaw`。
8. App Home → 啟用 **Messages Tab** 以便用戶可以私訊機器人。

使用下面的 manifest 以便範圍和事件保持同步。

多帳戶支援：使用 `channels.slack.accounts` 設定每個帳戶的令牌和可選的 `name`。

### OpenClaw 設定（最小）

透過環境變數設定令牌（建議）：

- `SLACK_APP_TOKEN=xapp-...`
- `SLACK_BOT_TOKEN=xoxb-...`

或透過設定：

```json5
{
  channels: {
    slack: {
      enabled: true,
      appToken: "xapp-...",
      botToken: "xoxb-...",
    },
  },
}
```

### 用戶令牌（可選）

OpenClaw 可以使用 Slack 用戶令牌（`xoxp-...`）進行讀取操作。預設情況下這保持唯讀。

用戶令牌在設定檔案中設定（不支援環境變數）。對於多帳戶，設定 `channels.slack.accounts.<id>.userToken`。

帶有機器人 + 應用程式 + 用戶令牌的範例：

```json5
{
  channels: {
    slack: {
      enabled: true,
      appToken: "xapp-...",
      botToken: "xoxb-...",
      userToken: "xoxp-...",
    },
  },
}
```

### 歷史上下文

- `channels.slack.historyLimit`（或 `channels.slack.accounts.*.historyLimit`）控制有多少最近的頻道/群組訊息被包裝到提示中。
- 回退到 `messages.groupChat.historyLimit`。設定 `0` 停用（預設 50）。

## HTTP 模式（Events API）

當您的 Gateway 可透過 HTTPS 被 Slack 存取時（典型的伺服器部署），使用 HTTP webhook 模式。

### 設定

1. 建立 Slack 應用程式並**停用 Socket Mode**（如果您只使用 HTTP 則為可選）。
2. **Basic Information** → 複製 **Signing Secret**。
3. **OAuth & Permissions** → 安裝應用程式並複製 **Bot User OAuth Token**（`xoxb-...`）。
4. **Event Subscriptions** → 啟用事件並將 **Request URL** 設定為您的 Gateway webhook 路徑（預設 `/slack/events`）。
5. **Interactivity & Shortcuts** → 啟用並設定相同的 **Request URL**。
6. **Slash Commands** → 為您的命令設定相同的 **Request URL**。

範例請求 URL：
`https://gateway-host/slack/events`

### OpenClaw 設定（最小）

```json5
{
  channels: {
    slack: {
      enabled: true,
      mode: "http",
      botToken: "xoxb-...",
      signingSecret: "your-signing-secret",
      webhookPath: "/slack/events",
    },
  },
}
```

## 限制

- 外發文字分塊至 `channels.slack.textChunkLimit`（預設 4000）。
- 可選的換行分塊：設定 `channels.slack.chunkMode="newline"` 在長度分塊前在空白行（段落邊界）分割。
- 媒體上傳由 `channels.slack.mediaMaxMb` 限制（預設 20）。

## 回覆串連

預設情況下，OpenClaw 在主頻道回覆。使用 `channels.slack.replyToMode` 控制自動串連：

| 模式 | 行為 |
| --- | --- |
| `off` | **預設。** 在主頻道回覆。僅當觸發訊息已在討論串中時才串連。 |
| `first` | 第一個回覆進入討論串（在觸發訊息下），後續回覆進入主頻道。 |
| `all` | 所有回覆進入討論串。 |

## 私訊安全（配對）

- 預設：`channels.slack.dm.policy="pairing"` — 未知私訊發送者收到配對碼。
- 透過以下方式批准：`openclaw pairing approve slack <code>`。
- 要允許任何人：設定 `channels.slack.dm.policy="open"` 和 `channels.slack.dm.allowFrom=["*"]`。

## 備註

- 提及閘門透過 `channels.slack.channels` 控制。
- 機器人撰寫的訊息預設被忽略；透過 `channels.slack.allowBots` 啟用。
- 當允許且在大小限制內時，附件會下載到媒體儲存。
