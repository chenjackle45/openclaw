---
title: "Memory(記憶)"
summary: "OpenClaw 記憶如何運作（工作區檔案 + 自動記憶體刷新）"
read_when:
  - 您想要記憶檔案佈局和工作流程
  - 您想要調整自動壓縮前記憶體刷新
---
# Memory（記憶）

OpenClaw 記憶是**代理工作區中的純 Markdown**。檔案是真實來源；模型只「記得」寫入磁碟的內容。

記憶搜尋工具由活動的記憶外掛提供（預設為 `memory-core`）。使用 `plugins.slots.memory = "none"` 停用記憶外掛。

## 記憶檔案 (Markdown)

預設工作區佈局使用兩個記憶層：

- `memory/YYYY-MM-DD.md`
  - 每日日誌（僅追加）。
  - 在會話開始時讀取今天 + 昨天。
- `MEMORY.md`（可選）
  - 精選的長期記憶。
  - **僅在主私人會話中載入**（絕不在群組上下文中載入）。

這些檔案位於工作區下（`agents.defaults.workspace`，預設為 `~/.openclaw/workspace`）。請參閱 [代理工作區](/concepts/agent-workspace) 了解完整佈局。

## 何時寫入記憶

- 決策、偏好和持久事實進入 `MEMORY.md`。
- 日常備註和執行上下文進入 `memory/YYYY-MM-DD.md`。
- 如果有人說「記住這個」，請寫下來（不要保留在 RAM 中）。
- 這個領域仍在發展中。提醒模型儲存記憶是有幫助的；它會知道該怎麼做。
- 如果您想讓某件事固定下來，**要求機器人將其寫入**記憶中。

## 自動記憶體刷新（壓縮前 ping）

