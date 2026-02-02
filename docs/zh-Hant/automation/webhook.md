---
title: "Webhooks"
summary: "Webhook 接入：用於喚醒與隔離的 Agent 執行任務"
read_when:
  - 新增或變更 Webhook 端點時
  - 將外部系統接入 OpenClaw 時
---

# Webhooks

Gateway 可以公開一個小型的 HTTP Webhook 端點供外部觸發器使用。

## 啟用

```json5
{
  hooks: {
    enabled: true,
    token: "shared-secret",
    path: "/hooks",
  },
}
```

備註：

- `hooks.token` 在 `hooks.enabled=true` 時為必要項。
- `hooks.path` 預設為 `/hooks`。

## 認證

每個請求都必須包含 Hook Token。推薦使用 Header：

- `Authorization: Bearer <token>` (推薦)
- `x-openclaw-token: <token>`
- `?token=<token>` (已棄用；會記錄警告，未來主版本會移除)

## 端點

### `POST /hooks/wake`

Payload：

```json
{ "text": "System line", "mode": "now" }
```

- `text` **必要** (字串)：事件說明（例如「收到新電郵」）。
- `mode` 選用（`now` | `next-heartbeat`）：是否觸發立即心跳（預設 `now`）或等待下次定期檢查。

效果：

- 為**主**會話加入系統事件
- 如果 `mode=now`，觸發立即心跳

### `POST /hooks/agent`

Payload：

```json
{
  "message": "Run this",
  "name": "Email",
  "sessionKey": "hook:email:msg-123",
  "wakeMode": "now",
  "deliver": true,
  "channel": "last",
  "to": "+15551234567",
  "model": "openai/gpt-5.2-mini",
  "thinking": "low",
  "timeoutSeconds": 120
}
```

- `message` **必要** (字串)：Agent 要處理的提示或訊息。
- `name` 選用 (字串)：Webhook 的人類可讀名稱（例如「GitHub」），用作會話摘要中的前綴。
- `sessionKey` 選用 (字串)：用於識別 Agent 會話的金鑰。預設為隨機的 `hook:<uuid>`。使用一致的金鑰可以在 Hook 語境中進行多輪對話。
- `wakeMode` 選用（`now` | `next-heartbeat`）：是否觸發立即心跳（預設 `now`）或等待下次定期檢查。
- `deliver` 選用 (布林值)：若為 `true`，Agent 的回應會傳送至通訊頻道。預設為 `true`。純粹的心跳確認回應會自動跳過。
- `channel` 選用 (字串)：投遞頻道。可選：`last`、`whatsapp`、`telegram`、`discord`、`slack`、`mattermost` (plugin)、`signal`、`imessage`、`msteams`。預設為 `last`。
- `to` 選用 (字串)：頻道的收件者識別碼（例如 WhatsApp/Signal 的電話號碼、Telegram 的聊天 ID、Discord/Slack/Mattermost (plugin) 的頻道 ID、MS Teams 的交談 ID）。預設為主會話中的最後收件者。
- `model` 選用 (字串)：模型覆寫（例如 `anthropic/claude-3-5-sonnet` 或別名）。若有限制，必須在允許的模型清單中。
- `thinking` 選用 (字串)：思考等級覆寫（例如 `low`、`medium`、`high`）。
- `timeoutSeconds` 選用 (數字)：Agent 執行的最大持續時間（秒）。

效果：

- 執行**隔離**的 Agent 輪次（獨立的會話金鑰）
- 始終在**主**會話中發佈摘要
- 如果 `wakeMode=now`，觸發立即心跳

### `POST /hooks/<name>` (已映射)

自訂 Hook 名稱可透過 `hooks.mappings` 解析（見設定）。映射可以將任意 Payload 轉換為 `wake` 或 `agent` 動作，並可選擇範本或程式碼轉換。

映射選項（總結）：

- `hooks.presets: ["gmail"]` 啟用內建的 Gmail 映射。
- `hooks.mappings` 讓您在設定中定義 `match`、`action` 和範本。
- `hooks.transformsDir` + `transform.module` 載入 JS/TS 模組進行自訂邏輯。
- 使用 `match.source` 保持通用的擷取端點（payload 驅動的路由）。
- TS transforms 需要 TS 載入器（例如 `bun` 或 `tsx`）或執行時的預編譯 `.js`。
- 在映射上設定 `deliver: true` + `channel`/`to` 以將回覆路由至聊天介面
  (`channel` 預設為 `last` 並回退至 WhatsApp）。
- `allowUnsafeExternalContent: true` 對該 Hook 禁用外部內容安全包裝紙
  (危險；僅用於信任的內部來源)。
- `openclaw webhooks gmail setup` 寫入 `hooks.gmail` 設定供 `openclaw webhooks gmail run` 使用。
  見 [Gmail Pub/Sub](/automation/gmail-pubsub) 查看完整的 Gmail 監看流程。

## 回應

- `/hooks/wake` 傳回 `200`
- `/hooks/agent` 傳回 `202`（非同步執行已啟動）
- 認證失敗傳回 `401`
- 無效 Payload 傳回 `400`
- 過大 Payload 傳回 `413`

## 範例

```bash
curl -X POST http://127.0.0.1:18789/hooks/wake \
  -H 'Authorization: Bearer SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"text":"New email received","mode":"now"}'
```

```bash
curl -X POST http://127.0.0.1:18789/hooks/agent \
  -H 'x-openclaw-token: SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"message":"Summarize inbox","name":"Email","wakeMode":"next-heartbeat"}'
```

### 使用不同的模型

在 Agent Payload（或映射）中加入 `model` 以覆寫該執行的模型：

```bash
curl -X POST http://127.0.0.1:18789/hooks/agent \
  -H 'x-openclaw-token: SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"message":"Summarize inbox","name":"Email","model":"openai/gpt-5.2-mini"}'
```

若您強制執行 `agents.defaults.models`，請確保覆寫模型包含在其中。

```bash
curl -X POST http://127.0.0.1:18789/hooks/gmail \
  -H 'Authorization: Bearer SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"source":"gmail","messages":[{"from":"Ada","subject":"Hello","snippet":"Hi"}]}'
```

## 安全

- 將 Hook 端點保持在 loopback、tailnet 或信任的反向代理後面。
- 使用專屬的 Hook Token；不要重複使用 Gateway 認證 Token。
- 避免在 Webhook 日誌中包含敏感的原始 Payload。
- Hook Payload 預設會被視為不受信任並使用安全邊界進行包裝。
  若您必須對特定 Hook 禁用此功能，請在該 Hook 的映射中設定 `allowUnsafeExternalContent: true`
  (危險)。
