---
title: "Imessage(iMessage imsg)"
summary: "透過 imsg（stdin 上的 JSON-RPC）的 iMessage 支援、設定和 chat_id 路由"
read_when:
  - 設定 iMessage 支援
  - 除錯 iMessage 發送/接收
---
# iMessage（imsg）


狀態：外部 CLI 整合。Gateway 生成 `imsg rpc`（stdin 上的 JSON-RPC）。

## 快速設定（初學者）
1) 確保此 Mac 上的訊息應用程式已登入。
2) 安裝 `imsg`：
   - `brew install steipete/tap/imsg`
3) 使用 `channels.imessage.cliPath` 和 `channels.imessage.dbPath` 設定 OpenClaw。
4) 啟動 Gateway 並批准任何 macOS 提示（自動化 + 完全磁碟存取）。

最小設定：
```json5
{
  channels: {
    imessage: {
      enabled: true,
      cliPath: "/usr/local/bin/imsg",
      dbPath: "/Users/<you>/Library/Messages/chat.db"
    }
  }
}
```

## 這是什麼
- macOS 上由 `imsg` 支援的 iMessage 頻道。
- 確定性路由：回覆始終返回 iMessage。
- 私訊共享代理的主會話；群組保持隔離（`agent:<agentId>:imessage:group:<chat_id>`）。
- 如果多參與者討論串以 `is_group=false` 到達，您仍然可以使用 `channels.imessage.groups` 按 `chat_id` 隔離它（請參閱下面的「類群組討論串」）。

## 設定寫入
預設情況下，iMessage 允許寫入由 `/config set|unset` 觸發的設定更新（需要 `commands.config: true`）。

使用以下方式停用：
```json5
{
  channels: { imessage: { configWrites: false } }
}
```

## 要求
- 已登入訊息的 macOS。
- OpenClaw + `imsg` 的完全磁碟存取（訊息資料庫存取）。
- 發送時的自動化權限。
- `channels.imessage.cliPath` 可以指向任何代理 stdin/stdout 的命令（例如，透過 SSH 連接到另一台 Mac 並運行 `imsg rpc` 的包裝腳本）。

## 設定（快速路徑）
1) 確保此 Mac 上的訊息應用程式已登入。
2) 設定 iMessage 並啟動 Gateway。

### 專用機器人 macOS 用戶（用於隔離身份）
如果您想讓機器人從**獨立的 iMessage 身份**發送（並保持個人訊息乾淨），請使用專用的 Apple ID + 專用的 macOS 用戶。

1) 建立專用的 Apple ID（範例：`my-cool-bot@icloud.com`）。
   - Apple 可能需要電話號碼進行驗證 / 2FA。
2) 建立 macOS 用戶（範例：`openclawhome`）並登入。
3) 在該 macOS 用戶中開啟訊息並使用機器人 Apple ID 登入 iMessage。
4) 啟用遠端登入（系統設定 → 一般 → 共享 → 遠端登入）。
5) 安裝 `imsg`：
   - `brew install steipete/tap/imsg`
6) 設定 SSH 使 `ssh <bot-macos-user>@localhost true` 無需密碼即可運作。
7) 將 `channels.imessage.accounts.bot.cliPath` 指向一個以機器人用戶身份運行 `imsg` 的 SSH 包裝器。

首次運行備註：發送/接收可能需要*機器人 macOS 用戶*中的 GUI 批准（自動化 + 完全磁碟存取）。如果 `imsg rpc` 看起來卡住或退出，請登入該用戶（螢幕共享有幫助），運行一次 `imsg chats --limit 1` / `imsg send ...`，批准提示，然後重試。

範例包裝器（`chmod +x`）。將 `<bot-macos-user>` 替換為您的實際 macOS 用戶名：
```bash
#!/usr/bin/env bash
set -euo pipefail

# 首先運行一次互動式 SSH 以接受主機金鑰：
#   ssh <bot-macos-user>@localhost true
exec /usr/bin/ssh -o BatchMode=yes -o ConnectTimeout=5 -T <bot-macos-user>@localhost \
  "/usr/local/bin/imsg" "$@"
```

範例設定：
```json5
{
  channels: {
    imessage: {
      enabled: true,
      accounts: {
        bot: {
          name: "Bot",
          enabled: true,
          cliPath: "/path/to/imsg-bot",
          dbPath: "/Users/<bot-macos-user>/Library/Messages/chat.db"
        }
      }
    }
  }
}
```

對於單帳戶設定，使用扁平選項（`channels.imessage.cliPath`、`channels.imessage.dbPath`）而不是 `accounts` 映射。

### 遠端/SSH 變體（可選）
如果您想在另一台 Mac 上使用 iMessage，將 `channels.imessage.cliPath` 設為透過 SSH 在遠端 macOS 主機上運行 `imsg` 的包裝器。OpenClaw 只需要 stdio。

範例包裝器：
```bash
#!/usr/bin/env bash
exec ssh -T gateway-host imsg "$@"
```

**遠端附件：** 當 `cliPath` 透過 SSH 指向遠端主機時，訊息資料庫中的附件路徑引用遠端機器上的檔案。OpenClaw 可以透過設定 `channels.imessage.remoteHost` 自動透過 SCP 獲取這些：

```json5
{
  channels: {
    imessage: {
      cliPath: "~/imsg-ssh",                     // 到遠端 Mac 的 SSH 包裝器
      remoteHost: "user@gateway-host",           // 用於 SCP 檔案傳輸
      includeAttachments: true
    }
  }
}
```

