---
title: "Webhook(Webhooks)"
summary: "Webhook 接入：用於喚醒與隔離的 Agent 執行任務"
read_when:
  - 新增或變更 Webhook 端點時
  - 將外部系統接入 OpenClaw 時
---
# Webhooks

Gateway 提供了一個輕量級的 HTTP Webhook 端點，供外部系統觸發 Agent 任務。

## 啟用方式

```json5
{
  hooks: {
    enabled: true,
    token: "您的共享金鑰",
    path: "/hooks"
  }
}
```

注意：啟用 `hooks.enabled` 時必須提供 `hooks.token`。

## 認證 (Auth)
每個請求都必須包含 Hook Token。推薦使用以下 Header：
- `Authorization: Bearer <token>` (推薦)
- `x-openclaw-token: <token>`

## 預設端點

### `POST /hooks/wake` (主會話喚醒)
- **作用**：在**主會話**中加入一條系統事件。
- **模式**：可設定 `now`（立即執行心跳）或 `next-heartbeat`（隨下次排程執行）。

### `POST /hooks/agent` (隔離執行)
- **作用**：執行一個**隔離**的 Agent 輪次（具備獨立的會話 Key）。
- **投遞**：可設定 `deliver: true` 將回應發送至指定的通訊頻道（如 WhatsApp/Telegram）。

## 自訂映射端點：`POST /hooks/<name>`
您可以透由 `hooks.mappings` 配置自訂的端點名稱。這允許您將任意格式的 Payload 轉換為 OpenClaw 可理解的 `wake` 或 `agent` 動作。

- **Presets**：`hooks.presets: ["gmail"]` 會啟用內建的 Gmail 映射。
- **Transforms**：支援透過 JS/TS 模組自訂數據轉換邏輯。

## 操作範例 (curl)

**喚醒主會話**：
```bash
curl -X POST http://127.0.0.1:18789/hooks/wake \
  -H 'Authorization: Bearer 您的密鑰' \
  -H 'Content-Type: application/json' \
  -d '{"text":"收到新郵件","mode":"now"}'
```

**指定模型執行隔離任務**：
```bash
curl -X POST http://127.0.0.1:18789/hooks/agent \
  -H 'x-openclaw-token: 您的密鑰' \
  -H 'Content-Type: application/json' \
  -d '{"message":"摘要收件匣內容","name":"Email","model":"openai/gpt-5.2-mini"}'
```

## 安全設定
- 建議將 Webhook 端點保持在 loopback (本地) 或 Tailnet 網路內。
- 建議使用專屬的 Hook Token，不要與 Gateway 認證 Token 共用。
- 預設情況下，Webhook 傳入的內容會被視為「不可信」，並加上安全邊界保護。
