---
title: "Memory（記憶體）"
summary: "OpenClaw 記憶體如何運作（工作區檔案 + 自動記憶體刷新）"
read_when:
  - 您想要記憶體檔案佈局和工作流程
  - 您想要調整自動壓縮前記憶體刷新
---

# Memory（記憶體）

OpenClaw 記憶體是**代理工作區中的純 Markdown**。檔案是真實來源；模型只「記得」寫入磁碟的內容。

記憶體搜尋工具由活動的記憶體外掛提供（預設：`memory-core`）。使用 `plugins.slots.memory = "none"` 停用記憶體外掛。

## Memory tools（記憶體工具）

OpenClaw 為這些 Markdown 檔案公開兩個代理端工具：

- `memory_search` — 對索引片段進行語義回想。
- `memory_get` — 針對特定 Markdown 檔案/行範圍的目標讀取。

`memory_get` 現在**在檔案不存在時優雅降級**（例如，第一次寫入前的今天日誌）。內建管理器和 QMD 後端都返回 `{ text: "", path }`，而不是拋出 `ENOENT`，因此代理可以處理「尚未記錄任何內容」並繼續其工作流程，無需將工具呼叫包裝在 try/catch 邏輯中。

## Memory files（記憶體檔案）(Markdown)

預設工作區佈局使用兩個記憶體層：

- `memory/YYYY-MM-DD.md`
  - 每日日誌（僅追加）。
  - 在會話開始時讀取今天 + 昨天。
- `MEMORY.md`（可選）
  - 精選的長期記憶體。
  - **僅在主私人會話中載入**（絕不在群組上下文中載入）。

這些檔案位於工作區下（`agents.defaults.workspace`，預設 `~/.openclaw/workspace`）。請參閱 [Agent workspace](/zh-Hant/concepts/agent-workspace) 了解完整佈局。

## 何時寫入記憶體

- 決策、偏好和持久事實進入 `MEMORY.md`。
- 日常備註和執行上下文進入 `memory/YYYY-MM-DD.md`。
- 如果有人說「記住這個」，請寫下來（不要保留在 RAM 中）。
- 此區域仍在發展中。提醒模型儲存記憶體是有幫助的；它會知道該怎麼做。
- 如果您想讓某件事固定下來，**要求機器人將其寫入**記憶體。

## Automatic memory flush（自動記憶體刷新）（壓縮前 ping）

當會話**接近自動壓縮**時，OpenClaw 會觸發一個**靜默、代理式輪次**，提醒模型在上下文被壓縮**之前**寫入持久記憶體。預設提示明確指出模型*可以回覆*，但通常 `NO_REPLY` 是正確的回應，這樣使用者就不會看到此輪次。

這由 `agents.defaults.compaction.memoryFlush` 控制：

```json5
{
  agents: {
    defaults: {
      compaction: {
        reserveTokensFloor: 20000,
        memoryFlush: {
          enabled: true,
          softThresholdTokens: 4000,
          systemPrompt: "Session nearing compaction. Store durable memories now.",
          prompt: "Write any lasting notes to memory/YYYY-MM-DD.md; reply with NO_REPLY if nothing to store.",
        },
      },
    },
  },
}
```

詳情：

- **Soft threshold（軟閾值）**：當會話 token 估計超過 `contextWindow - reserveTokensFloor - softThresholdTokens` 時觸發刷新。
- **Silent（靜默）** 預設：提示包含 `NO_REPLY` 以便不交付任何內容。
- **Two prompts（兩個提示）**：一個使用者提示加上一個系統提示追加提醒。
- **One flush per compaction cycle（每個壓縮週期一次刷新）**（在 `sessions.json` 中追蹤）。
- **Workspace must be writable（工作區必須可寫）**：如果會話以 `workspaceAccess: "ro"` 或 `"none"` 在沙盒中運行，則跳過刷新。

如需完整的壓縮生命週期，請參閱 [Session management + compaction](/zh-Hant/reference/session-management-compaction)。

## Vector memory search（向量記憶體搜尋）

OpenClaw 可以對 `MEMORY.md` 和 `memory/*.md` 建立一個小型向量索引，以便語義查詢可以找到相關備註，即使措辭不同。

預設值：

