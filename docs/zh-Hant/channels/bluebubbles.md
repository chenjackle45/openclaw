---
summary: "透過 BlueBubbles macOS 伺服器的 iMessage（REST 傳送/接收、輸入狀態、反應、配對、進階操作）。"
read_when:
  - 設定 BlueBubbles 頻道
  - 排除 webhook 配對問題
  - 在 macOS 上設定 iMessage
title: "BlueBubbles"
---

# BlueBubbles（macOS REST）

狀態：內建外掛，透過 HTTP 與 BlueBubbles macOS 伺服器通訊。由於 API 更豐富且設定更簡單，**建議用於 iMessage 整合**，優於舊版 imsg 頻道。

## 概覽

- 透過 BlueBubbles 輔助應用程式（[bluebubbles.app](https://bluebubbles.app)）在 macOS 上執行。
- 建議/測試版本：macOS Sequoia（15）。macOS Tahoe（26）可用；編輯功能在 Tahoe 上目前已損壞，群組圖示更新可能回報成功但未同步。
- OpenClaw 透過 REST API（`GET /api/v1/ping`、`POST /message/text`、`POST /chat/:id/*`）與其通訊。
- 傳入訊息透過 webhook 抵達；傳出回覆、輸入狀態指示器、已讀回條和 tapback 為 REST 呼叫。
- 附件和貼圖作為入站媒體處理（並在可能的情況下呈現給 agent）。
- 配對/允許清單與其他頻道相同（`/channels/pairing` 等），使用 `channels.bluebubbles.allowFrom` + 配對碼。
- 反應和 Slack/Telegram 一樣作為系統事件呈現，讓 agent 在回覆前能「提及」它們。
- 進階功能：編輯、撤回、回覆串、訊息效果、群組管理。

## 快速開始

1. 在 Mac 上安裝 BlueBubbles 伺服器（依照 [bluebubbles.app/install](https://bluebubbles.app/install) 的指示）。
2. 在 BlueBubbles 設定中，啟用 web API 並設定密碼。
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

4. 將 BlueBubbles webhook 指向你的 gateway（例如：`https://your-gateway-host:3000/bluebubbles-webhook?password=<password>`）。
5. 啟動 gateway；它將註冊 webhook 處理器並開始配對。

安全說明：

- 務必設定 webhook 密碼。
- Webhook 認證為必要項目。OpenClaw 會拒絕不包含與 `channels.bluebubbles.password` 相符的密碼/guid（例如 `?password=<password>` 或 `x-password`）的 BlueBubbles webhook 請求，無論 loopback/proxy 拓樸為何。
- 密碼認證在讀取/解析完整 webhook 內容之前進行檢查。

## 保持 Messages.app 存活（VM / 無頭設定）

某些 macOS VM / 常時開機設定可能導致 Messages.app 進入「閒置」狀態（傳入事件停止，直到應用程式被開啟/前景化）。一個簡單的解決方案是使用 AppleScript + LaunchAgent 每 5 分鐘**戳一下 Messages**。

### 1）儲存 AppleScript

將此儲存為：

- `~/Scripts/poke-messages.scpt`

範例腳本（非互動式；不搶奪焦點）：

```applescript
try
  tell application "Messages"
    if not running then
      launch
    end if

    -- Touch the scripting interface to keep the process responsive.
    set _chatCount to (count of chats)
  end tell
on error
  -- Ignore transient failures (first-run prompts, locked session, etc).
end try
```

### 2）安裝 LaunchAgent

將此儲存為：

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

- 此腳本每 **300 秒**執行一次，並**在登入時**執行。
- 首次執行可能觸發 macOS **自動化**提示（`osascript` → Messages）。請在執行 LaunchAgent 的同一用戶工作階段中核准。

載入：

```bash
launchctl unload ~/Library/LaunchAgents/com.user.poke-messages.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/com.user.poke-messages.plist
```

## 上手引導

BlueBubbles 可在互動式設定精靈中取得：

```
openclaw onboard
```

精靈會詢問：

- **伺服器 URL**（必要）：BlueBubbles 伺服器位址（例如：`http://192.168.1.100:1234`）
- **密碼**（必要）：來自 BlueBubbles 伺服器設定的 API 密碼
- **Webhook 路徑**（選用）：預設為 `/bluebubbles-webhook`
- **DM 政策**：配對、允許清單、開放或停用
- **允許清單**：電話號碼、電子郵件或聊天目標

也可透過 CLI 新增 BlueBubbles：

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
- 配對是預設的 token 交換方式。詳情：[配對](/zh-Hant/channels/pairing)

群組：

- `channels.bluebubbles.groupPolicy = open | allowlist | disabled`（預設：`allowlist`）。
- `channels.bluebubbles.groupAllowFrom` 控制設定 `allowlist` 時在群組中可觸發的人員。

### 提及限制（群組）

BlueBubbles 支援群組聊天的提及限制，與 iMessage/WhatsApp 行為相符：

- 使用 `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）偵測提及。
- 當群組啟用 `requireMention` 時，agent 只在被提及時回應。
- 已授權寄件者的控制指令可繞過提及限制。

個別群組設定：

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

### 指令限制

- 控制指令（例如 `/config`、`/model`）需要授權。
- 使用 `allowFrom` 和 `groupAllowFrom` 判斷指令授權。
- 已授權的寄件者即使在群組中未提及也可執行控制指令。

## 輸入狀態 + 已讀回條

- **輸入狀態指示器**：在回應生成前和生成期間自動傳送。
- **已讀回條**：由 `channels.bluebubbles.sendReadReceipts` 控制（預設：`true`）。
- **輸入狀態指示器**：OpenClaw 傳送輸入開始事件；BlueBubbles 在傳送或逾時後自動清除輸入狀態（手動透過 DELETE 停止不可靠）。

```json5
{
  channels: {
    bluebubbles: {
      sendReadReceipts: false, // 停用已讀回條
    },
  },
}
```

## 進階操作

在組態中啟用後，BlueBubbles 支援進階訊息操作：

```json5
{
  channels: {
    bluebubbles: {
      actions: {
        reactions: true, // tapback（預設：true）
        edit: true, // 編輯已傳送的訊息（macOS 13+，在 macOS 26 Tahoe 上已損壞）
        unsend: true, // 撤回訊息（macOS 13+）
        reply: true, // 透過訊息 GUID 回覆串
        sendWithEffect: true, // 訊息效果（撞擊、大聲等）
        renameGroup: true, // 重新命名群組聊天
        setGroupIcon: true, // 設定群組聊天圖示/照片（在 macOS 26 Tahoe 上不穩定）
        addParticipant: true, // 將參與者加入群組
        removeParticipant: true, // 從群組移除參與者
        leaveGroup: true, // 離開群組聊天
        sendAttachment: true, // 傳送附件/媒體
      },
    },
  },
}
```

可用操作：

- **react**：新增/移除 tapback 反應（`messageId`、`emoji`、`remove`）
- **edit**：編輯已傳送的訊息（`messageId`、`text`）
- **unsend**：撤回訊息（`messageId`）
- **reply**：回覆特定訊息（`messageId`、`text`、`to`）
- **sendWithEffect**：使用 iMessage 效果傳送（`text`、`to`、`effectId`）
- **renameGroup**：重新命名群組聊天（`chatGuid`、`displayName`）
- **setGroupIcon**：設定群組聊天圖示/照片（`chatGuid`、`media`）— 在 macOS 26 Tahoe 上不穩定（API 可能回報成功但圖示未同步）。
- **addParticipant**：將某人加入群組（`chatGuid`、`address`）
- **removeParticipant**：從群組移除某人（`chatGuid`、`address`）
- **leaveGroup**：離開群組聊天（`chatGuid`）
- **sendAttachment**：傳送媒體/檔案（`to`、`buffer`、`filename`、`asVoice`）
  - 語音備忘錄：設定 `asVoice: true` 並使用 **MP3** 或 **CAF** 音訊，以 iMessage 語音訊息傳送。BlueBubbles 在傳送語音備忘錄時將 MP3 轉換為 CAF。

### 訊息 ID（短版 vs 完整版）

OpenClaw 可能呈現*短*訊息 ID（例如 `1`、`2`）以節省 token。

- `MessageSid` / `ReplyToId` 可以是短 ID。
- `MessageSidFull` / `ReplyToIdFull` 包含供應商完整 ID。
- 短 ID 存於記憶體中；在重啟或快取清除時可能失效。
- 操作接受短或完整 `messageId`，但若短 ID 已不可用則會報錯。

持久化自動化和儲存請使用完整 ID：

- 範本：`{{MessageSidFull}}`、`{{ReplyToIdFull}}`
- 上下文：入站負載中的 `MessageSidFull` / `ReplyToIdFull`

參見[設定](/zh-Hant/gateway/configuration)了解範本變數。

## 區塊串流

控制回應是以單一訊息傳送還是分區塊串流：

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

- 入站附件被下載並儲存在媒體快取中。
- 透過 `channels.bluebubbles.mediaMaxMb` 控制入站和出站媒體的上限（預設：8 MB）。
- 出站文字被分割為 `channels.bluebubbles.textChunkLimit`（預設：4000 個字元）。

## 設定參考

完整設定：[設定](/zh-Hant/gateway/configuration)

供應商選項：

- `channels.bluebubbles.enabled`：啟用/停用頻道。
- `channels.bluebubbles.serverUrl`：BlueBubbles REST API 基礎 URL。
- `channels.bluebubbles.password`：API 密碼。
- `channels.bluebubbles.webhookPath`：Webhook 端點路徑（預設：`/bluebubbles-webhook`）。
- `channels.bluebubbles.dmPolicy`：`pairing | allowlist | open | disabled`（預設：`pairing`）。
- `channels.bluebubbles.allowFrom`：DM 允許清單（handles、電子郵件、E.164 號碼、`chat_id:*`、`chat_guid:*`）。
- `channels.bluebubbles.groupPolicy`：`open | allowlist | disabled`（預設：`allowlist`）。
- `channels.bluebubbles.groupAllowFrom`：群組寄件者允許清單。
- `channels.bluebubbles.groups`：個別群組設定（`requireMention` 等）。
- `channels.bluebubbles.sendReadReceipts`：傳送已讀回條（預設：`true`）。
- `channels.bluebubbles.blockStreaming`：啟用區塊串流（預設：`false`；串流回覆必要）。
- `channels.bluebubbles.textChunkLimit`：出站分塊大小（字元，預設：4000）。
- `channels.bluebubbles.chunkMode`：`length`（預設）僅在超過 `textChunkLimit` 時分割；`newline` 在長度分塊前先按空白行（段落邊界）分割。
- `channels.bluebubbles.mediaMaxMb`：入站/出站媒體上限（MB，預設：8）。
- `channels.bluebubbles.mediaLocalRoots`：允許出站本地媒體路徑的絕對本地目錄明確允許清單。本地路徑傳送預設被拒絕，除非已設定此項。每帳號覆蓋：`channels.bluebubbles.accounts.<accountId>.mediaLocalRoots`。
- `channels.bluebubbles.historyLimit`：群組訊息上下文的最大數量（0 表示停用）。
- `channels.bluebubbles.dmHistoryLimit`：DM 歷史記錄限制。
- `channels.bluebubbles.actions`：啟用/停用特定操作。
- `channels.bluebubbles.accounts`：多帳號設定。

相關全域選項：

- `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）。
- `messages.responsePrefix`。

## 定址 / 傳遞目標

優先使用 `chat_guid` 以穩定路由：

- `chat_guid:iMessage;-;+15555550123`（群組優先）
- `chat_id:123`
- `chat_identifier:...`
- 直接 handles：`+15555550123`、`user@example.com`
  - 若直接 handle 沒有現有的 DM 聊天，OpenClaw 將透過 `POST /api/v1/chat/new` 建立一個。這需要啟用 BlueBubbles 私有 API。

## 安全性

- Webhook 請求透過比對 `guid`/`password` 查詢參數或標頭與 `channels.bluebubbles.password` 來認證。來自 `localhost` 的請求也被接受。
- 保持 API 密碼和 webhook 端點的機密性（視同憑證處理）。
- Localhost 信任意味著同主機的反向代理可能意外繞過密碼。若你代理 gateway，請在代理層要求認證並設定 `gateway.trustedProxies`。參見 [Gateway 安全性](/zh-Hant/gateway/security#reverse-proxy-configuration)。
- 若 BlueBubbles 伺服器暴露在區域網路外，請啟用 HTTPS + 防火牆規則。

## 疑難排解

- 若輸入/已讀事件停止運作，請檢查 BlueBubbles webhook 日誌並確認 gateway 路徑與 `channels.bluebubbles.webhookPath` 相符。
- 配對碼在一小時後過期；使用 `openclaw pairing list bluebubbles` 和 `openclaw pairing approve bluebubbles <code>`。
- 反應需要 BlueBubbles 私有 API（`POST /api/v1/message/react`）；確認伺服器版本有提供此功能。
- 編輯/撤回需要 macOS 13+ 和相容的 BlueBubbles 伺服器版本。在 macOS 26（Tahoe）上，由於私有 API 變更，編輯功能目前已損壞。
- 群組圖示更新在 macOS 26（Tahoe）上可能不穩定：API 可能回報成功但新圖示未同步。
- OpenClaw 根據 BlueBubbles 伺服器的 macOS 版本自動隱藏已知損壞的操作。若在 macOS 26（Tahoe）上編輯仍出現，請使用 `channels.bluebubbles.actions.edit=false` 手動停用。
- 狀態/健康資訊：`openclaw status --all` 或 `openclaw status --deep`。

一般頻道工作流程參考，請參見[頻道](/zh-Hant/channels)和[外掛](/zh-Hant/tools/plugin)指南。
