---
title: "Telegram"
summary: "Telegram 機器人支援狀態、功能和設定"
read_when:
  - 處理 Telegram 功能或 webhook
---

# Telegram（Bot API）

狀態：透過 grammY 支援 bot DM + 群組，已可正式使用。預設模式為長輪詢；webhook 模式為選用。

<CardGroup cols={3}>
  <Card title="Pairing（配對）" icon="link" href="/zh-Hant/channels/pairing">
    Telegram 的預設 DM 政策為配對。
  </Card>
  <Card title="Channel troubleshooting（頻道疑難排解）" icon="wrench" href="/zh-Hant/channels/troubleshooting">
    跨頻道診斷與修復手冊。
  </Card>
  <Card title="Gateway configuration（Gateway 設定）" icon="settings" href="/zh-Hant/gateway/configuration">
    完整的頻道設定模式與範例。
  </Card>
</CardGroup>

## 快速設定

<Steps>
  <Step title="在 BotFather 建立 bot token">
    開啟 Telegram 並與 **@BotFather** 聊天（確認 handle 正確為 `@BotFather`）。

    執行 `/newbot`，按提示操作並儲存 token。

  </Step>

  <Step title="設定 token 和 DM 政策">

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

    環境變數備用：`TELEGRAM_BOT_TOKEN=...`（僅預設帳號）。
    Telegram **不**使用 `openclaw channels login telegram`；請在設定/環境中設定 token，然後啟動 gateway。

  </Step>

  <Step title="啟動 gateway 並核准第一個 DM">

