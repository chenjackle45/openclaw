---
summary: "OpenClaw Gateway CLI (`openclaw gateway`) — 運行、查詢與發現 Gateway"
read_when:
  - 從 CLI 運行 Gateway（開發或伺服器環境）時
  - 偵錯 Gateway 認證、綁定模式與連線問題時
  - 透過 Bonjour（區域網路或 Tailnet）發現 Gateway 時
title: "gateway（Gateway CLI）"
---

# Gateway CLI

Gateway 是 OpenClaw 的 WebSocket 伺服器（頻道、節點、會話、hooks）。

本頁面說明的子指令皆位於 `openclaw gateway …` 之下。

相關文件：

- [/gateway/bonjour](/zh-Hant/gateway/bonjour)
- [/gateway/discovery](/zh-Hant/gateway/discovery)
- [/gateway/configuration](/zh-Hant/gateway/configuration)

## 運行 Gateway

運行本地 Gateway 進程：

```bash
openclaw gateway
```

前景運行別名：

```bash
openclaw gateway run
```

注意事項：

- 預設情況下，除非在 `~/.openclaw/openclaw.json` 中設定了 `gateway.mode=local`，否則 Gateway 會拒絕啟動。臨時/開發執行請使用 `--allow-unconfigured`。
- 未啟用認證時，禁止綁定至非 loopback 位址（安全防護）。
- `SIGUSR1` 在獲得授權時（`commands.restart` 預設啟用；設定 `commands.restart: false` 可阻止手動重新啟動，但 gateway tool/config apply/update 仍允許）觸發進程內重新啟動。
- `SIGINT`/`SIGTERM` 處理器會停止 gateway 進程，但不會還原任何自訂終端機狀態。若您以 TUI 或原始模式輸入包裝 CLI，請在退出前還原終端機。

### 選項

- `--port <port>`：WebSocket 連接埠（預設來自 config/env；通常為 `18789`）。
- `--bind <loopback|lan|tailnet|auto|custom>`：監聽綁定模式。
- `--auth <token|password>`：認證模式覆寫。
- `--token <token>`：token 覆寫（同時為進程設定 `OPENCLAW_GATEWAY_TOKEN`）。
- `--password <password>`：密碼覆寫。警告：內聯密碼可能在本地進程列表中被暴露。
- `--password-file <path>`：從檔案讀取 gateway 密碼。
- `--tailscale <off|serve|funnel>`：透過 Tailscale 暴露 Gateway。
- `--tailscale-reset-on-exit`：關機時重設 Tailscale serve/funnel 設定。
- `--allow-unconfigured`：允許在 config 中沒有 `gateway.mode=local` 的情況下啟動 gateway。
- `--dev`：若缺少則建立開發版 config + workspace（跳過 BOOTSTRAP.md）。
- `--reset`：重設開發版 config + 憑證 + 會話 + workspace（需要 `--dev`）。
- `--force`：啟動前強制終止所選連接埠上的現有監聽器。
- `--verbose`：詳細日誌。
- `--claude-cli-logs`：僅在控制台顯示 claude-cli 日誌（並啟用其 stdout/stderr）。
- `--ws-log <auto|full|compact>`：websocket 日誌風格（預設 `auto`）。
- `--compact`：`--ws-log compact` 的別名。
- `--raw-stream`：將原始模型串流事件記錄至 jsonl。
- `--raw-stream-path <path>`：原始串流 jsonl 路徑。

## 查詢運行中的 Gateway

所有查詢指令皆使用 WebSocket RPC。

輸出模式：

- 預設：易於閱讀的格式（TTY 環境下帶色彩）。
- `--json`：機器可讀的 JSON 格式（無樣式/動畫）。
- `--no-color`（或 `NO_COLOR=1`）：停用 ANSI 同時保留人類可讀佈局。

共用選項（支援時）：

- `--url <url>`：Gateway WebSocket URL。
- `--token <token>`：Gateway token。
- `--password <password>`：Gateway 密碼。
- `--timeout <ms>`：逾時/預算（依指令而異）。
- `--expect-final`：等待「最終」回應（agent 呼叫）。

注意：設定 `--url` 時，CLI 不會回退至 config 或環境憑證。請明確傳遞 `--token` 或 `--password`。缺少明確憑證為錯誤。

### `gateway health`

```bash
openclaw gateway health --url ws://127.0.0.1:18789
```

### `gateway status`

`gateway status` 顯示 Gateway 服務（launchd/systemd/schtasks）加上可選的 RPC 探測。

```bash
openclaw gateway status
openclaw gateway status --json
```

選項：

- `--url <url>`：覆寫探測 URL。
- `--token <token>`：探測的 token 認證。
- `--password <password>`：探測的密碼認證。
- `--timeout <ms>`：探測逾時（預設 `10000`）。
- `--no-probe`：跳過 RPC 探測（僅服務視圖）。
- `--deep`：同時掃描系統層級的服務。

