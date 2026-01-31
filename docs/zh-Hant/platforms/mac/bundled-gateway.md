---
title: "bundled-gateway(Gateway on macOS)"
summary: "macOS 上的 Gateway 運行時 (外部 launchd 服務)"
read_when:
  - 打包 OpenClaw.app 時
  - Debug macOS Gateway launchd 服務時
  - 為 macOS 安裝 Gateway CLI 時
---

# macOS 上的 Gateway (外部 launchd)

OpenClaw.app 不再內建 Node/Bun 或 Gateway 運行時。macOS 應用程式預期有一個 **外部** 的 `openclaw` CLI 安裝，不會將 Gateway 作為子行程啟動，並管理一個使用者層級的 launchd 服務來保持 Gateway 運行（若已有本地 Gateway 運行則會連接至該 Gateway）。

## 安裝 CLI (Local 模式必需)

您需要在 Mac 上安裝 Node 22+，然後全域安裝 `openclaw`：

```bash
npm install -g openclaw@<version>
```

macOS 應用程式的 **Install CLI** 按鈕也會透過 npm/pnpm 執行相同的流程（不建議使用 bun 作為 Gateway 運行時）。

## Launchd (Gateway 作為 LaunchAgent)

標籤 (Label)：
- `bot.molt.gateway`（若使用 `--profile` 則為 `bot.molt.<profile>`；舊版 `com.openclaw.*` 可能仍存在）

Plist 位置 (使用者層級)：
- `~/Library/LaunchAgents/bot.molt.gateway.plist`
  （或 `~/Library/LaunchAgents/bot.molt.<profile>.plist`）

管理器：
- macOS 應用程式在 Local 模式下擁有 LaunchAgent 的安裝/更新權限。
- CLI 也可以安裝它：`openclaw gateway install`。

行為：
- 「OpenClaw Active」啟用/停用 LaunchAgent。
- 關閉應用程式**不會**停止 Gateway（launchd 會保持其存活）。
- 若 Gateway 已在配置的通訊埠運行，應用程式會連接至它，而非啟動新的 Gateway。

日誌：
- launchd stdout/err: `/tmp/openclaw/openclaw-gateway.log`

## 版本相容性

macOS 應用程式會檢查 Gateway 版本與自身版本是否相符。若不相容，請更新全域 CLI 以符合應用程式版本。

## 冒煙測試 (Smoke check)

```bash
openclaw --version

OPENCLAW_SKIP_CHANNELS=1 \
OPENCLAW_SKIP_CANVAS_HOST=1 \
openclaw gateway --port 18999 --bind loopback
```

接著：

```bash
openclaw gateway call health --url ws://127.0.0.1:18999 --timeout 3000
```