如果未設定 `remoteHost`，OpenClaw 嘗試透過解析包裝腳本中的 SSH 命令來自動檢測它。建議明確設定以確保可靠性。

多帳戶支援：使用 `channels.imessage.accounts` 設定每個帳戶的設定和可選的 `name`。請參閱 [`gateway/configuration`](/gateway/configuration#telegramaccounts--discordaccounts--slackaccounts--signalaccounts--imessageaccounts) 了解共享模式。不要提交 `~/.openclaw/openclaw.json`（它通常包含令牌）。

## 存取控制（私訊 + 群組）
私訊：
- 預設：`channels.imessage.dmPolicy = "pairing"`。
- 未知發送者收到配對碼；訊息在批准前被忽略（代碼在 1 小時後過期）。
- 透過以下方式批准：
  - `openclaw pairing list imessage`
  - `openclaw pairing approve imessage <CODE>`
- 配對是 iMessage 私訊的預設令牌交換。詳情：[配對](/start/pairing)

群組：
- `channels.imessage.groupPolicy = open | allowlist | disabled`。
- 當設定 `allowlist` 時，`channels.imessage.groupAllowFrom` 控制誰可以在群組中觸發。
- 提及閘門使用 `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`），因為 iMessage 沒有原生提及元資料。
- 多代理覆寫：在 `agents.list[].groupChat.mentionPatterns` 上設定每代理模式。

## 運作方式（行為）
- `imsg` 串流訊息事件；Gateway 將它們正規化為共享頻道信封。
- 回覆始終路由回同一個 chat id 或 handle。

## 類群組討論串（`is_group=false`）
根據訊息儲存聊天識別碼的方式，某些 iMessage 討論串可以有多個參與者但仍以 `is_group=false` 到達。

如果您在 `channels.imessage.groups` 下明確設定 `chat_id`，OpenClaw 會將該討論串視為「群組」用於：
- 會話隔離（獨立的 `agent:<agentId>:imessage:group:<chat_id>` 會話鍵）
- 群組允許清單 / 提及閘門行為

範例：
```json5
{
  channels: {
    imessage: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15555550123"],
      groups: {
        "42": { "requireMention": false }
      }
    }
  }
}
```
當您想要為特定討論串使用隔離的個性/模型時這很有用（請參閱 [多代理路由](/concepts/multi-agent)）。對於檔案系統隔離，請參閱 [沙盒](/gateway/sandboxing)。

## 媒體 + 限制
- 透過 `channels.imessage.includeAttachments` 進行可選的附件攝取。
- 透過 `channels.imessage.mediaMaxMb` 設定媒體上限。

## 限制
- 外發文字分塊至 `channels.imessage.textChunkLimit`（預設 4000）。
- 可選的換行分塊：設定 `channels.imessage.chunkMode="newline"` 在長度分塊前在空白行（段落邊界）分割。
- 媒體上傳由 `channels.imessage.mediaMaxMb` 限制（預設 16）。

## 地址 / 交付目標
優先使用 `chat_id` 進行穩定路由：
- `chat_id:123`（首選）
- `chat_guid:...`
- `chat_identifier:...`
- 直接 handle：`imessage:+1555` / `sms:+1555` / `user@example.com`

列出聊天：
```
imsg chats --limit 20
```

## 設定參考（iMessage）
完整設定：[設定](/gateway/configuration)

供應商選項：
- `channels.imessage.enabled`：啟用/停用頻道啟動。
- `channels.imessage.cliPath`：`imsg` 的路徑。
- `channels.imessage.dbPath`：訊息資料庫路徑。
- `channels.imessage.remoteHost`：當 `cliPath` 指向遠端 Mac 時用於 SCP 附件傳輸的 SSH 主機（例如 `user@gateway-host`）。如果未設定則從 SSH 包裝器自動檢測。
- `channels.imessage.service`：`imessage | sms | auto`。
- `channels.imessage.region`：SMS 區域。
- `channels.imessage.dmPolicy`：`pairing | allowlist | open | disabled`（預設：pairing）。
- `channels.imessage.allowFrom`：私訊允許清單（handle、電子郵件、E.164 號碼或 `chat_id:*`）。`open` 需要 `"*"`。iMessage 沒有用戶名；使用 handle 或聊天目標。
- `channels.imessage.groupPolicy`：`open | allowlist | disabled`（預設：allowlist）。
- `channels.imessage.groupAllowFrom`：群組發送者允許清單。
- `channels.imessage.historyLimit` / `channels.imessage.accounts.*.historyLimit`：作為上下文包含的最大群組訊息數（0 停用）。
- `channels.imessage.dmHistoryLimit`：用戶輪次中的私訊歷史限制。每用戶覆寫：`channels.imessage.dms["<handle>"].historyLimit`。
- `channels.imessage.groups`：每群組預設 + 允許清單（使用 `"*"` 作為全域預設）。
- `channels.imessage.includeAttachments`：將附件攝取到上下文中。
- `channels.imessage.mediaMaxMb`：入站/外發媒體上限（MB）。
- `channels.imessage.textChunkLimit`：外發分塊大小（字元）。
- `channels.imessage.chunkMode`：`length`（預設）或 `newline` 在長度分塊前在空白行（段落邊界）分割。

相關全域選項：
- `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）。
- `messages.responsePrefix`。
