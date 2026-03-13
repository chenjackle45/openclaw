---
summary: "Slack 設定與執行時行為（Socket Mode + HTTP Events API）"
read_when:
  - 設定 Slack 或除錯 Slack socket/HTTP 模式
title: "Slack（Slack 整合設定）"
---

# Slack

狀態：透過 Slack 應用程式整合，已可正式用於私訊與頻道。預設模式為 Socket Mode；也支援 HTTP Events API 模式。

<CardGroup cols={3}>
  <Card title="配對" icon="link" href="/zh-Hant/channels/pairing">
    Slack 私訊預設使用配對模式。
  </Card>
  <Card title="斜線指令" icon="terminal" href="/zh-Hant/tools/slash-commands">
    原生指令行為與指令目錄。
  </Card>
  <Card title="頻道疑難排解" icon="wrench" href="/zh-Hant/channels/troubleshooting">
    跨頻道診斷與修復流程。
  </Card>
</CardGroup>

## 快速設定

<Tabs>
  <Tab title="Socket Mode（預設）">
    <Steps>
      <Step title="建立 Slack 應用程式與 Token">
        在 Slack 應用程式設定中：

        - 啟用 **Socket Mode**
        - 建立 **App Token**（`xapp-...`），範圍設為 `connections:write`
        - 安裝應用程式並複製 **Bot Token**（`xoxb-...`）
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

        環境變數備援（僅限預設帳號）：

```bash
SLACK_APP_TOKEN=xapp-...
SLACK_BOT_TOKEN=xoxb-...
```

      </Step>

      <Step title="訂閱應用程式事件">
        訂閱以下 Bot 事件：

        - `app_mention`
        - `message.channels`、`message.groups`、`message.im`、`message.mpim`
        - `reaction_added`、`reaction_removed`
        - `member_joined_channel`、`member_left_channel`
        - `channel_rename`
        - `pin_added`、`pin_removed`

        同時在 App Home 中啟用 **Messages Tab** 以支援私訊。
      </Step>

      <Step title="啟動 Gateway">

```bash
openclaw gateway
```

      </Step>
    </Steps>

  </Tab>

  <Tab title="HTTP Events API 模式">
    <Steps>
      <Step title="設定 Slack 應用程式為 HTTP 模式">

        - 將模式設為 HTTP（`channels.slack.mode="http"`）
        - 複製 Slack **Signing Secret**
        - 將 Event Subscriptions、Interactivity 和 Slash command 的 Request URL 都設為相同的 Webhook 路徑（預設 `/slack/events`）

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

      <Step title="多帳號 HTTP 模式使用唯一 Webhook 路徑">
        支援每帳號的 HTTP 模式。

        給每個帳號設定不同的 `webhookPath`，以避免註冊衝突。
      </Step>
    </Steps>

  </Tab>
</Tabs>

## Token 模型

- Socket Mode 需要 `botToken` + `appToken`。
- HTTP 模式需要 `botToken` + `signingSecret`。
- 設定中的 Token 優先於環境變數備援。
- `SLACK_BOT_TOKEN` / `SLACK_APP_TOKEN` 環境變數備援僅適用於預設帳號。
- `userToken`（`xoxp-...`）僅可透過設定指定（無環境變數備援），預設為唯讀行為（`userTokenReadOnly: true`）。
- 選填：若希望輸出訊息使用當前 Agent 身份（自訂 `username` 和圖示），請新增 `chat:write.customize`。`icon_emoji` 使用 `:emoji_name:` 語法。

<Tip>
對於操作/目錄讀取，設定後可優先使用 User Token。對於寫入，Bot Token 仍為優先；只有在 `userTokenReadOnly: false` 且 Bot Token 不可用時，才允許使用 User Token 寫入。
</Tip>

## 存取控制與路由

