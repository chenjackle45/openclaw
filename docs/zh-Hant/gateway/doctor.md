---
summary: "Doctor 指令：健康檢查、設定遷移與修復步驟"
read_when:
  - 新增或修改 Doctor migrations 時
  - 引入破壞性設定變更時
title: "Doctor（診斷工具）"
---

# Doctor

`openclaw doctor` 是 OpenClaw 的修復 + 遷移工具。它可以修復過時的設定/狀態、執行健康檢查，並提供可操作的修復步驟。

## 快速開始

```bash
openclaw doctor
```

### 無頭模式 / 自動化

```bash
openclaw doctor --yes
```

接受預設值而不提示（包括適用時的重啟/服務/沙箱修復步驟）。

```bash
openclaw doctor --repair
```

不提示直接套用建議的修復（修復 + 安全時重啟）。

```bash
openclaw doctor --repair --force
```

也套用激進修復（覆蓋自訂的 supervisor 設定）。

```bash
openclaw doctor --non-interactive
```

不提示執行並只套用安全的遷移（設定正規化 + 磁碟狀態搬移）。跳過需要人工確認的重啟/服務/沙箱操作。
偵測到時會自動執行舊版狀態遷移。

```bash
openclaw doctor --deep
```

掃描系統服務中的額外 gateway 安裝（launchd/systemd/schtasks）。

若您想在寫入前先審查變更，請先開啟設定檔：

```bash
cat ~/.openclaw/openclaw.json
```

## 功能摘要

- 選用的 git 安裝預先更新（僅互動模式）。
- UI 協議新鮮度檢查（當協議 schema 更新時重建 Control UI）。
- 健康檢查 + 重啟提示。
- Skills 狀態摘要（符合資格/遺失/被封鎖）。
- 舊版值的設定正規化。
- OpenCode Zen provider 覆蓋警告（`models.providers.opencode`）。
- 舊版磁碟狀態遷移（sessions/agent 目錄/WhatsApp 認證）。
- 狀態完整性與權限檢查（sessions、transcripts、state 目錄）。
- 設定檔案權限檢查（chmod 600），本地執行時適用。
- 模型認證健康：檢查 OAuth 過期，可刷新即將過期的 Token，並回報 auth-profile 冷卻/停用狀態。
- 額外工作空間目錄偵測（`~/openclaw`）。
- 啟用沙箱時的沙箱映像修復。
- 舊版服務遷移與額外 gateway 偵測。
- Gateway 執行環境檢查（服務已安裝但未執行；快取的 launchd label）。
- 頻道狀態警告（從執行中的 gateway 探測）。
- Supervisor 設定稽核（launchd/systemd/schtasks），含選用修復。
- Gateway 執行環境最佳實踐檢查（Node 對比 Bun、版本管理器路徑）。
- Gateway 埠衝突診斷（預設 `18789`）。
- 開放 DM 政策的安全警告。
- 本地 Token 模式的 Gateway 認證檢查（若無 Token 來源則提供生成；不覆蓋 Token SecretRef 設定）。
- Linux 上的 systemd linger 檢查。
- 原始碼安裝檢查（pnpm 工作空間不符、缺少 UI 資源、缺少 tsx 二進位）。
- 寫入更新的設定 + 精靈中繼資料。

## 詳細行為與原理

### 0) 選用更新（git 安裝）

若這是 git checkout 且 doctor 以互動模式執行，它會在執行 doctor 前提供更新（fetch/rebase/build）。

### 1) 設定正規化

若設定包含舊版值形狀（例如沒有頻道特定覆蓋的 `messages.ackReaction`），doctor 會將其正規化為目前的 schema。

### 2) 舊版設定鍵遷移

當設定包含已棄用的鍵時，其他指令會拒絕執行並要求您執行 `openclaw doctor`。

Doctor 會：

- 說明找到哪些舊版鍵。
- 顯示套用的遷移。
- 以更新後的 schema 重寫 `~/.openclaw/openclaw.json`。

Gateway 在啟動時偵測到舊版設定格式時，也會自動執行 doctor 遷移，讓過時的設定無需手動介入即可修復。

目前的遷移：

- `routing.allowFrom` → `channels.whatsapp.allowFrom`
- `routing.groupChat.requireMention` → `channels.whatsapp/telegram/imessage.groups."*".requireMention`
- `routing.groupChat.historyLimit` → `messages.groupChat.historyLimit`
- `routing.groupChat.mentionPatterns` → `messages.groupChat.mentionPatterns`
- `routing.queue` → `messages.queue`
- `routing.bindings` → 頂層 `bindings`
- `routing.agents`/`routing.defaultAgentId` → `agents.list` + `agents.list[].default`
- `routing.agentToAgent` → `tools.agentToAgent`
- `routing.transcribeAudio` → `tools.media.audio.models`
- `bindings[].match.accountID` → `bindings[].match.accountId`
- 對於有具名 `accounts` 但缺少 `accounts.default` 的頻道，當存在時將帳號範圍的頂層單帳號頻道值移入 `channels.<channel>.accounts.default`
- `identity` → `agents.list[].identity`
- `agent.*` → `agents.defaults` + `tools.*`（tools/elevated/exec/sandbox/subagents）
- `agent.model`/`allowedModels`/`modelAliases`/`modelFallbacks`/`imageModelFallbacks`
  → `agents.defaults.models` + `agents.defaults.model.primary/fallbacks` + `agents.defaults.imageModel.primary/fallbacks`
