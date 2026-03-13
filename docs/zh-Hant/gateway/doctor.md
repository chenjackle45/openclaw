---
summary: "Doctor 指令：健康檢查、設定遷移和修復步驟"
read_when:
  - Adding or modifying doctor migrations
  - Introducing breaking config changes
title: "Doctor（醫生）"
---

# Doctor

`openclaw doctor` 是 OpenClaw 的修復 + 遷移工具。它修正陳舊的設定/狀態，進行健康檢查，並提供可行的修復步驟。

## 快速入門

```bash
openclaw doctor
```

### 無人值守 / 自動化

```bash
openclaw doctor --yes
```

接受預設值而不提示（包括當適用時的重啟/服務/沙箱修復步驟）。

```bash
openclaw doctor --repair
```

應用建議的修復而不提示（進行安全的修復 + 重啟）。

```bash
openclaw doctor --repair --force
```

也應用激進的修復（覆蓋自訂的 supervisor 設定）。

```bash
openclaw doctor --non-interactive
```

執行而不提示，僅應用安全遷移（設定正規化 + 磁碟狀態移動）。跳過需要人工確認的重啟/服務/沙箱操作。
偵測到時自動執行遺留狀態遷移。

```bash
openclaw doctor --deep
```

掃描系統服務中額外的 Gateway 安裝（launchd/systemd/schtasks）。

如果想在寫入前檢查變更，先開啟設定檔：

```bash
cat ~/.openclaw/openclaw.json
```

## 工作內容（摘要）

- 選用的 git 安裝前置更新（僅互動模式）。
- UI 協議新鮮度檢查（協議綱要較新時重建 Control UI）。
- 健康檢查 + 重啟提示。
- 技能狀態摘要（合格/遺失/阻止）。
- 遺留值的設定正規化。
- OpenCode 提供者覆蓋警告（`models.providers.opencode` / `models.providers.opencode-go`）。
- 遺留磁碟狀態遷移（會話/agent 目錄/WhatsApp 驗證）。
- 遺留 cron 存儲遷移（`jobId`、`schedule.cron`、頂級 delivery/payload 欄位、payload `provider`、簡易 `notify: true` webhook 回退工作）。
- 狀態完整性和權限檢查（會話、記錄、狀態目錄）。
- 本地執行時的設定檔權限檢查（chmod 600）。
- 模型驗證健康：檢查 OAuth 過期、可刷新即期權杖，並報告驗證設定檔冷卻期/禁用狀態。
- 額外工作區目錄檢測（`~/openclaw`）。
- 啟用沙箱時的沙箱映像修復。
- 遺留服務遷移和額外 Gateway 偵測。
- Gateway 執行時檢查（服務已安裝但未執行；快取 launchd 標籤）。
- 頻道狀態警告（從執行中的 Gateway 探測）。
- Supervisor 設定稽核（launchd/systemd/schtasks）與選用修復。
- Gateway 執行時最佳實踐檢查（Node vs Bun、版本管理器路徑）。
- Gateway 連接埠碰撞診斷（預設 `18789`）。
- 開放 DM 政策的安全警告。
- 本地權杖模式的 Gateway 驗證檢查（無權杖來源時提供權杖生成；不覆蓋權杖 SecretRef 設定）。
- Linux 上的 systemd linger 檢查。
- 源安裝檢查（pnpm 工作區不匹配、遺失 UI 資源、遺失 tsx 二進位）。
- 寫入更新的設定 + wizard 中繼資料。

## 詳細行為和理由

### 0）選用更新（git 安裝）

如果這是 git 簽出且 doctor 以互動方式執行，它會先提供更新（fetch/rebase/build）的選項，再執行 doctor。

### 1）設定正規化

如果設定包含遺留值形狀（例如 `messages.ackReaction` 沒有通道特定覆蓋），doctor 會將其正規化為目前綱要。

### 2）遺留設定鍵遷移

當設定包含已棄用的鍵時，其他指令會拒絕執行並要求執行 `openclaw doctor`。

Doctor 將：

