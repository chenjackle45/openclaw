---
summary: "Telegram Bot 支援狀態、功能說明與設定方式"
read_when:
  - 處理 Telegram 功能或 webhook
title: "Telegram"
---

# Telegram (Bot API)

狀態：已可正式用於 Bot 私訊與群組（透過 grammY）。預設模式為長輪詢；Webhook 模式為選填。

<CardGroup cols={3}>
  <Card title="配對" icon="link" href="/zh-Hant/channels/pairing">
    Telegram 的預設私訊政策為配對模式。
  </Card>
  <Card title="頻道疑難排解" icon="wrench" href="/zh-Hant/channels/troubleshooting">
    跨頻道診斷與修復流程。
  </Card>
  <Card title="Gateway 設定" icon="settings" href="/zh-Hant/gateway/configuration">
    完整頻道設定模式與範例。
  </Card>
</CardGroup>

## 快速設定

<Steps>
  <Step title="在 BotFather 中建立 Bot Token">
    開啟 Telegram，與 **@BotFather** 對話（確認帳號名稱完全正確為 `@BotFather`）。

    執行 `/newbot`，依照提示操作，並儲存 Token。

  </Step>

  <Step title="設定 Token 與私訊政策">

```json5
{
  channels: {
    telegram: {
      enabled: true,
      botToken: "123:abc",
      dmPolicy: "pairing",
      groups: { "*": { requireMention: true } },
    },
  },
}
```

    環境變數備援：`TELEGRAM_BOT_TOKEN=...`（僅限預設帳號）。
    Telegram **不**使用 `openclaw channels login telegram`；請在設定/環境變數中設定 Token，然後啟動 Gateway。

  </Step>

  <Step title="啟動 Gateway 並核准第一次私訊">

