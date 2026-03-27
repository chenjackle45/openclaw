---
title: "Memory configuration reference（Memory 設定參考）"
summary: "Full configuration reference for OpenClaw memory search, embedding providers, QMD backend, hybrid search, and multimodal memory（OpenClaw memory 搜尋、embedding providers、QMD backend、hybrid 搜尋與 multimodal memory 的完整設定參考）"
read_when:
  - 你想設定 memory 搜尋 providers 或 embedding 模型
  - 你想設定 QMD backend
  - 你想調整 hybrid 搜尋、MMR 或 temporal decay
  - 你想啟用 multimodal memory 索引
---

# Memory configuration reference

此頁涵蓋 OpenClaw memory 搜尋的完整設定介面。針對概念概述（檔案配置、memory 工具、何時寫入 memory 與自動刷新），參考 [Memory](/zh-Hant/concepts/memory)。

## Memory 搜尋預設值

- 預設啟用。
- 監視 memory 檔案以進行變更（防抖）。
- 在 `agents.defaults.memorySearch` 下設定 memory 搜尋（不是頂層 `memorySearch`）。
- 預設使用遠端 embeddings。如果未設定 `memorySearch.provider`，OpenClaw 自動選擇：
  1. `local`，如果已設定 `memorySearch.local.modelPath` 且檔案存在。
  2. `openai`，如果可解析 OpenAI key。
  3. `gemini`，如果可解析 Gemini key。
  4. `voyage`，如果可解析 Voyage key。
  5. `mistral`，如果可解析 Mistral key。
  6. 否則 memory 搜尋保持禁用，直到設定。
- 本地模式使用 node-llama-cpp，可能需要 `pnpm approve-builds`。
- 使用 sqlite-vec（當可用時）加速 SQLite 內的向量搜尋。
- `memorySearch.provider = "ollama"` 也支持本地/自託管 Ollama embeddings（`/api/embeddings`），但不會自動選擇。

遠端 embeddings **需要** embedding provider 的 API key。OpenClaw 從 auth profiles、`models.providers.*.apiKey` 或環境變數解析 keys。Codex OAuth 只涵蓋 chat/completions，**不** 滿足 memory 搜尋的 embeddings。針對 Gemini，使用 `GEMINI_API_KEY` 或 `models.providers.google.apiKey`。針對 Voyage，使用 `VOYAGE_API_KEY` 或 `models.providers.voyage.apiKey`。針對 Mistral，使用 `MISTRAL_API_KEY` 或 `models.providers.mistral.apiKey`。Ollama 通常不需要真實 API key（當本地策略需要時，如 `OLLAMA_API_KEY=ollama-local` 這樣的佔位符就足夠）。

使用自訂 OpenAI 相容端點時，設定 `memorySearch.remote.apiKey`（與可選 `memorySearch.remote.headers`）。

## QMD backend（實驗）