- 解釋找到了哪些遺留鍵。
- 顯示套用的遷移。
- 使用更新的綱要重寫 `~/.openclaw/openclaw.json`。

Gateway 也在啟動時自動執行 doctor 遷移，當它偵測到遺留設定格式時，所以陳舊設定無需手動干預即可修復。

目前遷移：

- `routing.allowFrom` → `channels.whatsapp.allowFrom`
- `routing.groupChat.requireMention` → `channels.whatsapp/telegram/imessage.groups."*".requireMention`
- `routing.groupChat.historyLimit` → `messages.groupChat.historyLimit`
- `routing.groupChat.mentionPatterns` → `messages.groupChat.mentionPatterns`
- `routing.queue` → `messages.queue`
- `routing.bindings` → 頂級 `bindings`
- `routing.agents`/`routing.defaultAgentId` → `agents.list` + `agents.list[].default`
- `routing.agentToAgent` → `tools.agentToAgent`
- `routing.transcribeAudio` → `tools.media.audio.models`
- `bindings[].match.accountID` → `bindings[].match.accountId`
- 對於命名帳戶但遺失 `accounts.default` 的通道，當存在時將帳戶範圍頂級單帳戶通道值移動到 `channels.<channel>.accounts.default`
- `identity` → `agents.list[].identity`
- `agent.*` → `agents.defaults` + `tools.*`（工具/elevated/exec/沙箱/子代理）
- `agent.model`/`allowedModels`/`modelAliases`/`modelFallbacks`/`imageModelFallbacks`
  → `agents.defaults.models` + `agents.defaults.model.primary/fallbacks` + `agents.defaults.imageModel.primary/fallbacks`
- `browser.ssrfPolicy.allowPrivateNetwork` → `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork`

Doctor 警告還包括多帳戶通道的帳戶預設指導：

- 如果兩個或多個 `channels.<channel>.accounts` 項目已設定但沒有 `channels.<channel>.defaultAccount` 或 `accounts.default`，doctor 會警告回退路由可能挑選到未預期的帳戶。
- 如果 `channels.<channel>.defaultAccount` 設定為未知帳戶 ID，doctor 會警告並列出已設定的帳戶 ID。

### 2b）OpenCode 提供者覆蓋

如果你已手動新增 `models.providers.opencode`、`opencode-zen` 或 `opencode-go`，它會覆蓋來自 `@mariozechner/pi-ai` 的內建 OpenCode 目錄。
這可能會將模型強制到錯誤的 API 或清空成本。Doctor 會警告，讓你可以移除覆蓋並恢復逐模型 API 路由 + 成本。

### 3）遺留狀態遷移（磁碟版面配置）

Doctor 可將較舊的磁碟版面配置遷移到目前結構：

- 會話存儲 + 記錄：
  - 來自 `~/.openclaw/sessions/` 到 `~/.openclaw/agents/<agentId>/sessions/`
- Agent 目錄：
  - 來自 `~/.openclaw/agent/` 到 `~/.openclaw/agents/<agentId>/agent/`
- WhatsApp 驗證狀態（Baileys）：
  - 來自遺留 `~/.openclaw/credentials/*.json`（除 `oauth.json` 外）
  - 到 `~/.openclaw/credentials/whatsapp/<accountId>/...`（預設帳戶 id：`default`）

這些遷移是盡力而為且冪等的；doctor 會在留下任何遺留資料夾作為備份時發出警告。Gateway/CLI 也在啟動時自動遷移遺留會話 + agent 目錄，所以歷史/驗證/模型無需手動 doctor 執行即可進入逐代理路徑。WhatsApp 驗證意圖上只能透過 `openclaw doctor` 遷移。

### 3b）遺留 cron 存儲遷移

Doctor 還檢查 cron 工作存儲（預設 `~/.openclaw/cron/jobs.json`，或 `cron.store` 被覆蓋時）中排程器仍接受相容的舊工作形狀。

目前 cron 清理包括：

