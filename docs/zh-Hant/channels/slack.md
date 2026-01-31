---
title: "Slack(Slack)"
summary: "Slack socket 或 HTTP webhook 模式設定"
read_when:
  - 設定 Slack 或除錯 Slack socket/HTTP 模式
---
# Slack（Slack 應用程式）

## Socket 模式（預設）

### 快速設定（初學者）
1) 建立 Slack 應用程式並啟用 **Socket Mode**。
2) 建立 **App Token**（`xapp-...`）和 **Bot Token**（`xoxb-...`）。
3) 為 OpenClaw 設定令牌並啟動 Gateway。

最小設定：
```json5
{
  channels: {
    slack: {
      enabled: true,
      appToken: "xapp-...",
      botToken: "xoxb-..."
    }
  }
}
```

### 設定
1) 在 https://api.slack.com/apps 建立 Slack 應用程式（從頭建立）。
2) **Socket Mode** → 切換開啟。然後前往 **Basic Information** → **App-Level Tokens** → **Generate Token and Scopes**，範圍為 `connections:write`。複製 **App Token**（`xapp-...`）。
3) **OAuth & Permissions** → 新增機器人令牌範圍（使用下面的 manifest）。點擊 **Install to Workspace**。複製 **Bot User OAuth Token**（`xoxb-...`）。
4) 可選：**OAuth & Permissions** → 新增 **User Token Scopes**（請參閱下面的唯讀列表）。重新安裝應用程式並複製 **User OAuth Token**（`xoxp-...`）。
5) **Event Subscriptions** → 啟用事件並訂閱：
   - `message.*`（包含編輯/刪除/討論串廣播）
   - `app_mention`
   - `reaction_added`、`reaction_removed`
   - `member_joined_channel`、`member_left_channel`
   - `channel_rename`
   - `pin_added`、`pin_removed`
6) 邀請機器人到您想要它讀取的頻道。
7) Slash Commands → 如果您使用 `channels.slack.slashCommand`，建立 `/openclaw`。如果您啟用原生命令，為每個內建命令新增一個斜線命令（與 `/help` 名稱相同）。原生預設為 Slack 關閉，除非您設定 `channels.slack.commands.native: true`（全域 `commands.native` 為 `"auto"`，保持 Slack 關閉）。
8) App Home → 啟用 **Messages Tab** 以便用戶可以私訊機器人。

使用下面的 manifest 以便範圍和事件保持同步。

多帳戶支援：使用 `channels.slack.accounts` 設定每個帳戶的令牌和可選的 `name`。請參閱 [`gateway/configuration`](/gateway/configuration#telegramaccounts--discordaccounts--slackaccounts--signalaccounts--imessageaccounts) 了解共享模式。

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
      botToken: "xoxb-..."
    }
  }
}
```

### 用戶令牌（可選）
OpenClaw 可以使用 Slack 用戶令牌（`xoxp-...`）進行讀取操作（歷史記錄、釘選、反應、表情符號、成員資訊）。預設情況下這保持唯讀：讀取時如果存在用戶令牌則優先使用，寫入仍使用機器人令牌，除非您明確選擇加入。即使設定 `userTokenReadOnly: false`，當機器人令牌可用時仍優先用於寫入。

用戶令牌在設定檔案中設定（不支援環境變數）。對於多帳戶，設定 `channels.slack.accounts.<id>.userToken`。

帶有機器人 + 應用程式 + 用戶令牌的範例：
```json5
{
  channels: {
    slack: {
      enabled: true,
      appToken: "xapp-...",
      botToken: "xoxb-...",
      userToken: "xoxp-..."
    }
  }
}
```

明確設定 userTokenReadOnly 的範例（允許用戶令牌寫入）：
```json5
{
  channels: {
    slack: {
      enabled: true,
      appToken: "xapp-...",
      botToken: "xoxb-...",
      userToken: "xoxp-...",
      userTokenReadOnly: false
    }
  }
}
```

#### 令牌使用
- 讀取操作（歷史記錄、反應列表、釘選列表、表情符號列表、成員資訊、搜尋）設定時優先使用用戶令牌，否則使用機器人令牌。
- 寫入操作（發送/編輯/刪除訊息、新增/移除反應、釘選/取消釘選、檔案上傳）預設使用機器人令牌。如果 `userTokenReadOnly: false` 且沒有機器人令牌可用，OpenClaw 回退到用戶令牌。

### 歷史上下文
- `channels.slack.historyLimit`（或 `channels.slack.accounts.*.historyLimit`）控制有多少最近的頻道/群組訊息被包裝到提示中。
- 回退到 `messages.groupChat.historyLimit`。設定 `0` 停用（預設 50）。

## HTTP 模式（Events API）
當您的 Gateway 可透過 HTTPS 被 Slack 存取時（典型的伺服器部署），使用 HTTP webhook 模式。
HTTP 模式使用 Events API + Interactivity + Slash Commands，共享請求 URL。

### 設定
1) 建立 Slack 應用程式並**停用 Socket Mode**（如果您只使用 HTTP 則為可選）。
2) **Basic Information** → 複製 **Signing Secret**。
3) **OAuth & Permissions** → 安裝應用程式並複製 **Bot User OAuth Token**（`xoxb-...`）。
4) **Event Subscriptions** → 啟用事件並將 **Request URL** 設定為您的 Gateway webhook 路徑（預設 `/slack/events`）。
5) **Interactivity & Shortcuts** → 啟用並設定相同的 **Request URL**。
6) **Slash Commands** → 為您的命令設定相同的 **Request URL**。

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
      webhookPath: "/slack/events"
    }
  }
}
```

