---
title: "doctor(Doctor)"
summary: "Doctor 指令: 健康檢查、設定遷移與修復步驟"
read_when:
  - 新增或修改 Doctor Migrations 時
  - 引入破壞性設定變更時
---

# Doctor

`openclaw doctor` 是 OpenClaw 的修復 + 遷移工具。它修復過時的 Config/State、檢查健康狀況，並提供可執行的修復步驟。

## 快速開始

```bash
openclaw doctor
```

### Headless / 自動化

```bash
openclaw doctor --yes
```

不經提示接受預設值 (包含適用的 Restart/Service/Sandbox 修復步驟)。

```bash
openclaw doctor --repair
```

不經提示套用推薦的修復 (修復 + 在安全的情況下重啟)。

```bash
openclaw doctor --repair --force
```

套用積極修復 (覆蓋自訂 Supervisor Configs)。

```bash
openclaw doctor --non-interactive
```

不經提示運行並僅套用安全遷移 (Config 正規化 + 磁碟狀態移動)。跳過需要人員確認的 Restart/Service/Sandbox 動作。舊版狀態遷移在偵測到時會自動執行。

```bash
openclaw doctor --deep
```

掃描系統服務以尋找額外的 Gateway 安裝 (launchd/systemd/schtasks)。

若您想在寫入前檢閱變更，請先開啟設定檔：

```bash
cat ~/.openclaw/openclaw.json
```

## 功能摘要

- 選用的 Pre-flight 更新 (Git Installs，僅限互動模式)。
- UI 協定新鮮度檢查 (當 Protocol Schema 較新時重建 Control UI)。
- 健康檢查 + 重啟提示。
- Skills 狀態摘要 (合格/遺失/被阻擋)。
- 舊版數值的 Config 正規化。
- OpenCode Zen Provider 覆蓋警告 (`models.providers.opencode`)。
- 舊版磁碟狀態遷移 (Sessions/Agent Dir/WhatsApp Auth)。
- 狀態完整性與權限檢查 (Sessions, Transcripts, State Dir)。
- 本地運行時的 Config 檔案權限檢查 (chmod 600)。
- 模型 Auth 健康: 檢查 OAuth 過期，可重新整理即將過期的 Token，並報告 Auth-profile 冷卻/停用狀態。
- 額外 Workspace Dir 偵測 (`~/openclaw`)。
- 啟用 Sandboxing 時的 Sandbox Image 修復。
- 舊版服務遷移與額外 Gateway 偵測。
- Gateway Runtime 檢查 (服務已安裝但未運行；快取的 Launchd Label)。
- Channel 狀態警告 (從運行中的 Gateway 探測)。
- Supervisor Config 稽核 (launchd/systemd/schtasks) 與選用修復。
- Gateway Runtime 最佳實踐檢查 (Node vs Bun, Version-manager Paths)。
- Gateway Port 衝突診斷 (預設 `18789`)。
- 開放 DM Policy 的安全性警告。
- 本地模式下無 `gateway.auth.token` 的 Gateway Auth 警告 (提供 Token 產生)。
- Linux 上的 systemd linger 檢查。
- Source Install 檢查 (pnpm workspace mismatch, missing UI assets, missing tsx binary)。
- 寫入更新後的 Config + Wizard Metadata。

## 詳細行為與原理

### 0) 選用更新 (Git Installs)
若這是 Git Checkout 且 Doctor 正在互動式運行，它會提供在執行 Doctor 前更新 (Fetch/Rebase/Build) 的選項。

### 1) Config 正規化
若設定包含舊版數值形狀 (例如沒有 Channel-specific 覆蓋的 `messages.ackReaction`)，Doctor 會將其正規化為目前的 Schema。

### 2) 舊版 Config Key 遷移
當設定包含過時鍵值時，其他指令會拒絕運行並要求您執行 `openclaw doctor`。

Doctor 會：
- 解釋發現了哪些舊版鍵值。
- 顯示它套用的遷移。
- 使用更新後的 Schema 重寫 `~/.openclaw/openclaw.json`。

Gateway 亦會在啟動時偵測到舊版 Config 格式時自動執行 Doctor Migrations，因此過時設定無需手動介入即可修復。

