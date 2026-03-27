---
summary: "Context engine：可插拔的上下文組裝、壓縮和子代理生命週期"
read_when:
  - 您想了解 OpenClaw 如何組裝模型上下文
  - 您在傳統引擎和外掛程式引擎之間切換
  - 您正在建立 context engine 外掛程式
title: "Context Engine（Context Engine）"
---

# Context Engine

一個 **context engine** 控制 OpenClaw 如何為每次執行建立模型上下文。
它決定要包含哪些訊息、如何摘要舊歷史記錄，以及如何
跨越子代理邊界管理上下文。

OpenClaw 提供內建的 `legacy` 引擎。外掛程式可以註冊
替代引擎，以取代活躍的 context-engine 生命週期。

## 快速開始

檢查哪個引擎處於活躍狀態：

```bash
openclaw doctor
# 或直接檢查設定：
cat ~/.openclaw/openclaw.json | jq '.plugins.slots.contextEngine'
```

### 安裝 context engine 外掛程式

Context engine 外掛程式像任何其他 OpenClaw 外掛程式一樣安裝。先安裝，
然後在 slot 中選擇引擎：

```bash
# 從 npm 安裝
openclaw plugins install @martian-engineering/lossless-claw

# 或從本地路徑安裝（用於開發）
openclaw plugins install -l ./my-context-engine
```

然後在您的設定中啟用外掛程式並將其選擇為活躍引擎：

```json5
// openclaw.json
{
  plugins: {
    slots: {
      contextEngine: "lossless-claw", // 必須符合外掛程式的已註冊引擎 id
    },
    entries: {
      "lossless-claw": {
        enabled: true,
        // 外掛程式特定設定在此處（參見外掛程式的文件）
      },
    },
  },
}
```

安裝並設定後重新啟動 gateway。

若要切換回內建引擎，將 `contextEngine` 設為 `"legacy"`（或
完全移除金鑰 — `"legacy"` 是預設值）。

## 運作方式

每當 OpenClaw 執行模型 prompt 時，context engine 在
四個生命週期點參與：

1. **Ingest** — 當新訊息新增到 session 時呼叫。引擎
   可以在其自己的資料存儲中存儲或索引訊息。
2. **Assemble** — 在每次模型執行前呼叫。引擎返回一個有序的
   訊息集合（和可選的 `systemPromptAddition`），適應
   token 預算。
3. **Compact** — 當上下文視窗滿時或使用者執行
   `/compact` 時呼叫。引擎摘要舊歷史記錄以釋放空間。
4. **After turn** — 在執行完成後呼叫。引擎可以持久化狀態，
   觸發背景壓縮，或更新索引。

### 子代理生命週期（選用）

OpenClaw 目前呼叫一個子代理生命週期 hook：

- **onSubagentEnded** — 當子代理 session 完成或被清除時清理。

`prepareSubagentSpawn` hook 是介面的一部分，供未來使用，但
執行時尚未叫用它。

### System prompt addition

`assemble` 方法可以返回一個 `systemPromptAddition` 字串。OpenClaw
將此加到執行的 system prompt 中。這讓引擎可以注入
動態召回指引、檢索指令或上下文感知提示
而無需靜態工作區檔案。

## 舊版引擎

內建的 `legacy` 引擎保留 OpenClaw 的原始行為：

- **Ingest**：無操作（session manager 直接處理訊息持久化）。
- **Assemble**：傳遞（執行時現有的 sanitize → validate → limit pipeline
  處理上下文組裝）。
- **Compact**：委託給內建摘要壓縮，這建立
  舊訊息的單一摘要並保持最近訊息完整。
- **After turn**：無操作。

舊版引擎不註冊 tool 或提供 `systemPromptAddition`。

當沒有設定 `plugins.slots.contextEngine`（或設為 `"legacy"`）時，
此引擎會自動使用。

## 外掛程式引擎

外掛程式可以使用外掛程式 API 註冊 context engine：

```ts
export default function register(api) {
  api.registerContextEngine("my-engine", () => ({
    info: {
      id: "my-engine",
      name: "My Context Engine",
      ownsCompaction: true,
    },

    async ingest({ sessionId, message, isHeartbeat }) {
      // 將訊息儲存在您的資料存儲中
      return { ingested: true };
    },

    async assemble({ sessionId, messages, tokenBudget }) {
      // 返回適應預算的訊息
      return {
        messages: buildContext(messages, tokenBudget),
        estimatedTokens: countTokens(messages),
        systemPromptAddition: "Use lcm_grep to search history...",
      };
    },

    async compact({ sessionId, force }) {
      // 摘要舊上下文
      return { ok: true, compacted: true };
    },
  }));
}
```

然後在設定中啟用它：

```json5
{
  plugins: {
    slots: {
      contextEngine: "my-engine",
    },
    entries: {
      "my-engine": {
        enabled: true,
      },
    },
  },
}
```

### ContextEngine 介面

必要的成員：

