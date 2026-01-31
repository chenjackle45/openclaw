---
title: "macos(macOS)"
summary: "OpenClaw macOS 配套應用程式 (選單列 + Gateway Broker)"
read_when:
  - 實作 macOS 應用程式功能時
  - 變更 macOS 上的 Gateway 生命週期或節點橋接時
---

# OpenClaw macOS 配套應用程式 (選單列 + Gateway Broker)

macOS 應用程式是 OpenClaw 的 **選單列配套程式**。它擁有權限、管理/連接本地 Gateway (launchd 或手動)，並將 macOS 的能力以節點形式暴露給 Agent。

## 主要功能

- 在選單列顯示原生通知與狀態。
- 擁有 TCC 提示權限（通知、輔助使用、螢幕錄製、麥克風、語音辨識、自動化/AppleScript）。
- 運行或連接至 Gateway（本地或遠端）。
- 暴露 macOS 專屬工具 (Canvas, Camera, Screen Recording, `system.run`)。
- 在 **Remote** 模式下啟動本地節點主機服務 (launchd)，在 **Local** 模式下停止它。
- 可選地託管 **PeekabooBridge** 用於 UI 自動化。
- 應要求透過 npm/pnpm 安裝全域 CLI (`openclaw`)（不建議使用 Bun 作為 Gateway 運行環境）。

## Local vs Remote 模式

- **Local** (預設)：應用程式會連接至正在運行的本地 Gateway（若存在）；否則透過 `openclaw gateway install` 啟用 launchd 服務。
- **Remote**：應用程式透過 SSH/Tailscale 連接至 Gateway，且**不**啟動本地 Gateway 行程。
  應用程式會啟動本地 **節點主機服務**，以便遠端 Gateway 能存取這台 Mac。
  應用程式**不會**將 Gateway 當作子行程啟動。

## Launchd 控制

應用程式管理標籤為 `bot.molt.gateway` 的使用者層級 LaunchAgent
（若使用 `--profile`/`OPENCLAW_PROFILE` 則為 `bot.molt.<profile>`；舊版 `com.openclaw.*` 仍會被卸載）。

```bash
launchctl kickstart -k gui/$UID/bot.molt.gateway
launchctl bootout gui/$UID/bot.molt.gateway
```

當運行具名設定檔時，請將標籤替換為 `bot.molt.<profile>`。

若 LaunchAgent 尚未安裝，請從應用程式中啟用，或執行 `openclaw gateway install`。

## 節點能力 (mac)

macOS 應用程式將自己呈現為一個節點。常見指令：

- Canvas: `canvas.present`, `canvas.navigate`, `canvas.eval`, `canvas.snapshot`, `canvas.a2ui.*`
- Camera: `camera.snap`, `camera.clip`
- Screen: `screen.record`
- System: `system.run`, `system.notify`

節點會報告 `permissions` 對照表，以便 Agent 決定允許的操作。

節點服務 + 應用程式 IPC：
- 當無顯示畫面的節點主機服務運行時（Remote 模式），它會作為節點連接至 Gateway WS。
- `system.run` 透過本地 Unix Socket 在 macOS 應用程式 (UI/TCC 上下文) 中執行；提示與輸出皆保留在應用程式內。

圖示 (SCI)：
```
Gateway -> Node Service (WS)
                 |  IPC (UDS + token + HMAC + TTL)
                 v
             Mac App (UI + TCC + system.run)
```

## 執行核准 (system.run)

`system.run` 受 macOS 應用程式中的 **Exec approvals** 控制（Settings → Exec approvals）。
安全性 + 詢問 + 允許清單儲存在 Mac 本地：

```
~/.openclaw/exec-approvals.json
```

範例：

```json
{
  "version": 1,
  "defaults": {
    "security": "deny",
    "ask": "on-miss"
  },
  "agents": {
    "main": {
      "security": "allowlist",
      "ask": "on-miss",
      "allowlist": [
        { "pattern": "/opt/homebrew/bin/rg" }
      ]
    }
  }
}
```

