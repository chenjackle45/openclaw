---
summary: "Slack 設定與執行時行為（Socket Mode + HTTP Events API）"
read_when: "設定 Slack 或除錯 Slack socket/HTTP 模式"
title: "Slack"
---

# Slack

狀態：透過 Slack app 整合支援 DM + 頻道，已可正式使用。預設模式為 Socket Mode；也支援 HTTP Events API 模式。

<CardGroup cols={3}>
  <Card title="Pairing（配對）" icon="link" href="/zh-Hant/channels/pairing">
    Slack DM 預設使用配對模式。
  </Card>
  <Card title="Slash commands（斜線指令）" icon="terminal" href="/zh-Hant/tools/slash-commands">
    原生指令行為與指令目錄。
  </Card>
  <Card title="Channel troubleshooting（頻道疑難排解）" icon="wrench" href="/zh-Hant/channels/troubleshooting">
    跨頻道診斷與修復手冊。
  </Card>
</CardGroup>

## 快速設定

<Tabs>
  <Tab title="Socket Mode（預設）">
    <Steps>
      <Step title="建立 Slack app 和 token">
        在 Slack app 設定中：

        - 啟用 **Socket Mode**
        - 建立 **App Token**（`xapp-...`），具有 `connections:write` 權限
        - 安裝 app 並複製 **Bot Token**（`xoxb-...`）
      </Step>

      <Step title="設定 OpenClaw">

```json5
{
  channels: {
    slack: {
      enabled: true,
      mode: "socket",
      appToken: "xapp-...",
      botToken: "xoxb-...",
    },
  },
}
```

        環境變數備用（僅預設帳號）：

```bash
SLACK_APP_TOKEN=xapp-...
SLACK_BOT_TOKEN=xoxb-...
```

      </Step>

      <Step title="訂閱 app 事件">
        訂閱 bot 事件：

        - `app_mention`
        - `message.channels`、`message.groups`、`message.im`、`message.mpim`
        - `reaction_added`、`reaction_removed`
        - `member_joined_channel`、`member_left_channel`
        - `channel_rename`
        - `pin_added`、`pin_removed`

        同時在 App Home 中啟用 **Messages Tab** 以支援 DM。
      </Step>

      <Step title="啟動 gateway">

```bash
openclaw gateway
```

      </Step>
    </Steps>

  </Tab>

  <Tab title="HTTP Events API 模式">
    <Steps>
      <Step title="為 HTTP 設定 Slack app">

        - 將模式設定為 HTTP（`channels.slack.mode="http"`）
        - 複製 Slack **Signing Secret**
        - 將 Event Subscriptions + Interactivity + Slash command Request URL 設定為相同的 webhook 路徑（預設 `/slack/events`）

      </Step>

      <Step title="設定 OpenClaw HTTP 模式">

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

      </Step>

      <Step title="多帳號 HTTP 使用唯一 webhook 路徑">
        支援每帳號 HTTP 模式。

        為每個帳號指定不同的 `webhookPath` 以避免衝突。
      </Step>
    </Steps>

  </Tab>
</Tabs>

## Token 模型

- Socket Mode 需要 `botToken` + `appToken`。
- HTTP 模式需要 `botToken` + `signingSecret`。
- 設定中的 token 優先於環境變數備用。
- `SLACK_BOT_TOKEN` / `SLACK_APP_TOKEN` 環境變數備用只適用於預設帳號。
- `userToken`（`xoxp-...`）僅限設定（無環境變數備用），預設為只讀行為（`userTokenReadOnly: true`）。
- 選用：若想讓出站訊息使用活動的 agent 身份（自訂 `username` 和圖示），新增 `chat:write.customize`。`icon_emoji` 使用 `:emoji_name:` 語法。

<Tip>
對於動作/目錄讀取，設定了 user token 時可優先使用。對於寫入，bot token 保持優先；只有在 `userTokenReadOnly: false` 且 bot token 不可用時，才允許 user-token 寫入。
</Tip>

## 存取控制與路由

