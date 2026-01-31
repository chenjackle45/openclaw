---
title: "Telegram(Telegram Bot API)"
summary: "Telegram 機器人支援狀態、功能和設定"
read_when:
  - 處理 Telegram 功能或 webhooks
---
# Telegram（Bot API）


狀態：透過 grammY 的機器人私訊 + 群組已達生產就緒狀態。預設使用長輪詢；webhook 為可選。

## 快速設定（初學者）
1) 使用 **@BotFather** 建立機器人並複製令牌。
2) 設定令牌：
   - 環境變數：`TELEGRAM_BOT_TOKEN=...`
   - 或設定：`channels.telegram.botToken: "..."`。
   - 如果兩者都設定，設定優先（環境變數備選僅用於預設帳戶）。
3) 啟動 Gateway。
4) 私訊存取預設為配對；首次聯繫時批准配對碼。

最小設定：
```json5
{
  channels: {
    telegram: {
      enabled: true,
      botToken: "123:abc",
      dmPolicy: "pairing"
    }
  }
}
```

## 這是什麼
- 由 Gateway 擁有的 Telegram Bot API 頻道。
- 確定性路由：回覆返回 Telegram；模型永遠不選擇頻道。
- 私訊共享代理的主會話；群組保持隔離（`agent:<agentId>:telegram:group:<chatId>`）。

## 設定（快速路徑）
### 1) 建立機器人令牌（BotFather）
1) 開啟 Telegram 並與 **@BotFather** 聊天。
2) 執行 `/newbot`，然後按照提示操作（名稱 + 以 `bot` 結尾的用戶名）。
3) 複製令牌並安全儲存。

可選的 BotFather 設定：
- `/setjoingroups` — 允許/拒絕將機器人新增到群組。
- `/setprivacy` — 控制機器人是否看到所有群組訊息。

### 2) 設定令牌（環境變數或設定）
範例：

```json5
{
  channels: {
    telegram: {
      enabled: true,
      botToken: "123:abc",
      dmPolicy: "pairing",
      groups: { "*": { requireMention: true } }
    }
  }
}
```

環境變數選項：`TELEGRAM_BOT_TOKEN=...`（適用於預設帳戶）。
如果環境變數和設定都設定了，設定優先。

多帳戶支援：使用 `channels.telegram.accounts` 設定每個帳戶的令牌和可選的 `name`。請參閱 [`gateway/configuration`](/gateway/configuration#telegramaccounts--discordaccounts--slackaccounts--signalaccounts--imessageaccounts) 了解共享模式。

3) 啟動 Gateway。當令牌被解析時（設定優先，環境變數備選），Telegram 會啟動。
4) 私訊存取預設為配對。當機器人首次被聯繫時批准代碼。
5) 對於群組：新增機器人，決定隱私/管理員行為（如下），然後設定 `channels.telegram.groups` 以控制提及閘門 + 允許清單。

## 令牌 + 隱私 + 權限（Telegram 端）

### 令牌建立（BotFather）
- `/newbot` 建立機器人並返回令牌（保密）。
- 如果令牌洩漏，透過 @BotFather 撤銷/重新生成並更新您的設定。

### 群組訊息可見性（隱私模式）
Telegram 機器人預設為**隱私模式**，這限制了它們接收哪些群組訊息。
如果您的機器人必須看到*所有*群組訊息，您有兩個選項：
- 使用 `/setprivacy` 停用隱私模式 **或**
- 將機器人新增為群組**管理員**（管理員機器人接收所有訊息）。

**注意：** 當您切換隱私模式時，Telegram 需要移除 + 重新新增機器人
到每個群組以使更改生效。

### 群組權限（管理員權限）
管理員狀態在群組內設定（Telegram UI）。管理員機器人始終接收所有
群組訊息，因此如果您需要完整可見性，請使用管理員。

