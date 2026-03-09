---
summary: "Feishu bot 概觀、功能與設定"
read_when:
  - 您想連接 Feishu/Lark bot
  - 您正在設定 Feishu 頻道
title: "Feishu"
---

# Feishu bot

Feishu（Lark）是企業用於訊息傳遞與協作的團隊聊天平台。此外掛程式透過平台的 WebSocket 事件訂閱將 OpenClaw 連接至 Feishu/Lark bot，無需公開 webhook URL 即可接收訊息。

---

## 內建外掛程式

Feishu 隨目前的 OpenClaw 版本內建捆綁，無需單獨安裝外掛程式。

若你使用不包含內建 Feishu 的舊版本或自訂安裝，請手動安裝：

```bash
openclaw plugins install @openclaw/feishu
```

---

## 快速開始

新增 Feishu 頻道有兩種方式：

### 方法 1：上線精靈（建議）

若你剛安裝 OpenClaw，執行精靈：

```bash
openclaw onboard
```

精靈將引導你完成：

1. 建立 Feishu 應用程式並收集憑證
2. 在 OpenClaw 中設定應用程式憑證
3. 啟動 gateway

✅ **設定完成後**，檢查 gateway 狀態：

- `openclaw gateway status`
- `openclaw logs --follow`

### 方法 2：CLI 設定

若你已完成初始安裝，透過 CLI 新增頻道：

```bash
openclaw channels add
```

選擇 **Feishu**，然後輸入 App ID 和 App Secret。

✅ **設定完成後**，管理 gateway：

- `openclaw gateway status`
- `openclaw gateway restart`
- `openclaw logs --follow`

---

## 步驟 1：建立 Feishu 應用程式

### 1. 開啟 Feishu 開放平台