<Tabs>
  <Tab title="私訊政策">
    `channels.slack.dmPolicy` 控制私訊存取（舊版：`channels.slack.dm.policy`）：

    - `pairing`（預設）
    - `allowlist`
    - `open`（需要 `channels.slack.allowFrom` 包含 `"*"`；舊版：`channels.slack.dm.allowFrom`）
    - `disabled`

    私訊旗標：

    - `dm.enabled`（預設 true）
    - `channels.slack.allowFrom`（推薦）
    - `dm.allowFrom`（舊版）
    - `dm.groupEnabled`（群組私訊預設 false）
    - `dm.groupChannels`（選填 MPIM 白名單）

    多帳號優先順序：

    - `channels.slack.accounts.default.allowFrom` 僅適用於 `default` 帳號。
    - 具名帳號在未設定自己的 `allowFrom` 時，繼承 `channels.slack.allowFrom`。
    - 具名帳號不繼承 `channels.slack.accounts.default.allowFrom`。

    私訊配對使用 `openclaw pairing approve slack <code>`。

  </Tab>

  <Tab title="頻道政策">
    `channels.slack.groupPolicy` 控制頻道處理：

    - `open`
    - `allowlist`
    - `disabled`

    頻道白名單位於 `channels.slack.channels`，應使用穩定的頻道 ID。

    執行時注意：若 `channels.slack` 完全缺失（僅環境變數設定），執行時備援為 `groupPolicy="allowlist"` 並記錄警告（即使 `channels.defaults.groupPolicy` 已設定）。

    名稱/ID 解析：

    - 頻道白名單項目和私訊白名單項目會在啟動時進行解析（Token 有足夠存取權時）
    - 無法解析的頻道名稱項目保留為設定值，但預設不用於路由
    - 收入授權和頻道路由預設優先使用 ID；直接使用者名稱/slug 比對需要 `channels.slack.dangerouslyAllowNameMatching: true`

  </Tab>

  <Tab title="Mention 與頻道用戶">
    頻道訊息預設需要 mention 才能觸發。

    Mention 來源：

    - 明確的應用程式 mention（`<@botId>`）
    - mention 正則模式（`agents.list[].groupChat.mentionPatterns`，備援 `messages.groupChat.mentionPatterns`）
    - 隱式回覆 Bot 討論串行為

    每頻道控制（`channels.slack.channels.<id>`；名稱僅可透過啟動解析或 `dangerouslyAllowNameMatching`）：

    - `requireMention`
    - `users`（白名單）
    - `allowBots`
    - `skills`
    - `systemPrompt`
    - `tools`、`toolsBySender`
    - `toolsBySender` 金鑰格式：`id:`、`e164:`、`username:`、`name:` 或 `"*"` 萬用字元
      （舊版無前綴金鑰仍映射至 `id:`）

  </Tab>
</Tabs>

## 指令與斜線行為

- 原生指令自動模式對 Slack **不啟用**（`commands.native: "auto"` 不會啟用 Slack 原生指令）。
- 透過 `channels.slack.commands.native: true`（或全域 `commands.native: true`）啟用原生 Slack 指令處理程式。
- 啟用原生指令後，請在 Slack 中註冊對應的斜線指令（`/<command>` 名稱），但有一個例外：
  - 狀態指令請註冊 `/agentstatus`（Slack 保留了 `/status`）
- 若未啟用原生指令，可透過 `channels.slack.slashCommand` 執行單一設定的斜線指令。
- 原生參數選單現在會自適應渲染策略：
  - 最多 5 個選項：按鈕區塊
  - 6-100 個選項：靜態下拉選單
  - 超過 100 個選項：啟用互動選項處理時使用非同步選項篩選的外部下拉選單
  - 若編碼後的選項值超過 Slack 限制，退回使用按鈕
- 對於較長的選項載荷，斜線指令參數選單在送出選取值前會顯示確認對話框。

預設斜線指令設定：

- `enabled: false`
- `name: "openclaw"`
- `sessionPrefix: "slack:slash"`
- `ephemeral: true`

斜線工作階段使用獨立金鑰：

- `agent:<agentId>:slack:slash:<userId>`

並仍針對目標對話工作階段執行指令（`CommandTargetSessionKey`）。

## 討論串、工作階段與回覆標籤

- 私訊路由為 `direct`；頻道為 `channel`；MPIM 為 `group`。
- 預設 `session.dmScope=main` 時，Slack 私訊收斂至 Agent 主要工作階段。
- 頻道工作階段：`agent:<agentId>:slack:channel:<channelId>`。
- 討論串回覆可建立討論串工作階段後綴（`:thread:<threadTs>`，視情況而定）。
- `channels.slack.thread.historyScope` 預設為 `thread`；`thread.inheritParent` 預設為 `false`。
- `channels.slack.thread.initialHistoryLimit` 控制新討論串工作階段開始時擷取的現有討論串訊息數量（預設 `20`；設為 `0` 停用）。

回覆串控制：

- `channels.slack.replyToMode`：`off|first|all`（預設 `off`）
- `channels.slack.replyToModeByChatType`：按 `direct|group|channel` 個別設定
- 直接聊天的舊版備援：`channels.slack.dm.replyToMode`

