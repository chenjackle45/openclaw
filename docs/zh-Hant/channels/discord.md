---
title: "Discord"
summary: "Discord 機器人支援狀態、功能和設定"
read_when:
  - 處理 Discord 頻道功能
---

# Discord（Bot API）

狀態：透過官方 Discord 機器人 gateway，DM 和伺服器文字頻道已準備就緒。

## 快速設定（初學者）

1. 建立 Discord 機器人並複製機器人令牌。
2. 在 Discord 應用程式設定中，啟用 **Message Content Intent**（如果您計劃使用允許清單或名稱查詢，還需啟用 **Server Members Intent**）。
3. 為 OpenClaw 設定令牌：
   - 環境變數：`DISCORD_BOT_TOKEN=...`
   - 或設定：`channels.discord.token: "..."`。
   - 如果兩者都設定，設定優先（環境變數備選僅用於預設帳戶）。
4. 使用訊息權限邀請機器人到您的伺服器（如果您只想要 DM，可以建立私人伺服器）。
5. 啟動 gateway。
6. DM 存取預設為配對；首次聯繫時批准配對碼。

最小設定：

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

## 目標

- 透過 Discord DM 或伺服器頻道與 OpenClaw 對話。
- 直接聊天歸納到代理的主會話（預設 `agent:main:main`）；伺服器頻道保持隔離為 `agent:<agentId>:discord:channel:<channelId>`（顯示名稱使用 `discord:<guildSlug>#<channelSlug>`）。
- 群組 DM 預設被忽略；透過 `channels.discord.dm.groupEnabled` 啟用，並可選擇透過 `channels.discord.dm.groupChannels` 限制。
- 保持路由確定性：回覆始終返回它們到達的頻道。

## 運作方式

1. 建立 Discord 應用程式 → Bot，啟用您需要的 intent（DM + guild messages + message content），並取得機器人令牌。
2. 使用您想要使用的位置所需的讀取/發送訊息權限邀請機器人到您的伺服器。
3. 使用 `channels.discord.token`（或 `DISCORD_BOT_TOKEN` 作為備選）設定 OpenClaw。
4. 運行 gateway；當令牌可用（設定優先，環境變數備選）且 `channels.discord.enabled` 不是 `false` 時，它會自動啟動 Discord 頻道。
   - 如果您偏好環境變數，設定 `DISCORD_BOT_TOKEN`（設定區塊是可選的）。
5. 直接聊天：交付時使用 `user:<id>`（或 `<@id>` mention）；所有輪次落在共享的 `main` 會話中。裸數字 ID 是模糊的，會被拒絕。
6. 伺服器頻道：交付時使用 `channel:<channelId>`。預設需要 mention，可以按伺服器或按頻道設定。
7. 直接聊天：預設透過 `channels.discord.dm.policy` 保護（預設：`"pairing"`）。未知發送者收到配對碼（1 小時後過期）；透過 `openclaw pairing approve discord <code>` 批准。
   - 要保持舊的「對任何人開放」行為：設定 `channels.discord.dm.policy="open"` 和 `channels.discord.dm.allowFrom=["*"]`。
   - 要硬允許清單：設定 `channels.discord.dm.policy="allowlist"` 並在 `channels.discord.dm.allowFrom` 中列出發送者。
   - 要忽略所有 DM：設定 `channels.discord.dm.enabled=false` 或 `channels.discord.dm.policy="disabled"`。
8. 群組 DM 預設被忽略；透過 `channels.discord.dm.groupEnabled` 啟用，並可選擇透過 `channels.discord.dm.groupChannels` 限制。
9. 可選的伺服器規則：設定 `channels.discord.guilds` 以伺服器 ID（首選）或 slug 為鍵，包含每頻道規則。
10. 可選的 native command：`commands.native` 預設為 `"auto"`（Discord/Telegram 開啟，Slack 關閉）。使用 `channels.discord.commands.native: true|false|"auto"` 覆寫；`false` 清除先前註冊的命令。文字命令由 `commands.text` 控制，必須作為獨立的 `/...` 訊息發送。使用 `commands.useAccessGroups: false` 繞過命令的存取群組檢查。
    - 完整命令列表 + 設定：[斜線命令](/tools/slash-commands)