```bash
openclaw gateway
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

    配對碼在 1 小時後過期。

  </Step>

  <Step title="將 Bot 加入群組">
    將 Bot 加入你的群組，然後設定 `channels.telegram.groups` 和 `groupPolicy` 以符合你的存取模型。
  </Step>
</Steps>

<Note>
Token 解析順序具備帳號感知能力。實際上，設定值優先於環境變數備援，且 `TELEGRAM_BOT_TOKEN` 僅適用於預設帳號。
</Note>

## Telegram 端設定

<AccordionGroup>
  <Accordion title="隱私模式與群組可見性">
    Telegram Bot 預設啟用**隱私模式**，限制了能接收的群組訊息範圍。

    若 Bot 必須看到所有群組訊息，可以：

    - 透過 `/setprivacy` 停用隱私模式，或
    - 將 Bot 設為群組管理員。

    切換隱私模式後，請在每個群組中移除並重新加入 Bot，讓 Telegram 套用變更。

  </Accordion>

  <Accordion title="群組權限">
    管理員狀態在 Telegram 群組設定中控制。

    管理員 Bot 可接收所有群組訊息，適合需要持續在線的群組行為。

  </Accordion>

  <Accordion title="BotFather 實用切換">

    - `/setjoingroups` 允許/禁止加入群組
    - `/setprivacy` 控制群組可見性行為

  </Accordion>
</AccordionGroup>

## 存取控制與啟動

<Tabs>
  <Tab title="私訊政策">
    `channels.telegram.dmPolicy` 控制直接訊息存取：

    - `pairing`（預設）
    - `allowlist`（需要 `allowFrom` 中至少有一個發送者 ID）
    - `open`（需要 `allowFrom` 包含 `"*"`）
    - `disabled`

    `channels.telegram.allowFrom` 接受數字 Telegram 用戶 ID。接受 `telegram:` / `tg:` 前綴並進行正規化。
    `dmPolicy: "allowlist"` 搭配空的 `allowFrom` 會封鎖所有私訊，設定驗證會拒絕此組合。
    引導精靈接受 `@username` 輸入並解析為數字 ID。
    若升級後你的設定中包含 `@username` 白名單項目，請執行 `openclaw doctor --fix` 解析（盡力而為；需要 Telegram Bot Token）。
    若你之前依賴配對儲存白名單檔案，`openclaw doctor --fix` 可以在白名單流程中（例如 `dmPolicy: "allowlist"` 尚無明確 ID 時）將項目恢復至 `channels.telegram.allowFrom`。

    對於單一擁有者 Bot，建議使用 `dmPolicy: "allowlist"` 搭配明確的數字 `allowFrom` ID，讓存取政策在設定中持久存在（而非依賴過去的配對核准）。

    ### 尋找你的 Telegram 用戶 ID

    較安全的方式（不需要第三方 Bot）：

    1. 私訊你的 Bot。
    2. 執行 `openclaw logs --follow`。
    3. 讀取 `from.id`。

    官方 Bot API 方式：

```bash
curl "https://api.telegram.org/bot<bot_token>/getUpdates"
```

    第三方方式（隱私較低）：`@userinfobot` 或 `@getidsbot`。

  </Tab>

  <Tab title="群組政策與白名單">
    兩個控制項共同作用：

    1. **允許哪些群組**（`channels.telegram.groups`）
       - 未設定 `groups`：
         - 搭配 `groupPolicy: "open"`：任何群組都可通過群組 ID 檢查
         - 搭配 `groupPolicy: "allowlist"`（預設）：群組被封鎖，直到你新增 `groups` 項目（或 `"*"`）
       - 設定了 `groups`：作為白名單（明確 ID 或 `"*"`）

    2. **群組中允許哪些發送者**（`channels.telegram.groupPolicy`）
       - `open`
       - `allowlist`（預設）
       - `disabled`

    `groupAllowFrom` 用於群組發送者篩選。未設定時，Telegram 備援使用 `allowFrom`。
    `groupAllowFrom` 項目應為數字 Telegram 用戶 ID（`telegram:` / `tg:` 前綴會被正規化）。
    不要將 Telegram 群組或超級群組聊天 ID 放在 `groupAllowFrom` 中。負數聊天 ID 應放在 `channels.telegram.groups` 下。
    非數字項目在發送者授權時會被忽略。
    安全邊界（`2026.2.25+`）：群組發送者授權**不繼承**私訊配對儲存核准。
    配對僅限私訊。群組請設定 `groupAllowFrom` 或每群組/每話題的 `allowFrom`。
    執行時注意：若 `channels.telegram` 完全缺失，除非明確設定 `channels.defaults.groupPolicy`，否則執行時預設為失敗關閉 `groupPolicy="allowlist"`。

    範例：允許特定群組的任何成員：

```json5
{
  channels: {
    telegram: {
      groups: {
        "-1001234567890": {
          groupPolicy: "open",
          requireMention: false,
        },
      },
    },
  },
}
```

    範例：僅允許特定群組中的特定用戶：

```json5
{
  channels: {
    telegram: {
      groups: {
        "-1001234567890": {
          requireMention: true,
          allowFrom: ["8734062810", "745123456"],
        },
      },
    },
  },
}
```

    <Warning>
      常見錯誤：`groupAllowFrom` 不是 Telegram 群組白名單。

      - 像 `-1001234567890` 這樣的負數 Telegram 群組或超級群組聊天 ID 應放在 `channels.telegram.groups` 下。
      - 像 `8734062810` 這樣的 Telegram 用戶 ID 應放在 `groupAllowFrom` 下，用於限制已允許群組中哪些人可以觸發 Bot。
      - 只有在希望已允許群組的任何成員都能與 Bot 對話時，才使用 `groupAllowFrom: ["*"]`。
    </Warning>

  </Tab>

  <Tab title="Mention 行為">
    群組回覆預設需要 mention 才能觸發。

    Mention 來源：

    - 原生 `@botusername` mention，或
    - mention 模式：
      - `agents.list[].groupChat.mentionPatterns`
      - `messages.groupChat.mentionPatterns`

    工作階段層級的指令切換：

    - `/activation always`
    - `/activation mention`

    這些只更新工作階段狀態。持久設定請使用設定檔。

    持久設定範例：

```json5
{
  channels: {
    telegram: {
      groups: {
        "*": { requireMention: false },
      },
    },
  },
}
```

    取得群組聊天 ID：

    - 將群組訊息轉寄給 `@userinfobot` / `@getidsbot`
    - 或從 `openclaw logs --follow` 讀取 `chat.id`
    - 或查看 Bot API `getUpdates`

  </Tab>
</Tabs>

## 執行時行為

- Telegram 由 Gateway 程序管理。
- 路由是確定性的：Telegram 收入訊息回覆至 Telegram（模型不選擇頻道）。
- 收入訊息正規化為共享頻道信封，包含回覆中繼資料和媒體佔位符。
- 群組工作階段以群組 ID 隔離。論壇話題附加 `:topic:<threadId>` 以保持話題隔離。
- 私訊可帶有 `message_thread_id`；OpenClaw 以具討論串感知的工作階段金鑰路由，並保留討論串 ID 用於回覆。
- 長輪詢使用 grammY runner，按聊天/討論串排序。整體 runner sink 並行量使用 `agents.defaults.maxConcurrent`。
- Telegram Bot API 不支援已讀回條（`sendReadReceipts` 不適用）。

## 功能參考

<AccordionGroup>
  <Accordion title="即時串流預覽（訊息編輯）">
    OpenClaw 可以即時串流部分回覆：

    - 直接聊天：預覽訊息 + `editMessageText`
    - 群組/話題：預覽訊息 + `editMessageText`

    需求：

    - `channels.telegram.streaming` 為 `off | partial | block | progress`（預設：`partial`）
    - `progress` 在 Telegram 上映射為 `partial`（跨頻道命名相容）
    - 舊版 `channels.telegram.streamMode` 和布林 `streaming` 值會自動映射

    對於純文字回覆：

    - 私訊：OpenClaw 保留相同的預覽訊息，並就地執行最終編輯（不傳送第二則訊息）
    - 群組/話題：OpenClaw 保留相同的預覽訊息，並就地執行最終編輯（不傳送第二則訊息）

    對於複雜回覆（例如媒體載荷），OpenClaw 退回至一般最終傳送，然後清除預覽訊息。

    預覽串流與區塊串流是分開的。當 Telegram 明確啟用區塊串流時，OpenClaw 跳過預覽串流以避免雙重串流。

    若原生草稿傳輸不可用/被拒絕，OpenClaw 自動退回至 `sendMessage` + `editMessageText`。

    Telegram 限定的推理串流：

    - `/reasoning stream` 在產生過程中將推理傳送至即時預覽
    - 最終答案不含推理文字傳送

  </Accordion>

  <Accordion title="格式化與 HTML 備援">
    輸出文字使用 Telegram `parse_mode: "HTML"`。

    - 類 Markdown 文字渲染為 Telegram 安全的 HTML。
    - 原始模型 HTML 會被跳脫以減少 Telegram 解析失敗。
    - 若 Telegram 拒絕已解析的 HTML，OpenClaw 退回至純文字重試。

    連結預覽預設啟用，可透過 `channels.telegram.linkPreview: false` 停用。

  </Accordion>

  <Accordion title="原生指令與自訂指令">
    Telegram 指令選單在啟動時透過 `setMyCommands` 進行註冊。

    原生指令預設：

    - `commands.native: "auto"` 對 Telegram 啟用原生指令

    新增自訂指令選單項目：

```json5
{
  channels: {
    telegram: {
      customCommands: [
        { command: "backup", description: "Git backup" },
        { command: "generate", description: "Create an image" },
      ],
    },
  },
}
```

    規則：

    - 名稱會被正規化（去掉開頭的 `/`，轉小寫）
    - 有效模式：`a-z`、`0-9`、`_`，長度 `1..32`
    - 自訂指令無法覆寫原生指令
    - 衝突/重複項目會被跳過並記錄

    注意：

    - 自訂指令僅為選單項目；它們不會自動實作行為
    - 插件/技能指令即使未顯示在 Telegram 選單中，輸入仍可運作

    若停用原生指令，內建指令會被移除。若已設定，自訂/插件指令仍可能註冊。

    常見設定失敗：

    - `setMyCommands failed` 加上 `BOT_COMMANDS_TOO_MUCH`：削減後 Telegram 選單仍溢出；請減少插件/技能/自訂指令，或停用 `channels.telegram.commands.native`。
    - `setMyCommands failed` 加上網路/fetch 錯誤：通常表示對 `api.telegram.org` 的輸出 DNS/HTTPS 被封鎖。

    ### 裝置配對指令（`device-pair` 插件）

    安裝 `device-pair` 插件後：

    1. `/pair` 產生設定碼
    2. 將碼貼入 iOS 應用程式
    3. `/pair approve` 核准最新的等待請求

    更多詳情：[配對](/zh-Hant/channels/pairing#pair-via-telegram-recommended-for-ios)。

  </Accordion>

  <Accordion title="內聯按鈕">
    設定內聯鍵盤範圍：

```json5
{
  channels: {
    telegram: {
      capabilities: {
        inlineButtons: "allowlist",
      },
    },
  },
}
```

    每帳號覆寫：

```json5
{
  channels: {
    telegram: {
      accounts: {
        main: {
          capabilities: {
            inlineButtons: "allowlist",
          },
        },
      },
    },
  },
}
```

    範圍：

    - `off`
    - `dm`
    - `group`
    - `all`
    - `allowlist`（預設）

    舊版 `capabilities: ["inlineButtons"]` 映射至 `inlineButtons: "all"`。

    訊息操作範例：

```json5
{
  action: "send",
  channel: "telegram",
  to: "123456789",
  message: "Choose an option:",
  buttons: [
    [
      { text: "Yes", callback_data: "yes" },
      { text: "No", callback_data: "no" },
    ],
    [{ text: "Cancel", callback_data: "cancel" }],
  ],
}
```

    按鈕點擊以文字形式傳遞給 Agent：
    `callback_data: <value>`

  </Accordion>

  <Accordion title="Agent 與自動化的 Telegram 訊息操作">
    Telegram 工具操作包括：

    - `sendMessage`（`to`、`content`，選填 `mediaUrl`、`replyToMessageId`、`messageThreadId`）
    - `react`（`chatId`、`messageId`、`emoji`）
    - `deleteMessage`（`chatId`、`messageId`）
    - `editMessage`（`chatId`、`messageId`、`content`）
    - `createForumTopic`（`chatId`、`name`，選填 `iconColor`、`iconCustomEmojiId`）

    頻道訊息操作提供語意別名（`send`、`react`、`delete`、`edit`、`sticker`、`sticker-search`、`topic-create`）。

    閘門控制：

    - `channels.telegram.actions.sendMessage`
    - `channels.telegram.actions.deleteMessage`
    - `channels.telegram.actions.reactions`
    - `channels.telegram.actions.sticker`（預設：停用）

    注意：`edit` 和 `topic-create` 目前預設啟用，沒有獨立的 `channels.telegram.actions.*` 切換開關。
    執行時傳送使用當前設定/密鑰快照（啟動/重載），因此操作路徑不會每次傳送都重新解析 SecretRef。

    反應移除語意：[/tools/reactions](/zh-Hant/tools/reactions)

  </Accordion>

  <Accordion title="回覆串標籤">
    Telegram 支援生成輸出中的明確回覆串標籤：

    - `[[reply_to_current]]` 回覆觸發訊息
    - `[[reply_to:<id>]]` 回覆特定 Telegram 訊息 ID

    `channels.telegram.replyToMode` 控制處理方式：

    - `off`（預設）
    - `first`
    - `all`

    注意：`off` 停用隱式回覆串。明確的 `[[reply_to_*]]` 標籤仍然有效。

  </Accordion>

  <Accordion title="論壇話題與討論串行為">
    論壇超級群組：

    - 話題工作階段金鑰附加 `:topic:<threadId>`
    - 回覆和輸入針對話題討論串
    - 話題設定路徑：
      `channels.telegram.groups.<chatId>.topics.<threadId>`

    一般話題（`threadId=1`）特殊處理：

    - 訊息傳送省略 `message_thread_id`（Telegram 拒絕 `sendMessage(...thread_id=1)`）
    - 輸入操作仍包含 `message_thread_id`

    話題繼承：話題項目繼承群組設定，除非有覆寫（`requireMention`、`allowFrom`、`skills`、`systemPrompt`、`enabled`、`groupPolicy`）。
    `agentId` 僅限話題，不繼承群組預設值。

    **每話題 Agent 路由**：每個話題可透過在話題設定中設定 `agentId` 路由至不同的 Agent。這讓每個話題擁有自己獨立的工作區、記憶和工作階段。範例：

    ```json5
    {
      channels: {
        telegram: {
          groups: {
            "-1001234567890": {
              topics: {
                "1": { agentId: "main" },      // 一般話題 → main agent
                "3": { agentId: "zu" },        // 開發話題 → zu agent
                "5": { agentId: "coder" }      // 程式碼審查 → coder agent
              }
            }
          }
        }
      }
    }
    ```

    每個話題擁有自己的工作階段金鑰：`agent:zu:telegram:group:-1001234567890:topic:3`

    **持久性 ACP 話題綁定**：論壇話題可透過頂層類型化 ACP binding 固定 ACP 工作階段：

    - `bindings[]` 包含 `type: "acp"` 且 `match.channel: "telegram"`

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
            channel: "telegram",
            accountId: "default",
            peer: { kind: "group", id: "-1001234567890:topic:42" },
          },
        },
      ],
      channels: {
        telegram: {
          groups: {
            "-1001234567890": {
              topics: {
                "42": {
                  requireMention: false,
                },
              },
            },
          },
        },
      },
    }
    ```

    目前範圍限於群組和超級群組中的論壇話題。

    **從聊天發起討論串綁定 ACP**：

    - `/acp spawn <agent> --thread here|auto` 可將當前 Telegram 話題綁定至新的 ACP 工作階段。
    - 後續話題訊息直接路由至已綁定的 ACP 工作階段（不需要 `/acp steer`）。
    - 成功綁定後，OpenClaw 在話題中釘選確認訊息。
    - 需要 `channels.telegram.threadBindings.spawnAcpSessions=true`。

    模板情境包含：

    - `MessageThreadId`
    - `IsForum`

    私訊討論串行為：

    - 帶有 `message_thread_id` 的私訊保持私訊路由，但使用具討論串感知的工作階段金鑰/回覆目標。

  </Accordion>

  <Accordion title="音訊、影片與貼圖">
    ### 音訊訊息

    Telegram 區分語音備忘錄和音訊檔案。

    - 預設：音訊檔案行為
    - 在 Agent 回覆中加上 `[[audio_as_voice]]` 標籤可強制以語音備忘錄形式傳送

    訊息操作範例：