| 成員               | 類型 | 目的                                          |
| ------------------ | ---- | --------------------------------------------- |
| `info`             | 屬性 | 引擎 id、名稱、版本和是否擁有壓縮             |
| `ingest(params)`   | 方法 | 儲存單個訊息                                  |
| `assemble(params)` | 方法 | 為模型執行建立上下文（返回 `AssembleResult`） |
| `compact(params)`  | 方法 | 摘要/減少上下文                               |

`assemble` 返回一個 `AssembleResult`，包含：

- `messages` — 要發送給模型的有序訊息。
- `estimatedTokens`（必需，`number`）— 引擎對組裝上下文中總 token 數的估計。OpenClaw 使用它來進行壓縮閾值決定和診斷報告。
- `systemPromptAddition`（可選，`string`）— 加到 system prompt 前。

可選的成員：

| 成員                           | 類型 | 目的                                                                               |
| ------------------------------ | ---- | ---------------------------------------------------------------------------------- |
| `bootstrap(params)`            | 方法 | 為 session 初始化引擎狀態。當引擎首次看到 session 時呼叫一次（例如匯入歷史記錄）。 |
| `ingestBatch(params)`          | 方法 | 將完成的 turn 作為批次攝取。在執行完成後呼叫，同時含有該 turn 中的所有訊息。       |
| `afterTurn(params)`            | 方法 | 執行後生命週期工作（持久化狀態、觸發背景壓縮）。                                   |
| `prepareSubagentSpawn(params)` | 方法 | 為子 session 設定共享狀態。                                                        |
| `onSubagentEnded(params)`      | 方法 | 子代理結束後清理。                                                                 |
| `dispose()`                    | 方法 | 釋放資源。在 gateway 關閉或外掛程式重新載入期間呼叫 — 不是 per-session。           |

### ownsCompaction

`ownsCompaction` 控制 Pi 的內建嘗試中自動壓縮是否保持
為執行啟用：

- `true` — 引擎擁有壓縮行為。OpenClaw 禁用該執行的 Pi 內建
  自動壓縮，引擎的 `compact()` 實現負責
  `/compact`、溢出恢復壓縮和任何它想在 `afterTurn()` 中做的主動壓縮。
- `false` 或未設定 — Pi 的內建自動壓縮仍可能在 prompt
  執行期間執行，但活躍引擎的 `compact()` 方法仍會為
  `/compact` 和溢出恢復呼叫。

`ownsCompaction: false` 不表示 OpenClaw 自動回退到
舊版引擎的壓縮路徑。

這意味著有兩種有效的外掛程式模式：

- **擁有模式** — 實現您自己的壓縮演算法並設定
  `ownsCompaction: true`。
- **委託模式** — 設定 `ownsCompaction: false` 並讓 `compact()` 呼叫
  `delegateCompactionToRuntime(...)`，來自 `openclaw/plugin-sdk/core`，以使用
  OpenClaw 的內建壓縮行為。

無操作 `compact()` 對於活躍的非擁有引擎是不安全的，因為它
禁用了該引擎 slot 的正常 `/compact` 和溢出恢復壓縮路徑。

## 設定參考

```json5
{
  plugins: {
    slots: {
      // 選擇活躍的 context engine。預設值："legacy"。
      // 設為外掛程式 id 以使用外掛程式引擎。
      contextEngine: "legacy",
    },
  },
}
```

該 slot 在執行時是獨佔的 — 只有一個已註冊的 context engine
為給定的執行或壓縮操作解析。其他已啟用的
`kind: "context-engine"` 外掛程式仍可載入並執行其註冊
代碼；`plugins.slots.contextEngine` 只選擇當 OpenClaw 需要 context engine 時解析的已註冊引擎 id。

## 與壓縮和記憶的關係

- **Compaction** 是 context engine 的一個職責。舊版引擎
  委託給 OpenClaw 的內建摘要。外掛程式引擎可以實現
  任何壓縮策略（DAG 摘要、向量檢索等）。
- **Memory 外掛程式**（`plugins.slots.memory`）與 context engines 分開。
  Memory 外掛程式提供搜尋/檢索；context engines 控制
  模型看到的內容。它們可以協同工作 — context engine 可能在
  組裝時使用 memory 外掛程式資料。
- **Session pruning**（在記憶體中修剪舊工具結果）仍然執行
  無論哪個 context engine 活躍。

## 提示

- 使用 `openclaw doctor` 驗證您的引擎正確載入。
- 如果切換引擎，現有 session 繼續使用其當前歷史記錄。
  新引擎接管未來執行。
- 引擎錯誤被記錄並在診斷中顯示。如果外掛程式引擎
  無法註冊或選擇的引擎 id 無法解析，OpenClaw
  不會自動回退；執行失敗直到您修復外掛程式或
  將 `plugins.slots.contextEngine` 切換回 `"legacy"`。
- 對於開發，使用 `openclaw plugins install -l ./my-engine` 連結
  本地外掛程式目錄而無需複製。

另見：[Compaction](/zh-Hant/concepts/compaction)、[Context](/zh-Hant/concepts/context)、
[Plugins](/zh-Hant/tools/plugin)、[Plugin manifest](/zh-Hant/plugins/manifest)。