多帳戶 HTTP 模式：設定 `channels.slack.accounts.<id>.mode = "http"` 並為每個帳戶提供唯一的 `webhookPath`，以便每個 Slack 應用程式可以指向自己的 URL。

### Manifest（可選）
使用此 Slack 應用程式 manifest 快速建立應用程式（如果需要可調整名稱/命令）。如果您計劃設定用戶令牌，請包含用戶範圍。

```json
{
  "display_information": {
    "name": "OpenClaw",
    "description": "OpenClaw 的 Slack 連接器"
  },
  "features": {
    "bot_user": {
      "display_name": "OpenClaw",
      "always_online": false
    },
    "app_home": {
      "messages_tab_enabled": true,
      "messages_tab_read_only_enabled": false
    },
    "slash_commands": [
      {
        "command": "/openclaw",
        "description": "向 OpenClaw 發送訊息",
        "should_escape": false
      }
    ]
  },
  "oauth_config": {
    "scopes": {
      "bot": [
        "chat:write",
        "channels:history",
        "channels:read",
        "groups:history",
        "groups:read",
        "groups:write",
        "im:history",
        "im:read",
        "im:write",
        "mpim:history",
        "mpim:read",
        "mpim:write",
        "users:read",
        "app_mentions:read",
        "reactions:read",
        "reactions:write",
        "pins:read",
        "pins:write",
        "emoji:read",
        "commands",
        "files:read",
        "files:write"
      ],
      "user": [
        "channels:history",
        "channels:read",
        "groups:history",
        "groups:read",
        "im:history",
        "im:read",
        "mpim:history",
        "mpim:read",
        "users:read",
        "reactions:read",
        "pins:read",
        "emoji:read",
        "search:read"
      ]
    }
  },
  "settings": {
    "socket_mode_enabled": true,
    "event_subscriptions": {
      "bot_events": [
        "app_mention",
        "message.channels",
        "message.groups",
        "message.im",
        "message.mpim",
        "reaction_added",
        "reaction_removed",
        "member_joined_channel",
        "member_left_channel",
        "channel_rename",
        "pin_added",
        "pin_removed"
      ]
    }
  }
}
```

如果您啟用原生命令，為每個您想要公開的命令新增一個 `slash_commands` 條目（與 `/help` 列表匹配）。使用 `channels.slack.commands.native` 覆寫。

## 範圍（當前 vs 可選）
Slack 的 Conversations API 是類型範圍的：您只需要您實際接觸的對話類型的範圍（channels、groups、im、mpim）。請參閱 https://docs.slack.dev/apis/web-api/using-the-conversations-api/ 了解概述。

### 機器人令牌範圍（必需）
- `chat:write`（透過 `chat.postMessage` 發送/更新/刪除訊息）
- `im:write`（透過 `conversations.open` 開啟用戶私訊）
- `channels:history`、`groups:history`、`im:history`、`mpim:history`
- `channels:read`、`groups:read`、`im:read`、`mpim:read`
- `users:read`（用戶查詢）
- `reactions:read`、`reactions:write`（`reactions.get` / `reactions.add`）
- `pins:read`、`pins:write`（`pins.list` / `pins.add` / `pins.remove`）
- `emoji:read`（`emoji.list`）
- `files:write`（透過 `files.uploadV2` 上傳）

### 用戶令牌範圍（可選，預設唯讀）
如果您設定 `channels.slack.userToken`，請在 **User Token Scopes** 下新增這些。

- `channels:history`、`groups:history`、`im:history`、`mpim:history`
- `channels:read`、`groups:read`、`im:read`、`mpim:read`
- `users:read`
- `reactions:read`
- `pins:read`
- `emoji:read`
- `search:read`

### 今天不需要（但可能未來需要）
- `mpim:write`（僅當我們新增群組私訊開啟/私訊透過 `conversations.open` 開始）
- `groups:write`（僅當我們新增私人頻道管理：建立/重新命名/邀請/封存）
- `chat:write.public`（僅當我們想要發送到機器人不在的頻道）
- `users:read.email`（僅當我們需要 `users.info` 的電子郵件欄位）
- `files:read`（僅當我們開始列出/讀取檔案元資料）

