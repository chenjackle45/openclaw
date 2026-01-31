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

- `--no-probe`：僅查看服務狀態，不執行 RPC 探針。
- `--deep`：同時掃描系統層級的其它服務。

### `gateway probe` (偵錯探針)

用於調試所有可存取的 Gateway。它會同時掃描：
1. 您配置的遠端 Gateway（若有）。
2. 本地的 localhost（回環位址）。

```bash
openclaw gateway probe
```

#### 透過 SSH 進行遠端存取 (SSH Tunnel)

類似於 macOS App 的「Remote over SSH」模式，這會建立本地埠位轉發。

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