```bash
openclaw gateway
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

    配對碼 1 小時後過期。

  </Step>

  <Step title="將 bot 加入群組">
    將 bot 加入你的群組，然後設定 `channels.telegram.groups` 和 `groupPolicy` 以符合你的存取模型。
  </Step>
</Steps>

<Note>
Token 解析順序有帳號感知能力。實際上，設定值優先於環境變數備用，且 `TELEGRAM_BOT_TOKEN` 只適用於預設帳號。
</Note>

## Telegram 端設定

<AccordionGroup>
  <Accordion title="隱私模式和群組可見性">
    Telegram bot 預設為**隱私模式**，這限制了它們接收的群組訊息。

    若 bot 必須看到所有群組訊息，請：

    - 透過 `/setprivacy` 停用隱私模式，或
    - 讓 bot 成為群組管理員。

    切換隱私模式後，在每個群組中移除並重新加入 bot 以讓 Telegram 套用變更。

  </Accordion>

  <Accordion title="群組權限">
    管理員狀態在 Telegram 群組設定中控制。

    管理員 bot 接收所有群組訊息，對於永久在線的群組行為很有用。

  </Accordion>

  <Accordion title="有用的 BotFather 切換">

    - `/setjoingroups` 允許/拒絕加入群組
    - `/setprivacy` 用於群組可見性行為

  </Accordion>
</AccordionGroup>

## 存取控制與啟動

<Tabs>
  <Tab title="DM 政策">
    `channels.telegram.dmPolicy` 控制直接訊息存取：

    - `pairing`（預設）
    - `allowlist`（需要 `allowFrom` 中至少一個發送者 ID）
    - `open`（需要 `allowFrom` 包含 `"*"`）
    - `disabled`

    `channels.telegram.allowFrom` 接受數字 Telegram 用戶 ID。`telegram:` / `tg:` 前綴被接受並正規化。
    `dmPolicy: "allowlist"` 搭配空 `allowFrom` 封鎖所有 DM，設定驗證時會拒絕。
    上線精靈接受 `@username` 輸入並解析為數字 ID。
    若你升級後設定包含 `@username` allowlist 條目，執行 `openclaw doctor --fix` 解析它們（盡力而為；需要 Telegram bot token）。
    若你之前依賴配對儲存 allowlist 檔案，`openclaw doctor --fix` 可以在 allowlist 流程中恢復條目到 `channels.telegram.allowFrom`（例如 `dmPolicy: "allowlist"` 尚無明確 ID 時）。

    對於單一擁有者 bot，建議使用 `dmPolicy: "allowlist"` 搭配明確的數字 `allowFrom` ID，以保持存取政策在設定中的持久性（而非依賴先前的配對核准）。

    ### 查找你的 Telegram 用戶 ID

    較安全的方式（無需第三方 bot）：

    1. 傳 DM 給你的 bot。
    2. 執行 `openclaw logs --follow`。
    3. 讀取 `from.id`。

    官方 Bot API 方法：

```bash
curl "https://api.telegram.org/bot<bot_token>/getUpdates"
```

    第三方方法（較不私密）：`@userinfobot` 或 `@getidsbot`。

  </Tab>

  <Tab title="群組政策與 allowlist">
    兩個控制共同作用：

    1. **允許哪些群組**（`channels.telegram.groups`）
       - 無 `groups` 設定：
         - 搭配 `groupPolicy: "open"`：任何群組都可通過群組 ID 檢查
         - 搭配 `groupPolicy: "allowlist"`（預設）：群組被封鎖直到新增 `groups` 條目（或 `"*"`）
       - 已設定 `groups`：作為 allowlist（明確 ID 或 `"*"`）

    2. **群組中允許哪些發送者**（`channels.telegram.groupPolicy`）
       - `open`
       - `allowlist`（預設）
       - `disabled`

    `groupAllowFrom` 用於群組發送者過濾。若未設定，Telegram 退回到 `allowFrom`。
    `groupAllowFrom` 條目應為數字 Telegram 用戶 ID（`telegram:` / `tg:` 前綴被正規化）。
    非數字條目在發送者授權時被忽略。
    安全邊界（`2026.2.25+`）：群組發送者驗證**不**繼承 DM 配對儲存核准。
    配對僅限 DM。對於群組，設定 `groupAllowFrom` 或每群組/每主題的 `allowFrom`。
    執行時注意：若 `channels.telegram` 完全缺失，執行時預設為封閉式 `groupPolicy="allowlist"`，除非明確設定了 `channels.defaults.groupPolicy`。

    範例：在特定群組中允許任何成員：

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

  </Tab>

  <Tab title="Mention 行為">
    群組回覆預設需要 mention。

    Mention 可來自：

    - 原生 `@botusername` mention，或
    - mention 模式：
      - `agents.list[].groupChat.mentionPatterns`
      - `messages.groupChat.mentionPatterns`

    工作階段層級指令切換：

    - `/activation always`
    - `/activation mention`

    這些只更新工作階段狀態。使用設定來持久化。

    持久化設定範例：

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

    - 將群組訊息轉發給 `@userinfobot` / `@getidsbot`
    - 或從 `openclaw logs --follow` 讀取 `chat.id`
    - 或檢查 Bot API `getUpdates`

  </Tab>
</Tabs>

## 執行時行為

- Telegram 由 gateway 進程擁有。
- 路由是確定性的：Telegram 入站回覆到 Telegram（模型不選擇頻道）。
- 入站訊息正規化為帶有回覆 metadata 和媒體佔位符的共享頻道封包。
- 群組工作階段按群組 ID 隔離。論壇主題在工作階段金鑰中附加 `:topic:<threadId>` 以保持主題隔離。
- DM 訊息可攜帶 `message_thread_id`；OpenClaw 以串感知工作階段金鑰路由它們，並保留串 ID 用於回覆。
- 長輪詢使用帶有每聊天/每串排序的 grammY runner。整體 runner sink 並發使用 `agents.defaults.maxConcurrent`。
- Telegram Bot API 不支援已讀回執（`sendReadReceipts` 不適用）。

## 功能參考

<AccordionGroup>
  <Accordion title="即時串流預覽（訊息編輯）">
    OpenClaw 可以即時串流部分回覆：

    - 直接聊天：預覽訊息 + `editMessageText`
    - 群組/主題：預覽訊息 + `editMessageText`

    需求：

    - `channels.telegram.streaming` 為 `off | partial | block | progress`（預設：`partial`）
    - `progress` 在 Telegram 對應到 `partial`（跨頻道命名相容）
    - 舊版 `channels.telegram.streamMode` 和布林值 `streaming` 自動對應

    對於純文字回覆：

    - DM：OpenClaw 保留相同的預覽訊息並在原地進行最終編輯（不傳第二條訊息）
    - 群組/主題：OpenClaw 保留相同的預覽訊息並在原地進行最終編輯（不傳第二條訊息）

    對於複雜回覆（例如媒體 payload），OpenClaw 退回到一般最終傳遞，然後清理預覽訊息。

    預覽串流與區塊串流是分開的。當 Telegram 明確啟用區塊串流時，OpenClaw 跳過預覽串流以避免雙重串流。

    若原生草稿傳輸不可用/被拒絕，OpenClaw 自動退回到 `sendMessage` + `editMessageText`。

    Telegram 專用推理串流：

    - `/reasoning stream` 在生成時將推理傳送到即時預覽
    - 最終答案不含推理文字傳送

  </Accordion>

  <Accordion title="格式化和 HTML 備用">
    出站文字使用 Telegram `parse_mode: "HTML"`。

    - Markdown 式文字被渲染為 Telegram 安全 HTML。
    - 原始模型 HTML 被跳脫以減少 Telegram 解析失敗。
    - 若 Telegram 拒絕解析的 HTML，OpenClaw 以純文字重試。

    連結預覽預設啟用，可用 `channels.telegram.linkPreview: false` 停用。

  </Accordion>

  <Accordion title="原生指令和自訂指令">
    Telegram 指令選單註冊在啟動時透過 `setMyCommands` 處理。

    原生指令預設：

    - `commands.native: "auto"` 對 Telegram 啟用原生指令

    新增自訂指令選單條目：

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

    - 名稱被正規化（去除前導 `/`，小寫）
    - 有效模式：`a-z`、`0-9`、`_`，長度 `1..32`
    - 自訂指令不能覆蓋原生指令
    - 衝突/重複被跳過並記錄

    注意：

    - 自訂指令只是選單條目；它們不自動實作行為
    - 即使未在 Telegram 選單中顯示，輸入時插件/技能指令仍然可以運作

    若停用原生指令，內建指令被移除。若已設定，自訂/插件指令仍可能註冊。

    常見設定失敗：

    - `setMyCommands failed` 通常表示到 `api.telegram.org` 的出站 DNS/HTTPS 被封鎖。

    ### 裝置配對指令（`device-pair` 外掛程式）

    當安裝 `device-pair` 外掛程式時：

    1. `/pair` 生成設定碼
    2. 在 iOS app 中貼上碼
    3. `/pair approve` 核准最新的待處理請求

    更多詳情：[Pairing](/zh-Hant/channels/pairing#pair-via-telegram-recommended-for-ios)。

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

    每帳號覆蓋：

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

    舊版 `capabilities: ["inlineButtons"]` 對應到 `inlineButtons: "all"`。

    訊息動作範例：

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

    按鈕點擊作為文字傳遞給 agent：
    `callback_data: <value>`

  </Accordion>

  <Accordion title="Telegram 訊息動作（agent 和自動化）">
    Telegram 工具動作包括：

    - `sendMessage`（`to`、`content`、選用 `mediaUrl`、`replyToMessageId`、`messageThreadId`）
    - `react`（`chatId`、`messageId`、`emoji`）
    - `deleteMessage`（`chatId`、`messageId`）
    - `editMessage`（`chatId`、`messageId`、`content`）
    - `createForumTopic`（`chatId`、`name`、選用 `iconColor`、`iconCustomEmojiId`）

    頻道訊息動作公開了易用的別名（`send`、`react`、`delete`、`edit`、`sticker`、`sticker-search`、`topic-create`）。

    閘道控制：

    - `channels.telegram.actions.sendMessage`
    - `channels.telegram.actions.deleteMessage`
    - `channels.telegram.actions.reactions`
    - `channels.telegram.actions.sticker`（預設：停用）

    注意：`edit` 和 `topic-create` 目前預設啟用，沒有單獨的 `channels.telegram.actions.*` 切換。

    Reaction 移除語義：[/tools/reactions](/zh-Hant/tools/reactions)

  </Accordion>

  <Accordion title="Reply threading tags">
    Telegram 支援在生成輸出中明確的回覆串標籤：

    - `[[reply_to_current]]` 回覆觸發訊息
    - `[[reply_to:<id>]]` 回覆特定 Telegram 訊息 ID

    `channels.telegram.replyToMode` 控制處理：

    - `off`（預設）
    - `first`
    - `all`

    注意：`off` 停用隱式回覆串。明確的 `[[reply_to_*]]` 標籤仍然有效。

  </Accordion>

  <Accordion title="論壇主題和串行為">
    論壇超級群組：

    - 主題工作階段金鑰附加 `:topic:<threadId>`
    - 回覆和 typing 以主題串為目標
    - 主題設定路徑：
      `channels.telegram.groups.<chatId>.topics.<threadId>`

    一般主題（`threadId=1`）特殊情況：

    - 訊息傳送省略 `message_thread_id`（Telegram 拒絕 `sendMessage(...thread_id=1)`）
    - Typing 動作仍包含 `message_thread_id`

    主題繼承：主題條目繼承群組設定，除非有覆蓋（`requireMention`、`allowFrom`、`skills`、`systemPrompt`、`enabled`、`groupPolicy`）。
    `agentId` 是僅限主題的，不從群組預設繼承。

    **每主題 agent 路由**：每個主題可以透過在主題設定中設定 `agentId` 路由到不同的 agent。這讓每個主題有自己隔離的工作區、記憶體和工作階段。範例：

    ```json5
    {
      channels: {
        telegram: {
          groups: {
            "-1001234567890": {
              topics: {
                "1": { agentId: "main" },      // 一般主題 → main agent
                "3": { agentId: "zu" },        // 開發主題 → zu agent
                "5": { agentId: "coder" }      // 程式碼審查 → coder agent
              }
            }
          }
        }
      }
    }
    ```

    每個主題有自己的工作階段金鑰：`agent:zu:telegram:group:-1001234567890:topic:3`

    **持久 ACP 主題綁定**：論壇主題可以透過頂層類型 ACP 綁定固定 ACP harness 工作階段：

    - `bindings[]` 帶有 `type: "acp"` 和 `match.channel: "telegram"`

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

    目前範圍限於群組和超級群組中的論壇主題。

    **從聊天中 ACP spawn 串綁定**：

    - `/acp spawn <agent> --thread here|auto` 可以將當前 Telegram 主題綁定到新的 ACP 工作階段。
    - 後續主題訊息直接路由到綁定的 ACP 工作階段（不需要 `/acp steer`）。
    - 成功綁定後，OpenClaw 在主題中固定 spawn 確認訊息。
    - 需要 `channels.telegram.threadBindings.spawnAcpSessions=true`。

    範本上下文包括：

    - `MessageThreadId`
    - `IsForum`

    DM 串行為：

    - 帶有 `message_thread_id` 的私人聊天保留 DM 路由，但使用串感知的工作階段金鑰/回覆目標。

  </Accordion>

  <Accordion title="音訊、影片和貼圖">
    ### 音訊訊息

    Telegram 區分語音筆記和音訊檔案。

    - 預設：音訊檔案行為
    - 在 agent 回覆中標記 `[[audio_as_voice]]` 強制傳送語音筆記

    訊息動作範例：

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

    Telegram 區分影片檔案和影片筆記。

    訊息動作範例：

```json5
{
  action: "send",
  channel: "telegram",
  to: "123456789",
  media: "https://example.com/video.mp4",
  asVideoNote: true,
}
```

    影片筆記不支援說明；提供的訊息文字單獨傳送。

    ### 貼圖

    入站貼圖處理：

    - 靜態 WEBP：下載並處理（佔位符 `<media:sticker>`）
    - 動態 TGS：跳過
    - 影片 WEBM：跳過

    貼圖上下文欄位：

    - `Sticker.emoji`
    - `Sticker.setName`
    - `Sticker.fileId`
    - `Sticker.fileUniqueId`
    - `Sticker.cachedDescription`

    貼圖快取檔案：

    - `~/.openclaw/telegram/sticker-cache.json`

    貼圖描述一次後快取以減少重複的視覺呼叫。

    啟用貼圖動作：

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

    傳送貼圖動作：

```json5
{
  action: "sticker",
  channel: "telegram",
  to: "123456789",
  fileId: "CAACAgIAAxkBAAI...",
}
```

    搜尋快取的貼圖：

```json5
{
  action: "sticker-search",
  channel: "telegram",
  query: "cat waving",
  limit: 5,
}
```

  </Accordion>

  <Accordion title="Reaction 通知">
    Telegram reactions 以 `message_reaction` 更新形式到達（與訊息 payload 分開）。

    啟用後，OpenClaw 排隊系統事件，例如：

    - `Telegram reaction added: 👍 by Alice (@alice) on msg 42`

    設定：

    - `channels.telegram.reactionNotifications`：`off | own | all`（預設：`own`）
    - `channels.telegram.reactionLevel`：`off | ack | minimal | extensive`（預設：`minimal`）

    注意：

    - `own` 指用戶對 bot 傳送訊息的 reaction（透過已傳送訊息快取，盡力而為）。
    - Reaction 事件仍遵循 Telegram 存取控制（`dmPolicy`、`allowFrom`、`groupPolicy`、`groupAllowFrom`）；未授權的發送者被丟棄。
    - Telegram 在 reaction 更新中不提供串 ID。
      - 非論壇群組路由到群組聊天工作階段
      - 論壇群組路由到群組一般主題工作階段（`:topic:1`），而非確切的來源主題

    輪詢/webhook 的 `allowed_updates` 自動包含 `message_reaction`。

  </Accordion>

  <Accordion title="Ack reactions">
    `ackReaction` 在 OpenClaw 處理入站訊息時傳送確認表情符號。

    解析順序：

    - `channels.telegram.accounts.<accountId>.ackReaction`
    - `channels.telegram.ackReaction`
    - `messages.ackReaction`
    - agent 身份表情符號備用（`agents.list[].identity.emoji`，否則為 "👀"）

    注意：

    - Telegram 期望 unicode 表情符號（例如 "👀"）。
    - 使用 `""` 停用頻道或帳號的 reaction。

  </Accordion>

  <Accordion title="從 Telegram 事件和指令寫入設定">
    頻道設定寫入預設啟用（`configWrites !== false`）。

    Telegram 觸發的寫入包括：

    - 群組遷移事件（`migrate_to_chat_id`）更新 `channels.telegram.groups`
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

  <Accordion title="長輪詢 vs webhook">
    預設：長輪詢。

    Webhook 模式：

    - 設定 `channels.telegram.webhookUrl`
    - 設定 `channels.telegram.webhookSecret`（設定了 webhook URL 時必要）
    - 選用 `channels.telegram.webhookPath`（預設 `/telegram-webhook`）
    - 選用 `channels.telegram.webhookHost`（預設 `127.0.0.1`）
    - 選用 `channels.telegram.webhookPort`（預設 `8787`）

    webhook 模式的預設本地監聽器綁定到 `127.0.0.1:8787`。

    若你的公開端點不同，在前面放置反向代理並將 `webhookUrl` 指向公開 URL。
    當你確實需要外部 ingress 時設定 `webhookHost`（例如 `0.0.0.0`）。

  </Accordion>

  <Accordion title="限制、重試和 CLI 目標">
    - `channels.telegram.textChunkLimit` 預設為 4000。
    - `channels.telegram.chunkMode="newline"` 在長度分割前偏好段落邊界（空行）。
    - `channels.telegram.mediaMaxMb`（預設 100）限制入站和出站 Telegram 媒體大小。
    - `channels.telegram.timeoutSeconds` 覆蓋 Telegram API 用戶端逾時（若未設定，套用 grammY 預設）。
    - 群組上下文歷史使用 `channels.telegram.historyLimit` 或 `messages.groupChat.historyLimit`（預設 50）；`0` 停用。
    - DM 歷史控制：
      - `channels.telegram.dmHistoryLimit`
      - `channels.telegram.dms["<user_id>"].historyLimit`
    - `channels.telegram.retry` 設定適用於 Telegram 傳送輔助工具（CLI/工具/動作）的可恢復出站 API 錯誤重試。

    CLI 傳送目標可以是數字聊天 ID 或用戶名：

```bash
openclaw message send --channel telegram --target 123456789 --message "hi"
openclaw message send --channel telegram --target @name --message "hi"
```

    Telegram 輪詢使用 `openclaw message poll` 並支援論壇主題：

```bash
openclaw message poll --channel telegram --target 123456789 \
  --poll-question "Ship it?" --poll-option "Yes" --poll-option "No"
