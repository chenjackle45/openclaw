---
title: "gateway(Gateway 服務)"
summary: "OpenClaw Gateway CLI (`openclaw gateway`) —— 運行、查詢與發現 Gateway"
read_when:
  - 從 CLI 運行 Gateway（開發或伺服器環境）時
  - 調試 Gateway 認證、綁定模式與連線問題時
  - 透過 Bonjour (區域網路或 Tailnet) 發現 Gateway 時
---

# Gateway CLI

Gateway 是 OpenClaw 的 WebSocket 伺服器，負責管理頻道 (Channels)、節點 (Nodes)、會話 (Sessions) 與鉤子 (Hooks)。

本頁面說明的子指令皆位於 `openclaw gateway …` 之下。

相關文件：
- [Bonjour 發現](/gateway/bonjour)
- [廣域發現與 DNS](/gateway/discovery)
- [Gateway 配置](/gateway/configuration)

## 運行 Gateway

運行本地 Gateway 進程：

```bash
openclaw gateway
```

前景運行別名：

```bash
openclaw gateway run
```

**注意事項**：
- 預設情況下，除非在 `~/.openclaw/openclaw.json` 中設定了 `gateway.mode=local`，否則 Gateway 會拒絕啟動。開發或臨時運行可加上 `--allow-unconfigured` 旗標。
- 為了安全起見，禁止在未啟用認證的情況下綁定至非本地回環 (Loopback) 位址。
- 具備權限時，可透過 `SIGUSR1` 訊號觸發進程內重啟。
- `SIGINT`/`SIGTERM` 控制信號會停止進程。

### 參數選項

- `--port <port>`：WebSocket 埠位（通常預設為 `18789`）。
- `--bind <loopback|lan|tailnet|auto|custom>`：監聽綁定模式。
- `--auth <token|password>`：認證模式覆寫。
- `--token <token>`：權杖 (Token) 覆寫。
- `--password <password>`：密碼覆寫。
- `--tailscale <off|serve|funnel>`：透過 Tailscale 暴露 Gateway。
- `--dev`：建立開發用配置與工作區（跳過 BOOTSTRAP.md）。
- `--reset`：重設開發版配置、憑證、會話與工作區（需搭配 `--dev`）。
- `--force`：啟動前強制關閉該埠位既有的監聽程式。
- `--ws-log <auto|full|compact>`：設定 WebSocket 日誌風格。
- `--raw-stream`：將原始模型的串流事件日誌記錄為 JSONL 格式。

## 查詢運行中的 Gateway

所有查詢指令皆使用 WebSocket RPC 協定。

輸出模式：
- 預設：易於閱讀的格式（TTY 環境下帶色彩）。
- `--json`：機器可讀的 JSON 格式（停用樣式與動畫）。

共用選項：
- `--url <url>`：Gateway 的 WebSocket URL。
- `--token <token>`：認證權杖。
- `--password <password>`：認證密碼。
- `--timeout <ms>`：超時設定。
- `--expect-final`：等待「最終」回應（適用於 Agent 調用）。

### `gateway health` (健康檢查)

```bash
openclaw gateway health --url ws://127.0.0.1:18789
```

### `gateway status` (狀態盤查)

顯示 Gateway 系統服務狀態以及選用的 RPC 探針。

```bash
openclaw gateway status
openclaw gateway status --json
```

- `--url <url>`：覆寫探針 URL。
- `--token <token>`：探針的權杖認證。
- `--password <password>`：探針的密碼認證。
- `--timeout <ms>`：探針超時（預設 `10000`）。
- `--no-probe`：跳過 RPC 探針（僅查看服務）。
- `--deep`：同時掃描系統層級的服務。

### `gateway probe` (偵錯探針)

`gateway probe` 是「調試所有內容」指令。它始終探針：

- 您配置的遠端 Gateway（若有），以及
- localhost (loopback) **即使遠端已配置**。

若多個 Gateway 可達，它將列印所有。當您使用隔離的設定檔/埠位時支援多個 Gateway（例如救援機器人），但大多數安裝仍執行單個 Gateway。

```bash
openclaw gateway probe
openclaw gateway probe --json
```

#### 遠端 SSH 存取 (與 macOS App 對等)

macOS App 的「遠端 SSH」模式使用本地埠位轉發，使遠端 Gateway（可能只綁定至 loopback）在 `ws://127.0.0.1:<port>` 上可達。

CLI 等效用法：

```bash
openclaw gateway probe --ssh user@gateway-host
```

選項：

- `--ssh <target>`：`user@host` 或 `user@host:port` (埠位預設 `22`)。
- `--ssh-identity <path>`：身份檔案。
- `--ssh-auto`：選擇第一個發現的 Gateway 主機作為 SSH 目標（僅 LAN/WAB）。

配置（選用，用作預設值）：

- `gateway.remote.sshTarget`
- `gateway.remote.sshIdentity`

### `gateway call <method>`

低級 RPC 助手。

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

注意：

- `gateway install` 支援 `--port`、`--runtime`、`--token`、`--force`、`--json`。
- 生命週期指令接受 `--json` 用於指令化。

## 發現 Gateway (Bonjour)

`gateway discover` 掃描 Gateway 信號 (`_openclaw-gw._tcp`)。

- 多播 DNS-SD：`local.`
- 單播 DNS-SD（廣域 Bonjour）：選擇一個網域（例如 `openclaw.internal.`）並設定分割 DNS + DNS 伺服器；詳見 [/gateway/bonjour](/gateway/bonjour)

只有啟用 Bonjour 發現（預設）的 Gateway 才會廣告信號。

廣域發現記錄包括 (TXT)：

- `role` (Gateway 角色提示)
- `transport` (傳輸提示，例如 `gateway`)
- `gatewayPort` (WebSocket 埠位，通常 `18789`)
- `sshPort` (SSH 埠位；若不存在預設 `22`)
- `tailnetDns` (MagicDNS 主機名稱，若可用)
- `gatewayTls` / `gatewayTlsSha256` (TLS 啟用 + 憑證指紋)
- `cliPath` (遠端安裝的選用提示)

### `gateway discover`

```bash
openclaw gateway discover
```

選項：

- `--timeout <ms>`：每個指令超時（瀏覽/解析）；預設 `2000`。
- `--json`：機器可讀輸出（亦停用樣式/動畫）。

範例：

```bash
openclaw gateway discover --timeout 4000
openclaw gateway discover --json | jq '.beacons[].wsUrl'
```

```bash
openclaw gateway probe --ssh 使用者@主機名
```

## 管理 Gateway 服務

```bash
# 安裝、啟動、停止、重啟、卸載 Gateway 服務 (launchd/systemd/schtasks)
openclaw gateway install
openclaw gateway start
openclaw gateway stop
openclaw gateway restart
openclaw gateway uninstall
```

## 發現 Gateway (Bonjour)

`gateway discover` 會掃描網域內的 Gateway 指標 (`_openclaw-gw._tcp`)。支援多播 DNS-SD (`local.`) 與單播 DNS-SD（廣域 Bonjour）。

### `gateway discover`

```bash
openclaw gateway discover
openclaw gateway discover --json | jq '.beacons[].wsUrl'
```
