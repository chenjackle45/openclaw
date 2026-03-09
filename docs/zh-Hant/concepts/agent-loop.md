---
summary: "Agent 迴圈生命週期、串流和等待語義"
read_when:
  - 您需要了解 Agent 迴圈或生命週期事件的確切流程
title: "Agent Loop（Agent 迴圈）"
---

# Agent Loop（OpenClaw）

Agentic 迴圈是 agent 的完整「真實」執行過程：接收 → 上下文組裝 → 模型推理 → 工具執行 → 串流回覆 → 持久化。這是將訊息轉化為動作和最終回覆的權威路徑，同時保持工作階段狀態一致。

在 OpenClaw 中，一個迴圈是每個工作階段的單一、序列化執行，在模型思考、呼叫工具和串流輸出時發出生命週期和串流事件。本文件說明該真實迴圈如何端到端串接。

## 進入點

- Gateway RPC：`agent` 和 `agent.wait`。
- CLI：`agent` 指令。

## 工作原理（高層次）

1. `agent` RPC 驗證參數，解析工作階段（sessionKey/sessionId），持久化工作階段 metadata，立即返回 `{ runId, acceptedAt }`。
2. `agentCommand` 執行 agent：
   - 解析模型 + thinking/verbose 預設
   - 載入技能快照
   - 呼叫 `runEmbeddedPiAgent`（pi-agent-core 執行時）
   - 若嵌入式迴圈未發出生命週期 end/error，則發出**生命週期 end/error**
3. `runEmbeddedPiAgent`：
   - 透過每個工作階段 + 全域佇列序列化執行
   - 解析模型 + 驗證設定檔並建立 pi 工作階段
   - 訂閱 pi 事件並串流助理/工具 delta
   - 強制執行逾時 -> 超時時中止執行
   - 返回 payload + 使用 metadata
4. `subscribeEmbeddedPiSession` 將 pi-agent-core 事件橋接到 OpenClaw `agent` 串流：
   - 工具事件 => `stream: "tool"`
   - 助理 delta => `stream: "assistant"`
   - 生命週期事件 => `stream: "lifecycle"`（`phase: "start" | "end" | "error"`）
5. `agent.wait` 使用 `waitForAgentJob`：
   - 等待 `runId` 的**生命週期 end/error**
   - 返回 `{ status: ok|error|timeout, startedAt, endedAt, error? }`

## 佇列 + 並發

- 執行按工作階段金鑰（工作階段通道）序列化，並可選擇透過全域通道。
- 這防止工具/工作階段競爭並保持工作階段歷史一致。
- 訊息頻道可以選擇佇列模式（collect/steer/followup）來饋送這個通道系統。
  請參閱 [Command Queue](/zh-Hant/concepts/queue)。

## 工作階段 + 工作區準備

- 工作區被解析並建立；沙盒執行可能重定向到沙盒工作區根目錄。
- 技能被載入（或從快照重用）並注入到環境和 prompt 中。
- Bootstrap/上下文檔案被解析並注入到 system prompt 報告中。
- 獲取工作階段寫入鎖；`SessionManager` 在串流前開啟並準備。

## Prompt 組裝 + system prompt

- System prompt 由 OpenClaw 的基礎 prompt、技能 prompt、bootstrap 上下文和每執行覆蓋建構。
- 強制執行模型特定限制和壓縮保留 token。
- 請參閱 [System prompt](/zh-Hant/concepts/system-prompt) 了解模型看到什麼。

## Hook 點（可以攔截的地方）

OpenClaw 有兩個 hook 系統：

- **內部 hooks**（Gateway hooks）：用於指令和生命週期事件的事件驅動指令碼。
- **外掛程式 hooks**：agent/工具生命週期和 gateway 管線中的擴展點。

### 內部 hooks（Gateway hooks）

- **`agent:bootstrap`**：在 system prompt 最終確定前建構 bootstrap 檔案時執行。
  用於新增/移除 bootstrap 上下文檔案。