- `browser.ssrfPolicy.allowPrivateNetwork` → `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork`

Doctor 警告也包含多帳號頻道的帳號預設指引：

- 若兩個或更多的 `channels.<channel>.accounts` 項目設定了但沒有 `channels.<channel>.defaultAccount` 或 `accounts.default`，doctor 會警告 fallback 路由可能選到非預期的帳號。
- 若 `channels.<channel>.defaultAccount` 設定為未知的帳號 ID，doctor 會警告並列出已設定的帳號 ID。

### 2b) OpenCode Zen provider 覆蓋

若您手動新增了 `models.providers.opencode`（或 `opencode-zen`），它會覆蓋 `@mariozechner/pi-ai` 內建的 OpenCode Zen 目錄。這可能會強制所有模型使用單一 API 或清零成本。Doctor 會警告，以便您可以移除覆蓋並恢復每模型的 API 路由 + 成本。

### 3) 舊版狀態遷移（磁碟佈局）

Doctor 可以將較舊的磁碟佈局遷移到目前的結構：

- Sessions store + transcripts：
  - 從 `~/.openclaw/sessions/` 到 `~/.openclaw/agents/<agentId>/sessions/`
- Agent 目錄：
  - 從 `~/.openclaw/agent/` 到 `~/.openclaw/agents/<agentId>/agent/`
- WhatsApp 認證狀態（Baileys）：
  - 從舊版 `~/.openclaw/credentials/*.json`（`oauth.json` 除外）
  - 到 `~/.openclaw/credentials/whatsapp/<accountId>/...`（預設帳號 id：`default`）

這些遷移是盡力而為且冪等的；doctor 會在留下任何舊版備份資料夾時發出警告。Gateway/CLI 在啟動時也會自動遷移舊版 sessions + agent 目錄，讓歷史記錄/認證/模型落在每 agent 路徑中，無需手動執行 doctor。WhatsApp 認證刻意只透過 `openclaw doctor` 遷移。

### 4) 狀態完整性檢查（session 持久性、路由與安全性）

狀態目錄是操作的核心。若它消失，您將遺失 sessions、憑證、日誌和設定（除非您有其他備份）。

Doctor 檢查：

- **狀態目錄遺失**：警告災難性狀態損失，提示重新建立目錄，並提醒您它無法恢復遺失的資料。
- **狀態目錄權限**：驗證可寫入性；提供修復權限（並在偵測到擁有者/群組不符時發出 `chown` 提示）。
- **macOS 雲端同步狀態目錄**：當狀態解析到 iCloud Drive（`~/Library/Mobile Documents/com~apple~CloudDocs/...`）或 `~/Library/CloudStorage/...` 下時發出警告，因為同步備份路徑可能導致較慢的 I/O 和鎖定/同步競爭。
- **Linux SD 或 eMMC 狀態目錄**：當狀態解析到 `mmcblk*` 掛載來源時發出警告，因為 SD 或 eMMC 支援的隨機 I/O 在 session 和憑證寫入下可能較慢且磨損更快。
- **Sessions 目錄遺失**：`sessions/` 和 session store 目錄是持久化歷史記錄和避免 `ENOENT` 崩潰的必要條件。
- **Transcript 不符**：當近期的 session 項目有遺失的 transcript 檔案時發出警告。
- **主 session「1 行 JSONL」**：當主 transcript 只有一行時標記（歷史記錄未累積）。
- **多個狀態目錄**：當多個 `~/.openclaw` 資料夾跨 home 目錄存在，或 `OPENCLAW_STATE_DIR` 指向別處時發出警告（歷史記錄可能在安裝之間分散）。
- **遠端模式提醒**：若 `gateway.mode=remote`，doctor 提醒您在遠端主機上執行（狀態存在於那裡）。
- **設定檔案權限**：若 `~/.openclaw/openclaw.json` 對群組/所有人可讀，發出警告並提供收緊到 `600` 的選項。

### 5) 模型認證健康（OAuth 過期）

Doctor 檢查認證 store 中的 OAuth profiles，在 Token 即將過期/已過期時發出警告，並可在安全時刷新。若 Anthropic Claude Code profile 過期，它建議執行 `claude setup-token`（或貼上 setup-token）。刷新提示只在互動執行時出現（TTY）；`--non-interactive` 會跳過刷新嘗試。

Doctor 也回報因以下原因暫時無法使用的 auth profiles：

- 短暫冷卻（速率限制/逾時/認證失敗）
- 較長的停用（帳單/信用失敗）

### 6) Hooks 模型驗證

若設定了 `hooks.gmail.model`，doctor 會根據目錄和 allowlist 驗證模型引用，並在無法解析或不允許時發出警告。

