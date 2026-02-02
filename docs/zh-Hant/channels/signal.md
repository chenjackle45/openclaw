---
title: "Signal"
summary: "透過 signal-cli（JSON-RPC + SSE）的 Signal 支援、設定和號碼模型"
read_when:
  - 設定 Signal 支援
  - 除錯 Signal 發送/接收
---

# Signal（signal-cli）

狀態：外部 CLI 整合。Gateway 透過 HTTP JSON-RPC + SSE 與 `signal-cli` 通訊。

## 快速設定（初學者）

1. 為機器人使用**獨立的 Signal 號碼**（建議）。
2. 安裝 `signal-cli`（需要 Java）。
3. 連結機器人裝置並啟動守護程序：
   - `signal-cli link -n "OpenClaw"`
4. 設定 OpenClaw 並啟動 Gateway。

最小設定：

```json5
{
  channels: {
    signal: {
      enabled: true,
      account: "+15551234567",
      cliPath: "signal-cli",
      dmPolicy: "pairing",
      allowFrom: ["+15557654321"],
    },
  },
}
```

## 這是什麼

- 透過 `signal-cli` 的 Signal 頻道（非嵌入式 libsignal）。
- 確定性路由：回覆始終返回 Signal。
- 私訊共享代理的主會話；群組保持隔離（`agent:<agentId>:signal:group:<groupId>`）。

## 設定寫入

預設情況下，Signal 允許寫入由 `/config set|unset` 觸發的設定更新（需要 `commands.config: true`）。

停用方式：

```json5
{
  channels: { signal: { configWrites: false } },
}
```

## 號碼模型（重要）

- Gateway 連接到一個 **Signal 裝置**（`signal-cli` 帳戶）。
- 如果您在**個人 Signal 帳戶**上運行機器人，它會忽略您自己的訊息（循環保護）。
- 對於「我發訊息給機器人，它回覆」，使用**獨立的機器人號碼**。

## 設定（快速路徑）

1. 安裝 `signal-cli`（需要 Java）。
2. 連結機器人帳戶：
   - `signal-cli link -n "OpenClaw"` 然後在 Signal 中掃描 QR。
3. 設定 Signal 並啟動 Gateway。

範例：

```json5
{
  channels: {
    signal: {
      enabled: true,
      account: "+15551234567",
      cliPath: "signal-cli",
      dmPolicy: "pairing",
      allowFrom: ["+15557654321"],
    },
  },
}
```

