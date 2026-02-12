---
summary: "Gateway 的瀏覽器基礎控制 UI（聊天、節點、設定）"
read_when:
  - 你想從瀏覽器操作 Gateway
  - 你想要 Tailnet 存取而無需 SSH 隧道
title: "Control UI（Control UI）"
---

# Control UI（瀏覽器）

Control UI 是一個小的 **Vite + Lit** 單頁應用程式，由 Gateway 提供：

- 預設值：`http://<host>:18789/`
- 選擇性前綴：設定 `gateway.controlUi.basePath`（例如 `/openclaw`）

它**直接向 Gateway WebSocket** 在相同連接埠上發言。

## 快速開啟（本機）

如果 Gateway 在同一部電腦上執行，請開啟：

- [http://127.0.0.1:18789/](http://127.0.0.1:18789/)（或 [http://localhost:18789/](http://localhost:18789/)）

如果頁面無法載入，請先啟動 Gateway：`openclaw gateway`。

驗證在 WebSocket 握手期間透過以下方式提供：

- `connect.params.auth.token`
- `connect.params.auth.password`

儀表板設定面板允許你儲存標記；密碼不會持久化。
上線精靈預設產生 Gateway 標記，所以在首次連接時將其貼上。

## 裝置配對（首次連接）

當你從新瀏覽器或裝置連接到 Control UI 時，Gateway 需要 **一次性配對核准** — 即使你在相同的 Tailnet 上，且 `gateway.auth.allowTailscale: true`。這是防止未授權存取的安全措施。

**你會看到：** "disconnected (1008): pairing required"

**核准裝置：**

```bash
# 列出待審請求
openclaw devices list

# 透過請求 ID 核准
openclaw devices approve <requestId>
```

一旦核准，裝置將被記住，除非你使用 `openclaw devices revoke --device <id> --role <role>` 撤銷，否則不會需要重新核准。詳見[裝置 CLI](/zh-Hant/cli/devices)了解標記旋轉和撤銷。

**注意事項：**

- 本機連接（`127.0.0.1`）自動核准。
- 遠端連接（LAN、Tailnet 等）需要明確核准。
- 每個瀏覽器設定檔會產生唯一的裝置 ID，因此切換瀏覽器或清除瀏覽器資料將需要重新配對。

## 它現在可以做什麼

- 透過 Gateway WS 與模型聊天（`chat.history`、`chat.send`、`chat.abort`、`chat.inject`）
- 在聊天中串流工具呼叫 + 即時工具輸出卡片（Agent 事件）
- 頻道：WhatsApp/Telegram/Discord/Slack + 外掛程式頻道（Mattermost 等）狀態 + QR 登入 + 每個頻道設定（`channels.status`、`web.login.*`、`config.patch`）
- 實例：存在清單 + 刷新（`system-presence`）
- 會話：列表 + 每個會話思考/詳細覆蓋（`sessions.list`、`sessions.patch`）
- Cron 工作：列表/新增/執行/啟用/停用 + 執行歷史記錄（`cron.*`）
- 技能：狀態、啟用/停用、安裝、API 金鑰更新（`skills.*`）
- 節點：列表 + 功能（`node.list`）
- Exec 核准：編輯 Gateway 或節點允許清單 + 詢問 `exec host=gateway/node` 的原則（`exec.approvals.*`）
- 設定：檢視/編輯 `~/.openclaw/openclaw.json`（`config.get`、`config.set`）
- 設定：套用並使用驗證重新啟動（`config.apply`），喚醒最後活躍會話
- 設定寫入包括基礎雜湊守衛，防止覆蓋並發編輯
- 設定結構描述 + 表單轉譯（`config.schema`，包括外掛程式 + 頻道結構描述）；原始 JSON 編輯器保持可用
- 調試：狀態/健康/模型快照 + 事件日誌 + 手動 RPC 呼叫（`status`、`health`、`models.list`）
- 日誌：Gateway 檔案日誌的即時尾端，帶有篩選/匯出（`logs.tail`）
- 更新：執行套件/git 更新 + 重新啟動（`update.run`），帶有重新啟動報告

Cron 工作面板筆記：

- 對於隔離的工作，傳遞預設為宣佈摘要。如果你想要僅限內部執行，可以切換到無。
- 選擇宣佈時出現頻道/目標欄位。

## 聊天行為

- `chat.send` 是**非阻斷**：它立即以 `{ runId, status: "started" }` 應答，回應透過 `chat` 事件串流。
- 使用相同 `idempotencyKey` 重新傳送在執行時傳回 `{ status: "in_flight" }`，完成後傳回 `{ status: "ok" }`。
- `chat.inject` 將助手筆記附加到會話文字記錄，並廣播 `chat` 事件以進行 UI 專用更新（無 Agent 執行、無頻道傳遞）。
- 停止：
  - 按一下**停止**（呼叫 `chat.abort`）
  - 輸入 `/stop`（或 `stop|esc|abort|wait|exit|interrupt`）進行帶外中止
  - `chat.abort` 支援 `{ sessionKey }`（無 `runId`）以中止該會話的所有活躍執行

## Tailnet 存取（建議）

### 整合 Tailscale Serve（首選）

將 Gateway 保持在迴圈上，讓 Tailscale Serve 使用 HTTPS 代理它：

```bash
openclaw gateway --tailscale serve
```

開啟：

- `https://<magicdns>/`（或你設定的 `gateway.controlUi.basePath`）

預設情況下，當 `gateway.auth.allowTailscale` 為 `true` 時，Serve 請求可以透過 Tailscale 身分標頭（`tailscale-user-login`）進行驗證。OpenClaw 透過使用 `tailscale whois` 解析 `x-forwarded-for` 位址並將其與標頭比對來驗證身分，並且僅在請求使用 Tailscale 的 `x-forwarded-*` 標頭進擊迴圈時接受這些。設定 `gateway.auth.allowTailscale: false`（或強制 `gateway.auth.mode: "password"`）以在你想要為 Serve 流量需要標記/密碼時。

### 繫結至 tailnet + 標記

```bash
openclaw gateway --bind tailnet --token "$(openssl rand -hex 32)"
```

然後開啟：

- `http://<tailscale-ip>:18789/`（或你設定的 `gateway.controlUi.basePath`）

將標記貼上到 UI 設定（作為 `connect.params.auth.token` 傳送）。

## 不安全的 HTTP

如果你透過純 HTTP（`http://<lan-ip>` 或 `http://<tailscale-ip>`）開啟儀表板，瀏覽器在**非安全內容**中執行並阻止 WebCrypto。預設情況下，OpenClaw **阻止**沒有裝置身分的 Control UI 連接。

**建議修正：** 使用 HTTPS（Tailscale Serve）或在本機開啟 UI：

- `https://<magicdns>/`（Serve）
- `http://127.0.0.1:18789/`（在 Gateway 主機上）

**降級範例（HTTP 上的純標記）：**

```json5
{
  gateway: {
    controlUi: { allowInsecureAuth: true },
    bind: "tailnet",
    auth: { mode: "token", token: "replace-me" },
  },
}
```

這會停用 Control UI 的裝置身分 + 配對（甚至在 HTTPS 上）。僅在你信任網路時使用。

詳見[Tailscale](/zh-Hant/gateway/tailscale)了解 HTTPS 設定指南。

## 建置 UI

Gateway 從 `dist/control-ui` 提供靜態檔案。使用以下方式建置：

```bash
pnpm ui:build # 首次執行時自動安裝 UI 依賴項
```

選擇性絕對基數（當你想要固定資產 URL 時）：

```bash
OPENCLAW_CONTROL_UI_BASE_PATH=/openclaw/ pnpm ui:build
```

用於本機開發（獨立開發伺服器）：

```bash
pnpm ui:dev # 首次執行時自動安裝 UI 依賴項
```

然後指向 UI 到你的 Gateway WS URL（例如 `ws://127.0.0.1:18789`）。

## 調試/測試：開發伺服器 + 遠端 Gateway

Control UI 是靜態檔案；WebSocket 目標是可設定的，可能與 HTTP 來源不同。當你想要本機 Vite 開發伺服器但 Gateway 在其他地方執行時很方便。

1. 啟動 UI 開發伺服器：`pnpm ui:dev`
2. 開啟如下 URL：

```text
http://localhost:5173/?gatewayUrl=ws://<gateway-host>:18789
```

選擇性一次性驗證（如果需要）：

```text
http://localhost:5173/?gatewayUrl=wss://<gateway-host>:18789&token=<gateway-token>
```

注意事項：

- `gatewayUrl` 在載入後儲存在 localStorage 中，並從 URL 移除。
- `token` 儲存在 localStorage；`password` 僅保留在記憶體中。
- 當設定 `gatewayUrl` 時，UI 不會回退到設定或環境認證。明確提供 `token`（或 `password`）。遺漏明確認證是錯誤。
- 當 Gateway 在 TLS 後面（Tailscale Serve、HTTPS 代理等）時，使用 `wss://`。
- `gatewayUrl` 僅在頂級視窗中接受（未嵌入），以防止點擊劫持。
- 對於跨來源開發設定（例如 `pnpm ui:dev` 到遠端 Gateway），將 UI 來源新增到 `gateway.controlUi.allowedOrigins`。

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
