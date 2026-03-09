---
summary: "Skills：受管 vs 工作區、閘控規則及設定/env 接線"
read_when:
  - 新增或修改 skills
  - 變更 skill 閘控或載入規則
title: "Skills（技能）"
---

# Skills (OpenClaw)

OpenClaw 使用**[AgentSkills](https://agentskills.io) 相容**的 skill 資料夾，教導 agent 如何使用工具。每個 skill 是一個包含帶有 YAML frontmatter 和說明的 `SKILL.md` 的目錄。OpenClaw 載入**內建 skills** 加上可選的本地覆寫，並在載入時根據環境、設定和二進位檔案的存在進行篩選。

## 位置和優先順序

Skills 從**三個**地方載入：

1. **內建 skills**：隨安裝附帶（npm 套件或 OpenClaw.app）
2. **受管/本地 skills**：`~/.openclaw/skills`
3. **工作區 skills**：`<workspace>/skills`

若 skill 名稱衝突，優先順序為：

`<workspace>/skills`（最高）→ `~/.openclaw/skills` → 內建 skills（最低）

此外，你可以透過 `~/.openclaw/openclaw.json` 中的 `skills.load.extraDirs` 設定額外的 skill 資料夾（最低優先順序）。

## 每個 agent vs 共用 skills

在**多 agent** 設定中，每個 agent 有自己的工作區。這意味著：

- **每個 agent 的 skills** 位於僅適用於該 agent 的 `<workspace>/skills`。
- **共用 skills** 位於 `~/.openclaw/skills`（受管/本地），對同一機器上的**所有 agent** 可見。
- 若你希望多個 agent 使用共同的 skills 套件，也可以透過 `skills.load.extraDirs`（最低優先順序）新增**共用資料夾**。

若相同的 skill 名稱存在於多個地方，則套用一般優先順序：工作區優先，然後是受管/本地，再來是內建。

## Plugins + skills

Plugins 可以透過在 `openclaw.plugin.json` 中列出 `skills` 目錄來附帶自己的 skills（路徑相對於 plugin 根目錄）。Plugin skills 在 plugin 啟用時載入，並參與正常的 skill 優先順序規則。你可以透過 plugin 設定條目上的 `metadata.openclaw.requires.config` 進行閘控。請參閱 [Plugins](/zh-Hant/tools/plugin) 了解探索/設定，以及 [Tools](/zh-Hant/tools) 了解這些 skills 所教授的工具介面。

## ClawHub（安裝 + 同步）

ClawHub 是 OpenClaw 的公開 skills 登錄中心。瀏覽 [https://clawhub.com](https://clawhub.com)。使用它來探索、安裝、更新和備份 skills。
完整指南：[ClawHub](/zh-Hant/tools/clawhub)。

常見流程：

- 安裝 skill 至你的工作區：
  - `clawhub install <skill-slug>`
- 更新所有已安裝的 skills：
  - `clawhub update --all`
- 同步（掃描 + 發布更新）：
  - `clawhub sync --all`

預設情況下，`clawhub` 安裝至你目前工作目錄下的 `./skills`（或退而使用設定的 OpenClaw 工作區）。OpenClaw 在下次 session 時將其作為 `<workspace>/skills` 載入。

## 安全注意事項

- 將第三方 skills 視為**不受信任的程式碼**。啟用前請先閱讀它們。
- 對不受信任的輸入和高風險工具優先使用沙箱化執行。請參閱 [Sandboxing](/zh-Hant/gateway/sandboxing)。
- 工作區和 extra-dir skill 探索只接受 skill 根目錄，且 `SKILL.md` 檔案的解析實際路徑必須保持在設定的根目錄內。
- `skills.entries.*.env` 和 `skills.entries.*.apiKey` 會在該 agent 輪次的**主機**行程注入密鑰（而非沙箱）。請勿在提示和日誌中使用密鑰。
- 更廣泛的威脅模型和檢查清單，請參閱 [Security](/zh-Hant/gateway/security)。

## 格式（AgentSkills + Pi 相容）

`SKILL.md` 至少必須包含：

```markdown
---
name: nano-banana-pro
description: Generate or edit images via Gemini 3 Pro Image
---
```

注意事項：

- 我們遵循 AgentSkills 規格的佈局/意圖。
- 嵌入式 agent 使用的解析器僅支援**單行** frontmatter 鍵。
- `metadata` 應為**單行 JSON 物件**。
- 在說明中使用 `{baseDir}` 來參考 skill 資料夾路徑。
- 可選的 frontmatter 鍵：
  - `homepage` — URL 在 macOS Skills UI 中顯示為「Website」（也可透過 `metadata.openclaw.homepage` 支援）。
  - `user-invocable` — `true|false`（預設：`true`）。當為 `true` 時，skill 公開為使用者斜線命令。
  - `disable-model-invocation` — `true|false`（預設：`false`）。當為 `true` 時，skill 從模型提示中排除（仍可透過使用者呼叫使用）。
  - `command-dispatch` — `tool`（可選）。設為 `tool` 時，斜線命令繞過模型直接分派至工具。
  - `command-tool` — 設定 `command-dispatch: tool` 時要呼叫的工具名稱。
  - `command-arg-mode` — `raw`（預設）。對於工具分派，將原始 args 字串轉發至工具（無核心解析）。

    工具以以下參數呼叫：
    `{ command: "<raw args>", commandName: "<slash command>", skillName: "<skill name>" }`。

## 閘控（載入時篩選器）

OpenClaw 使用 `metadata`（單行 JSON）**在載入時篩選 skills**：

```markdown
---
name: nano-banana-pro
description: Generate or edit images via Gemini 3 Pro Image
metadata:
  {
    "openclaw":
      {
        "requires": { "bins": ["uv"], "env": ["GEMINI_API_KEY"], "config": ["browser.enabled"] },
        "primaryEnv": "GEMINI_API_KEY",
      },
  }
---
```

`metadata.openclaw` 下的欄位：

- `always: true` — 始終包含此 skill（跳過其他閘控）。
- `emoji` — macOS Skills UI 使用的可選 emoji。
- `homepage` — macOS Skills UI 中顯示為「Website」的可選 URL。
- `os` — 可選的平台列表（`darwin`、`linux`、`win32`）。若設定，skill 僅在這些作業系統上有效。
- `requires.bins` — 列表；每項必須存在於 `PATH`。
- `requires.anyBins` — 列表；至少一項必須存在於 `PATH`。
- `requires.env` — 列表；env var 必須存在**或**在設定中提供。
- `requires.config` — 必須為 truthy 的 `openclaw.json` 路徑列表。
- `primaryEnv` — 與 `skills.entries.<name>.apiKey` 關聯的 env var 名稱。
- `install` — macOS Skills UI 使用的可選安裝器規格陣列（brew/node/go/uv/download）。

沙箱化注意事項：

- `requires.bins` 在 skill 載入時於**主機**上檢查。
- 若 agent 已沙箱化，二進位檔案也必須存在於**容器內部**。
  透過 `agents.defaults.sandbox.docker.setupCommand`（或自訂映像）安裝它。
  `setupCommand` 在容器建立後執行一次。
  套件安裝還需要網路輸出、可寫入的根 FS 和沙箱中的 root 使用者。
  範例：`summarize` skill（`skills/summarize/SKILL.md`）需要沙箱容器中的 `summarize` CLI 才能在那裡執行。

安裝器範例：

```markdown
---
name: gemini
description: Use Gemini CLI for coding assistance and Google search lookups.
metadata:
  {
    "openclaw":
      {
        "emoji": "♊️",
        "requires": { "bins": ["gemini"] },
        "install":
          [
            {
              "id": "brew",
              "kind": "brew",
              "formula": "gemini-cli",
              "bins": ["gemini"],
              "label": "Install Gemini CLI (brew)",
            },
          ],
      },
  }
---
```

注意事項：

- 若列出多個安裝器，gateway 會選取**單一**首選選項（可用時為 brew，否則為 node）。
- 若所有安裝器都是 `download`，OpenClaw 會列出每個條目，讓你查看可用的 artifacts。
- 安裝器規格可包含 `os: ["darwin"|"linux"|"win32"]` 以按平台篩選選項。
- Node 安裝遵循 `openclaw.json` 中的 `skills.install.nodeManager`（預設：npm；選項：npm/pnpm/yarn/bun）。
  這僅影響 **skill 安裝**；Gateway 執行期仍應使用 Node（不建議 WhatsApp/Telegram 使用 Bun）。
- Go 安裝：若缺少 `go` 且 `brew` 可用，gateway 會先透過 Homebrew 安裝 Go，並在可能時將 `GOBIN` 設為 Homebrew 的 `bin`。
- Download 安裝：`url`（必填）、`archive`（`tar.gz` | `tar.bz2` | `zip`）、`extract`（預設：偵測到 archive 時自動）、`stripComponents`、`targetDir`（預設：`~/.openclaw/tools/<skillKey>`）。

若不存在 `metadata.openclaw`，skill 始終有效（除非在設定中停用，或被內建 skills 的 `skills.allowBundled` 封鎖）。

## 設定覆寫（`~/.openclaw/openclaw.json`）

內建/受管 skills 可以切換並提供 env 值：

```json5
{
  skills: {
    entries: {
      "nano-banana-pro": {
        enabled: true,
        apiKey: { source: "env", provider: "default", id: "GEMINI_API_KEY" }, // or plaintext string
        env: {
          GEMINI_API_KEY: "GEMINI_KEY_HERE",
        },
        config: {
          endpoint: "https://example.invalid",
          model: "nano-pro",
        },
      },
      peekaboo: { enabled: true },
      sag: { enabled: false },
    },
  },
}
```

注意：若 skill 名稱包含連字號，請將鍵加上引號（JSON5 允許引號鍵）。

設定鍵預設與 **skill 名稱**相符。若 skill 定義了 `metadata.openclaw.skillKey`，請在 `skills.entries` 下使用該鍵。

規則：

- `enabled: false` 會停用 skill，即使它是內建/已安裝的。
- `env`：**僅在**變數尚未在行程中設定時注入。
- `apiKey`：適用於宣告 `metadata.openclaw.primaryEnv` 的 skills 的便利設定。
  支援明文字串或 SecretRef 物件（`{ source, provider, id }`）。
- `config`：可選的每個 skill 自訂欄位容器；自訂鍵必須放在這裡。
- `allowBundled`：僅限**內建** skills 的可選允許清單。若設定，只有清單中的內建 skills 有效（受管/工作區 skills 不受影響）。

## 環境注入（每次 agent 執行）

當 agent 執行開始時，OpenClaw：

1. 讀取 skill 元資料。
2. 將任何 `skills.entries.<key>.env` 或 `skills.entries.<key>.apiKey` 套用至 `process.env`。
3. 使用**有效的** skills 建構 system prompt。
4. 在執行結束後還原原始環境。

這**限定於 agent 執行範圍**，不是全域 shell 環境。

## Session 快照（效能）

OpenClaw 在 **session 開始時**快照有效的 skills，並將該清單重複用於同一 session 的後續輪次。Skills 或設定的變更在下一個新 session 時生效。

Skills 也可以在啟用 skills 監視器時或出現新的有效遠端節點時（見下文）在 session 中間重新整理。這可視為**熱重載**：重新整理後的清單在下一個 agent 輪次時被採用。

## 遠端 macOS 節點（Linux gateway）

若 Gateway 在 Linux 上執行，但有 **macOS 節點**連接（且已允許 `system.run`，即 Exec 審批安全性未設為 `deny`），當所需的二進位檔案存在於該節點時，OpenClaw 可以將僅限 macOS 的 skills 視為有效。Agent 應透過 `nodes` 工具（通常是 `nodes.run`）執行這些 skills。

這依賴節點回報其命令支援以及透過 `system.run` 進行的二進位探測。若 macOS 節點稍後離線，skills 仍然可見；在節點重新連接前，呼叫可能會失敗。

## Skills 監視器（自動重新整理）

預設情況下，OpenClaw 監視 skill 資料夾，並在 `SKILL.md` 檔案變更時更新 skills 快照。在 `skills.load` 下設定此項：

```json5
{
  skills: {
    load: {
      watch: true,
      watchDebounceMs: 250,
    },
  },
}
```

## Token 影響（skills 清單）

當 skills 有效時，OpenClaw 會將可用 skills 的緊湊 XML 清單注入 system prompt（透過 `pi-coding-agent` 中的 `formatSkillsForPrompt`）。成本是確定性的：

- **基礎開銷（僅在 ≥1 個 skill 時）：** 195 個字元。
- **每個 skill：** 97 個字元 + XML 跳脫後的 `<name>`、`<description>` 和 `<location>` 值的長度。

公式（字元）：

```
total = 195 + Σ (97 + len(name_escaped) + len(description_escaped) + len(location_escaped))
```

注意事項：

- XML 跳脫將 `& < > " '` 擴展為實體（`&amp;`、`&lt;` 等），增加長度。
- Token 計數因模型的 tokenizer 而異。粗略的 OpenAI 風格估計約為 4 個字元/token，因此每個 skill **97 個字元 ≈ 24 個 token** 加上你的實際欄位長度。

## 受管 skills 生命週期

OpenClaw 作為安裝的一部分（npm 套件或 OpenClaw.app）附帶一組基礎 skills，作為**內建 skills**。`~/.openclaw/skills` 用於本地覆寫（例如，固定/修補 skill 而不更改內建副本）。工作區 skills 由使用者擁有，在名稱衝突時覆寫兩者。

## 設定參考

請參閱 [Skills config](/zh-Hant/tools/skills-config) 了解完整的設定 schema。

## 尋找更多 skills？

瀏覽 [https://clawhub.com](https://clawhub.com)。

---
