---
summary: "iMessage support via imsg (JSON-RPC over stdio), setup, and chat_id routing"
read_when:
  - Setting up iMessage support
  - Debugging iMessage send/receive
title: iMessage
---

# iMessage (imsg)

狀態：外部 CLI 整合。Gateway 生成 `imsg rpc`（JSON-RPC over stdio）。

## 快速設定（初學者）

1. 確保此 Mac 上的訊息應用程式已登入。
2. 安裝 `imsg`：
   - `brew install steipete/tap/imsg`
3. 使用 `channels.imessage.cliPath` 和 `channels.imessage.dbPath` 設定 OpenClaw。
4. 啟動 Gateway 並批准任何 macOS 提示（自動化 + 完全磁碟存取）。

最小設定：

```json5
{
  channels: {
    imessage: {
      enabled: true,
      cliPath: "/usr/local/bin/imsg",
      dbPath: "/Users/<you>/Library/Messages/chat.db",
    },
  },
}
```

## 這是什麼

- iMessage 頻道由 macOS 上的 `imsg` 支援。
- 確定性路由：回覆始終返回 iMessage。
- DM 共享代理的主會話；群組被隔離（`agent:<agentId>:imessage:group:<chat_id>`）。
- 如果多參與者討論串以 `is_group=false` 到達，您仍然可以使用 `channels.imessage.groups` 按 `chat_id` 隔離它（見下面的「類群組討論串」）。

## 設定寫入

預設情況下，iMessage 允許寫入由 `/config set|unset` 觸發的設定更新（需要 `commands.config: true`）。

使用以下方式停用：

```json5
{
  channels: { imessage: { configWrites: false } },
}
```

## 需求

- 已登入訊息的 macOS。
- OpenClaw + `imsg` 的完全磁碟存取（訊息資料庫存取）。
- 發送時的自動化權限。
- `channels.imessage.cliPath` 可以指向任何代理 stdin/stdout 的命令（例如，透過 SSH 連接到另一台 Mac 並執行 `imsg rpc` 的包裝指令碼）。

## 設定（快速路徑）

1. 確保此 Mac 上的訊息應用程式已登入。
2. 設定 iMessage 並啟動 Gateway。

### 專用 Bot macOS 使用者（用於隔離身份）

如果您想讓 Bot 從**獨立的 iMessage 身份**發送（並保持個人訊息乾淨），使用專用的 Apple ID + 專用的 macOS 使用者。

1. 建立專用的 Apple ID（例如：`my-cool-bot@icloud.com`）。
   - Apple 可能需要電話號碼進行驗證 / 2FA。
2. 建立 macOS 使用者（例如：`openclawhome`）並登入。
3. 在該 macOS 使用者中開啟訊息並使用 Bot Apple ID 登入 iMessage。
4. 啟用遠端登入（系統設定 → 一般 → 共享 → 遠端登入）。
5. 安裝 `imsg`：
   - `brew install steipete/tap/imsg`
6. 設定 SSH 使 `ssh <bot-macos-user>@localhost true` 無需密碼即可運作。
7. 將 `channels.imessage.accounts.bot.cliPath` 指向以 Bot 使用者身份執行 `imsg` 的 SSH 包裝器。

首次執行注意事項：發送/接收可能需要在 _Bot macOS 使用者_ 中的 GUI 批准（自動化 + 完全磁碟存取）。如果 `imsg rpc` 看起來卡住或退出，請登入該使用者（螢幕共享有幫助），執行一次 `imsg chats --limit 1` / `imsg send ...`，批准提示，然後重試。

範例包裝器（`chmod +x`）。將 `<bot-macos-user>` 替換為您的實際 macOS 使用者名：

```bash
#!/usr/bin/env bash
set -euo pipefail

# 首先執行一次互動式 SSH 以接受主機金鑰：
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
          dbPath: "/Users/<bot-macos-user>/Library/Messages/chat.db",
        },
      },
    },
  },
}
```

對於單帳戶設定，使用扁平選項（`channels.imessage.cliPath`、`channels.imessage.dbPath`）而不是 `accounts` 對應。