當會話**接近自動壓縮**時，OpenClaw 會觸發一個**靜默、代理式輪次**，提醒模型在上下文被壓縮**之前**寫入持久記憶。預設提示明確指出模型*可以回覆*，但通常 `NO_REPLY` 是正確的回應，這樣使用者就不會看到這個輪次。

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
          prompt: "Write any lasting notes to memory/YYYY-MM-DD.md; reply with NO_REPLY if nothing to store."
        }
      }
    }
  }
}
```

詳情：
- **軟閾值**：當會話 token 估計超過 `contextWindow - reserveTokensFloor - softThresholdTokens` 時觸發刷新。
- 預設**靜默**：提示包含 `NO_REPLY` 以便不交付任何內容。
- **兩個提示**：一個使用者提示加上一個系統提示追加提醒。
- **每個壓縮週期一次刷新**（在 `sessions.json` 中追蹤）。
- **工作區必須可寫**：如果會話以 `workspaceAccess: "ro"` 或 `"none"` 在沙盒中運行，則跳過刷新。

有關完整的壓縮生命週期，請參閱 [會話管理 + 壓縮](/reference/session-management-compaction)。

## 向量記憶搜尋

OpenClaw 可以對 `MEMORY.md` 和 `memory/*.md`（加上您選擇加入的任何額外目錄或檔案）建立一個小型向量索引，以便語義查詢可以找到相關備註，即使措辭不同。

預設值：
- 預設啟用。
- 觀察記憶檔案的更改（防抖）。
- 預設使用遠端 embeddings。如果未設定 `memorySearch.provider`，OpenClaw 會自動選擇：
  1. 如果配置了 `memorySearch.local.modelPath` 且檔案存在，則使用 `local`。
  2. 如果可以解析 OpenAI 金鑰，則使用 `openai`。
  3. 如果可以解析 Gemini 金鑰，則使用 `gemini`。
  4. 否則，在配置之前，記憶搜尋保持停用狀態。
- 本地模式使用 node-llama-cpp，可能需要 `pnpm approve-builds`。
- 使用 sqlite-vec（可用時）來加速 SQLite 內部的向量搜尋。

遠端 embeddings **需要** embedding 供應商的 API 金鑰。OpenClaw 從身份驗證設定檔、`models.providers.*.apiKey` 或環境變數中解析金鑰。Codex OAuth 僅涵蓋聊天/補全，並**不**滿足記憶搜尋的 embeddings。對於 Gemini，使用 `GEMINI_API_KEY` 或 `models.providers.google.apiKey`。當使用自訂的 OpenAI 相容端點時，設定 `memorySearch.remote.apiKey`（以及可選的 `memorySearch.remote.headers`）。

### 額外記憶路徑

如果您想對預設工作區佈局之外的 Markdown 檔案建立索引，請新增明確路徑：

```json5
agents: {
  defaults: {
    memorySearch: {
      extraPaths: ["../team-docs", "/srv/shared-notes/overview.md"]
    }
  }
}
```

備註：
- 路徑可以是絕對路徑或相對於工作區的路徑。
- 遞迴掃描目錄尋找 `.md` 檔案。
- 僅對 Markdown 檔案建立索引。
- 符號連結會被忽略（檔案或目錄）。

### Gemini embeddings（原生）

將供應商設定為 `gemini` 以直接使用 Gemini embeddings API：

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

備註：
- `remote.baseUrl` 是可選的（預設為 Gemini API 基準 URL）。
- `remote.headers` 讓您在需要時新增額外標頭。
- 預設模型：`gemini-embedding-001`。

如果您想使用**自訂的 OpenAI 相容端點**（OpenRouter、vLLM 或代理），您可以使用 OpenAI 供應商的 `remote` 配置：

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

如果您不想設定 API 金鑰，請使用 `memorySearch.provider = "local"` 或設定 `memorySearch.fallback = "none"`。

回退機制：
- `memorySearch.fallback` 可以是 `openai`、`gemini`、`local` 或 `none`。
- 回退供應商僅在主要 embedding 供應商失敗時使用。

批次索引（OpenAI + Gemini）：
- 對於 OpenAI 和 Gemini embeddings，預設啟用。將 `agents.defaults.memorySearch.remote.batch.enabled = false` 設為停用。
- 預設行為是等待批次完成；如果需要，請調整 `remote.batch.wait`、`remote.batch.pollIntervalMs` 和 `remote.batch.timeoutMinutes`。
- 設定 `remote.batch.concurrency` 以控制我們並行提交多少個批次工作（預設：2）。
- 當 `memorySearch.provider = "openai"` 或 `"gemini"` 時適用批次模式，並使用相應的 API 金鑰。
- Gemini 批次工作使用非同步 embeddings 批次端點，需要 Gemini Batch API 可用。

為什麼 OpenAI 批次快速又便宜：
- 對於大型回填，OpenAI 通常是我們支援的最快選項，因為我們可以在單個批次工作中提交許多 embedding 請求，讓 OpenAI 非同步處理。
- OpenAI 為批次 API 工作量提供折扣定價，因此大型索引運行的通常比同步發送相同請求便宜。
- 有關詳情，請參閱 OpenAI 批次 API 文檔和定價：
  - https://platform.openai.com/docs/api-reference/batch
  - https://platform.openai.com/pricing

配置範例：

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

工具：
- `memory_search` — 返回帶有檔案 + 行範圍的程式碼片段。
- `memory_get` — 按路徑讀取記憶檔案內容。

本地模式：
- 將 `agents.defaults.memorySearch.provider = "local"`。
- 提供 `agents.defaults.memorySearch.local.modelPath`（GGUF 或 `hf:` URI）。
- 可選：將 `agents.defaults.memorySearch.fallback = "none"` 設為避免遠端回退。

### 記憶工具如何運作

- `memory_search` 從 `MEMORY.md` + `memory/**/*.md` 對 Markdown 區塊進行語義搜尋（目標約 400 token，80 token 重疊）。它返回片段文字（上限約 700 字元）、檔案路徑、行範圍、評分、供應商/模型，以及我們是否從本地回退到遠端 embeddings。不返回完整的檔案負載。
- `memory_get` 讀取特定的記憶 Markdown 檔案（相對於工作區），可選地從起始行開始讀取 N 行。僅當在 `memorySearch.extraPaths` 中明確列出時，才允許 `MEMORY.md` / `memory/` 之外的路徑。
- 僅當代理的 `memorySearch.enabled` 解析為 true 時，這兩個工具才會啟用。

### 什麼被建立索引（以及何時）

- 檔案類型：僅 Markdown（`MEMORY.md`、`memory/**/*.md`，加上 `memorySearch.extraPaths` 下的任何 `.md` 檔案）。
- 索引儲存：每代理 SQLite 位元於 `~/.openclaw/memory/<agentId>.sqlite`（可透過 `agents.defaults.memorySearch.store.path` 配置，支援 `{agentId}` 權杖）。
- 新鮮度：`MEMORY.md`、`memory/` 和 `memorySearch.extraPaths` 上的觀察者將索引標記為髒值（防抖 1.5 秒）。同步安排在會話開始、搜索或間隔時運行，並非同步執行。會話轉錄使用增量閾值來觸發背景同步。
- 重新索引觸發器：索引儲存了 embedding **供應商/模型 + 端點指紋 + 區塊參數**。如果其中任何一個發生變化，OpenClaw 會自動重置並重新索引整個存儲。

### 混合搜尋 (BM25 + 向量)

啟用時，OpenClaw 結合：
- **向量相似度**（語義匹配，措辭可以不同）
- **BM25 關鍵字相關性**（精確權杖，如 ID、環境變數、程式碼符號）

如果您的平台無法使用全文搜索，OpenClaw 會回退到僅向量搜尋。

#### 為什麼要混合？

向量搜尋非常擅長「這意味著同樣的事情」：
- 「Mac Studio gateway host」vs 「運行 gateway 的機器」
- 「debounce file updates」vs 「避免每次寫入都建立索引」

但它在精確的、高訊號權杖方面可能較弱：
- ID (`a828e60`, `b3b9895a…`)
- 程式碼符號 (`memorySearch.query.hybrid`)
- 錯誤字串 (「sqlite-vec unavailable」)

BM25（全文搜尋）則相反：擅長精確權杖，在轉述方面較弱。
混合搜尋是務實的中間立場：**使用兩種檢索訊號**，以便您可以為「自然語言」查詢和「大海撈針」查詢都獲得良好的結果。

#### 我們如何合併結果（目前的設計）

實作草圖：

1) 從雙方檢索候選池：
- **向量**：按餘弦相似度取前 `maxResults * candidateMultiplier` 個。
- **BM25**：按 FTS5 BM25 排名（越低越好）取前 `maxResults * candidateMultiplier` 個。

2) 將 BM25 排名轉換為 0..1 左右的評分：
- `textScore = 1 / (1 + max(0, bm25Rank))`

3) 按區塊 id 合併候選者並計算加權評分：
- `finalScore = vectorWeight * vectorScore + textWeight * textScore`

備註：
- `vectorWeight` + `textWeight` 在配置解析中被正規化為 1.0，因此權重的表現就像百分比。
- 如果 embeddings 不可用（或供應商返回零向量），我們仍會運行 BM25 並返回關鍵字匹配。
- 如果無法建立 FTS5，我們會保持僅向量搜尋（不會發生致命失敗）。

這並非「IR 理論上的完美」，但它簡單、快速，並且傾向於提高真實備註的召回率/精確度。
如果我們以後想變得更華麗，常見的下一步是在混合之前進行倒數排名融合 (RRF) 或評分正規化（最小/最大或 z-評分）。

配置：

```json5
agents: {
  defaults: {
    memorySearch: {
      query: {
        hybrid: {
          enabled: true,
          vectorWeight: 0.7,
          textWeight: 0.3,
          candidateMultiplier: 4
        }
      }
    }
  }
}
```

### Embedding 快取

OpenClaw 可以將**區塊 embeddings** 快取在 SQLite 中，以便重新索引和頻繁更新（特別是會話轉錄）不會重新 embed 未更改的文字。

配置：

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

### 會話記憶搜尋（實驗性）

您可以選擇對**會話轉錄**建立索引，並透過 `memory_search` 顯示它們。
這被放在實驗性標記之後。

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

備註：
- 會話索引是**選擇性加入**（預設關閉）。
- 會話更新會進行防抖處理，並在跨增量閾值後**非同步建立索引**（盡力而為）。
- `memory_search` 從不阻塞索引；在背景同步完成之前，結果可能略微陳舊。
- 結果仍僅包含片段；`memory_get` 仍僅限於記憶檔案。
- 會話索引按代理隔離（僅對該代理的會話日誌建立索引）。
- 會話日誌位元於磁碟上 (`~/.openclaw/agents/<agentId>/sessions/*.jsonl`)。任何具有檔案系統存取權限的程序/使用者都可以讀取它們，因此請將磁碟存取權限視為信任邊界。對於更嚴格的隔離，請在不同的作業系統使用者或主機下運行代理。

增量閾值（顯示預設值）：

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

### SQLite 向量加速 (sqlite-vec)

當 sqlite-vec 擴展可用時，OpenClaw 將 embeddings 儲存在 SQLite 虛擬表 (`vec0`) 中，並在資料庫中執行向量距離查詢。這可以在不將每個 embedding 載入到 JS 的情況下保持搜尋快速。

配置（可選）：

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

備註：
- `enabled` 預設為 true；停用時，搜尋會回退到對儲存的 embeddings 進行程序內餘弦相似度計算。
- 如果 sqlite-vec 擴展開遺失或載入失敗，OpenClaw 會記錄錯誤並繼續執行 JS 回退（無向量表）。
- `extensionPath` 會覆寫綁定的 sqlite-vec 路徑（對自訂建置或非標準安裝位置有用）。

### 本地 embedding 自動下載

- 預設本地 embedding 模型：`hf:ggml-org/embeddinggemma-300M-GGUF/embeddinggemma-300M-Q8_0.gguf` (~0.6 GB)。
- 當 `memorySearch.provider = "local"` 時，`node-llama-cpp` 會解析 `modelPath`；如果 GGUF 遺漏，它會**自動下載**到快取（或 `local.modelCacheDir`，如果已設定），然後載入它。下載在重試時恢復。
- 原生建置要求：運行 `pnpm approve-builds`，選擇 `node-llama-cpp`，然後運行 `pnpm rebuild node-llama-cpp`。
- 回退：如果本地設定失敗且 `memorySearch.fallback = "openai"`，我們會自動切換到遠端 embeddings（除非覆寫，否則為 `openai/text-embedding-3-small`）並記錄原因。

### 自訂 OpenAI 相容端點範例

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

備註：
- `remote.*` 優先於 `models.providers.openai.*`。
- `remote.headers` 與 OpenAI 標頭合併；在金鑰衝突時遠端優先。省略 `remote.headers` 以使用 OpenAI 預設值。