```json5
{
  action: "send",
  channel: "telegram",
  to: "123456789",
  media: "https://example.com/voice.ogg",
  asVoice: true,
}
```

    ### 影片訊息

    Telegram 區分影片檔案和影片備忘錄。

    訊息操作範例：

```json5
{
  action: "send",
  channel: "telegram",
  to: "123456789",
  media: "https://example.com/video.mp4",
  asVideoNote: true,
}
```

    影片備忘錄不支援說明文字；提供的訊息文字會另外傳送。

    ### 貼圖

    收入貼圖處理：

    - 靜態 WEBP：下載並處理（佔位符 `<media:sticker>`）
    - 動態 TGS：跳過
    - 影片 WEBM：跳過

    貼圖情境欄位：

    - `Sticker.emoji`
    - `Sticker.setName`
    - `Sticker.fileId`
    - `Sticker.fileUniqueId`
    - `Sticker.cachedDescription`

    貼圖快取檔案：

    - `~/.openclaw/telegram/sticker-cache.json`

    貼圖會描述一次（盡可能），並快取以減少重複的視覺呼叫。

    啟用貼圖操作：

```json5
{
  channels: {
    telegram: {
      actions: {
        sticker: true,
      },
    },
  },
}
```

    傳送貼圖操作：

```json5
{
  action: "sticker",
  channel: "telegram",
  to: "123456789",
  fileId: "CAACAgIAAxkBAAI...",
}
```

    搜尋快取貼圖：

