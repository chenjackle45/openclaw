---
summary: "透過 BlueBubbles macOS 伺服器的 iMessage（REST 傳送／接收、輸入狀態、反應、配對、進階操作）"
read_when:
  - 設置 BlueBubbles 頻道
  - 疑難排解 webhook 配對
  - 在 macOS 上配置 iMessage
title: "BlueBubbles"
---

# BlueBubbles (macOS REST)

狀態：捆綁外掛程式，透過 HTTP 與 BlueBubbles macOS 伺服器通訊。**推薦用於 iMessage 整合**，因其 API 更豐富，且相比舊版 imsg 頻道設置更簡單。

## 概述

- 透過 BlueBubbles 輔助應用在 macOS 上運行（[bluebubbles.app](https://bluebubbles.app)）。
- 推薦／已測試：macOS Sequoia (15)。macOS Tahoe (26) 可運作；編輯功能在 Tahoe 上目前損壞，群組圖示更新可能報告成功但不會同步。
- OpenClaw 透過其 REST API 與之通訊（`GET /api/v1/ping`、`POST /message/text`、`POST /chat/:id/*`）。
- 傳入訊息透過 webhook 抵達；傳出回覆、輸入指示器、已讀收據和 tapback 是 REST 呼叫。
- 附件和貼圖被納入為傳入媒體（並在可能時提供給代理）。
- 配對／允許清單的運作方式與其他頻道相同（`/channels/pairing` 等），支援 `channels.bluebubbles.allowFrom` + 配對碼。
- 反應如同 Slack／Telegram 一樣呈現為系統事件，代理可在回覆前「提及」它們。
- 進階功能：編輯、撤銷、回覆串連、訊息效果、群組管理。

## 快速入門

1. 在 Mac 上安裝 BlueBubbles 伺服器（遵循 [bluebubbles.app/install](https://bluebubbles.app/install) 的說明）。
2. 在 BlueBubbles 設定中啟用 web API 並設定密碼。
3. 執行 `openclaw onboard` 並選擇 BlueBubbles，或手動配置：

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

4. 將 BlueBubbles webhook 指向你的 gateway（範例：`https://your-gateway-host:3000/bluebubbles-webhook?password=<password>`）。
5. 啟動 gateway；它將註冊 webhook 處理程式並開始配對。

安全備註：

- 一律設定 webhook 密碼。
- Webhook 驗證一律必需。OpenClaw 拒絕 BlueBubbles webhook 請求，除非它們包含與 `channels.bluebubbles.password` 相符的密碼／guid（例如 `?password=<password>` 或 `x-password`），無論迴路／代理拓撲如何。
- 密碼驗證在讀取／解析完整 webhook 本體之前進行檢查。

## 保持 Messages.app 運行（VM／無頭設置）

某些 macOS VM／永遠開啟的設置可能導致 Messages.app 進入「空閒」狀態（傳入事件停止，直到應用被開啟／置於前景）。一個簡單的解決方案是使用 AppleScript + LaunchAgent **每 5 分鐘輕敲 Messages 一次**。

### 1) 儲存 AppleScript

儲存為：

- `~/Scripts/poke-messages.scpt`

範例腳本（非互動式；不會奪取焦點）：

```applescript
try
  tell application "Messages"
    if not running then
      launch
    end if

    -- 觸碰腳本介面以保持處理程式回應。
    set _chatCount to (count of chats)
  end tell
on error
  -- 忽略暫時性故障（首次運行提示、鎖定的工作階段等）。
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

備註：

- 這每 **300 秒**運行一次，並在**登入時**運行。
- 首次運行可能觸發 macOS **自動化**提示（`osascript` → Messages）。在運行 LaunchAgent 的相同使用者工作階段中核准它們。

載入它：

```bash
launchctl unload ~/Library/LaunchAgents/com.user.poke-messages.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/com.user.poke-messages.plist
```

## 上線引導

BlueBubbles 可在互動式上線引導中取得：

```
openclaw onboard
```

精靈提示輸入：

- **伺服器 URL**（必需）：BlueBubbles 伺服器位址（例如 `http://192.168.1.100:1234`）
- **密碼**（必需）：BlueBubbles 伺服器設定中的 API 密碼
- **Webhook 路徑**（選擇性）：預設為 `/bluebubbles-webhook`
- **DM 原則**：配對、允許清單、開放或停用
- **允許清單**：電話號碼、電子郵件或聊天目標

你也可以透過 CLI 新增 BlueBubbles：

```
openclaw channels add bluebubbles --http-url http://192.168.1.100:1234 --password <password>
```

## 存取控制（DM + 群組）

DM：

- 預設：`channels.bluebubbles.dmPolicy = "pairing"`。
- 未知寄件者收到配對碼；訊息在核准前被忽略（碼在 1 小時後過期）。
- 透過以下方式核准：
  - `openclaw pairing list bluebubbles`
  - `openclaw pairing approve bluebubbles <CODE>`
- 配對是預設的權杖交換。詳情：[配對](/zh-Hant/channels/pairing)

群組：

- `channels.bluebubbles.groupPolicy = open | allowlist | disabled`（預設：`allowlist`）。
- `channels.bluebubbles.groupAllowFrom` 控制當設定 `allowlist` 時誰可在群組中觸發。

### 提及閘門（群組）

BlueBubbles 支援群組聊天的提及閘門，符合 iMessage／WhatsApp 行為：

- 使用 `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）偵測提及。
- 當為群組啟用 `requireMention` 時，代理僅在被提及時回應。
- 來自授權寄件者的控制命令略過提及閘門。

每個群組配置：

```json5
{
  channels: {
    bluebubbles: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15555550123"],
      groups: {
        "*": { requireMention: true }, // 所有群組的預設值
        "iMessage;-;chat123": { requireMention: false }, // 特定群組的覆蓋
      },
    },
  },
}
```

### 命令閘門

- 控制命令（例如 `/config`、`/model`）需要授權。
- 使用 `allowFrom` 和 `groupAllowFrom` 決定命令授權。
- 授權寄件者即使未在群組中提及也可執行控制命令。

## 輸入 + 已讀收據

- **輸入指示器**：在回應產生前和期間自動傳送。
- **已讀收據**：由 `channels.bluebubbles.sendReadReceipts` 控制（預設：`true`）。
- **輸入指示器**：OpenClaw 傳送輸入開始事件；BlueBubbles 在傳送或逾時時自動清除輸入（透過 DELETE 的手動停止不可靠）。

```json5
{
  channels: {
    bluebubbles: {
      sendReadReceipts: false, // 停用已讀收據
    },
  },
}
```

## 進階操作

BlueBubbles 在設定中啟用時支援進階訊息操作：

```json5
{
  channels: {
    bluebubbles: {
      actions: {
        reactions: true, // tapback（預設：true）
        edit: true, // 編輯已傳送的訊息（macOS 13+，在 macOS 26 Tahoe 上損壞）
        unsend: true, // 撤銷訊息（macOS 13+）
        reply: true, // 按訊息 GUID 回覆串連
        sendWithEffect: true, // 訊息效果（猛擊、大聲等）
        renameGroup: true, // 重新命名群組聊天
        setGroupIcon: true, // 設定群組聊天圖示／照片（在 macOS 26 Tahoe 上不穩定）
        addParticipant: true, // 新增參與者到群組
        removeParticipant: true, // 從群組移除參與者
        leaveGroup: true, // 離開群組聊天
        sendAttachment: true, // 傳送附件／媒體
      },
    },
  },
}
```

可用操作：

- **react**：新增／移除 tapback 反應（`messageId`、`emoji`、`remove`）
- **edit**：編輯已傳送的訊息（`messageId`、`text`）
- **unsend**：撤銷訊息（`messageId`）
- **reply**：回覆特定訊息（`messageId`、`text`、`to`）
- **sendWithEffect**：使用 iMessage 效果傳送（`text`、`to`、`effectId`）
- **renameGroup**：重新命名群組聊天（`chatGuid`、`displayName`）
- **setGroupIcon**：設定群組聊天的圖示／照片（`chatGuid`、`media`）— 在 macOS 26 Tahoe 上不穩定（API 可能返回成功但圖示不會同步）。
- **addParticipant**：將某人新增至群組（`chatGuid`、`address`）
- **removeParticipant**：從群組移除某人（`chatGuid`、`address`）
- **leaveGroup**：離開群組聊天（`chatGuid`）
- **sendAttachment**：傳送媒體／檔案（`to`、`buffer`、`filename`、`asVoice`）
  - 語音備忘錄：使用 **MP3** 或 **CAF** 音訊設定 `asVoice: true` 以作為 iMessage 語音訊息傳送。BlueBubbles 在傳送語音備忘錄時將 MP3 → CAF 轉換。

### 訊息 ID（短版本與完整版本）

OpenClaw 可能呈現 _短_ 訊息 ID（例如 `1`、`2`）以節省權杖。

- `MessageSid` / `ReplyToId` 可以是短 ID。
- `MessageSidFull` / `ReplyToIdFull` 包含提供者完整 ID。
- 短 ID 在記憶體中；它們可在重新啟動或快取驅逐時過期。
- 操作接受短或完整 `messageId`，但如果不再可用，短 ID 將出錯。

為了持久自動化和儲存使用完整 ID：

- 範本：`{{MessageSidFull}}`、`{{ReplyToIdFull}}`
- 上下文：傳入酬載中的 `MessageSidFull` / `ReplyToIdFull`

參見[配置](/zh-Hant/gateway/configuration)以了解範本變數。

## 區塊串流

控制回應是作為單一訊息傳送還是按區塊串流：

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
- 透過 `channels.bluebubbles.mediaMaxMb` 對傳入和傳出媒體設定媒體上限（預設：8 MB）。
- 傳出文字被分割為 `channels.bluebubbles.textChunkLimit`（預設：4000 字元）。

## 配置參考

完整配置：[配置](/zh-Hant/gateway/configuration)

提供者選項：

- `channels.bluebubbles.enabled`：啟用／停用頻道。
- `channels.bluebubbles.serverUrl`：BlueBubbles REST API 基本 URL。
- `channels.bluebubbles.password`：API 密碼。
- `channels.bluebubbles.webhookPath`：Webhook 端點路徑（預設：`/bluebubbles-webhook`）。
- `channels.bluebubbles.dmPolicy`：`pairing | allowlist | open | disabled`（預設：`pairing`）。
- `channels.bluebubbles.allowFrom`：DM 允許清單（處理代碼、電子郵件、E.164 號碼、`chat_id:*`、`chat_guid:*`）。
- `channels.bluebubbles.groupPolicy`：`open | allowlist | disabled`（預設：`allowlist`）。
- `channels.bluebubbles.groupAllowFrom`：群組寄件者允許清單。
- `channels.bluebubbles.groups`：每個群組配置（`requireMention` 等）。
- `channels.bluebubbles.sendReadReceipts`：傳送已讀收據（預設：`true`）。
- `channels.bluebubbles.blockStreaming`：啟用區塊串流（預設：`false`；串流回覆需要）。
- `channels.bluebubbles.textChunkLimit`：傳出區塊大小（字元）（預設：4000）。
- `channels.bluebubbles.chunkMode`：`length`（預設）僅在超過 `textChunkLimit` 時分割；`newline` 在長度分割前在空白行（段落邊界）上分割。
- `channels.bluebubbles.mediaMaxMb`：傳入／傳出媒體上限（MB）（預設：8）。
- `channels.bluebubbles.mediaLocalRoots`：允許傳出本機媒體路徑的絕對本機目錄的明確允許清單。除非配置，否則預設拒絕本機路徑傳送。每個帳戶覆蓋：`channels.bluebubbles.accounts.<accountId>.mediaLocalRoots`。
- `channels.bluebubbles.historyLimit`：上下文的最大群組訊息（0 停用）。
- `channels.bluebubbles.dmHistoryLimit`：DM 歷史記錄限制。
- `channels.bluebubbles.actions`：啟用／停用特定操作。
- `channels.bluebubbles.accounts`：多帳戶配置。

相關全域選項：

- `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）。
- `messages.responsePrefix`。

## 定址／傳遞目標

偏好 `chat_guid` 以進行穩定路由：

- `chat_guid:iMessage;-;+15555550123`（群組偏好）
- `chat_id:123`
- `chat_identifier:...`
- 直接處理代碼：`+15555550123`、`user@example.com`
  - 如果直接處理代碼沒有現有 DM 聊天，OpenClaw 將透過 `POST /api/v1/chat/new` 建立一個。這需要啟用 BlueBubbles 私密 API。

## 安全性

- Webhook 請求透過將 `guid`／`password` 查詢參數或標頭與 `channels.bluebubbles.password` 比較進行驗證。來自 `localhost` 的請求也被接受。
- 保持 API 密碼和 webhook 端點祕密（將它們視為憑證）。
- Localhost 信任意味著相同主機反向代理可能會無意間略過密碼。如果代理 gateway，在代理處要求驗證並配置 `gateway.trustedProxies`。參見[Gateway 安全性](/zh-Hant/gateway/security#reverse-proxy-configuration)。
- 如果在 LAN 外部公開 BlueBubbles 伺服器，請啟用 HTTPS + 防火牆規則。

## 疑難排解

- 如果輸入／讀取事件停止運作，請檢查 BlueBubbles webhook 日誌並驗證 gateway 路徑與 `channels.bluebubbles.webhookPath` 相符。
- 配對碼在 1 小時後過期；使用 `openclaw pairing list bluebubbles` 和 `openclaw pairing approve bluebubbles <code>`。
- 反應需要 BlueBubbles 私密 API（`POST /api/v1/message/react`）；確保伺服器版本公開它。
- 編輯／撤銷需要 macOS 13+ 和相容的 BlueBubbles 伺服器版本。在 macOS 26 (Tahoe) 上，編輯由於私密 API 更改目前損壞。
- 群組圖示更新在 macOS 26 (Tahoe) 上可能不穩定：API 可能返回成功但新圖示不會同步。
- OpenClaw 根據 BlueBubbles 伺服器的 macOS 版本自動隱藏已知損壞的操作。如果編輯在 macOS 26 (Tahoe) 上仍出現，請使用 `channels.bluebubbles.actions.edit=false` 手動停用它。
- 狀態／健康資訊：`openclaw status --all` 或 `openclaw status --deep`。

如需一般頻道工作流參考，請參見[頻道](/zh-Hant/channels)和[外掛程式](/zh-Hant/tools/plugin)指南。
