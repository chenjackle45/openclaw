---
title: "Control ui(控制介面)"
summary: "Gateway 的瀏覽器端控制介面（聊天、節點管理、配置編輯）"
read_when:
  - 您想要透過瀏覽器操作 Gateway 時
  - 您想要在不使用 SSH 隧道的情況下透過 Tailnet 存取時
---
# 控制介面 (Control UI)

控制介面是一個由 Gateway 提供的輕量級 **Vite + Lit** 單頁應用程式 (SPA)：

- 預設路徑：`http://<host>:18789/`
- 選用的前綴路徑：設定 `gateway.controlUi.basePath`（例如 `/openclaw`）

它透過同一個連接埠**直接與 Gateway WebSocket 通訊**。

## 快速開啟（本地執行）

如果 Gateway 執行在同一台電腦上，請開啟：
- http://127.0.0.1:18789/ (或 http://localhost:18789/)

若頁面無法讀取，請先啟動 Gateway：使用指令 `openclaw gateway`。

認證資訊是在 WebSocket 交握時透過以下方式提供的：
- `connect.params.auth.token`
- `connect.params.auth.password`
儀表板的「設定 (Settings)」面板允許您儲存 Token；密碼則不會被持久化儲存。
入門精靈預設會生成一個 Gateway Token，首次連線時請將其貼至此處。

## 功能概覽（現狀）

- **聊天**：透過 Gateway WS 與模型對話（包含歷史紀錄、發送、中止、注入訊息等）。
- **即時串流**：在對話中即時顯示工具呼叫與輸出結果卡片（Agent 事件）。
- **頻道管理**：查看 WhatsApp/Telegram/Discord/Slack 及其他插件頻道（如 Mattermost）的狀態、執行 QR 登入、以及針對個別頻道進行配置。
- **實例 (Instances)**：查看在線狀態列表。
- **會話 (Sessions)**：列出所有會話，並可針對個別會話覆寫思考 (Thinking) 或詳細 (Verbose) 模式。
- **排程任務 (Cron jobs)**：列出、新增、執行、啟用或停用任務，並查看執行歷史。
- **技能 (Skills)**：查看狀態、啟用/停用技能、安裝技能、更新 API Key。
- **節點 (Nodes)**：列出所有節點及其功能 (Capabilities)。
- **執行核准 (Exec approvals)**：編輯 Gateway 或節點的執行允許清單，設定執行原則。
- **配置編輯**：檢視與編輯 `~/.openclaw/openclaw.json`（具備驗證、衝突防止機制與對應的 Schema 表單渲染）。
- **偵錯與日誌**：查看狀態/健康度/模型快照、事件紀錄、發送手動 RPC 呼叫。支援即時追蹤 (Live tail) 日誌與匯出功能。
- **更新**：執行套件或 Git 更新並重啟，隨後自動顯示重啟報告。

## 聊天行為說明

- `chat.send` 是**非阻塞 (Non-blocking)** 的：它會立即回傳 `{ runId, status: "started" }`，而回應內容則會透過 `chat` 事件串流傳回。
- `chat.inject` 會在會話紀錄中追加助理筆記，並僅發送 UI 更新事件（不會觸發 Agent 執行，也不會發送至通訊頻道）。
- **停止回應**：
  - 點擊 **Stop** 按鈕（呼叫 `chat.abort`）。
  - 輸入 `/stop` (或 `stop|esc|abort|wait|exit|interrupt`) 來中止任務。

## Tailnet 存取（推薦做法）

### 整合式 Tailscale Serve (首選)

將 Gateway 保持在 loopback，並讓 Tailscale Serve 提供 HTTPS 代理：

```bash
openclaw gateway --tailscale serve
```

路徑：`https://<magicdns>/`

預設情況下，當 `gateway.auth.allowTailscale` 為 `true` 時，Serve 請求可透過 Tailscale 身份標頭 (`tailscale-user-login`) 自動通過認證。

### 綁定至 Tailnet 並使用 Token

```bash
openclaw gateway --bind tailnet --token "$(openssl rand -hex 32)"
```

路徑：`http://<tailscale-ip>:18789/`
請將 Token 貼至 UI 設定面板中。

## 關於非安全 HTTP (Insecure HTTP)

如果您透過普通的 HTTP (`http://<lan-ip>` 或 `http://<tailscale-ip>`) 開啟儀表板，瀏覽器會處於**非安全內容 (Non-secure context)** 環境並阻擋 WebCrypto。預設情況下，OpenClaw 會阻擋這類連線。

**推薦修復方式**：使用 HTTPS (Tailscale Serve) 或在本地開啟 UI：
- `https://<magicdns>/` (Serve 模式)
- `http://127.0.0.1:18789/` (在 Gateway 主機上)

## 建置介面

Gateway 從 `dist/control-ui` 提供靜態檔案。您可以使用以下指令建置：

```bash
pnpm ui:build # 首次執行時會自動安裝 UI 依賴
```

若需本地開發（使用獨立的開發伺服器）：

```bash
pnpm ui:dev
```
然後將 UI 指向您的 Gateway WS 網址（例如 `ws://127.0.0.1:18789`）。