```json5
{
  action: "sticker-search",
  channel: "telegram",
  query: "cat waving",
  limit: 5,
}
```

  </Accordion>

  <Accordion title="反應通知">
    Telegram 反應以 `message_reaction` 更新形式到達（與訊息載荷分開）。

    啟用後，OpenClaw 會排入以下系統事件：

    - `Telegram reaction added: 👍 by Alice (@alice) on msg 42`

    設定：

    - `channels.telegram.reactionNotifications`：`off | own | all`（預設：`own`）
    - `channels.telegram.reactionLevel`：`off | ack | minimal | extensive`（預設：`minimal`）

    注意：

    - `own` 表示用戶對 Bot 發送訊息的反應（透過已傳送訊息快取盡力而為）。
    - 反應事件仍遵循 Telegram 存取控制（`dmPolicy`、`allowFrom`、`groupPolicy`、`groupAllowFrom`）；未授權的發送者會被丟棄。
    - Telegram 在反應更新中不提供討論串 ID。
      - 非論壇群組路由至群組聊天工作階段
      - 論壇群組路由至群組一般話題工作階段（`:topic:1`），而非確切的原始話題

    輪詢/webhook 的 `allowed_updates` 自動包含 `message_reaction`。

  </Accordion>

  <Accordion title="確認反應">
    `ackReaction` 在 OpenClaw 處理收入訊息時傳送確認 emoji。

    解析順序：

    - `channels.telegram.accounts.<accountId>.ackReaction`
    - `channels.telegram.ackReaction`
    - `messages.ackReaction`
    - Agent 身份 emoji 備援（`agents.list[].identity.emoji`，否則使用 "👀"）

    注意：

    - Telegram 使用 unicode emoji（例如 "👀"）。
    - 使用 `""` 停用特定頻道或帳號的反應。

  </Accordion>

  <Accordion title="來自 Telegram 事件和指令的設定寫入">
    頻道設定寫入預設啟用（`configWrites !== false`）。

    Telegram 觸發的寫入包括：

    - 群組遷移事件（`migrate_to_chat_id`）以更新 `channels.telegram.groups`
    - `/config set` 和 `/config unset`（需要指令啟用）

    停用：

