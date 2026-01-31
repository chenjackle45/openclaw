---
title: "Queue(佇列)"
summary: "序列化入站自動回覆運行的命令佇列設計"
read_when:
  - 更改自動回覆執行或並行性
---
# Command Queue（命令佇列，2026-01-16）

我們透過一個小型程序內佇列序列化入站自動回覆運行（所有頻道），以防止多個代理運行碰撞，同時仍允許跨會話的安全並行。

## 原因
- 自動回覆運行可能很昂貴（LLM 呼叫），當多個入站訊息接近時可能會碰撞。
- 序列化避免競爭共享資源（會話檔案、日誌、CLI stdin）並減少上游速率限制的機會。

## 如何運作
- 車道感知的 FIFO 佇列以可設定的並行上限清空每個車道（未設定車道預設為 1；main 預設為 4，subagent 為 8）。
- `runEmbeddedPiAgent` 按**會話鍵**入隊（車道 `session:<key>`）以保證每會話只有一個活動運行。
- 然後每個會話運行被排入**全域車道**（預設 `main`），因此總並行性受 `agents.defaults.maxConcurrent` 限制。
- 當啟用詳細日誌時，如果排隊的運行在開始前等待超過 ~2s，會發出短通知。
- 輸入指示器仍然在入隊時立即觸發（當頻道支援時），因此在等待輪次時使用者體驗不變。

## 佇列模式（每頻道）
入站訊息可以引導當前運行、等待後續輪次或兩者都做：
- `steer`：立即注入當前運行（在下一個工具邊界後取消待處理的工具呼叫）。如果未串流，回退到 followup。
- `followup`：在當前運行結束後為下一個代理輪次入隊。
- `collect`：將所有排隊訊息合併為**單一**後續輪次（預設）。如果訊息針對不同頻道/討論串，它們會單獨清空以保留路由。
- `steer-backlog`（又名 `steer+backlog`）：現在引導**並**保留訊息用於後續輪次。
- `interrupt`（舊版）：中止該會話的活動運行，然後運行最新訊息。
- `queue`（舊版別名）：與 `steer` 相同。

Steer-backlog 意味著您可以在引導運行後獲得後續回應，因此串流介面可能看起來像重複。如果您希望每個入站訊息一個回應，請偏好 `collect`/`steer`。
發送 `/queue collect` 作為獨立命令（每會話）或設定 `messages.queue.byChannel.discord: "collect"`。

預設值（在設定中未設定時）：
- 所有介面 → `collect`

透過 `messages.queue` 全域或每頻道設定：

```json5
{
  messages: {
    queue: {
      mode: "collect",
      debounceMs: 1000,
      cap: 20,
      drop: "summarize",
      byChannel: { discord: "collect" }
    }
  }
}
```

## 佇列選項
選項適用於 `followup`、`collect` 和 `steer-backlog`（以及當 `steer` 回退到 followup 時）：
- `debounceMs`：在開始後續輪次之前等待安靜（防止「continue, continue」）。
- `cap`：每會話最大排隊訊息數。
- `drop`：溢出策略（`old`、`new`、`summarize`）。

Summarize 保留丟棄訊息的簡短項目符號列表，並將其作為合成後續提示注入。
預設值：`debounceMs: 1000`、`cap: 20`、`drop: summarize`。

## 每會話覆寫
- 發送 `/queue <mode>` 作為獨立命令以儲存當前會話的模式。
- 選項可以組合：`/queue collect debounce:2s cap:25 drop:summarize`
- `/queue default` 或 `/queue reset` 清除會話覆寫。

## 範圍和保證
- 適用於使用 Gateway 回覆管道的所有入站頻道的自動回覆代理運行（WhatsApp web、Telegram、Slack、Discord、Signal、iMessage、webchat 等）。
- 預設車道（`main`）對於入站 + 主心跳是程序範圍的；設定 `agents.defaults.maxConcurrent` 以允許多個會話並行。
- 可能存在額外車道（例如 `cron`、`subagent`），以便背景工作可以並行運行而不阻塞入站回覆。
- 每會話車道保證一次只有一個代理運行接觸給定會話。
- 無外部依賴或背景工作執行緒；純 TypeScript + promises。

## 疑難排解
- 如果命令似乎卡住，啟用詳細日誌並尋找「queued for …ms」行以確認佇列正在清空。
- 如果您需要佇列深度，啟用詳細日誌並觀察佇列計時行。
