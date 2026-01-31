---
title: "Getting started(開始使用)"
summary: "初學者指南：從零開始到發送第一則訊息（精靈導引、認證、頻道與配對）"
read_when:
  - 第一次從零開始設定時
  - 您想要從安裝到傳送第一則訊息的最快路徑時
---

# 開始使用

目標：以最快速度實現 **從零** 到 **第一則成功對話**（並套用合理的預設設定）。

**最速體驗**：直接開啟控制介面 (Control UI)，無需設定通訊頻道。執行 `openclaw dashboard` 即可在瀏覽器中對話，或在 Gateway 主機開啟 `http://127.0.0.1:18789/`。詳細文件見：[儀表板 (Dashboard)](/web/dashboard) 與 [控制介面 (Control UI)](/web/control-ui)。

**推薦路徑**：使用 **CLI 入門精靈** (`openclaw onboard`)。它會協助您設定：
- 模型與認證 (推薦使用 OAuth)
- Gateway 設定
- 通訊頻道 (WhatsApp/Telegram/Discord/Mattermost 等)
- 配對預設值 (安全的私訊存取)
- 工作區引導與技能
- 選用的背景服務 (Background service)

如果您想查看更深層的參考頁面，請跳转至：[引導精靈](/start/wizard)、[系統設定](/start/setup)、[配對機制](/start/pairing)、[安全性](/gateway/security)。

## 0) 前置需求

- Node `>=22`
- `pnpm` (選用；若您從原始碼建置則強力推薦)
- **推薦**：準備好 Brave Search API Key 以供網頁搜尋。最簡單的方法是：執行 `openclaw configure --section web`。詳見 [網頁工具](/tools/web)。

**macOS**：如果您計畫建置應用程式，請安裝 Xcode / CLT。若僅需 CLI 與 Gateway，則 Node 已足夠。
**Windows**：**務必使用 WSL2**（推薦 Ubuntu）。強烈建議在 Windows 上使用 WSL2；原生 Windows 環境尚未經過效能測試，問題較多且工具相容性較差。請先安裝 WSL2，接著在 WSL 內執行 Linux 的安裝步驟。詳見 [Windows (WSL2)](/platforms/windows)。

## 1) 安裝 CLI (推薦方式)

```bash
curl -fsSL https://openclaw.bot/install.sh | bash
```

Windows (PowerShell 執行方式)：

```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

或是使用 NPM/PNPM 全域安裝：

```bash
npm install -g openclaw@latest
```

## 2) 執行入門精靈 (並安裝背景服務)

```bash
openclaw onboard --install-daemon
```

您將在精靈中選擇：
- **本地 (Local) vs 遠端 (Remote)** Gateway。
- **認證 (Auth)**：建議為 Anthropic 設定 API Key（精靈可為您存儲以供服務使用）。
- **供應商 (Providers)**：WhatsApp QR 登入、Telegram/Discord Bot Token、Mattermost 令牌等。
- **守護程序 (Daemon)**：背景服務安裝 (launchd/systemd；WSL2 使用 systemd)。
- **Gateway Token**：精靈預設會生成一個（即使是在本地連線）並存儲在 `gateway.auth.token`。

## 3) 啟動 Gateway

如果您在入門精靈中安裝了背景服務，Gateway 應該已經在執行中：

```bash
openclaw gateway status
```

手動在前台執行：

```bash
openclaw gateway --port 18789 --verbose
```

儀表板路徑（本地）：`http://127.0.0.1:18789/`

⚠️ **Bun 警告 (WhatsApp + Telegram)**：Bun 在處理這些頻道時有已知問題。如果您使用 WhatsApp 或 Telegram，請務必使用 **Node** 執行 Gateway。

## 4) 配對並連接您的首個聊天介面

### WhatsApp (QR 登入)

```bash
openclaw channels login
```
開啟手機 WhatsApp → 設定 → 已連結裝置，掃描終端機顯示的 QR Code。

### Telegram / Discord / 其他頻道
入門精靈可以自動為您寫入 Token 與配置。如果您偏好手動設定，請參考各頻道文件。

## 5) 私訊安全性 (配對核准)

預設情況下：未知的私訊發送者會收到一個短代碼，機器人在您核准之前不會處理訊息。如果您發的第一封訊息沒收到回覆，請核准配對：

```bash
openclaw pairing list whatsapp
openclaw pairing approve whatsapp <代碼>
```

詳見 [配對機制](/start/pairing)。

## 6) 驗證端到端連線

在新的終端機視窗發送測試訊息：

```bash
openclaw message send --target +886912345678 --message "你好，來自 OpenClaw 的問候"
```

提示：`openclaw status --all` 是最適合用於除錯的唯讀報告。
健康檢查：`openclaw health`（或 `openclaw status --deep`）可獲取執行中 Gateway 的健康快照。