注意事項：

- `gateway status` 會在可能時解析配置的認證 SecretRefs 以進行探測認證。
- 若必要的認證 SecretRef 在此指令路徑中未解析，探測認證可能會失敗；請明確傳遞 `--token`/`--password` 或先解析密鑰來源。
- 在 Linux systemd 安裝中，服務認證漂移檢查從 unit 讀取 `Environment=` 和 `EnvironmentFile=` 兩種值（包含 `%h`、引號路徑、多個檔案和可選的 `-` 檔案）。

### `gateway probe`

`gateway probe` 是「全部偵錯」指令。它始終探測：

- 您配置的遠端 gateway（若已設定），以及
- localhost（loopback）**即使遠端已配置**。

若多個 gateway 可連線，它會列印所有。當您使用隔離的設定檔/連接埠時支援多個 gateway（例如救援機器人），但大多數安裝仍執行單個 gateway。

```bash
openclaw gateway probe
openclaw gateway probe --json
```

#### 遠端 SSH（與 macOS App 對等）

macOS App 的「遠端 SSH」模式使用本地連接埠轉發，使遠端 gateway（可能只綁定至 loopback）在 `ws://127.0.0.1:<port>` 上可連線。

CLI 等效指令：

```bash
openclaw gateway probe --ssh user@gateway-host
```

選項：

- `--ssh <target>`：`user@host` 或 `user@host:port`（連接埠預設為 `22`）。
- `--ssh-identity <path>`：身份檔案。
- `--ssh-auto`：選擇第一個探索到的 gateway 主機作為 SSH 目標（僅 LAN/WAB）。

設定（選用，用作預設值）：

- `gateway.remote.sshTarget`
- `gateway.remote.sshIdentity`

### `gateway call <method>`

低階 RPC 輔助工具。

```bash
openclaw gateway call status
openclaw gateway call logs.tail --params '{"sinceMs": 60000}'
```

## 管理 Gateway 服務

```bash
openclaw gateway install
openclaw gateway start
openclaw gateway stop
openclaw gateway restart
openclaw gateway uninstall
```

注意事項：

- `gateway install` 支援 `--port`、`--runtime`、`--token`、`--force`、`--json`。
- 當 token 認證需要 token 且 `gateway.auth.token` 是 SecretRef 管理的，`gateway install` 會驗證 SecretRef 是否可解析，但不會將解析後的 token 儲存至服務環境中繼資料。
- 若 token 認證需要 token 且配置的 token SecretRef 未解析，安裝會快速失敗，而非儲存回退的明文。
- 對於 `gateway run` 的密碼認證，建議優先使用 `OPENCLAW_GATEWAY_PASSWORD`、`--password-file` 或 SecretRef 支援的 `gateway.auth.password`，而非內聯 `--password`。
- 在推斷認證模式下，僅限 shell 的 `OPENCLAW_GATEWAY_PASSWORD`/`CLAWDBOT_GATEWAY_PASSWORD` 不會放寬安裝 token 要求；安裝受管理服務時請使用持久設定（`gateway.auth.password` 或 config `env`）。
- 若 `gateway.auth.token` 和 `gateway.auth.password` 均已配置，且 `gateway.auth.mode` 未設定，安裝會被阻止直到明確設定 mode 為止。
- 生命週期指令接受 `--json` 以供腳本使用。

## 探索 Gateway（Bonjour）

`gateway discover` 掃描 Gateway 信標（`_openclaw-gw._tcp`）。

- 多播 DNS-SD：`local.`
- 單播 DNS-SD（廣域 Bonjour）：選擇一個網域（例如 `openclaw.internal.`）並設定分割 DNS + DNS 伺服器；請參閱 [/gateway/bonjour](/zh-Hant/gateway/bonjour)

只有啟用 Bonjour 探索（預設）的 gateway 才會廣播信標。

廣域探索記錄包含（TXT）：

- `role`（gateway 角色提示）
- `transport`（傳輸提示，例如 `gateway`）
- `gatewayPort`（WebSocket 連接埠，通常為 `18789`）
- `sshPort`（SSH 連接埠；若不存在預設為 `22`）
- `tailnetDns`（MagicDNS 主機名稱，若可用）
- `gatewayTls` / `gatewayTlsSha256`（TLS 啟用 + 憑證指紋）
- `cliPath`（遠端安裝的選用提示）

### `gateway discover`

```bash
openclaw gateway discover
```

選項：

- `--timeout <ms>`：每個指令逾時（瀏覽/解析）；預設 `2000`。
- `--json`：機器可讀輸出（亦停用樣式/動畫）。

範例：

```bash
openclaw gateway discover --timeout 4000
openclaw gateway discover --json | jq '.beacons[].wsUrl'
```