### 遠端/SSH 變體（選用）

如果您想在另一台 Mac 上使用 iMessage，將 `channels.imessage.cliPath` 設為透過 SSH 在遠端 macOS 主機上執行 `imsg` 的包裝器。OpenClaw 只需要 stdio。

範例包裝器：

```bash
#!/usr/bin/env bash
exec ssh -T gateway-host imsg "$@"
```

**遠端附件：** 當 `cliPath` 透過 SSH 指向遠端主機時，訊息資料庫中的附件路徑引用遠端機器上的檔案。OpenClaw 可以透過設定 `channels.imessage.remoteHost` 自動透過 SCP 提取這些檔案：

```json5
{
  channels: {
    imessage: {
      cliPath: "~/imsg-ssh", // SSH 包裝器至遠端 Mac
      remoteHost: "user@gateway-host", // 用於 SCP 檔案傳輸
      includeAttachments: true,
    },
  },
}
```

如果未設定 `remoteHost`，OpenClaw 嘗試透過解析包裝指令碼中的 SSH 命令來自動偵測它。建議明確設定以確保可靠性。

#### 透過 Tailscale 的遠端 Mac（範例）

如果 Gateway 在 Linux 主機/VM 上執行但 iMessage 必須在 Mac 上執行，Tailscale 是最簡單的橋樑：Gateway 透過 Tailnet 與 Mac 通訊、透過 SSH 執行 `imsg`，以及透過 SCP 返回附件。

架構：

```
┌──────────────────────────────┐          SSH (imsg rpc)          ┌──────────────────────────┐
│ Gateway 主機 (Linux/VM)       │──────────────────────────────────▶│ Mac with Messages + imsg │
│ - openclaw gateway           │          SCP (attachments)        │ - 訊息已登入             │
│ - channels.imessage.cliPath  │◀──────────────────────────────────│ - 遠端登入已啟用         │
└──────────────────────────────┘                                   └──────────────────────────┘
              ▲
              │ Tailscale tailnet (hostname or 100.x.y.z)
              ▼
        user@gateway-host
```

具體設定範例（Tailscale 主機名稱）：

```json5
{
  channels: {
    imessage: {
      enabled: true,
      cliPath: "~/.openclaw/scripts/imsg-ssh",
      remoteHost: "bot@mac-mini.tailnet-1234.ts.net",
      includeAttachments: true,
      dbPath: "/Users/bot/Library/Messages/chat.db",
    },
  },
}
```

範例包裝器（`~/.openclaw/scripts/imsg-ssh`）：

```bash
#!/usr/bin/env bash
exec ssh -T bot@mac-mini.tailnet-1234.ts.net imsg "$@"
```

注意：

- 確保 Mac 已登入訊息，且遠端登入已啟用。
- 使用 SSH 金鑰使 `ssh bot@mac-mini.tailnet-1234.ts.net` 無需提示即可運作。
- `remoteHost` 應與 SSH 目標相符以便 SCP 可以提取附件。