目前的遷移:
- `routing.allowFrom` → `channels.whatsapp.allowFrom`
- `routing.groupChat.requireMention` → `channels.whatsapp/telegram/imessage.groups."*".requireMention`
- `routing.groupChat.historyLimit` → `messages.groupChat.historyLimit`
- `routing.groupChat.mentionPatterns` → `messages.groupChat.mentionPatterns`
- `routing.queue` → `messages.queue`
- `routing.bindings` → top-level `bindings`
- `routing.agents`/`routing.defaultAgentId` → `agents.list` + `agents.list[].default`
- `routing.agentToAgent` → `tools.agentToAgent`
- `routing.transcribeAudio` → `tools.media.audio.models`
- `bindings[].match.accountID` → `bindings[].match.accountId`
- `identity` → `agents.list[].identity`
- `agent.*` → `agents.defaults` + `tools.*` (tools/elevated/exec/sandbox/subagents)
- `agent.model`/`allowedModels`/`modelAliases`/`modelFallbacks`/`imageModelFallbacks`
  → `agents.defaults.models` + `agents.defaults.model.primary/fallbacks` + `agents.defaults.imageModel.primary/fallbacks`

### 2b) OpenCode Zen Provider 覆蓋
若您手動新增了 `models.providers.opencode` (或 `opencode-zen`)，它會覆蓋來自 `@mariozechner/pi-ai` 的內建 OpenCode Zen 目錄。這可能會強迫每個模型使用單一 API 或將成本歸零。Doctor 會發出警告以便您移除覆蓋並還原每個模型的 API 路由 + 成本。

### 3) 舊版狀態遷移 (磁碟佈局)
Doctor 可將較舊的磁碟佈局遷移至目前的結構：
- Sessions Store + Transcripts:
  - 從 `~/.openclaw/sessions/` 到 `~/.openclaw/agents/<agentId>/sessions/`
- Agent Dir:
  - 從 `~/.openclaw/agent/` 到 `~/.openclaw/agents/<agentId>/agent/`
- WhatsApp Auth State (Baileys):
  - 從舊版 `~/.openclaw/credentials/*.json` (除 `oauth.json` 外)
  - 到 `~/.openclaw/credentials/whatsapp/<accountId>/...` (預設 Account ID: `default`)

這些遷移是盡力而為且冪等的；當 Doctor 留下任何舊版資料夾作為備份時會發出警告。Gateway/CLI 亦會在啟動時自動遷移舊版 Sessions + Agent Dir，因此 History/Auth/Models 會落在 Per-agent 路徑中而無需手動執行 Doctor。WhatsApp Auth 刻意僅透過 `openclaw doctor` 遷移。

### 4) 狀態完整性檢查 (Session Persistence, Routing, 與 Safety)
狀態目錄是運作的中樞。若它消失，您會遺失 Sessions, Credentials, Logs, 與 Config (除非別處有備份)。

Doctor 檢查：
- **State dir missing**: 警告災難性狀態遺失，提示重新建立目錄，並提醒您它無法復原遺失的資料。
- **State dir permissions**: 驗證可寫性；提供修復權限的選項 (並在偵測到 Owner/Group 不符時發出 `chown` 提示)。
- **Session dirs missing**: 需要 `sessions/` 與 Session Store Directory 來持久化歷史記錄並避免 `ENOENT` 崩潰。
- **Transcript mismatch**: 當最近的 Session 項目遺失 Transcript 檔案時發出警告。
- **Main session “1-line JSONL”**: 標記 Main Transcript 只有一行 (歷史記錄未累積) 的情況。
- **Multiple state dirs**: 當 Home 目錄中存在多個 `~/.openclaw` 資料夾或 `OPENCLAW_STATE_DIR` 指向別處時發出警告 (歷史記錄可能在安裝間分裂)。
- **Remote mode reminder**: 若 `gateway.mode=remote`，Doctor 提醒您在 Remote Host 上執行它 (狀態位於該處)。
- **Config file permissions**: 若 `~/.openclaw/openclaw.json` 為 Group/World 可讀，發出警告並提供緊縮至 `600` 的選項。

### 5) 模型 Auth 健康 (OAuth 過期)
Doctor 檢查 Auth Store 中的 OAuth Profiles，在 Token 即將過期/已過期時警告，並可在安全時重新整理它們。若 Anthropic Claude Code Profile 過時，它建議執行 `claude setup-token` (或貼上 Setup-token)。重新整理提示僅在互動式運行 (TTY) 時出現；`--non-interactive` 跳過重新整理嘗試。