<Tabs>
  <Tab title="DM 政策">
    `channels.slack.dmPolicy` 控制 DM 存取（舊版：`channels.slack.dm.policy`）：

    - `pairing`（預設）
    - `allowlist`
    - `open`（需要 `channels.slack.allowFrom` 包含 `"*"`；舊版：`channels.slack.dm.allowFrom`）
    - `disabled`

    DM 旗標：

    - `dm.enabled`（預設 true）
    - `channels.slack.allowFrom`（建議使用）
    - `dm.allowFrom`（舊版）
    - `dm.groupEnabled`（群組 DM 預設 false）
    - `dm.groupChannels`（選用 MPIM allowlist）

    多帳號優先順序：

    - `channels.slack.accounts.default.allowFrom` 只適用於 `default` 帳號。
    - 具名帳號在未設定自己的 `allowFrom` 時繼承 `channels.slack.allowFrom`。
    - 具名帳號不繼承 `channels.slack.accounts.default.allowFrom`。

    DM 中的配對使用 `openclaw pairing approve slack <code>`。

  </Tab>

  <Tab title="頻道政策">
    `channels.slack.groupPolicy` 控制頻道處理：

    - `open`
    - `allowlist`
    - `disabled`

    頻道 allowlist 位於 `channels.slack.channels` 下。

    執行時注意：若 `channels.slack` 完全缺失（僅環境變數設定），執行時退回到 `groupPolicy="allowlist"` 並記錄警告（即使設定了 `channels.defaults.groupPolicy`）。

    名稱/ID 解析：

    - 頻道 allowlist 條目和 DM allowlist 條目在啟動時解析（當 token 存取允許時）
    - 未解析的條目保留原樣設定
    - 入站授權匹配預設 ID 優先；直接用戶名/slug 匹配需要 `channels.slack.dangerouslyAllowNameMatching: true`

  </Tab>

  <Tab title="Mentions 和頻道用戶">
    頻道訊息預設以 mention 作為進入條件。

    Mention 來源：

    - 明確的 app mention（`<@botId>`）
    - mention 正規表達式模式（`agents.list[].groupChat.mentionPatterns`，備用 `messages.groupChat.mentionPatterns`）
    - 隱式回覆 bot 串的行為

    每頻道控制（`channels.slack.channels.<id|name>`）：

    - `requireMention`
    - `users`（allowlist）
    - `allowBots`
    - `skills`
    - `systemPrompt`
    - `tools`、`toolsBySender`
    - `toolsBySender` 鍵格式：`id:`、`e164:`、`username:`、`name:` 或 `"*"` 萬用字元
      （舊版無前綴鍵仍只對應到 `id:`）

  </Tab>
</Tabs>

## 指令與斜線行為

- 對 Slack 而言，原生指令自動模式為**關閉**（`commands.native: "auto"` 不啟用 Slack 原生指令）。
- 使用 `channels.slack.commands.native: true`（或全域 `commands.native: true`）啟用原生 Slack 指令處理器。
- 啟用原生指令後，在 Slack 中註冊對應的斜線指令（`/<command>` 名稱），有一個例外：
  - 為狀態指令註冊 `/agentstatus`（Slack 保留 `/status`）
- 若未啟用原生指令，可透過 `channels.slack.slashCommand` 執行單個已設定的斜線指令。
- 原生參數選單現在自動調整呈現策略：
  - 最多 5 個選項：按鈕區塊
  - 6-100 個選項：靜態選擇選單
  - 超過 100 個選項：非同步選項過濾的外部選擇（當可互動性選項處理器可用時）
  - 若編碼的選項值超過 Slack 限制，流程退回到按鈕
- 對於較長的選項 payload，斜線指令參數選單在發送選定值前使用確認對話框。

預設斜線指令設定：

- `enabled: false`
- `name: "openclaw"`
- `sessionPrefix: "slack:slash"`
- `ephemeral: true`

斜線工作階段使用隔離金鑰：

- `agent:<agentId>:slack:slash:<userId>`

並仍然對目標對話工作階段執行指令（`CommandTargetSessionKey`）。

## 串、工作階段和 reply tags

- DM 路由為 `direct`；頻道為 `channel`；MPIM 為 `group`。
- 使用預設的 `session.dmScope=main`，Slack DM 合併至 agent 主要工作階段。
- 頻道工作階段：`agent:<agentId>:slack:channel:<channelId>`。
- 串回覆可在適用時建立串工作階段後綴（`:thread:<threadTs>`）。
- `channels.slack.thread.historyScope` 預設為 `thread`；`thread.inheritParent` 預設為 `false`。
- `channels.slack.thread.initialHistoryLimit` 控制新串工作階段啟動時獲取多少現有串訊息（預設 `20`；設定 `0` 停用）。

回覆串控制：

- `channels.slack.replyToMode`：`off|first|all`（預設 `off`）
- `channels.slack.replyToModeByChatType`：按 `direct|group|channel` 設定
- 直接聊天的舊版備用：`channels.slack.dm.replyToMode`

支援手動 reply tags：

- `[[reply_to_current]]`
- `[[reply_to:<id>]]`

注意：`replyToMode="off"` 停用 Slack 中**所有**回覆串，包括明確的 `[[reply_to_*]]` 標籤。這與 Telegram 不同，在 Telegram 中明確標籤在 `"off"` 模式下仍然有效。差異反映了平台串模型的不同：Slack 串對頻道隱藏訊息，而 Telegram 回覆在主要聊天流中仍然可見。