- 預設啟用。
- 監視記憶體檔案的更改（防抖）。
- 在 `agents.defaults.memorySearch` 下配置記憶體搜尋（不是頂層 `memorySearch`）。
- 預設使用遠端 embeddings。若未設定 `memorySearch.provider`，OpenClaw 會自動選擇：
  1. `local`（若設定了 `memorySearch.local.modelPath` 且檔案存在）。
  2. `openai`（若可解析 OpenAI key）。
  3. `gemini`（若可解析 Gemini key）。
  4. `voyage`（若可解析 Voyage key）。
  5. `mistral`（若可解析 Mistral key）。
  6. 否則記憶體搜尋保持停用，直至配置。
- 本地模式使用 node-llama-cpp，可能需要 `pnpm approve-builds`。
- 使用 sqlite-vec（可用時）加速 SQLite 內的向量搜尋。
- `memorySearch.provider = "ollama"` 也支援本地/自架 Ollama embeddings（`/api/embeddings`），但不會自動選擇。

遠端 embeddings **需要** embedding 提供商的 API key。OpenClaw 從驗證設定檔、`models.providers.*.apiKey` 或環境變數解析 key。Codex OAuth 僅涵蓋聊天/補全，並**不**滿足記憶體搜尋的 embeddings。對於 Gemini，使用 `GEMINI_API_KEY` 或 `models.providers.google.apiKey`。對於 Voyage，使用 `VOYAGE_API_KEY` 或 `models.providers.voyage.apiKey`。對於 Mistral，使用 `MISTRAL_API_KEY` 或 `models.providers.mistral.apiKey`。Ollama 通常不需要真實 API key（當本地政策需要時，`OLLAMA_API_KEY=ollama-local` 此類佔位符就足夠了）。
使用自訂 OpenAI 相容端點時，設定 `memorySearch.remote.apiKey`（及可選的 `memorySearch.remote.headers`）。

### QMD backend（實驗性）