支援手動回覆標籤：

- `[[reply_to_current]]`
- `[[reply_to:<id>]]`

注意：`replyToMode="off"` 會停用 Slack 中**所有**回覆串，包括明確的 `[[reply_to_*]]` 標籤。這與 Telegram 不同，Telegram 在 `"off"` 模式下仍支援明確標籤。此差異反映了平台討論串模型的不同：Slack 討論串會將訊息隱藏在頻道外，而 Telegram 回覆仍在主聊天流中可見。

## 媒體、區塊與傳送

<AccordionGroup>
  <Accordion title="收入附件">
    Slack 檔案附件從 Slack 托管的私有 URL（Token 驗證請求流程）下載，並在擷取成功且大小符合限制時寫入媒體儲存。

    執行時收入大小上限預設為 `20MB`，除非由 `channels.slack.mediaMaxMb` 覆寫。

  </Accordion>

  <Accordion title="輸出文字與檔案">
    - 文字區塊使用 `channels.slack.textChunkLimit`（預設 4000）
    - `channels.slack.chunkMode="newline"` 啟用段落優先分割
    - 檔案傳送使用 Slack 上傳 API，可包含討論串回覆（`thread_ts`）
    - 輸出媒體上限遵循 `channels.slack.mediaMaxMb`（若已設定）；否則頻道傳送使用媒體管道的 MIME 類型預設值
  </Accordion>

  <Accordion title="傳送目標">
    推薦的明確目標：

    - `user:<id>` 用於私訊
    - `channel:<id>` 用於頻道

    傳送至用戶目標時，Slack 私訊透過 Slack 對話 API 開啟。

  </Accordion>
</AccordionGroup>

## 操作與閘門

Slack 操作由 `channels.slack.actions.*` 控制。

當前 Slack 工具中可用的操作群組：

| 群組       | 預設 |
| ---------- | ---- |
| messages   | 啟用 |
| reactions  | 啟用 |
| pins       | 啟用 |
| memberInfo | 啟用 |
| emojiList  | 啟用 |

## 事件與操作行為

- 訊息編輯/刪除/討論串廣播映射為系統事件。
- 反應新增/移除事件映射為系統事件。
- 成員加入/離開、頻道建立/重新命名和釘選新增/移除事件映射為系統事件。
- 助理討論串狀態更新（討論串中的「正在輸入...」指示器）使用 `assistant.threads.setStatus`，需要 Bot 範圍 `assistant:write`。
- 啟用 `configWrites` 時，`channel_id_changed` 可遷移頻道設定金鑰。
- 頻道主題/用途中繼資料視為不可信任的情境，可注入路由情境。
- 區塊操作和 Modal 互動發出帶有豐富載荷欄位的結構化 `Slack interaction: ...` 系統事件：
  - 區塊操作：選取值、標籤、選取器值和 `workflow_*` 中繼資料
  - Modal `view_submission` 和 `view_closed` 事件，附帶路由頻道中繼資料和表單輸入

## 確認反應

`ackReaction` 在 OpenClaw 處理收入訊息時傳送確認 emoji。

解析順序：

- `channels.slack.accounts.<accountId>.ackReaction`
- `channels.slack.ackReaction`
- `messages.ackReaction`
- Agent 身份 emoji 備援（`agents.list[].identity.emoji`，否則使用 "👀"）

注意：

- Slack 使用 shortcode（例如 `"eyes"`）。
- 使用 `""` 停用 Slack 帳號或全域的反應。

## 輸入反應備援

`typingReaction` 在 OpenClaw 處理回覆時，為收入的 Slack 訊息暫時新增一個反應，回覆完成後移除。這在 Slack 原生助理輸入狀態不可用時（尤其在私訊中）很有用。

解析順序：

- `channels.slack.accounts.<accountId>.typingReaction`
- `channels.slack.typingReaction`

注意：

- Slack 使用 shortcode（例如 `"hourglass_flowing_sand"`）。
- 反應採用盡力而為的方式，回覆或失敗路徑完成後自動嘗試清除。

## Manifest 與範圍清單

<AccordionGroup>
  <Accordion title="Slack 應用程式 Manifest 範例">

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

  <Accordion title="選填 User Token 範圍（讀取操作）">
    若你設定了 `channels.slack.userToken`，典型的讀取範圍為：

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
  <Accordion title="頻道沒有收到回覆">
    依序確認：

    - `groupPolicy`
    - 頻道白名單（`channels.slack.channels`）
    - `requireMention`
    - 每頻道 `users` 白名單

    實用指令：