多帳戶支援：使用 `channels.signal.accounts` 設定每個帳戶的設定和可選的 `name`。請參閱 [`gateway/configuration`](/gateway/configuration#telegramaccounts--discordaccounts--slackaccounts--signalaccounts--imessageaccounts) 了解共享模式。

## 外部守護程序模式（httpUrl）

如果您想自己管理 `signal-cli`（JVM 冷啟動慢、容器初始化或共享 CPU），單獨運行守護程序並將 OpenClaw 指向它：

```json5
{
  channels: {
    signal: {
      httpUrl: "http://127.0.0.1:8080",
      autoStart: false,
    },
  },
}
```

這跳過 OpenClaw 內的自動生成和啟動等待。對於自動生成時的慢啟動，設定 `channels.signal.startupTimeoutMs`。

## 存取控制（私訊 + 群組）

私訊：

- 預設：`channels.signal.dmPolicy = "pairing"`。
- 未知發送者收到配對碼；訊息在批准前被忽略（代碼在 1 小時後過期）。
- 透過以下方式批准：
  - `openclaw pairing list signal`
  - `openclaw pairing approve signal <CODE>`
- 配對是 Signal 私訊的預設令牌交換。詳情：[配對](/start/pairing)
- 僅 UUID 的發送者（來自 `sourceUuid`）在 `channels.signal.allowFrom` 中儲存為 `uuid:<id>`。

群組：

- `channels.signal.groupPolicy = open | allowlist | disabled`。
- 當設定 `allowlist` 時，`channels.signal.groupAllowFrom` 控制誰可以在群組中觸發。

## 運作方式（行為）

- `signal-cli` 作為守護程序運行；Gateway 透過 SSE 讀取事件。
- 入站訊息被正規化為共享頻道信封。
- 回覆始終路由回同一個號碼或群組。

## 媒體 + 限制

- 外發文字分塊至 `channels.signal.textChunkLimit`（預設 4000）。
- 可選的換行分塊：設定 `channels.signal.chunkMode="newline"` 在長度分塊前在空白行（段落邊界）分割。
- 支援附件（從 `signal-cli` 獲取 base64）。
- 預設媒體上限：`channels.signal.mediaMaxMb`（預設 8）。
- 使用 `channels.signal.ignoreAttachments` 跳過下載媒體。
- 群組歷史上下文使用 `channels.signal.historyLimit`（或 `channels.signal.accounts.*.historyLimit`），回退到 `messages.groupChat.historyLimit`。設定 `0` 停用（預設 50）。

## 輸入指示器 + 已讀回執

- **輸入指示器**：OpenClaw 透過 `signal-cli sendTyping` 發送輸入信號，並在回覆運行時刷新它們。
- **已讀回執**：當 `channels.signal.sendReadReceipts` 為 true 時，OpenClaw 為允許的私訊轉發已讀回執。
- Signal-cli 不公開群組的已讀回執。

## 反應（訊息工具）

- 使用 `message action=react` 並設定 `channel=signal`。
- 目標：發送者 E.164 或 UUID（使用配對輸出中的 `uuid:<id>`；裸 UUID 也可以）。
- `messageId` 是您要反應的訊息的 Signal 時間戳記。
- 群組反應需要 `targetAuthor` 或 `targetAuthorUuid`。

範例：

```
message action=react channel=signal target=uuid:123e4567-e89b-12d3-a456-426614174000 messageId=1737630212345 emoji=🔥
message action=react channel=signal target=+15551234567 messageId=1737630212345 emoji=🔥 remove=true
message action=react channel=signal target=signal:group:<groupId> targetAuthor=uuid:<sender-uuid> messageId=1737630212345 emoji=✅
```

設定：

- `channels.signal.actions.reactions`：啟用/停用反應動作（預設 true）。
- `channels.signal.reactionLevel`：`off | ack | minimal | extensive`。
  - `off`/`ack` 停用代理反應（訊息工具 `react` 會報錯）。
  - `minimal`/`extensive` 啟用代理反應並設定指導級別。
- 每帳戶覆寫：`channels.signal.accounts.<id>.actions.reactions`、`channels.signal.accounts.<id>.reactionLevel`。

## 交付目標（CLI/cron）

- 私訊：`signal:+15551234567`（或純 E.164）。
- UUID 私訊：`uuid:<id>`（或裸 UUID）。
- 群組：`signal:group:<groupId>`。
- 用戶名：`username:<name>`（如果您的 Signal 帳戶支援）。

## 設定參考（Signal）

完整設定：[設定](/gateway/configuration)

供應商選項：

- `channels.signal.enabled`：啟用/停用頻道啟動。
- `channels.signal.account`：機器人帳戶的 E.164。
- `channels.signal.cliPath`：`signal-cli` 的路徑。
- `channels.signal.httpUrl`：完整守護程序 URL（覆寫 host/port）。
- `channels.signal.httpHost`、`channels.signal.httpPort`：守護程序綁定（預設 127.0.0.1:8080）。
- `channels.signal.autoStart`：自動生成守護程序（如果 `httpUrl` 未設定則預設 true）。
- `channels.signal.startupTimeoutMs`：啟動等待逾時（毫秒）（上限 120000）。
- `channels.signal.receiveMode`：`on-start | manual`。
- `channels.signal.ignoreAttachments`：跳過附件下載。
- `channels.signal.ignoreStories`：忽略來自守護程序的限時動態。
- `channels.signal.sendReadReceipts`：轉發已讀回執。
- `channels.signal.dmPolicy`：`pairing | allowlist | open | disabled`（預設：pairing）。
- `channels.signal.allowFrom`：私訊允許清單（E.164 或 `uuid:<id>`）。`open` 需要 `"*"`。Signal 沒有用戶名；使用電話/UUID ID。
- `channels.signal.groupPolicy`：`open | allowlist | disabled`（預設：allowlist）。
- `channels.signal.groupAllowFrom`：群組發送者允許清單。
- `channels.signal.historyLimit`：作為上下文包含的最大群組訊息數（0 停用）。
- `channels.signal.dmHistoryLimit`：用戶輪次中的私訊歷史限制。每用戶覆寫：`channels.signal.dms["<phone_or_uuid>"].historyLimit`。
- `channels.signal.textChunkLimit`：外發分塊大小（字元）。
- `channels.signal.chunkMode`：`length`（預設）或 `newline` 在長度分塊前在空白行（段落邊界）分割。
- `channels.signal.mediaMaxMb`：入站/外發媒體上限（MB）。

相關全域選項：

- `agents.list[].groupChat.mentionPatterns`（Signal 不支援原生提及）。
- `messages.groupChat.mentionPatterns`（全域備選）。
- `messages.responsePrefix`。