## 設定
Slack 僅使用 Socket Mode（無 HTTP webhook 伺服器）。提供兩個令牌：

```json
{
  "slack": {
    "enabled": true,
    "botToken": "xoxb-...",
    "appToken": "xapp-...",
    "groupPolicy": "allowlist",
    "dm": {
      "enabled": true,
      "policy": "pairing",
      "allowFrom": ["U123", "U456", "*"],
      "groupEnabled": false,
      "groupChannels": ["G123"],
      "replyToMode": "all"
    },
    "channels": {
      "C123": { "allow": true, "requireMention": true },
      "#general": {
        "allow": true,
        "requireMention": true,
        "users": ["U123"],
        "skills": ["search", "docs"],
        "systemPrompt": "保持回答簡短。"
      }
    },
    "reactionNotifications": "own",
    "reactionAllowlist": ["U123"],
    "replyToMode": "off",
    "actions": {
      "reactions": true,
      "messages": true,
      "pins": true,
      "memberInfo": true,
      "emojiList": true
    },
    "slashCommand": {
      "enabled": true,
      "name": "openclaw",
      "sessionPrefix": "slack:slash",
      "ephemeral": true
    },
    "textChunkLimit": 4000,
    "mediaMaxMb": 20
  }
}
```

令牌也可以透過環境變數提供：
- `SLACK_BOT_TOKEN`
- `SLACK_APP_TOKEN`

確認反應透過 `messages.ackReaction` + `messages.ackReactionScope` 全域控制。使用 `messages.removeAckAfterReply` 在機器人回覆後清除確認反應。

## 限制
- 外發文字分塊至 `channels.slack.textChunkLimit`（預設 4000）。
- 可選的換行分塊：設定 `channels.slack.chunkMode="newline"` 在長度分塊前在空白行（段落邊界）分割。
- 媒體上傳由 `channels.slack.mediaMaxMb` 限制（預設 20）。

## 回覆串連
預設情況下，OpenClaw 在主頻道回覆。使用 `channels.slack.replyToMode` 控制自動串連：

| 模式 | 行為 |
| --- | --- |
| `off` | **預設。** 在主頻道回覆。僅當觸發訊息已在討論串中時才串連。 |
| `first` | 第一個回覆進入討論串（在觸發訊息下），後續回覆進入主頻道。適合保持上下文可見同時避免討論串雜亂。 |
| `all` | 所有回覆進入討論串。保持對話包含但可能降低可見性。 |

該模式同時適用於自動回覆和代理工具呼叫（`slack sendMessage`）。

### 每聊天類型串連
您可以透過設定 `channels.slack.replyToModeByChatType` 為每個聊天類型設定不同的串連行為：

```json5
{
  channels: {
    slack: {
      replyToMode: "off",        // 頻道的預設
      replyToModeByChatType: {
        direct: "all",           // 私訊始終串連
        group: "first"           // 群組私訊/MPIM 第一個回覆串連
      },
    }
  }
}
```

支援的聊天類型：
- `direct`：1:1 私訊（Slack `im`）
- `group`：群組私訊 / MPIM（Slack `mpim`）
- `channel`：標準頻道（公開/私人）

優先級：
1) `replyToModeByChatType.<chatType>`
2) `replyToMode`
3) 供應商預設（`off`）

舊版 `channels.slack.dm.replyToMode` 仍被接受作為 `direct` 的備選，當沒有設定聊天類型覆寫時。

### 手動串連標籤
對於細粒度控制，在代理回應中使用這些標籤：
- `[[reply_to_current]]` — 回覆觸發訊息（開始/繼續討論串）。
- `[[reply_to:<id>]]` — 回覆特定訊息 ID。

## 會話 + 路由
- 私訊共享 `main` 會話（如 WhatsApp/Telegram）。
- 頻道對應到 `agent:<agentId>:slack:channel:<channelId>` 會話。
- 斜線命令使用 `agent:<agentId>:slack:slash:<userId>` 會話（前綴可透過 `channels.slack.slashCommand.sessionPrefix` 設定）。
- 如果 Slack 不提供 `channel_type`，OpenClaw 從頻道 ID 前綴（`D`、`C`、`G`）推斷它並預設為 `channel` 以保持會話鍵穩定。
- 原生命令註冊使用 `commands.native`（全域預設 `"auto"` → Slack 關閉），可以使用 `channels.slack.commands.native` 按工作區覆寫。文字命令需要獨立的 `/...` 訊息，可以使用 `commands.text: false` 停用。Slack 斜線命令在 Slack 應用程式中管理，不會自動移除。使用 `commands.useAccessGroups: false` 繞過命令的存取群組檢查。
- 完整命令列表 + 設定：[斜線命令](/tools/slash-commands)