```bash
openclaw channels status --probe
openclaw logs --follow
openclaw doctor
```

  </Accordion>

  <Accordion title="私訊被忽略">
    確認：

    - `channels.slack.dm.enabled`
    - `channels.slack.dmPolicy`（或舊版 `channels.slack.dm.policy`）
    - 配對核准 / 白名單項目

```bash
openclaw pairing list slack
```

  </Accordion>

  <Accordion title="Socket Mode 無法連線">
    確認 Slack 應用程式設定中的 Bot + App Token 及 Socket Mode 是否已啟用。
  </Accordion>

  <Accordion title="HTTP 模式無法接收事件">
    確認：

    - Signing Secret
    - Webhook 路徑
    - Slack Request URL（事件、互動性、斜線指令）
    - 每個 HTTP 帳號的唯一 `webhookPath`

  </Accordion>

  <Accordion title="原生/斜線指令無法觸發">
    確認你的設定意圖：

    - 原生指令模式（`channels.slack.commands.native: true`），且在 Slack 中已註冊對應的斜線指令
    - 或單一斜線指令模式（`channels.slack.slashCommand.enabled: true`）

    同時確認 `commands.useAccessGroups` 和頻道/用戶白名單。

  </Accordion>
</AccordionGroup>

## 文字串流

OpenClaw 支援透過 Agents and AI Apps API 的 Slack 原生文字串流。

`channels.slack.streaming` 控制即時預覽行為：

- `off`：停用即時預覽串流。
- `partial`（預設）：以最新的部分輸出替換預覽文字。
- `block`：附加區塊化的預覽更新。
- `progress`：產生過程中顯示進度狀態文字，然後傳送最終文字。

`channels.slack.nativeStreaming` 控制 `streaming` 為 `partial` 時的 Slack 原生串流 API（`chat.startStream` / `chat.appendStream` / `chat.stopStream`）（預設：`true`）。

停用 Slack 原生串流（保留草稿預覽行為）：

```yaml
channels:
  slack:
    streaming: partial
    nativeStreaming: false
```

舊版金鑰：

- `channels.slack.streamMode`（`replace | status_final | append`）自動遷移至 `channels.slack.streaming`。
- 布林值 `channels.slack.streaming` 自動遷移至 `channels.slack.nativeStreaming`。

### 需求

1. 在 Slack 應用程式設定中啟用 **Agents and AI Apps**。
2. 確保應用程式擁有 `assistant:write` 範圍。
3. 該訊息必須有可用的回覆討論串。討論串選擇仍遵循 `replyToMode`。

### 行為

- 第一個文字區塊啟動串流（`chat.startStream`）。
- 後續文字區塊附加至相同串流（`chat.appendStream`）。
- 回覆結束時完成串流（`chat.stopStream`）。
- 媒體和非文字載荷退回至一般傳送方式。
- 若串流在回覆中途失敗，OpenClaw 對剩餘載荷退回至一般傳送方式。

## 設定參考指引

主要參考：

- [設定參考 - Slack](/zh-Hant/gateway/configuration-reference#slack)

  Slack 重要欄位：
  - 模式/驗證：`mode`、`botToken`、`appToken`、`signingSecret`、`webhookPath`、`accounts.*`
  - 私訊存取：`dm.enabled`、`dmPolicy`、`allowFrom`（舊版：`dm.policy`、`dm.allowFrom`）、`dm.groupEnabled`、`dm.groupChannels`
  - 相容切換：`dangerouslyAllowNameMatching`（緊急用；除非必要否則保持關閉）
  - 頻道存取：`groupPolicy`、`channels.*`、`channels.*.users`、`channels.*.requireMention`
  - 討論串/記錄：`replyToMode`、`replyToModeByChatType`、`thread.*`、`historyLimit`、`dmHistoryLimit`、`dms.*.historyLimit`
  - 傳送：`textChunkLimit`、`chunkMode`、`mediaMaxMb`、`streaming`、`nativeStreaming`
  - 操作/功能：`configWrites`、`commands.native`、`slashCommand.*`、`actions.*`、`userToken`、`userTokenReadOnly`

## 相關文件

- [配對](/zh-Hant/channels/pairing)
- [頻道路由](/zh-Hant/channels/channel-routing)
- [疑難排解](/zh-Hant/channels/troubleshooting)
- [設定](/zh-Hant/gateway/configuration)
- [斜線指令](/zh-Hant/tools/slash-commands)
