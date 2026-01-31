---
title: "Bluebubbles(BlueBubbles macOS REST)"
summary: "透過 BlueBubbles macOS 伺服器的 iMessage（REST 發送/接收、輸入指示器、反應、配對、進階動作）"
read_when:
  - 設定 BlueBubbles 頻道
  - 疑難排解 webhook 配對
  - 在 macOS 上設定 iMessage
---
# BlueBubbles（macOS REST）

狀態：內建插件，透過 HTTP 與 BlueBubbles macOS 伺服器通訊。**建議用於 iMessage 整合**，因為相比舊版 imsg 頻道，它有更豐富的 API 和更簡單的設定。

## 概述
- 透過 BlueBubbles 輔助應用程式在 macOS 上運行（[bluebubbles.app](https://bluebubbles.app)）。
- 建議/已測試：macOS Sequoia (15)。macOS Tahoe (26) 可用；編輯功能在 Tahoe 上目前有問題，群組圖示更新可能報告成功但不會同步。
- OpenClaw 透過其 REST API 與之通訊（`GET /api/v1/ping`、`POST /message/text`、`POST /chat/:id/*`）。
- 傳入訊息透過 webhook 到達；外發回覆、輸入指示器、已讀回執和 tapback 是 REST 呼叫。
- 附件和貼圖作為入站媒體攝取（並在可能時呈現給代理）。
- 配對/允許清單的運作方式與其他頻道相同（`/start/pairing` 等）配合 `channels.bluebubbles.allowFrom` + 配對碼。
- 反應作為系統事件呈現，就像 Slack/Telegram 一樣，以便代理可以在回覆前「提及」它們。
- 進階功能：編輯、取消傳送、回覆串連、訊息效果、群組管理。

## 快速開始
1. 在您的 Mac 上安裝 BlueBubbles 伺服器（按照 [bluebubbles.app/install](https://bluebubbles.app/install) 的說明操作）。
2. 在 BlueBubbles 設定中，啟用 web API 並設定密碼。
3. 運行 `openclaw onboard` 並選擇 BlueBubbles，或手動設定：
   ```json5
   {
     channels: {
       bluebubbles: {
         enabled: true,
         serverUrl: "http://192.168.1.100:1234",
         password: "example-password",
         webhookPath: "/bluebubbles-webhook"
       }
     }
   }
   ```
4. 將 BlueBubbles webhook 指向您的 Gateway（範例：`https://your-gateway-host:3000/bluebubbles-webhook?password=<password>`）。
5. 啟動 Gateway；它會註冊 webhook 處理器並開始配對。

## 引導設定
BlueBubbles 在互動式設定精靈中可用：
```
openclaw onboard
```

精靈會提示：
- **伺服器 URL**（必需）：BlueBubbles 伺服器地址（例如 `http://192.168.1.100:1234`）
- **密碼**（必需）：來自 BlueBubbles 伺服器設定的 API 密碼
- **Webhook 路徑**（可選）：預設為 `/bluebubbles-webhook`
- **私訊策略**：pairing、allowlist、open 或 disabled
- **允許清單**：電話號碼、電子郵件或聊天目標

您也可以透過 CLI 新增 BlueBubbles：
```
openclaw channels add bluebubbles --http-url http://192.168.1.100:1234 --password <password>
```

## 存取控制（私訊 + 群組）
私訊：
- 預設：`channels.bluebubbles.dmPolicy = "pairing"`。
- 未知發送者收到配對碼；訊息在批准前被忽略（代碼在 1 小時後過期）。
- 透過以下方式批准：
  - `openclaw pairing list bluebubbles`
  - `openclaw pairing approve bluebubbles <CODE>`
- 配對是預設的令牌交換。詳情：[配對](/start/pairing)

群組：
- `channels.bluebubbles.groupPolicy = open | allowlist | disabled`（預設：`allowlist`）。
- 當設定 `allowlist` 時，`channels.bluebubbles.groupAllowFrom` 控制誰可以在群組中觸發。

### 提及閘門（群組）
BlueBubbles 支援群組聊天的提及閘門，匹配 iMessage/WhatsApp 行為：
- 使用 `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）檢測提及。
- 當群組啟用 `requireMention` 時，代理僅在被提及時回應。
- 來自授權發送者的控制命令繞過提及閘門。

每群組設定：
```json5
{
  channels: {
    bluebubbles: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15555550123"],
      groups: {
        "*": { requireMention: true },  // 所有群組的預設
        "iMessage;-;chat123": { requireMention: false }  // 特定群組的覆寫
      }
    }
  }
}
```

### 命令閘門
- 控制命令（例如 `/config`、`/model`）需要授權。
- 使用 `allowFrom` 和 `groupAllowFrom` 確定命令授權。
- 授權的發送者可以在群組中運行控制命令，即使沒有提及。

## 輸入指示器 + 已讀回執
- **輸入指示器**：在回應生成之前和期間自動發送。
- **已讀回執**：由 `channels.bluebubbles.sendReadReceipts` 控制（預設：`true`）。
- **輸入指示器**：OpenClaw 發送輸入開始事件；BlueBubbles 在發送或逾時時自動清除輸入（透過 DELETE 手動停止不可靠）。

```json5
{
  channels: {
    bluebubbles: {
      sendReadReceipts: false  // 停用已讀回執
    }
  }
}
```

## 進階動作
BlueBubbles 在設定中啟用時支援進階訊息動作：

```json5
{
  channels: {
    bluebubbles: {
      actions: {
        reactions: true,       // tapback（預設：true）
        edit: true,            // 編輯已發送訊息（macOS 13+，在 macOS 26 Tahoe 上有問題）
        unsend: true,          // 取消傳送訊息（macOS 13+）
        reply: true,           // 按訊息 GUID 回覆串連
        sendWithEffect: true,  // 訊息效果（slam、loud 等）
        renameGroup: true,     // 重新命名群組聊天
        setGroupIcon: true,    // 設定群組聊天圖示/照片（在 macOS 26 Tahoe 上不穩定）
        addParticipant: true,  // 將參與者新增到群組
        removeParticipant: true, // 從群組移除參與者
        leaveGroup: true,      // 離開群組聊天
        sendAttachment: true   // 發送附件/媒體
      }
    }
  }
}
```

可用動作：
- **react**：新增/移除 tapback 反應（`messageId`、`emoji`、`remove`）
- **edit**：編輯已發送訊息（`messageId`、`text`）
- **unsend**：取消傳送訊息（`messageId`）
- **reply**：回覆特定訊息（`messageId`、`text`、`to`）
- **sendWithEffect**：使用 iMessage 效果發送（`text`、`to`、`effectId`）
- **renameGroup**：重新命名群組聊天（`chatGuid`、`displayName`）
- **setGroupIcon**：設定群組聊天的圖示/照片（`chatGuid`、`media`）— 在 macOS 26 Tahoe 上不穩定（API 可能返回成功但圖示不會同步）。
- **addParticipant**：將某人新增到群組（`chatGuid`、`address`）
- **removeParticipant**：從群組移除某人（`chatGuid`、`address`）
- **leaveGroup**：離開群組聊天（`chatGuid`）
- **sendAttachment**：發送媒體/檔案（`to`、`buffer`、`filename`、`asVoice`）
  - 語音備忘：設定 `asVoice: true` 並使用 **MP3** 或 **CAF** 音訊以作為 iMessage 語音訊息發送。BlueBubbles 在發送語音備忘時將 MP3 轉換為 CAF。

### 訊息 ID（短 vs 完整）
OpenClaw 可能會呈現*短*訊息 ID（例如 `1`、`2`）以節省令牌。
- `MessageSid` / `ReplyToId` 可以是短 ID。
- `MessageSidFull` / `ReplyToIdFull` 包含供應商完整 ID。
- 短 ID 存在記憶體中；它們可能在重啟或快取清除時過期。
- 動作接受短或完整 `messageId`，但如果不再可用短 ID 會報錯。

對於持久自動化和儲存使用完整 ID：
- 範本：`{{MessageSidFull}}`、`{{ReplyToIdFull}}`
- 上下文：入站負載中的 `MessageSidFull` / `ReplyToIdFull`

請參閱 [設定](/gateway/configuration) 了解範本變數。

## 區塊串流
控制回應是作為單一訊息發送還是分塊串流：
```json5
{
  channels: {
    bluebubbles: {
      blockStreaming: true  // 啟用區塊串流（預設行為）
    }
  }
}
```

## 媒體 + 限制
- 入站附件會下載並儲存在媒體快取中。
- 透過 `channels.bluebubbles.mediaMaxMb` 設定媒體上限（預設：8 MB）。
- 外發文字分塊至 `channels.bluebubbles.textChunkLimit`（預設：4000 字元）。

## 設定參考
完整設定：[設定](/gateway/configuration)

供應商選項：
- `channels.bluebubbles.enabled`：啟用/停用頻道。
- `channels.bluebubbles.serverUrl`：BlueBubbles REST API 基礎 URL。
- `channels.bluebubbles.password`：API 密碼。
- `channels.bluebubbles.webhookPath`：Webhook 端點路徑（預設：`/bluebubbles-webhook`）。
- `channels.bluebubbles.dmPolicy`：`pairing | allowlist | open | disabled`（預設：`pairing`）。
- `channels.bluebubbles.allowFrom`：私訊允許清單（handle、電子郵件、E.164 號碼、`chat_id:*`、`chat_guid:*`）。
- `channels.bluebubbles.groupPolicy`：`open | allowlist | disabled`（預設：`allowlist`）。
- `channels.bluebubbles.groupAllowFrom`：群組發送者允許清單。
- `channels.bluebubbles.groups`：每群組設定（`requireMention` 等）。
- `channels.bluebubbles.sendReadReceipts`：發送已讀回執（預設：`true`）。
- `channels.bluebubbles.blockStreaming`：啟用區塊串流（預設：`true`）。
- `channels.bluebubbles.textChunkLimit`：外發分塊大小（字元）（預設：4000）。
- `channels.bluebubbles.chunkMode`：`length`（預設）僅在超過 `textChunkLimit` 時分割；`newline` 在長度分塊前在空白行（段落邊界）分割。
- `channels.bluebubbles.mediaMaxMb`：入站媒體上限（MB）（預設：8）。
- `channels.bluebubbles.historyLimit`：上下文的最大群組訊息數（0 停用）。
- `channels.bluebubbles.dmHistoryLimit`：私訊歷史限制。
- `channels.bluebubbles.actions`：啟用/停用特定動作。
- `channels.bluebubbles.accounts`：多帳戶設定。

相關全域選項：
- `agents.list[].groupChat.mentionPatterns`（或 `messages.groupChat.mentionPatterns`）。
- `messages.responsePrefix`。

## 地址 / 交付目標
優先使用 `chat_guid` 進行穩定路由：
- `chat_guid:iMessage;-;+15555550123`（群組首選）
- `chat_id:123`
- `chat_identifier:...`
- 直接 handle：`+15555550123`、`user@example.com`
  - 如果直接 handle 沒有現有的私訊聊天，OpenClaw 會透過 `POST /api/v1/chat/new` 建立一個。這需要啟用 BlueBubbles Private API。

## 安全
- Webhook 請求透過比較 `guid`/`password` 查詢參數或標頭與 `channels.bluebubbles.password` 進行認證。來自 `localhost` 的請求也被接受。
- 保持 API 密碼和 webhook 端點保密（像憑證一樣對待它們）。
- Localhost 信任意味著同主機反向代理可能無意中繞過密碼。如果您代理 Gateway，請在代理處要求認證並設定 `gateway.trustedProxies`。請參閱 [Gateway 安全](/gateway/security#reverse-proxy-configuration)。
- 如果在區域網路外公開 BlueBubbles 伺服器，請啟用 HTTPS + 防火牆規則。

## 疑難排解
- 如果輸入/讀取事件停止運作，請檢查 BlueBubbles webhook 日誌並驗證 Gateway 路徑是否與 `channels.bluebubbles.webhookPath` 匹配。
- 配對碼在一小時後過期；使用 `openclaw pairing list bluebubbles` 和 `openclaw pairing approve bluebubbles <code>`。
- 反應需要 BlueBubbles private API（`POST /api/v1/message/react`）；確保伺服器版本公開它。
- 編輯/取消傳送需要 macOS 13+ 和相容的 BlueBubbles 伺服器版本。在 macOS 26（Tahoe）上，編輯由於 private API 變更目前有問題。
- 群組圖示更新在 macOS 26（Tahoe）上可能不穩定：API 可能返回成功但新圖示不會同步。
- OpenClaw 根據 BlueBubbles 伺服器的 macOS 版本自動隱藏已知有問題的動作。如果編輯仍在 macOS 26（Tahoe）上出現，請使用 `channels.bluebubbles.actions.edit=false` 手動停用它。
- 對於狀態/健康資訊：`openclaw status --all` 或 `openclaw status --deep`。

對於一般頻道工作流程參考，請參閱 [頻道](/channels) 和 [插件](/plugins) 指南。
