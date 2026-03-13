---
summary: "Discord Bot 支援狀態、功能說明與設定方式"
read_when:
  - Working on Discord channel features
title: "Discord（Discord Bot API）"
---

# Discord (Bot API)

狀態：已就緒，支援透過官方 Discord Gateway 進行私訊（DM）及伺服器頻道通訊。

<CardGroup cols={3}>
  <Card title="配對" icon="link" href="/zh-Hant/channels/pairing">
    Discord 私訊預設使用配對模式。
  </Card>
  <Card title="斜線指令" icon="terminal" href="/zh-Hant/tools/slash-commands">
    原生指令行為與指令目錄。
  </Card>
  <Card title="頻道疑難排解" icon="wrench" href="/zh-Hant/channels/troubleshooting">
    跨頻道診斷與修復流程。
  </Card>
</CardGroup>

## 快速設定

你需要建立一個含有 Bot 的應用程式、將 Bot 加入你的伺服器，並與 OpenClaw 配對。建議將 Bot 加入你自己的私人伺服器。如果你還沒有伺服器，請先[建立一個](https://support.discord.com/hc/en-us/articles/204849977-How-do-I-create-a-server)（選擇 **Create My Own > For me and my friends**）。

<Steps>
  <Step title="建立 Discord 應用程式與 Bot">
    前往 [Discord 開發者入口網站](https://discord.com/developers/applications)，點選 **New Application**。名稱可取為「OpenClaw」之類的名稱。

    點選側邊欄的 **Bot**，將 **Username** 設為你的 OpenClaw Agent 名稱。

  </Step>

  <Step title="啟用特權 Intent">
    在 **Bot** 頁面，向下捲動至 **Privileged Gateway Intents** 並啟用：

    - **Message Content Intent**（必要）
    - **Server Members Intent**（建議啟用；角色白名單與名稱轉 ID 功能需要此項）
    - **Presence Intent**（選填；僅在需要接收上線狀態更新時啟用）

  </Step>

  <Step title="複製 Bot Token">
    在 **Bot** 頁面向上捲動，點選 **Reset Token**。

    <Note>
    儘管名稱叫「Reset」，這實際上是第一次產生你的 Token，並非重置既有的 Token。
    </Note>

    複製 Token 並妥善保存。這是你的 **Bot Token**，稍後需要用到。

  </Step>

  <Step title="產生邀請網址並將 Bot 加入伺服器">
    點選側邊欄的 **OAuth2**，產生含有適當權限的邀請網址，以將 Bot 加入伺服器。

    向下捲動至 **OAuth2 URL Generator** 並勾選：

    - `bot`
    - `applications.commands`

    下方會出現 **Bot Permissions** 區塊，請啟用：

    - View Channels（檢視頻道）
    - Send Messages（傳送訊息）
    - Read Message History（讀取訊息記錄）
    - Embed Links（嵌入連結）
    - Attach Files（附加檔案）
    - Add Reactions（新增反應，選填）

    複製底部產生的網址，貼到瀏覽器，選擇你的伺服器，點選 **Continue** 完成連接。你應該可以在 Discord 伺服器中看到你的 Bot。

  </Step>

  <Step title="啟用開發者模式並收集 ID">
    回到 Discord 應用程式，你需要啟用開發者模式以便複製內部 ID。

    1. 點選 **用戶設定**（頭像旁的齒輪圖示）→ **進階** → 開啟 **開發者模式**
    2. 右鍵點選側邊欄的 **伺服器圖示** → **複製伺服器 ID**
    3. 右鍵點選你的 **頭像** → **複製用戶 ID**

    將 **伺服器 ID** 與 **用戶 ID** 連同 Bot Token 一起保存——下一步你需要將三者都傳給 OpenClaw。

  </Step>

  <Step title="允許從伺服器成員接收私訊">
    要使配對功能正常運作，Discord 需要允許你的 Bot 向你傳送私訊。右鍵點選**伺服器圖示** → **隱私設定** → 開啟 **私訊**。

    這讓伺服器成員（包括 Bot）可以向你傳送私訊。如果你想搭配 OpenClaw 使用 Discord 私訊，請保持此設定啟用。若你只打算使用伺服器頻道，配對完成後可以關閉。

  </Step>

  <Step title="步驟 0：安全地設定 Bot Token（不要在聊天中傳送）">
    你的 Discord Bot Token 是機密資訊（類似密碼）。請在執行 OpenClaw 的機器上設定，再開始與 Agent 聊天。

```bash
openclaw config set channels.discord.token '"YOUR_BOT_TOKEN"' --json
openclaw config set channels.discord.enabled true --json
openclaw gateway
```

    如果 OpenClaw 已作為背景服務執行，請改用 `openclaw gateway restart`。

  </Step>

  <Step title="設定 OpenClaw 並配對">

    <Tabs>
      <Tab title="詢問你的 Agent">
        透過任何現有頻道（例如 Telegram）與你的 OpenClaw Agent 對話並告知它。如果 Discord 是你的第一個頻道，請改用 CLI / 設定 頁籤。

        > "我已在設定中設好我的 Discord Bot Token。請用 User ID `<user_id>` 和 Server ID `<server_id>` 完成 Discord 設定。"
      </Tab>
      <Tab title="CLI / 設定">
        如果你偏好以檔案方式設定：

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

        預設帳號的環境變數備援：

```bash
DISCORD_BOT_TOKEN=...
```

        `channels.discord.token` 也支援 SecretRef 值（env/file/exec 提供者）。請參閱[機密管理](/zh-Hant/gateway/secrets)。

      </Tab>
    </Tabs>

  </Step>

  <Step title="核准第一次私訊配對">
    等待 Gateway 啟動後，在 Discord 中向你的 Bot 傳送私訊，Bot 會回覆一組配對碼。

    <Tabs>
      <Tab title="詢問你的 Agent">
        透過現有頻道將配對碼傳給你的 Agent：

        > "請核准此 Discord 配對碼：`<CODE>`"
      </Tab>
      <Tab title="CLI">

```bash
openclaw pairing list discord
openclaw pairing approve discord <CODE>
```

      </Tab>
    </Tabs>

    配對碼在 1 小時後過期。

    你現在應該可以透過 Discord 私訊與你的 Agent 聊天了。

  </Step>
</Steps>

<Note>
Token 解析具備帳號感知能力。設定中的 Token 優先於環境變數備援。`DISCORD_BOT_TOKEN` 僅適用於預設帳號。
進階輸出呼叫（訊息工具/頻道操作）使用該呼叫的明確 per-call `token`。帳號政策/重試設定仍來自當前執行快照中選取的帳號。
</Note>

## 建議：設定伺服器工作區

私訊運作正常後，你可以將 Discord 伺服器設定為完整工作區，讓每個頻道擁有獨立的 Agent 工作階段與情境。這對於只有你和 Bot 的私人伺服器特別推薦。

<Steps>
  <Step title="將你的伺服器加入伺服器白名單">
    這讓你的 Agent 能在伺服器的任何頻道回覆，而不只是私訊。

    <Tabs>
      <Tab title="詢問你的 Agent">
        > "請將我的 Discord 伺服器 ID `<server_id>` 加入伺服器白名單"
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

  <Step title="允許不需要 @mention 即可回覆">
    預設情況下，你的 Agent 只會在伺服器頻道被 @mention 時回覆。對於私人伺服器，你可能希望它回覆每一條訊息。

    <Tabs>
      <Tab title="詢問你的 Agent">
        > "讓我的 Agent 在這個伺服器上無需被 @mention 就能回覆"
      </Tab>
      <Tab title="設定">
        在你的伺服器設定中將 `requireMention` 設為 `false`：

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

  <Step title="規劃伺服器頻道的記憶機制">
    預設情況下，長期記憶（MEMORY.md）只會在私訊工作階段載入。伺服器頻道不會自動載入 MEMORY.md。

    <Tabs>
      <Tab title="詢問你的 Agent">
        > "當我在 Discord 頻道提問時，如需 MEMORY.md 的長期情境請使用 memory_search 或 memory_get。"
      </Tab>
      <Tab title="手動設定">
        如果你需要在每個頻道都有共享情境，請將穩定的指示放入 `AGENTS.md` 或 `USER.md`（每個工作階段都會注入這些檔案）。長期備忘放在 `MEMORY.md`，需要時用記憶工具存取。
      </Tab>
    </Tabs>

  </Step>
</Steps>

現在在你的 Discord 伺服器上建立一些頻道並開始聊天。你的 Agent 可以看到頻道名稱，每個頻道都有自己獨立的工作階段，所以你可以設定 `#coding`、`#home`、`#research`，或任何符合你工作流程的頻道。

## 執行模型

- Gateway 擁有 Discord 連線。
- 回覆路由是確定性的：Discord 收入的訊息回覆至 Discord。
- 預設情況下（`session.dmScope=main`），直接聊天共用 Agent 主要工作階段（`agent:main:main`）。
- 伺服器頻道使用獨立的工作階段金鑰（`agent:<agentId>:discord:channel:<channelId>`）。
- 群組私訊預設被忽略（`channels.discord.dm.groupEnabled=false`）。
- 原生斜線指令在獨立的指令工作階段中執行（`agent:<agentId>:discord:slash:<userId>`），同時仍將 `CommandTargetSessionKey` 傳遞至路由的對話工作階段。

## 論壇頻道

Discord 論壇與媒體頻道只接受討論串貼文。OpenClaw 支援兩種建立方式：

- 傳送訊息至論壇父頻道（`channel:<forumId>`）以自動建立討論串。討論串標題使用訊息的第一個非空行。
- 使用 `openclaw message thread create` 直接建立討論串。論壇頻道不要傳入 `--message-id`。

範例：傳送至論壇父頻道以建立討論串

```bash
openclaw message send --channel discord --target channel:<forumId> \
  --message "Topic title\nBody of the post"
```

範例：明確建立論壇討論串

```bash
openclaw message thread create --channel discord --target channel:<forumId> \
  --thread-name "Topic title" --message "Body of the post"
```

論壇父頻道不接受 Discord 元件。如果需要元件，請傳送至討論串本身（`channel:<threadId>`）。

## 互動元件

OpenClaw 支援 Agent 訊息使用 Discord 元件 v2 容器。使用訊息工具並附上 `components` 載荷。互動結果會作為一般收入訊息路由回 Agent，並遵循現有的 Discord `replyToMode` 設定。

支援的區塊：

- `text`、`section`、`separator`、`actions`、`media-gallery`、`file`
- Action rows 允許最多 5 個按鈕或一個下拉選單
- 下拉選單類型：`string`、`user`、`role`、`mentionable`、`channel`

預設情況下，元件為單次使用。設定 `components.reusable=true` 可讓按鈕、下拉選單和表單在過期前多次使用。

若要限制誰可以點擊按鈕，請在該按鈕上設定 `allowedUsers`（Discord 用戶 ID、標籤或 `*`）。設定後，不符合的用戶會收到暫時性拒絕通知。

`/model` 和 `/models` 斜線指令會開啟互動式模型選擇器，包含提供者和模型下拉選單及提交步驟。選擇器回覆為暫時性，只有呼叫者可以使用。

檔案附件：

- `file` 區塊必須指向附件參照（`attachment://<filename>`）
- 透過 `media`/`path`/`filePath` 提供附件（單一檔案）；多個檔案使用 `media-gallery`
- 使用 `filename` 在上傳名稱需要符合附件參照時覆寫名稱

Modal 表單：

- 在 `components.modal` 中新增最多 5 個欄位
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
  <Tab title="私訊政策">
    `channels.discord.dmPolicy` 控制私訊存取（舊版：`channels.discord.dm.policy`）：

    - `pairing`（預設）
    - `allowlist`
    - `open`（需要 `channels.discord.allowFrom` 包含 `"*"`；舊版：`channels.discord.dm.allowFrom`）
    - `disabled`

    若私訊政策非 open，未知用戶將被封鎖（或在 `pairing` 模式下提示配對）。

    多帳號優先順序：

    - `channels.discord.accounts.default.allowFrom` 僅適用於 `default` 帳號。
    - 具名帳號在未設定自己的 `allowFrom` 時，繼承 `channels.discord.allowFrom`。
    - 具名帳號不繼承 `channels.discord.accounts.default.allowFrom`。

    傳送的私訊目標格式：

    - `user:<id>`
    - `<@id>` mention

    裸數字 ID 因具有歧義性而被拒絕，除非提供明確的 user/channel 目標類型。

  </Tab>

  <Tab title="伺服器政策">
    伺服器處理由 `channels.discord.groupPolicy` 控制：

    - `open`
    - `allowlist`
    - `disabled`

    當 `channels.discord` 存在時，安全基準為 `allowlist`。

    `allowlist` 行為：

    - 伺服器必須符合 `channels.discord.guilds`（優先使用 `id`，接受 slug）
    - 選填的發送者白名單：`users`（建議使用穩定 ID）和 `roles`（僅 role ID）；若兩者都已設定，發送者符合 `users` OR `roles` 時才被允許
    - 直接名稱/標籤比對預設停用；僅在緊急相容模式下啟用 `channels.discord.dangerouslyAllowNameMatching: true`
    - `users` 支援名稱/標籤，但 ID 更安全；使用名稱/標籤時 `openclaw security audit` 會發出警告
    - 若伺服器設有 `channels`，不在列表中的頻道會被拒絕
    - 若伺服器沒有 `channels` 區塊，該白名單伺服器的所有頻道均被允許

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

    如果你只設定 `DISCORD_BOT_TOKEN` 而未建立 `channels.discord` 區塊，執行時備援為 `groupPolicy="allowlist"`（日誌中會有警告），即使 `channels.defaults.groupPolicy` 設為 `open`。

  </Tab>

  <Tab title="Mention 與群組私訊">
    伺服器訊息預設需要 mention 才能觸發。

    Mention 偵測包含：

    - 明確的 Bot mention
    - 設定的 mention 模式（`agents.list[].groupChat.mentionPatterns`，備援 `messages.groupChat.mentionPatterns`）
    - 支援的情況下隱式回覆 Bot 行為

    `requireMention` 在每個伺服器/頻道設定（`channels.discord.guilds...`）。
    `ignoreOtherMentions` 可選擇性忽略 mention 了其他用戶/角色但未 mention Bot 的訊息（排除 @everyone/@here）。

    群組私訊：

    - 預設：忽略（`dm.groupEnabled=false`）
    - 可選擇透過 `dm.groupChannels`（頻道 ID 或 slug）設定白名單

  </Tab>
</Tabs>

### 基於角色的 Agent 路由

使用 `bindings[].match.roles` 可依角色 ID 將 Discord 伺服器成員路由至不同的 Agent。基於角色的 binding 僅接受角色 ID，優先順序在 peer 或 parent-peer binding 之後、純伺服器 binding 之前評估。若 binding 同時設定了其他 match 欄位（例如 `peer` + `guildId` + `roles`），所有設定的欄位都必須符合。

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

## 開發者入口網站設定

<AccordionGroup>
  <Accordion title="建立應用程式與 Bot">

    1. Discord 開發者入口網站 -> **Applications** -> **New Application**
    2. **Bot** -> **Add Bot**
    3. 複製 Bot Token

  </Accordion>

  <Accordion title="特權 Intent">
    在 **Bot -> Privileged Gateway Intents** 中啟用：

    - Message Content Intent
    - Server Members Intent（建議）

    Presence Intent 為選填，只有在需要接收成員上線狀態更新時才需要。設定 Bot presence（`setPresence`）不需要啟用成員 presence 更新。

  </Accordion>

  <Accordion title="OAuth 範圍與基本權限">
    OAuth URL 產生器：

    - 範圍：`bot`、`applications.commands`

    典型基本權限：

    - View Channels
    - Send Messages
    - Read Message History
    - Embed Links
    - Attach Files
    - Add Reactions（選填）

    除非明確需要，否則避免 `Administrator`。

  </Accordion>

  <Accordion title="複製 ID">
    啟用 Discord 開發者模式，然後複製：

    - 伺服器 ID
    - 頻道 ID
    - 用戶 ID

    在 OpenClaw 設定中優先使用數字 ID，以確保可靠的稽核與探測。

  </Accordion>
</AccordionGroup>

## 原生指令與指令驗證

- `commands.native` 預設為 `"auto"`，在 Discord 上已啟用。
- 每頻道覆寫：`channels.discord.commands.native`。
- `commands.native=false` 會明確清除先前已註冊的 Discord 原生指令。
- 原生指令驗證使用與一般訊息處理相同的 Discord 白名單/政策。
- 未獲授權的用戶仍可能在 Discord UI 中看到指令；執行仍會強制執行 OpenClaw 驗證並回傳「未授權」。

請參閱[斜線指令](/zh-Hant/tools/slash-commands)了解指令目錄與行為。

預設斜線指令設定：

- `ephemeral: true`

## 功能詳細說明

<AccordionGroup>
  <Accordion title="回覆標籤與原生回覆">
    Discord 支援 Agent 輸出中的回覆標籤：

    - `[[reply_to_current]]`
    - `[[reply_to:<id>]]`

    由 `channels.discord.replyToMode` 控制：

    - `off`（預設）
    - `first`
    - `all`

    注意：`off` 停用隱式回覆串。明確的 `[[reply_to_*]]` 標籤仍然有效。

    訊息 ID 會顯示在情境/記錄中，讓 Agent 可以針對特定訊息回覆。

  </Accordion>

  <Accordion title="即時串流預覽">
    OpenClaw 可以透過傳送暫時訊息並在文字到來時編輯它來串流草稿回覆。

    - `channels.discord.streaming` 控制預覽串流（`off` | `partial` | `block` | `progress`，預設：`off`）。
    - `progress` 為跨頻道一致性而被接受，在 Discord 上映射為 `partial`。
    - `channels.discord.streamMode` 是舊版別名，會自動遷移。
    - `partial` 在 Token 到來時編輯單一預覽訊息。
    - `block` 發出草稿大小的區塊（使用 `draftChunk` 調整大小和分割點）。

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

    `block` 模式區塊預設值（受 `channels.discord.textChunkLimit` 限制）：

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

    預覽串流僅適用於文字；媒體回覆會退回到一般傳送方式。

    注意：預覽串流與區塊串流是分開的。當 Discord 明確啟用區塊串流時，OpenClaw 會跳過預覽串流以避免雙重串流。

  </Accordion>

  <Accordion title="記錄、情境與討論串行為">
    伺服器記錄情境：

    - `channels.discord.historyLimit` 預設 `20`
    - 備援：`messages.groupChat.historyLimit`
    - `0` 停用

    私訊記錄控制：

    - `channels.discord.dmHistoryLimit`
    - `channels.discord.dms["<user_id>"].historyLimit`

    討論串行為：

    - Discord 討論串以頻道工作階段路由
    - 父討論串中繼資料可用於父工作階段連結
    - 討論串設定繼承父頻道設定，除非有特定的討論串項目

    頻道主題注入為**不可信任的**情境（不作為系統提示）。

  </Accordion>

  <Accordion title="子 Agent 的討論串綁定工作階段">
    Discord 可以將討論串綁定至工作階段目標，讓該討論串的後續訊息持續路由至相同工作階段（包括子 Agent 工作階段）。

    指令：

    - `/focus <target>` 將當前/新討論串綁定至子 Agent/工作階段目標
    - `/unfocus` 移除當前討論串綁定
    - `/agents` 顯示執行中的工作階段與綁定狀態
    - `/session idle <duration|off>` 查看/更新已聚焦綁定的閒置自動解除綁定設定
    - `/session max-age <duration|off>` 查看/更新已聚焦綁定的最大存活時間

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
    - `channels.discord.threadBindings.*` 覆寫 Discord 行為。
    - `spawnSubagentSessions` 必須為 true 才能自動為 `sessions_spawn({ thread: true })` 建立/綁定討論串。
    - `spawnAcpSessions` 必須為 true 才能自動為 ACP（`/acp spawn ... --thread ...` 或 `sessions_spawn({ runtime: "acp", thread: true })`）建立/綁定討論串。
    - 若某帳號停用了討論串綁定，`/focus` 及相關討論串綁定操作將無法使用。

    請參閱[子 Agent](/zh-Hant/tools/subagents)、[ACP Agents](/zh-Hant/tools/acp-agents) 和[設定參考](/zh-Hant/gateway/configuration-reference)。

  </Accordion>

  <Accordion title="持久性 ACP 頻道綁定">
    若要建立穩定的「永遠在線」ACP 工作區，請設定指向 Discord 對話的頂層類型化 ACP binding。

    設定路徑：

    - `bindings[]` 包含 `type: "acp"` 且 `match.channel: "discord"`

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

    - 討論串訊息可繼承父頻道的 ACP binding。
    - 在已綁定的頻道或討論串中，`/new` 和 `/reset` 會就地重置相同的 ACP 工作階段。
    - 暫時性討論串綁定仍有效，可在活躍時覆寫目標解析。

    請參閱 [ACP Agents](/zh-Hant/tools/acp-agents) 了解 binding 行為詳細說明。

  </Accordion>

  <Accordion title="反應通知">
    每個伺服器的反應通知模式：

    - `off`
    - `own`（預設）
    - `all`
    - `allowlist`（使用 `guilds.<id>.users`）

    反應事件會轉換為系統事件，並附加至路由的 Discord 工作階段。

  </Accordion>

  <Accordion title="確認反應">
    `ackReaction` 在 OpenClaw 處理收入訊息時傳送確認 emoji。

    解析順序：

    - `channels.discord.accounts.<accountId>.ackReaction`
    - `channels.discord.ackReaction`
    - `messages.ackReaction`
    - Agent 身份 emoji 備援（`agents.list[].identity.emoji`，否則使用 "👀"）

    注意：

    - Discord 接受 unicode emoji 或自訂 emoji 名稱。
    - 使用 `""` 停用特定頻道或帳號的反應。

  </Accordion>

  <Accordion title="設定寫入">
    頻道發起的設定寫入預設啟用。

    這影響 `/config set|unset` 流程（當指令功能已啟用時）。

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

  <Accordion title="Gateway Proxy">
    透過 `channels.discord.proxy` 將 Discord Gateway WebSocket 流量和啟動 REST 查詢（應用程式 ID + 白名單解析）路由至 HTTP(S) Proxy。

```json5
{
  channels: {
    discord: {
      proxy: "http://proxy.example:8080",
    },
  },
}
```

    每帳號覆寫：

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
    啟用 PluralKit 解析以將代理訊息映射至系統成員身份：

```json5
{
  channels: {
    discord: {
      pluralkit: {
        enabled: true,
        token: "pk_live_...", // 選填；私人系統需要此項
      },
    },
  },
}
```

    注意：

    - 白名單可使用 `pk:<memberId>`
    - 成員顯示名稱僅在 `channels.discord.dangerouslyAllowNameMatching: true` 時才以名稱/slug 比對
    - 查詢使用原始訊息 ID 並受時間窗限制
    - 若查詢失敗，代理訊息被視為 Bot 訊息而被丟棄，除非設定了 `allowBots=true`

  </Accordion>

  <Accordion title="上線狀態設定">
    當你設定狀態或活動欄位，或啟用自動上線狀態時，上線狀態更新會被套用。

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
    - 4：Custom（自訂，使用活動文字作為狀態文字；emoji 選填）
    - 5：Competing（競技）

    自動上線狀態範例（執行時健康訊號）：

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

    自動上線狀態將執行時可用性映射至 Discord 狀態：健康 => online，降級或未知 => idle，耗盡或不可用 => dnd。選填文字覆寫：

    - `autoPresence.healthyText`
    - `autoPresence.degradedText`
    - `autoPresence.exhaustedText`（支援 `{reason}` 佔位符）

  </Accordion>

  <Accordion title="Discord 中的執行核准">
    Discord 支援私訊中基於按鈕的執行核准，也可以選擇性地在來源頻道張貼核准提示。

    設定路徑：

    - `channels.discord.execApprovals.enabled`
    - `channels.discord.execApprovals.approvers`
    - `channels.discord.execApprovals.target`（`dm` | `channel` | `both`，預設：`dm`）
    - `agentFilter`、`sessionFilter`、`cleanupAfterResolve`

    當 `target` 為 `channel` 或 `both` 時，核准提示在頻道中可見。只有已設定的核准者可以使用按鈕；其他用戶會收到暫時性拒絕。核准提示包含指令文字，因此請只在受信任的頻道啟用頻道傳送。若頻道 ID 無法從工作階段金鑰取得，OpenClaw 會退回至私訊傳送。

    此處理程式的 Gateway 驗證使用與其他 Gateway 客戶端相同的共享憑證解析：

    - 環境優先的本地驗證（`OPENCLAW_GATEWAY_TOKEN` / `OPENCLAW_GATEWAY_PASSWORD`，然後 `gateway.auth.*`）
    - 本地模式下，只有在 `gateway.auth.*` 未設定時，`gateway.remote.*` 才可作為備援；已設定但無法解析的本地 SecretRef 會失敗關閉
    - 適用時透過 `gateway.remote.*` 支援遠端模式
    - URL 覆寫是安全的：CLI 覆寫不重用隱式憑證，環境覆寫僅使用環境憑證

    若核准失敗並顯示未知的核准 ID，請確認核准者清單和功能啟用狀態。

    相關文件：[執行核准](/zh-Hant/tools/exec-approvals)

  </Accordion>
</AccordionGroup>

## 工具與操作閘門

Discord 訊息操作包括訊息傳送、頻道管理、版主操作、上線狀態和中繼資料操作。

核心範例：

- 訊息：`sendMessage`、`readMessages`、`editMessage`、`deleteMessage`、`threadReply`
- 反應：`react`、`reactions`、`emojiList`
- 版主：`timeout`、`kick`、`ban`
- 上線狀態：`setPresence`

操作閘門位於 `channels.discord.actions.*`。

預設閘門行為：

| 操作群組                                                                                                                                                                 | 預設 |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---- |
| reactions, messages, threads, pins, polls, search, memberInfo, roleInfo, channelInfo, channels, voiceStatus, events, stickers, emojiUploads, stickerUploads, permissions | 啟用 |
| roles                                                                                                                                                                    | 停用 |
| moderation                                                                                                                                                               | 停用 |
| presence                                                                                                                                                                 | 停用 |

## 元件 v2 UI

OpenClaw 使用 Discord 元件 v2 進行執行核准和跨情境標記。Discord 訊息操作也可接受 `components` 自訂 UI（進階功能；需要 Carbon 元件實例），而舊版 `embeds` 仍可使用但不建議。

- `channels.discord.ui.components.accentColor` 設定 Discord 元件容器使用的強調色（十六進位）。
- 每帳號設定：`channels.discord.accounts.<id>.ui.components.accentColor`。
- 存在元件 v2 時會忽略 `embeds`。

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

OpenClaw 可以加入 Discord 語音頻道進行即時、持續的對話。這與語音訊息附件是不同的功能。

需求：

- 啟用原生指令（`commands.native` 或 `channels.discord.commands.native`）。
- 設定 `channels.discord.voice`。
- Bot 需要在目標語音頻道擁有 Connect + Speak 權限。

使用 Discord 限定的原生指令 `/vc join|leave|status` 控制工作階段。該指令使用帳號預設 Agent，並遵循與其他 Discord 指令相同的白名單和群組政策規則。

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

- `voice.tts` 僅覆寫語音播放的 `messages.tts`。
- 語音轉錄輪次從 Discord `allowFrom`（或 `dm.allowFrom`）取得擁有者狀態；非擁有者的發言者無法存取僅限擁有者的工具（例如 `gateway` 和 `cron`）。
- 語音預設啟用；設定 `channels.discord.voice.enabled=false` 可停用。
- `voice.daveEncryption` 和 `voice.decryptionFailureTolerance` 傳遞至 `@discordjs/voice` 的加入選項。
- `@discordjs/voice` 的預設值為 `daveEncryption=true` 和 `decryptionFailureTolerance=24`（若未設定）。
- OpenClaw 也監視接收解密失敗，並在短時間內重複失敗後自動離開/重新加入語音頻道進行恢復。
- 若接收日誌持續顯示 `DecryptionFailed(UnencryptedWhenPassthroughDisabled)`，這可能是 [discord.js #11419](https://github.com/discordjs/discord.js/issues/11419) 追蹤的上游 `@discordjs/voice` 接收錯誤。

## 語音訊息

Discord 語音訊息顯示波形預覽，需要 OGG/Opus 音訊及中繼資料。OpenClaw 會自動產生波形，但需要 Gateway 主機上有 `ffmpeg` 和 `ffprobe` 才能檢視和轉換音訊檔案。

需求與限制：

- 必須提供**本地檔案路徑**（不接受 URL）。
- 省略文字內容（Discord 不允許在相同載荷中同時包含文字和語音訊息）。
- 接受任何音訊格式；OpenClaw 在需要時會轉換為 OGG/Opus。

範例：

```bash
message(action="send", channel="discord", target="channel:123", path="/path/to/audio.mp3", asVoice=true)
```

## 疑難排解

<AccordionGroup>
  <Accordion title="使用了不允許的 Intent 或 Bot 看不到伺服器訊息">

    - 啟用 Message Content Intent
    - 當你依賴用戶/成員解析時，啟用 Server Members Intent
    - 變更 Intent 後重啟 Gateway

  </Accordion>

  <Accordion title="伺服器訊息意外被封鎖">

    - 確認 `groupPolicy`
    - 確認 `channels.discord.guilds` 下的伺服器白名單
    - 若伺服器有 `channels` 映射，只有列出的頻道才被允許
    - 確認 `requireMention` 行為與 mention 模式

    實用的指令：

```bash
openclaw doctor
openclaw channels status --probe
openclaw logs --follow
```

  </Accordion>

  <Accordion title="requireMention 設為 false 但仍然被封鎖">
    常見原因：

    - `groupPolicy="allowlist"` 但沒有符合的伺服器/頻道白名單
    - `requireMention` 設定在錯誤的位置（必須在 `channels.discord.guilds` 或頻道項目下）
    - 發送者被伺服器/頻道的 `users` 白名單封鎖

  </Accordion>

  <Accordion title="長時間執行的處理程式超時或重複回覆">

    典型日誌：

    - `Listener DiscordMessageListener timed out after 30000ms for event MESSAGE_CREATE`
    - `Slow listener detected ...`
    - `discord inbound worker timed out after ...`

    監聽器預算調節：

    - 單帳號：`channels.discord.eventQueue.listenerTimeout`
    - 多帳號：`channels.discord.accounts.<accountId>.eventQueue.listenerTimeout`

    工作執行超時調節：

    - 單帳號：`channels.discord.inboundWorker.runTimeoutMs`
    - 多帳號：`channels.discord.accounts.<accountId>.inboundWorker.runTimeoutMs`
    - 預設：`1800000`（30 分鐘）；設為 `0` 停用

    建議基準：

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

    慢速監聽器設定使用 `eventQueue.listenerTimeout`；只有在需要額外的佇列 Agent 輪次安全閥時才使用 `inboundWorker.runTimeoutMs`。

  </Accordion>

  <Accordion title="權限稽核不符">
    `channels status --probe` 的權限檢查只適用於數字頻道 ID。

    若你使用 slug 金鑰，執行時比對仍可運作，但探測無法完整驗證權限。

  </Accordion>

  <Accordion title="私訊與配對問題">

    - 私訊已停用：`channels.discord.dm.enabled=false`
    - 私訊政策已停用：`channels.discord.dmPolicy="disabled"`（舊版：`channels.discord.dm.policy`）
    - 在 `pairing` 模式下等待配對核准

  </Accordion>

  <Accordion title="Bot 對 Bot 的循環問題">
    預設情況下，Bot 發送的訊息會被忽略。

    若你設定了 `channels.discord.allowBots=true`，請使用嚴格的 mention 和白名單規則以避免循環行為。
    建議使用 `channels.discord.allowBots="mentions"` 以僅接受有 mention Bot 的 Bot 訊息。

  </Accordion>

  <Accordion title="語音 STT 因 DecryptionFailed(...) 中斷">

    - 保持 OpenClaw 最新（`openclaw update`）以確保 Discord 語音接收恢復邏輯存在
    - 確認 `channels.discord.voice.daveEncryption=true`（預設值）
    - 從 `channels.discord.voice.decryptionFailureTolerance=24`（上游預設）開始，只在需要時調整
    - 監看日誌：
      - `discord voice: DAVE decrypt failures detected`
      - `discord voice: repeated decrypt failures; attempting rejoin`
    - 若在自動重新加入後仍持續失敗，請收集日誌並對照 [discord.js #11419](https://github.com/discordjs/discord.js/issues/11419)

  </Accordion>
</AccordionGroup>

## 設定參考指引

主要參考：

- [設定參考 - Discord](/zh-Hant/gateway/configuration-reference#discord)

Discord 重要欄位：

- 啟動/驗證：`enabled`、`token`、`accounts.*`、`allowBots`
- 政策：`groupPolicy`、`dm.*`、`guilds.*`、`guilds.*.channels.*`
- 指令：`commands.native`、`commands.useAccessGroups`、`configWrites`、`slashCommand.*`
- 事件佇列：`eventQueue.listenerTimeout`（監聽器預算）、`eventQueue.maxQueueSize`、`eventQueue.maxConcurrency`
- 收入工作：`inboundWorker.runTimeoutMs`
- 回覆/記錄：`replyToMode`、`historyLimit`、`dmHistoryLimit`、`dms.*.historyLimit`
- 傳送：`textChunkLimit`、`chunkMode`、`maxLinesPerMessage`
- 串流：`streaming`（舊版別名：`streamMode`）、`draftChunk`、`blockStreaming`、`blockStreamingCoalesce`
- 媒體/重試：`mediaMaxMb`、`retry`
  - `mediaMaxMb` 限制 Discord 上傳大小（預設：`8MB`）
- 操作：`actions.*`
- 上線狀態：`activity`、`status`、`activityType`、`activityUrl`
- UI：`ui.components.accentColor`
- 功能：`threadBindings`、頂層 `bindings[]`（`type: "acp"`）、`pluralkit`、`execApprovals`、`intents`、`agentComponents`、`heartbeat`、`responsePrefix`

## 安全性與操作

- 將 Bot Token 視為機密資訊（建議在受監控的環境中使用 `DISCORD_BOT_TOKEN`）。
- 授予最小必要的 Discord 權限。
- 若指令部署/狀態已過期，重啟 Gateway 並用 `openclaw channels status --probe` 重新確認。

## 相關文件

- [配對](/zh-Hant/channels/pairing)
- [頻道路由](/zh-Hant/channels/channel-routing)
- [多 Agent 路由](/zh-Hant/concepts/multi-agent)
- [疑難排解](/zh-Hant/channels/troubleshooting)
- [斜線指令](/zh-Hant/tools/slash-commands)
