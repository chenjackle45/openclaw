---
title: "Agent workspace(代理工作區)"
summary: "代理工作區：位置、佈局和備份策略"
read_when:
  - 您需要解釋代理工作區或其檔案佈局
  - 您想要備份或遷移代理工作區
---
# Agent workspace（代理工作區）

工作區是代理的家。它是唯一用於檔案工具和工作區上下文的工作目錄。請保持其私密性，並將其視為記憶。

這與 `~/.openclaw/` 分開，後者儲存設定、憑證和會話。

**重要提示：** 工作區是**預設的 CWD**（當前工作目錄），而不是硬性沙盒。工具根據工作區解析相對路徑，但除非啟用了沙盒化，否則絕對路徑仍然可以到達主機上的其他地方。如果您需要隔離，請使用 [`agents.defaults.sandbox`](/gateway/sandboxing)（以及/或每代理沙盒設定）。當啟用沙盒化且 `workspaceAccess` 不是 `"rw"` 時，工具在 `~/.openclaw/sandboxes` 下的沙盒工作區中操作，而不是您的主機工作區。

## 預設位置

- 預設值：`~/.openclaw/workspace`
- 如果設定了 `OPENCLAW_PROFILE` 且不是 `"default"`，預設值變為 `~/.openclaw/workspace-<profile>`。
- 在 `~/.openclaw/openclaw.json` 中覆寫：

```json5
{
  agent: {
    workspace: "~/.openclaw/workspace"
  }
}
```

`openclaw onboard`、`openclaw configure` 或 `openclaw setup` 會在檔案缺失時建立工作區並植入啟動檔案。

如果您已經自己管理工作區檔案，可以停用啟動檔案的建立：

```json5
{ agent: { skipBootstrap: true } }
```

## 額外的工作區資料夾

較舊的安裝可能已建立 `~/openclaw`。保留多個工作區目錄可能會導致混淆的權限或狀態漂移，因為一次只有一個工作區處於活動狀態。

**建議：** 保持單個活動工作區。如果您不再使用額外的資料夾，請將其封存或移至垃圾桶（例如 `trash ~/openclaw`）。如果您有意保留多個工作區，請確保 `agents.defaults.workspace` 指向活動的那一個。

`openclaw doctor` 會在檢測到額外的工作區目錄時發出警告。

## 工作區檔案地圖（各檔案的含義）

以下是 OpenClaw 預期在工作區內包含的標準檔案：

- `AGENTS.md`
  - 代理的操作說明以及它應該如何使用記憶。
  - 在每次會話開始時載入。
  - 適合存放規則、優先順序和「如何表現」等細節的地方。

- `SOUL.md`
  - 人格、語氣和邊界。
  - 每次會話載入。

- `USER.md`
  - 使用者是誰以及如何稱呼他們。
  - 每次會話載入。

- `IDENTITY.md`
  - 代理的名稱、氛圍和表情符號。
  - 在啟動儀式期間建立/更新。

- `TOOLS.md`
  - 關於您的本地工具和慣例的備註。
  - 不控制工具的可用性；僅作為指導。

- `HEARTBEAT.md`
  - 可選的心跳運行小型檢查清單。
  - 保持簡短以避免 token 消耗。

- `BOOT.md`
  - 在啟用內部 hook 時，於 Gateway 重啟時執行的可選啟動檢查清單。
  - 保持簡短；使用 message 工具進行出站發送。

- `BOOTSTRAP.md`
  - 一次性的首次運行儀式。
  - 僅為全新工作區建立。
  - 在儀式完成後將其刪除。

- `memory/YYYY-MM-DD.md`
  - 每日記憶日誌（每天一個檔案）。
  - 建議在會話開始時讀取今天 + 昨天。

- `MEMORY.md`（可選）
  - 精選的長期記憶。
  - 僅在主私人會話中載入（不包括共享/群組上下文）。

有關工作流程和自動記憶體刷新，請參閱 [Memory](/concepts/memory)。