注意：
- `allowlist` 項目為已解析二進位路徑的 glob 模式。
- 在提示中選擇「Always Allow」會將該指令加入允許清單。
- `system.run` 環境變數覆寫會被過濾（丟棄 `PATH`, `DYLD_*`, `LD_*`, `NODE_OPTIONS`, `PYTHON*`, `PERL*`, `RUBYOPT`），然後與應用程式環境合併。

## Deep Links

應用程式註冊了 `openclaw://` URL scheme 用於本地操作。

### `openclaw://agent`

觸發 Gateway `agent` 請求。

```bash
open 'openclaw://agent?message=Hello%20from%20deep%20link'
```

查詢參數：
- `message` (必填)
- `sessionKey` (選填)
- `thinking` (選填)
- `deliver` / `to` / `channel` (選填)
- `timeoutSeconds` (選填)
- `key` (選填，無人值守模式金鑰)

安全性：
- 若無 `key`，應用程式會提示確認。
- 若有有效 `key`，則為無人值守執行（適用於個人自動化）。

## Onboarding 流程 (典型)

1) 安裝並啟動 **OpenClaw.app**。
2) 完成權限檢查清單 (TCC 提示)。
3) 確保 **Local** 模式已啟用且 Gateway 正在運行。
4) 若需要終端機存取，請安裝 CLI。

## 建置與開發工作流程 (原生)

- `cd apps/macos && swift build`
- `swift run OpenClaw` (或使用 Xcode)
- 打包應用程式：`scripts/package-mac-app.sh`

## 除錯 Gateway 連線 (macOS CLI)

使用除錯 CLI 執行與 macOS 應用程式相同的 Gateway WebSocket 握手與探索邏輯，無需啟動應用程式。

```bash
cd apps/macos
swift run openclaw-mac connect --json
swift run openclaw-mac discover --timeout 3000 --json
```

Connect 選項：
- `--url <ws://host:port>`: 覆寫設定
- `--mode <local|remote>`: 從設定解析（預設：設定或 local）
- `--probe`: 強制進行全新的健康探測 (fresh health probe)
- `--timeout <ms>`: 請求逾時（預設：`15000`）
- `--json`: 結構化輸出以便比對

Discovery 選項：
- `--include-local`: 包含會被過濾為「local」的 Gateway
- `--timeout <ms>`: 整體探索視窗（預設：`2000`）
- `--json`: 結構化輸出以便比對

提示：與 `openclaw gateway discover --json` 進行比較，看看 macOS 應用程式的探索管道 (NWBrowser + tailnet DNS‑SD fallback) 與 Node CLI 基於 `dns-sd` 的探索是否有異。

## 遠端連線管道 (SSH Tunnels)

當 macOS 應用程式在 **Remote** 模式下運行時，它會開啟 SSH 通道，讓本地 UI 元件能像在 localhost 一樣與遠端 Gateway 通訊。

### 控制通道 (Gateway WebSocket Port)
- **目的：** 健康檢查、狀態、Web Chat、設定與其他控制平面呼叫。
- **本地通訊埠：** Gateway 通訊埠（預設 `18789`），始終穩定。
- **遠端通訊埠：** 遠端主機上的相同 Gateway 通訊埠。
- **行為：** 無隨機本地通訊埠；應用程式會重複使用現有的健康通道或在需要時重啟。
- **SSH 形式：** `ssh -N -L <local>:127.0.0.1:<remote>` 搭配 BatchMode + ExitOnForwardFailure + keepalive 選項。
- **IP 回報：** SSH 通道使用 loopback，因此 Gateway 會看到節點 IP 為 `127.0.0.1`。若希望顯示真實客戶端 IP，請使用 **Direct (ws/wss)** 傳輸（參閱 [macOS remote access](/platforms/mac/remote)）。

設定步驟請參閱 [macOS remote access](/platforms/mac/remote)。
協定詳情請參閱 [Gateway protocol](/gateway/protocol)。

## 相關文件

- [Gateway runbook](/gateway)
- [Gateway (macOS)](/platforms/mac/bundled-gateway)
- [macOS permissions](/platforms/mac/permissions)
- [Canvas](/platforms/mac/canvas)
