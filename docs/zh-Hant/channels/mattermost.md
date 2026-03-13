---
summary: "Mattermost bot 設定與 OpenClaw 設定"
read_when:
  - 設定 Mattermost
  - 除錯 Mattermost 路由
title: "Mattermost"
---

# Mattermost（外掛程式）

狀態：透過外掛程式支援（bot token + WebSocket 事件）。支援頻道、群組和 DM。
Mattermost 是可自行託管的團隊訊息平台；請參閱官方網站 [mattermost.com](https://mattermost.com) 了解產品詳情和下載。

## 需要外掛程式

Mattermost 以外掛程式形式發布，未隨核心安裝捆綁。

透過 CLI 安裝（npm registry）：

```bash
openclaw plugins install @openclaw/mattermost
```

本地 checkout（從 git repo 執行時）：

```bash
openclaw plugins install ./extensions/mattermost
```

若你在設定/上線過程中選擇 Mattermost，且偵測到 git checkout，OpenClaw 將自動提供本地安裝路徑。

詳情：[Plugins](/zh-Hant/tools/plugin)

## 快速設定

1. 安裝 Mattermost 外掛程式。
2. 建立 Mattermost bot 帳號並複製 **bot token**。
3. 複製 Mattermost **base URL**（例如 `https://chat.example.com`）。
4. 設定 OpenClaw 並啟動 gateway。

最小設定：

```json5
{
  channels: {
    mattermost: {
      enabled: true,
      botToken: "mm-token",
      baseUrl: "https://chat.example.com",
      dmPolicy: "pairing",
    },
  },
}
```

## 原生斜線指令

原生斜線指令需要選擇啟用。啟用後，OpenClaw 透過 Mattermost API 註冊 `oc_*` 斜線指令，並在 gateway HTTP server 上接收 callback POST。

```json5
{
  channels: {
    mattermost: {
      commands: {
        native: true,
        nativeSkills: true,
        callbackPath: "/api/channels/mattermost/command",
        // 當 Mattermost 無法直接連接 gateway 時使用（反向代理/公開 URL）。
        callbackUrl: "https://gateway.example.com/api/channels/mattermost/command",
      },
    },
  },
}
```

注意：

- `native: "auto"` 對 Mattermost 預設為停用。設定 `native: true` 啟用。
- 若省略 `callbackUrl`，OpenClaw 從 gateway host/port + `callbackPath` 推導。
- 對於多帳號設定，`commands` 可在頂層或 `channels.mattermost.accounts.<id>.commands` 下設定（帳號值覆蓋頂層欄位）。
- 指令 callback 使用每個指令的 token 驗證，token 檢查失敗時拒絕。
- 可連線需求：callback 端點必須可從 Mattermost server 連接。
  - 除非 Mattermost 和 OpenClaw 在同一主機/網路命名空間執行，否則不要將 `callbackUrl` 設定為 `localhost`。
  - 除非該 URL 會反向代理 `/api/channels/mattermost/command` 至 OpenClaw，否則不要將 `callbackUrl` 設定為你的 Mattermost base URL。
  - 快速檢查：`curl https://<gateway-host>/api/channels/mattermost/command`；GET 應返回 OpenClaw 的 `405 Method Not Allowed`，而非 `404`。
- Mattermost 出站 allowlist 需求：
  - 若你的 callback 目標是私有/tailnet/內部位址，請在 Mattermost `ServiceSettings.AllowedUntrustedInternalConnections` 中加入 callback host/domain。
  - 使用 host/domain 條目，而非完整 URL。
    - 正確：`gateway.tailnet-name.ts.net`
    - 錯誤：`https://gateway.tailnet-name.ts.net`

## 環境變數（預設帳號）

若偏好使用環境變數，在 gateway 主機上設定：

- `MATTERMOST_BOT_TOKEN=...`
- `MATTERMOST_URL=https://chat.example.com`

環境變數只適用於**預設**帳號（`default`）。其他帳號必須使用設定值。

## 聊天模式

Mattermost 自動回覆 DM。頻道行為由 `chatmode` 控制：

- `oncall`（預設）：只在頻道中被 @mention 時回覆。
- `onmessage`：回覆每條頻道訊息。
- `onchar`：當訊息以觸發前綴開頭時回覆。

設定範例：

```json5
{
  channels: {
    mattermost: {
      chatmode: "onchar",
      oncharPrefixes: [">", "!"],
    },
  },
}
```

注意：

- `onchar` 仍回覆明確的 @mention。
- `channels.mattermost.requireMention` 在舊版設定中受尊重，但 `chatmode` 是建議方式。

## Threading（討論串）和工作階段

使用 `channels.mattermost.replyToMode` 控制頻道和群組回覆是保留在主頻道中還是在觸發文章下開始討論串。

- `off`（預設）：只有在入站文章已在討論串中時才在討論串中回覆。
- `first`：對頂層頻道/群組文章，在該文章下開始討論串，並將對話路由到串作用域的工作階段。
- `all`：目前在 Mattermost 上與 `first` 行為相同。
- 私訊忽略此設定，保持非串式。

設定範例：

```json5
{
  channels: {
    mattermost: {
      replyToMode: "all",
    },
  },
}
```

注意：

- 串作用域的工作階段使用觸發文章 ID 作為串根。
- `first` 和 `all` 目前等效，因為一旦 Mattermost 有了串根，後續的分塊和媒體會繼續在同一討論串中。

## 存取控制（DM）

- 預設：`channels.mattermost.dmPolicy = "pairing"`（未知發送者收到配對碼）。
- 透過以下核准：
  - `openclaw pairing list mattermost`
  - `openclaw pairing approve mattermost <CODE>`
- 公開 DM：`channels.mattermost.dmPolicy="open"` 加上 `channels.mattermost.allowFrom=["*"]`。

## 頻道（群組）

- 預設：`channels.mattermost.groupPolicy = "allowlist"`（需要 mention）。
- 使用 `channels.mattermost.groupAllowFrom` 指定允許的發送者（建議使用用戶 ID）。
- `@username` 匹配是可變的，只有在 `channels.mattermost.dangerouslyAllowNameMatching: true` 時才啟用。
- 開放頻道：`channels.mattermost.groupPolicy="open"`（需要 mention）。
- 執行時注意：若 `channels.mattermost` 完全缺失（僅環境變數設定），執行時會退回到 `groupPolicy="allowlist"` 進行群組檢查（即使設定了 `channels.defaults.groupPolicy`）。

## 出站傳遞目標

在 `openclaw message send` 或 cron/webhook 中使用這些目標格式：

- `channel:<id>` 用於頻道
- `user:<id>` 用於 DM
- `@username` 用於 DM（透過 Mattermost API 解析）

純 ID 被視為頻道。

## Reactions（訊息工具）

- 使用 `message action=react` 搭配 `channel=mattermost`。
- `messageId` 是 Mattermost post id。
- `emoji` 接受 `thumbsup` 或 `:+1:` 等名稱（冒號可選）。
- 設定 `remove=true`（布林值）移除 reaction。
- Reaction 新增/移除事件作為系統事件轉發到路由的 agent 工作階段。

範例：

```
message action=react channel=mattermost target=channel:<channelId> messageId=<postId> emoji=thumbsup
message action=react channel=mattermost target=channel:<channelId> messageId=<postId> emoji=thumbsup remove=true
```

設定：

- `channels.mattermost.actions.reactions`：啟用/停用 reaction 動作（預設 true）。
- 每帳號覆蓋：`channels.mattermost.accounts.<id>.actions.reactions`。

## 互動按鈕（訊息工具）

傳送帶有可點擊按鈕的訊息。當用戶點擊按鈕時，agent 收到選擇並可回應。

透過在頻道能力中新增 `inlineButtons` 啟用按鈕：

```json5
{
  channels: {
    mattermost: {
      capabilities: ["inlineButtons"],
    },
  },
}
```

使用帶有 `buttons` 參數的 `message action=send`。按鈕是 2D 陣列（按鈕列）：

```
message action=send channel=mattermost target=channel:<channelId> buttons=[[{"text":"Yes","callback_data":"yes"},{"text":"No","callback_data":"no"}]]
```

按鈕欄位：

- `text`（必要）：顯示標籤。
- `callback_data`（必要）：點擊時返回的值（用作動作 ID）。
- `style`（選用）：`"default"`、`"primary"` 或 `"danger"`。

當用戶點擊按鈕時：

1. 所有按鈕被替換為確認行（例如「✓ **Yes** selected by @user」）。
2. Agent 收到選擇作為入站訊息並回應。

注意：

- 按鈕 callback 使用 HMAC-SHA256 驗證（自動，無需設定）。
- Mattermost 從 API 回應中去除 callback data（安全功能），因此所有按鈕在點擊時都被移除——無法部分移除。
- 包含連字號或底線的動作 ID 會自動清理（Mattermost 路由限制）。

設定：

- `channels.mattermost.capabilities`：能力字串陣列。新增 `"inlineButtons"` 在 agent system prompt 中啟用按鈕工具描述。
- `channels.mattermost.interactions.callbackBaseUrl`：選用的按鈕 callback 外部 base URL（例如 `https://gateway.example.com`）。當 Mattermost 無法直接連接 gateway 的綁定主機時使用。
- 多帳號設定中，也可在 `channels.mattermost.accounts.<id>.interactions.callbackBaseUrl` 下設定相同欄位。
- 若省略 `interactions.callbackBaseUrl`，OpenClaw 從 `gateway.customBindHost` + `gateway.port` 推導 callback URL，然後退回到 `http://localhost:<port>`。
- 可連線規則：按鈕 callback URL 必須可從 Mattermost server 連接。`localhost` 只有在 Mattermost 和 OpenClaw 在同一主機/網路命名空間執行時才有效。
- 若你的 callback 目標是私有/tailnet/內部的，請將其 host/domain 加入 Mattermost `ServiceSettings.AllowedUntrustedInternalConnections`。

### 直接 API 整合（外部指令碼）

外部指令碼和 webhook 可以直接透過 Mattermost REST API 發布按鈕，而無需透過 agent 的 `message` 工具。盡量使用擴展功能中的 `buildButtonAttachments()`；若發布原始 JSON，請遵循以下規則：

**Payload 結構：**

```json5
{
  channel_id: "<channelId>",
  message: "Choose an option:",
  props: {
    attachments: [
      {
        actions: [
          {
            id: "mybutton01", // 僅限英數字元——見下方
            type: "button", // 必要，否則點擊被靜默忽略
            name: "Approve", // 顯示標籤
            style: "primary", // 選用："default"、"primary"、"danger"
            integration: {
              url: "https://gateway.example.com/mattermost/interactions/default",
              context: {
                action_id: "mybutton01", // 必須匹配按鈕 id（用於名稱查詢）
                action: "approve",
                // ... 任何自訂欄位 ...
                _token: "<hmac>", // 見下方 HMAC 章節
              },
            },
          },
        ],
      },
    ],
  },
}
```

**關鍵規則：**

1. Attachments 放在 `props.attachments` 中，而非頂層 `attachments`（靜默忽略）。
2. 每個動作需要 `type: "button"`——沒有它，點擊會被靜默吞掉。
3. 每個動作需要 `id` 欄位——Mattermost 忽略沒有 ID 的動作。
4. 動作 `id` 必須**僅限英數字元**（`[a-zA-Z0-9]`）。連字號和底線會破壞 Mattermost 伺服器端動作路由（返回 404）。使用前請去除它們。
5. `context.action_id` 必須匹配按鈕的 `id`，這樣確認訊息才能顯示按鈕名稱（例如「Approve」）而非原始 ID。
6. `context.action_id` 是必要的——沒有它，互動處理器返回 400。

**HMAC token 生成：**

Gateway 使用 HMAC-SHA256 驗證按鈕點擊。外部指令碼必須生成與 gateway 驗證邏輯匹配的 token：

1. 從 bot token 推導 secret：
   `HMAC-SHA256(key="openclaw-mattermost-interactions", data=botToken)`
2. 建立包含所有欄位（**除了** `_token`）的 context 物件。
3. 使用**排序鍵**和**無空格**序列化（gateway 使用 `JSON.stringify` 搭配排序鍵，產生緊湊輸出）。
4. 簽署：`HMAC-SHA256(key=secret, data=serializedContext)`
5. 在 context 中將結果的十六進位摘要加入 `_token`。

Python 範例：

```python
import hmac, hashlib, json

secret = hmac.new(
    b"openclaw-mattermost-interactions",
    bot_token.encode(), hashlib.sha256
).hexdigest()

ctx = {"action_id": "mybutton01", "action": "approve"}
payload = json.dumps(ctx, sort_keys=True, separators=(",", ":"))
token = hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest()

context = {**ctx, "_token": token}
```

常見 HMAC 陷阱：

- Python 的 `json.dumps` 預設加空格（`{"key": "val"}`）。使用 `separators=(",", ":")` 匹配 JavaScript 的緊湊輸出（`{"key":"val"}`）。
- 始終簽署**所有** context 欄位（減去 `_token`）。Gateway 去除 `_token` 後對其餘所有內容簽署。簽署子集會導致靜默驗證失敗。
- 使用 `sort_keys=True`——gateway 在簽署前排序鍵，而 Mattermost 在儲存 payload 時可能重新排列 context 欄位。
- 從 bot token 推導 secret（確定性的），而非隨機位元組。Secret 在建立按鈕的進程和驗證的 gateway 之間必須相同。

## 目錄適配器

Mattermost 外掛程式包含目錄適配器，透過 Mattermost API 解析頻道和用戶名稱。這使得 `openclaw message send` 和 cron/webhook 傳遞中可以使用 `#channel-name` 和 `@username` 目標。

無需設定——適配器使用帳號設定中的 bot token。

## 多帳號

Mattermost 支援 `channels.mattermost.accounts` 下的多個帳號：

```json5
{
  channels: {
    mattermost: {
      accounts: {
        default: { name: "Primary", botToken: "mm-token", baseUrl: "https://chat.example.com" },
        alerts: { name: "Alerts", botToken: "mm-token-2", baseUrl: "https://alerts.example.com" },
      },
    },
  },
}
```

## 疑難排解

- 頻道中無回覆：確認 bot 在頻道中並 mention 它（oncall），使用觸發前綴（onchar），或設定 `chatmode: "onmessage"`。
- 驗證錯誤：檢查 bot token、base URL 和帳號是否啟用。
- 多帳號問題：環境變數只適用於 `default` 帳號。
- 按鈕顯示為白色方塊：agent 可能傳送了格式錯誤的按鈕資料。確認每個按鈕都有 `text` 和 `callback_data` 欄位。
- 按鈕顯示但點擊無反應：驗證 Mattermost server 設定中的 `AllowedUntrustedInternalConnections` 包含 `127.0.0.1 localhost`，且 ServiceSettings 中的 `EnablePostActionIntegration` 為 `true`。
- 點擊按鈕返回 404：按鈕 `id` 可能包含連字號或底線。Mattermost 的動作路由器在非英數字元 ID 上出錯。只使用 `[a-zA-Z0-9]`。
- Gateway 日誌顯示 `invalid _token`：HMAC 不匹配。確認你簽署了所有 context 欄位（而非子集），使用排序鍵，並使用緊湊 JSON（無空格）。參見上方 HMAC 章節。
- Gateway 日誌顯示 `missing _token in context`：按鈕的 context 中缺少 `_token` 欄位。建立整合 payload 時確保包含它。
- 確認顯示原始 ID 而非按鈕名稱：`context.action_id` 與按鈕的 `id` 不匹配。將兩者設定為相同的清理值。
- Agent 不知道按鈕：在 Mattermost 頻道設定中新增 `capabilities: ["inlineButtons"]`。