## 運作方式（行為）
- 入站訊息被正規化為帶有回覆上下文和媒體佔位符的共享頻道信封。
- 群組回覆預設需要提及（原生 @mention 或 `agents.list[].groupChat.mentionPatterns` / `messages.groupChat.mentionPatterns`）。
- 多代理覆寫：在 `agents.list[].groupChat.mentionPatterns` 上設定每代理模式。
- 回覆始終路由回同一個 Telegram 聊天。
- 長輪詢使用 grammY runner 進行每聊天排序；整體並發由 `agents.defaults.maxConcurrent` 限制。
- Telegram Bot API 不支援已讀回執；沒有 `sendReadReceipts` 選項。

## 格式化（Telegram HTML）
- 外發 Telegram 文字使用 `parse_mode: "HTML"`（Telegram 支援的標籤子集）。
- 類 Markdown 輸入被渲染為 **Telegram 安全的 HTML**（粗體/斜體/刪除線/程式碼/連結）；區塊元素被扁平化為帶有換行/項目符號的文字。
- 來自模型的原始 HTML 會被轉義以避免 Telegram 解析錯誤。
- 如果 Telegram 拒絕 HTML 負載，OpenClaw 會以純文字重試同一訊息。

## 命令（原生 + 自訂）
OpenClaw 在啟動時向 Telegram 的機器人選單註冊原生命令（如 `/status`、`/reset`、`/model`）。
您可以透過設定將自訂命令新增到選單：

```json5
{
  channels: {
    telegram: {
      customCommands: [
        { command: "backup", description: "Git 備份" },
        { command: "generate", description: "建立圖片" }
      ]
    }
  }
}
```

## 疑難排解

- 日誌中的 `setMyCommands failed` 通常表示到 `api.telegram.org` 的外發 HTTPS/DNS 被阻止。
- 如果您看到 `sendMessage` 或 `sendChatAction` 失敗，請檢查 IPv6 路由和 DNS。

更多幫助：[頻道疑難排解](/channels/troubleshooting)。

備註：
- 自訂命令**僅為選單項目**；除非您在其他地方處理它們，否則 OpenClaw 不會實作它們。
- 命令名稱被正規化（前導 `/` 剝離，小寫）且必須匹配 `a-z`、`0-9`、`_`（1–32 字元）。
- 自訂命令**無法覆寫原生命令**。衝突會被忽略並記錄。
- 如果 `commands.native` 被停用，只有自訂命令會被註冊（如果沒有則清除）。

## 限制
- 外發文字分塊至 `channels.telegram.textChunkLimit`（預設 4000）。
- 可選的換行分塊：設定 `channels.telegram.chunkMode="newline"` 在長度分塊前在空白行（段落邊界）分割。
- 媒體下載/上傳由 `channels.telegram.mediaMaxMb` 限制（預設 5）。
- Telegram Bot API 請求在 `channels.telegram.timeoutSeconds` 後逾時（透過 grammY 預設 500）。設定較低以避免長時間掛起。
- 群組歷史上下文使用 `channels.telegram.historyLimit`（或 `channels.telegram.accounts.*.historyLimit`），回退到 `messages.groupChat.historyLimit`。設定 `0` 停用（預設 50）。
- 私訊歷史可以用 `channels.telegram.dmHistoryLimit`（用戶輪次）限制。每用戶覆寫：`channels.telegram.dms["<user_id>"].historyLimit`。

## 群組啟動模式

預設情況下，機器人只回應群組中的提及（`@botname` 或 `agents.list[].groupChat.mentionPatterns` 中的模式）。要更改此行為：

### 透過設定（推薦）

```json5
{
  channels: {
    telegram: {
      groups: {
        "-1001234567890": { requireMention: false }  // 在此群組中始終回應
      }
    }
  }
}
```

**重要：** 設定 `channels.telegram.groups` 會建立**允許清單** - 只有列出的群組（或 `"*"`）會被接受。
論壇主題繼承其父群組設定（allowFrom、requireMention、skills、prompts），除非您在 `channels.telegram.groups.<groupId>.topics.<topicId>` 下新增每主題覆寫。