- `skills/`（可選）
  - 工作區特定的技能。
  - 當名稱衝突時覆寫受管理/綁定的技能。

- `canvas/`（可選）
  - 用於節點顯示的 Canvas UI 檔案（例如 `canvas/index.html`）。

如果缺少任何啟動檔案，OpenClaw 會在會話中注入「缺失檔案」標記並繼續。注入時，大型啟動檔案會被截斷；使用 `agents.defaults.bootstrapMaxChars`（預設：20000）調整限制。`openclaw setup` 可以重新建立缺失的預設值，而不會覆寫現有檔案。

## **不**在工作區中的內容

這些內容位於 `~/.openclaw/` 下，**不應**提交到工作區儲存庫：

- `~/.openclaw/openclaw.json`（設定）
- `~/.openclaw/credentials/`（OAuth token、API 金鑰）
- `~/.openclaw/agents/<agentId>/sessions/`（會話轉錄 + 元資料）
- `~/.openclaw/skills/`（受管理的技能）

如果您需要遷移會話或設定，請單獨複製它們，並將它們排除在版控之外。

## Git 備份（建議，私密）

將工作區視為私密記憶。將其放在**私有 (Private)** git 儲存庫中，以便進行備份和恢復。

在 Gateway 運行的機器上執行這些步驟（那是工作區所在的地方）。

### 1) 初始化儲存庫

如果安裝了 git，全新工作區會自動初始化。如果此工作區還不是儲存庫，請執行：

```bash
cd ~/.openclaw/workspace
git init
git add AGENTS.md SOUL.md TOOLS.md IDENTITY.md USER.md HEARTBEAT.md memory/
git commit -m "Add agent workspace"
```

### 2) 新增私有遠端（適合初學者的選項）

選項 A：GitHub 網頁 UI

1. 在 GitHub 上建立一個新的 **私有 (Private)** 儲存庫。
2. 不要使用 README 初始化（避免合併衝突）。
3. 複製 HTTPS 遠端 URL。
4. 新增遠端並推送：

```bash
git branch -M main
git remote add origin <https-url>
git push -u origin main
```

選項 B：GitHub CLI (`gh`)

```bash
gh auth login
gh repo create openclaw-workspace --private --source . --remote origin --push
```

選項 C：GitLab 網頁 UI

1. 在 GitLab 上建立一個新的 **私有 (Private)** 儲存庫。
2. 不要使用 README 初始化（避免合併衝突）。
3. 複製 HTTPS 遠端 URL。
4. 新增遠端並推送：

```bash
git branch -M main
git remote add origin <https-url>
git push -u origin main
```

### 3) 持續更新

```bash
git status
git add .
git commit -m "Update memory"
git push
```

## 不要提交秘密內容

即使在私有儲存庫中，也要避免在工作區中儲存秘密：

- API 金鑰、OAuth token、密碼或私密憑證。
- `~/.openclaw/` 下的任何內容。
- 聊天記錄或敏感附件的原始傾印。

如果您必須儲存敏感引用，請使用佔位符，並將真實的秘密儲存在其他地方（密碼管理員、環境變數或 `~/.openclaw/`）。

建議的 `.gitignore` 起始設定：

```gitignore
.DS_Store
.env
**/*.key
**/*.pem
**/secrets*
```

## 將工作區移至新機器

1. 將儲存庫複製到所需路徑（預設 `~/.openclaw/workspace`）。
2. 在 `~/.openclaw/openclaw.json` 中將 `agents.defaults.workspace` 設定為該路徑。
3. 執行 `openclaw setup --workspace <path>` 以植入任何缺失的檔案。
4. 如果您需要會話，請單獨從舊機器複製 `~/.openclaw/agents/<agentId>/sessions/`。

## 進階備註

- 多代理路由可以為每個代理使用不同的工作區。有關路由設定，請參閱 [頻道路由](/concepts/channel-routing)。
- 如果啟用了 `agents.defaults.sandbox`，非主會話可以在 `agents.defaults.sandbox.workspaceRoot` 下使用每會話沙盒工作區。
