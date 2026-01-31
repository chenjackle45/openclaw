---
title: "index(Gateway Service)"
summary: "Gateway 服務的運行手冊、生命週期與操作"
read_when:
  - 運行或除錯 Gateway 程序時
---

# Gateway 服務運行手冊

最後更新: 2025-12-09

## 這係什麼
- 擁有單一 Baileys/Telegram 連線與控制/事件平面的永遠在線 (always-on) 程序。
- 取代舊版 `gateway` 指令。CLI 入口點: `openclaw gateway`。
- 持續運行直到被停止；發生致命錯誤時非零退出，以便 Supervisor 重啟它。

## 如何運行 (本機)
```bash
openclaw gateway --port 18789
# 在 stdio 中顯示完整除錯/追蹤日誌:
openclaw gateway --port 18789 --verbose
# 若連接埠忙碌，終止聆聽者然後啟動:
openclaw gateway --force
# 開發迴圈 (TS 變更時自動重載):
pnpm gateway:watch
```
- 設定熱重載 (Hot reload) 監聽 `~/.openclaw/openclaw.json` (或 `OPENCLAW_CONFIG_PATH`)。
  - 預設模式: `gateway.reload.mode="hybrid"` (熱套用安全變更，關鍵變更則重啟)。
  - 需要時透過 **SIGUSR1** 進行程序內重啟。
  - 使用 `gateway.reload.mode="off"` 停用。
- 將 WebSocket控制平面綁定至 `127.0.0.1:<port>` (預設 18789)。
- 同一個連接埠也服務 HTTP (Control UI, hooks, A2UI)。單埠多工。
  - OpenAI Chat Completions (HTTP): [`/v1/chat/completions`](/gateway/openai-http-api).
  - OpenResponses (HTTP): [`/v1/responses`](/gateway/openresponses-http-api).
  - Tools Invoke (HTTP): [`/tools/invoke`](/gateway/tools-invoke-http-api).
- 預設在 `canvasHost.port` (預設 `18793`) 啟動 Canvas 檔案伺服器，從 `~/.openclaw/workspace/canvas` 服務 `http://<gateway-host>:18793/__openclaw__/canvas/`。使用 `canvasHost.enabled=false` 或 `OPENCLAW_SKIP_CANVAS_HOST=1` 停用。
- 寫入日誌至 stdout；使用 launchd/systemd 保持存活並輪替日誌。
- 故障排除時傳遞 `--verbose` 以將除錯日誌 (handshakes, req/res, events) 從日誌檔鏡像至 stdio。
- `--force` 使用 `lsof` 尋找選定連接埠上的聆聽者，發送 SIGTERM，記錄被殺死的程序，然後啟動 gateway (若缺少 `lsof` 則快速失敗)。
- 若您在 Supervisor (launchd/systemd/mac app child-process mode) 下運行，停止/重啟通常發送 **SIGTERM**；較舊的組建可能會顯示為 `pnpm` `ELIFECYCLE` 退出碼 **143** (SIGTERM)，這是正常關閉，並非崩潰。
- **SIGUSR1** 在授權時觸發程序內重啟 (gateway tool/config apply/update，或啟用 `commands.restart` 進行手動重啟)。
- 預設需要 Gateway 認證：設定 `gateway.auth.token` (或 `OPENCLAW_GATEWAY_TOKEN`) 或 `gateway.auth.password`。用戶端必須發送 `connect.params.auth.token/password`，除非使用 Tailscale Serve 身分。
- 精靈現在預設會產生 Token，即使在 Loopback 上也是如此。
- 連接埠優先順序: `--port` > `OPENCLAW_GATEWAY_PORT` > `gateway.port` > 預設 `18789`。

## 遠端存取
- 首選 Tailscale/VPN；否則使用 SSH Tunnel:
  ```bash
  ssh -N -L 18789:127.0.0.1:18789 user@host
  ```