openclaw message poll --channel telegram --target -1001234567890:topic:42 \
  --poll-question "Pick a time" --poll-option "10am" --poll-option "2pm" \
  --poll-duration-seconds 300 --poll-public
```

    Telegram 專用輪詢旗標：

    - `--poll-duration-seconds`（5-600）
    - `--poll-anonymous`
    - `--poll-public`
    - `--thread-id` 用於論壇主題（或使用 `:topic:` 目標）

    動作閘道：

    - `channels.telegram.actions.sendMessage=false` 停用出站 Telegram 訊息，包括輪詢
    - `channels.telegram.actions.poll=false` 停用 Telegram 輪詢建立，同時保留一般傳送啟用

  </Accordion>
</AccordionGroup>

## 疑難排解

<AccordionGroup>
  <Accordion title="Bot 不回覆未 mention 的群組訊息">

    - 若 `requireMention=false`，Telegram 隱私模式必須允許完整可見性。
      - BotFather：`/setprivacy` -> Disable
      - 然後在群組中移除並重新加入 bot
    - 若設定期望未提及的群組訊息，`openclaw channels status` 會警告。
    - `openclaw channels status --probe` 可以檢查明確的數字群組 ID；萬用字元 `"*"` 無法探測成員資格。
    - 快速工作階段測試：`/activation always`。

  </Accordion>

  <Accordion title="Bot 完全看不到群組訊息">

    - 當 `channels.telegram.groups` 存在時，群組必須列出（或包含 `"*"`）
    - 驗證 bot 在群組中的成員資格
    - 檢查日誌：`openclaw logs --follow` 查看跳過原因

  </Accordion>

  <Accordion title="指令部分或完全不運作">

    - 授權你的發送者身份（配對和/或數字 `allowFrom`）
    - 即使群組政策為 `open`，指令授權仍然適用
    - `setMyCommands failed` 通常表示到 `api.telegram.org` 的 DNS/HTTPS 連線問題

  </Accordion>

  <Accordion title="輪詢或網路不穩定">

    - Node 22+ + 自訂 fetch/proxy 可能在 AbortSignal 類型不匹配時觸發立即中止行為。
    - 某些主機首先解析 `api.telegram.org` 到 IPv6；斷掉的 IPv6 出站可能導致間歇性 Telegram API 失敗。
    - 若日誌包含 `TypeError: fetch failed` 或 `Network request for 'getUpdates' failed!`，OpenClaw 現在將這些重試為可恢復的網路錯誤。
    - 在直接出站/TLS 不穩定的 VPS 主機上，透過 `channels.telegram.proxy` 路由 Telegram API 呼叫：

```yaml
channels:
  telegram:
    proxy: socks5://<user>:<password>@proxy-host:1080
