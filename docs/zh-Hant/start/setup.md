---
summary: "設定指南：保持 OpenClaw 設定客製化同時保持最新"
read_when:
  - 在新機器上設定時
  - 您想要「最新 + 最棒」但不破壞您的個人設定時
title: "設定"
---

# 設定

最後更新：2026-01-01

## 快速總結

- **客製化在儲存庫外：** `~/.openclaw/workspace`（工作區）+ `~/.openclaw/openclaw.json`（配置）。
- **穩定工作流：**安裝 macOS 應用程式；讓它執行內建 Gateway。
- **前沿工作流：**自己透過 `pnpm gateway:watch` 執行 Gateway，然後讓 macOS 應用程式在本地模式附加。

## 先決條件（從原始碼）

- Node `>=22`
- `pnpm`
- Docker（選用；僅用於容器化設定/e2e — 見 [Docker](/install/docker)）

## 客製化策略（所以更新不會傷害）

若您想要「100% 為我客製化」_且_簡單更新，將您的客製化保留在：

- **配置：** `~/.openclaw/openclaw.json`（JSON/JSON5-ish）
- **工作區：** `~/.openclaw/workspace`（技能、提示、記憶；使其成為私有 git 儲存庫）

一次引導：

```bash
openclaw setup
```

從此儲存庫內，使用本地 CLI 入口：

```bash
openclaw setup
```

若您還沒有全域安裝，透過 `pnpm openclaw setup` 執行它。

## 穩定工作流（macOS 應用程式優先）

1. 安裝 + 啟動 **OpenClaw.app**（選單列）。
2. 完成入門/權限檢核清單（TCC 提示）。
3. 確保 Gateway 是**本地**且執行中（應用程式管理它）。
4. 連結介面（示例：WhatsApp）：

```bash
openclaw channels login
```

5. 健智檢查：

```bash
openclaw health
```

若入門在您的構建中不可用：

- 執行 `openclaw setup`，然後 `openclaw channels login`，然後手動啟動 Gateway（`openclaw gateway`）。

## 前沿工作流（終端中的 Gateway）

目標：在 TypeScript Gateway 上工作、取得熱重載、保持 macOS 應用程式 UI 附加。

### 0)（選用）也從原始碼執行 macOS 應用程式

若您也想要前沿的 macOS 應用程式：

```bash
./scripts/restart-mac.sh
```

### 1) 啟動開發 Gateway

```bash
pnpm install
pnpm gateway:watch
```

`gateway:watch` 在監視模式中執行 Gateway，在 TypeScript 變更時重載。

### 2) 將 macOS 應用程式指向您執行中的 Gateway

在 **OpenClaw.app** 中：

- 連線模式：**本地**
  應用程式將附加到配置埠上執行的 Gateway。

### 3) 驗證

- 應用程式 Gateway 狀態應讀取**「使用現有 Gateway ...」**
- 或透過 CLI：

```bash
openclaw health
```

### 常見陷阱

- **錯誤連接埠：** Gateway WS 預設為 `ws://127.0.0.1:18789`；保持應用程式 + CLI 在同一連接埠。
- **狀態位置：**
  - 認證：`~/.openclaw/credentials/`
  - 會話：`~/.openclaw/agents/<agentId>/sessions/`
  - 日誌：`/tmp/openclaw/`

## 認證儲存對應

調試認證或決定要備份什麼時使用：

- **WhatsApp**：`~/.openclaw/credentials/whatsapp/<accountId>/creds.json`
- **Telegram bot 令牌**：配置/環境或 `channels.telegram.tokenFile`
- **Discord bot 令牌**：配置/環境（令牌檔案尚未支援）
- **Slack 令牌**：配置/環境（`channels.slack.*`）
- **配對允許清單**：`~/.openclaw/credentials/<channel>-allowFrom.json`
- **模型認證設定檔**：`~/.openclaw/agents/<agentId>/agent/auth-profiles.json`
- **舊版 OAuth 匯入**：`~/.openclaw/credentials/oauth.json`
  更多詳情：[安全性](/gateway/security#credential-storage-map)。

## 更新（不破壞您的設定）

- 保持 `~/.openclaw/workspace` 和 `~/.openclaw/` 為「您的東西」；不要將個人提示/配置放入 `openclaw` 儲存庫。
- 更新原始碼：`git pull` + `pnpm install`（當鎖定檔案變更時）+ 繼續使用 `pnpm gateway:watch`。

## Linux（systemd 使用者服務）

Linux 安裝使用 systemd **使用者**服務。根據預設，systemd 在登出/閒置時停止使用者
服務，這會終止 Gateway。入門嘗試為您啟用徘徊（可能提示 sudo）。若仍未開啟，執行：

```bash
sudo loginctl enable-linger $USER
```

對於全天候或多使用者伺服器，考慮**系統**服務而非
使用者服務（無需徘徊）。詳見 [Gateway 操作手冊](/gateway)的 systemd 備註。

## 相關文件

- [Gateway 操作手冊](/gateway)（旗標、監督、連接埠）
- [Gateway 配置](/gateway/configuration)（配置綱要 + 範例）
- [Discord](/channels/discord) 和 [Telegram](/channels/telegram)（回覆標籤 + replyToMode 設定）
- [OpenClaw 助理設定](/start/openclaw)
- [macOS 應用程式](/platforms/macos)（Gateway 生命週期）
