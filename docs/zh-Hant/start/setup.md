---
title: "Setup(系統設定)"
summary: "設定指南：在保持 OpenClaw 更新的同時，維護您專屬的個人化設定"
read_when:
  - 在新機器上進行設定時
  - 您想要同步最新版本但不希望破壞個人化設定時
---

# 系統設定 (Setup)

最後更新日期：2026-01-01

## 核心重點 (TL;DR)
- **自訂內容應放在倉庫之外**：工作區位於 `~/.openclaw/workspace`，配置文件位於 `~/.openclaw/openclaw.json`。
- **穩定版工作流**：安裝 macOS App，並執行其內建的 Gateway。
- **開發者版 (Bleeding edge) 工作流**：透過 `pnpm gateway:watch` 自行執行 Gateway，然後讓 macOS App 以「本地模式 (Local mode)」連接。

## 前置需求（從原始碼建置）
- Node >= 22
- `pnpm`
- Docker（選用，僅用於容器化設定或端到端測試 —— 詳見 [Docker](/install/docker)）

## 自訂策略（確保更新不受影響）

如果您希望擁有「100% 個人化」且「易於更新」的體驗，請將您的自訂內容保留在：

- **配置**：`~/.openclaw/openclaw.json` (JSON 或 JSON5 格式)。
- **工作區**：`~/.openclaw/workspace`（存放技能、提示詞、記憶；建議將其設為私有 Git 倉庫）。

初次建立環境：

```bash
openclaw setup
```

## 穩定版工作流 (以 macOS App 為主)

1) 安裝並啟動 **OpenClaw.app** (位於選單列)。
2) 完成入門/權限檢查清單 (TCC 權限提示)。
3) 確保 Gateway 設為 **本地 (Local)** 且正在執行（由 App 管理）。
4) 連結通訊頻道（例如 WhatsApp）：

```bash
openclaw channels login
```

5) 基本檢查：

```bash
openclaw health
```

## 開發者版工作流 (在終端機執行 Gateway)

目標：開發 TypeScript Gateway 代碼、獲得熱重載 (Hot reload) 功能，同時保持 macOS App 的介面連線。

### 1) 啟動開發版 Gateway

```bash
pnpm install
pnpm gateway:watch
```

`gateway:watch` 會以檢視模式執行 Gateway，並在 TypeScript 代碼變動時自動重載。

### 2) 將 macOS App 指向執行中的 Gateway

在 **OpenClaw.app** 中：
- 連線模式 (Connection Mode)：**本地 (Local)**
App 會自動附加到已在配置連接埠執行中的 Gateway 上。

### 3) 驗證
- App 內的 Gateway 狀態應顯示為：**「Using existing gateway ...（正在使用現有的 Gateway...）」**
- 也可以透過 CLI 驗證：`openclaw health`

## 常見陷阱
- **連接埠錯誤**：Gateway WebSocket 預設為 `ws://127.0.0.1:18789`；請確保 App 與 CLI 使用相同的連接埠。
- **狀態存儲位置**：
  - 憑證：`~/.openclaw/credentials/`
  - 會話：`~/.openclaw/agents/<agentId>/sessions/`
  - 日誌：`/tmp/openclaw/`

## 憑證存儲地圖 (Credential storage map)

在進行認證偵錯或決定備份內容時，可參考以下路徑：
- **WhatsApp**: `~/.openclaw/credentials/whatsapp/<accountId>/creds.json`
- **配對允許清單**: `~/.openclaw/credentials/<channel>-allowFrom.json`
- **模型認證設定檔**: `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`

## Linux (systemd 使用者服務)

Linux 安裝會使用 systemd 的「使用者 (User)」服務。預設情況下，登出或主機閒置時 systemd 會停止使用者服務，這會導致 Gateway 被終止。入門精靈會嘗試為您啟用 **Lingering**（可能會要求 sudo 權限）。如果仍未開啟，請執行：

```bash
sudo loginctl enable-linger $USER
```

詳情請參閱 [Gateway 操作手冊](/gateway)。