### 7) 沙箱映像修復

啟用沙箱時，doctor 檢查 Docker 映像並提供建立或切換到舊版名稱的選項（若目前映像遺失）。

### 8) Gateway 服務遷移與清理提示

Doctor 偵測舊版 gateway 服務（launchd/systemd/schtasks）並提供移除它們並使用目前 gateway 埠安裝 OpenClaw 服務的選項。它也可以掃描額外的類 gateway 服務並列印清理提示。以 profile 命名的 OpenClaw gateway 服務被視為一等公民，不會被標記為「額外」。

### 9) 安全警告

當供應商在沒有 allowlist 的情況下開放 DM，或政策以危險方式設定時，doctor 會發出警告。

### 10) systemd linger（Linux）

若作為 systemd 使用者服務執行，doctor 確保已啟用 lingering，讓 gateway 在登出後保持運行。

### 11) Skills 狀態

Doctor 列印目前工作空間中符合資格/遺失/被封鎖的 skills 快速摘要。

### 12) Gateway 認證檢查（本地 token）

Doctor 檢查本地 gateway token 認證就緒狀態。

- 若 token 模式需要 token 且無 token 來源，doctor 提供生成選項。
- 若 `gateway.auth.token` 由 SecretRef 管理但無法使用，doctor 發出警告且不以明文覆蓋。
- `openclaw doctor --generate-gateway-token` 僅在未設定 token SecretRef 時強制生成。

### 12b) 唯讀 SecretRef 感知修復

部分修復流程需要在不弱化執行環境 fail-fast 行為的情況下檢查設定的憑證。

- `openclaw doctor --fix` 現在對目標設定修復使用與 status 系列指令相同的唯讀 SecretRef 摘要模型。
- 範例：Telegram `allowFrom` / `groupAllowFrom` `@username` 修復會在可用時嘗試使用設定的 bot 憑證。
- 若 Telegram bot token 透過 SecretRef 設定但在目前的指令路徑中無法使用，doctor 回報憑證已設定但無法使用，並跳過自動解析而非崩潰或錯誤回報 token 遺失。

### 13) Gateway 健康檢查 + 重啟

Doctor 執行健康檢查，並在 gateway 看起來不健康時提供重啟選項。

### 14) 頻道狀態警告

若 gateway 健康，doctor 執行頻道狀態探測並回報警告與建議修復。

### 15) Supervisor 設定稽核 + 修復

Doctor 檢查已安裝的 supervisor 設定（launchd/systemd/schtasks）是否有遺失或過時的預設值（例如 systemd network-online 相依性和重啟延遲）。發現不符時，它建議更新並可將服務檔案/任務重寫為目前的預設值。

注意事項：

- `openclaw doctor` 在重寫 supervisor 設定前會提示。
- `openclaw doctor --yes` 接受預設修復提示。
- `openclaw doctor --repair` 不提示直接套用建議修復。
- `openclaw doctor --repair --force` 覆蓋自訂的 supervisor 設定。
- 若 token 認證需要 token 且 `gateway.auth.token` 由 SecretRef 管理，doctor 服務安裝/修復會驗證 SecretRef 但不將解析後的明文 token 值持久化到 supervisor 服務環境中繼資料。
- 若 token 認證需要 token 且設定的 token SecretRef 未解析，doctor 封鎖安裝/修復路徑並提供可操作的指引。
- 若 `gateway.auth.token` 和 `gateway.auth.password` 都設定了且 `gateway.auth.mode` 未設定，doctor 封鎖安裝/修復直到明確設定 mode。
- 對於 Linux 使用者 systemd 單元，doctor token 漂移檢查現在在比較服務認證中繼資料時包含 `Environment=` 和 `EnvironmentFile=` 來源。
- 您隨時可以透過 `openclaw gateway install --force` 強制完整重寫。

### 16) Gateway 執行環境 + 埠診斷

Doctor 檢查服務執行環境（PID、最後退出狀態），並在服務已安裝但未實際執行時發出警告。它也檢查 gateway 埠（預設 `18789`）的埠衝突並回報可能的原因（gateway 已在執行、SSH 隧道）。

### 17) Gateway 執行環境最佳實踐

Doctor 在 gateway 服務執行於 Bun 或版本管理器 Node 路徑（`nvm`、`fnm`、`volta`、`asdf` 等）時發出警告。WhatsApp + Telegram 頻道需要 Node，且版本管理器路徑在升級後可能中斷，因為服務不會載入您的 shell 初始化。Doctor 在可用時提供遷移到系統 Node 安裝的選項（Homebrew/apt/choco）。

### 18) 設定寫入 + 精靈中繼資料

Doctor 持久化任何設定變更並標記精靈中繼資料以記錄 doctor 執行。

### 19) 工作空間提示（備份 + 記憶系統）

Doctor 在遺失時建議工作空間記憶系統，並在工作空間尚未在 git 下時列印備份提示。

請參閱 [/concepts/agent-workspace](/zh-Hant/concepts/agent-workspace) 了解工作空間結構與 git 備份的完整指南（建議使用私人 GitHub 或 GitLab）。