設定 `memory.backend = "qmd"` 以將內建 SQLite 索引器替換為 [QMD](https://github.com/tobi/qmd)：結合 BM25 + vectors + reranking 的本地優先搜尋 sidecar。Markdown 保持真實來源；OpenClaw shell 出到 QMD 以進行檢索。關鍵點：

**Prereqs（先決條件）**

- 預設停用。按配置選擇加入（`memory.backend = "qmd"`）。
- 分別安裝 QMD CLI（`bun install -g https://github.com/tobi/qmd` 或取得發行版），並確保 `qmd` 二進制檔在 Gateway 的 `PATH` 上。
- QMD 需要允許擴展的 SQLite 建置（macOS 上執行 `brew install sqlite`）。
- QMD 完全在本地透過 Bun + `node-llama-cpp` 執行，並在首次使用時從 HuggingFace 自動下載 GGUF 模型（無需分開的 Ollama daemon）。
- Gateway 在 `~/.openclaw/agents/<agentId>/qmd/` 下設定 `XDG_CONFIG_HOME` 和 `XDG_CACHE_HOME` 以在自包含的 XDG 主目錄中執行 QMD。
- 作業系統支援：macOS 和 Linux 在安裝 Bun + SQLite 後開箱即用。Windows 最好透過 WSL2 支援。

**How the sidecar runs（sidecar 如何執行）**

- Gateway 在 `~/.openclaw/agents/<agentId>/qmd/` 下寫入自包含的 QMD 主目錄（設定 + 快取 + sqlite DB）。
- 集合透過 `qmd collection add` 從 `memory.qmd.paths` 建立（加上預設工作區記憶體檔案），然後 `qmd update` + `qmd embed` 在啟動時和可設定的間隔（`memory.qmd.update.interval`，預設 5 m）執行。
- Gateway 現在在啟動時初始化 QMD 管理器，因此定期更新計時器即使在第一個 `memory_search` 呼叫前也會武裝。
- 啟動重新整理現在預設在背景執行，因此聊天啟動不會被阻塞；設定 `memory.qmd.update.waitForBootSync = true` 保持先前的阻塞行為。
- 搜尋透過 `memory.qmd.searchMode` 執行（預設 `qmd search --json`；也支援 `vsearch` 和 `query`）。若選定的模式在你的 QMD 建置上拒絕旗標，OpenClaw 重試使用 `qmd query`。若 QMD 失敗或二進制檔遺漏，OpenClaw 自動回退到內建 SQLite 管理器，以便記憶體工具持續運作。
- OpenClaw 目前不公開 QMD embed batch-size 調整；批次行為由 QMD 本身控制。
- **First search may be slow（首次搜尋可能較慢）**：QMD 可能在首次 `qmd query` 執行時下載本地 GGUF 模型（reranker/query expansion）。
  - OpenClaw 在執行 QMD 時自動設定 `XDG_CONFIG_HOME`/`XDG_CACHE_HOME`。
  - 若想手動預先下載模型（並預熱 OpenClaw 使用的同一索引），執行一個一次性查詢，使用 agent 的 XDG 目錄。

    OpenClaw 的 QMD 狀態位於你的**狀態目錄**（預設 `~/.openclaw`）。
    你可以透過匯出 OpenClaw 使用的相同 XDG vars 指向完全相同的索引：

    ```bash
    # 選擇 OpenClaw 使用的相同狀態目錄
    STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

    export XDG_CONFIG_HOME="$STATE_DIR/agents/main/qmd/xdg-config"
    export XDG_CACHE_HOME="$STATE_DIR/agents/main/qmd/xdg-cache"

    # （可選）強制索引重新整理 + embeddings
    qmd update
    qmd embed

    # 預熱 / 觸發首次模型下載
    qmd query "test" -c memory-root --json >/dev/null 2>&1
    ```

**Config surface（`memory.qmd.*`）**

- `command`（預設 `qmd`）：覆寫可執行檔路徑。
- `searchMode`（預設 `search`）：選擇哪個 QMD 指令支援 `memory_search`（`search`、`vsearch`、`query`）。
- `includeDefaultMemory`（預設 `true`）：自動索引 `MEMORY.md` + `memory/**/*.md`。
- `paths[]`：新增額外目錄/檔案（`path`、選用 `pattern`、選用穩定 `name`）。
- `sessions`：選擇加入會話 JSONL 索引（`enabled`、`retentionDays`、`exportDir`）。
- `update`：控制重新整理頻率和維護執行：
  （`interval`、`debounceMs`、`onBoot`、`waitForBootSync`、`embedInterval`、`commandTimeoutMs`、`updateTimeoutMs`、`embedTimeoutMs`）。
- `limits`：鉗制回想負載（`maxResults`、`maxSnippetChars`、`maxInjectedChars`、`timeoutMs`）。
- `scope`：與 [`session.sendPolicy`](/zh-Hant/gateway/configuration#session) 相同的 schema。
  預設為僅 DM（`deny` 所有、`allow` 直接聊天）；放寬它以在群組/頻道中顯示 QMD 命中。
  - `match.keyPrefix` 匹配**正規化的**會話鍵（小寫，移除任何前導 `agent:<id>:`）。例：`discord:channel:`。
  - `match.rawKeyPrefix` 匹配**原始**會話鍵（小寫），包括 `agent:<id>:`。例：`agent:main:discord:`。
  - 舊版：`match.keyPrefix: "agent:..."` 仍被視為原始鍵前綴，但偏好 `rawKeyPrefix` 以明確性。
- 當 `scope` 拒絕搜尋時，OpenClaw 記錄警告，包含衍生的 `channel`/`chatType`，以便空結果更易除錯。
- 工作區外取得的片段在 `memory_search` 結果中顯示為 `qmd/<collection>/<relative-path>`；`memory_get` 理解此前綴並從配置的 QMD 集合根讀取。
- 當 `memory.qmd.sessions.enabled = true` 時，OpenClaw 將清理後的會話轉錄（User/Assistant 輪次）匯出到 `~/.openclaw/agents/<id>/qmd/sessions/` 下的專用 QMD 集合，以便 `memory_search` 可以回想最近的對話，無需觸及內建 SQLite 索引。
- `memory_search` 片段現在在 `memory.citations` 為 `auto`/`on` 時包含 `Source: <path#line>` 頁腳；設定 `memory.citations = "off"` 以保持路徑元資料內部（agent 仍接收路徑以用於 `memory_get`，但片段文字省略頁腳，系統提示警告 agent 不引用它）。

**Example（範例）**

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
        // 正規化會話鍵前綴（移除 `agent:<id>:`）。
        { action: "deny", match: { keyPrefix: "discord:channel:" } },
        // 原始會話鍵前綴（包括 `agent:<id>:`）。
        { action: "deny", match: { rawKeyPrefix: "agent:main:discord:" } },
      ]
    },
    paths: [
      { name: "docs", path: "~/notes", pattern: "**/*.md" }
    ]
  }
}
```

**Citations & fallback（引文和備用）**

- `memory.citations` 不論後端而適用（`auto`/`on`/`off`）。
- QMD 執行時，我們標記 `status().backend = "qmd"`，以便診斷顯示哪個引擎服務結果。若 QMD 子程序結束或 JSON 輸出無法解析，搜尋管理器記錄警告並返回內建提供商（現有 Markdown embeddings）直至 QMD 恢復。

### Additional memory paths（額外記憶體路徑）

若想對預設工作區佈局外的 Markdown 檔案建立索引，新增明確路徑：

```json5
agents: {
  defaults: {
    memorySearch: {
      extraPaths: ["../team-docs", "/srv/shared-notes/overview.md"]
    }
  }
}
```

注意：

- 路徑可以是絕對或工作區相對。
- 目錄遞迴掃描以找 `.md` 檔案。
- 預設僅索引 Markdown 檔案。
- 若 `memorySearch.multimodal.enabled = true`，OpenClaw 也索引 `extraPaths` 下支援的圖片/音訊檔案。預設記憶體根（`MEMORY.md`、`memory.md`、`memory/**/*.md`）保持僅 Markdown。
- 符號連結被忽略（檔案或目錄）。

### Multimodal memory files（多模態記憶體檔案）(Gemini image + audio)

OpenClaw 可在使用 Gemini embedding 2 時索引 `memorySearch.extraPaths` 的圖片和音訊檔案：

```json5
agents: {
  defaults: {
    memorySearch: {
      provider: "gemini",
      model: "gemini-embedding-2-preview",
      extraPaths: ["assets/reference", "voice-notes"],
      multimodal: {
        enabled: true,
        modalities: ["image", "audio"], // 或 ["all"]
        maxFileBytes: 10000000
      },
      remote: {
        apiKey: "YOUR_GEMINI_API_KEY"
      }
    }
  }
}
```

注意：

- 多模態記憶體目前僅支援 `gemini-embedding-2-preview`。
- 多模態索引僅適用於透過 `memorySearch.extraPaths` 探索的檔案。
- 此階段支援的模態：圖片和音訊。
- `memorySearch.fallback` 必須在啟用多模態記憶體時保持 `"none"`。
- 匹配的圖片/音訊檔案位元組在索引時上傳到配置的 Gemini embedding 端點。
- 支援的圖片副檔名：`.jpg`、`.jpeg`、`.png`、`.webp`、`.gif`、`.heic`、`.heif`。
- 支援的音訊副檔名：`.mp3`、`.wav`、`.ogg`、`.opus`、`.m4a`、`.aac`、`.flac`。
- 搜尋查詢保持文字，但 Gemini 可比較這些文字查詢與索引的圖片/音訊 embeddings。
- `memory_get` 仍僅讀 Markdown；二進制檔案可搜尋但不作為原始檔案內容返回。

### Gemini embeddings（原生）

將提供商設定為 `gemini` 以直接使用 Gemini embeddings API：

```json5
agents: {
  defaults: {
    memorySearch: {
      provider: "gemini",
      model: "gemini-embedding-001",
      remote: {
        apiKey: "YOUR_GEMINI_API_KEY"
      }
    }
  }
}
```

注意：

- `remote.baseUrl` 為可選（預設為 Gemini API base URL）。
- `remote.headers` 允許你在需要時新增額外標頭。
- 預設模型：`gemini-embedding-001`。
- `gemini-embedding-2-preview` 也支援：8192 token 限制和可設定維度（768 / 1536 / 3072，預設 3072）。

#### Gemini Embedding 2（preview）

```json5
agents: {
  defaults: {
    memorySearch: {
      provider: "gemini",
      model: "gemini-embedding-2-preview",
      outputDimensionality: 3072,  // 選用：768、1536 或 3072（預設）
      remote: {
        apiKey: "YOUR_GEMINI_API_KEY"
      }
    }
  }
}
```

> **⚠️ Re-index required（需要重新索引）：** 從 `gemini-embedding-001`（768 維度）切換到 `gemini-embedding-2-preview`（3072 維度）會改變向量大小。若你在 768、1536 和 3072 之間改變 `outputDimensionality` 也一樣。
> OpenClaw 會在偵測到模型或維度改變時自動重新索引。

若想使用**自訂 OpenAI 相容端點**（OpenRouter、vLLM 或代理），你可使用 OpenAI 提供商的 `remote` 配置：

```json5
agents: {
  defaults: {
    memorySearch: {
      provider: "openai",
      model: "text-embedding-3-small",
      remote: {
        baseUrl: "https://api.example.com/v1/",
        apiKey: "YOUR_OPENAI_COMPAT_API_KEY",
        headers: { "X-Custom-Header": "value" }
      }
    }
  }
}
```

若不想設定 API key，使用 `memorySearch.provider = "local"` 或設定 `memorySearch.fallback = "none"`。

Fallbacks（備用）：

- `memorySearch.fallback` 可為 `openai`、`gemini`、`voyage`、`mistral`、`ollama`、`local` 或 `none`。
- 備用提供商僅在主要 embedding 提供商失敗時使用。

Batch indexing（OpenAI + Gemini + Voyage）：

- 預設停用。設定 `agents.defaults.memorySearch.remote.batch.enabled = true` 以啟用大型語料庫索引（OpenAI、Gemini 和 Voyage）。
- 預設行為等待批次完成；若需要，調整 `remote.batch.wait`、`remote.batch.pollIntervalMs` 和 `remote.batch.timeoutMinutes`。
- 設定 `remote.batch.concurrency` 以控制我們並行提交多少個批次工作（預設：2）。
- 當 `memorySearch.provider = "openai"` 或 `"gemini"` 時，批次模式適用，並使用相應的 API key。
- Gemini 批次工作使用非同步 embeddings 批次端點，需要 Gemini Batch API 可用。

Why OpenAI batch is fast + cheap（為什麼 OpenAI 批次快速又便宜）：

- 對於大型回填，OpenAI 通常是我們支援的最快選項，因為我們可在單個批次工作中提交許多 embedding 請求，讓 OpenAI 非同步處理。
- OpenAI 為 Batch API 工作量提供折扣定價，因此大型索引執行通常比同步傳送相同請求便宜。
- 見 OpenAI Batch API 文檔和定價詳情：
  - [https://platform.openai.com/docs/api-reference/batch](https://platform.openai.com/docs/api-reference/batch)
  - [https://platform.openai.com/pricing](https://platform.openai.com/pricing)

Config example（配置範例）：

```json5
agents: {
  defaults: {
    memorySearch: {
      provider: "openai",
      model: "text-embedding-3-small",
      fallback: "openai",
      remote: {
        batch: { enabled: true, concurrency: 2 }
      },
      sync: { watch: true }
    }
  }
}
```

Tools（工具）：

- `memory_search` — 返回帶檔案 + 行範圍的片段。
- `memory_get` — 按路徑讀取記憶體檔案內容。

Local mode（本地模式）：

- 設定 `agents.defaults.memorySearch.provider = "local"`。
- 提供 `agents.defaults.memorySearch.local.modelPath`（GGUF 或 `hf:` URI）。
- 選用：設定 `agents.defaults.memorySearch.fallback = "none"` 以避免遠端備用。

### How the memory tools work（記憶體工具如何運作）

- `memory_search` 對 `MEMORY.md` + `memory/**/*.md` 的 Markdown 區塊進行語義搜尋（約 400 token 目標，80 token 重疊）。返回片段文字（上限約 700 字元）、檔案路徑、行範圍、評分、提供商/模型，以及我們是否從本地回退到遠端 embeddings。不返回完整檔案負載。
- `memory_get` 讀取特定記憶體 Markdown 檔案（工作區相對），選擇性地從起始行開始讀取 N 行。僅當在 `memorySearch.extraPaths` 中明確列出時，才允許 `MEMORY.md` / `memory/` 外的路徑。
- 僅當代理的 `memorySearch.enabled` 解析為 true 時，兩工具才啟用。

### What gets indexed（and when）（什麼被索引（以及何時））

- File type（檔案類型）：僅 Markdown（`MEMORY.md`、`memory/**/*.md`）。
- Index storage（索引儲存）：每代理 SQLite 於 `~/.openclaw/memory/<agentId>.sqlite`（透過 `agents.defaults.memorySearch.store.path` 可設定，支援 `{agentId}` token）。
- Freshness（新鮮度）：`MEMORY.md` + `memory/` 上的監視者標記索引髒值（防抖 1.5 秒）。同步安排在會話開始、搜尋時或間隔上執行，且非同步執行。會話轉錄使用 delta 閾值觸發背景同步。
- Reindex triggers（重新索引觸發器）：索引儲存 embedding **提供商/模型 + 端點指紋 + 區塊參數**。若其中任何改變，OpenClaw 自動重設並重新索引整個儲存。

### Hybrid search（混合搜尋）(BM25 + vector)

啟用時，OpenClaw 結合：

- **Vector similarity（向量相似度）**（語義匹配，措辭可不同）
- **BM25 keyword relevance（BM25 關鍵字相關性）**（精確 token，如 ID、環境變數、程式碼符號）

若你的平台無法使用全文搜尋，OpenClaw 回退到僅向量搜尋。

#### Why hybrid?（為什麼混合？）

向量搜尋擅長「這意味著相同的事」：

- 「Mac Studio gateway host」vs「執行 Gateway 的機器」
- 「debounce file updates」vs「避免每次寫入都索引」

但在精確、高訊號 token 上可能較弱：

- ID （`a828e60`、`b3b9895a…`）
- 程式碼符號（`memorySearch.query.hybrid`）
- 錯誤字串（「sqlite-vec unavailable」）

BM25（全文搜尋）相反：擅長精確 token，在釋義上較弱。
混合搜尋是務實的中間立場：**使用兩種檢索訊號**，以便你為「自然語言」查詢和「大海撈針」查詢都獲得好結果。

#### How we merge results（目前的設計）（我們如何合併結果（目前的設計））

實作草圖：

1. 從雙方檢索候選池：

- **Vector**：按餘弦相似度取前 `maxResults * candidateMultiplier` 個。
- **BM25**：按 FTS5 BM25 rank（越低越好）取前 `maxResults * candidateMultiplier` 個。

2. 將 BM25 rank 轉為 0..1-ish 評分：

- `textScore = 1 / (1 + max(0, bm25Rank))`

3. 按 chunk id 合併候選者，計算加權評分：

- `finalScore = vectorWeight * vectorScore + textWeight * textScore`

注意：

- `vectorWeight` + `textWeight` 在配置解析中正規化為 1.0，因此權重表現如百分比。
- 若 embeddings 不可用（或提供商返回零向量），我們仍執行 BM25 並返回關鍵字匹配。
- 若無法建立 FTS5，我們保持僅向量搜尋（無致命失敗）。

這不是「IR 理論完美」，但簡單、快速，傾向在真實備註上改善召回率/精確度。
若我們以後想變得更花俏，常見下一步是倒數排名融合 (RRF) 或評分正規化（min/max 或 z-score）在混合前。

#### Post-processing pipeline（後處理管線）

在向量和關鍵字評分合併後，兩個選用後處理階段在結果到達 agent 前精煉結果清單：

```
向量 + 關鍵字 → 加權合併 → 時間衰退 → 排序 → MMR → Top-K 結果
```

兩階段**預設關閉**，可獨立啟用。

#### MMR re-ranking（多樣性）

混合搜尋傳回結果時，多個區塊可能包含相似或重疊內容。
例如，搜尋「home network setup」可能傳回五個幾乎相同的片段，來自不同日期的筆記，都提及相同路由器設定。

**MMR（Maximal Marginal Relevance）** 重新排名結果以平衡相關性與多樣性，確保頂部結果涵蓋查詢的不同方面，而不是重複相同資訊。

運作方式：

1. 結果按其原始相關性評分（向量 + BM25 加權評分）。
2. MMR 迭代選取最大化的結果：`λ × 相關性 − (1−λ) × 選定的最大相似性`。
3. 結果之間的相似性使用符號化內容上的 Jaccard 文字相似性測量。

`lambda` 參數控制權衡：

- `lambda = 1.0` → 純相關性（無多樣性懲罰）
- `lambda = 0.0` → 最大多樣性（忽略相關性）
- 預設：`0.7`（平衡，略偏相關性）

**Example（範例）— query: "home network setup"**

給定這些記憶體檔案：

```
memory/2026-02-10.md  → "Configured Omada router, set VLAN 10 for IoT devices"
memory/2026-02-08.md  → "Configured Omada router, moved IoT to VLAN 10"
memory/2026-02-05.md  → "Set up AdGuard DNS on 192.168.10.2"
memory/network.md     → "Router: Omada ER605, AdGuard: 192.168.10.2, VLAN 10: IoT"
```

Without MMR（無 MMR）— 頂部 3 結果：

```
1. memory/2026-02-10.md  (score: 0.92)  ← router + VLAN
2. memory/2026-02-08.md  (score: 0.89)  ← router + VLAN（近似複製！）
3. memory/network.md     (score: 0.85)  ← 參考文檔
```

With MMR（λ=0.7）— 頂部 3 結果：

```
1. memory/2026-02-10.md  (score: 0.92)  ← router + VLAN
2. memory/network.md     (score: 0.85)  ← 參考文檔（多樣！）
3. memory/2026-02-05.md  (score: 0.78)  ← AdGuard DNS（多樣！）
```

Feb 8 的近似複製掉出，agent 獲得三個不同的資訊片段。

**When to enable（何時啟用）：** 若你注意 `memory_search` 傳回冗餘或近似複製片段，特別是日記檔案經常跨天重複相似資訊。

#### Temporal decay（時間衰退）（recency boost）

累積數百個日期檔案的 agent 隨時間增長。無衰退，六個月前的措辭良好筆記可超越昨天對相同主題的更新。

**Temporal decay**（時間衰退）基於每個結果的年齡將指數乘數應用於評分，以便最近記憶體自然排名更高，舊記憶體淡去：

```
decayedScore = score × e^(-λ × ageInDays)
```

其中 `λ = ln(2) / halfLifeDays`。

預設半衰期 30 天：

- 今天的筆記：**100%** 原始評分
- 7 天前：**~84%**
- 30 天前：**50%**
- 90 天前：**12.5%**
- 180 天前：**~1.6%**

**Evergreen files are never decayed（常青檔案永不衰退）：**

- `MEMORY.md`（根記憶體檔案）
- `memory/` 中非日期檔案（例如 `memory/projects.md`、`memory/network.md`）
- 這些包含應始終正常排名的持久參考資訊。

**Dated daily files（日期日誌檔案）** (`memory/YYYY-MM-DD.md`) 使用從檔案名稱提取的日期。
其他來源（例如會話轉錄）回退到檔案修改時間 (`mtime`)。

**Example（範例）— query: "what's Rod's work schedule?"**

給定這些記憶體檔案（今天是 Feb 10）：

```
memory/2025-09-15.md  → "Rod works Mon-Fri, standup at 10am, pairing at 2pm"  (148 days old)
memory/2026-02-10.md  → "Rod has standup at 14:15, 1:1 with Zeb at 14:45"    (today)
memory/2026-02-03.md  → "Rod started new team, standup moved to 14:15"        (7 days old)
```

Without decay（無衰退）：

```
1. memory/2025-09-15.md  (score: 0.91)  ← 最佳語義匹配，但陳舊！
2. memory/2026-02-10.md  (score: 0.82)
3. memory/2026-02-03.md  (score: 0.80)
```

With decay（halfLife=30）：

```
1. memory/2026-02-10.md  (score: 0.82 × 1.00 = 0.82)  ← 今天，無衰退
2. memory/2026-02-03.md  (score: 0.80 × 0.85 = 0.68)  ← 7 天，輕微衰退
3. memory/2025-09-15.md  (score: 0.91 × 0.03 = 0.03)  ← 148 天，幾乎消失
```

陳舊的 September 筆記掉到底部，儘管有最佳原始語義匹配。

**When to enable（何時啟用）：** 若你的 agent 有數月日誌，發現舊陳舊資訊超越最近上下文。30 天的半衰期在日記為重心的工作流程上表現良好；若你頻繁參考較舊筆記，增加它（例如 90 天）。

#### Configuration（配置）

兩功能在 `memorySearch.query.hybrid` 下配置：

```json5
agents: {
  defaults: {
    memorySearch: {
      query: {
        hybrid: {
          enabled: true,
          vectorWeight: 0.7,
          textWeight: 0.3,
          candidateMultiplier: 4,
          // 多樣性：降低冗餘結果
          mmr: {
            enabled: true,    // 預設：false
            lambda: 0.7       // 0 = 最大多樣性, 1 = 最大相關性
          },
          // 回顯性：提升較新記憶體
          temporalDecay: {
            enabled: true,    // 預設：false
            halfLifeDays: 30  // 評分每 30 天減半
          }
        }
      }
    }
  }
}
```

你可獨立啟用任一功能：

- **MMR only（僅 MMR）** — 有許多相似筆記但年齡無關時有用。
- **Temporal decay only（僅時間衰退）** — 當回顯性重要但結果已多樣化時有用。
- **Both（兩者）** — 對有大型、長期執行日誌歷史的 agent 推薦。

### Embedding cache（Embedding 快取）

OpenClaw 可在 SQLite 中快取**區塊 embeddings**，以便重新索引和頻繁更新（特別是會話轉錄）無須重新 embed 未改變的文字。

Config：

```json5
agents: {
  defaults: {
    memorySearch: {
      cache: {
        enabled: true,
        maxEntries: 50000
      }
    }
  }
}
```

### Session memory search（會話記憶體搜尋）（實驗性）

你可選擇對**會話轉錄**建立索引，並透過 `memory_search` 顯示它們。
這位在實驗性旗標後。

```json5
agents: {
  defaults: {
    memorySearch: {
      experimental: { sessionMemory: true },
      sources: ["memory", "sessions"]
    }
  }
}
```

注意：

- 會話索引是**選擇加入**（預設關閉）。
- 會話更新防抖及在跨 delta 閾值後**非同步建立索引**（盡力而為）。
- `memory_search` 永不阻塞索引；結果在背景同步完成前可略微陳舊。
- 結果仍僅含片段；`memory_get` 仍限於記憶體檔案。
- 會話索引按 agent 隔離（僅該 agent 的會話日誌被索引）。
- 會話日誌位於磁碟（`~/.openclaw/agents/<agentId>/sessions/*.jsonl`）。任何具檔案系統存取的程序/用戶可讀，故視磁碟存取為信任邊界。更嚴格隔離，在不同 OS 用戶或主機下執行 agent。

Delta thresholds（delta 閾值）（顯示預設）：

```json5
agents: {
  defaults: {
    memorySearch: {
      sync: {
        sessions: {
          deltaBytes: 100000,   // ~100 KB
          deltaMessages: 50     // JSONL 行
        }
      }
    }
  }
}
```

### SQLite vector acceleration（SQLite 向量加速）(sqlite-vec)

當 sqlite-vec 擴展可用時，OpenClaw 儲存 embeddings 於 SQLite 虛擬表（`vec0`）且在資料庫執行向量距離查詢。這在不將每個 embedding 載入 JS 的情況下保持搜尋快速。

Configuration（可選）：

```json5
agents: {
  defaults: {
    memorySearch: {
      store: {
        vector: {
          enabled: true,
          extensionPath: "/path/to/sqlite-vec"
        }
      }
    }
  }
}
```

注意：

- `enabled` 預設 true；停用時，搜尋回退到儲存 embeddings 上的程序內餘弦相似度。
- 若 sqlite-vec 擴展遺漏或載入失敗，OpenClaw 記錄錯誤並繼續 JS 備用（無向量表）。
- `extensionPath` 覆寫綁定 sqlite-vec 路徑（對自訂建置或非標準安裝位置有用）。

### Local embedding auto-download（本地 embedding 自動下載）

- 預設本地 embedding 模型：`hf:ggml-org/embeddinggemma-300m-qat-q8_0-GGUF/embeddinggemma-300m-qat-Q8_0.gguf` (~0.6 GB)。
- 當 `memorySearch.provider = "local"` 時，`node-llama-cpp` 解析 `modelPath`；若 GGUF 遺漏，**自動下載**到快取（或 `local.modelCacheDir` 若已設定），然後載入。下載在重試時繼續。
- 原生建置需求：執行 `pnpm approve-builds`，選 `node-llama-cpp`，然後 `pnpm rebuild node-llama-cpp`。
- 備用：若本地設定失敗且 `memorySearch.fallback = "openai"`，我們自動切換到遠端 embeddings（`openai/text-embedding-3-small` 除非覆寫）並記錄原因。

### Custom OpenAI-compatible endpoint example（自訂 OpenAI 相容端點範例）

```json5
agents: {
  defaults: {
    memorySearch: {
      provider: "openai",
      model: "text-embedding-3-small",
      remote: {
        baseUrl: "https://api.example.com/v1/",
        apiKey: "YOUR_REMOTE_API_KEY",
        headers: {
          "X-Organization": "org-id",
          "X-Project": "project-id"
        }
      }
    }
  }
}
```

注意：

- `remote.*` 優先於 `models.providers.openai.*`。
- `remote.headers` 與 OpenAI 標頭合併；衝突時遠端優先。省略 `remote.headers` 以使用 OpenAI 預設。
