---
summary: "技能：受管 vs 工作區、閘控規則及設定/env 接線"
read_when:
  - Adding or modifying skills
  - Changing skill gating or load rules
title: "Skills（技能）"
---

# Skills（技能）

OpenClaw 使用 **[AgentSkills](https://agentskills.io)-相容**技能資料夾教代理如何使用工具。每個技能是一個包含帶 YAML frontmatter 的 `SKILL.md` 的目錄及指導。OpenClaw 載入**捆綁技能**加可選本地覆蓋，及在載入時根據環境、設定及二進位存在篩選它們。

## 位置及優先順序

技能從**三個**地方載入：

1. **捆綁技能**：隨安裝一起提供（npm 套件或 OpenClaw.app）
2. **受管/本地技能**：`~/.openclaw/skills`
3. **工作區技能**：`<workspace>/skills`

如技能名衝突，優先順序是：

`<workspace>/skills`（最高）→ `~/.openclaw/skills` → 捆綁技能（最低）

此外，可配置額外技能資料夾（最低優先順序）透過
`skills.load.extraDirs` 在 `~/.openclaw/openclaw.json`。

## 每個代理 vs 共享技能

在**多代理**設定中，每個代理有自己的工作區。這表示：

- **每個代理技能**在 `<workspace>/skills` 針對該代理僅。
- **共享技能**在 `~/.openclaw/skills`（受管/本地）及對同一機器上的**所有代理**可見。
- **共享資料夾**也可透過 `skills.load.extraDirs`（最低優先順序）新增，如想要多個代理使用的常見技能包。

如相同技能名在多個地方存在，通常優先順序
適用：工作區贏，接著受管/本地，接著捆綁。

## 外掛＋技能

外掛可在 `openclaw.plugin.json` 中列出 `skills` 目錄來運送它們自己的技能
（相對於外掛根的路徑）。當外掛啟用及參與通常技能優先順序規則時外掛技能載入。
可透過 `metadata.openclaw.requires.config` 在外掛的設定項上閘控它們。見 [Plugins](/zh-Hant/tools/plugin) 發現/設定及 [Tools](/zh-Hant/tools) 用於那些技能教的工具表面。

## ClawHub（安裝＋同步）

ClawHub 是 OpenClaw 的公開技能登錄。瀏覽 [https://clawhub.com](https://clawhub.com)。使用發現、安裝、更新及備份技能。
完整指南：[ClawHub](/zh-Hant/tools/clawhub)。

常見流程：

- 安裝技能至工作區：
  - `clawhub install <skill-slug>`
- 更新所有安裝技能：
  - `clawhub update --all`
- 同步（掃描＋發佈更新）：
  - `clawhub sync --all`

預設，`clawhub` 安裝到你現在工作目錄下的 `./skills`（或退回至已設定 OpenClaw 工作區）。OpenClaw 在下個工作階段挑選它作 `<workspace>/skills`。

## 安全注

- 將第三方技能當作**不可信代碼**。在啟用前讀它們。
- 針對不可信輸入及危險工具，優先使用沙箱執行。見 [Sandboxing](/zh-Hant/gateway/sandboxing)。
- `skills.entries.*.env` 及 `skills.entries.*.apiKey` 注入秘密至**主機**程序，用於該代理轉（不沙箱）。保持秘密不超出提示及記錄。
- 用於更廣威脅模型及檢查清單，見 [Security](/zh-Hant/gateway/security)。

## 格式（AgentSkills + Pi-相容）

`SKILL.md` 必須包含至少：

```markdown
---
name: nano-banana-pro
description: Generate or edit images via Gemini 3 Pro Image
---
```

註：

- 我們遵循 AgentSkills 規格用於佈局/意圖。
- 嵌入代理使用的解析器僅支援**單行** frontmatter 鑰。
- `metadata` 應是**單行 JSON 物件**。
- 在指導中使用 `{baseDir}` 參考技能資料夾路徑。
- 可選 frontmatter 鑰：
  - `homepage` — URL 在 macOS Skills UI 中作"Website"出現（也透過 `metadata.openclaw.homepage` 支援）。
  - `user-invocable` — `true|false`（預設：`true`）。當 `true` 時，技能暴露作使用者斜線命令。
  - `disable-model-invocation` — `true|false`（預設：`false`）。當 `true` 時，技能從模型提示排除（仍可透過使用者調用）。
  - `command-dispatch` — `tool`（可選）。當設至 `tool` 時，斜線命令繞過模型及直接分派至工具。
  - `command-tool` — 當設定 `command-dispatch: tool` 時調用的工具名。
  - `command-arg-mode` — `raw`（預設）。用於工具分派，轉發原始 args 字串至工具（無核心解析）。

    工具使用參數調用：
    `{ command: "<raw args>", commandName: "<slash command>", skillName: "<skill name>" }`。

## 閘控（載入時篩選）

OpenClaw **在載入時用 `metadata`（單行 JSON）篩選技能**：

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

- `always: true` — 總是包含技能（跳過其他閘控）。
- `emoji` — macOS Skills UI 使用的可選 emoji。
- `homepage` — macOS Skills UI 中作"Website"顯示的可選 URL。
- `os` — 平台的可選列表（`darwin`、`linux`、`win32`）。如設定，技能僅在那些 OS 上合格。
- `requires.bins` — 列表；各必須存在 `PATH`。
- `requires.anyBins` — 列表；至少一個必須存在 `PATH`。
- `requires.env` — 列表；env var 必須存在**或**在設定中提供。
- `requires.config` — `openclaw.json` 路徑列表，必須是 truthy。
- `primaryEnv` — env var 名關聯 `skills.entries.<name>.apiKey`。
- `install` — macOS Skills UI 使用的可選安裝程式規格陣列（brew/node/go/uv/download）。

沙箱化上的註：

- `requires.bins` 在技能載入時檢查**主機**。
- 如代理沙箱化，二進位也必須在**容器內**存在。
  透過 `agents.defaults.sandbox.docker.setupCommand`（或自訂映像）安裝它。
  `setupCommand` 在建立容器後執行一次。
  套件安裝也需要網路出口、可寫根 FS 及沙箱中的根使用者。
  例：`summarize` 技能（`skills/summarize/SKILL.md`）需要 `summarize` CLI
  在沙箱容器中執行。

安裝程式例子：

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

註：

- 列出多個安裝程式時，gateway 選擇**單個**偏好選項（當可用時 brew，否則 node）。
- 如所有安裝程式是 `download`，OpenClaw 列出各項，所以可見可用成品。
- 安裝程式規格可包含 `os: ["darwin"|"linux"|"win32"]` 按平台篩選選項。
- Node 安裝遵守 `skills.install.nodeManager` 在 `openclaw.json`（預設：npm；選項：npm/pnpm/yarn/bun）。
  這僅影響**技能安裝**；Gateway 執行時應仍是 Node（不推薦 Bun 用於 WhatsApp/Telegram）。
- Go 安裝：如 `go` 遺失且 `brew` 可用，gateway 首先透過 Homebrew 安裝 Go 及可能時設定 `GOBIN` 至 Homebrew 的 `bin`。
- 下載安裝：`url`（必需）、`archive`（`tar.gz` | `tar.bz2` | `zip`）、`extract`（預設：當偵測到存檔時自動）、`stripComponents`、`targetDir`（預設：`~/.openclaw/tools/<skillKey>`）。

如沒 `metadata.openclaw`，技能總是合格（除非在設定中停用或透過 `skills.allowBundled` 針對捆綁技能被阻止）。

## 設定覆蓋（`~/.openclaw/openclaw.json`）

捆綁/受管技能可被切換及供應 env 值：

```json5
{
  skills: {
    entries: {
      "nano-banana-pro": {
        enabled: true,
        apiKey: "GEMINI_KEY_HERE",
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

註：如技能名包含連字號，引用鑰（JSON5 允許引用鑰）。

設定鑰預設符合**技能名**。如技能定義
`metadata.openclaw.skillKey`，使用 `skills.entries` 下該鑰。

規則：

- `enabled: false` 停用技能即使它的捆綁/安裝。
- `env`：注入**僅如果**變數不已在程序中設定。
- `apiKey`：聲明 `metadata.openclaw.primaryEnv` 的技能便利。
- `config`：可選行包自訂每個技能欄位；自訂鑰必須住這裡。
- `allowBundled`：可選 allowlist 針對**捆綁**技能僅。如設定，僅
  列表中的捆綁技能合格（受管/工作區技能不受影響）。

## 環境注入（每個代理執行）

當代理執行開始，OpenClaw：

1. 讀技能元資料。
2. 套用任何 `skills.entries.<key>.env` 或 `skills.entries.<key>.apiKey`
   至 `process.env`。
3. 用**合格**技能建立系統提示。
4. 代理執行結束後恢復原始環境。

這是**範圍至代理執行**，不全域 shell 環境。

## 工作階段快照（效能）

OpenClaw 快照符合技能**當工作階段開始**及重用該列表於隨後同一工作階段中的轉。技能或設定變更在下個新工作階段生效。

技能也可在工作階段中間刷新當技能監視程式啟用或當新符合遠端節點出現（見下）時。把這看作**熱重載**：刷新列表在下個代理轉被挑選。

## 遠端 macOS 節點（Linux gateway）

如 Gateway 執行在 Linux 但一個**macOS 節點**連接**帶 `system.run` 允許**（Exec approvals security 未設至 `deny`），OpenClaw 可視 macOS-only 技能在該節點上存在必需二進位時符合。代理應透過 `nodes` 工具執行那些技能（通常 `nodes.run`）。

這依賴該節點報告它的命令支援及透過 `system.run` 的 bin 探測。如 macOS 節點稍後離線，技能保持可見；調用可能失敗直到節點重連。

## 技能監視程式（自動刷新）

預設，OpenClaw 監視技能資料夾並在 `SKILL.md` 檔案改變時凹陷技能快照。在 `skills.load` 下設定此項：

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

## 令牌影響（技能列表）

當技能符合時，OpenClaw 注入緊湊 XML 符合技能列表至系統提示（透過 pi-coding-agent 中的 `formatSkillsForPrompt`）。成本是決定性的：

- **僅當 ≥1 技能時的基礎開銷**：195 字元。
- **每個技能**：97 字元＋ XML-escap `<name>`、`<description>` 及 `<location>` 值的長度。

公式（字元）：

```
總 = 195 + Σ (97 + len(name_escaped) + len(description_escaped) + len(location_escaped))
```

註：

- XML 逃逸擴展 `& < > " '` 至實體（`&amp;`、`&lt;` 等），增加長度。
- 令牌計數由模型分詞器變化。粗 OpenAI 型估計大約 4 字元/令牌，所以**97 字元 ≈ 24 令牌**每個技能加你實際欄位長度。

## 受管技能生命週期

OpenClaw 運送基線技能集作為**捆綁技能**作為安裝部分（npm 套件或 OpenClaw.app）。`~/.openclaw/skills` 存在用於本地覆蓋（例如，固定/補丁技能無需改變捆綁複本）。工作區技能是使用者擁有且覆蓋兩者名衝突。

## 設定參考

見 [Skills config](/zh-Hant/tools/skills-config) 用於完整設定架構。

## 想要更多技能？

瀏覽 [https://clawhub.com](https://clawhub.com)。
