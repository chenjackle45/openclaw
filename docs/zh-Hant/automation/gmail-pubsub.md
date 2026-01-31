---
title: "Gmail 整合 (Pub/Sub)"
summary: "透過 gogcli 將 Gmail Pub/Sub 推送接入 OpenClaw Webhooks"
read_when:
  - 將 Gmail 收件匣觸發器接入 OpenClaw 時
  - 設定 Pub/Sub 推送以喚醒 Agent 時
---
# Gmail 整合 (Pub/Sub)

目標：實現 Gmail 監控 -> Pub/Sub 推送 -> `gog gmail watch serve` -> OpenClaw Webhook。

## 前置需求
- 已安裝並登入 `gcloud`。
- 已安裝並授權 `gog` (gogcli) 存取 Gmail 帳戶。
- 已啟用 OpenClaw Hooks（詳見 [Webhooks](/automation/webhook)）。
- 已登入 `tailscale`。推薦方案使用 Tailscale Funnel 提供公開的 HTTPS 端點。

### Hook 配置範例
```json5
{
  hooks: {
    enabled: true,
    presets: ["gmail"],
    mappings: [
      {
        match: { path: "gmail" },
        action: "agent",
        wakeMode: "now",
        messageTemplate: "收到來自 {{messages[0].from}} 的新郵件\n主旨：{{messages[0].subject}}\n{{messages[0].body}}",
        deliver: true,
        channel: "last"
      }
    ]
  }
}
```

您可以透過 `hooks.gmail.model` 與 `hooks.gmail.thinking` 為 Gmail Hook 指定特定模型與思考等級。

## 推薦路徑：入門精靈 (Wizard)
使用 OpenClaw 助手將所有組組件連結在一起（在 macOS 上會透過 brew 自動安裝依賴）：

```bash
openclaw webhooks gmail setup --account openclaw@gmail.com
```

預設行為：
- 使用 Tailscale Funnel 作為公開推送端點。
- 寫入 `hooks.gmail` 配置。
- 啟用 Gmail Hook 預設集 (`hooks.presets: ["gmail"]`)。

## 啟動監控
當配置完成後，Gateway 在開機時會自動啟動監控。若需手動執行：

```bash
openclaw webhooks gmail run
```

## Google Cloud 設定步驟
1) 確保 `gcloud` 指向正確的專案。
2) 啟用 `gmail.googleapis.com` 與 `pubsub.googleapis.com` API。
3) 建立主題：`gcloud pubsub topics create gog-gmail-watch`。
4) 授權 Gmail 推送服務發布訊息至該主題：
   ```bash
   gcloud pubsub topics add-iam-policy-binding gog-gmail-watch \
     --member=serviceAccount:gmail-api-push@system.gserviceaccount.com \
     --role=roles/pubsub.publisher
   ```

## 故障排除
- **Invalid topicName**：專案不匹配（主題必須與 OAuth 客戶端屬於同一個專案）。
- **User not authorized**：主題缺少 `roles/pubsub.publisher` 權限。
- **空訊息**：Gmail 推送僅提供 `historyId`；內容需透過 `gog gmail history` 獲取。