- **指令 hooks**：`/new`、`/reset`、`/stop` 和其他指令事件（見 Hooks 文件）。

請參閱 [Hooks](/zh-Hant/automation/hooks) 了解設定和範例。

### 外掛程式 hooks（agent + gateway 生命週期）

這些在 agent 迴圈或 gateway 管線內執行：

- **`before_model_resolve`**：在 pre-session（無 `messages`）執行，以在模型解析前確定性覆蓋 provider/模型。
- **`before_prompt_build`**：在工作階段載入後（帶有 `messages`）執行，在 prompt 提交前注入 `prependContext`、`systemPrompt`、`prependSystemContext` 或 `appendSystemContext`。對每回合動態文字使用 `prependContext`，對應在 system prompt 空間的穩定指引使用 system-context 欄位。
- **`before_agent_start`**：舊版相容 hook，可能在任一階段執行；優先使用上面的明確 hooks。
- **`agent_end`**：在完成後檢查最終訊息列表和執行 metadata。
- **`before_compaction` / `after_compaction`**：觀察或標註壓縮週期。
- **`before_tool_call` / `after_tool_call`**：攔截工具參數/結果。
- **`tool_result_persist`**：在工具結果寫入工作階段轉錄前同步轉換它們。
- **`message_received` / `message_sending` / `message_sent`**：入站 + 出站訊息 hooks。
- **`session_start` / `session_end`**：工作階段生命週期邊界。
- **`gateway_start` / `gateway_stop`**：gateway 生命週期事件。

請參閱 [Plugins](/zh-Hant/tools/plugin#plugin-hooks) 了解 hook API 和註冊詳情。

## 串流 + 部分回覆

- 助理 delta 從 pi-agent-core 串流並作為 `assistant` 事件發出。
- 區塊串流可以在 `text_end` 或 `message_end` 時發出部分回覆。
- 推理串流可以作為單獨串流或區塊回覆發出。
- 請參閱 [Streaming](/zh-Hant/concepts/streaming) 了解分塊和區塊回覆行為。

## 工具執行 + 訊息工具

- 工具 start/update/end 事件在 `tool` 串流上發出。
- 工具結果在記錄/發出前對大小和圖片 payload 進行清理。
- 訊息工具傳送被追蹤以抑制重複的助理確認。

## 回覆塑形 + 抑制

- 最終 payload 從以下組裝：
  - 助理文字（和選用推理）
  - 內聯工具摘要（當 verbose + 允許時）
  - 當模型出錯時的助理錯誤文字
- `NO_REPLY` 被視為靜默 token 並從傳出 payload 過濾。
- 訊息工具重複從最終 payload 列表移除。
- 若沒有可渲染的 payload 且工具出錯，會發出備用工具錯誤回覆
  （除非訊息工具已傳送了用戶可見的回覆）。

## 壓縮 + 重試

- 自動壓縮發出 `compaction` 串流事件並可觸發重試。
- 重試時，記憶體緩衝區和工具摘要被重置以避免重複輸出。
- 請參閱 [Compaction](/zh-Hant/concepts/compaction) 了解壓縮管線。

## 事件串流（當前）

- `lifecycle`：由 `subscribeEmbeddedPiSession` 發出（以及由 `agentCommand` 作為備用）
- `assistant`：從 pi-agent-core 串流的 delta
- `tool`：從 pi-agent-core 串流的工具事件

## 聊天頻道處理

- 助理 delta 被緩衝到聊天 `delta` 訊息中。
- 在**生命週期 end/error** 時發出聊天 `final`。

## 逾時

- `agent.wait` 預設：30 秒（僅等待）。`timeoutMs` 參數覆蓋。
- Agent 執行時：`agents.defaults.timeoutSeconds` 預設 600 秒；在 `runEmbeddedPiAgent` 中透過中止計時器強制執行。

## 可能提前結束的地方

- Agent 逾時（中止）
- AbortSignal（取消）
- Gateway 斷開或 RPC 逾時
- `agent.wait` 逾時（僅等待，不停止 agent）