允許所有群組且始終回應：
```json5
{
  channels: {
    telegram: {
      groups: {
        "*": { requireMention: false }  // 所有群組，始終回應
      }
    }
  }
}
```

保持所有群組僅提及（預設行為）：
```json5
{
  channels: {
    telegram: {
      groups: {
        "*": { requireMention: true }  // 或完全省略 groups
      }
    }
  }
}
```

### 透過命令（會話級）

在群組中發送：
- `/activation always` - 回應所有訊息
- `/activation mention` - 需要提及（預設）

**注意：** 命令僅更新會話狀態。對於重啟後的持久行為，請使用設定。

### 取得群組聊天 ID

將群組中的任何訊息轉發給 Telegram 上的 `@userinfobot` 或 `@getidsbot` 以查看聊天 ID（負數如 `-1001234567890`）。

**提示：** 對於您自己的用戶 ID，私訊機器人，它會回覆您的用戶 ID（配對訊息），或在命令啟用後使用 `/whoami`。

**隱私備註：** `@userinfobot` 是第三方機器人。如果您願意，將機器人新增到群組，發送訊息，並使用 `openclaw logs --follow` 讀取 `chat.id`，或使用 Bot API `getUpdates`。

## 設定寫入
預設情況下，Telegram 允許寫入由頻道事件或 `/config set|unset` 觸發的設定更新。

這發生在：
- 群組升級為超級群組且 Telegram 發出 `migrate_to_chat_id`（聊天 ID 更改）。OpenClaw 可以自動遷移 `channels.telegram.groups`。
- 您在 Telegram 聊天中執行 `/config set` 或 `/config unset`（需要 `commands.config: true`）。

使用以下方式停用：
```json5
{
  channels: { telegram: { configWrites: false } }
}
```

## 存取控制（私訊 + 群組）

### 私訊存取
- 預設：`channels.telegram.dmPolicy = "pairing"`。未知發送者收到配對碼；訊息在批准前被忽略（代碼在 1 小時後過期）。
- 透過以下方式批准：
  - `openclaw pairing list telegram`
  - `openclaw pairing approve telegram <CODE>`
- 配對是用於 Telegram 私訊的預設令牌交換。詳情：[配對](/start/pairing)
- `channels.telegram.allowFrom` 接受數字用戶 ID（推薦）或 `@username` 項目。它**不是**機器人用戶名；使用人類發送者的 ID。精靈接受 `@username` 並在可能時將其解析為數字 ID。

#### 找到您的 Telegram 用戶 ID
更安全（無第三方機器人）：
1) 啟動 Gateway 並私訊您的機器人。
2) 執行 `openclaw logs --follow` 並查找 `from.id`。

替代方案（官方 Bot API）：
1) 私訊您的機器人。
2) 使用您的機器人令牌獲取更新並讀取 `message.from.id`：
   ```bash
   curl "https://api.telegram.org/bot<bot_token>/getUpdates"
   ```

第三方（較不私密）：
- 私訊 `@userinfobot` 或 `@getidsbot` 並使用返回的用戶 ID。

### 群組存取

兩個獨立的控制：

**1. 哪些群組被允許**（透過 `channels.telegram.groups` 的群組允許清單）：
- 無 `groups` 設定 = 所有群組被允許
- 有 `groups` 設定 = 只有列出的群組或 `"*"` 被允許
- 範例：`"groups": { "-1001234567890": {}, "*": {} }` 允許所有群組

**2. 哪些發送者被允許**（透過 `channels.telegram.groupPolicy` 的發送者過濾）：
- `"open"` = 允許群組中的所有發送者可以發訊息
- `"allowlist"` = 只有 `channels.telegram.groupAllowFrom` 中的發送者可以發訊息
- `"disabled"` = 完全不接受群組訊息
預設為 `groupPolicy: "allowlist"`（除非您新增 `groupAllowFrom` 否則被阻止）。