- 用戶端隨後透過 Tunnel 連線至 `ws://127.0.0.1:18789`。
- 若設定了 Token，用戶端即使透過 Tunnel 也必須在 `connect.params.auth.token` 中包含它。

## 多個 Gateway (同一主機)

通常不需要：一個 Gateway 可以服務多個訊息 Channel 與 Agent。僅在為了冗餘或嚴格隔離 (例如：救援機器人) 時使用多個 Gateway。

若您隔離狀態 + 設定並使用唯一連接埠，則支援此功能。完整指南: [Multiple gateways](/gateway/multiple-gateways)。

服務名稱具備 Profile 感知能力：
- macOS: `bot.molt.<profile>` (舊版 `com.openclaw.*` 可能仍存在)
- Linux: `openclaw-gateway-<profile>.service`
- Windows: `OpenClaw Gateway (<profile>)`

安裝中繼資料嵌入在服務設定中：
- `OPENCLAW_SERVICE_MARKER=openclaw`
- `OPENCLAW_SERVICE_KIND=gateway`
- `OPENCLAW_SERVICE_VERSION=<version>`

救援機器人模式 (Rescue-Bot Pattern): 保持第二個 Gateway 隔離，擁有自己的 Profile、狀態目錄、工作區與基礎連接埠間距。完整指南: [Rescue-bot guide](/gateway/multiple-gateways#rescue-bot-guide)。

### Dev Profile (`--dev`)

快速路徑: 運行完全隔離的開發實例 (config/state/workspace) 而不影響您的主要設定。

```bash
openclaw --dev setup
openclaw --dev gateway --allow-unconfigured
# 然後針對開發實例:
openclaw --dev status
openclaw --dev health
```

預設值 (可透過 env/flags/config 覆蓋):
- `OPENCLAW_STATE_DIR=~/.openclaw-dev`
- `OPENCLAW_CONFIG_PATH=~/.openclaw-dev/openclaw.json`
- `OPENCLAW_GATEWAY_PORT=19001` (Gateway WS + HTTP)
- 瀏覽器控制服務連接埠 = `19003` (推導: `gateway.port+2`, 僅限 loopback)
- `canvasHost.port=19005` (推導: `gateway.port+4`)
- 當您在 `--dev` 下執行 `setup`/`onboard` 時，`agents.defaults.workspace` 預設變為 `~/.openclaw/workspace-dev`。

推導連接埠 (經驗法則):
- Base port = `gateway.port` (或 `OPENCLAW_GATEWAY_PORT` / `--port`)
- 瀏覽器控制服務連接埠 = base + 2 (僅限 loopback)
- `canvasHost.port = base + 4` (或 `OPENCLAW_CANVAS_HOST_PORT` / config override)
- 瀏覽器 Profile CDP 連接埠從 `browser.controlPort + 9 .. + 108` 自動分配 (每個 Profile 持久化)。

每個實例的檢查清單:
- 唯一的 `gateway.port`
- 唯一的 `OPENCLAW_CONFIG_PATH`
- 唯一的 `OPENCLAW_STATE_DIR`
- 唯一的 `agents.defaults.workspace`
- 獨立的 WhatsApp 號碼 (若使用 WA)

每個 Profile 的服務安裝:
```bash
openclaw --profile main gateway install
openclaw --profile rescue gateway install
```

範例:
```bash
OPENCLAW_CONFIG_PATH=~/.openclaw/a.json OPENCLAW_STATE_DIR=~/.openclaw-a openclaw gateway --port 19001
OPENCLAW_CONFIG_PATH=~/.openclaw/b.json OPENCLAW_STATE_DIR=~/.openclaw-b openclaw gateway --port 19002
```

## 協定 (操作者觀點)
- 完整文件: [Gateway protocol](/gateway/protocol) 與 [Bridge protocol (legacy)](/gateway/bridge-protocol)。
- 用戶端強制的第一個 Frame: `req {type:"req", id, method:"connect", params:{minProtocol,maxProtocol,client:{id,displayName?,version,platform,deviceFamily?,modelIdentifier?,mode,instanceId?}, caps, auth?, locale?, userAgent? } }`。
- Gateway 回覆 `res {type:"res", id, ok:true, payload:hello-ok }` (或 `ok:false` 帶錯誤，然後關閉)。
- 握手後:
  - 請求: `{type:"req", id, method, params}` → `{type:"res", id, ok, payload|error}`
  - 事件: `{type:"event", event, payload, seq?, stateVersion?}`
- 結構化 Presence 項目: `{host, ip, version, platform?, deviceFamily?, modelIdentifier?, mode, lastInputSeconds?, ts, reason?, tags?[], instanceId? }` (對於 WS 用戶端，`instanceId` 來自 `connect.client.instanceId`)。
- `agent` 回應是兩階段的：首先 `res` ack `{runId,status:"accepted"}`, 然後是最終 `res` `{runId,status:"ok"|"error",summary}` 在執行結束後；串流輸出以 `event:"agent"` 到達。

## 方法 (初始集合)
- `health` — 完整健康快照 (與 `openclaw health --json` 形狀相同)。
- `status` — 簡短摘要。
- `system-presence` — 目前 Presence 清單。
- `system-event` — 發布 Presence/系統註記 (結構化)。
- `send` — 透過活動 Channel 發送訊息。
- `agent` — 執行一次 Agent Turn (在同一個連線上串流事件回傳)。
- `node.list` — 列出已配對 + 目前連線的節點 (包含 `caps`, `deviceFamily`, `modelIdentifier`, `paired`, `connected`, 與廣播的 `commands`)。
- `node.describe` — 描述一個節點 (功能 + 支援的 `node.invoke` 指令；適用於已配對節點與目前連線的未配對節點)。
- `node.invoke` — 在節點上呼叫指令 (例如 `canvas.*`, `camera.*`)。
- `node.pair.*` — 配對生命週期 (`request`, `list`, `approve`, `reject`, `verify`)。

參閱: [Presence](/concepts/presence) 了解 Presence 如何產生/去重以及為何穩定的 `client.instanceId` 很重要。

## 事件
- `agent` — 來自 Agent 執行的串流工具/輸出事件 (seq-tagged)。
- `presence` — Presence 更新 (deltas with stateVersion) 推送給所有連線的用戶端。
- `tick` — 定期 keepalive/no-op 以確認存活。
- `shutdown` — Gateway 正在退出；Payload 包含 `reason` 與選用的 `restartExpectedMs`。用戶端應重新連線。

## WebChat 整合
- WebChat 是一個原生 SwiftUI UI，直接與 Gateway WebSocket 對話以取得歷史記錄、發送、中止與事件。
- 遠端使用透過相同的 SSH/Tailscale tunnel；若設定了 Gateway Token，用戶端在 `connect` 期間包含它。
- macOS App 透過單一 WS 連線 (共享連線)；它從初始快照 Hydrate Presence 並監聽 `presence` 事件以更新 UI。

## 類型與驗證
- 伺服器使用 AJV 針對從協定定義發出的 JSON Schema 驗證每個 Inbound Frame。
- 用戶端 (TS/Swift) 使用生成的類型 (TS 直接使用；Swift 透過 Repo 的產生器)。
- 協定定義是 Source of Truth；使用以下指令重新生成 Schema/Models：
  - `pnpm protocol:gen`
  - `pnpm protocol:gen:swift`

## 連線快照
- `hello-ok` 包含一個 `snapshot` 帶有 `presence`, `health`, `stateVersion`, 與 `uptimeMs` 加上 `policy {maxPayload,maxBufferedBytes,tickIntervalMs}`，讓用戶端無需額外請求即可立即渲染。
- `health`/`system-presence` 仍可用於手動重新整理，但在連線時並非必要。

## 錯誤碼 (res.error 形狀)
- 錯誤使用 `{ code, message, details?, retryable?, retryAfterMs? }`。
- 標準代碼:
  - `NOT_LINKED` — WhatsApp 未驗證。
  - `AGENT_TIMEOUT` — Agent 未在設定的截止時間內回應。
  - `INVALID_REQUEST` — Schema/Param 驗證失敗。
  - `UNAVAILABLE` — Gateway 正在關閉或依賴項目無法使用。

## Keepalive 行為
- 定期發送 `tick` 事件 (或 WS ping/pong)，讓用戶端知道 Gateway 活著，即使沒有流量發生。
- Send/agent 確認保持獨立的回應；不要為了 Sends 過載 Ticks。

## 重播 / Gaps
- 事件不會重播。用戶端偵測 Seq gaps 並應在繼續前重新整理 (`health` + `system-presence`)。WebChat 與 macOS 用戶端現在會在 Gap 發生時自動重新整理。

## Supervision (macOS 範例)
- 使用 launchd 保持服務存活:
  - Program: path to `openclaw`
  - Arguments: `gateway`
  - KeepAlive: true
  - StandardOut/Err: file paths or `syslog`
- 失敗時，launchd 重啟；致命錯誤設定應保持退出以便操作者注意。
- LaunchAgents 是 Per-user 的且需要登入的工作階段；對於 Headless 設定，使用自訂 LaunchDaemon (未隨附)。
  - `openclaw gateway install` 寫入 `~/Library/LaunchAgents/bot.molt.gateway.plist`
    (或 `bot.molt.<profile>.plist`; 舊版 `com.openclaw.*` 會被清理)。
  - `openclaw doctor` 稽核 LaunchAgent 設定並可將其更新至目前預設值。

## Gateway 服務管理 (CLI)

使用 Gateway CLI 進行 install/start/stop/restart/status:

```bash
openclaw gateway status
openclaw gateway install
openclaw gateway stop
openclaw gateway restart
openclaw logs --follow
```

備註:
- `gateway status` 預設使用服務解析的連接埠/設定探測 Gateway RPC (使用 `--url` 覆蓋)。
- `gateway status --deep` 新增系統層級掃描 (LaunchDaemons/system units)。
- `gateway status --no-probe` 跳過 RPC 探測 (在網路中斷時有用)。
- `gateway status --json` 對腳本穩定。
- `gateway status` 分別報告 **Supervisor runtime** (launchd/systemd 運行中) 與 **RPC reachability** (WS connect + status RPC)。
- `gateway status` 印出 Config path + Probe target 以避免 “localhost vs LAN bind” 混淆與 Profile 不相符。
- `gateway status` 在服務看起來運行中但連接埠關閉時，包含最後的 Gateway 錯誤行。
- `logs` 透過 RPC 追蹤 Gateway 檔案日誌 (無需手動 `tail`/`grep`)。
- 若偵測到其他類 Gateway 服務，CLI 會發出警告，除非它們是 OpenClaw Profile 服務。
  大多數設定我們仍建議 **每台機器一個 Gateway**；使用隔離的 Profiles/Ports 進行冗餘或救援機器人。參閱 [Multiple gateways](/gateway/multiple-gateways)。
  - 清理: `openclaw gateway uninstall` (目前服務) 與 `openclaw doctor` (舊版遷移)。
- `gateway install` 在已安裝時為 No-op；使用 `openclaw gateway install --force` 重新安裝 (Profile/Env/Path 變更)。

綑綁的 Mac App:
- OpenClaw.app 可綑綁基於 Node 的 Gateway Relay 並安裝 Per-user LaunchAgent 標記為 `bot.molt.gateway` (或 `bot.molt.<profile>`; 舊版 `com.openclaw.*` 標記仍可乾淨卸載)。
- 要乾淨停止，使用 `openclaw gateway stop` (或 `launchctl bootout gui/$UID/bot.molt.gateway`)。
- 要重啟，使用 `openclaw gateway restart` (或 `launchctl kickstart -k gui/$UID/bot.molt.gateway`)。
  - `launchctl` 僅在 LaunchAgent 安裝後有效；否則先使用 `openclaw gateway install`。
  - 運行具名 Profile 時將標記替換為 `bot.molt.<profile>`。

## Supervision (systemd user unit)
OpenClaw 在 Linux/WSL2 上預設安裝 **systemd user service**。我們建議單一使用者機器使用 User Services (較簡單的環境，Per-user Config)。對於多使用者或 Always-on 伺服器，使用 **System Service** (無需 Lingering，共享 Supervision)。

`openclaw gateway install` 寫入 User Unit。`openclaw doctor` 稽核 Unit 並可將其更新以符合目前推薦預設值。

建立 `~/.config/systemd/user/openclaw-gateway[-<profile>].service`:
```
[Unit]
Description=OpenClaw Gateway (profile: <profile>, v<version>)
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/openclaw gateway --port 18789
Restart=always
RestartSec=5
Environment=OPENCLAW_GATEWAY_TOKEN=
WorkingDirectory=/home/youruser

[Install]
WantedBy=default.target
```
啟用 Lingering (User Service 在登出/閒置後存活所需):
```
sudo loginctl enable-linger youruser
```
Onboarding 在 Linux/WSL2 上執行此操作 (可能提示 sudo；寫入 `/var/lib/systemd/linger`)。
然後啟用服務:
```
systemctl --user enable --now openclaw-gateway[-<profile>].service
```

**替代方案 (System Service)** - 對於 Always-on 或多使用者伺服器，您可以安裝 systemd **system** unit 代替 user unit (無需 Lingering)。
建立 `/etc/systemd/system/openclaw-gateway[-<profile>].service` (複製上面的 Unit，切換 `WantedBy=multi-user.target`，設定 `User=` + `WorkingDirectory=`)，然後:
```
sudo systemctl daemon-reload
sudo systemctl enable --now openclaw-gateway[-<profile>].service
```

## Windows (WSL2)

Windows 安裝應使用 **WSL2** 並遵循上述 Linux systemd 章節。

## 操作檢查
- Liveness: 開啟 WS 並發送 `req:connect` → 預期 `res` 帶有 `payload.type="hello-ok"` (含 snapshot)。
- Readiness: 呼叫 `health` → 預期 `ok: true` 與 `linkChannel` 中已連結的 Channel (若適用)。
- Debug: 訂閱 `tick` 與 `presence` 事件；確保 `status` 顯示 Linked/Auth age；Presence 項目顯示 Gateway Host 與已連線用戶端。

## 安全性保證
- 預設假設每台主機一個 Gateway；若運行多個 Profile，隔離 Ports/State 並指向正確的實例。
- 無直接 Baileys 連線的回退 (Fallback)；若 Gateway 當機，Sends 快速失敗。
- 非 Connect 的第一個 Frames 或格式錯誤的 JSON 會被拒絕並關閉 Socket。
- 優雅關閉: 在關閉前發送 `shutdown` 事件；用戶端必須處理 Close + Reconnect。

## CLI 輔助工具
- `openclaw gateway health|status` — 透過 Gateway WS 請求 Health/Status。
- `openclaw message send --target <num> --message "hi" [--media ...]` — 透過 Gateway 發送 (WhatsApp 為冪等)。
- `openclaw agent --message "hi" --to <num>` — 執行一次 Agent Turn (預設等待最終結果)。
- `openclaw gateway call <method> --params '{"k":"v"}'` — 用於除錯的原始方法呼叫器。
- `openclaw gateway stop|restart` — 停止/重啟受監管的 Gateway 服務 (launchd/systemd)。
- Gateway 輔助子指令假設 `--url` 上有運行中的 Gateway；它們不再自動衍生 (Spawn) 一個。

## 遷移指引
- 淘汰使用 `openclaw gateway` 與舊版 TCP 控制連接埠。
- 更新用戶端以使用強制 Connect 與結構化 Presence 的 WS 協定。
