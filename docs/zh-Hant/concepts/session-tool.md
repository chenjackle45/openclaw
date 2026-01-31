---
title: "Session tool(會話工具)"
summary: "用於列出會話、獲取歷史記錄以及發送跨會話訊息的代理會話工具"
read_when:
  - 新增或修改會話工具
---

# Session Tools（會話工具）

目標：一套簡單、難以誤用的工具集，讓代理可以列出會話、獲取歷史記錄以及向另一個會話發送訊息。

## 工具名稱
- `sessions_list`
- `sessions_history`
- `sessions_send`
- `sessions_spawn`

## 關鍵模型
- 主直接聊天桶 (Main direct chat bucket) 的字面鍵始終是 `"main"`（解析為目前代理的主會話鍵）。
- 群組聊天使用 `agent:<agentId>:<channel>:group:<id>` 或 `agent:<agentId>:<channel>:channel:<id>`（傳遞完整鍵）。
- Cron 任務使用 `cron:<job.id>`。
- 鉤子 (Hooks) 使用 `hook:<uuid>`（除非另有設定）。
- 節點 (Node) 會話使用 `node-<nodeId>`（除非另有設定）。

`global` 和 `unknown` 是保留值，絕不會被列出。如果 `session.scope = "global"`，我們會將其別名設為所有工具的 `main`，因此呼叫方絕不會看到 `global`。

## sessions_list
將會話列為行陣列。

參數：
- `kinds?: string[]` 過濾器：`"main" | "group" | "cron" | "hook" | "node" | "other"` 之一。
- `limit?: number` 最大行數（預設：伺服器預設值，限制為 200 行）。
- `activeMinutes?: number` 僅包含在 N 分鐘內有更新的會話。
- `messageLimit?: number` 0 = 不含訊息（預設）；>0 = 包含最後 N 條訊息。

行為：
- `messageLimit > 0` 會獲取每個會話的 `chat.history` 並包含最後 N 條訊息。
- 工具結果會在列表輸出中被過濾掉；若要查看工具訊息，請使用 `sessions_history`。
- 在**沙盒化**代理會話中執行時，會話工具預設僅具備**生成後可見性 (spawned-only visibility)**（見下文）。

## sessions_history
獲取單個會話的轉錄記錄。

參數：
- `sessionKey`（必填；接受會話鍵或來自 `sessions_list` 的 `sessionId`）。
- `limit?: number` 最大訊息數。
- `includeTools?: boolean`（預設為 false）。

行為：
- `includeTools=false` 會過濾掉 `role: "toolResult"` 的訊息。
- 以原始轉錄格式返回訊息陣列。

## sessions_send
向另一個會話發送訊息。

參數：
- `sessionKey`（必填；接受會話鍵或來自 `sessions_list` 的 `sessionId`）。
- `message`（必填）。
- `timeoutSeconds?: number`（預設 >0；0 = 發送後不理）。

行為：
- `timeoutSeconds = 0`：加入佇列並返回 `{ runId, status: "accepted" }`。
- `timeoutSeconds > 0`：等待最多 N 秒直到完成，然後返回 `{ runId, status: "ok", reply }`。
- 代理對代理 (Agent-to-agent) 訊息上下文會注入到主要運行中。
- 在主要運行完成後，OpenClaw 會執行一個**回覆循環 (reply-back loop)**：
  - 第 2 輪及之後會在發起請求與目標代理之間輪流。
  - 回覆 `REPLY_SKIP` 以停止對話。
  - 最大輪數為 5 輪（可設定）。
- 循環結束後執行**公告步驟 (announce step)**：
  - 任何非 `ANNOUNCE_SKIP` 的回覆都會被發送到目標頻道。

## 頻道欄位 (Channel Field)
- 對於群組，`channel` 是會話條目上記錄的頻道。
- 對於直接聊天，`channel` 從 `lastChannel` 映射而來。
- 對於 cron/hook/node，`channel` 為 `internal`。

## sessions_spawn
在隔離的會話中生成子代理運行，並將結果公告回請求者的聊天頻道。

參數：
- `task`（必填）。
- `label?`（選填；用於日誌/UI）。
- `agentId?`（選填；如果允許，在另一個代理 ID 下生成）。
- `model?`（選填；覆寫子代理的模型）。
- `runTimeoutSeconds?`（預設為 0；若設定，則在 N 秒後中止子代理運行）。
- `cleanup?` (`delete|keep`，預設為 `keep`)。

行為：
- 啟動一個新的 `agent:<agentId>:subagent:<uuid>` 會話，且 `deliver: false`。
- 子代理預設擁有完整工具集，但**不含會話工具**。
- 子代理不允許調用 `sessions_spawn`（不支援巢狀生成）。
- 始終是非阻塞的：立即返回 `{ status: "accepted", runId, childSessionKey }`。
- 完成後，OpenClaw 執行子代理**公告步驟**並將結果發送到請求者的聊天頻道。
- 專門回覆 `ANNOUNCE_SKIP` 可保持靜默。

## 沙盒會話可見性
沙盒化會話可以使用會話工具，但預設情況下它們只能看到透過 `sessions_spawn` 生成的會話。

組態：
```json5
{
  agents: {
    defaults: {
      sandbox: {
        // 預設為 "spawned"
        sessionToolsVisibility: "spawned" // 或 "all"
      }
    }
  }
}
```