大多數用戶想要：`groupPolicy: "allowlist"` + `groupAllowFrom` + `channels.telegram.groups` 中列出的特定群組

## 長輪詢 vs webhook
- 預設：長輪詢（不需要公開 URL）。
- Webhook 模式：設定 `channels.telegram.webhookUrl`（可選 `channels.telegram.webhookSecret` + `channels.telegram.webhookPath`）。
  - 本地監聽器預設綁定到 `0.0.0.0:8787` 並服務 `POST /telegram-webhook`。
  - 如果您的公開 URL 不同，使用反向代理並將 `channels.telegram.webhookUrl` 指向公開端點。

## 回覆串連
Telegram 透過標籤支援可選的串連回覆：
- `[[reply_to_current]]` -- 回覆觸發訊息。
- `[[reply_to:<id>]]` -- 回覆特定訊息 ID。

由 `channels.telegram.replyToMode` 控制：
- `first`（預設）、`all`、`off`。

## 疑難排解

**機器人不回應群組中的非提及訊息：**
- 如果您設定 `channels.telegram.groups.*.requireMention=false`，Telegram 的 Bot API **隱私模式**必須停用。
  - BotFather：`/setprivacy` → **停用**（然後從群組移除 + 重新新增機器人）
- `openclaw channels status` 在設定預期未提及的群組訊息時顯示警告。
- `openclaw channels status --probe` 可以額外檢查明確數字群組 ID 的成員資格（它無法審計萬用字元 `"*"` 規則）。
- 快速測試：`/activation always`（僅會話；使用設定以持久化）

**機器人完全看不到群組訊息：**
- 如果設定了 `channels.telegram.groups`，群組必須被列出或使用 `"*"`
- 在 @BotFather 中檢查隱私設定 → 「群組隱私」應該**關閉**
- 驗證機器人確實是成員（不僅是沒有讀取權限的管理員）
- 檢查 Gateway 日誌：`openclaw logs --follow`（查找「skipping group message」）

**機器人回應提及但不回應 `/activation always`：**
- `/activation` 命令更新會話狀態但不會持久化到設定
- 對於持久行為，將群組新增到 `channels.telegram.groups` 並設定 `requireMention: false`

**像 `/status` 這樣的命令不起作用：**
- 確保您的 Telegram 用戶 ID 已授權（透過配對或 `channels.telegram.allowFrom`）
- 即使在 `groupPolicy: "open"` 的群組中，命令也需要授權

## 設定參考（Telegram）
完整設定：[設定](/gateway/configuration)

供應商選項：
- `channels.telegram.enabled`：啟用/停用頻道啟動。
- `channels.telegram.botToken`：機器人令牌（BotFather）。
- `channels.telegram.tokenFile`：從檔案路徑讀取令牌。
- `channels.telegram.dmPolicy`：`pairing | allowlist | open | disabled`（預設：pairing）。
- `channels.telegram.allowFrom`：私訊允許清單（ID/用戶名）。`open` 需要 `"*"`。
- `channels.telegram.groupPolicy`：`open | allowlist | disabled`（預設：allowlist）。
- `channels.telegram.groupAllowFrom`：群組發送者允許清單（ID/用戶名）。
- `channels.telegram.groups`：每群組預設 + 允許清單（使用 `"*"` 作為全域預設）。
- `channels.telegram.replyToMode`：`off | first | all`（預設：`first`）。
- `channels.telegram.textChunkLimit`：外發分塊大小（字元）。
- `channels.telegram.mediaMaxMb`：入站/外發媒體上限（MB）。
- `channels.telegram.webhookUrl`：啟用 webhook 模式。

相關全域選項：
- `agents.list[].groupChat.mentionPatterns`（提及閘門模式）。
- `messages.groupChat.mentionPatterns`（全域備選）。
- `commands.native`（預設為 `"auto"` → Telegram/Discord 開啟，Slack 關閉）。
