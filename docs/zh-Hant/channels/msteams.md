---
summary: "Microsoft Teams bot 支援狀態、功能與設定"
read_when:
  - 處理 MS Teams 頻道功能
title: "Microsoft Teams"
---

# Microsoft Teams（外掛）

> "Abandon all hope, ye who enter here."

更新日期：2026-01-21

狀態：支援文字與私訊附件；頻道/群組檔案發送需要 `sharePointSiteId` 與 Graph 權限（參見[在群組聊天中傳送檔案](#sending-files-in-group-chats)）。投票功能透過 Adaptive Cards 發動。

## 需要外掛

Microsoft Teams 以外掛形式發布，未隨核心安裝捆綁。

**重大變更（2026.1.15）：** MS Teams 已移出核心。若你使用它，必須安裝外掛。

透過 CLI 安裝（npm registry）：

```bash
openclaw plugins install @openclaw/msteams
```

本地 checkout（從 git repo 執行時）：

```bash
openclaw plugins install ./extensions/msteams
```

若你在設定/上線過程中選擇 Teams 且偵測到 git checkout，OpenClaw 將自動提供本地安裝路徑。

詳情：[Plugins](/zh-Hant/tools/plugin)

## 快速設定（初學者）

1. 安裝 Microsoft Teams 外掛。
2. 建立 **Azure Bot**（取得 App ID、用戶端 secret 和租戶 ID）。
3. 以這些憑證設定 OpenClaw。
4. 透過公開 URL 或 tunnel 暴露 `/api/messages`（預設埠 3978）。
5. 安裝 Teams App 套件並啟動 gateway。

最小設定：

```json5
{
  channels: {
    msteams: {
      enabled: true,
      appId: "<APP_ID>",
      appPassword: "<APP_PASSWORD>",
      tenantId: "<TENANT_ID>",
      webhook: { port: 3978, path: "/api/messages" },
    },
  },
}
```

注意：群組聊天預設被封鎖（`channels.msteams.groupPolicy: "allowlist"`）。若要允許群組回覆，請設定 `channels.msteams.groupAllowFrom`（或使用 `groupPolicy: "open"` 以允許任何成員，仍需 mention）。

## 目標

- 透過 Teams 私訊、群組聊天或頻道與 OpenClaw 對話。
- 保持路由確定性：回覆始終回到訊息來源的頻道。
- 預設安全的頻道行為（除非另行設定，否則需要 mention）。

## 設定寫入

預設情況下，Microsoft Teams 允許由 `/config set|unset` 觸發的設定寫入（需要 `commands.config: true`）。

停用：

```json5
{
  channels: { msteams: { configWrites: false } },
}
```

## 存取控制（DM + 群組）

**DM 存取**

- 預設：`channels.msteams.dmPolicy = "pairing"`。未知發送者在核准前被忽略。
- `channels.msteams.allowFrom` 應使用穩定的 AAD 物件 ID。
- UPN/顯示名稱是可變的；直接匹配預設停用，只有在 `channels.msteams.dangerouslyAllowNameMatching: true` 時才啟用。
- 精靈在憑證允許時可以透過 Microsoft Graph 將名稱解析為 ID。

**群組存取**

- 預設：`channels.msteams.groupPolicy = "allowlist"`（除非新增 `groupAllowFrom`，否則封鎖）。使用 `channels.defaults.groupPolicy` 在未設定時覆蓋預設。
- `channels.msteams.groupAllowFrom` 控制哪些發送者可以在群組聊天/頻道中觸發（退回到 `channels.msteams.allowFrom`）。
- 設定 `groupPolicy: "open"` 允許任何成員（預設仍需 mention）。
- 若要**不允許任何頻道**，設定 `channels.msteams.groupPolicy: "disabled"`。

範例：

```json5
{
  channels: {
    msteams: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["user@org.com"],
    },
  },
}
```

**Teams + 頻道 allowlist**

- 在 `channels.msteams.teams` 下列出 teams 和頻道，限制群組/頻道回覆範圍。
- 鍵應使用穩定的 team ID 和頻道 conversation ID。
- 當 `groupPolicy="allowlist"` 且存在 teams allowlist 時，只有列出的 teams/頻道被接受（需要 mention）。
- 設定精靈接受 `Team/Channel` 條目並為你儲存。
- 啟動時，OpenClaw 將 team/頻道和用戶 allowlist 名稱解析為 ID（當 Graph 權限允許時）並記錄對應；未解析的 team/頻道名稱保留原樣但預設不用於路由，除非啟用 `channels.msteams.dangerouslyAllowNameMatching: true`。

範例：

```json5
{
  channels: {
    msteams: {
      groupPolicy: "allowlist",
      teams: {
        "My Team": {
          channels: {
            General: { requireMention: true },
          },
        },
      },
    },
  },
}
```

## 運作原理

1. 安裝 Microsoft Teams 外掛。
2. 建立 **Azure Bot**（App ID + secret + 租戶 ID）。
3. 建立引用 bot 並包含 RSC 權限的 **Teams App 套件**（見下方）。
4. 將 Teams App 上傳/安裝到 team（或個人範圍用於私訊）。
5. 在 `~/.openclaw/openclaw.json`（或環境變數）中設定 `msteams` 並啟動 gateway。
6. Gateway 預設監聽 `/api/messages` 上的 Bot Framework webhook 流量。

## Azure Bot 設定（前置條件）

設定 OpenClaw 前，你需要建立 Azure Bot 資源。

### 步驟 1：建立 Azure Bot

1. 前往 [Create Azure Bot](https://portal.azure.com/#create/Microsoft.AzureBot)
2. 填寫 **Basics** 分頁：

   | 欄位               | 值                                               |
   | ------------------ | ------------------------------------------------ |
   | **Bot handle**     | 你的 bot 名稱，例如 `openclaw-msteams`（需唯一） |
   | **Subscription**   | 選擇你的 Azure 訂閱                              |
   | **Resource group** | 建立新的或使用現有的                             |
   | **Pricing tier**   | **Free**（用於開發/測試）                        |
   | **Type of App**    | **Single Tenant**（建議，見下方說明）            |
   | **Creation type**  | **Create new Microsoft App ID**                  |

> **棄用說明：** 2025-07-31 後，新的多租戶 bot 建立已棄用。新 bot 請使用 **Single Tenant**。

3. 點擊 **Review + create** → **Create**（等待約 1-2 分鐘）

### 步驟 2：取得憑證

1. 前往你的 Azure Bot 資源 → **Configuration**
2. 複製 **Microsoft App ID** → 這是你的 `appId`
3. 點擊 **Manage Password** → 前往 App Registration
4. 在 **Certificates & secrets** → **New client secret** → 複製 **Value** → 這是你的 `appPassword`
5. 前往 **Overview** → 複製 **Directory (tenant) ID** → 這是你的 `tenantId`

### 步驟 3：設定 Messaging Endpoint

1. 在 Azure Bot → **Configuration**
2. 將 **Messaging endpoint** 設定為你的 webhook URL：
   - 生產環境：`https://your-domain.com/api/messages`
   - 本地開發：使用 tunnel（見下方[本地開發（Tunneling）](#local-development-tunneling)）

### 步驟 4：啟用 Teams 頻道

1. 在 Azure Bot → **Channels**
2. 點擊 **Microsoft Teams** → Configure → Save
3. 接受服務條款

## 本地開發（Tunneling）

Teams 無法連接到 `localhost`。本地開發請使用 tunnel：

**方案 A：ngrok**

```bash
ngrok http 3978
# 複製 https URL，例如 https://abc123.ngrok.io
# 將 messaging endpoint 設定為：https://abc123.ngrok.io/api/messages
```

**方案 B：Tailscale Funnel**

```bash
tailscale funnel 3978
# 使用你的 Tailscale funnel URL 作為 messaging endpoint
```

## Teams Developer Portal（替代方案）

除了手動建立 manifest ZIP，你也可以使用 [Teams Developer Portal](https://dev.teams.microsoft.com/apps)：

1. 點擊 **+ New app**
2. 填寫基本資訊（名稱、描述、開發者資訊）
3. 前往 **App features** → **Bot**
4. 選擇 **Enter a bot ID manually** 並貼上 Azure Bot App ID
5. 勾選範圍：**Personal**、**Team**、**Group Chat**
6. 點擊 **Distribute** → **Download app package**
7. 在 Teams：**Apps** → **Manage your apps** → **Upload a custom app** → 選擇 ZIP

這通常比手動編輯 JSON manifest 更容易。

## 測試 Bot

**方案 A：Azure Web Chat（先驗證 webhook）**

1. 在 Azure Portal → 你的 Azure Bot 資源 → **Test in Web Chat**
2. 傳送訊息——你應該看到回覆
3. 這確認在設定 Teams 前你的 webhook 端點能正常運作

**方案 B：Teams（安裝 App 後）**

1. 安裝 Teams App（sideload 或 org catalog）
2. 在 Teams 中找到 bot 並傳送私訊
3. 確認 gateway 日誌中的入站活動

## 設定（最小文字模式）

1. **安裝 Microsoft Teams 外掛**
   - 從 npm：`openclaw plugins install @openclaw/msteams`
   - 從本地 checkout：`openclaw plugins install ./extensions/msteams`

2. **Bot 註冊**
   - 建立 Azure Bot（見上方）並記下：
     - App ID
     - 用戶端 secret（App password）
     - 租戶 ID（single-tenant）

3. **Teams App Manifest**
   - 包含帶有 `botId = <App ID>` 的 `bot` 條目。
   - Scopes：`personal`、`team`、`groupChat`。
   - `supportsFiles: true`（個人範圍檔案處理必要）。
   - 新增 RSC 權限（見下方）。
   - 建立圖示：`outline.png`（32x32）和 `color.png`（192x192）。
   - 將三個檔案壓縮：`manifest.json`、`outline.png`、`color.png`。

4. **設定 OpenClaw**

   ```json
   {
     "msteams": {
       "enabled": true,
       "appId": "<APP_ID>",
       "appPassword": "<APP_PASSWORD>",
       "tenantId": "<TENANT_ID>",
       "webhook": { "port": 3978, "path": "/api/messages" }
     }
   }
   ```

   也可以使用環境變數：
   - `MSTEAMS_APP_ID`
   - `MSTEAMS_APP_PASSWORD`
   - `MSTEAMS_TENANT_ID`

5. **Bot 端點**
   - 將 Azure Bot Messaging Endpoint 設定為：
     - `https://<host>:3978/api/messages`（或你選擇的路徑/埠）。

6. **執行 gateway**
   - 安裝外掛且存在帶有憑證的 `msteams` 設定時，Teams 頻道自動啟動。

## 歷史記錄上下文

- `channels.msteams.historyLimit` 控制將多少條最近的頻道/群組訊息包裝到 prompt 中。
- 退回到 `messages.groupChat.historyLimit`。設定 `0` 停用（預設 50）。
- DM 歷史可用 `channels.msteams.dmHistoryLimit` 限制（用戶回合）。每用戶覆蓋：`channels.msteams.dms["<user_id>"].historyLimit`。

## 目前的 Teams RSC 權限（Manifest）

這些是我們 Teams App manifest 中**現有的 resourceSpecific 權限**。它們只適用於安裝 App 的 team/聊天中。

**頻道（team 範圍）：**

- `ChannelMessage.Read.Group`（Application）- 無需 @mention 接收所有頻道訊息
- `ChannelMessage.Send.Group`（Application）
- `Member.Read.Group`（Application）
- `Owner.Read.Group`（Application）
- `ChannelSettings.Read.Group`（Application）
- `TeamMember.Read.Group`（Application）
- `TeamSettings.Read.Group`（Application）

**群組聊天：**

- `ChatMessage.Read.Chat`（Application）- 無需 @mention 接收所有群組聊天訊息

## Teams Manifest 範例（部分省略）

最小有效範例，包含必填欄位。請替換 ID 和 URL。

```json
{
  "$schema": "https://developer.microsoft.com/en-us/json-schemas/teams/v1.23/MicrosoftTeams.schema.json",
  "manifestVersion": "1.23",
  "version": "1.0.0",
  "id": "00000000-0000-0000-0000-000000000000",
  "name": { "short": "OpenClaw" },
  "developer": {
    "name": "Your Org",
    "websiteUrl": "https://example.com",
    "privacyUrl": "https://example.com/privacy",
    "termsOfUseUrl": "https://example.com/terms"
  },
  "description": { "short": "OpenClaw in Teams", "full": "OpenClaw in Teams" },
  "icons": { "outline": "outline.png", "color": "color.png" },
  "accentColor": "#5B6DEF",
  "bots": [
    {
      "botId": "11111111-1111-1111-1111-111111111111",
      "scopes": ["personal", "team", "groupChat"],
      "isNotificationOnly": false,
      "supportsCalling": false,
      "supportsVideo": false,
      "supportsFiles": true
    }
  ],
  "webApplicationInfo": {
    "id": "11111111-1111-1111-1111-111111111111"
  },
  "authorization": {
    "permissions": {
      "resourceSpecific": [
        { "name": "ChannelMessage.Read.Group", "type": "Application" },
        { "name": "ChannelMessage.Send.Group", "type": "Application" },
        { "name": "Member.Read.Group", "type": "Application" },
        { "name": "Owner.Read.Group", "type": "Application" },
        { "name": "ChannelSettings.Read.Group", "type": "Application" },
        { "name": "TeamMember.Read.Group", "type": "Application" },
        { "name": "TeamSettings.Read.Group", "type": "Application" },
        { "name": "ChatMessage.Read.Chat", "type": "Application" }
      ]
    }
  }
}
```

### Manifest 注意事項（必填欄位）

- `bots[].botId` **必須**符合 Azure Bot App ID。
- `webApplicationInfo.id` **必須**符合 Azure Bot App ID。
- `bots[].scopes` 必須包含你計劃使用的服務（`personal`、`team`、`groupChat`）。
- `bots[].supportsFiles: true` 是個人範圍檔案處理的必要條件。
- `authorization.permissions.resourceSpecific` 若你想要頻道流量，必須包含頻道讀/寫。

### 更新現有 App

若要更新已安裝的 Teams App（例如新增 RSC 權限）：

1. 用新設定更新 `manifest.json`
2. **遞增 `version` 欄位**（例如 `1.0.0` → `1.1.0`）
3. **重新壓縮** manifest 和圖示（`manifest.json`、`outline.png`、`color.png`）
4. 上傳新的 zip：
   - **方案 A（Teams Admin Center）：** Teams Admin Center → Teams apps → Manage apps → 找到你的 App → Upload new version
   - **方案 B（Sideload）：** 在 Teams → Apps → Manage your apps → Upload a custom app
5. **對於 team 頻道：** 在每個 team 中重新安裝 App 以使新權限生效
6. **完全退出並重新啟動 Teams**（不只是關閉視窗）以清除快取的 App metadata

## 功能：僅 RSC vs Graph

### 只有 **Teams RSC**（已安裝 App，無 Graph API 權限）

可用：

- 讀取頻道訊息**文字**內容。
- 傳送頻道訊息**文字**內容。
- 接收**個人（DM）**檔案附件。

不可用：

- 頻道/群組**圖片或檔案內容**（payload 只包含 HTML 存根）。
- 下載儲存在 SharePoint/OneDrive 中的附件。
- 讀取訊息歷史（超出即時 webhook 事件範圍）。

### 有 **Teams RSC + Microsoft Graph 應用程式權限**

新增：

- 下載已託管的內容（貼入訊息的圖片）。
- 下載儲存在 SharePoint/OneDrive 中的檔案附件。
- 透過 Graph 讀取頻道/聊天訊息歷史。

### RSC vs Graph API

| 功能           | RSC 權限           | Graph API                   |
| -------------- | ------------------ | --------------------------- |
| **即時訊息**   | 是（透過 webhook） | 否（僅輪詢）                |
| **歷史訊息**   | 否                 | 是（可查詢歷史）            |
| **設定複雜度** | 僅需 App manifest  | 需要管理員同意 + token 流程 |
| **離線時可用** | 否（必須執行中）   | 是（隨時查詢）              |

**結論：** RSC 用於即時監聽；Graph API 用於歷史存取。若需要補齊離線時錯過的訊息，你需要帶有 `ChannelMessage.Read.All` 的 Graph API（需要管理員同意）。

## Graph 媒體 + 歷史（頻道必需）

若需要**頻道**中的圖片/檔案或想要獲取**訊息歷史**，必須啟用 Microsoft Graph 權限並授予管理員同意。

1. 在 Entra ID（Azure AD）**App Registration** 中，新增 Microsoft Graph **Application 權限**：
   - `ChannelMessage.Read.All`（頻道附件 + 歷史）
   - `Chat.Read.All` 或 `ChatMessage.Read.All`（群組聊天）
2. 為租戶**授予管理員同意**。
3. 遞增 Teams App **manifest version**，重新上傳，並**在 Teams 中重新安裝 App**。
4. **完全退出並重新啟動 Teams** 以清除快取的 App metadata。

**用戶 @mention 的額外權限：** 對話中的用戶 @mention 直接可用。但若你想動態搜尋和 mention **不在目前對話中的用戶**，需新增 `User.Read.All`（Application）權限並授予管理員同意。

## 已知限制

### Webhook 逾時

Teams 透過 HTTP webhook 傳遞訊息。若處理時間過長（例如 LLM 回覆緩慢），可能出現：

- Gateway 逾時
- Teams 重試訊息（導致重複）
- 回覆遺失

OpenClaw 透過快速返回並主動傳送回覆來處理此問題，但非常慢的回覆仍可能造成問題。

### 格式化

Teams Markdown 比 Slack 或 Discord 更有限：

- 基本格式可用：**粗體**、_斜體_、`code`、連結
- 複雜 Markdown（表格、巢狀列表）可能無法正確渲染
- 支援 Adaptive Cards 用於投票和任意卡片傳送（見下方）

## 設定

主要設定（共享頻道模式請參閱 `/gateway/configuration`）：

- `channels.msteams.enabled`：啟用/停用頻道。
- `channels.msteams.appId`、`channels.msteams.appPassword`、`channels.msteams.tenantId`：bot 憑證。
- `channels.msteams.webhook.port`（預設 `3978`）
- `channels.msteams.webhook.path`（預設 `/api/messages`）
- `channels.msteams.dmPolicy`：`pairing | allowlist | open | disabled`（預設：pairing）
- `channels.msteams.allowFrom`：DM allowlist（建議使用 AAD 物件 ID）。精靈在 Graph 存取可用時設定期間將名稱解析為 ID。
- `channels.msteams.dangerouslyAllowNameMatching`：緊急切換，重新啟用可變的 UPN/顯示名稱匹配和直接 team/頻道名稱路由。
- `channels.msteams.textChunkLimit`：出站文字分塊大小。
- `channels.msteams.chunkMode`：`length`（預設）或 `newline`，在長度分塊前按空白行（段落邊界）分割。
- `channels.msteams.mediaAllowHosts`：入站附件主機 allowlist（預設為 Microsoft/Teams 域名）。
- `channels.msteams.mediaAuthAllowHosts`：在媒體重試時附加 Authorization 標頭的主機 allowlist（預設為 Graph + Bot Framework 主機）。
- `channels.msteams.requireMention`：在頻道/群組中需要 @mention（預設 true）。
- `channels.msteams.replyStyle`：`thread | top-level`（見[回覆樣式：Thread vs Post](#reply-style-threads-vs-posts)）。
- `channels.msteams.teams.<teamId>.replyStyle`：每 team 覆蓋。
- `channels.msteams.teams.<teamId>.requireMention`：每 team 覆蓋。
- `channels.msteams.teams.<teamId>.tools`：預設每 team 工具政策覆蓋（`allow`/`deny`/`alsoAllow`）。
- `channels.msteams.teams.<teamId>.toolsBySender`：預設每 team 每發送者工具政策覆蓋（支援 `"*"` 萬用字元）。
- `channels.msteams.teams.<teamId>.channels.<conversationId>.replyStyle`：每頻道覆蓋。
- `channels.msteams.teams.<teamId>.channels.<conversationId>.requireMention`：每頻道覆蓋。
- `channels.msteams.teams.<teamId>.channels.<conversationId>.tools`：每頻道工具政策覆蓋。
- `channels.msteams.teams.<teamId>.channels.<conversationId>.toolsBySender`：每頻道每發送者工具政策覆蓋。
- `toolsBySender` 鍵應使用明確前綴：`id:`、`e164:`、`username:`、`name:`（舊版無前綴鍵仍只對應到 `id:`）。
- `channels.msteams.sharePointSiteId`：用於群組聊天/頻道中上傳檔案的 SharePoint 站台 ID（見[在群組聊天中傳送檔案](#sending-files-in-group-chats)）。

## 路由與工作階段

- 工作階段金鑰遵循標準 Agent 格式（見 [/concepts/session](/zh-Hant/concepts/session)）：
  - 私訊共享主要工作階段（`agent:<agentId>:<mainKey>`）。
  - 頻道/群組訊息使用 conversation id：
    - `agent:<agentId>:msteams:channel:<conversationId>`
    - `agent:<agentId>:msteams:group:<conversationId>`

## 回覆樣式：Thread vs Post

Teams 最近在相同底層資料模型上引入了兩種頻道 UI 樣式：

| 樣式                    | 描述                           | 建議 `replyStyle` |
| ----------------------- | ------------------------------ | ----------------- |
| **Posts**（傳統）       | 訊息顯示為卡片，下方有巢狀回覆 | `thread`（預設）  |
| **Threads**（類 Slack） | 訊息線性流動，更像 Slack       | `top-level`       |

**問題：** Teams API 不揭露頻道使用哪種 UI 樣式。若使用了錯誤的 `replyStyle`：

- 在 Threads 樣式頻道使用 `thread` → 回覆顯示在巢狀位置，看起來很奇怪
- 在 Posts 樣式頻道使用 `top-level` → 回覆顯示為單獨的頂層文章而非串中

**解決方案：** 根據頻道設定方式，每頻道設定 `replyStyle`：

```json
{
  "msteams": {
    "replyStyle": "thread",
    "teams": {
      "19:abc...@thread.tacv2": {
        "channels": {
          "19:xyz...@thread.tacv2": {
            "replyStyle": "top-level"
          }
        }
      }
    }
  }
}
```

## 附件與圖片

**目前限制：**

- **私訊：** 圖片和檔案附件透過 Teams bot 檔案 API 運作。
- **頻道/群組：** 附件存放在 M365 儲存（SharePoint/OneDrive）中。Webhook payload 只包含 HTML 存根，不含實際檔案位元組。**下載頻道附件需要 Graph API 權限**。

若無 Graph 權限，包含圖片的頻道訊息將以純文字接收（圖片內容無法存取）。
預設情況下，OpenClaw 只從 Microsoft/Teams 主機名稱下載媒體。使用 `channels.msteams.mediaAllowHosts` 覆蓋（使用 `["*"]` 允許任何主機）。
Authorization 標頭只附加到 `channels.msteams.mediaAuthAllowHosts` 中的主機（預設為 Graph + Bot Framework 主機）。請保持此清單嚴格（避免多租戶後綴）。

## 在群組聊天中傳送檔案

Bot 可以使用 FileConsentCard 流程在私訊中傳送檔案（內建）。但**在群組聊天/頻道中傳送檔案**需要額外設定：

| 情境                 | 傳送方式                              | 所需設定                             |
| -------------------- | ------------------------------------- | ------------------------------------ |
| **私訊**             | FileConsentCard → 用戶接受 → bot 上傳 | 直接可用                             |
| **群組聊天/頻道**    | 上傳至 SharePoint → 分享連結          | 需要 `sharePointSiteId` + Graph 權限 |
| **圖片（任何情境）** | Base64 編碼內嵌                       | 直接可用                             |

### 為什麼群組聊天需要 SharePoint

Bot 沒有個人 OneDrive 磁碟機（`/me/drive` Graph API 端點對應用程式身份不適用）。若要在群組聊天/頻道中傳送檔案，bot 需上傳至 **SharePoint 站台**並建立分享連結。

### 設定

1. 在 Entra ID（Azure AD）→ App Registration 中**新增 Graph API 權限**：
   - `Sites.ReadWrite.All`（Application）- 上傳檔案至 SharePoint
   - `Chat.Read.All`（Application）- 選用，啟用每用戶分享連結

2. 為租戶**授予管理員同意**。

3. **取得你的 SharePoint 站台 ID：**

   ```bash
   # 透過 Graph Explorer 或帶有有效 token 的 curl：
   curl -H "Authorization: Bearer $TOKEN" \
     "https://graph.microsoft.com/v1.0/sites/{hostname}:/{site-path}"

   # 範例：位於 "contoso.sharepoint.com/sites/BotFiles" 的站台
   curl -H "Authorization: Bearer $TOKEN" \
     "https://graph.microsoft.com/v1.0/sites/contoso.sharepoint.com:/sites/BotFiles"

   # 回應包含："id": "contoso.sharepoint.com,guid1,guid2"
   ```

4. **設定 OpenClaw：**

   ```json5
   {
     channels: {
       msteams: {
         // ... 其他設定 ...
         sharePointSiteId: "contoso.sharepoint.com,guid1,guid2",
       },
     },
   }
   ```

### 分享行為

| 權限                                    | 分享行為                                 |
| --------------------------------------- | ---------------------------------------- |
| 僅 `Sites.ReadWrite.All`                | 整個組織分享連結（組織中任何人都可存取） |
| `Sites.ReadWrite.All` + `Chat.Read.All` | 每用戶分享連結（只有聊天成員可存取）     |

每用戶分享更安全，因為只有聊天參與者可以存取檔案。若缺少 `Chat.Read.All` 權限，bot 退回到整個組織分享。

### 備援行為

| 情境                                        | 結果                                     |
| ------------------------------------------- | ---------------------------------------- |
| 群組聊天 + 檔案 + 已設定 `sharePointSiteId` | 上傳至 SharePoint，傳送分享連結          |
| 群組聊天 + 檔案 + 未設定 `sharePointSiteId` | 嘗試 OneDrive 上傳（可能失敗），僅傳文字 |
| 個人聊天 + 檔案                             | FileConsentCard 流程（無需 SharePoint）  |
| 任何情境 + 圖片                             | Base64 編碼內嵌（無需 SharePoint）       |

### 檔案儲存位置

上傳的檔案儲存在已設定 SharePoint 站台預設文件庫的 `/OpenClawShared/` 資料夾中。

## 投票（Adaptive Cards）

OpenClaw 以 Adaptive Cards 傳送 Teams 投票（無原生 Teams 投票 API）。

- CLI：`openclaw message poll --channel msteams --target conversation:<id> ...`
- 投票由 gateway 記錄在 `~/.openclaw/msteams-polls.json`。
- Gateway 必須保持在線才能記錄投票。
- 投票不會自動張貼結果摘要（如需請檢查儲存檔案）。

## Adaptive Cards（任意）

使用 `message` 工具或 CLI 向 Teams 用戶或對話傳送任意 Adaptive Card JSON。

`card` 參數接受 Adaptive Card JSON 物件。提供 `card` 時，訊息文字是選用的。

**Agent 工具：**

```json
{
  "action": "send",
  "channel": "msteams",
  "target": "user:<id>",
  "card": {
    "type": "AdaptiveCard",
    "version": "1.5",
    "body": [{ "type": "TextBlock", "text": "Hello!" }]
  }
}
```

**CLI：**

```bash
openclaw message send --channel msteams \
  --target "conversation:19:abc...@thread.tacv2" \
  --card '{"type":"AdaptiveCard","version":"1.5","body":[{"type":"TextBlock","text":"Hello!"}]}'
```

請參閱 [Adaptive Cards 文件](https://adaptivecards.io/) 了解卡片結構和範例。目標格式詳情請見下方[目標格式](#target-formats)。

## 目標格式

MSTeams 目標使用前綴區分用戶和對話：

| 目標類型          | 格式                             | 範例                                          |
| ----------------- | -------------------------------- | --------------------------------------------- |
| 用戶（依 ID）     | `user:<aad-object-id>`           | `user:40a1a0ed-4ff2-4164-a219-55518990c197`   |
| 用戶（依名稱）    | `user:<display-name>`            | `user:John Smith`（需要 Graph API）           |
| 群組/頻道         | `conversation:<conversation-id>` | `conversation:19:abc123...@thread.tacv2`      |
| 群組/頻道（原始） | `<conversation-id>`              | `19:abc123...@thread.tacv2`（若含 `@thread`） |

**CLI 範例：**

```bash
# 依 ID 傳送給用戶
openclaw message send --channel msteams --target "user:40a1a0ed-..." --message "Hello"

# 依顯示名稱傳送給用戶（觸發 Graph API 查詢）
openclaw message send --channel msteams --target "user:John Smith" --message "Hello"

# 傳送至群組聊天或頻道
openclaw message send --channel msteams --target "conversation:19:abc...@thread.tacv2" --message "Hello"

# 傳送 Adaptive Card 至對話
openclaw message send --channel msteams --target "conversation:19:abc...@thread.tacv2" \
  --card '{"type":"AdaptiveCard","version":"1.5","body":[{"type":"TextBlock","text":"Hello"}]}'
```

注意：沒有 `user:` 前綴時，名稱預設為群組/team 解析。依顯示名稱指定人員時請始終使用 `user:`。

## 主動訊息

- 主動訊息只有在用戶互動後才可能發送，因為我們在那時儲存了對話引用。
- DM 政策和 allowlist 限制請參閱 `/gateway/configuration`。

## Team 和 Channel ID（常見陷阱）

Teams URL 中的 `groupId` 查詢參數**不是**用於設定的 team ID。請從 URL 路徑中提取 ID：

**Team URL：**

```
https://teams.microsoft.com/l/team/19%3ABk4j...%40thread.tacv2/conversations?groupId=...
                                    └────────────────────────────┘
                                    Team ID（URL 解碼此部分）
```

**Channel URL：**

```
https://teams.microsoft.com/l/channel/19%3A15bc...%40thread.tacv2/ChannelName?groupId=...
                                      └─────────────────────────┘
                                      Channel ID（URL 解碼此部分）
```

**用於設定：**

- Team ID = `/team/` 後的路徑段（URL 解碼，例如 `19:Bk4j...@thread.tacv2`）
- Channel ID = `/channel/` 後的路徑段（URL 解碼）
- **忽略** `groupId` 查詢參數

## 私人頻道

Bot 在私人頻道中的支援有限：

| 功能                | 標準頻道 | 私人頻道          |
| ------------------- | -------- | ----------------- |
| Bot 安裝            | 是       | 有限              |
| 即時訊息（webhook） | 是       | 可能無法運作      |
| RSC 權限            | 是       | 行為可能不同      |
| @mention            | 是       | 若 bot 可存取則可 |
| Graph API 歷史      | 是       | 是（需要權限）    |

**私人頻道不運作時的替代方案：**

1. 使用標準頻道進行 bot 互動
2. 使用 DM——用戶可以隨時直接訊息 bot
3. 使用 Graph API 進行歷史存取（需要 `ChannelMessage.Read.All`）

## 疑難排解

### 常見問題

- **頻道中圖片不顯示：** 缺少 Graph 權限或管理員同意。重新安裝 Teams App 並完全退出/重新開啟 Teams。
- **頻道中無回覆：** 預設需要 mention；設定 `channels.msteams.requireMention=false` 或按 team/頻道設定。
- **版本不匹配（Teams 仍顯示舊 manifest）：** 移除並重新新增 App，然後完全退出 Teams 以重新整理。
- **Webhook 的 401 Unauthorized：** 手動測試時（無 Azure JWT）為預期行為，意味著端點可達但驗證失敗。請使用 Azure Web Chat 進行正確測試。

### Manifest 上傳錯誤

- **"Icon file cannot be empty"：** Manifest 引用的圖示檔案大小為 0。請建立有效的 PNG 圖示（`outline.png` 為 32x32，`color.png` 為 192x192）。
- **"webApplicationInfo.Id already in use"：** App 仍安裝在另一個 team/聊天中。先找到並卸載它，或等待 5-10 分鐘讓變更傳播。
- **上傳時"Something went wrong"：** 改由 [https://admin.teams.microsoft.com](https://admin.teams.microsoft.com) 上傳，開啟瀏覽器 DevTools（F12）→ Network 分頁，檢查回應主體以獲取實際錯誤。
- **Sideload 失敗：** 嘗試「Upload an app to your org's app catalog」而非「Upload a custom app」——這通常可以繞過 sideload 限制。

### RSC 權限不運作

1. 確認 `webApplicationInfo.id` 完全符合你的 bot App ID
2. 重新上傳 App 並在 team/聊天中重新安裝
3. 檢查你的組織管理員是否封鎖了 RSC 權限
4. 確認你使用了正確的範圍：teams 使用 `ChannelMessage.Read.Group`，群組聊天使用 `ChatMessage.Read.Chat`

## 參考資料

- [Create Azure Bot](https://learn.microsoft.com/en-us/azure/bot-service/bot-service-quickstart-registration) - Azure Bot 設定指南
- [Teams Developer Portal](https://dev.teams.microsoft.com/apps) - 建立/管理 Teams App
- [Teams App manifest schema](https://learn.microsoft.com/en-us/microsoftteams/platform/resources/schema/manifest-schema)
- [Receive channel messages with RSC](https://learn.microsoft.com/en-us/microsoftteams/platform/bots/how-to/conversations/channel-messages-with-rsc)
- [RSC permissions reference](https://learn.microsoft.com/en-us/microsoftteams/platform/graph-api/rsc/resource-specific-consent)
- [Teams bot file handling](https://learn.microsoft.com/en-us/microsoftteams/platform/bots/how-to/bots-filesv4)（頻道/群組需要 Graph）
- [Proactive messaging](https://learn.microsoft.com/en-us/microsoftteams/platform/bots/how-to/conversations/send-proactive-messages)