## 媒體、分塊和傳遞

<AccordionGroup>
  <Accordion title="入站附件">
    Slack 檔案附件從 Slack 託管的私有 URL 下載（token 驗證的請求流），當獲取成功且大小限制允許時寫入媒體儲存。

    執行時入站大小上限預設為 `20MB`，除非被 `channels.slack.mediaMaxMb` 覆蓋。

  </Accordion>

  <Accordion title="出站文字和檔案">
    - 文字分塊使用 `channels.slack.textChunkLimit`（預設 4000）
    - `channels.slack.chunkMode="newline"` 啟用段落優先分割
    - 檔案傳送使用 Slack 上傳 API，可包含串回覆（`thread_ts`）
    - 出站媒體上限遵循 `channels.slack.mediaMaxMb`（若設定）；否則頻道傳送使用媒體管線的 MIME 類型預設值
  </Accordion>

  <Accordion title="傳遞目標">
    建議的明確目標：

    - `user:<id>` 用於 DM
    - `channel:<id>` 用於頻道

    傳送至 user 目標時，Slack DM 透過 Slack conversation API 開啟。

  </Accordion>
</AccordionGroup>

## 動作與閘道

Slack 動作由 `channels.slack.actions.*` 控制。

目前 Slack 工具中可用的動作群組：

| 群組       | 預設 |
| ---------- | ---- |
| messages   | 啟用 |
| reactions  | 啟用 |
| pins       | 啟用 |
| memberInfo | 啟用 |
| emojiList  | 啟用 |

## 事件與操作行為

- 訊息編輯/刪除/串廣播被對應到系統事件。
- Reaction 新增/移除事件被對應到系統事件。
- 成員加入/離開、頻道建立/重命名，以及 pin 新增/移除事件被對應到系統事件。
- 助理串狀態更新（用於串中的「正在輸入...」指示器）使用 `assistant.threads.setStatus`，需要 bot scope `assistant:write`。
- 當 `configWrites` 啟用時，`channel_id_changed` 可以遷移頻道設定金鑰。
- 頻道主題/目的 metadata 被視為不受信任的上下文，可以注入到路由上下文中。
- 區塊動作和 modal 互動發出結構化的 `Slack interaction: ...` 系統事件，包含豐富的 payload 欄位：
  - 區塊動作：選定值、標籤、選擇器值和 `workflow_*` metadata
  - modal `view_submission` 和 `view_closed` 事件，包含路由的頻道 metadata 和表單輸入

## Ack reactions

`ackReaction` 在 OpenClaw 處理入站訊息時傳送確認表情符號。

解析順序：

- `channels.slack.accounts.<accountId>.ackReaction`
- `channels.slack.ackReaction`
- `messages.ackReaction`
- agent 身份表情符號備用（`agents.list[].identity.emoji`，否則為 "👀"）

注意：

- Slack 期望使用 shortcode（例如 `"eyes"`）。
- 使用 `""` 停用 Slack 帳號或全域的 reaction。

## Typing reaction 備用

`typingReaction` 在 OpenClaw 處理回覆時，在入站 Slack 訊息上新增暫時的 reaction，完成後移除。這在 Slack 原生助理 typing 不可用時很有用，特別是在 DM 中。

解析順序：

- `channels.slack.accounts.<accountId>.typingReaction`
- `channels.slack.typingReaction`

注意：

- Slack 期望使用 shortcode（例如 `"hourglass_flowing_sand"`）。
- Reaction 是盡力而為的，並在回覆或失敗路徑完成後自動嘗試清理。

## Manifest 和 scope 清單

<AccordionGroup>
  <Accordion title="Slack app manifest 範例">

