---
summary: "透過 BlueBubbles macOS 伺服器的 iMessage（REST 傳送/接收、輸入狀態、反應、配對、進階操作）。"
read_when:
  - 設定 BlueBubbles 頻道
  - 針對 webhook 配對進行故障排除
  - 在 macOS 上設定 iMessage
title: "BlueBubbles（macOS REST 整合）"
---

# BlueBubbles (macOS REST)

狀態：綑綁外掛程式，透過 HTTP 與 BlueBubbles macOS 伺服器通訊。**建議用於 iMessage 整合**，因為其 API 更豐富，相比舊版 imsg 頻道設定更簡單。

## 概述

- 透過 BlueBubbles 協助應用程式在 macOS 上運行（[bluebubbles.app](https://bluebubbles.app)）。
- 建議/測試：macOS Sequoia (15)。macOS Tahoe (26) 可運行，但編輯目前在 Tahoe 上損壞，群組圖示更新可能顯示成功但不會同步。
- OpenClaw 透過其 REST API 與其通訊（`GET /api/v1/ping`、`POST /message/text`、`POST /chat/:id/*`）。
- 傳入訊息透過 webhook 到達；傳出回覆、輸入指示、讀取回條和 tapback 是 REST 呼叫。
- 附件和貼紙被作為傳入媒體被接收（並在可能時向代理呈現）。
- 配對/允許清單的運作方式與其他頻道相同（`/channels/pairing` 等），使用 `channels.bluebubbles.allowFrom` + 配對代碼。
- 反應被作為系統事件呈現，就像 Slack/Telegram，因此代理可以在回覆前「提及」它們。
- 進階功能：編輯、取消傳送、回覆執行緒、訊息效果、群組管理。

## 快速開始

1. 在您的 Mac 上安裝 BlueBubbles 伺服器（按照 [bluebubbles.app/install](https://bluebubbles.app/install) 的說明進行）。
2. 在 BlueBubbles 設定中，啟用 Web API 並設定密碼。
3. 執行 `openclaw onboard` 並選擇 BlueBubbles，或手動設定：

   ```json5
   {
     channels: {
       bluebubbles: {
         enabled: true,
         serverUrl: "http://192.168.1.100:1234",
         password: "example-password",
         webhookPath: "/bluebubbles-webhook",
       },
     },
   }
   ```

4. 指向 BlueBubbles webhook 到您的 Gateway（例如：`https://your-gateway-host:3000/bluebubbles-webhook?password=<password>`）。
5. 啟動 Gateway；它將註冊 webhook 處理程式並開始配對。

安全性提示：

- 一律設定 webhook 密碼。
- Webhook 驗證一律必要。OpenClaw 拒絕 BlueBubbles webhook 請求，除非包含與 `channels.bluebubbles.password` 相符的密碼/guid（例如 `?password=<password>` 或 `x-password`），無論循環/代理拓撲如何。
- 密碼驗證在讀取/解析完整 webhook 本體前進行檢查。

## 保持 Messages.app 運作（VM / 無頭設定）

某些 macOS VM / 常開設定可能導致 Messages.app 進入「閒置」狀態（傳入事件停止，直到應用程式被開啟/前景化）。簡單的解決方案是**每 5 分鐘戳一下 Messages**，使用 AppleScript + LaunchAgent。

### 1) 儲存 AppleScript

儲存為：

- `~/Scripts/poke-messages.scpt`

範例指令碼（非互動式；不會竊取焦點）：

```applescript
try
  tell application "Messages"
    if not running then
      launch
    end if

    -- 觸及指令碼介面以保持程序回應。
    set _chatCount to (count of chats)
  end tell
on error
  -- 忽略暫時性故障（初次執行提示、鎖定會話等）。
end try
```

### 2) 安裝 LaunchAgent

儲存為：

- `~/Library/LaunchAgents/com.user.poke-messages.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.user.poke-messages</string>

    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string>
      <string>-lc</string>
      <string>/usr/bin/osascript &quot;$HOME/Scripts/poke-messages.scpt&quot;</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>StartInterval</key>
    <integer>300</integer>

    <key>StandardOutPath</key>
    <string>/tmp/poke-messages.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/poke-messages.err</string>
  </dict>
</plist>
```

注意：

- 這每 **300 秒**和**登入時**運行。
- 首次執行可能觸發 macOS **自動化**提示（`osascript` → Messages）。在執行 LaunchAgent 的相同使用者會話中批准它們。

載入它：

```bash
launchctl unload ~/Library/LaunchAgents/com.user.poke-messages.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/com.user.poke-messages.plist
```

## 上線過程

BlueBubbles 在互動式設定精靈中可用：

```
openclaw onboard
```

精靈提示：

- **Server URL**（必要）：BlueBubbles 伺服器地址（例如，`http://192.168.1.100:1234`）
- **密碼**（必要）：來自 BlueBubbles Server 設定的 API 密碼
- **Webhook 路徑**（選用）：預設為 `/bluebubbles-webhook`
- **DM 政策**：配對、允許清單、開放或禁用
- **允許清單**：電話號碼、電子郵件或聊天目標

您也可以透過 CLI 新增 BlueBubbles：

```
openclaw channels add bluebubbles --http-url http://192.168.1.100:1234 --password <password>
```

## 存取控制（DM + 群組）

DM：

- 預設：`channels.bluebubbles.dmPolicy = "pairing"`。
- 未知傳送者接收配對代碼；訊息被忽略，直到被核准（代碼在 1 小時後過期）。
- 透過以下方式批准：
  - `openclaw pairing list bluebubbles`
  - `openclaw pairing approve bluebubbles <CODE>`
- 配對是預設的 Token 交換。詳細資訊：[配對](/zh-Hant/channels/pairing)

群組：

- `channels.bluebubbles.groupPolicy = open | allowlist | disabled`（預設：`allowlist`）。
- `channels.bluebubbles.groupAllowFrom` 控制當設定 `allowlist` 時誰可以在群組中觸發。

### 提及把關（群組）

BlueBubbles 支援群組聊天的提及把關，符合 iMessage/WhatsApp 行為：

- 使用 `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）來偵測提及。
- 當為群組啟用 `requireMention` 時，代理僅在被提及時回應。
- 來自授權傳送者的控制命令繞過提及把關。

每個群組設定：

```json5
{
  channels: {
    bluebubbles: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15555550123"],
      groups: {
        "*": { requireMention: true }, // 所有群組的預設
        "iMessage;-;chat123": { requireMention: false }, // 特定群組的覆蓋
      },
    },
  },
}
```

### 命令把關

- 控制命令（例如，`/config`、`/model`）需要授權。
- 使用 `allowFrom` 和 `groupAllowFrom` 來決定命令授權。
- 授權傳送者可以執行控制命令，即使在群組中沒有提及。

## 輸入狀態 + 讀取回條

- **輸入指示**：在回應產生前和期間自動傳送。
- **讀取回條**：由 `channels.bluebubbles.sendReadReceipts` 控制（預設：`true`）。
- **輸入指示**：OpenClaw 傳送輸入開始事件；BlueBubbles 在傳送或逾時時自動清除輸入（透過 DELETE 的手動停止不可靠）。

```json5
{
  channels: {
    bluebubbles: {
      sendReadReceipts: false, // 停用讀取回條
    },
  },
}
```

## 進階操作

當在設定中啟用時，BlueBubbles 支援進階訊息操作：

```json5
{
  channels: {
    bluebubbles: {
      actions: {
        reactions: true, // tapback（預設：true）
        edit: true, // 編輯傳送的訊息（macOS 13+，在 macOS 26 Tahoe 上損壞）
        unsend: true, // 取消傳送訊息（macOS 13+）
        reply: true, // 按訊息 GUID 回覆執行緒
        sendWithEffect: true, // 訊息效果（slam、loud 等）
        renameGroup: true, // 重新命名群組聊天
        setGroupIcon: true, // 設定群組聊天圖示/照片（在 macOS 26 Tahoe 上不穩定）
        addParticipant: true, // 將參與者新增到群組
        removeParticipant: true, // 從群組中移除參與者
        leaveGroup: true, // 離開群組聊天
        sendAttachment: true, // 傳送附件/媒體
      },
    },
  },
}
```

可用的操作：

- **react**：新增/移除 tapback 反應（`messageId`、`emoji`、`remove`）
- **edit**：編輯傳送的訊息（`messageId`、`text`）
- **unsend**：取消傳送訊息（`messageId`）
- **reply**：回覆特定訊息（`messageId`、`text`、`to`）
- **sendWithEffect**：使用 iMessage 效果傳送（`text`、`to`、`effectId`）
- **renameGroup**：重新命名群組聊天（`chatGuid`、`displayName`）
- **setGroupIcon**：設定群組聊天的圖示/照片（`chatGuid`、`media`）— 在 macOS 26 Tahoe 上不穩定（API 可能返回成功但圖示不同步）。
- **addParticipant**：將某人新增到群組（`chatGuid`、`address`）
- **removeParticipant**：從群組中移除某人（`chatGuid`、`address`）
- **leaveGroup**：離開群組聊天（`chatGuid`）
- **sendAttachment**：傳送媒體/檔案（`to`、`buffer`、`filename`、`asVoice`）
  - 語音備忘錄：使用 **MP3** 或 **CAF** 音訊設定 `asVoice: true` 以作為 iMessage 語音訊息傳送。BlueBubbles 在傳送語音備忘錄時將 MP3 → CAF。

### 訊息 ID（短 vs 完整）

OpenClaw 可能呈現*短*訊息 ID（例如，`1`、`2`）以節省 Token。

- `MessageSid` / `ReplyToId` 可以是短 ID。
- `MessageSidFull` / `ReplyToIdFull` 包含供應商完整 ID。
- 短 ID 在記憶體中；它們可能在重新啟動或快取驅逐時過期。
- 操作接受短或完整的 `messageId`，但如果短 ID 不再可用，將出現錯誤。

使用完整 ID 以用於持久自動化和儲存：

- 範本：`{{MessageSidFull}}`、`{{ReplyToIdFull}}`
- 上下文：傳入負載中的 `MessageSidFull` / `ReplyToIdFull`

參見[設定](/zh-Hant/gateway/configuration)以取得範本變數。

## 區塊串流

控制回應是否作為單個訊息傳送或以區塊串流：

```json5
{
  channels: {
    bluebubbles: {
      blockStreaming: true, // 啟用區塊串流（預設關閉）
    },
  },
}
```

## 媒體 + 限制

- 傳入附件被下載並儲存在媒體快取中。
- 媒體上限透過 `channels.bluebubbles.mediaMaxMb`（預設：8 MB）。
- 傳出文字被分割到 `channels.bluebubbles.textChunkLimit`（預設：4000 個字元）。

## 設定參考

完整設定：[設定](/zh-Hant/gateway/configuration)

供應商選項：

- `channels.bluebubbles.enabled`：啟用/停用頻道。
- `channels.bluebubbles.serverUrl`：BlueBubbles REST API 基礎 URL。
- `channels.bluebubbles.password`：API 密碼。
- `channels.bluebubbles.webhookPath`：Webhook 端點路徑（預設：`/bluebubbles-webhook`）。
- `channels.bluebubbles.dmPolicy`：`pairing | allowlist | open | disabled`（預設：`pairing`）。
- `channels.bluebubbles.allowFrom`：DM 允許清單（處理程序、電子郵件、E.164 號碼、`chat_id:*`、`chat_guid:*`）。
- `channels.bluebubbles.groupPolicy`：`open | allowlist | disabled`（預設：`allowlist`）。
- `channels.bluebubbles.groupAllowFrom`：群組傳送者允許清單。
- `channels.bluebubbles.groups`：每個群組設定（`requireMention` 等）。
- `channels.bluebubbles.sendReadReceipts`：傳送讀取回條（預設：`true`）。
- `channels.bluebubbles.blockStreaming`：啟用區塊串流（預設：`false`；串流回覆需要）。
- `channels.bluebubbles.textChunkLimit`：傳出區塊大小（字元）（預設：4000）。
- `channels.bluebubbles.chunkMode`：`length`（預設）僅在超過 `textChunkLimit` 時分割；`newline` 在長度分割前在空白行（段落邊界）分割。
- `channels.bluebubbles.mediaMaxMb`：傳入媒體上限（MB）（預設：8）。
- `channels.bluebubbles.mediaLocalRoots`：允許傳出本機媒體路徑的絕對本機目錄的明確允許清單。本機路徑傳送預設被拒絕，除非設定此項。每個帳戶覆蓋：`channels.bluebubbles.accounts.<accountId>.mediaLocalRoots`。
- `channels.bluebubbles.historyLimit`：上下文的最大群組訊息（0 停用）。
- `channels.bluebubbles.dmHistoryLimit`：DM 歷史限制。
- `channels.bluebubbles.actions`：啟用/停用特定操作。
- `channels.bluebubbles.accounts`：多帳戶設定。

相關全域選項：

- `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）。
- `messages.responsePrefix`。

## 尋址 / 傳遞目標

偏好 `chat_guid` 以用於穩定路由：

- `chat_guid:iMessage;-;+15555550123`（偏好用於群組）
- `chat_id:123`
- `chat_identifier:...`
- 直接處理程序：`+15555550123`、`user@example.com`
  - 如果直接處理程序沒有現有的 DM 聊天，OpenClaw 將透過 `POST /api/v1/chat/new` 建立一個。這需要啟用 BlueBubbles Private API。

## 安全性

- Webhook 請求透過將 `guid`/`password` 查詢參數或標題與 `channels.bluebubbles.password` 比較進行驗證。來自 `localhost` 的請求也被接受。
- 保持 API 密碼和 webhook 端點保密（將它們視為認證資訊）。
- 本機信任意味著相同主機的反向代理可能無意中繞過密碼。如果您代理 Gateway，需要在代理處進行身份驗證並設定 `gateway.trustedProxies`。參見 [Gateway 安全性](/zh-Hant/gateway/security#reverse-proxy-configuration)。
- 如果在局域網外公開 BlueBubbles 伺服器，請啟用 HTTPS + 防火牆規則。

## 故障排除

- 如果輸入/讀取事件停止運作，請檢查 BlueBubbles webhook 日誌並驗證 Gateway 路徑與 `channels.bluebubbles.webhookPath` 相符。
- 配對代碼在一小時後過期；使用 `openclaw pairing list bluebubbles` 和 `openclaw pairing approve bluebubbles <code>`。
- 反應需要 BlueBubbles private API（`POST /api/v1/message/react`）；確保伺服器版本公開它。
- 編輯/取消傳送需要 macOS 13+ 和相容的 BlueBubbles 伺服器版本。在 macOS 26 (Tahoe) 上，由於 private API 變更，編輯目前損壞。
- 群組圖示更新在 macOS 26 (Tahoe) 上可能不穩定：API 可能返回成功但新圖示不同步。
- OpenClaw 根據 BlueBubbles 伺服器的 macOS 版本自動隱藏已知損壞的操作。如果編輯仍在 macOS 26 (Tahoe) 上出現，使用 `channels.bluebubbles.actions.edit=false` 手動停用。
- 如需狀態/健康資訊：`openclaw status --all` 或 `openclaw status --deep`。

如需一般頻道工作流程參考，請參見[頻道](/zh-Hant/channels)和 [Plugins](/zh-Hant/tools/plugin) 指南。
