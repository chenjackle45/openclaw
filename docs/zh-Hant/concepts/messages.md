---
title: "Messages(訊息處理)"
summary: "訊息流、會話、佇列以及推理過程的可見性"
read_when:
  - 解釋入站訊息如何變為回覆
  - 釐清會話、佇列模式或串流行為
  - 記錄推理過程的可見性及其對用量的影響
---
# Messages（訊息）

本頁面彙整了 OpenClaw 如何處理入站訊息、會話、佇列、串流以及推理過程的可見性。

## 訊息流（高層級）

```
入站訊息
  -> 路由/綁定 -> 會話鍵 (Session key)
  -> 佇列 (若已有運行中的任務)
  -> 代理運行 (串流 + 工具)
  -> 出站回覆 (頻道限制 + 分塊)
```

關鍵設定位於組態中：
- `messages.*`：用於前綴、佇列和群組行為。
- `agents.defaults.*`：用於區塊串流和分塊的預設值。
- 頻道覆寫 (`channels.whatsapp.*`, `channels.telegram.*` 等)：用於上限值和串流切換。

請參閱 [Configuration（設定）](/gateway/configuration) 以獲取完整結構。

## 入站去重 (Inbound dedupe)

頻道在重新連線後可能會重新傳遞同一條訊息。OpenClaw 會維護一個短期的快取，以頻道/帳戶/對象/會話/訊息 ID 為鍵，這樣重複傳遞的訊息就不會觸發另一次代理運行。

## 入站防抖 (Inbound debouncing)

來自**同一個發送者**的一連串訊息可以透過 `messages.inbound` 合併為單次代理運行。防抖的作用範圍是按頻道 + 對話進行的，並使用最近的一條訊息來進行回覆線程/ID 的處理。

設定範例（全域預設 + 各頻道覆寫）：
```json5
{
  messages: {
    inbound: {
      debounceMs: 2000,
      byChannel: {
        whatsapp: 5000,
        slack: 1500,
        discord: 1500
      }
    }
  }
}
```

備註：
- 防抖僅適用於**純文字**訊息；媒體/附件會立即發送。
- 控制命令會繞過防抖，以保持其獨立性。

## 會話與裝置

會話由 Gateway 擁有，而不是由客戶端擁有。
- 直接聊天會合併到代理的主會話鍵中。
- 群組/頻道擁有各自的會話鍵。
- 會話儲存和轉錄記錄保存在 Gateway 主機上。

多個裝置/頻道可以映射到同一個會話，但歷史記錄不會完全同步回每個客戶端。建議：對於長篇對話，使用一個主要裝置，以避免上下文出現分歧。控制 UI 和 TUI 始終顯示由 Gateway 支援的會話轉錄，因此它們是事實來源。

詳情請參閱：[Session management（會話管理）](/concepts/session)。

## 入站正文與歷史上下文

OpenClaw 將**提示正文 (prompt body)** 與**命令正文 (command body)** 分開：
- `Body`：發送給代理的提示文字。可能包含頻道封裝和可選的歷史包裝。
- `CommandBody`：用於指令/命令解析的原始使用者文字。
- `RawBody`：`CommandBody` 的舊版別名（保留用於相容性）。

當頻道提供歷史記錄時，會使用共享的包裝：
- `[Chat messages since your last reply - for context]`
- `[Current message - respond to this]`

對於**非直接聊天**（群組/頻道/房間），**目前的訊息正文**會加上發送者標籤（與歷史條目使用的樣式相同）。這能保持代理提示詞中實時訊息與佇列/歷史訊息的一致性。

歷史緩衝區**僅包含待處理內容**：包括未觸發運行的群組訊息（例如受提及限制的訊息），且**排除**已存在於會話轉錄中的訊息。

指令剝離僅適用於「目前訊息」區段，以便歷史記錄保持原樣。包裝歷史記錄的頻道應將 `CommandBody`（或 `RawBody`）設定為原始訊息文字，並將 `Body` 保持為組合後的提示。歷史緩衝區可透過 `messages.groupChat.historyLimit`（全域預設）和各頻道覆寫（例如 `channels.slack.historyLimit`）進行設定（設為 `0` 則停用）。

## 佇列與後續行動 (Followups)

如果一個任務已在運行中，入站訊息可以被加入佇列、引導至目前任務中，或者收集起來用於後續的一輪。

- 透過 `messages.queue`（以及 `messages.queue.byChannel`）進行設定。
- 模式：`interrupt`, `steer`, `followup`, `collect`，以及待辦事項變體。

詳情請參閱：[Queueing（佇列）](/concepts/queue)。

## 串流、分塊與批處理

區塊串流隨著模型產出的文字塊發送部分回覆。分塊則遵循頻道的文字限制，並避免拆分圍欄程式碼（fenced code）。

詳情請參閱：[Streaming + chunking（串流與分塊）](/concepts/streaming)。

## 推理過程的可見性與權杖

OpenClaw 可以顯示或隱藏模型的推理過程（reasoning）：
- `/reasoning on|off|stream` 控制可見性。
- 當由模型產出時，推理內容仍會計入權杖 (token) 使用量。
- Telegram 支援將推理串流顯示在草稿泡泡中。

詳情請參閱：[Thinking + reasoning directives（思考與推理指令）](/tools/thinking) 和 [Token use（Token 使用）](/token-use)。

## 前綴、執行緒與回覆

出站訊息格式化集中在 `messages` 中處理：
- `messages.responsePrefix`（出站前綴）和 `channels.whatsapp.messagePrefix`（WhatsApp 入站前綴）。
- 透過 `replyToMode` 和各頻道預設值進行回覆執行緒化。

詳情請參閱：[Configuration（設定）](/gateway/configuration#messages) 和各頻道文件。