前往 [Feishu 開放平台](https://open.feishu.cn/app) 並登入。

Lark（全球）租戶應使用 [https://open.larksuite.com/app](https://open.larksuite.com/app)，並在 Feishu 設定中設定 `domain: "lark"`。

### 2. 建立應用程式

1. 點擊**建立企業自建應用**
2. 填寫應用程式名稱 + 描述
3. 選擇應用程式圖示

![建立企業自建應用](../images/feishu-step2-create-app.png)

### 3. 複製憑證

從**憑證與基本資訊**複製：

- **App ID**（格式：`cli_xxx`）
- **App Secret**

❗ **重要：** 請保管好 App Secret。

![取得憑證](../images/feishu-step3-credentials.png)

### 4. 設定權限

在**權限管理**中，點擊**批量導入**並貼上：

```json
{
  "scopes": {
    "tenant": [
      "aily:file:read",
      "aily:file:write",
      "application:application.app_message_stats.overview:readonly",
      "application:application:self_manage",
      "application:bot.menu:write",
      "cardkit:card:read",
      "cardkit:card:write",
      "contact:user.employee_id:readonly",
      "corehr:file:download",
      "event:ip_list",
      "im:chat.access_event.bot_p2p_chat:read",
      "im:chat.members:bot_access",
      "im:message",
      "im:message.group_at_msg:readonly",
      "im:message.p2p_msg:readonly",
      "im:message:readonly",
      "im:message:send_as_bot",
      "im:resource"
    ],
    "user": ["aily:file:read", "aily:file:write", "im:chat.access_event.bot_p2p_chat:read"]
  }
}
```

![設定權限](../images/feishu-step4-permissions.png)

### 5. 啟用 bot 能力

在**應用能力** > **機器人**：

1. 啟用機器人能力
2. 設定機器人名稱

![啟用 bot 能力](../images/feishu-step5-bot-capability.png)

### 6. 設定事件訂閱

⚠️ **重要：** 在設定事件訂閱前，請確認：

1. 你已執行 `openclaw channels add` 設定 Feishu
2. Gateway 正在執行（`openclaw gateway status`）

在**事件訂閱**中：

1. 選擇**使用長連接接收事件**（WebSocket）
2. 新增事件：`im.message.receive_v1`

⚠️ 若 gateway 未執行，長連接設定可能無法儲存。

![設定事件訂閱](../images/feishu-step6-event-subscription.png)

### 7. 發布應用程式

1. 在**版本管理與發布**中建立版本
2. 提交審核並發布
3. 等待管理員核准（企業應用通常自動核准）

---

## 步驟 2：設定 OpenClaw

### 使用精靈設定（建議）

```bash
openclaw channels add
```

選擇 **Feishu** 並貼上你的 App ID + App Secret。

### 透過設定檔設定

編輯 `~/.openclaw/openclaw.json`：

```json5
{
  channels: {
    feishu: {
      enabled: true,
      dmPolicy: "pairing",
      accounts: {
        main: {
          appId: "cli_xxx",
          appSecret: "xxx",
          botName: "My AI assistant",
        },
      },
    },
  },
}
```

若你使用 `connectionMode: "webhook"`，請設定 `verificationToken`。Feishu webhook server 預設綁定至 `127.0.0.1`；僅在你確實需要不同綁定位址時才設定 `webhookHost`。

#### Verification Token（webhook 模式）

使用 webhook 模式時，在設定中設定 `channels.feishu.verificationToken`。取得該值：

1. 在 Feishu 開放平台，開啟你的應用程式
2. 前往**開發配置** → **事件與回調**
3. 開啟**加密策略**標籤
4. 複製 **Verification Token**

![Verification Token 位置](../images/feishu-verification-token.png)

### 透過環境變數設定

```bash
export FEISHU_APP_ID="cli_xxx"
export FEISHU_APP_SECRET="xxx"
```

### Lark（全球）網域

若你的租戶在 Lark（國際版），請將網域設定為 `lark`（或完整網域字串）。可在 `channels.feishu.domain` 或每個帳號（`channels.feishu.accounts.<id>.domain`）設定。

```json5
{
  channels: {
    feishu: {
      domain: "lark",
      accounts: {
        main: {
          appId: "cli_xxx",
          appSecret: "xxx",
        },
      },
    },
  },
}
```

### 配額最佳化旗標

你可以使用兩個選用旗標減少 Feishu API 使用量：

- `typingIndicator`（預設 `true`）：當為 `false` 時，跳過 typing reaction 呼叫。
- `resolveSenderNames`（預設 `true`）：當為 `false` 時，跳過發送者設定檔查詢呼叫。

可在頂層或每個帳號設定：

```json5
{
  channels: {
    feishu: {
      typingIndicator: false,
      resolveSenderNames: false,
      accounts: {
        main: {
          appId: "cli_xxx",
          appSecret: "xxx",
          typingIndicator: true,
          resolveSenderNames: false,
        },
      },
    },
  },
}
```

---

## 步驟 3：啟動 + 測試

### 1. 啟動 gateway

```bash
openclaw gateway
```

### 2. 傳送測試訊息

在 Feishu 中找到你的 bot 並傳送訊息。

### 3. 核准配對

預設情況下，bot 會回覆配對碼。核准它：

```bash
openclaw pairing approve feishu <CODE>
```

核准後，你可以正常聊天。

---

## 概覽

- **Feishu bot 頻道**：由 gateway 管理的 Feishu bot
- **確定性路由**：回覆始終返回 Feishu
- **工作階段隔離**：DM 共享主要工作階段；群組隔離
- **WebSocket 連線**：透過 Feishu SDK 的長連接，無需公開 URL

---

## 存取控制

### 直接訊息

- **預設**：`dmPolicy: "pairing"`（未知用戶收到配對碼）
- **核准配對**：

  ```bash
  openclaw pairing list feishu
  openclaw pairing approve feishu <CODE>
  ```

- **Allowlist 模式**：用允許的 Open ID 設定 `channels.feishu.allowFrom`

### 群組聊天

**1. 群組政策**（`channels.feishu.groupPolicy`）：

- `"open"` = 允許群組中的所有人（預設）
- `"allowlist"` = 只允許 `groupAllowFrom`
- `"disabled"` = 停用群組訊息

**2. Mention 要求**（`channels.feishu.groups.<chat_id>.requireMention`）：

- `true` = 需要 @mention（預設）
- `false` = 無需 mention 即回覆

---

## 群組設定範例

### 允許所有群組，需要 @mention（預設）

```json5
{
  channels: {
    feishu: {
      groupPolicy: "open",
      // 預設 requireMention: true
    },
  },
}
```

### 允許所有群組，不需要 @mention

```json5
{
  channels: {
    feishu: {
      groups: {
        oc_xxx: { requireMention: false },
      },
    },
  },
}
```

### 只允許特定群組

```json5
{
  channels: {
    feishu: {
      groupPolicy: "allowlist",
      // Feishu 群組 ID（chat_id）格式如：oc_xxx
      groupAllowFrom: ["oc_xxx", "oc_yyy"],
    },
  },
}
```

### 限制哪些發送者可以在群組中傳訊息（發送者 allowlist）

除了允許群組本身，**所有訊息**在該群組中還受到發送者 open_id 的控制：只有列於 `groups.<chat_id>.allowFrom` 的用戶的訊息才會被處理；其他成員的訊息會被忽略（這是完整的發送者層級控制，不僅限於 /reset 或 /new 等控制指令）。

```json5
{
  channels: {
    feishu: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["oc_xxx"],
      groups: {
        oc_xxx: {
          // Feishu 用戶 ID（open_id）格式如：ou_xxx
          allowFrom: ["ou_user1", "ou_user2"],
        },
      },
    },
  },
}
```

---

## 取得群組/用戶 ID

### 群組 ID（chat_id）

群組 ID 格式如 `oc_xxx`。

**方法 1（建議）**

1. 啟動 gateway 並在群組中 @mention bot
2. 執行 `openclaw logs --follow` 並查找 `chat_id`

**方法 2**

使用 Feishu API 偵錯工具列出群組聊天。

### 用戶 ID（open_id）

用戶 ID 格式如 `ou_xxx`。

**方法 1（建議）**

1. 啟動 gateway 並傳 DM 給 bot
2. 執行 `openclaw logs --follow` 並查找 `open_id`

**方法 2**

從配對請求取得用戶 Open ID：

```bash
openclaw pairing list feishu
```

---

## 常用指令

| 指令      | 說明          |
| --------- | ------------- |
| `/status` | 顯示 bot 狀態 |
| `/reset`  | 重置工作階段  |
| `/model`  | 顯示/切換模型 |

> 注意：Feishu 目前不支援原生指令選單，所以指令必須以文字傳送。

## Gateway 管理指令

| 指令                       | 說明                   |
| -------------------------- | ---------------------- |
| `openclaw gateway status`  | 顯示 gateway 狀態      |
| `openclaw gateway install` | 安裝/啟動 gateway 服務 |
| `openclaw gateway stop`    | 停止 gateway 服務      |
| `openclaw gateway restart` | 重啟 gateway 服務      |
| `openclaw logs --follow`   | 追蹤 gateway 日誌      |

---

## 疑難排解

### Bot 在群組聊天中不回覆

1. 確認 bot 已加入群組
2. 確認你 @mention 了 bot（預設行為）
3. 檢查 `groupPolicy` 是否未設定為 `"disabled"`
4. 檢查日誌：`openclaw logs --follow`

### Bot 收不到訊息

1. 確認應用程式已發布並核准
2. 確認事件訂閱包含 `im.message.receive_v1`
3. 確認已啟用**長連接**
4. 確認應用程式權限完整
5. 確認 gateway 正在執行：`openclaw gateway status`
6. 檢查日誌：`openclaw logs --follow`

### App Secret 洩漏

1. 在 Feishu 開放平台重置 App Secret
2. 在設定中更新 App Secret
3. 重啟 gateway

### 訊息傳送失敗

1. 確認應用程式有 `im:message:send_as_bot` 權限
2. 確認應用程式已發布
3. 檢查日誌以取得詳細錯誤

---

## 進階設定

### 多帳號

```json5
{
  channels: {
    feishu: {
      defaultAccount: "main",
      accounts: {
        main: {
          appId: "cli_xxx",
          appSecret: "xxx",
          botName: "Primary bot",
        },
        backup: {
          appId: "cli_yyy",
          appSecret: "yyy",
          botName: "Backup bot",
          enabled: false,
        },
      },
    },
  },
}
```

`defaultAccount` 控制出站 API 未明確指定 `accountId` 時使用哪個 Feishu 帳號。

### 訊息限制

- `textChunkLimit`：出站文字區塊大小（預設：2000 字元）
- `mediaMaxMb`：媒體上傳/下載限制（預設：30MB）

### 串流

Feishu 透過互動卡片支援串流回覆。啟用後，bot 在生成文字時會更新卡片。

```json5
{
  channels: {
    feishu: {
      streaming: true, // 啟用串流卡片輸出（預設 true）
      blockStreaming: true, // 啟用區塊層級串流（預設 true）
    },
  },
}
```

設定 `streaming: false` 以等待完整回覆後再傳送。

### 多 agent 路由

使用 `bindings` 將 Feishu DM 或群組路由到不同的 agent。

```json5
{
  agents: {
    list: [
      { id: "main" },
      {
        id: "clawd-fan",
        workspace: "/home/user/clawd-fan",
        agentDir: "/home/user/.openclaw/agents/clawd-fan/agent",
      },
      {
        id: "clawd-xi",
        workspace: "/home/user/clawd-xi",
        agentDir: "/home/user/.openclaw/agents/clawd-xi/agent",
      },
    ],
  },
  bindings: [
    {
      agentId: "main",
      match: {
        channel: "feishu",
        peer: { kind: "direct", id: "ou_xxx" },
      },
    },
    {
      agentId: "clawd-fan",
      match: {
        channel: "feishu",
        peer: { kind: "direct", id: "ou_yyy" },
      },
    },
    {
      agentId: "clawd-xi",
      match: {
        channel: "feishu",
        peer: { kind: "group", id: "oc_zzz" },
      },
    },
  ],
}
```

路由欄位：

- `match.channel`：`"feishu"`
- `match.peer.kind`：`"direct"` 或 `"group"`
- `match.peer.id`：用戶 Open ID（`ou_xxx`）或群組 ID（`oc_xxx`）

請參閱[取得群組/用戶 ID](#取得群組用戶-id)了解查詢技巧。

---

## 設定參考

完整設定：[Gateway configuration](/zh-Hant/gateway/configuration)

主要選項：

| 設定                                              | 說明                           | 預設值           |
| ------------------------------------------------- | ------------------------------ | ---------------- |
| `channels.feishu.enabled`                         | 啟用/停用頻道                  | `true`           |
| `channels.feishu.domain`                          | API 網域（`feishu` 或 `lark`） | `feishu`         |
| `channels.feishu.connectionMode`                  | 事件傳輸模式                   | `websocket`      |
| `channels.feishu.defaultAccount`                  | 出站路由的預設帳號 ID          | `default`        |
| `channels.feishu.verificationToken`               | webhook 模式必要               | -                |
| `channels.feishu.webhookPath`                     | Webhook 路由路徑               | `/feishu/events` |
| `channels.feishu.webhookHost`                     | Webhook 綁定主機               | `127.0.0.1`      |
| `channels.feishu.webhookPort`                     | Webhook 綁定埠                 | `3000`           |
| `channels.feishu.accounts.<id>.appId`             | App ID                         | -                |
| `channels.feishu.accounts.<id>.appSecret`         | App Secret                     | -                |
| `channels.feishu.accounts.<id>.domain`            | 每帳號 API 網域覆蓋            | `feishu`         |
| `channels.feishu.dmPolicy`                        | DM 政策                        | `pairing`        |
| `channels.feishu.allowFrom`                       | DM allowlist（open_id 清單）   | -                |
| `channels.feishu.groupPolicy`                     | 群組政策                       | `open`           |
| `channels.feishu.groupAllowFrom`                  | 群組 allowlist                 | -                |
| `channels.feishu.groups.<chat_id>.requireMention` | 需要 @mention                  | `true`           |
| `channels.feishu.groups.<chat_id>.enabled`        | 啟用群組                       | `true`           |
| `channels.feishu.textChunkLimit`                  | 訊息區塊大小                   | `2000`           |
| `channels.feishu.mediaMaxMb`                      | 媒體大小限制                   | `30`             |
| `channels.feishu.streaming`                       | 啟用串流卡片輸出               | `true`           |
| `channels.feishu.blockStreaming`                  | 啟用區塊串流                   | `true`           |

---

## dmPolicy 參考

| 值            | 行為                                          |
| ------------- | --------------------------------------------- |
| `"pairing"`   | **預設。** 未知用戶收到配對碼；必須核准       |
| `"allowlist"` | 只有 `allowFrom` 中的用戶可以聊天             |
| `"open"`      | 允許所有用戶（需要 `allowFrom` 中包含 `"*"`） |
| `"disabled"`  | 停用 DM                                       |

---

## 支援的訊息類型

### 接收

- ✅ 文字
- ✅ 富文字（post）
- ✅ 圖片
- ✅ 檔案
- ✅ 音訊
- ✅ 影片
- ✅ 貼圖

### 傳送

- ✅ 文字
- ✅ 圖片
- ✅ 檔案
- ✅ 音訊
- ⚠️ 富文字（部分支援）