設定 `memory.backend = "qmd"` 以將內建 SQLite indexer 交換為 [QMD](https://github.com/tobi/qmd)：結合 BM25 + vectors + 重排的本地優先搜尋 sidecar。Markdown 保持事實來源；OpenClaw shells 到 QMD 以進行檢索。關鍵點：

### 前置條件

- 預設禁用。按 config 選擇加入（`memory.backend = "qmd"`）。
- 分別安裝 QMD CLI（`bun install -g https://github.com/tobi/qmd` 或取得版本），並確保 `qmd` 二進位檔在 gateway 的 `PATH` 上。
- QMD 需要允許擴充的 SQLite 建置（macOS 上 `brew install sqlite`）。
- QMD 透過 Bun + `node-llama-cpp` 完全本地執行，並在首次使用時從 HuggingFace 自動下載 GGUF 模型（不需單獨 Ollama daemon）。
- Gateway 在 `~/.openclaw/agents/<agentId>/qmd/` 下的自包含 XDG home 中執行 QMD，設定 `XDG_CONFIG_HOME` 與 `XDG_CACHE_HOME`。
- OS 支援：macOS 與 Linux 在安裝 Bun + SQLite 後立即工作。Windows 最好透過 WSL2 支援。

### Sidecar 如何執行

- Gateway 在 `~/.openclaw/agents/<agentId>/qmd/` 下寫入自包含 QMD home（config + cache + sqlite DB）。
- Collections 透過 `qmd collection add` 從 `memory.qmd.paths` 建立（加上預設工作區 memory 檔案），然後 `qmd update` + `qmd embed` 在 boot 與可設定間隔執行（`memory.qmd.update.interval`，預設 5 m）。
- Gateway 現在在 startup 初始化 QMD manager，所以週期更新計時器甚至在首個 `memory_search` 呼叫前就武裝。
- Boot 重新整理現在預設在背景執行，所以聊天 startup 不被阻止；設定 `memory.qmd.update.waitForBootSync = true` 以保持前一個阻止行為。
- 搜尋透過 `memory.qmd.searchMode` 執行（預設 `qmd search --json`；也支援 `vsearch` 與 `query`）。如果所選模式拒絕你 QMD 建置上的旗標，OpenClaw 使用 `qmd query` 重試。如果 QMD 失敗或二進位遺漏，OpenClaw 自動回退到內建 SQLite manager，所以 memory 工具保持運作。
- OpenClaw 今天不公開 QMD embed 批量大小調整；批量行為由 QMD 本身控制。
- **首個搜尋可能緩慢**：QMD 可在首個 `qmd query` 執行時下載本地 GGUF 模型（重排機/query 擴張）。
  - OpenClaw 在執行 QMD 時自動設定 `XDG_CONFIG_HOME`/`XDG_CACHE_HOME`。
  - 如果你想預先手動下載模型（並預熱相同 OpenClaw 使用的索引），執行一次性查詢，agent 的 XDG dirs。

    OpenClaw 的 QMD 狀態住在你的 **state dir**（預設 `~/.openclaw`）。你可透過匯出相同 XDG 變數 OpenClaw 使用來指向確切相同的索引：

    ```bash
    # 選擇相同的 state dir OpenClaw 使用
    STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

    export XDG_CONFIG_HOME="$STATE_DIR/agents/main/qmd/xdg-config"
    export XDG_CACHE_HOME="$STATE_DIR/agents/main/qmd/xdg-cache"

    # （可選）強制索引重新整理 + embeddings
    qmd update
    qmd embed

    # 預熱 / 觸發首次模型下載
    qmd query "test" -c memory-root --json >/dev/null 2>&1
    ```

### Config 介面（`memory.qmd.*`）

- `command`（預設 `qmd`）：覆蓋執行檔路徑。
- `searchMode`（預設 `search`）：選擇哪個 QMD 命令支援 `memory_search`（`search`、`vsearch`、`query`）。
- `includeDefaultMemory`（預設 `true`）：自動索引 `MEMORY.md` + `memory/**/*.md`。
- `paths[]`：加入額外目錄/檔案（`path`、可選 `pattern`、可選穩定 `name`）。
- `sessions`：選擇加入工作階段 JSONL 索引（`enabled`、`retentionDays`、`exportDir`）。
- `update`：控制重新整理節奏與維護執行：（`interval`、`debounceMs`、`onBoot`、`waitForBootSync`、`embedInterval`、`commandTimeoutMs`、`updateTimeoutMs`、`embedTimeoutMs`）。
- `limits`：夾結回復有效載荷（`maxResults`、`maxSnippetChars`、`maxInjectedChars`、`timeoutMs`）。
- `scope`：相同 schema 如 [`session.sendPolicy`](/zh-Hant/gateway/configuration-reference#session)。預設為 DM-only（`deny` 全部，`allow` 直接聊天）；鬆弛它以在群組/channels 中呈現 QMD 命中。
  - `match.keyPrefix` 匹配 **正規化** 工作階段鍵（小寫，移除任何前導 `agent:<id>:`）。範例：`discord:channel:`。
  - `match.rawKeyPrefix` 匹配 **原始** 工作階段鍵（小寫），包括 `agent:<id>:`。範例：`agent:main:discord:`。
  - Legacy：`match.keyPrefix: "agent:..."` 仍視為原始鍵前綴，但針對清晰性偏好 `rawKeyPrefix`。
- 當 `scope` 拒絕搜尋時，OpenClaw 記錄派生的 `channel`/`chatType` 的警告，所以空結果更容易 debug。
- 源自工作區外的 snippets 在 `memory_search` 結果中呈現為 `qmd/<collection>/<relative-path>`；`memory_get` 理解該前綴並從已設定的 QMD collection 根讀取。
- 當 `memory.qmd.sessions.enabled = true` 時，OpenClaw 將已消毒的工作階段 transcripts（User/Assistant 回合）匯出到 `~/.openclaw/agents/<id>/qmd/sessions/` 下的專用 QMD collection，所以 `memory_search` 可回想最近 conversations，不觸及內建 SQLite 索引。
- `memory_search` snippets 現在包括 `Source: <path#line>` 頁尾，當 `memory.citations` 為 `auto`/`on` 時；設定 `memory.citations = "off"` 以保持路徑中繼資料內部（agent 仍接收用於 `memory_get` 的路徑，但 snippet 文字省略頁尾且系統 prompt 警告 agent 不引用它）。

### QMD 範例

```json5
memory: {
  backend: "qmd",
  citations: "auto",
  qmd: {
    includeDefaultMemory: true,
    update: { interval: "5m", debounceMs: 15000 },
    limits: { maxResults: 6, timeoutMs: 4000 },
    scope: {
      default: "deny",
      rules: [
        { action: "allow", match: { chatType: "direct" } },
        // 正規化工作階段鍵前綴（移除 `agent:<id>:`）。
        { action: "deny", match: { keyPrefix: "discord:channel:" } },
        // 原始工作階段鍵前綴（包括 `agent:<id>:`）。
        { action: "deny", match: { rawKeyPrefix: "agent:main:discord:" } },
      ]
    },
    paths: [
      { name: "docs", path: "~/notes", pattern: "**/*.md" }
    ]
  }
}
```

### 引用與回退

- `memory.citations` 不論 backend（`auto`/`on`/`off`）適用。
- 當 `qmd` 執行時，我們標記 `status().backend = "qmd"`，所以診斷顯示哪個引擎提供結果。如果 QMD 子處理離開或 JSON 輸出無法解析，搜尋管理器記錄警告並傳回內建提供者（現有 Markdown embeddings），直到 QMD 復原。

## 額外 memory 路徑

如果你想索引預設工作區配置外的 Markdown 檔案，加入明確路徑：

```json5
agents: {
  defaults: {
    memorySearch: {
      extraPaths: ["../team-docs", "/srv/shared-notes/overview.md"]
    }
  }
}
```