```json5
{
  channels: {
    telegram: {
      configWrites: false,
    },
  },
}
```

  </Accordion>

  <Accordion title="長輪詢與 Webhook">
    預設：長輪詢。

    Webhook 模式：

    - 設定 `channels.telegram.webhookUrl`
    - 設定 `channels.telegram.webhookSecret`（設定 Webhook URL 時必要）
    - 選填 `channels.telegram.webhookPath`（預設 `/telegram-webhook`）
    - 選填 `channels.telegram.webhookHost`（預設 `127.0.0.1`）
    - 選填 `channels.telegram.webhookPort`（預設 `8787`）

    Webhook 模式的預設本地監聽器綁定至 `127.0.0.1:8787`。

    若你的公開端點不同，請在前方放置反向 Proxy，並將 `webhookUrl` 指向公開 URL。
    當你明確需要外部存取時，設定 `webhookHost`（例如 `0.0.0.0`）。

  </Accordion>

  <Accordion title="限制、重試與 CLI 目標">
    - `channels.telegram.textChunkLimit` 預設為 4000。
    - `channels.telegram.chunkMode="newline"` 在長度分割前優先以空行（段落邊界）分割。
    - `channels.telegram.mediaMaxMb`（預設 100）限制收入和輸出 Telegram 媒體大小。
    - `channels.telegram.timeoutSeconds` 覆寫 Telegram API 客戶端超時（未設定時使用 grammY 預設值）。
    - 群組情境記錄使用 `channels.telegram.historyLimit` 或 `messages.groupChat.historyLimit`（預設 50）；`0` 停用。
    - 私訊記錄控制：
      - `channels.telegram.dmHistoryLimit`
      - `channels.telegram.dms["<user_id>"].historyLimit`
    - `channels.telegram.retry` 設定適用於 Telegram 傳送輔助函式（CLI/工具/操作）對可恢復輸出 API 錯誤的重試。

    CLI 傳送目標可以是數字聊天 ID 或用戶名稱：

```bash
openclaw message send --channel telegram --target 123456789 --message "hi"
openclaw message send --channel telegram --target @name --message "hi"
```

    Telegram 投票使用 `openclaw message poll`，並支援論壇話題：