Doctor 亦報告因以下原因暫時無法使用的 Auth Profiles：
- 短暫冷卻 (Rate limits/Timeouts/Auth failures)
- 較長停用 (Billing/Credit failures)

### 6) Hooks 模型驗證
若設定了 `hooks.gmail.model`，Doctor 會針對目錄與 Allowlist 驗證 Model Reference，並在無法解析或被拒絕時發出警告。

### 7) Sandbox Image 修復
當啟用 Sandboxing 時，Doctor 檢查 Docker Images，若目前 Image 遺失，提供建置或切換至 Legacy Names 的選項。

### 8) Gateway 服務遷移與清理提示
Doctor 偵測舊版 Gateway 服務 (launchd/systemd/schtasks) 並提供移除它們並使用目前 Gateway Port 安裝 OpenClaw 服務的選項。它亦可掃描額外的 Gateway-like 服務並印出清理提示。以 Profile 命名的 OpenClaw Gateway 服務被視為 First-class 且不會被標記為“額外”。

### 9) 安全性警告
當 Provider 對 DMs 開放且無 Allowlist，或 Policy 設定方式危險時，Doctor 發出警告。

### 10) systemd linger (Linux)
若作為 systemd user service 運行，Doctor 確保已啟用 Lingering，以便 Gateway 在登出後保持存活。

### 11) Skills 狀態
Doctor 印出目前 Workspace 的合格/遺失/被阻擋 Skills 的快速摘要。

### 12) Gateway Auth 檢查 (Local Token)
當本地 Gateway 遺失 `gateway.auth` 時，Doctor 發出警告並提供產生 Token 的選項。在自動化中使用 `openclaw doctor --generate-gateway-token` 強制建立 Token。

### 13) Gateway 健康檢查 + 重啟
Doctor 運行健康檢查，並在 Gateway 看起來不健康時提供重啟選項。

### 14) Channel 狀態警告
若 Gateway 健康，Doctor 運行 Channel Status Probe 並報告警告與建議修復。

### 15) Supervisor Config 稽核 + 修復
Doctor 檢查已安裝的 Supervisor Config (launchd/systemd/schtasks) 是否有遺失或過時的預設值 (例如 systemd network-online 相依性與 Restart Delay)。當發現不符時，它建議更新並可將 Service File/Task 重寫為目前預設值。

備註:
- `openclaw doctor` 在重寫 Supervisor Config 前會提示。
- `openclaw doctor --yes` 接受預設修復提示。
- `openclaw doctor --repair` 不經提示套用推薦修復。
- `openclaw doctor --repair --force` 覆蓋自訂 Supervisor Configs。
- 您總是可以透過 `openclaw gateway install --force` 強制完全重寫。

### 16) Gateway Runtime + Port 診斷
Doctor 檢查 Service Runtime (PID, last exit status) 並在服務已安裝但未實際運行時發出警告。它亦檢查 Gateway Port (預設 `18789`) 上的 Port 衝突並報告可能原因 (Gateway 已在運行, SSH Tunnel)。

### 17) Gateway Runtime 最佳實踐
當 Gateway 服務運行在 Bun 或版本管理的 Node 路徑 (`nvm`, `fnm`, `volta`, `asdf`, etc.) 上時，Doctor 發出警告。WhatsApp + Telegram Channels 需要 Node，且版本管理路徑在升級後可能會中斷，因為服務不載入您的 Shell Init。當系統 Node 安裝 (Homebrew/apt/choco) 可用時，Doctor 提供遷移建議。

### 18) Config 寫入 + Wizard Metadata
Doctor 持久化任何 Config 變更並蓋上 Wizard Metadata 以記錄 Doctor 執行。

### 19) Workspace Tips (備份 + 記憶系統)
若遺失 Workspace 記憶系統，Doctor 建議之；若 Workspace 尚未受 Git 控制，印出備份提示。

參閱 [/concepts/agent-workspace](/concepts/agent-workspace) 了解 Workspace 結構與 Git 備份 (推薦 Private GitHub 或 GitLab) 的完整指南。