- `jobId` → `id`
- `schedule.cron` → `schedule.expr`
- 頂級 payload 欄位（`message`、`model`、`thinking`、...）→ `payload`
- 頂級 delivery 欄位（`deliver`、`channel`、`to`、`provider`、...）→ `delivery`
- payload `provider` delivery 別名 → 明確 `delivery.channel`
- 簡易遺留 `notify: true` webhook 回退工作 → 明確 `delivery.mode="webhook"` 與 `delivery.to=cron.webhook`

Doctor 只在不變更行為時自動遷移 `notify: true` 工作。如果工作結合遺留 notify 回退與現有非 webhook delivery 模式，doctor 會警告並將該工作留予手動檢查。

### 4）狀態完整性檢查（會話持久性、路由和安全）

狀態目錄是操作腦幹。如果消失了，你會失去會話、認證、日誌和設定（除非在別處有備份）。

Doctor 檢查：

- **狀態目錄遺失**：警告災難性狀態喪失，提示重建目錄，並提醒無法復原遺失資料。
- **狀態目錄權限**：驗證可寫性；提供修復權限（當偵測到擁有者/群組不匹配時發出 `chown` 提示）。
- **macOS 雲端同步狀態目錄**：警告當狀態解析在 iCloud Drive（`~/Library/Mobile Documents/com~apple~CloudDocs/...`）或 `~/Library/CloudStorage/...` 下，因為同步備份路徑可能導致較慢 I/O 和鎖定/同步競爭。
- **Linux SD 或 eMMC 狀態目錄**：警告當狀態解析到 `mmcblk*` 掛載來源時，因為 SD 或 eMMC 備份隨機 I/O 可能較慢且在會話和認證寫入下磨損更快。
- **會話目錄遺失**：`sessions/` 和會話存儲目錄是持久化歷史和避免 `ENOENT` 崩潰所需的。
- **記錄不匹配**：警告當近期會話項目有遺失的記錄檔案時。
- **主會話「1 行 JSONL」**：標記當主記錄只有一行時（歷史沒有累積）。
- **多個狀態目錄**：警告當多個 `~/.openclaw` 資料夾存在跨家目錄或 `OPENCLAW_STATE_DIR` 指向別處時（歷史可能在安裝間分割）。
- **遠端模式提醒**：如果 `gateway.mode=remote`，doctor 會提醒在遠端主機上執行它（狀態住在那裡）。
- **設定檔權限**：警告如果 `~/.openclaw/openclaw.json` 群組/世界可讀並提供收緊到 `600` 的選項。

### 5）模型驗證健康（OAuth 過期）

Doctor 檢查驗證存儲中的 OAuth 設定檔，當權杖即期/已過期時警告，並可在安全時刷新它們。如果 Anthropic Claude Code 設定檔陳舊，它建議執行 `claude setup-token`（或貼上設定權杖）。
刷新提示只在以互動方式執行時出現（TTY）；`--non-interactive` 跳過刷新嘗試。

Doctor 還報告因以下暫時不可用的驗證設定檔：

- 短冷卻期（速率限制/逾時/驗證失敗）
- 更長禁用（計費/信用失敗）

### 6）Hooks 模型驗證

如果 `hooks.gmail.model` 已設定，doctor 會根據目錄和允許清單驗證模型參考，並當它無法解析或被禁用時警告。

### 7）沙箱映像修復

啟用沙箱時，doctor 檢查 Docker 映像並提供建置或切換到遺留名稱的選項，如果目前映像遺失。

### 8）Gateway 服務遷移和清理提示

Doctor 偵測遺留 Gateway 服務（launchd/systemd/schtasks）並提供移除它們和使用目前 Gateway 連接埠安裝 OpenClaw 服務的選項。它也可掃描額外類 Gateway 服務並列印清理提示。
設定檔名稱的 OpenClaw Gateway 服務視為一級，未被標記為「額外」。

### 9）安全警告

當提供者向 DM 開放而不帶允許清單，或當政策以危險方式設定時，doctor 會發出警告。

### 10）systemd linger（Linux）

如果以 systemd 使用者服務執行，doctor 確保啟用 lingering，使 Gateway 在登出後保持活動。

### 11）技能狀態

Doctor 列印目前工作區符合資格/遺失/阻止技能的快速摘要。