```

    - Node 22+ 預設 `autoSelectFamily=true`（WSL2 除外）和 `dnsResultOrder=ipv4first`。
    - 若你的主機是 WSL2 或明確在僅 IPv4 行為下運作更好，強制 family 選擇：

```yaml
channels:
  telegram:
    network:
      autoSelectFamily: false
```

    - 環境變數覆蓋（臨時）：
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

更多幫助：[Channel troubleshooting](/zh-Hant/channels/troubleshooting)。

## Telegram 設定參考指標

主要參考：

- `channels.telegram.enabled`：啟用/停用頻道啟動。
- `channels.telegram.botToken`：bot token（BotFather）。
- `channels.telegram.tokenFile`：從檔案路徑讀取 token。
- `channels.telegram.dmPolicy`：`pairing | allowlist | open | disabled`（預設：pairing）。
- `channels.telegram.allowFrom`：DM allowlist（數字 Telegram 用戶 ID）。`allowlist` 需要至少一個發送者 ID。`open` 需要 `"*"`。`openclaw doctor --fix` 可以將舊版 `@username` 條目解析為 ID，並可以在 allowlist 遷移流程中從配對儲存檔案恢復 allowlist 條目。
- `channels.telegram.actions.poll`：啟用或停用 Telegram 輪詢建立（預設：啟用；仍需要 `sendMessage`）。
- `channels.telegram.defaultTo`：CLI `--deliver` 使用的預設 Telegram 目標（未提供明確 `--reply-to` 時）。
- `channels.telegram.groupPolicy`：`open | allowlist | disabled`（預設：allowlist）。
- `channels.telegram.groupAllowFrom`：群組發送者 allowlist（數字 Telegram 用戶 ID）。`openclaw doctor --fix` 可以將舊版 `@username` 條目解析為 ID。非數字條目在驗證時被忽略。群組驗證不使用 DM 配對儲存備用（`2026.2.25+`）。
- 多帳號優先順序：
  - 當設定了兩個或更多帳號 ID 時，設定 `channels.telegram.defaultAccount`（或包含 `channels.telegram.accounts.default`）以明確預設路由。
  - 若兩者都未設定，OpenClaw 退回到第一個正規化的帳號 ID，`openclaw doctor` 警告。
  - `channels.telegram.accounts.default.allowFrom` 和 `channels.telegram.accounts.default.groupAllowFrom` 只適用於 `default` 帳號。
  - 具名帳號在帳號層級值未設定時繼承 `channels.telegram.allowFrom` 和 `channels.telegram.groupAllowFrom`。
  - 具名帳號不繼承 `channels.telegram.accounts.default.allowFrom` / `groupAllowFrom`。
- `channels.telegram.groups`：每群組預設 + allowlist（使用 `"*"` 作為全域預設）。
  - `channels.telegram.groups.<id>.groupPolicy`：每群組的 groupPolicy 覆蓋（`open | allowlist | disabled`）。
  - `channels.telegram.groups.<id>.requireMention`：mention 閘道預設。
  - `channels.telegram.groups.<id>.skills`：技能過濾器（省略 = 所有技能，空 = 無）。
  - `channels.telegram.groups.<id>.allowFrom`：每群組發送者 allowlist 覆蓋。
  - `channels.telegram.groups.<id>.systemPrompt`：群組的額外 system prompt。
  - `channels.telegram.groups.<id>.enabled`：`false` 時停用群組。
  - `channels.telegram.groups.<id>.topics.<threadId>.*`：每主題覆蓋（群組欄位 + 僅限主題的 `agentId`）。
  - `channels.telegram.groups.<id>.topics.<threadId>.agentId`：將此主題路由到特定 agent（覆蓋群組層級和繫結路由）。
  - `channels.telegram.groups.<id>.topics.<threadId>.groupPolicy`：每主題的 groupPolicy 覆蓋（`open | allowlist | disabled`）。
  - `channels.telegram.groups.<id>.topics.<threadId>.requireMention`：每主題 mention 閘道覆蓋。
  - 帶有 `type: "acp"` 的頂層 `bindings[]` 和 `match.peer.id` 中的標準主題 id `chatId:topic:topicId`：持久 ACP 主題繫結欄位（參見 [ACP Agents](/zh-Hant/tools/acp-agents#channel-specific-settings)）。
  - `channels.telegram.direct.<id>.topics.<threadId>.agentId`：將 DM 主題路由到特定 agent（與論壇主題行為相同）。
- `channels.telegram.capabilities.inlineButtons`：`off | dm | group | all | allowlist`（預設：allowlist）。
- `channels.telegram.accounts.<account>.capabilities.inlineButtons`：每帳號覆蓋。
- `channels.telegram.commands.nativeSkills`：啟用/停用 Telegram 原生技能指令。
- `channels.telegram.replyToMode`：`off | first | all`（預設：`off`）。
- `channels.telegram.textChunkLimit`：出站區塊大小（字元）。
- `channels.telegram.chunkMode`：`length`（預設）或 `newline` 在長度分塊前按空行（段落邊界）分割。
- `channels.telegram.linkPreview`：切換出站訊息的連結預覽（預設：true）。
- `channels.telegram.streaming`：`off | partial | block | progress`（即時串流預覽；預設：`partial`；`progress` 對應到 `partial`；`block` 是舊版預覽模式相容）。Telegram 預覽串流使用在原地編輯的單一預覽訊息。
- `channels.telegram.mediaMaxMb`：入站/出站 Telegram 媒體上限（MB，預設：100）。
- `channels.telegram.retry`：Telegram 傳送輔助工具（CLI/工具/動作）的重試政策，用於可恢復的出站 API 錯誤（attempts、minDelayMs、maxDelayMs、jitter）。
- `channels.telegram.network.autoSelectFamily`：覆蓋 Node autoSelectFamily（true=啟用，false=停用）。Node 22+ 預設啟用，WSL2 預設停用。
- `channels.telegram.network.dnsResultOrder`：覆蓋 DNS 結果順序（`ipv4first` 或 `verbatim`）。Node 22+ 預設 `ipv4first`。
- `channels.telegram.proxy`：Bot API 呼叫的 proxy URL（SOCKS/HTTP）。
- `channels.telegram.webhookUrl`：啟用 webhook 模式（需要 `channels.telegram.webhookSecret`）。
- `channels.telegram.webhookSecret`：webhook secret（設定 webhookUrl 時必要）。
- `channels.telegram.webhookPath`：本地 webhook 路徑（預設 `/telegram-webhook`）。
- `channels.telegram.webhookHost`：本地 webhook 綁定主機（預設 `127.0.0.1`）。
- `channels.telegram.webhookPort`：本地 webhook 綁定埠（預設 `8787`）。
- `channels.telegram.actions.reactions`：閘道 Telegram 工具 reactions。
- `channels.telegram.actions.sendMessage`：閘道 Telegram 工具訊息傳送。
- `channels.telegram.actions.deleteMessage`：閘道 Telegram 工具訊息刪除。
- `channels.telegram.actions.sticker`：閘道 Telegram 貼圖動作——傳送和搜尋（預設：false）。
- `channels.telegram.reactionNotifications`：`off | own | all`——控制哪些 reactions 觸發系統事件（未設定時預設：`own`）。
- `channels.telegram.reactionLevel`：`off | ack | minimal | extensive`——控制 agent 的 reaction 能力（未設定時預設：`minimal`）。

- [Configuration reference - Telegram](/zh-Hant/gateway/configuration-reference#telegram)

Telegram 特定高信號欄位：

- 啟動/驗證：`enabled`、`botToken`、`tokenFile`、`accounts.*`
- 存取控制：`dmPolicy`、`allowFrom`、`groupPolicy`、`groupAllowFrom`、`groups`、`groups.*.topics.*`、頂層 `bindings[]`（`type: "acp"`）
- 指令/選單：`commands.native`、`commands.nativeSkills`、`customCommands`
- 串/回覆：`replyToMode`
- 串流：`streaming`（預覽）、`blockStreaming`
- 格式化/傳遞：`textChunkLimit`、`chunkMode`、`linkPreview`、`responsePrefix`
- 媒體/網路：`mediaMaxMb`、`timeoutSeconds`、`retry`、`network.autoSelectFamily`、`proxy`
- webhook：`webhookUrl`、`webhookSecret`、`webhookPath`、`webhookHost`
- 動作/能力：`capabilities.inlineButtons`、`actions.sendMessage|editMessage|deleteMessage|reactions|sticker`
- reactions：`reactionNotifications`、`reactionLevel`
- 寫入/歷史：`configWrites`、`historyLimit`、`dmHistoryLimit`、`dms.*.historyLimit`

## 相關

- [Pairing](/zh-Hant/channels/pairing)
- [Channel routing](/zh-Hant/channels/channel-routing)
- [Multi-agent routing](/zh-Hant/concepts/multi-agent)
- [Troubleshooting](/zh-Hant/channels/troubleshooting)
