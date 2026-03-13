---
summary: "OpenClaw 的進階設定與開發工作流程"
read_when:
  - 設定新機器時
  - 希望取得最新功能而不破壞個人設定時
title: "Setup（設定）"
---

# 設定

<Note>
如果您是首次設定，請從[入門指南](/zh-Hant/start/getting-started)開始。
如需精靈詳情，請參閱[入門精靈](/zh-Hant/start/wizard)。
</Note>

最後更新：2026-01-01

## TL;DR

- **個人化設定放在 repo 外：**`~/.openclaw/workspace`（工作區）+ `~/.openclaw/openclaw.json`（設定）。
- **穩定工作流程：**安裝 macOS 應用程式；讓它執行捆綁的 Gateway。
- **最新版工作流程：**透過 `pnpm gateway:watch` 自行執行 Gateway，然後讓 macOS 應用程式以本地模式連接。

## 前置需求（從原始碼）

- Node `>=22`
- `pnpm`
- Docker（選用；僅用於容器化設定/e2e — 請參閱 [Docker](/zh-Hant/install/docker)）

## 個人化策略（讓更新不造成損害）

如果您想要「100% 為我量身訂做」*且*方便更新，請將您的自訂設定放在：

- **設定：**`~/.openclaw/openclaw.json`（JSON/JSON5 格式）
- **工作區：**`~/.openclaw/workspace`（技能、提示、記憶；將其設為私有 git repo）

一次性引導：

```bash
openclaw setup
```

在此 repo 內部，使用本地 CLI 入口點：

```bash
openclaw setup
```

如果您尚未有全域安裝，請透過 `pnpm openclaw setup` 執行。

## 從此 repo 執行 Gateway

`pnpm build` 後，您可以直接執行打包好的 CLI：

```bash
node openclaw.mjs gateway --port 18789 --verbose
```

## 穩定工作流程（macOS 應用程式優先）

1. 安裝並啟動 **OpenClaw.app**（選單列）。
2. 完成入門/權限清單（TCC 提示）。
3. 確保 Gateway 是**本地**模式且正在執行（由應用程式管理）。
4. 連結介面（例如：WhatsApp）：

```bash
openclaw channels login
```

5. 健全性檢查：

```bash
openclaw health
```

如果您的版本沒有入門功能：

- 執行 `openclaw setup`，然後 `openclaw channels login`，再手動啟動 Gateway（`openclaw gateway`）。

## 最新版工作流程（在終端機中執行 Gateway）

目標：開發 TypeScript Gateway，獲得熱重載，讓 macOS 應用程式 UI 保持連接。

### 0) （選用）從原始碼執行 macOS 應用程式

如果您也想讓 macOS 應用程式使用最新版：

```bash
./scripts/restart-mac.sh
```

### 1) 啟動開發版 Gateway

```bash
pnpm install
pnpm gateway:watch
```

`gateway:watch` 以監視模式執行 gateway，並在 TypeScript 變更時重新載入。

### 2) 將 macOS 應用程式指向您執行中的 Gateway

在 **OpenClaw.app** 中：

- 連線模式：**本地**
  應用程式將連接到設定連接埠上正在執行的 gateway。

### 3) 驗證

- 應用程式內的 Gateway 狀態應顯示 **「Using existing gateway …」**
- 或透過 CLI：

```bash
openclaw health
```

### 常見陷阱

- **錯誤的連接埠：**Gateway WS 預設為 `ws://127.0.0.1:18789`；讓應用程式和 CLI 使用相同的連接埠。
- **狀態的儲存位置：**
  - 憑證：`~/.openclaw/credentials/`
  - 會話：`~/.openclaw/agents/<agentId>/sessions/`
  - 日誌：`/tmp/openclaw/`

## 憑證儲存位置對照

偵錯認證或決定要備份什麼時使用：

- **WhatsApp**：`~/.openclaw/credentials/whatsapp/<accountId>/creds.json`
- **Telegram 機器人 Token**：設定/環境變數或 `channels.telegram.tokenFile`
- **Discord 機器人 Token**：設定/環境變數或 SecretRef（env/file/exec 提供者）
- **Slack Tokens**：設定/環境變數（`channels.slack.*`）
- **配對允許清單**：
  - `~/.openclaw/credentials/<channel>-allowFrom.json`（預設帳號）
  - `~/.openclaw/credentials/<channel>-<accountId>-allowFrom.json`（非預設帳號）
- **模型認證設定檔**：`~/.openclaw/agents/<agentId>/agent/auth-profiles.json`
- **檔案支援的 secrets 承載（選用）**：`~/.openclaw/secrets.json`
- **舊版 OAuth 匯入**：`~/.openclaw/credentials/oauth.json`
  更多詳情：[安全性](/zh-Hant/gateway/security#credential-storage-map)。

## 更新（不破壞您的設定）

- 將 `~/.openclaw/workspace` 和 `~/.openclaw/` 視為「您的東西」；不要將個人提示/設定放入 `openclaw` repo。
- 更新原始碼：`git pull` + `pnpm install`（當 lockfile 變更時）+ 繼續使用 `pnpm gateway:watch`。

## Linux（systemd 使用者服務）

Linux 安裝使用 systemd **使用者**服務。預設情況下，systemd 在登出/閒置時停止使用者服務，這會終止 Gateway。入門嘗試為您啟用 lingering（可能需要 sudo 提示）。如果它仍然關閉，請執行：

```bash
sudo loginctl enable-linger $USER
```

對於常開或多使用者伺服器，請考慮使用**系統**服務而非使用者服務（不需要 lingering）。請參閱 [Gateway 操作手冊](/zh-Hant/gateway)中的 systemd 說明。

## 相關文件

- [Gateway 操作手冊](/zh-Hant/gateway)（旗標、監督、連接埠）
- [Gateway 設定](/zh-Hant/gateway/configuration)（設定架構 + 範例）
- [Discord](/zh-Hant/channels/discord) 和 [Telegram](/zh-Hant/channels/telegram)（回覆標籤 + replyToMode 設定）
- [OpenClaw 助理設定](/zh-Hant/start/openclaw)
- [macOS 應用程式](/zh-Hant/platforms/macos)（gateway 生命週期）