11. 可選的伺服器上下文歷史：設定 `channels.discord.historyLimit`（預設 20，回退到 `messages.groupChat.historyLimit`）以在回覆 mention 時包含最後 N 條伺服器訊息作為上下文。設定 `0` 停用。
12. 反應：代理可以透過 `discord` 工具觸發反應（由 `channels.discord.actions.*` 閘門控制）。
    - 反應移除語意：請參閱[/tools/reactions](/tools/reactions)。
    - `discord` 工具僅在當前頻道為 Discord 時公開。
13. Native command 使用隔離的會話鍵（`agent:<agentId>:discord:slash:<userId>`）而不是共享的 `main` 會話。

備註：名稱 → ID 解析使用伺服器成員搜尋，需要 Server Members Intent；如果機器人無法搜尋成員，請使用 ID 或 `<@id>` mention。
備註：Slug 為小寫，空格替換為 `-`。頻道名稱不帶前導 `#` 進行 slug 化。
備註：伺服器上下文 `[from:]` 行包含 `author.tag` + `id`，使 ping-ready 回覆變得容易。

## 設定寫入

預設情況下，Discord 允許寫入由 `/config set|unset` 觸發的設定更新（需要 `commands.config: true`）。

停用方式：

```json5
{
  channels: { discord: { configWrites: false } },
}
```

## 如何建立您自己的機器人

這是在伺服器（guild）頻道如 `#help` 中運行 OpenClaw 的「Discord 開發者入口」設定。

### 1) 建立 Discord 應用程式 + 機器人用戶

1. Discord 開發者入口 → **Applications** → **New Application**
2. 在您的應用程式中：
   - **Bot** → **Add Bot**
   - 複製 **Bot Token**（這是您放入 `DISCORD_BOT_TOKEN` 的內容）

### 2) 啟用 OpenClaw 需要的 gateway intent

Discord 會阻止「特權 intent」，除非您明確啟用它們。

在 **Bot** → **Privileged Gateway Intents** 中，啟用：

- **Message Content Intent**（在大多數伺服器中讀取訊息文字所必需；沒有它您會看到「Used disallowed intents」或機器人會連線但不會對訊息做出反應）
- **Server Members Intent**（建議；某些成員/用戶查詢和伺服器中的允許清單匹配所必需）

您通常**不需要** **Presence Intent**。

### 3) 生成邀請 URL（OAuth2 URL Generator）

在您的應用程式中：**OAuth2** → **URL Generator**

**Scopes**

- ✅ `bot`
- ✅ `applications.commands`（native command 所必需）

**Bot Permissions**（最小基線）

- ✅ View Channels
- ✅ Send Messages
- ✅ Read Message History
- ✅ Embed Links
- ✅ Attach Files
- ✅ Add Reactions（可選但建議）
- ✅ Use External Emojis / Stickers（可選；僅當您想要時）

除非您在除錯且完全信任機器人，否則避免 **Administrator**。

複製生成的 URL，開啟它，選擇您的伺服器，並安裝機器人。

### 4) 取得 ID（guild/user/channel）

Discord 到處使用數字 ID；OpenClaw 設定首選 ID。

1. Discord（桌面/網頁）→ **使用者設定** → **進階** → 啟用 **開發者模式**
2. 右鍵點擊：
   - 伺服器名稱 → **複製伺服器 ID**（guild ID）
   - 頻道（例如 `#help`）→ **複製頻道 ID**
   - 您的用戶 → **複製用戶 ID**

### 5) 設定 OpenClaw

#### 令牌

透過環境變數設定機器人令牌（伺服器上建議）：

- `DISCORD_BOT_TOKEN=...`

或透過設定：

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