```bash
openclaw message poll --channel telegram --target 123456789 \
  --poll-question "Ship it?" --poll-option "Yes" --poll-option "No"
openclaw message poll --channel telegram --target -1001234567890:topic:42 \
  --poll-question "Pick a time" --poll-option "10am" --poll-option "2pm" \
  --poll-duration-seconds 300 --poll-public
```

    Telegram 限定的投票旗標：

    - `--poll-duration-seconds`（5-600）
    - `--poll-anonymous`
    - `--poll-public`
    - `--thread-id` 用於論壇話題（或使用 `:topic:` 目標）

    操作閘門：

    - `channels.telegram.actions.sendMessage=false` 停用輸出 Telegram 訊息，包括投票
    - `channels.telegram.actions.poll=false` 停用 Telegram 投票建立，同時保留一般傳送啟用

  </Accordion>

  <Accordion title="Telegram 中的執行核准">
    Telegram 支援在核准者私訊中執行核准，也可選擇性地在原始聊天或話題中張貼核准提示。

    設定路徑：

    - `channels.telegram.execApprovals.enabled`
    - `channels.telegram.execApprovals.approvers`
    - `channels.telegram.execApprovals.target`（`dm` | `channel` | `both`，預設：`dm`）
    - `agentFilter`、`sessionFilter`

    核准者必須是數字 Telegram 用戶 ID。當 `enabled` 為 false 或 `approvers` 為空時，Telegram 不作為執行核准客戶端。核准請求會備援至其他已設定的核准路由或執行核准備援政策。

    傳送規則：

    - `target: "dm"` 僅將核准提示傳送至已設定的核准者私訊
    - `target: "channel"` 將提示傳回原始 Telegram 聊天/話題
    - `target: "both"` 傳送至核准者私訊和原始聊天/話題

    只有已設定的核准者可以核准或拒絕。非核准者無法使用 `/approve`，也無法使用 Telegram 核准按鈕。

    頻道傳送會在聊天中顯示指令文字，因此請只在受信任的群組/話題啟用 `channel` 或 `both`。提示出現在論壇話題時，OpenClaw 會為核准提示和核准後的後續追蹤保留話題。

    內聯核准按鈕也依賴 `channels.telegram.capabilities.inlineButtons` 允許目標介面（`dm`、`group` 或 `all`）。

    相關文件：[執行核准](/zh-Hant/tools/exec-approvals)

  </Accordion>
</AccordionGroup>

## 疑難排解

<AccordionGroup>
  <Accordion title="Bot 沒有回應非 mention 的群組訊息">

    - 若 `requireMention=false`，Telegram 隱私模式必須允許完整可見性。
      - BotFather：`/setprivacy` -> Disable
      - 然後從群組中移除並重新加入 Bot
    - 當設定期望未 mention 的群組訊息時，`openclaw channels status` 會發出警告。
    - `openclaw channels status --probe` 可以檢查明確的數字群組 ID；萬用字元 `"*"` 無法進行成員探測。
    - 快速工作階段測試：`/activation always`。

  </Accordion>

  <Accordion title="Bot 完全看不到群組訊息">

    - 當 `channels.telegram.groups` 存在時，群組必須被列出（或包含 `"*"`）
    - 確認 Bot 是群組成員
    - 檢視日誌：`openclaw logs --follow` 查看略過原因

  </Accordion>

  <Accordion title="指令部分有效或完全無效">

    - 授權你的發送者身份（配對和/或數字 `allowFrom`）
    - 即使群組政策為 `open`，指令授權仍然適用
    - `setMyCommands failed` 加上 `BOT_COMMANDS_TOO_MUCH`：原生選單項目太多；減少插件/技能/自訂指令，或停用原生選單
    - `setMyCommands failed` 加上網路/fetch 錯誤：通常表示對 `api.telegram.org` 的 DNS/HTTPS 可達性問題

  </Accordion>

  <Accordion title="輪詢或網路不穩定">

    - Node 22+ 加上自訂 fetch/proxy 如果 AbortSignal 類型不匹配，可能觸發立即中止行為。
    - 某些主機將 `api.telegram.org` 優先解析為 IPv6；損壞的 IPv6 出口可能導致間歇性 Telegram API 失敗。
    - 若日誌包含 `TypeError: fetch failed` 或 `Network request for 'getUpdates' failed!`，OpenClaw 現在會將這些作為可恢復的網路錯誤重試。
    - 在直接出口/TLS 不穩定的 VPS 主機上，透過 `channels.telegram.proxy` 路由 Telegram API 呼叫：

```yaml
channels:
  telegram:
    proxy: socks5://<user>:<password>@proxy-host:1080
```

    - Node 22+ 預設 `autoSelectFamily=true`（WSL2 除外）和 `dnsResultOrder=ipv4first`。
    - 若你的主機是 WSL2 或明確使用純 IPv4 效果更好，強制 IP 系列選擇：

```yaml
channels:
  telegram:
    network:
      autoSelectFamily: false
```

    - 環境覆寫（臨時）：
      - `OPENCLAW_TELEGRAM_DISABLE_AUTO_SELECT_FAMILY=1`
      - `OPENCLAW_TELEGRAM_ENABLE_AUTO_SELECT_FAMILY=1`
      - `OPENCLAW_TELEGRAM_DNS_RESULT_ORDER=ipv4first`
    - 驗證 DNS 答案：

