---
title: "Googlechat(Google Chat API)"
summary: "Google Chat 應用程式支援狀態、功能與設定"
read_when:
  - 處理 Google Chat 頻道功能時
---
# Google Chat (Chat API)

狀態：支援透過 Google Chat API Webhook 進行私訊 (DM) 與空間 (Spaces) 通訊（僅限 HTTP）。

## 快速設定（初学者）
1. 建立一個 Google Cloud 專案並啟用 **Google Chat API**。
2. 建立一個 **服務帳號 (Service Account)**：
   - 生成並下載 **JSON 金鑰**。
3. 將 JSON 金鑰檔案存儲在 Gateway 主機上（例如 `~/.openclaw/googlechat-service-account.json`）。
4. 在 Google Cloud 控制台的 [Chat 設定](https://console.cloud.google.com/apis/api/chat.googleapis.com/hangouts-chat)中建立一個 Chat 應用程式：
   - 啟用 **互動功能 (Interactive features)**。
   - 在功能中勾選 **加入空間與群組對話**。
   - 連線設定選擇 **HTTP 端點 URL**。
   - 觸發器選擇 **對所有觸發器使用通用的 HTTP 端點 URL**，並將其指向您的 Gateway 公開網址加上 `/googlechat`。
   - 在可見性部分，將應用程式開放給您的網域或特定人員。
5. **發布應用程式**：在設定頁面將應用程式狀態改為 **Live - 開放給使用者**。
6. 設定 OpenClaw 指向服務帳號路徑：
   - 設定：`channels.googlechat.serviceAccountFile: "/路徑/to/service-account.json"`。
7. 啟動 Gateway。Google Chat 將會透過 Webhook 向您的主機發送 POST 請求。

## 加入 Google Chat
1. 前往 [Google Chat](https://chat.google.com/)。
2. 點擊私訊旁邊的 **+**。
3. 搜尋您剛剛設定的 **應用程式名稱**（因為是私有應用程式，它不會出現在商店列表中）。
4. 開始對話！

## 公開網址 (Webhook-only)
Google Chat 需要一個公開的 HTTPS 端點。基於安全，建議**僅將 `/googlechat` 路徑暴露至網際網路**。

### 推薦做法：Tailscale Funnel
使用 Tailscale Funnel 可以僅暴露 Webhook 路徑，同時保持後台管理介面的私密。
指令範例：
```bash
tailscale funnel --bg --set-path /googlechat http://127.0.0.1:18789/googlechat
```
您的 Webhook 網址將會是 `https://<節點名稱>.<網域>.ts.net/googlechat`。

## 運作原理
- **認證**：OpenClaw 會驗證 Google 傳來的 Bearer 令牌與 `audience` 設定是否匹配。
- **會話**：私訊與空間會被映射到獨立的代理會話中。
- **配對**：私訊預設需要配對，未知發送者會收到配對碼。

## 設定摘要
```json5
{
  channels: {
    "googlechat": {
      enabled: true,
      serviceAccountFile: "/path/to/service-account.json",
      audienceType: "app-url",
      audience: "https://your-gateway.com/googlechat",
      webhookPath: "/googlechat",
      dm: { policy: "pairing" }
    }
  }
}
```

## 故障排除
- **405 Method Not Allowed**：通常代表 Webhook 處理程序未註冊。請檢查 `channels.googlechat` 是否已設定，且 Gateway 已重啟。
- **無法收到訊息**：請檢查 `openclaw logs --follow` 看看請求是否有抵達 Gateway。
- **確認權限**：使用 `openclaw channels status --probe` 檢查服務帳號權限或 Audience 設定是否正確。