多帳戶支援：使用 `channels.discord.accounts` 設定每個帳戶的令牌和可選的 `name`。請參閱[`gateway/configuration`](/gateway/configuration#telegramaccounts--discordaccounts--slackaccounts--signalaccounts--imessageaccounts)了解共享模式。

#### 允許清單 + 頻道路由

範例「單一伺服器，只允許我，只允許 #help」：

```json5
{
  channels: {
    discord: {
      enabled: true,
      dm: { enabled: false },
      guilds: {
        YOUR_GUILD_ID: {
          users: ["YOUR_USER_ID"],
          requireMention: true,
          channels: {
            help: { allow: true, requireMention: true },
          },
        },
      },
      retry: {
        attempts: 3,
        minDelayMs: 500,
        maxDelayMs: 30000,
        jitter: 0.1,
      },
    },
  },
}
```

備註：

- `requireMention: true` 表示機器人只在被 mention 時回覆（建議用於共享頻道）。
- `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）也計為伺服器訊息的 mention。
- 多代理覆寫：在 `agents.list[].groupChat.mentionPatterns` 上設定每代理模式。
- 如果存在 `channels`，任何未列出的頻道預設被拒絕。
- 使用 `"*"` 頻道條目在所有頻道上套用預設；明確的頻道條目覆寫萬用字元。
- 討論串繼承父頻道設定（允許清單、`requireMention`、技能、提示等），除非您明確新增討論串頻道 ID。
- 機器人撰寫的訊息預設被忽略；設定 `channels.discord.allowBots=true` 以允許它們（自己的訊息仍被過濾）。
- 警告：如果您允許回覆其他機器人（`channels.discord.allowBots=true`），請使用 `requireMention`、`channels.discord.guilds.*.channels.<id>.users` 允許清單和/或在 `AGENTS.md` 和 `SOUL.md` 中設定清晰的護欄來防止機器人對機器人的回覆循環。

### 6) 驗證它是否運作

1. 啟動 gateway。
2. 在您的伺服器頻道中，發送：`@Krill hello`（或您的機器人名稱）。
3. 如果什麼都沒發生：請檢查下面的**疑難排解**。

### 疑難排解

- 首先：運行 `openclaw doctor` 和 `openclaw channels status --probe`（可操作的警告 + 快速審計）。
- **「Used disallowed intents」**：在開發者入口中啟用 **Message Content Intent**（可能還有 **Server Members Intent**），然後重啟 gateway。
- **機器人連線但從不在伺服器頻道回覆**：
  - 缺少 **Message Content Intent**，或
  - 機器人缺少頻道權限（View/Send/Read History），或
  - 您的設定需要 mention 但您沒有 mention 它，或
  - 您的伺服器/頻道允許清單拒絕了頻道/用戶。
- **`requireMention: false` 但仍然沒有回覆**：
- `channels.discord.groupPolicy` 預設為 **allowlist**；將其設為 `"open"` 或在 `channels.discord.guilds` 下新增伺服器條目（可選在 `channels.discord.guilds.<id>.channels` 下列出頻道以限制）。
  - 如果您只設定 `DISCORD_BOT_TOKEN` 且從未建立 `channels.discord` 區塊，運行時會將 `groupPolicy` 預設為 `open`。新增 `channels.discord.groupPolicy`、`channels.defaults.groupPolicy` 或伺服器/頻道允許清單以鎖定它。
  - `requireMention` 必須位於 `channels.discord.guilds`（或特定頻道）下。頂層的 `channels.discord.requireMention` 會被忽略。
- **權限審計**（`channels status --probe`）只檢查數字頻道 ID。如果您使用 slug/名稱作為 `channels.discord.guilds.*.channels` 鍵，審計無法驗證權限。
- **DM 不起作用**：`channels.discord.dm.enabled=false`、`channels.discord.dm.policy="disabled"` 或您尚未被批准（`channels.discord.dm.policy="pairing"`）。
- **Discord 中的執行批准**：Discord 支援在 DM 中進行**按鈕 UI** 執行批准（Allow once / Always allow / Deny）。`/approve <id> ...` 僅用於轉發批准，不會解決 Discord 的按鈕提示。如果您看到 `❌ Failed to submit approval: Error: unknown approval id` 或 UI 從不顯示，請檢查：
  - 您的設定中有 `channels.discord.execApprovals.enabled: true`。
  - 您的 Discord 用戶 ID 列在 `channels.discord.execApprovals.approvers` 中（UI 僅發送給批准者）。
  - 使用 DM 提示中的按鈕（**Allow once**、**Always allow**、**Deny**）。
  - 請參閱[執行批准](/tools/exec-approvals)和[斜線命令](/tools/slash-commands)了解更廣泛的批准和命令流程。

## 功能 & 限制

- DM 和伺服器文字頻道（討論串被視為獨立頻道；不支援語音）。
- 盡力發送輸入指示器；訊息分塊使用 `channels.discord.textChunkLimit`（預設 2000）並按行數分割高回覆（`channels.discord.maxLinesPerMessage`，預設 17）。
- 可選的換行分塊：設定 `channels.discord.chunkMode="newline"` 在長度分塊前在空白行（段落邊界）分割。
- 支援最大 `channels.discord.mediaMaxMb` 設定的檔案上傳（預設 8 MB）。
- 預設 mention 閘門的伺服器回覆以避免嘈雜的機器人。
- 當訊息參考另一條訊息時注入回覆上下文（引用內容 + ID）。
- Native 回覆串連預設**關閉**；使用 `channels.discord.replyToMode` 和回覆標籤啟用。

## 重試策略

外發 Discord API 呼叫在速率限制（429）時使用 Discord `retry_after`（如果可用）進行重試，並使用指數退避和抖動。透過 `channels.discord.retry` 設定。請參閱[重試策略](/concepts/retry)。

## 設定

```json5
{
  channels: {
    discord: {
      enabled: true,
      token: "abc.123",
      groupPolicy: "allowlist",
      guilds: {
        "*": {
          channels: {
            general: { allow: true },
          },
        },
      },
      mediaMaxMb: 8,
      actions: {
        reactions: true,
        stickers: true,
        emojiUploads: true,
        stickerUploads: true,
        polls: true,
        permissions: true,
        messages: true,
        threads: true,
        pins: true,
        search: true,
        memberInfo: true,
        roleInfo: true,
        roles: false,
        channelInfo: true,
        channels: true,
        voiceStatus: true,
        events: true,
        moderation: false,
      },
      replyToMode: "off",
      dm: {
        enabled: true,
        policy: "pairing", // pairing | allowlist | open | disabled
        allowFrom: ["123456789012345678", "steipete"],
        groupEnabled: false,
        groupChannels: ["openclaw-dm"],
      },
      guilds: {
        "*": { requireMention: true },
        "123456789012345678": {
          slug: "friends-of-openclaw",
          requireMention: false,
          reactionNotifications: "own",
          users: ["987654321098765432", "steipete"],
          channels: {
            general: { allow: true },
            help: {
              allow: true,
              requireMention: true,
              users: ["987654321098765432"],
              skills: ["search", "docs"],
              systemPrompt: "保持回答簡短。",
            },
          },
        },
      },
    },
  },
}
```

確認反應透過 `messages.ackReaction` + `messages.ackReactionScope` 全域控制。使用 `messages.removeAckAfterReply` 在機器人回覆後清除確認反應。

- `dm.enabled`：設為 `false` 以忽略所有 DM（預設 `true`）。
- `dm.policy`：DM 存取控制（建議 `pairing`）。`"open"` 需要 `dm.allowFrom=["*"]`。
- `dm.allowFrom`：DM 允許清單（用戶 ID 或名稱）。由 `dm.policy="allowlist"` 使用，也用於 `dm.policy="open"` 驗證。精靈接受用戶名並在機器人可以搜尋成員時將其解析為 ID。
- `dm.groupEnabled`：啟用群組 DM（預設 `false`）。
- `dm.groupChannels`：群組 DM 頻道 ID 或 slug 的可選允許清單。
- `groupPolicy`：控制伺服器頻道處理（`open|disabled|allowlist`）；`allowlist` 需要頻道允許清單。
- `guilds`：以伺服器 ID（首選）或 slug 為鍵的每伺服器規則。
- `guilds."*"`：當沒有明確條目時套用的預設每伺服器設定。
- `guilds.<id>.slug`：用於顯示名稱的可選友好 slug。
- `guilds.<id>.users`：可選的每伺服器用戶允許清單（ID 或名稱）。
- `guilds.<id>.tools`：可選的每伺服器工具策略覆寫（`allow`/`deny`/`alsoAllow`）用於當頻道覆寫缺失時。
- `guilds.<id>.toolsBySender`：可選的每發送者工具策略覆寫在伺服器層級（適用於當頻道覆寫缺失時；支援 `"*"` 萬用字元）。
- `guilds.<id>.channels.<channel>.allow`：當 `groupPolicy="allowlist"` 時允許/拒絕頻道。
- `guilds.<id>.channels.<channel>.requireMention`：頻道的 mention 閘門。
- `guilds.<id>.channels.<channel>.tools`：可選的每頻道工具策略覆寫（`allow`/`deny`/`alsoAllow`）。
- `guilds.<id>.channels.<channel>.toolsBySender`：可選的每發送者工具策略覆寫在頻道內（支援 `"*"` 萬用字元）。
- `guilds.<id>.channels.<channel>.users`：可選的每頻道用戶允許清單。
- `guilds.<id>.channels.<channel>.skills`：技能過濾器（省略 = 所有技能，空 = 無）。
- `guilds.<id>.channels.<channel>.systemPrompt`：頻道的額外系統提示（與頻道主題結合）。
- `guilds.<id>.channels.<channel>.enabled`：設為 `false` 以停用頻道。
- `guilds.<id>.channels`：頻道規則（鍵為頻道 slug 或 ID）。
- `guilds.<id>.requireMention`：每伺服器 mention 要求（可按頻道覆寫）。
- `guilds.<id>.reactionNotifications`：反應系統事件模式（`off`、`own`、`all`、`allowlist`）。
- `textChunkLimit`：外發文字分塊大小（字元）。預設：2000。
- `chunkMode`：`length`（預設）僅在超過 `textChunkLimit` 時分割；`newline` 在長度分塊前在空白行（段落邊界）分割。
- `maxLinesPerMessage`：每條訊息的軟最大行數。預設：17。
- `mediaMaxMb`：限制儲存到磁碟的入站媒體。
- `historyLimit`：回覆 mention 時包含作為上下文的最近伺服器訊息數量（預設 20；回退到 `messages.groupChat.historyLimit`；`0` 停用）。
- `dmHistoryLimit`：用戶輪次中的 DM 歷史限制。每用戶覆寫：`dms["<user_id>"].historyLimit`。
- `retry`：外發 Discord API 呼叫的重試策略（attempts、minDelayMs、maxDelayMs、jitter）。
- `pluralkit`：解析 PluralKit 代理訊息，使系統成員顯示為不同的發送者。
- `actions`：每動作工具閘門；省略以允許全部（設為 `false` 以停用）。
  - `reactions`（涵蓋 react + read reactions）
  - `stickers`、`emojiUploads`、`stickerUploads`、`polls`、`permissions`、`messages`、`threads`、`pins`、`search`
  - `memberInfo`、`roleInfo`、`channelInfo`、`voiceStatus`、`events`
  - `channels`（建立/編輯/刪除頻道 + 分類 + 權限）
  - `roles`（角色新增/移除，預設 `false`）
  - `moderation`（逾時/踢出/禁止，預設 `false`）
- `execApprovals`：Discord 唯一執行批准 DM（按鈕 UI）。支援 `enabled`、`approvers`、`agentFilter`、`sessionFilter`。

反應通知使用 `guilds.<id>.reactionNotifications`：

- `off`：無反應事件。
- `own`：機器人自己訊息上的反應（預設）。
- `all`：所有訊息上的所有反應。
- `allowlist`：來自 `guilds.<id>.users` 的反應在所有訊息上（空列表停用）。

### PluralKit（PK）支援

啟用 PK 查詢，使代理訊息解析到基礎系統 + 成員。
啟用後，OpenClaw 使用成員身份進行允許清單並將發送者標記為 `Member (PK:System)` 以避免意外 Discord ping。

```json5
{
  channels: {
    discord: {
      pluralkit: {
        enabled: true,
        token: "pk_live_...", // 可選；私人系統所需
      },
    },
  },
}
```

允許清單備註（啟用 PK）：

- 在 `dm.allowFrom`、`guilds.<id>.users` 或每頻道 `users` 中使用 `pk:<memberId>`。
- 成員顯示名稱也按名稱/slug 匹配。
- 查詢使用**原始** Discord 訊息 ID（預代理訊息），所以 PK API 僅在其 30 分鐘視窗內解析它。
- 如果 PK 查詢失敗（例如，沒有令牌的私人系統），代理訊息被視為機器人訊息並被丟棄，除非 `channels.discord.allowBots=true`。

### 工具動作預設

| 動作群組   | 預設  | 備註                              |
| ---------- | ----- | --------------------------------- |
| reactions  | 啟用  | React + list reactions + emojiList |
| stickers   | 啟用  | 發送貼圖                        |
| emojiUploads   | 啟用  | 上傳表情符號                      |
| stickerUploads | 啟用  | 上傳貼圖                    |
| polls      | 啟用  | 建立民調                       |
| permissions    | 啟用  | 頻道權限快照        |
| messages   | 啟用  | 讀取/發送/編輯/刪除              |
| threads    | 啟用  | 建立/列出/回覆                  |
| pins       | 啟用  | 釘選/取消釘選/列出                    |
| search     | 啟用  | 訊息搜尋（預覽功能）   |
| memberInfo | 啟用  | 成員資訊                        |
| roleInfo   | 啟用  | 角色列表                         |
| channelInfo    | 啟用  | 頻道資訊 + 列表                |
| channels   | 啟用  | 頻道/分類管理        |
| voiceStatus    | 啟用  | 語音狀態查詢                 |
| events     | 啟用  | 列出/建立排定事件       |
| roles      | 停用 | 角色新增/移除                    |
| moderation | 停用 | 逾時/踢出/禁止                  |

- `replyToMode`：`off`（預設）、`first` 或 `all`。僅在模型包含回覆標籤時套用。

## 回覆標籤

要請求串連回覆，模型可以在其輸出中包含一個標籤：

- `[[reply_to_current]]` — 回覆觸發的 Discord 訊息。
- `[[reply_to:<id>]]` — 回覆上下文/歷史中的特定訊息 ID。
  當前訊息 ID 附加到提示中作為 `[message_id: …]`；歷史條目已包含 ID。

行為由 `channels.discord.replyToMode` 控制：

- `off`：忽略標籤。
- `first`：只有第一個外發塊/附件是回覆。
- `all`：每個外發塊/附件都是回覆。

允許清單匹配備註：

- `allowFrom`/`users`/`groupChannels` 接受 ID、名稱、標籤或 mention 如 `<@id>`。
- 支援前綴如 `discord:`/`user:`（用戶）和 `channel:`（群組 DM）。
- 使用 `*` 允許任何發送者/頻道。
- 當 `guilds.<id>.channels` 存在時，未列出的頻道預設被拒絕。
- 當 `guilds.<id>.channels` 省略時，允許清單伺服器中的所有頻道都被允許。
- 要允許**沒有頻道**，設定 `channels.discord.groupPolicy: "disabled"`（或保持空允許清單）。
- 設定精靈接受 `Guild/Channel` 名稱（公開 + 私人）並在可能時將其解析為 ID。
- 在啟動時，OpenClaw 解析允許清單中的頻道/用戶名稱為 ID（當機器人可以搜尋成員時）並記錄映射；未解析的條目保持原樣。

Native command 備註：

- 註冊的命令鏡像 OpenClaw 的聊天命令。
- Native command 遵守與 DM/伺服器訊息相同的允許清單（`channels.discord.dm.allowFrom`、`channels.discord.guilds`、每頻道規則）。
- 斜線命令可能在 Discord UI 中對不在允許清單中的用戶可見；OpenClaw 在執行時強制執行允許清單並回覆「not authorized」。

## 工具動作

代理可以使用以下動作呼叫 `discord`：

- `react` / `reactions`（新增或列出反應）
- `sticker`、`poll`、`permissions`
- `readMessages`、`sendMessage`、`editMessage`、`deleteMessage`
- 讀取/搜尋/釘選工具負載包含正規化的 `timestampMs`（UTC 紀元毫秒）和 `timestampUtc` 以及原始 Discord `timestamp`。
- `threadCreate`、`threadList`、`threadReply`
- `pinMessage`、`unpinMessage`、`listPins`
- `searchMessages`、`memberInfo`、`roleInfo`、`roleAdd`、`roleRemove`、`emojiList`
- `channelInfo`、`channelList`、`voiceStatus`、`eventList`、`eventCreate`
- `timeout`、`kick`、`ban`

Discord 訊息 ID 在注入的上下文中公開（`[discord message id: …]` 和歷史行），以便代理可以針對它們。
表情符號可以是 unicode（例如 `✅`）或自訂表情符號語法如 `<:party_blob:1234567890>`。

## 安全 & 運營

- 將機器人令牌視為密碼；在受監督的主機上首選 `DISCORD_BOT_TOKEN` 環境變數或鎖定設定檔權限。
- 只授予機器人它需要的權限（通常是讀取/發送訊息）。
- 如果機器人卡住或受到速率限制，在確認沒有其他程序擁有 Discord 會話後重啟 gateway（`openclaw gateway --force`）。