```bash
dig +short api.telegram.org A
dig +short api.telegram.org AAAA
```

  </Accordion>
</AccordionGroup>

更多協助：[頻道疑難排解](/zh-Hant/channels/troubleshooting)。

## Telegram 設定參考指引

主要參考：

- `channels.telegram.enabled`：啟用/停用頻道啟動。
- `channels.telegram.botToken`：Bot Token（BotFather 提供）。
- `channels.telegram.tokenFile`：從一般檔案路徑讀取 Token。不接受符號連結。
- `channels.telegram.dmPolicy`：`pairing | allowlist | open | disabled`（預設：pairing）。
- `channels.telegram.allowFrom`：私訊白名單（數字 Telegram 用戶 ID）。`allowlist` 需要至少一個發送者 ID。`open` 需要 `"*"`。`openclaw doctor --fix` 可將舊版 `@username` 項目解析為 ID，並可在白名單遷移流程中從配對儲存檔案恢復白名單項目。
- `channels.telegram.actions.poll`：啟用或停用 Telegram 投票建立（預設：啟用；仍需要 `sendMessage`）。
- `channels.telegram.defaultTo`：CLI `--deliver` 在未提供明確 `--reply-to` 時使用的預設 Telegram 目標。
- `channels.telegram.groupPolicy`：`open | allowlist | disabled`（預設：allowlist）。
- `channels.telegram.groupAllowFrom`：群組發送者白名單（數字 Telegram 用戶 ID）。`openclaw doctor --fix` 可將舊版 `@username` 項目解析為 ID。非數字項目在授權時被忽略。群組授權不使用私訊配對儲存備援（`2026.2.25+`）。
- 多帳號優先順序：
  - 設定兩個或以上帳號 ID 時，設定 `channels.telegram.defaultAccount`（或包含 `channels.telegram.accounts.default`）以明確指定預設路由。
  - 若兩者都未設定，OpenClaw 備援至第一個正規化的帳號 ID，`openclaw doctor` 會發出警告。
  - `channels.telegram.accounts.default.allowFrom` 和 `channels.telegram.accounts.default.groupAllowFrom` 僅適用於 `default` 帳號。
  - 具名帳號在帳號層級未設定值時，繼承 `channels.telegram.allowFrom` 和 `channels.telegram.groupAllowFrom`。
  - 具名帳號不繼承 `channels.telegram.accounts.default.allowFrom` / `groupAllowFrom`。
- `channels.telegram.groups`：每群組預設 + 白名單（使用 `"*"` 設定全域預設）。
  - `channels.telegram.groups.<id>.groupPolicy`：每群組的 groupPolicy 覆寫（`open | allowlist | disabled`）。
  - `channels.telegram.groups.<id>.requireMention`：Mention 閘門預設。
  - `channels.telegram.groups.<id>.skills`：技能篩選（省略 = 所有技能，空白 = 無）。
  - `channels.telegram.groups.<id>.allowFrom`：每群組發送者白名單覆寫。
  - `channels.telegram.groups.<id>.systemPrompt`：群組的額外系統提示。
  - `channels.telegram.groups.<id>.enabled`：為 `false` 時停用群組。
  - `channels.telegram.groups.<id>.topics.<threadId>.*`：每話題覆寫（群組欄位 + 話題限定的 `agentId`）。
  - `channels.telegram.groups.<id>.topics.<threadId>.agentId`：將此話題路由至特定 Agent（覆寫群組層級和 binding 路由）。
