---
title: "Discord"
summary: "Discord bot 支援狀態、功能和設定"
read_when:
  - 處理 Discord 頻道功能
---

# Discord（Bot API）

狀態：已支援透過官方 Discord gateway 處理 DM 和 guild 頻道。

<CardGroup cols={3}>
  <Card title="Pairing（配對）" icon="link" href="/zh-Hant/channels/pairing">
    Discord DM 預設使用配對模式。
  </Card>
  <Card title="Slash commands（斜線指令）" icon="terminal" href="/zh-Hant/tools/slash-commands">
    原生指令行為與指令目錄。
  </Card>
  <Card title="Channel troubleshooting（頻道疑難排解）" icon="wrench" href="/zh-Hant/channels/troubleshooting">
    跨頻道診斷與修復流程。
  </Card>
</CardGroup>

## 快速設定

你需要建立一個帶有 bot 的新應用程式、將 bot 加入伺服器，並與 OpenClaw 配對。建議將 bot 加入你自己的私人伺服器。若還沒有伺服器，請先[建立一個](https://support.discord.com/hc/en-us/articles/204849977-How-do-I-create-a-server)（選擇 **Create My Own > For me and my friends**）。

<Steps>
  <Step title="建立 Discord 應用程式和 bot">
    前往 [Discord Developer Portal](https://discord.com/developers/applications) 並點擊 **New Application**。命名為「OpenClaw」或其他名稱。

    在側欄點擊 **Bot**。將 **Username** 設定為你的 OpenClaw agent 的名稱。

  </Step>

  <Step title="啟用 Privileged Intents">
    仍在 **Bot** 頁面，向下捲動至 **Privileged Gateway Intents** 並啟用：

    - **Message Content Intent**（必要）
    - **Server Members Intent**（建議；角色 allowlist 和名稱轉 ID 需要）
    - **Presence Intent**（選用；僅在需要 presence 更新時使用）

  </Step>

  <Step title="複製 bot token">
    在 **Bot** 頁面向上捲動，點擊 **Reset Token**。

    <Note>
    儘管名稱如此，這其實是生成你的第一個 token，並非真正「重設」。
    </Note>

    複製 token 並儲存。這是你的 **Bot Token**，稍後會用到。

  </Step>

  <Step title="產生邀請 URL 並將 bot 加入伺服器">
    在側欄點擊 **OAuth2**。你將產生一個帶有正確權限的邀請 URL，用於將 bot 加入伺服器。

    向下捲動至 **OAuth2 URL Generator** 並啟用：

    - `bot`
    - `applications.commands`

    下方會出現 **Bot Permissions** 區段。啟用：

    - View Channels
    - Send Messages
    - Read Message History
    - Embed Links
    - Attach Files
    - Add Reactions（選用）

    複製底部產生的 URL，貼到瀏覽器，選擇伺服器，點擊 **Continue** 完成連接。此時你的 bot 應該已出現在 Discord 伺服器中。

  </Step>

  <Step title="啟用 Developer Mode 並收集 ID">
    回到 Discord 應用程式，你需要啟用 Developer Mode 才能複製內部 ID。

    1. 點擊 **User Settings**（頭像旁的齒輪圖示）→ **Advanced** → 開啟 **Developer Mode**
    2. 右鍵點擊側欄中的**伺服器圖示** → **Copy Server ID**
    3. 右鍵點擊**自己的頭像** → **Copy User ID**

    將你的 **Server ID** 和 **User ID** 與 Bot Token 一起儲存，下一步將三者一起傳給 OpenClaw。

  </Step>

  <Step title="允許來自伺服器成員的 DM">
    為了配對能正常運作，Discord 需要允許你的 bot 傳送 DM 給你。右鍵點擊**伺服器圖示** → **Privacy Settings** → 開啟 **Direct Messages**。

    這讓伺服器成員（包含 bot）可以傳 DM 給你。若你想使用 Discord DM 搭配 OpenClaw，請保持啟用。若只計劃使用 guild 頻道，可在配對後關閉 DM。

  </Step>

  <Step title="步驟 0：安全地設定 bot token（不要在聊天中傳送）">
    你的 Discord bot token 是機密（如同密碼）。在傳訊息給 agent 前，先在執行 OpenClaw 的機器上設定它。

```bash
openclaw config set channels.discord.token '"YOUR_BOT_TOKEN"' --json
openclaw config set channels.discord.enabled true --json
openclaw gateway
```

    若 OpenClaw 已作為背景服務執行，請改用 `openclaw gateway restart`。

  </Step>

  <Step title="設定 OpenClaw 並配對">

    <Tabs>
      <Tab title="詢問你的 agent">
        在任何現有頻道（如 Telegram）與你的 OpenClaw agent 聊天並告知它。若 Discord 是你的第一個頻道，請改用 CLI / 設定分頁。

        > "我已在設定中設定 Discord bot token。請使用 User ID `<user_id>` 和 Server ID `<server_id>` 完成 Discord 設定。"
      </Tab>
      <Tab title="CLI / 設定">
        若偏好檔案式設定，請設定：

```json5
{
  channels: {
    discord: {
      enabled: true,
      token: "YOUR_BOT_TOKEN",
    },
  },
}
```

        預設帳號的環境變數備用：

```bash
DISCORD_BOT_TOKEN=...
```

        `channels.discord.token` 也支援 SecretRef 值（env/file/exec providers）。請參閱 [Secrets Management](/zh-Hant/gateway/secrets)。

      </Tab>
    </Tabs>

  </Step>

  <Step title="核准第一個 DM 配對">
    等待 gateway 啟動後，在 Discord 傳 DM 給你的 bot。它會回應一個配對碼。

    <Tabs>
      <Tab title="詢問你的 agent">
        在現有頻道將配對碼傳給你的 agent：

        > "核准這個 Discord 配對碼：`<CODE>`"
      </Tab>
      <Tab title="CLI">

```bash
openclaw pairing list discord
openclaw pairing approve discord <CODE>
```

      </Tab>
    </Tabs>

    配對碼 1 小時後過期。

    現在你應該可以透過 Discord DM 與你的 agent 聊天了。

  </Step>
</Steps>

<Note>
Token 解析有帳號感知能力。設定中的 token 值優先於環境變數備用。`DISCORD_BOT_TOKEN` 僅適用於預設帳號。
</Note>

## 建議：設定 guild 工作區

DM 正常運作後，你可以將 Discord 伺服器設定為完整工作區，讓每個頻道都有自己的 agent 工作階段和獨立上下文。建議在只有你和 bot 的私人伺服器上使用。

<Steps>
  <Step title="將伺服器加入 guild allowlist">
    這讓你的 agent 可以在伺服器的任何頻道（不只是 DM）回覆。

    <Tabs>
      <Tab title="詢問你的 agent">
        > "將我的 Discord Server ID `<server_id>` 加入 guild allowlist"
      </Tab>
      <Tab title="設定">

```json5
{
  channels: {
    discord: {
      groupPolicy: "allowlist",
      guilds: {
        YOUR_SERVER_ID: {
          requireMention: true,
          users: ["YOUR_USER_ID"],
        },
      },
    },
  },
}
```

      </Tab>
    </Tabs>

  </Step>

  <Step title="允許不需 @mention 的回覆">
    預設情況下，你的 agent 在 guild 頻道只有在被 @mention 時才會回覆。對於私人伺服器，你可能希望它回覆每一條訊息。

    <Tabs>
      <Tab title="詢問你的 agent">
        > "允許我的 agent 在這個伺服器無需 @mention 即可回覆"
      </Tab>
      <Tab title="設定">
        在 guild 設定中將 `requireMention: false`：

```json5
{
  channels: {
    discord: {
      guilds: {
        YOUR_SERVER_ID: {
          requireMention: false,
        },
      },
    },
  },
}
```

      </Tab>
    </Tabs>

  </Step>

  <Step title="規劃 guild 頻道的記憶體策略">
    預設情況下，長期記憶體（MEMORY.md）只在 DM 工作階段中載入，guild 頻道不會自動載入 MEMORY.md。

    <Tabs>
      <Tab title="詢問你的 agent">
        > "當我在 Discord 頻道提問時，若需要 MEMORY.md 的長期上下文，請使用 memory_search 或 memory_get。"
      </Tab>
      <Tab title="手動">
        若需要在每個頻道共享上下文，請將穩定的指令放在 `AGENTS.md` 或 `USER.md`（每個工作階段都會注入）。將長期筆記放在 `MEMORY.md`，並按需使用記憶體工具存取。
      </Tab>
    </Tabs>

  </Step>
</Steps>

在你的 Discord 伺服器建立一些頻道並開始聊天。你的 agent 可以看到頻道名稱，每個頻道都有自己的隔離工作階段，你可以設定 `#coding`、`#home`、`#research` 或任何符合工作流程的頻道。

## 執行模型

- Gateway 擁有 Discord 連線。
- 回覆路由是確定性的：Discord 入站訊息回覆到 Discord。
- 預設情況下（`session.dmScope=main`），直接聊天共享 agent 主要工作階段（`agent:main:main`）。
- Guild 頻道使用隔離的工作階段金鑰（`agent:<agentId>:discord:channel:<channelId>`）。
- 群組 DM 預設忽略（`channels.discord.dm.groupEnabled=false`）。
- 原生斜線指令在隔離的指令工作階段中執行（`agent:<agentId>:discord:slash:<userId>`），同時仍將 `CommandTargetSessionKey` 帶到路由的對話工作階段。

## 論壇頻道

Discord 論壇和媒體頻道只接受串文章。OpenClaw 支援兩種建立方式：

- 傳送訊息至論壇父頻道（`channel:<forumId>`）自動建立串。串標題使用訊息的第一行非空文字。
- 使用 `openclaw message thread create` 直接建立串。論壇頻道不要傳入 `--message-id`。

範例：傳送至論壇父頻道建立串

```bash
openclaw message send --channel discord --target channel:<forumId> \
  --message "Topic title\nBody of the post"
```

範例：明確建立論壇串

```bash
openclaw message thread create --channel discord --target channel:<forumId> \
  --thread-name "Topic title" --message "Body of the post"
```

論壇父頻道不接受 Discord 元件。若需要元件，請傳送至串本身（`channel:<threadId>`）。

## 互動元件

OpenClaw 支援 agent 訊息的 Discord components v2 容器。使用帶有 `components` payload 的訊息工具。互動結果作為一般入站訊息路由回 agent，並遵循現有的 Discord `replyToMode` 設定。

支援的區塊：

- `text`、`section`、`separator`、`actions`、`media-gallery`、`file`
- Action rows 允許最多 5 個按鈕或一個選單
- 選單類型：`string`、`user`、`role`、`mentionable`、`channel`

預設情況下，元件是一次性的。將 `components.reusable=true` 設定為允許按鈕、選單和表單被多次使用直到過期。

若要限制誰可以點擊按鈕，在該按鈕上設定 `allowedUsers`（Discord 用戶 ID、標籤或 `*`）。設定後，未匹配的用戶會收到臨時拒絕訊息。

`/model` 和 `/models` 斜線指令會開啟一個互動式模型選擇器，包含 provider 和模型下拉選單以及提交步驟。選擇器回覆是臨時的，只有呼叫用戶可以使用。

檔案附件：

- `file` 區塊必須指向附件參考（`attachment://<filename>`）
- 透過 `media`/`path`/`filePath` 提供附件（單一檔案）；多個檔案使用 `media-gallery`
- 使用 `filename` 在上傳名稱需與附件參考匹配時覆蓋名稱

Modal 表單：

- 新增 `components.modal`，最多 5 個欄位
- 欄位類型：`text`、`checkbox`、`radio`、`select`、`role-select`、`user-select`
- OpenClaw 會自動新增觸發按鈕

範例：

```json5
{
  channel: "discord",
  action: "send",
  to: "channel:123456789012345678",
  message: "Optional fallback text",
  components: {
    reusable: true,
    text: "Choose a path",
    blocks: [
      {
        type: "actions",
        buttons: [
          {
            label: "Approve",
            style: "success",
            allowedUsers: ["123456789012345678"],
          },
          { label: "Decline", style: "danger" },
        ],
      },
      {
        type: "actions",
        select: {
          type: "string",
          placeholder: "Pick an option",
          options: [
            { label: "Option A", value: "a" },
            { label: "Option B", value: "b" },
          ],
        },
      },
    ],
    modal: {
      title: "Details",
      triggerLabel: "Open form",
      fields: [
        { type: "text", label: "Requester" },
        {
          type: "select",
          label: "Priority",
          options: [
            { label: "Low", value: "low" },
            { label: "High", value: "high" },
          ],
        },
      ],
    },
  },
}
```

## 存取控制與路由

<Tabs>
  <Tab title="DM 政策">
    `channels.discord.dmPolicy` 控制 DM 存取（舊版：`channels.discord.dm.policy`）：

    - `pairing`（預設）
    - `allowlist`
    - `open`（需要 `channels.discord.allowFrom` 包含 `"*"`；舊版：`channels.discord.dm.allowFrom`）
    - `disabled`

    若 DM 政策不是 open，未知用戶會被封鎖（或在 `pairing` 模式下提示配對）。

    多帳號優先順序：

    - `channels.discord.accounts.default.allowFrom` 僅適用於 `default` 帳號。
    - 具名帳號在未設定自己的 `allowFrom` 時繼承 `channels.discord.allowFrom`。
    - 具名帳號不繼承 `channels.discord.accounts.default.allowFrom`。

    傳遞的 DM 目標格式：

    - `user:<id>`
    - `<@id>` mention

    純數字 ID 具有歧義性，除非提供了明確的 user/channel 目標類型，否則會被拒絕。

  </Tab>

  <Tab title="Guild 政策">
    Guild 處理由 `channels.discord.groupPolicy` 控制：

    - `open`
    - `allowlist`
    - `disabled`

    當 `channels.discord` 存在時，安全基準為 `allowlist`。

    `allowlist` 行為：

    - guild 必須符合 `channels.discord.guilds`（建議用 `id`，也接受 slug）
    - 選用的發送者 allowlist：`users`（建議使用穩定 ID）和 `roles`（僅限 role ID）；若任一已設定，發送者符合 `users` 或 `roles` 其中一項即允許
    - 名稱/標籤直接匹配預設停用；僅作為緊急相容模式時啟用 `channels.discord.dangerouslyAllowNameMatching: true`
    - `users` 支援名稱/標籤，但 ID 更安全；`openclaw security audit` 會在使用名稱/標籤條目時警告
    - 若 guild 有設定 `channels`，未列出的頻道會被拒絕
    - 若 guild 沒有 `channels` 區塊，該 allowlist guild 中的所有頻道都允許

    範例：

```json5
{
  channels: {
    discord: {
      groupPolicy: "allowlist",
      guilds: {
        "123456789012345678": {
          requireMention: true,
          ignoreOtherMentions: true,
          users: ["987654321098765432"],
          roles: ["123456789012345678"],
          channels: {
            general: { allow: true },
            help: { allow: true, requireMention: true },
          },
        },
      },
    },
  },
}
```

    若你只設定 `DISCORD_BOT_TOKEN` 而未建立 `channels.discord` 區塊，執行時備用為 `groupPolicy="allowlist"`（日誌中會有警告），即使 `channels.defaults.groupPolicy` 為 `open`。

  </Tab>

  <Tab title="Mentions 和群組 DM">
    Guild 訊息預設以 mention 作為進入條件。

    Mention 偵測包含：

    - 明確的 bot mention
    - 設定的 mention 模式（`agents.list[].groupChat.mentionPatterns`，備用 `messages.groupChat.mentionPatterns`）
    - 在支援的情況下隱式回覆 bot 的行為

    `requireMention` 按 guild/頻道設定（`channels.discord.guilds...`）。
    `ignoreOtherMentions` 選擇性地丟棄 mention 了其他用戶/角色但未 mention bot 的訊息（不含 @everyone/@here）。

    群組 DM：

    - 預設：忽略（`dm.groupEnabled=false`）
    - 透過 `dm.groupChannels` 選用 allowlist（頻道 ID 或 slug）

  </Tab>
</Tabs>

### 基於角色的 agent 路由

使用 `bindings[].match.roles` 按角色 ID 將 Discord guild 成員路由到不同的 agent。基於角色的繫結只接受角色 ID，在 peer 或 parent-peer 繫結之後、guild-only 繫結之前評估。若繫結還設定了其他匹配欄位（例如 `peer` + `guildId` + `roles`），所有設定的欄位都必須匹配。

```json5
{
  bindings: [
    {
      agentId: "opus",
      match: {
        channel: "discord",
        guildId: "123456789012345678",
        roles: ["111111111111111111"],
      },
    },
    {
      agentId: "sonnet",
      match: {
        channel: "discord",
        guildId: "123456789012345678",
      },
    },
  ],
}
```

## Developer Portal 設定

<AccordionGroup>
  <Accordion title="建立應用程式和 bot">

    1. Discord Developer Portal -> **Applications** -> **New Application**
    2. **Bot** -> **Add Bot**
    3. 複製 bot token

  </Accordion>

  <Accordion title="Privileged Intents">
    在 **Bot -> Privileged Gateway Intents** 中啟用：

    - Message Content Intent
    - Server Members Intent（建議）

    Presence intent 是選用的，只有在需要接收 presence 更新時才需要。設定 bot presence（`setPresence`）不需要啟用成員 presence 更新。

  </Accordion>

  <Accordion title="OAuth scopes 和基本權限">
    OAuth URL 產生器：

    - scopes：`bot`、`applications.commands`

    典型基本權限：

    - View Channels
    - Send Messages
    - Read Message History
    - Embed Links
    - Attach Files
    - Add Reactions（選用）

    除非明確需要，否則避免 `Administrator`。

  </Accordion>

  <Accordion title="複製 ID">
    啟用 Discord Developer Mode，然後複製：

    - server ID
    - channel ID
    - user ID

    在 OpenClaw 設定中優先使用數字 ID，以確保審計和探測的可靠性。

  </Accordion>
</AccordionGroup>

## 原生指令與指令驗證

- `commands.native` 預設為 `"auto"`，對 Discord 啟用。
- 每個頻道的覆蓋：`channels.discord.commands.native`。
- `commands.native=false` 明確清除先前已註冊的 Discord 原生指令。
- 原生指令驗證使用與一般訊息處理相同的 Discord allowlist/政策。
- 指令在 Discord UI 中對未授權用戶仍可能可見；執行仍會強制執行 OpenClaw 驗證並回傳「not authorized」。

請參閱 [Slash commands](/zh-Hant/tools/slash-commands) 了解指令目錄和行為。

預設斜線指令設定：

- `ephemeral: true`

## 功能詳情

<AccordionGroup>
  <Accordion title="Reply tags 和原生回覆">
    Discord 支援 agent 輸出中的 reply tags：

    - `[[reply_to_current]]`
    - `[[reply_to:<id>]]`

    由 `channels.discord.replyToMode` 控制：

    - `off`（預設）
    - `first`
    - `all`

    注意：`off` 會停用隱式回覆串。明確的 `[[reply_to_*]]` 標籤仍然有效。

    訊息 ID 會在上下文/歷史中顯示，讓 agent 可以針對特定訊息。

  </Accordion>

  <Accordion title="即時串流預覽">
    OpenClaw 可以透過傳送暫時訊息並在文字到達時編輯它來串流草稿回覆。

    - `channels.discord.streaming` 控制預覽串流（`off` | `partial` | `block` | `progress`，預設：`off`）。
    - `progress` 接受用於跨頻道一致性，在 Discord 上對應到 `partial`。
    - `channels.discord.streamMode` 是舊版別名，會自動遷移。
    - `partial` 在 token 到達時編輯單一預覽訊息。
    - `block` 發出草稿大小的區塊（使用 `draftChunk` 調整大小和斷點）。

    範例：

```json5
{
  channels: {
    discord: {
      streaming: "partial",
    },
  },
}
```

    `block` 模式區塊預設（以 `channels.discord.textChunkLimit` 限制）：

```json5
{
  channels: {
    discord: {
      streaming: "block",
      draftChunk: {
        minChars: 200,
        maxChars: 800,
        breakPreference: "paragraph",
      },
    },
  },
}
```

    預覽串流僅限文字；媒體回覆退回到一般傳遞。

    注意：預覽串流與區塊串流是分開的。當 Discord 明確啟用區塊串流時，OpenClaw 會跳過預覽串流以避免雙重串流。

  </Accordion>

  <Accordion title="歷史記錄、上下文和串行為">
    Guild 歷史記錄上下文：

    - `channels.discord.historyLimit` 預設 `20`
    - 備用：`messages.groupChat.historyLimit`
    - `0` 停用

    DM 歷史記錄控制：

    - `channels.discord.dmHistoryLimit`
    - `channels.discord.dms["<user_id>"].historyLimit`

    串行為：

    - Discord 串作為 channel 工作階段路由
    - 父串 metadata 可用於父工作階段連結
    - 串設定繼承父頻道設定，除非存在串特定條目

    頻道主題作為**不受信任**的上下文注入（不作為 system prompt）。

  </Accordion>

  <Accordion title="子 agent 的串綁定工作階段">
    Discord 可以將串綁定到工作階段目標，讓該串中的後續訊息繼續路由到相同的工作階段（包括子 agent 工作階段）。

    指令：

    - `/focus <target>` 將目前/新串綁定到子 agent/工作階段目標
    - `/unfocus` 移除目前串的綁定
    - `/agents` 顯示活動執行和綁定狀態
    - `/session idle <duration|off>` 檢查/更新已聚焦綁定的閒置自動解除聚焦
    - `/session max-age <duration|off>` 檢查/更新已聚焦綁定的最大存活時間

    設定：

```json5
{
  session: {
    threadBindings: {
      enabled: true,
      idleHours: 24,
      maxAgeHours: 0,
    },
  },
  channels: {
    discord: {
      threadBindings: {
        enabled: true,
        idleHours: 24,
        maxAgeHours: 0,
        spawnSubagentSessions: false, // opt-in
      },
    },
  },
}
```

    注意：

    - `session.threadBindings.*` 設定全域預設值。
    - `channels.discord.threadBindings.*` 覆蓋 Discord 行為。
    - `spawnSubagentSessions` 必須為 true 才能為 `sessions_spawn({ thread: true })` 自動建立/綁定串。
    - `spawnAcpSessions` 必須為 true 才能為 ACP（`/acp spawn ... --thread ...` 或 `sessions_spawn({ runtime: "acp", thread: true })`）自動建立/綁定串。
    - 若帳號停用了串綁定，`/focus` 和相關串綁定操作將不可用。

    請參閱 [Sub-agents](/zh-Hant/tools/subagents)、[ACP Agents](/zh-Hant/tools/acp-agents) 和 [Configuration Reference](/zh-Hant/gateway/configuration-reference)。

  </Accordion>

  <Accordion title="持久 ACP 頻道綁定">
    對於穩定的「永遠在線」ACP 工作區，設定以 Discord 對話為目標的頂層類型 ACP 綁定。

    設定路徑：

    - `bindings[]` 帶有 `type: "acp"` 和 `match.channel: "discord"`

    範例：

```json5
{
  agents: {
    list: [
      {
        id: "codex",
        runtime: {
          type: "acp",
          acp: {
            agent: "codex",
            backend: "acpx",
            mode: "persistent",
            cwd: "/workspace/openclaw",
          },
        },
      },
    ],
  },
  bindings: [
    {
      type: "acp",
      agentId: "codex",
      match: {
        channel: "discord",
        accountId: "default",
        peer: { kind: "channel", id: "222222222222222222" },
      },
      acp: { label: "codex-main" },
    },
  ],
  channels: {
    discord: {
      guilds: {
        "111111111111111111": {
          channels: {
            "222222222222222222": {
              requireMention: false,
            },
          },
        },
      },
    },
  },
}
```

    注意：

    - 串訊息可以繼承父頻道的 ACP 綁定。
    - 在已綁定的頻道或串中，`/new` 和 `/reset` 會重置相同的 ACP 工作階段。
    - 臨時串綁定仍然有效，並可在活動時覆蓋目標解析。

    請參閱 [ACP Agents](/zh-Hant/tools/acp-agents) 了解綁定行為詳情。

  </Accordion>

  <Accordion title="Reaction 通知">
    每個 guild 的 reaction 通知模式：

    - `off`
    - `own`（預設）
    - `all`
    - `allowlist`（使用 `guilds.<id>.users`）

    Reaction 事件被轉換為系統事件並附加到路由的 Discord 工作階段。

  </Accordion>

  <Accordion title="Ack reactions">
    `ackReaction` 在 OpenClaw 處理入站訊息時傳送確認表情符號。

    解析順序：

    - `channels.discord.accounts.<accountId>.ackReaction`
    - `channels.discord.ackReaction`
    - `messages.ackReaction`
    - agent 身份表情符號備用（`agents.list[].identity.emoji`，否則為 "👀"）

    注意：

    - Discord 接受 unicode 表情符號或自訂表情符號名稱。
    - 使用 `""` 停用頻道或帳號的 reaction。

  </Accordion>

  <Accordion title="設定寫入">
    頻道發起的設定寫入預設啟用。

    這影響 `/config set|unset` 流程（當指令功能啟用時）。

    停用：

```json5
{
  channels: {
    discord: {
      configWrites: false,
    },
  },
}
```

  </Accordion>

  <Accordion title="Gateway proxy">
    透過 HTTP(S) proxy 路由 Discord gateway WebSocket 流量和啟動 REST 查詢（應用程式 ID + allowlist 解析），設定 `channels.discord.proxy`。

```json5
{
  channels: {
    discord: {
      proxy: "http://proxy.example:8080",
    },
  },
}
```

    每帳號覆蓋：

```json5
{
  channels: {
    discord: {
      accounts: {
        primary: {
          proxy: "http://proxy.example:8080",
        },
      },
    },
  },
}
```

  </Accordion>

  <Accordion title="PluralKit 支援">
    啟用 PluralKit 解析，將代理訊息對應到系統成員身份：

```json5
{
  channels: {
    discord: {
      pluralkit: {
        enabled: true,
        token: "pk_live_...", // 選用；私人系統需要
      },
    },
  },
}
```

    注意：

    - allowlist 可使用 `pk:<memberId>`
    - 僅在 `channels.discord.dangerouslyAllowNameMatching: true` 時，成員顯示名稱才按名稱/slug 匹配
    - 查詢使用原始訊息 ID 並受時間窗口限制
    - 若查詢失敗，代理訊息被視為 bot 訊息並丟棄，除非 `allowBots=true`

  </Accordion>

  <Accordion title="Presence 設定">
    當你設定狀態或活動欄位，或啟用自動 presence 時，會套用 presence 更新。

    僅設定狀態範例：

```json5
{
  channels: {
    discord: {
      status: "idle",
    },
  },
}
```

    活動範例（自訂狀態是預設活動類型）：

```json5
{
  channels: {
    discord: {
      activity: "Focus time",
      activityType: 4,
    },
  },
}
```

    串流範例：

```json5
{
  channels: {
    discord: {
      activity: "Live coding",
      activityType: 1,
      activityUrl: "https://twitch.tv/openclaw",
    },
  },
}
```

    活動類型對應：

    - 0：Playing（遊玩）
    - 1：Streaming（串流，需要 `activityUrl`）
    - 2：Listening（聆聽）
    - 3：Watching（觀看）
    - 4：Custom（自訂，使用 activity 文字作為狀態；表情符號選用）
    - 5：Competing（競賽）

    自動 presence 範例（執行時健康狀態訊號）：

```json5
{
  channels: {
    discord: {
      autoPresence: {
        enabled: true,
        intervalMs: 30000,
        minUpdateIntervalMs: 15000,
        exhaustedText: "token exhausted",
      },
    },
  },
}
```

    自動 presence 將執行時可用性對應到 Discord 狀態：healthy => online，degraded 或 unknown => idle，exhausted 或 unavailable => dnd。選用文字覆蓋：

    - `autoPresence.healthyText`
    - `autoPresence.degradedText`
    - `autoPresence.exhaustedText`（支援 `{reason}` 佔位符）

  </Accordion>

  <Accordion title="Discord 中的 Exec 核准">
    Discord 在 DM 中支援按鈕式 exec 核准，並可選擇在來源頻道中張貼核准提示。

    設定路徑：

    - `channels.discord.execApprovals.enabled`
    - `channels.discord.execApprovals.approvers`
    - `channels.discord.execApprovals.target`（`dm` | `channel` | `both`，預設：`dm`）
    - `agentFilter`、`sessionFilter`、`cleanupAfterResolve`

    當 `target` 為 `channel` 或 `both` 時，核准提示在頻道中可見。只有設定的核准者可以使用按鈕；其他用戶會收到臨時拒絕訊息。核准提示包含指令文字，因此僅在受信任的頻道啟用頻道傳遞。若無法從工作階段金鑰取得頻道 ID，OpenClaw 會退回到 DM 傳遞。

    此處理器的 Gateway 驗證使用與其他 Gateway 用戶端相同的共享憑證解析合約：

    - 環境變數優先的本地驗證（`OPENCLAW_GATEWAY_TOKEN` / `OPENCLAW_GATEWAY_PASSWORD` 然後 `gateway.auth.*`）
    - 在本地模式中，當 `gateway.auth.*` 未設定時，可用 `gateway.remote.*` 作為備用
    - 適用時透過 `gateway.remote.*` 支援遠端模式
    - URL 覆蓋是安全的：CLI 覆蓋不重用隱式憑證，環境變數覆蓋僅使用環境變數憑證

    若核准失敗並出現未知核准 ID，請驗證核准者清單和功能啟用狀態。

    相關文件：[Exec approvals](/zh-Hant/tools/exec-approvals)

  </Accordion>
</AccordionGroup>

## 工具與動作閘道

Discord 訊息動作包括訊息傳遞、頻道管理、仲裁、presence 和 metadata 動作。

核心範例：

- 訊息傳遞：`sendMessage`、`readMessages`、`editMessage`、`deleteMessage`、`threadReply`
- reactions：`react`、`reactions`、`emojiList`
- 仲裁：`timeout`、`kick`、`ban`
- presence：`setPresence`

動作閘道位於 `channels.discord.actions.*`。

預設閘道行為：

| 動作群組                                                                                                                                                                 | 預設 |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---- |
| reactions、messages、threads、pins、polls、search、memberInfo、roleInfo、channelInfo、channels、voiceStatus、events、stickers、emojiUploads、stickerUploads、permissions | 啟用 |
| roles                                                                                                                                                                    | 停用 |
| moderation                                                                                                                                                               | 停用 |
| presence                                                                                                                                                                 | 停用 |

## Components v2 UI

OpenClaw 使用 Discord components v2 進行 exec 核准和跨上下文標記。Discord 訊息動作也可接受 `components` 用於自訂 UI（進階；需要 Carbon 元件實例），而舊版 `embeds` 雖仍可用但不建議使用。

- `channels.discord.ui.components.accentColor` 設定 Discord 元件容器使用的強調色（十六進位）。
- 每帳號設定：`channels.discord.accounts.<id>.ui.components.accentColor`。
- 當 components v2 存在時，`embeds` 會被忽略。

範例：

```json5
{
  channels: {
    discord: {
      ui: {
        components: {
          accentColor: "#5865F2",
        },
      },
    },
  },
}
```

## 語音頻道

OpenClaw 可以加入 Discord 語音頻道進行即時、連續對話。這與語音訊息附件不同。

需求：

- 啟用原生指令（`commands.native` 或 `channels.discord.commands.native`）。
- 設定 `channels.discord.voice`。
- Bot 需要在目標語音頻道擁有 Connect + Speak 權限。

使用 Discord 專用的原生指令 `/vc join|leave|status` 控制工作階段。該指令使用帳號預設 agent 並遵循與其他 Discord 指令相同的 allowlist 和 group policy 規則。

自動加入範例：

```json5
{
  channels: {
    discord: {
      voice: {
        enabled: true,
        autoJoin: [
          {
            guildId: "123456789012345678",
            channelId: "234567890123456789",
          },
        ],
        daveEncryption: true,
        decryptionFailureTolerance: 24,
        tts: {
          provider: "openai",
          openai: { voice: "alloy" },
        },
      },
    },
  },
}
```

注意：

- `voice.tts` 僅對語音播放覆蓋 `messages.tts`。
- 語音轉錄回合從 Discord `allowFrom`（或 `dm.allowFrom`）取得擁有者狀態；非擁有者發言者無法存取僅限擁有者的工具（例如 `gateway` 和 `cron`）。
- 語音預設啟用；設定 `channels.discord.voice.enabled=false` 停用。
- `voice.daveEncryption` 和 `voice.decryptionFailureTolerance` 直接傳遞給 `@discordjs/voice` 加入選項。
- `@discordjs/voice` 預設為 `daveEncryption=true` 和 `decryptionFailureTolerance=24`（若未設定）。
- OpenClaw 也會監控接收解密失敗，並在短時間窗口內重複失敗後自動透過離開/重新加入語音頻道恢復。
- 若接收日誌持續顯示 `DecryptionFailed(UnencryptedWhenPassthroughDisabled)`，這可能是追蹤於 [discord.js #11419](https://github.com/discordjs/discord.js/issues/11419) 的上游 `@discordjs/voice` 接收 bug。

## 語音訊息

Discord 語音訊息顯示波形預覽，需要 OGG/Opus 音訊加上 metadata。OpenClaw 自動生成波形，但需要在 gateway 主機上有可用的 `ffmpeg` 和 `ffprobe` 來檢查和轉換音訊檔案。

需求和限制：

- 提供**本地檔案路徑**（URL 不接受）。
- 省略文字內容（Discord 不允許在同一 payload 中包含文字 + 語音訊息）。
- 接受任何音訊格式；OpenClaw 在需要時轉換為 OGG/Opus。

範例：

```bash
message(action="send", channel="discord", target="channel:123", path="/path/to/audio.mp3", asVoice=true)
```

## 疑難排解

<AccordionGroup>
  <Accordion title="使用了不允許的 intents 或 bot 看不到 guild 訊息">

    - 啟用 Message Content Intent
    - 當你依賴用戶/成員解析時啟用 Server Members Intent
    - 更改 intents 後重啟 gateway

  </Accordion>

  <Accordion title="Guild 訊息被意外封鎖">

    - 驗證 `groupPolicy`
    - 驗證 `channels.discord.guilds` 下的 guild allowlist
    - 若 guild `channels` map 存在，只有列出的頻道被允許
    - 驗證 `requireMention` 行為和 mention 模式

    有用的檢查：

```bash
openclaw doctor
openclaw channels status --probe
openclaw logs --follow
```

  </Accordion>

  <Accordion title="requireMention 為 false 但仍被封鎖">
    常見原因：

    - `groupPolicy="allowlist"` 但沒有匹配的 guild/頻道 allowlist
    - `requireMention` 設定在錯誤的位置（必須在 `channels.discord.guilds` 或頻道條目下）
    - 發送者被 guild/頻道 `users` allowlist 封鎖

  </Accordion>

  <Accordion title="長時間執行的處理器逾時或重複回覆">

    典型日誌：

    - `Listener DiscordMessageListener timed out after 30000ms for event MESSAGE_CREATE`
    - `Slow listener detected ...`
    - `discord inbound worker timed out after ...`

    監聽器預算設定：

    - 單帳號：`channels.discord.eventQueue.listenerTimeout`
    - 多帳號：`channels.discord.accounts.<accountId>.eventQueue.listenerTimeout`

    Worker 執行逾時設定：

    - 單帳號：`channels.discord.inboundWorker.runTimeoutMs`
    - 多帳號：`channels.discord.accounts.<accountId>.inboundWorker.runTimeoutMs`
    - 預設：`1800000`（30 分鐘）；設定 `0` 停用

    建議基準值：

```json5
{
  channels: {
    discord: {
      accounts: {
        default: {
          eventQueue: {
            listenerTimeout: 120000,
          },
          inboundWorker: {
            runTimeoutMs: 1800000,
          },
        },
      },
    },
  },
}
```

    對於緩慢的監聽器設定使用 `eventQueue.listenerTimeout`，只有在需要單獨的排隊 agent 回合安全閥時才使用 `inboundWorker.runTimeoutMs`。

  </Accordion>

  <Accordion title="權限審計不匹配">
    `channels status --probe` 權限檢查僅適用於數字頻道 ID。

    若你使用 slug 金鑰，執行時匹配仍然可以運作，但 probe 無法完全驗證權限。

  </Accordion>

  <Accordion title="DM 和配對問題">

    - DM 停用：`channels.discord.dm.enabled=false`
    - DM 政策停用：`channels.discord.dmPolicy="disabled"`（舊版：`channels.discord.dm.policy`）
    - 在 `pairing` 模式中等待配對核准

  </Accordion>

  <Accordion title="Bot 對 bot 迴圈">
    預設情況下，bot 發送的訊息會被忽略。

    若你設定 `channels.discord.allowBots=true`，請使用嚴格的 mention 和 allowlist 規則以避免迴圈行為。
    建議使用 `channels.discord.allowBots="mentions"` 只接受 mention 了 bot 的 bot 訊息。

  </Accordion>

  <Accordion title="語音 STT 出現 DecryptionFailed(...) 中斷">

    - 保持 OpenClaw 最新（`openclaw update`）以確保 Discord 語音接收恢復邏輯存在
    - 確認 `channels.discord.voice.daveEncryption=true`（預設）
    - 從 `channels.discord.voice.decryptionFailureTolerance=24`（上游預設）開始，只有在需要時才調整
    - 監看日誌：
      - `discord voice: DAVE decrypt failures detected`
      - `discord voice: repeated decrypt failures; attempting rejoin`
    - 若自動重新加入後失敗持續，收集日誌並與 [discord.js #11419](https://github.com/discordjs/discord.js/issues/11419) 對比

  </Accordion>
</AccordionGroup>

## 設定參考指標

主要參考：

- [Configuration reference - Discord](/zh-Hant/gateway/configuration-reference#discord)

高信號 Discord 欄位：

- 啟動/驗證：`enabled`、`token`、`accounts.*`、`allowBots`
- 政策：`groupPolicy`、`dm.*`、`guilds.*`、`guilds.*.channels.*`
- 指令：`commands.native`、`commands.useAccessGroups`、`configWrites`、`slashCommand.*`
- event queue：`eventQueue.listenerTimeout`（監聽器預算）、`eventQueue.maxQueueSize`、`eventQueue.maxConcurrency`
- inbound worker：`inboundWorker.runTimeoutMs`
- 回覆/歷史：`replyToMode`、`historyLimit`、`dmHistoryLimit`、`dms.*.historyLimit`
- 傳遞：`textChunkLimit`、`chunkMode`、`maxLinesPerMessage`
- 串流：`streaming`（舊版別名：`streamMode`）、`draftChunk`、`blockStreaming`、`blockStreamingCoalesce`
- 媒體/重試：`mediaMaxMb`、`retry`
  - `mediaMaxMb` 限制 Discord 出站上傳（預設：`8MB`）
- 動作：`actions.*`
- presence：`activity`、`status`、`activityType`、`activityUrl`
- UI：`ui.components.accentColor`
- 功能：`threadBindings`、頂層 `bindings[]`（`type: "acp"`）、`pluralkit`、`execApprovals`、`intents`、`agentComponents`、`heartbeat`、`responsePrefix`

## 安全與操作

- 將 bot token 視為機密（在受監管的環境中建議使用 `DISCORD_BOT_TOKEN`）。
- 授予 Discord 最低權限。
- 若指令部署/狀態已過期，重啟 gateway 並使用 `openclaw channels status --probe` 重新確認。

## 相關

- [Pairing](/zh-Hant/channels/pairing)
- [Channel routing](/zh-Hant/channels/channel-routing)
- [Multi-agent routing](/zh-Hant/concepts/multi-agent)
- [Troubleshooting](/zh-Hant/channels/troubleshooting)
- [Slash commands](/zh-Hant/tools/slash-commands)
