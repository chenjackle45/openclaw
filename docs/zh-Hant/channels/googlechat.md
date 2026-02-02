---
summary: "Google Chat 應用程式支援狀態、功能與設定"
read_when:
  - 處理 Google Chat 頻道功能時
title: "Google Chat"
---

# Google Chat (Chat API)

狀態：支援透過 Google Chat API Webhook 進行私訊 (DM) 與空間 (Spaces) 通訊（僅限 HTTP）。

## 快速設定（初學者）

1. 建立 Google Cloud 專案並啟用 **Google Chat API**。
   - 前往：[Google Chat API 認證](https://console.cloud.google.com/apis/api/chat.googleapis.com/credentials)
   - 如果尚未啟用，請啟用 API。
2. 建立 **服務帳號**：
   - 點擊 **建立認證** > **服務帳號**。
   - 命名為您想要的名稱（例如 `openclaw-chat`）。
   - 將權限保持空白（按 **繼續**）。
   - 將存取主體保持空白（按 **完成**）。
3. 建立並下載 **JSON 金鑰**：
   - 在服務帳號列表中，點擊您剛剛建立的帳號。
   - 前往 **金鑰** 標籤。
   - 點擊 **新增金鑰** > **建立新金鑰**。
   - 選擇 **JSON** 並按 **建立**。
4. 將下載的 JSON 檔案儲存在您的 Gateway 主機上（例如 `~/.openclaw/googlechat-service-account.json`）。
5. 在 [Google Cloud 控制台 Chat 設定](https://console.cloud.google.com/apis/api/chat.googleapis.com/hangouts-chat)中建立 Google Chat 應用程式：
   - 填寫 **應用程式資訊**：
     - **應用程式名稱**：（例如 `OpenClaw`）
     - **頭像 URL**：（例如 `https://openclaw.ai/logo.png`）
     - **描述**：（例如 `Personal AI Assistant`）
   - 啟用 **互動功能**。
   - 在 **功能** 下，勾選 **加入空間與群組對話**。
   - 在 **連線設定** 下，選擇 **HTTP 端點 URL**。
   - 在 **觸發器** 下，選擇 **對所有觸發器使用通用 HTTP 端點 URL**，並將其設為您的 Gateway 公開 URL 加上 `/googlechat`。
     - _提示：執行 `openclaw status` 找到您的 Gateway 公開 URL。_
   - 在 **可見性** 下，勾選 **將此 Chat 應用程式開放給您的網域中的特定人員與群組**。
   - 在文字方塊中輸入您的電子郵件地址（例如 `user@example.com`）。
   - 點擊底部的 **儲存**。
6. **啟用應用程式狀態**：
   - 儲存後，**重新整理頁面**。
   - 尋找 **應用程式狀態** 部分（通常在儲存後的頂部或底部）。
   - 將狀態變更為 **Live - 開放給使用者**。
   - 再次點擊 **儲存**。
7. 使用服務帳號路徑 + Webhook audience 設定 OpenClaw：
   - 環境變數：`GOOGLE_CHAT_SERVICE_ACCOUNT_FILE=/path/to/service-account.json`
   - 或設定：`channels.googlechat.serviceAccountFile: "/path/to/service-account.json"`。
8. 設定 Webhook audience 類型 + 值（與您的 Chat 應用程式設定相符）。
9. 啟動 Gateway。Google Chat 將 POST 到您的 Webhook 路徑。

## 加入 Google Chat

Gateway 執行中且您的電子郵件已新增至可見性清單後：

1. 前往 [Google Chat](https://chat.google.com/)。
2. 點擊 **直接訊息** 旁的 **+**（加號）圖示。
3. 在搜尋列（通常是新增人員的地方），輸入您在 Google Cloud 控制台中設定的 **應用程式名稱**。
   - **注意**：此機器人 _不會_ 出現在「Marketplace」瀏覽列中，因為它是私有應用程式。您必須按名稱搜尋。
4. 從結果中選擇您的機器人。
5. 點擊 **新增** 或 **聊天** 開始 1:1 對話。
6. 發送「Hello」以觸發助理！

## 公開 URL（僅限 Webhook）

Google Chat Webhook 需要公開的 HTTPS 端點。為了安全，**只暴露 `/googlechat` 路徑** 至網際網路。將 OpenClaw 儀表板和其他敏感端點保留在您的私人網路上。

### 選項 A：Tailscale Funnel（推薦）

使用 Tailscale Serve 作為私人儀表板，使用 Funnel 作為公開 Webhook 路徑。這樣保持 `/` 私人，同時只暴露 `/googlechat`。

1. **檢查您的 Gateway 綁定的地址：**

   ```bash
   ss -tlnp | grep 18789
   ```

   記下 IP 地址（例如 `127.0.0.1`、`0.0.0.0` 或您的 Tailscale IP 如 `100.x.x.x`）。

2. **將儀表板暴露至 Tailnet 只（連接埠 8443）：**

   ```bash
   # 如果綁定至 localhost (127.0.0.1 或 0.0.0.0)：
   tailscale serve --bg --https 8443 http://127.0.0.1:18789

   # 如果只綁定至 Tailscale IP（例如 100.106.161.80）：
   tailscale serve --bg --https 8443 http://100.106.161.80:18789
   ```

3. **僅暴露 Webhook 路徑至公開：**

   ```bash
   # 如果綁定至 localhost (127.0.0.1 或 0.0.0.0)：
   tailscale funnel --bg --set-path /googlechat http://127.0.0.1:18789/googlechat

   # 如果只綁定至 Tailscale IP（例如 100.106.161.80）：
   tailscale funnel --bg --set-path /googlechat http://100.106.161.80:18789/googlechat
   ```

4. **授權節點進行 Funnel 存取：**
   如果出現提示，請訪問輸出中顯示的授權 URL，以在您的 Tailnet 政策中啟用此節點的 Funnel。

5. **驗證設定：**
   ```bash
   tailscale serve status
   tailscale funnel status
   ```

您的公開 Webhook URL 將是：
`https://<node-name>.<tailnet>.ts.net/googlechat`

您的私人儀表板保持 Tailnet 專用：
`https://<node-name>.<tailnet>.ts.net:8443/`

在 Google Chat 應用程式設定中使用公開 URL（不含 `:8443`）。

> 注意：此設定在重啟後持續存在。若要稍後移除它，執行 `tailscale funnel reset` 和 `tailscale serve reset`。

### 選項 B：反向代理（Caddy）

如果您使用 Caddy 等反向代理，只代理特定路徑：

```caddy
your-domain.com {
    reverse_proxy /googlechat* localhost:18789
}
```

使用此設定，任何對 `your-domain.com/` 的請求將被忽略或返回 404，而 `your-domain.com/googlechat` 安全地路由至 OpenClaw。

### 選項 C：Cloudflare Tunnel

設定您的 Tunnel 入口規則，只路由 Webhook 路徑：

- **路徑**：`/googlechat` -> `http://localhost:18789/googlechat`
- **預設規則**：HTTP 404（找不到）

## 運作方式

1. Google Chat 向 Gateway 傳送 Webhook POST。每個請求包含 `Authorization: Bearer <token>` 標頭。
2. OpenClaw 根據設定的 `audienceType` + `audience` 驗證令牌：
   - `audienceType: "app-url"` → audience 是您的 HTTPS Webhook URL。
   - `audienceType: "project-number"` → audience 是 Cloud 專案編號。
3. 訊息按空間路由：
   - 直接訊息使用會話金鑰 `agent:<agentId>:googlechat:dm:<spaceId>`。
   - 空間使用會話金鑰 `agent:<agentId>:googlechat:group:<spaceId>`。
4. 預設情況下，DM 存取需要配對。未知發送者會收到配對碼；使用以下方式批准：
   - `openclaw pairing approve googlechat <code>`
5. 預設情況下，群組空間需要 @-mention。如果提及偵測需要應用程式的使用者名稱，請使用 `botUser`。

## 目標

使用這些識別碼進行交付和允許清單：

- 直接訊息：`users/<userId>` 或 `users/<email>`（接受電子郵件地址）。
- 空間：`spaces/<spaceId>`。

## 設定重點

```json5
{
  channels: {
    googlechat: {
      enabled: true,
      serviceAccountFile: "/path/to/service-account.json",
      audienceType: "app-url",
      audience: "https://gateway.example.com/googlechat",
      webhookPath: "/googlechat",
      botUser: "users/1234567890", // 選用；有助於提及偵測
      dm: {
        policy: "pairing",
        allowFrom: ["users/1234567890", "name@example.com"],
      },
      groupPolicy: "allowlist",
      groups: {
        "spaces/AAAA": {
          allow: true,
          requireMention: true,
          users: ["users/1234567890"],
          systemPrompt: "Short answers only.",
        },
      },
      actions: { reactions: true },
      typingIndicator: "message",
      mediaMaxMb: 20,
    },
  },
}
```

注意：

- 服務帳號認證也可以使用 `serviceAccount`（JSON 字串）內聯傳遞。
- 如果未設定 `webhookPath`，預設 Webhook 路徑是 `/googlechat`。
- 當 `actions.reactions` 被啟用時，可以透過 `reactions` 工具和 `channels action` 使用反應。
- `typingIndicator` 支援 `none`、`message`（預設）和 `reaction`（反應需要使用者 OAuth）。
- 附件透過 Chat API 下載並儲存在媒體管道中（大小由 `mediaMaxMb` 限制）。

## 故障排除

### 405 Method Not Allowed

如果 Google Cloud Logs Explorer 顯示錯誤如：

```
status code: 405, reason phrase: HTTP error response: HTTP/1.1 405 Method Not Allowed
```

這表示 Webhook 處理程序未註冊。常見原因：

1. **未設定頻道**：您的設定中缺少 `channels.googlechat` 部分。使用以下方式驗證：

   ```bash
   openclaw config get channels.googlechat
   ```

   如果返回「Config path not found」，請新增設定（見[設定重點](#設定重點)）。

2. **外掛未啟用**：檢查外掛狀態：

   ```bash
   openclaw plugins list | grep googlechat
   ```

   如果顯示「disabled」，將 `plugins.entries.googlechat.enabled: true` 新增到您的設定。

3. **Gateway 未重啟**：新增設定後，重啟 Gateway：
   ```bash
   openclaw gateway restart
   ```

驗證頻道正在執行：

```bash
openclaw channels status
# 應該顯示：Google Chat default: enabled, configured, ...
```

### 其他問題

- 檢查 `openclaw channels status --probe` 以了解認證錯誤或缺少 audience 設定。
- 如果沒有訊息抵達，確認 Chat 應用程式的 Webhook URL + 事件訂閱。
- 如果提及閘門阻止回覆，將 `botUser` 設為應用程式的使用者資源名稱並驗證 `requireMention`。
- 在傳送測試訊息時使用 `openclaw logs --follow` 以查看請求是否抵達 Gateway。

相關文件：

- [Gateway 設定](/gateway/configuration)
- [安全性](/gateway/security)
- [反應](/tools/reactions)
