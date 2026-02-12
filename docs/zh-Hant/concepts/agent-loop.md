---
title: "Agent Loop（Agent 迴圈）"
summary: "Agent 迴圈生命週期、串流和等待語義"
read_when:
  - 您需要了解 Agent 迴圈或生命週期事件的確切流程
---

# Agent Loop（OpenClaw）

Agent 迴圈是 Agent 的一次完整「真實」執行過程：輸入 → 上下文組裝 → 模型推理 → 工具執行 → 串流回覆 → 持久化。這是將訊息轉化為行動和最終回覆的主權路徑，同時保持會話狀態的一致性。

在 OpenClaw 中，迴圈是每個會話單個、序列化的執行，在模型思考、呼叫工具和串流輸出時發送生命週期和串流事件。本文件解釋了這個真實迴圈是如何端到端連接的。

## 進入點

- Gateway RPC：`agent` 和 `agent.wait`。
- CLI：`agent` 命令。

## 運作方式（高層級）

1. `agent` RPC 驗證參數、解析會話（sessionKey/sessionId）、持久化會話中繼資料，並立即返回 `{ runId, acceptedAt }`。
2. `agentCommand` 執行 Agent：
   - 解析模型 + 思考/詳細模式預設值
   - 載入技能快照
   - 呼叫 `runEmbeddedPiAgent` (pi-agent-core 執行環境)
   - 如果內嵌迴圈未發送，則發送 **lifecycle end/error**
3. `runEmbeddedPiAgent`：
   - 透過每會話 + 全域佇列序列化執行
   - 解析模型 + 驗證設定檔並建構 pi 會話
   - 訂閱 pi 事件並串流助手/工具增量
   - 強制執行逾時 -> 超過則中止執行
   - 返回負載 + 使用量中繼資料
4. `subscribeEmbeddedPiSession` 將 pi-agent-core 事件橋接到 OpenClaw `agent` 串流：
   - 工具事件 => `stream: "tool"`
   - 助手增量 => `stream: "assistant"`
   - 生命週期事件 => `stream: "lifecycle"` (`phase: "start" | "end" | "error"`)
5. `agent.wait` 使用 `waitForAgentJob`：
   - 等待 `runId` 的 **lifecycle end/error**
   - 返回 `{ status: ok|error|timeout, startedAt, endedAt, error? }`

## 佇列與並行性

- 執行按會話鍵（會話車道）以及可選的全域車道進行序列化。
- 這可以防止工具/會話競爭，並保持會話歷史一致。
- 傳訊頻道可以選擇佇列模式（collect/steer/followup），該模式會餵入此車道系統。請參閱 [Command Queue](/zh-Hant/concepts/queue)。

## 會話與工作區準備

- 工作區會被解析並建立；沙盒化執行可能會重定向到沙盒工作區根路徑。
- 技能會被載入（或從快照重用）並注入環境與提示詞中。
- 啟動/上下文檔案會被解析並注入系統提示詞報告。
- 會話寫入鎖被獲取；在串流前開啟並準備 `SessionManager`。

## 提示詞組裝與系統提示詞

- 系統提示詞由 OpenClaw 基礎提示詞、技能提示詞、啟動上下文和每次執行的覆寫組裝而成。
- 模型特定的限制和壓縮保留權杖會被強制執行。
- 請參閱 [System Prompt](/zh-Hant/concepts/system-prompt) 了解模型看到的內容。

## 鉤子點（您可以攔截的地方）

OpenClaw 有兩種鉤子系統：

- **內部鉤子** (Gateway hooks)：用於命令和生命週期事件的事件驅動腳本。
- **外掛鉤子**：Agent/工具生命週期和 Gateway 管線中的擴充點。

### 內部鉤子 (Gateway hooks)

- **`agent:bootstrap`**：在最終確定系統提示詞前建立啟動檔案時執行。用於新增/移除啟動上下文檔案。
- **命令鉤子**：`/new`、`/reset`、`/stop` 和其他命令事件。

請參閱 [Hooks](/zh-Hant/automation/hooks) 了解設定與範例。

### 外掛鉤子（Agent + Gateway 生命週期）

這些運行在 Agent 迴圈或 Gateway 管線中：

- **`before_agent_start`**：在執行開始前注入上下文或覆寫系統提示詞。
- **`agent_end`**：完成後檢查最終訊息列表和執行中繼資料。
- **`before_compaction` / `after_compaction`**：觀察或標註壓縮週期。
- **`before_tool_call` / `after_tool_call`**：攔截工具參數/結果。
- **`tool_result_persist`**：在工具結果寫入會話轉錄前，同步對其進行轉換。
- **`message_received` / `message_sending` / `message_sent`**：入站 + 出站訊息鉤子。
- **`session_start` / `session_end`**：會話生命週期邊界。
- **`gateway_start` / `gateway_stop`**：Gateway 生命週期事件。

請參閱 [Plugins](/zh-Hant/tools/plugin#plugin-hooks) 了解鉤子 API 和註冊細節。

## 串流與部分回覆

- 助手增量從 pi-agent-core 串流傳輸，並作為 `assistant` 事件發送。
- 區塊串流可以在 `text_end` 或 `message_end` 時發送部分回覆。
- 推理 (Reasoning) 串流可以作為單獨的串流或區塊回覆發送。
- 請參閱 [Streaming](/zh-Hant/concepts/streaming) 了解分塊和區塊回覆行為。

## 工具執行與傳訊工具

- 工具開始/更新/結束事件在 `tool` 串流中發送。
- 工具結果在記錄/發送前會針對大小和圖片負載進行清理。
- 傳訊工具的發送會被追蹤，以抑制重複的助手確認訊息。

## 回覆整形與抑制

- 最終負載由以下內容組裝而成：
  - 助手文字（和可選的推理過程）
  - 行內工具摘要（詳細模式 + 允許時）
  - 模型出錯時的助手錯誤文字
- `NO_REPLY` 被視為靜默權杖，並從傳出的負載中過濾掉。
- 傳訊工具的重複內容會從最終負載列表中移除。
- 如果沒有剩餘可渲染的負載且工具出錯，則發送回退工具錯誤回覆（除非傳訊工具已發送了使用者可見的回覆）。

## 壓縮與重試

- 自動壓縮會發送 `compaction` 串流事件並可能觸發重試。
- 重試時，記憶體緩衝區和工具摘要會重置以避免重複輸出。
- 請參閱 [Compaction](/zh-Hant/concepts/compaction) 了解壓縮管線。

## 事件串流（目前）

- `lifecycle`：由 `subscribeEmbeddedPiSession` 發送（或作為 `agentCommand` 的回退）
- `assistant`：來自 pi-agent-core 的串流增量
- `tool`：來自 pi-agent-core 的串流工具事件

## 聊天頻道處理

- 助手增量被緩衝到聊天的 `delta` 訊息中。
- 在 **lifecycle end/error** 時發送聊天的 `final` 訊息。

## 逾時

- `agent.wait` 預設：30 秒（僅等待）。`timeoutMs` 參數可覆寫。
- Agent 執行時間：`agents.defaults.timeoutSeconds` 預設 600 秒；在 `runEmbeddedPiAgent` 的中止計時器中強制執行。

## 可能提前結束的地方

- Agent 逾時（中止）
- AbortSignal（取消）
- Gateway 斷開連接或 RPC 逾時
- `agent.wait` 逾時（僅等待，不停止 Agent）