```json
{
  "display_information": {
    "name": "OpenClaw",
    "description": "Slack connector for OpenClaw"
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
        "description": "Send a message to OpenClaw",
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
        "im:history",
        "im:read",
        "im:write",
        "mpim:history",
        "mpim:read",
        "mpim:write",
        "users:read",
        "app_mentions:read",
        "assistant:write",
        "reactions:read",
        "reactions:write",
        "pins:read",
        "pins:write",
        "emoji:read",
        "commands",
        "files:read",
        "files:write"
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

  </Accordion>

  <Accordion title="選用 user-token scopes（讀取操作）">
    若你設定 `channels.slack.userToken`，典型的讀取 scopes 為：

    - `channels:history`、`groups:history`、`im:history`、`mpim:history`
    - `channels:read`、`groups:read`、`im:read`、`mpim:read`
    - `users:read`
    - `reactions:read`
    - `pins:read`
    - `emoji:read`
    - `search:read`（若依賴 Slack 搜尋讀取）

  </Accordion>
</AccordionGroup>

## 疑難排解

<AccordionGroup>
  <Accordion title="頻道中無回覆">
    依序檢查：

    - `groupPolicy`
    - 頻道 allowlist（`channels.slack.channels`）
    - `requireMention`
    - 每頻道 `users` allowlist

    有用指令：

```bash
openclaw channels status --probe
openclaw logs --follow
openclaw doctor
```

  </Accordion>

  <Accordion title="DM 訊息被忽略">
    檢查：

    - `channels.slack.dm.enabled`
    - `channels.slack.dmPolicy`（或舊版 `channels.slack.dm.policy`）
    - 配對核准 / allowlist 條目

```bash
openclaw pairing list slack
```

  </Accordion>

  <Accordion title="Socket mode 無法連接">
    在 Slack app 設定中驗證 bot + app token 和 Socket Mode 啟用狀態。
  </Accordion>

  <Accordion title="HTTP 模式未接收事件">
    驗證：

    - signing secret
    - webhook 路徑
    - Slack Request URLs（Events + Interactivity + Slash Commands）
    - 每個 HTTP 帳號的唯一 `webhookPath`

  </Accordion>

  <Accordion title="原生/斜線指令未觸發">
    驗證你是否打算使用：

    - 原生指令模式（`channels.slack.commands.native: true`），並在 Slack 中註冊對應的斜線指令
    - 或單一斜線指令模式（`channels.slack.slashCommand.enabled: true`）

    同時檢查 `commands.useAccessGroups` 和頻道/用戶 allowlist。

  </Accordion>
</AccordionGroup>

## 文字串流

OpenClaw 透過 Agents and AI Apps API 支援 Slack 原生文字串流。

`channels.slack.streaming` 控制即時預覽行為：

- `off`：停用即時預覽串流。
- `partial`（預設）：將預覽文字替換為最新的部分輸出。
- `block`：以分塊/附加步驟更新預覽。
- `progress`：生成時顯示進度狀態文字，然後傳送最終文字。

`channels.slack.nativeStreaming` 控制當 `streaming` 為 `partial` 時 Slack 的原生串流 API（`chat.startStream` / `chat.appendStream` / `chat.stopStream`）（預設：`true`）。

停用 Slack 原生串流（保留草稿預覽行為）：

```yaml
channels:
  slack:
    streaming: partial
    nativeStreaming: false
```

舊版金鑰：

- `channels.slack.streamMode`（`replace | status_final | append`）自動遷移到 `channels.slack.streaming`。
- 布林值 `channels.slack.streaming` 自動遷移到 `channels.slack.nativeStreaming`。

### 需求

1. 在你的 Slack app 設定中啟用 **Agents and AI Apps**。
2. 確認 app 有 `assistant:write` scope。
3. 該訊息必須有可用的回覆串。串選擇仍遵循 `replyToMode`。

### 行為

- 第一個文字區塊啟動串流（`chat.startStream`）。
- 後續文字區塊附加到相同串流（`chat.appendStream`）。
- 回覆結束時完成串流（`chat.stopStream`）。
- 媒體和非文字 payload 退回到一般傳遞。
- 若串流在回覆中途失敗，OpenClaw 退回到一般傳遞處理剩餘 payload。

## 設定參考指標

主要參考：

- [Configuration reference - Slack](/zh-Hant/gateway/configuration-reference#slack)

  Slack 高信號欄位：
  - 模式/驗證：`mode`、`botToken`、`appToken`、`signingSecret`、`webhookPath`、`accounts.*`
  - DM 存取：`dm.enabled`、`dmPolicy`、`allowFrom`（舊版：`dm.policy`、`dm.allowFrom`）、`dm.groupEnabled`、`dm.groupChannels`
  - 相容性切換：`dangerouslyAllowNameMatching`（緊急；除非需要否則保持關閉）
  - 頻道存取：`groupPolicy`、`channels.*`、`channels.*.users`、`channels.*.requireMention`
  - 串/歷史：`replyToMode`、`replyToModeByChatType`、`thread.*`、`historyLimit`、`dmHistoryLimit`、`dms.*.historyLimit`
  - 傳遞：`textChunkLimit`、`chunkMode`、`mediaMaxMb`、`streaming`、`nativeStreaming`
  - 操作/功能：`configWrites`、`commands.native`、`slashCommand.*`、`actions.*`、`userToken`、`userTokenReadOnly`

## 相關

- [Pairing](/zh-Hant/channels/pairing)
- [Channel routing](/zh-Hant/channels/channel-routing)
- [Troubleshooting](/zh-Hant/channels/troubleshooting)
- [Configuration](/zh-Hant/gateway/configuration)
- [Slash commands](/zh-Hant/tools/slash-commands)