多帳戶支援：使用 `channels.imessage.accounts` 進行每帳戶設定和選用的 `name`。見 [`gateway/configuration`](/gateway/configuration#telegramaccounts--discordaccounts--slackaccounts--signalaccounts--imessageaccounts) 以了解共享模式。不要提交 `~/.openclaw/openclaw.json`（它通常包含令牌）。

## 存取控制（DM + 群組）

DM：

- 預設：`channels.imessage.dmPolicy = "pairing"`。
- 未知發送者收到配對碼；訊息被忽略直到批准（碼在 1 小時後過期）。
- 透過以下方式批准：
  - `openclaw pairing list imessage`
  - `openclaw pairing approve imessage <CODE>`
- 配對是 iMessage DM 的預設令牌交換。詳情：[配對](/start/pairing)

群組：

- `channels.imessage.groupPolicy = open | allowlist | disabled`。
- 當設定 `allowlist` 時，`channels.imessage.groupAllowFrom` 控制誰可以在群組中觸發。
- 提及閘門使用 `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`），因為 iMessage 沒有原生提及中繼資料。
- 多代理覆蓋：在 `agents.list[].groupChat.mentionPatterns` 上設定每代理模式。

## 運作方式（行為）

- `imsg` 串流訊息事件；Gateway 將它們正規化為共享頻道信封。
- 回覆始終路由回相同的 chat id 或 handle。

## 類群組討論串（`is_group=false`）

某些 iMessage 討論串可以有多個參與者但仍以 `is_group=false` 到達，取決於訊息儲存聊天識別碼的方式。

如果您在 `channels.imessage.groups` 下明確設定 `chat_id`，OpenClaw 對下列項目將該討論串視為「群組」：

- 會話隔離（獨立的 `agent:<agentId>:imessage:group:<chat_id>` 會話金鑰）
- 群組允許清單 / 提及閘門行為

範例：

```json5
{
  channels: {
    imessage: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15555550123"],
      groups: {
        "42": { requireMention: false },
      },
    },
  },
}
```

當您想要為特定討論串使用隔離的個性/模型時很有用（見[多代理路由](/concepts/multi-agent)）。對於檔案系統隔離，見[沙盒](/gateway/sandboxing)。

## 媒體 + 限制

- 透過 `channels.imessage.includeAttachments` 進行選用的附件攝取。
- 透過 `channels.imessage.mediaMaxMb` 設定媒體上限。

## 限制

- 外發文字分塊至 `channels.imessage.textChunkLimit`（預設 4000）。
- 選用的換行分塊：設定 `channels.imessage.chunkMode="newline"` 在長度分塊前在空白行（段落邊界）分割。
- 媒體上傳由 `channels.imessage.mediaMaxMb` 限制（預設 16）。

## 尋址 / 交付目標

偏好使用 `chat_id` 進行穩定路由：

- `chat_id:123`（首選）
- `chat_guid:...`
- `chat_identifier:...`
- 直接 handle：`imessage:+1555` / `sms:+1555` / `user@example.com`

列出聊天：

```
imsg chats --limit 20
```

## 設定參考 (iMessage)

完整設定：[設定](/gateway/configuration)

提供商選項：

- `channels.imessage.enabled`：啟用/停用頻道啟動。
- `channels.imessage.cliPath`：路徑至 `imsg`。
- `channels.imessage.dbPath`：訊息資料庫路徑。
- `channels.imessage.remoteHost`：當 `cliPath` 指向遠端 Mac 時用於 SCP 附件傳輸的 SSH 主機（例如 `user@gateway-host`）。如果未設定則從 SSH 包裝器自動偵測。
- `channels.imessage.service`：`imessage | sms | auto`。
- `channels.imessage.region`：SMS 區域。
- `channels.imessage.dmPolicy`：`pairing | allowlist | open | disabled`（預設：pairing）。
- `channels.imessage.allowFrom`：DM 允許清單（handle、電子郵件、E.164 號碼或 `chat_id:*`）。`open` 需要 `"*"`。iMessage 沒有使用者名稱；使用 handle 或聊天目標。
- `channels.imessage.groupPolicy`：`open | allowlist | disabled`（預設：allowlist）。
- `channels.imessage.groupAllowFrom`：群組發送者允許清單。
- `channels.imessage.historyLimit` / `channels.imessage.accounts.*.historyLimit`：作為上下文包含的最大群組訊息（0 停用）。
- `channels.imessage.dmHistoryLimit`：使用者輪次中的 DM 歷史限制。每使用者覆蓋：`channels.imessage.dms["<handle>"].historyLimit`。
- `channels.imessage.groups`：每群組預設 + 允許清單（使用 `"*"` 作為全域預設）。
- `channels.imessage.includeAttachments`：將附件攝取至上下文中。
- `channels.imessage.mediaMaxMb`：入站/外發媒體上限 (MB)。
- `channels.imessage.textChunkLimit`：外發分塊大小（字元）。
- `channels.imessage.chunkMode`：`length`（預設）或 `newline` 在長度分塊前在空白行（段落邊界）分割。

相關全域選項：

- `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）。
- `messages.responsePrefix`。