- `channels.telegram.groups.<id>.topics.<threadId>.groupPolicy`：每話題的 groupPolicy 覆寫（`open | allowlist | disabled`）。
- `channels.telegram.groups.<id>.topics.<threadId>.requireMention`：每話題 mention 閘門覆寫。
- 頂層 `bindings[]` 包含 `type: "acp"` 和 `match.peer.id` 中的標準話題 id `chatId:topic:topicId`：持久性 ACP 話題 binding 欄位（請參閱 [ACP Agents](/zh-Hant/tools/acp-agents#channel-specific-settings)）。
- `channels.telegram.direct.<id>.topics.<threadId>.agentId`：將私訊話題路由至特定 Agent（行為與論壇話題相同）。
- `channels.telegram.execApprovals.enabled`：為此帳號啟用 Telegram 作為基於聊天的執行核准客戶端。
- `channels.telegram.execApprovals.approvers`：允許核准或拒絕執行請求的 Telegram 用戶 ID。啟用執行核准時必要。
- `channels.telegram.execApprovals.target`：`dm | channel | both`（預設：`dm`）。`channel` 和 `both` 在有話題時保留原始 Telegram 話題。
- `channels.telegram.execApprovals.agentFilter`：轉發核准提示的選填 Agent ID 篩選。
- `channels.telegram.execApprovals.sessionFilter`：轉發核准提示的選填工作階段金鑰篩選（子字串或正則）。
- `channels.telegram.accounts.<account>.execApprovals`：Telegram 執行核准路由和核准者授權的每帳號覆寫。
- `channels.telegram.capabilities.inlineButtons`：`off | dm | group | all | allowlist`（預設：allowlist）。
- `channels.telegram.accounts.<account>.capabilities.inlineButtons`：每帳號覆寫。
- `channels.telegram.commands.nativeSkills`：啟用/停用 Telegram 原生技能指令。
- `channels.telegram.replyToMode`：`off | first | all`（預設：`off`）。
- `channels.telegram.textChunkLimit`：輸出區塊大小（字元數）。
- `channels.telegram.chunkMode`：`length`（預設）或 `newline`，在長度分割前先在空行（段落邊界）分割。
- `channels.telegram.linkPreview`：切換輸出訊息的連結預覽（預設：true）。
- `channels.telegram.streaming`：`off | partial | block | progress`（即時串流預覽；預設：`partial`；`progress` 映射至 `partial`；`block` 為舊版預覽模式相容性）。Telegram 預覽串流使用就地編輯的單一預覽訊息。
- `channels.telegram.mediaMaxMb`：收入/輸出 Telegram 媒體上限（MB，預設：100）。
- `channels.telegram.retry`：Telegram 傳送輔助函式（CLI/工具/操作）對可恢復輸出 API 錯誤的重試政策（attempts、minDelayMs、maxDelayMs、jitter）。
- `channels.telegram.network.autoSelectFamily`：覆寫 Node autoSelectFamily（true=啟用，false=停用）。Node 22+ 預設啟用，WSL2 預設停用。
- `channels.telegram.network.dnsResultOrder`：覆寫 DNS 結果順序（`ipv4first` 或 `verbatim`）。Node 22+ 預設為 `ipv4first`。
- `channels.telegram.proxy`：Bot API 呼叫的 Proxy URL（SOCKS/HTTP）。
- `channels.telegram.webhookUrl`：啟用 Webhook 模式（需要 `channels.telegram.webhookSecret`）。
- `channels.telegram.webhookSecret`：Webhook 密鑰（設定 webhookUrl 時必要）。
- `channels.telegram.webhookPath`：本地 Webhook 路徑（預設 `/telegram-webhook`）。
- `channels.telegram.webhookHost`：本地 Webhook 綁定主機（預設 `127.0.0.1`）。
- `channels.telegram.webhookPort`：本地 Webhook 綁定端口（預設 `8787`）。
- `channels.telegram.actions.reactions`：閘門控制 Telegram 工具反應。
- `channels.telegram.actions.sendMessage`：閘門控制 Telegram 工具訊息傳送。
- `channels.telegram.actions.deleteMessage`：閘門控制 Telegram 工具訊息刪除。
- `channels.telegram.actions.sticker`：閘門控制 Telegram 貼圖操作——傳送和搜尋（預設：false）。
- `channels.telegram.reactionNotifications`：`off | own | all` — 控制哪些反應觸發系統事件（未設定時預設：`own`）。
- `channels.telegram.reactionLevel`：`off | ack | minimal | extensive` — 控制 Agent 的反應能力（未設定時預設：`minimal`）。

- [設定參考 - Telegram](/zh-Hant/gateway/configuration-reference#telegram)

Telegram 特定的重要欄位：

- 啟動/驗證：`enabled`、`botToken`、`tokenFile`、`accounts.*`（`tokenFile` 必須指向一般檔案；不接受符號連結）
- 存取控制：`dmPolicy`、`allowFrom`、`groupPolicy`、`groupAllowFrom`、`groups`、`groups.*.topics.*`、頂層 `bindings[]`（`type: "acp"`）
- 執行核准：`execApprovals`、`accounts.*.execApprovals`
- 指令/選單：`commands.native`、`commands.nativeSkills`、`customCommands`
- 討論串/回覆：`replyToMode`
- 串流：`streaming`（預覽）、`blockStreaming`
- 格式化/傳送：`textChunkLimit`、`chunkMode`、`linkPreview`、`responsePrefix`
- 媒體/網路：`mediaMaxMb`、`timeoutSeconds`、`retry`、`network.autoSelectFamily`、`proxy`
- Webhook：`webhookUrl`、`webhookSecret`、`webhookPath`、`webhookHost`
- 操作/能力：`capabilities.inlineButtons`、`actions.sendMessage|editMessage|deleteMessage|reactions|sticker`
- 反應：`reactionNotifications`、`reactionLevel`
- 寫入/記錄：`configWrites`、`historyLimit`、`dmHistoryLimit`、`dms.*.historyLimit`

## 相關文件

- [配對](/zh-Hant/channels/pairing)
- [頻道路由](/zh-Hant/channels/channel-routing)
- [多 Agent 路由](/zh-Hant/concepts/multi-agent)
- [疑難排解](/zh-Hant/channels/troubleshooting)
