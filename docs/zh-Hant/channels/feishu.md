---
summary: "Feishu bot 概觀、功能與設定"
read_when:
  - 您想連接 Feishu/Lark bot
  - 您正在設定 Feishu 頻道
title: "Feishu（飛書）"
---

# Feishu bot

Feishu（飛書）是公司用於訊息傳遞和協作的團隊聊天平台。此外掛使用平台的 WebSocket 事件訂閱將 OpenClaw 連接到 Feishu/Lark bot，以便可以接收訊息而無需公開 webhook URL。

---

## 需要外掛程式

安裝 Feishu 外掛程式：

```bash
openclaw plugins install @openclaw/feishu
```

本機簽出（從 git 儲存庫執行時）：

```bash
openclaw plugins install ./extensions/feishu
```

---

## 快速開始

有兩種方法來新增 Feishu 頻道：

### 方法 1：上線精靈（推薦）

如果您剛安裝 OpenClaw，執行精靈：

```bash
openclaw onboard
```

精靈會引導您完成：

1. 建立 Feishu 應用程式並收集認證
2. 在 OpenClaw 中設定應用程式認證
3. 啟動 gateway

✅ **設定後**，檢查 gateway 狀態：

- `openclaw gateway status`
- `openclaw logs --follow`

### 方法 2：CLI 設定

如果您已完成初始安裝，透過 CLI 新增頻道：

```bash
openclaw channels add
```

選擇 **Feishu**，然後輸入應用程式 ID 和應用程式機密。

✅ **設定後**，管理 gateway：

- `openclaw gateway status`
- `openclaw gateway restart`
- `openclaw logs --follow`

---

## 步驟 1：建立 Feishu 應用程式

### 1. 開啟 Feishu 開放平台

