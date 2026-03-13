---
title: "Control UI（控制 UI）"
summary: "用於 Gateway 的瀏覽器型控制 UI（聊天、節點、設定）"
read_when:
  - 您想從瀏覽器操作 Gateway
  - 您想要 Tailnet 存取而無需 SSH 通道
---

# 控制 UI（瀏覽器）

控制 UI 是由 Gateway 提供的小型 **Vite + Lit** 單一頁面應用程式：

- 預設：`http://<host>:18789/`
- 選擇性前綴：設定 `gateway.controlUi.basePath`（例如 `/openclaw`）

它 **直接與 Gateway WebSocket** 在同一連接埠上通信。

## 快速開啟（本地）

如果 Gateway 在同一台電腦上執行，請開啟：

- [http://127.0.0.1:18789/](http://127.0.0.1:18789/)（或 [http://localhost:18789/](http://localhost:18789/)）

如果頁面無法載入，先啟動 Gateway：`openclaw gateway`。

驗證透過以下方式在 WebSocket 握手期間提供：

- `connect.params.auth.token`
- `connect.params.auth.password`
  儀表板設定面板為目前瀏覽器標籤工作階段和所選 gateway URL 保持令牌；密碼不保持。
  登機精靈預設會產生 gateway 令牌，所以在首次連接時將其貼到此處。

## 設備配對（首次連接）

當您從新瀏覽器或設備連接到控制 UI 時，Gateway 需要 **一次性配對批准** — 即使您在同一 Tailnet 上且 `gateway.auth.allowTailscale: true` 也是如此。這是防止未經授權存取的安全措施。

**您會看到的內容**：「disconnected (1008): pairing required」

**要批准設備**：

```bash
# 列出待處理要求
openclaw devices list

# 按要求 ID 批准
openclaw devices approve <requestId>
```

批准後，設備會被記住，除非您使用 `openclaw devices revoke --device <id> --role <role>` 撤銷它，否則不會需要重新批准。如需令牌輪換和撤銷，請參閱 [設備 CLI](/zh-Hant/cli/devices)。

**備註**：

- 本地連接（`127.0.0.1`）自動批准。
- 遠端連接（LAN、Tailnet 等）需要明確批准。
- 每個瀏覽器設定檔產生唯一設備 ID，所以切換瀏覽器或清除瀏覽器資料將需要重新配對。

## 語言支援

控制 UI 可根據您的瀏覽器區域設定在首次載入時將自身當地語系化，您稍後可從存取卡中的語言挑選器覆寫它。

- 支援的區域設定：`en`、`zh-CN`、`zh-TW`、`pt-BR`、`de`、`es`
- 非英文翻譯在瀏覽器中延遲載入。
- 所選區域設定儲存在瀏覽器儲存體中，並在未來造訪時重新使用。
- 遺留翻譯金鑰回退至英文。

## 它能做的（今天）

- 透過 Gateway WS 與模型聊天（`chat.history`、`chat.send`、`chat.abort`、`chat.inject`）
- 串流工具呼叫 + 聊天中的實況工具輸出卡（代理事件）
- 頻道：WhatsApp／Telegram／Discord／Slack + 外掛頻道（Mattermost 等）狀態 + QR 登入 + 每個頻道設定（`channels.status`、`web.login.*`、`config.patch`）
- 實例：目前清單 + 重新整理（`system-presence`）
- 工作階段：清單 + 每個工作階段思考／快速／詳細／推理覆寫（`sessions.list`、`sessions.patch`）
- Cron 工作：清單／新增／編輯／執行／啟用／停用 + 執行歷史記錄（`cron.*`）
- 技能：狀態、啟用／停用、安裝、API 金鑰更新（`skills.*`）
- 節點：清單 + 功能（`node.list`）
- 執行批准：編輯 gateway 或節點允許清單 + 詢問 `exec host=gateway/node` 的原則（`exec.approvals.*`）
- 設定：檢視／編輯 `~/.openclaw/openclaw.json`（`config.get`、`config.set`）
- 設定：使用驗證套用 + 重啟（`config.apply`）並喚醒上次作用中的工作階段
- 設定寫入包括基礎雜湊防護以防止並行編輯衝突
- 設定架構 + 表單轉譯（`config.schema`，包括外掛 + 頻道架構）；原始 JSON 編輯器仍可用
- 除錯：狀態／健康／模型快照 + 事件記錄 + 手動 RPC 呼叫（`status`、`health`、`models.list`）
- 記錄：使用篩選／匯出即時 tail gateway 檔案記錄（`logs.tail`）
- 更新：執行套件／git 更新 + 重啟（`update.run`）及重啟報告

Cron 工作面板備註：

- 針對隔離工作，傳遞預設為宣佈摘要。如果您想要僅內部執行，您可以切換為無。
- 當選擇宣佈時，頻道／目標欄位會出現。
- Webhook 模式使用 `delivery.mode = "webhook"`，其中 `delivery.to` 設定為有效的 HTTP(S) webhook URL。
- 對於主工作階段工作，webhook 和無傳遞模式可用。
- 進階編輯控制項包括執行後刪除、清除代理覆寫、cron 精確／交錯選項、代理模型／思考覆寫和盡力傳遞切換。
- 表單驗證與欄位層級錯誤內聯；無效值停用儲存按鈕直到固定。
- 設定 `cron.webhookToken` 以傳送專用持有人令牌；如果省略，webhook 在沒有驗證標頭的情況下傳送。
- 已棄用回退：儲存的舊版工作 `notify: true` 仍可使用 `cron.webhook` 直到遷移。

## 聊天行為

- `chat.send` 為 **非阻擋**：立即使用 `{ runId, status: "started" }` 確認並透過 `chat` 事件串流回應。
- 使用相同 `idempotencyKey` 重新傳送時，在執行時傳回 `{ status: "in_flight" }`，完成後傳回 `{ status: "ok" }`。
- `chat.history` 回應因 UI 安全性而受大小限制。當抄本條目太大時，Gateway 可能截斷長文字欄位、省略重型中繼資料區塊，以及將超大訊息取代為預留位置（`[chat.history omitted: message too large]`）。
- `chat.inject` 將助理備註附加到工作階段謄本並廣播用於僅 UI 更新的 `chat` 事件（無代理執行、無頻道傳遞）。
- 停止：
  - 按一下 **Stop**（呼叫 `chat.abort`）
  - 鍵入 `/stop`（或獨立停止短語如 `stop`、`stop action`、`stop run`、`stop openclaw`、`please stop`）以停止頻外
  - `chat.abort` 支援 `{ sessionKey }`（無 `runId`）以停止該工作階段的所有作用中執行
- 停止部分保留：
  - 當執行被停止時，部分助理文字仍可在 UI 中顯示
  - Gateway 在存在緩衝輸出時將已停止的部分助理文字保持到謄本歷史記錄
  - 保持的條目包括停止中繼資料，以便謄本消費者可以區別停止部分與普通完成輸出

## Tailnet 存取（建議）

### 整合 Tailscale Serve（首選）

保持 Gateway 在迴圈上，讓 Tailscale Serve 使用 HTTPS 代理它：

```bash
openclaw gateway --tailscale serve
```

開啟：

- `https://<magicdns>/`（或您設定的 `gateway.controlUi.basePath`）

預設情況下，控制 UI／WebSocket Serve 要求可透過 Tailscale 身分識別標頭（`tailscale-user-login`）驗證，當 `gateway.auth.allowTailscale` 為 `true` 時。OpenClaw 透過使用 `tailscale whois` 解析 `x-forwarded-for` 位址並將其比對標頭來驗證身分識別，並僅在要求叫用 loopback 時接受它們，使用 Tailscale 的 `x-forwarded-*` 標頭。設定 `gateway.auth.allowTailscale: false`（或強制 `gateway.auth.mode: "password"`），如果您想要求令牌／密碼驗證甚至 Serve 流量。
無令牌 Serve 驗證假設 gateway 主機受信。如果不信任的本地代碼可能在該主機上執行，需要令牌／密碼驗證。

### 繫結至 tailnet + 令牌

```bash
openclaw gateway --bind tailnet --token "$(openssl rand -hex 32)"
```

然後開啟：

- `http://<tailscale-ip>:18789/`（或您設定的 `gateway.controlUi.basePath`）

將令牌貼到 UI 設定（作為 `connect.params.auth.token` 傳送）。

## 不安全的 HTTP

如果您透過純 HTTP（`http://<lan-ip>` 或 `http://<tailscale-ip>`）開啟儀表板，瀏覽器在 **非安全背景**中執行並阻擋 WebCrypto。預設情況下，OpenClaw **阻擋**控制 UI 連接而無需設備身分識別。

**建議的修復**：使用 HTTPS（Tailscale Serve）或在本地開啟 UI：

- `https://<magicdns>/`（Serve）
- `http://127.0.0.1:18789/`（在 gateway 主機上）

**不安全驗證切換行為**：

```json5
{
  gateway: {
    controlUi: { allowInsecureAuth: true },
    bind: "tailnet",
    auth: { mode: "token", token: "replace-me" },
  },
}
```

`allowInsecureAuth` 僅為本地相容性切換：

- 它允許 localhost 控制 UI 工作階段在非安全 HTTP 背景中無設備身分識別進行。
- 它不會略過配對檢查。
- 它不會放鬆遠端（非 localhost）設備身分識別需求。

**中斷玻璃僅有**：

```json5
{
  gateway: {
    controlUi: { dangerouslyDisableDeviceAuth: true },
    bind: "tailnet",
    auth: { mode: "token", token: "replace-me" },
  },
}
```

`dangerouslyDisableDeviceAuth` 停用控制 UI 設備身分識別檢查，這是嚴重安全降級。在緊急使用後快速還原。

如需 HTTPS 設定指導，請參閱 [Tailscale](/zh-Hant/gateway/tailscale)。

## 構建 UI

Gateway 提供來自 `dist/control-ui` 的靜態檔案。使用以下方式構建它們：

```bash
pnpm ui:build # 首次執行時自動安裝 UI 依賴項
```

選擇性絕對基礎（當您想要固定資產 URL 時）：

```bash
OPENCLAW_CONTROL_UI_BASE_PATH=/openclaw/ pnpm ui:build
```

針對本地開發（獨立 dev 伺服器）：

```bash
pnpm ui:dev # 首次執行時自動安裝 UI 依賴項
```

然後將 UI 指向您的 Gateway WS URL（例如 `ws://127.0.0.1:18789`）。

## 除錯／測試：dev 伺服器 + 遠端 Gateway

控制 UI 是靜態檔案；WebSocket 目標是可設定的且可能不同於 HTTP 來源。這在您想要本地 Vite dev 伺服器但 Gateway 執行在別處時很方便。

1. 啟動 UI dev 伺服器：`pnpm ui:dev`
2. 開啟類似的 URL：

```text
http://localhost:5173/?gatewayUrl=ws://<gateway-host>:18789
```

選擇性一次性驗證（如果需要）：

```text
http://localhost:5173/?gatewayUrl=wss://<gateway-host>:18789#token=<gateway-token>
```

備註：

- `gatewayUrl` 在載入後儲存在 localStorage 中，並從 URL 移除。
- `token` 從 URL 片段匯入，儲存在目前瀏覽器標籤工作階段和所選 gateway URL 的 sessionStorage 中，並從 URL 移除；它不儲存在 localStorage。
- `password` 僅保持在記憶體中。
- 當 `gatewayUrl` 設定時，UI 不會回退到設定或環境認證。明確提供 `token`（或 `password`）。遺留明確認證是錯誤。
- 當 Gateway 在 TLS（Tailscale Serve、HTTPS Proxy 等）後時使用 `wss://`。
- `gatewayUrl` 僅在頂層視窗中接受（未嵌入）以防止點擊劫持。
- 非 loopback 控制 UI 部署必須明確設定 `gateway.controlUi.allowedOrigins`（完整來源）。這包括遠端 dev 設定。
- `gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback=true` 啟用主機標頭來源回退模式，但這是危險安全模式。

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

遠端存取設定詳細資料：[遠端存取](/zh-Hant/gateway/remote)。