### 12）Gateway 驗證檢查（本地權杖）

Doctor 檢查本地 Gateway 權杖驗證整備。

- 如果權杖模式需要權杖且沒有權杖來源存在，doctor 提供生成一個的選項。
- 如果 `gateway.auth.token` 由 SecretRef 管理但無法取得，doctor 會警告並不用純文字覆蓋它。
- `openclaw doctor --generate-gateway-token` 在沒有設定權杖 SecretRef 時強制只生成。

### 12b）唯讀 SecretRef 感知修復

某些修復流程需要檢查已設定認證而不削弱執行時快速失敗行為。

- `openclaw doctor --fix` 現在對目標設定修復使用與狀態族指令相同的唯讀 SecretRef 摘要模型。
- 範例：Telegram `allowFrom` / `groupAllowFrom` `@username` 修復嘗試在可用時使用已設定的機器人認證。
- 如果 Telegram 機器人權杖透過 SecretRef 設定但在目前指令路徑中無法取得，doctor 報告認證已設定但無法取得，並跳過自動解析而不是崩潰或誤報權杖遺失。

### 13）Gateway 健康檢查 + 重啟

Doctor 執行健康檢查並在 Gateway 看起來不健康時提供重啟的選項。

### 14）頻道狀態警告

如果 Gateway 健康，doctor 執行頻道狀態探測並報告警告及建議修復。

### 15）Supervisor 設定稽核 + 修復

Doctor 檢查已安裝的 supervisor 設定（launchd/systemd/schtasks）以查詢遺失或過時的預設值（例如 systemd 網路上線相依性和重啟延遲）。當找到不匹配時，它建議更新並可重寫服務檔案/工作到目前預設值。

備註：

- `openclaw doctor` 在重寫 supervisor 設定前提示。
- `openclaw doctor --yes` 接受預設修復提示。
- `openclaw doctor --repair` 應用建議的修復而不提示。
- `openclaw doctor --repair --force` 覆蓋自訂 supervisor 設定。
- 如果權杖驗證需要權杖且 `gateway.auth.token` 由 SecretRef 管理，doctor 服務安裝/修復會驗證 SecretRef 但不將已解析純文字權杖值持久化為 supervisor 服務環境中繼資料。
- 如果權杖驗證需要權杖且已設定的權杖 SecretRef 未解析，doctor 會以可行指導阻止安裝/修復路徑。
- 如果 `gateway.auth.token` 和 `gateway.auth.password` 都已設定且 `gateway.auth.mode` 未設定，doctor 會阻止安裝/修復直到明確設定模式。
- 對於 Linux 使用者 systemd 單元，doctor 權杖漂移檢查現在包括比較服務驗證中繼資料時的 `Environment=` 和 `EnvironmentFile=` 來源。
- 你可一律透過 `openclaw gateway install --force` 強制完全重寫。

### 16）Gateway 執行時 + 連接埠診斷

Doctor 檢查服務執行時（PID、上次結束狀態）並在服務已安裝但未實際執行時警告。它也檢查 Gateway 連接埠（預設 `18789`）的連接埠碰撞並報告可能原因（Gateway 已執行、SSH 通道）。

### 17）Gateway 執行時最佳實踐

當 Gateway 服務在 Bun 或版本管理 Node 路徑（`nvm`、`fnm`、`volta`、`asdf` 等）上執行時 doctor 會警告。WhatsApp + Telegram 通道需要 Node，版本管理路徑可在升級後破斷，因為服務不載入你的 shell init。Doctor 在可用時提供遷移到系統 Node 安裝（Homebrew/apt/choco）的選項。

### 18）設定寫入 + wizard 中繼資料

Doctor 持久化任何設定變更並戳記 wizard 中繼資料以記錄 doctor 執行。

### 19）工作區提示（備份 + 記憶系統）

Doctor 在遺失時建議工作區記憶系統並在工作區尚未在 git 下時列印備份提示。

參見 [/concepts/agent-workspace](/zh-Hant/concepts/agent-workspace) 以獲得工作區結構和 git 備份的完整指南（建議使用私人 GitHub 或 GitLab）。