## 私訊安全（配對）
- 預設：`channels.slack.dm.policy="pairing"` — 未知私訊發送者收到配對碼（1 小時後過期）。
- 透過以下方式批准：`openclaw pairing approve slack <code>`。
- 要允許任何人：設定 `channels.slack.dm.policy="open"` 和 `channels.slack.dm.allowFrom=["*"]`。
- `channels.slack.dm.allowFrom` 接受用戶 ID、@handles 或電子郵件（令牌允許時在啟動時解析）。精靈接受用戶名並在令牌允許時在設定期間將其解析為 ID。

## 群組策略
- `channels.slack.groupPolicy` 控制頻道處理（`open|disabled|allowlist`）。
- `allowlist` 需要頻道列在 `channels.slack.channels` 中。
- 如果您只設定 `SLACK_BOT_TOKEN`/`SLACK_APP_TOKEN` 且從未建立 `channels.slack` 區塊，運行時會將 `groupPolicy` 預設為 `open`。新增 `channels.slack.groupPolicy`、`channels.defaults.groupPolicy` 或頻道允許清單以鎖定它。
- 設定精靈接受 `#channel` 名稱並在可能時將其解析為 ID（公開 + 私人）；如果存在多個匹配，它優先選擇活躍頻道。
- 在啟動時，OpenClaw 將允許清單中的頻道/用戶名稱解析為 ID（當令牌允許時）並記錄映射；未解析的條目保持原樣。
- 要允許**無頻道**，設定 `channels.slack.groupPolicy: "disabled"`（或保持空允許清單）。

頻道選項（`channels.slack.channels.<id>` 或 `channels.slack.channels.<name>`）：
- `allow`：當 `groupPolicy="allowlist"` 時允許/拒絕頻道。
- `requireMention`：頻道的提及閘門。
- `tools`：可選的每頻道工具策略覆寫（`allow`/`deny`/`alsoAllow`）。
- `toolsBySender`：可選的頻道內每發送者工具策略覆寫（鍵為發送者 ID/@handles/電子郵件；支援 `"*"` 萬用字元）。
- `allowBots`：允許此頻道中機器人撰寫的訊息（預設：false）。
- `users`：可選的每頻道用戶允許清單。
- `skills`：技能過濾器（省略 = 所有技能，空 = 無）。
- `systemPrompt`：頻道的額外系統提示（與主題/目的結合）。
- `enabled`：設為 `false` 以停用頻道。

## 交付目標
與 cron/CLI 發送一起使用：
- `user:<id>` 用於私訊
- `channel:<id>` 用於頻道

## 工具動作
Slack 工具動作可以使用 `channels.slack.actions.*` 閘門控制：

| 動作群組 | 預設 | 備註 |
| --- | --- | --- |
| reactions | 啟用 | 反應 + 列出反應 |
| messages | 啟用 | 讀取/發送/編輯/刪除 |
| pins | 啟用 | 釘選/取消釘選/列出 |
| memberInfo | 啟用 | 成員資訊 |
| emojiList | 啟用 | 自訂表情符號列表 |

## 安全備註
- 寫入預設使用機器人令牌，以便狀態更改動作保持在應用程式的機器人權限和身份範圍內。
- 設定 `userTokenReadOnly: false` 允許在機器人令牌不可用時使用用戶令牌進行寫入操作，這意味著動作以安裝用戶的存取權限運行。將用戶令牌視為高權限，並保持動作閘門和允許清單嚴格。
- 如果您啟用用戶令牌寫入，請確保用戶令牌包含您期望的寫入範圍（`chat:write`、`reactions:write`、`pins:write`、`files:write`），否則這些操作將失敗。

## 備註
- 提及閘門透過 `channels.slack.channels` 控制（將 `requireMention` 設為 `true`）；`agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）也計為提及。
- 多代理覆寫：在 `agents.list[].groupChat.mentionPatterns` 上設定每代理模式。
- 反應通知遵循 `channels.slack.reactionNotifications`（使用 `reactionAllowlist` 與模式 `allowlist`）。
- 機器人撰寫的訊息預設被忽略；透過 `channels.slack.allowBots` 或 `channels.slack.channels.<id>.allowBots` 啟用。
- 警告：如果您允許回覆其他機器人（`channels.slack.allowBots=true` 或 `channels.slack.channels.<id>.allowBots=true`），請使用 `requireMention`、`channels.slack.channels.<id>.users` 允許清單和/或在 `AGENTS.md` 和 `SOUL.md` 中設定清晰的護欄來防止機器人對機器人的回覆循環。
- 對於 Slack 工具，反應移除語意在 [/tools/reactions](/tools/reactions) 中。
- 當允許且在大小限制內時，附件會下載到媒體儲存。
