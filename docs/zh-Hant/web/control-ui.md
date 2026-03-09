---
summary: "Gateway 的瀏覽器 Control UI（聊天、節點、設定）"
read_when:
  - 想從瀏覽器操作 Gateway
  - 想透過 Tailnet 存取而不使用 SSH 隧道
title: "Control UI（控制介面）"
---

# Control UI（瀏覽器）

Control UI 是一個由 Gateway 提供的小型 **Vite + Lit** 單頁應用程式：

- 預設：`http://<host>:18789/`
- 可選前綴：設定 `gateway.controlUi.basePath`（例如 `/openclaw`）

它**直接透過相同連接埠與 Gateway WebSocket 通訊**。

## 快速開啟（本地）

若 Gateway 在同一台電腦上運行，開啟：

- [http://127.0.0.1:18789/](http://127.0.0.1:18789/)（或 [http://localhost:18789/](http://localhost:18789/)）

若頁面無法載入，請先啟動 Gateway：`openclaw gateway`。

驗證在 WebSocket 握手時透過以下方式提供：

- `connect.params.auth.token`
- `connect.params.auth.password`
  儀表板設定面板可讓你儲存 token；密碼不會持久化。
  入門精靈預設會產生 gateway token，首次連線時請貼上此 token。

## 裝置配對（首次連線）

當你從新瀏覽器或新裝置連線至 Control UI 時，Gateway
需要**一次性配對核准**——即使你在同一個 Tailnet 且設定了
`gateway.auth.allowTailscale: true`。這是防止未授權存取的安全措施。

**你會看到：**「disconnected (1008): pairing required」

**核准裝置：**

```bash
# 列出待處理的請求
openclaw devices list

# 依請求 ID 核准
openclaw devices approve <requestId>
```

核准後，裝置會被記住，除非你使用 `openclaw devices revoke --device <id> --role <role>` 撤銷，否則不需要重新配對。Token 輪換與撤銷請見 [Devices CLI](/zh-Hant/cli/devices)。

**注意事項：**

- 本地連線（`127.0.0.1`）會自動核准。
- 遠端連線（LAN、Tailnet 等）需要明確核准。
- 每個瀏覽器設定檔會產生唯一的裝置 ID，因此切換瀏覽器或清除瀏覽器資料需要重新配對。

## 語言支援

Control UI 可在首次載入時根據你的瀏覽器語系進行本地化，之後可從「Access」卡片中的語言選擇器覆蓋。

- 支援的語系：`en`、`zh-CN`、`zh-TW`、`pt-BR`、`de`、`es`
- 非英文翻譯在瀏覽器中延遲載入。
- 選擇的語系儲存在瀏覽器儲存空間，下次造訪時重複使用。
- 缺少的翻譯鍵會退回至英文。

## 目前可以做什麼

- 透過 Gateway WS 與模型聊天（`chat.history`、`chat.send`、`chat.abort`、`chat.inject`）
- 在聊天中串流工具呼叫 + 即時工具輸出卡片（agent 事件）
- 頻道：WhatsApp/Telegram/Discord/Slack + plugin 頻道（Mattermost 等）狀態 + QR 碼登入 + 每頻道設定（`channels.status`、`web.login.*`、`config.patch`）
- 實例：存在清單 + 重新整理（`system-presence`）
- Sessions：清單 + 每個 session 的思考/詳細覆蓋（`sessions.list`、`sessions.patch`）
- Cron 工作：清單/新增/編輯/執行/啟用/停用 + 執行歷程（`cron.*`）
- Skills：狀態、啟用/停用、安裝、API 金鑰更新（`skills.*`）
- 節點：清單 + 功能（`node.list`）
- Exec 核准：編輯 gateway 或節點允許清單 + `exec host=gateway/node` 的詢問策略（`exec.approvals.*`）
- 設定：檢視/編輯 `~/.openclaw/openclaw.json`（`config.get`、`config.set`）
- 設定：帶驗證的套用 + 重啟（`config.apply`）並喚醒最後的活躍 session
- 設定寫入包含基礎雜湊保護，防止並行編輯衝突
- 設定 schema + 表單渲染（`config.schema`，包含 plugin + 頻道 schema）；原始 JSON 編輯器仍可使用
- 偵錯：status/health/models 快照 + 事件記錄 + 手動 RPC 呼叫（`status`、`health`、`models.list`）
- 記錄：帶過濾/匯出的 gateway 檔案記錄即時追蹤（`logs.tail`）
- 更新：執行套件/git 更新 + 重啟（`update.run`）並附重啟報告

Cron 工作面板注意事項：

- 隔離工作的傳送預設為公告摘要。若只需內部執行，可切換為無。
- 選擇公告時會顯示頻道/目標欄位。
- Webhook 模式使用 `delivery.mode = "webhook"`，`delivery.to` 設為有效的 HTTP(S) webhook URL。
- 主 session 工作可使用 webhook 和無傳送模式。
- 進階編輯控制項包括執行後刪除、清除 agent 覆蓋、cron 精確/錯開選項、agent 模型/思考覆蓋，以及盡力傳送切換。
- 表單驗證為內嵌式，含欄位層級錯誤；無效值會停用儲存按鈕直到修正。
- 設定 `cron.webhookToken` 可傳送專用的 bearer token；若省略則不附驗證標頭傳送 webhook。
- 已棄用的退備：含 `notify: true` 的舊版工作可繼續使用 `cron.webhook` 直到遷移。

## 聊天行為

- `chat.send` 是**非阻塞**的：立即以 `{ runId, status: "started" }` 確認，回應透過 `chat` 事件串流。
- 以相同 `idempotencyKey` 重新傳送，執行中返回 `{ status: "in_flight" }`，完成後返回 `{ status: "ok" }`。
- `chat.history` 回應有大小限制以確保 UI 安全。當對話記錄條目過大時，Gateway 可能截斷長文字欄位、省略大型中繼資料區塊，並用佔位符替換過大的訊息（`[chat.history omitted: message too large]`）。
- `chat.inject` 將助理備註附加至 session 對話記錄，並廣播 `chat` 事件供僅限 UI 的更新（不執行 agent，不傳送頻道）。
- 停止：
  - 點擊 **Stop**（呼叫 `chat.abort`）
  - 輸入 `/stop`（或獨立中止短語如 `stop`、`stop action`、`stop run`、`stop openclaw`、`please stop`）進行帶外中止
  - `chat.abort` 支援 `{ sessionKey }`（無 `runId`）以中止該 session 的所有活躍執行
- 中止部分保留：
  - 執行被中止時，部分助理文字仍可在 UI 中顯示
  - 若有緩衝輸出，Gateway 會將中止的部分助理文字持久化至對話記錄
  - 持久化條目包含中止中繼資料，讓對話記錄消費者能區分中止部分輸出與正常完成輸出

## Tailnet 存取（建議）

### 整合式 Tailscale Serve（首選）

保持 Gateway 在 loopback，讓 Tailscale Serve 以 HTTPS 代理它：

```bash
openclaw gateway --tailscale serve
```

開啟：

- `https://<magicdns>/`（或你設定的 `gateway.controlUi.basePath`）

預設情況下，當 `gateway.auth.allowTailscale` 為 `true` 時，Control UI/WebSocket Serve 請求可透過 Tailscale 身份標頭（`tailscale-user-login`）驗證。OpenClaw 透過 `tailscale whois` 解析 `x-forwarded-for` 位址並與標頭比對，且僅在請求到達 loopback 且附帶 Tailscale 的 `x-forwarded-*` 標頭時才接受。若希望即使對 Serve 流量也需要 token/密碼，請設定 `gateway.auth.allowTailscale: false`（或強制 `gateway.auth.mode: "password"`）。
無 token 的 Serve 驗證假設 gateway 主機是受信任的。若不受信任的本地程式碼可能在該主機上執行，請要求 token/密碼驗證。

### 綁定至 tailnet + token

```bash
openclaw gateway --bind tailnet --token "$(openssl rand -hex 32)"
```

然後開啟：

- `http://<tailscale-ip>:18789/`（或你設定的 `gateway.controlUi.basePath`）

將 token 貼入 UI 設定（以 `connect.params.auth.token` 傳送）。

## 不安全的 HTTP

若你透過純 HTTP（`http://<lan-ip>` 或 `http://<tailscale-ip>`）開啟儀表板，瀏覽器會在**非安全上下文**中運行並封鎖 WebCrypto。預設情況下，OpenClaw **封鎖**沒有裝置身份的 Control UI 連線。

**建議修復：** 使用 HTTPS（Tailscale Serve）或在本地開啟 UI：

- `https://<magicdns>/`（Serve）
- `http://127.0.0.1:18789/`（在 gateway 主機上）

**不安全驗證切換行為：**

```json5
{
  gateway: {
    controlUi: { allowInsecureAuth: true },
    bind: "tailnet",
    auth: { mode: "token", token: "replace-me" },
  },
}
```

`allowInsecureAuth` 不會繞過 Control UI 裝置身份或配對檢查。

**僅限緊急使用：**

```json5
{
  gateway: {
    controlUi: { dangerouslyDisableDeviceAuth: true },
    bind: "tailnet",
    auth: { mode: "token", token: "replace-me" },
  },
}
```

`dangerouslyDisableDeviceAuth` 停用 Control UI 裝置身份檢查，是嚴重的安全降級。緊急使用後請立即還原。

HTTPS 設定指引請見 [Tailscale](/zh-Hant/gateway/tailscale)。

## 建置 UI

Gateway 從 `dist/control-ui` 提供靜態檔案。使用以下指令建置：

```bash
pnpm ui:build # 首次執行時自動安裝 UI 依賴項
```

可選的絕對基礎路徑（當你需要固定資源 URL 時）：

```bash
OPENCLAW_CONTROL_UI_BASE_PATH=/openclaw/ pnpm ui:build
```

本地開發（獨立開發伺服器）：

```bash
pnpm ui:dev # 首次執行時自動安裝 UI 依賴項
```

然後將 UI 指向你的 Gateway WS URL（例如 `ws://127.0.0.1:18789`）。

## 偵錯/測試：開發伺服器 + 遠端 Gateway

Control UI 是靜態檔案；WebSocket 目標是可設定的，可以與 HTTP 來源不同。當你希望 Vite 開發伺服器在本地運行但 Gateway 在其他地方時，這非常方便。

1. 啟動 UI 開發伺服器：`pnpm ui:dev`
2. 開啟如下 URL：

```text
http://localhost:5173/?gatewayUrl=ws://<gateway-host>:18789
```

可選的一次性驗證（若需要）：

```text
http://localhost:5173/?gatewayUrl=wss://<gateway-host>:18789#token=<gateway-token>
```

注意事項：

- `gatewayUrl` 在載入後儲存至 localStorage 並從 URL 中移除。
- `token` 匯入至目前分頁的記憶體並從 URL 中剝除；不儲存至 localStorage。
- `password` 僅保存在記憶體中。
- 設定 `gatewayUrl` 後，UI 不會退回至設定或環境憑證。請明確提供 `token`（或 `password`）。缺少明確憑證會被視為錯誤。
- Gateway 在 TLS 後方時（Tailscale Serve、HTTPS 代理等）請使用 `wss://`。
- `gatewayUrl` 僅在頂層視窗中接受（非嵌入），以防止點擊劫持。
- 非 loopback Control UI 部署必須明確設定 `gateway.controlUi.allowedOrigins`（完整來源）。這包括遠端開發設定。
- `gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback=true` 啟用 Host 標頭來源退備模式，但這是危險的安全模式。

範例：

```json5
{
  gateway: {
    controlUi: {
      allowedOrigins: ["http://localhost:5173"],
    },
  },
}
```

遠端存取設定詳情：[遠端存取](/zh-Hant/gateway/remote)。