訪問 [Feishu 開放平台](https://open.feishu.cn/app)並登入。

Lark（全球）租戶應使用 [https://open.larksuite.com/app](https://open.larksuite.com/app)，並在 Feishu 設定中設定 `domain: "lark"`。

### 2. 建立應用程式

1. 按一下 **建立企業應用程式**
2. 填入應用程式名稱 + 描述
3. 選擇應用程式圖示

### 3. 複製認證

從 **認證與基本資訊**，複製：

- **應用程式 ID**（格式：`cli_xxx`）
- **應用程式機密**

❗ **重要**：保持應用程式機密私密。

### 4. 設定權限

在 **權限**上，按一下 **批次匯入**並貼上：

```json
{
  "scopes": {
    "tenant": [
      "aily:file:read",
      "aily:file:write",
      "application:application.app_message_stats.overview:readonly",
      "application:application:self_manage",
      "application:bot.menu:write",
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

### 5. 啟用 bot 功能

在 **應用程式功能** > **Bot**：

1. 啟用 bot 功能
2. 設定 bot 名稱

### 6. 設定事件訂閱

⚠️ **重要**：在設定事件訂閱之前，請確保：

1. 您已針對 Feishu 執行 `openclaw channels add`
2. gateway 正在執行（`openclaw gateway status`）

在 **事件訂閱**：

1. 選擇 **使用長連接來接收事件**（WebSocket）
2. 新增事件：`im.message.receive_v1`

⚠️ 如果 gateway 未執行，長連接設定可能無法保存。

### 7. 發佈應用程式

1. 在 **版本管理與發佈**中建立版本
2. 提交審核並發佈
3. 等待管理員核准（企業應用程式通常自動核准）

---

## 步驟 2：設定 OpenClaw

### 使用精靈設定（推薦）

```bash
openclaw channels add
```

選擇 **Feishu**，並貼上您的應用程式 ID + 應用程式機密。

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

### 透過環境變數設定

```bash
export FEISHU_APP_ID="cli_xxx"
export FEISHU_APP_SECRET="xxx"
```

### Lark（全球）網域

如果您的租戶位於 Lark（國際），將網域設定為 `lark`（或完整網域字串）。您可以在 `channels.feishu.domain` 或每個帳戶（`channels.feishu.accounts.<id>.domain`）設定它。

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

---

## 步驟 3：啟動 + 測試

### 1. 啟動 gateway

```bash
openclaw gateway
```

### 2. 傳送測試訊息

在 Feishu 中，找到您的 bot 並傳送訊息。

### 3. 核准配對

根據預設，bot 會使用配對代碼回覆。核准它：

```bash
openclaw pairing approve feishu <CODE>
```

核准後，您可以正常聊天。

---

## 概觀

- **Feishu bot 頻道**：由 gateway 管理的 Feishu bot
- **確定性路由**：回覆始終返回至 Feishu
- **會話隔離**：DM 共享主會話；群組已隔離
- **WebSocket 連接**：透過 Feishu SDK 的長連接，無需公開 URL

---

## 存取控制

### 直接訊息

- **預設**：`dmPolicy: "pairing"`（未知使用者取得配對代碼）
- **核准配對**：

  ```bash
  openclaw pairing list feishu
  openclaw pairing approve feishu <CODE>
  ```

- **allowlist 模式**：在 `channels.feishu.allowFrom` 設定允許的 Open ID

### 群組聊天

**1. 群組策略** (`channels.feishu.groupPolicy`)：

- `"open"` = 允許群組中的所有人（預設）
- `"allowlist"` = 僅允許 `groupAllowFrom`
- `"disabled"` = 停用群組訊息

**2. 提及要求** (`channels.feishu.groups.<chat_id>.requireMention`)：

- `true` = 需要 @mention（預設）
- `false` = 不需要提及即可回應

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

### 僅允許群組中的特定使用者

```json5
{
  channels: {
    feishu: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["ou_xxx", "ou_yyy"],
    },
  },
}
```

---

## 取得群組/使用者 ID

### 群組 ID (chat_id)

群組 ID 看起來像 `oc_xxx`。

**方法 1（推薦）**

1. 啟動 gateway 並在群組中 @mention bot
2. 執行 `openclaw logs --follow` 並查找 `chat_id`

**方法 2**

使用 Feishu API 除錯工具列出群組聊天。

### 使用者 ID (open_id)

使用者 ID 看起來像 `ou_xxx`。

**方法 1（推薦）**

1. 啟動 gateway 並對 bot 進行 DM
2. 執行 `openclaw logs --follow` 並查找 `open_id`

**方法 2**

檢查配對請求以瞭解使用者 Open ID：

```bash
openclaw pairing list feishu
```

---

## 常見指令

| 命令      | 描述          |
| --------- | ------------- |
| `/status` | 顯示 bot 狀態 |
| `/reset`  | 重設會話      |
| `/model`  | 顯示/切換模型 |

> 注意：Feishu 尚不支援原生命令功能表，因此命令必須以文字形式傳送。

## Gateway 管理命令

| 命令                       | 描述                   |
| -------------------------- | ---------------------- |
| `openclaw gateway status`  | 顯示 gateway 狀態      |
| `openclaw gateway install` | 安裝/啟動 gateway 服務 |
| `openclaw gateway stop`    | 停止 gateway 服務      |
| `openclaw gateway restart` | 重新啟動 gateway 服務  |
| `openclaw logs --follow`   | 跟隨 gateway 日誌      |

---

## 除錯

### Bot 在群組聊天中不回應

1. 確保 bot 已新增至群組
2. 確保您 @mention bot（預設行為）
3. 檢查 `groupPolicy` 未設定為 `"disabled"`
4. 檢查日誌：`openclaw logs --follow`

### Bot 未收到訊息

1. 確保應用程式已發佈並獲得核准
2. 確保事件訂閱包含 `im.message.receive_v1`
3. 確保 **長連接** 已啟用
4. 確保應用程式權限完整
5. 確保 gateway 正在執行：`openclaw gateway status`
6. 檢查日誌：`openclaw logs --follow`

### 應用程式機密洩露

1. 在 Feishu 開放平台重設應用程式機密
2. 在您的設定中更新應用程式機密
3. 重新啟動 gateway

### 訊息傳送失敗

1. 確保應用程式具有 `im:message:send_as_bot` 權限
2. 確保應用程式已發佈
3. 檢查日誌中的詳細錯誤

---

## 進階設定

### 多個帳戶

```json5
{
  channels: {
    feishu: {
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

### 訊息限制

- `textChunkLimit`：輸出文字區塊大小（預設：2000 字元）
- `mediaMaxMb`：媒體上傳/下載限制（預設：30MB）

### 串流

Feishu 支援透過互動卡片進行串流回覆。啟用後，bot 會在產生文字時更新卡片。

```json5
{
  channels: {
    feishu: {
      streaming: true, // 啟用串流卡片輸出（預設為 true）
      blockStreaming: true, // 啟用區塊級串流（預設為 true）
    },
  },
}
```

設定 `streaming: false` 以在傳送前等待完整回覆。

### 多 Agent 路由

使用 `bindings` 將 Feishu DM 或群組路由到不同的 Agent。

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
- `match.peer.id`：使用者 Open ID（`ou_xxx`）或群組 ID（`oc_xxx`）

查看[取得群組/使用者 ID](#取得群組使用者-id) 以取得查找提示。

---

## 設定參考

完整設定：[Gateway 設定](/zh-Hant/gateway/configuration)

關鍵選項：

| 設定                                              | 描述                           | 預設      |
| ------------------------------------------------- | ------------------------------ | --------- |
| `channels.feishu.enabled`                         | 啟用/停用頻道                  | `true`    |
| `channels.feishu.domain`                          | API 網域（`feishu` 或 `lark`） | `feishu`  |
| `channels.feishu.accounts.<id>.appId`             | 應用程式 ID                    | -         |
| `channels.feishu.accounts.<id>.appSecret`         | 應用程式機密                   | -         |
| `channels.feishu.accounts.<id>.domain`            | 每帳戶 API 網域覆蓋            | `feishu`  |
| `channels.feishu.dmPolicy`                        | DM 策略                        | `pairing` |
| `channels.feishu.allowFrom`                       | DM allowlist（open_id 列表）   | -         |
| `channels.feishu.groupPolicy`                     | 群組策略                       | `open`    |
| `channels.feishu.groupAllowFrom`                  | 群組 allowlist                 | -         |
| `channels.feishu.groups.<chat_id>.requireMention` | 需要 @mention                  | `true`    |
| `channels.feishu.groups.<chat_id>.enabled`        | 啟用群組                       | `true`    |
| `channels.feishu.textChunkLimit`                  | 訊息區塊大小                   | `2000`    |
| `channels.feishu.mediaMaxMb`                      | 媒體大小限制                   | `30`      |
| `channels.feishu.streaming`                       | 啟用串流卡片輸出               | `true`    |
| `channels.feishu.blockStreaming`                  | 啟用區塊串流                   | `true`    |

---

## dmPolicy 參考

| 值            | 行為                                            |
| ------------- | ----------------------------------------------- |
| `"pairing"`   | **預設。** 未知使用者取得配對代碼；必須核准     |
| `"allowlist"` | 只有 `allowFrom` 中的使用者可以聊天             |
| `"open"`      | 允許所有使用者（需要在 allowFrom 中使用 `"*"`） |
| `"disabled"`  | 停用 DM                                         |

---

## 支援的訊息類型

### 接收

- ✅ 文字
- ✅ 豐富文字（發佈）
- ✅ 影像
- ✅ 檔案
- ✅ 音聲
- ✅ 影片
- ✅ 貼紙

### 傳送

- ✅ 文字
- ✅ 影像
- ✅ 檔案
- ✅ 音聲
- ⚠️ 豐富文字（部分支援）
